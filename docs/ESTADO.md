---
updated: 2026-09-11
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-11 (Lima)

**Rama** `2.1` — Merge #140: **la cuenta de grupos se ve, se suelta y se vuelve a poner.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el paso 10: la cuenta de grupos deja de ser invisible)

**Tu cuenta de grupos ya tiene una pantalla.** Hasta hoy, quien usa Grupos con sus finanzas en su iCloud
privado no tenía forma de saber CON QUÉ cuenta las usa, ni de soltarla sin cerrar la sesión entera. Ahora,
en Ajustes → «¿Dónde viven tus datos?», una sección **Grupos** dice el correo de esa cuenta, ofrece
asociar una si no hay, y deja **desasociarla** — preguntando antes qué pasa con los gastos de grupo que ya
están en el Panel: conservar los que pagaste tú, o quitarlo todo. **Las dos salidas, decisión tuya del
9-sep, implementadas y probadas.**

**Y la asociación viaja contigo**: va al iCloud-KV de tu Apple ID, así que tu segundo móvil —o éste tras
«Restaurar desde iCloud»— sabe que existe aunque la sesión no viaje, y te ofrece **entrar** con ella en vez
de proponerte crear la cuenta que ya tienes. Era el hueco de la fila «D · N» de la matriz.

**El «enlace dormido» que pedía el ticket era IMPOSIBLE tal cual, y esa es la decisión que más pesa.**
`TransactionItem` **no tiene identidad propia serializable** (ni `id`, ni UUID estable: `syncID` es
opcional y en sesión privada es `nil`), así que «devuélvele el puntero a ESA fila» no se puede escribir sin
inventar un ancla. Y dejarlo puesto —la lectura literal del ticket— deja el movimiento **ATRAPADO**: ni
editable ni borrable, sobre un gasto que ya no existe, y ningún barrido lo repara. ⇒ Se entrega la mitad
que el criterio persigue de verdad (**cero duplicados**, con un libro sellado por el `sub` de la cuenta) y
el re-ENLACE queda con ticket y con su vía real: campo nuevo **con deploy de schema coordinado**.

**Lo que costó la review** (tres lentes, 12 defectos míos): el peor es que **desasociar no era durable** —
el otro dispositivo del Apple ID, con su sesión viva, reponía la asociación en su siguiente arranque y el
gesto se deshacía solo; ahora hay tombstone. Los otros tres graves: la asociación se escribía DESPUÉS de
arrancar el canal, así que un pull rápido duplicaba cada gasto conservado; `.remove` se llevaba por delante
puentes de grupos de la era CloudKit —dinero real, en un store sin espejo que lo reponga—; y el CTA
apostaba a un `sleep` de 350 ms sobre un flag que bloquea el router de toda la app.

**Verificado sobre el árbol final**: unit **6918/709** en verde, XCUITest **18 casos en 4 suites**, los dos
builds con `clean` y **cero warnings nuevos** (los 8 mismos ficheros del árbol base), **20 mutantes y 20
muertos**.

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
2-nonies. **Device-QA del paso 10** (`device-qa-groups-account-association`, guion de siete recorridos
   dentro). **NO es simulable**: el simulador no tiene sesión de nube. El que más caro sale es el
   **quinto**: desasocia en un teléfono, abre el otro del mismo Apple ID, y comprueba que la asociación
   **sigue soltada**. Si reaparece, el tombstone no está llegando y el gesto se deshace solo. El tercero
   es el que prueba lo demás: re-asocia la misma cuenta y **cuenta los movimientos del Panel** — tres
   gastos tienen que seguir siendo tres, no seis.
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
retirada de M1. Pasos 0-10 cerrados; el 11 sigue vacante a propósito. **El board: 311 en disco = 311 en
`docs/TICKETS.md`**, cero desajustes de estado.

## Bloqueo

**Lo que deja el paso 10, y el primero es el que más caro sale**
(`detach-history-replay-can-tombstone-groups-on-next-launch`, **high**): desasociar borra las filas de los
grupos por FILAS, y en un arranque posterior el canal puede leer esos borrados del historial y
**convertirlos en tombstones que borren los gastos para todos los miembros del grupo**. Hoy solo lo frena
un efecto colateral del orden de `syncCycleOnce`, no una defensa: la forma correcta —borrar ARCHIVOS antes
del mount, como hacen los tres cierres del paso 9— está escrita en el ticket.

**Y el segundo es de producto** (`cloud-killswitch-hides-the-only-door-to-detach-groups`, **high**): si
bajas el kill-switch de la nube por un incidente, la fila «¿Dónde viven tus datos?» desaparece — pero
Grupos sigue encendido, porque tiene su propio interruptor. Quien tenga cuenta asociada se queda sin
ninguna pantalla desde la que soltarla. Hasta este paso esconder esa fila era inocuo. **Decisión tuya**
entre las dos salidas del ticket.

**Un bug vivo medido el 10-sep** (`settings-migrate-to-cloud-adopts-silently-instead-of-migrating`,
**high**): «Ajustes → migrar a la nube» sobre una cuenta que ya tiene datos **no migra: adopta en
silencio**, y te cobra dos confirmaciones destructivas antes. Tus datos locales se quedan donde están, sin
aviso. **El paso 10 le entregó la mitad que le faltaba**: ya se sabe cuál es la cuenta de grupos asociada
(`isAssociatedGroupsAccount`), que es lo que esa puerta necesitaba para promover la correcta.

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
