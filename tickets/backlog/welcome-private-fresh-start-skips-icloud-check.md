---
id: welcome-private-fresh-start-skips-icloud-check
status: backlog
priority: high
area: "onboarding, modo-nube"
created: 2026-09-09
source: "device-QA guiado por Jürgen (2026-09-09) · ADR 2026-09-09 «Sesiones — dos ejes» §9"
---

# «Primera vez → privado» en una instalación fresca no valida iCloud: reinicia y hace el onboarding encima de los datos viejos

## El síntoma, en lenguaje de usuario

Tengo meses de datos en mi iCloud privado. Desinstalo Yala y la vuelvo a instalar. Toco «Es mi
primera vez en Yala» → «Tu cuenta en tu iCloud privado». La app me dice «Un último paso: reabre
Yala». La reabro y me mete **directo al onboarding completo, como si fuera nuevo** — sin preguntarme
nada — mientras por debajo iCloud va bajando todos mis datos viejos. Termino con un onboarding «de
cero» encima de un histórico intacto que nadie me dijo que existía.

## Lo que Jürgen espera (dictado el 2026-09-09, es la regla del ADR §9)

1. Apenas elijo *privado*, la app **valida si hay datos en el iCloud de este dispositivo**.
2. Si hay: alert con **doble confirmación**.
   - Borrar → **se borra** y **pide reinicio**. Tras el reinicio ya no existen datos de iCloud en el
     dispositivo y abre el **onboarding completo de cero**.
   - Cancelar → vuelve a la elección privado / nube.
3. Si no hay: sin alert, directo al onboarding completo.
4. **Nunca** se muestra la pantalla de reinicio sin haber hecho antes esa validación.

## Lo medido (2026-09-09, árbol `3a94604e`)

- La instalación fresca monta el store personal **neutro**, sin espejo de iCloud
  (`SwiftDataConfiguration.personalStoreDecision`, `Yala/Utils/SwiftDataConfiguration.swift:341`, vía
  `isFreshInstallForNeutralMount` `:266-277`). En ese store no hay filas, así que cualquier detector de
  «hay datos» que cuente filas locales (`ContentView.checkHasExistingData`, `Yala/App/ContentView.swift:1118-1141`)
  responde `false` por construcción.
- La rama privada sale del Welcome por el portal `leaveWelcome` de `WelcomeFlowContainer`
  (`Yala/App/Views/Onboarding/WelcomeFlowContainer.swift`, `handleNewOption` → `.privateAccount`):
  como `.privateOnboarding` **requiere espejo** (`WelcomeMirrorRelaunchLogic.requiresMirror`) y el mount
  es neutro, persiste el destino (`WelcomePendingDestinationStore.set`) y muestra «reabre Yala». **El
  callback `onSelectPrivateAccount` —el único que consulta `hasExistingData` y levanta el alert
  (`startFreshPrivateOnboarding`, `ContentView.swift:1662-1671`)— no llega a ejecutarse.**
- Al reabrir, `presentNextOnboardingScreen` consume el destino y abre el onboarding **sin volver a
  comprobar nada** (`ContentView.swift:1390-1393`: `case .privateOnboarding: showOnboarding = true`).
  Mientras tanto el espejo recién adjuntado importa el contenedor de iCloud por debajo.
- El alert «Detectamos datos previos en tu dispositivo. ¿Borrar todo para empezar como nuevo?» solo
  aparece cuando los datos ya estaban en el dispositivo al elegir (p. ej. tras cerrar sesión sin
  desinstalar). Los tickets `welcome-start-fresh-wipes-before-ask` y
  `welcome-fresh-start-alert-leaves-blank-screen` hablan de ESE alert; ninguno cubre este caso.

## Alcance

- La validación tiene que preguntar a **iCloud**, no al store local: es la misma búsqueda que ya hace
  «Restaurar desde iCloud» (`WelcomeRestoreView.startSearch` → `ICloudAccountSummary`; hoy corre
  DESPUÉS de reabrir porque también requiere espejo). Decidir en el diseño si la búsqueda se hace
  antes del relanzamiento con una consulta directa a CloudKit (sin adjuntar el espejo al store) o si
  el relanzamiento pasa a ser «reabrir para comprobar» y la validación + alert corren al reabrir,
  ANTES del onboarding. En ambos casos se cumple el punto 4: la pantalla de reinicio ya no es ciega.
- Borrar = el mismo `DataWipeService.wipeAllUserData` + `wipeLocalGroupsDomain` +
  `clearResidualPreferencesForFreshStart` del alert actual (`ShellDataAlertsModifier.swift:89-127`),
  y después el reinicio que pide el ADR. Al reabrir: onboarding completo, sin restos.
- Cancelar = volver al chooser privado/nube (el de dos cards, hoy visible en prod:
  `cloudOnboardingChoiceRolloutPercent: 100` medido por curl al `/config` de producción).
- Doble confirmación: el alert existente + una segunda («¿Seguro? Esto es definitivo.» ya existe
  para «Vaciar datos»: `settings.wipeDataSecondConfirmTitle`).

- **Sin iCloud disponible (K)**: no se puede validar; se informa (como «Restaurar» con `.iCloudDisabled`)
  y se sigue en local (`.localNoMirror`). Nunca se bloquea por no poder preguntar.
- **Kill-safety:** matar la app entre «borrar» y el reinicio no puede dejar datos a medio borrar ni un
  onboarding encima de ellos: armar el borrado y el destino como hace el boot-wipe del cierre de sesión
  (`SwiftDataConfiguration.swift:689`), y consumirlos al arrancar.

## Criterios de aceptación

- [ ] Instalación fresca + iCloud con datos → «Primera vez → privado» muestra el alert ANTES de
      cualquier pantalla de reinicio. Nunca onboarding directo.
- [ ] Borrar (doble confirmación) → reinicio → onboarding completo con CERO filas de usuario en el
      store y CERO registros en el contenedor de iCloud del Apple ID (verificable con «Restaurar desde
      iCloud» en otra instalación: `notFound`).
- [ ] Cancelar → chooser privado/nube, con los datos de iCloud intactos.
- [ ] Instalación fresca + iCloud vacío → onboarding directo (con el reinicio que haga falta), sin alert.
- [ ] Sin iCloud en el dispositivo → aviso + onboarding local; con iCloud activado después, el espejo se
      adjunta como hoy.
- [ ] Matar la app justo tras confirmar «borrar» → al reabrir, el borrado se completa y abre el onboarding
      limpio (breadcrumb del arm consumido).
- [ ] Los dos tickets del alert (`welcome-start-fresh-wipes-before-ask`,
      `welcome-fresh-start-alert-leaves-blank-screen`) siguen verdes en el recorrido nuevo.

## Cómo se prueba

- Lógica de decisión (¿validar dónde y cuándo?, ¿qué destino tras borrar?) → `nonisolated enum` puro con
  unit tests, como `WelcomeMirrorRelaunchLogic`.
- El recorrido entero es **device-QA** (CloudKit no existe en simulador): iPhone con datos en iCloud
  privado → desinstalar → instalar desde TestFlight → los cuatro casos de arriba.

## Fuera de alcance

- La elección nube (rama `.cloudAccount`) no cambia.
- Cambiar qué borra «Vaciar datos» (ADR §6) es de `session-exits-one-verb-per-session`.
