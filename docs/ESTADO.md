---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `8ad32fd3` — la cola autónoma ya no tiene ningún ticket parado por una decisión
de Jürgen; el saldo de Distribución cuadra con el Panel; buscar un grupo no se atasca. TestFlight
build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva.

## Esta sesión, en una línea

**Diecinueve decisiones de producto de Jürgen, escritas en sus tickets** (PR #79, solo docs). El
encargo traía tres (el hero de Estadísticas, la puerta del miembro pendiente, el kill-switch de la
re-entrada) y dos extra. Después preguntó si **ya no quedaba ninguna**: **leer los 94 tickets vivos
enteros** —cuatro lectores, citas re-comprobadas con grep— destapó **13 más**, seis frenando bugs, y
la mitad escondidas en `qa/` como residuales «decisión aparte» sin ticket. Las contestó todas; tomó
la recomendada en las 19 porque cada una se apoyaba en una decisión suya anterior.

Lo que cambia para el usuario cuando se implementen, en una línea cada una: el número grande de
Estadísticas dice qué es; el invitado pendiente no entra a un grupo vacío; bajo el kill nadie lee
«no encontramos tus datos»; volver a la nube no pide reiniciar; el dueño con deuda puede transferir el
grupo y salir; el Panel respeta dos cuentas filtradas; un movimiento sin categoría cuenta por su
signo; un grupo archivado no acepta nuevos; el recordatorio de deuda le llega al deudor, suave.

**Tres decisiones sobre tickets de `qa/` generaban trabajo nuevo y salen a ticket propio**:
`groups-owner-transfer-and-leave` (high), `groups-archived-group-rejects-join`,
`budget-days-left-counts-today`. Lección en la memoria de Frank: «¿queda alguna?» se responde
leyendo, no con grep; un residual «decisión aparte» en `qa/` es una decisión huérfana.

## Te espera a ti

1. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme» y el freno de la lista.
2. **La tanda de QA: 32 tickets en 4 montajes.** Guion en **`qa/guion-tanda.md`**, sin tocar. El
   montaje de dos teléfonos cubre TRES de golpe con una precondición frágil: **B se une por enlace y
   NO relanza la app** antes de que A cree el gasto. `groups-leave-rpc-error-10` necesita el suyo.
   **Device-QA multi-moneda del KPI de Balance** (`distribution-balance-kpi-skips-fx`): cuatro pasos
   en el ticket; sin números de aparato no hay PASS.
3. **Dos decisiones de la web**, las únicas que quedan: el texto legal de Grupos (dice «vía iCloud» y
   el backend propio está al 100 % en prod) y si Vercel despliega al mergear (`1.0` vs `2.1`; de esa
   depende `invite-aasa-requires-s-param`). Y ratificar o revertir el botón «Más tarde» del invitado
   (decidido el 5-sep; revertirlo es un commit).

## Abiertos

**`in-progress` vacío.** Todo lo vivo espera la tanda de QA o hardware (los 2 de `blocked`:
`apppreferences-rewritten-on-launch`, `groups-join-intent-reconciler`); **ya nada espera una
decisión**. Lo siguiente que la cola puede lanzar sin preguntar, por peso: `groups-owner-transfer-and-leave`
y `groups-pending-member-can-open-group` (high, Grupos, review adversarial), después
`panel-colapsa-la-seleccion-de-cuentas-a-la-primera` y `hero-estadisticas-stock-vs-flujo-entre-pestanas`.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea,
no abras la línea citada. Y la premisa del ticket también caduca.

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**118 tickets · backlog 59 · in-progress 0 · qa 36 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado con control positivo
(ids con mayúsculas incluidos). **Todo cierre incluye `docs/TICKETS.md`**, y lo que salga de camino
lleva ticket propio.
