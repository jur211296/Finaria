//
//  SessionExitsPerCellUITests.swift
//  YalaUITests
//
//  Paso 9 del rediseño de sesiones (ADR 2026-09-09 «Sesiones — dos ejes» §5-6): Ajustes enseña los mismos DOS
//  botones —«Cerrar sesión» y «Vaciar datos»— en todas las celdas, y la hoja de «Cerrar sesión» es la de SU
//  celda. La fila es una sola en las cuatro, así que lo que demuestra de qué celda es cada pantalla es el
//  identifier de escenario de la hoja (`destructive_scope_sheet_<operación>`).
//
//  Celdas alcanzables en el simulador con los seams que ya existen:
//   - C · privada sin nube: el arranque por defecto.
//   - D · privada + sesión de grupos: `-uitest-fake-cloud-session` (finge el predicado GLOBAL de sesión).
//   - F · solo grupos: el mismo seam + `-uitest-group-invite`.
//  La E (nube completa) no tiene seam de `storageMode == .cloud` y la cubre la tabla unitaria
//  (`CloudSignOutFlowLogicTests`, `DestructiveScopeLogicTests`).
//
//  Ningún test CONFIRMA el cierre: el seam no crea una sesión real, y confirmar borraría el store del
//  simulador. Se abre la hoja, se lee su escenario y se cancela.
//

import XCTest

final class SessionExitsPerCellUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Las filas de salida que el ADR retiró. Ninguna puede volver en ninguna celda.
    private let retiredRows = [
        "profile_security_signout_plain", "profile_security_signout_groups",
        "profile_security_exit_yala_split", "profile_security_exit_yala_legacy",
        "profile_security_delete_account",
    ]

    /// Baja por Ajustes hasta que el botón sea hittable (la sección Seguridad y cuenta vive al final).
    /// Determinista: tope de intentos, sin sleeps.
    private func scrollTo(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        let element = app.buttons[identifier]
        var tries = 0
        while !element.isHittable && tries < 14 {
            app.swipeUp()
            tries += 1
        }
        return element
    }

    /// Los dos botones están, y ninguna de las salidas retiradas.
    private func assertTwoButtons(_ app: XCUIApplication, cell: String) {
        let reset = scrollTo(app, "profile_security_reset_data")
        XCTAssertTrue(reset.waitForExistence(timeout: 5), "\(cell): falta «Vaciar datos».")
        let signOut = scrollTo(app, "profile_security_signout")
        XCTAssertTrue(signOut.waitForExistence(timeout: 5), "\(cell): falta «Cerrar sesión».")
        for retired in retiredRows {
            XCTAssertFalse(app.buttons[retired].exists, "\(cell): volvió la fila retirada '\(retired)'.")
        }
    }

    /// Abre la hoja de «Cerrar sesión», devuelve su identifier de escenario y la cierra sin confirmar.
    private func signOutSheetScenario(_ app: XCUIApplication) -> String {
        scrollTo(app, "profile_security_signout").tap()
        let sheet = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "destructive_scope_sheet_"))
            .firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5), "La hoja de «Cerrar sesión» no se presentó.")
        let scenario = sheet.identifier
        app.buttons["destructive_scope_cancel"].tap()
        return scenario
    }

    func test_privateCell_C_twoButtons_andPrivateSheet() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "minimal")
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap no completó.")
        app.openProfile()

        assertTwoButtons(app, cell: "C")
        let scenario = signOutSheetScenario(app)
        // Con o sin copia en iCloud, pero la del privado SIN grupos. Cuál de las dos lo decide el testigo del
        // mount, y bajo `-uitest` el store es propio y ese testigo se queda en su valor por defecto: el aviso
        // «sin copia» y su segundo gesto los fijan los source-scans de `PrivateSignOutWiringTests` y el device-QA.
        XCTAssertTrue(scenario.hasPrefix("destructive_scope_sheet_signout_private"), "C mostró \(scenario)")
        XCTAssertFalse(scenario.contains("with_groups"), "C mostró la hoja del «equipo»: \(scenario)")
    }

    func test_teamCell_D_twoButtons_andTeamSheet() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "minimal", cloudSession: true)
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap no completó.")
        app.openProfile()

        assertTwoButtons(app, cell: "D")
        let scenario = signOutSheetScenario(app)
        XCTAssertTrue(scenario.hasPrefix("destructive_scope_sheet_signout_private_with_groups"),
                      "D (privada + grupos) mostró \(scenario): no hay «salir solo de grupos».")
    }

    /// F es además la celda donde «Eliminar mi cuenta» NO existía antes del paso 9: la fila excluía el modo
    /// group-invite con una premisa de la era CKShare. Aquí tiene que aparecer, dentro de «Tu cuenta de Yala».
    func test_groupsOnlyCell_F_twoButtons_groupsOnlySheet_andDeleteAccountInsideYalaAccount() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "solo-grupos", groupInvite: true, cloudSession: true)
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap/seed no completó.")
        app.openProfile()

        assertTwoButtons(app, cell: "F")
        let scenario = signOutSheetScenario(app)
        XCTAssertEqual(scenario, "destructive_scope_sheet_signout_groups_only")

        let accountRow = scrollTo(app, "profile_yala_account")
        XCTAssertTrue(accountRow.waitForExistence(timeout: 5), "F: falta «Tu cuenta de Yala».")
        accountRow.tap()
        XCTAssertTrue(app.buttons["yala_account_delete"].waitForExistence(timeout: 5),
                      "F: «Eliminar mi cuenta» tiene que estar en «Tu cuenta de Yala» (App Store 5.1.1 v).")
    }
}
