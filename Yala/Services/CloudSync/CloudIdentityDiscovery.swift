//
//  CloudIdentityDiscovery.swift
//  Yala
//
//  El **motor** del bloque [I]: le pregunta al backend qué hay detrás de la identidad que acaba de
//  firmar, y devuelve uno de los tres resultados del ADR §7 ya resuelto para la puerta que pregunta.
//
//  POR QUÉ ES UN MOTOR Y NO UNA VISTA COMPARTIDA. Decisión de Jürgen (2026-09-09): «`GroupsSignInView`
//  cambia de motor, no de aspecto». La puerta de Grupos se sigue viendo como hoy —su tono de mini-app— y
//  lo que se comparte es la secuencia: pedir el JWT, preguntar `GET /account/exists`, cachear el tipo y
//  traducir la respuesta a un resultado. Compartir la vista habría cambiado justo lo que no debe cambiar.
//
//  **Y compartido significa dos call-sites de verdad**: `WelcomeCloudSignInView.runSignInFlow` y
//  `GroupsSignInView.resolveDestination`. La primera versión de este fichero decía «compartido» con un
//  solo llamador, mientras el Welcome conservaba su copia de la secuencia — y las dos ya cacheaban
//  distinto: una pasaba por `AccountKindLogic.snapshotToPersist` (que NO pisa con un `kind` ausente) y la
//  otra escribía el snapshot a pelo. Lo cazó una lente adversarial leyendo el docblock contra el grep.
//
//  ## Qué NO hace, y cada «no» tiene su motivo
//
//  · **No firma.** Cada puerta ya tiene su sign-in con sus propios catches —la asimetría Apple/Google no
//    es cosmética— y su propio copy de error. Este motor arranca con la sesión ya viva.
//  · **No aplica el guard cross-cuenta.** `CrossAccountEntryGuardLogic` necesita inputs que solo conoce
//    cada puerta (`hasLocalDataNow`, el claim persistido, la señal de restore en curso), y en la puerta de
//    Grupos «hay datos locales» significa otra cosa que en el Welcome. Lo aplica quien pregunta.
//  · **No rutea.** La tabla es `CloudIdentityRoutingLogic`, y es pura.
//
//  ## El caso normal es que el servidor NO diga el tipo
//
//  Medido el 2026-09-10: ni staging ni producción sirven `kind` todavía. Por eso el motor **no** decide
//  qué asumir: le pasa la puerta a `CloudIdentityRoutingLogic.discovery(exists:kind:gate:)`, que degrada
//  al comportamiento de HOY de esa puerta. Y por eso mismo un `kind` ausente **jamás borra** lo cacheado
//  (`AccountKindLogic.snapshotToPersist`): un gateway viejo no es prueba de que la cuenta haya cambiado.
//
//  ADR 2026-09-09 «Sesiones — dos ejes» §7 · ticket `cloud-sign-in-discovers-account-kind`.
//

import Foundation

@MainActor
final class CloudIdentityDiscovery {

    /// Qué se pudo averiguar.
    enum Outcome: Equatable {
        /// El backend contestó. `discovery` viene ya resuelto para la puerta que preguntó.
        case discovered(CloudIdentityRoutingLogic.Discovery, userID: String)
        /// No se pudo preguntar: sin sesión, sin JWT, o la red/el gateway no contestaron.
        ///
        /// **No es un resultado de la tabla y no debe tratarse como uno.** La matriz de escenarios lo dice
        /// en su fila «M · cualquier [I]»: error reintentable, sin crear ni borrar nada.
        case unavailable(retryable: Bool)
    }

    private let client: CloudAccountClient
    private let store: AccountKindStore
    private let jwtProvider: @MainActor () async -> String?
    private let userIDProvider: @MainActor () -> String?
    private let now: () -> Date

    /// `client` se construye SIN `attestProvider` a propósito: `/account/exists` lo sirve `requireUser`,
    /// que NO exige App Attest —es una ruta pre-sesión, anterior a `/attest/bind`— y cablear attest donde
    /// no se exige es lo que rompe el alta. Ver `.claude/rules/gateway-attest.md`.
    init(
        client: CloudAccountClient? = nil,
        store: AccountKindStore? = nil,
        jwtProvider: (@MainActor () async -> String?)? = nil,
        userIDProvider: (@MainActor () -> String?)? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client ?? CloudAccountClient()
        self.store = store ?? AccountKindStore.shared
        self.jwtProvider = jwtProvider ?? { await CloudAuthService.shared.accessToken() }
        self.userIDProvider = userIDProvider ?? { CloudAuthService.shared.currentUserID }
        self.now = now
    }

    /// Pregunta por la identidad viva y devuelve el resultado que ve la tabla.
    ///
    /// - Parameter gate: la puerta que pregunta. Decide **solo** qué se asume cuando la cuenta existe y el
    ///   servidor no dijo de qué tipo es; con el dato presente, el dato manda.
    func discover(gate: CloudIdentityRoutingLogic.Gate) async -> Outcome {
        guard let userID = userIDProvider(), !userID.isEmpty else {
            // Sin sesión no hay a quién preguntar. NO es reintentable desde aquí: quien reintenta es la
            // puerta, volviendo a firmar.
            return .unavailable(retryable: false)
        }
        guard let jwt = await jwtProvider() else { return .unavailable(retryable: true) }

        let outcome = await client.exists(jwt: jwt)

        // El userID se re-lee DESPUÉS del await: entre la petición y la respuesta puede haberse cerrado la
        // sesión o entrado otra cuenta, y atribuirle esta respuesta a quien está firmado AHORA sería
        // rutear a una persona con el tipo de cuenta de otra. Mismo guard que `AccountKindService.refresh`.
        guard let userIDVivo = userIDProvider(), userIDVivo == userID else {
            return .unavailable(retryable: false)
        }

        switch CloudWelcomeSignInFlow.route(outcome) {
        case .failed(let retryable):
            return .unavailable(retryable: retryable)

        case .accountMissing:
            return .discovered(.newAccount, userID: userIDVivo)

        case .accountFound(let kind):
            // El tipo se cachea aquí porque éste es el único punto de la app donde el backend lo dice
            // antes de que la sesión esté en marcha. `snapshotToPersist` es quien decide si se escribe:
            // un `kind` ausente devuelve `nil` y **no** borra lo que ya sabíamos.
            if let snapshot = AccountKindLogic.snapshotToPersist(
                remote: kind, sessionUserID: userIDVivo, cached: store.read(), now: now()
            ) {
                store.write(snapshot)
            }
            return .discovered(
                CloudIdentityRoutingLogic.discovery(exists: true, kind: kind, gate: gate),
                userID: userIDVivo)
        }
    }
}
