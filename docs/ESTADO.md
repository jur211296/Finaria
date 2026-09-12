---
updated: 2026-09-12
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-12 (Lima)

**Rama** `2.1` — Merge #144: **si no se pueden soltar los grupos, la app lo dice en vez de fingir que
soltó la cuenta.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el `high` que el paso 10 dejó abierto)

**Desasociar la cuenta de grupos ya no puede mentir.** Toco «Desasociar» en Ajustes → «¿Dónde viven tus
datos?» → Grupos; si el borrado local falla, la pantalla me decía igual que ya no había cuenta asociada —
y **mis grupos seguían enteros en el teléfono**. Ahora el borrado es la **última condición del gesto, no
su último paso**: si no entra, no se limpia nada, sale un aviso propio, y la sección recuerda que quedó a
medias hasta que se termine, aunque cierre la app y vuelva otro día.

**Se ofrece TERMINAR el borrado, no repetir el gesto, y el porqué está medido.** Rehacer la asociación no
se puede: cuando el borrado corre, las credenciales ya se soltaron. Y repetir el gesto entero vuelve a
entrar por el push-all **después** del teardown —lo que prohíben dos docblocks del propio coordinador— y
un gasto añadido entre medias deja History que ese drain traduce a outbox, quemando 20 ciclos sin
credenciales hasta bloquearse: el desasociar dejaría de poder terminarse **nunca**.

**La review fue en DOS vueltas, y la segunda es la que enseña.** Tres lentes sobre el arreglo, y una
cuarta sobre el rediseño que esas tres me obligaron a hacer — lo que se escribe DESPUÉS de una review no
lo ha revisado nadie. Esa cuarta cazó dos ALTAS mías: **la marca de «a medias» no iba sellada**, así que
«Terminar» podía borrarle los grupos a una cuenta **viva** (quien pulsara «Entrar» y luego «Terminar» se
quedaba dentro de una cuenta cuyos datos acababa de borrar), y **el borrado del cierre de sesión no se la
llevaba** — nombra a sus tres hermanas y se olvidaba de ella. De propina, mi propio docblock afirmaba que
esa función «barre el prefijo `groups.*`» y es una **lista de keys**: el namespace era convención, no
mecanismo.

Y tres defectos preexistentes del mismo gesto, arreglados porque son el mismo objeto: `detachBridge`
devolvía un `Outcome` vacío cuando su `save()` fallaba —el llamador lo leía como éxito y dejaba
transacciones apuntando a una zona sin filas vivas, dinero atrapado que no recoge ningún barrido—, el
aviso de bloqueo describía otro problema, y el «estoy ocupado» era mudo.

**Verificado**: build ×2 sin warnings nuevos, unit **380 en 45 suites**, XCUITest **10** en tres suites y
**catorce mutantes**. Y una trampa nueva en las reglas, que costó tres corridas: **los XCUITest de esta
pantalla van con `Yala Dev`** — con `Yala` la fila de Ajustes no existe (el gate de rollout es fail-closed
sin `DEV_BUILD`), y el rojo se parece mucho al del disco lleno.

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
   gastos tienen que seguir siendo tres, no seis. **Y desde hoy hay un octavo, que es el más caro de todos
   y necesita DOS personas**: desasocia, **mata la app y vuélvela a abrir** —el daño estaba en el arranque
   siguiente, no en el gesto—, re-asocia, y comprueba en el teléfono del OTRO miembro que sus gastos siguen
   ahí. Si desaparecen sin que él toque nada, para el release.
2-decies. **Device-QA del #144** (`detach-failure-looks-like-success`, dentro de su ticket). **NO es
   simulable**, y necesita provocar el fallo: desasocia con el borrado roto y comprueba que la app lo DICE
   y que la pestaña Grupos sigue entera; que «Terminar de soltar la cuenta» funciona **sin sesión viva**;
   y que re-asociar después **no duplica** los gastos que elegiste conservar — tres siguen siendo tres.
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
retirada de M1. Pasos 0-10 cerrados; el 11 sigue vacante a propósito. **El board: 321 en disco = 321 en
`docs/TICKETS.md`**, cero desajustes de estado.

## Bloqueo

**El `high` de testing sigue siendo el primero** (`welcome-chooser-uitests-cannot-reach-the-chooser`):
**siete XCUITest** de `WelcomeChooserUITests` y `SecondarySessionGateUITests` fallan en un worktree limpio
de `2.1` (bisecado, no supuesto). El Hero sale y se tapea; el chooser de nivel 1 no llega nunca. Ciegan el
primer minuto de la app y las dos celdas que el paso 5 escribió para que la puerta de Grupos no volviera a
bloquear al dueño — y la suite de UI ya no corre en los PR, solo en la nocturna.

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
