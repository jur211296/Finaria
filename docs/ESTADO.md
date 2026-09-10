---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` — Merge #123: el avisador de rojos del CI ya entrega, y dejó de tumbar la suite
TestFlight build **13** (CPV 13) — subido el 2026-09-09, `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (la última: el avisador del CI)

**El canal de avisos del CI vuelve a entregar, y ya no puede morir en silencio.** Verificado desde
el runner —que era el punto: el secreto que fallaba es el del repo, y probarlo en el Mac no
demostraba nada—: HTTP **200** contra el webhook real. Y el avisador de push a `2.1` está **verde
por primera vez tras 37 rojos seguidos**, con el propio commit del merge.

**Eran tres workflows, no uno.** `qa.yml`, `avisar-grok-push-principal.yml` y
`nocturna-vigilante.yml` compartían el par de secretos y el mismo `curl` triplicado con tres
tratamientos de error distintos. El envío vive ahora en `.github/actions/avisar`: si el webhook no
responde, deja el aviso escrito en un issue (`aviso-ci`) en vez de morir, y solo se pone rojo
cuando no queda ningún canal.

**Decisión de Jürgen: check propio + canal de respaldo.** El aviso salió del job `tests`, así que
un `tests: fail` vuelve a significar «la suite falló de verdad». De los 3 rojos de `qa.yml` en las
40 últimas corridas los TRES eran del avisador, y dos tapaban señal real.

**Una premisa del ticket queda matizada:** `2.1` no tiene protección de rama ni rulesets, así que
GitHub nunca bloqueó nada. Lo que paró el #118 fue nuestra propia `/cerrar-total`, que para si
`mergeStateStatus` no está limpio — y con checks rojos no requeridos ese estado es `UNSTABLE`,
que significa «mergeable con checks fallando». Ticket propio.

**La review adversarial cazó SEIS defectos del arreglo**, y el peor lo anulaba entero: el ping
salía **verde** el día que el canal muere, porque el respaldo entregaba y el paso salía con 0. Un
vigilante que se rescata a sí mismo no vigila nada. El segundo se midió en producción en vez de
razonarlo: con `always()`, cancelar un run **a mano** entregaba «la suite NO llegó a correr»; con
`!cancelled()`, el mismo gesto no dice nada. Dos runs, mismo gesto, resultado opuesto.

## La sesión anterior (la divisa de una cuenta) — cerrada

Merge #118. Cambiar la divisa de una cuenta ya no deja su histórico atrás: con movimientos, Guardar
pide confirmación con el número de filas y reexpresa cada importe con la tasa **de su fecha**. Es el
primer sitio del repo que reescribe el `amount` crudo de filas ya persistidas, y por eso la
confirmación es explícita y sin cobertura no se convierte nada. Lo que sigue vivo de esa sesión está
en «Abiertos» y en sus cinco tickets; el resto lo guarda git.

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

**El backlog está en 239 y trae cuatro tickets nuevos del avisador**, además de los cinco de la
sesión de la divisa: `nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo` (**high**),
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

**Tres decisiones tuyas** (era una más: la divisa de la cuenta se decidió hoy y ya está cerrada):
`el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo` (**high**, toca a todos los agentes;
los **seis** commits de esta sesión se verificaron con un grep a mano, uno a uno),
`corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.

**Y dos cortas de la tanda del 9-sep, sin contestar:**

- **¿Se ataca ya el chat caído?** Es `high` y es función de pago; está sólo capturado.
- **`fab-appears-without-animation` quedó en `low`**: es polish y no corrige nada incorrecto. Una
  línea del frontmatter si prefieres subirla.

**Un efecto de hoy que ninguna pantalla avisa, y que puede merecer decisión:** un CSV exportado
**antes** de convertir una cuenta deja de poder importarse a ella, y el fallo aborta el fichero
entero. Medido, no arreglado, sin ticket propio: dímelo si quieres uno.
