//
//  ICloudPersonalCorpusProbe.swift
//  Yala
//
//  Paso 4 del rediseño de sesiones · **preguntarle a iCloud qué hay ANTES de montarle el espejo encima.**
//
//  El problema que resuelve, medido en device el 2026-09-09: una instalación fresca monta el store
//  personal NEUTRO (`SwiftDataConfiguration.personalStoreDecision` → `.neutralNoMirror`), o sea sin
//  espejo de CloudKit. Ese store está VACÍO por construcción, así que cualquier detector que cuente
//  filas locales —`ContentView.checkHasExistingData`, `ModelContext.iCloudAccountSummary`— responde
//  «no hay datos» aunque el Apple ID tenga meses de histórico en su iCloud. Decisión de Jürgen
//  (2026-09-09): la validación **pregunta a CloudKit directamente y sin adjuntar el espejo**, para que
//  el aviso salga en el mismo gesto en que se elige «privado» y no haya pantalla de reinicio ciega.
//
//  ES EL PRIMER LECTOR DE REGISTROS DE CLOUDKIT DEL REPO, y conviene saberlo al tocarlo: hasta hoy había
//  tres call-sites del framework y ninguno leía nada —`allRecordZones()` como ping en
//  `iCloudSyncService.forceSync`, `userRecordID()` para la identidad de Grupos, y `CKNotification` para
//  clasificar un push—. Todo lo demás que «mira CloudKit» en `Yala/` lee las side-tables del mirror por
//  SQLite (`CKIdentityCapture`), que aquí no sirve: esas tablas son locales y en una instalación fresca
//  están vacías igual que el store.
//
//  **Por qué `recordZoneChanges` y no `CKQueryOperation`.** Una query sobre `CD_TransactionItem` exige
//  que el tipo tenga el índice `queryable` en el esquema, y eso NO está garantizado para los tipos que
//  crea `NSPersistentCloudKitContainer` (él sincroniza por cambios de zona, no por queries). Un fallo así
//  solo se vería en device y contra el contenedor de producción. `recordZoneChanges` no depende de
//  índices, pagina sola con `moreComing` y con `desiredKeys` acotado baja payloads mínimos.
//
//  **La zona NO se hardcodea.** Se enumeran las zonas reales con `allRecordZones()` y se filtran por
//  prefijo. El literal `com.apple.coredata.cloudkit.zone` no aparece hoy en producción —`CKIdentityCapture`
//  resuelve la zona por FK, precisamente para no depender de un nombre— y este fichero no lo convierte en
//  verdad única: si Apple añadiera una segunda zona al mirror, el prefijo la coge igual.
//
//  **Qué NO toca:** el contenedor de Grupos (`groupsCloudKitContainerIdentifier`) es OTRO contenedor y no
//  se enumera ni se borra. El ADR §6 dice que «Vaciar datos» nunca se lleva grupos, y esto es más
//  destructivo que aquello.
//

import CloudKit
import Foundation

// MARK: - Lo que la sonda encuentra

