---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `fd33894b` — el dueño de un grupo con deuda ya puede salir de él. TestFlight
build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva.

## Esta sesión, en una línea

**«Transferir y salir»** (PR #80). El dueño de un grupo con saldos pendientes estaba encerrado:
«Salir» no se le ofrece por ser dueño y «Eliminar» está en gris por la deuda — aunque sea **entre
terceros**, con un aviso que le pedía liquidar lo ajeno. Ahora, si queda otro miembro elegible, cede
el grupo y sale; el grupo sigue vivo con sus saldos y **se le dice a quién va antes de confirmar**.

Dos cosas que el ticket da por sabidas y no lo eran. **El AC («elige a quién») partía de una premisa
falsa**: medido contra producción, `transfer_group_ownership` toma **un solo parámetro** y elige él al
heredero, así que no hay selector sin tocar el servidor — justo lo que el motivo de la decisión
descartaba. Y **la review adversarial (3 lentes) cazó cinco defectos, todos míos**; el peor lo
introducía el propio cambio: tras transferir, el ex-dueño **sigue siendo admin server-side**, así que
podía pulsar «Eliminar» y **el borrado aterrizaba**, llevándose el grupo del dueño recién coronado.

## Te espera a ti

1. **Una decisión nueva** — `groups-owner-debt-no-heir-dead-end` (high). El dueño **con deuda y SIN
   heredero** (único activo, canal CloudKit, o co-miembros sin cuenta) sigue sin salida: la decisión
   del 6-sep no cubre esa celda porque descartó «eliminar con deuda». Cuatro opciones en el ticket;
   la más prometedora es permitir eliminar cuando la deuda es solo con miembros que ya se fueron.
2. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme» y el freno de la lista.
3. **La tanda de QA: 33 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe con una precondición frágil: **B se une por enlace y
   NO relanza la app** antes de que A cree el gasto. `groups-leave-rpc-error-10` necesita el suyo, y
   ahora `groups-owner-transfer-and-leave` también (dos teléfonos).
4. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear (`1.0` vs `2.1`; de esa depende
   `invite-aasa-requires-s-param`). Y ratificar o revertir el botón «Más tarde» del invitado.

## Abiertos

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una
decisión tuya** (1, el de arriba). Lo siguiente que la cola puede lanzar sin preguntar, por peso:
`groups-pending-member-can-open-group` (high, Grupos, review adversarial), después
`panel-colapsa-la-seleccion-de-cuentas-a-la-primera` y
`hero-estadisticas-stock-vs-flujo-entre-pestanas`.

**El gate tiene ruido: `unit-suite-nondeterministic-reds` (high).** La suite completa da rojos
**distintos en cada corrida** en local y **pasa entera en CI** (6100 en 622 suites, log leído, no el
semáforo). Medido con el árbol base: el limpio falla con 3 y el modificado con 1, disjuntos; los cinco
pasan aislados. Mientras siga así, cada sesión paga tres corridas para saber si un rojo es suyo — y el
riesgo caro es el inverso: dar por ruido un rojo real. Sospecha principal: **disco/carga de la Mac**.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. Y la premisa del ticket también caduca.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**122 tickets · backlog 62 · in-progress 0 · qa 37 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado con control positivo
(ids con mayúsculas incluidos). **Todo cierre incluye `docs/TICKETS.md`**, y lo que salga de camino
lleva ticket propio — esta sesión sacó cuatro.
