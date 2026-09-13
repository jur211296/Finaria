---
updated: 2026-09-12
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-12 (Lima)

**Rama** `2.1` — Merge #150: **el eje «¿hay sesión privada?» ya tiene fuente propia.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (#150 · el paso 12, PR-A: el eje 1)

**Lo que desbloquea el paso 12.** El eje 1 se construía nueve veces como
`!SessionState.shared.isGroupInviteMode`, o sea a partir del flag que el propio ticket borra. Ahora hay
una marca positiva persistida (`PrivateSessionMark`) con backfill de un arranque, tu decisión del 12-sep.
**Para el usuario no cambia nada visible**: cambia de dónde sale la respuesta a «¿esta persona tiene vida
personal en este teléfono?», de la que cuelgan qué se borra al cerrar sesión, si «Vaciar datos» avisa a
los demás dispositivos del Apple ID y si al eliminar la cuenta de grupos sobrevive lo personal.

**El eje eran NUEVE constructores, no los 6 del encargo.** Los otros tres son las funciones de
`DestructiveScopeLogic` que recibían el mismo eje bajo el nombre viejo. Aprobado antes de tocar nada:
dejarlas habría partido el eje en dos nombres justo antes del barrido.

**Dos lecturas con direcciones de fallo OPUESTAS, y es el corazón del PR.** `hasPrivateSession`
(ausente ⇒ `true`, conserva de más) y `confirmedPrivateSession` (ausente ⇒ `false`). No hay un default
que sirva para las dos preguntas: la señal de vaciado a los demás dispositivos del Apple ID, al fallar
hacia `true`, vacía el iPad del dueño — el daño que la review del paso 9 ya había cazado una vez.

**La review adversarial cazó SEIS defectos, y los seis eran míos.** Dos que importan: el seam de uitest
envenenaba el simulador **de forma permanente** —elegí el prefijo `cloudSync.` para que la marca
sobreviviera a «Vaciar datos» y con eso la dejé fuera del único barrido que la limpia entre corridas—, y
el backfill **resucitaba la marca que el cierre de sesión acababa de borrar** en el mismo arranque, con
lo que la ausencia no existía nunca y el default estricto no protegía nada.

**Y se cayó una afirmación de mi propia cabecera:** la marca no viaja por el iCloud-KV, pero su SEMILLA
sí puede venir de ahí — el backfill no tiene más fuente que `onboardingMode`. Es una limitación heredada
de la migración, ahora escrita en el código en vez de prometida.

**Verificado:** build ×2 sin warnings nuevos —medido contra un worktree del árbol base con DerivedData
limpio, porque el primer intento fue incremental y dio un cero falso— · **6976 unit, 0 fallos** · 32
XCUITest en 10 suites con el centinela en 0 · audit limpio · CI en verde · **10 mutantes que caen**.

**Lo que falta y es tuyo:** el device-QA del eje **NO es simulable** (sin sesión de nube en el simulador;
las dos celdas que importan piden dos dispositivos del mismo Apple ID). Y el **PR-B** —barrido de M1 y
retirada de `OnboardingMode`— queda desbloqueado, con lo que hereda ya medido dentro del ticket.

## La anterior (#149 · un solo dominio de preferencias)

Se retiró la puerta que elegía en qué `UserDefaults` escribía la app —resolvía al mismo sitio para el
100 % del parque— y sus 155 lecturas pasaron a `.standard`. Y se apagó el encendido compilado de la
entrada a sesión secundaria: yo había afirmado que ese flag estaba en `false` y estaba en `true`, con lo
que el aislamiento retirado lo convertía en una fuga. Lo cazó la review.

## Las de antes (#147 · la cola del simulador)

**Dos sesiones que lleguen al gate a la vez ya no se derriban.** Catorce worktrees compartían un solo
iPhone 17 Pro; ahora el gate dice `[cola] … ESPERA` y arranca cuando le toca. Tu decisión del 11-sep, la
opción (2). El precio aceptado: serializa el gate de todas las sesiones. **Ya está en uso y funcionó**:
las corridas de hoy esperaron su turno y el centinela salió 0.

## Las de antes (#146 · #145 · #144)

Con el kill-switch de la nube bajado, la fila «¿Dónde viven tus datos?» ya no desaparece si hay una
cuenta de grupos que soltar (#146). Los 7 XCUITest del Welcome estaban **sanos** — era un `high` falso,
`discarded` con tres mediciones dentro (#145). Y «Desasociar» ya no finge que soltó la cuenta (#144); su
device-QA sigue pendiente y **NO es simulable**.

## Marketing (Lola · #142 · el estudio de vídeo)

**Ya hay sistema para sacar vídeo del producto sin dibujar la app**: `marketing/remotion/`, con dos
formatos —una presentación 16:9 por escenas y clips 9:16 por función— sobre grabaciones reales.
**Espera tu ojo** y tres decisiones cortas (`marketing/remotion/out/`, se regenera con
`bun run render:presentation` y `bun run render:reels`).

## Tu cola

0-bis. **Marketing · el estudio de vídeo espera tu ojo** (`marketing/remotion/out/` se regenera con
   `bun run render:presentation` y `bun run render:reels`). Tres decisiones cortas: fondo de la
   presentación **oscuro o blanco**; el **guion de 8 líneas** en `copy.ts`; y cuándo grabas los **clips por
   función** desde QuickTime, en Liquid Glass y sin la píldora roja. Sin eso, la presentación sigue
   repitiendo el mismo mp4 del piloto.
0. **Device-QA del eje 1 (#150), y NO es simulable.** El simulador no tiene sesión de nube, así que
   las dos celdas que deciden datos hay que verlas en device con dos teléfonos del mismo Apple ID:
   **cerrar sesión en «equipo»** (privada + cuenta de grupos) y **eliminar la cuenta de grupos sin
   sesión privada**. Lo que hay que mirar es que la hoja prometa exactamente lo que el borrado hace.


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

**El PR-B del paso 12** (`shell-derives-from-two-session-axes`): M1 entera + `OnboardingMode` +
`SessionShape`. **Ya no hay nada que diseñar antes**: el eje 1 tiene su marca y su backfill desde el #150,
así que el barrido puede borrar el flag sin dejar decisiones colgando. `StorageMode` queda fuera por
decisión tuya, y el cambio de Apple ID ya tiene ticket propio.

Lo que el PR-A dejó **medido** para que el PR-B no lo redescubra, dentro del ticket:
`CloudIdentityRoutingLogic.deviceState` es una segunda fuente del mismo eje ·
`ProfileView.isExportEnabled` se queda en el flag a propósito · y el flag y la marca divergen hoy en el
vaciado remoto, cosa que se cierra sola al retirar el flag.

**El board: 331 en disco = 331 en `docs/TICKETS.md`**, cero desajustes de estado.

## Bloqueo

**`groups-killswitch-403-blocks-detach-forever` (high).** Con el kill de **Grupos** servido como 403 y
cambios de grupos sin subir, desasociar queda **imposible** —`.permanent`, sin un solo reintento— y el
aviso le dice al usuario que el problema es su cuenta. El #146 abrió la puerta para que ese gesto exista
durante un incidente de la nube; por el eje de Grupos la puerta está abierta y el gesto no funciona. Pide
decisión: distinguir el 403 de kill-switch del resto de lo permanente, o dejar soltar sin subir lo
pendiente (que hoy es una decisión deliberada del orden del gesto).

**La nocturna del 11-sep confirma que los cuatro de
`nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo` siguen rojos**, tres de ellos 3/3 reintentos en dos
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