/// Qué hay en el iCloud privado de este Apple ID, contado en el propio contenedor.
///
/// **Espeja `ICloudAccountSummary` a propósito, y no lo reusa.** Aquél cuenta filas de un `ModelContext`
/// —o sea, lo que el espejo ya bajó— y esta sonda existe justamente para el momento en que no hay espejo.
/// Los criterios de exclusión sí son los mismos, porque el hecho que describen es el mismo: cuentas y
/// categorías de sistema no son datos del usuario (las crea el bridge de Grupos en el bootstrap, antes
/// del onboarding, y contarlas diría «hay datos» en una instalación recién hecha), y las transacciones
/// bridgeadas son derivados de un grupo, no movimientos que el usuario escribiera.
nonisolated struct ICloudPersonalCorpus: Equatable, Sendable, Identifiable {
    /// Movimientos del usuario: `CD_TransactionItem` sin `CD_splitExpenseID` ni `CD_splitSettlementID`.
    let transactions: Int
    /// Cuentas propias: `CD_Account` sin `CD_isSystemAccount`.
    let accounts: Int
    /// Subcategorías propias: `CD_Subcategory` sin `CD_isSystem`.
    let categories: Int
    /// El movimiento más antiguo, para el «desde <fecha>» del aviso. `nil` si no hay ninguno con fecha
    /// legible — el copy tiene que aguantarlo sin prometer una fecha que no tiene.
    let oldestTransactionDate: Date?
    /// Se alcanzó el tope de registros y las cifras son un MÍNIMO, no un total. El copy lo dice.
    let truncated: Bool

    /// Mismo criterio que `ICloudAccountSummary.hasAnyData`: tres cifras, cualquiera de ellas basta.
    /// **Se pregunta por los tres y no solo por los movimientos** porque un corpus real puede no tener
    /// ninguno todavía —alguien que creó sus cuentas y lo dejó— y borrárselo sin avisar sería el mismo
    /// bug con otro disfraz.
    ///
    /// **Y `truncated` cuenta como «sí hay», aunque las tres cifras sean cero** (review adversarial,
    /// 2026-09-10). El tope se cuenta sobre TODOS los tipos de la zona —el schema personal espeja
    /// tasas, notificaciones, etiquetas, presupuestos…— y `recordZoneChanges` no garantiza ningún orden,
    /// así que un corpus enorme puede agotar el tope antes de que llegue el primer `CD_TransactionItem`.
    /// `truncated` significa **«no lo sé»**, y leerlo como «no hay» borraría el histórico de quien más
    /// tiene sin decirle una palabra — que es exactamente el bug de este ticket, con otro disfraz.
    var hasAnyData: Bool {
        truncated || transactions > 0 || accounts > 0 || categories > 0
    }

    /// `Identifiable` para el `.sheet(item:)` del aviso tardío. La identidad son las CIFRAS: dos sondas
    /// que miden lo mismo describen el mismo hecho, así que no re-presentan la hoja. El fallo seguro es
    /// ese — una hoja que reaparece encima de sí misma sería una presentación sobre otra.
    var id: String { "\(transactions)-\(accounts)-\(categories)-\(truncated)" }

    static let empty = ICloudPersonalCorpus(
        transactions: 0, accounts: 0, categories: 0, oldestTransactionDate: nil, truncated: false)
}

/// Cómo terminó la sonda. Tres desenlaces y **ninguno bloquea**, que es la regla del ADR §9.
nonisolated enum ICloudProbeOutcome: Equatable, Sendable {
    /// Se pudo preguntar. El corpus puede estar vacío — eso también es una respuesta.
    case measured(ICloudPersonalCorpus)
    /// No hay iCloud en el dispositivo (estado **K** de la matriz). No es un error: no hay a quién
    /// preguntar, y la app sigue en local.
    case noAccount
    /// Se pudo intentar y falló: red, CloudKit caído, timeout. Se distingue de `noAccount` porque el
    /// remedio es distinto — aquí reintentar puede funcionar, allí no.
    case failed(String)
}

// MARK: - La sonda

/// Lee y borra el corpus personal del contenedor de iCloud **sin adjuntar el espejo al store**.
///
/// `@MainActor` como el resto de servicios del Welcome; el trabajo real está en `await`, así que no
/// bloquea. Los dos seams son `static var` inyectables y no un protocolo, siguiendo el molde ya usado por
/// `GroupICloudIdentitySeed.recordNameFetcher`: hay un solo implementador de producción y lo que los
/// tests necesitan es sustituirlo, no abstraerlo.
@MainActor
enum ICloudPersonalCorpusProbe {

    /// Tope de registros que se recorren antes de rendirse y decir «al menos N». Un corpus de años cabe
    /// de sobra.
    static let recordScanCap = 20_000

