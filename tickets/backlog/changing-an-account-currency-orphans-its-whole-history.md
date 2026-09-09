---
id: changing-an-account-currency-orphans-its-whole-history
status: backlog
priority: high
area: "accounts, currency, fx"
created: 2026-09-08
source: barrido de chat-draft-stamps-its-own-currency-not-the-account (2026-09-08)
---

# Cambiar la divisa de una cuenta deja todo su histórico en la divisa vieja

## Qué le pasa al usuario

Tiene una cuenta en soles con dos años de movimientos. Entra a editarla, cambia la divisa a dólares
y guarda. **Las transacciones no se tocan**: siguen estampadas en PEN dentro de una cuenta que ahora
dice USD. A partir de ahí la app da dos respuestas distintas sobre el mismo dinero, y solo una se
mueve con el tipo de cambio.

Nada avisa, nada convierte y no hay vuelta atrás automática.

## Lo medido (2026-09-08)

`Yala/App/ViewModels/Accounts/AccountFormViewModel.swift:372-386`:

```swift
private func applyBaseAccountProperties(to account: Account, trimmedAccountNumber: String) {
    account.name = trimmedName
    account.currencyCode = normalizeCurrencyCode(selectedCurrency.rawValue)   // :374
```

Se usa **también en la ruta de update**, y el selector de divisa es un `NavigationLink` liso, **sin
gate por `isEditing`** (`Yala/App/Views/Accounts/AccountFormView.swift:248-274` — compárese con
`:140` y `:531`, donde otras secciones sí se gatean). No hay ninguna referencia a reestampado,
conversión ni recálculo en ese ViewModel.

Esto lo convierte en **la ruta más productiva de desemparejamientos de la app**: las de creación
producen como mucho una fila; ésta produce el histórico entero de una cuenta de una vez.

## Por qué duele: el sistema asume dos cosas incompatibles a la vez

No es que el resto del código dé por hecho que coinciden. Es que **la mitad se fía de la transacción
y la otra mitad de la cuenta**, y nadie reconcilia:

- **Suman en crudo y rotulan con la divisa de la CUENTA** — `Yala/Utils/AccountBalanceCalculator.swift:81-83`
  (`signedAmount` devuelve `Decimal(item.amount)`, sin leer `currencyCode`). De ahí comen las
  tarjetas del carrusel del Panel (`AccountCardView:88-92`, `:155`), la lista de cuentas de Ajustes
  (`AccountsSettingsListViewModel:145-158`) y los widgets (`WidgetDataCache:422-434`).
- **Leen `tx.currencyCode` y convierten** — `LiveBalanceCalculator:125`,`:130-140` (con la tasa de
  **hoy**), presupuestos (`BudgetsViewModel:645-654`, también tasa de hoy), FX P&L
  (`FXPnLLogic:147-157`), cash flow, top categorías, insights, informes, el pivot «por divisa»
  (`PivotTableCalculator:228-230`), los filtros (`FilterService:279`) y la fila y el detalle
  (`RecordRowView:126`,`:243`).

⇒ La tarjeta de la cuenta y el saldo vivo del Panel enseñan cifras distintas del mismo dinero.

**Y el round-trip de exportación queda roto**: la exportación escribe `transaction.currencyCode`
(`TransactionsExportService:435-437`, `:571-572`) y la importación **rechaza** toda fila cuya divisa
no sea la de la cuenta destino (`TransactionCSVImportService:450-457`, `:689-695`, `:1313-1320`,
`:1619-1625`, `ImportError.currencyMismatchWithAccount`). Yala exporta un fichero que Yala se niega
a importar.

## Lo que NO se midió

- Si el `NavigationLink` de la divisa se puede abrir **de verdad** en modo edición desde la UI (se
  midió que no hay gate en el código; no se ejecutó en simulador).
- **INFERIDO, no medido**: `Yala/Services/CloudSync/EntityApplyMap.swift:158` escribe `currency_code`
  del cable sin contrastarlo con el `account_ref` que resuelve unas líneas más abajo. Si es así,
  propagaría el desemparejamiento al resto de dispositivos, y podría crearlo en el receptor cuando la
  divisa de la cuenta se edita en un device y las transacciones llegan del otro. Hay que medirlo
  antes de decidir nada aquí.

## Criterio de hecho (AC)

- [ ] Decidido qué pasa al cambiar la divisa de una cuenta **con movimientos**: se prohíbe, se
      convierte el histórico, o se avisa con claridad de que los importes no se re-expresan.
- [ ] Si se permite, las cuatro columnas del grupo de coherencia `money` quedan coherentes en cada
      fila tocada (mismo criterio que `bulkUpdateAmount`, que sí recalcula).
- [ ] Test que fije la decisión sobre una cuenta con histórico.
- [ ] Medida la rama de CloudSync de arriba, y con ticket propio si confirma.

## Relacionados

- `bulk-update-account-leaves-converted-amount-stale` — el caso complementario (mover transacciones
  a una cuenta de otra divisa). Su AC nº3 pide barrer «cualquier otra ruta que escriba `currencyCode`
  o `amount` de una transacción ya persistida»; **ésta no cae ahí**, porque aquí nadie escribe la
  transacción: es la cuenta la que cambia debajo.
- `chat-draft-stamps-its-own-currency-not-the-account` — el hueco de creación, ya cerrado.
- `saving-a-mismatched-transaction-relabels-it-without-converting` — qué pasa al abrir en el
  formulario una fila ya desemparejada.
