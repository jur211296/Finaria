//
//  CloudIdentityDiscoveryTests.swift
//  YalaTests / CloudSync
//
//  El motor del bloque [I], SIN red (URLSession stub) y con `UserDefaults` aislados. Molde de
//  `CloudAccountClientTests`: los fixtures del wire copian los nombres reales de
//  `gateway/src/sync/account.ts` (`{"exists":true,"kind":"groups_only"}`).
//
//  Lo que estos tests cargan de verdad es el caso raro: **la sesión que cambia durante el `await`**. Sin
//  ese guard, la respuesta de una cuenta se le atribuye a la que entró después, y eso rutea a una persona
//  con el tipo de cuenta de otra.
//

import Foundation
import Testing

@testable import Yala

// MARK: - URLSession stub

private final class ExistsStubHTTP: SyncHTTPSession, @unchecked Sendable {
    let status: Int
    let body: Data
    let error: Error?
    private(set) var calls = 0

    init(status: Int = 200, body: Data = Data(), error: Error? = nil) {
        self.status = status
        self.body = body
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        calls += 1
        if let error { throw error }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
        )!
        return (body, response)
    }
}

@Suite("Bloque [I] · el motor de descubrimiento")
@MainActor
struct CloudIdentityDiscoveryTests {

    private typealias Logic = CloudIdentityRoutingLogic

    private let base = URL(string: "https://gw.local")!

    private func makeMotor(
        body: String,
        status: Int = 200,
        error: Error? = nil,
        userID: String? = "sub-A",
        userIDAfterAwait: String? = nil,
        jwt: String? = "jwt-A",
        store: AccountKindStore
    ) -> (CloudIdentityDiscovery, ExistsStubHTTP) {
        let stub = ExistsStubHTTP(status: status, body: Data(body.utf8), error: error)
        // El segundo valor solo se usa si el test pide un cambio de sesión a mitad: la primera lectura
        // devuelve `userID` y las siguientes `userIDAfterAwait`.
        var lecturas = 0
        let motor = CloudIdentityDiscovery(
            client: CloudAccountClient(baseURL: base, urlSession: stub),
            store: store,
            jwtProvider: { jwt },
            userIDProvider: {
                lecturas += 1
                if lecturas > 1, let userIDAfterAwait { return userIDAfterAwait }
                return userID
            },
            now: { Date(timeIntervalSince1970: 1_000) })
        return (motor, stub)
    }

    // MARK: - Los tres resultados

    @Test("`exists:true` con `kind: complete` → completa, y lo cachea")
    func existsCompleta() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.completa")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(body: #"{"exists":true,"kind":"complete"}"#, store: store)

        let outcome = await motor.discover(gate: .welcomeExistingAccount)

