---
name: mi-gate-no-compila-los-targets-de-test
description: El paso 1 del gate corre `xcodebuild build`, que NO compila YalaTests ni YalaUITests — el CI usa `build-for-testing`; si el paso 2 no dispara, nadie comprueba que los tests siguen compilando
metadata:
  type: feedback
---

**Cuando el gate no dispare el paso 2 (unit), compila los targets de test a mano antes de dar el
árbol por verificado: `xcodebuild build-for-testing -scheme "Yala Dev" -destination '…iPhone 17 Pro'`.**

**Why:** el paso 1 del gate corre `xcodebuild … build`, y `build` **no construye los targets de
test**. El paso 2 los tocaría, pero sólo se dispara si hay `.swift` modificados. El 2026-09-09, con
un cambio que era **sólo `Yala.xcodeproj/project.pbxproj`** (bump de CPV para TestFlight), el gate
salió entero verde habiendo compilado **cero** código de test — y un `.pbxproj` toca los 20 targets,
los de test incluidos. El CI, que usa `build-for-testing`, sí los compila: ahí es donde se habría
visto un roto, es decir, después de commitear y abrir el PR.

Es la familia de [[mis-mediciones-fallan-por-el-filtro]] y de
[[gate-paso3-no-detecta-cero-casos]]: el gate no dijo nada falso, simplemente **su alcance no
cubría lo que yo creía que cubría**, y la diferencia sólo se ve leyendo qué compila cada verbo.

**How to apply:**

- El disparador no es «toqué tests», es **«el gate saltó el paso 2»**. Si el paso 2 no corrió y el
  diff toca algo que alcanza a los targets de test (`.pbxproj`, `.xcconfig`, `.xcscheme`,
  `Package.resolved`), `build-for-testing` es la comprobación que falta.
- **Con control positivo, o no vale**: `** TEST BUILD SUCCEEDED **` puede salir sin haber tocado los
  targets. Confirma que produjo los bundles — `grep -oE "(YalaTests|YalaUITests)\.xctest"` sobre el
  log — igual que se cuenta `Test run with` para descartar el «cero casos».
- Y **lee el exit, no el grep**: aquel día `grep -E "error:"` sobre el log de `build-for-testing`
  devolvió líneas que eran código fuente de tests (`AttestSyncGate.classify(error:` …), no errores.
  El veredicto estaba en `EXIT_REAL=0` y en `** TEST BUILD SUCCEEDED **`.
