---
id: bridge-virtual-only-currency-mismatch-is-silent
status: backlog
priority: medium
area: "groups, bridge, currency"
created: 2026-09-09
source: barrido de changing-an-account-currency-orphans-its-whole-history (2026-09-09)
---

# Un gasto de grupo que cambia de divisa deja la transacción muda por un camino y avisada por otro

## Qué le pasa al usuario

Un gasto de grupo se edita y cambia de divisa. Por el camino normal, Yala **borra** la transacción
personal que le correspondía y deja un borrador en la bandeja para que el usuario la rehaga: se
entera. Por el otro camino —el que reconstruye solo las filas virtuales— no pasa **nada**: la
transacción se queda con el importe viejo, en la divisa vieja, sin borrarse y sin avisar. El usuario
sigue viendo en su cuenta un gasto que el grupo ya cambió.

## Lo medido (2026-09-09)

`Yala/Services/Groups/GroupTransactionBridge.swift`.

Los dos caminos gatean igual, y solo uno tiene salida cuando el guard no pasa:

- `bridgeExpense` (`:390-422`): si `realTx.currencyCode == expense.currencyCode` actualiza; si no,
  `context.delete(realTx)` + `createDraftCaseA(reason: .currencyChanged, …)`.
- `bridgeVirtualOnly` (`:542-557`): el mismo guard, `if let realTx, realTx.currencyCode ==
  expense.currencyCode { … }`, **sin `else`**. No actualiza, no borra y no genera draft.

El comentario de `:540-541` dice que el gate existe «para no corromper data del user», que es
correcto — lo que falta no es el gate, es qué hacer cuando corta.

Encontrado midiendo qué filas admitían reexpresión al cambiar la divisa de una cuenta; no es un
efecto de ese cambio, es preexistente.

## Criterio de hecho (AC)

- [ ] Decidido si el camino virtual-only debe hacer lo mismo que `bridgeExpense` (borrar + draft) o
      algo distinto, y por qué.
- [ ] Test que fije la decisión con una `TransactionItem` real superviviente cuya divisa no casa.

## Relacionados

- `changing-an-account-currency-orphans-its-whole-history` — de donde salió la medición.
