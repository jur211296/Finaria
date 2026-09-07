//
//  ApproximateAmountMarkTests.swift
//  YalaTests
//
//  La marca «≈» de los totales: cuándo se enciende y cuándo NO.
//  Ticket `fx-presentation-still-shows-1to1`.
//
//  **Las dos vías, y por qué hacen falta las dos.** Un total de estas pantallas casi nunca pasa por
//  el converter: cuando la divisa de destino es la preferida —el caso normal— se suma el
//  `amountInPreferredCurrency` que ya está guardado, convertido el día que se creó la transacción.
//  Así que «este número es aproximado» se sabe por dos caminos distintos según la rama:
//
//    · rama guardada  → el flag `isExchangeRateProvisional` de cada transacción
//    · rama convertida → la `RateQuality` que devuelve el converter
//
//  Cubrir solo una deja pantallas enteras sin marca. El control positivo de cada test es su gemelo
//  «todo exacto ⇒ sin marca»: sin él, marcar SIEMPRE pasaría la mitad de esta suite y le pondría el
//  «≈» a todos los usuarios, que es tan mentira como no ponerlo nunca.
//

import Foundation
import SwiftData
import Testing

@testable import Yala

@MainActor
@Suite("Marca de aproximado en los totales")
struct ApproximateAmountMarkTests {

    private let calendar = Calendar.current

    private func makeAccount() -> Account {
        Account(name: "Main", currencyCode: "USD", colorHex: "#6366F1", iconName: "creditcard", type: "bank")
    }

    private func makeCategory(isIncome: Bool = false) -> YalaCategory {
        YalaCategory(name: isIncome ? "Salary" : "Food", colorHex: "#FF0000", isIncome: isIncome)
    }

