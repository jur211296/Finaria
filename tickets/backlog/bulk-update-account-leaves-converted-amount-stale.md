---
id: bulk-update-account-leaves-converted-amount-stale
status: backlog
priority: medium
area: "currency, fx, cloud-sync"
created: 2026-09-07
source: review adversarial de fx-manual-writes-seal-approximate-as-final (2026-09-07)
---

# `TransactionService.bulkUpdateAccount` cambia la divisa y deja el monto convertido de la vieja

## Qué pasa

`Yala/Services/TransactionService.swift:113-122` reasigna la cuenta **y con ella `currencyCode`**, que
es el input de la conversión, y guarda sin recalcular nada:

```swift
for transaction in transactions {
    transaction.account = account
    transaction.currencyCode = account.currencyCode   // ← cambia el input de la conversión
}
try context.save()                                    // ← sin recalcular las derivadas
```

`amountInPreferredCurrency`, `exchangeRate` y `preferredCurrencyCode` se quedan con los valores
calculados para la divisa **anterior**. Los once calculadores que leen `amountInPreferredCurrency`
suman ese número como si fuera bueno.

## Lo que lo delata: sus dos hermanos sí lo hacen bien

- `TransactionService.bulkUpdateAmount` (`:238-242`) llama `recalculatePreferredCurrency` y lo
  documenta en voz alta: *«al tocar `amount` SIEMPRE recomputar las derivadas […] o el drain de sync
  emitiría un money-group incoherente (canario `cloudSyncCoherenceGroupPartial`)»*. Y **tiene test**:
  `YalaTests/TransactionServiceTests.swift:22`.
- `RecordsViewModel.bulkUpdateAccount` (`:516-519`), que es el que la UI llama de verdad, también
  recalcula.

La única de las tres que no lo hace es ésta, y es la única sin test. La asimetría es la trampa: un
refactor que unifique las dos rutas por la del «servicio» hereda el bug.

## Atenuante, dicho con claridad

**Hoy no tiene llamador.** `BulkEditSheet.swift:271` llama al de `RecordsViewModel` y
`InboxBulkActionsSheet.swift:297` al de `DraftService`. Es código muerto — por eso `medium` y no
`high`. Pero está vivo en el árbol, es la copia «de servicio» que un refactor futuro llamaría, y

**el canario no lo cazaría**: `currency_code` **no** está en el grupo de coherencia `money`
(`EntityEmissionMap.swift:181`, que sí lleva `amount`, `amount_in_preferred_currency`,
`preferred_currency_code`, `exchange_rate`, `is_exchange_rate_provisional`). Cambiar la divisa sin
tocar las derivadas emite un grupo `money` que parece coherente y no lo es. Se colaría en silencio.

## Criterio de hecho (AC)

- [ ] `bulkUpdateAccount` llama `recalculatePreferredCurrency` tras reasignar la divisa, como su
      gemelo — o se borra, si de verdad no debe existir.
- [ ] Test equivalente al de `bulkUpdateAmount`: mover transacciones a una cuenta de OTRA divisa deja
      las cuatro columnas del grupo `money` coherentes entre sí.
- [ ] Barrer el patrón: cualquier otra ruta que escriba `currencyCode` o `amount` de una transacción
      ya persistida sin recalcular las derivadas.
