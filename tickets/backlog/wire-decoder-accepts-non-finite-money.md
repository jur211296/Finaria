---
id: wire-decoder-accepts-non-finite-money
status: backlog
priority: medium
area: "cloud-sync, currency"
created: 2026-09-08
source: review adversarial de repair-queue-has-no-exit-for-partial-rate-rows (2026-09-08)
---

# Un importe no finito puede entrar por el canal nube y no sale nunca

## Qué pasa

`WireValueDecoder.double` convierte el valor de wire sin comprobar que el número resultante sea
finito. `Double("nan")` devuelve `NaN`, y ese valor entra por `Apply.moneyReq(\.amount)`
(`EntityApplyMap.swift`) directamente a `TransactionItem.amount`.

La salida está cerrada en el otro sentido —`Canonc1Codec` rechaza los no finitos al EMITIR, con
canario— así que un `NaN` que entre no puede volver a salir: se queda en el dispositivo.

## Por qué importa más de lo que parece

Un `amount` no finito **degenera todo guard de igualdad sobre las columnas derivadas**, porque
`NaN != NaN` es `true`. En concreto, `TransactionItem.recalculatePreferredCurrency` volvería a
escribir esa fila en cada arranque: es justo el bucle que
`repair-queue-has-no-exit-for-partial-rate-rows` cerró para el resto de la población.

Y el número se pinta. Un total que incluya un `NaN` se propaga a cualquier suma que lo toque.

## Qué NO es

**No es una regresión del guard de igualdad.** El decoder es anterior y el agujero existe igual sin
él; lo que cambia es que ahora hay una fila que se comporta distinto al resto.

## Criterio de hecho (AC)

- [ ] `WireValueDecoder.double` rechaza (o cuarentena) los valores no finitos, con el mismo criterio
      que `Canonc1Codec` usa al emitir — las dos direcciones deben coincidir.
- [ ] Test con `"nan"`, `"inf"` y `"-inf"` en el wire, en las dos direcciones.
- [ ] Comprobar si hay filas así ya en producción antes de decidir si hace falta una cura.
