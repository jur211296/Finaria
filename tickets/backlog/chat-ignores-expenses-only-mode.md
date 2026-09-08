---
id: chat-ignores-expenses-only-mode
status: backlog
priority: low
area: "chat"
created: 2026-09-08
source: hallazgo de camino en chat-draft-drops-the-expense-sign (2026-09-08)
---

# El modo «solo gastos» no llega al chat

## Qué le pasa al usuario

Tiene la app en modo **solo gastos** —donde ingresos y su UI desaparecen de Panel, Registros,
Estadísticas y Planificación— dicta algo al chat que el modelo interpreta como ingreso, y el chat le
propone un borrador de **ingreso**. Es la única superficie de captura donde ese modo no se respeta.

Antes del 2026-09-08 la incoherencia era invisible: el chat guardaba todo positivo, así que un
«ingreso» y un «gasto» acababan idénticos en el store. Al firmar el monto, la diferencia pasa a ser
real: ahora ese borrador sí entra como ingreso.

## Lo medido (2026-09-08, en este árbol)

Las otras tres rutas de captura fuerzan el gasto cuando el modo está activo. `SiriDraftService` lo
hace y explica por qué:

```swift
// Respeta expensesOnlyMode: si activo, fuerza gasto ignorando lo que infirió el LLM
// (consistente con el intent viejo + QuickExpense + ApplePay).
let isExpense = expensesOnlyMode ? true : parsed.isExpense
```

`QuickExpenseIntent` lo replica (`expensesOnlyMode ? true : (firstParsed?.isExpense ?? true)`), y
`ApplePayDraftService` lo fuerza en la línea. **`ChatAssistantViewModel` y `DraftBuilder` no
mencionan `expensesOnlyMode` en ningún punto** — grep sobre los dos ficheros: cero.

El Inbox sí lo respeta al editar (`if sessionState.isExpensesOnlyMode { isExpense = true }`), así que
la incoherencia es solo del chat.

## Lo que NO se midió

Si Jürgen quiere que el chat respete el modo o que sea deliberadamente la vía de escape para
registrar un ingreso sin salir del modo. El comentario de Siri sugiere lo primero («consistente
con…»), pero es una inferencia sobre la intención, no algo escrito en una decisión.

## Criterio de hecho (AC)

- [ ] Decidido si el chat respeta `expensesOnlyMode`.
- [ ] Si lo respeta: el borrador nace como gasto, con la forma de `SiriDraftService`, y un test lo fija.
