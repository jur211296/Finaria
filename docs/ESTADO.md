---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #134: **una sesión solo-grupos ya no baja el iCloud del teléfono.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el paso 5, y la review cazó doce cosas mías)

**Entras por «Vengo por un grupo», creas tu grupo y reabres la app: hasta hoy Yala se conectaba sola al
iCloud del teléfono y te bajaba los datos personales que hubiera ahí** — tuyos de otra época, o de otra
persona. Ahora se queda con lo tuyo en TODOS los arranques, hasta que decidas dónde viven tus datos desde
«Activar Yala completo». Vale igual entrando por invitación. Y se quita el aviso «monté sin iCloud,
reinicia» que a esta gente le salía en cada arranque sin arreglar nada.

**Lo que costó el diseño fue el camino CONTRARIO.** El modo de onboarding viaja por iKV con
never-downgrade, así que un device que RESTAURA de iCloud puede heredar `.groupInvite` con el espejo ya
puesto: derivar el mount de ahí le apagaría el espejo sobre su histórico recién bajado. Por eso la marca
es un hecho de ESTE device, no de la cuenta, y va confinada a `.icloud` sin armar como sus dos hermanas.

**La review (3 lentes) encontró doce defectos y los doce eran míos**, con 14 tests verdes y tres mutantes
ya caídos. Dos graves: desarmaba la marca sin el guard de secundaria —le devolvía el espejo al dueño del
teléfono desde la sesión de otra persona— y la marca sin confinar revivía tras «Volver a iCloud»,
apagando el espejo para siempre. Más un bloqueante de tests: el único cable que enciende la feature no lo
miraba nadie, así que se apagaba en una línea con la suite entera en verde.

## Tu cola

1. **Cierra sesión en el iPhone y recrea los grupos de prueba.** Es lo ÚNICO que falta para el device-QA
   del paso 3: el móvil apunta a la cuenta que borró el fresh start y cada llamada da 409/502.
2. **Device-QA del paso 3** — los cuatro recorridos del ticket. Sal del bloqueo **por swipe y por
   «Entendido»**, no solo por el botón; y en el recorrido 1 **fuerza el cierre de la app** antes de darlo
   por bueno. Más los device-QA de los pasos 4, 5, 8, 9 y 10.
2-bis. **Device-QA del paso 4, y empieza por su punto BLOQUEANTE** (`welcome-private-fresh-start-skips-icloud-check`,
   guion dentro): comprobar que la sonda de CloudKit **no lanza**. Baja una lista de `desiredKeys` única
   sobre una zona multi-tipo, y si el servidor la validara contra el schema de cada tipo, la rama privada
   quedaría en «reintentar» para siempre. El plan B está escrito. Después, los cinco recorridos —y el
   feo: **mata la app a mitad del borrado** y comprueba que al reabrir vuelve a preguntar.
2-quater. **Device-QA del paso 5** (`groups-only-second-launch-mounts-icloud-mirror`, guion dentro). **NO
   es simulable**: sin cuenta de iCloud no hay espejo que adjuntar. Cuatro recorridos, y el que más caro
   sale es el **tercero** —la no-regresión—: restaurar de iCloud tiene que seguir trayéndote tu histórico.
   Si en vez de eso te pide reabrir la app una y otra vez, es el fallo grave de este cambio.
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

**El paso 6** del rediseño. Pasos 0-5 cerrados; el 11 sigue vacante a propósito. **El board: 167 en
backlog, 51 en qa** (276 = 276 contra disco).

## Bloqueo

**Un bug vivo medido hoy** (`settings-migrate-to-cloud-adopts-silently-instead-of-migrating`, **high**):
«Ajustes → migrar a la nube» sobre una cuenta que ya tiene datos **no migra: adopta en silencio**, y te
cobra dos confirmaciones destructivas antes. Tus datos locales se quedan donde están, sin aviso.

**Los goldens de grupos** (`corpus-de-test-de-staging-crece-sin-limite`, **high**): seguían sin dar señal
por timeout, con 702 grupos de un usuario de test. **Dato nuevo:** el deploy de staging subió `f84620b5`
—el fix del canon viejo, sin desplegar desde el 8-sep— así que **un rojo anterior a hoy puede no valer**.
Re-medir antes de perseguirlo.

**Dos que este cambio agranda de un caso raro a toda la población** (los dos **high**, y ninguno lo
introdujo la sesión de hoy): `reverse-upload-has-no-ceiling-and-no-exit` —la subida a iCloud no tiene tope
ni salida, y ahí el backend ya está congelado— y `reverse-claim-rejection-has-no-way-out-in-the-client`.
Los dos son la misma forma: una fase de la reversa sin salida.

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

**Y una decisión tuya, pequeña** (`revert-card-copy-says-datos-regresan-a-quien-nunca-estuvo`): el texto
dice «tus datos **regresan** a tu iCloud» a quien nunca estuvo ahí. Son 16 locales y es voz de producto,
así que no lo toqué — `.claude/rules/l10n.md` dice «no reescribas copy que ya funciona».

**Sigue en pie:** la política de privacidad y los términos **bloquean la publicación** del rediseño. Y las
decisiones tuyas de antes: el filtro de naturaleza, los worktrees sin candado anti-atribución, ¿se ataca
ya el chat caído?, y si `fab-appears-without-animation` sube de `low`. **Sin ticket, medido el 9-sep:** un
CSV exportado antes de convertir una cuenta ya no se importa a ella y aborta el fichero entero.
