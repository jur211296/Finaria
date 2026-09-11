---
updated: 2026-09-11
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-11 (Lima)

**Rama** `2.1` — Merge #139: **«Vengo por un grupo» deja de bloquear al dueño de los datos.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (la mitad 2 del paso 5: la puerta de Grupos deja de bloquear)

**«Vengo por un grupo → Crear mi primer grupo» ya no deja tirado al dueño de sus datos.** Hasta hoy, en un
teléfono con datos guardados, salía «Aquí ya hay datos guardados… si son tuyos, crea el grupo desde la app
que ya usas» con un único botón «Volver» — y la app que ya usas es ésa. Ahora Yala sube a iCloud lo último
que guardaste, deja el teléfono en blanco, pide reabrir la app una vez y **te devuelve a la misma puerta**,
listo para crear tu grupo. Tu iCloud no se toca: «Restaurar desde iCloud» lo encuentra todo.

**También pasa con el teléfono VACÍO** si todavía sincroniza con un iCloud: antes te dejaba entrar y los
gastos de tu grupo acababan en la cuenta del dueño del móvil. Sin copia en iCloud —y solo con prueba— se
pide un segundo gesto; si algo no sube en 45 s, un aviso dice cuántos cambios faltan y deja elegir.

**El verbo se CONSUME, no se reinventa.** La pasada del 10-sep encalló intentando armar el boot-wipe por su
cuenta: declara tres precondiciones que un call-site suelto no cumple. Entrando por el coordinador del
cierre privado se cumplen las tres y se heredan sus redes. **Y el relanzamiento no era una decisión
pendiente**: la matriz del ADR, fila B, ya decía «vuelta al neutro (borra local, iCloud intacto, relanza) y
sigue».

**Lo que costó la review** (tres lentes, 10 defectos míos): el peor es que **el testigo del mount MIENTE en
los hosts de test** — sale por la rama del store de UITest antes de capturarse, así que manda su default
`.iCloudMirror`. Sin seam, la puerta volvía siempre al neutro en XCUITest y **cada corrida armaba un
borrado real** cuya key sobrevive a `-uitest-reset`. Está en la rule de área. Los otros dos graves: los
tres `return` mudos de `signOut` dejaban un progreso eterno sin botón, y apagar el latch de restauración
resultó peor que no apagarlo.

**Verificado sobre el árbol final**: unit **6861/701** en verde, XCUITest **34 casos en 10 clases**, los dos
builds con `clean` y **cero warnings nuevos** (13, los mismos del árbol base), **15 mutantes y 15 muertos**.

## Tu cola

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

**El paso 10** del rediseño. Pasos 0-9 cerrados y la mitad 2 del 5 también; el 11 sigue vacante a
propósito. **El board: 304 en disco = 304 en `docs/TICKETS.md`**, cero desajustes de estado.

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

**Lo que deja la mitad 2 del paso 5, y hay una decisión tuya dentro**
(`groups-invite-on-a-mirrored-store-crosses-data`, **high**): la puerta de CREAR ya no bloquea, pero la
entrada por **invitación** sigue sin puerta — aceptar un enlace en un teléfono que ya espeja manda los
gastos del invitado al iCloud del dueño. Se midió por qué no se cerró de paso: su embudo lo llama también
el reconciler **en el arranque, sin pantalla**, y el intent de la invitación muere en el borrado. Hacen
falta dos piezas nuevas. **Lo que decides tú** es si eso entra antes o después del paso 10.

**Y tres residuales de esa misma sesión**, los tres con ticket y ninguno bloqueante:
`invite-recovery-relaunches-for-a-mirror-it-never-uses` (**medium** — al invitado se le cobra un
relanzamiento para encender un espejo que su camino no usa, y encima lo deja entrando con él),
`sign-out-wipe-abort-loops-the-groups-gate` (**medium**) y
`superseding-intent-can-strand-the-sign-out-coordinator` (**medium** — un enlace de grupo que llegue a
mitad del borrado puede dejar mudo el «Cerrar sesión» de Ajustes del resto del proceso).

**Dos tickets rescatados de una rama sin PR** (`encargo/2026-09-10-…`, que queda superada y se puede
borrar): `forcesync-returns-ok-without-touching-the-network` e `icloud-export-error-latch-never-clears`.
Se midieron el 10-sep, nunca llegaron a `2.1` y los dos siguen vivos — el segundo lo comprobé hoy:
`lastExportError` no se limpia en ningún camino de producción.

**Y una regresión que encontró la review del paso 5** (`groups-only-private-restart-skips-the-wipe-alert`,
**high**): desde solo-grupos, «Primera vez → privado» se salta el aviso de datos existentes. Mitigada
para que no persista entre arranques; abierta dentro de la misma sesión.

**Un residual del paso 4, con ticket** (`late-icloud-wipe-can-re-export-between-its-two-halves`,
**medium**): matar la app entre las dos mitades del borrado tardío puede devolver los datos viejos. Es
reaparición, no pérdida. **El paso 9 NO lo cerró** —sus cierres privados sí entran en la máquina de
`CloudSessionSignOut`, que es justo lo que este caso quería evitar—, pero deja el precedente de borrar
por archivos un store CON espejo después de confirmar el export. Anotado en su ticket.

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
