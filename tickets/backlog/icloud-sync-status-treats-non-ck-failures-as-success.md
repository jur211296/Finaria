---
id: icloud-sync-status-treats-non-ck-failures-as-success
status: backlog
priority: low
area: "modo-nube, sync"
created: 2026-09-11
source: "review adversarial del paso 9 (`session-exits-one-verb-per-session`), lente de pérdida de datos"
---

# Un evento del espejo que falla con un error que no es de CloudKit cuenta como un éxito

## Lo medido (2026-09-11)

`iCloudSyncService.handleContainerNotification` pasa `event.error as? CKError` a `apply`. Un evento que
TERMINA con un error de otro dominio —los `NSCocoaErrorDomain` 1344xx del propio espejo— llega con
`error == nil` y con fecha de fin, y cae en la rama de éxito: `lastSuccessfulImportDate`,
`lastSuccessfulExportDate`, `consecutiveFailures = 0`, el estado `.success` y, en un import,
`hasCompletedFirstImport = true`.

El paso 9 cortó solo sus dos piezas con `Event.succeeded`: el ancla del export y
`mirrorReportedNotAuthenticated`. El resto se dejó igual a propósito, porque `hasCompletedFirstImport`
abre las puertas de quiescencia de varios `save()` y cambiarlo sin medir podía dejar puertas cerradas para
siempre.

## Lo que hay que mirar

- Qué eventos terminan con `succeeded == false` y un error de Cocoa en device (setup sin cuenta, import con
  el store bloqueado).
- Qué consumidores de `hasCompletedFirstImport` y del estado se quedarían esperando si esos eventos dejaran de
  contar como éxito.

## Criterios de aceptación

- [ ] Un evento con `succeeded == false` no cuenta como éxito en ningún campo, o se documenta por qué uno sí.
- [ ] Ninguna puerta de quiescencia queda cerrada para siempre por el cambio (test por consumidor).
