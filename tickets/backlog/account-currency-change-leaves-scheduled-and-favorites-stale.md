---
id: account-currency-change-leaves-scheduled-and-favorites-stale
status: backlog
priority: medium
area: "accounts, currency, fx, planning"
created: 2026-09-09
source: review adversarial de changing-an-account-currency-orphans-its-whole-history (2026-09-09)
---

# Tras convertir una cuenta de divisa, los pagos programados y los favoritos siguen con el importe viejo

## Qué le pasa al usuario

Cambia su cuenta de soles a dólares y acepta convertir el histórico: los movimientos pasados quedan
bien. Pero el alquiler que tenía programado por **3.500** sigue diciendo 3.500, y cuando llegue su
fecha nacerá como **3.500 dólares** en vez de los ~930 que le corresponden. Lo mismo con los
favoritos de la pantalla de nuevo movimiento. Y se repite cada mes.

## Lo medido (2026-09-09)

El importe se conserva y la divisa se toma de la **cuenta**, así que al materializarse quedan
emparejados con el número equivocado:

- `Yala/App/Services/ScheduledPaymentDraftService.swift:253-271` crea el borrador con
  `payment.amount` crudo y `account: payment.account`; al aprobarlo,
  `Yala/Services/DraftService.swift:299-303` estampa `currencyCode: account.currencyCode`.
- `Yala/App/Views/Transactions/NewTransactionView.swift:1732-1742` precarga `favorite.amount` y acto
  seguido hace `viewModel.currencyCode = account.currencyCode`.

El veredicto que decide si la divisa de una cuenta se puede cambiar
(`AccountFormViewModel.currencyChangeVerdict`) solo mira `TransactionItem`: `ScheduledPayment`,
`FavoritePayment` y los `InboxDraft` pendientes no entran ni en el bloqueo ni en la conversión.

## Por qué va aparte

`changing-an-account-currency-orphans-its-whole-history` cerró el histórico —el objeto que la
decisión del owner nombraba—. Esto son **otros tres objetos** con su propia forma: un pago
programado no tiene fecha pasada con la que convertir, así que ni siquiera está claro que
«convertir con la tasa de su fecha» sea la respuesta.

## Criterio de hecho (AC)

- [ ] Decidido qué pasa con `ScheduledPayment`, `FavoritePayment` e `InboxDraft` pendientes de una
      cuenta cuya divisa cambia: convertir (¿con qué tasa?), bloquear el cambio, o avisar.
- [ ] Si se convierte, con qué tasa se hace y qué pasa con los que no tienen fecha aún.
- [ ] Test que fije la decisión con un pago programado sobre la cuenta convertida.

## Relacionados

- `changing-an-account-currency-orphans-its-whole-history` — el histórico, ya cerrado.
