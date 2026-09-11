//
//  GroupsAssociationRowUITests.swift
//  YalaUITests
//
//  Paso 10 del rediseño de sesiones (ADR 2026-09-09 «Sesiones — dos ejes» §4): la cuenta que una sesión
//  privada usa para Grupos **se ve, se deshace y se rehace** en Ajustes → «¿Dónde viven tus datos?».
//
//  Lo que esta suite prueba y ninguna tabla unitaria puede: que la sección **se monta de verdad dentro de
//  esa pantalla**. La tabla de estados (`GroupsAssociationLogicTests`) dice qué debería pintar cada celda,
//  pero con la sección colgada de una rama del `switch` que nadie recorre, o con la fila de Ajustes
//  gateada fuera, esa tabla sigue verde y el gesto no existe para nadie.
//
//  Celdas alcanzables en el simulador con los seams que ya existen, las mismas que `SessionExitsPerCell`:
//   - **sin cuenta**: el arranque por defecto (sesión privada, sin sesión en la nube).
//   - **asociada**: `-uitest-fake-cloud-session`, que finge el predicado GLOBAL de sesión.
//   - **solo grupos (F)**: el mismo seam + `-uitest-group-invite` — ahí la sección NO aplica.
//  Las otras dos —nube completa, y asociada SIN sesión viva (el segundo móvil)— no tienen seam: la
//  primera necesita `storageMode == .cloud` y la segunda una asociación sembrada en el iCloud-KV. Las
//  cubre la tabla unitaria, y el recorrido real, el device-QA.
//
//  **Ningún test confirma el desasociar.** El seam no crea una sesión real, así que confirmarlo dejaría el
//  coordinador intentando subir un outbox contra un backend que no existe. Se abre la hoja, se leen sus
//  dos salidas y se cancela — el molde de `SessionExitsPerCellUITests`.
//

import XCTest

