//
//  ManualWriteRateQualityTests.swift
//  YalaTests
//
//  Que ninguna escritura a mano de `amountInPreferredCurrency` selle como definitiva una tasa que
//  fue aproximada. Ticket `fx-manual-writes-seal-approximate-as-final`.
//
//  **El bug, en una frase**: `CurrencyConverter.convert` devuelve `Decimal` a secas —tira la
//  calidad— y catorce sitios escribían el monto convertido dejando `isExchangeRateProvisional` en su
//  default `false`. El reparador (`TransactionUpdateService`) solo busca `== true`, así que el
//  número aproximado se quedaba para siempre, viajaba por la nube y alimentaba informes.
//
//  **Por qué hay un barrido de fuente y no solo tests de comportamiento.** Las catorce escrituras
//  viven en cuatro familias, y montar el escenario de cada una cuesta desde un contexto in-memory
//  (barato) hasta una vista SwiftUI con su sheet (imposible en unit). El barrido cubre las catorce a
//  la vez y, sobre todo, cubre **la que se añada mañana**: el modo de fallo de este bug no es que una
//  de ellas se rompa, es que aparezca una nueva sin el flag. Los tests de comportamiento de abajo
//  fijan que la decisión es la CORRECTA; el barrido fija que está PUESTA en todas.
//
//  El barrido lleva control positivo —un fragmento sintético que DEBE detectar— porque un escáner
//  que no encuentra nada y un escáner roto se leen igual.
//

import Foundation
import SwiftData
import Testing

@testable import Yala

@Suite("Ninguna escritura a mano sella una tasa aproximada")
struct ManualWriteRateQualityTests {

    // MARK: - Infraestructura del barrido

    private static func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func source(_ path: String) throws -> String {
        try String(contentsOf: repoRoot().appendingPathComponent(path), encoding: .utf8)
    }

    /// Ficheros EXENTOS del barrido, cada uno con la razón por la que escribir el monto sin decidir
    /// el flag es correcto ahí — y con un centinela que comprueba que esa razón sigue siendo cierta.
    ///
    /// **Se barre `Yala/` ENTERO y se exime nombrando, en vez de enumerar los ficheros vigilados.**
    /// La primera versión de este archivo hacía lo contrario, y el modo de fallo salta a la vista en
    /// cuanto se dice en voz alta: una lista de vigilados no puede detectar **el fichero que aún no
    /// existe**, que es justo lo que este barrido promete cubrir. Con la lista invertida, cualquier
    /// ruta nueva que persista un monto convertido entra vigilada por defecto.
    ///
    /// El centinela es lo que impide que una exención se pudra: no basta con afirmar «éste llama a
    /// `recalculatePreferredCurrency` después», hay que comprobar que lo sigue llamando.
    static let exemptions: [String: (reason: String, sentinel: String)] = [
        "Yala/Services/InitialBalanceService.swift": (
            reason: """
                Pasa placeholders al init y llama `recalculatePreferredCurrency` justo después del \
                `context.insert`, que es quien decide el flag con la calidad real.
                """,
            sentinel: "recalculatePreferredCurrency(context: context)"
        ),
        "Yala/Services/WidgetDataCache.swift": (
            reason: """
                No escribe una transacción: construye `WidgetTransaction`, una `struct Codable` para \
                el widget que COPIA un monto ya calculado y persistido. No hay tasa que evaluar.
                """,
            sentinel: "struct WidgetTransaction: Codable"
        ),
        "Yala/Seed/DevSeedTransactions.swift": (
            reason: """
                Datos sintéticos de desarrollo, con montos inventados que nunca salen de una \
                conversión real. Marcarlos provisionales mandaría el seed entero al reparador.
                """,
            sentinel: "DevSeed"
        )
    ]

    /// Todos los `.swift` bajo `Yala/` que escriben el monto convertido, sea por asignación o por
    /// init. Se descubre recorriendo el árbol: nada que mantener a mano.
    static func filesWritingConvertedAmounts() throws -> [String] {
        let root = repoRoot().appendingPathComponent("Yala")
        guard let walker = FileManager.default.enumerator(atPath: root.path) else { return [] }
        var found: [String] = []
        for case let rel as String in walker where rel.hasSuffix(".swift") {
            let path = "Yala/" + rel
            guard let src = try? source(path) else { continue }
            if tally(src).writes > 0 { found.append(path) }
        }
        return found.sorted()
    }

