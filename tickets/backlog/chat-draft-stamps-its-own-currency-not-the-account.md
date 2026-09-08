---
id: chat-draft-stamps-its-own-currency-not-the-account
status: backlog
priority: medium
area: "chat, currency"
created: 2026-09-08
source: review adversarial de chat-draft-drops-the-expense-sign (2026-09-08)
---

# Una transacción del chat puede quedar en una divisa distinta a la de su cuenta

## Qué le pasa al usuario

Dicta «50 dólares», no tiene ninguna cuenta en dólares, elige su cuenta en soles y guarda. La
transacción queda **en USD dentro de una cuenta PEN**. El saldo agrupa por la divisa de la
transacción y convierte con la tasa de HOY, así que esa cuenta enseña un saldo que no cuadra con lo
que el usuario cree tener, y que además **cambia solo** al moverse el tipo de cambio.

## Lo medido (2026-09-08, en este árbol)

El chat estampa la divisa que dictó el usuario; el formulario de siempre estampa la de la cuenta:

| Ruta | Qué persiste |
|---|---|
| `ChatAssistantViewModel.saveDraft` | `currencyCode: draft.currencyCode` |
| `NewTransactionViewModel` | `currencyCode: account.currencyCode` |

Y el borrador no tiene forma de corregirlo: `updateDraft` acepta `amount`, `accountID`,
`subcategoryID`, `note`, `date` y `tagIDs` — **no `currencyCode`**. Así que el usuario puede cambiar
la cuenta pero no la divisa, y la pareja queda desemparejada sin que nada avise.

Aguas abajo, `LiveBalanceCalculator` agrupa por `tx.currencyCode` y convierte cada grupo con la tasa
actual, no con la del día de la transacción: el descuadre no es fijo, se mueve.

La ruta «Editar → Guardar» **no** tiene este defecto, porque pasa por el formulario.

## Lo que NO se midió

Si el parseo puede devolver una divisa distinta de la de la cuenta con frecuencia real, o si en la
práctica `findAccount(byCurrency:)` casi siempre acierta. Antes de arreglar conviene saber si esto
ocurre alguna vez fuera del laboratorio.

## Criterio de hecho (AC)

- [ ] Decidido qué manda: la divisa dictada o la de la cuenta elegida.
- [ ] La combinación imposible no se puede guardar en silencio — o se convierte, o se avisa, o
      `updateDraft` deja cambiar la divisa.
- [ ] Test que fije la decisión.
