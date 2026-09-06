---
updated: 2026-09-05
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-05 (Lima)

**Rama** `2.1` · HEAD `fa9b9b88` — el enlace de invitación ya no te mete en el grupo a escondidas;
borrar un grupo no te deja mirándolo; la visita en el móvil de otra persona no deja huella en el Yala
del dueño. TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe`
sirve la web nueva desde el 4-sep.

## Esta sesión, en una línea

**La hoja de «Unirme» aparece siempre al abrir un invite** (PR #74). Antes, si ya tenías cuenta,
tocabas el enlace y Yala no te preguntaba nada: ni de qué grupo se trataba, ni con qué nombre te iban
a ver, ni un «sí». Descubrías por tu cuenta que ya estabas dentro. Y unirte a un grupo ya no te toca
nada tuyo: ni nombre de perfil, ni moneda, ni periodo, ni cómo ves la app en tus otros dispositivos.

**La señal era un PROXY, y ese es el patrón que conviene recordar.** El corte preguntaba
«¿tiene cuenta?» y funcionaba solo para el invitado nuevo, porque la propia hoja marcaba su alta al
terminar — así que «ya está dado de alta» acababa significando «ya pasó por aquí». La pregunta real
siempre fue la segunda. Es el mismo arreglo que `hasSeenEducational` frente a `onboardingMode`:
sustituir un testigo prestado por el hecho que se quería medir.

**Y la review adversarial cazó cuatro defectos que introducía el propio fix**, ninguno visible en un
grep: confirmar UNA invitación sellaba TODAS (el defecto del ticket colado por la puerta de atrás, con
mi test de esa propiedad en verde porque montaba el estado a mano); la hoja no tenía salida y al
ampliar su audiencia se volvía una jaula que el reconciler remonta 7 días; re-abrir el mismo enlace
mandaba a repetir un «sí» ya dado. Detalle en `tickets/qa/groups-invite-skips-unirme-sheet-if-onboarded.md`.

## Te espera a ti

1. **Una decisión de producto pequeña y reversible.** La hoja del invitado gana un botón **«Más
   tarde»** (copy ya traducido, cero cadenas nuevas) **solo para quien ya tiene la app montada** —
   al que llega sin app no se le ofrece, porque salir le dejaría en una app sin dar de alta. Sin él,
   un enlace tapeado por error te tapaba tu propia app hasta que te rindieras y entraras al grupo. Lo
   metí porque entregar eso habría sido peor que el bug; **revertirlo es un commit** y nada depende de
   ello.
2. **Publicar la app.** Los dos avisos de Grupos están completos en servidor y en los dos entornos;
   falta el cliente iOS. Ahora llevaría además el fix de identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle y esto.
3. **La tanda de QA: 29 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe —`group-joiner-flag-consumers-still-narrow`,
   `groups-equal-split-shows-not-participating-on-peer` y `rejoin-tap-renotifies-admins`— con una
   precondición frágil: **B se une por enlace y NO relanza la app** antes de que A cree el gasto. Si B
   relanza, ninguno reproduce. `invite-link-five-causes-one-message` cabe en el mismo montaje.
   **Entra hoy `groups-invite-skips-unirme-sheet-if-onboarded`, y encaja justo ahí**: B tiene la cuenta
   ya creada, abre el enlace y tiene que ver la hoja con su nombre puesto, sin estar dentro hasta
   tocar «Unirme». Su criterio de no-regresión es el que importa: **después de unirse, el nombre, la
   moneda y el periodo de B siguen como estaban**. Y `groups-deleted-group-detail-stays-open`, que es
   otra pila.
4. **Dos decisiones de la web** (§9 del informe): el **texto legal de Grupos** —dice «vía iCloud, no
   por servidores nuestros» y el backend propio está al 100 % en prod— y si Vercel debe desplegar al
   mergear (hoy su rama de producción es `1.0`).

## Abiertos

**`in-progress` sigue vacío.** Todo lo vivo espera la tanda de QA o hardware (los **2 de `blocked`**),
no código.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. Hoy volvió a pasar tres veces en el mismo ticket, y una de ellas era una
premisa que el ticket daba por medida y es **falsa**: `onboardingMode = .groupInvite` NO escala al iKV
por el camino de la hoja (`OnboardingMode.setCurrent` escribe `.standard` a secas). Lo que sí viaja
cross-device es `userName`, `defaultCurrencyCode` y `defaultPeriod` — el daño era real, el titular no.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

110 tickets · backlog 54 · in-progress 0 · qa 33 · blocked 2 · done 16 · discarded 5. `qa` significa
«esperando la tanda», no «cerrado».

**Sigue el desajuste de conteos**, sin recontar: el disco tiene 110 y `docs/TICKETS.md` dice `= 96`
(con `in-progress 7`, que hoy es 0). Y **`rojo-heroBuckets-thisWeek-trailing-window` está en disco sin
fila** en el índice. Hoy se tocó solo la fila del ticket de la sesión, otra vez, para no ampliar
alcance — van dos sesiones seguidas dejándolo dicho.

**El verde del CI no dice que los XCUITest pasaran:** su paso de UI es *advisory* (`continue-on-error`)
y el job sale `success` con fallos dentro. Lo bloqueante de verdad es `Build for testing`. En el PR #74
se esperaron los tres checks bloqueantes en verde y se mergeó con el advisory aún corriendo — llevaba
1 h 45 min, y **la suite completa (130 XCUITest) ya había corrido 130/0 en esta Mac**, que es la red
real.

**Y ojo con el `CLAUDE.md` de casa:** dice «El CI de GitHub, apagado». Es **falso** — `qa.yml` está
activo y corre en cada push. Medido dos sesiones seguidas.
