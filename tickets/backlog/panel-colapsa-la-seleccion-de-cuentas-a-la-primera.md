---
id: panel-colapsa-la-seleccion-de-cuentas-a-la-primera
status: backlog
priority: medium
area: panel
created: 2026-09-06
updated: 2026-09-06
source: hallazgo de la review adversarial de distribution-balance-kpi-skips-fx
---

# Con dos o más cuentas filtradas, el Panel solo mira la primera

## Qué pasa

El filtro de cuentas es un **conjunto** (`SessionState.selectedAccountIDs`) y la barra de filtros lo
pinta con su cuenta («2 cuentas»). Estadísticas lo respeta entero
(`StatisticsViewModel.computeEligibleAccounts:517-527`). El Panel, en cambio, lo colapsa a su primer
elemento:

```swift
// PanelViewModel.swift:291
var selectedAccountID: PersistentIdentifier? { SessionState.shared.selectedAccountIDs.first }
```

y lo consume en `computeEligibleAccounts` (`:1392`) y en `displayedBalanceInDefaultCurrency`
(`:1056`). O sea: seleccionas A y B, el Panel te enseña solo A — y `.first` sobre un `Set` **no es
estable**, así que ni siquiera es "la primera que tocaste".

## Cómo se llega

No es un estado exótico. `SessionState.toggleAccountFilter` es single-select, pero **no es el único
escritor**: `RecordsFiltersView.accountChip` hace `insert` sin `removeAll` (`:183-191`) y
`commitToViewModel` lo vuelca a la misma clave global (`:677`); y `SessionState.applyBudgetFilters`
escribe el conjunto entero resuelto del presupuesto (`:743`). Tres toques desde Registros → Filtros.

## Por qué sale ahora

Al cerrar `distribution-balance-kpi-skips-fx` (KPI de Balance de Distribución == el del Panel), esta
asimetría se convirtió en la única vía conocida por la que esos dos números pueden seguir sin
cuadrar: con cuentas A=10.000 y B=5.000 seleccionadas, el Panel diría 10.000 y Distribución 15.000.
Queda documentado como límite conocido en aquel ticket y en su PR, sin corregir, porque la decisión
del owner del 2026-08-26 fue **no tocar Panel**.

## Qué hay que decidir antes de arreglarlo

Cuál de los dos comportamientos es el correcto. Si el Panel debe respetar el conjunto, el cambio no
es solo `computeEligibleAccounts`: `displayedBalanceInDefaultCurrency` pasa `selectedAccountID` a
`LiveBalanceCalculator`, que tiene su propia rama de cuenta única con fallback al total
(`LiveBalanceCalculator.swift:66-77`), y `PanelTotalAccountsLogic.accountsForTotal` decide con
`hasSelectedAccount` (`:18-25`). Son cuatro sitios que asumen «una o ninguna».

## Decisión Jürgen (2026-09-06)

**El Panel respeta el conjunto de cuentas, como Estadísticas.** Elegida entre eso y «el Panel es de
una cuenta y con varias muestra el total». Motivo, tal como se le puso delante y ratificó: la barra de filtros dice «2 cuentas» y Distribución ya
suma las dos; que el Panel enseñe una —y no se sepa cuál— es el único camino conocido por el que los
dos saldos siguen sin cuadrar tras `distribution-balance-kpi-skips-fx`. Toca los cuatro sitios que
asumen «una o ninguna» (`selectedAccountID`, `computeEligibleAccounts`,
`displayedBalanceInDefaultCurrency` → `LiveBalanceCalculator`, `PanelTotalAccountsLogic`).

## Acceptance Criteria

- [ ] Con dos cuentas seleccionadas, Panel y Estadísticas muestran el mismo saldo.
- [ ] El toggle `includeGroupsInPanelTotal` sigue aplicando solo al total agregado.
- [ ] Unit que fije el caso de dos cuentas en los dos caminos.
- [ ] Device-QA: seleccionar dos cuentas desde Registros → Filtros y comparar Panel vs Distribución.
