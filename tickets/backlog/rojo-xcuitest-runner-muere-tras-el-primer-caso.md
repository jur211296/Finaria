---
id: rojo-xcuitest-runner-muere-tras-el-primer-caso
status: backlog
priority: high
area: testing
created: 2026-09-06
updated: 2026-09-06
source: /gate de la sesión fx-presentation-still-shows-1to1 (2026-09-06)
---

# El runner de XCUITest muere tras el primer caso de cada suite

## Qué pasa

Cada suite de `YalaUITests` ejecuta **su primer caso, lo pasa, y el runner muere**. `xcodebuild`
reintenta («Restarting after unexpected exit, crash, or test timeout»), la siguiente ejecución
reporta `Executed 0 tests` y la corrida acaba en `** TEST FAILED **` listando en «Failing tests»
casos que **nunca imprimieron una línea `Test Case … failed`**.

Corrida de 5 suites, 2026-09-06:

```
pasados: 5   (exactamente uno por suite)
fallados según "Test Case ... failed": 0
Failing tests: 5
```

## No es de la sesión que lo encontró — medido, no supuesto

Se creó un **worktree limpio desde `HEAD` (`6d87123e`)** con `Secrets.xcconfig` copiado, y
`PanelDashboardUITests` falla **exactamente igual**: mismos dos casos, mismos dos reinicios del
runner, mismo 1 pasado / 0 fallados. Ninguno de los cambios de aquella sesión toca XCUITest ni el
arranque.

**Y no es un flaky clásico**: `test_hidingSectionRemovesItFromPanelAndPersists` PASÓ en la corrida
de 5 suites y FALLÓ en la corrida aislada de su propia suite. Lo que cambia entre las dos no es el
test: es cuál de sus casos llegó a ser el primero.

Las otras cuatro suites, corridas también en el árbol base, dan el mismo cuadro (3 pasados, 4 en
«Failing tests», 4 reinicios del runner). Y ahí aparece la comprobación que cierra la pregunta en la
dirección contraria: **`QuickActionsFavoritesUITests.test_opensSaveAsFavoriteSheetFromForm` PASA en
el árbol con los cambios y FALLA en el árbol limpio.** Un rojo introducido por un cambio no se
comporta así.

## La sospecha principal, y por qué no se cierra aquí

**El disco.** La máquina estuvo toda la sesión entre 8,7 y 15 GB libres, con el umbral del repo en
25 GB, y la doctrina de `CLAUDE.md` es explícita: con el disco lleno CoreSimulator falla con errores
que no mencionan el disco. Encaja con la forma del síntoma —el primer lanzamiento va, el segundo no—
y con que no aparezca ningún `RequestDenied` ni error de test.

Se liberaron 6,3 GB durante la sesión (incluidos **5,7 GB en
`CoreSimulator/…/Caches/com.apple.containermanagerd/Dead`**, contenedores de apps desinstaladas que
el informe de disco no destaca) y el síntoma **siguió igual a 14 GB**. O el umbral real está más
arriba, o la causa es otra.

## Qué hacer

1. Reproducir con el disco **por encima de 25 GB**. Es la variable que la doctrina del repo señala
   primero y la única que no se ha podido descartar en esta máquina.
2. Si persiste, leer el `.xcresult` de la corrida (`DerivedData/…/Logs/Test/`) y el crash del runner
   en `~/Library/Logs/DiagnosticReports`: el motivo del `unexpected exit` no está en el stdout.
3. Mientras dure, **el paso 3 del `/gate` no puede dar veredicto para XCUITest**: una corrida así
   pasa por roja sin que haya nada roto, y —peor— **taparía un rojo real** en cualquier caso que no
   sea el primero de su suite. Eso es lo que lo hace `high`.

## Aviso al siguiente

No archives estos cinco nombres como «rojos conocidos»: el conjunto de casos que aparece en «Failing
tests» **depende del orden de ejecución**, no de qué esté roto. Una lista de nombres aquí envejece
mal en una semana.
