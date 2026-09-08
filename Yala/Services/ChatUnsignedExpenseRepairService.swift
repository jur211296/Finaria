//
//  ChatUnsignedExpenseRepairService.swift
//  Yala
//
//  Barrido one-shot de las transacciones que el chat guardó sin firmar.
//  Ticket `chat-rows-with-unsigned-amount-have-no-repair-path`.
//

import Foundation
import SwiftData

/// Le devuelve el signo a los gastos que `ChatAssistantViewModel.saveDraft` guardó con la magnitud sin
/// firmar entre el 2026-04-27 y el arreglo (`cb3779f9`, PR #102).
///
/// **Por qué hace falta un barrido y no basta con lo que ya existe.** Ninguno de los cinco mecanismos
/// que tocan estas columnas corrige un signo, medido el 2026-09-08: `recalculatePreferredCurrency`
/// nunca asigna `amount` y propaga el signo malo al convertido;
/// `TransactionUpdateService.updateProvisionalTransactions` filtra por
/// `isExchangeRateProvisional == true` y el grueso del corpus se selló en `false`; `TransactionService` y
/// `RecordsViewModel` preservan el signo existente a propósito; y `CloudSyncReconciler` lo dice en su
/// propio comentario. Sin esto, las filas quedan mal para siempre salvo que el usuario las edite una
/// a una.
///
/// **One-shot a propósito**, igual que `TransactionUpdateService.repairLegacyOneToOneRatesIfNeeded`:
/// el estado que busca solo lo produce el código viejo, así que repetirlo en cada arranque sería
/// recorrer todas las transacciones para siempre a cambio de nada. Y `amount` viaja por el canal nube
/// en el grupo de coherencia `money`: cada fila corregida emite, que es justo lo que se quiere —la
/// corrección se propaga a los demás dispositivos— pero conviene que ocurra una vez y no en bucle.
///
/// **Residual conocido y aceptado, en sus dos mitades:** un segundo dispositivo que siga con el build
/// viejo puede seguir creando filas sin firmar y mandarlas por sync después de que este barrido ya
/// haya corrido aquí; y ese mismo dispositivo **tampoco puede barrer**, así que el corpus que solo
/// viva allí sigue roto mientras el flag de este ya está quemado. Es inherente a cualquier one-shot y
/// se cierra solo cuando ese dispositivo actualiza y corre el suyo. Lo que sí se cierra aquí es el
/// caso en que ESTE dispositivo quema el flag sin haber visto el corpus — ver el guard de presencia.
@MainActor
enum ChatUnsignedExpenseRepairService {

    /// Clave del flag idempotente. Se corre UNA vez por dispositivo.
    static let repairSweepKey = "chatUnsignedExpenseRepairSweep.v1"

