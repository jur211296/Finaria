---
name: subir-build-a-testflight
description: Los deltas medidos el 2026-09-09 subiendo el build 13 — ExportOptions.plist ya no existe en el repo, Secrets.xcconfig es un symlink en el worktree, y quién responde «¿es instalable?»
metadata:
  type: reference
---

La receta larga (archive → export → preflight → `asc builds upload`, con la key, el issuer y los
gotchas de PLA / tren cerrado / disco) vive en la memoria de proyecto
`project_release_archive_upload`. Aquí sólo van **los deltas que medí el 2026-09-09** subiendo el
**build 13** de 2.1, porque contradicen o completan lo que estaba escrito.

**1 · `ExportOptions.plist` ya NO existe en el repo.** La ficha dice que es reusable en
`App Store/build-25/`; ese directorio no está ni en el árbol principal ni en un worktree. **Hay que
recrearlo**, y con esto basta: `method=app-store-connect`, `teamID=3WKFFVD66J`,
`signingStyle=automatic`, `manageAppVersionAndBuildNumber=false`, `uploadSymbols=true`,
`destination=export`. Escríbelo fuera del repo (el scratchpad) — `App Store/` **no** está
gitignoreado y un plist suelto ahí se cuela en un `git add`.

**2 · En un worktree, `Secrets.xcconfig` es un symlink al del árbol principal.** No hay que copiarlo
a mano, contra lo que dice el gotcha de la ficha larga: `lanzar-sesion` ya lo enlaza. Compruébalo con
`ls -la Secrets.xcconfig` antes de asumir cualquiera de las dos cosas.

**3 · El gotcha de «archivar desde un worktree aislado» sigue vivo y hoy aplicaba.** Mientras
archivaba había otra sesión compilando en su propio worktree; archivar desde `~/Yala` habría
empaquetado sus ediciones en vuelo. Comprobar con `pgrep -x xcodebuild` (con `-f` hay falsos
positivos) y `lsof -a -p <pid> -d cwd`, que dice **de qué worktree** es cada corrida.

**4 · Quién responde «¿ya es instalable?» — y no es `processing_state`.** `VALID` sólo dice que ASC
lo procesó. Lo que decide si alguien puede instalarlo es
`asc testflight distribution view --build-id <id>`:

- `internalBuildState: IN_BETA_TESTING` → instalable **ya**, sin beta review.
- `externalBuildState: READY_FOR_BETA_SUBMISSION` → a los testers externos **no les llega** hasta
  pasar beta review de Apple.

En Yala son dos grupos y la diferencia importa: «Test interno» (1 tester, Jürgen) y «Testers Yala»
(3, externo). Un device-QA en un **segundo teléfono** sólo funciona si ese Apple ID está en el grupo
interno. Míralo con `asc testflight groups list` + `asc testflight testers list --group <id>` y
**dilo en el parte**: mandar un build a beta review es una acción con efectos externos, no se hace
por iniciativa propia.

**5 · El tren de 2.1 está abierto porque 2.1 nunca se publicó.** `asc versions list` llega hasta
**2.0.4** como última `READY_FOR_SALE`; no existe una `appStoreVersion` 2.1. Por eso el bump de
`MARKETING_VERSION` que exige ITMS-90186 **no** aplicaba y sólo tocaba `CURRENT_PROJECT_VERSION`
(20 ocurrencias, `sed` global). Cuidado al buscar el bump anterior en `git log -S`: sale un
`bump build a 13` de **mayo** que es del tren 1.x, no del actual.

Relacionado: [[mi-gate-no-compila-los-targets-de-test]] — un bump de CPV toca los 20 targets y el
gate no compila los de test.
