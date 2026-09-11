//
//  CloudSignOutFlowLogicTests.swift
//  YalaTests
//

import Foundation
import Testing

@testable import Yala

@Suite("Cerrar sesión — un camino por celda (ADR 2026-09-09, dos ejes)")
struct CloudSignOutFlowLogicTests {

    typealias Path = CloudSignOutFlowLogic.Path

    /// Defaults = la configuración de producción (canal de grupos compilado, sesión privada, sin visita).
    private func path(_ mode: StorageMode, secondary: Bool = false, session: Bool = false,
                      groups: Bool = true, privateSession: Bool = true) -> Path {
        CloudSignOutFlowLogic.path(
            for: mode, secondarySessionActive: secondary, hasLiveSession: session,
            groupsBackendEnabled: groups, hasPrivateSession: privateSession)
    }

    @Test("C · privada sin sesión en la nube → cierre privado")
    func privateWithoutCloud() {
        #expect(path(.icloud) == .privateSignOut)
    }

    @Test("D · privada + sesión de grupos → «equipo», no «salir solo de grupos»")
    func privateWithGroupsSession() {
        #expect(path(.icloud, session: true) == .privateWithGroupsSignOut)
    }

    @Test("E · nube completa → cierre de la nube, sea cual sea el resto")
    func cloud() {
        for privateSession in [true, false] {
            for session in [true, false] {
                #expect(path(.cloud, session: session, privateSession: privateSession) == .cloudSecureSignOut)
            }
        }
    }

    @Test("F · sesión en la nube solo grupos, sin sesión privada → cierre solo-grupos")
    func groupsOnlyWithoutPrivate() {
        #expect(path(.icloud, session: true, privateSession: false) == .groupsOnlySignOut)
    }

    /// El solo-grupos legado que ya no tiene sesión («5a») tampoco tiene vida privada: cierra por el camino
    /// de F, que borra lo local. La hoja privada le habría dicho «tus datos siguen en iCloud», que es falso.
    @Test("sin sesión privada, el camino es el de solo grupos, haya sesión en la nube o no")
    func noPrivateSession_isGroupsOnly_withOrWithoutSession() {
        #expect(path(.icloud, session: false, privateSession: false) == .groupsOnlySignOut)
        #expect(path(.icloud, session: true, groups: false, privateSession: false) == .groupsOnlySignOut)
    }

    @Test("sin el canal de grupos compilado, una sesión viva no convierte a la privada en «equipo»")
    func noGroupsCapability_isPrivate() {
        #expect(path(.icloud, session: true, groups: false) == .privateSignOut)
    }

