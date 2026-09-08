---
id: chat-draft-drops-the-expense-sign
status: backlog
priority: high
area: "chat, accounts"
created: 2026-09-08
source: hallazgo de camino en chat-assistant-plants-exchange-rate-one (review adversarial, 2026-09-08)
---

# Un gasto guardado desde el chat SUMA al saldo de la cuenta

## Qué le pasa al usuario

Dicta «gasté 30 soles en el almuerzo», el chat propone el borrador, pulsa Guardar — y **el saldo de la
cuenta sube 30 soles en vez de bajar**.

## Lo medido (2026-09-08, en este árbol)

`ChatAssistantViewModel.saveDraft` persiste el monto **sin firmar**:

```swift
guard dbl.isFinite, dbl > 0, dbl < 1_000_000 else { … }   // solo acepta positivos
…
let transaction = TransactionItem(
    date: draft.date,
    amount: amountDouble,        // ← positivo siempre
```

`draft.isExpense` existe y el ViewModel lo usa en otros dos sitios —lo propaga al abrir el formulario
(`prefill`) y filtra subcategorías con él (`sub.safeCategory.isIncome == !draft.isExpense`)— pero
**no lo usa para firmar el monto que guarda**. `TransactionService.create` tampoco lo toca: hace
`insert` + `save` y nada más.

Todas las demás rutas de escritura SÍ firman:

- `NewTransactionViewModel`: `let finalAmount = transactionType.isNegative ? -amount : amount`
- `TransactionFormModels`: «Indica si el monto debe ser negativo internamente», `.expense → true`
- `DraftService` recibe el monto ya firmado; `InboxView` deduce `isExpense: amount < 0`

Y el saldo se calcula sumando el monto **en crudo**, sin mirar la categoría:

```swift
// LiveBalanceCalculator
nativeBalances[tx.currencyCode, default: 0] += Decimal(tx.amount)
```

## Por qué no salta a la vista

Las pantallas que clasifican ingreso/gasto por **categoría** (`TransactionClassificationLogic`, que
solo cae al signo cuando `category == nil`) muestran la transacción bien: en Registros y Estadísticas
aparece como gasto porque su subcategoría lo es. **El saldo es el que no pregunta por la categoría.**
De ahí que el síntoma sea «los números de las listas cuadran y el saldo no».

## Lo que NO se midió

No se reprodujo en ejecución el saldo resultante — la evidencia es de código: las cuatro piezas de
arriba, leídas en este árbol. Antes de arreglar, conviene un test que ate el saldo, no solo el signo.

## Relación con `chat-assistant-plants-exchange-rate-one`

Ninguna causal, pero sí una consecuencia incómoda que conviene tener presente: ese ticket hizo que
estas filas guarden una tasa correcta y coherente. **Antes, el `1.0` plantado era una señal visible de
que la fila no era de fiar; ahora la fila luce impecable sobre un monto de signo equivocado.** El
arreglo de la tasa no causa este bug, pero le quita el único síntoma que lo delataba de lado.

## Criterio de hecho (AC)

- [ ] Un gasto guardado desde el chat resta del saldo de la cuenta.
- [ ] El signo sale de `draft.isExpense`, como en las otras rutas — no de una heurística nueva.
- [ ] Test de comportamiento sobre el SALDO (no solo sobre el signo del campo), con control positivo
      por mutación.
- [ ] Comprobar qué pasa con las filas ya guardadas: si hay corpus afectado, decidir si se migra.
      Esa parte puede necesitar decisión de Jürgen.
