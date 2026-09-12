---
updated: 2026-09-12
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-12 (Lima)

**Rama** `2.1` — Merge #147: **el simulador se pide por turno; la segunda sesión espera.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (#147 · la cola del simulador)

**Dos sesiones que lleguen al gate a la vez ya no se derriban.** Catorce worktrees compartían un solo
iPhone 17 Pro, y cuando coincidían la segunda instalaba su `.app` sobre el mismo bundle id: la primera
seguía tapeando un binario ajeno y sacaba rojos **con su línea de fallo**, con la pinta exacta de una
regresión. Eso costó el `high` falso de #145. Ahora el gate dice `[cola] … ESPERA`, nombra a quién
espera y arranca solo cuando le toca.

**Tu decisión del 11-sep, la opción (2), está implementada y escrita** en el ticket y en
`.claude/rules/testing.md`, con el motivo de las otras dos: un simulador por worktree no (la Mini con
4 booteados llegó a load 944 y dobló el tiempo por corrida), y dejarlo en la guardia tampoco (las
nocturnas autónomas son las que coinciden). El precio aceptado: **serializa el gate de todas las
sesiones**.

**Tres cosas que no se sabían y ahora sí.** `flock(1)` no existe en macOS, así que el lock es del
kernel vía python3 y lo suelta solo al morir el proceso, incluso con `kill -9`. **Tener el turno no
es tener el simulador**: el runner de XCUITest cuelga de `launchd_sim` y sobrevive a su `xcodebuild`
—medido, 1 runner vivo a los 10 s con el lock ya libre—, así que el turno espera a que el simulador
se quede quieto. Y **`pgrep -f 'UITests-Runner'` se contaba a sí mismo**: dos comprobaciones
simultáneas se declaraban «ocupado» mutuamente 6 de 6 veces con el simulador en reposo, bloqueando
gates por nada. Eso era preexistente.

**La review adversarial cazó diez defectos míos, y dos eran llaves maestras** que hacían correr sin
lock y en silencio (`YALA_SIM_LOCK_HELD=0` y el PID de otro usuario). Detalle en el PR #147.

**Medido con dos corridas reales simultáneas**: intervalos disjuntos (la segunda arrancó 0,63 s
después de terminar la primera), las dos verdes, los dos centinelas en verde, cero «Restarting».
Banco de 37 casos con control negativo y nueve mutantes; corre también en Linux (CI, 37/37).

## La anterior (#146 · el `high` del kill-switch)

**Con el kill-switch de la nube bajado, la fila «¿Dónde viven tus datos?» ya no desaparece si hay una
cuenta de grupos que soltar.** Desde el paso 10 detrás de esa fila vive la única superficie para
soltarla, y Grupos va por su propio flag: el kill de la nube apagaba un control de Grupos.

**El predicado del ticket era el equivocado, y eso lo cazó la review.** Decía
`GroupsAccountAssociation.shared.hasAssociation`; cableado literal, el arreglo dejaba el bug vivo para
quien tiene sesión de grupos viva y ningún registro —la sección ofrece «Desasociar» también ahí, y a esa
celda se llega por el «empiezo de cero» del Welcome, que no cierra la sesión en la nube—. El término es
**«hay una cuenta que esta pantalla pueda soltar»**, leído del mismo sitio que dibuja el botón
(`GroupsAssociationPresence`, nuevo, con un source-scan que prohíbe derivarlo por tu cuenta).

**Y abrir la fila abría la migración.** «Migrar a la nube» no tenía candado propio del kill-switch: su
cierre durante un incidente era una consecuencia de que la fila estuviera oculta. Ahora es explícito
(`offersCloudMigrationEntry`) y **se re-mide en la acción**, porque el flujo consent → confirmación →
chooser no volvía a preguntar por el flag.

**Tu decisión del 6-sep sigue en pie** —«las dos puertas de la nube cerradas bajo el kill»— y ahora se
cumple con un candado explícito en vez de un efecto lateral. Lo que cambió fue la premisa, no la
política. Anotado en la cabecera del gate y en `reentry-killswitch-closes-both-doors`.

## Las dos de antes (#145 y #144)

