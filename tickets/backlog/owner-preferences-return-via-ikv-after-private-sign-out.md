---
id: owner-preferences-return-via-ikv-after-private-sign-out
status: backlog
priority: medium
area: "settings, sync"
created: 2026-09-11
source: "review adversarial del plan del paso 9 (`session-exits-one-verb-per-session`)"
---

# Tras cerrar una sesión privada, las preferencias del dueño vuelven por el iCloud KV

## El síntoma, en lenguaje de usuario

Cierro mi sesión privada para prestar el móvil. La otra persona entra y ve mi nombre y mi moneda.

## Lo medido (2026-09-11)

- El borrado de cierre (`performSignOutWipeIfArmed` → `DataWipeService.resetForSignOutWipe`) resetea las
  preferencias LOCALES.
- En `.icloud`, `PreferenceSyncService.bootstrap()` vuelve a aplicar las claves sincronizadas del iCloud KV
  del Apple ID —`userName`, `defaultCurrencyCode` y el resto del catálogo— en el arranque siguiente.
- El iCloud KV es del Apple ID, no de la persona: en el préstamo de móvil que el ADR 2026-09-09 hace
  normal, el Apple ID sigue siendo el del dueño.

## La decisión que falta (Jürgen)

¿El Welcome tras un cierre privado debe arrancar sin preferencias heredadas (no aplicar el iCloud KV hasta
que alguien restaure o haga el onboarding privado), o se acepta como semántica de la plataforma (el
teléfono es del Apple ID)?
