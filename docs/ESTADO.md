---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #126: el rediseño de sesiones está **decidido, especificado y desbloqueado**;
sigue sin haber código. TestFlight build **13** (CPV 13) — `VALID` e `IN_BETA_TESTING`.
**Subida Yala (TF/store) = solo Mini.**

## Esta sesión (la última: la pasada de decisiones)

**Los trece tickets del rediseño pasaron uno a uno por AskUserQuestion, y ninguno se libró.** Cada uno
lleva ahora al final una sección **«Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)»** que
**manda sobre el cuerpo del ticket y sobre el ADR**; varias derogan lo escrito antes. El runbook gana una
**regla 0** que lo dice, para que la cola autónoma no repregunte. Índice:
`docs/sessions/2026-09-09-desbloqueo-decisiones-rediseno-sesiones.md`.

Tres cambios de forma: el **vocabulario se adelantó al paso 0** (con el orden viejo, siete tickets
escribían copy antes de que existiera el glosario); el **13 se partió** y la mitad de web, ficha y legal
salió a `session-redesign-web-and-store-copy`, **de Lola**; y **producción se vacía entera** —identidades
incluidas— antes del esquema del ticket 2, decidido con los conteos delante: son dos cuentas, las dos
tuyas, cero datos de terceros.

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
   (`encargos-markdown-triggers-the-whole-ios-suite`, medido en el #126): pasa en toda sesión lanzada, y
   sin `concurrency` dos pushes dejan dos runs de 90 min compitiendo.
6. **El aviso de cierre cita el PR de OTRA sesión** (medium): falla en silencio con `HTTP 200`.
7. **El build 13 llega al grupo interno, no al externo**: un segundo teléfono sin tu Apple ID no lo verá
   hasta pasar beta review.
8. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 0 del runbook:** `retire-guest-vocabulary-for-session-terms` (fija el glosario antes de que se
escriba una línea de copy). Luego `wrangler-prod-onboarding-choice-percent-drift` y los once restantes en
orden. **El 11 está vacante a propósito** y no se renumera: las decisiones se citan entre sí por número.

**El board: 158 en backlog, 46 en qa** (`docs/TICKETS.md`, 260 = 260 contra disco). Los `high` fuera del
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
