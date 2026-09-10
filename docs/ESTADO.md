---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #127: el rediseño de sesiones arranca por su **paso 0**, el vocabulario.
Sigue sin haber código de producto. TestFlight build **13** (CPV 13) — `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (paso 0: el vocabulario)

**Para el usuario no cambia nada, y ese es medio objetivo**; la otra mitad es que siga sin cambiar
cuando los pasos 4-10 escriban el copy nuevo. Conviven **dos vocabularios a propósito**: dentro se dice
*sesión privada* / *sesión en la nube*; al usuario se le habla de **dónde viven sus datos**, y ese copy
ya funciona. `docs/glosario.md` lo deja escrito, con los strings reales y con **«Yala completo» ≠ «nube
completa»**, que el ADR advierte y ningún documento recogía. `.claude/rules/l10n.md` y `BRAND-VOICE.md`
§7 llevan un puntero de una línea: la tabla no se copia.

**Medido, y una corrección mía:** cero de los 4.074 strings ES usa la jerga interna; «invitad» sigue en
2 keys, que viven en **los 16 locales** — el paso 12 retira 32 strings, no 2. El «15 hermanos» del
ticket eran los otros locales, no otras keys; lo leí mal y medirlo lo corrigió. El código M1 sigue vivo
(65 ficheros), así que las rules se **marcan como históricas**, no se borran.

## Abiertos

1. **Tu cola física**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6), Apple Pay
   y carreras de red (4). Nada de eso se simula. Súmale los device-QA de los pasos 4, 5, 8, 9 y 10.
2. **De FX quedan cuatro cosas**: el widget de inicio (simulable), el asistente (LLM real), la red
   (`ExchangeRateService` falla por AppAttest) y el seam `-uitest-preferred-currency`, que no existe.
3. **Tres veredictos de QA caducos**: `scheduled-payments-notif-dedup`,
   `welcome-start-fresh-wipes-before-ask` (el seam ya existe) y el callout de `siri-intent-dual-container`.
4. **CUATRO XCUITest en rojo** de la nocturna del 9-sep (**high**): caminos centrales, y la suite de UI ya
   no corre en los PR.
5. **Un markdown de encargo dispara la suite entera de iOS**
   (`encargos-markdown-triggers-the-whole-ios-suite`): vuelto a ver en el #127 — 90 min de suite sobre un
   diff sin una línea de Swift. Pasa en toda sesión lanzada.
6. **El aviso de cierre cita el PR de OTRA sesión** (medium): falla en silencio con `HTTP 200`.
7. **El build 13 llega al grupo interno, no al externo**: un segundo teléfono sin tu Apple ID no lo verá
   hasta pasar beta review.
8. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 1 del runbook:** `wrangler-prod-onboarding-choice-percent-drift` (protege algo que ya está en
producción), y luego los diez restantes en orden. **El 11 está vacante a propósito** y no se renumera:
las decisiones se citan entre sí por número. El paso 0 no bloqueaba a nadie y ya está en `done`.

**El board: 157 en backlog, 46 en qa** (`docs/TICKETS.md`, 260 = 260 contra disco). Los `high` fuera del
rediseño siguen siendo `nocturna-del-9-sep-…`, `chat-assistant-is-down` y `siri-ai-integration-ios-27`.

## Bloqueo

**Tres cosas que te tocan a ti antes de que la cola avance del todo:** desplegar el gateway tras el paso 1;
tras el fresh start, tu iPhone quedará con sesión a una cuenta inexistente y **hay que recrear los grupos
de prueba** antes de los device-QA; y la política de privacidad y los términos **bloquean la publicación**
del rediseño (hoy dicen que Grupos viaja por iCloud).

**Decisiones tuyas que siguen abiertas**, ninguna del rediseño:
`corpus-de-test-de-staging-crece-sin-limite`, el filtro de naturaleza, los worktrees sin el candado
anti-atribución (`open-worktrees-lack-the-attribution-hook`), ¿se ataca ya el chat caído?, y si
`fab-appears-without-animation` sube de `low`. **Sin ticket y medido el 9-sep:** un CSV exportado antes de
convertir una cuenta ya no se importa a ella y aborta el fichero entero — dímelo si quieres uno.
