---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `22cc2cd2` — el saldo de Distribución ya cuadra con el Panel; buscar un grupo
no se atasca; salir de un grupo dice qué pasó. TestFlight build **12** (CPV 12).
**Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva desde el 4-sep.

## Esta sesión, en una línea

**El saldo de Distribución deja de ser el gasto del mes** (PR #78). Abrías el Panel y veías un
saldo; ibas a Estadísticas → Distribución con los mismos filtros y veías otro número.

**La hipótesis del ticket era falsa.** Decía que Distribución «no aplica la transformación entre
monedas»: sí la aplica. Sumaba el **gasto del período** al TC del día de cada movimiento, mientras el
Panel mostraba el **saldo de hoy** al TC actual. Un flujo contra un stock.

**Y el KPI del Panel tiene DOS regímenes, no uno** — esto cambió el diseño: `liveBalanceOverride`
devuelve nil si el período no cubre hoy, y entonces cae al último punto histórico. La lectura literal
de «igualar Balance a stock» habría enseñado el saldo de HOY bajo una etiqueta que dice «Mes pasado».
Se replican los tres casos. También se midió que el Panel tiene **dos** números de balance: se igualó
al del widget de tendencia, el único que responde al selector de período.

**La review adversarial (3 lentes) cazó SEIS defectos que introducía el propio fix** y que los tests
en verde no veían: un `> 0` heredado escondía el hero con saldo negativo; sin movimientos en el
período decía «0» a quien sí tiene saldo; flash de «0» antes del primer cálculo; `isBalanceMode`
colgaba de un flag sin observador; con los DOS chips marcados volvía al flujo; y el `adjustment` de
grupos no viajaba al processor.

**Dos lentes se contradijeron** sobre si el buscador dispara por tecla. Lo zanjó un grep: no lo hace
—es un `@State` local con botón «Aplicar»— y el error ya estaba en un comentario mío.
Está en `.claude/agent-memory/frank/`.

**Perf medido:** el processor construía la curva entera y la descartaba. Con atajo, «Este mes»
21,1 → 14,9 ms y «Todo» 42,8 → 14,8 ms con 5.475 movimientos.

## Te espera a ti

1. **Device-QA multi-moneda del KPI de Balance** (`distribution-balance-kpi-skips-fx`, en `qa`).
   Cuatro pasos escritos en el ticket. **Sin números de aparato no hay PASS.**
2. **Cuatro decisiones de producto**, tres de antes y una nueva:
   - **NUEVA — el número grande de Estadísticas significa dos cosas** según la pestaña: stock en
     Distribución, flujo en Tendencias/Insights/Registros. `TrendsTabView:1193-1203` documenta que
     esa coherencia era **intencional**. Ticket propio: `hero-estadisticas-stock-vs-flujo-entre-pestanas`
     (`blocked`).
   - **El dueño con deuda sigue sin salida** — el bloqueo mira la deuda de todo el grupo, no la suya.
   - **El botón «Más tarde»** de la hoja del invitado. Revertirlo es un commit.
   - **Dos de la web**: el texto legal de Grupos (dice «vía iCloud» y el backend propio está al 100 %
     en prod) y si Vercel debe desplegar al mergear.
3. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Ahora llevaría además el saldo de Distribución, la identidad del recién llegado,
   los predeterminados del Panel, el cierre del detalle, la hoja de «Unirme» y el freno de la lista.
4. **La tanda de QA: 32 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe con una precondición frágil: **B se une por enlace y
   NO relanza la app** antes de que A cree el gasto. `groups-leave-rpc-error-10` necesita el suyo.

## Abiertos

**`in-progress` sigue vacío.** Todo lo vivo espera la tanda de QA, hardware (los **3 de `blocked`**)
o una decisión, no código.

**Cuatro tickets nuevos**, todos de la review adversarial de esta sesión, ninguno bloqueante del PR:
`panel-colapsa-la-seleccion-de-cuentas-a-la-primera` (`.first` sobre un Set, que además no es
estable — la vía conocida por la que Panel y Distribución pueden seguir sin cuadrar),
`el-saldo-de-distribucion-no-se-entera-de-un-registro-nuevo`,
`distribucion-recalcula-dos-veces-por-toque-y-sin-debounce` y
`el-job-de-tests-del-ci-no-tiene-timeout`.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. Hoy volvió a pasar: `displayedBalanceInDefaultCurrency` estaba citada 46
líneas más arriba de donde vive. **Y la premisa del ticket también caduca**: la de hoy era falsa.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**115 tickets · backlog 55 · in-progress 0 · qa 36 · blocked 3 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado».

**El desajuste del índice, CERRADO** (mandato de Jürgen del 6-sep). Llevaba **cuatro sesiones**
señalado sin recontar. Estaba peor de lo que decía la nota: además del ticket ausente y del conteo
`= 96`, había **dos tickets con el status de otra carpeta** (`groups-leave-rpc-error-10`,
`secondary-guest-exit-lock-and-outbox`). `docs/TICKETS.md` regenerado desde el disco y verificado con
control positivo de los tres modos de drift: **Index, filas y Counts = 115 = disco**. El primer
verificador dio un falso positivo por no aceptar mayúsculas en los ids.

**Desde ahora, todo cierre incluye `docs/TICKETS.md`**, y lo que salga de camino lleva ticket propio
en vez de quedarse en el cuerpo del PR.

**El verde del CI no dice que los XCUITest pasaran:** su paso de UI es *advisory*
(`continue-on-error`) y el job sale `success` con fallos dentro. Lo bloqueante es `Build for testing`.
**Medido hoy: un run completo tarda 77-90 min** (4 runs) y **no hay `timeout-minutes` en el workflow**,
así que un cuelgue ocuparía un runner seis horas — ticket propio. El #78 se mergeó con el paso de UI
aún corriendo, tras comprobar que el árbol Swift era **idéntico** (0 líneas de diff) al del commit
cuyo run ya había salido `success`.

**Y ojo con el `CLAUDE.md` de casa:** dice «El CI de GitHub, apagado». Es **falso** — `qa.yml` está
activo y corre en cada push. Medido **cinco** sesiones seguidas.
