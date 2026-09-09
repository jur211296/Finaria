//
//  AccountCurrencyMigrationService.swift
//  Yala
//
//  Reexpresa el histórico de una cuenta cuando cambia su divisa.
//  Ticket `changing-an-account-currency-orphans-its-whole-history`.
//

import Foundation
import SwiftData

/// Convierte los movimientos de UNA cuenta a la divisa nueva de esa cuenta.
///
/// **Es el primer sitio del repo que reexpresa el `amount` de transacciones ya persistidas**, y la
/// distinción importa: `CurrencyChangeService` (cambio de divisa PREFERIDA) barre el corpus entero
/// pero escribe solo las cuatro derivadas —`amountInPreferredCurrency`, `exchangeRate`,
/// `preferredCurrencyCode`, `isExchangeRateProvisional`—, que un reparador puede volver a calcular.
/// Aquí se toca la columna cruda, que **no tiene reparador**: es el dato de origen. Por eso el
/// llamador pide confirmación explícita antes y por eso las tasas se refrescan ANTES de convertir.
///
/// Qué filas llegan aquí lo decide `AccountCurrencyChangeLogic`: las que manda otra entidad
/// —transferencias, gastos de grupo, liquidaciones— no entran nunca, porque su conversión no se
/// sostendría. Este servicio no vuelve a comprobarlo: recibe la lista ya filtrada.
@MainActor
enum AccountCurrencyMigrationService {

    /// Qué se hizo, para poder afirmarlo en un test y contarlo en el log.
    struct Outcome: Equatable, Sendable {
        /// Filas cuyo importe se reexpresó.
        let convertedCount: Int
        /// De esas, cuántas salieron con una tasa que no era la exacta de su día (arrastrada de un
        /// día anterior o de la tabla estática). No es un fallo —el número sigue siendo del orden
        /// correcto— pero es lo que distingue «convertido con el dato bueno» de «convertido con lo
        /// que había», y sin contarlo no hay forma de saber cuál de los dos pasó.
        let approximateCount: Int

        static let empty = Outcome(convertedCount: 0, approximateCount: 0)
    }

    // MARK: - Tasas primero

    /// Trae las tasas que la conversión va a necesitar, **antes** de tocar ningún importe.
    ///
    /// **El orden no es cosmético**: es la lección de `fx-partial-rate-rows-silent-1to1`, que
    /// `CurrencySettingsView` ya paga por su lado. Convertir primero y refrescar después deja los
    /// importes escritos con lo que hubiera —en el caso normal, `1.0`, porque el preload histórico
    /// solo cubre las divisas que el usuario ya usaba— y **no se recupera solo**: repoblar
    /// `ExchangeRate` después no vuelve a convertir nada.
    ///
    /// Se nombran las dos divisas (`needing:`) en vez de pedir la fila a secas: una fila de tasas que
    /// existe pero no trae la divisa pedida es indistinguible de una completa si solo se pregunta por
    /// la fila, y ese era justamente el cuarto estado que `RateQuality` existe para separar.
    ///
    /// **Por fechas SUELTAS y no por intervalo, y la diferencia es de dos órdenes de magnitud.**
    /// `ensureRates(for:needing:)` recorre el rango día a día, así que un histórico de dos años con
    /// cuarenta movimientos pediría ~730 días para necesitar cuarenta. `ExchangeRateService` ya avisa
    /// de esto en el docblock de `uncoveredDates` —«su cola son transacciones concretas, no un
    /// intervalo»— y expone la versión buena; usar la del rango habría sido repetir el error que el
    /// reparador de arranque ya pagó.
    /// - Returns: `true` si al terminar **todas** las fechas tienen cubiertas las divisas que hacen
    ///   falta. `false` significa «no conviertas»: es la única señal que separa una conversión con el
    ///   dato bueno de una con lo que hubiera, y en la columna cruda esa diferencia no se puede
    ///   deshacer después.
    ///
    /// Las divisas se toman de las FILAS, no solo del par vieja→nueva. Una cuenta que ya venía
    /// desemparejada puede tener filas en una tercera divisa —caso que `convertHistory` soporta a
    /// propósito— y pedir cobertura solo del par daría por cubierta una fecha que a esa tercera le
    /// falta.
    static func prepareRates(
        rows: [TransactionItem],
        to newCurrencyCode: String,
        context: ModelContext
    ) async -> Bool {
        guard !rows.isEmpty else { return true }

        let missing = missingRateDates(rows: rows, to: newCurrencyCode, context: context)
        if missing.isEmpty { return true }

        _ = await ExchangeRateService.shared.fetchRates(for: missing, context: context)
        // `fetchRates` persiste filas nuevas pero **no** postea la notificación que invalida la caché
        // en memoria de `convertWithLatestRate` (solo lo hacen `forceUpdateToday` y
        // `forceRefreshRates`). Sin esto, lo que la app pinta a «tasa de hoy» —presupuestos, saldo
        // vivo— seguiría leyendo la tasa anterior justo después de que este flujo la trajera.
        NotificationCenter.default.post(name: .yalaExchangeRatesUpdated, object: nil)

        // **Se vuelve a preguntar en vez de fiarse del `Bool` de `fetchRates`.** Ese booleano dice si
        // las peticiones salieron bien, no si el proveedor trajo las divisas pedidas: los dos fallos
        // llevan al mismo sitio —convertir con la tabla estática— pero solo uno se ve en el `catch`.
        // La pregunta que de verdad decide es la misma que decide la calidad de la conversión.
        return missingRateDates(rows: rows, to: newCurrencyCode, context: context).isEmpty
    }

