---
id: full-mode-activation-must-ask-where-personal-data-lives
status: backlog
priority: high
area: "groups, onboarding, modo-nube"
created: 2026-09-09
source: "medido durante el device-QA guiado del 2026-09-09 · ADR 2026-09-09 «Sesiones — dos ejes» §8"
---

# «Activar Yala completo» no pregunta dónde van a vivir tus datos personales

## El síntoma, en lenguaje de usuario

Uso Yala solo para grupos. Toco «Activar Yala completo» (desde Ajustes o desde cualquiera de los 32
empujones que hay repartidos por Grupos). Me sale el onboarding con mi nombre y mi moneda ya puestos y
al terminar tengo Panel, cuentas y presupuestos… **sin que nadie me haya preguntado si quiero mis
finanzas en mi iCloud privado o en mi cuenta de Yala.** Aterrizan donde caigan.

## Lo que Jürgen decidió (ADR §8)

«Yala completo» no es «nube completa». Yala completo = personal + grupos, y lo personal puede ser
**privado** (CloudKit) o **en la nube** (la misma cuenta que ya usa para grupos, que pasa a ser
completa). Quien activa Yala completo desde solo-grupos **elige con el mismo chooser** que ve quien
entra por «Primera vez» (las dos cards: «Tu cuenta en tu iCloud privado» / «Tu cuenta en la nube»).

## Lo medido (2026-09-09, árbol `3a94604e`)

- `Yala/App/Views/Groups/FullModeActivationView.swift` reusa `OnboardingView` con nombre y moneda
  prerrellenados (docblock `:1-8`) y al terminar escribe `onboardingMode = .completed` y
  `usageFocus = .full` (`completeFullActivation`, `:86-100`). **Ni `storageMode`, ni elección, ni
  validación de iCloud.**
- Los datos aterrizan en el store que esté montado. Por `groups-only-second-launch-mounts-icloud-mirror`,
  desde la segunda apertura ese store lleva el espejo de iCloud con lo que hubiera en el Apple ID ⇒ el
  onboarding «completo» corre sobre datos viejos sin el alert de «Detectamos datos previos».
- 32 strings `groups.nudge.*` en `Yala/Resources/es.lproj/Localizable.strings` (y sus 15 hermanos)
  empujan hacia esta pantalla con el copy «Activar Yala completo».

## Alcance

1. Al activar: **chooser privado / nube** (reusar `WelcomeNewChooserView`, mismas cards, mismo gate de
   visibilidad `WelcomeAccountChoiceLogic.visibleNewOptions`).
2. **Privado** → validación de iCloud + alert con doble confirmación (misma pieza que
   `welcome-private-fresh-start-skips-icloud-check`; depende de ella) → adjuntar el espejo (relanzar si
   hace falta) → onboarding personal [P] prerrellenado. Resultado: celda «privada + grupos asociados»
   del ADR: la cuenta en la nube que ya tenía queda **asociada** para grupos.
3. **Nube** → la cuenta en la nube que ya tiene pasa de «solo grupos» a «completa» en el backend
   (depende de `backend-account-kind-complete-or-groups-only`) → onboarding [P] → `storageMode = .cloud`
   y el motor de sync personal arranca (el mismo tramo que el alta born-cloud recorre hoy tras
   `activateBornCloudStorage`). Resultado: celda «nacida en la nube».
4. Copy: el CTA puede seguir diciendo «Activar Yala completo»; lo que cambia es que ahora pregunta.
5. **Ratificado por Jürgen (2026-09-09):** en la rama *privado*, si iCloud tiene datos, se ofrece **«Restaurar mis datos»** además de borrar/cancelar. Quien llega aquí no es «nuevo» (entró por grupos
   y puede ser un usuario privado de antes); mandarlo a cerrar sesión → «Ya tengo cuenta → iCloud» →
   asociar de nuevo para conseguir lo mismo es un rodeo. Restaurar = el mismo recorrido de «Ya tengo cuenta → iCloud» (`WelcomeRestoreView`: resumen → continuar), terminando en D (privada + la cuenta de grupos asociada).

## Criterios de aceptación

- [ ] Desde solo-grupos, «Activar Yala completo» muestra el chooser antes de cualquier onboarding.
- [ ] Privado + iCloud con datos → alert con TRES salidas; borrar → onboarding limpio; restaurar → los datos
      de iCloud aparecen y la cuenta de grupos queda asociada; cancelar → vuelve al chooser.
- [ ] Privado + iCloud vacío → onboarding directo; al terminar, «¿Dónde viven tus datos?» muestra
      «iCloud privado» y la cuenta de grupos como **asociada**.
- [ ] Nube → al terminar, el backend devuelve `kind = complete` para la cuenta, `storageMode == .cloud`
      y el sync personal está vivo (mismos canarios que el born-cloud).
- [ ] Los grupos y sus gastos siguen intactos en los dos caminos; el bridge al Panel arranca solo
      DESPUÉS de completar [P].
- [ ] Ninguno de los 32 nudges lleva a un onboarding sin chooser.

## Cómo se prueba

- Unit: el ruteo (chooser → destino) como lógica pura; `OnboardingStepPlan` con prefill.
- XCUITest: el chooser aparece desde solo-grupos (seed uitest de solo-grupos + `-uitest-cloud-chooser`).
- Device-QA: las ramas privado (CloudKit) y nube (backend staging) enteras.

## Depende de

`welcome-private-fresh-start-skips-icloud-check` · `backend-account-kind-complete-or-groups-only` ·
`cloud-sign-in-discovers-account-kind`.