    /// Cuenta escrituras del monto convertido y decisiones del flag en un fuente.
    ///
    /// **La forma del patrón importa y ya mordió una vez.** Seis de las escrituras están partidas en
    /// dos líneas (`x.amountInPreferredCurrency =\n    (…)`), así que un patrón que exija algo
    /// después del `=` devuelve la mitad y deja creer que no hay nada que arreglar. Por eso el
    /// patrón acepta fin de línea, y por eso el control positivo de abajo incluye una asignación
    /// partida.
    static func tally(_ src: String) -> (writes: Int, decisions: Int) {
        func matches(_ pattern: String) -> Int {
            // `.anchorsMatchLines` NO es decorativo: sin él, `^` ancla al inicio del ARCHIVO y los
            // patrones de init cuentan cero en todas partes. Se descubrió porque el barrido declaró
            // «ninguna escritura» sobre `ChatAssistantViewModel`, cuyo único sitio es un init —el
            // mismo modo de fallo que este archivo persigue, cometido por el propio detector.
            guard let rx = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            else { return -1 }
            let range = NSRange(src.startIndex..., in: src)
            return rx.numberOfMatches(in: src, range: range)
        }
        // Asignaciones (`.foo =`) e inits (`foo:`) cuentan igual: las dos persisten el número.
        let writes =
            matches(#"\.amountInPreferredCurrency[ \t]*=(?![=])"#)
            + matches(#"^[ \t]*amountInPreferredCurrency:"#)
        let decisions =
            matches(#"\.isExchangeRateProvisional[ \t]*=(?![=])"#)
            + matches(#"^[ \t]*isExchangeRateProvisional:"#)
        return (writes, decisions)
    }

    // MARK: - Control positivo

    @Test("El barrido detecta una escritura sin flag (control positivo)")
    func sweepCatchesAnUnflaggedWrite() {
        // Las DOS formas de persistir el monto, en un solo fragmento. Que estén las dos es el punto:
        // la primera versión de este control solo traía la asignación, así que no pudo avisar de que
        // el patrón de init estaba midiendo cero — lo destapó el barrido real, un paso más tarde.
        let bad = """
            tx.exchangeRate = abs(rate)
            tx.amountInPreferredCurrency =
                (amountInPreferred as NSDecimalNumber).doubleValue
            tx.preferredCurrencyCode = preferredCode

            let otra = TransactionItem(
                date: date,
                amount: amount,
                currencyCode: code,
                amountInPreferredCurrency: convertido,
                preferredCurrencyCode: preferido
            )
            """
        let tally = Self.tally(bad)
        #expect(
            tally.writes == 2,
            """
            El patrón no ve una de las dos formas de escribir el monto: la asignación partida en
            dos líneas (seis de las reales la tienen) o el paso por init (cuatro de las reales).
            Cualquiera de las dos cegueras hace inútil el barrido entero: el escáner diría «todo en
            orden» justo sobre el fichero que tiene el bug.
            """
        )
        #expect(
            tally.decisions == 0,
            "el fragmento no decide el flag; si el contador dice que sí, mide otra cosa"
        )
        #expect(
            tally.writes > tally.decisions,
            "y por tanto el barrido debe declararlo insuficiente"
        )
    }

    @Test("El barrido aprueba una escritura que sí decide (control negativo)")
    func sweepAcceptsAFlaggedWrite() {
        let good = """
            tx.exchangeRate = abs(rate)
            tx.amountInPreferredCurrency =
                (amountInPreferred as NSDecimalNumber).doubleValue
            tx.preferredCurrencyCode = preferredCode
            tx.isExchangeRateProvisional = !outcome.quality.isExact
            """
        let tally = Self.tally(good)
        #expect(tally.writes == 1)
        #expect(tally.decisions == 1)
    }

    // MARK: - El barrido

    @Test("Cada escritura del monto convertido decide la provisionalidad")
    func everyWriteDecidesTheFlag() throws {
        let files = try Self.filesWritingConvertedAmounts()
        #expect(
            files.count >= 8,
            "el barrido encontró solo \(files.count) ficheros — o se movió el código, o el patrón dejó de medir"
        )

        for path in files {
            if let exemption = Self.exemptions[path] {
                // Una exención vale mientras su motivo siga siendo cierto, y eso se comprueba.
                #expect(
                    try Self.source(path).contains(exemption.sentinel),
                    """
                    \(path) está exento del barrido porque: \(exemption.reason)
                    Pero su centinela `\(exemption.sentinel)` ya no aparece en el fichero, así que esa \
                    razón dejó de ser verdad. Revisa si ahora necesita decidir el flag, o actualiza el \
                    centinela si solo cambió de nombre.
                    """
                )
                continue
            }

            let tally = Self.tally(try Self.source(path))
            #expect(
                tally.decisions >= tally.writes,
                """
                \(path): \(tally.writes) escrituras del monto convertido y solo \(tally.decisions) \
                decisiones de `isExchangeRateProvisional`.

                Una escritura que no decide el flag lo deja en su default `false` — sellada como \
                definitiva. El reparador (`TransactionUpdateService`) tiene un `#Predicate` que solo \
                busca `== true`, así que no vuelve a mirarla NUNCA: si la tasa era aproximada, el \
                número malo se queda para siempre, viaja por la nube y alimenta los informes.

                Al añadir una escritura nueva, resuelve la conversión con `convertChecked` (no \
                `convert`, que tira la calidad) y escribe \
                `isExchangeRateProvisional = !outcome.quality.isExact`.

                Si este fichero NO persiste una transacción de verdad, añádelo a `exemptions` con su \
                razón y un centinela que la haga comprobable.
                """
            )
        }
    }

    @Test("Ningún sitio que persiste usa el `convert` que tira la calidad")
    func persistingSitesUseCheckedVariants() throws {
        for path in try Self.filesWritingConvertedAmounts() where Self.exemptions[path] == nil {
            let src = try Self.source(path)
            // `convert(` a secas, sin el `Checked`. Se buscan las dos formas con receptor explícito
            // que existen en el repo.
            let offenders = [
                "CurrencyConverter.shared.convert(",
                "CurrencyConverter.shared.convertWithLatestRate(",
                "currencyConverter.convert(",
                "currencyConverter.convertWithLatestRate("
            ].filter { src.contains($0) }

            #expect(
                offenders.isEmpty,
                """
                \(path) llama a \(offenders.joined(separator: ", ")) y además PERSISTE el resultado.

                `convert` devuelve `Decimal` a secas: su llamador no puede distinguir «convertí con \
                la tasa del día» de «bajé a la fila anterior» o «tiré de la tabla estática». Quien \
                solo PINTA un número puede usarlo; quien lo guarda, no.
                """
            )
        }
    }
}
