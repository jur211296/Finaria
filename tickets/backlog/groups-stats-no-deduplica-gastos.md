---
id: groups-stats-no-deduplica-gastos
status: backlog
priority: medium
area: "groups, stats"
created: 2026-09-07
updated: 2026-09-07
source: hallazgo de la review adversarial de groups-budget (2026-09-07)
---

# Estadísticas del grupo no deduplica los gastos, y ahora se contradice con la barra de presupuesto

## Qué ve el usuario

Dos números distintos para lo mismo, en la misma pantalla y a un tap de distancia. En un grupo con un
gasto duplicado de S/ 400 y un presupuesto de S/ 3.000:

- pestaña **Registros** → «S/ 2.100 de S/ 3.000»
- pestaña **Estadísticas** → «Total gastado: S/ 2.500»

La que está mal es la de Estadísticas.

## Por qué pasa

`GroupStatsViewModel.periodExpenses` agrupa y suma sobre `GroupDetailViewModel.expenses` **tal cual**,
sin deduplicar por `id`. Todos sus vecinos sí lo hacen, con el mismo molde
(`Dictionary(grouping:by:\.id).values.compactMap(\.first)`):

| | dedup por `id` | excluye `isOpeningBalance` |
|---|---|---|
| `GroupBalanceService.calculateBalances` | sí | no (usa otro filtro) |
| `GroupShareableSummaryLogic` | sí | sí |
| `GroupBudgetLogic.progress` (nuevo) | sí | sí |
| **`GroupStatsViewModel.periodExpenses`** | **NO** | sí |

Los duplicados llegan por merges del canal de sync; es la misma premisa que justifica el dedup en los
otros tres, y está escrita en `GroupBalanceService`.

## Por qué se abre AHORA si es preexistente

Porque hasta ahora nadie ponía las dos cifras a la vista a la vez. Con la barra de presupuesto en
Registros, el mismo grupo enseña dos totales que se contradicen — y eso deja de ser deuda silenciosa
para convertirse en algo que un usuario reporta.

## Qué hacer

Deduplicar en `GroupStatsViewModel.periodExpenses`, con el mismo molde que los otros tres, y un test que
muera si se revierte (el de `GroupBudgetLogicTests.duplicadosPorIdNoInflanElTotal` sirve de plantilla).

**No se hizo en `groups-budget` a propósito**: ese ticket tenía alcance «un límite por grupo», y tocar el
cálculo de otra pantalla es ampliar a otro objeto. Se abre aparte, que es donde se decide con su propio
device-QA.
