---
id: icloud-export-error-latch-never-clears
status: backlog
priority: high
area: "modo-nube, sync"
created: 2026-09-10
source: "review adversarial del paso 5-b (`groups-entry-on-a-mirrored-store-still-blocks-the-owner`), dos lentes independientes"
---

# Un fallo de subida a iCloud se queda pegado hasta que matas la app

## El síntoma, en lenguaje de usuario

Estoy en el metro y Yala intenta subir algo a iCloud. Falla, y no me dice nada —es un fallo transitorio y
la app se los guarda—. Salgo, con Wi-Fi, y todo vuelve a funcionar: mis datos suben. Pero cualquier
pantalla que **pregunte** «¿ha fallado la subida?» seguirá diciendo que sí, hasta que cierre la app del
todo.

## Lo medido (2026-09-10, en este árbol)

`iCloudSyncService.lastExportError` se escribe en `:291` y **ningún camino de producción lo limpia**:

- La rama de export CON ÉXITO (`:296-301`) repone `lastSuccessfulExportDate` y `consecutiveFailures = 0`,
  pero **no** el error.
- Los dos únicos `lastExportError = nil` son `_testReset()` (`:602`) y `_qaSimulateFailed()` (`:623`),
  ambos bajo `#if DEBUG`.
- `promoteToIdleOrStalled` (`:395`) solo lo LEE, como `hasFailureHistory`.

Y el propio `forceSync` lo ensucia: su `catch` llama `apply(eventType: .exportEvent, error: ckError,
endDate: nil)` (`:542`), que ejecuta la asignación.

O sea: es un **latch de proceso**. La primera vez que falla un export en la vida del proceso, el campo
queda puesto para siempre, aunque después suba todo correctamente.

## Por qué importa ahora

Lo destapó el paso 5-b al usarlo como término de «¿ya subió lo pendiente?»: con el latch puesto, su
botón «Reintentar» era **estructuralmente incapaz** de tener éxito. Ese camino se paró por otras razones,
pero el latch afecta a dos consumidores que SÍ están vivos:

- `MigrationWorkExecutor` (`:251`, `:765`) lo pasa a `ICloudCutoverGateLogic.classify`, que decide si el
  atasco del cutover es `definitive` (presupuesto 900 s) o `unknown` (259 200 s). Un blip antiguo puede
  clasificar como definitivo un atasco que ya se resolvió.
- El propio `ICloudCutoverGateLogic` documenta en `:84` que el valor es «post-hoc y EN MEMORIA (`nil` tras
  relanzar)», así que el comportamiento está descrito — lo que no está descrito es que **no se limpia
  nunca dentro del proceso**.

## Lo que se espera

Que el campo describa el estado ACTUAL: un export con éxito lo limpia, igual que repone
`consecutiveFailures`. Y para quien necesite «¿ha fallado DESDE que empecé?», la forma correcta es
capturar el valor antes y comparar, no leer un absoluto.

## Criterios de aceptación

- [ ] Un export con éxito deja `lastExportError == nil`.
- [ ] Un test fija la secuencia fallo → éxito → `nil` (hoy no existe: la suite solo cubre el set).
- [ ] `ICloudCutoverGateLogic` sigue clasificando igual ante un error VIVO (no-regresión de su tabla).