    /// M1 — la trampa de la atomicidad: en secundaria el modo EFECTIVO es `.cloud`; sin esta rama el
    /// cierre de la invitada iría a `.cloudSecureSignOut` → `armSignOutWipe` → el boot borraría el
    /// YalaModel del DUEÑO.
    @Test("la visita M1 gana sobre cualquier celda")
    func secondaryWinsEverything() {
        for mode in [StorageMode.icloud, .cloud] {
            for session in [true, false] {
                for privateSession in [true, false] {
                    #expect(path(mode, secondary: true, session: session, privateSession: privateSession)
                            == .secondaryCloudSignOut)
                }
            }
        }
    }

    /// La puerta de quiescencia de los cierres que drenan grupos. Sin espejo no hay import con el que
    /// chocar: el término del mount es la corrección del cierre solo-grupos, que con iCloud Drive activo
    /// esperaba un «primer import» que un store neutro no emite nunca.
    @Test("la puerta de quiescencia: sin espejo es seguro siempre; con espejo y cuenta, solo asentado")
    func personalSaveSafety() {
        typealias L = CloudSignOutFlowLogic
        for account in [true, false] {
            for first in [true, false] {
                for quiet in [true, false] {
                    #expect(L.isPersonalSaveSafe(mountAttachesMirror: false, accountAvailable: account,
                                                 firstImportCompleted: first, importQuiescent: quiet))
                }
            }
        }
        #expect(L.isPersonalSaveSafe(mountAttachesMirror: true, accountAvailable: false,
                                     firstImportCompleted: false, importQuiescent: false))
        #expect(L.isPersonalSaveSafe(mountAttachesMirror: true, accountAvailable: true,
                                     firstImportCompleted: true, importQuiescent: true))
        #expect(!L.isPersonalSaveSafe(mountAttachesMirror: true, accountAvailable: true,
                                      firstImportCompleted: false, importQuiescent: true),
                "`isImportQuiescent` a secas es true ANTES del primer import: señal prematura en un restore")
        #expect(!L.isPersonalSaveSafe(mountAttachesMirror: true, accountAvailable: true,
                                      firstImportCompleted: true, importQuiescent: false))
    }

    @Test("las cinco salidas son alcanzables y distintas: ninguna celda comparte camino")
    func everyCellHasItsOwnPath() {
        let cells: [Path] = [
            path(.icloud),                                          // C
            path(.icloud, session: true),                           // D
            path(.cloud, session: true),                            // E
            path(.icloud, session: true, privateSession: false),    // F
            path(.icloud, secondary: true),                         // M1
        ]
        #expect(Set(cells.map { "\($0)" }).count == 5, "\(cells)")
    }

    /// El reparto de los tres cierres por archivos, por tabla. La review adversarial midió que invertir un solo
    /// término —C sin esperar al export, D sin subir sus grupos— no lo cazaba ningún test. C y D esperan salvo
    /// el «sin copia» confirmado; F espera solo si su store espeja; la nube y la visita no pasan por aquí.
    @Test("quién sube grupos y quién espera al export: la tabla entera")
    func exitPlan_table() {
        typealias L = CloudSignOutFlowLogic
        for mirror in [true, false] {
            #expect(L.exitPlan(path: .privateSignOut, confirmedWithoutICloudCopy: false, mountAttachesMirror: mirror)
                    == .init(kind: .privateOnly, waitsForExport: true))
            #expect(L.exitPlan(path: .privateSignOut, confirmedWithoutICloudCopy: true, mountAttachesMirror: mirror)
                    == .init(kind: .privateOnly, waitsForExport: false))
            #expect(L.exitPlan(path: .privateWithGroupsSignOut, confirmedWithoutICloudCopy: false, mountAttachesMirror: mirror)
                    == .init(kind: .privateWithGroups, waitsForExport: true))
            #expect(L.exitPlan(path: .privateWithGroupsSignOut, confirmedWithoutICloudCopy: true, mountAttachesMirror: mirror)
                    == .init(kind: .privateWithGroups, waitsForExport: false))
            for noCopy in [true, false] {
                #expect(L.exitPlan(path: .groupsOnlySignOut, confirmedWithoutICloudCopy: noCopy, mountAttachesMirror: mirror)
                        == .init(kind: .groupsOnly, waitsForExport: mirror))
                #expect(L.exitPlan(path: .cloudSecureSignOut, confirmedWithoutICloudCopy: noCopy,
                                   mountAttachesMirror: mirror) == nil)
                #expect(L.exitPlan(path: .secondaryCloudSignOut, confirmedWithoutICloudCopy: noCopy,
                                   mountAttachesMirror: mirror) == nil)
            }
        }
    }

    @Test("solo la privada sin cuenta en la nube no sube grupos")
    func exitKind_pushesGroups() {
        #expect(!CloudSignOutFlowLogic.ExitKind.privateOnly.pushesGroups)
        #expect(CloudSignOutFlowLogic.ExitKind.privateWithGroups.pushesGroups)
        #expect(CloudSignOutFlowLogic.ExitKind.groupsOnly.pushesGroups)
    }
}

@Suite("Cerrar sesión — veredicto del push-all (.cloud)")
struct CloudSignOutPushAllVerdictTests {

    @Test
    func outboxEmpty_isDrained_regardlessOfCycleOutcome() {
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 0, cycleOutcome: .completed, iteration: 1, maxIterations: 10
        ) == .drained)
        // Ciclo con error pero outbox ya vacío → drained igual (el objetivo se cumplió).
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 0, cycleOutcome: .transient, iteration: 3, maxIterations: 10
        ) == .drained)
    }

    @Test
    func pendingWithSuccessfulCycle_keepsIterating() {
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 12, cycleOutcome: .completed, iteration: 2, maxIterations: 10
        ) == nil)
        // `.coalesced` (ciclo en vuelo, sin señal de fallo) también cuenta como éxito.
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 12, cycleOutcome: .coalesced, iteration: 2, maxIterations: 10
        ) == nil)
    }

    @Test
    func pendingWithFailedTransientCycle_blocksTransient() {
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 5, cycleOutcome: .transient, iteration: 1, maxIterations: 10
        ) == .blocked(pendingCount: 5, reason: .transient))
    }

    @Test
    func pendingWithSessionOrAccountFailure_blocksPermanent() {
        // La sesión caducada lleva su motivo propio desde el paso 9 (el aviso pide volver a entrar); el camino
        // `.cloud` lo sigue mostrando como permanente porque re-mapea todo bloqueo a `.permanent`.
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 5, cycleOutcome: .sessionExpired, iteration: 1, maxIterations: 10
        ) == .blocked(pendingCount: 5, reason: .sessionExpired))
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 7, cycleOutcome: .accountUnavailable, iteration: 2, maxIterations: 10
        ) == .blocked(pendingCount: 7, reason: .permanent))
    }

    @Test
    func pendingAtMaxIterations_blocksTransient_evenWithSuccessfulCycle() {
        // Tope alcanzado con ciclo sano pero pendientes → transitorio (aún drenando).
        #expect(CloudSignOutFlowLogic.pushAllVerdict(
            livePendingCount: 3, cycleOutcome: .completed, iteration: 10, maxIterations: 10
        ) == .blocked(pendingCount: 3, reason: .transient))
    }
}

