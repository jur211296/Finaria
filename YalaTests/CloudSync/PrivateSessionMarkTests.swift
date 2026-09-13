//
//  PrivateSessionMarkTests.swift
//  YalaTests / CloudSync
//
//  EL EJE 1 («¿hay sesión privada en este dispositivo?») sobre fixtures de `UserDefaults`.
//
//  **Lo que carga el peso aquí es la ASIMETRÍA de las dos lecturas ante la ausencia**, no el
//  guardar y leer. Guardar un `Bool` no se rompe solo; lo que se rompe —y en silencio— es el
//  default que alguien unifica «para simplificar». `hasPrivateSession` y `confirmedPrivateSession`
//  existen porque no hay un default que sirva para las dos preguntas: fallar a `true` conserva de
//  más (barato), y fallar a `true` en la señal de vaciado ORDENA a los demás dispositivos del Apple
//  ID vaciarse (el daño que la review del paso 9 cazó). Un test que solo mirase la marca PUESTA
//  pasaría verde con las dos lecturas colapsadas en una, que es justo la mutación que importa.
//

import Foundation
import Testing

@testable import Yala

@Suite("El eje 1: la marca de sesión privada")
struct PrivateSessionMarkTests {

    /// Suite propio por test: la marca vive en `UserDefaults` y dos tests compartiendo dominio se
    /// pisan el estado. `removePersistentDomain` se llama sobre la instancia del PROPIO suite —
    /// hacerlo desde otro dominio deja residuos (medido en este repo, ver `SessionDefaults`).
    private final class Fixture {
        let name: String
        let defaults: UserDefaults

        init() {
            name = "test.privateSessionMark.\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: name)!
        }

        deinit {
            defaults.removePersistentDomain(forName: name)
        }
    }

    // MARK: - La ausencia, que es el caso que justifica el diseño