**#145 · los siete XCUITest del Welcome estaban sanos: el rojo era de la máquina.** Medido tres veces
(11/11 en `2.1`, 11/11 en la revisión bisecada, 11 verdes en la nocturna) y las dos suites eran
byte-idénticas, así que no había eje que bisecar. Lo real era el simulador compartido; desde entonces
`sim-libre.sh --vigilar <pid>` vigila la corrida entera y el paso 3 del `/gate` lo lanza en paralelo.
**Y hoy ha vuelto a rendir**: confirmó «estuviste solo durante toda la corrida» en los 17 XCUITest.

**#144 · desasociar la cuenta de grupos ya no puede mentir.** El borrado local pasó a ser la **última condición
del gesto, no su último paso**: si no entra, no se limpia nada, sale un aviso propio y la sección recuerda
que quedó a medias. Se ofrece **Terminar** el borrado, no repetir el gesto (repetirlo vuelve a entrar por
el push-all tras el teardown y puede dejarlo sin poder terminarse nunca). La review fue en dos vueltas y
la segunda —sobre el rediseño que la primera obligó— cazó dos ALTAS mías. Detalle en su ticket y en el
cuerpo del PR #144. **Su device-QA sigue pendiente y NO es simulable** (falta el seam de la asociación
sembrada).

## Marketing (Lola · #142 · el estudio de vídeo)

**Ya hay sistema para sacar vídeo del producto sin dibujar la app**: `marketing/remotion/`, con dos
formatos —**una presentación 16:9 por escenas** y **clips 9:16 por función**— sobre grabaciones reales
del iPhone. Tres versiones en un día: la primera no vendía nada (teléfono pequeño sobre negro), la segunda
recortaba la pantalla en una caja y parecía una captura pegada, la tercera pone **un iPhone entero como
objeto 3D** con la gramática de la referencia que trajo Jürgen (Kelo). **Se cerró sin su visto bueno**:
«lo seguiremos mirando en una siguiente sesión». Detalle y trampas medidas en el PR #142 y en
`marketing/remotion/docs/`.

## Tu cola

0-bis. **Marketing · el estudio de vídeo espera tu ojo** (`marketing/remotion/out/` se regenera con
   `bun run render:presentation` y `bun run render:reels`). Tres decisiones cortas: fondo de la
   presentación **oscuro o blanco**; el **guion de 8 líneas** en `copy.ts`; y cuándo grabas los **clips por
   función** desde QuickTime, en Liquid Glass y sin la píldora roja. Sin eso, la presentación sigue
   repitiendo el mismo mp4 del piloto.
0. **Nada nuevo te pide esta sesión.** #147 y #148 están mergeados y no tocan ninguna superficie de la
   app, así que **no hay device-QA que hacer**. Lo único que cambia para ti: a partir de ahora, si dos
   sesiones llegan al gate a la vez, la segunda dice `[cola] … ESPERA` en vez de sacar un rojo falso.


1. **Cierra sesión en el iPhone y recrea los grupos de prueba.** Es lo ÚNICO que falta para el device-QA
   del paso 3: el móvil apunta a la cuenta que borró el fresh start y cada llamada da 409/502. **Mira antes
   el orden del punto 2-quinquies.**
2. **Device-QA del paso 3** — los cuatro recorridos del ticket. Sal del bloqueo **por swipe y por
   «Entendido»**, no solo por el botón; y en el recorrido 1 **fuerza el cierre de la app** antes de darlo
   por bueno. Más los device-QA de los pasos 4, 5, 6, 8 y 9.
2-bis. **Device-QA del paso 4, y empieza por su punto BLOQUEANTE** (`welcome-private-fresh-start-skips-icloud-check`,
   guion dentro): comprobar que la sonda de CloudKit **no lanza**. Baja una lista de `desiredKeys` única
   sobre una zona multi-tipo, y si el servidor la validara contra el schema de cada tipo, la rama privada
   quedaría en «reintentar» para siempre. El plan B está escrito. Después, los cinco recorridos —y el
   feo: **mata la app a mitad del borrado** y comprueba que al reabrir vuelve a preguntar.
