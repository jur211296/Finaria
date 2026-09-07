---
id: fx-manual-writes-seal-approximate-as-final
status: backlog
priority: high
area: currency
created: 2026-09-06
updated: 2026-09-06
source: hallazgo de camino en fx-presentation-still-shows-1to1 (2026-09-06)
---

# Diez escrituras sellan como definitiva una tasa que fue aproximada

## Qué le pasa al usuario

Crear una transacción a mano —el flujo principal de la app— guarda el monto convertido y lo marca
como **definitivo**, aunque la tasa que se usó no fuera la del día. Si ese día a la fila de tasas le
faltaba la divisa, el converter baja al escalón siguiente (fila anterior real, o tabla estática) y
devuelve un número **aproximado**. La transacción se sella con `isExchangeRateProvisional = false`, y
el reparador —cuyo `#Predicate` es `== true` (`TransactionUpdateService.swift:96`)— **no vuelve a
mirarla nunca**. El número aproximado se queda para siempre, viaja por la nube y alimenta informes.

## Por qué esto no lo cerró `fx-partial-rate-rows-silent-1to1`

Aquel ticket arregló el converter y el **punto de paso** de la escritura:
`TransactionItem.recalculatePreferredCurrency` (24 llamadas) más las cuatro rutas del import CSV.
Los diez sitios de abajo **no pasan por ese punto de paso**: llaman a `CurrencyConverter.convert(...)`
—que devuelve `Decimal` a secas y tira la calidad— y escriben `amountInPreferredCurrency`,
`exchangeRate` y `preferredCurrencyCode` a mano, sin tocar el flag.

## Medido el 2026-09-06 (worktree de `fx-presentation-still-shows-1to1`, HEAD `6d87123e`)

Las doce escrituras a `amountInPreferredCurrency` en `Yala/`; **diez** son escritura a mano con
`convert` a ciegas y ninguna fija `isExchangeRateProvisional`:

| fichero:línea | flujo |
|---|---|
| `NewTransactionViewModel.swift:645` | crear/editar transacción (**flujo principal**) |
| `NewTransactionViewModel.swift:730` | transferencia, pata de salida |
| `NewTransactionViewModel.swift:745` | transferencia, pata de entrada |
| `DraftService.swift:245` | aprobar borrador de liquidación de grupo |
| `DraftService.swift:314` | aprobar borrador genérico |
| `DraftService.swift:446` | aprobación masiva de borradores |
| `DraftService.swift:738` | aprobar gasto de grupo con cuenta |
| `DraftService.swift:926` | aprobar opt-in personal de liquidación |
| `InboxDraftEditSheet.swift:970` | editar y aprobar desde Inbox |
| `CurrencyChangeService.swift:77` | cambio de moneda preferida (**reescribe TODO el histórico**) |

Las otras dos no son el bug: `TransactionItem.swift:175` es el init (recibe el flag como parámetro) y
`CloudSyncReconciler.swift:101` copia del ganador, junto al flag (`:104`).

**El caso de `CurrencyChangeService` es el peor de los diez**: reescribe en bucle transacciones ya
persistidas sin tocar el flag, así que puede **degradar** a aproximada una transacción que sí estaba
marcada como provisional, quitándole la ruta de auto-cura que tenía.

**El grep que mide esto falla si se escribe ingenuamente**: seis de las diez asignaciones están
partidas en dos líneas, y `grep "\.amountInPreferredCurrency = "` (con espacio) devuelve seis, no
doce. El patrón que mide es `"\.amountInPreferredCurrency\s*="`.

## Criterio de hecho (AC)

- [ ] Los diez sitios usan `convertChecked` y fijan `isExchangeRateProvisional = !quality.isExact`.
- [ ] `CurrencyChangeService` no baja el flag de una transacción que ya lo tenía en alto.
- [ ] Un test por familia (creación, transferencia, borrador, cambio de preferida) con una fila de
      tasas a la que le falte la divisa: la transacción nace marcada.
- [ ] Barrido con control positivo: ninguna escritura de `amountInPreferredCurrency` fuera del init y
      del reconciler deja el flag sin decidir.

## No confundir con

- `fx-partial-rate-rows-silent-1to1` (en `qa/`) — el converter y el punto de paso, ya arreglados.
- `fx-presentation-still-shows-1to1` — que el número **mostrado** declare que es aproximado.
