---
id: unit-suite-nondeterministic-reds
status: backlog
priority: high
area: testing
created: 2026-09-06
updated: 2026-09-06
source: medido durante groups-owner-transfer-and-leave (2026-09-06)
---

# `YalaTests` completa da rojos DISTINTOS en cada corrida, y todos pasan aislados

## Por qué importa

**El gate se apoya en esta suite.** Si sus rojos bailan, cada sesión que corra el gate tiene que
decidir a mano si el rojo es suyo, y la respuesta honesta cuesta tres corridas completas (~90 s cada
una) más un worktree limpio. Eso es exactamente el coste que el gate existe para evitar, y el riesgo
es peor que el coste: un rojo REAL se confunde con el ruido y pasa.

La regla del repo dice «NUNCA declarar fix completo si un test falla; "preexistente" no es excusa».
Hoy no se puede cumplir sin este trabajo previo.

## Lo medido (2026-09-06, iPhone 17 Pro · iOS 26.5 · `-parallel-testing-enabled NO`)

Tres corridas completas de `-only-testing:YalaTests`, **tres conjuntos disjuntos de rojos**:

| Corrida | Árbol | Rojos |
|---|---|---|
| A | con cambios de `groups-owner-transfer-and-leave` | `CloudSyncWiredEntitiesTests.notificationItem_reportConfig_roundTrip_reportType`, `OwnerKeyValueWiringTests.rawStoreIsNotReachable` |
| B | el mismo árbol, misma sesión | `AttestWiringTests.productionConstructions_injectTheLiveProvider_neverAnExplicitNil` |
| C | **`e84b9636` limpio** (worktree aparte, sin ningún cambio) | `GroupICloudIdentitySeedTests.bootSeed_doesNotDependOnTheTransportFetch`, `ModelConfigurationCloudKitWiringTests.everyTestConfiguration_declaresCloudKitDatabase`, `ModelConfigurationCloudKitWiringTests.noTestConfiguration_optsIntoAutomatic` |

Y **los cinco pasan aislados**: `-only-testing` de las tres suites de B y C da `14 tests in 3 suites
passed`; las dos de A dan `19 tests in 2 suites passed` en el árbol limpio.

⇒ No es un fallo de código: es **interacción dentro de la corrida** (estado global compartido, orden
de ejecución, o el reuso per-file de `ModelContainer`).

## La pista más fuerte: son casi todos SOURCE-SCANS

Cuatro de los cinco (`CloudSyncWiredEntities`, `OwnerKeyValueWiring`, `AttestWiring`,
`ModelConfigurationCloudKitWiring`) son escáneres que **leen ficheros del repo** vía `#filePath`, no
tests de comportamiento. Eso apunta a que lo frágil es el acceso al sistema de ficheros bajo carga
—no la lógica que afirman—, y explica por qué el conjunto cambia sin que cambie el código.

Hipótesis a comprobar, en este orden:
1. Los helpers de escaneo enumeran el árbol y algo del entorno los hace fallar bajo carga
   (¿límite de descriptores? ¿`DerivedData` escribiendo a la vez?). Un `catch` que devuelva lista
   vacía convertiría eso en un rojo de aserción, no en un error legible.
2. El **disco**: la máquina estaba en **20 GB libres**, por debajo del umbral de 25 GB del repo.
   `bash qa/scripts/disk-report.sh` antes de repetir la medición — está en el CLAUDE.md por algo.
3. Orden/estado global (`@Suite(.serialized)` ausente donde toca).

## No confundir con esto

El resumen de Swift Testing (`Test run with N tests in M suites`) **no cuadra con la realidad** cuando
hay fallos: la corrida B lo reportó como `5784 tests in 594 suites passed` mientras el conteo directo
de líneas `✔ Test … passed` daba **6139** y las suites arrancadas eran **629**. Al comparar dos
corridas, contar a mano:

```
grep -cE '^✔ Test .* passed' <log>
grep -oE '◇ Suite "?[^"]*"? started' <log> | sort -u | wc -l
```

Y **no canalizar `xcodebuild` a `tail`**: el SIGPIPE corta la corrida a media suite y el resumen
resultante (`1959 tests`) parece un dato y no lo es. Costó una medición entera.

## Criterio de hecho (AC)

- [ ] Causa identificada con evidencia (no hipótesis): por qué un source-scan falla en conjunto y
      pasa aislado.
- [ ] La suite completa da el mismo resultado en dos corridas consecutivas sobre el mismo árbol.
- [ ] Si algún caso queda flaky sin arreglo, entra en la Lista Negra de `TESTING-STRATEGY.md` con
      owner y deadline, como manda `.claude/rules/testing.md`.

## Relacionados

- [[groups-owner-transfer-and-leave]] — la sesión que lo midió (y que tuvo que pagar el coste).
