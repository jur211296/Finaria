---
updated: 2026-09-05
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-05 (Lima)

**Rama** `2.1` · HEAD `83958dc6` — borrar un grupo ya no te deja mirándolo; el enlace de invitación no
pierde el nombre del grupo, y la visita en el móvil de otra persona no deja huella en el Yala del dueño.
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web
nueva desde el 4-sep.

## Esta sesión, en una línea

**Borrar un grupo ya no te deja mirándolo** (PR #73). Confirmabas dos veces sobre un aviso que dice
«esta acción es irreversible» y te quedabas delante del mismo grupo, con sus gastos; había que tocar
Atrás para comprobar que la app te había hecho caso. El detalle ya sabía cerrarse solo, pero el
borrado no enciende ninguna de sus señales: no saca la fila del almacén, le pone una marca de oculto.
Esa marca pasa a ser una señal más, y cubre también el borrado que llega desde otro teléfono.

**Lo que desatascó el ticket no fue leer el código, fue compilarlo.** Llevaba parado desde el 28-ago
con un criterio de «antes de tocar código, anota qué pantalla se quedó abierta», y tres hipótesis
declaradas irresolubles porque del device solo había el relato. Compilar el código **anterior** y
repetir el recorrido en el simulador reprodujo el fallo exacto y zanjó cuál era. Coste: 30 s de build.

## Te espera a ti

1. **Publicar la app.** Los dos avisos de Grupos están completos en servidor y en los dos entornos;
   falta el cliente iOS. Ahora llevaría además el fix de identidad del recién llegado, los
   predeterminados del Panel y este cierre del detalle.
2. **La tanda de QA: 28 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe —`group-joiner-flag-consumers-still-narrow`,
   `groups-equal-split-shows-not-participating-on-peer` y `rejoin-tap-renotifies-admins`— con una
   precondición frágil: **B se une por enlace y NO relanza la app** antes de que A cree el gasto. Si
   B relanza, ninguno reproduce. `invite-link-five-causes-one-message` cabe en el mismo montaje
   (tapear el enlace con la app cerrada). Entra hoy `groups-deleted-group-detail-stays-open`: basta
   borrar un grupo sin deuda siendo owner, y repetirlo entrando por deeplink, que es otra pila.
3. **Dos decisiones de la web** (§9 del informe): el **texto legal de Grupos** —dice «vía iCloud, no
   por servidores nuestros» y el backend propio está al 100 % en prod— y si Vercel debe desplegar al
   mergear (hoy su rama de producción es `1.0`).

## Abiertos

**`in-progress` está vacío**: los dos que este documento listaba —`secondary-guest-exit-lock-and-outbox`
y `reentry-counts-as-fresh-install`— ya salieron a `qa`. Todo lo vivo espera la tanda de QA o hardware
(los **2 de `blocked`**), no código.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

110 tickets · backlog 55 · in-progress 0 · qa 32 · blocked 2 · done 16 · discarded 5. `qa` significa
«esperando la tanda», no «cerrado».

**Tres cifras distintas en tres sitios, medido hoy:** el disco tiene 110; `docs/TICKETS.md` dice `= 96`
(con `in-progress 7`, que hoy es 0); este documento venía diciendo 108. Y
**`rojo-heroBuckets-thisWeek-trailing-window` está en disco sin fila** en el índice. Nadie lo ha
recontado entero — hoy se tocó solo la fila del ticket de la sesión, para no ampliar alcance.

**El verde del CI no dice que los XCUITest pasaran:** su paso de UI es *advisory* y el job sale
`success` con fallos dentro. Hoy fueron **3**, y son **subconjunto** de los 5 que falla `2.1` sin
cambio alguno — comparados nombre a nombre contra el run de `cb74daba`, cero regresiones. Dos flaky de
la base (`BudgetAlertsConfigUITests`, `QuickActionsFavoritesUITests`) hasta pasaron esta vez: el eje es
el runner frío, no el código. Uno de los tres tiene causa escrita en
`uitest-compara-fechas-sin-fijar-locale`.

**Y ojo con el `CLAUDE.md` de casa:** dice «El CI de GitHub, apagado». Es **falso** — `qa.yml` está
activo y corre en cada push. Medido esta sesión.
