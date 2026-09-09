---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` — Merge #118: cambiar la divisa de una cuenta ya no deja su histórico atrás
TestFlight build **13** (CPV 13) — subido el 2026-09-09, `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**Se cerró el hueco grande de la familia FX, y la review adversarial cazó seis defectos del
ARREGLO.** Decisión de Jürgen: **prohibir, y ofrecer convertir cuando se puede** — no «avisar y
seguir», que dejaba vivo el desemparejamiento y el round-trip roto de exportación.

Ahora, con movimientos, Guardar pide confirmación con el número de filas y reexpresa cada importe
con la tasa **de su fecha**. Si el histórico lo manda otra entidad, el selector ni se abre. Las
tres clases que bloquean lo hacen porque su conversión **no se sostiene**, medido: el re-bridge
pisa el `amount` de un gasto de grupo en cada pasada y, en cuanto su divisa deja de casar, **borra
la transacción** (`GroupTransactionBridge:391`, `:410-422`).

**Es el primer sitio del repo que reescribe el `amount` crudo de filas ya persistidas** —
`CurrencyChangeService` barre el corpus entero pero solo toca las derivadas, que tienen reparador.
Por eso: confirmación explícita, tasas antes, y si falta cobertura no se convierte nada.

**De los seis defectos del arreglo, el peor lo vieron dos lentes por separado:** el `set` del
binding del alert competía con su propio botón Convertir —en iOS un alert no tiene gesto de
descarte, así que SwiftUI escribe `false` al pulsar cualquiera— y en el peor orden guardaba la
divisa **vieja** sobre el histórico ya convertido. El bug del ticket, recreado por su arreglo.

**Y un séptimo lo cazó el CI, no las lentes:** una aserción que dependía de la divisa preferida de
la máquina. Verde en local (PEN), roja en CI (USD), con 19.569 tests y un solo issue. Nueve
mutantes y tres lentes pasaron por encima porque **todos corrían en el mismo entorno**.

**Dos premisas del ticket eran falsas y se corrigieron en él:** el grupo `money` de `tx_items` tiene
**cinco** columnas, no cuatro, y `currency_code` no es una; y lo inferido sobre CloudSync apuntaba
al applier de `tx_items` cuando la rama que propaga el daño es la de `accounts`.

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
4. **El avisador de rojos del CI no solo no avisa: BLOQUEA EL MERGE**
   (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`, **high**). Medido hoy en dos corridas del
   mismo PR: con un paso advisory en rojo, el avisador sale `exit 1` por `Invalid API key` y pone
   el job entero en rojo; sin rojos advisory, pasa. **Anula el `continue-on-error` de sus propios
   pasos** justo cuando se quería lo contrario. Ojo al arreglarlo: el `exit 1` está bien puesto — lo
   que falla es la credencial.
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

**El backlog está en 235 y trae cinco tickets nuevos de esta sesión.** El que más pesa:
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