    /// **Y el tope que de verdad acota la ESPERA.** El de registros no lo hace, y el docblock decía que
    /// sí: una página que vuelve vacía no incrementa el contador, así que la terminación dependía entera
    /// de que el servidor dijera `moreComing == false`. Con CloudKit lento, la persona se quedaba mirando
    /// «Revisando qué hay en tu iCloud…» sin salida — y en la puerta del Welcome eso es la app entera.
    ///
    /// Rendirse por tiempo cae en `.failed`, no en «vacío»: la pantalla ofrece reintentar **y** seguir sin
    /// comprobar. Lo que no puede pasar es que decidamos por ella que no tiene datos.
    static let scanDeadline: TimeInterval = 25

    /// Prefijo de las zonas que crea `NSPersistentCloudKitContainer` para el store privado. Se compara
    /// por PREFIJO y no por igualdad: si el mirror repartiera el schema en varias zonas, las coge todas.
    static let mirrorZonePrefix = "com.apple.coredata.cloudkit"

    /// Los únicos campos que se bajan. Todo lo demás llega como metadato del sistema (`recordType`,
    /// `creationDate`), que es gratis.
    ///
    /// **La lista es UNA para una zona MULTI-TIPO, y eso no está medido contra CloudKit real.**
    /// `CD_isSystemAccount` no existe en el schema de `CD_TransactionItem` ni `CD_date` en el de
    /// `CD_Account`. Lo esperado es que el servidor devuelva cada registro sin las keys que no le
    /// corresponden; si en cambio validara la lista contra el schema del tipo, **cada página lanzaría** y
    /// la rama privada quedaría en «reintentar» para siempre. Es el primer lector de registros del repo,
    /// así que no hay precedente donde apoyarse: **va como punto BLOQUEANTE del device-QA**, con su plan B
    /// escrito (bajar solo metadatos y sobrecontar, que falla hacia el lado seguro).
    ///
    /// Una key que falte degrada la CIFRA, nunca la decisión: sin `CD_splitExpenseID` las bridgeadas
    /// contarían como movimientos y el aviso diría un número de más.
    static let desiredKeys: [CKRecord.FieldKey] = [
        "CD_splitExpenseID", "CD_splitSettlementID", "CD_isSystemAccount", "CD_isSystem", "CD_date"
    ]

    // MARK: Seams

    /// Sonda de producción. Sustituible en tests (no hay CloudKit en simulador ni en CI).
    static var probe: @MainActor () async -> ICloudProbeOutcome = { await measureFromCloudKit() }

    /// Borrado de producción. Devuelve `nil` si fue bien, o el motivo del fallo.
    static var wipe: @MainActor () async -> String? = { await deleteMirrorZonesFromCloudKit() }

    /// **¿Espeja ESTE arranque?** No es «¿hay iCloud?», y la diferencia es el defecto más grave que cazó
    /// la review adversarial del 2026-09-10.
    ///
    /// **Solo lo consume el aviso TARDÍO**, y el matiz es load-bearing: contesta si el espejo está puesto
    /// AHORA, que es exactamente la pregunta de ese camino —«¿hay algo bajando encima de lo que la persona
    /// acaba de crear?»— y **no** la de la puerta del Welcome. Allí el mount es `.neutralNoMirror`, que
    /// devuelve `false` porque todavía no adjunta nada; usarlo como pre-filtro apagaba la puerta justo en
    /// el caso principal del ticket.
    ///
    /// La primera versión preguntaba `SwiftDataConfiguration.isICloudAvailable()`, o sea
    /// `ubiquityIdentityToken != nil`, que mide **iCloud Drive**. Un Apple ID con Drive apagado y CloudKit
    /// funcionando salía por «no se pudo validar» → la persona continuaba → y el mount `.localNoMirror`
    /// **adjunta el espejo igual**, porque no pasa `cloudKitDatabase:` y cae en `.automatic` (medido en la
    /// auditoría R1(c), `PersonalStoreDecision.attachesCloudKitMirror`). O sea: el histórico bajaba encima
    /// del onboarding recién hecho, por el predicado elegido para impedirlo.
    ///
    /// El hecho que importa es si **este proceso montó un store que espeja**, y de eso hay un testigo
    /// exacto y gratis. `CKContainer.accountStatus()` sigue descartado por la decisión escrita en
    /// `ICloudCutoverGateLogic` y `MigrationWorkExecutor`: aquí no se añade una segunda verdad, se lee la
    /// que ya gobierna.
    static var mirrorWillSync: @MainActor () -> Bool = {
        SwiftDataConfiguration.personalStoreMountedDecision.attachesCloudKitMirror
    }

