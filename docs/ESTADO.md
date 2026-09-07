---
updated: 2026-09-07
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-07 (Lima)

**Rama** `2.1` · HEAD `77dff99e` — en el móvil de otra persona, «privacidad total» ya lo dice.
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.** `yala-app.pe` sirve la web
nueva.

## Esta sesión, en una línea

**La rama privada del Welcome deja de callarse en visita** (PR #86). «Es mi primera vez → privacidad
total» llevaba a quien usa Yala en el móvil de otra persona al onboarding **sin decirle nada**,
mientras la rama de al lado sí se lo decía: la app se contradecía según por dónde entraras. Ahora
sale una pantalla propia —«Lo tuyo no se mezcla con lo suyo»— que **informa y no bloquea**. Y el
onboarding en visita deja de ofrecer las categorías de ejemplo que nunca creaba: un paso menos
(8 → 7) en vez de una promesa incumplida.

**La premisa trajo dos hechos que el ticket no tenía, y uno cambió el copy.** La card que la visita
acaba de tocar promete «se sincronizan por tu iCloud privado», y el store secundario es
`cloudKitDatabase: .none` — no se espeja a ninguna CloudKit, ni a la del dueño ni a la suya. Por eso
el cuerpo dice «solo en este dispositivo»: es medido, no cautela. El segundo era un defecto vivo:
**el saldo inicial de la visita se descartaba en silencio** (sin seed no existía «Ajuste de saldo»,
así que no había dónde colgar el importe). No hizo falta arreglo aparte — tratarla como «sin seed»
entra por la rama que ya la crea.

**Y un tercero, que la review adversarial encontró a UN TAP de la pantalla nueva.**
`clearResidualPreferencesForFreshStart` borraba `userName` y `defaultCurrencyCode` del
`UserDefaults` del **dueño**, y la visita entra siempre por esa rama. Se cerró aquí porque sin eso
el copy es falso. Su mitad iKV **ya estaba protegida**, con un comentario que nombra la sesión
secundaria: era un arreglo hecho a medias, y el comentario correcto de al lado hacía la zona parecer
revisada. Está en `aprendizajes-tecnicos.md`.

**Se vio en pantalla, y ahí saltó lo que el fuente escondía:** la primera captura mostró el copy
VIEJO con el fichero ya corregido — `es` y `pt` son copias regeneradas de `es-419` y `pt-BR`, y
editarlas tras `add-l10n-key.sh` las dejó atrás, con un `[NEEDS_TRANSLATION]` vivo en `pt`.

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
3. **Publicar la app.** Los avisos de Grupos están completos en servidor y en los dos entornos; falta
   el cliente iOS. Llevaría además el saldo de Distribución, la identidad del recién llegado, los
   predeterminados del Panel, el cierre del detalle, la hoja de «Unirme», el freno de la lista,
   «Transferir y salir», la puerta del grupo, la puerta del archivado, la marca de aproximado con su
   corrección del 1:1, el rótulo del hero de Estadísticas **y el aviso de visita**.
4. **La tanda de QA: 42 tickets en `qa/`, y el guion solo cubre 22.** Entra
   `welcome-privacy-branch-has-no-secondary-door`: el seam de simulador enciende el descriptor pero
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

**Ruido del gate — hoy hay UN rojo nuevo bien medido y dos viejos que no aparecieron.**

- **`transaction-save-helper-flake-one-per-suite` (nuevo, medium).** Toda corrida completa de
  `YalaUITests` acaba con **un** fallo en el mismo aserto («no apareció la pantalla de éxito de la
  transacción», `XCUIApplication+Yala.swift:208`) y **la víctima cambia**: `QuickActionsFavorites`
  dos veces, `EdgeCases.test_extremeMinimumAmountSaves` la tercera —con la primera pasando esa vez—.
  Bisecado con 17 muestras contra el árbol base; la que lo zanja **falló con un único fichero
  cambiado cuyo parámetro nuevo no lo pasa nadie**: un fallo sin causa posible ⇒ ruido del
  instrumento, no regresión. El ticket lleva un **reproductor de 3 minutos** (4 suites + la suya) para
  que nadie repita las dos horas de bisección. **Aviso que va en el propio ticket:** este mismo aserto
  ya cazó una rotura REAL (el `.alert` con label dinámico), así que **no se descarta sin medir**.
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

**Al retomar cualquiera: las coordenadas de los tickets están sistemáticamente caducadas.** Greppea, no
abras la línea citada. **Y la premisa del ticket —y la del encargo— también caduca.**

## Release 2.1 (sin cambios)

2.0.5 no se lanza; release = 2.1. A7 y M5: **HOLD, no flip**. Prod: CLOUD_MODE 100 · GROUPS_BACKEND
100 · CLOUD_ONBOARDING_CHOICE 0 · SECONDARY_SESSION 0. Cola C: 9 ACs owner/device, no corrida; D-R1
sigue sin `ok_`. **Cero `ok_` inventado.**

## Board

**134 tickets · backlog 69 · qa 42 · blocked 2 · done 16 · discarded 5.**
`qa` significa «esperando la tanda», no «cerrado». Índice = disco, verificado comparando **conjuntos**
(134 = 134, cero huérfanos en ambas direcciones, cero rutas rotas). **Todo cierre incluye
`docs/TICKETS.md`**, y lo que salga de camino lleva ticket propio — esta sesión sacó **cinco**:
`secondary-onboarding-still-crosses-owner-domain`, `transaction-save-helper-flake-one-per-suite`,
`welcome-beacon-reads-owner-icloud-in-secondary`,
`secondary-visit-data-lost-on-signout-unannounced` y `welcome-private-card-promises-icloud-in-visit`.

**Dos trampas al recontar, las dos han mordido ya:** cuenta solo `*.md` —hay un `.gitkeep` por carpeta
y PNG de evidencia en `done/` y `qa/`, que inflan un `ls`— y si filtras las filas con una regex,
acepta MAYÚSCULAS en el id: `rojo-heroBuckets-thisWeek-trailing-window` se escapa de `[a-z0-9-]+` y
aparenta ser un huérfano que no existe. Se comprueba con **conjuntos**, no con el contador.
