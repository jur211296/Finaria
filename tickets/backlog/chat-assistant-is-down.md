---
id: chat-assistant-is-down
status: backlog
priority: high
area: chat
created: 2026-09-09
source: reporte de Jürgen 2026-09-09
---

# El chat de IA está caído

## Qué le pasa al usuario

Jürgen reporta el 2026-09-09 que **el chat de IA no funciona**. Es una función de pago (gate Pro),
así que mientras esté caída hay usuarios pagando por algo que no responde.

## Lo que NO se sabe todavía

Este ticket es una **captura del reporte**, no un diagnóstico. No se ha reproducido ni medido nada:
no consta si falla al abrir, al enviar, sólo en producción, sólo en `Yala Dev`, ni desde cuándo. La
causa **no se infiere aquí**.

## Por dónde empezaría quien lo tome

Los sitios, sin afirmar que el fallo esté en ninguno:

- `Yala/Services/ChatAssistantService.swift` y `Yala/App/ViewModels/ChatAssistantViewModel.swift`.
- La entrada de usuario: `Yala/App/Views/Chat/ChatSheetView.swift`.
- El gate de acceso: `FeatureGateService.canAccess(.chatAssistant)` (se consulta desde
  `PanelView.swift:612`).
- Y antes que el código, lo de siempre en este repo: **descartar el entorno y la red**. El
  `docs/ESTADO.md` del 2026-09-09 ya deja escrito que en este equipo `ExchangeRateService` falla por
  AppAttest en todos los arranques; si el chat comparte esa puerta, el síntoma puede no ser del chat.

## Estado

Bug capturado, **sin investigar**, a petición de Jürgen (la tanda del 2026-09-09 era captura, no
implementación). Prioridad `high` puesta por él.

## Relacionados

- [[chat-ignores-expenses-only-mode]] y la familia `chat-draft-*` — defectos del chat ya conocidos,
  todos de contenido del borrador, ninguno de disponibilidad.
- [[chat-creates-only-one-transaction-per-message]] — la mejora pedida el mismo día; no se puede
  probar mientras esto siga caído.