    /// **¿El store de este proceso espeja hacia el iCloud del Apple ID?** El hermano ESTRECHO de
    /// `mirrorWillSync`, y la diferencia entre los dos es justo el caso que separa las dos ramas nuevas
    /// de la puerta de Grupos (paso 5-b): `attachesCloudKitMirror` es `true` también en `.localNoMirror`
    /// —el mount sin cuenta iCloud, que adjunta el espejo igual por caer en `.automatic`— y ahí **no hay
    /// iCloud que respalde nada**, así que borrar lo local sería pérdida definitiva y no una vuelta al
    /// neutro. `mirrorsToICloud` es `true` solo en `.iCloudMirror`.
    ///
    /// **Es un seam y no una lectura directa porque el testigo MIENTE en los hosts de test.**
    /// `personalConfiguration` retorna antes de capturarlo bajo `isRunningTests` / `isUITesting`, así que
    /// el testigo se queda con su default `.iCloudMirror` — o sea, «espejo vivo» en un simulador que no
    /// tiene cuenta de iCloud. Leerlo crudo mandaría **todos** los XCUITest de la rama organizador a la
    /// vuelta al neutro. Por eso el default de producción excluye el host de UITest, y el hook
    /// `-uitest-groups-gate-mirror-live` es lo que permite recorrer esa rama en simulador a propósito.
    static var mirrorsToICloudNow: @MainActor () -> Bool = { productionMirrorsToICloudNow() }

    /// El cuerpo del seam, con nombre, para que `_testReset` no lo duplique — dos copias de un default
    /// divergen en cuanto alguien toca una.
    static func productionMirrorsToICloudNow() -> Bool {
        guard !SwiftDataConfiguration.isUITesting else { return UITestHooks.groupsGateMirrorLive }
        // **Y el host de unit tests miente igual**, por la misma razón: `personalConfiguration` retorna
        // antes de capturar el testigo bajo `isRunningTests`, así que el default `.iCloudMirror` gana.
        // Sin este término, un test que olvide inyectar el seam mide la rama del espejo vivo creyendo
        // medir la otra — y ésa es la que borra.
        guard !SwiftDataConfiguration.isRunningTests else { return false }
        return SwiftDataConfiguration.personalStoreMountedDecision.mirrorsToICloud
    }

    #if DEBUG
    /// Repone los cuatro seams. Lo llaman los tests entre casos.
    static func _testReset() {
        probe = { await measureFromCloudKit() }
        wipe = { await deleteMirrorZonesFromCloudKit() }
        mirrorWillSync = { SwiftDataConfiguration.personalStoreMountedDecision.attachesCloudKitMirror }
        mirrorsToICloudNow = { productionMirrorsToICloudNow() }
    }
    #endif

    // MARK: Implementación de producción

    private static var privateDatabase: CKDatabase {
        CKContainer(identifier: SwiftDataConfiguration.cloudKitContainerIdentifier).privateCloudDatabase
    }

    /// Enumera las zonas del mirror. Vacío significa «este Apple ID nunca espejó nada aquí», que es una
    /// respuesta legítima y no un error.
    private static func mirrorZoneIDs() async throws -> [CKRecordZone.ID] {
        try await privateDatabase.allRecordZones()
            .map(\.zoneID)
            .filter { $0.zoneName.hasPrefix(mirrorZonePrefix) }
    }