    /// Las fechas a las que les falta alguna de las divisas en juego. **No toca la red.**
    ///
    /// Está separada de `prepareRates` para que la DECISIÓN («¿se puede convertir con el dato bueno?»)
    /// se pueda fijar con un test que no dependa de que el simulador tenga salida — aquí
    /// `ExchangeRateService` cae por AppAttest en todos los arranques, así que un test del camino de
    /// fallo a través del fetch mediría el timeout de la red y no el guard.
    ///
    /// Las divisas se toman de las FILAS, no solo del par vieja→nueva. Una cuenta que ya venía
    /// desemparejada puede tener filas en una tercera divisa —caso que `convertHistory` soporta a
    /// propósito— y pedir cobertura solo del par daría por cubierta una fecha que a esa tercera le
    /// falta.
    static func missingRateDates(
        rows: [TransactionItem],
        to newCurrencyCode: String,
        context: ModelContext
    ) -> [Date] {
        guard !rows.isEmpty else { return [] }

        var needed: Set<String> = [normalizeCurrencyCode(newCurrencyCode)]
        for row in rows { needed.insert(normalizeCurrencyCode(row.currencyCode)) }

        // Hoy entra siempre, aunque el histórico acabe antes: es la tasa con la que el resto de la
        // app pinta el saldo vivo, y dejarla fuera haría que la cuenta recién convertida se leyera
        // con una tasa más vieja que la que acaba de sellar cada fila.
        let wanted = Set(rows.map(\.date)).union([Date.now])
        return ExchangeRateService.shared.uncoveredDates(
            among: wanted, needing: needed, context: context)
    }

    // MARK: - Conversión

