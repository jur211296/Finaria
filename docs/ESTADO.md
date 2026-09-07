---
updated: 2026-09-07
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-07 (Lima)

**Rama** `2.1` · HEAD `9498b9b3` — al cerrar un viaje puedes mandar al chat una imagen con las cuentas
del grupo y los pagos mínimos para saldarlas.
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web
nueva.

## Esta sesión, en una línea

**El resumen compartible del grupo ya existe** (PR #90). En Ajustes de un grupo, «Compartir resumen»
genera una **imagen** con el total gastado, quién puso qué y la lista mínima de pagos para saldarlo
todo, y la manda por el share sheet: WhatsApp, Mensajes, Guardar en Fotos. Cubre **todo el historial**
—no el período filtrado en Estadísticas, decisión tuya del 6-sep— y con gastos en varias monedas cada
una lleva su bloque, sin sumarse jamás entre sí. Si no queda nada pendiente, lo dice. Solo lectura.

**Primera vez que la app genera una imagen**, así que la tarjeta va con dos reglas que no son
estética: ni un `@Environment` dentro —`ImageRenderer` hostea su contenido fuera del árbol y una
sub-vista que lea `AppPreferences` daría `SIGTRAP`, la trampa de las `.annotation` de Swift Charts— y
colores fijos en claro, porque la imagen sale de la app y no puede depender del tema de quien la mandó.

**Las tres lentes cazaron nueve defectos míos, y otra vez el más caro fue un razonamiento explícito y
equivocado.** Había escrito que los pagos irían siempre por moneda cruda, «porque una conversión al
cambio del momento se congela en una imagen»: bueno para los totales, **falso para los pagos**, porque
se me escapó que «ver deudas en una sola moneda» también decide **en qué moneda se ESCRIBE la
liquidación**. Con ese ajuste puesto, una cena de US$ 100 pagada en soles dejaba la deuda viva en
dólares y el pago como deuda inversa en soles: la imagen habría mandado al chat **dos transferencias
fantasma en direcciones opuestas por dinero ya pagado**, contradiciendo a Balances. Los otros ocho:
se ofrecía en grupos **migrados y congelados** (que enseñan una copia vieja, y la imagen se fecha hoy);
el botón lo decidía un proxy que contaba los saldos iniciales y dejaba pasar grupos que producían una
**tarjeta en blanco**; los **repartos no se deduplicaban** —solo los gastos—, con el total blindado y
«le tocaba» al doble; **sin techo de tamaño**, 40 personas × 4 divisas dan 38 940 px a escala 3, el
doble del techo de textura, y un bitmap de ~336 MB; y faltaba **`NSPhotoLibraryAddUsageDescription`**,
sin la cual «Guardar imagen» crashea — es la primera vez que la app escribe en la fototeca.

**Y una explicación mía que era falsa aunque la medición fuera buena.** Documenté que la columna «le
tocaba» descuadra «porque el reparto asigna los céntimos gasto a gasto». Lo que vi en el simulador era
cierto (123,34 × 3 contra 370), pero la causa no: `GroupSplitCalculator.equalSplit` **sí** reparte el
residuo y cuadra exacto — el descuadre era del **seed**. En producción existe por otras vías (el
reparto exacto tolera ±0,02; los importes del wire no pasan por el calculador). ⇒ un comentario que
dice «medido» y explica mal lo medido es peor que no tenerlo.

**Dos mutantes sobrevivieron a su primera pasada**, los dos por la trampa del helper ciego: el del
orden de monedas usaba PEN/USD, donde «la principal primero» y «alfabético» **coinciden**. Salió dos
veces en el mismo cambio. Nueve mutantes verificados al final, uno por decisión.

## Te espera a ti

1. **Staging arrastra ya DOS migraciones** — g13_04 (4-sep) y g13_05. Mismo bloqueo las dos: **no hay
   credencial de DDL** (el conector MCP solo lista producción, `~/Secrets/yala-supabase-test/` solo
   tiene JWTs de usuario). Se cierran aplicando los dos `.sql` de `qa/cloud/` en orden. Es acceso tuyo,
   no una tarea que se destrabe sola.
2. **Decisiones abiertas:**
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
3. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme», el freno de la lista,
   «Transferir y salir», la puerta del grupo, la puerta del archivado, la marca de aproximado con su
   corrección del 1:1, el rótulo del hero de Estadísticas, el aviso de visita **y el resumen
   compartible del grupo**.
4. **La tanda de QA: 46 tickets en `qa/`, y el guion solo cubre 22.** Entra
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
5. **La deuda FX del PR #84, y el orden importa.** **`fx-manual-writes-seal-approximate-as-final`
   (high)** gobierna a los otros: diez sitios que GUARDAN un importe convertido lo sellan como
   definitivo aunque la tasa fuera aproximada. **Es la razón de que la marca nueva avise menos de lo
   que debería**, así que probar la marca antes de cerrarlo da falsos negativos. Detrás:
   `fx-approximate-mark-missing-on-secondary-surfaces` y `fx-unknown-currency-code-collapses-to-usd`.
6. **Dos decisiones de la web**, sin cambios: el texto legal de Grupos (dice «vía iCloud» y el backend
   propio está al 100 % en prod) y si Vercel despliega al mergear. Y ratificar o revertir el botón «Más
   tarde» del invitado.

## Abiertos

**`in-progress` vacío.** Lo vivo espera la tanda de QA, hardware (los 2 de `blocked`) o **una decisión
tuya** (4, las de arriba).

**Ruido del gate — el rojo del helper de guardado ya tiene condición, y los dos viejos siguen sin
aparecer.**

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
  tanda en la rama diría «es tuyo» y sería falso. **Ninguna de las 21 muestras se ha tomado con el
  disco sobre 25 GB**: es la comprobación barata que queda.
  **Muestra 18 (7-sep, tarde): falla con CUATRO tests y le toca al PRIMERO por orden alfabético.**
  Corriendo solo los cuatro candidatos con `-only-testing` —sin las suites que los preceden— sale
  igualmente un único rojo (`EdgeCases`, 60,4 s) y los otros tres pasan. Eso **debilita la hipótesis
  de acumulación a lo largo de la corrida**: aquí no hay nada acumulado delante. Quedan en pie la
  race real en el guardado y el presupuesto de 10 s de la espera — y la primera es la que importaría
  en un teléfono, donde no hay aserto que la cace.
- **`rojo-xcuitest-runner-muere-tras-el-primer-caso` (high) NO se reprodujo, y esta vez con volumen.**
  **Tres corridas completas de 134 casos cada una**, todas ejecutando los 134 (el 6-sep moría tras el
  primer caso de CADA suite). Es la segunda sesión seguida sin verlo. Sigue sin descartarse, pero ya
  no es «una sola observación».
- **`unit-suite-nondeterministic-reds` (high): tampoco.** La suite unit completa pasó entera dos veces
  hoy — **6272 tests en 637 suites**, 89 s. Tercera sesión sin reproducirlo.

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

**143 tickets · backlog 74 · qa 46 · blocked 2 · done 16 · discarded 5 · in-progress 0.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(143 = 143, cero huérfanos en ambas direcciones, y ningún estado discrepante entre fila y carpeta).
**El índice traía dos defectos que nadie había visto**, los dos arreglados: una fila de datos **por
encima de la cabecera de la tabla**, y dos punteros del mapa de origen apuntando a `in-progress/`,
que está vacío desde hace días. **Todo cierre incluye `docs/TICKETS.md`**, y lo que
salga de camino lleva ticket propio — esta sesión sacó **tres**:
`panel-lee-el-filtro-de-cuentas-en-singular-fuera-del-saldo` (el subtítulo «en N cuentas» cuenta todas
mientras el saldo filtra; y el prefill del formulario propone una cuenta arbitraria, en modo excluir
la excluida), `saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas` y
`filtro-de-cuentas-se-colapsa-al-navegar-a-registros`. La del kill-switch sacó **dos** más, los dos
de la review adversarial: **`restore-beacon-outlives-account-deletion`** —el faro que decide el
mensaje sobrevive al borrado de cuenta (su `clear` es best-effort y el `set` tuvo toda la vida de la
cuenta para propagarse), y de paso deja escrito que **el usuario MIGRADO —el único que existe hoy en
producción— ve su copia de iCloud congelada pre-migración sin que nada le avise de que es vieja**— y
**`adopt-terminal-claims-ready-without-checking-engine`**, que la pantalla de «listo» se deriva del
journal y nunca pregunta si el motor arrancó de verdad. La del recordatorio de liquidación sacó
**dos**: **`groups-settlement-reminder-stale-clock`** —el reloj del nudge no ve las ediciones de un
gasto viejo ni los pagos retro-fechados, porque `SplitSettlement` no tiene `createdAt` ni
`SplitExpense` tiene `updatedAt`; cerrarlo pide campo nuevo y migración— y
**`groups-settlement-reminder-discoverability`**, que es decisión tuya y está arriba. La del
resumen compartible sacó **dos**, los dos sobre código que ese cambio **no tocó a propósito**:
**`debt-simplification-nondeterministic-ties`** —ante un empate exacto de saldos,
`DebtSimplificationService` elige acreedor y deudor con `max`/`min` sobre un `Dictionary`, cuyo orden
de iteración cambia entre procesos, así que el conjunto de transferencias puede salir distinto (todas
correctas, mismo total); hasta ahora eso quedaba en pantalla, donde se vuelve a mirar, y desde el
resumen **se congela en una imagen** y circulan dos versiones por el mismo chat— y
**`group-balance-service-shares-not-deduped`**, el mismo hueco de repartos duplicados que se cerró en
la lógica del resumen y sigue abierto en el servicio que alimenta Balances, la banda del header y el
recordatorio de deudas.

**Y una lección de higiene del board:** abrí un cuarto ticket para el rojo de
`EdgeCases.test_extremeMinimumAmountSaves` **sin comprobar que ya existía uno**
(`transaction-save-helper-flake-one-per-suite`, de esta misma mañana). Se retiró y su medición nueva
se fusionó en el que ya estaba. ⇒ **antes de abrir ticket por un rojo, greppea el board por el aserto,
no por el nombre del test** — la víctima cambia entre corridas y el nombre no encuentra nada.

**Dos trampas al recontar, las dos han mordido ya:** cuenta solo `*.md` —hay un `.gitkeep` por carpeta
y PNG de evidencia en `done/` y `qa/`, que inflan un `ls`— y si filtras las filas con una regex,
acepta MAYÚSCULAS en el id: `rojo-heroBuckets-thisWeek-trailing-window` se escapa de `[a-z0-9-]+` y
aparenta ser un huérfano que no existe. **Estaba escrito y volvió a morder el 7-sep**: la sesión del
resumen compartible «encontró» ese mismo huérfano, añadió su fila al índice y creó un duplicado, que
tuvo que deshacer. ⇒ ante una discrepancia del board, sospecha **primero del filtro** y córrelo con un
patrón laxo (`\S+`) antes de tocar el fichero. **Y el índice tiene DOS tablas**: acota al bloque que sigue al
separador `|----|`, o cuentas filas de la de abajo. Se comprueba con **conjuntos**, no con el contador.
