//
//  GroupsAssociationDetach.swift
//  Yala
//
//  Paso 10 del rediseño de sesiones · **desasociar la cuenta de grupos de una sesión privada**, con las
//  DOS salidas que Jürgen decidió el 2026-09-09: conservar los movimientos que el puente metió en el
//  Panel, o quitarlos. Las dos implementadas, las dos probadas.
//
//  ## Las dos polaridades son las que ya existen, no una tercera
//
//  La cabecera de `LegacyGroupsRetirement` tiene la tabla de las CINCO mecánicas de limpieza del puente
//  (`LegacyGroupsRetirement.swift:33-40`), y el criterio con el que eligió la suya: no «¿destruyo o
//  congelo?», sino quién podrá arreglarlo si la elección resulta equivocada. Aquí:
//
//  | Salida        | TX de cuenta REAL | Espejo VIRTUAL (sistema) | Mecánica                      |
//  |---------------|-------------------|--------------------------|-------------------------------|
//  | **Conservar** | libera punteros   | BORRA                    | la del BARREDOR               |
//  | **Quitar**    | BORRA             | BORRA                    | `unbridgeDeletedRemotely`     |
//
//  **Conservar es la del barredor y no la del freeze**, por la misma razón que la retirada de los grupos
//  legacy: el freeze conserva el espejo virtual («debo 10», «presté 40»), y aquí ese espejo se queda sin
//  nadie que pueda limpiarlo después — `OrphanedBridgedTxSweeper.zoneIsSweepable` exige un veredicto de
//  zona que se construye de filas `SplitGroup` VIVAS, y desasociar las borra todas. Un fantasma
//  permanente y sin canario.
//
//  **Y por eso conservar tampoco puede dejar los punteros puestos**, que es lo que la primera redacción
//  del ticket pedía («conservando su `splitExpenseID` dormido»). Medido: con el puntero puesto y sin
//  filas de grupo, `NewTransactionView.resolveBridgedPointer` calcula `found == false` y la zona no
//  fresca ⇒ `bridgedPointerResolves == true` ⇒ **Borrar y Duplicar deshabilitados** sobre un gasto que ya
//  no existe, con un banner que ofrece abrir un grupo vacío. Es dinero ATRAPADO, el mismo bug que
//  `LegacyGroupsRetirement` documenta en su sección «La fila `SplitGroup` se CONSERVA». Y los sitios que
//  leen `splitExpenseID != nil` como «esto es de grupo» —33 en `Yala/`, medidos el 2026-09-11— tampoco
//  dejarían de marcarla.
//
//  ## Lo que sustituye al enlace dormido: el libro de conservados
//
//  `TransactionItem` **no tiene identidad propia serializable** (ni `id`, ni UUID estable: `syncID` es
//  opcional y en una sesión privada es `nil`), así que no hay forma honesta de guardar «devuélvele el
//  puntero a ESA fila». Lo que sí se puede guardar, y es lo que el criterio de aceptación persigue, es el
//  conjunto de gastos y liquidaciones **cuyo movimiento personal el usuario decidió conservar**, sellado
//  con el `sub` de la cuenta que se fue. Con eso:
//
//   · **Re-asociar la MISMA cuenta → cero duplicados.** El bridge no vuelve a crear la transacción de un
//     gasto que ya está en el Panel como movimiento personal.
//   · **Asociar OTRA cuenta → no se toca nada.** El sello no casa, y sus gastos llegan limpios.
//
//  Lo que NO vuelve, y se declara en vez de fingirlo: el ENLACE. El movimiento conservado sigue siendo un
//  movimiento personal normal —editable y borrable, que es justo lo que el usuario pidió al conservarlo—
//  y editar el gasto en el grupo ya no lo actualiza. Tiene ticket propio.
//

import Foundation
import SwiftData

// MARK: - El libro de conservados

