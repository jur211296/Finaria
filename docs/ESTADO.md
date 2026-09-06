---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `15b26b0b` — quien espera aprobación ya no entra al grupo. TestFlight build
**12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva.

## Esta sesión, en una línea

**La puerta del grupo** (PR #81). Quien se unía por un enlace y quedaba pendiente veía el grupo en su
lista y, al tocarlo, **entraba**: una pantalla sin un solo gasto y sin nada que explicara por qué.
Ahora la tarjeta no lo abre y le dice en qué estado está su solicitud.

**Y la premisa del encargo era falsa, otra vez** — segunda vez en dos sesiones. La tarjeta ya **no**
abría el detalle (`handleTap` no navegaba desde `#26`); lo que fallaba en el build 12 era la
**identidad** que alimentaba ese gate, y eso lo arregló `5ca4dd47` el 4-sep. **El bug reportado ya no
se reproduce en `2.1`, y no por este PR.** Lo que sí quedaba, y es lo que se hizo: (1) el tap del
pendiente era un **muro mudo** —`.disabled`, no pasaba nada—, el mismo defecto que C-10 cerró para los
grupos congelados; (2) **la tarjeta no era la única puerta**: `openDetail` tiene **tres** call-sites y
los otros dos —deep link de notificación y nudge— **no tenían gate de estado**; (3) el copy prometía
«verás el grupo y quién está dentro», que la decisión convertía en mentira.

## Te espera a ti

1. **Una decisión** — `groups-owner-debt-no-heir-dead-end` (high). El dueño **con deuda y SIN
   heredero** (único activo, canal CloudKit, o co-miembros sin cuenta) sigue sin salida: la decisión
   del 6-sep no cubre esa celda porque descartó «eliminar con deuda». Cuatro opciones en el ticket;
   la más prometedora es permitir eliminar cuando la deuda es solo con miembros que ya se fueron.
2. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme», el freno de la lista,
   «Transferir y salir» y **la puerta del grupo**.
3. **La tanda de QA: 34 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe con una precondición frágil: **B se une por enlace y
   NO relanza la app** antes de que A cree el gasto. `groups-leave-rpc-error-10` necesita el suyo,
   `groups-owner-transfer-and-leave` también, y ahora **`groups-pending-member-can-open-group`**
   (dos teléfonos; incluye comprobar que al aprobar la puerta se abre sin relanzar).
4. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear (`1.0` vs `2.1`; de esa depende
   `invite-aasa-requires-s-param`). Y ratificar o revertir el botón «Más tarde» del invitado.

## Abiertos

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una
decisión tuya** (1, el de arriba). Lo siguiente que la cola puede lanzar sin preguntar, por peso:
`panel-colapsa-la-seleccion-de-cuentas-a-la-primera` y
`hero-estadisticas-stock-vs-flujo-entre-pestanas`.

**El gate tiene ruido: `unit-suite-nondeterministic-reds` (high).** La suite completa da rojos
**distintos en cada corrida** en local y **pasa entera en CI** (log leído, no el semáforo). Mientras
siga así, cada sesión paga tres corridas para saber si un rojo es suyo — y el riesgo caro es el
inverso: dar por ruido un rojo real.

**Y el CI verde tampoco es verde.** Su paso `tests` sale `success` con **9 fallos dentro** (leído en
el log, 6-sep): son 3 XCUITest × 3 reintentos, los tres preexistentes en `2.1` y ya con ticket
(`uitest-compara-fechas-sin-fijar-locale`, `edgecases-extreme-minimum-flaky-under-load`). **El estado
de un paso del CI no es su resultado**: se baja el log del job y se cuenta.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. **Y la premisa del ticket —y la del encargo— también caduca**: dos sesiones
seguidas han encontrado la suya falsa, y hoy el defecto ya estaba arreglado por un vecino.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**123 tickets · backlog 62 · in-progress 0 · qa 38 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(no conteos: el grep de filas falló y el índice estaba bien). **Todo cierre incluye
`docs/TICKETS.md`**, y lo que salga de camino lleva ticket propio — esta sesión sacó uno,
`groups-pending-member-sees-detail-chrome` (low): dentro del detalle, Miembros y Ajustes no miran el
estado del miembro. Hoy inalcanzable, por eso no se arregló.
