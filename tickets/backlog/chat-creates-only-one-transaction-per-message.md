---
id: chat-creates-only-one-transaction-per-message
status: backlog
priority: medium
area: chat
created: 2026-09-09
source: idea Jürgen 2026-09-09
---

# El chat debería crear varias transacciones desde un solo mensaje

## La idea

Que un único mensaje al chat pueda producir **varias** transacciones de golpe. El caso que Jürgen
tiene en la cabeza: pedirle a una IA que lea sus correos, arme un solo texto con el detalle y se lo
pegue al chat de Yala para que lo registre todo de una vez.

## Por qué importa

Hoy el camino de «tengo veinte movimientos del mes en el correo» a «están en Yala» es de veinte
idas y vueltas. De uno en uno, la función deja de compensar justo cuando más falta hace.

## Lo medido (2026-09-09) — el transporte ya es plural

El modelo de respuesta del chat **ya lleva un array**, no un borrador suelto:

```swift
case drafts([ChatTransactionDraft])   // Yala/App/Models/ChatAssistantModels.swift:301
```

…con su `encode`/`decode` de la lista completa (`:316-332`). Así que el tope, si existe, **no está
en la estructura de datos**. Antes de diseñar hay que medir dónde está: en el prompt, en
`ChatIntentClassifierService`, en el ViewModel o en la card que los pinta
(`ChatTransactionDraftCard.swift`). Que el transporte lo admita no significa que el camino entero
funcione.

## Estado

Idea capturada, **sin spec**. Y hay una dependencia dura: [[chat-assistant-is-down]] — mientras el
chat esté caído esto no se puede ni probar.

## Relacionados

- [[chat-assistant-is-down]] (**high**) — bloquea la verificación.
- [[chat-draft-sign-can-contradict-its-subcategory]] — con N borradores por mensaje, los defectos
  de contenido de un borrador se multiplican por N. Conviene mirarlos antes de abrir el grifo.