    /// **No hay gate local antes de preguntar, y es deliberado.** Quien sabe si CloudKit puede contestar
    /// es CloudKit: `notAuthenticated` y `managedAccountRestricted` SON la respuesta «no hay cuenta a la
    /// que preguntar», y cualquier predicado local que se adelante a ellas es un pre-filtro que tapa al
    /// criterio (aquí lo fue: ver `mirrorWillSync`).
    private static func measureFromCloudKit() async -> ICloudProbeOutcome {
        let startedAt = Date()
        do {
            var transactions = 0
            var accounts = 0
            var categories = 0
            var oldest: Date?
            var scanned = 0
            var truncated = false

            for zoneID in try await mirrorZoneIDs() {
                var token: CKServerChangeToken?
                var moreComing = true
                while moreComing {
                    let batch = try await privateDatabase.recordZoneChanges(
                        inZoneWith: zoneID, since: token, desiredKeys: desiredKeys)
                    for (_, result) in batch.modificationResultsByID {
                        // **Un registro que falla NO se salta en silencio.** Los fallos parciales son el
                        // canal normal de reporte de esta API, y descartarlos mide de menos hacia el lado
                        // peligroso: menos registros ⇒ «iCloud vacío» ⇒ borrado sin avisar. Un throw a
                        // nivel de zona ya da `.failed`; los dos hechos son el mismo y merecen el mismo
                        // veredicto.
                        guard case .success(let modification) = result else {
                            return .failed("partialRecordFailure")
                        }
                        scanned += 1
                        classify(modification.record,
                                 transactions: &transactions,
                                 accounts: &accounts,
                                 categories: &categories,
                                 oldest: &oldest)
                    }
                    token = batch.changeToken
                    moreComing = batch.moreComing
                    if scanned >= recordScanCap {
                        truncated = true
                        moreComing = false
                    }
                    // El deadline corta la ESPERA, no el conteo: si se agota, lo medido hasta aquí no es
                    // una respuesta y no puede presentarse como tal.
                    if Date().timeIntervalSince(startedAt) > scanDeadline {
                        return .failed("scanDeadline")
                    }
                }
                if truncated { break }
            }

            return .measured(ICloudPersonalCorpus(
                transactions: transactions,
                accounts: accounts,
                categories: categories,
                oldestTransactionDate: oldest,
                truncated: truncated))
        } catch let error as CKError {
            #if DEBUG
            print("ICloudPersonalCorpusProbe: probe failed: \(error)")
            #endif
            // **`notAuthenticated` es el estado K de verdad**, y solo CloudKit puede declararlo.
            if error.code == .notAuthenticated || error.code == .managedAccountRestricted {
                return .noAccount
            }
            // El código, no el nombre del tipo: `CKError` a secas no distingue una cuota agotada de una
            // red caída, y el canario que lo recibe es la única superficie de observación que hay.
            return .failed("CKError.\(error.code.rawValue)")
        } catch {
            #if DEBUG
            print("ICloudPersonalCorpusProbe: probe failed: \(error)")
            #endif
            return .failed(String(describing: type(of: error)))
        }
    }

    /// Un registro → su casilla.
    ///
    /// **Las exclusiones se PARECEN a las de `ModelContext.iCloudAccountSummary`, no la espejan.** Aquél
    /// descarta además las cuentas archivadas y las de `type == "system"`; aquí no se puede sin ampliar
    /// `desiredKeys`, que es justo la lista que el device-QA tiene que validar primero. La diferencia
    /// cuenta de MÁS (un Apple ID cuyo único corpus sean cuentas archivadas dispara el aviso), y ese es el
    /// lado seguro: un aviso que sobra se cancela, uno que falta borra un histórico.
    private static func classify(_ record: CKRecord,
                                 transactions: inout Int,
                                 accounts: inout Int,
                                 categories: inout Int,
                                 oldest: inout Date?) {
        switch record.recordType {
        case "CD_TransactionItem":
            guard record["CD_splitExpenseID"] == nil, record["CD_splitSettlementID"] == nil else { return }
            transactions += 1
            if let date = record["CD_date"] as? Date, oldest.map({ date < $0 }) ?? true {
                oldest = date
            }
        case "CD_Account":
            guard !isFlagSet(record["CD_isSystemAccount"]) else { return }
            accounts += 1
        case "CD_Subcategory":
            guard !isFlagSet(record["CD_isSystem"]) else { return }
            categories += 1
        default:
            return
        }
    }