    /// Transacción ya convertida y guardada, con el flag en el estado que pida el test.
    private func makeStoredTx(
        amount: Double,
        date: Date,
        account: Account,
        category: YalaCategory,
        provisional: Bool
    ) -> TransactionItem {
        let tx = TransactionItem(
            date: date,
            amount: amount,
            currencyCode: "USD",
            note: "",
            category: category,
            account: account,
            tags: [],
            amountInPreferredCurrency: amount
        )
        tx.preferredCurrencyCode = "USD"
        tx.isExchangeRateProvisional = provisional
        return tx
    }

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
    }

    private func monthInterval(_ y: Int, _ m: Int) -> DateInterval {
        let start = day(y, m, 1)
        let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    // MARK: - Rama guardada · el flag de la transacción

    @Test("Una transacción con tasa provisional marca el total del período")
    func cashFlow_storedProvisionalTx_marksTheTotal() {
        let account = makeAccount()
        let category = makeCategory()
        let interval = monthInterval(2026, 4)
        let tx = makeStoredTx(
            amount: -100, date: day(2026, 4, 10),
            account: account, category: category, provisional: true
        )

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: [tx], interval: interval, grouping: .day,
            currencyCode: "USD", converter: MockCurrencyConverter()
        )

        #expect(summary.amountsAreApproximate, """
            El monto se guardó con una tasa que no era la de su día. El total lo hereda: se sigue
            mostrando, pero con la marca de aproximado.
            """)
    }

    @Test("Con todas las tasas exactas no hay marca")
    func cashFlow_allExact_hasNoMark() {
        let account = makeAccount()
        let category = makeCategory()
        let interval = monthInterval(2026, 4)
        let txs = [
            makeStoredTx(amount: -100, date: day(2026, 4, 10), account: account, category: category, provisional: false),
            makeStoredTx(amount: -50, date: day(2026, 4, 12), account: account, category: category, provisional: false),
        ]

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: txs, interval: interval, grouping: .day,
            currencyCode: "USD", converter: MockCurrencyConverter()
        )

        #expect(!summary.amountsAreApproximate)
    }

    /// **La transacción aproximada va la PRIMERA a propósito.** Puesta la última, este test pasa
    /// igual con `acumulador = tx.isExchangeRateProvisional` —sin el `||`— porque el último valor
    /// escrito sería `true`: mediría el orden del array, no la acumulación. Con ella delante, las
    /// cinco exactas que vienen detrás apagarían la señal y el test se pone rojo.
    @Test("Una sola transacción aproximada entre muchas exactas basta para marcar")
    func cashFlow_oneProvisionalAmongMany_marksTheTotal() {
        let account = makeAccount()
        let category = makeCategory()
        let interval = monthInterval(2026, 4)
        var txs = [makeStoredTx(
            amount: -10, date: day(2026, 4, 1),
            account: account, category: category, provisional: true
        )]
        txs += (2...6).map {
            makeStoredTx(amount: -10, date: day(2026, 4, $0), account: account, category: category, provisional: false)
        }

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: txs, interval: interval, grouping: .day,
            currencyCode: "USD", converter: MockCurrencyConverter()
        )

        #expect(summary.expenseAmountsAreApproximate, """
            El total suma las seis, así que un solo sumando aproximado lo vuelve aproximado. La marca
            es una propiedad del número que se muestra, no de la mayoría de sus partes.
            """)
    }

    /// El gemelo del anterior para el bucket del hero, por el mismo motivo: allí el `||` vive en
    /// `HeroBucketsCalculator` y ningún test lo cargaba con más de una transacción.
    @Test("El hero acumula: la aproximada primera no la apagan las exactas siguientes")
    func heroBuckets_provisionalFirst_staysMarked() {
        let account = makeAccount()
        let category = makeCategory()
        let period = monthInterval(2026, 4)
        var txs = [makeStoredTx(
            amount: -10, date: day(2026, 4, 1),
            account: account, category: category, provisional: true
        )]
        txs += (2...6).map {
            makeStoredTx(amount: -10, date: day(2026, 4, $0), account: account, category: category, provisional: false)
        }

        let buckets = HeroBucketsCalculator.calculate(
            transactions: txs,
            monthInterval: period,
            prevInterval: monthInterval(2026, 3),
            periodInterval: period,
            eligibleAccountIDs: [account.persistentModelID]
        )

        #expect(buckets.periodExpenseApproximate)
    }

    // MARK: - La marca es del lado que se pinta

    /// **El hero de Tendencias muestra UNO de tres números según la métrica**, y el del Panel en
    /// modo Solo Gastos muestra solo el gasto. Con una señal única para todo el período, un gasto
    /// mal convertido le ponía «≈» al total de INGRESOS — un número en el que no hubo ninguna
    /// conversión. Este par fija que cada lado lleva la suya.
    @Test("Un gasto aproximado no marca el total de ingresos")
    func cashFlow_approximateExpense_doesNotMarkIncome() {
        let account = makeAccount()
        let interval = monthInterval(2026, 4)
        let ingreso = makeStoredTx(
            amount: 5000, date: day(2026, 4, 3),
            account: account, category: makeCategory(isIncome: true), provisional: false
        )
        let gasto = makeStoredTx(
            amount: -100, date: day(2026, 4, 5),
            account: account, category: makeCategory(), provisional: true
        )

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: [ingreso, gasto], interval: interval, grouping: .day,
            currencyCode: "USD", converter: MockCurrencyConverter()
        )

        #expect(summary.expenseAmountsAreApproximate, "el gasto sí es aproximado")
        #expect(!summary.incomeAmountsAreApproximate, """
            El total de ingresos no incluye ese gasto. Marcarlo sería decirle al usuario que un
            número exacto es dudoso, que erosiona la marca igual que no ponerla.
            """)
        #expect(summary.amountsAreApproximate, "y el neto, que sí agrega los dos, va marcado")
    }

    @Test("Un ingreso aproximado no marca el total de gastos")
    func cashFlow_approximateIncome_doesNotMarkExpense() {
        let account = makeAccount()
        let interval = monthInterval(2026, 4)
        let ingreso = makeStoredTx(
            amount: 5000, date: day(2026, 4, 3),
            account: account, category: makeCategory(isIncome: true), provisional: true
        )
        let gasto = makeStoredTx(
            amount: -100, date: day(2026, 4, 5),
            account: account, category: makeCategory(), provisional: false
        )

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: [ingreso, gasto], interval: interval, grouping: .day,
            currencyCode: "USD", converter: MockCurrencyConverter()
        )

        #expect(summary.incomeAmountsAreApproximate)
        #expect(!summary.expenseAmountsAreApproximate)
    }

    /// Su gemelo en el Panel: en modo Solo Gastos el número grande es `expense`, y un ingreso
    /// antiguo con tasa aproximada no debe ensuciarlo.
    @Test("En el hero del Panel, un ingreso aproximado no marca el gasto")
    func heroBuckets_approximateIncome_doesNotMarkExpense() {
        let account = makeAccount()
        let period = monthInterval(2026, 4)
        let ingreso = makeStoredTx(
            amount: 5000, date: day(2026, 4, 3),
            account: account, category: makeCategory(isIncome: true), provisional: true
        )
        let gasto = makeStoredTx(
            amount: -100, date: day(2026, 4, 5),
            account: account, category: makeCategory(), provisional: false
        )

        let buckets = HeroBucketsCalculator.calculate(
            transactions: [ingreso, gasto],
            monthInterval: period,
            prevInterval: monthInterval(2026, 3),
            periodInterval: period,
            eligibleAccountIDs: [account.persistentModelID]
        )

        #expect(buckets.periodIncomeApproximate)
        #expect(!buckets.periodExpenseApproximate)
    }

    // MARK: - Rama convertida · la calidad del converter

    @Test("Una conversión en vivo con tasa inexacta marca el total")
    func cashFlow_inexactConversion_marksTheTotal() {
        let account = makeAccount()
        let category = makeCategory()
        let interval = monthInterval(2026, 4)
        // `preferredCurrencyCode` ≠ divisa pedida ⇒ el cálculo NO puede usar el monto guardado y
        // tiene que convertir, que es la rama donde manda la calidad del converter.
        let tx = makeStoredTx(
            amount: -100, date: day(2026, 4, 10),
            account: account, category: category, provisional: false
        )

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: [tx], interval: interval, grouping: .day,
            currencyCode: "PEN",
            converter: MockCurrencyConverter(fixedRate: 3.75, quality: .staticFallback)
        )

        #expect(summary.amountsAreApproximate, """
            La transacción está sellada como exacta, pero el total se pidió en otra divisa y esa
            conversión salió de la tabla estática. La marca tiene que venir del converter aquí.
            """)
    }

    @Test("Conversión en vivo con tasa exacta no marca")
    func cashFlow_exactConversion_hasNoMark() {
        let account = makeAccount()
        let category = makeCategory()
        let interval = monthInterval(2026, 4)
        let tx = makeStoredTx(
            amount: -100, date: day(2026, 4, 10),
            account: account, category: category, provisional: false
        )

        let summary = CashFlowCalculator.calculateCashFlow(
            transactions: [tx], interval: interval, grouping: .day,
            currencyCode: "PEN",
            converter: MockCurrencyConverter(fixedRate: 3.75, quality: .exact)
        )

        #expect(!summary.amountsAreApproximate)
    }

    // MARK: - El hero del Panel

    @Test("El bucket de período del Panel hereda el flag de sus transacciones")
    func heroBuckets_provisionalTxInPeriod_marksThePeriod() {
        let account = makeAccount()
        let category = makeCategory()
        let period = monthInterval(2026, 4)
        let tx = makeStoredTx(
            amount: -100, date: day(2026, 4, 10),
            account: account, category: category, provisional: true
        )

        let buckets = HeroBucketsCalculator.calculate(
            transactions: [tx],
            monthInterval: period,
            prevInterval: monthInterval(2026, 3),
            periodInterval: period,
            eligibleAccountIDs: [account.persistentModelID]
        )

        #expect(buckets.periodExpenseApproximate)
    }

    /// La marca es del bucket que se PINTA. Una transacción aproximada fuera del período elegido no
    /// tiene por qué ensuciar un número que no la incluye — si no, cambiar de período no apagaría
    /// nunca la marca y dejaría de significar nada.
    @Test("Una transacción aproximada FUERA del período no marca")
    func heroBuckets_provisionalTxOutsidePeriod_doesNotMark() {
        let account = makeAccount()
        let category = makeCategory()
        let tx = makeStoredTx(
            amount: -100, date: day(2026, 3, 10),
            account: account, category: category, provisional: true
        )

        let buckets = HeroBucketsCalculator.calculate(
            transactions: [tx],
            monthInterval: monthInterval(2026, 4),
            prevInterval: monthInterval(2026, 3),
            periodInterval: monthInterval(2026, 4),
            eligibleAccountIDs: [account.persistentModelID]
        )

        #expect(!buckets.periodExpenseApproximate)
    }

    // MARK: - El saldo vivo

    /// Este saldo usa el TC de HOY, así que aquí no hay monto guardado en el que apoyarse: la única
    /// fuente de la marca es la calidad que devuelve el converter.
    @Test("El saldo vivo marca cuando la tasa de hoy no es exacta")
    func liveBalance_inexactRate_marksTheTotal() {
        let account = makeAccount()
        let category = makeCategory()
        let tx = makeStoredTx(
            amount: 100, date: day(2026, 4, 10),
            account: account, category: category, provisional: false
        )
        tx.account = account

        let breakdown = LiveBalanceCalculator.liveBalanceBreakdown(
            accounts: [account],
            transactions: [tx],
            preferredCurrencyCode: "PEN",
            converter: MockCurrencyConverter(fixedRate: 3.75, quality: .carriedForward(fromDateKey: "2026-04-09"))
        )

        #expect(breakdown.amountsAreApproximate)
    }

    @Test("El saldo vivo no marca con tasa exacta")
    func liveBalance_exactRate_hasNoMark() {
        let account = makeAccount()
        let category = makeCategory()
        let tx = makeStoredTx(
            amount: 100, date: day(2026, 4, 10),
            account: account, category: category, provisional: false
        )
        tx.account = account

        let breakdown = LiveBalanceCalculator.liveBalanceBreakdown(
            accounts: [account],
            transactions: [tx],
            preferredCurrencyCode: "PEN",
            converter: MockCurrencyConverter(fixedRate: 3.75, quality: .exact)
        )

        #expect(!breakdown.amountsAreApproximate)
    }

    /// Un usuario monomoneda —la inmensa mayoría— no debe ver nunca la marca: con la divisa de
    /// destino igual a la nativa **no se llama al converter**, así que no hay conversión que pueda
    /// ser aproximada. Lo que fija este test es ese cortocircuito, no el comportamiento del
    /// converter (la calidad que declare el doble aquí es inerte, y por eso no se le pone ninguna
    /// llamativa: prometería cubrir algo que no cubre). Sin él, un `return true` descuidado le
    /// pondría «≈» permanente a la pantalla principal de todo el mundo.
    @Test("Monomoneda: no se convierte nada, así que no hay marca")
    func liveBalance_singleCurrency_neverMarks() {
        let account = makeAccount()
        let category = makeCategory()
        let tx = makeStoredTx(
            amount: 100, date: day(2026, 4, 10),
            account: account, category: category, provisional: false
        )
        tx.account = account

        let breakdown = LiveBalanceCalculator.liveBalanceBreakdown(
            accounts: [account],
            transactions: [tx],
            preferredCurrencyCode: "USD",
            converter: MockCurrencyConverter(fixedRate: 3.75)
        )

        #expect(!breakdown.amountsAreApproximate)
    }
}
