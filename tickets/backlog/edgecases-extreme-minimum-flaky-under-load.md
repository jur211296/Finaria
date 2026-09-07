---
id: edgecases-extreme-minimum-flaky-under-load
status: backlog
priority: low
area: testing
created: 2026-09-05
source: rojo clasificado en el gate de group-joiner-flag-consumers-still-narrow
---

# `test_extremeMinimumAmountSaves` falla en lote y pasa solo

## Qué se observó, medido el 2026-09-05

Corriendo cinco suites XCUITest en una sola invocación (`GroupMembersAdminUITests`, `GroupsSmokeUITests`,
`GroupsEmptyStateUITests`, `EdgeCasesUITests`, `WelcomeFreshStartAlertUITests` — 19 tests), falló uno:

```
YalaUITests/Support/XCUIApplication+Yala.swift:208: error:
-[YalaUITests.EdgeCasesUITests test_extremeMinimumAmountSaves] : XCTAssertTrue failed —
No apareció la pantalla de éxito de la transacción (transaction_success_accept) — el guardado no completó.
```

Re-corrida **la misma suite en aislamiento**, los 2 tests pasan (`test_extremeMinimumAmountSaves` en
32.5 s). En el lote había tardado 37.7 s antes de rendirse.

## Por qué NO es el cambio que lo destapó

El gate corría el fix de identidad de Grupos (`group-joiner-flag-consumers-still-narrow`). Este test
guarda una transacción **personal** y no pasa por ninguna ruta de identidad de Grupos. Las tres suites
de Grupos del mismo lote pasaron, y los 6038 unit tests también.

## La hipótesis, sin comprobar

Espera por un elemento de UI que bajo carga (cinco suites seguidas, simulador ya caliente) tarda más
que su timeout. No se midió cuál es ese timeout ni si es el mismo patrón que ya se corrigió el
2026-08-04 en este test (el falso verde que afirmaba el regreso al Panel con el sheet aún puesto).

**Antes de perseguirlo**: `bash qa/scripts/disk-report.sh`. En la corrida donde falló había 26 GB
libres, por encima del umbral, así que el disco NO lo explica esa vez — pero es lo primero que se
descarta si reaparece.

## Segunda medición, el mismo día

Re-corrido **el lote entero de cinco suites** tras el arreglo de la review adversarial: **19 tests, 0
fallos**, `test_extremeMinimumAmountSaves` incluido. O sea, en el mismo montaje que lo tumbó una vez,
pasó a la siguiente. Va **1 fallo de 2 corridas del lote**, más 1 de 1 en aislamiento — muestra
demasiado pequeña para concluir nada salvo que no es determinista.

## Qué haría falta

Reproducirlo: correr el mismo lote de cinco suites unas cuantas veces y contar. Un fallo de 1 en N no
justifica tocar el test; uno de 1 en 3 sí, y entonces el arreglo es el timeout de la espera, no el
guardado.

## Medición del 2026-09-06 (Frank, desde `groups-archived-group-rejects-join`)

**No es flaky bajo carga: es determinista, y el nombre del ticket induce a error.** Medido hoy en
local, aislado y sin nada más corriendo:

- Falla con mis cambios (39,3 s) **y falla igual con `ContentView.swift` revertido a HEAD** (36,3 s)
  ⇒ preexistente, no de ninguna rama en vuelo.
- **Falla también corriéndolo SOLO**, que es lo que lo separa de sus vecinos: en la misma tanda,
  `QuickActionsFavoritesUITests` y `TransactionsCrudUITests` fallan dentro de una tanda y **pasan
  aislados** (47 s y 37 s). Ésos sí son carga; éste no.
- Cae en `XCUIApplication+Yala.swift:208`, esperando `transaction_success_accept`: la pantalla de
  éxito de la transacción no aparece en 10 s.

⇒ Subir el timeout del helper —que ayudaría a los otros dos— **no arreglará éste**. Hay algo que
impide que el guardado complete con ese importe. Y un aviso de método pagado hoy: ese mismo síntoma,
en esa misma línea, lo produjo también un **bug real** introducido en esta sesión (una alerta con el
label del botón dependiendo del `@State`). ⇒ el síntoma no identifica la causa; hay que bisecar.

