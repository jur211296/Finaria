---
id: restore-start-fresh-keeps-the-imported-corpus
status: backlog
priority: high
area: "onboarding, modo-nube"
created: 2026-09-11
source: "medido leyendo el código durante el paso 8 del rediseño de sesiones; NO reproducido en device"
---

# «Empezar desde cero» en Restaurar promete «sin tus datos previos» y los deja bajando

## El síntoma, en lenguaje de usuario

Welcome → «Ya tengo una cuenta» → «Restaurar desde iCloud» → la app encuentra mis datos → toco «Empezar
desde cero» → «Esto creará una cuenta nueva sin tus datos previos. ¿Continuar?» → «Sí». Me sale el
onboarding… y mis datos de antes siguen bajando por debajo, porque el espejo de iCloud ya estaba puesto.

## Lo medido (árbol del paso 8, 2026-09-11)

- `ContentView.welcomeRestoreCover` → `onStartFresh`: limpia nombre y divisa y enciende `showOnboarding`.
  **No borra nada**, ni la zona de iCloud ni lo que el espejo ya importó.
- `WelcomeMirrorRelaunchLogic.requiresMirror(.restoreICloud) == true`: esa pantalla solo existe con el
  espejo adjunto, así que el corpus sigue importándose mientras la persona hace su onboarding «de cero».
- Es la misma familia que el bug del paso 4 (`welcome-private-fresh-start-skips-icloud-check`), por otra
  puerta. `welcome-start-fresh-wipes-before-ask` habla de este mismo botón, pero de otra cosa: de las
  preferencias que borra antes de preguntar.
- **La activación de Yala completo (paso 8) lo hereda a propósito**: «Restaurar» ahí es el mismo recorrido
  de «Ya tengo cuenta → iCloud» (decisión de Jürgen), y su «empezar de cero» lleva al mismo onboarding. En
  ese contexto el arreglo tiene una restricción más: el borrado local (`DataWipeService.wipeAllUserData`)
  resetea `hasCompletedOnboarding`, el modo y el nombre, y mandaría al Welcome a un solo-grupos.

## Qué se espera

Lo mismo que la puerta del paso 4: si hay corpus, «empezar de cero» es **borrar** (con segunda
confirmación, zona de iCloud + lo importado) — o no ofrecerlo desde aquí y devolver a la puerta.

## Criterios de aceptación

- [ ] **DEVICE** · Restaurar → encontrado → «Empezar desde cero» → tras terminar el onboarding y esperar a
      que iCloud sincronice, no aparece ningún dato previo.
- [ ] El mismo recorrido desde «Activar Yala completo → privado → Restaurar» deja la sesión de grupos
      intacta.
