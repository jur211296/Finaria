---
id: reverse-upload-has-no-ceiling-and-no-exit
status: backlog
priority: high
area: "modo-nube, migración"
created: 2026-09-10
source: "review adversarial de `reverse-cutover-cerrado-para-cuentas-born-cloud` (2026-09-10), lente de rules + lente de backend"
---

# «Volviendo a iCloud…» al 95 % puede quedarse ahí para siempre, y con la nube ya cerrada

## El problema, en lenguaje de usuario

Pulso «Volver a iCloud». La barra avanza hasta el 95 %, pone «Volviendo a iCloud…» y **no se mueve
más**. Hay un botón «Retomar» que no cambia nada. No hay ningún mensaje que me explique qué falta ni
cuánto puede tardar.

Y mientras estoy ahí, **mis datos están en una sola copia**: en el teléfono. La nube de Yala ya quedó
cerrada a escritura al empezar la reversa, y a iCloud —por hipótesis— no está llegando nada. No pierdo
nada mientras el teléfono viva, pero pierdo la red.

## Por qué pasa

La reversa no sube el corpus a mano: monta el mirror de CloudKit y deja que
`NSPersistentCloudKitContainer` exporte solo. La fase `reverseUpload` **sondea** ese progreso y no
avanza hasta que drene:

- `Yala/Services/CloudSync/MigrationWorkExecutor.swift` · `reverseUploadStatus()` →
  `pending = report.exportPending + report.noMetadata`; `pending == 0 ? .drained : .pending(count:)`.
- `Yala/Services/CloudSync/MigrationRunner.swift` · `driveReverseUpload()` → con `pending` emite un
  breadcrumb, refresca el lease y `return false` («stop retomable»). **No consulta ningún reloj.**

Y ahí se queda:

- **No hay tope.** El presupuesto por tiempo journaleado existe **solo para la ida**
  (`MigrationState.markerWrittenSince`, sellado en la arista `cutover(.markerWritten)`, evaluado con
  `ICloudCutoverGateLogic`). Un `grep` de `ICloudCutoverGateLogic` en `Yala/` da **un solo consumidor**,
  y es el de la ida. Esto choca de frente con la regla del repo, que se pagó con ese mismo caso:
  `.claude/rules/swiftdata-cloudkit.md` — «toda espera por un export del mirror lleva tope, y el tope va
  por TIEMPO journaleado, no por intentos».
- **La cadencia no es un timer**: boot + foreground + tap (`MigrationForegroundRekick`). Si el usuario no
  abre la app, no se re-sondea.
- **Un fallo fatal en esa fase HOLDEA, nunca rueda atrás**: `MigrationStateMachine.swift` —
  `case (.reverseUpload, .fatalError): return .transition(next: .reverseUpload, effects: [])`, con el
  comentario «fatalError POST-mount → HOLD the state, NEVER rollback». El `.reverseRollback` solo cuelga
  de los terminales PRE-mount.
- **En producción no hay escape.** `StorageSettingsView` solo ofrece `resetAfterRollback()`, que es no-op
  fuera de `failedRollback`/`reverseFailedRollback`. El «Forzar salida (escape hatch)» vive en
  `CloudSyncDebugView` y es `DEV_BUILD` only.
- **El backend está congelado.** El orden es `reverseFreezeBackend` → `reverseMountMirror` →
  `reverseReconcile` → `reverseUpload`, así que al llegar aquí `reverse_frozen_at` ya está estampado y
  `gateway/src/sync/routes.ts` responde **409 `yala_account_reverting`** a `/sync/push` y `/prefs/push`.
  Lo único que des-congela es `reverse_abort`, y ningún camino de producción lo alcanza desde aquí.

## Por qué es `high` AHORA y no antes

Porque hasta el 2026-09-10 esto lo alcanzaba «el líder migrado — el único caso real actual» (lo dice
`MigrationRunner`). `reverse-cutover-cerrado-para-cuentas-born-cloud` abrió la reversa a las cuentas
nacidas en la nube, y tras el fresh start de ese día **eso es toda la población**. Además, para un
born-cloud el mirror tiene que exportar **el corpus entero** —no un delta—, así que la espera es
estructuralmente mucho más larga: el `pending` inicial son todas sus filas.

**Y el mecanismo del que todo esto depende no está medido en este repo.**
`Yala/App/Logic/WelcomeMirrorRelaunchLogic.swift` lo dice de su puño: que un mirror adjuntado en un
arranque POSTERIOR exporte lo escrito en la ventana sin mirror es «plausible pero **NO está medido**».
La dirección contraria sí se midió en device (`groups-only-second-launch-mounts-icloud-mirror`, iPhone,
2026-09-09): un mirror diferido **importa**. Que **suba** es lo que falta.

## Lo que hay que decidir (es de producto, no técnico)

1. **¿Cuánto es «demasiado»?** El tope de la ida distingue `definitive` (CloudKit ya dijo que no entra:
   900 s) de `unknown` (aún no se sabe: 259 200 s = 3 días), con **fail-open**: la ambigüedad nunca
   aborta. La reversa necesita su equivalente, y el número no es evidente: un corpus born-cloud grande
   puede tardar horas legítimamente.
2. **¿Qué se le ofrece al llegar al tope?** Un terminal `reverseFailedRollback` deja al usuario en modo
   nube con el backend descongelado (hay que abortar) y el mirror montado — hay que comprobar que ese
   estado es sano. La alternativa es un estado «sigue subiendo, puedes usar la app» que hoy no existe.
3. **¿Y mientras espera?** Como mínimo, decir cuántas filas quedan: el sondeo ya tiene el número
   (`pending(count:)`) y hoy no se muestra. Existe el precedente exacto de copy honesto para la ida
   (`controller.isWaitingICloudExport`), y en la reversa **no se pinta nada**.

## Criterios de aceptación

- [ ] La espera de `reverseUpload` tiene tope por **tiempo journaleado** (no por intentos), con su
      clasificación fail-open, en el molde de `ICloudCutoverGateLogic`.
- [ ] Al agotarse hay una salida que **des-congela el backend** y deja un estado que el usuario entiende.
- [ ] Durante la espera la pantalla dice algo verdadero (cuántas filas faltan, o que puede tardar).
- [ ] Hay un canario que distingue «va lento» de «no avanza», visible en la flota.

## Fuera de alcance

Medir si el mirror exporta de verdad: eso es device-QA y está en el guion de
`reverse-cutover-cerrado-para-cuentas-born-cloud`. Este ticket es lo que hay que hacer **suponiendo que
alguna vez no lo haga**.

## Relacionado

- `reverse-claim-rejection-has-no-way-out-in-the-client` — el gemelo en la fase anterior: un **rechazo**
  del claim deja la barra clavada en 15 % por el mismo motivo (ninguna salida para `.rejected`).
- `.claude/rules/swiftdata-cloudkit.md`, la regla del tope por tiempo y la del cuarteto de cierre con el
  orden invertido (residual documentado de la misma familia).