        #expect(outcome == .discovered(.complete, userID: "sub-A"))
        #expect(store.read() == AccountKindSnapshot(
            userID: "sub-A", kind: .complete, refreshedAt: Date(timeIntervalSince1970: 1_000)),
            "el tipo tiene que quedar cacheado: es el único punto donde el backend lo dice pre-sesión")
    }

    @Test("`exists:true` con `kind: groups_only` → solo grupos")
    func existsSoloGrupos() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.grupos")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(body: #"{"exists":true,"kind":"groups_only"}"#, store: store)

        #expect(await motor.discover(gate: .welcomeExistingAccount)
            == .discovered(.groupsOnly, userID: "sub-A"))
        #expect(store.read()?.kind == .groupsOnly)
    }

    @Test("`exists:false` → nueva, y no cachea nada")
    func existsNueva() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.nueva")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(body: #"{"exists":false}"#, store: store)

        #expect(await motor.discover(gate: .welcomeExistingAccount)
            == .discovered(.newAccount, userID: "sub-A"))
        #expect(store.read() == nil, "no hay cuenta: no hay tipo que guardar")
    }

    // MARK: - El caso normal de hoy: el servidor no dice el tipo

    /// Medido el 2026-09-10: ni staging ni producción sirven `kind`. El motor no decide qué asumir — se lo
    /// pregunta a la tabla, que degrada al comportamiento de HOY **de esa puerta**. Por eso el mismo
    /// cuerpo del wire da dos resultados distintos según quién pregunte.
    @Test("`kind` ausente ⇒ la tabla degrada por PUERTA, no a un valor fijo")
    func kindAusenteDegradaPorPuerta() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.sinkind")
        let store = AccountKindStore(defaults: defaults)

        let (welcome, _) = makeMotor(body: #"{"exists":true}"#, store: store)
        #expect(await welcome.discover(gate: .welcomeExistingAccount)
            == .discovered(.complete, userID: "sub-A"),
            "la re-entrada dejaría de adoptar: regresión en producción")

        let (grupos, _) = makeMotor(body: #"{"exists":true}"#, store: store)
        #expect(await grupos.discover(gate: .groups)
            == .discovered(.groupsOnly, userID: "sub-A"),
            "la puerta de Grupos hoy no toca lo personal, y sin el dato debe seguir así")
    }

    /// Un gateway viejo, o uno caído, **no es prueba de que la cuenta haya cambiado de tipo**. Borrar aquí
    /// convertiría un fail-safe transitorio en una degradación permanente y silenciosa.
    @Test("`kind` ausente NO borra lo que ya sabíamos")
    func kindAusenteNoBorraLoCacheado() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.nopisa")
        let store = AccountKindStore(defaults: defaults)
        let previo = AccountKindSnapshot(
            userID: "sub-A", kind: .complete, refreshedAt: Date(timeIntervalSince1970: 1))
        store.write(previo)

        let (motor, _) = makeMotor(body: #"{"exists":true}"#, store: store)
        _ = await motor.discover(gate: .groups)

        #expect(store.read() == previo, "el snapshot se pisó con la respuesta muda del gateway")
    }

    // MARK: - Cuando no se puede preguntar

    @Test("red caída → no disponible y reintentable, sin tocar la caché")
    func redCaida() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.red")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(
            body: "", error: URLError(.notConnectedToInternet), store: store)

        #expect(await motor.discover(gate: .groups) == .unavailable(retryable: true))
        #expect(store.read() == nil)
    }

    @Test("sin sesión no hay a quién preguntar, y no se llama a la red")
    func sinSesion() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.sinsesion")
        let store = AccountKindStore(defaults: defaults)
        let (motor, stub) = makeMotor(
            body: #"{"exists":true,"kind":"complete"}"#, userID: nil, store: store)

        #expect(await motor.discover(gate: .groups) == .unavailable(retryable: false))
        #expect(stub.calls == 0, "preguntó sin sesión: el JWT no puede identificar a nadie")
    }

    @Test("sin JWT → reintentable (la sesión puede rehacerse)")
    func sinJWT() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.sinjwt")
        let store = AccountKindStore(defaults: defaults)
        let (motor, stub) = makeMotor(
            body: #"{"exists":true}"#, jwt: nil, store: store)

        #expect(await motor.discover(gate: .groups) == .unavailable(retryable: true))
        #expect(stub.calls == 0)
    }

    // MARK: - El guard que carga el peso

    /// **La respuesta de una cuenta jamás se le atribuye a otra.** Si entre la petición y la respuesta
    /// cambió quién está firmado, este resultado ya no describe a nadie: rutear con él llevaría a una
    /// persona al Yala completo de otra, o al revés.
    @Test("la sesión cambia durante el `await` ⇒ se descarta la respuesta y NO se cachea")
    func sesionCambiaDuranteElAwait() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.carrera")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(
            body: #"{"exists":true,"kind":"complete"}"#,
            userID: "sub-A", userIDAfterAwait: "sub-B", store: store)

        #expect(await motor.discover(gate: .welcomeExistingAccount) == .unavailable(retryable: false))
        #expect(store.read() == nil, """
            Se cacheó el tipo de `sub-A` mientras la sesión viva era ya de `sub-B`. El sello por userID \
            impediría LEERLO, pero el dato de una persona no debe quedarse en el disco de un dispositivo \
            que ya no es suyo.
            """)
    }

    /// **CONTROL POSITIVO del guard anterior.** Sin esto, «la carrera se descarta» se cumpliría igual si el
    /// motor devolviera `.unavailable` SIEMPRE — que es la familia del «Executed 0 tests».
    @Test("CONTROL POSITIVO: sin carrera, el mismo montaje SÍ descubre y cachea")
    func sinCarreraElMotorFunciona() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.control")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(
            body: #"{"exists":true,"kind":"complete"}"#,
            userID: "sub-A", userIDAfterAwait: "sub-A", store: store)

        #expect(await motor.discover(gate: .welcomeExistingAccount)
            == .discovered(.complete, userID: "sub-A"))
        #expect(store.read()?.kind == .complete)
    }

    // MARK: - La sesión expirada es reintentable, el 500 también

    @Test("401 del gateway → reintentable (volver a firmar rehace la sesión)")
    func sesionExpirada() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.401")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(
            body: #"{"error":{"type":"yala_unauthorized","message":"nope"}}"#,
            status: 401, store: store)

        #expect(await motor.discover(gate: .groups) == .unavailable(retryable: true))
    }

    @Test("502 del gateway → reintentable")
    func gatewayCaido() async {
        let defaults = makeIsolatedDefaults(prefix: "idisc.502")
        let store = AccountKindStore(defaults: defaults)
        let (motor, _) = makeMotor(body: "", status: 502, store: store)

        #expect(await motor.discover(gate: .groups) == .unavailable(retryable: true))
    }
}
