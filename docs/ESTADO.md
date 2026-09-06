---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `19533bc7` — salir de un grupo ya no falla con un número; el enlace de
invitación no te mete en el grupo a escondidas; borrar un grupo no te deja mirándolo. TestFlight
build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva
desde el 4-sep.

## Esta sesión, en una línea

**Salir de un grupo dice qué pasó, y el dueño deja de quedarse sin salida** (PR #75). El alert era
«No se ha podido completar la operación. (Error de Yala.GroupsRPCError 10.)»: un número, sin
explicación y sin nada que hacer. Y ese teléfono tampoco podía **borrar** el grupo, que era lo que
venía a hacer: no podía salir y no podía borrar.

**La premisa del ticket —y la del encargo— era falsa, y medirla costó un script.** Los dos daban
por seguro que el 10 era `channelDisabled`, el kill-switch del canal, **contando casos en el
fichero**. El tag que Foundation imprime **no sigue el orden de declaración**: Swift coloca primero
los casos CON payload. En el enum del build 12 el 10 era **`ownerCannotLeave`** — el servidor le
dijo a ese teléfono «eres el dueño, no puedes salir».

Con la premisa buena, **las dos «caras» que el ticket separaba eran el mismo defecto**, y la que
descartó explícitamente como causa («el agujero de UX, y NO la causa del error 10») resultó serlo.
La raíz: `SplitGroup.isOwner` es device-local, lo escribe solo quien crea el grupo y el pull nunca
lo actualiza ⇒ la pantalla decidía con un flag que el servidor contradecía.

**La review adversarial cazó seis defectos que introducía el propio fix**, dos de ellos peores que
el bug: el reconciliador se convertía en una cárcel (tras el primer rechazo el guard local cortaba
todo intento futuro, y ningún pull reabre ese flag), y un `save()` fallido dejaba el flag vivo en
memoria con la UI ya ofreciendo una acción irreversible sobre un dato que no estaba en disco.
Detalle en `tickets/qa/groups-leave-rpc-error-10.md`.

## Te espera a ti

1. **Dos decisiones de producto de Grupos**, las dos pequeñas y reversibles:
   - **El dueño con deuda sigue sin salida** (nuevo). «Eliminar» se deshabilita con deuda, y el
     bloqueo mira la deuda de **todo el grupo**, no la suya: puede quedar atascado por una deuda
     entre otras dos personas, con un aviso que le pide liquidar deudas ajenas. Opciones: ofrecer
     «transferir y salir» (el RPC ya existe, falta UI), permitir eliminar con deuda como ya se
     permite salir con deuda, o dejarlo así.
   - **El botón «Más tarde» de la hoja del invitado**, solo para quien ya tiene la app montada.
     **Revertirlo es un commit** y nada depende de ello.
2. **Publicar la app.** Los dos avisos de Grupos están completos en servidor y en los dos entornos;
   falta el cliente iOS. Ahora llevaría además la identidad del recién llegado, los predeterminados
   del Panel, el cierre del detalle, la hoja de «Unirme» y esto.
3. **La tanda de QA: 30 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe —`group-joiner-flag-consumers-still-narrow`,
   `groups-equal-split-shows-not-participating-on-peer` y `rejoin-tap-renotifies-admins`— con una
   precondición frágil: **B se une por enlace y NO relanza la app** antes de que A cree el gasto.
   `invite-link-five-causes-one-message` y `groups-invite-skips-unirme-sheet-if-onboarded` caben en
   el mismo montaje. **`groups-leave-rpc-error-10` necesita el suyo**: reproducir el rechazo por
   ownership y comprobar que el mensaje se entiende y que «Eliminar grupo» aparece después.
4. **Dos decisiones de la web** (§9 del informe): el **texto legal de Grupos** —dice «vía iCloud, no
   por servidores nuestros» y el backend propio está al 100 % en prod— y si Vercel debe desplegar al
   mergear (hoy su rama de producción es `1.0`).

## Abiertos

**`in-progress` sigue vacío.** Todo lo vivo espera la tanda de QA o hardware (los **2 de `blocked`**),
no código.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. Y **la premisa medida también caduca**: hoy volvió a pasar, esta vez en el
propio encargo, que afirmaba como hecho lo que el ticket marcaba como inferencia sin comprobar.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

110 tickets · backlog 53 · in-progress 0 · qa 34 · blocked 2 · done 16 · discarded 5. `qa` significa
«esperando la tanda», no «cerrado».

**Sigue el desajuste de conteos**, sin recontar: el disco tiene 110 y `docs/TICKETS.md` dice `= 96`
(con `in-progress 7`, que hoy es 0). Y **`rojo-heroBuckets-thisWeek-trailing-window` está en disco sin
fila** en el índice. Van **tres** sesiones seguidas dejándolo dicho y tocando solo la fila del ticket
propio para no ampliar alcance.

**El verde del CI no dice que los XCUITest pasaran:** su paso de UI es *advisory* (`continue-on-error`)
y el job sale `success` con fallos dentro. Lo bloqueante de verdad es `Build for testing`. En el PR #75
se esperaron los **cinco** checks en verde antes de mergear, `tests` incluido — tardó **1 h 25 min**.

**Y ojo con el `CLAUDE.md` de casa:** dice «El CI de GitHub, apagado». Es **falso** — `qa.yml` está
activo y corre en cada push. Medido **tres** sesiones seguidas.