    /// **Un `Bool` de Core Data NO viaja como `Bool` por CloudKit: viaja como número**, así que
    /// `as? Bool` da `nil` siempre y `as? Int` depende de si el valor llega como `Int64` nativo o
    /// puenteado desde `NSNumber` — `Int64` no casa con `Int` por `as?` aunque midan lo mismo. `NSNumber`
    /// es lo único que cubre las tres formas (`Bool`, `Int`, `Int64`) por bridging.
    ///
    /// **Y el default es `false` —«no es de sistema, cuéntalo»— a propósito.** Los dos errores no cuestan
    /// lo mismo: contar de más saca un aviso que la persona cancela; contar de menos deja el aviso sin
    /// salir y le borra su histórico sin preguntar. Ante un campo ilegible, sobra un aviso.
    private static func isFlagSet(_ value: Any?) -> Bool {
        (value as? NSNumber)?.boolValue ?? false
    }

    /// Borra las zonas del mirror. **Borrar la zona y no sus registros** es lo que deja el contenedor a
    /// cero sin adjuntar el espejo: `NSPersistentCloudKitContainer` recrea una zona vacía la próxima vez
    /// que arranque con el mirror puesto.
    ///
    /// **Es idempotente, y de eso depende la kill-safety**: borrar una zona que ya no existe no es un
    /// error, y si no queda ninguna la operación no tiene nada que hacer.
    private static func deleteMirrorZonesFromCloudKit() async -> String? {
        do {
            let zoneIDs = try await mirrorZoneIDs()
            guard !zoneIDs.isEmpty else { return nil }
            let (_, deleteResults) = try await privateDatabase.modifyRecordZones(
                saving: [], deleting: zoneIDs)
            // **`modifyRecordZones` solo LANZA por un fallo de la operación entera.** Los fallos POR ZONA
            // —`zoneBusy`, `quotaExceeded`, una red que se cae a medio batch— llegan aquí dentro, en
            // silencio. Descartar este tuple con `_ =` era reportar éxito sobre un borrado que no ocurrió:
            // el arm se retiraba, nadie reintentaba, y en el camino tardío el store local ya se había
            // vaciado ⇒ la persona se quedaba sin sus datos locales Y con el corpus viejo entero en
            // iCloud, que es la peor combinación de las posibles.
            for (_, result) in deleteResults {
                guard case .failure(let error) = result else { continue }
                if let ck = error as? CKError,
                   ck.code == .zoneNotFound || ck.code == .userDeletedZone { continue }
                #if DEBUG
                print("ICloudPersonalCorpusProbe: zone delete failed: \(error)")
                #endif
                return (error as? CKError).map { "CKError.\($0.code.rawValue)" }
                    ?? String(describing: type(of: error))
            }
            return nil
        } catch let error as CKError where error.code == .zoneNotFound || error.code == .userDeletedZone {
            // Ya no estaba: el borrado anterior llegó a completarse aunque su arm no se limpiara.
            return nil
        } catch let error as CKError {
            #if DEBUG
            print("ICloudPersonalCorpusProbe: wipe failed: \(error)")
            #endif
            return "CKError.\(error.code.rawValue)"
        } catch {
            #if DEBUG
            print("ICloudPersonalCorpusProbe: wipe failed: \(error)")
            #endif
            return String(describing: type(of: error))
        }
    }
}