/// Qué gastos y liquidaciones dejaron un movimiento personal vivo al desasociar, y de qué cuenta eran.
///
/// Molde `GroupsPendingBridgeIntent`: un blob JSON en `UserDefaults`, namespace `groups.*` para que el
/// «empiezo de cero» se lo lleve (`DataWipeService.removeGroupsDomainPreferenceKeys`). Sin TTL: no
/// caduca porque lo que afirma —«este gasto ya está en el Panel»— no deja de ser cierto con el tiempo.
nonisolated enum GroupsDetachedBridgeLedger {

    static let userDefaultsKey = "groups.conservedOnDetach"

    struct Stored: Codable, Equatable {
        /// `sub` de la cuenta que se desasoció. **El sello**: sin él, los conservados de una cuenta
        /// frenarían el puente de otra que resulte tener un gasto con el mismo UUID.
        let sub: String
        var expenseIDs: Set<String>
        var settlementIDs: Set<String>

        var isEmpty: Bool { expenseIDs.isEmpty && settlementIDs.isEmpty }
    }

    /// Registra lo conservado. **Reemplaza**, no acumula: un `sub` distinto es otra cuenta, y sus
    /// conservados no tienen nada que ver con los de la anterior.
    static func record(sub: String, expenseIDs: Set<String>, settlementIDs: Set<String>,
                       defaults: UserDefaults = .standard) {
        let stored = Stored(sub: sub, expenseIDs: expenseIDs, settlementIDs: settlementIDs)
        guard !stored.isEmpty else { return clear(defaults: defaults) }
        do {
            defaults.set(try JSONEncoder().encode(stored), forKey: userDefaultsKey)
        } catch {
            #if DEBUG
            print("GroupsDetachedBridgeLedger: no se pudo escribir: \(error)")
            #endif
        }
    }

    static func read(defaults: UserDefaults = .standard) -> Stored? {
        guard let data = defaults.data(forKey: userDefaultsKey) else { return nil }
        do {
            return try JSONDecoder().decode(Stored.self, from: data)
        } catch {
            // Ilegible: se descarta. Conservarlo dejaría el bridge frenado sin forma de repararse, que
            // es el lado peligroso — perder el libro solo cuesta un duplicado.
            #if DEBUG
            print("GroupsDetachedBridgeLedger: payload ilegible, se descarta: \(error)")
            #endif
            defaults.removeObject(forKey: userDefaultsKey)
            return nil
        }
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: userDefaultsKey)
    }

    /// ¿Este gasto ya está en el Panel como movimiento personal conservado, **de la cuenta que está
    /// asociada ahora**?
    ///
    /// El `associatedSub` se pasa por parámetro y no se lee aquí a propósito: el bridge corre en caliente
    /// y esta pregunta se le hace una vez por gasto.
    static func isConserved(expenseID: String, associatedSub: String?, defaults: UserDefaults = .standard) -> Bool {
        guard let stored = read(defaults: defaults), let associatedSub, stored.sub == associatedSub else {
            return false
        }
        return stored.expenseIDs.contains(expenseID)
    }

    static func isConserved(settlementID: String, associatedSub: String?, defaults: UserDefaults = .standard) -> Bool {
        guard let stored = read(defaults: defaults), let associatedSub, stored.sub == associatedSub else {
            return false
        }
        return stored.settlementIDs.contains(settlementID)
    }
}

// MARK: - El barrido del puente al desasociar

@MainActor
enum GroupsAssociationDetach {

    /// Qué se hace con los movimientos que el puente metió en el Panel. **Lo elige el usuario**, y las dos
    /// son válidas: decisión de Jürgen del 2026-09-09, que deroga el «se quedan siempre» del ticket.
    enum BridgedRowsChoice: Equatable, CaseIterable {
        /// Se quedan como movimientos personales normales. Es dinero que pasó.
        case keep
        /// Se van con la cuenta.
        case remove
    }

    struct Outcome: Equatable {
        var released = 0
        var deleted = 0
        var draftsConverted = 0
        var draftsDeleted = 0
        var conservedExpenses = 0
        var conservedSettlements = 0

