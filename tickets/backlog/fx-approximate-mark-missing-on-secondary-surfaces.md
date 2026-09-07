---
id: fx-approximate-mark-missing-on-secondary-surfaces
status: backlog
priority: medium
area: currency
created: 2026-09-06
updated: 2026-09-06
source: review adversarial de fx-presentation-still-shows-1to1 (2026-09-06)
---

# La marca de aproximado llega a los cuatro totales grandes, no a los demás

## Qué le pasa al usuario

Desde `fx-presentation-still-shows-1to1` el número grande del Panel, el de Tendencias, el de
Estadísticas y el saldo del panorama avisan con «≈» cuando alguna tasa no era la del día. **Otras
pantallas pintan los MISMOS importes sin la marca**, así que el usuario ve el mismo dinero declarado
aproximado en una pantalla y exacto en la de al lado.

## Dónde, medido el 2026-09-06

| superficie | fichero:línea | de dónde sale el número |
|---|---|---|
| «¿Cuánto tienes hoy?» | `BalanceLiveAnchorEducationSheet.swift:66` | `LiveBalanceCalculator` — **la peor omisión: esa hoja existe justo porque el saldo es multimoneda** |
| KPI de Distribución | `CategoriesTabView.swift:353` | `BalanceKPICalculator`, que tira la señal |
| Registros | `RecordsTabView.swift:144` | `RecordsViewModel:315`, suma `amountInPreferredCurrency` |
| Promedio diario | `InsightsTabView.swift:546` | derivado de `cashFlow.totalExpense` |
| Flujo de caja | `CashFlowWidget.swift:350` y `:428` | **el `CashFlowSummary` que YA trae la señal** — el más barato |
| Widget de inicio | `WidgetDataCache.swift:729` | `WidgetPeriodSummary` **no tiene el campo**: no está a `false`, está ausente |
| Asistente | `FullFinancialContextBuilder.swift:404` | descarta la señal al construir su resumen |

## Por qué quedó fuera y no es un olvido

El AC del ticket original nombraba cuatro superficies y ésas están cubiertas. Llevar la señal hasta
la hoja del saldo vivo exige atravesar `TrendDataProcessor` y los dos ViewModels —es núcleo con
suite propia—, y el widget tiene decisión aparte pendiente (`fx-widget-drops-missing-currency`).

**Rastro dejado a propósito**: `LiveAnchorInfo` NO lleva la señal. Se le añadió y se retiró en la
misma sesión al medir que nadie la leía; un campo que nadie lee parece cobertura en una auditoría
posterior y no lo es. El motivo está escrito en su docblock.

## Criterio de hecho (AC)

- [ ] Las superficies de la tabla llevan la marca, o queda escrito por qué una no debe llevarla.
- [ ] `CashFlowWidget` primero: su summary ya trae la señal y es un `isEstimate:` de una línea.
- [ ] Un source-scan que falle si una de ellas pierde el cableado, al molde de
      `ApproximateMarkWiringTests`.

## No confundir con

- `fx-manual-writes-seal-approximate-as-final` (high) — por qué la señal **se enciende menos de lo
  que debería** en cualquier superficie.
- `fx-widget-drops-missing-currency` — el widget omite la divisa en vez de marcarla; es otra decisión.