    /// Reexpresa cada fila a `newCurrencyCode` usando la tasa **de su propia fecha**.
    ///
    /// No hace red: consume lo que `prepareRates` haya dejado en el store. Eso permite fijar el
    /// comportamiento con tests que no dependen de que el simulador tenga salida —aquí
    /// `ExchangeRateService` falla por AppAttest en todos los arranques— y separa el fallo de red del
    /// fallo de cálculo.
    ///
    /// **El origen de cada fila es `tx.currencyCode`, no la divisa de la cuenta.** Son cosas
    /// distintas justo en el caso que importa: si la cuenta ya venía desemparejada de antes, cada
    /// fila se convierte desde la divisa en la que de verdad está estampada, no desde la que la
    /// cuenta dice.
    ///
    /// No llama a `context.save()`: quien orquesta el guardado del formulario decide cuándo, y así la
    /// conversión y el resto de propiedades de la cuenta entran en la misma transacción.
    @discardableResult
    static func convertHistory(
        rows: [TransactionItem],
        to newCurrencyCode: String,
        context: ModelContext
    ) -> Outcome {
        let target = normalizeCurrencyCode(newCurrencyCode)
        var converted = 0
        var approximate = 0

        for row in rows {
            let source = normalizeCurrencyCode(row.currencyCode)
            // Misma divisa: no hay nada que reexpresar. Se salta ANTES de contar, porque una fila que
            // ya estaba en la divisa destino no es una fila convertida — decir que sí inflaría el
            // número que el usuario acaba de confirmar en pantalla.
            guard source != target else { continue }

            // `CurrencyConverter` concreto y no el protocolo `CurrencyConverting`: la variante que
            // recibe `ModelContext` solo existe en la clase. La del protocolo cae al `modelContext`
            // interno del converter, que en un test recién montado está vacío — y entonces convierte
            // por la tabla estática sin que nada lo diga.
            let outcome = CurrencyConverter.shared.convertChecked(
                Decimal(row.amount),
                from: source,
                to: target,
                on: row.date,
                context: context
            )

            let rate = ratio(of: outcome.amount, over: row.amount)

            row.amount = (outcome.amount as NSDecimalNumber).doubleValue
            row.currencyCode = target
            reexpressLocalSplit(of: row, by: rate)
            // Las derivadas se recalculan desde el importe YA reexpresado: leerlas antes las dejaría
            // describiendo el importe viejo, que es la forma exacta del bug que este ticket cierra,
            // solo que una columna más abajo.
            row.recalculatePreferredCurrency(context: context)

            converted += 1
            if !outcome.quality.isExact { approximate += 1 }
        }

        #if DEBUG
        print("AccountCurrencyMigrationService: reexpresadas \(converted) filas a \(target) (\(approximate) con tasa aproximada)")
        #endif

        return Outcome(convertedCount: converted, approximateCount: approximate)
    }

    // MARK: - El split LOCAL viaja con el importe

    /// La proporción que aplicó la conversión, para reusarla en los campos que no pasan por el
    /// converter. Con importe cero no hay proporción derivable y se devuelve `nil`: multiplicar por
    /// una tasa inventada sería peor que dejar el campo como está.
    private static func ratio(of converted: Decimal, over original: Double) -> Double? {
        guard abs(original) > 0.0001 else { return nil }
        return (converted as NSDecimalNumber).doubleValue / original
    }

    /// Reexpresa los campos del divisor **local** (la calculadora de «dividir entre N»), que no tiene
    /// nada que ver con los grupos.
    ///
    /// **Por qué hay que tocarlos y por qué no bloquean la fila.** Una transacción con split local no
    /// lleva `splitExpenseID` ni `splitSettlementID`, así que no la manda ninguna otra entidad y se
    /// puede convertir sin problema — pero `splitTotalAmount` (y `splitMyValue` cuando el tipo es
    /// `exact`) son DINERO en la divisa vieja. Dejarlos sin tocar hace que al reabrir la transacción
    /// la calculadora enseñe «Total 400 / entre 4 = 100» sobre un importe que ya vale 25, y que la
    /// exportación escriba ese 400 con el símbolo nuevo.
    ///
    /// `splitDivisor` y el `splitMyValue` de los demás tipos NO se tocan: son personas, partes o un
    /// porcentaje. Multiplicarlos por un tipo de cambio no significa nada.
    private static func reexpressLocalSplit(of row: TransactionItem, by rate: Double?) {
        guard let rate else { return }
        if let total = row.splitTotalAmount { row.splitTotalAmount = total * rate }
        if row.splitType == "exact", let mine = row.splitMyValue {
            row.splitMyValue = mine * rate
        }
    }
}