@Suite("Cerrar sesión — clasificación transitorio/permanente (H-2026-07-18-6)")
struct CloudSignOutClassifyTests {

    @Test
    func sessionOrAccountFailure_isPermanent() {
        // Las dos son permanentes, pero la sesión caducada tiene su motivo propio desde el paso 9: se arregla
        // volviendo a entrar, y el aviso tiene que decirlo en vez de mandar a revisar la conexión.
        #expect(CloudSignOutFlowLogic.classify(.sessionExpired) == .sessionExpired)
        #expect(CloudSignOutFlowLogic.classify(.accountUnavailable) == .permanent)
    }

    @Test
    func networkOrCoalescedOrCompleted_isTransient() {
        #expect(CloudSignOutFlowLogic.classify(.transient) == .transient)
        #expect(CloudSignOutFlowLogic.classify(.completed) == .transient)
        #expect(CloudSignOutFlowLogic.classify(.coalesced) == .transient)
    }
}

@Suite("Cerrar sesión solo-grupos — decisión de retry con presupuesto (H-2026-07-18-6)")
struct GroupsSignOutRetryDecisionTests {

    private let budget = GroupsSignOutRetryDecision.budgetSeconds  // 45

    @Test
    func permanent_surfacesImmediately_regardlessOfElapsed() {
        // La sesión caducada (paso 9) se trata igual: sin sesión, esperar no sube nada.
        for reason in [CloudSignOutFlowLogic.BlockReason.permanent, .sessionExpired] {
            #expect(GroupsSignOutRetryDecision.decide(
                elapsedSeconds: 0, budgetSeconds: budget, reason: reason) == .surfacePermanent)
            // Aunque quede presupuesto, un permanente jamás reintenta.
            #expect(GroupsSignOutRetryDecision.decide(
                elapsedSeconds: 100, budgetSeconds: budget, reason: reason) == .surfacePermanent)
        }
    }

    @Test
    func transient_withinBudget_retries() {
        #expect(GroupsSignOutRetryDecision.decide(
            elapsedSeconds: 0, budgetSeconds: budget, reason: .transient)
            == .retryAfter(seconds: GroupsSignOutRetryDecision.retryIntervalSeconds))
        #expect(GroupsSignOutRetryDecision.decide(
            elapsedSeconds: 44, budgetSeconds: budget, reason: .transient)
            == .retryAfter(seconds: GroupsSignOutRetryDecision.retryIntervalSeconds))
    }

    @Test
    func transient_budgetExhausted_surfacesTransient() {
        #expect(GroupsSignOutRetryDecision.decide(
            elapsedSeconds: 46, budgetSeconds: budget, reason: .transient) == .surfaceTransient)
    }

    @Test
    func transient_atExactBudgetBoundary_surfacesTransient() {
        // elapsed == budget: el `<` es ESTRICTO → ya no reintenta (borde, no `retryAfter`).
        #expect(GroupsSignOutRetryDecision.decide(
            elapsedSeconds: budget, budgetSeconds: budget, reason: .transient) == .surfaceTransient)
    }
}

/// **La invitada tiene DOS outboxes y el cierre solo empujaba uno.**
///
/// El camino `.cloud` empuja el personal Y el de grupos, y re-verifica los dos antes de soltar
/// credenciales. El camino secundario (M1) empujaba solo el personal — mientras el wipe de arranque
/// borra igual `YalaGroups-Secondary` y `YalaSyncMeta-Secondary`, que es donde vive `GroupSyncOutbox`,
/// y la purga de frontera se lleva además el espejo del App Group, que era la red de rehidratación.
/// ⇒ los últimos gastos de grupo de la visita podían quedarse sin subir, y su copia local moría con la
/// sesión.
///
/// **Y el comentario que lo justificaba era falso**: decía que en secundaria el canal de Grupos «ni
/// corre», cuando con el canal encendido la sesión secundaria lo corre sobre su propio store — que es
/// exactamente la configuración en la que ese archivo existe.
///
/// Source-scan porque `performSecondaryCloudSignOut` es privado y su camino exige runtime de red: lo
/// que hay que fijar es que el paso EXISTA y que la re-verificación cuente los dos, y eso no se puede
/// afirmar desde fuera de otra forma. Molde `SecondaryOwnerDomainWiringTests`.
@Suite("Cerrar sesión — la sesión secundaria empuja los DOS outboxes (source-scan)")
struct SecondarySignOutPushesBothOutboxesTests {

