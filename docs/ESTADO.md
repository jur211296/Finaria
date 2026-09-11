---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #135: **el faro de iCloud ya solo encamina.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el paso 6, y la regla obvia que no habría disparado nunca)

**«Es mi primera vez» con un Apple ID que ya tiene cuenta en la nube ya no decide por ti.** La app sigue
proponiendo entrar en esa cuenta, pero dice de dónde viene —«Este Apple ID ya tiene una cuenta de Yala
creada con Apple»— y ofrece **«Crear otra cuenta»**, que abre el chooser entero, iCloud privado incluido.
**«Esa cuenta usa otro método» dejó de ser una pared:** da entrar con el método de la cuenta o crear cuenta
con el que usaste. Y **el faro que dejó el fresh start se apaga solo** en cuanto el sign-in lo demuestra.

**Tu decisión decía «se limpia en cuanto [I] lo descubre», y la regla obvia no habría disparado nunca.** El
faro guarda el hash del uuid de Supabase, y el fresh start borró `auth.users`: volver a firmar da OTRO
uuid. Lo que sí lo demuestra es el método: Sign in with Apple solo firma con el Apple ID del teléfono, que
es el mismo cuyo iCloud guarda el faro. Con Google no hay forma de demostrarlo, así que ahí el faro se
queda y solo vale «al menos no bloquea». Y `restore-beacon-outlives-account-deletion` **no se cierra**:
su caso ocurre con el kill-switch puesto, donde [I] no corre.

**La review (4 lentes) no encontró nada grave, y arreglé lo de este cambio** —el más serio: cerrar la app
en el chooser de «Crear otra cuenta» abría el onboarding privado sin la puerta de iCloud del paso 4—.
Veinte de veinte mutantes caen, cada uno en su test. **Y el gate tenía un hueco:** no mira los warnings de
los ficheros de test, y dos míos iban al commit (`gate-never-reads-test-file-warnings`).

## Tu cola

1. **Cierra sesión en el iPhone y recrea los grupos de prueba.** Es lo ÚNICO que falta para el device-QA
   del paso 3: el móvil apunta a la cuenta que borró el fresh start y cada llamada da 409/502. **Mira antes
   el orden del punto 2-quinquies.**
2. **Device-QA del paso 3** — los cuatro recorridos del ticket. Sal del bloqueo **por swipe y por
   «Entendido»**, no solo por el botón; y en el recorrido 1 **fuerza el cierre de la app** antes de darlo
   por bueno. Más los device-QA de los pasos 4, 5 y 6.
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

**El paso 7** del rediseño (`onboarding-purpose-drops-groups-card`). Pasos 0-6 cerrados; el 11 sigue
vacante a propósito. **El board: 170 en backlog, 52 en qa** (280 = 280 contra disco).

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

**Un gemelo de lo que arregló el paso 6, anterior a él** (`welcome-cloud-back-leaves-chooser-marked-seen`,
**medium**): volver atrás desde el sign-in de nube deja el Welcome «ya elegido», y cerrar la app ahí abre
el onboarding privado sin la puerta de iCloud.

**Y decisiones tuyas, pequeñas, las tres de copy.** `revert-card-copy-says-datos-regresan-a-quien-nunca-estuvo`:
el texto dice «tus datos **regresan** a tu iCloud» a quien nunca estuvo ahí. Del paso 6:
`welcome-beacon-origin-contradicts-not-found-copy` (con un faro de Google sin cuenta salen seguidas «ya
tiene una cuenta» y «aún no tiene una cuenta») y `born-cloud-signup-lands-on-existing-account-silently`
(«Crear otra cuenta → nube → Apple» entra en la cuenta que ya existe diciendo «Creando tu cuenta…»). Es
voz de producto en 16 locales, así que no las toqué — `.claude/rules/l10n.md` dice «no reescribas copy que
ya funciona».

**Sigue en pie:** la política de privacidad y los términos **bloquean la publicación** del rediseño. Y las
decisiones tuyas de antes: el filtro de naturaleza, los worktrees sin candado anti-atribución, ¿se ataca
ya el chat caído?, y si `fab-appears-without-animation` sube de `low`. **Sin ticket, medido el 9-sep:** un
CSV exportado antes de convertir una cuenta ya no se importa a ella y aborta el fichero entero.
