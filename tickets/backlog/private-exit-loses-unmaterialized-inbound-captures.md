---
id: private-exit-loses-unmaterialized-inbound-captures
status: backlog
priority: medium
area: "settings, inbox, modo-nube"
created: 2026-09-11
source: "review adversarial del paso 9 (`session-exits-one-verb-per-session`), lente de pérdida de datos; la sesión de la mitad 2 del paso 5 midió lo mismo desde su puerta"
---

# Un pago de Apple Pay o un gasto dictado a Siri se pierde si cierras sesión antes de que Yala lo convierta en borrador

## El síntoma, en lenguaje de usuario

Pago con Apple Pay, la automatización lo manda a Yala, y antes de abrir la bandeja cierro sesión en mi
sesión privada. La hoja me dice que mis datos siguen en iCloud y que antes se sube lo pendiente. Al
restaurar, ese pago no está: nunca llegó a ser un movimiento, así que nunca subió.

## Lo medido (2026-09-11, en este árbol)

- Las capturas de Apple Pay, Siri y las imágenes compartidas esperan en colas del App Group hasta que la app
  las materializa (`ApplePayPendingStore`, `SiriPendingStore`, `SharedContainerService`). No pasan por
  SwiftData, así que no están en iCloud.
- El boot-wipe del cierre las purga (`AppGroupInboundPurge.purgeInboundSurfaces()`, dentro de
  `SwiftDataConfiguration.performSignOutWipeIfArmed`). Es la frontera correcta de PRIVACIDAD —lo que capturó la
  cuenta saliente no puede aparecer en la entrante—, pero en la sesión privada la persona que vuelve suele ser
  la misma.
- La espera del export (`PersonalExportPendingCounter`) solo mira el historial del store: estas capturas no
  cuentan, así que el aviso de la salida de emergencia tampoco las nombra.
- Con el wipe ya armado en `.icloud`, el handler de cambios remotos de `AppBootstrapper` sigue drenando esas
  colas hacia el store que el arranque va a borrar: solo `handleBecameActive` mira `isSignOutWipeArmed()`.
  Antes del paso 9 eso solo era alcanzable desde `.cloud`.

## Lo que se espera

- En el cierre privado, materializar las colas del App Group ANTES de la espera del export, para que viajen
  como cualquier otro cambio y el contador las vea.
- El mismo guard `isSignOutWipeArmed()` en el drenaje del handler de cambios remotos.

## Criterios de aceptación

- [ ] Una captura pendiente en la cola se convierte en borrador antes de que el cierre privado cuente lo pendiente.
- [ ] Con el wipe armado, ningún camino drena las colas al store condenado (test de las dos direcciones).
- [ ] El cierre de la nube y la frontera M1 siguen purgando sin materializar.
