---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `5ef94c1f` — buscar un grupo ya no se atasca; salir de un grupo dice qué
pasó; el enlace de invitación no te mete a escondidas. TestFlight build **12** (CPV 12).
**Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva desde el 4-sep.

## Esta sesión, en una línea

**La lista de Grupos deja de rehacer las deudas en cada tecla** (PR #77). Cada letra del buscador
recalculaba quién le debe a quién en **todos** los grupos, incluidos los que no caben en pantalla:
`searchText` vive en el ViewModel e invalidaba el body, y el `VStack` no perezoso reconstruía todas
las tarjetas. **Perfilado por primera vez** —el ticket avisaba de que no había una sola medida de
tiempo—: **29,74 ms por tecla** con 30 grupos × 6 miembros × 50 gastos, contra los 16,7 ms de un
frame. Ahora 0,014 ms.

**El ticket señalaba al cuadrático de simplificación y no era**: con `simplifyDebts` encendido
cuesta 25,3 ms y apagado 24,8. Lo caro es recorrer gastos × repartos, que corre siempre.

**La review adversarial (3 lentes) cazó un defecto que introducía el propio fix**: el `LazyVStack`
cancelaba el `.task` de 10 s con que el aviso de la lista se auto-descarta —su `catch` es un noop—,
así que bajar por la lista lo dejaba sin retirarse. Se arregló dejando resumen y nudge fuera del
contenedor perezoso.

**Y hay una contrapartida, escrita en `.claude/rules/swiftui-ds.md`:** precalcular corta el
live-binding a los `@Model`, y `pullUntilExhausted` tiene salidas tempranas que no bumpean
`dataVersion` con páginas ya guardadas. Se cierra en el siguiente `onAppear`; el arreglo está en el
canal de sync y pide dos aparatos.

## Te espera a ti

1. **Dos decisiones de producto de Grupos**, las dos pequeñas y reversibles:
   - **El dueño con deuda sigue sin salida.** «Eliminar» se deshabilita con deuda, y el bloqueo mira
     la deuda de **todo el grupo**, no la suya: puede quedar atascado por una deuda entre otras dos
     personas. Opciones: «transferir y salir» (el RPC ya existe, falta UI), permitir eliminar con
     deuda como ya se permite salir, o dejarlo así.
   - **El botón «Más tarde» de la hoja del invitado**, solo para quien ya tiene la app montada.
     **Revertirlo es un commit** y nada depende de ello.
2. **Publicar la app.** Los dos avisos de Grupos están completos en servidor y en los dos entornos;
   falta el cliente iOS. Ahora llevaría además la identidad del recién llegado, los predeterminados
   del Panel, el cierre del detalle, la hoja de «Unirme» y el freno de la lista.
3. **La tanda de QA: 31 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe —`group-joiner-flag-consumers-still-narrow`,
   `groups-equal-split-shows-not-participating-on-peer` y `rejoin-tap-renotifies-admins`— con una
   precondición frágil: **B se une por enlace y NO relanza la app** antes de que A cree el gasto.
   `invite-link-five-causes-one-message` y `groups-invite-skips-unirme-sheet-if-onboarded` caben en
   el mismo montaje. **`groups-leave-rpc-error-10` necesita el suyo.** Nuevo:
   **`groups-tab-missing-panel-perf`** — con muchos grupos, comprobar que teclear no se atasca y que
   el aviso de la lista sigue retirándose solo a los 10 s aunque se haga scroll.
4. **Dos decisiones de la web** (§9 del informe): el **texto legal de Grupos** —dice «vía iCloud, no
   por servidores nuestros» y el backend propio está al 100 % en prod— y si Vercel debe desplegar al
   mergear (hoy su rama de producción es `1.0`).

## Abiertos

**`in-progress` sigue vacío.** Todo lo vivo espera la tanda de QA o hardware (los **2 de `blocked`**),
no código.

Del ticket de perf quedan **dos puntos sin tocar**, a propósito: `GroupSettingsView` recalcula la
deuda en cada `dataVersion` **sin freno** (mismo patrón que este ticket quitó de la lista, en una
vista que su tabla nunca listó), y la **validación cruzada del coalescing** sigue pidiendo dos
aparatos.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. Hoy volvieron a derivar tres del propio ticket de perf. Y **la premisa
medida también caduca**: el cuadrático que este ticket señalaba como sospechoso no lo era.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

110 tickets · backlog 52 · in-progress 0 · qa 35 · blocked 2 · done 16 · discarded 5 *(contados en
disco hoy)*. `qa` significa «esperando la tanda», no «cerrado».

**Sigue el desajuste de conteos**, sin recontar: el disco tiene 110 y `docs/TICKETS.md` dice `= 96`
(con `in-progress 7`, que hoy es 0). Y **`rojo-heroBuckets-thisWeek-trailing-window` está en disco sin
fila** en el índice. Van **cuatro** sesiones seguidas dejándolo dicho y tocando solo la fila del
ticket propio para no ampliar alcance.

**El verde del CI no dice que los XCUITest pasaran:** su paso de UI es *advisory* (`continue-on-error`)
y el job sale `success` con fallos dentro. Lo bloqueante de verdad es `Build for testing`. En el PR #75
se esperaron los cinco checks antes de mergear — tardó **1 h 25 min**. El **#77 se mergeó a la 1 h 20**
con ese paso aún corriendo y los bloqueantes en verde: los dos de unit del CI ya habían pasado y las
mismas suites de UI se habían corrido en local (23 tests, 8 suites, 0 fallos).

**Y ojo con el `CLAUDE.md` de casa:** dice «El CI de GitHub, apagado». Es **falso** — `qa.yml` está
activo y corre en cada push. Medido **cuatro** sesiones seguidas.
