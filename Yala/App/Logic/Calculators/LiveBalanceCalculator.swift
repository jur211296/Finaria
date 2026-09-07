//
//  LiveBalanceCalculator.swift
//  Yala
//
//  Calcula el saldo "vivo" del usuario en moneda preferida, agrupando
//  transacciones por moneda nativa y convirtiendo cada bucket con el TC
//  ACTUAL (no el TC del día de cada transacción). Esto refleja el valor
//  real disponible HOY.
//
//  Para flujos históricos (cashflow, income/gasto del mes, sankey, top
//  categorías) seguir usando `tx.amountInPreferredCurrency` directamente
//  — esa semántica es correcta porque refleja "qué pasó económicamente".
//

import Foundation
import SwiftData

struct LiveBalanceCalculator {

    /// Desglose por moneda nativa del saldo vivo, útil para debug y para
    /// futuras vistas educativas (FX P&L breakdown).
    struct Breakdown {
        let nativeBalances: [String: Decimal]
        let convertedTotal: Decimal
        let preferredCurrencyCode: String

        /// `true` si alguna de las divisas nativas se convirtió con una tasa que no era la de hoy.
        /// Este saldo usa el TC ACTUAL, así que la vía es siempre el converter — no hay aquí monto
        /// guardado en el que apoyarse, a diferencia de los totales históricos.
        let amountsAreApproximate: Bool

        /// Las cuentas que este desglose acabó sumando, ya resueltas (contables, filtro de
        /// selección e `isExcludeMode` aplicados).
        ///
        /// Se expone para que el cálculo de ganancia/pérdida cambiaria recorra **exactamente** las
        /// mismas transacciones que este saldo. El FX P&L es una resta contra ese saldo: si cada
        /// lado resolviera la elegibilidad por su cuenta, el día que cambie una de las reglas el
        /// resultado seguirá pareciendo plausible y estará mal. Compartir el conjunto ya resuelto
        /// es lo que hace que no puedan divergir.
        let eligibleAccountIDs: Set<PersistentIdentifier>
    }

    /// Output del helper `liveBalanceOverride`: valor total + breakdown por
    /// moneda nativa. El breakdown habilita UX educativa sobre composición
    /// multi-currency (sheet "Tu saldo hoy"). Stats consumers ignoran el
    /// breakdown y usan solo `value`.
    /// **No lleva la señal de aproximado a propósito.** Se le añadió y se retiró en la misma
    /// sesión: su único consumidor es `TrendDataProcessor`, que toma de aquí `value` y
    /// `nativeBalances` para el punto «hoy» de la curva, y llevarla hasta la sheet educativa del
    /// saldo exigía atravesar el processor y los dos ViewModels. Un campo que nadie lee parece
    /// cobertura en cualquier auditoría posterior y no lo es. Queda en `Breakdown`, que sí tiene
    /// consumidor. Pendiente: `fx-live-anchor-sheet-and-distribution-kpi-unmarked`.
    struct LiveAnchorInfo: Equatable, Sendable {
        let value: Double
        let nativeBalances: [String: Decimal]
    }

    /// Saldo total "hoy" en moneda preferida. Si `selectedAccountIDs` no
    /// resuelve a ninguna cuenta contable, hace fallback al total agregado
    /// (replica behavior del antiguo `BalanceHelper.displayedBalance`).
    static func liveBalance(
        accounts: [Account],
        transactions: [TransactionItem],
        preferredCurrencyCode: String,
        selectedAccountIDs: Set<PersistentIdentifier> = [],
        isExcludeMode: Bool = false,
        converter: CurrencyConverting = CurrencyConverter.shared
    ) -> Double {
        let breakdown = liveBalanceBreakdown(
            accounts: accounts,
            transactions: transactions,
            preferredCurrencyCode: preferredCurrencyCode,
            selectedAccountIDs: selectedAccountIDs,
            isExcludeMode: isExcludeMode,
            converter: converter
        )
        return (breakdown.convertedTotal as NSDecimalNumber).doubleValue
    }

