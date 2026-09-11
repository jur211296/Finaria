---
updated: 2026-09-11
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-11 (Lima)

**Rama** `2.1` — Merge #137: **«Activar Yala completo» pregunta dónde viven tus datos personales.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el paso 8, y lo que costaba el bridge)

**Quien usa Yala solo para grupos y toca «Activar Yala completo» ve primero «¿Dónde guardamos tus
finanzas?»**, con las dos cards del Welcome; la de nube dice que es la misma cuenta que ya usa para sus
grupos. Privado pasa por la puerta de iCloud del paso 4 y deja restaurar; nube promociona la cuenta al
final, y si no sale no escribe nada. Al terminar el onboarding se pregunta si los gastos de grupo se ven
también en lo personal.

**La review (cuatro lentes) cazó 14 defectos míos, y el más caro era de dinero**: con el modo aún en
solo-grupos, el bridge borra la transacción real de cada gasto que re-puentea — y tras restaurar, esas son
las de tu vida anterior. Ahora el bridge queda cerrado mientras la activación está a medias y los gastos
convergen después del modo completo; medido contra el bridge real, con su control. Suite unitaria (6808) y
XCUITest **enteras** (62 clases) en verde.

## Tu cola

1. **Cierra sesión en el iPhone y recrea los grupos de prueba.** Es lo ÚNICO que falta para el device-QA
   del paso 3: el móvil apunta a la cuenta que borró el fresh start y cada llamada da 409/502. **Mira antes
   el orden del punto 2-quinquies.**
2. **Device-QA del paso 3** — los cuatro recorridos del ticket. Sal del bloqueo **por swipe y por
   «Entendido»**, no solo por el botón; y en el recorrido 1 **fuerza el cierre de la app** antes de darlo
   por bueno. Más los device-QA de los pasos 4, 5, 6 y 8.
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

**El paso 9** del rediseño (`session-exits-one-verb-per-session`): un solo verbo de salida por sesión.
Pasos 0-8 cerrados; el 11 sigue vacante a propósito. **El board: 174 en backlog, 53 en qa** (286 = 286
contra disco).

## Bloqueo

**Un bug vivo medido el 10-sep** (`settings-migrate-to-cloud-adopts-silently-instead-of-migrating`,
**high**): «Ajustes → migrar a la nube» sobre una cuenta que ya tiene datos **no migra: adopta en
silencio**, y te cobra dos confirmaciones destructivas antes. Tus datos locales se quedan donde están, sin
aviso.

**Los goldens de grupos** (`corpus-de-test-de-staging-crece-sin-limite`, **high**): seguían sin dar señal
por timeout, con 702 grupos de un usuario de test. **Dato nuevo:** el deploy de staging subió `f84620b5`
—el fix del canon viejo, sin desplegar desde el 8-sep— así que **un rojo anterior al 10-sep puede no
valer**. Re-medir antes de perseguirlo.

**Dos que el paso 6 agranda de un caso raro a toda la población** (los dos **high**, y ninguno lo
introdujo esa sesión): `reverse-upload-has-no-ceiling-and-no-exit` —la subida a iCloud no tiene tope ni
salida, y ahí el backend ya está congelado— y `reverse-claim-rejection-has-no-way-out-in-the-client`. Los
dos son la misma forma: una fase de la reversa sin salida.

**La mitad 2 del paso 5, y es decisión tuya** (`groups-entry-on-a-mirrored-store-still-blocks-the-owner`,
**high**): cuando el store YA lleva espejo, la puerta «datos ajenos» te sigue bloqueando. Lo medido: el
desmontaje en caliente que pediste lo rechaza su propio guard, y borrar lo local con el espejo montado
**exporta los borrados a iCloud** — destruiría justo lo que el criterio promete conservar. La salida que
sí existe cuesta un relanzamiento. **Conviene decidirlo junto al residual del paso 4**, que converge en
el mismo mecanismo.

**Y una regresión que encontró la review del paso 5** (`groups-only-private-restart-skips-the-wipe-alert`,
**high**): desde solo-grupos, «Primera vez → privado» se salta el aviso de datos existentes. Mitigada
para que no persista entre arranques; abierta dentro de la misma sesión.

**Un residual del paso 4, con ticket** (`late-icloud-wipe-can-re-export-between-its-two-halves`,
**medium**): matar la app entre las dos mitades del borrado tardío puede devolver los datos viejos. Es
reaparición, no pérdida, y su arreglo natural es del paso 9 — necesita pedir relanzamiento sin entrar en
la máquina de `CloudSessionSignOut`.

**Un gemelo de lo que arregló el paso 6, anterior a él** (`welcome-cloud-back-leaves-chooser-marked-seen`,
**medium**): volver atrás desde el sign-in de nube deja el Welcome «ya elegido», y cerrar la app ahí abre
el onboarding privado sin la puerta de iCloud.

**Dos del paso 8, con ticket** (los dos **medium**): `completed-mode-escalates-a-second-groups-only-device`
—activar Yala completo en un dispositivo sube de nivel al otro, que sigue en solo-grupos, y lo deja sin
espejo; no lo introdujo el paso 8 y **la salida es decisión tuya**— y
`claim-promotion-lost-response-blocks-the-retry` —si se pierde la respuesta de la promoción, «Reintentar»
bloquea la activación a la nube—.

**Y decisiones tuyas, pequeñas.** Tres de copy: `revert-card-copy-says-datos-regresan-a-quien-nunca-estuvo`
(el texto dice «tus datos **regresan** a tu iCloud» a quien nunca estuvo ahí) y, del paso 6,
`welcome-beacon-origin-contradicts-not-found-copy` (con un faro de Google sin cuenta salen seguidas «ya
tiene una cuenta» y «aún no tiene una cuenta») y `born-cloud-signup-lands-on-existing-account-silently`
(«Crear otra cuenta → nube → Apple» entra en la cuenta que ya existe diciendo «Creando tu cuenta…»). Es
voz de producto en 16 locales, así que no las toqué — `.claude/rules/l10n.md` dice «no reescribas copy que
ya funciona». **Y una del paso 7, sin prisa:** `flows-atlas-predates-session-redesign` — el Atlas de flujos
de Modo Nube sigue enseñando la card retirada (su validador pasa de 4 a 13 fallos); ¿se re-ancla cuando
acabe el rediseño o se retira?

**Sigue en pie:** la política de privacidad y los términos **bloquean la publicación** del rediseño. Y las
decisiones tuyas de antes: el filtro de naturaleza, los worktrees sin candado anti-atribución, ¿se ataca
ya el chat caído?, y si `fab-appears-without-animation` sube de `low`. **Sin ticket, medido el 9-sep:** un
CSV exportado antes de convertir una cuenta ya no se importa a ella y aborta el fichero entero.
