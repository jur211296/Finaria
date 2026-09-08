//
//  CashFlowCalculator.swift
//  Yala
//
//  Created by Yala Refactoring.
//

import Foundation

struct CashFlowData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let income: Double
    let expense: Double
    let net: Double

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.date == rhs.date
            && lhs.income == rhs.income
            && lhs.expense == rhs.expense
            && lhs.net == rhs.net
    }
}

struct CashFlowSummary: Equatable {
    let totalIncome: Double
    let totalExpense: Double
    let netFlow: Double
    let chartData: [CashFlowData]
    let currencyCode: String

    /// Si algún INGRESO agregado aquí salió de una tasa que no era la de su día.
    ///
    /// **Va separado del gasto porque las pantallas no siempre pintan la suma.** El hero de
    /// Tendencias muestra uno de tres números según la métrica elegida (`heroKPIValue`), y el del
    /// Panel en modo Solo Gastos muestra solo el gasto: una única señal OR'd sobre todo el período
    /// le ponía «≈» a un total de ingresos por culpa de un gasto mal convertido, sobre un número en
    /// el que no hubo ninguna conversión.
    ///
    /// Se enciende por dos vías, y hacen falta las dos porque la mayoría de los importes **no pasan
    /// por el converter**: cuando la divisa de destino es la preferida se lee el
    /// `amountInPreferredCurrency` ya guardado, y entonces quien sabe si aquella conversión fue
    /// aproximada es el flag de la propia transacción.
    ///
    /// **No es un OR desde el 2026-09-08**: pide que el importe aproximado PESE sobre su lado. El
    /// criterio es `ApproximateMarkThreshold`, compartido con el hero del Panel.
    let incomeAmountsAreApproximate: Bool

    /// Lo mismo para los GASTOS.
    let expenseAmountsAreApproximate: Bool

    /// Para el número que agrega los dos lados (`netFlow`, el «Disponible» del Panel).
    ///
    /// **No es el OR de los dos lados, y esa era una regresión real** (cazada por la review
    /// adversarial del 2026-09-08 antes de mergear). Con umbrales por lado, un ingreso de 1.000.000
    /// con 49.000 aproximados no marca —4,9 %— y un gasto exacto de 999.000 tampoco; el neto que se
    /// pinta es **1.000**, con una incertidumbre 49 veces mayor que el propio número, y salía sin
    /// «≈». El neto necesita su propio cociente: la incertidumbre de los dos lados **sumada** contra
    /// el número que de verdad se muestra.
    let amountsAreApproximate: Bool
}

struct CashFlowCalculator {

