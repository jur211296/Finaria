---
updated: 2026-09-11
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-11 (Lima)

**Rama** `2.1` — Merge #141: **soltar la cuenta de grupos ya no puede borrarle los gastos a los demás.**
TestFlight build **13** (CPV 13). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión (el agujero que dejó el paso 10, cerrado)

**Nadie va a perder los gastos de su grupo porque otro suelte su cuenta.** Cuando sueltas tu cuenta de
grupos, Yala borra tus grupos **de este teléfono** — es lo que promete. Podía no quedarse ahí: el historial
de cambios de SwiftData sobrevive al relanzamiento, así que en un **arranque posterior** el canal leía esos
borrados locales, los convertía en borrados de servidor y **les quitaba los gastos a todos los miembros**.
Gente que no tocó nada, viendo desaparecer su dinero de la pantalla.

Lo único que lo impedía era el orden en que corren dos pasos del ciclo de sync, y bastaba con que el
primero fallara —su `catch` se traga el error— para que el agujero se abriera.

**El arreglo no es ninguna de las dos vías que proponía el ticket, y esa es la decisión que más pesa.** El
boot-wipe por ARCHIVOS exigiría **relanzar la app**, y desasociar es un gesto in-session de Ajustes:
convertirlo en «reabre Yala» es un cambio de producto que ni el ADR ni el ticket piden. Y conservar el ancla
del drain —la alternativa escrita— se implementó, se midió y **se retiró**: el ancla es ANTERIOR a esos
borrados, así que no los tapaba; encima clavaba uno de los cuatro suelos del corte de purga del historial,
sin canal que volviera a avanzarlo. ⇒ lo que queda es una tercera vía, más simple y más fuerte: **el borrado
va FIRMADO con el autor del canal**, y el drain descarta por autor antes de traducir. No depende del cursor,
ni de las zonas vivas, ni del orden de `syncCycleOnce`, que era el requisito duro.

**Y arregla de paso un camino que el ticket no nombraba.** La firma vive DENTRO del escritor
(`DataWipeService.deleteLocalGroupsRows`), no en los llamadores, así que el **«Empiezo de cero»** del
Welcome queda cubierto por construcción: sus borrados eran igualmente traducibles, a borrados de los grupos
del humano anterior.

**Lo que costó la review** (tres lentes + la regla de área leída contra el diff): un `rollback` que no
cubría los `fetch` —la misma pérdida de datos por la puerta de al lado—, una aserción que **no podía
fallar** (el campo ya valía `"{}"` por su default de modelo), dos afirmaciones falsas en mis docblocks, y
que **media solución no servía**.

**Verificado sobre el árbol final**: unit **6923/710** en verde, XCUITest 3/3, los dos builds con `clean` y
cero warnings nuevos, **tres mutantes y tres muertos**. Con el agujero abierto salen **2 tombstones de
`SplitExpense`** (medido; el grupo no cuenta, su emisión es `updateOnly`).

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
retirada de M1. Pasos 0-10 cerrados; el 11 sigue vacante a propósito. **El board: 314 en disco = 314 en
`docs/TICKETS.md`**, cero desajustes de estado.

## Bloqueo

**Lo que sale de camino, y el primero es el que más caro sale** (`detach-failure-looks-like-success`,
**high**): si el borrado del desasociar **falla**, la pantalla dice que soltó la cuenta y **no avisa de
nada** — la sesión queda cerrada, la asociación borrada, y tus grupos siguen enteros en el teléfono. La app
y el teléfono cuentan cosas distintas y la que se equivoca es la app. Es preexistente del paso 10, y su
salida está escrita: el hermano «Empiezo de cero» sí tiene alert y canario.

Los otros dos son de testing: `shared-state-guard-misses-wipelocalgroupsdomain` (el guard del trait de
aislamiento busca `wipeAllUserData(` y se le escapa el otro escritor del espejo) y
`spike-r3-eje-4b-flaky-en-suite-completa` (rojo en la suite completa, verde en solitario; su control
negativo afirma un modo de fallo que cambia según lo que corriera antes).
