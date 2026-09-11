//
//  FullModeActivationChooserUITests.swift
//  YalaUITests
//
//  Paso 8 del rediseño de sesiones · «Activar Yala completo» desde una sesión solo-grupos pregunta dónde
//  van a vivir los datos personales ANTES de cualquier onboarding.
//
//  `-uitest-group-invite` deja la app en solo-grupos (`OnboardingMode.groupInvite`) y `-uitest-cloud-chooser`
//  destapa la card de nube, que bajo XCUITest está oculta para el resto de la suite. Lo que NO se puede
//  recorrer aquí es lo que vive de CloudKit o del backend —la sonda de iCloud, el relanzamiento con el espejo,
//  la promoción de la cuenta—: bajo XCUITest la puerta de iCloud no toca la red y deja pasar, y el mount no es
//  el neutro, así que no hay relanzamiento. Eso es device-QA (guion en el ticket).
//

import XCTest

final class FullModeActivationChooserUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchGroupsOnlyAndOpenTheActivation() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchForUITest(groupInvite: true, extraArguments: ["-uitest-cloud-chooser"])
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap/seed no completó.")

        app.openProfile()
        let activate = app.buttons["profile_activate_full_yala"]
        XCTAssertTrue(activate.waitForExistence(timeout: 10),
                      "No apareció «Activar Yala completo» en el Perfil de un usuario solo-grupos.")
        activate.tap()
        return app
    }

    /// Criterio 1 del ticket: la elección va ANTES de cualquier onboarding. La aserción negativa se apoya en la
    /// positiva —las cards ya están en pantalla—, así que no puede cumplirse por no haber cargado nada.
    func test_activation_showsTheChooserBeforeAnyOnboarding() {
        let app = launchGroupsOnlyAndOpenTheActivation()

        XCTAssertTrue(app.buttons["welcome_new_private"].waitForExistence(timeout: 10),
                      "La activación no enseñó la card «Tu cuenta en tu iCloud privado».")
        XCTAssertTrue(app.buttons["welcome_new_cloud"].exists,
                      "La activación no enseñó la card «Tu cuenta en la nube».")
        XCTAssertFalse(app.buttons["onboarding_next_button"].exists,
                       "El onboarding personal apareció sin que nadie eligiera dónde viven los datos.")
    }

    /// Privado → la puerta de iCloud (bajo XCUITest deja pasar sin tocar la red) → el onboarding personal.
    func test_privateChoice_leadsToThePersonalOnboarding() {
        let app = launchGroupsOnlyAndOpenTheActivation()

        let privateCard = app.buttons["welcome_new_private"]
        XCTAssertTrue(privateCard.waitForExistence(timeout: 10))
        privateCard.tap()

        XCTAssertTrue(app.buttons["onboarding_next_button"].waitForExistence(timeout: 15),
                      "Elegir privado no llevó al onboarding personal.")
    }

    /// Nube → el consentimiento, que no se recorta. Y cancelarlo vuelve a la elección, no cierra la activación.
    func test_cloudChoice_opensTheConsent_andCancelReturnsToTheChooser() {
        let app = launchGroupsOnlyAndOpenTheActivation()

        let cloudCard = app.buttons["welcome_new_cloud"]
        XCTAssertTrue(cloudCard.waitForExistence(timeout: 10))
        cloudCard.tap()

        XCTAssertTrue(app.buttons["storage_consent_accept"].waitForExistence(timeout: 10),
                      "Elegir la nube no pasó por el consentimiento.")
        app.buttons["storage_consent_cancel"].tap()

        XCTAssertTrue(app.buttons["welcome_new_private"].waitForExistence(timeout: 10),
                      "Cancelar el consentimiento no devolvió a la elección privado / nube.")
    }
}
