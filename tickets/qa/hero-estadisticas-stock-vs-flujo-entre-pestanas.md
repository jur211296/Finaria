---
id: hero-estadisticas-stock-vs-flujo-entre-pestanas
status: qa
priority: medium
area: statistics
created: 2026-09-06
updated: 2026-09-07
source: hallazgo de la review adversarial de distribution-balance-kpi-skips-fx
---

# El número grande de Estadísticas significa una cosa en Distribución y otra en las demás pestañas

**Desbloqueado el 2026-09-06: Jürgen decidió. Ver «Decisión Jürgen» abajo. Estuvo en `blocked/` desde
su alta el mismo día (PR #78).**

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

## Decisión Jürgen (2026-09-06)

**Etiquetar el número.** Elegida entre las tres salidas de arriba, presentadas con su coste cada una.
El motivo, tal como se le puso delante y ratificó: es la única salida que **no revierte** lo que él
mismo pidió el 26-ago (Distribución cuadra con el Panel) y **no cambia ningún cálculo** — los cuatro
números son correctos para lo que miden; lo que falta es decir cuál es cada uno. Descartó «dejarlo»
(la incoherencia se queda), «igualar a flujo» (revierte el 26-ago) e «igualar a stock» (un saldo
global sobre la gráfica de flujo de Tendencias no significa nada).

Lo que implica: un rótulo bajo el hero en las **cuatro** pestañas —del estilo «Saldo de cuentas» en
Distribución y «Neto del período» en Tendencias, Insights y Registros—, copy nuevo en los 16 `.lproj`
(leer `BRAND-VOICE.md`), y ningún cambio en `TrendsTabView`/`InsightsTabView`/`RecordsTabView` más allá
del rótulo. El comentario de `TrendsTabView.swift:1193-1203` («coherencia cross-tab») queda desfasado y
hay que reescribirlo para que diga la coherencia nueva: mismo hueco, cifra distinta, **rotulada**.

## Acceptance Criteria

- [x] Jürgen decide: dejarlo, igualar las cuatro, o etiquetar → **etiquetar** (2026-09-06).
- [x] Las cuatro pestañas de Estadísticas llevan un rótulo bajo el hero que dice qué es la cifra.
      **Con una corrección medida sobre el AC original** — ver «La premisa del AC era falsa» abajo:
      el rótulo NO es fijo por pestaña, se deriva del estado que elige el número.
- [x] Copy en los 16 `.lproj`; paridad verde (11/11 `LocalizationParityTests`, cero
      `[NEEDS_TRANSLATION]`, alias `es`/`pt` byte-a-byte con su base).
- [x] Ningún cálculo cambia: no se tocó ningún `value:` de los cuatro `AmountText` ni ningún
      calculador. El diff sobre `Yala/` es un `Text` nuevo por vista + un fichero de lógica pura.
- [x] El comentario de `TrendsTabView.swift` que justificaba el hero por «coherencia cross-tab» se
      reescribe: ya no describe lo que hay. Fijado por test para que no vuelva.
- [ ] Device-QA de las cuatro pestañas deslizando con el mismo período (**es lo único que falta**).

## La premisa del AC era falsa, y un rótulo fijo habría mentido en pantalla

El AC pedía «Distribución nombra un saldo de cuentas, los otros tres un neto del período». Medido el
2026-09-07 contra el árbol, **ninguna de las cuatro cifras es siempre la misma magnitud**:

| Pestaña | Estado | Qué muestra | Rótulo |
|---|---|---|---|
| Distribución | `isBalanceMode` | saldo de cuentas (stock) | Saldo de cuentas |
| Distribución | filtro de categoría · solo-gastos · un chip | flujo del período | Gastos/Ingresos del período |
| Distribución | los dos chips + filtro dimensional | magnitudes sumadas (`abs`) | Total del período |
| Tendencias | `.balance` / `.income` / `.expense` | uno de tres | Neto / Ingresos / Gastos |
| Insights | siempre | `netBalance` | Neto del período |
| Registros | sin chip de naturaleza | neto de lo filtrado | Neto del período |
| Registros | con un chip | un solo lado (el otro es 0) | Ingresos/Gastos del período |

Las dos fuentes que lo prueban, citadas del árbol de esta rama:

- `CategoriesTabView.swift:102-103` — «Solo alimenta el hero cuando `isBalanceMode`; en
  Ingresos/Gastos el hero **sigue mostrando el flujo del período** (`totalAmount`)».
- `qa/coverage-index.json`, área `statistics` — «Ingresos/Gastos siguen siendo flujo (**decisión del
  owner 2026-08-26**)».

O sea: rotular Distribución fijo como «Saldo de cuentas» habría contradicho una decisión del owner
del 26-ago en los estados más frecuentes de esa pestaña. Y un rótulo que miente es peor que ningún
rótulo — sería el mismo defecto del ticket, agravado. **No se repreguntó porque no hay decisión nueva
que tomar**: la decisión del 6-sep es «etiquetar el número», y rotular el número que de verdad se
pinta es cumplirla, no ampliarla.

## Qué se hizo

- `StatsHeroCaptionLogic` (nuevo, lógica pura sin `L10n`, como `DistributionInsightLogic`): cinco
  casos y una derivación por pestaña desde las señales que ya existían (`isBalanceMode`,
  `selectedMetric`, `selectedTransactionNatures`).
- Un `Text` bajo el `AmountText` en las cuatro vistas, con el patrón del repo
  (`subheadline` + `.secondary`), identificador `stats_hero_caption` para el device-QA.
- Cinco keys nuevas en los 16 `.lproj` vía `qa/scripts/add-l10n-key.sh`, traducidas a los 10 idiomas
  base + las 4 variantes. **Trampa que mordió**: el script regenera los alias `es`/`pt` por copia al
  final, así que traducir `pt-BR` después dejaba `pt` con el marcador — hay que re-correr el script
  para re-sincronizar (es idempotente).
- Tests: 10 de derivación + 5 de cableado por source-scan. El source-scan existe porque cablear el
  rótulo a un valor fijo deja la suite entera en verde, que es el bug del ticket; mismo compromiso
  que `ApproximateMarkWiringTests`. **Control positivo por mutación**: cablear Distribución a
  `natures: []` y devolver el comentario viejo a `TrendsTabView` pone rojos exactamente esos 2 tests
  y deja verdes los otros 3.

## Lo que falta (device-QA)

Recorrer las cuatro pestañas deslizando con el mismo período y comprobar que el rótulo cambia con el
estado, no solo con la pestaña. Los casos que importan, porque son los que un rótulo fijo pasaba:

1. Distribución sin filtros → «Saldo de cuentas»; poner el chip de Gastos → «Gastos del período».
2. Distribución con un filtro de categoría → deja de decir saldo.
3. Tendencias cambiando la métrica entre Balance / Ingresos / Gastos → el rótulo sigue a las tres.
4. Registros tocando los chips de ingresos/gastos → deja de decir «Neto del período».
5. Deslizar entre las cuatro con el mismo período: el hueco es el mismo y cada cifra dice qué es.
