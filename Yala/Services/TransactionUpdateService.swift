//
//  TransactionUpdateService.swift
//  Yala
//
//  Service to update transactions with provisional exchange rates.
//  Called on app launch to update transactions that were imported
//  without exact exchange rates for their dates.
//

import Foundation
import SwiftData

// MARK: - Transaction Update Service

/// Service that updates transactions with provisional exchange rates.
/// Called on app launch to fill in missing exchange rate data.
@MainActor
enum TransactionUpdateService {

    /// Updates all transactions that have provisional exchange rates.
    /// This function:
    /// 1. Finds all transactions where isExchangeRateProvisional == true
    /// 2. For each unique date, fetches exchange rates from API if missing
    /// 3. Recalculates and updates the transactions
    /// 4. Sets isExchangeRateProvisional = false
    ///
    /// - Parameter context: SwiftData ModelContext
    /// Clave del flag idempotente del barrido de reparación. Se corre UNA vez por dispositivo.
    private static let repairSweepKey = "fxOneToOneRepairSweep.v1"

    /// Devuelve a la cola de reparación las transacciones que quedaron con un 1:1 envenenado **antes**
    /// de que existiera el fix (`fx-partial-rate-rows-silent-1to1`, paso 2).
    ///
    /// No reconvierte nada: solo levanta `isExchangeRateProvisional`, y de eso ya se ocupa
    /// `updateProvisionalTransactions` unas líneas después, en el mismo arranque. Así hay UNA sola
    /// implementación de la conversión, no dos que se desincronizan — y el barrido se limita a
    /// deshacer el sellado, que es el daño que hay que revertir.
    ///
    /// **One-shot a propósito.** El estado que busca solo lo produce el código viejo; repetirlo en cada
    /// arranque sería recorrer todas las transacciones para siempre a cambio de nada. Y `exchangeRate`
    /// viaja por el canal nube en el grupo de coherencia `money`, así que cada fila marcada emite:
    /// conviene que ocurra una vez y no en bucle. (Matiz medido el 2026-09-08: emite la fila que
    /// CAMBIA de valor; una asignación idéntica ensucia el contexto pero no llega al outbox — ver
    /// `FXRepairQueueOutboxTests`. El razonamiento de fondo se sostiene; su mitad de sync era más
    /// débil de lo que decía.)
    static func repairLegacyOneToOneRatesIfNeeded(
        context: ModelContext,
        defaults: UserDefaults = .standard
    ) {
        guard !defaults.bool(forKey: repairSweepKey) else { return }

        let preferred = CurrencyDefaults.currentPreferred
        // El predicado filtra por `exchangeRate == 1.0` y la comparación de divisas se hace en Swift:
        // un `#Predicate` que compara dos propiedades del mismo modelo entre sí es terreno resbaladizo
        // en SwiftData, y aquí no compensa el riesgo (ver la regla de `#Predicate` en las rules).
        let descriptor = FetchDescriptor<TransactionItem>(
            predicate: #Predicate { $0.exchangeRate == 1.0 }
        )

        do {
            let candidates = try context.fetch(descriptor).filter {
                ExchangeRateRepairLogic.needsRepair(
                    exchangeRate: $0.exchangeRate,
                    currencyCode: $0.currencyCode,
                    preferredCurrencyCode: preferred
                )
            }
            // El guard de igualdad, por el mismo motivo que en `recalculatePreferredCurrency`: el
            // filtro (`needsRepair`) mira la tasa y la divisa, **nunca el flag**, así que la población
            // que ya está marcada —justo la que produce el bug de la fila parcial— recibía una
            // asignación idéntica que ensucia la fila y fuerza un `save()` por nada.
            var reopenedCount = 0
            for transaction in candidates where !transaction.isExchangeRateProvisional {
                transaction.isExchangeRateProvisional = true
                reopenedCount += 1
            }
            if reopenedCount > 0 {
                SaveBreadcrumb.willSave("TransactionUpdateService.repairLegacyOneToOne")
                try context.save()
                SaveBreadcrumb.didSave("TransactionUpdateService.repairLegacyOneToOne")
            }
            // El flag se marca aunque no hubiera candidatas: el barrido HIZO su trabajo.
            defaults.set(true, forKey: repairSweepKey)
            #if DEBUG
            print(
                "TransactionUpdateService: repair sweep reopened \(reopenedCount) of \(candidates.count) candidates"
            )
            #endif
        } catch {
            // Sin marcar el flag: si el fetch falló, el barrido no ha corrido y debe reintentarse en el
            // próximo arranque.
            #if DEBUG
            print("TransactionUpdateService: repair sweep failed: \(error)")
            #endif
        }
    }

