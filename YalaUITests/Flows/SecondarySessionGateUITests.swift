//
//  SecondarySessionGateUITests.swift
//  YalaUITests
//
//  **Los PRIMEROS XCUITest de la sesión secundaria M1** (chip M4 de MODO-NUBE-SPEC-M1-REVIVAL).
//  Hasta aquí el área `secondary-session` era 100 % unit + panel DEBUG: cero cobertura determinista de
//  lo único que la invitada llega a VER.
//
//  ## Qué se finge, y por qué es lo único que se puede fingir
//
//  `-uitest-secondary-session` enciende `SecondarySessionStore.isActive()` por el dominio VOLÁTIL de
//  `UserDefaults` y declara el testigo del mount. **No monta un store secundario, y no puede**: bajo
//  `-uitest` los tres `ModelConfiguration` retornan sus variantes `…-UITest` antes de mirar el
//  descriptor, así que ningún archivo `-Secondary` toca el disco del simulador — que es justo lo que
//  hace al seam seguro. El porqué completo, y por qué el testigo es obligatorio (sin él el cover
//  terminal de relanzamiento TAPA la app y no se ve ninguna de estas pantallas), está en
//  `UITestEphemeralDefaults.applySecondarySession`.
//
//  ## Lo que estos casos NO cubren, para que nadie lo busque aquí
//
//  · **La celda `.blockedChannelOff` de la puerta.** Bajo `-uitest` `CloudSyncFlags.groupsBackendEnabled`
//    es SIEMPRE `true` (`CloudRemoteConfig.decide` corta en `isUITestHost` → `absentDefault`, ON bajo
//    `DEV_BUILD`) y no hay launch arg que lo apague. Vive en `YalaTests/Groups/GroupsOrganizerBranchTests`.
//  · **La VENTANA DE ENTRADA** (descriptor puesto + store del dueño montado, el estado que espera el
//    relanzamiento). No es expresable desde XCUITest —el seam declara el testigo justo para no caer en
//    ella— y su guard vive en los unit tests de mount-mismatch.
//  · **El e2e real**: entrada SIWA de una segunda cuenta, mount del store secundario, wipe de salida y
//    «el iCloud del dueño no recibe nada». Eso es device-only con 2 cuentas ⇒ MODO-NUBE-M1-GUION-DEVICE.
//

import XCTest

