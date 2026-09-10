---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` — Merge #125: el modelo de sesiones está decidido y especificado; nada de código todavía.
TestFlight build **13** (CPV 13) — `VALID` e `IN_BETA_TESTING`. **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (la última: el rediseño del modelo de sesiones)

**Un device-QA guiado se convirtió en rediseño, y Jürgen lo ratificó.** La confusión del Welcome, los
onboardings y los cierres no era de pantalla: tres flags de modo + sesión secundaria, 7 verbos de salida
sobre 11 operaciones. Ahora hay **dos ejes** —¿sesión privada? × sesión en la nube (ninguna / solo grupos /
completa)—, un verbo por sesión, dos botones en Ajustes, y Grupos como mini-app con su cuenta asociable.
Todo en `docs/DECISIONS.md` → «[2026-09-09] Sesiones — dos ejes». **La sesión de visita (M1) se retira**,
ratificado; sus 12 tickets están descartados con el ADR como motivo (13 descartes en total).

**Para implementarlo hay 14 tickets y un runbook** (`session-redesign-implementation-order`): Jürgen pedirá
«implementa el siguiente» y el siguiente es el primero de esa tabla que no esté en `done`. La **matriz de
escenarios** (`docs/sessions/2026-09-09-matriz-escenarios-sesiones.md`, 45 filas) encontró nueve huecos ya
añadidos a sus tickets; el grave: la salida privada tiene que esperar al último export a CloudKit antes de
borrar lo local. **Dos bugs medidos en código y uno confirmado en device** (la puerta «datos ajenos» de
grupos bloqueó al propio Jürgen tras reinstalar). Y producción sirve la elección nube al 100 % mientras el
`wrangler.toml` dice 0: **ese ticket va primero**, antes de cualquier deploy del gateway.

## Abiertos

1. **La cola física de Jürgen**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6),
   Apple Pay y carreras de red (4). Nada de eso se simula.
2. **De FX quedan cuatro cosas**: el widget de inicio (simulable), el asistente (LLM real), la red
   (`ExchangeRateService` falla por AppAttest) y el seam `-uitest-preferred-currency`, que no existe.
3. **Tres veredictos de QA caducos** en sus tickets: `scheduled-payments-notif-dedup`,
   `welcome-start-fresh-wipes-before-ask` (el seam ya existe) y el callout de `siri-intent-dual-container`.
4. **La nocturna del 9-sep dejó CUATRO XCUITest en rojo** (`nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo`,
   **high**): caminos centrales, y la suite de UI ya no corre en los PR.
5. **El aviso de cierre cita el PR de OTRA sesión** (medium): falla en silencio con `HTTP 200`.
6. **El build 13 llega al grupo interno, no al externo** (`READY_FOR_BETA_SUBMISSION`): un segundo
   teléfono sin el Apple ID de Jürgen no lo verá hasta pasar beta review.
7. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El primer ticket del runbook:** `wrangler-prod-onboarding-choice-percent-drift` (alinear el repo con lo
que producción ya sirve). Después, en orden, los otros doce. El device-QA de
`changing-an-account-currency-orphans-its-whole-history` sigue en `tickets/qa/` con guion.

**El board: 156 en backlog, 46 en qa.** El inventario vive en `docs/TICKETS.md`; los `high` fuera del
rediseño siguen siendo `nocturna-del-9-sep-…`, `chat-assistant-is-down` y `siri-ai-integration-ios-27`.

## Bloqueo

**Decisiones tuyas, ninguna del rediseño (todas ratificadas):** `corpus-de-test-de-staging-crece-sin-limite`,
el filtro de naturaleza, los worktrees abiertos sin el candado anti-atribución
(`open-worktrees-lack-the-attribution-hook`, había 11 vivos), ¿se ataca ya el chat caído?, y si
`fab-appears-without-animation` sube de `low`. **Sin ticket y medido el 9-sep:** un CSV exportado antes de
convertir una cuenta ya no se importa a ella y aborta el fichero entero — dímelo si quieres uno.
