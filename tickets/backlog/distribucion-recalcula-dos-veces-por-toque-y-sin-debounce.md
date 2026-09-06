---
id: distribucion-recalcula-dos-veces-por-toque-y-sin-debounce
status: backlog
priority: low
area: statistics
created: 2026-09-06
updated: 2026-09-06
source: hallazgo de la review adversarial de distribution-balance-kpi-skips-fx
---

# Distribución recalcula dos veces por toque, y es la única pestaña sin freno

## Dos cosas, las dos medidas por lectura de código (no cronometradas en aparato)

**1. Doble invocación por chip de naturaleza.** `viewModel.selectedTransactionNatures` es un proxy
puro de `SessionState.shared.selectedTransactionNatures`
(`StatisticsViewModel.swift:104-107`). `CategoriesTabView` observa **el mismo almacenamiento dos
veces**: en `CategoriesFilterRecalcObservers` (`:2059`, vía `viewModel`) y en el body (`:224`, vía
`sessionState`). Un toque en el chip corre `calculateData()` **dos veces**.

Y el chip es justo lo que conmuta el modo Balance, así que desde 2026-09-06 el trabajo que se duplica
incluye el cálculo del saldo (~15 ms con 5.475 movimientos).

**2. Es la única superficie de la pantalla sin debounce.** El contenedor tiene uno de 150 ms
(`DetailContainerView.swift:538-548`) y la pestaña hermana el suyo de 200 ms
(`TrendsTabView.scheduleTrendsRecalc`, `:1242`, usado en sus 13 observadores).
`CategoriesTabView` llama `calculateData()` **síncrono en sus 17**. Hay dos patrones ya establecidos
en la misma carpeta que este fichero no adopta.

## Lo que NO es

**No es el bug del buscador del PR #77.** Se comprobó: el campo de nota de esta pantalla es un
`@State` local de `RecordsFiltersView` (`:41`, `TextField` en `:511`) que solo se vuelca al ViewModel
en `commitToViewModel()` (`:685`), colgado del botón «Aplicar». **No hay escritura por tecla**, y no
existe ningún `.searchable` en `Yala/App/Views/Statistics/`. El coste se paga por toque, no por
pulsación — por eso esto es `low` y no `high`.

## Deuda adyacente encontrada de camino (no urge, pero está medida)

- `TrendDataProcessor` calcula `totalIncome`/`totalExpense` para la métrica `.balance`, que los
  descarta.
- `movingAverage` (`TrendProcessingHelper.swift:29-51`) corre en `.thisYear`/`.lastYear`/`.allTime`
  con un `.sorted()` sobre datos ya ordenados y una asignación en heap por punto — y su resultado
  (`chartPoints`) no lo lee quien solo quiere `finalBalance`. Desde el atajo de
  `BalanceKPICalculator` esto solo afecta a los períodos cerrados.
- `StatisticsViewModel.currentBalance` (`:196`) **no lo lee ninguna vista** (único lector:
  `StatisticsViewModelTests:44`), y `totalMetricValue` (`:217`) no lo lee nadie en absoluto. Dos
  candidatos a borrar.

## Acceptance Criteria

- [ ] Un toque en el chip de naturaleza dispara un solo recálculo.
- [ ] Medido antes y después, en aparato o simulador con datos realistas — no por lectura de código.
