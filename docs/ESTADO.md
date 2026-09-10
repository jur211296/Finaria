---
updated: 2026-09-10
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-10 (Lima)

**Rama** `2.1` — Merge #132: **«Volver a iCloud» abierta a quien nació en la nube.** TestFlight build
**13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (la reversa se abre a born-cloud, y la review cazó dos defectos graves)

**Creas tu cuenta con Google, la usas meses, y ya puedes pasar tus finanzas a tu iCloud privado.** Hasta
hoy no había salida: el backend rechazaba la operación y la única forma de dejar la nube era borrar la
cuenta. No era un caso raro — tras el fresh start, esa puerta estaba cerrada para **todo el mundo**.

**Eran dos gates que abrir, no un camino que construir.** La premisa del ticket era falsa: la reversa
nunca subió nada a mano — monta el mirror y `NSPersistentCloudKitContainer` exporta solo. `g15_02` está
**aplicada en staging y producción** (md5 idéntico, cero filas afectadas), y el orden es el sano: la base
antes que el cliente, porque al revés el botón aparecería y el servidor lo rechazaría.

**La review adversarial (4 lentes) cazó siete cosas y las dos graves eran de diseño mío.** El gate del
cliente **fallaba abierto** —derivaba «nació en la nube» de la *ausencia* de un marcador que también falta
en un 2.º teléfono de una cuenta **migrada**, o sea que habría abierto el guardarraíl justo para la
población que protege— y el guard del backend **rompía multi-device**: dejaba al segundo teléfono con la
barra clavada al 15 %, para siempre. Los dos corregidos, re-aplicados y verificados con 5/5 escenarios
contra la función viva.

**De paso quedó refutado un ticket que llevaba una semana en pie:** el golden 20 no se cuelga, **tarda
9,3 s** contra un presupuesto de 5 s y pasa en verde con más tiempo.

## Tu cola

1. **Cierra sesión en el iPhone y recrea los grupos de prueba.** Es lo ÚNICO que falta para el device-QA
   del paso 3: el móvil apunta a la cuenta que borró el fresh start y cada llamada da 409/502.
2. **Device-QA del paso 3** — los cuatro recorridos del ticket. Sal del bloqueo **por swipe y por
   «Entendido»**, no solo por el botón; y en el recorrido 1 **fuerza el cierre de la app** antes de darlo
   por bueno. Más los device-QA de los pasos 4, 5, 8, 9 y 10.
2-bis. **Device-QA de la reversa born-cloud → iCloud**, que es lo único de hoy que no es simulable
   (`reverse-cutover-cerrado-para-cuentas-born-cloud`, guion dentro). Dos cosas: el **contador de testigos
   con `ckRecordName`** del panel DEBUG tiene que pasar de 0 a cubrir tus filas vivas —ése es el único
   testigo real de que la subida ocurrió, la pantalla no vale—, y **borra 2-3 transacciones antes de
   empezar**: lo que no debe pasar es que reaparezcan.
3. **Física, la de siempre**: push APNs real (4), RPC de producción (3), sign-in real SIWA/Google (6),
   Apple Pay y carreras de red (4).
4. **De FX quedan cuatro** · **tres veredictos de QA caducos** · **el build 13 no llega al grupo externo**
   hasta pasar beta review.
5. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario.

## Siguiente

**El paso 4** (`welcome-private-fresh-start-skips-icloud-check`). Pasos 0-3 cerrados; el 11 sigue vacante
a propósito. **El board: 164 en backlog, 49 en qa** (271 = 271 contra disco).

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

**Y una decisión tuya, pequeña** (`revert-card-copy-says-datos-regresan-a-quien-nunca-estuvo`): el texto
dice «tus datos **regresan** a tu iCloud» a quien nunca estuvo ahí. Son 16 locales y es voz de producto,
así que no lo toqué — `.claude/rules/l10n.md` dice «no reescribas copy que ya funciona».

**Sigue en pie:** la política de privacidad y los términos **bloquean la publicación** del rediseño. Y las
decisiones tuyas de antes: el filtro de naturaleza, los worktrees sin candado anti-atribución, ¿se ataca
ya el chat caído?, y si `fab-appears-without-animation` sube de `low`. **Sin ticket, medido el 9-sep:** un
CSV exportado antes de convertir una cuenta ya no se importa a ella y aborta el fichero entero.