    /// Clave de la huella del último barrido que no curó nada. Ver `FXRepairQueueLogic`.
    private static let futileSweepKey = "fxRepairQueue.futileSweepFingerprint.v1"

    static func updateProvisionalTransactions(
        context: ModelContext,
        defaults: UserDefaults = .standard
    ) async {
        // Gate de quiescencia: actualiza `TransactionItem` (store personal) + `save()`; diferir durante
        // el import del restore (idempotente: las provisionales se re-procesan en el próximo arranque).
        guard iCloudSyncService.shared.isImportQuiescent else {
            SaveBreadcrumb.deferred("TransactionUpdateService.updateProvisional", "import not quiescent")
            return
        }
        // 1. Find transactions with provisional exchange rates
        let descriptor = FetchDescriptor<TransactionItem>(
            predicate: #Predicate { $0.isExchangeRateProvisional == true }
        )

        let transactions: [TransactionItem]
        do {
            transactions = try context.fetch(descriptor)
        } catch {
            #if DEBUG
            print("TransactionUpdateService: Error fetching provisional transactions: \(error)")
            #endif
            return
        }
        guard !transactions.isEmpty else {
            // La cola está vacía: la huella describe un estado que ya no existe y retenerla podría
            // silenciar un barrido futuro por coincidencia.
            defaults.removeObject(forKey: futileSweepKey)
            return
        }

        // 1bis. La salida del bucle. Si nada de lo que decide el resultado se ha movido desde un
        // barrido que ya se demostró estéril, repetirlo da el mismo cero: se sale ANTES de pedir nada
        // por red. Coste de un arranque atascado: los dos fetches locales de arriba.
        //
        // Las divisas se piden NORMALIZADAS, que es como las compara quien decide la calidad
        // (`CurrencyConverter.resolveRates`). Con el código crudo, una grafía distinta haría que su
        // fecha figurase como descubierta para siempre: refetch inútil en cada intento.
        var needed = Set(transactions.map { normalizeCurrencyCode($0.currencyCode) })
        needed.insert(normalizeCurrencyCode(CurrencyDefaults.currentPreferred))
        let dates = Set(transactions.map { $0.date })

        let service = ExchangeRateService.shared
        // Las FECHAS de la cola, no su rango. Un gasto de 2023 y otro de hoy son dos fechas, no mil
        // días: pedir el intervalo entero refetchearía el histórico completo en cada intento, porque
        // si al proveedor le falta esa divisa le falta todos los días.
        let uncoveredBefore = service.uncoveredDates(among: dates, needing: needed, context: context)

        let fingerprintBefore = FXRepairQueueLogic.fingerprint(
            provisionalCount: transactions.count, uncoveredDateCount: uncoveredBefore.count)
        if FXRepairQueueLogic.shouldSkipSweep(
            current: fingerprintBefore, lastFutile: defaults.string(forKey: futileSweepKey))
        {
            #if DEBUG
            print(
                "TransactionUpdateService: cola atascada (\(transactions.count) provisionales, \(uncoveredBefore.count) fechas sin cubrir); nada nuevo desde el último intento, se salta"
            )
            #endif
            MetricsService.canary(
                .fxRepairQueueStuck, detail: "skipped", value: Double(transactions.count))
            return
        }

        // 2. Pedir las tasas que faltan. El resultado dice si TODAS las peticiones salieron bien: un
        //    fallo de red es transitorio y no puede sellarse como estéril.
        let allFetchesSucceeded = await service.fetchRates(for: uncoveredBefore, context: context)

        // 3. Recalcular cada transacción provisional.
        //
        // Antes esto preguntaba `hasExactRate(for:)` y, si decía que sí, reimplementaba a mano las
        // mismas cinco líneas de `TransactionItem.recalculatePreferredCurrency`. Dos problemas, los
        // dos del ticket `fx-partial-rate-rows-silent-1to1`: (a) `hasExactRate` responde por que la
        // FILA EXISTA, no por que traiga la divisa que hace falta, así que sobre una fila parcial
        // decía `true`, la conversión devolvía el monto crudo y la línea final sellaba
        // `isExchangeRateProvisional = false` — un 1:1 marcado como oficial y ya nunca revisitado,
        // porque el `#Predicate` de arriba solo busca `== true`; y (b) el cálculo duplicado se
        // desincroniza del punto de paso en cuanto uno de los dos cambia.
        //
        // Ahora se delega, y quien decide si sigue provisional es la CALIDAD de la tasa. El efecto
        // para el usuario es que una transacción con tasa aproximada se corrige sola en cuanto llegan
        // las tasas reales, en vez de quedarse con el número malo para siempre.
        //
        // Se cuentan DOS cosas distintas y hacen falta las dos: `sealedCount` son las que dejaron de
        // ser provisionales —lo que el log llama «curadas»— y `changedCount` las que cambiaron ALGO.
        // Una tasa arrastrada mejor que la anterior mejora el monto sin poder sellarlo: con el
        // contador de selladas como único criterio, ese trabajo no se guardaba y encima el barrido se
        // marcaba estéril, bloqueando el reintento de una mejora que sí había ocurrido.
        var sealedCount = 0
        var changedCount = 0

        for transaction in transactions {
            let before = MoneySnapshot(transaction)
            transaction.recalculatePreferredCurrency(context: context)
            if MoneySnapshot(transaction) != before { changedCount += 1 }
            if !transaction.isExchangeRateProvisional { sealedCount += 1 }
        }

        // 4. Guardar lo que haya cambiado.
        var savedCleanly = true
        if changedCount > 0 {
            do {
                SaveBreadcrumb.willSave("TransactionUpdateService.updateProvisional")
                try context.save()
                SaveBreadcrumb.didSave("TransactionUpdateService.updateProvisional")
            } catch {
                savedCleanly = false
                #if DEBUG
                print("TransactionUpdateService: Failed to save updates: \(error)")
                #endif
            }
        }

        // 5. Dejar constancia del resultado, y sobre todo del NO-resultado.
        //
        // **El log estaba dentro del `if updatedCount > 0`, así que el único estado que no imprimía
        // nada era justo el que hay que ver: la cola atascada.** Cuanto peor iba, más callaba.
        #if DEBUG
        print(
            "TransactionUpdateService: cola de reparación: \(transactions.count) provisionales, \(sealedCount) curadas, \(changedCount) tocadas, \(transactions.count - sealedCount) siguen"
        )
        #endif

        // 6. Sellar el veredicto.
        //
        // Solo se marca «estéril» un intento COMPLETO que no movió nada: si alguna petición falló o el
        // guardado no llegó a disco, el resultado es indeterminado y la huella **no se toca** —ni se
        // escribe ni se borra—. Escribirla convertiría un corte de red en una transacción que se queda
        // mal; borrarla dejaría sin freno un `save()` que falla siempre.
        if changedCount > 0 && savedCleanly {
            defaults.removeObject(forKey: futileSweepKey)
        } else if changedCount == 0 && allFetchesSucceeded {
            // La huella se recalcula AQUÍ, no se reusa la de la entrada: si el paso 2 trajo tasas
            // nuevas y aun así no curó nada, lo que hay que recordar es que **con esas tasas ya
            // incluidas** no había nada que hacer. Guardar la de antes dejaría el bucle vivo, porque
            // el arranque siguiente vería otra cobertura y volvería a intentarlo igual.
            let uncoveredAfter = service.uncoveredDates(
                among: dates, needing: needed, context: context)
            defaults.set(
                FXRepairQueueLogic.fingerprint(
                    provisionalCount: transactions.count, uncoveredDateCount: uncoveredAfter.count),
                forKey: futileSweepKey)
            MetricsService.canary(
                .fxRepairQueueStuck, detail: "futile", value: Double(transactions.count))
        }
    }

    /// Las cuatro columnas que `recalculatePreferredCurrency` puede tocar, para saber si tocó alguna.
    ///
    /// No se usa `context.hasChanges`: mide el contexto ENTERO —en el arranque lo comparten varios
    /// barridos— y diría que sí por el trabajo de otro.
    private struct MoneySnapshot: Equatable {
        let rate: Double
        let amountInPreferred: Double
        let preferredCode: String
        let isProvisional: Bool

        init(_ transaction: TransactionItem) {
            rate = transaction.exchangeRate
            amountInPreferred = transaction.amountInPreferredCurrency
            preferredCode = transaction.preferredCurrencyCode
            isProvisional = transaction.isExchangeRateProvisional
        }
    }
}
