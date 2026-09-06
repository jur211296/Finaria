---
id: el-saldo-de-distribucion-no-se-entera-de-un-registro-nuevo
status: backlog
priority: medium
area: statistics
created: 2026-09-06
updated: 2026-09-06
source: hallazgo de la review adversarial de distribution-balance-kpi-skips-fx
---

# Registras un gasto y el saldo de Distribución no cambia

## Qué ve el usuario

Estás en **Estadísticas → Distribución** con la métrica Balance. Abres el botón de añadir, registras
un ingreso de 500 y vuelves. El Panel ya dice 6.500; Distribución sigue diciendo 6.000. Se arregla
solo al cambiar de pestaña o de filtro, pero hasta entonces enseña un saldo que no es el tuyo.

Con editar el **importe** de un movimiento existente es peor: no cambia el número de movimientos, así
que ni siquiera el observador que hay salta.

## Causa

`CategoriesTabView` recalcula en `calculateData()`, y sus disparadores son todos de **filtro**
(período, cuentas, categorías, etiquetas, monedas, importe, búsqueda, chips…). El único que mira los
datos es `.onChange(of: allTransactions.count)` (`:202`) y **solo llama a `recomputeSankey()`**, no a
`calculateData()`.

Esto era tolerable mientras el hero mostraba el **flujo del período**: ese número solo cambia con
movimientos dentro del período y de las categorías visibles, y el resto de la pantalla quedaba rancio
a la vez, así que era coherente consigo mismo. Desde 2026-09-06 el hero muestra un **saldo**, y un
saldo cambia con cualquier movimiento de cualquier fecha y cualquier cuenta. La dependencia se
ensanchó y los disparadores no.

Es la contrapartida que `.claude/rules/swiftui-ds.md` avisa al precalcular en un ViewModel: mover un
cálculo fuera del body corta el live-binding a los `@Model`, y entonces el refresco depende entero de
que todo mutador llegue al recálculo.

## Alcance

`totalAmount` (el flujo) tiene el mismo agujero y es **preexistente** — no se abrió con el cambio del
KPI. Lo que cambió es cuánto se nota.

## Qué mirar al arreglarlo

`DetailContainerView` ya tiene un `.onChange(of: sessionState.dataVersion)` (`:201`) que recarga el
array; el problema es que la pestaña observa `.count` y no el contenido. Y hay un debounce de 150 ms
en el contenedor (`:538-548`) del que `calculateData()` no cuelga, así que atarlo a `dataVersion` sin
más puede recalcular de más — medir antes: el cálculo cuesta ~15 ms con 5.475 movimientos.

## Acceptance Criteria

- [ ] Registrar un movimiento estando en Distribución actualiza el hero sin cambiar de pestaña.
- [ ] Editar el importe de un movimiento existente también.
- [ ] No se recalcula más veces por gesto que ahora (medido, no supuesto).
