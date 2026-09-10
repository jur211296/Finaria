//
//  GroupsNeutralReturnTests.swift
//  YalaTests / CloudSync
//
//  Paso 5-b del rediseño de sesiones · **la vuelta al neutro de «Vengo por un grupo»**.
//
//  Lo que la tabla de `GroupsOrganizerBranchTests` ya cubre —qué decide la puerta con sus cinco
//  términos— no se repite aquí. Esto cubre las tres piezas que están al otro lado de ese veredicto y
//  que, si fallan, lo hacen en silencio:
//
//   (A) **Cuándo se autoriza el borrado.** Es el único sitio del chip donde un `if` invertido cuesta
//       datos: la promesa «lo tuyo sigue en iCloud» solo es cierta para lo que ya subió.
//   (B) **El seam del testigo del mount**, que existe porque el testigo MIENTE en el host de test.
//   (C) **El cableado** (source-scan): que el arm y el destino se escriban JUNTOS y que la espera
//       llame a la tabla en vez de decidir a mano. Una lógica pura impecable no sirve de nada si el
//       call-site la rodea — es la familia de mutantes que en este mismo ticket ya cayó una vez.
//

import Foundation
import Testing

@testable import Yala

private typealias Neutral = GroupsNeutralReturnLogic

// MARK: - (A) Cuándo se autoriza el borrado

@Suite("Paso 5-b · la subida que autoriza el borrado")
struct GroupsNeutralReturnUploadTests {

    @Test("solo autoriza la celda en la que TODO salió bien")
    func onlyTheCleanCaseAuthorizes() {
        #expect(Neutral.verdict(attempt: .reachedICloud, exportFailed: false, stillSyncing: false)
                == .safeToArmWipe)
    }

    /// **Las tres celdas que cuestan datos, una por término.** Cada una por separado tiene que bastar
    /// para frenar: son los tres modos en los que la app creería que subió algo que no subió.
    @Test("cualquiera de los tres términos, por sí solo, frena el borrado")
    func everyTermAloneStopsTheWipe() {
        // Sin red: el caso REAL, y el que la decisión de Jürgen del 2026-09-09 nombra («nunca borra sin
        // subir»). Aquí lo que se pierde es lo que la persona escribió y no llegó a salir del teléfono.
        #expect(Neutral.verdict(attempt: .unreachable, exportFailed: false, stillSyncing: false)
                == .waitForUpload)
        // Falló por otra cosa (sin cuenta, conflicto al guardar): tampoco sabemos que subiera.
        #expect(Neutral.verdict(attempt: .failed, exportFailed: false, stillSyncing: false)
                == .waitForUpload)
        // El export falló DESPUÉS de que la red contestara: es el peor de los tres, porque el intento
        // sí llegó a iCloud y sin este término la app lo leería como éxito.
        #expect(Neutral.verdict(attempt: .reachedICloud, exportFailed: true, stillSyncing: false)
                == .waitForUpload)
        // Sigue habiendo algo en vuelo al agotarse la ventana: borrar los archivos por debajo lo mata.
        #expect(Neutral.verdict(attempt: .reachedICloud, exportFailed: false, stillSyncing: true)
                == .waitForUpload)
    }

    /// **La exhaustividad, y no es decorativa: es lo que fija que el gate falle CERRADO.** Cualquier
    /// reescritura del predicado en forma negativa (un `guard` por motivo de fallo) sigue pasando los
    /// casos de arriba y deja pasar el término que alguien añada mañana sin tratar. Aquí no.
    @Test("las 12 celdas: `safeToArmWipe` exige los tres términos y nada más")
    func fullTableFailsClosed() {
        for attempt: Neutral.UploadAttempt in [.reachedICloud, .unreachable, .failed] {
            for exportFailed in [true, false] {
                for stillSyncing in [true, false] {
                    let verdict = Neutral.verdict(attempt: attempt,
                                                  exportFailed: exportFailed,
                                                  stillSyncing: stillSyncing)
                    let expected = attempt == .reachedICloud && !exportFailed && !stillSyncing
                    #expect((verdict == .safeToArmWipe) == expected,
                            "intento=\(attempt) exportFalló=\(exportFailed) sincronizando=\(stillSyncing) ⇒ \(verdict)")
                }
            }
        }
    }

    /// **Sin espejo no se espera, y esta celda es la que impide un cuelgue permanente.** En la rama
    /// `.askBeforeWiping` no hay iCloud a donde subir: `forceSync` devolvería `.failed` por su propio
    /// `guard isAccountAvailable`, el veredicto diría «espera» y la persona se quedaría mirando «un
    /// momento más» para siempre. Lo que autoriza ahí es su segundo gesto.
    @Test("la espera de subida es SOLO del camino con espejo")
    func uploadIsRequiredOnlyWhenThereIsAMirror() {
        #expect(Neutral.requiresUploadBeforeWipe(mirrorsToICloud: true))
        #expect(!Neutral.requiresUploadBeforeWipe(mirrorsToICloud: false))
    }
}