2-quater. **Device-QA del paso 5** (`groups-only-second-launch-mounts-icloud-mirror`, guion dentro). **NO
   es simulable**: sin cuenta de iCloud no hay espejo que adjuntar. Cuatro recorridos, y el que más caro
   sale es el **tercero** —la no-regresión—: restaurar de iCloud tiene que seguir trayéndote tu histórico.
   Si en vez de eso te pide reabrir la app una y otra vez, es el fallo grave de este cambio.
2-quinquies. **Device-QA del paso 6** (`beacon-routes-only-never-blocks`, guion dentro). Necesita un
   TestFlight con este cambio, y su mitad de sign-in real **NO es simulable**. Su recorrido 1 usa el faro
   que dejó el fresh start en tu iPhone, y **el orden importa**: si recreas los grupos del punto 1 con el
   build 13, el faro sigue ahí; con el TestFlight nuevo, entrar con Apple por Grupos ya lo limpia —a
   propósito: el motor lo hace en toda puerta— y el recorrido 1 se comprueba en Console.app en vez de en
   pantalla.
2-sexies. **Device-QA del paso 8** (`full-mode-activation-must-ask-where-personal-data-lives`, guion de 10
   recorridos dentro). **NO es simulable.** Antes, **reinstala** si tu sesión solo-grupos es de antes del
   10-sep: si no, verás el aviso de reinstalar —correcto— y no el chooser. El que más caro sale es
   **restaurar**: los gastos de grupo tienen que salir UNA vez, y los que ya habías clasificado conservan
   su cuenta y su nota.
2-septies. **Device-QA del paso 9** (`session-exits-one-verb-per-session`, guion dentro). **NO es
   simulable**: sin cuenta de iCloud no hay espejo, y el testigo del export solo se prueba en device.
   **Empieza por su spike de tres supuestos**, que ningún test puede medir: que el espejo firme sus
   importaciones con su autor, que emita un evento de export tras cada save, y que un export con éxito
   haya subido todo lo anterior a su inicio. **Si falla el primero, todo cierre privado acaba en la
   salida de emergencia diciendo «1 cambio»** —falla seguro, pero inservible—. Y una decisión tuya
   dentro: qué hacer con cambios de grupos que ya no tienen a dónde subir
   (`groups-outbox-rows-without-a-live-session-have-no-exit`).
2-octies. **Device-QA de la mitad 2 del paso 5** (`groups-entry-on-a-mirrored-store-still-blocks-the-owner`,
   guion de cinco recorridos dentro). **NO es simulable**: sin cuenta de iCloud no hay espejo. El que más
   caro sale si falla es el **segundo**: después de que la puerta devuelva el teléfono al neutro,
   «Restaurar desde iCloud» tiene que traerte TODO el histórico. Y el quinto es el que prueba la otra
   mitad del bug: con el teléfono vacío pero aún espejando, crea el grupo tras el relanzamiento y
   comprueba en otro dispositivo del mismo Apple ID que ese gasto **no aparece** en tu Panel personal.
2-nonies. **Device-QA del paso 10** (`device-qa-groups-account-association`, guion de siete recorridos
   dentro). **NO es simulable**: el simulador no tiene sesión de nube. El que más caro sale es el
   **quinto**: desasocia en un teléfono, abre el otro del mismo Apple ID, y comprueba que la asociación
   **sigue soltada**. Si reaparece, el tombstone no está llegando y el gesto se deshace solo. El tercero
   es el que prueba lo demás: re-asocia la misma cuenta y **cuenta los movimientos del Panel** — tres
   gastos tienen que seguir siendo tres, no seis. **Y desde hoy hay un octavo, que es el más caro de todos
   y necesita DOS personas**: desasocia, **mata la app y vuélvela a abrir** —el daño estaba en el arranque
   siguiente, no en el gesto—, re-asocia, y comprueba en el teléfono del OTRO miembro que sus gastos siguen
   ahí. Si desaparecen sin que él toque nada, para el release.
2-decies. **Device-QA del #144** (`detach-failure-looks-like-success`, dentro de su ticket). **NO es
   simulable**, y necesita provocar el fallo: desasocia con el borrado roto y comprueba que la app lo DICE
   y que la pestaña Grupos sigue entera; que «Terminar de soltar la cuenta» funciona **sin sesión viva**;
   y que re-asociar después **no duplica** los gastos que elegiste conservar — tres siguen siendo tres.