    /// Voltea las filas de la ventana que tienen la forma del bug. Devuelve cuántas reparó.
    ///
    /// El flag se marca **solo si el barrido llegó al final**: si el fetch falla, no ha corrido y debe
    /// reintentarse en el próximo arranque. La espera a que el store esté quieto es del llamador
    /// (`AppBootstrapper`), que es quien tiene el gate; aquí se asume que ya se resolvió.
    ///
    /// - Parameter now: cierre de la ventana. Inyectable para los tests; en producción es el instante
    ///   real de ejecución — ver `ChatUnsignedExpenseRepairLogic.isWithinWindow`.
    @discardableResult
    static func repairUnsignedChatExpensesIfNeeded(
        context: ModelContext,
        defaults: UserDefaults = .standard,
        now: Date = Date.now
    ) -> Int {
        guard !defaults.bool(forKey: repairSweepKey) else { return 0 }

        // Sin ventana no hay barrido posible, y sobre todo no hay que QUEMAR el one-shot: el
        // `?? .distantFuture` de `windowStart` es inalcanzable con sus componentes, pero si alguna vez
        // se alcanzara, `isWithinWindow` diría siempre `false`, el barrido llegaría igualmente al
        // `set(true)` del final y el corpus se quedaría sin cura para siempre — incluso después de
        // arreglar la constante. «Falla hacia el lado seguro» solo es cierto si además no se sella.
        guard ChatUnsignedExpenseRepairLogic.windowStart != .distantFuture else {
            #if DEBUG
            print("ChatUnsignedExpenseRepairService: ventana no resoluble; no se marca el flag")
            #endif
            return 0
        }

        // El predicado es SOLO un pre-filtro barato, y deliberadamente más ancho que el criterio: la
        // decisión de qué fila se voltea la toma entera `ChatUnsignedExpenseRepairLogic.isCandidate`.
        //
        // La ventana estaba también aquí y se quitó el 2026-09-08 tras medirlo: con el acotado
        // duplicado, los tests que exigen que un reembolso de fuera de la ventana sobreviva pasaban
        // por ESTE filtro y no por el criterio, así que un mutante que borrase la ventana de
        // `isCandidate` los dejaba VERDES. Dos implementaciones del mismo criterio no solo se
        // desincronizan: esconden cuál de las dos manda cuando llega el rojo.
        //
        // La categoría tampoco entra: es una relación OPCIONAL, y un `#Predicate` que navega una
        // relación así es terreno resbaladizo en SwiftData — el mismo motivo por el que el reparador
        // de tasas deja su comparación de divisas fuera del predicado.
        let descriptor = FetchDescriptor<TransactionItem>(
            predicate: #Predicate { $0.amount > 0 }
        )

        do {
            // **El flag no se quema sobre un store que todavía no tiene el corpus.**
            //
            // `awaitPersonalStoreReady()` contesta «¿es seguro guardar?», no «¿han llegado ya los
            // datos?», y dos de sus ramas abren sobre un store vacío: `runNoAccount`
            // (`BootSaveGateLogic.swift:154`) responde de inmediato, sin gracia ni poll, en cuanto no
            // hay cuenta de iCloud disponible en ese instante —que no es lo mismo que «no la habrá»—;
            // y `runEmptyStore` (`:167`) abre tras 60 s sin ver un import, algo que un restore lento
            // alcanza. Sin esta comprobación, un primer arranque tras reinstalar —con la sesión de
            // iCloud aún no lista, o con el restore más lento que la gracia— barría cero filas, marcaba
            // el flag y dejaba el corpus roto PARA SIEMPRE cuando bajara en el arranque siguiente: por
            // la propia premisa del ticket, no hay ningún otro mecanismo que lo cure.
            //
            // Un store sin NINGUNA transacción no puede contener el corpus, así que el barrido no ha
            // podido hacer su trabajo y se reintenta. El coste en un usuario nuevo de verdad es un
            // `fetchCount` sobre un store vacío por arranque, hasta que registre su primera
            // transacción; entonces el barrido corre y el flag se marca.
            //
            // Copiar el re-chequeo de quiescencia que hace `migrateToLiveBalanceIfNeeded` NO cerraría
            // esto: en las dos ramas de escape el store SÍ está quiescente. Lo que falta no es
            // quiescencia, es presencia del corpus.
            //
            // El reparador de tasas del que este barrido copia la forma tiene el mismo punto ciego
            // (`TransactionUpdateService.swift:82-83`). Allí una fila que se escape conserva una tasa
            // 1:1 sellada; aquí infla el saldo para siempre, así que aquí sí compensa cerrarlo.
            guard try context.fetchCount(FetchDescriptor<TransactionItem>()) > 0 else {
                #if DEBUG
                print("ChatUnsignedExpenseRepairService: store sin transacciones; se reintenta en el próximo arranque")
                #endif
                return 0
            }

            let candidates = try context.fetch(descriptor).filter {
                ChatUnsignedExpenseRepairLogic.isCandidate(
                    ChatUnsignedExpenseRepairLogic.RowFacts(
                        amount: $0.amount,
                        categoryIsIncome: $0.category?.isIncome,
                        createdAt: $0.createdAt,
                        balanceAdjustmentType: $0.balanceAdjustmentType,
                        transferPairID: $0.transferPairID,
                        splitExpenseID: $0.splitExpenseID,
                        splitSettlementID: $0.splitSettlementID,
                        scheduledPaymentID: $0.scheduledPaymentID
                    ),
                    sweepRunAt: now
                )
            }

            for transaction in candidates {
                let repaired = ChatUnsignedExpenseRepairLogic.repairedAmounts(
                    amount: transaction.amount,
                    amountInPreferredCurrency: transaction.amountInPreferredCurrency
                )
                transaction.amount = repaired.amount
                transaction.amountInPreferredCurrency = repaired.amountInPreferredCurrency
            }

            if !candidates.isEmpty {
                SaveBreadcrumb.willSave("ChatUnsignedExpenseRepairService.repairUnsigned")
                try context.save()
                SaveBreadcrumb.didSave("ChatUnsignedExpenseRepairService.repairUnsigned")
                // El mismo cierre que `TransactionService` tras crear o editar una transacción, y aquí
                // no es adorno: este barrido corre en un `Task` desprendido que puede terminar hasta
                // dos minutos después del bootstrap, cuando el `incrementDataVersion()` del arranque ya
                // pasó. Sin esto, el saldo se corrige en el store pero el widget y las vistas que
                // cachean por `dataVersion` siguen enseñando el número inflado hasta el siguiente
                // movimiento del usuario — que es justo lo que el device-QA va a mirar.
                WidgetDataCache.updateCache(context: context)
                SessionState.shared.incrementDataVersion()
            }
            // El flag se marca aunque no hubiera candidatas: el barrido HIZO su trabajo.
            defaults.set(true, forKey: repairSweepKey)
            #if DEBUG
            print("ChatUnsignedExpenseRepairService: repaired \(candidates.count) unsigned chat expenses")
            #endif
            return candidates.count
        } catch {
            // Sin marcar el flag: si el fetch o el save fallaron, el barrido no ha corrido y se
            // reintenta en el próximo arranque.
            //
            // No hace falta deshacer las asignaciones que ya se hicieron sobre el contexto. El
            // barrido es IDEMPOTENTE por construcción: tanto el pre-filtro como el criterio piden
            // `amount > 0`, y una fila ya volteada deja de cumplirlo. Da igual que el `save()` fallido
            // acabe persistiéndose después por otra vía o que no se persista nada — en las dos
            // salidas, el reintento del próximo arranque no vuelve a tocar lo que ya está firmado.
            // Lo fija `alreadySignedExpense_isNotFlippedBack` para el camino completo y
            // `nonPositiveAmountsAreNeverCandidates` para el criterio por separado, que es el que el
            // pre-filtro tapaba.
            #if DEBUG
            print("ChatUnsignedExpenseRepairService: sweep failed: \(error)")
            #endif
            return 0
        }
    }
}