    /// Versión que retorna el desglose completo. La versión `liveBalance` la
    /// llama internamente.
    ///
    /// El filtro de cuentas es un **conjunto**, no una cuenta: `SessionState`
    /// admite varias (Registros → Filtros hace `insert` sin `removeAll`, y un
    /// presupuesto vuelca su conjunto resuelto), y colapsarlo a un elemento
    /// hacía que el saldo del Panel mostrase UNA cuenta —cuál, no era estable,
    /// porque `Set.first` no lo es— mientras Distribución sumaba todas.
    /// `isExcludeMode` viaja con el conjunto por la misma razón: sin él, "excluir
    /// la cuenta A" enseñaba justamente el saldo de A.
    static func liveBalanceBreakdown(
        accounts: [Account],
        transactions: [TransactionItem],
        preferredCurrencyCode: String,
        selectedAccountIDs: Set<PersistentIdentifier> = [],
        isExcludeMode: Bool = false,
        converter: CurrencyConverting = CurrencyConverter.shared
    ) -> Breakdown {
        // Las cuentas marcadas "excluir de estadísticas" nunca entran, se filtre
        // por cuenta o no.
        let countableIDs = Set(
            accounts.filter { !$0.excludeFromStatistics }
                .map { $0.persistentModelID }
        )

        let eligibleAccountIDs: Set<PersistentIdentifier>
        if selectedAccountIDs.isEmpty {
            eligibleAccountIDs = countableIDs
        } else if isExcludeMode {
            // "Todas menos las seleccionadas". Si se excluyen todas, el saldo es
            // 0 y no el total: aquí NO hay fallback, igual que en Estadísticas.
            eligibleAccountIDs = countableIDs.subtracting(selectedAccountIDs)
        } else {
            let filtered = countableIDs.intersection(selectedAccountIDs)
            // Fallback al total agregado cuando la selección no resuelve a
            // ninguna cuenta contable (p. ej. la única elegida está excluida de
            // estadísticas). Comportamiento heredado, fijado por test.
            eligibleAccountIDs = filtered.isEmpty ? countableIDs : filtered
        }

        var nativeBalances: [String: Decimal] = [:]
        for tx in transactions {
            guard let acc = tx.account,
                eligibleAccountIDs.contains(acc.persistentModelID)
            else { continue }
            nativeBalances[tx.currencyCode, default: 0] += Decimal(tx.amount)
        }

        var convertedTotal: Decimal = 0
        var amountsAreApproximate = false
        for (code, amount) in nativeBalances {
            if code == preferredCurrencyCode {
                convertedTotal += amount
            } else {
                let outcome = converter.convertCheckedWithLatestRate(
                    amount, from: code, to: preferredCurrencyCode
                )
                convertedTotal += outcome.amount
                amountsAreApproximate = amountsAreApproximate || !outcome.quality.isExact
            }
        }

        return Breakdown(
            nativeBalances: nativeBalances,
            convertedTotal: convertedTotal,
            preferredCurrencyCode: preferredCurrencyCode,
            amountsAreApproximate: amountsAreApproximate,
            eligibleAccountIDs: eligibleAccountIDs
        )
    }

    /// Override del último punto del trend chart. Solo retorna no-nil cuando
    /// la métrica es `.balance` y el intervalo cubre "hoy" — en otros casos
    /// el último punto del trend mantiene su valor histórico.
    /// Centraliza el patrón usado por callers de `TrendDataProcessor`.
    static func liveBalanceOverride(
        for metric: TrendType,
        interval: DateInterval,
        accounts: [Account],
        transactions: [TransactionItem],
        preferredCurrencyCode: String,
        converter: CurrencyConverting = CurrencyConverter.shared
    ) -> LiveAnchorInfo? {
        guard metric == .balance, interval.end >= Date.now else { return nil }
        let breakdown = liveBalanceBreakdown(
            accounts: accounts,
            transactions: transactions,
            preferredCurrencyCode: preferredCurrencyCode,
            converter: converter
        )
        return LiveAnchorInfo(
            value: (breakdown.convertedTotal as NSDecimalNumber).doubleValue,
            nativeBalances: breakdown.nativeBalances
        )
    }
}
