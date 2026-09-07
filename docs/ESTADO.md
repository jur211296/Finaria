---
updated: 2026-09-07
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-07 (Lima)

**Rama** `2.1` · HEAD `00924924` — el número grande de Estadísticas ya dice qué es. TestFlight
build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva.

## Esta sesión, en una línea

**El hero de Estadísticas dice qué es la cifra** (PR #85). Las cuatro pestañas comparten el mismo
hueco visual y se deslizan entre sí, pero desde #78 ese hueco mostraba dos cosas distintas con el
mismo período: un saldo de cuentas en Distribución, el neto del período en las otras tres. Tu
decisión del 6-sep era etiquetar el número, y eso se hizo. **Cero cambio de cálculo.**

**La premisa del AC era falsa, y cumplirla al pie de la letra habría metido un bug peor.** El
ticket pedía un rótulo FIJO por pestaña —Distribución «Saldo de cuentas», las otras tres «Neto del
período»—. Medido contra el árbol, ninguna de las cuatro cifras es siempre la misma magnitud:
Distribución solo enseña saldo en `isBalanceMode` y vuelve al flujo con un filtro de categoría, en
modo solo-gastos o con un chip —que es **tu decisión del 26-ago**, escrita en el propio código—;
Tendencias pinta uno de tres números según la métrica; Registros deja de ser un neto en cuanto hay
un chip; y el pie suma con `abs`, así que con las dos naturalezas no es ni neto ni un lado. Un
rótulo fijo habría mentido en pantalla, que es el mismo defecto del ticket agravado. Por eso el
rótulo se deriva del estado que elige el número. No se repreguntó: rotular el número que de verdad
se pinta **es** cumplir tu decisión, no ampliarla.

**Y se vio en pantalla, no solo en el fuente.** En el simulador, Distribución e Insights enseñaban
S/ 80.018,00 y S/ 72.361,30 en el mismo hueco sin filtros; y la misma pestaña Distribución pasa de
80.018,00 «Saldo de cuentas» a 204.821,00 «Gastos del período» al tocar un chip. Esa segunda es la
prueba de que el rótulo fijo mentía. Evidencia en `tickets/qa/`.

**El source-scan existe porque cablear el rótulo a un valor fijo deja la suite entera en verde** —
el bug del ticket. Control positivo por mutación: rompe exactamente los 2 tests que debe y deja
verdes los otros 3.

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
   «Transferir y salir», la puerta del grupo, la puerta del archivado, **la marca de aproximado con
   su corrección del 1:1** y **el rótulo del hero de Estadísticas**.
4. **La tanda de QA: 40 tickets, y el guion solo cubre 22.** Entra
   `hero-estadisticas-stock-vs-flujo-entre-pestanas`, ya verificado en simulador; en el teléfono
   falta la 4ª pestaña (Registros con sus chips), el estado de las dos naturalezas a la vez y el
   deslizamiento entre las cuatro con el mismo período, que es donde la incoherencia se nota. Guion en **`qa/guion-tanda.md`**. El
   montaje de dos teléfonos ya lleva ocho, incluido `groups-archived-group-rejects-join` (A archiva → B
   tapea y ve el aviso; A desarchiva → B entra). Los **17 sin montaje asignado** salen a
   `qa-guion-tanda-no-cubre-17-tickets`, con la sugerencia de sostenerlo con un comprobador en vez de
   con la memoria.
5. **La deuda FX que deja el PR #84, y el orden importa.** Cuatro tickets, uno de ellos gobierna a
   los otros: **`fx-manual-writes-seal-approximate-as-final` (high)** — diez sitios que GUARDAN un
   importe convertido lo sellan como definitivo aunque la tasa fuera aproximada, incluidos crear una
   transacción y el cambio de moneda preferida (que reescribe todo el histórico). **Es la razón de
   que la marca nueva avise menos de lo que debería**, así que probar la marca antes de cerrarlo da
   falsos negativos. Detrás: `fx-approximate-mark-missing-on-secondary-surfaces` (siete pantallas
   más sin marca) y `fx-unknown-currency-code-collapses-to-usd`.
6. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear. Y ratificar o revertir el botón «Más
   tarde» del invitado.

## Abiertos

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una decisión
tuya** (2, las de arriba).

**El gate tiene ruido: `unit-suite-nondeterministic-reds` (high).** Hoy la suite unit completa volvió
a pasar entera (**6240 tests en 633 suites**, 84 s) sin un solo rojo. Dos sesiones seguidas sin
reproducirlo: sigue sin estar descartado, pero tampoco visto.

**El runner de XCUITest: `rojo-xcuitest-runner-muere-tras-el-primer-caso` (high) NO se reprodujo el
7-sep.** El 6-sep se caía tras el primer caso de CADA suite («Restarting after unexpected exit»): 5
suites, 5 casos, 5 en «Failing tests». Hoy, en el gate de esta sesión: **8 suites, 15 casos
ejecutados = 15 declarados, 0 fallos** —y las suites de 2 casos ejecutaron los 2, que es justo lo
que ayer no pasaba—. Dos diferencias de entorno, ninguna descartada: hoy el disco se subió a 12 GB
antes de correr (borrando dos `DerivedData` de worktrees ya retirados, 6,6 GB) y el Mac llevaba
menos horas encendido. **No lo des por cerrado con una sola observación**, pero tampoco arranques
asumiendo que el paso 3 no da veredicto: hoy lo dio. Lo que lo hace `high` sigue en pie — taparía
un rojo de verdad en cualquier caso que no sea el primero de su suite.

Que es ajeno está medido en las **dos** direcciones: worktree limpio desde HEAD falla idéntico, y un
caso que PASA con los cambios FALLA sin ellos. **No lo confundas con
`uitest-compara-fechas-sin-fijar-locale`**, que cataloga rojos de ASERCIÓN con causa conocida; aquí
lo que muere es el proceso.

**Ojo con el entorno, y con la hipótesis correcta.** La sospecha del disco se probó y **no explica el
síntoma**: se liberaron 6,3 GB —de ellos **5,7 GB en
`CoreSimulator/…/Caches/com.apple.containermanagerd/Dead`**, contenedores muertos que el informe
esconde dentro del total de «Simuladores»— y siguió igual a 14 GB. La pista buena ya estaba en este
bloque ayer: **la MEMORIA**. Anoche el sistema mató además dos procesos de espera de la sesión por
presión de memoria. Antes de perseguir un rojo de UI: mirar memoria **y** disco, y repetir aislado.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea, no
abras la línea citada. **Y la premisa del ticket —y la del encargo— también caduca.**

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**129 tickets · backlog 65 · qa 41 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(129 = 129, cero huérfanos en ambas direcciones). **Todo cierre incluye `docs/TICKETS.md`**, y lo
que salga de camino lleva ticket propio — esta sesión sacó **cuatro**:
`fx-manual-writes-seal-approximate-as-final` (high),
`fx-approximate-mark-missing-on-secondary-surfaces`, `fx-unknown-currency-code-collapses-to-usd` y
`rojo-xcuitest-runner-muere-tras-el-primer-caso` (high). Al índice le faltaban además **dos entradas
que no eran de esta sesión**: se comprueba con conjuntos, no con el contador.

El 7-sep la tabla cuadraba fila a fila (129 = 129, cero huérfanos), pero su línea de *counts*
seguía diciendo `= 118`. Corregida. **Dos trampas al recontar, las dos me mordieron:** cuenta solo
`*.md` —hay un `.gitkeep` por carpeta y tres PNG en `done/`, que inflan un `ls` a 132— y si filtras
las filas con una regex, acepta MAYÚSCULAS en el id: `rojo-heroBuckets-thisWeek-trailing-window` se
escapa de `[a-z0-9-]+` y aparenta ser un huérfano que no existe. Estuve a punto de "reparar" un
índice que estaba sano.