// MARK: - (B) El seam del testigo del mount

@Suite("Paso 5-b · el seam del testigo del mount", .serialized)
@MainActor
struct GroupsGateMirrorSeamTests {

    /// **El seam es más ESTRECHO que su hermano, y esa es toda su razón de ser.**
    /// `mirrorWillSync` usa `attachesCloudKitMirror`, que es `true` también en `.localNoMirror` —el
    /// mount sin cuenta de iCloud, que adjunta el espejo igual por caer en `.automatic`—. Si la puerta
    /// usara ése, un teléfono sin iCloud caería en «vuelta al neutro» y se le borraría un histórico que
    /// **no está en ninguna otra parte**, con un aviso que además le prometería lo contrario.
    @Test("`.localNoMirror` adjunta espejo pero NO espeja a iCloud")
    func localNoMirrorIsNotAnICloudMirror() {
        #expect(SwiftDataConfiguration.PersonalStoreDecision.localNoMirror.attachesCloudKitMirror)
        #expect(!SwiftDataConfiguration.PersonalStoreDecision.localNoMirror.mirrorsToICloud)
        // Y el control positivo, sin el cual lo de arriba se cumpliría con un eje que devolviera
        // siempre `false`.
        #expect(SwiftDataConfiguration.PersonalStoreDecision.iCloudMirror.mirrorsToICloud)
    }

    /// El seam se puede sustituir, que es lo que permite que la puerta tenga tests deterministas sobre
    /// un host donde el testigo real es un default.
    @Test("el seam manda sobre el testigo, y `_testReset` lo repone")
    func seamOverridesAndResets() {
        defer { ICloudPersonalCorpusProbe._testReset() }

        ICloudPersonalCorpusProbe.mirrorsToICloudNow = { true }
        #expect(ICloudPersonalCorpusProbe.mirrorsToICloudNow())
        ICloudPersonalCorpusProbe.mirrorsToICloudNow = { false }
        #expect(!ICloudPersonalCorpusProbe.mirrorsToICloudNow())

        ICloudPersonalCorpusProbe._testReset()
        // Repuesto = el cuerpo de producción. En el host de tests eso es la rama de UITest o el testigo
        // real; lo que se afirma aquí es que `_testReset` deja de devolver el override anterior.
        #expect(ICloudPersonalCorpusProbe.mirrorsToICloudNow()
                == ICloudPersonalCorpusProbe.productionMirrorsToICloudNow())
    }
}

// MARK: - (C) El cableado

@Suite("Paso 5-b · el cableado de la vuelta al neutro (source-scan)")
struct GroupsNeutralReturnWiringTests {

    private static let contentView = "Yala/App/ContentView.swift"
    private static let gateView = "Yala/App/Views/Onboarding/WelcomeGroupsGateView.swift"

