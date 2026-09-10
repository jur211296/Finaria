# Mitad 2 del paso 5: groups-entry-on-a-mirrored-store-still-blocks-the-owner

## Contexto
Jürgen 2026-09-10 eligió esto **antes** del paso 6 del rediseño. Mitad 1 ya en `2.1` (PR #134): alta solo-grupos deja neutro duradero. Esta mitad: «Vengo por un grupo» con store que **ya lleva espejo** sigue bloqueando al dueño con la puerta «datos ajenos».

Lo medido (ticket): desmontaje en caliente rechazado (`mountAdmitsSwap` / spike R3); borrar con espejo montado exporta deletes a iCloud; no existe «esperar al export» en el repo. El ADR §2-3 pide: nunca bloquear — volver al neutro (esperar export, avisar sin confirmar, borrar local, iCloud intacto, neutro duradero) y seguir al sign-in.

Permisos: **auto** (pregunta lo que toca).

Avisos a Frank: (1) decisión/acceso de Jürgen; (2) PR; (3) `/cerrar-total` resumen producto; (4) idle — una vez.

## Que se pide
1. Leer ticket entero + Paso 0 del padre si aplica + ADR §2-3 + spike R3 / PersonalContainerSwap / PersonalSwapReleaseLogic.
2. Diseñar e implementar el camino viable para estado B **sin** destruir el corpus de iCloud. Si el camino es caro (espera de export + ensanchar swap), haz `/spec` + Plan + `/review-plan` y review adversarial; no improvises un wipe con espejo montado.
3. Retirar la puerta «datos ajenos» solo cuando la vuelta al neutro esté segura.
4. Un PR a `2.1`; board + `docs/TICKETS.md`; device-QA CloudKit → `tickets/qa/` si el sim no basta; `/cerrar-total`.

## Que NO hay que tocar
marketing/. Paso 6+ del runbook salvo lo mínimo. Ampliar wipe a prod. Reabrir mitad 1 ya mergeada.

## Como se sabe que esta bien
Criterios del ticket; dueño ya no queda atrapado; iCloud del corpus intacto tras la vuelta al neutro; PR mergeado; `/cerrar-total`.

## Paso 0 — decisiones

> Las dos primeras las contestó **Jürgen en esta sesión** (2026-09-10), no son bypass autónomo. Las
> demás las resolví yo contra el árbol y se discuten en el PR.

### D1 · Cómo se vuelve al neutro con el espejo ya montado → **pantalla de reabrir** (Jürgen)

La medición corrigió una de las dos premisas que pararon esta mitad el 2026-09-10 (D3 del ticket
padre): «borrar lo local con el espejo montado borra también iCloud» es cierto de `wipeAllUserData`,
que borra **filas**, pero **no** del camino del swap ni del boot-wipe, que borran **archivos** tras
soltar el container — y el propio `SwiftDataConfiguration:610-617` dice por qué se hace así («los
deletes de filas quedan en la History y el remount los replayaría hacia iCloud»). Con la premisa
corregida, la vía sin relanzar volvía a estar sobre la mesa; se le preguntó con las dos opciones
medidas y eligió **no tocar el swap**: armar `armSignOutWipe`, avisar y pedir que reabra. El precio
—una pantalla en un camino que solo pisa quien ya adjuntó espejo por otra rama— lo aceptó; la matriz
de escenarios, fila B, ya decía «relanza».

**Lo que NO se hace, y es la mitad de esta decisión:** no se ensancha `PersonalSwapReleaseLogic.mountAdmitsSwap`,
así que el residual del eje 3 del spike R3 (el trabajo de CloudKit que sobrevive 10 s al release)
sigue cerrado donde estaba.

### D2 · Qué pasa si queda algo sin subir a iCloud → **«un momento más» hasta que suba** (Jürgen)

Es su regla del 2026-09-09 («nunca borra sin subir») aplicada aquí, aun sabiendo que frena unos
segundos la entrada a Grupos. Se implementa con lo que existe —`forceSync` (que despierta el motor,
prueba la red de verdad con `allRecordZones()` y hace `save()` de lo local) + quiescencia con tope, y
**no armar si hay error de export**— y no construyendo la espera fina, que la matriz asigna
explícitamente al **paso 9** (`session-exits-one-verb-per-session`, «HUECO grave: nadie espera al
export hoy»). Duplicarla aquí sería adelantar su pieza.

### D3 · Sin cuenta de iCloud pero CON datos locales → **preguntar, con dos gestos** (Jürgen)

Es el único caso donde «tus datos siguen a salvo en iCloud» es falso: sin cuenta, ese histórico solo
vive en ese teléfono. Alcanzable (device sin iCloud cuyo dueño cerró sesión con `.privateReset`, que
no borra datos). Se le dice la verdad y elige. Coincide con la forma que el ADR §9 ya usa para
«Primera vez → privado» y con la regla de que la app pregunta cuando la decisión mueve datos suyos.

### D4 · El disparador es el TESTIGO DEL MOUNT, no el contador de filas (Frank)

`hasExistingData` cuenta **grupos y filas puenteadas**, y el borrado de arranque **no toca el store de
Grupos** (ADR §6). Dejarlo como disparador manda a bucle de «reabre la app» a cualquiera con grupos
locales — el fallo que el device-QA del padre marca como grave. Se usa `checkHasPersonalData` (el
detector estrecho que ya existe al lado) **más** `mirrorsToICloud` del testigo del mount: mientras el
espejo esté adjunto, lo que la sesión de grupos escriba —las filas del bridge, que corre por
defecto— sube al iCloud del Apple ID de este teléfono. Por eso dispara también con el store vacío.

### D5 · El bucle se corta con un término propio, no con un contador (Frank)

Si el borrado de arranque estaba armado y el proceso montó igual, es que **no corrió** (el guard S3 de
`performSignOutWipeIfArmed` aborta sin desarmar). Ese hecho es el término `cleanupAlreadyArmed` →
`.blockedCleanupFailed`, con copy honesto. Sin él, un fallo de borrado pide reabrir para siempre.

### D6 · Tras reabrir se vuelve al chooser, no al alta (Frank)

`WelcomePendingDestinationStore` ya tiene `.groupsOrganizer`, y su consumo lo manda al chooser **a
propósito** (`ContentView.swift:1602-1608`: «jamás retomar una rama organizador a mitad en un proceso
que no ha visto su puerta»). Se respeta: un toque más, y no se invade
`groups-organizer-intent-is-lost-on-relaunch`, que depende del paso 12. Lo que sí se hereda gratis es
el auto-exit en background, cuyo testigo ya es genérico («hay destino pendiente», `YalaApp.swift:195`).

### D7 · Se reusa `armSignOutWipe`, sin arm nuevo (Frank)

Hace exactamente lo que este camino necesita y nada que estorbe: borra los archivos del store personal
y de syncMeta, **no** los de Grupos (no se marca `signOutWipeIncludesGroups`), resetea las preferencias
personales —`groupsBetaUnlocked` está excluido del barrido— y borra `hasShownWelcomeChooser`, de modo
que el arranque siguiente cae en `.neutralNoMirror` por `freshInstall`. No cierra ninguna sesión de
nube: eso es de `CloudSessionSignOut`. Cero infraestructura nueva.

### D8 · El testigo del mount se lee por un SEAM, porque bajo UITest miente (Frank)

`personalStoreMountedDecision` devuelve su default `.iCloudMirror` en los hosts de test y de UITest
(`personalConfiguration` retorna antes de capturarlo). Leerlo crudo haría que **todos** los XCUITest
de la rama organizador cayeran en `.returnToNeutral` sobre un simulador que no tiene iCloud. Se lee por
`ICloudPersonalCorpusProbe.mirrorsToICloudNow`, que bajo UITest devuelve `false` salvo hook explícito
— y ese hook es lo que permite cubrir las dos ramas nuevas en simulador.