    private static func body(of marker: String, in source: String) throws -> String {
        let start = try #require(source.range(of: marker))
        var depth = 1
        var out = ""
        for ch in source[start.upperBound...] {
            if ch == "{" { depth += 1 }
            if ch == "}" { depth -= 1; if depth == 0 { break } }
            out.append(ch)
        }
        return out
    }

    private static func signOutSource() throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // YalaTests/
            .deletingLastPathComponent()  // repo root
        return try String(
            contentsOf: root.appendingPathComponent("Yala/Services/CloudSync/CloudSessionSignOut.swift"),
            encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    @Test("el camino secundario hace push-all de GRUPOS antes del teardown")
    func secondaryPushesGroupsOutbox() throws {
        let secondary = try Self.body(
            of: "private func performSecondaryCloudSignOut(context: ModelContext) async {",
            in: Self.signOutSource())

        let push = try #require(
            secondary.range(of: "pushAllPendingGroupsForSignOut(context: context)"), """
            El cierre de la sesión secundaria dejó de empujar el outbox de GRUPOS. El wipe de arranque \
            borra `YalaGroups-Secondary` y la purga se lleva el espejo del App Group: lo que no suba \
            aquí no sube nunca.
            """)
        let teardown = try #require(secondary.range(of: "GroupsSyncClient.shared.teardownForSignOut()"))
        #expect(push.lowerBound < teardown.lowerBound, """
            El push-all quedó DESPUÉS del teardown: la guardia de generación aborta el ciclo, así que \
            empujar ahí no empuja nada (mismo racional que el paso 2 del camino `.cloud`).
            """)
    }

    @Test("la re-verificación previa a soltar credenciales cuenta los DOS outboxes")
    func secondaryReverifiesBoth() throws {
        let secondary = try Self.body(
            of: "private func performSecondaryCloudSignOut(context: ModelContext) async {",
            in: Self.signOutSource())

        #expect(secondary.contains("controller.livePendingUploadCount()"))
        #expect(secondary.contains("Self.liveGroupsPendingCount(context: context)"), """
            La re-verificación de S2 volvió a mirar solo el outbox personal: una fila de grupos encolada \
            por un save concurrente durante el push-all pasaría el guard y moriría en el wipe.
            """)
    }
}

/// **Cuando la invitada se va y algo la bloquea, ya no se le dice siempre «revisa tu conexión».**
///
/// Las salidas de bloqueo del camino secundario emitían SIEMPRE `reason: .permanent`, y el `reason`
/// verdadero venía ya clasificado desde los dos push-all: el consumidor lo descartaba. Consecuencia:
/// un corte de red de dos segundos le decía que revisara la conexión, el presupuesto de 45 s de
/// `GroupsSignOutRetryDecision` no la alcanzaba, y `waitingForPending` no se encendía nunca ⇒ tampoco
/// veía el caption de espera.
///
/// Y sobre eso, la decisión del owner del 2026-09-03: el aviso le ofrece **salir igualmente**, porque
/// está en el móvil de otra persona y hay que devolverlo.
///
/// Source-scan por la misma razón que el suite hermano: `performSecondaryCloudSignOut` es privado y su
/// camino exige runtime de red. Lo que hay que fijar es la ESTRUCTURA — que el reason se propague, que
/// el bucle no envuelva el teardown, y que la salida forzada arme el wipe secundario y no otro.
@Suite("Cerrar sesión — la visita distingue el bloqueo transitorio y puede salir igualmente")
struct SecondarySignOutBlockClassificationTests {

    private static func body(of marker: String, in source: String) throws -> String {
        let start = try #require(source.range(of: marker))
        var depth = 1
        var out = ""
        for ch in source[start.upperBound...] {
            if ch == "{" { depth += 1 }
            if ch == "}" { depth -= 1; if depth == 0 { break } }
            out.append(ch)
        }
        return out
    }

    private static func source(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // YalaTests/
            .deletingLastPathComponent()  // repo root
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static func secondaryBody() throws -> String {
        try body(
            of: "private func performSecondaryCloudSignOut(context: ModelContext) async {",
            in: source("Yala/Services/CloudSync/CloudSessionSignOut.swift"))
    }

    // MARK: - El gate puro de la salida forzada

    @Test("«salir igualmente» se ofrece SOLO en la sesión de visita y SOLO con algo pendiente")
    func forcedExitGate() {
        #expect(CloudSignOutFlowLogic.offersForcedSecondaryExit(
            isSecondaryActive: true, pendingCount: 3))
        // En el móvil propio no hay ningún teléfono que devolver: la salida no se ofrece, y el alert
        // conserva su único botón de siempre.
        #expect(!CloudSignOutFlowLogic.offersForcedSecondaryExit(
            isSecondaryActive: false, pendingCount: 3))
        // `pendingCount: 0` es el bloqueo que NO viene de datos sin subir (el guard sin controller):
        // ofrecer "salir igualmente" ahí prometería descartar algo que no existe.
        #expect(!CloudSignOutFlowLogic.offersForcedSecondaryExit(
            isSecondaryActive: true, pendingCount: 0))
        #expect(!CloudSignOutFlowLogic.offersForcedSecondaryExit(
            isSecondaryActive: false, pendingCount: 0))
    }

    // MARK: - La clasificación del bloqueo (pieza 2)

    @Test("el camino secundario decide con GroupsSignOutRetryDecision, no con `.permanent` fijo")
    func secondaryClassifiesBlock() throws {
        let secondary = try Self.secondaryBody()
        #expect(secondary.contains("GroupsSignOutRetryDecision.decide("), """
            El cierre de la sesión secundaria volvió a emitir el bloqueo sin clasificarlo. El `reason` \
            llega ya clasificado desde los dos push-all: descartarlo es lo que hacía que un corte de red \
            de dos segundos se presentara como «revisa tu conexión».
            """)
        #expect(secondary.contains("reason: .transient"), """
            Ninguna salida del camino secundario emite ya `.transient` ⇒ el copy «Un momento más» y el \
            caption de espera vuelven a ser inalcanzables para la invitada.
            """)
        #expect(secondary.contains("waitingForPending = true"), """
            El camino secundario dejó de encender `waitingForPending`: durante los reintentos la persona \
            mira un spinner mudo, que es el síntoma que H-2026-07-18-6 arregló en el otro camino.
            """)
    }

    @Test("el bucle de reintento NO envuelve el teardown")
    func retryLoopStopsBeforeTeardown() throws {
        let secondary = try Self.secondaryBody()
        let loop = try #require(secondary.range(of: "pushLoop: while true {"))
        let breakOut = try #require(secondary.range(of: "break pushLoop"))
        let teardown = try #require(secondary.range(of: "CloudSyncRuntime.shared?.teardownGuestSession()"))
        #expect(breakOut.lowerBound < teardown.lowerBound)
        #expect(loop.lowerBound < teardown.lowerBound, """
            El teardown quedó DENTRO del bucle de reintento. Después de él no hay nada que drenar \
            —`teardownGuestSession` deja el motor con `currentUserID = nil`, el mirror purgado y la \
            cadencia cancelada—, así que reintentar ahí quema los 45 s del presupuesto para llegar al \
            mismo bloqueo, con la persona esperando para devolver el móvil.
            """)
    }

    @Test("la re-verificación posterior al teardown se queda en `.permanent` a propósito")
    func postTeardownResidualStaysPermanent() throws {
        let secondary = try Self.secondaryBody()
        let teardown = try #require(secondary.range(of: "CloudSyncRuntime.shared?.teardownGuestSession()"))
        let tail = String(secondary[teardown.upperBound...])
        #expect(tail.contains("reason: .permanent"), """
            El residual de S2 pasó a `.transient`. Es el único bloqueo del camino que NO es reintentable: \
            los dos teardowns ya corrieron, así que ni un reintento interno ni el del usuario pueden \
            drenar la fila que acaba de aparecer.
            """)
        #expect(!tail.contains("GroupsSignOutRetryDecision.decide("))
    }

    // MARK: - La salida forzada (pieza 3)

    @Test("la salida forzada exige un bloqueo vivo Y una sesión secundaria")
    func forcedExitIsGuarded() throws {
        let forced = try Self.body(
            of: "func exitSecondaryDiscardingPending() async {",
            in: Self.source("Yala/Services/CloudSync/CloudSessionSignOut.swift"))
        #expect(forced.contains("guard case .blocked = phase else { return }"), """
            Sin el guard de fase, «salir igualmente» sería invocable sin que ningún bloqueo lo haya \
            ofrecido: descartaría pendientes que el push-all todavía podía subir.
            """)
        #expect(forced.contains("guard SecondarySessionStore.isActive() else { return }"), """
            Sin el guard de sesión, esta función armaría el wipe SECUNDARIO en un device que no está en \
            sesión de visita.
            """)
    }

    @Test("la salida forzada arma el wipe SECUNDARIO y no toca los archivos del dueño")
    func forcedExitArmsSecondaryWipe() throws {
        let forced = try Self.body(
            of: "func exitSecondaryDiscardingPending() async {",
            in: Self.source("Yala/Services/CloudSync/CloudSessionSignOut.swift"))
        #expect(forced.contains("SecondarySessionStore.armWipe()"))
        // `armSignOutWipe` es el del camino `.cloud`: borra los archivos del DUEÑO y devuelve el device
        // a "recién instalado". Aquí sería catastrófico — la invitada se llevaría los datos del anfitrión.
        #expect(!forced.contains("StorageModePersistence.armSignOutWipe()"), """
            La salida forzada de la visita armó el wipe del camino `.cloud`: eso borra los archivos del \
            DUEÑO del móvil, no los de la invitada.
            """)
        // Orden congelado: credenciales ANTES del arm (el arm es el disparador y va último).
        let signOut = try #require(forced.range(of: "CloudAuthService.shared.signOut()"))
        let arm = try #require(forced.range(of: "SecondarySessionStore.armWipe()"))
        #expect(signOut.lowerBound < arm.lowerBound)
        // Y sin push-all: los dos acaban de fallar, reintentarlos aquí es lo que la persona ya descartó.
        #expect(!forced.contains("pushAllPendingForSignOut()"))
        #expect(!forced.contains("pushAllPendingGroupsForSignOut("))
    }

    // MARK: - El cableado de la vista

    @Test("el aviso decide por el `pendingCount` del bloqueo que está mostrando")
    func profileViewWiresTheGate() throws {
        let profile = try Self.source("Yala/App/Views/Profile/ProfileView.swift")
        #expect(profile.contains("CloudSignOutFlowLogic.offersForcedSecondaryExit("), """
            ProfileView dejó de consultar el gate: o esconde la salida a la invitada, o la ofrece en el \
            móvil del dueño. Las dos son regresiones del mismo cableado.
            """)
        #expect(profile.contains("isSecondaryActive: SecondarySessionStore.isActive(), pendingCount: pending)"))
        #expect(profile.contains("await CloudSessionSignOut.shared.exitSecondaryDiscardingPending()"))
        // Los DOS alerts comparten los botones: si uno se quedara con el "OK" pelado, la invitada
        // bloqueada por un transitorio seguiría sin salida.
        #expect(profile.components(separatedBy: "signOutBlockedButtons").count - 1 >= 3, """
            Los dos alerts de bloqueo dejaron de compartir sus botones. El transitorio es JUSTO el caso \
            que más le pasa a la invitada: si ése se queda sin «salir igualmente», el fix no la alcanza.
            """)
    }
}

/// **Los cierres que borran por ARCHIVOS esperan al export y no se llevan nada sin contarlo: esa es toda
/// la seguridad del paso 9.**
///
/// Source-scan por la misma razón que las suites de arriba: el coordinador es privado y su camino exige
/// singletons de red y del espejo. Lo que hay que fijar es el ORDEN — los grupos antes de la espera, la
/// espera antes del arm, el último recuento sin `await` hasta el arm — y que ningún cierre borre filas.
@Suite("Cerrar sesión privada — espera el export y borra por archivos (source-scan)")
struct PrivateSignOutWiringTests {

    private static func source(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // YalaTests/
            .deletingLastPathComponent()  // repo root
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static func body(of marker: String, in source: String) throws -> String {
        let start = try #require(source.range(of: marker), "no se encontró `\(marker)`")
        var depth = 1
        var out = ""
        for ch in source[start.upperBound...] {
            if ch == "{" { depth += 1 }
            if ch == "}" { depth -= 1; if depth == 0 { break } }
            out.append(ch)
        }
        return out
    }

    private static let signOutPath = "Yala/Services/CloudSync/CloudSessionSignOut.swift"
    private static let performMarker =
        "private func performSessionExit(context: ModelContext, plan: CloudSignOutFlowLogic.ExitPlan) async {"
    private static let finalizeMarker =
        "private func finalizeSessionExit(context: ModelContext, kind: CloudSignOutFlowLogic.ExitKind, export: ExportPolicy) async {"
    private static let armMarker =
        "private func armAfterCredentials(context: ModelContext, kind: CloudSignOutFlowLogic.ExitKind, export: ExportPolicy) async {"

    @Test("los grupos suben ANTES de la espera, y la espera va ANTES del borrado")
    func groupsThenExportThenWipe() throws {
        let perform = try Self.body(of: Self.performMarker, in: Self.source(Self.signOutPath))
        let groupsCheck = try #require(perform.range(of: "if blockIfGroupsCannotUpload(context: context, kind: plan.kind) { return }"), """
            La privada dejó de mirar sus grupos sin subir: el boot-wipe borraría el outbox de una sesión caducada.
            """)
        let push = try #require(perform.range(of: "await pushGroupsForSignOut(context: context)"))
        let gate = try #require(perform.range(of: "await confirmExportOrBlock(context: context, kind: plan.kind, credentialsReleased: false)"), """
            El cierre dejó de esperar al export de iCloud: un cambio guardado hace segundos se borraría sin \
            haber subido.
            """)
        let finalize = try #require(perform.range(of: "await finalizeSessionExit("))
        #expect(groupsCheck.lowerBound < push.lowerBound)
        #expect(push.lowerBound < gate.lowerBound)
        #expect(gate.lowerBound < finalize.lowerBound)
    }

    /// Con el espejo montado, borrar FILAS exporta los deletes a iCloud: destruiría la copia que el cierre
    /// promete conservar. Ningún cierre del coordinador puede llamar al wipe por filas.
    @Test("ningún cierre de sesión borra filas")
    func noRowWipeAnywhere() throws {
        #expect(!(try Self.source(Self.signOutPath)).contains("wipeAllUserData"))
    }

    /// Lo que se escribe mientras se cierra la sesión (las suspensiones de `signOut()` y del push token)
    /// tiene que contarse: el último recuento va DESPUÉS de soltar la sesión y no hay ni un `await` entre él y
    /// el arm, en los dos caminos que lo hacen — la espera normal y la pérdida aceptada, que vuelve a avisar
    /// si hay más de lo que se aceptó.
    @Test("el último recuento va pegado al arm, sin suspensiones de por medio")
    func finalCountIsGluedToTheArm() throws {
        let source = try Self.source(Self.signOutPath)
        let finalize = try Self.body(of: Self.finalizeMarker, in: source)
        let signOut = try #require(finalize.range(of: "await CloudAuthService.shared.signOut()"))
        let handOff = try #require(finalize.range(of: "await armAfterCredentials(context: context, kind: kind, export: export)"))
        #expect(signOut.lowerBound < handOff.lowerBound, "el recuento final tiene que ir DESPUÉS de soltar la sesión")
        let arm = try Self.body(of: Self.armMarker, in: source)
        let armCall = try #require(arm.range(of: "StorageModePersistence.armSignOutWipe()"))
        for finalCount in ["if Self.pendingPersonalExportCount(context: context) == 0 { break }",
                           "let now = Self.pendingPersonalExportCount(context: context)"] {
            let count = try #require(arm.range(of: finalCount), "falta el recuento `\(finalCount)`")
            #expect(count.lowerBound < armCall.lowerBound)
            #expect(!String(arm[count.upperBound..<armCall.lowerBound]).contains("await"), """
                Hay una suspensión entre el recuento y el arm: lo que se escriba en ella muere con el wipe sin \
                haberse contado.
                """)
        }
    }

    /// La re-verificación de grupos va tras la segunda subida y antes de soltar credenciales; el consent se
    /// olvida antes de `signOut()` (CR-2), y el arm es el disparador: va el último.
    @Test("grupos: segunda subida, residual, consent y credenciales en su orden")
    func groupsTailOrder() throws {
        let tail = try Self.body(of: Self.finalizeMarker, in: Self.source(Self.signOutPath))
        let push = try #require(tail.range(of: "await pushGroupsForSignOut(context: context)"))
        let teardown = try #require(tail.range(of: "GroupsSyncClient.shared.teardownForSignOut()"))
        let residual = try #require(tail.range(of: "Self.liveGroupsPendingCount(context: context)"))
        let consent = try #require(tail.range(of: "GroupsConsentState.clear()"))
        let signOut = try #require(tail.range(of: "await CloudAuthService.shared.signOut()"))
        #expect(push.lowerBound < teardown.lowerBound)
        #expect(teardown.lowerBound < residual.lowerBound)
        #expect(residual.lowerBound < consent.lowerBound)
        #expect(consent.lowerBound < signOut.lowerBound)
    }

    /// Sin sesión privada que conservar, el store de grupos se olvida con la sesión; en la privada sin
    /// sesión (C) solo si guarda filas del canal backend. Y ninguno de estos cierres intenta el swap.
    @Test("el store de grupos entra en el borrado por su regla, y el swap sigue siendo solo de la nube")
    func groupsMarkerRule_andNoSwap() throws {
        let source = try Self.source(Self.signOutPath)
        let finalize = try Self.body(of: Self.finalizeMarker, in: source)
        let arm = try Self.body(of: Self.armMarker, in: source)
        let groupsCheck = try #require(arm.range(of: "if blockIfGroupsCannotUpload(context: context, kind: kind) { return }"), """
            El último tramo dejó de mirar los grupos sin subir de la privada: una fila encolada durante la \
            espera moriría con el wipe.
            """)
        let marker = try #require(arm.range(of: "let forgetsGroups = kind.pushesGroups || Self.hasBackendGroupRows(context: context)"))
        #expect(groupsCheck.lowerBound < marker.lowerBound)
        #expect(arm.contains("if forgetsGroups && CloudSyncFlags.groupsBackendCompiledCapability {"))
        // Solo F suelta su `.groupInvite` del iCloud KV, y lo hace antes de armar.
        #expect(arm.contains("if kind == .groupsOnly {\n            DataWipeService.releaseGroupsOnlyOnboardingModeFromICloudKV()"), """
            El cierre solo-grupos dejó de soltar su modo del iCloud KV: la vida siguiente de este teléfono \
            nacería dentro de la shell de grupos.
            """)
        let tail = finalize + arm
        #expect(!tail.contains("attemptSignOutSwap"))
        #expect(!tail.contains("armGroupsOnlyWipe()"))
        #expect(!tail.contains("purgeGroupsSyncState("), """
            Volvió la purga en sesión: es un `save()` sobre el contexto compartido y el boot-wipe ya borra \
            el archivo de sync-meta.
            """)
    }

    @Test("la salida de emergencia exige el bloqueo del export vivo y vuelve a avisar si hay más")
    func emergencyExitIsGuarded() throws {
        let source = try Self.source(Self.signOutPath)
        let exit = try Self.body(of: "func exitDiscardingUnconfirmed(context: ModelContext) async {", in: source)
        #expect(exit.contains("guard case .blocked(let shown, .exportUnconfirmed) = phase else { return }"), """
            Sin el guard, «Cerrar sesión igualmente» borraría sin que ningún aviso lo haya ofrecido.
            """)
        #expect(exit.contains("now > accepted"), "entraron más cambios que los avisados: hay que volver a avisar")
        // La cifra aceptada viaja hasta el arm por los DOS caminos, antes y después de soltar la sesión…
        #expect(exit.contains("await armAfterCredentials(context: context, kind: blocked.kind, export: .acceptLoss(upTo: accepted))"))
        #expect(exit.contains("await finalizeSessionExit(context: context, kind: blocked.kind, export: .acceptLoss(upTo: accepted))"))
        // …y allí se vuelve a contar, pegado al arm.
        let arm = try Self.body(of: Self.armMarker, in: source)
        #expect(arm.contains("if now.map({ $0 > accepted }) ?? true {"))
    }

    /// «Esperar» sigue esperando y cierra solo al llegar a cero. Volver a `.idle` cancelaba el cierre sin
    /// decirlo y, tras soltar la sesión, dejaba el dispositivo sin sesión y sin borrado (review adversarial).
    @Test("«Esperar» retoma la espera donde se paró, sin volver a empezar el cierre")
    func waitResumesWhereItStopped() throws {
        let source = try Self.source(Self.signOutPath)
        let resume = try Self.body(of: "func resumeWaitingForExport(context: ModelContext) async {", in: source)
        #expect(resume.contains("guard case .blocked(_, .exportUnconfirmed) = phase else { return }"))
        #expect(resume.contains("await armAfterCredentials(context: context, kind: blocked.kind, export: .confirm)"))
        #expect(resume.contains("await finalizeSessionExit(context: context, kind: blocked.kind, export: .confirm)"))
        let profile = try Self.source("Yala/App/Views/Profile/ProfileView.swift")
        let waitID = try #require(profile.range(of: ".accessibilityIdentifier(\"signout_export_wait\")"))
        let waitButton = String(profile[..<waitID.lowerBound].suffix(220))
        #expect(waitButton.contains("resumeWaitingForExport(context: modelContext)"), """
            El «Esperar» del aviso del export tiene que retomar la espera, no cerrar el aviso con \
            `acknowledgeBlocked()`.
            """)
        #expect(!waitButton.contains("acknowledgeBlocked()"))
    }

    /// La vista elige la hoja y el coordinador el borrado: si leyeran ejes distintos, la hoja prometería
    /// otro borrado. Y el coordinador no ejecuta una celda distinta de la confirmada.
    @Test("la vista y el coordinador resuelven la misma celda, y la confirmada manda")
    func viewAndCoordinatorShareTheCell() throws {
        let profile = try Self.source("Yala/App/Views/Profile/ProfileView.swift")
        // En el cuerpo de `signOutRowPath`, no en todo el fichero: el literal sale también en la operación de
        // «Eliminar mi cuenta», y con él una mutación de la celda del cierre pasaba verde (review adversarial).
        let rowPath = try Self.body(of: "private var signOutRowPath: CloudSignOutFlowLogic.Path {", in: profile)
        #expect(rowPath.contains("hasPrivateSession: !isGroupInviteMode"))
        #expect(rowPath.contains("groupsBackendEnabled: CloudSyncFlags.groupsBackendCompiledCapability"))
        #expect(profile.contains("guard live.operation == scope.operation else {"))
        let signOut = try Self.source(Self.signOutPath)
        #expect(signOut.contains("hasPrivateSession: !SessionState.shared.isGroupInviteMode"))
        #expect(signOut.contains("if let confirmedPath, confirmedPath != path {"))
    }
}
