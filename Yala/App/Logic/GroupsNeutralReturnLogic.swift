//
//  GroupsNeutralReturnLogic.swift
//  Yala
//
//  Paso 5-b del rediseño de sesiones · **la mitad de la vuelta al neutro que decide si YA se puede
//  borrar.** La otra mitad —si hay que volver al neutro— la decide `GroupsOrganizerGateLogic`.
//
//  ## ⚠️ ESTE CAMINO NO ESTÁ TERMINADO, y no puede mergearse tal cual (2026-09-10)
//
//  La rama entra en `.returnToNeutral`, intenta la subida y —cuando no la puede confirmar— se queda en la
//  pantalla de espera. **Eso es lo único que hace hoy, y es a propósito**: el borrado que tendría que venir
//  después no existe todavía en una forma reusable aquí. Medido con tres lentes adversariales:
//
//   · `armSignOutWipe` **no sirve** para un camino que no cierra sesión — borra `YalaSyncMeta` (donde vive
//     el canal de Grupos, que se supone que sobrevive) y purga las colas de Apple Pay/Siri, que nunca
//     pasaron por iCloud y ninguna subida puede salvar.
//   · **«Esperar a que suba» no se puede demostrar** con las señales de hoy: `forceSync` devuelve `.ok` sin
//     tocar la red si ya hay sync en vuelo, su watchdog convierte «aún no empezó» en «ya terminó» a los 8 s,
//     y `lastExportError` no se limpia nunca dentro del proceso.
//
//  ⇒ Decisión de Jürgen (2026-09-10): **esperar al verbo «Salir de Yala en este dispositivo»** del paso 9
//  (`session-exits-one-verb-per-session`) y NO construir un borrado propio aquí. La medición completa, los
//  ~30 defectos que la review cazó y lo que falta (la entrada por invitación, el disparador por el eje
//  ancho) están en `tickets/blocked/groups-entry-on-a-mirrored-store-still-blocks-the-owner.md`.
//
//  ## Por qué esto es una tabla y no un `if` en la vista
//
//  Lo que hay al otro lado de este veredicto es un borrado del corpus personal de este teléfono. La
//  promesa que lo hace aceptable —«lo tuyo sigue en iCloud»— es cierta **solo para lo que ya subió**, y
//  esa es la decisión de Jürgen del 2026-09-09, repetida el 2026-09-10 para este camino: *nunca borres
//  sin subir*, aunque frene unos segundos la entrada a Grupos. Un `if` invertido aquí no rompe ninguna
//  pantalla: se lleva por delante lo que la persona escribió en el avión.
//
//  ## Los tres términos son POSITIVOS a propósito (falla cerrado)
//
//  El veredicto bueno exige que las tres cosas se cumplan, así que cualquier duda —una red que no
//  contesta, un error que nadie miró, un export a medias— cae en «espera». Escribirlo al revés (un
//  `guard` por cada motivo de fallo) parece equivalente y no lo es: el día que aparezca un cuarto motivo,
//  la forma positiva lo trata como desconocido y espera, y la negativa lo deja pasar. Es la misma lección
//  que dejó el gate que fallaba ABIERTO por su entrada.
//
//  ## Lo que este veredicto NO es, y hay que decirlo
//
//  **No es un contador de deltas pendientes.** En el árbol no existe ninguno —cero
//  `hasUnsyncedChanges` / `pendingExport` / `isExportQuiescent`, medido el 2026-09-10— y construirlo
//  entero es el alcance del **paso 9** (`session-exits-one-verb-per-session`), que la matriz de
//  escenarios señala como el sitio del «HUECO grave: nadie espera al export hoy».
//
//  **Y lo que hay aquí NO ES SUFICIENTE — medido, no inferido.** La primera versión de este párrafo decía
//  que `forceSync` «prueba la red de verdad con `allRecordZones()`, guarda lo local y despierta el motor».
//  Es falso en el estado que dispara esta rama: con un sync ya en vuelo sale por su
//  `guard !status.isSyncing else { return .ok }` **antes de las tres cosas**, y el espejo importando
//  durante el Welcome es precisamente ese estado. A eso se suman dos señales que tampoco dicen lo que
//  parecen: el watchdog de `forceSync` devuelve el estado a `.idle` a los 8 s cuando no llega ningún
//  evento —así que «no está sincronizando» también significa «todavía no ha empezado»—, y
//  `lastExportError` no se limpia en ningún camino de producción, de modo que un blip viejo bloquea el
//  camino el resto del proceso. Los tres tienen ticket propio, y son los insumos que el paso 9 necesita
//  antes de escribir su espera.
//

import Foundation

nonisolated enum GroupsNeutralReturnLogic {

    /// El resultado de pedirle a CloudKit que suba lo pendiente, traducido a lo único que importa aquí.
    /// Los tres casos son los tres desenlaces de `iCloudSyncService.forceSync`, sin su vocabulario: esta
    /// tabla no debe depender de un tipo `@MainActor` para poder vivir en un test sin app.
    enum UploadAttempt: Equatable {
        /// `forceSync` llegó a iCloud: la red contestó y lo local quedó guardado.
        case reachedICloud
        /// No se pudo llegar (sin red, error reintentable). **No es un fallo de la app**, y el copy que le
        /// corresponde dice «un momento más», no «algo salió mal».
        case unreachable
        /// Falló por otra cosa (sin cuenta, conflicto al guardar). Tampoco autoriza nada.
        case failed
    }

    enum Verdict: Equatable {
        /// Lo pendiente está en iCloud —o no había nada pendiente— y se puede armar el borrado de
        /// arranque. Es el ÚNICO valor que autoriza a escribir el arm.
        case safeToArmWipe
        /// No se pudo confirmar la subida. **No se arma nada, no se borra nada** y la persona ve «un
        /// momento más» con reintento: el estado del teléfono queda exactamente como estaba.
        case waitForUpload
    }

    /// - Parameters:
    ///   - attempt: el desenlace de `forceSync`.
    ///   - exportFailed: `iCloudSyncService.lastExportError != nil` **leído después** del intento. Un
    ///     error de export es el caso que de verdad muerde: la app cree que subió y no subió.
    ///   - stillSyncing: `status.isSyncing` al agotar la ventana de quietud. Un export en vuelo significa
    ///     que todavía hay algo yendo hacia iCloud, y borrar los archivos por debajo lo mataría.
    static func verdict(attempt: UploadAttempt,
                        exportFailed: Bool,
                        stillSyncing: Bool) -> Verdict {
        guard attempt == .reachedICloud, !exportFailed, !stillSyncing else { return .waitForUpload }
        return .safeToArmWipe
    }

    /// **Sin espejo no hay nada que esperar, y esperar sería un cuelgue.** El camino
    /// `.askBeforeWiping` —corpus local en un teléfono sin cuenta de iCloud— no puede subir nada a
    /// ninguna parte: `forceSync` devolvería `.failed` por su propio `guard isAccountAvailable`, y el
    /// veredicto de arriba diría «espera» **para siempre**. Ahí lo que autoriza el borrado no es una
    /// subida sino el segundo gesto de la persona, que ya sabe lo que pierde.
    static func requiresUploadBeforeWipe(mirrorsToICloud: Bool) -> Bool {
        mirrorsToICloud
    }
}
