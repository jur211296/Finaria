//
//  ApproximateMarkWiringTests.swift
//  YalaTests
//
//  Que la señal de «aproximado» llegue de verdad a la PANTALLA.
//  Ticket `fx-presentation-still-shows-1to1`.
//
//  **Por qué hace falta este archivo, dicho sin rodeos.** Toda la cañería —converter, calculadores,
//  ViewModels— está cubierta por tests de comportamiento, y aun así se puede revertir el `isEstimate:`
//  de los cuatro `AmountText` que pintan los totales y **la suite entera sigue en verde**. Eso es
//  exactamente el bug del ticket: el número vuelve a presentarse como exacto. Un `AmountText` es una
//  `View` y afirmar su render pide un XCUITest con una cuenta multimoneda y una fila de tasas
//  incompleta — el más caro de montar de todo el ticket.
//
//  El sustituto es fijar el CABLEADO leyendo el fuente, que es el idioma que este repo ya usa para
//  el mismo compromiso (`PreferredCurrencyChangeOrderTests`, `ExchangeRateMergeWiringTests`). Es más
//  débil que un test de comportamiento —fija el texto, no el resultado— y se elige a conciencia: sin
//  él, quitar la marca de una pantalla no lo nota nadie.
//

import Foundation
import Testing

@testable import Yala

@Suite("Cableado de la marca de aproximado (source-scan)")
struct ApproximateMarkWiringTests {

    private static func source(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
    }

    /// El número grande del Panel, en sus dos modos. El de Solo Gastos lleva **solo** el lado del
    /// gasto: es lo que impide que un ingreso antiguo mal convertido marque un número que no lo
    /// incluye.
    @Test("El hero del Panel pasa la marca, y el lado correcto en cada modo")
    func panelHeroPassesTheMark() throws {
        let src = try Self.source("Yala/App/Views/Panel/HeroMonthView.swift")

        #expect(src.contains("isEstimate: periodSummary.expenseApproximate"), """
            El hero en modo Solo Gastos pinta `periodSummary.expense`: su marca tiene que ser la del
            gasto, no la del período entero.
            """)
        #expect(src.contains("isEstimate: periodSummary.amountsAreApproximate"), """
            El hero normal pinta `available`, que agrega los dos lados.
            """)
    }

    /// VoiceOver tiene que oír lo mismo que se ve. La marca es información, y dejarla solo en el
    /// glifo la esconde justo de quien no puede verlo.
    @Test("La etiqueta de accesibilidad del Panel también lleva la marca")
    func panelAccessibilityLabelCarriesTheMark() throws {
        let src = try Self.source("Yala/App/Views/Panel/HeroMonthView.swift")
        let label = try #require(src.range(of: "private var heroAccessibilityLabel"))
        let scope = String(src[label.lowerBound...].prefix(700))

        #expect(scope.contains("isEstimate:"), """
            El monto de la etiqueta se formatea sin `isEstimate:`, así que VoiceOver lee como exacto
            el mismo número que en pantalla lleva el «≈».
            """)
    }

    /// El saldo del panorama es el caso más puro: se convierte al TC de HOY, sin ningún monto
    /// guardado en el que apoyarse. Sus tres composiciones del importe —resumen, resumen atribuido
    /// y el monto con jerarquía— tienen que llevar la marca, o dos de ellas contradicen a la tercera
    /// en la misma pantalla.
    @Test("El saldo del panorama pasa la marca en sus tres composiciones")
    func panoramaBalancePassesTheMark() throws {
        let src = try Self.source("Yala/App/Views/Panel/Sections/PanelPanoramaSection.swift")
        let ocurrencias = src.components(separatedBy: "isEstimate: viewModel.panelTotalBalanceIsApproximate").count - 1

        #expect(ocurrencias == 3, """
            Se esperaban 3 y hay \(ocurrencias). Los tres sitios pintan el MISMO saldo: si uno se
            queda sin marca, la pantalla se contradice a sí misma.
            """)
    }

    /// El hero de Tendencias muestra uno de tres números según la métrica, así que su marca no puede
    /// ser una señal única del período.
    @Test("El hero de Tendencias elige la marca de su métrica")
    func trendsHeroPicksTheMetricMark() throws {
        let src = try Self.source("Yala/App/Views/Statistics/TrendsTabView.swift")

        #expect(src.contains("isEstimate: heroKPIIsApproximate(for: summary)"), """
            Con `summary.amountsAreApproximate` a secas, un gasto mal convertido le pone «≈» al total
            de INGRESOS, donde no hubo ninguna conversión.
            """)
        let fn = try #require(src.range(of: "private func heroKPIIsApproximate"))
        let scope = String(src[fn.lowerBound...].prefix(400))
        #expect(scope.contains("incomeAmountsAreApproximate"))
        #expect(scope.contains("expenseAmountsAreApproximate"))
    }

    @Test("El hero de Estadísticas pasa la marca")
    func insightsHeroPassesTheMark() throws {
        let src = try Self.source("Yala/App/Views/Statistics/InsightsTabView.swift")
        #expect(src.contains("isEstimate: summary.amountsAreApproximate"), """
            Pinta `summary.netBalance`, que agrega los dos lados.
            """)
    }

    /// Y el productor del glifo, que es el eslabón que ningún test de la app ejercitaba: vaciar el
    /// efecto de `isEstimate` en el formateador dejaría toda la suite en verde y la app sin marca.
    @Test("El formateador antepone el símbolo de aproximado")
    func formatterPrependsTheApproximateSymbol() {
        let conMarca = CurrencyFormattingHelper.currency(
            1234.56, decimals: 2, identifier: "S/", forceSign: false, isEstimate: true
        )
        let sinMarca = CurrencyFormattingHelper.currency(
            1234.56, decimals: 2, identifier: "S/", forceSign: false, isEstimate: false
        )

        #expect(conMarca.hasPrefix("≈"), "se esperaba el prefijo «≈» y salió \(conMarca)")
        #expect(!sinMarca.hasPrefix("≈"))
        #expect(conMarca.contains(sinMarca.trimmingCharacters(in: .whitespaces)), """
            La marca ANTEPONE, no reemplaza: el número tiene que seguir siendo el mismo.
            """)
    }
}
