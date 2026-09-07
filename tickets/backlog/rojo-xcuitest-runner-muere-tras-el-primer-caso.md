---
id: rojo-xcuitest-runner-muere-tras-el-primer-caso
status: backlog
priority: high
area: testing
created: 2026-09-06
updated: 2026-09-07
source: /gate de la sesión fx-presentation-still-shows-1to1 (2026-09-06)
---

# El runner de XCUITest muere tras el primer caso de cada suite

## Qué lo distingue de los rojos ya catalogados

`uitest-compara-fechas-sin-fijar-locale` cataloga **tests que fallan por su aserción** (locale, y
dos vecinos preexistentes). Esto es otra cosa: **el runner se cae**. Cada suite ejecuta su primer
caso, lo pasa, y el proceso muere — «Restarting after unexpected exit, crash, or test timeout»—; la
siguiente ejecución reporta `Executed 0 tests` y la corrida acaba en `TEST FAILED` listando casos
que **nunca imprimieron una línea `Test Case … failed`**.

Corrida de 5 suites (2026-09-06): **5 pasados, exactamente uno por suite**; 0 con línea de fallo; 5
en «Failing tests».

Importa la diferencia porque **el modo de fallo tapa a los otros**: con el runner cayéndose, un rojo
de aserción real en el segundo caso de cualquier suite es indistinguible de este ruido. Por eso es
`high` y no otro «rojo conocido» más.

## Medido, no supuesto

- **No es de la sesión que lo encontró.** Worktree limpio desde `HEAD` (`6d87123e`) con
  `Secrets.xcconfig` copiado: `PanelDashboardUITests` falla **idéntico** — mismos dos casos, mismos
  dos reinicios del runner.
- **Y en la dirección contraria, que es la que cierra la pregunta:**
  `QuickActionsFavoritesUITests.test_opensSaveAsFavoriteSheetFromForm` **PASA en el árbol con
  cambios y FALLA en el árbol limpio.** Un rojo introducido por un cambio no se comporta así.
- **El conjunto de nombres varía entre corridas.** `test_hidingSectionRemovesItFromPanelAndPersists`
  pasó en la corrida de 5 suites y falló en la corrida aislada de su propia suite. Lo que cambia no
  es el test: es cuál de sus casos llegó a ser el primero.

## La sospecha, corregida por lo que ya estaba medido

La primera hipótesis fue el disco (la máquina estuvo entre 8,7 y 15 GB, umbral 25). Se liberaron
6,3 GB —incluidos **5,7 GB en
`CoreSimulator/…/Caches/com.apple.containermanagerd/Dead`**, contenedores de apps desinstaladas que
el informe de disco esconde dentro del total de «Simuladores»— y **el síntoma siguió igual a 14 GB**.

`docs/ESTADO.md` del 6-sep ya apuntaba a la causa mejor: **«el sistema mató `xcodebuild` tres veces
por falta de memoria»**. Esa misma noche, y en esta máquina, el sistema mató además **dos procesos
de espera** de la sesión por presión de memoria (35 % libre). ⇒ **la memoria es la hipótesis
principal, no el disco**; encaja con que el proceso muera sin dejar error de test y con que el caso
afectado dependa del orden.

## Qué hacer

1. Reproducir con memoria holgada (sin builds ni simuladores compitiendo) **y** disco > 25 GB.
   Separar las dos variables, que hasta ahora se movieron juntas.
2. Si persiste, el motivo del `unexpected exit` no está en el stdout: mirar el `.xcresult`
   (`DerivedData/…/Logs/Test/`) y `~/Library/Logs/DiagnosticReports`.
3. Mientras dure, **el paso 3 del `/gate` no da veredicto** para XCUITest. Decirlo en el PR es
   obligatorio: un «XCUITest en rojo» sin esta nota se lee como un fallo del cambio.

## Aviso al siguiente

No archives los nombres que aparezcan en «Failing tests»: **el conjunto depende del orden de
ejecución**, no de qué esté roto. Una lista de nombres aquí envejece en una semana. Los que sí son
rojos de aserción, con su causa medida, están en `uitest-compara-fechas-sin-fijar-locale`.

## No confundir con

- `uitest-compara-fechas-sin-fijar-locale` — rojos de ASERCIÓN preexistentes, causas ya medidas.
- `unit-suite-nondeterministic-reds` — la suite unit, otro target y otro síntoma.