final class GroupsAssociationRowUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Baja por Ajustes hasta que el elemento sea alcanzable. Determinista: tope de intentos, sin sleeps.
    private func scrollTo(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        let element = app.buttons[identifier]
        var tries = 0
        while !element.isHittable && tries < 14 {
            app.swipeUp()
            tries += 1
        }
        return element
    }

    /// Abre Ajustes → «¿Dónde viven tus datos?» y espera a que la pantalla monte.
    ///
    /// La fila está gateada por `StorageRowGateLogic.isVisible`, así que **que exista ya es parte de lo
    /// que se prueba**: si algún día el gate la cerrara para una sesión privada, el gesto de desasociar se
    /// quedaría sin ninguna superficie y esta suite lo diría aquí.
    private func openStorageScreen(_ app: XCUIApplication) {
        let row = scrollTo(app, "storage_settings_row")
        XCTAssertTrue(row.waitForExistence(timeout: 5), """
            No aparece la fila «¿Dónde viven tus datos?» en Ajustes. Es la ÚNICA superficie desde la que se
            puede soltar la cuenta de grupos: sin ella, quien la tenga asociada no puede desasociarla.
            """)
        row.tap()
        // Por `descendants(matching: .any)` y no por `otherElements`: el tipo con el que SwiftUI publica
        // una card depende de lo que lleve dentro, y un `XCUIElementQuery` acotado al tipo equivocado da
        // un rojo mudo que parece «la pantalla no montó». Medido aquí mismo.
        XCTAssertTrue(
            app.descendants(matching: .any)["storage_status_card"].waitForExistence(timeout: 5),
            "La pantalla de almacenamiento no montó.")
    }

    /// El TÍTULO de la sección, que es donde vive el identifier: puesto en el contenedor pisaría el de
    /// los botones y estos dejarían de existir con su id propio en el árbol de accesibilidad.
    private func section(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts["storage_groups_section"]
    }

    // MARK: - Sesión privada SIN cuenta de grupos

    func test_privateWithoutAccount_offersAssociate_andNoDetach() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "minimal")
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap no completó.")
        app.openProfile()
        openStorageScreen(app)

        XCTAssertTrue(section(app).waitForExistence(timeout: 5),
                      "La sección «Grupos» no se monta en la pantalla de almacenamiento.")
        XCTAssertTrue(scrollTo(app, "storage_groups_associate_button").waitForExistence(timeout: 5),
                      "Sin cuenta asociada, la sección tiene que ofrecer asociar una.")
        XCTAssertFalse(app.buttons["storage_groups_detach_button"].exists, """
            Se ofrece «Desasociar» sin ninguna cuenta asociada.
            """)
    }

    // MARK: - Sesión privada CON cuenta de grupos (el «equipo»)

    func test_privateWithGroupsSession_offersDetach_withBothOutcomes() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "minimal", cloudSession: true)
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap no completó.")
        app.openProfile()
        openStorageScreen(app)

        XCTAssertTrue(section(app).waitForExistence(timeout: 5), "La sección «Grupos» no se monta.")
        // Decisión de Jürgen (2026-09-09): mientras haya una asociada, la fila SOLO ofrece desasociar. No
        // existe un «Cambiar cuenta» que haga las dos cosas de un gesto.
        XCTAssertFalse(app.buttons["storage_groups_associate_button"].exists, """
            Con una cuenta ya asociada se sigue ofreciendo asociar otra: para cambiar de cuenta hay que
            desasociar primero.
            """)

        let detach = scrollTo(app, "storage_groups_detach_button")
        XCTAssertTrue(detach.waitForExistence(timeout: 5), "Falta «Desasociar».")
        detach.tap()

        // **Las DOS salidas, en la misma hoja.** Es la decisión de Jürgen que deroga el «se quedan
        // siempre» del ticket: conservar los gastos que pagó, o quitarlo todo. Se afirma que existen las
        // dos: una hoja con una sola salida sería la decisión anterior del ticket, en silencio.
        // `.firstMatch` porque el `confirmationDialog` de SwiftUI publica sus botones DOS veces en el
        // árbol de accesibilidad (medido): una consulta sin acotar falla con «Multiple matching elements»
        // en cuanto se le pide una propiedad, no al buscarlos.
        let keep = app.buttons.matching(identifier: "storage_groups_detach_keep").firstMatch
        let remove = app.buttons.matching(identifier: "storage_groups_detach_remove").firstMatch
        XCTAssertTrue(keep.waitForExistence(timeout: 5), "La confirmación no ofrece conservar.")
        XCTAssertTrue(remove.exists, "La confirmación no ofrece quitar.")
        XCTAssertNotEqual(keep.label, remove.label, """
            Las dos salidas comparten texto: quien las lea no puede distinguir qué elige.
            """)

        // **El botón de cancelar no se toca, y no es un descuido.** Medido en el árbol de accesibilidad:
        // SwiftUI NO propaga el `accessibilityIdentifier` al botón `role: .cancel` de un
        // `confirmationDialog` —los otros dos sí salen con el suyo—, así que la única forma de tocarlo
        // sería por su texto localizado, que es justo lo que este repo prohíbe. El diálogo se queda
        // abierto al terminar el caso, que es inocuo: nada se confirma y la app muere con el test.
    }


    // MARK: - Solo grupos (F): la sección no aplica

    /// Sin sesión privada no hay nada a lo que ligar una cuenta, así que la sección no existe. Es una
    /// aserción NEGATIVA, y por eso va acompañada del control positivo de que la pantalla sí montó: sin
    /// él se cumpliría igual con la fila de Ajustes cerrada, que es otra cosa.
    func test_groupsOnly_sectionDoesNotApply() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "solo-grupos", groupInvite: true, cloudSession: true)
        XCTAssertTrue(app.waitForUITestReady(), "uitest_ready ausente — bootstrap/seed no completó.")
        app.openProfile()
        openStorageScreen(app)

        XCTAssertFalse(section(app).exists, """
            La sección «Grupos» se pinta en una sesión solo-grupos, donde no hay sesión privada a la que
            asociar nada: ahí la cuenta de la nube ES la sesión, y soltarla es «Cerrar sesión».
            """)
    }
}
