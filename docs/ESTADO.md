---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` — Merge #120: once ideas del 9-sep al backlog, medidas contra el código
TestFlight build **13** (CPV 13) — subido el 2026-09-09, `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Once ideas de Jürgen pasaron de su cabeza al board, y tres no eran lo que parecían.** Captura sin
spec: cinco al arrancar (cuentas, sheet de media altura, multi-divisa, hero de Distribución, FAB) y
seis a mitad de sesión (Siri de iOS 27 **high**, chat caído **high**, iPad, chat multi-transacción,
iPhone Duo, Apple Watch). **Diez tickets nuevos**; `apple-watch` ya existía y se actualizó en vez de
duplicarse.

Aunque el encargo era capturar, cada premisa se midió contra el árbol, y **tres cambiaron**: el
«nuevo registro» **no** usa detent medium hoy —se presenta con `.large` explícito, y el `[.medium]`
de `NewTransactionView` es de un sub-sheet interno—; al hero **no le falta** llegar a Distribución,
sino que hay **cinco heros paralelos** y ninguno se comparte; y el FAB **sí anima en el Panel** y no
en Estadísticas, con el vocabulario ya escrito dentro del propio componente. Un cuarto dato ahorra
trabajo: el chat **ya transporta un array** de borradores, así que el tope de «una transacción por
mensaje» no está en la estructura de datos.

**Y una corrección propia, que conviene leer antes que lo anterior:** el hallazgo de camino de esta
sesión —el `commit-msg` de ADR-013 no corre en Yala— **ya tenía ticket desde el 8-sep**
(`el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo`, **high**). Se creó un duplicado por
no buscarlo antes, se detectó al escribir este estado y se retiró; lo único que aportaba —**768 de
3335 commits (23 %) llevan el trailer**, el más antiguo del 13-ene— se fusionó en el ticket bueno.
La búsqueda de duplicados se hizo para las cinco ideas y **no** para el hallazgo: ahí estuvo el
fallo.

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
4. **El avisador de rojos advisory del CI no puede avisar** (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`,
   **high**): `Invalid API key`. Mientras siga así, un `tests: fail` no distingue «hay tests rotos»
   de «la credencial está mal».
5. **El aviso de cierre cita el PR de OTRA sesión** (`el-aviso-de-cierre-cita-el-pr-de-otra-sesion`,
   **medium**): falla en silencio, con `HTTP 200` y aspecto bueno.
6. **El build 13 llega al grupo interno, no al externo.** «Test interno» tiene un tester
   (Jürgen, `INSTALLED`) y ahí ya es instalable. «Testers Yala» son 3 y su
   `externalBuildState` es `READY_FOR_BETA_SUBMISSION`: para que les llegue hay que pasar
   beta review de Apple. Si el segundo teléfono del device-QA no usa el Apple ID de
   Jürgen, no verá el build hasta resolver eso — es decisión suya, no se tocó.
7. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

**El backlog creció a 230 tickets y trae dos `high` nuevos que no estaban ayer**:
`chat-assistant-is-down` (el chat de IA caído — capturado, **sin investigar**, porque el encargo era
captura) y `siri-ai-integration-ios-27` (pide investigación antes que spec: hay que averiguar qué
expone iOS 27 y si obliga a subir el suelo, que hoy es iOS 26+).

Sigue en pie lo de la tanda anterior: cuatro tickets de FX del 9-sep
(`live-anchor-breakdown-doubles-the-approximate-glyph`, `pie-header-total-unmarked`,
`weekday-bar-daily-average-unmarked`, `uitest-seed-reseeds-the-corpus-without-reset`) y del board
previo `preferred-currency-has-three-different-defaults`, `financial-report-amounts-unmarked`,
`widget-fallback-summary-uses-ten-rows`, `bridge-synthesis-trusts-a-zero-converted-amount`,
`fx-historical-balance-curve-unmarked` y `records-summary-mixes-preferred-currencies`.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso; sigue siendo el hueco grande de esta familia),
`el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo` (**high**, toca a todos los agentes —
los **cuatro** commits de esta sesión se verificaron con un grep a mano, y el cuerpo del PR salió
sucio hasta que se editó: el grep del commit no cubre `gh pr create`),
`corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.

**Y dos nuevas, cortas, de la tanda del 9-sep:**

- **¿Se ataca ya el chat caído?** Es `high` y es función de pago; está sólo capturado.
- **`fab-appears-without-animation` quedó en `low`**, la única de las once que se desvía del «medium
  salvo que el área diga otra»: es polish y no corrige nada incorrecto. Una línea del frontmatter si
  prefieres subirla.
