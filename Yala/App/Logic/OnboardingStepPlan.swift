//
//  OnboardingStepPlan.swift
//  Yala
//
//  SSOT de la planificación de pasos del onboarding: qué pasos se saltan
//  (por prefill de iCloud restore + modo de uso) y cuál es el primer paso
//  efectivo. Pure-logic, sin SwiftUI — testeable y reusado por `OnboardingView`
//  para reconciliar `currentStep` con `effectiveSteps` desde el `init` (evita el
//  bug del botón "Siguiente" muerto cuando el primer paso está saltado por prefill).
//

import Foundation

/// Pasos del flujo de onboarding. Movido fuera de `OnboardingView` (era un enum
/// privado anidado) para que la planificación sea pure-logic y testeable.
/// `OnboardingView` lo referencia vía `typealias Step = OnboardingStep`.
enum OnboardingStep: Int, CaseIterable {
    case name = 0
    case purpose = 1       // "¿Qué te gustaría hacer?" (binary)
    case accounts = 2      // "¿Cómo organizas?" (binary) — skip if expensesOnly
    case accountType = 3   // "¿Cuál es tu primera cuenta?" — skip if not fullControl
    case currencyName = 4
    case balance = 5       // skip if expensesOnly
    case categories = 6
    case confirmation = 7  // Resumen + privacidad (último paso)

    /// String estable para telemetría — desacoplado del rawValue Int.
    var trackingName: String {
        switch self {
        case .name:         return "name"
        case .purpose:      return "purpose"
        case .accounts:     return "accounts"
        case .accountType:  return "accountType"
        case .currencyName: return "currencyName"
        case .balance:      return "balance"
        case .categories:   return "categories"
        case .confirmation: return "confirmation"
        }
    }
}

/// Pure-logic de planificación de pasos. SSOT de los skips y del primer paso
/// efectivo, reusada por `OnboardingView` tanto para `effectiveSteps` como para
/// el valor inicial de `currentStep` en el `init`.
enum OnboardingStepPlan {

    /// Conjunto de pasos a saltar combinando el prefill de iCloud (rama B del
    /// Welcome Restore) con el modo de uso elegido por el usuario.
    /// `.purpose` y `.confirmation` nunca se saltan (tracking + resumen final).
    ///
    /// - Parameter isSecondarySession: `SecondarySessionStore.isActive()` — la visita está usando la app
    ///   en el móvil de otra persona. Salta `.categories` porque el seed **no puede correr** en ese
    ///   estado: `seedCategoriesIfNeeded` retorna en su primera línea con el cinturón M1, así que el paso
    ///   preguntaba «¿quieres estas categorías?», la visita decía que sí y el store quedaba vacío.
    ///   Ofrecer lo que no se va a hacer es exactamente el tipo de detalle que le hace creer que la app
    ///   está rota. Lleva `= false` como `groupsOnly` —y a diferencia de `restoreInProgress` en
    ///   `GroupsOrganizerGateLogic.decide`, que lo prohíbe— porque aquí el término solo AÑADE un skip:
    ///   un call-site que lo olvide se comporta como antes en vez de heredar un veredicto invertido.
    static func skippedSteps(
        prefilledUserName: String?,
        prefilledAccountsCount: Int,
        prefilledCurrencyCode: String?,
        prefilledCategoriesCount: Int,
        hasPrefill: Bool,
        expensesOnly: Bool,
        dayToDay: Bool,
        groupsOnly: Bool = false,
        isSecondarySession: Bool = false
    ) -> Set<OnboardingStep> {
        var skip: Set<OnboardingStep> = []

        // Sesión secundaria: el seed no corre en visita, así que el paso no se enseña. Va FUERA de la
        // cadena de modos de uso —y antes que ella— porque no es un modo: es un estado del dispositivo
        // que se combina con cualquiera de los tres.
        if isSecondarySession {
            skip.insert(.categories)
        }

        // Skips por modo de uso (elección única del usuario en `.purpose`).
        if groupsOnly {
            // "Solo grupos": sin cuentas ni balance personales, y sin el paso de
            // personalización de categorías (se siembran en silencio para tener
            // subcategorías disponibles en los gastos de grupo). `.currencyName`
            // se conserva (adaptado a solo-moneda) y `.name`/`.purpose` también.
            skip.formUnion([.accounts, .accountType, .balance, .categories])
        } else if expensesOnly {
            skip.formUnion([.accounts, .accountType, .balance])
        } else if dayToDay {
            skip.insert(.accountType)
        }

        // Skips por datos ya presentes en iCloud — no volvemos a preguntarlos.
        if hasPrefill {
            if prefilledUserName != nil { skip.insert(.name) }
            if prefilledAccountsCount > 0 {
                skip.formUnion([.accounts, .accountType, .balance])
            }
            if prefilledCurrencyCode != nil { skip.insert(.currencyName) }
            if prefilledCategoriesCount > 0 { skip.insert(.categories) }
        }

        return skip
    }

    /// Pasos visibles, en orden, tras aplicar `skipped`.
    static func effectiveSteps(skipping skipped: Set<OnboardingStep>) -> [OnboardingStep] {
        OnboardingStep.allCases.filter { !skipped.contains($0) }
    }

    /// Primer paso efectivo — el valor inicial correcto de `currentStep`.
    /// Cae a `.name` defensivamente si todo estuviera saltado (no ocurre:
    /// `.purpose`/`.confirmation` siempre visibles).
    static func firstStep(skipping skipped: Set<OnboardingStep>) -> OnboardingStep {
        effectiveSteps(skipping: skipped).first ?? .name
    }
}