    @Test("MUTACIÓN: ante la marca AUSENTE las dos lecturas responden distinto")
    func absentMarkSplitsTheTwoReads() {
        let f = Fixture()
        let d = f.defaults

        // El control NEGATIVO va primero: si la marca ya estuviera puesta, lo de abajo no mediría
        // la ausencia sino un valor, y pasaría verde sin comprobar ningún default.
        #expect(PrivateSessionMark.raw(d) == nil, "el fixture no arranca limpio: el test no mide nada")

        #expect(PrivateSessionMark.hasPrivateSession(d) == true, """
            «¿hay vida personal que PROTEGER?» falla hacia SÍ: conservar y esperar de más es el lado
            barato. Con `false` aquí, un cierre de sesión borraría sin esperar al export de iCloud.
            """)
        #expect(PrivateSessionMark.confirmedPrivateSession(d) == false, """
            «¿puedo AFIRMAR que es privada?» falla hacia NO. Con `true` aquí, «Vaciar datos» ordenaría
            a los demás dispositivos del Apple ID vaciarse — el iPad del dueño incluido.
            """)
        #expect(PrivateSessionMark.hasPrivateSession(d) != PrivateSessionMark.confirmedPrivateSession(d),
                "las dos lecturas colapsaron en una: una de las dos direcciones de fallo se perdió")
    }

    @Test("MUTACIÓN: `raw` distingue AUSENTE de `false`")
    func rawDistinguishesAbsentFromFalse() {
        let f = Fixture()
        let d = f.defaults

        #expect(PrivateSessionMark.raw(d) == nil)
        PrivateSessionMark.set(false, d)
        #expect(PrivateSessionMark.raw(d) == false, """
            sin el guard de `object(forKey:)`, `defaults.bool` devuelve `false` para una key ausente y
            `raw` no podría distinguirlos — y con eso el backfill se creería ya hecho para siempre.
            """)
    }

    // MARK: - Con la marca puesta, las dos lecturas coinciden

    @Test("con la marca PUESTA las dos lecturas dicen lo mismo", arguments: [true, false])
    func presentMarkAgreesOnBothReads(_ value: Bool) {
        let f = Fixture()
        let d = f.defaults

        PrivateSessionMark.set(value, d)
        #expect(PrivateSessionMark.hasPrivateSession(d) == value)
        #expect(PrivateSessionMark.confirmedPrivateSession(d) == value)
    }

    @Test("`clear` devuelve el dispositivo a la ausencia, con sus dos defaults")
    func clearRestoresTheAbsence() {
        let f = Fixture()
        let d = f.defaults

        PrivateSessionMark.set(false, d)
        #expect(PrivateSessionMark.raw(d) == false)   // control positivo: había algo que borrar

        PrivateSessionMark.clear(d)
        #expect(PrivateSessionMark.raw(d) == nil)
        #expect(PrivateSessionMark.hasPrivateSession(d) == true)
        #expect(PrivateSessionMark.confirmedPrivateSession(d) == false)
    }

    // MARK: - El backfill de un arranque

    @Test("el backfill escribe la celda del parque existente", arguments: [true, false])
    func backfillWritesTheLegacyCell(_ legacyIsGroupsOnly: Bool) {
        let f = Fixture()
        let d = f.defaults

        let escribio = PrivateSessionMark.backfillIfNeeded(legacyIsGroupsOnly: legacyIsGroupsOnly, hasCompletedOnboarding: true, d)
        #expect(escribio == true)
        #expect(PrivateSessionMark.raw(d) == !legacyIsGroupsOnly, """
            un dispositivo que hoy está en `.groupInvite` despierta SIN sesión privada; todos los
            demás —la celda normal, que es casi todo el parque— despiertan CON ella.
            """)
    }

    @Test("MUTACIÓN: el backfill es idempotente por PRESENCIA, no por valor")
    func backfillIsIdempotentByPresenceNotValue() {
        let f = Fixture()
        let d = f.defaults

        // Un solo-grupos que ya tiene su marca escrita a `false`.
        PrivateSessionMark.set(false, d)

        // Un arranque posterior en el que el flag legacy dice lo contrario — pasa de verdad: el
        // `onboardingMode` viaja por el iCloud-KV del Apple ID y otro dispositivo puede moverlo.
        let escribio = PrivateSessionMark.backfillIfNeeded(legacyIsGroupsOnly: false, hasCompletedOnboarding: true, d)

        #expect(escribio == false, "el backfill volvió a escribir sobre una marca que ya existía")
        #expect(PrivateSessionMark.raw(d) == false, """
            con el guard por VALOR (`raw != true`) en vez de por PRESENCIA, este backfill habría
            pisado la marca del dispositivo con un flag movido desde fuera. La marca es local.
            """)
    }

    @Test("MUTACIÓN: tras un cierre de sesión el backfill NO resucita la marca")
    func backfillDoesNotResurrectTheMarkAfterSignOut() {
        let f = Fixture()
        let d = f.defaults

        // Lo que hace el boot real, en su orden medido: `performSignOutWipeIfArmed` corre pre-mount
        // y llama a `clear()`, y su `resetPrefs()` borra además `hasCompletedOnboarding`.
        PrivateSessionMark.set(false, d)
        PrivateSessionMark.clear(d)

        // El arranque siguiente. Sin el gate, aquí se escribía `true` —el flag legacy también se fue,
        // así que `legacyIsGroupsOnly` es `false`— y la marca revivía en el mismo lanzamiento.
        let escribio = PrivateSessionMark.backfillIfNeeded(
            legacyIsGroupsOnly: false, hasCompletedOnboarding: false, d)

        #expect(escribio == false)
        #expect(PrivateSessionMark.raw(d) == nil, """
            el backfill resucitó la marca que el cierre de sesión acababa de borrar. Con eso la
            AUSENCIA no existe nunca en producción y el default estricto de `confirmedPrivateSession`
            deja de proteger nada: «Vaciar datos» podría ordenar a los demás dispositivos del Apple ID
            vaciarse en un teléfono que acaba de volver a «recién instalado».
            """)
        #expect(PrivateSessionMark.confirmedPrivateSession(d) == false)
    }

    @Test("MUTACIÓN: en instalación fresca el backfill no se inventa una sesión privada")
    func backfillDoesNotInventASessionOnAFreshInstall() {
        let f = Fixture()
        let d = f.defaults

        // Celda A: nadie se ha dado de alta todavía. `onboardingMode` ausente cae a `.full`, así que
        // sin el gate el backfill se convertía en el PRIMER escritor de la marca — contradiciendo el
        // invariante del tipo, que dice que se escribe cuando la sesión privada NACE.
        #expect(PrivateSessionMark.backfillIfNeeded(
            legacyIsGroupsOnly: false, hasCompletedOnboarding: false, d) == false)
        #expect(PrivateSessionMark.raw(d) == nil)
        // Y quien lea mientras tanto sigue protegido por el default conservador.
        #expect(PrivateSessionMark.hasPrivateSession(d) == true)
    }

    @Test("el backfill SÍ escribe en el parque existente (control positivo del gate)")
    func backfillStillWritesForTheExistingFleet() {
        let f = Fixture()
        let d = f.defaults

        #expect(PrivateSessionMark.backfillIfNeeded(
            legacyIsGroupsOnly: true, hasCompletedOnboarding: true, d) == true)
        #expect(PrivateSessionMark.raw(d) == false, """
            el gate de `hasCompletedOnboarding` se comió también el caso que el backfill existe para
            cubrir. Sin esta aserción, poner `guard false` arriba dejaría los otros dos tests verdes.
            """)
    }

    // MARK: - La frontera de M1 (la visita no se pronuncia sobre la sesión privada del dueño)

    @Test("MUTACIÓN: en sesión secundaria `set` NO escribe la marca del dueño")
    func secondarySessionCannotWriteTheOwnersMark() {
        let f = Fixture()
        let d = f.defaults

        PrivateSessionMark.set(true, d)                       // el dueño, con su vida personal
        SecondarySessionStore.activate(userID: "sub-visita", d)
        // Control del instrumento: `isActive` mira primero un override GLOBAL de tests. Si otro
        // fichero lo dejó puesto, este test mediría otra cosa y pasaría verde sin guard.
        #expect(SecondarySessionStore.isActive(d) == true, "el override global de M1 está pisando el fixture")

        PrivateSessionMark.set(false, d)

        #expect(PrivateSessionMark.raw(d) == true, """
            la key vive en el `UserDefaults.standard` que la visita COMPARTE con el dueño: un `false`
            escrito desde la sesión secundaria le diría al dueño que no tiene vida personal, y con eso
            su «Cerrar sesión» borraría sin esperar al export de iCloud.
            """)
    }

    @Test("MUTACIÓN: en sesión secundaria el backfill tampoco escribe")
    func secondarySessionCannotBackfill() {
        let f = Fixture()
        let d = f.defaults

        SecondarySessionStore.activate(userID: "sub-visita", d)
        #expect(SecondarySessionStore.isActive(d) == true, "el override global de M1 está pisando el fixture")

        #expect(PrivateSessionMark.backfillIfNeeded(legacyIsGroupsOnly: true, hasCompletedOnboarding: true, d) == false)
        #expect(PrivateSessionMark.raw(d) == nil, """
            el backfill entra por `set`, así que hereda su guard. Sin él, el primer arranque de una
            visita sellaría la celda del dueño a partir del flag que la visita tiene en memoria.
            """)
    }

    @Test("MUTACIÓN: en sesión secundaria las LECTURAS no contestan por el dueño")
    func secondarySessionReadsAreAboutTheVisitorNotTheOwner() {
        let f = Fixture()
        let d = f.defaults

        PrivateSessionMark.set(true, d)                       // el dueño, con su vida personal
        SecondarySessionStore.activate(userID: "sub-visita", d)
        #expect(SecondarySessionStore.isActive(d) == true, "el override global de M1 está pisando el fixture")

        #expect(PrivateSessionMark.hasPrivateSession(d) == false, """
            la visita leía la marca del DUEÑO. Con `true`, su «Vaciar datos» enseña la hoja completa
            —que nombra un corpus personal que su wipe no toca, porque solo borra los archivos
            `-Secondary`— y aterriza en el onboarding personal de otra persona.
            """)
        #expect(PrivateSessionMark.confirmedPrivateSession(d) == false)

        // Y la marca del dueño sigue intacta debajo: esto es un corte de LECTURA, no un borrado.
        #expect(PrivateSessionMark.raw(d) == true)
    }

    @Test("el guard de M1 NO alcanza a `clear`, y es deliberado")
    func secondarySessionDoesNotBlockClear() {
        let f = Fixture()
        let d = f.defaults

        PrivateSessionMark.set(true, d)
        SecondarySessionStore.activate(userID: "sub-visita", d)

        PrivateSessionMark.clear(d)

        #expect(PrivateSessionMark.raw(d) == nil, """
            borrar deja las dos lecturas en su lado conservador, así que no hay dirección en la que
            este camino pueda hacer daño — y el boot-wipe pre-mount corre sin saber de qué sesión
            viene. Un guard aquí dejaría marcas vivas tras un cierre.
            """)
    }
}

// MARK: - El cableado: quién lee cuál, y por qué no se pueden aplanar

@Suite("El eje 1: el reparto de las dos lecturas en producción")
struct PrivateSessionMarkWiringTests {

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // …/YalaTests/CloudSync
        .deletingLastPathComponent()   // …/YalaTests
        .deletingLastPathComponent()   // raíz

    /// Sin comentarios de línea: el reparto se explica en prosa en los dos ficheros, y contar la
    /// prosa haría que documentar el invariante lo rompiera (ya pasó en este repo).
    private static func code(_ path: String) throws -> String {
        let raw = try String(contentsOf: repoRoot.appendingPathComponent(path), encoding: .utf8)
        return raw.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    /// **La aserción que importa de todo este ticket.** Las tres decisiones de «Vaciar datos» salen del
    /// mismo eje, y dos de ellas fallan bien hacia `true`; la tercera —la que ORDENA a los demás
    /// dispositivos del Apple ID vaciarse— falla mal. Un refactor que las unifique «porque son la misma
    /// pregunta» no rompe ningún test de comportamiento: con la marca PUESTA las dos lecturas coinciden,
    /// así que toda la suite de `DestructiveScopeLogic` sigue verde. Lo único que lo caza es esto.
    @Test("MUTACIÓN: solo la señal al Apple ID lee `confirmedPrivateSession`")
    func onlyTheAppleIDSignalReadsTheConfirmedFlavour() throws {
        let vista = try Self.code("Yala/App/Views/Settings/UserDataResetView.swift")

        #expect(vista.contains("confirmedPrivateSession: PrivateSessionMark.confirmedPrivateSession()"), """
            la señal a los otros dispositivos del Apple ID dejó de leer la lectura estricta. Con
            `hasPrivateSession`, una marca ausente vacía el iPad privado del dueño de un móvil prestado.
            """)
        #expect(vista.contains("wipeOperation(\n            hasPrivateSession: PrivateSessionMark.hasPrivateSession()"), """
            el alcance de la hoja tiene que leer la lectura conservadora: barrer de más es el lado barato,
            y la hoja nombra todo lo que va a borrar antes de que nadie confirme.
            """)
        #expect(vista.contains("wipeLanding(\n            hasPrivateSession: PrivateSessionMark.hasPrivateSession()"))

        // El conteo va sobre TODO `Yala/`, no sobre esta vista: un segundo consumidor en
        // `ProfileView`, `CloudSessionSignOut` o `AccountDeletionService` es exactamente donde el
        // fallo alcanza datos de fuera, y medirlo aquí dentro lo habría dejado pasar en verde.
        #expect(Self.countInProduction("PrivateSessionMark.confirmedPrivateSession()") == 1, """
            `confirmedPrivateSession` tiene UN solo consumidor en toda la app. Si aparece un segundo,
            decide a conciencia si su fallo también alcanza datos fuera de este teléfono.
            """)
    }

    /// **Las dos muertes de la marca, pinneadas.** Sus vecinas literales en los dos ficheros ya lo
    /// están (`clearGroupsOnlyNeutralMount`, `clearPrivateChoseWithoutICloud`,
    /// `clearHandoverOnboardingMode`); sin esto, un mutante que borrara cualquiera de las dos líneas
    /// salía verde y la persona siguiente heredaba el eje del humano anterior.
    @Test("MUTACIÓN: la marca muere en los dos sitios que devuelven el teléfono a recién instalado")
    func theMarkDiesInBothHandoverPaths() throws {
        let boot = try Self.code("Yala/Utils/SwiftDataConfiguration.swift")
        #expect(boot.contains("PrivateSessionMark.clear(defaults)"), """
            el boot-wipe del cierre de sesión dejó de limpiar el eje: quien restaure su iCloud en este
            teléfono hereda el de quien se fue.
            """)

        let wipe = try Self.code("Yala/Utils/DataWipeService.swift")
        #expect(wipe.contains("PrivateSessionMark.clear(defaults)"), "el relevo de humano dejó de limpiar el eje")
        #expect(wipe.contains("if !SecondarySessionStore.isActive(defaults) {"), """
            el `clear` del relevo perdió su guard de M1. Ese camino es IN-SESSION y su cinturón deja
            pasar a una visita operativa: sin el guard, la visita borra la marca del DUEÑO.
            """)
    }

    /// La pantalla de vaciar decide el TEXTO y el ALCANCE con el mismo eje, o promete un borrado
    /// distinto del que ejecuta — que es el daño que `wipeOperation` existe para cerrar.
    @Test("MUTACIÓN: la copy de «Vaciar datos» sale del mismo eje que su alcance")
    func theWipeCopyReadsTheSameAxisAsItsScope() throws {
        let vista = try Self.code("Yala/App/Views/Settings/UserDataResetView.swift")
        #expect(vista.contains("PrivateSessionMark.hasPrivateSession()\n                                        ? L10n.Settings.resetDataDescription"), """
            la descripción de la pantalla volvió a leer el flag viejo mientras el alcance lee la marca.
            Divergen justo en el caso del eje: un `.groupInvite` llegado por el iCloud-KV a un teléfono
            privado leía «solo tu perfil y tus preferencias» sobre un `.wipeDataFull`.
            """)
        #expect(!vista.contains("sessionState.isGroupInviteMode\n                                        ?"))
    }

    /// El contrato del propio tipo: si alguien colapsa los dos defaults, el eje pierde una de sus dos
    /// direcciones de fallo y ningún test de comportamiento lo nota.
    @Test("MUTACIÓN: los dos defaults del tipo siguen siendo opuestos")
    func theTwoDefaultsStayOpposite() throws {
        let marca = try Self.code("Yala/Services/CloudSync/PrivateSessionMark.swift")
        #expect(marca.contains("raw(defaults) ?? true"), "`hasPrivateSession` perdió su default conservador")
        #expect(marca.contains("raw(defaults) ?? false"), "`confirmedPrivateSession` perdió su default estricto")
    }

    /// El backfill es lo único que escribe la marca del parque existente, y su entrada tiene que ser el
    /// `onboardingMode` LOCAL. Leerlo tras `PreferenceSyncService.bootstrap()` lo backfillearía con un
    /// valor mergeado del iCloud-KV del Apple ID — o sea, con el estado de OTRO dispositivo.
    @Test("MUTACIÓN: el backfill corre ANTES del merge del iCloud-KV")
    func backfillRunsBeforeTheKeyValueMerge() throws {
        let boot = try Self.code("Yala/App/AppBootstrapper.swift")
        let backfill = try #require(boot.range(of: "PrivateSessionMark.backfillIfNeeded("))
        let merge = try #require(boot.range(of: "PreferenceSyncService.shared.bootstrap()"))
        #expect(backfill.lowerBound < merge.lowerBound, """
            el backfill quedó DESPUÉS del merge del iCloud-KV: a partir de ahí `OnboardingMode.current()`
            puede traer el `.groupInvite` de otro dispositivo del mismo Apple ID, y la marca —que es
            LOCAL por diseño— nacería describiendo un teléfono que no es éste.
            """)
    }

    /// **El seam que envenena el simulador.** `PrivateSessionMark.set(false)` de
    /// `-uitest-group-invite` escribe en el dominio PERSISTENTE, y el prefijo `cloudSync.` —elegido
    /// para que la marca sobreviva a «Vaciar datos»— la deja fuera de `removeUserPreferenceKeys`, así
    /// que nada más en el árbol la borra. Sin la purga del bloque de `-uitest-reset`, la corrida
    /// siguiente arranca creyendo que no hay sesión privada, y el arranque MANUAL de Yala Dev en ese
    /// simulador queda igual — que es la víctima que nadie mira.
    @Test("MUTACIÓN: el bloque de `-uitest-reset` purga la marca, y ANTES de que el seam la escriba")
    func theUITestResetPurgesTheMark() throws {
        let boot = try Self.code("Yala/App/AppBootstrapper.swift")
        let purga = try #require(boot.range(of: "PrivateSessionMark.clear()"), """
            el bloque de `-uitest-reset` no purga el eje 1. Su vecina `onboardingMode` sí se repone
            ahí, y ésta es peor: el barrido de preferencias excluye `cloudSync.*` a propósito.
            """)
        let seam = try #require(boot.range(of: "PrivateSessionMark.set(false)"))
        #expect(purga.lowerBound < seam.lowerBound, """
            la purga quedó DESPUÉS del seam: borraría la marca que el propio `-uitest-group-invite`
            acaba de sembrar y esa corrida arrancaría sin la celda que pidió.
            """)
    }

    private static func count(_ needle: String, in haystack: String) -> Int {
        haystack.components(separatedBy: needle).count - 1
    }

    /// El mismo conteo pero sobre TODO el target de producción, que es el alcance que la aserción
    /// declara. Sin comentarios, por la misma razón que `code(_:)`.
    private static func countInProduction(_ needle: String) -> Int {
        let base = repoRoot.appendingPathComponent("Yala")
        guard let e = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else { return 0 }
        var total = 0
        for case let url as URL in e where url.pathExtension == "swift" {
            guard let raw = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let sinComentarios = raw.split(separator: "\n", omittingEmptySubsequences: false)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
                .joined(separator: "\n")
            total += count(needle, in: sinComentarios)
        }
        return total
    }

    /// Control del instrumento: si el recorrido del árbol se rompe, `countInProduction` devolvería 0
    /// y la aserción de arriba pasaría verde sin medir nada — la familia de «Executed 0 tests».
    @Test("control: el escáner de producción encuentra algo")
    func theProductionScannerActuallyFindsThings() {
        #expect(Self.countInProduction("PrivateSessionMark.hasPrivateSession()") == 9, """
            el eje 1 tiene NUEVE consumidores de la lectura conservadora. Si este número cambia, hay un
            constructor nuevo y hay que decidir con qué lectura contesta — y si el consumidor nuevo
            alcanza datos de FUERA de este teléfono, la lectura que le toca es la otra.
            """)
        #expect(Self.countInProduction("PrivateSessionMark.set(") == 9, """
            el eje 1 se escribe en NUEVE puntos. Un décimo es un alta o una baja nueva: decide de qué
            lado va, y corrige el conteo de la cabecera de `PrivateSessionMark`.
            """)
    }
}
