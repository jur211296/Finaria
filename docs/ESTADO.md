---
updated: 2026-09-06
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-06 (Lima)

**Rama** `2.1` · HEAD `24fd9eb8` — un grupo archivado ya no acepta miembros nuevos. TestFlight build
**12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva.

## Esta sesión, en una línea

**La puerta del grupo archivado** (PR #83). El enlace de un grupo que su dueño había archivado seguía
dejando entrar: quien lo tapeaba caía como pendiente en un grupo que ya nadie mira. Ahora el servidor
lo rechaza (`yala_group_archived`, g13_05 **aplicada y verificada en producción**) y la app le dice por
qué, estrenando un copy que llevaba meses traducido a 16 idiomas **sin un solo consumidor**.

**La premisa del encargo era cierta —la primera en tres sesiones— y aun así se midió**: ejecutando el
RPC contra la función viva en sandbox transaccional, no leyendo el `prosrc`. Devolvía `pendingApproval`,
dejaba la fila del miembro y **consumía un uso del invite**.

**Y hubo un bug propio, encontrado y arreglado.** Dar al botón de la alerta un label dependiente del
`@State` deja la vista sin alcanzar `idle` y **rompía el guardado de una transacción** — un flujo sin
ninguna relación con invitaciones. Lo delató `QuickActionsFavoritesUITests`, que estaba documentado como
**flaky en dos sitios**: archivarlo como rojo conocido lo habría mandado a producción. Regla durable en
`.claude/rules/swiftui-ds.md`.

## Te espera a ti

1. **Staging arrastra ya DOS migraciones** — g13_04 (4-sep) y g13_05. Mismo bloqueo las dos: **no hay
   credencial de DDL** (el conector MCP solo lista producción, `~/Secrets/yala-supabase-test/` solo
   tiene JWTs de usuario). Se cierran aplicando los dos `.sql` de `qa/cloud/` en orden. Es acceso tuyo,
   no una tarea que se destrabe sola.
2. **Dos decisiones nuevas, las dos salidas de cumplir un AC al pie de la letra:**
   - `groups-archived-still-accepts-changes` — el copy promete que un archivado «ya no acepta cambios»
     y acepta todos: gastos, ediciones, liquidaciones, ajustes, invitaciones. Ni los dos
     `validateGroupIsWritable` ni ninguna función del servidor miran `isArchived`. Tres opciones dentro.
   - `groups-owner-debt-no-heir-dead-end` (high, del 6-sep) — el dueño con deuda y SIN heredero sigue
     sin salida.
3. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme», el freno de la lista,
   «Transferir y salir», la puerta del grupo y **la puerta del archivado**.
4. **La tanda de QA: 39 tickets, y el guion solo cubre 22.** Guion en **`qa/guion-tanda.md`**. El
   montaje de dos teléfonos ya lleva ocho, incluido `groups-archived-group-rejects-join` (A archiva → B
   tapea y ve el aviso; A desarchiva → B entra). Los **17 sin montaje asignado** salen a
   `qa-guion-tanda-no-cubre-17-tickets`, con la sugerencia de sostenerlo con un comprobador en vez de
   con la memoria.
5. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear. Y ratificar o revertir el botón «Más
   tarde» del invitado.

## Abiertos

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una decisión
tuya** (2, las de arriba).

**El gate tiene ruido: `unit-suite-nondeterministic-reds` (high).** Hoy la suite unit completa pasó
**entera dos veces** (6207 tests en 630 suites) sin un solo rojo, así que el ruido no se reprodujo en
esta corrida — no está descartado, solo no visto.

**Y el CI verde tampoco es verde.** Su paso `tests` sale `success` con fallos dentro. Medido hoy sobre
**133 casos de XCUITest en seis tandas**: 3 rojos, los tres ajenos y **cada uno medido por separado**,
que es lo que este bloque venía pidiendo. `EdgeCases.test_extremeMinimumAmountSaves` falla también con
`ContentView` de HEAD ⇒ determinista y preexistente. `QuickActionsFavorites` y `TransactionsCrud`
**pasan aislados** (47 s y 37 s) y solo caen dentro de una tanda ⇒ fragilidad por CARGA, no por locale.
Anotado en `uitest-compara-fechas-sin-fijar-locale`, que **agrupaba los cuatro bajo una causa única y
no la tienen**.

**Ojo con el entorno al correr XCUITest aquí.** Hoy el sistema **mató `xcodebuild` tres veces por falta
de memoria** con 8-13 GB de disco libre (umbral 25), y eso produjo rojos que desaparecen al reintentar.
Antes de perseguir un rojo: `bash qa/scripts/disk-report.sh`, y repetirlo aislado.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea, no
abras la línea citada. **Y la premisa del ticket —y la del encargo— también caduca.**

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**125 tickets · backlog 63 · in-progress 0 · qa 39 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(125 = 125, cero huérfanos en ambas direcciones). **Todo cierre incluye `docs/TICKETS.md`**, y lo que
salga de camino lleva ticket propio — esta sesión sacó dos: `groups-archived-still-accepts-changes` y
`qa-guion-tanda-no-cubre-17-tickets`.