    static func calculateCashFlow(
        transactions: [TransactionItem],
        interval: DateInterval,
        grouping: TrendGrouping,
        currencyCode: String,
        adjustment: GroupBridgeStatsAdjustment = .none,
        converter: CurrencyConverting = CurrencyConverter.shared
    ) -> CashFlowSummary {

        let calendar = Calendar.current
        var groupedData: [Date: (income: Double, expense: Double)] = [:]

        var totalIncome: Double = 0
        var totalExpense: Double = 0
        // Numerador y denominador del umbral, los dos en MAGNITUDES sumadas y NO en netos.
        //
        // `totalIncome`/`totalExpense` no sirven de denominador porque llevan signo: un reembolso
        // los encoge, y con ellos el cociente se dispara o se anula según qué transacción llevara el
        // flag. Y el numerador con signo es peor todavía: dos aproximaciones opuestas se cancelan y
        // el número sale limpio justo cuando menos lo está. Es la conclusión a la que ya llegó
        // `FXPnLLogic` con su `exposedBase`.
        var incomeApproximateMagnitude: Double = 0
        var incomeTotalMagnitude: Double = 0
        var expenseApproximateMagnitude: Double = 0
        var expenseTotalMagnitude: Double = 0

        // 1. Process Transactions and Accumulate
        for tx in transactions {
            // Strict Filter:
            // Must have a category (excludes Transfers)
            // Skip balance adjustments (they affect balance, not cash flow)
            guard let category = tx.category else { continue }
            guard tx.balanceAdjustmentType == nil else { continue }
            // Excluir patas de préstamo derivadas del bridge: son un préstamo, no ingreso/gasto
            // propio — así se mata el "ingreso fantasma" +lent y el neto queda en -myShare.
            guard !adjustment.isSuppressed(tx) else { continue }

            // `adjustment` proyecta un gasto de grupo Caso A a "mi parte" (neto).
            let adjustedNative = adjustment.amount(tx)
            let decimalAmt = Decimal(abs(adjustedNative))

            // Convert using the transaction's date for accurate historical rate
            let val: Double
            let isApproximate: Bool
            if tx.preferredCurrencyCode == currencyCode {
                // Use signed amount
                val = adjustment.amountInPreferredCurrency(tx)
                // Aquí no hay conversión que juzgar: el monto se convirtió al guardarse, y lo que
                // sabe si aquella tasa era la del día es el flag de la transacción.
                isApproximate = tx.isExchangeRateProvisional
            } else {
                let outcome = converter.convertChecked(
                    decimalAmt,
                    from: tx.currencyCode,
                    to: currencyCode,
                    on: tx.date
                )
                isApproximate = !outcome.quality.isExact
                // Restore sign from the ADJUSTED amount (paridad con la rama preferida).
                let magnitude = NSDecimalNumber(decimal: outcome.amount).doubleValue
                val = (adjustedNative < 0) ? -magnitude : magnitude
            }

            let isIncome = category.isIncome
            let magnitude = abs(val)
            if isIncome {
                incomeTotalMagnitude += magnitude
                if isApproximate { incomeApproximateMagnitude += magnitude }
            } else {
                expenseTotalMagnitude += magnitude
                if isApproximate { expenseApproximateMagnitude += magnitude }
            }

            // Date Grouping key
            let dateKey = grouping.dateKey(for: tx.date, calendar: calendar)

            // Accumulate in Group
            var current = groupedData[dateKey] ?? (0.0, 0.0)
            if isIncome {
                current.income += val
                totalIncome += val
            } else {
                // Expenses are negative signed values.
                // We want positive magnitude for the "Expense" bar/total.
                // Subtracting a negative value adds to the magnitude.
                // Subtracting a positive value (refund) reduces the magnitude.
                current.expense -= val
                totalExpense -= val
            }
            groupedData[dateKey] = current
        }

        // 2. Generate Chart Data (filling gaps)
        var chartData: [CashFlowData] = []
        var currentDate = interval.start

        let component = grouping.calendarComponent

        while currentDate < interval.end {
            let keyDate = grouping.dateKey(for: currentDate, calendar: calendar)

            let values = groupedData[keyDate] ?? (0.0, 0.0)
            let net = values.income - values.expense

            chartData.append(
                CashFlowData(
                    date: keyDate,
                    income: values.income,
                    expense: values.expense,
                    net: net
                ))

            // Increment date
            guard let next = calendar.date(byAdding: component, value: 1, to: currentDate) else {
                break
            }
            currentDate = next
            // Safety break if loop goes infinite (e.g. component issue)
            if currentDate <= keyDate { break }
        }

        let netFlow = totalIncome - totalExpense

        return CashFlowSummary(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            netFlow: netFlow,
            chartData: chartData,
            currencyCode: currencyCode,
            incomeAmountsAreApproximate: ApproximateMarkThreshold.marks(
                approximate: incomeApproximateMagnitude, total: incomeTotalMagnitude
            ),
            expenseAmountsAreApproximate: ApproximateMarkThreshold.marks(
                approximate: expenseApproximateMagnitude, total: expenseTotalMagnitude
            ),
            // El neto: incertidumbre de los DOS lados sumada, contra el número que se muestra.
            amountsAreApproximate: ApproximateMarkThreshold.marks(
                approximate: incomeApproximateMagnitude + expenseApproximateMagnitude,
                total: netFlow
            )
        )
    }
}
