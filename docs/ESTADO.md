---
updated: 2026-09-07
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-07 (Lima)

**Rama** `2.1` · HEAD `a970de04` — un total con tipo de cambio aproximado ahora lo dice. TestFlight
build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web nueva.

## Esta sesión, en una línea

**La marca de «aproximado», y el 1:1 que seguía vivo debajo** (PR #84). El encargo pedía que un total
calculado con tasas incompletas dejara de presentarse como exacto. Al medir la premisa apareció algo
peor: en la ruta del **TC actual** —el total del Panel, los saldos de Grupos, presupuestos, pagos
programados— una tabla de tasas incompleta hacía que el importe saliera **sin convertir**. 1000 JPY
como 1000 PEN, unas 40 veces de más. `fx-partial-rate-rows-silent-1to1` cerró eso en septiembre para
la ruta con fecha; esta quedó fuera, y el ticket la describía como un problema de presentación.

**La premisa era falsa por un lado y corta por el otro**, y las dos mitades se midieron ejecutando
las dos rutas contra un store real. La ruta con fecha ya convertía bien: solo callaba que el número
era aproximado.

**La marca no hubo que diseñarla.** `AmountText.isEstimate` y el «≈» ya existían y los saldos de
Grupos ya los usaban ⇒ **cero copy nuevo en 16 `.lproj`**, contra lo que pedía el AC.

**Y la review adversarial volvió a cazar lo mío: cinco defectos, ninguno visible en verde.** El más
instructivo es que **mi propio arreglo repetía la forma del bug que arreglaba** — sembrar la caché
con la tabla estática hacía *vacua* la comprobación de cobertura recién escrita, y la tasa real de
ayer no se usaba nunca (24,79 por una ruta, 40 por la otra, en el mismo instante). También: una tasa
`0` guardada devolvía el importe crudo sellado como exacto; VoiceOver leía como exacto lo que en
pantalla llevaba «≈»; y un test que decía probar la acumulación no la probaba. Regla durable nueva
en `.claude/rules/currency-fx.md`.

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
   «Transferir y salir», la puerta del grupo, la puerta del archivado y **la marca de aproximado con
   su corrección del 1:1**.
4. **La tanda de QA: 39 tickets, y el guion solo cubre 22.** Guion en **`qa/guion-tanda.md`**. El
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

**El paso 3 del gate no está dando veredicto, y eso es lo más urgente del bloque.** Hoy el runner de
XCUITest **se cae tras el primer caso de CADA suite** («Restarting after unexpected exit»): 5 suites,
5 casos ejecutados —uno por suite—, 0 líneas de fallo y 5 nombres en «Failing tests». Ticket nuevo
`rojo-xcuitest-runner-muere-tras-el-primer-caso` **(high)**, y lo que lo hace `high` no es el falso
rojo sino que **taparía un rojo de verdad** en cualquier caso que no sea el primero de su suite.

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

**129 tickets · backlog 66 · qa 40 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(129 = 129, cero huérfanos en ambas direcciones). **Todo cierre incluye `docs/TICKETS.md`**, y lo
que salga de camino lleva ticket propio — esta sesión sacó **cuatro**:
`fx-manual-writes-seal-approximate-as-final` (high),
`fx-approximate-mark-missing-on-secondary-surfaces`, `fx-unknown-currency-code-collapses-to-usd` y
`rojo-xcuitest-runner-muere-tras-el-primer-caso` (high). Al índice le faltaban además **dos entradas
que no eran de esta sesión**: se comprueba con conjuntos, no con el contador.
