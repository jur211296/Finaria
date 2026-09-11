---
id: remote-wipe-signal-honored-by-any-session
status: backlog
priority: high
area: "settings, modo-nube, sync"
created: 2026-09-11
source: "review adversarial del plan del paso 9 (`session-exits-one-verb-per-session`), lado RECEPTOR de la señal de vaciado"
---

# La señal «vacía tus datos» la obedece cualquier sesión del Apple ID, también las de la nube

## El síntoma, en lenguaje de usuario

Vacío mis datos en mi iPhone privado. En el iPad del mismo Apple ID tengo abierta una sesión en la nube (o
el móvil lo está usando otra persona con su cuenta): ese dispositivo también se vacía, y como está en la
nube, sus borrados suben a SU cuenta.

## Lo medido (2026-09-11)

- «Vaciar datos» llama a `DataWipeService.wipeAllUserData(broadcastSignal: true)`, que escribe
  `lastWipeTimestamp` en el **iCloud KV del Apple ID** (`PreferenceSyncService.signalWipeInitiated`).
- Todo dispositivo con el onboarding completado lo procesa (`ContentView.handleRemoteWipeSignal` →
  `performLocalWipeForRemoteSync`), **sin mirar qué sesión tiene**: borra filas con `wipeAllUserData`.
  En `.icloud` con espejo eso borra además su iCloud; en `.cloud` el motor sube los borrados a la cuenta.
- El paso 9 cerró el lado EMISOR: la señal ya solo sale de una sesión privada
  (`DestructiveScopeLogic.wipeSignalsAppleIDDevices`). Queda este lado.

## Lo que debería pasar

Solo una sesión PRIVADA obedece la señal: es la única cuyos datos son los del Apple ID. Una sesión en la
nube (completa o solo grupos) la ignora y la marca como procesada.

## Criterios de aceptación

- [ ] Un dispositivo en `.cloud` o solo-grupos que recibe `lastWipeTimestamp` no borra nada.
- [ ] Una sesión privada del mismo Apple ID sigue vaciándose como hoy.
- [ ] Test de la decisión pura (`RemoteWipeSignalDecider`) con el eje de sesión.