2-undecies. **Device-QA del #146** (`device-qa-cloud-killswitch-groups-door`, cuatro recorridos dentro).
   **Éste SÍ es simulable**, al revés que todos los de arriba: el toggle «Simular remote OFF» del panel
   DEBUG en un build **Yala Dev**, y el panel se alcanza desde Ajustes → iCloud, sin pasar por la pantalla
   que se va a mirar. El que importa es el **tercero**: tras desasociar, la fila tiene que DESAPARECER —si
   sigue ahí, el término no es un término, es un `true`.
2-ter. **Device-QA de la reversa born-cloud → iCloud** (`reverse-cutover-cerrado-para-cuentas-born-cloud`).
   Dos cosas: el **contador de testigos con `ckRecordName`** del panel DEBUG tiene que pasar de 0 a cubrir
   tus filas vivas —ése es el único testigo real de que la subida ocurrió—, y **borra 2-3 transacciones
   antes de empezar**: lo que no debe pasar es que reaparezcan.
3. **Física, la de siempre**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6),
   Apple Pay y carreras de red (4).
4. **De FX quedan cuatro** · **tres veredictos de QA caducos** · **el build 13 no llega al grupo externo**
   hasta pasar beta review.
5. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 12** del rediseño (`shell-derives-from-two-session-axes`): el barrido de las 19 vistas y la
retirada de M1. Pasos 0-10 cerrados; el 11 sigue vacante a propósito. **El board: 326 en disco = 326 en
`docs/TICKETS.md`**, cero desajustes de estado.

## Bloqueo

**Lo nuevo de hoy, y es el mismo agujero por el otro eje:**
`groups-killswitch-403-blocks-detach-forever` (**high**). Con el kill de **Grupos** servido como 403 y
cambios de grupos sin subir, desasociar queda **imposible** —`.permanent`, sin un solo reintento— y el
aviso le dice al usuario que el problema es su cuenta. El #146 abrió la puerta para que ese gesto exista
durante un incidente de la nube; por el eje de Grupos la puerta está abierta y el gesto no funciona. Pide
decisión: distinguir el 403 de kill-switch del resto de lo permanente, o dejar soltar sin subir lo
pendiente (que hoy es una decisión deliberada del orden del gesto).

**El `high` de testing que iba primero ya no existe: era un falso positivo** y queda `discarded` con la
medición dentro. Lo que sí sube a `high` es su causa, `diez-worktrees-comparten-un-simulador`, y **espera
decisión tuya** entre tres opciones que el ticket ya tiene escritas: un simulador por worktree (cuesta
disco), un lock de fichero (serializa el gate de las 14 sesiones) o seguir a mano. Lo de este PR es
**detección**, no prevención.

Y un dato de paso: la nocturna del 11-sep confirma que los cuatro de
`nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo` **siguen rojos**, tres de ellos 3/3 reintentos en dos
noches distintas. Eso ya no se sostiene como «flaky de runner frío».

Los otros dos de testing: `shared-state-guard-misses-wipelocalgroupsdomain` (el guard del trait de
aislamiento busca `wipeAllUserData(` y se le escapa el otro escritor del espejo) y
`spike-r3-eje-4b-flaky-en-suite-completa` (rojo en la suite completa, verde en solitario; su control
negativo afirma un modo de fallo que cambia según lo que corriera antes).

**Y lo que deja el #144, por orden de lo que más cuesta si falla:**
`groups-purge-save-crosses-two-stores-without-atomicity` — el borrado del dominio Grupos promete «todo o
nada» y su `save()` cruza **dos archivos**; si el segundo falla después del primero queda el par que la
regla de área marca como peligroso, «cursor borrado + filas vivas». Y
`uitest-seam-for-a-seeded-groups-association` (**medium**): sin un seam que siembre la asociación hay dos
estados de la pantalla que **nadie puede probar en simulador** — la celda del segundo móvil, sin cobertura
desde el paso 10, y el botón «Terminar de soltar la cuenta» de hoy.