    /// **El código SIN sus comentarios.** Un source-scan que mira el fichero entero afirma sobre la
    /// prosa: los docblocks de esta familia NOMBRAN lo que prohíben («no toca `UserDefaults`», «quien
    /// arma es `ContentView`»), así que un escáner ingenuo se dispara con la frase que explica la regla
    /// y no con su incumplimiento. Cazado por estos mismos tests al escribirlos.
    private static func codeWithoutComments(_ path: String) throws -> String {
        try code(path)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static func code(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // CloudSync
            .deletingLastPathComponent()   // YalaTests
            .deletingLastPathComponent()   // repo
        return try String(contentsOf: root.appending(path: path), encoding: .utf8)
    }

    /// **Las dos mitades del efecto durable van JUNTAS, y separarlas rompe cosas distintas.**
    ///
    ///  · Sin el arm no se borra nada: el arranque siguiente vuelve a montar el espejo y la persona
    ///    reabre la app para nada — el bucle que el device-QA marca como fallo grave.
    ///  · Sin el destino, el proceso NO se muere al irse al fondo (`RelaunchNetLogic` lee «hay destino
    ///    pendiente», no el motivo), así que la persona vuelve al mismo proceso, con el mismo store
    ///    montado, y el borrado pre-mount no llega a correr nunca.
    @Test("el arm del borrado y el destino pendiente se escriben en el MISMO sitio")
    func armAndDestinationAreWrittenTogether() throws {
        let code = try Self.codeWithoutComments(Self.contentView)
        let callback = try #require(code.range(of: "onNeedsNeutralReturn: {"))
        let resto = code[callback.upperBound...]
        // **El corte NO puede depender de la indentación** (la primera versión cableaba 20 espacios y un
        // reformateo del modifier la habría puesto en rojo por formato). Se corta en el siguiente
        // parámetro nombrado del container, que es una frontera semántica.
        let fin = try #require(resto.range(of: "hasPersonalDataNow:"))
        let cuerpo = String(resto[..<fin.lowerBound])

        #expect(cuerpo.contains("StorageModePersistence.armSignOutWipe()"), """
            la vuelta al neutro tiene que ARMAR el borrado de arranque. Sin él la persona reabre la app y
            el store sigue con el espejo puesto: bucle de «reabre Yala».
            """)
        #expect(cuerpo.contains("WelcomePendingDestinationStore.set(.groupsOrganizer)"), """
            sin destino pendiente el proceso no se mata al pasar a background, así que el borrado
            pre-mount no llega a correr.
            """)
        // Y lo que NO puede aparecer: marcar Grupos dentro del borrado se llevaría el store de grupos,
        // que el ADR §6 deja fuera de cualquier vaciado.
        #expect(!cuerpo.contains("markSignOutWipeIncludesGroups"), """
            el borrado de esta vuelta al neutro NO puede incluir el store de Grupos (ADR §6).
            """)
    }

    /// **El hueco que este escáner tapa está en `ContentView`, no en la puerta.** La vista pide
    /// `hasPersonalDataNow`, pero quien decide QUÉ detector lo alimenta es el call-site — y ahí
    /// `checkHasExistingData()` compila igual de bien. Con el ancho, el borrado de arranque no se lleva
    /// los grupos (ADR §6) y la puerta vuelve a disparar tras reabrir: «reabre la app» para siempre.
    /// Medido al escribir el chip: ningún test de comportamiento lo ve, porque en un simulador sin
    /// grupos los dos detectores devuelven lo mismo.
    @Test("el detector que alimenta la puerta es el ESTRECHO, en el call-site")
    func theGateIsFedTheNarrowDetector() throws {
        let code = try Self.codeWithoutComments(Self.contentView)
        #expect(code.contains("hasPersonalDataNow: { checkHasPersonalData() }"), """
            la puerta de Grupos tiene que alimentarse de `checkHasPersonalData`. Con `checkHasExistingData`
            —que cuenta grupos y filas puenteadas— quien tenga grupos locales entra en bucle de
            relanzamiento: el borrado de arranque no toca el store de Grupos.
            """)
        // Y el ancho SIGUE alimentando a quien sí lo necesita: el guard cross-cuenta del sign-in de nube,
        // donde «datos de otro humano» incluye sus grupos. Sin este control, el escáner de arriba se
        // cumpliría igual borrando el detector ancho de todo el fichero.
        #expect(code.contains("hasLocalDataNow: { checkHasExistingData() }"), """
            el guard cross-cuenta del sign-in sigue queriendo el detector ANCHO: son dos preguntas
            distintas sobre el mismo dispositivo.
            """)
    }

    /// **El mutante que sobrevivía a la suite entera: el MAPEO de `forceSync` al enum de la tabla.**
    /// Ni la tabla pura lo ve (no conoce el call-site) ni el XCUITest lo mata (en simulador `forceSync`
    /// devuelve `.failed` por su `guard isAccountAvailable`, así que la rama `.unreachable` no se
    /// recorre). Con `case .unreachable: attempt = .reachedICloud` —un swap de dos identificadores que
    /// compila— la app armaría el borrado **sin red**, que es exactamente el daño que este chip existe
    /// para impedir. Cazado por la review adversarial del 2026-09-10.
    ///
    /// Se fija el EMPAREJAMIENTO completo y en orden, no la presencia de los tres nombres: un `contains`
    /// por separado pasa con los tres casos intercambiados.
    @Test("MUTACIÓN: los tres desenlaces de `forceSync` se traducen uno a uno, sin swaps")
    func forceSyncOutcomesMapOneToOne() throws {
        let code = try Self.codeWithoutComments(Self.contentView)
        let pares = [("ok", "reachedICloud"), ("unreachable", "unreachable"), ("failed", "failed")]
        var cursor = code.startIndex
        for (resultado, esperado) in pares {
            let literal = "case .\(resultado): attempt = .\(esperado)"
            let encontrado = try #require(
                code.range(of: literal, range: cursor..<code.endIndex),
                """
                falta o cambió `\(literal)`. Traducir `.unreachable` a `.reachedICloud` arma el borrado
                sin red; traducir `.ok` a otra cosa deja el camino de Grupos inalcanzable para siempre.
                """)
            cursor = encontrado.upperBound
        }
    }

    /// La señal de restore se apaga ANTES de armar, y es un criterio de aceptación del ticket. El
    /// docblock de la puerta lo afirmaba cuando la llamada no existía — la review lo cazó.
    @Test("la vuelta al neutro apaga la señal de restore ANTES de armar nada")
    func restoreSignalIsClearedBeforeArming() throws {
        let view = try Self.codeWithoutComments(Self.gateView)
        let apagado = try #require(view.range(of: "ICloudRestoreSessionSignal.noteRestoreFinished()"), """
            un restore que nadie declara terminado deja a `CrossAccountEntryGuardLogic` —que consume la
            misma señal— creyendo que este dispositivo está restaurando.
            """)
        let arm = try #require(view.range(of: "onNeedsNeutralReturn()"))
        #expect(apagado.upperBound < arm.lowerBound,
                "la señal se apaga ANTES del arm: después, el arm ya decidió sobre un hecho falso")
    }

    /// La espera no puede decidir a mano: el veredicto es una tabla probada, y el call-site tiene que
    /// consumirla. Un `if result == .ok` escrito aquí compilaría y se saltaría los otros dos términos.
    @Test("la espera de subida consume la tabla y mira el error de export DESPUÉS")
    func uploadUsesTheTable() throws {
        let code = try Self.codeWithoutComments(Self.contentView)
        #expect(code.contains("GroupsNeutralReturnLogic.verdict("), """
            el veredicto de la subida sale de la tabla pura, no de un `if` en la vista.
            """)
        #expect(code.contains("exportFailed: sync.lastExportError != nil"), """
            un export que falla es el caso en el que la app creería que subió y no subió.
            """)
        #expect(code.contains("stillSyncing: sync.status.isSyncing"))
    }

    /// El único camino que arma pasa por el veredicto, en las DOS ramas. Si alguien llamara al callback
    /// desde la rama sin iCloud sin pasar por aquí, el segundo gesto dejaría de ser el que autoriza.
    @Test("la puerta arma por un solo camino, y ese camino pregunta si hay que subir")
    func theGateArmsThroughASinglePath() throws {
        let view = try Self.codeWithoutComments(Self.gateView)
        #expect(view.contains("GroupsNeutralReturnLogic.requiresUploadBeforeWipe(mirrorsToICloud:"), """
            sin este término, la rama sin iCloud esperaría una subida imposible y se quedaría en «un
            momento más» para siempre.
            """)
        // Dos llamadas y no más: la del veredicto `.returnToNeutral` y la del segundo gesto.
        // **Lo que se cuenta es el CALLBACK, no el helper**, y ésa era la debilidad que la review cazó:
        // contar `runNeutralReturn(` no impide que alguien llame a `onNeedsNeutralReturn()` por su cuenta
        // desde una rama nueva — el conteo seguiría cuadrando y el segundo gesto dejaría de ser lo que
        // autoriza el borrado. El cuello de botella es el callback y tiene que tener UN solo call-site.
        let armados = view.components(separatedBy: "onNeedsNeutralReturn()").count - 1
        #expect(armados == 2, """
            `onNeedsNeutralReturn()` tiene DOS call-sites legítimos, los dos dentro de
            `runNeutralReturn`: el atajo de la rama sin respaldo (donde autoriza el segundo gesto) y el
            `.safeToArmWipe` de la rama con espejo. Hay \(armados) — cada uno de más es un camino que
            arma el borrado sin pasar por ninguna de las dos autorizaciones.
            """)
        // Y los dos están DENTRO del helper: un call-site en el `body` o en `evaluate()` —los dos viven
        // ANTES en el fichero— armaría sin veredicto y el conteo seguiría cuadrando si alguien quitara
        // otro. Esto es lo que fija el cuello de botella.
        let helper = try #require(view.range(of: "func runNeutralReturn(mirrorsToICloud:"))
        let primerArm = try #require(view.range(of: "onNeedsNeutralReturn()"))
        #expect(helper.upperBound < primerArm.lowerBound, """
            hay una llamada a `onNeedsNeutralReturn()` ANTES de `runNeutralReturn`, o sea fuera del único
            camino que comprueba si lo pendiente subió a iCloud.
            """)
    }

    /// **La puerta sigue sin escribir nada por su cuenta**, que es la mitad vieja del chip y no se
    /// pierde al añadirle ramas: `onboardingMode` es never-downgrade cross-device.
    @Test("la vista de la puerta no toca `UserDefaults` ni arma nada")
    func theGateViewStillWritesNothing() throws {
        let view = try Self.codeWithoutComments(Self.gateView)
        for prohibido in ["UserDefaults", "armSignOutWipe", "WelcomePendingDestinationStore",
                          "OnboardingMode.setCurrent"] {
            #expect(!view.contains(prohibido), """
                la puerta escribió `\(prohibido)`. Decide y enseña; quien toca el estado durable es
                `ContentView`, por la misma razón que con `onNeedsMirrorRelaunch`.
                """)
        }
    }
}
