---
updated: 2026-09-08
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-08 (Lima)

**Rama** `2.1` · HEAD `385e80d3` — las tres decisiones del desbloqueo, implementadas (PR #101).
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web
nueva y firma su correo (SPF + DKIM + DMARC, los tres en `pass`).

## Esta sesión, en una línea

**Cinco decisiones que llevaban semanas quietas se contestaron y las tres que llevaban código están
dentro.** Jürgen las ratificó todas; se prepararon con opciones, coste medido en ficheros y una
recomendación con motivo, y se contestaron con una letra cada una.

**Lo que cambia para el usuario:**

1. **El dueño de un grupo con deuda y sin heredero ya no está atrapado.** Tenía las tres salidas
   cerradas y la app se lo decía con honestidad… callándose la que tenía delante: **«Archivar» ya
   existía en esa misma pantalla y ya funcionaba con deuda**. Ahora el aviso la nombra. No es una
   salida nueva: es dejar de esconderla. «Eliminar» sigue bloqueado, que era el principio a proteger.
2. **El recordatorio de deudas ya llega a quien dijo que sí.** Estaba construido y correcto, y no lo
   recibía casi nadie: nació apagado —bien— pero **se copió ese default de su hermano sin copiar su
   encendido**. Ahora entra en el «sí, avísame» inicial, y su interruptor ya no se puede encender si
   los avisos de Grupos están apagados: antes se podía, se veía en verde y no llegaba nada.
3. **El «≈» vuelve a significar algo.** Bastaba UNA transacción con tasa aproximada para marcar el
   mes entero —editar la nota de una de hace dos años lo conseguía—. Ahora hay que ganárselo: se
   marca cuando lo aproximado pesa **≥5 %** de su propio lado.

## Lo que hay que recordar de cómo salió, porque vuelve a pasar

**La review adversarial se lanzó con los 6448 tests en verde y encontró una regresión mía.** El
«Disponible» del Panel perdía el «≈» justo en el caso peligroso: dos lados grandes, cada uno por
debajo del 5 %, y un neto de 1.000 con 49.000 de incertidumbre. Con el código anterior sí marcaba.
Ningún test lo cubría porque **no existía ningún test del neto**.

**Y el patrón que más escuece: mi fichero nuevo citaba a `FXPnLLogic` como modelo y hacía lo
contrario que él.** `FXPnLLogic` ya había rechazado acumular con signo —«posiciones que se cancelan…
cualquier céntimo pasa el filtro»— y adoptado `Σ|costBasis|`. Yo acumulé con signo, así que un gasto
aproximado y su reembolso aproximado se anulaban y el número salía limpio precisamente cuando menos
lo estaba. **Citar un precedente no es haberlo leído.**

**Ningún test existente cambió de color** al pasar del OR al umbral: los 14 usaban importes iguales,
donde una de seis pesa un 16,7 %. O sea que la batería **no distinguía un criterio del otro**. Un
verde que no se mueve cuando cambias el comportamiento no es una verificación, es un silencio. Los
dos tests que sí lo demuestran están verificados con mutante.

## Las otras dos decisiones, sin código

- **Cobertura de UI**: no se monta el `launchd`. El cron de GitHub **revivió el 8-sep** tras no
  disparar nunca, con 4 h 35 min de retraso. Se re-mira el **22-sep** con muestra de dos semanas.
- **DMARC**: fecha confirmada, **15-sep**. No espera a nadie: espera al calendario.

## Antes, hoy mismo — el correo de `yala-app.pe` (PR #97)

Cerrado. El dominio publica SPF, DKIM y DMARC y un correo real llegó con los tres en `pass`; el
ticket `high` está en `tickets/done/`. Lo que hay que leer en la cabecera **no son los tres `pass`**
sino que firmó con **nuestro** selector (`d=yala-app.pe; s=google`), porque eso es lo único que ningún
`dig` contesta. Detalle completo en el ticket y en la memoria.

## Antes, hoy mismo — la tasa del chat (PR #99)

**El chat guardaba «1,00» como tipo de cambio de un gasto en otra divisa**, aunque el importe
convertido de al lado sí saliera de una conversión real. PR #99, mergeado.

**Lo que cambia para el usuario:** abre el detalle de un gasto que dictó al chat en dólares o en
euros y ve el cambio que se le aplicó, no un 1,00 que no significa nada.

**Por qué no se curaba solo, que era la parte que el ticket tenía mal calibrada.** El reparador de
arranque solo mira las filas marcadas como provisionales. Cuando la conversión es **exacta** —el caso
normal, con la fila de tasas del día completa— la marca queda en `false`, la fila sale de esa cola y
el 1,00 se sellaba **para siempre**. O sea que la ruta guardaba un número falso en la mayoría de sus
ejecuciones, no en la minoría.

**El AC que más valía era el tercero, y se midió:** barrido de las **18 construcciones** de
`TransactionItem` fuera de `Seed` y de tests. Era el **único** sitio del árbol que plantaba una tasa
falsa habiendo conversión real. De los otros doce que pasan `1.0`, once lo hacen de forma transitoria
porque llaman `recalculatePreferredCurrency` acto seguido, y uno es el stub del apply de sync, donde
el grupo `money` llega del wire y recalcular está prohibido. Lo que el barrido sí dejó a la vista: el
init tiene `exchangeRate: Double = 1.0` por defecto, así que **olvidar esa línea de recálculo es
silencioso** — once sitios dependen hoy de ella, y así se llegó a este bug.

**Una premisa del ticket era falsa.** Decía que estas filas «parecen candidatas del barrido legacy
sin serlo». Es al revés: `needsRepair` pide `exchangeRate == 1.0` **y** divisa distinta de la
preferida, que es exactamente el daño. Eran candidatas **legítimas**; lo que las deja sin cura es que
ese barrido es one-shot por dispositivo y su flag se marca aunque no haya candidatas.

**La review adversarial cazó lo mío, otra vez.** Tres lentes: (1) un comentario que yo acababa de
escribir era **falso** — justificaba el umbral diciendo que protegía de «infinito o NaN» cuando la
guard de entrada ya garantiza finito y positivo; está ahí por paridad con el reparador, y escribir
una razón plausible en vez de la verdadera tapaba que esa rama es alcanzable y ahí escribe un número
falso. (2) **Seis defectos en mi propio test**, incluido uno que lo habría puesto rojo *con el fix
puesto* si el simulador tuviera la divisa preferida guardada como `"jpy"`. (3) Un bug ajeno y peor
que éste, ver abajo.

**Verificación:** control positivo por mutación, repetido después de endurecer el test — replantar el
`1.0` pone el caso en rojo con el número real (0,9752 de desvío en JPY→PEN) mientras la pareja de
control, donde `1.0` es el valor correcto, sigue verde. CI leído por dentro y no por su conclusión
(sus pasos son *advisory*): **6.432 tests en 656 suites, cero fallos**.

## Te espera a ti

0. **Las cinco decisiones están CONTESTADAS** (8-sep) y escritas en sus tickets. Las tres con código
   están dentro (PR #101) y pasaron a `qa/`: lo que les queda es device-QA, no trabajo. Las dos de
   calendario siguen en `backlog` — el 15-sep la de DMARC, el 22-sep la de cobertura.

1. **Subir la política DMARC, y no antes del 15-sep** (fecha ratificada al preparar la decisión). Hoy está en `p=none`: observa quién suplanta
   el dominio pero **no lo impide** — un correo falsificado sigue llegando a la bandeja, solo que
   ahora aparece en un informe. Los `rua` llegan a `admin@yala-app.pe` una vez al día, así que el
   primero es de mañana y hacen falta varios. Cuando los haya: comprobar que nada legítimo sale con
   `fail`, subir a `quarantine` (manda a spam, no descarta: un error se recupera) y más tarde a
   `reject`. Ticket con el procedimiento: `dmarc-sube-la-politica-tras-observar`. **Un matiz que
   importa:** medí que en el repo no hay otro remitente, pero eso no cubre un servicio contratado
   desde el navegador —facturación, un formulario, un boletín—; si existe, el informe lo saca y hay
   que añadirlo al SPF **antes** de endurecer.
2. **Staging arrastra ya TRES migraciones** — g13_04 (4-sep), g13_05 y **g14_01** (7-sep). Mismo
   bloqueo las tres: **no hay credencial de DDL** (el conector MCP solo lista producción).
   **El procedimiento ya no hay que reconstruirlo: `docs/RUNBOOK-staging-ddl.md`** — las tres en
   orden, con las dos vías de aplicación, por qué `psql -1` no es opcional en las dos primeras, dónde
   está el bloque de verificación de cada una y las dos trampas de g14_01. Se cierran
   aplicando los tres `.sql` de `qa/cloud/` **en orden**. Es acceso tuyo, no una tarea que se destrabe
   sola. Con g14_01 el drift ya muerde: fijar un presupuesto contra staging deja un dead-letter
   permanente, y un dead-letter apaga el Merkle de ese grupo. Producción está al día.
3. **Desplegar el Worker cuando quieras encender el Merkle nuevo.** El manifest de Grupos va en `c2`;
   hasta que el gateway se despliegue, la verificación Merkle de Grupos queda apagada (los clientes
   saltan por el guard de canon en vez de reportar divergencias falsas). No corre prisa y no rompe
   nada: es una red que vuelve cuando tú quieras. **Corregido el 8-sep: no lo bloquea una credencial.**
   `gateway/README.md` decía que `wrangler` no está autenticado aquí y es falso —medido con
   `wrangler whoami`: OAuth de `admin@yala-app.pe` con `workers:write`—. Lo que lo hace decisión tuya
   es que su último deploy de staging es del **12-ago** y arrastra commits ajenos (`eb6593ce`,
   `6bf0f588`), así que desplegar hoy subiría trabajo de otros sin revisar.
4. **El `schedule` DEJÓ de estar en cero — disparó el 8-sep a las 12:52 UTC**, con 4 h 35 min de
   retraso sobre su ventana. Sigue habiendo decisión tuya (`cobertura-ui-diaria-cuelga-del-push`),
   pero cambia de sentido: ya no es «montar un reloj porque el de GitHub está muerto», es «¿basta con
   el que acaba de despertar?». Mi recomendación es esperar y re-mirar el **22-sep** con muestra de
   dos semanas. **Y un fallo nuevo que sale de ahí:** el margen del vigilante (3 h 26 min) es menor
   que ese retraso, así que el día que su cron despierte cantará un rojo falso —
   `vigilante-margen-menor-que-el-retraso-real-del-cron`. El vigilante sostiene la
   cobertura por su disparador de `push`, y eso deja descubiertos los días sin commits — 8 de los
   últimos 30, con rachas de hasta 3. Las dos salidas: montar un reloj que no dependa de GitHub (un
   `launchd` en la Mini que haga `gh workflow run qa.yml`, que es acceso tuyo) o aceptar que la
   cobertura de UI vaya atada al ritmo de trabajo y no al calendario — que en un repo con esta
   cadencia es defendible, porque un día sin commits tampoco trae código nuevo que probar. No corre
   prisa: hoy la suite corrió.
5. **Del cierre del 2026-09-08 (la tasa del chat, PR #99) — el primero urge más que el ticket que lo
   destapó:**
   - `chat-draft-drops-the-expense-sign` (**high**) — **un gasto dictado al chat SUMA al saldo en vez
     de restar.** `saveDraft` no usa `draft.isExpense` para firmar el monto y su guard solo acepta
     positivos; todas las demás rutas sí firman. Las listas cuadran porque clasifican por categoría,
     pero el saldo suma el monto en crudo. Detalle incómodo: hasta el PR #99 el `1,00` plantado era la
     señal visible de que esa fila no era de fiar, y arreglarlo se la ha quitado. Falta reproducirlo
     en ejecución: la evidencia es de código.
   - **Device-QA pendiente y NO simulable**: ningún seed es multi-divisa, así que para ver el número
     en el detalle hace falta una cuenta en otra divisa y el chat contra el LLM real. Es la **misma**
     limitación que bloquea los device-QA de `fx-pnl-card` y `fx-escrituras-a-mano`: sembrar un seed
     multi-divisa desbloquearía los tres de una vez.
   - `chat-rows-sealed-before-the-fix-have-no-repair-path` (medium) — el fix es forward-only y el
     barrido legacy no vuelve a correr, así que lo ya escrito no se cura. **Puede necesitar decisión
     tuya**: si el corpus es pequeño, quizá no compense re-disparar un barrido sobre toda la tabla.
   - `exchange-rate-detail-shows-zero-for-low-denomination-currencies` (medium) — el detalle formatea
     con `%.4f` y VND→USD (0,0000408) se enseña como **«0,0000»**. Preexistente y general, no del
     chat: esa ruta pasó de un «1,0000» falso a un «0,0000» ilegible.
   - `fx-rate-derivation-threshold-reseals-one-to-one` (low) — la banda `0 < monto <= 0.0001` cae en
     el escape del umbral y vuelve a sellar un 1:1. **No se toca en un solo sitio**: el reparador
     tiene el mismo umbral y romper la paridad haría que la fila cambiara de número al repararse.

6. **Del cierre anterior (la cola del reparador, PR #98):**
   - **Device-QA pendiente y NO es simulable del todo**: hace falta una transacción en una divisa que
     no esté en ninguna cuenta (yenes) fechada en un día cuya fila de tasas ya exista **sin** esa
     divisa. Comprobar que se corrige sola al llegar las tasas, y que abrir y cerrar la app sin
     conexión **no** la reescribe. El canario `fxRepairQueueStuck` con `detail=skipped` debe salir una
     vez por arranque, nunca un barrido entero.
   - `wire-decoder-accepts-non-finite-money` (**medium**, hallazgo de su review) — un importe `NaN`
     puede entrar por el canal nube (`WireValueDecoder.double` no valida finitud) y **no puede volver a
     salir**: el codec lo rechaza al emitir. Mientras esté dentro degenera cualquier guard de igualdad,
     porque `NaN != NaN`, así que esa fila sí se reescribiría en cada arranque. No es una regresión del
     PR: el agujero es anterior y lo único que cambia es que ahora esa fila se comporta distinto al
     resto. Antes de arreglarlo conviene saber **si hay filas así en producción**.
   - `approximate-mark-ors-over-whole-period` — **decisión de producto tuya**: una sola transacción
     aproximada pone «≈» al total del mes, porque la marca se acumula por OR sobre el bucket entero.
     Con más población marcada eso pasa de raro a frecuente en multidivisa, y los tres calculadores
     no usan hoy el mismo criterio.
7. **Decisiones abiertas:**
   - `groups-archived-still-accepts-changes` — el copy promete que un archivado «ya no acepta cambios»
     y acepta todos: gastos, ediciones, liquidaciones, ajustes, invitaciones. Tres opciones dentro.
   - `groups-owner-debt-no-heir-dead-end` (high, del 6-sep) — el dueño con deuda y SIN heredero sigue
     sin salida.
   - **`secondary-onboarding-still-crosses-owner-domain` (nuevo, 7-sep)** — lo que QUEDA de la
     frontera: el prellenado LEE del dueño (y por esa vía hereda `expensesOnlyMode`, que **apaga la
     rama del saldo** que el PR #86 acaba de encender), y `notificationsSeeded` escribe en él. Las
     dos con contrapartida: la divisa heredada probablemente sí se quiere; las notificaciones de la
     visita sonando en un móvil prestado, quizá no. **Decisión key por key, no un barrido.**
   - **`secondary-visit-data-lost-on-signout-unannounced` (nuevo)** — el wipe de salida borra lo que
     la visita apuntó. Es correcto; qué se le cuenta y cuándo son cuatro salidas con contrapartidas.
   - **`groups-settlement-reminder-discoverability` (nuevo, 7-sep)** — el recordatorio de deuda
     funciona y **casi nadie lo va a recibir**: nace apagado (correcto, es dinero que le debes a
     alguien) pero **no entra en el primer de notificaciones**, que es donde se enciende su hermano
     `budgetAlertsEnabled` — se heredó el default sin heredar el encendido —, y además depende de un
     **segundo interruptor invisible**, el `NotificationItem` de Grupos, que también nace apagado:
     quien lo encienda con los avisos de Grupos apagados no recibe nada y nadie se lo dice. Tres
     preguntas dentro; solo la primera es de producto.
   - **`saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas` (nuevo, 7-sep)** — al
     filtrar una cuenta «excluida de estadísticas», el saldo grande muestra el TOTAL, los widgets 0 y
     el KPI 0: **la pantalla se contradice consigo misma**. Tres salidas dentro (0 en las tres, total
     en las tres, o no dejar filtrarlas). Alcanzable desde el carrusel, que sí lista esas cuentas.
8. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme», el freno de la lista,
   «Transferir y salir», la puerta del grupo, la puerta del archivado, la marca de aproximado con su
   corrección del 1:1, el rótulo del hero de Estadísticas, el aviso de visita **y el resumen
   compartible del grupo**.
9. **La tanda de QA: 50 tickets en `qa/`, y el guion solo cubre 22.** Entra
   **`fx-pnl-education-card`** (7-sep), y su device-QA **no es simulable**: la tarjeta de ganancia
   cambiaria sólo aparece con una cuenta multi-moneda con histórico real, y **ningún perfil de seed
   la produce** —son todos PEN—, así que su cobertura de UI es cero por construcción. Hace falta
   dinero en al menos una divisa extranjera, con movimientos a tipos de cambio distintos, para ver
   la tarjeta y su hoja de detalle.
    Entra
   **`groups-shareable-summary`**, y su device-QA tiene algo que el simulador no da: **«Guardar en
   Fotos» es camino nuevo** —la app nunca había escrito en la fototeca— y estrena
   `NSPhotoLibraryAddUsageDescription`; hay que ver además cómo llega la imagen a un chat de WhatsApp
   y que el texto del permiso se lea bien en su idioma. Entra
   **`reentry-killswitch-closes-both-doors`** (7-sep), y es el más caro de montar de los tres: pide
   **conmutar el kill desde el backend** y un móvil limpio por caso. Bajo `-uitest` los flags remotos
   cortocircuitan a su default, así que el estado nuevo **no es alcanzable por XCUITest**: su guion
   está en el ticket, y lleva los identificadores para distinguir las dos terminales, que **se ven
   iguales** (`welcome_reentry_ready` sale a la app, `welcome_born_cloud_ready` al onboarding). Entra
   también
   **`panel-colapsa-la-seleccion-de-cuentas-a-la-primera`**, con escenario paso a paso en su ticket:
   filtrar DOS cuentas desde Registros → Filtros y comparar Panel vs Distribución; repetirlo con
   «excluir» y con el toggle de grupos OFF. Hacen falta **tres cuentas con saldo distinto y no cero**.
   Y entra `welcome-privacy-branch-has-no-secondary-door`: el seam de simulador enciende el descriptor pero
   **no monta** un store secundario, así que falta el e2e con dos cuentas reales — los datos de la
   visita en SU store, su saldo inicial, y que el copy quepa en alemán y neerlandés (solo se vio en
   español). Guion en **`qa/guion-tanda.md`**. Los **17 sin montaje asignado** siguen en
   `qa-guion-tanda-no-cubre-17-tickets`.
10. **La deuda FX del PR #84: el que gobernaba ya está cerrado.**
   `fx-manual-writes-seal-approximate-as-final` pasa a `qa` (PR #94) — eran **catorce** sitios, no
   diez. Era la razón de que la marca de aproximado avisara menos de lo que debía, así que **ahora ya
   se puede probar la marca sin falsos negativos**, que era el motivo de ponerlo primero. Detrás
   siguen `fx-approximate-mark-missing-on-secondary-surfaces` y
   `fx-unknown-currency-code-collapses-to-usd`. Y por delante entra uno nuevo que pesa más que los
   dos: `repair-queue-has-no-exit-for-partial-rate-rows` (high), en el punto 3.
11. **Diez worktrees comparten un solo simulador, y eso rompía el gate de UI sin que se notara.**
   Cerrado el diagnóstico (PR #96) y puesta una guardia que lo **detecta**, pero la contención sigue:
   la sesión que llega segunda al paso 3 espera a mano, sin saber cuánto, y de madrugada no hay nadie
   mirando. Tres opciones en `diez-worktrees-comparten-un-simulador`: **un simulador clonado por
   worktree** (cuesta disco: el device actual son 9,1 GB), **un `flock`** que haga esperar en vez de
   fallar (barato, pero serializa el gate de todos), o **dejarlo en la guardia**. Toca cómo trabajan
   todas las sesiones, así que no lo decide una.
12. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear. Y ratificar o revertir el botón «Más
   tarde» del invitado.

## Abiertos

**Del CI, tres cosas y una se cerró.** (1) **La nocturna no suena sola, y ya está cubierto.** El
`schedule` no sirve ventanas en este repositorio: siete del canario `*/5` en 37 min, cero runs, más
la de `qa.yml` con casi 8 h de margen — y con control positivo, porque el canario lanzado a mano sí
corre. **La cobertura ya no depende de eso:** `nocturna-vigilante.yml` comprueba que la suite de UI
corrió en 26 h y, si no, la lanza y avisa; su reloj bueno es el `push` a `2.1`, que no pasa por el
cron. Verificado de punta a punta en producción. Lo único que queda abierto es de decisión tuya y
está abajo, con ticket propio: `cobertura-ui-diaria-cuelga-del-push` (medium). El diagnóstico
está cerrado: `la-nocturna-de-ui-no-ha-disparado-ni-una-vez` (done). (1b) Los **topes sí aguantan**, ya con corridas reales: 21 runs del job,
mediana 21,7 min y máximo 34,0 contra un tope de 45, cero cancelaciones. El colchón es menor de lo
previsto (1,32× en vez de 1,5×), así que si build o unit crecen otro 30 % se sube el tope, no se
quita. (2) `ci-checkout-v4-runs-on-deprecated-node`
(low): cada run deja un warning de Node 20 deprecado que GitHub ya está forzando a Node 24; son dos
líneas y no corre prisa, pero el ruido permanente entrena a no mirar las anotaciones, que es donde
este repo pone los avisos que sí importan. (3) `ci-workflow-cites-missing-testing-strategy` (low): el
workflow manda tres veces a un documento que no está en el repo.

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una decisión
tuya** (4, las de arriba).

**Ruido del gate — antes de anotar cualquier muestra, clasifica el rojo.** `grep -c "Test Case .*
failed"` sobre el log: **0** con un bloque `Failing tests` ⇒ murió el runner (otra corrida encima),
no hay veredicto y esos nombres no se archivan; **>0** con su mensaje de aserto ⇒ eso sí es un rojo
de test. Y `bash qa/scripts/sim-libre.sh` antes de correr.

- **`transaction-save-helper-flake-one-per-suite` (nuevo, medium).** Toda corrida completa de
  `YalaUITests` acaba con **un** fallo en el mismo aserto («no apareció la pantalla de éxito de la
  transacción», `XCUIApplication+Yala.swift:208`) y **la víctima cambia**: `QuickActionsFavorites`
  dos veces, `EdgeCases.test_extremeMinimumAmountSaves` la tercera —con la primera pasando esa vez—.
  Bisecado con 17 muestras contra el árbol base; la que lo zanja **falló con un único fichero
  cambiado cuyo parámetro nuevo no lo pasa nadie**: un fallo sin causa posible ⇒ ruido del
  instrumento, no regresión. El ticket lleva un **reproductor de 3 minutos** (4 suites + la suya) para
  que nadie repita las dos horas de bisección. **Aviso que va en el propio ticket:** este mismo aserto
  ya cazó una rotura REAL (el `.alert` con label dinámico), así que **no se descarta sin medir**.
  **Cuarta medición (tarde): la condición es la TANDA, no la corrida completa.** Con **cinco** suites
  ya sale, y en aislado pasa. Lo que lo zanja en cuatro corridas y sin bisecar: **el mismo comando en
  los dos árboles** —`HEAD` limpio falla idéntico, 11 tests y 1 fallo—. Correr aislado en el base y en
  tanda en la rama diría «es tuyo» y sería falso. ~~Ninguna de las 21 muestras se ha tomado con el disco
  sobre 25 GB~~ — **hecha el 7-sep y el umbral no cambia nada**: el reproductor de 5 suites da
  11/11 verde tanto a 25 GB como a **12 GB forzados**, doce corridas seguidas. (La afirmación era
  falsa además por otro lado: `edgecases` ya documentaba un fallo **con 26 GB**.)
  **Muestra 18 (7-sep, tarde): falla con CUATRO tests y le toca al PRIMERO por orden alfabético.**
  Corriendo solo los cuatro candidatos con `-only-testing` —sin las suites que los preceden— sale
  igualmente un único rojo (`EdgeCases`, 60,4 s) y los otros tres pasan. Eso **debilita la hipótesis
  de acumulación a lo largo de la corrida**: aquí no hay nada acumulado delante. Quedan en pie la
  race real en el guardado y el presupuesto de 10 s de la espera — y la primera es la que importaría
  en un teléfono, donde no hay aserto que la cace.
- ~~`rojo-xcuitest-runner-muere-tras-el-primer-caso`~~ **cerrado el 7-sep (PR #96)**: no era el
  entorno, eran **dos corridas a la vez sobre el único simulador**. Ver «Esta sesión». Lo que deja
  vivo: `bash qa/scripts/sim-libre.sh` **antes** de cualquier medición de UI, o la muestra no vale.
- ~~`unit-suite-nondeterministic-reds`~~ **cerrado el 7-sep (PR #95)**: la suite es determinista y el
  no-determinismo estaba en el grep que la contaba. Ver «Esta sesión».

**El entorno, con una medición nueva.** El disco bajó a **7,1 GB** (umbral 25) tras dos horas de
corridas encadenadas; un `simctl erase` lo devolvió a 12 GB — y **no eliminó el flake de arriba**, que
volvió a salir en la corrida hecha desde el simulador recién borrado. El disco libre absoluto **no**
es su variable. Antes de perseguir un rojo de UI: mirar memoria **y** disco, y repetir aislado.

**Y una causa nueva del disco, medida el 7-sep: un SNAPSHOT LOCAL de Time Machine nacido a mitad de
la corrida.** Con él puesto, **liberar espacio no libera nada** — retiene los bloques borrados —, así
que un `simctl erase` que quitó 4,4 GB del simulador dejó el disco **peor** (10 → 5 GB) en vez de
mejor. Borrarlo (`tmutil deletelocalsnapshots <timestamp>`, solo el timestamp: el nombre completo da
«is not a valid disk») devolvió **9 GB de golpe**, 4,2 → 13 GB. `disk-report.sh` **sí** los cuenta,
pero el informe del arranque decía 0 porque el snapshot **nació después**. ⇒ cuando liberar disco no
suba el número, mira los snapshots antes de seguir borrando; y re-mide el disco **durante** la sesión,
no solo al abrirla.

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea, no
abras la línea citada. **Y la premisa del ticket —y la del encargo— también caduca.**

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**176 tickets · backlog 94 · qa 54 · blocked 2 · done 21 · discarded 5 · in-progress 0.**
Recontado sobre disco el 8-sep en `2.1` tras mergear el PR #101, con
`find tickets/<estado> -maxdepth 1 -name '*.md'`. **`in-progress` queda VACÍO**, que es lo coherente
con la cola autónoma en pausa: `groups-budget` llevaba ahí desde el merge del PR #91 diciendo que
había trabajo cuando lo que queda es device-QA, y pasó a `qa/`. Entran dos hallazgos de esta sesión
—`vigilante-margen-menor-que-el-retraso-real-del-cron` y
`qa-cloud-readme-sin-entradas-g13-04-y-g13-05`— y el resto de la diferencia son tickets de otras
ramas mergeadas entretanto. `docs/TICKETS.md` cuadra fila a fila y con su cabecera:
**174 = 174 = 174**, cero huérfanos en ambas direcciones, orden alfabético comprobado.

**El índice tenía además un defecto de forma que ningún conteo detecta:** la fila de
`dmarc-sube-la-politica-tras-observar` estaba **antes** de la cabecera de la tabla, así que Markdown
la renderizaba como párrafo suelto y quedaba fuera del índice sin faltar de él. Reinsertada en su
sitio alfabético.

**Y el conteo anterior venía desviado en tres** (declaraba `blocked 3`, `done 20`, `backlog 92`
cuando en disco había 2, 21 y 93 antes de esta sesión). Se confirma lo que ya avisaba la línea de
abajo: **recuéntalo, no lo heredes.**

Histórico del recuento anterior:
**171 tickets · backlog 92 · qa 50 · blocked 3 · done 20 · discarded 5 · in-progress 1.**
Recontado sobre disco el 8-sep en `2.1` tras mergear el PR #99: sale
`chat-assistant-plants-exchange-rate-one` a `qa` y entran **cuatro** hallazgos, tres de su review
adversarial y ninguno suyo — `chat-draft-drops-the-expense-sign` (**high**, el que más importa: un
gasto dictado al chat suma al saldo en vez de restar), `chat-rows-sealed-before-the-fix-have-no-repair-path`,
`exchange-rate-detail-shows-zero-for-low-denomination-currencies` y
`fx-rate-derivation-threshold-reseals-one-to-one`. `docs/TICKETS.md` cuadra fila a fila y con su
cabecera: **171 = 171 = 171**, cero huérfanos en ambas direcciones.

**Y el conteo de la línea anterior estaba desviado en 2 antes de esta sesión** (declaraba 165 con 167
en disco): entre aquel recuento y éste entraron dos tickets de otras ramas. La línea se vuelve a
desviar en cuanto otra sesión mergea, así que **recuéntala, no la heredes.**

## Trampas al recontar el board (vivas — rescatadas de los históricos podados el 8-sep)

Las cuatro han mordido ya, y **las dos primeras volvieron a morder el 2026-09-08**, estando escritas
aquí. Léelas antes de recontar, no después:

- **`ls tickets/<estado> | wc -l` NO da el número de tickets.** Cuenta los `.gitkeep`, las capturas
  `.jpg`/`.png` que algunas sesiones dejaron dentro y el directorio de evidencia de
  `welcome-privacy-secondary`. Medido el 8-sep: `ls` da `qa 53` y `done 24` donde hay 51 y 21. El
  conteo bueno es `find tickets/<estado> -maxdepth 1 -name '*.md' | wc -l`.
- **El índice tiene DOS tablas.** La de arriba es el índice (3 columnas); la de abajo es el mapa de
  origen de YalaWiki (2 columnas, y su segunda también dice `tickets/`). Un filtro laxo cuenta las
  dos: el 8-sep un `startswith("| ")` dio **234** donde había 174. Ancla el número de columnas
  (`NF>=5 && $4 ~ /tickets\//`), no el contenido.
- **Una regex de id que no acepta MAYÚSCULAS inventa huérfanos.**
  `rojo-heroBuckets-thisWeek-trailing-window` se escapa de `[a-z0-9-]+` y aparenta faltar del índice.
  Ya provocó un duplicado el 7-sep, cuando una sesión «lo encontró» y añadió su fila. Ante una
  discrepancia, **sospecha primero del filtro** y córrelo con un patrón laxo antes de tocar nada.
- **El owner map del final apunta a las carpetas de ORIGEN de la migración**, no al estado de hoy, así
  que algunas de sus rutas «no existen» y es correcto. No es un puntero roto.

**Y antes de abrir ticket por un rojo, greppea el board por el aserto, no por el nombre del test** —
la víctima cambia entre corridas y el nombre no encuentra nada. Costó un ticket duplicado el 7-sep.

**El histórico anterior de recuentos se podó el 8-sep**: cinco niveles acumulados que ya solo eran
rastro. `git log -- docs/ESTADO.md` los tiene enteros.
