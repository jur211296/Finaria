---
updated: 2026-09-07
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-07 (Lima)

**Rama** `2.1` · HEAD `2e8f083c` — el runner de XCUITest no moría de memoria: lo pisaba otra sesión.
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web
nueva.

## Esta sesión, en una línea

**El runner de XCUITest no se caía por memoria ni por disco: se caían dos corridas a la vez sobre el
único simulador** (PR #96, mergeado). El ticket `high` llevaba días diciendo que el runner muere tras
el primer caso de cada suite y señalaba la memoria como hipótesis principal, con el disco ya
descartado a 14 GB. **Las dos eran falsas.**

**La causa, reproducida 2 de 2.** Dos `xcodebuild test` de XCUITest sobre el mismo simulador comparten
bundle id, así que la segunda **mata al runner de la primera** al lanzar el suyo. En el log se ve el
relevo: un PID nuevo de `YalaUITests-Runner` diciendo «Running tests…» justo donde el anterior se
corta a mitad de un `Synthesize event`. Lanzadas con 25 s de diferencia dan `4 reinicios / 7 pasados /
0 fallos` y `3 reinicios / 1 pasado / 0 fallos` — idéntico las dos veces, y es la firma exacta del
ticket: exit 65 y casos en «Failing tests» que **nunca imprimieron una línea de fallo**.

**Las dos hipótesis, medidas y descartadas.** La memoria: el swap estuvo **lleno** (6,0-6,1 de 6,1 GB)
durante las 12 corridas de control, y aun así **124 casos sin un solo fallo**; no hay **ni un
`JetsamEvent` el 6-sep**, y en los 8 que existen desde el 1-sep ni `xcodebuild`, ni el runner, ni la
app salen nunca con `reason` (los `jettisoned` que sí hay matan daemons de iOS *dentro* del
simulador). El disco: bajado a **12 GB** a propósito con un fichero de relleno, 3 corridas, **11/11
verde cada una**. Y el control en la dirección contraria — la corrida solitaria lanzada *justo
después* de las concurrentes vuelve a 11/11 y exit 0 ⇒ es la concurrencia, no el desgaste del
simulador.

**Explica por fin lo que cuatro tickets no cuadraban: por qué fallaba en TANDA y pasaba AISLADO.** Una
tanda son ~3 min de ventana para que otra sesión entre; un test suelto, 30 s. En esta máquina hay
**un solo simulador** y conviven **10 worktrees**, todos con el mismo `-destination name=iPhone 17 Pro`.

**El fix y el criterio que ahorra el diagnóstico entero.** `qa/scripts/sim-libre.sh` (nuevo, con
control positivo y negativo) dice si hay otra corrida en curso, y el paso 3 del `/gate` lo consulta
antes de correr nada ⇒ **el paso 3 vuelve a dar veredicto**. Y en `.claude/rules/testing.md`, un
`grep -c`: `Failing tests` **sin** línea `Test Case … failed` es el runner muerto, no hay veredicto;
**con** su mensaje de aserto sí es un rojo de test.

**De camino, dos contradicciones entre documentos.** `transaction-save-helper` decía que ninguna de
sus 21 muestras se tomó con el disco sobre 25 GB; `edgecases` documentaba un fallo **con 26 GB**. No
se elige entre dos documentos que se contradicen: se mide a los dos lados, y el umbral no cambia nada.

## Te espera a ti

1. **Staging arrastra ya TRES migraciones** — g13_04 (4-sep), g13_05 y **g14_01** (7-sep). Mismo
   bloqueo las tres: **no hay credencial de DDL** (el conector MCP solo lista producción). Se cierran
   aplicando los tres `.sql` de `qa/cloud/` **en orden**. Es acceso tuyo, no una tarea que se destrabe
   sola. Con g14_01 el drift ya muerde: fijar un presupuesto contra staging deja un dead-letter
   permanente, y un dead-letter apaga el Merkle de ese grupo. Producción está al día.
2. **Desplegar el Worker cuando quieras encender el Merkle nuevo.** El manifest de Grupos va en `c2`
   desde este PR; hasta que el gateway se despliegue, la verificación Merkle de Grupos queda apagada
   (los clientes saltan por el guard de canon en vez de reportar divergencias falsas). No corre prisa y
   no rompe nada: es una red que vuelve cuando tú quieras.
3. **Del cierre de hoy (`fx-manual-writes`), y la primera pesa:**
   - `repair-queue-has-no-exit-for-partial-rate-rows` (**high**) — `ensureRates` pregunta si **existe
     la fila** de tasas, no si trae la divisa, así que declara «no falta nada» justo en el caso que
     más llena la cola del reparador, y ésta se recorre en cada arranque para siempre reemitiendo el
     grupo `money`. Los tres mecanismos son **preexistentes** (de `85ba0077`); lo que hace el PR de
     hoy es aumentar la población que los recorre — que es lo correcto, porque antes esas
     transacciones tenían el número aproximado **sellado y sin ruta de cura**. El intercambio pasó de
     «dato falso, coste cero» a «dato correcto y marcado, coste de arranque», y ese ticket paga la
     segunda mitad. Si prefieres el reparto contrario, se revierte.
   - `approximate-mark-ors-over-whole-period` — **decisión de producto tuya**: una sola transacción
     aproximada pone «≈» al total del mes, porque la marca se acumula por OR sobre el bucket entero.
     Con más población marcada eso pasa de raro a frecuente en multidivisa, y los tres calculadores
     no usan hoy el mismo criterio.
4. **Decisiones abiertas:**
   - `groups-archived-still-accepts-changes` — el copy promete que un archivado «ya no acepta cambios»
     y acepta todos: gastos, ediciones, liquidaciones, ajustes, invitaciones. Tres opciones dentro.
   - `groups-owner-debt-no-heir-dead-end` (high, del 6-sep) — el dueño con deuda y SIN heredero sigue
     sin salida.
   - **`secondary-onboarding-still-crosses-owner-domain` (nuevo, 7-sep)** — lo que QUEDA de la
     frontera: el prellenado LEE del dueño (y por esa vía hereda `expensesOnlyMode`, que **apaga la
     rama del saldo** que el PR #86 acaba de encender), y `notificationsSeeded` escribe en él. Las
     dos con contrapartida: la divisa heredada probablemente sí se quiere; las notificaciones de la
     visita sonando en un móvil prestado, quizá no. **Decisión key por key, no un barrido.**
   - **`secondary-visit-data-lost-on-signout-unannounced` (nuevo)** — el wipe de salida borra lo que
     la visita apuntó. Es correcto; qué se le cuenta y cuándo son cuatro salidas con contrapartidas.
   - **`groups-settlement-reminder-discoverability` (nuevo, 7-sep)** — el recordatorio de deuda
     funciona y **casi nadie lo va a recibir**: nace apagado (correcto, es dinero que le debes a
     alguien) pero **no entra en el primer de notificaciones**, que es donde se enciende su hermano
     `budgetAlertsEnabled` — se heredó el default sin heredar el encendido —, y además depende de un
     **segundo interruptor invisible**, el `NotificationItem` de Grupos, que también nace apagado:
     quien lo encienda con los avisos de Grupos apagados no recibe nada y nadie se lo dice. Tres
     preguntas dentro; solo la primera es de producto.
   - **`saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas` (nuevo, 7-sep)** — al
     filtrar una cuenta «excluida de estadísticas», el saldo grande muestra el TOTAL, los widgets 0 y
     el KPI 0: **la pantalla se contradice consigo misma**. Tres salidas dentro (0 en las tres, total
     en las tres, o no dejar filtrarlas). Alcanzable desde el carrusel, que sí lista esas cuentas.
5. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme», el freno de la lista,
   «Transferir y salir», la puerta del grupo, la puerta del archivado, la marca de aproximado con su
   corrección del 1:1, el rótulo del hero de Estadísticas, el aviso de visita **y el resumen
   compartible del grupo**.
6. **La tanda de QA: 48 tickets en `qa/`, y el guion solo cubre 22.** Entra
   **`fx-pnl-education-card`** (7-sep), y su device-QA **no es simulable**: la tarjeta de ganancia
   cambiaria sólo aparece con una cuenta multi-moneda con histórico real, y **ningún perfil de seed
   la produce** —son todos PEN—, así que su cobertura de UI es cero por construcción. Hace falta
   dinero en al menos una divisa extranjera, con movimientos a tipos de cambio distintos, para ver
   la tarjeta y su hoja de detalle.
    Entra
   **`groups-shareable-summary`**, y su device-QA tiene algo que el simulador no da: **«Guardar en
   Fotos» es camino nuevo** —la app nunca había escrito en la fototeca— y estrena
   `NSPhotoLibraryAddUsageDescription`; hay que ver además cómo llega la imagen a un chat de WhatsApp
   y que el texto del permiso se lea bien en su idioma. Entra
   **`reentry-killswitch-closes-both-doors`** (7-sep), y es el más caro de montar de los tres: pide
   **conmutar el kill desde el backend** y un móvil limpio por caso. Bajo `-uitest` los flags remotos
   cortocircuitan a su default, así que el estado nuevo **no es alcanzable por XCUITest**: su guion
   está en el ticket, y lleva los identificadores para distinguir las dos terminales, que **se ven
   iguales** (`welcome_reentry_ready` sale a la app, `welcome_born_cloud_ready` al onboarding). Entra
   también
   **`panel-colapsa-la-seleccion-de-cuentas-a-la-primera`**, con escenario paso a paso en su ticket:
   filtrar DOS cuentas desde Registros → Filtros y comparar Panel vs Distribución; repetirlo con
   «excluir» y con el toggle de grupos OFF. Hacen falta **tres cuentas con saldo distinto y no cero**.
   Y entra `welcome-privacy-branch-has-no-secondary-door`: el seam de simulador enciende el descriptor pero
   **no monta** un store secundario, así que falta el e2e con dos cuentas reales — los datos de la
   visita en SU store, su saldo inicial, y que el copy quepa en alemán y neerlandés (solo se vio en
   español). Guion en **`qa/guion-tanda.md`**. Los **17 sin montaje asignado** siguen en
   `qa-guion-tanda-no-cubre-17-tickets`.
7. **La deuda FX del PR #84: el que gobernaba ya está cerrado.**
   `fx-manual-writes-seal-approximate-as-final` pasa a `qa` (PR #94) — eran **catorce** sitios, no
   diez. Era la razón de que la marca de aproximado avisara menos de lo que debía, así que **ahora ya
   se puede probar la marca sin falsos negativos**, que era el motivo de ponerlo primero. Detrás
   siguen `fx-approximate-mark-missing-on-secondary-surfaces` y
   `fx-unknown-currency-code-collapses-to-usd`. Y por delante entra uno nuevo que pesa más que los
   dos: `repair-queue-has-no-exit-for-partial-rate-rows` (high), en el punto 3.
8. **Diez worktrees comparten un solo simulador, y eso rompía el gate de UI sin que se notara.**
   Cerrado el diagnóstico (PR #96) y puesta una guardia que lo **detecta**, pero la contención sigue:
   la sesión que llega segunda al paso 3 espera a mano, sin saber cuánto, y de madrugada no hay nadie
   mirando. Tres opciones en `diez-worktrees-comparten-un-simulador`: **un simulador clonado por
   worktree** (cuesta disco: el device actual son 9,1 GB), **un `flock`** que haga esperar en vez de
   fallar (barato, pero serializa el gate de todos), o **dejarlo en la guardia**. Toca cómo trabajan
   todas las sesiones, así que no lo decide una.
9. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear. Y ratificar o revertir el botón «Más
   tarde» del invitado.

## Abiertos

**Del CI, dos cosas menores y ninguna urgente.** (1) La **primera nocturna de verdad** salta esta
madrugada a las 03:17; la de hoy se lanzó a mano para verificarla y quedó corriendo. Si algo va mal,
avisa sola — y si no llega ningún aviso, es que fue verde. (2) `ci-checkout-v4-runs-on-deprecated-node`
(low): cada run deja un warning de Node 20 deprecado que GitHub ya está forzando a Node 24; son dos
líneas y no corre prisa, pero el ruido permanente entrena a no mirar las anotaciones, que es donde
este repo pone los avisos que sí importan. (3) `ci-workflow-cites-missing-testing-strategy` (low): el
workflow manda tres veces a un documento que no está en el repo.

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una decisión
tuya** (4, las de arriba).

**Ruido del gate — antes de anotar cualquier muestra, clasifica el rojo.** `grep -c "Test Case .*
failed"` sobre el log: **0** con un bloque `Failing tests` ⇒ murió el runner (otra corrida encima),
no hay veredicto y esos nombres no se archivan; **>0** con su mensaje de aserto ⇒ eso sí es un rojo
de test. Y `bash qa/scripts/sim-libre.sh` antes de correr.

- **`transaction-save-helper-flake-one-per-suite` (nuevo, medium).** Toda corrida completa de
  `YalaUITests` acaba con **un** fallo en el mismo aserto («no apareció la pantalla de éxito de la
  transacción», `XCUIApplication+Yala.swift:208`) y **la víctima cambia**: `QuickActionsFavorites`
  dos veces, `EdgeCases.test_extremeMinimumAmountSaves` la tercera —con la primera pasando esa vez—.
  Bisecado con 17 muestras contra el árbol base; la que lo zanja **falló con un único fichero
  cambiado cuyo parámetro nuevo no lo pasa nadie**: un fallo sin causa posible ⇒ ruido del
  instrumento, no regresión. El ticket lleva un **reproductor de 3 minutos** (4 suites + la suya) para
  que nadie repita las dos horas de bisección. **Aviso que va en el propio ticket:** este mismo aserto
  ya cazó una rotura REAL (el `.alert` con label dinámico), así que **no se descarta sin medir**.
  **Cuarta medición (tarde): la condición es la TANDA, no la corrida completa.** Con **cinco** suites
  ya sale, y en aislado pasa. Lo que lo zanja en cuatro corridas y sin bisecar: **el mismo comando en
  los dos árboles** —`HEAD` limpio falla idéntico, 11 tests y 1 fallo—. Correr aislado en el base y en
  tanda en la rama diría «es tuyo» y sería falso. ~~Ninguna de las 21 muestras se ha tomado con el disco
  sobre 25 GB~~ — **hecha el 7-sep y el umbral no cambia nada**: el reproductor de 5 suites da
  11/11 verde tanto a 25 GB como a **12 GB forzados**, doce corridas seguidas. (La afirmación era
  falsa además por otro lado: `edgecases` ya documentaba un fallo **con 26 GB**.)
  **Muestra 18 (7-sep, tarde): falla con CUATRO tests y le toca al PRIMERO por orden alfabético.**
  Corriendo solo los cuatro candidatos con `-only-testing` —sin las suites que los preceden— sale
  igualmente un único rojo (`EdgeCases`, 60,4 s) y los otros tres pasan. Eso **debilita la hipótesis
  de acumulación a lo largo de la corrida**: aquí no hay nada acumulado delante. Quedan en pie la
  race real en el guardado y el presupuesto de 10 s de la espera — y la primera es la que importaría
  en un teléfono, donde no hay aserto que la cace.
- ~~`rojo-xcuitest-runner-muere-tras-el-primer-caso`~~ **cerrado el 7-sep (PR #96)**: no era el
  entorno, eran **dos corridas a la vez sobre el único simulador**. Ver «Esta sesión». Lo que deja
  vivo: `bash qa/scripts/sim-libre.sh` **antes** de cualquier medición de UI, o la muestra no vale.
- ~~`unit-suite-nondeterministic-reds`~~ **cerrado el 7-sep (PR #95)**: la suite es determinista y el
  no-determinismo estaba en el grep que la contaba. Ver «Esta sesión».

**El entorno, con una medición nueva.** El disco bajó a **7,1 GB** (umbral 25) tras dos horas de
corridas encadenadas; un `simctl erase` lo devolvió a 12 GB — y **no eliminó el flake de arriba**, que
volvió a salir en la corrida hecha desde el simulador recién borrado. El disco libre absoluto **no**
es su variable. Antes de perseguir un rojo de UI: mirar memoria **y** disco, y repetir aislado.

**Y una causa nueva del disco, medida el 7-sep: un SNAPSHOT LOCAL de Time Machine nacido a mitad de
la corrida.** Con él puesto, **liberar espacio no libera nada** — retiene los bloques borrados —, así
que un `simctl erase` que quitó 4,4 GB del simulador dejó el disco **peor** (10 → 5 GB) en vez de
mejor. Borrarlo (`tmutil deletelocalsnapshots <timestamp>`, solo el timestamp: el nombre completo da
«is not a valid disk») devolvió **9 GB de golpe**, 4,2 → 13 GB. `disk-report.sh` **sí** los cuenta,
pero el informe del arranque decía 0 porque el snapshot **nació después**. ⇒ cuando liberar disco no
suba el número, mira los snapshots antes de seguir borrando; y re-mide el disco **durante** la sesión,
no solo al abrirla.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea, no
abras la línea citada. **Y la premisa del ticket —y la del encargo— también caduca.**

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**162 tickets · backlog 87 · qa 48 · blocked 2 · done 19 · discarded 5 · in-progress 1.**
Recontado sobre disco el 7-sep tras cerrar el runner: sale `rojo-xcuitest-runner-…` a `done` y entran
**tres** hallazgos de camino — `diez-worktrees-comparten-un-simulador` (la contención que la guardia
detecta pero no resuelve: **decisión tuya**), `rules-testing-habla-de-ios-27-que-no-existe` (las
reglas mandan comprobar un runtime que esta máquina no tiene desde hace ~6 semanas) y
`ci-allowlist-no-cubre-encargos-ni-qa-scripts` (un `.md` del encargo dispara 1,5 h de `macos-26`).
`docs/TICKETS.md` reconstruido contra el disco: **162 = 162** — venía declarando 159, con 158 filas y
un ticket de otra sesión sin indexar.

Histórico del recuento anterior:
Recontado sobre disco el 7-sep tras el no-determinismo de la suite: `unit-suite-nondeterministic-reds`
pasa a `done` y entra **uno** que no es suyo, el hallazgo de camino
`tests-borran-el-store-sqlite-abierto` (554-556 violaciones `vnode unlinked while in use` por corrida,
en 12 familias de test: hoy inocuo, mañana variable de confusión). `backlog` no se mueve —sale uno,
entra otro— y por eso el total sube solo por el `done`. Verificado por **conjuntos**: 159 = 159, cero
huérfanos en ambas direcciones. Y la comprobación de rutas del índice trae un falso positivo que
conviene no volver a perseguir: el **owner map** del final apunta a las carpetas de ORIGEN de la
migración, no al estado de hoy, así que cinco de sus rutas «no existen» y es correcto — la tabla del
índice, que es la que manda, está entera.

**158 tickets · backlog 85 · qa 48 · blocked 2 · done 17 · discarded 5 · in-progress 1.**
Recontado sobre disco el 7-sep tras las escrituras a mano de FX: `fx-manual-writes-seal-approximate-as-final`
pasa a `qa` y entran **seis** tickets que **no son suyos** — dos hallazgos de camino
(`currency-change-service-tests-mirror-the-logic`, cuyos siete casos **reimplementan la lógica dentro
del test** y siguieron verdes con el bug dentro; y `chat-assistant-plants-exchange-rate-one`, que sube
de `low` a `medium` porque su `exchangeRate: 1.0` plantado **no se cura en el caso normal**), tres de
la review adversarial (`repair-queue-has-no-exit-for-partial-rate-rows` **high**,
`approximate-mark-ors-over-whole-period`, `bulk-update-account-leaves-converted-amount-stale`) y uno
del rojo del CI (`ci-destination-assumes-a-simulator-that-may-not-exist`). Verificado por **conjuntos**:
158 = 158, cero huérfanos en ambas direcciones. Y otra vez la trampa de siempre: `grep -c` dio 153
frente a 154 ficheros por un id con un carácter fuera de la clase — **el cruce de conjuntos es la
medición, el conteo no**.

**150 tickets · backlog 79 · qa 47 · blocked 2 · done 16 · discarded 5 · in-progress 1.**
Recontado sobre disco el 7-sep tras la ganancia cambiaria: `fx-pnl-education-card` pasa a `qa` y entran **cuatro** hallazgos de su review adversarial que **no son suyos** — `panel-no-recalcula-al-llegar-tasas-nuevas` (llegan las tasas del día y el Panel sigue con las de ayer, con la marca de aproximado encendida), `reparacion-de-tasas-no-avisa-al-panel` (el reparador de importes provisionales corrige el disco en el arranque y no bumpea `dataVersion`), `hoja-del-saldo-vivo-ignora-los-filtros-de-sesion` (la hoja «Tu saldo hoy» y el saldo del panorama suman cuentas distintas, así que la misma pantalla da dos cifras del mismo dinero) y `widget-de-tc-no-localiza-separadores`. **El índice traía DOS filas sin registrar** —`groups-budget` y `rojo-heroBuckets-thisWeek-trailing-window`, las dos con commits ya en `2.1`—: se indexan con el estado que tienen en disco, sin reclasificar. Verificado por conjuntos: **150 = 150**, cero huérfanos en ambas direcciones y ningún estado discrepante. Dos trampas al medirlo, las dos mías: `in-progress` lleva guion (no casa `\w+`) y hay ids con mayúsculas (`rojo-heroBuckets-…`), así que un regex estrecho da un «todo cuadra» falso.

Recontado sobre disco el 7-sep tras el presupuesto de grupo: `groups-budget` pasa a `in-progress` y entran **tres** hallazgos de su review adversarial que **no son suyos** — `groups-canal-sin-capability-set` (el canal de Grupos no manda capability-set, así que cada columna nueva apaga el Merkle del parque viejo), `groups-stats-no-deduplica-gastos` (Estadísticas no dedupe y ahora se contradice con la barra de presupuesto, a un tap de distancia) y `gateway-typecheck-roto-y-fuera-del-ci` (tres errores de tipos que nadie ve porque el CI no corre `typecheck` y `@types/node` no está declarado).
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(143 = 143, cero huérfanos en ambas direcciones, y ningún estado discrepante entre fila y carpeta).
**El índice traía dos defectos que nadie había visto**, los dos arreglados: una fila de datos **por
encima de la cabecera de la tabla**, y dos punteros del mapa de origen apuntando a `in-progress/`,
que está vacío desde hace días. **Todo cierre incluye `docs/TICKETS.md`**, y lo que
salga de camino lleva ticket propio — esta sesión sacó **tres**:
`panel-lee-el-filtro-de-cuentas-en-singular-fuera-del-saldo` (el subtítulo «en N cuentas» cuenta todas
mientras el saldo filtra; y el prefill del formulario propone una cuenta arbitraria, en modo excluir
la excluida), `saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas` y
`filtro-de-cuentas-se-colapsa-al-navegar-a-registros`. La del kill-switch sacó **dos** más, los dos
de la review adversarial: **`restore-beacon-outlives-account-deletion`** —el faro que decide el
mensaje sobrevive al borrado de cuenta (su `clear` es best-effort y el `set` tuvo toda la vida de la
cuenta para propagarse), y de paso deja escrito que **el usuario MIGRADO —el único que existe hoy en
producción— ve su copia de iCloud congelada pre-migración sin que nada le avise de que es vieja**— y
**`adopt-terminal-claims-ready-without-checking-engine`**, que la pantalla de «listo» se deriva del
journal y nunca pregunta si el motor arrancó de verdad. La del recordatorio de liquidación sacó
**dos**: **`groups-settlement-reminder-stale-clock`** —el reloj del nudge no ve las ediciones de un
gasto viejo ni los pagos retro-fechados, porque `SplitSettlement` no tiene `createdAt` ni
`SplitExpense` tiene `updatedAt`; cerrarlo pide campo nuevo y migración— y
**`groups-settlement-reminder-discoverability`**, que es decisión tuya y está arriba. La del
resumen compartible sacó **dos**, los dos sobre código que ese cambio **no tocó a propósito**:
**`debt-simplification-nondeterministic-ties`** —ante un empate exacto de saldos,
`DebtSimplificationService` elige acreedor y deudor con `max`/`min` sobre un `Dictionary`, cuyo orden
de iteración cambia entre procesos, así que el conjunto de transferencias puede salir distinto (todas
correctas, mismo total); hasta ahora eso quedaba en pantalla, donde se vuelve a mirar, y desde el
resumen **se congela en una imagen** y circulan dos versiones por el mismo chat— y
**`group-balance-service-shares-not-deduped`**, el mismo hueco de repartos duplicados que se cerró en
la lógica del resumen y sigue abierto en el servicio que alimenta Balances, la banda del header y el
recordatorio de deudas.

**Y una lección de higiene del board:** abrí un cuarto ticket para el rojo de
`EdgeCases.test_extremeMinimumAmountSaves` **sin comprobar que ya existía uno**
(`transaction-save-helper-flake-one-per-suite`, de esta misma mañana). Se retiró y su medición nueva
se fusionó en el que ya estaba. ⇒ **antes de abrir ticket por un rojo, greppea el board por el aserto,
no por el nombre del test** — la víctima cambia entre corridas y el nombre no encuentra nada.

**Dos trampas al recontar, las dos han mordido ya:** cuenta solo `*.md` —hay un `.gitkeep` por carpeta
y PNG de evidencia en `done/` y `qa/`, que inflan un `ls`— y si filtras las filas con una regex,
acepta MAYÚSCULAS en el id: `rojo-heroBuckets-thisWeek-trailing-window` se escapa de `[a-z0-9-]+` y
aparenta ser un huérfano que no existe. **Estaba escrito y volvió a morder el 7-sep**: la sesión del
resumen compartible «encontró» ese mismo huérfano, añadió su fila al índice y creó un duplicado, que
tuvo que deshacer. ⇒ ante una discrepancia del board, sospecha **primero del filtro** y córrelo con un
patrón laxo (`\S+`) antes de tocar el fichero. **Y el índice tiene DOS tablas**: acota al bloque que sigue al
separador `|----|`, o cuentas filas de la de abajo. Se comprueba con **conjuntos**, no con el contador.