final class SecondarySessionGateUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Recorre el Welcome hasta la puerta de la rama organizador: Hero → «Vengo por un grupo» →
    /// «Crear mi primer grupo». Es el mismo camino que
    /// `WelcomeChooserUITests.testGroupsOrganizer_createCardWalksToTheGroupForm`, que es el CONTROL
    /// POSITIVO de este fichero: con los mismos args y sin `secondarySession` la puerta abre y aparece
    /// el educativo.
    private func walkToOrganizerGate(seed: String?, secondarySession: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchForUITest(
            reset: true,
            skipOnboarding: false,
            seed: seed,
            cloudSession: true,
            groupsConsent: true,
            groupsEducativo: true,
            secondarySession: secondarySession
        )

        // `uitest_ready` vive en el root de ContentView, que queda CUBIERTO por el fullScreenCover del
        // Welcome ⇒ se espera el Hero directamente (patrón de WelcomeChooserUITests).
        let heroCTA = app.buttons["welcome_hero_cta"]
        XCTAssertTrue(heroCTA.waitForExistence(timeout: 60), "No apareció el CTA del Hero.")
        heroCTA.tap()

        let inviteBranch = app.buttons["welcome_chooser_invite"]
        XCTAssertTrue(inviteBranch.waitForExistence(timeout: 10), "No apareció la card «Vengo por un grupo».")
        inviteBranch.tap()

        let createCard = app.buttons["welcome_groups_create"]
        XCTAssertTrue(createCard.waitForExistence(timeout: 10), "No apareció la card «Crear mi primer grupo».")
        createCard.tap()
        return app
    }

    /// El identifier de las tres pantallas de bloqueo lo pone `blockedContent` al VStack CONTENEDOR, y un
    /// id de contenedor PISA el de sus hijos ⇒ el elemento no sale como `buttons[…]` ni como
    /// `staticTexts[…]`. Se busca por descendiente, que es el patrón que el repo ya usa cuando el id vive
    /// en un contenedor (`.claude/rules/testing.md`).
    private func gateScreen(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    // MARK: - La puerta del Welcome

    /// **La celda que este chip existe para cubrir.** Estás de visita en el móvil de otra persona y la
    /// rama «crea tu primer grupo» no puede seguir: detrás de ella el alta escribe SEIS preferencias por
    /// `PreferenceSyncService`, que en `.localOnly` sigue escribiendo el espejo local — o sea el
    /// `UserDefaults` del DUEÑO — incluida `groupsBetaUnlocked`, que el wipe de salida NO repone.
    ///
    /// **Aserción NEGATIVA incluida y necesaria:** afirmar solo que sale la pantalla de bloqueo no
    /// distingue «la puerta bloqueó» de «la puerta abrió y además pintó algo»; lo que prueba que la rama
    /// se cortó es que el educativo —el primer escalón de la cadena, y lo que el control positivo SÍ ve—
    /// no llegue nunca.
    func test_organizerGate_inSecondarySession_blocksWithItsOwnScreen() {
        let app = walkToOrganizerGate(seed: nil, secondarySession: true)

        let blocked = gateScreen(app, "welcome_groups_gate_secondary_session")
        XCTAssertTrue(
            blocked.waitForExistence(timeout: 20),
            """
            De visita en el móvil de otro, la puerta de «crear mi primer grupo» tiene que bloquear con su \
            copy propio. Si no aparece, o el término `isSecondarySession` salió de \
            `GroupsOrganizerGateLogic.decide`, o el seam de la sesión secundaria dejó de encender el \
            descriptor.
            """
        )
        XCTAssertFalse(
            app.buttons["groups_onboarding_cta"].exists,
            "La puerta dejó pasar: el educativo es el primer escalón del alta y no debería montarse nunca aquí."
        )
    }

    /// La celda GEMELA, y el control que impide que la anterior pase por casualidad: **el mismo recorrido,
    /// el mismo build y la misma puerta, con la ÚNICA diferencia del seam**, acaban en pantallas
    /// distintas. Aquí hay corpus en el dispositivo (`checkHasExistingData` cuenta cuentas y categorías
    /// no-system, que el perfil de seed crea) pero nadie está de visita ⇒ **vuelta al neutro**.
    ///
    /// **Y esto es la regresión que el ticket cierra.** Hasta el 2026-09-11 esta celda pintaba
    /// `welcome_groups_gate_foreign_data`: «Aquí ya hay datos guardados … si son tuyos, crea el grupo
    /// desde la app que ya usas», con un único botón «Volver» y siendo «la app que ya usas» ÉSTA. Jürgen
    /// lo midió en su móvil el 2026-09-09 sobre su propio corpus. Ahora la app no bloquea: informa de que
    /// lo personal sigue en iCloud y deja el teléfono listo para el grupo.
    ///
    /// **Lo que este caso NO puede probar, y por eso no lo afirma:** que iCloud queda intacto. En el
    /// simulador no hay espejo, así que el borrado y su testigo del export son device-QA. Lo que sí se
    /// mide aquí es el VEREDICTO —qué pantalla decide la puerta— y la ausencia del bloqueo viejo.
    func test_organizerGate_withLocalCorpus_returnsToNeutralInsteadOfBlocking() {
        let app = walkToOrganizerGate(seed: "minimal", secondarySession: false)

        let working = gateScreen(app, "welcome_groups_gate_neutral_working")
        XCTAssertTrue(
            working.waitForExistence(timeout: 20),
            """
            Con corpus en el dispositivo la puerta tiene que VOLVER AL NEUTRO, no bloquear. Si en su lugar \
            salió el educativo, `hasExistingData` dejó de contar el corpus (ojo: `checkHasExistingData` \
            excluye lo `isSystem`); si salió una pantalla de bloqueo, alguien repuso el término que este \
            ticket retiró.
            """
        )
        // **La aserción que carga el peso**: la pantalla que atrapaba al dueño ya no es alcanzable.
        XCTAssertFalse(
            app.descendants(matching: .any).matching(identifier: "welcome_groups_gate_foreign_data")
                .firstMatch.exists,
            """
            `welcome_groups_gate_foreign_data` es el bloqueo sin salida que este ticket retiró. Si vuelve \
            a aparecer, el dueño de los datos vuelve a quedarse atrapado.
            """
        )
        XCTAssertFalse(
            app.descendants(matching: .any).matching(identifier: "welcome_groups_gate_secondary_session")
                .firstMatch.exists,
            "Sin descriptor secundario, la pantalla de «estás de visita» no puede aparecer: el veredicto es otro."
        )
        // Y no se pasa al alta: la vuelta al neutro va DELANTE, o el grupo nacería sobre el corpus.
        XCTAssertFalse(
            app.buttons["groups_onboarding_cta"].exists,
            "La puerta dejó pasar al educativo sin haber devuelto el dispositivo al neutro."
        )
    }

    // MARK: - La shell de la invitada

    /// **El pin de la mitad no obvia del seam, y su docblock tiene que ser honesto sobre lo que NO
    /// prueba.** Su aserción positiva —que el Panel es alcanzable— se cumple IGUAL sin el seam, así que
    /// no demuestra nada de la sesión secundaria por sí sola. Existe por su MUTANTE, que es el único
    /// que lo pone en rojo dejando a los otros tres en verde: quitar `setMountWitness(true)` de
    /// `UITestEphemeralDefaults.applySecondarySession`.
    ///
    /// **Por qué hace falta un test propio para eso, medido y no razonado.** La intuición dice que sin el
    /// testigo el cover terminal de relanzamiento tapa la app y caen los tres tests de la puerta. **Es
    /// falso**: mientras el Welcome está presentado, el anchor está ocupado y el net no llega a montar su
    /// `fullScreenCover` (UIKit no presenta dos veces sobre el mismo anchor), así que las tres pantallas
    /// de bloqueo se ven exactamente igual con el seam a medias. La ventana de entrada solo se hace
    /// visible cuando NO hay Welcome delante — es decir, aquí.
    ///
    /// Lo que esto compra en producto: la sesión que el seam reproduce es la de la invitada **ya
    /// relanzada y usando el móvil**, no la que está esperando el relanzamiento. Sin esa distinción,
    /// cualquier XCUITest futuro que quiera ejercitar la shell de la invitada (tab bar, Perfil, ajustes)
    /// arrancaría contra una pantalla terminal y daría un rojo que no menciona el seam.
    func test_secondarySession_landsOnUsableShell_notOnTheRelaunchCover() {
        let app = XCUIApplication()
        app.launchForUITest(seed: "minimal", secondarySession: true)
        XCTAssertTrue(app.waitForUITestReady(), "La app no llegó a estar lista con la sesión secundaria puesta.")

        XCTAssertFalse(
            app.descendants(matching: .any).matching(identifier: "signout_relaunch_screen").firstMatch.exists,
            """
            La app quedó en el cover terminal de relanzamiento: el seam encendió el descriptor sin declarar \
            el testigo del mount, así que el proceso está en la VENTANA DE ENTRADA en vez de en la sesión \
            ya operativa.
            """
        )

        // `exists` del Panel no probaría nada —con un cover puesto el fondo sigue ENTERO en el árbol de
        // accesibilidad y los taps se pierden en {-1,-1}—, así que la aserción es de ALCANZABILIDAD.
        let avatar = app.buttons["profile_avatar"]
        XCTAssertTrue(avatar.waitForExistence(timeout: 20), "No apareció el avatar de Perfil en el Panel.")
        XCTAssertTrue(
            avatar.waitForHittable(timeout: 20),
            "El Panel está en el árbol pero no es alcanzable: algo lo tapa — el cover terminal de la ventana de entrada."
        )
    }

    // MARK: - La rama privada: informa y sigue

    /// Recorre el Welcome hasta la rama privada: Hero → «Es mi primera vez». **Bajo `-uitest` no hay
    /// sub-chooser** —`visibleNewOptions` deja una sola card, igual que en producción con el percent
    /// remoto en 0— así que la card de nivel 1 lleva directa a `handleNewOption(.privateAccount)`, que es
    /// exactamente el recorrido que hace hoy todo usuario nuevo.
    private func walkToPrivateBranch(secondarySession: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        // **Sin `onboarding:`**, que salta el Welcome entero (`UITestHooks.startAtOnboarding`) y dejaría
        // este recorrido sin la pantalla que viene a comprobar. Misma combinación que
        // `walkToOrganizerGate`, que es el recorrido hermano por la otra rama del chooser.
        app.launchForUITest(
            reset: true,
            skipOnboarding: false,
            seed: nil,
            secondarySession: secondarySession
        )

        let heroCTA = app.buttons["welcome_hero_cta"]
        XCTAssertTrue(heroCTA.waitForExistence(timeout: 60), "No apareció el CTA del Hero.")
        heroCTA.tap()

        let newBranch = app.buttons["welcome_chooser_new"]
        XCTAssertTrue(newBranch.waitForExistence(timeout: 10), "No apareció la card «Es mi primera vez».")
        newBranch.tap()
        return app
    }

    /// **El hueco que este cambio cierra.** Hasta el 2026-09-07 la visita elegía «privacidad total» y
    /// entraba al onboarding sin que nadie le dijera que estaba en el móvil de otra persona, mientras la
    /// rama de al lado —la organizador, dos casos más arriba— sí se lo decía. La app se contradecía
    /// según por dónde entraras.
    ///
    /// **Informa y NO bloquea**, y esa es la mitad que hay que afirmar: no basta con que salga la
    /// pantalla, porque una pantalla sin salida sería un camino muerto (y la decisión del owner del
    /// 2026-09-02 para esta familia es «encauzar, no bloquear»). Por eso el caso continúa: tras el CTA,
    /// el onboarding tiene que montar.
    func test_privateBranch_inSecondarySession_informsAndThenContinues() {
        let app = walkToPrivateBranch(secondarySession: true)

        let notice = gateScreen(app, "welcome_private_secondary_notice")
        XCTAssertTrue(
            notice.waitForExistence(timeout: 20),
            """
            De visita en el móvil de otro, «Es mi primera vez → privacidad total» tiene que decirlo antes \
            de seguir. Si no aparece, o el término `SecondarySessionStore.isActive()` salió de \
            `handleNewOption`, o el seam de la sesión secundaria dejó de encender el descriptor.
            """
        )

        let cta = app.buttons["welcome_private_secondary_continue"]
        XCTAssertTrue(cta.waitForExistence(timeout: 5), "El aviso se quedó sin su CTA de continuar.")
        cta.tap()

        XCTAssertTrue(
            app.textFields["onboarding_name_field"].waitForExistence(timeout: 20),
            """
            El aviso INFORMA, no bloquea: tras continuar, el onboarding privado tiene que montar. Si se \
            queda aquí, la pantalla se convirtió en el camino muerto que el spec del flujo prohíbe.
            """
        )
    }

    /// **El control positivo, y el que impide que el anterior pase por casualidad**: el mismo recorrido,
    /// el mismo build y la misma card, con la ÚNICA diferencia del seam. Sin sesión secundaria el aviso
    /// no existe y el usuario cae directo en el onboarding — el recorrido que este build ejercita bajo
    /// `-uitest` (la card born-cloud queda apagada por el seam, no por el percent) y que no puede haber
    /// cambiado ni un paso. Ojo: ya NO es el recorrido de producción — prod sirve el percent de la
    /// elección nube en 100 (medido el 2026-09-09) y muestra el sub-chooser.
    func test_privateBranch_withoutSecondarySession_goesStraightToOnboarding() {
        let app = walkToPrivateBranch(secondarySession: false)

        XCTAssertTrue(
            app.textFields["onboarding_name_field"].waitForExistence(timeout: 30),
            "Sin sesión secundaria, «Es mi primera vez» tiene que llevar directo al onboarding."
        )
        XCTAssertFalse(
            gateScreen(app, "welcome_private_secondary_notice").exists,
            """
            El aviso de visita salió para un usuario que NO está de visita. Es una pantalla de más en el \
            camino por el que pasa todo usuario nuevo de producción.
            """
        )
    }
}
