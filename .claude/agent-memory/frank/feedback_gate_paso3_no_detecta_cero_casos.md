---
name: gate-paso3-no-detecta-cero-casos
description: El paso 3 del gate (XCUITest) puede dar TEST SUCCEEDED sin ejecutar nada y su grep no lo detecta — YalaUITests es XCTest, no Swift Testing, y no emite «Test run with»
metadata:
  type: feedback
---

En el paso 3 del gate, cuenta los XCUITest con `^Test Suite '.*' (passed|failed)` y
`Executed [0-9]+ test` — **no** con los marcadores del paso 2.

**Why:** el paso 2 obliga a verificar `Test run with N tests in M suites` porque el modo de fallo
«cero casos» de Swift Testing sale con exit 0 y `TEST SUCCEEDED`. El paso 3 hereda ese mismo grep,
pero `YalaUITests` es **XCTest**: emite `Test Suite '<X>' passed` y `Executed N tests`, y **nunca
emite `Test run with`**. Medido el 2026-09-06: 5 suites de XCUITest dieron como única salida
filtrada `** TEST SUCCEEDED **` — indistinguible de una corrida que no ejecutó nada. Al re-grepear
salieron 16 tests en 5 suites. Un nombre de suite mal escrito ahí pasa por verde sin dejar rastro.

**How to apply:** siempre que corras el paso 3, saca los nombres de suite ejecutados
(`grep -oE "^Test Suite '[A-Za-z]+UITests'" | sort -u`) y compáralos uno a uno con los que pediste.
Si no cuadran, no está verde: está vacío.

Y el corolario general, que es el mismo de siempre:
[[feedback_mis_mediciones_fallan_por_el_filtro]] — un «cero» casi nunca es el código, es el filtro.
Aquí el filtro no daba cero: daba **verde**, que es peor.
