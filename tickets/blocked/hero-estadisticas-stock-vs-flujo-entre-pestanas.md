---
id: hero-estadisticas-stock-vs-flujo-entre-pestanas
status: blocked
priority: medium
area: statistics
created: 2026-09-06
updated: 2026-09-06
source: hallazgo de la review adversarial de distribution-balance-kpi-skips-fx
---

# El número grande de Estadísticas significa una cosa en Distribución y otra en las demás pestañas

**Bloqueado por una decisión de producto de Jürgen. No hay trabajo técnico que hacer hasta que
responda.**

## Qué pasa

Las cuatro pestañas de Estadísticas comparten el mismo hueco visual: el mismo selector de período,
los mismos tokens tipográficos (`heroAmount`/`heroAmountSecondary`), el mismo padding. Y se deslizan
entre sí. Desde el cierre de `distribution-balance-kpi-skips-fx` (2026-09-06), con el mismo período y
los mismos filtros, ese hueco muestra dos cosas distintas:

| Pestaña | Qué muestra su hero | Naturaleza |
|---|---|---|
| **Distribución** | Saldo de las cuentas | **stock** |
| Tendencias | `summary.netBalance` — ingresos − gastos del período (`TrendsTabView.swift:1199`) | flujo |
| Insights | `summary.netBalance` — lo mismo (`InsightsTabView.swift:207`) | flujo |
| Registros | `recordsSummary.balance` — neto de lo filtrado (`RecordsTabView.swift:148`) | flujo |

## Por qué esto necesita una decisión y no un fix

**El código documenta que la coherencia entre pestañas era intencional.**
`TrendsTabView.swift:1193-1203` dice, literalmente:

> «KPI period-specific para el hero (matches `InsightsTabView.heroSummary`). Distinto de
> `currentKPIValue` que para `.balance` retorna el running balance final del chart (global, no
> responde al período). El hero usa el agregado del período **para coherencia cross-tab**.»

O sea: alguien ya se planteó poner el saldo global en el hero y decidió no hacerlo, por esta razón
exacta. La decisión del 2026-08-26 —igualar el KPI de Distribución al del Panel— es posterior y se
tomó comparando **Panel contra Distribución**, no Distribución contra sus tres hermanas. El Panel no
está en esta pantalla; las otras tres sí, y se deslizan.

Las dos posturas son defendibles y por eso no la tomo yo:

- **Dejarlo como está.** Distribución cuadra con el Panel, que es lo que el owner vio y pidió. La
  incoherencia entre pestañas es el precio, y quizá nadie la nota porque cada pestaña se lee sola.
- **Igualar las cuatro.** Sea a stock (y entonces hay que revisar qué significa en Tendencias, cuya
  gráfica es de flujo) o a flujo (y entonces se revierte lo que el owner pidió).
- **Etiquetar el número.** Ninguna de las cuatro dice qué es la cifra. Un rótulo bajo el hero
  resolvería la ambigüedad sin cambiar ningún cálculo — pero es diseño, y toca las cuatro pantallas.

## Qué NO es

No es un bug de cálculo: los cuatro números son correctos para lo que cada uno mide. No es
`trends-comparison-kpi-vs-curve`, que va de KPI contra curva dentro de Comparativa.

## Acceptance Criteria

- [ ] Jürgen decide: dejarlo, igualar las cuatro, o etiquetar.
- [ ] Si toca cambiar algo, el cambio va con device-QA de las cuatro pestañas deslizando con el
      mismo período.