        var isEmpty: Bool {
            released == 0 && deleted == 0 && draftsConverted == 0 && draftsDeleted == 0
        }
    }

    /// Suelta el puente personal de TODAS las zonas antes de que el store de grupos se vacíe.
    ///
    /// **Corre ANTES de `DataWipeService.wipeLocalGroupsDomain`**, y el orden es load-bearing por dos
    /// razones medidas: (1) con las filas `Split*` ya borradas no se puede saber qué zona era de qué
    /// canal ni qué gasto seguía vivo, y (2) `computeFreezePlan` decide si un borrador es un puntero
    /// redundante comparando su `splitExpenseID` con el de las transacciones — calculado después de
    /// mutar, la comparación da `false` siempre y aprobar un borrador duplicaría el gasto. Es la misma
    /// trampa de orden que documentan el barredor y la retirada de legacy.
    ///
    /// - Parameter associatedSub: el `sub` de la cuenta que se va. Sella el libro de conservados.
    /// - Returns: el recuento, o **`nil` si no se pudo ni mirar el puente** — en ese caso el llamador
    ///   DEBE abortar el desasociar: ver el `catch` del fetch.
    @discardableResult
    static func detachBridge(
        context: ModelContext,
        choice: BridgedRowsChoice,
        associatedSub: String?,
        defaults: UserDefaults = .standard
    ) -> Outcome? {
        var outcome = Outcome()

        let txs: [TransactionItem]
        let drafts: [InboxDraft]
        let backendZones: Set<String>
        do {
            // **Solo las zonas del canal BACKEND.** El puente de un grupo de la era CloudKit no es de la
            // cuenta que se desasocia y no le toca a este gesto: con `.remove` se llevaría por delante
            // transacciones de cuenta REAL que nunca tuvieron que ver con ella —dinero que salió de
            // verdad, en un store sin mirror que lo reponga—. Quien limpia aquéllas es
            // `LegacyGroupsRetirement`, y corre en el arranque detrás de su propio gate, así que en el
            // primer minuto tras un «Restaurar desde iCloud» todavía no ha pasado.
            //
            // El cuantificador es ANY-row por zona, la primitiva compartida de esta familia: por FILA se
            // lleva por delante la copia congelada de un grupo migrado y la gemela legacy de un duplicado
            // mixto.
            backendZones = try Self.backendChannelZones(context: context)
            // `#Predicate` CONCRETO por tipo y por comparación con `nil` — la misma forma que usan el
            // barredor y la retirada de legacy sobre estos campos. El filtro por zona va en memoria: el
            // conjunto no cabe en un `#Predicate` sin un `contains` sobre colección capturada.
            txs = try context.fetch(FetchDescriptor<TransactionItem>(
                predicate: #Predicate { $0.splitExpenseID != nil || $0.splitSettlementID != nil }))
                .filter { backendZones.contains($0.splitGroupZoneID ?? "") }
            drafts = try context.fetch(FetchDescriptor<InboxDraft>(
                predicate: #Predicate { $0.splitExpenseID != nil || $0.splitSettlementID != nil }))
                .filter { backendZones.contains($0.splitGroupZoneID ?? "") }
        } catch {
            // FALLA CERRADO en lo que este método escribe, y el LLAMADOR tiene que abortar: lo que
            // queda si sigue adelante NO es «lo que había antes». Sin este barrido, las filas se quedan
            // con sus punteros apuntando a una zona cuyas filas `Split*` el desasociar borra a
            // continuación, y esas huérfanas **no las recoge nadie**: `OrphanedBridgedTxSweeper` exige un
            // veredicto de zona que se construye de filas vivas. Es el dinero ATRAPADO de la cabecera,
            // esta vez para siempre. Por eso `detachBridge` devuelve `nil` aquí y no un `Outcome` vacío.
            #if DEBUG
            print("GroupsAssociationDetach: fetch del puente falló — el desasociar debe abortar: \(error)")
            #endif
            return nil
        }

        guard !txs.isEmpty || !drafts.isEmpty else {
            // Sin puente que soltar, el libro de una desasociación anterior deja de significar nada.
            GroupsDetachedBridgeLedger.clear(defaults: defaults)
            return outcome
        }

        // FASE 1 · plan de los borradores, con los punteros TODAVÍA intactos (ver el docblock).
        let freeze = GroupTransactionBridge.computeFreezePlan(transactions: txs, drafts: drafts)

        // FASE 2 · aplicar.
        var conservedExpenses: Set<String> = []
        var conservedSettlements: Set<String> = []

        for tx in txs {
            switch action(for: tx, choice: choice) {
            case .releasePointers:
                if let expenseID = tx.splitExpenseID { conservedExpenses.insert(expenseID) }
                if let settlementID = tx.splitSettlementID { conservedSettlements.insert(settlementID) }
                tx.splitExpenseID = nil
                tx.splitSettlementID = nil
                tx.splitGroupZoneID = nil
                outcome.released += 1
            case .delete:
                context.delete(tx)
                outcome.deleted += 1
            }
        }

        let manualRaw = DraftSourceType.manual.rawValue
        switch choice {
        case .keep:
            // Mismo reparto que el freeze y la retirada de legacy: el puntero redundante se borra (si
            // no, aprobarlo insertaría una transacción NUEVA junto a la recién liberada) y el resto
            // pasa a `.manual` preservando lo que el usuario ya había puesto.
            for draft in freeze.draftsToConvert {
                // El borrador conservado entra al libro igual que una transacción: si no, al re-asociar la
                // misma cuenta el puente crearía OTRO borrador del mismo gasto y el Inbox mostraría dos
                // entradas idénticas — aprobarlas mete el gasto dos veces en el Panel.
                if let expenseID = draft.splitExpenseID { conservedExpenses.insert(expenseID) }
                if let settlementID = draft.splitSettlementID { conservedSettlements.insert(settlementID) }
                convertToManual(draft, manualRaw: manualRaw)
                outcome.draftsConverted += 1
            }
            for draft in freeze.draftsToDelete {
                context.delete(draft)
                outcome.draftsDeleted += 1
            }
            // Los borradores que ningún plan nombró —el tercer tipo, `groupScheduledExpense`, que
            // `computeFreezePlan` no mira— también tienen que soltar su zona: sin esto sobreviven
            // apuntando a un grupo que ya no existe.
            let planned = Set(freeze.draftsToConvert.map(ObjectIdentifier.init))
                .union(freeze.draftsToDelete.map(ObjectIdentifier.init))
            for draft in drafts where !planned.contains(ObjectIdentifier(draft)) {
                if let expenseID = draft.splitExpenseID { conservedExpenses.insert(expenseID) }
                if let settlementID = draft.splitSettlementID { conservedSettlements.insert(settlementID) }
                convertToManual(draft, manualRaw: manualRaw)
                outcome.draftsConverted += 1
            }
        case .remove:
            // Se van con la cuenta: no queda nada que clasificar.
            for draft in drafts {
                context.delete(draft)
                outcome.draftsDeleted += 1
            }
        }

        guard !outcome.isEmpty else { return outcome }

        do {
            SaveBreadcrumb.willSave("GroupsAssociationDetach.detachBridge")
            try context.save()
            SaveBreadcrumb.didSave("GroupsAssociationDetach.detachBridge")
        } catch {
            #if DEBUG
            print("GroupsAssociationDetach: save falló: \(error)")
            #endif
            context.rollback()
            return Outcome()
        }

        // El libro se escribe DESPUÉS del save y solo si el save entró: un libro que afirme «esto ya
        // está en el Panel» sobre un cambio que no llegó a disco frenaría el puente de un gasto que
        // nunca tuvo transacción.
        switch choice {
        case .keep:
            outcome.conservedExpenses = conservedExpenses.count
            outcome.conservedSettlements = conservedSettlements.count
            if let associatedSub, !associatedSub.isEmpty {
                GroupsDetachedBridgeLedger.record(
                    sub: associatedSub,
                    expenseIDs: conservedExpenses,
                    settlementIDs: conservedSettlements,
                    defaults: defaults)
            }
        case .remove:
            GroupsDetachedBridgeLedger.clear(defaults: defaults)
        }

        SessionState.shared.incrementDataVersion()
        WidgetDataCache.updateCache(context: context)
        MetricsService.canary(
            .groupsAssociationDetached,
            detail: "choice=\(choice == .keep ? "keep" : "remove")|released=\(outcome.released)|deleted=\(outcome.deleted)|drafts=\(outcome.draftsConverted + outcome.draftsDeleted)")
        #if DEBUG
        print("GroupsAssociationDetach: choice=\(choice) released=\(outcome.released) deleted=\(outcome.deleted) draftsConverted=\(outcome.draftsConverted) draftsDeleted=\(outcome.draftsDeleted)")
        #endif
        return outcome
    }

    /// Zonas cuyas filas `SplitGroup` pertenecen al canal backend, con un solo fetch. ANY-row por zona,
    /// vía la primitiva compartida: es el mismo cuantificador, y por la misma razón, que usan
    /// `GroupZoneCacheGate`, `GroupChannelFreshness` y `LegacyGroupsRetirement`.
    private static func backendChannelZones(context: ModelContext) throws -> Set<String> {
        var byZone: [String: [(isBackendGroup: Bool, movedToBackendAt: Date?)]] = [:]
        for row in try context.fetch(FetchDescriptor<SplitGroup>()) where !row.cloudKitZoneID.isEmpty {
            byZone[row.cloudKitZoneID, default: []].append(
                (isBackendGroup: row.isBackendGroup, movedToBackendAt: row.movedToBackendAt))
        }
        return Set(byZone.filter { GroupZoneCacheGate.belongsToBackendChannel(rowsInZone: $0.value) }.keys)
    }

    // MARK: - Decisión

    enum Action: Equatable {
        case releasePointers
        case delete
    }

    /// Qué le pasa a UNA transacción puenteada.
    ///
    /// Con `.remove` se borran las dos mitades, que es la polaridad de `unbridge*` y lo que el ticket
    /// llama «el camino de borrado es el `unbridge*` de hoy». Con `.keep` se delega en
    /// `GroupTransactionBridge.classifyForSoftDelete`, el clasificador COMPARTIDO, por lo mismo que lo
    /// hace la retirada de legacy: resolver «real vs espejo» con una regla propia es el anti-patrón que
    /// este subsistema lleva media docena de arreglos persiguiendo. Lo que cambia respecto del freeze son
    /// las ACCIONES, no la clasificación.
    static func action(for tx: TransactionItem, choice: BridgedRowsChoice) -> Action {
        action(choice: choice, accountIsSystem: tx.account?.isSystemAccount == true)
    }

    /// Forma pura, para fijar la tabla sin `ModelContext`. `account == nil` cuenta como REAL (conservar):
    /// ante la duda, preservar el rastro.
    static func action(choice: BridgedRowsChoice, accountIsSystem: Bool) -> Action {
        guard choice == .keep else { return .delete }
        switch GroupTransactionBridge.classifyForSoftDelete(transactionAccountIsSystem: accountIsSystem) {
        case .releaseRealAccountTx: return .releasePointers
        case .preserveVirtualSystemTx: return .delete
        }
    }

    private static func convertToManual(_ draft: InboxDraft, manualRaw: String) {
        draft.sourceTypeRaw = manualRaw
        draft.splitExpenseID = nil
        draft.splitSettlementID = nil
        draft.splitGroupZoneID = nil
        draft.needsUserInput = []
    }
}
