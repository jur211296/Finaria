# Paso 1 del rediseño: alinear wrangler.toml de prod con lo que ya sirve el gateway (elección nube al 100 %)

## Contexto
Cola autónoma del rediseño de sesiones (Jürgen 2026-09-10). El paso 0 (`retire-guest-vocabulary-for-session-terms`, PR #127) ya está mergeado a 2.1 y su tmux residual se mató. Arrancas en contexto limpio: no ves la conversación anterior.

Ticket: `tickets/backlog/wrangler-prod-onboarding-choice-percent-drift.md`
Orden: `tickets/backlog/session-redesign-implementation-order.md` (paso 1, modo directo)
Decisiones que mandan: sección «Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)» al final del ticket — léela ANTES que el cuerpo. Índice: `docs/sessions/2026-09-09-desbloqueo-decisiones-rediseno-sesiones.md`.

Qué pasa: producción ya sirve `cloudOnboardingChoiceRolloutPercent: 100`, pero `gateway/wrangler.toml` en prod tiene `"0"`. El próximo `wrangler deploy --env production` apagaría la card «Tu cuenta en la nube» del Welcome en todo el parque.

## Que se pide
1. `gateway/wrangler.toml` (env production): `CLOUD_ONBOARDING_CHOICE_ROLLOUT_PERCENT = "100"` con comentario de fecha al estilo de `CLOUD_MODE`.
2. Corregir comentarios del cliente que afirman «0 en producción» para la elección (`WelcomeAccountChoiceLogic.swift`, `CloudRemoteConfig.swift`, `WelcomeFlowContainer.swift` donde diga «percent remoto en 0»). Grep: `ONBOARDING_CHOICE_ROLLOUT_PERCENT` y «percent remoto».
3. Test en `gateway/test/config.test.ts` que fije SOLO los TRES percents vivos (`cloudMode`, `cloudOnboardingChoice`, `groupsBackend`) parseando el `.toml` (sin red). `secondarySessionRolloutPercent` fuera a propósito.
4. Antes de mergear: `curl` al `/config` de prod y anotar el valor en el PR.
5. Tras merge: `wrangler deploy --env production` + `curl` de confirmación; anotar antes/después en el PR. Si te falta acceso/credencial Cloudflare, PARA y avisa (acceso Jürgen).
6. Staging NO se toca. No decidir rollout: solo alinear repo con lo ya desplegado.
7. Al cerrar: mover ticket a `done/`, actualizar board y **`docs/TICKETS.md`**, matriz si aplica.

## Que NO hay que tocar
- Staging vars / `SECONDARY_SESSION_ROLLOUT_PERCENT` (ticket 12).
- Decidir el percent (ya está en 100 en prod).
- marketing/, clinicas, otros tickets del rediseño.
- Empezar el paso 2.

## Como se sabe que esta bien
- toml prod con onboarding choice en `"100"` y comentario.
- Comentarios cliente alineados; test verde fijando los 3 percents vivos leyendo el toml.
- PR con curls antes/después; deploy prod hecho o bloqueo explícito por acceso.
- Ticket en done, `docs/TICKETS.md` al día, merge a 2.1, `/cerrar-total`.

## MODO AUTÓNOMO HASTA TERMINAR
Gate, commit, docs/board, actualizar `docs/TICKETS.md`, merge y `/cerrar-total` sin preguntar. Bugs/decisiones nuevas → ticket propio (`--solo-crear`) antes de cerrar. Solo parar ante decisión de producto nueva o acceso/credencial real (Cloudflare deploy).

## Avisos al bot dueño (Frank)
POSTea al webhook local de la Mini (URL y key en fichero local, no en git; no las escribas en el repo) cuando:
  (1) necesitas una decisión de producto o de acceso de Jürgen;
  (2) abriste el PR o dejaste preview/artifact listo;
  (3) terminaste el ticket y vas a /cerrar-total — incluye resumen corto de cierre en lenguaje de usuario;
  (4) acabaste un tramo y no tienes siguiente paso claro (aunque no haya pregunta formal) — una vez, no en bucle.
NO avises por: un test rojo que vas a reclasificar, un build que vas a reintentar, ni ruido de CI advisory. URL/key solo en la Mini.
