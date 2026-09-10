---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #133: **«Primera vez → privado» ya le pregunta a iCloud antes de pedir reinicio.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el paso 4, y la review cazó diecinueve cosas mías)

**Reinstalas Yala, eliges «Tu cuenta en tu iCloud privado», y ahora la app mira primero qué tienes
guardado ahí**: te lo dice con cifras y eliges — traerlo, empezar de cero con doble confirmación, o
volver. Hasta hoy te pedía reiniciar y al reabrir te metía en el onboarding **como si fueras nuevo**,
con iCloud bajando tu histórico por debajo. Y se cierra la puerta de atrás: si eliges privado sin poder
validar, el aviso llega el día que iCloud aparece.

**Mandó el criterio de aceptación sobre la premisa del ticket**: reusar `wipeAllUserData` no borra nada
de iCloud con el store local vacío, así que se borra la **zona del mirror en CloudKit** — el primer
lector y escritor de registros de CloudKit del repo.

**La review (4 lentes) encontró diecinueve defectos y los diecinueve eran míos**, con 32 tests verdes y
tres mutantes cayendo. El peor dejaba **el bug vivo**: el gate medía iCloud **Drive**
(`ubiquityIdentityToken`) y `.localNoMirror` adjunta el espejo igual. Y su corrección falló por el otro
lado —apagaba la puerta en toda instalación fresca—; eso lo encontré releyendo el flujo, no las lentes.

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

**El paso 5** (`groups-only-second-launch-mounts-icloud-mirror`, **[adv]**), que retira además la puerta
«datos ajenos». Pasos 0-4 cerrados; el 11 sigue vacante a propósito. **El board: 166 en backlog, 50 en
qa** (274 = 274 contra disco).

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
