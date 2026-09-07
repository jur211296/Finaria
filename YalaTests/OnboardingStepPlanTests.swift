//
//  OnboardingStepPlanTests.swift
//  YalaTests
//
//  Planificación de pasos del onboarding (skip set + primer paso efectivo).
//  Reproduce el bug del botón "Siguiente" muerto: con nombre ya en iCloud,
//  `.name` se salta y el primer paso debe ser `.purpose` — no `.name`, que
//  quedaría fuera de `effectiveSteps` dejando a `advance()` sin siguiente paso.
//  Pure-logic, sin contexto ni singletons.
//

import Foundation
import Testing

@testable import Yala

struct OnboardingStepPlanTests {

    // MARK: - firstStep (corazón del fix del síntoma 3)

    @Test func firstStep_noPrefill_isName() {
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: false, dayToDay: false
        )
        #expect(OnboardingStepPlan.firstStep(skipping: skip) == .name)
    }

    @Test func firstStep_prefillWithUserName_isPurpose() {
        // Caso Pia: iCloud trae el nombre → `.name` saltado → primer paso `.purpose`.
        // Sin el fix, currentStep arrancaría en `.name` (fuera de effectiveSteps)
        // y el botón "Siguiente" quedaría muerto.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: "Pia", prefilledAccountsCount: 0,
            prefilledCurrencyCode: "PEN", prefilledCategoriesCount: 5,
            hasPrefill: true, expensesOnly: false, dayToDay: false
        )
        #expect(skip.contains(.name))
        #expect(OnboardingStepPlan.firstStep(skipping: skip) == .purpose)
    }

    @Test func firstStep_prefillAccountsButNoName_isName() {
        // Prefill con cuentas pero sin nombre → `.name` NO se salta → primer paso `.name`.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 3,
            prefilledCurrencyCode: "USD", prefilledCategoriesCount: 0,
            hasPrefill: true, expensesOnly: false, dayToDay: false
        )
        #expect(!skip.contains(.name))
        #expect(OnboardingStepPlan.firstStep(skipping: skip) == .name)
    }

    // MARK: - skippedSteps por prefill

    @Test func skippedSteps_prefillFull_skipsAllPrefillable() {
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: "Pia", prefilledAccountsCount: 2,
            prefilledCurrencyCode: "PEN", prefilledCategoriesCount: 5,
            hasPrefill: true, expensesOnly: false, dayToDay: false
        )
        #expect(skip == [.name, .accounts, .accountType, .balance, .currencyName, .categories])
        // `.purpose` y `.confirmation` nunca se saltan.
        #expect(OnboardingStepPlan.effectiveSteps(skipping: skip) == [.purpose, .confirmation])
    }

    @Test func skippedSteps_hasPrefillFalse_ignoresPrefillValues() {
        // Rama A: aunque lleguen valores, hasPrefill=false → no se aplican.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: "Pia", prefilledAccountsCount: 2,
            prefilledCurrencyCode: "PEN", prefilledCategoriesCount: 5,
            hasPrefill: false, expensesOnly: false, dayToDay: false
        )
        #expect(skip.isEmpty)
        #expect(OnboardingStepPlan.firstStep(skipping: skip) == .name)
    }

    // MARK: - skippedSteps por modo de uso

    @Test func skippedSteps_expensesOnly_skipsAccountSteps() {
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: true, dayToDay: false
        )
        #expect(skip == [.accounts, .accountType, .balance])
    }

    @Test func skippedSteps_dayToDay_skipsAccountType() {
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: false, dayToDay: true
        )
        #expect(skip == [.accountType])
    }

    @Test func skippedSteps_combinesPrefillAndUsageMode() {
        // expensesOnly + prefill con nombre → unión de ambos.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: "Pia", prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: true, expensesOnly: true, dayToDay: false
        )
        #expect(skip == [.name, .accounts, .accountType, .balance])
    }

    // MARK: - skippedSteps: modo "Solo grupos"

    @Test func skippedSteps_groupsOnly_skipsAccountsBalanceAndCategories() {
        // Solo grupos: sin cuentas/tipo/saldo Y sin el paso de categorías (se
        // siembran en silencio). Conserva `.name`, `.purpose`, `.currencyName`,
        // `.confirmation`.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: false, dayToDay: false,
            groupsOnly: true
        )
        #expect(skip == [.accounts, .accountType, .balance, .categories])
        #expect(OnboardingStepPlan.effectiveSteps(skipping: skip) == [
            .name, .purpose, .currencyName, .confirmation
        ])
    }

    @Test func skippedSteps_groupsOnly_defaultsToFalse_unchanged() {
        // El parámetro nuevo tiene default false → no altera el comportamiento
        // de los callsites que no lo pasan (expensesOnly sigue igual).
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: true, dayToDay: false
        )
        #expect(skip == [.accounts, .accountType, .balance])
    }

    @Test func skippedSteps_groupsOnly_combinesWithPrefillName() {
        // Solo grupos + prefill con nombre → también salta `.name`.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: "Pia", prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: true, expensesOnly: false, dayToDay: false,
            groupsOnly: true
        )
        #expect(skip == [.name, .accounts, .accountType, .balance, .categories])
        #expect(OnboardingStepPlan.firstStep(skipping: skip) == .purpose)
    }

    @Test func skippedSteps_groupsOnly_takesPrecedenceOverExpensesOnly() {
        // groupsOnly y expensesOnly son mutuamente excluyentes en la UI, pero si
        // ambos llegaran true, groupsOnly gana (rama primero) y añade `.categories`.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: true, dayToDay: false,
            groupsOnly: true
        )
        #expect(skip == [.accounts, .accountType, .balance, .categories])
    }

    // MARK: - skippedSteps: sesión secundaria (la visita en el móvil de otra persona)

    @Test func skippedSteps_secondarySession_skipsCategories() {
        // El seed no puede correr en visita (cinturón M1 en `seedCategoriesIfNeeded`), así que el paso
        // que lo ofrece no se enseña. Todo lo demás del onboarding sigue en pie: la visita da su
        // nombre, elige propósito, crea su cuenta y pone su saldo.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: false, dayToDay: false,
            isSecondarySession: true
        )
        #expect(skip == [.categories])
        #expect(OnboardingStepPlan.effectiveSteps(skipping: skip) == [
            .name, .purpose, .accounts, .accountType, .currencyName, .balance, .confirmation
        ])
    }

    @Test func skippedSteps_secondarySession_defaultsToFalse_unchanged() {
        // Molde de `skippedSteps_groupsOnly_defaultsToFalse_unchanged`: el parámetro nuevo con default
        // `false` no altera a los callsites que no lo pasan. Es lo que hace seguro tener default aquí
        // — el término solo AÑADE un skip, nunca invierte un veredicto.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: false, dayToDay: true
        )
        #expect(skip == [.accountType])
        #expect(!skip.contains(.categories))
    }

    @Test func skippedSteps_secondarySession_combinesWithUsageModeAndPrefill() {
        // No es un modo de uso: es un estado del dispositivo que se SUMA a cualquiera de ellos. Con
        // expensesOnly (que ya salta cuentas/tipo/saldo) el skip debe contener las cuatro cosas.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: "Pia", prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: true, expensesOnly: true, dayToDay: false,
            isSecondarySession: true
        )
        #expect(skip == [.name, .accounts, .accountType, .balance, .categories])
        #expect(OnboardingStepPlan.firstStep(skipping: skip) == .purpose)
    }

    @Test func skippedSteps_secondarySession_withGroupsOnly_isIdempotent() {
        // `groupsOnly` ya salta `.categories` por su cuenta. Sumar la visita no puede añadirlo dos veces
        // ni quitar nada: el skip es un Set y los dos términos coinciden en ese paso.
        let skip = OnboardingStepPlan.skippedSteps(
            prefilledUserName: nil, prefilledAccountsCount: 0,
            prefilledCurrencyCode: nil, prefilledCategoriesCount: 0,
            hasPrefill: false, expensesOnly: false, dayToDay: false,
            groupsOnly: true, isSecondarySession: true
        )
        #expect(skip == [.accounts, .accountType, .balance, .categories])
    }

    // MARK: - effectiveSteps orden

    @Test func effectiveSteps_noSkip_isFullOrderedList() {
        #expect(OnboardingStepPlan.effectiveSteps(skipping: []) == [
            .name, .purpose, .accounts, .accountType, .currencyName, .balance, .categories, .confirmation
        ])
    }
}
