---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` — Merge #124: el candado que prohíbe atribuir un commit a una IA ya está puesto
TestFlight build **13** (CPV 13) — subido el 2026-09-09, `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (la última: el candado anti-atribución)

**Un commit de este repo ya no puede decir que lo escribió una IA.** Hasta hoy podía: el hook que
ADR-013 da por puesto **nunca corrió aquí**, porque `core.hooksPath` local **sustituye** al global
en vez de sumarse. Yala era el único de los 25 repos del Mac en esa situación.

**El dato que cambió tu decisión no estaba en el ticket:** el hook global también prohíbe
*mencionar* «Claude», y aplicado aquí rechazaría **216 commits legítimos** que citan rutas del
propio árbol. De ahí el camino elegido — hook propio, solo atribución, y aquí se puede seguir
nombrando `CLAUDE.md` y `.claude/rules/…`.

**774 rechazos sobre los 3348 mensajes de la historia, 0 fugas y 0 falsos positivos.** Cubre
también el `--author`, que es atribución permanente en la cabecera y no viaja en el mensaje. Banco
de 32 casos en el CI. Detalle en `tickets/done/` y en el PR #124.

## La sesión anterior (el avisador del CI) — cerrada

Merge #123. El canal de avisos del CI vuelve a entregar y ya no puede morir en silencio: el envío
vive en `.github/actions/avisar`, con respaldo a un issue. Eran tres workflows compartiendo el
mismo `curl` triplicado. Lo que sigue vivo está abajo; el resto lo guarda git.

## Abiertos

1. **La cola física de Jürgen**: push APNs real (4 tickets), RPC de producción (3), sign-in real
   SIWA/Google (6), Apple Pay y carreras de red (4). Nada de eso se simula; lo demás sí.
2. **De FX quedan cuatro cosas, y ninguna es montaje**: el **widget de inicio** (simulable, no cupo
   en la tanda), el **asistente** (pide LLM real), la **red** —aquí `ExchangeRateService` falla por
   AppAttest en todos los arranques— y el seam **`-uitest-preferred-currency`**, que no existe y es
   lo único que le falta a `fx-partial-rate-rows-silent-1to1`.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **La nocturna del 9-sep dejó CUATRO XCUITest en rojo y nadie se enteró**
   (`nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo`, **high**). Es lo que el canal roto no llegó
   a entregar: `Executed 145 tests, with 12 failures` — cuatro casos con sus reintentos, en
   caminos centrales (crear transacción, guardar favorito, convertir borrador a gasto de grupo).
   La suite de UI ya no corre en los PR, así que si se quedan, la nocturna pasa a ser un rojo
   permanente — y un rojo permanente se deja de mirar.
5. **El aviso de cierre cita el PR de OTRA sesión** (`el-aviso-de-cierre-cita-el-pr-de-otra-sesion`,
   **medium**): falla en silencio, con `HTTP 200` y aspecto bueno.
6. **El build 13 llega al grupo interno, no al externo.** «Test interno» tiene un tester
   (Jürgen, `INSTALLED`). «Testers Yala» son 3 y su `externalBuildState` es
   `READY_FOR_BETA_SUBMISSION`: para que les llegue hay que pasar beta review. Si el segundo
   teléfono del device-QA no usa el Apple ID de Jürgen, no verá el build hasta resolver eso.
7. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

**Device-QA de `changing-an-account-currency-orphans-its-whole-history`**, ya en `tickets/qa/` con
guion. Sí es simulable, pero **dos de los cuatro pasos van a mano**: el selector de Moneda es un
`NavigationLink` y no responde a taps sintéticos (medido el 8-sep con cuatro técnicas).

**El backlog está en 244.** Los cuatro nuevos son del candado:
`adr-013-does-not-know-yala-has-its-own-commit-msg` (el hook global no sabe que Yala tiene el suyo),
`rebase-and-cherry-pick-skip-the-attribution-hook` (git no invoca el hook al replayar commits, ni en
los merges de la web), `open-worktrees-lack-the-attribution-hook` y `two-qa-benches-nobody-runs`
(dos bancos de `qa/scripts/` que no ejecuta nadie, y los dos nacieron de un fallo real).

**Los cuatro del avisador**, además de los cinco de la sesión de la divisa: `nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo` (**high**),
`cerrar-total-para-ante-un-check-rojo-que-no-bloquea`,
`vigilante-calla-si-no-puede-comprobar-la-nocturna` y
`qa-yml-no-cancela-la-corrida-anterior-de-la-misma-rama`.

**Los cinco de la sesión de la divisa:** El que más pesa:
`account-currency-change-leaves-scheduled-and-favorites-stale` — tras convertir la cuenta, un
alquiler programado de 3.500 soles nace como 3.500 dólares, y se repite cada mes. Los otros:
`cloudsync-account-currency-orphans-receiver-history`,
`account-currency-conversion-overlay-has-no-ceiling`,
`save-error-alert-lies-when-the-context-autosaves`,
`bridge-virtual-only-currency-mismatch-is-silent`.

Siguen en pie los dos `high` de la tanda anterior —`chat-assistant-is-down` (capturado, sin
investigar) y `siri-ai-integration-ios-27`—, los cuatro de FX del 9-sep
(`live-anchor-breakdown-doubles-the-approximate-glyph`, `pie-header-total-unmarked`,
`weekday-bar-daily-average-unmarked`, `uitest-seed-reseeds-the-corpus-without-reset`) y del board
previo `preferred-currency-has-three-different-defaults`, `financial-report-amounts-unmarked`,
`widget-fallback-summary-uses-ten-rows`, `bridge-synthesis-trusts-a-zero-converted-amount`,
`fx-historical-balance-curve-unmarked` y `records-summary-mixes-preferred-currencies`.

## Bloqueo

**Dos decisiones tuyas** (eran tres: el candado anti-atribución se decidió y se cerró hoy):
`corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.

**Y una nueva, corta, del candado:** los worktrees abiertos antes de hoy **no lo tienen** —el hook
vive en el árbol de trabajo, así que una rama sin el fichero no ejecuta nada y git no avisa—. Había
**11 vivos** al medirlo. `open-worktrees-lack-the-attribution-hook` trae las tres opciones.

**Y dos cortas de la tanda del 9-sep, sin contestar:**

- **¿Se ataca ya el chat caído?** Es `high` y es función de pago; está sólo capturado.
- **`fab-appears-without-animation` quedó en `low`**: es polish y no corrige nada incorrecto. Una
  línea del frontmatter si prefieres subirla.

**Un efecto de hoy que ninguna pantalla avisa, y que puede merecer decisión:** un CSV exportado
**antes** de convertir una cuenta deja de poder importarse a ella, y el fallo aborta el fichero
entero. Medido, no arreglado, sin ticket propio: dímelo si quieres uno.
