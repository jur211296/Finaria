//
//  GroupsOrganizerOnboarding.swift
//  Yala
//
//  G3 de Grupos-first · **el alta del organizador: el paso 7 de la rama, y el ÚNICO sitio donde escribe.**
//
//  Nació como el calco funcional del alta que el onboarding de 8 steps hacía para su card «Solo grupos»
//  —mismo modo, mismos seeds, mismo aterrizaje—, extraído aquí en vez de reusado porque aquel era un
//  método privado de esa vista, cuyo planner decide por `selectedUsageMode`: reusarlo exigía arrastrar el
//  planner entero para pedir un campo. Aquel método se borró en C2, y la card, con su puerta, el
//  2026-09-10 (ADR 2026-09-09 §7).
//
//  **Qué es «el trío» y por qué el ORDEN de la rama es load-bearing.** Las tres escrituras que hacen la
//  shell son `onboardingMode = .groupInvite`, `groupsBetaUnlocked = true` y `hasCompletedOnboarding = true`.
//  La primera es **never-downgrade cross-device** (rank 1 > 0, `PreferenceMergeLogic`) y viaja al iKV del
//  Apple ID: escrita antes de confirmar la puerta, no vuelve — se propaga a los otros dispositivos de ese
//  Apple ID y deja al usuario con la shell reducida a Grupos y sin grupo que enseñar. Por eso este tipo se
//  invoca DESPUÉS de `GroupsOrganizerGateLogic` y de la cadena sign-in → consent, nunca antes, y por eso
//  un source-scan pinnea que tenga un solo call-site de producción.
//
//  **La divisa (G4) es la ÚNICA escritura CONDICIONAL del alta, y esa condición es el invariante.**
//  `defaultCurrencyCode = CurrencyDefaults.detectCurrencyFromRegion()` sigue el precedente vivo de
//  `GroupInviteOnboardingView` («grupo primero, región después», `:374-376`), pero **solo si la key está
//  AUSENTE**: el default global `.pen` de `AppPreferences` NO se toca —79 lectores, 3 de ellos
//  pre-onboarding y 2 tests que lo pinnean— y quien ya tenga una divisa escrita no puede verla cambiar.
//  Y «ya escrita» no es un caso raro: `defaultCurrencyCode` es `synced: true`, así que en una instalación
//  nueva de un Apple ID con Yala en otro dispositivo el valor puede haber bajado por iKV ANTES de que el
//  organizador toque nada; sobrescribirlo le cambiaría la divisa por la de la región donde esté hoy. Por
//  eso el writer expone `hasValue(forKey:)` en vez de que el alta consulte `UserDefaults.standard`: la
//  condición tiene que ser afirmable sobre un STORE inyectado, igual que el «cero escrituras» del gate.
//  La divisa es editable en el grupo desde el primer minuto (`GroupFormView` / `GroupSettingsView`).
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - El canal de escritura, inyectable

/// El mínimo que el alta necesita escribir, con los dos canales SEPARADOS a propósito: mezclarlos es
/// cómo una preferencia per-device acaba viajando a la cuenta (regla de `swiftdata-cloudkit.md`).
///
/// Existe inyectable —molde de `BeaconKeyValueStore`, el protocolo con el que G0 hizo testeable el
/// handover— para que «con la puerta cerrada no se escribe nada» sea una afirmación comprobable sobre un
/// STORE y no sobre una pantalla, que es lo que el criterio de hecho del chip pide.
@MainActor
protocol GroupsOrganizerPreferenceWriting {
    /// Preferencia SINCRONIZADA: iKV en `.icloud`, outbox de prefs en `.cloud`.
    func setSynced(_ value: String, forKey key: String)
    /// Preferencia PER-DEVICE: jamás viaja.
    func setLocal(_ value: Bool, forKey key: String)
    /// ¿Este dispositivo ya tiene valor para esta key? Lo pide la divisa, la única escritura CONDICIONAL
    /// del alta: sin lectura inyectable habría que preguntarle a `UserDefaults.standard`, y entonces el
    /// test de «no se pisa una divisa existente» dependería del simulador en vez del store que le pasan.
    func hasValue(forKey key: String) -> Bool
}

/// El canal de producción: `PreferenceSyncService` para lo sincronizado, `UserDefaults` para lo del device.
@MainActor
struct LiveGroupsOrganizerPreferenceWriter: GroupsOrganizerPreferenceWriting {
    var sync: PreferenceSyncService = .shared
    var defaults: UserDefaults = .standard

    func setSynced(_ value: String, forKey key: String) {
        sync.set(string: value, forKey: key)
    }

    func setLocal(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    /// `.standard` es el espejo local también de lo sincronizado: `PreferenceSyncService.set(string:)`
    /// escribe ahí antes de empujar al canal, y el merge de bajada aplica ahí lo que llega del iKV o del
    /// backend. ⇒ es el sitio correcto para preguntar «¿este dispositivo ya sabe una divisa?».
    func hasValue(forKey key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }
}

// MARK: - El alta

@MainActor
enum GroupsOrganizerOnboarding {

    /// Las SIETE keys que este alta puede escribir. Publicadas para que el test pueda afirmar su AUSENCIA en
    /// el camino bloqueado con el mismo inventario que usa el camino que sí escribe — una lista duplicada a
    /// mano en el test se quedaría corta en cuanto alguien añadiera una escritura aquí.
    ///
    /// - Note: `defaultCurrencyCode` es la única CONDICIONAL (solo si está ausente), así que el control
    ///   positivo del test que compara contra este inventario tiene que correr sobre un store limpio.
    /// Las SEIS que viajan por el canal de PREFERENCIAS (el `writer`). Se publican aparte de `writtenKeys`
    /// porque el spy de los tests solo puede ver éstas: la séptima no pasa por el writer a propósito —no es
    /// una preferencia del usuario, es la decisión de mount de este teléfono, y propagarla apagaría el
    /// espejo en el otro device del mismo usuario.
    static let writtenPreferenceKeys: [String] = [
        AppPreferences.Keys.userName,
        AppPreferences.Keys.defaultPeriod,
        AppPreferences.Keys.defaultCurrencyCode,
        OnboardingMode.userDefaultsKey,
        AppPreferences.Keys.groupsBetaUnlocked,
        AppPreferences.Keys.hasCompletedOnboarding
    ]

    static let writtenKeys: [String] = writtenPreferenceKeys + [
        // 2026-09-10 · la séptima, y entra en el inventario A PROPÓSITO (el guard de
        // `SecondaryOwnerDomainGuardsTests` obliga a decidirlo en vez de dejarla aparecer en silencio).
        // No es una preferencia del usuario —es la decisión de MOUNT de este teléfono— pero comparte las
        // dos propiedades que este inventario existe para vigilar: la escribe el alta, y tiene que ir
        // DESPUÉS del guard de sesión secundaria. Dejarla fuera la habría vuelto invisible para las tres
        // redes que se alimentan de aquí, incluido el bucle que comprueba ese orden.
        StorageModePersistence.groupsOnlyNeutralMountKey
    ]

    /// Solo las preferencias, sin SwiftData. Separada de `completeSetup` para poder ejercitarla contra un
    /// writer espía sin montar un `ModelContainer` — no es una división cosmética: es la mitad que el test
    /// del gate usa como CONTROL POSITIVO de que sabe detectar una escritura.
    ///
    /// - Parameter regionCode: región ISO con la que se deriva la divisa. Default: la del dispositivo,
    ///   inyectable para tests deterministas (patrón canónico `now: Date = .now`; el mismo default que
    ///   `CurrencyDefaults.detectCurrencyFromRegion`, que es quien la traduce a divisa).
    ///   - isSecondarySession: C3 · `SecondarySessionStore.isActive()` por default, evaluado EN LA LLAMADA.
    ///     Va como parámetro y no leído por dentro para que el invariante sea afirmable sin tocar el
    ///     `UserDefaults.standard` del simulador — el override global de `isActive()` es estado de PROCESO
    ///     y contaminaría a las suites que corren en paralelo. Que el default siga siendo el mecanismo real
    ///     lo pinnea un source-scan: cambiarlo por `false` dejaría los tests de comportamiento en verde.
    ///
    /// - Returns: `false` si el alta se abortó por la frontera M1. El caller **tiene que respetarlo**:
    ///   seguir con los seeds y el aterrizaje dejaría al usuario en un shell de Grupos que ninguna
    ///   preferencia sostiene.
    @discardableResult
    static func writePreferences(displayName: String,
                                 writer: any GroupsOrganizerPreferenceWriting,
                                 regionCode: String = Locale.current.region?.identifier ?? "",
                                 isSecondarySession: Bool = SecondarySessionStore.isActive(),
                                 defaults: UserDefaults = .standard) -> Bool {
        // **C3 · el guard subió de UNA key al MÉTODO ENTERO, y esa es la corrección.** Hasta C3 solo
        // `onboardingMode` lo llevaba, porque el escáner de M1 buscaba los literales de ESA key y C2
        // arregló exactamente lo que el escáner señalaba. Las otras CINCO cruzaban igual: `set(string:)` de
        // `PreferenceSyncService` hace su `local.set(...)` FUERA del switch de behavior, así que
        // `.localOnly` no evita la escritura local — solo la propagación—, y `local` es `.standard`
        // hardcodeado, que en secundaria es el dominio del DUEÑO.
        //
        // La que más pesa no es el modo: es `groupsBetaUnlocked`, porque **nadie la repone al salir**.
        // `DataWipeService.removeGroupsDomainPreferenceKeys` tiene UN call-site, dentro de
        // `wipeLocalGroupsDomain` (el «empiezo de cero» del Welcome) ⇒ cerrar la sesión de la invitada le
        // deja al dueño el dominio Grupos adoptado, que es justo lo que
        // `recordEntry_isInertUnderASecondarySession` ya advierte por escrito para el OTRO escritor de esa
        // misma key.
        //
        // Esto es defensa en profundidad y NO la respuesta al usuario: la rama entera se bloquea antes, en
        // `GroupsOrganizerGateLogic` (`.blockedSecondarySession`), y su choke-point es
        // `ContentView.advanceGroupsOrganizerFlow`. Aquí solo se garantiza que ninguna escritura sale.
        guard !isSecondarySession else { return false }

        // **El neutro durable de la sesión solo-grupos** (paso 5 del rediseño). Sin esto, el arranque
        // SIGUIENTE monta `.iCloudMirror` sobre el store personal —el archivo ya existe, así que
        // `isFreshInstallForNeutralMount` deja de ser `true`— y se trae el contenedor privado del Apple ID
        // del teléfono, que es el bug del ticket.
        //
        // Va DENTRO del guard de secundaria (la cabecera de este método) como las otras seis: es una
        // decisión de mount del DEVICE, y en secundaria el device es de otra persona.
        //
        // Local y no sincronizada a propósito: describe cómo monta ESTE teléfono, no qué eligió la
        // cuenta. Propagarla apagaría el espejo en el otro device del mismo usuario, que puede tener su
        // sesión privada viva.
        //
        // **`defaults` es inyectable y eso NO es cosmética de tests.** El host de `YalaTests` es la app,
        // así que comparte el `UserDefaults.standard` del simulador: con esta escritura clavada a
        // `.standard`, correr la suite dejaba la marca puesta y la app de ese simulador montaba neutro
        // para siempre — rompiendo cualquier QA visual posterior. Las siete llamadas de test pasan su
        // suite aislado, igual que ya hacen con el `writer`.
        StorageModePersistence.armGroupsOnlyNeutralMountIfPrimary(defaults, isSecondary: isSecondarySession)

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveName = trimmed.isEmpty ? L10n.Profile.defaultName : trimmed

        writer.setSynced(effectiveName, forKey: AppPreferences.Keys.userName)
        writer.setSynced(DetailPeriod.thisMonth.rawValue, forKey: AppPreferences.Keys.defaultPeriod)

        // G4 · la divisa por región, en silencio y SOLO sobre una key ausente. El alta del organizador no
        // pregunta la moneda (decisión del owner: solo nombre) y sin esta línea nacería en `.pen` —el
        // default global, que NO se cambia— fuera de Perú. El guard es el invariante, no una optimización:
        // esta key es `synced: true` y pisarla propagaría a la CUENTA la divisa de la región donde el
        // usuario esté hoy, encima de la que ya eligió en otro dispositivo.
        if !writer.hasValue(forKey: AppPreferences.Keys.defaultCurrencyCode) {
            let currency = CurrencyDefaults.detectCurrencyFromRegion(regionCode: regionCode)
            writer.setSynced(currency.rawValue, forKey: AppPreferences.Keys.defaultCurrencyCode)
        }

        // Modo Solo Grupos: reusa `.groupInvite`. Push EXPLÍCITO al canal sincronizado (dual-write, mismo
        // patrón que `FullModeActivationView`) — el `didSet` de `onboardingMode` solo escribe local, así
        // que sin esto no hay paridad cross-device.
        //
        // **M1 · el `if !SecondarySessionStore.isActive()` que envolvía SOLO esta línea se retiró en C3**,
        // absorbido por el `guard` de la cabecera. No es una relajación: es que proteger una de las seis
        // escrituras y dejar las otras cinco era la mitad del bug — `.groupInvite` (rank 1) sobre el
        // `.full` (rank 0) del dueño es irreversible por never-downgrade, pero `groupsBetaUnlocked` es
        // PEOR, porque ni siquiera hay quien la reponga al cerrar la sesión.
        writer.setSynced(OnboardingMode.groupInvite.rawValue, forKey: OnboardingMode.userDefaultsKey)

        // Adopción explícita del dominio Grupos. `.groupInvite` ya la implica por el segundo término de
        // `GroupsDomainAdoptionLogic.isDomainOpen`, pero ese término muere si el usuario activa Yala
        // completo más tarde; la key es per-device y permanente (mismo trato que la entrada por invitación).
        writer.setLocal(true, forKey: AppPreferences.Keys.groupsBetaUnlocked)
        writer.setLocal(true, forKey: AppPreferences.Keys.hasCompletedOnboarding)

        return true
    }

    /// El alta completa: preferencias, espejo en memoria, seeds y aterrizaje en el tab Grupos.
    ///
    /// - Important: **es UN call-site de producción, detrás de la cadena completa**:
    ///   `GroupsOrganizerNameView` (puerta A, Welcome). Hubo un segundo hasta el 2026-09-10 —el caso
    ///   `.presentName` con payload de `ContentView.advanceGroupsOrganizerFlow`, la puerta B de la card
    ///   «Solo grupos» del onboarding—, retirado con la card (ADR 2026-09-09 §7). Pinneado por source-scan
    ///   con conteo; moverlo antes de la cadena es la mutación (b) del chip.
    /// - Parameter writer: `nil` = el canal de producción. Va opcional y no con un default construido en
    ///   la firma porque `LiveGroupsOrganizerPreferenceWriter` es `@MainActor` (sus dos dependencias lo son)
    ///   y un default se evalúa en contexto nonisolated.
    static func completeSetup(displayName: String,
                              context: ModelContext,
                              writer: (any GroupsOrganizerPreferenceWriting)? = nil) {
        let sessionState = SessionState.shared
        // C3 · si las preferencias no se escribieron (frontera M1), el alta NO ocurre: seguir con el modo
        // en memoria, los seeds y el aterrizaje en el tab dejaría a la invitada dentro de un shell de
        // Grupos que ninguna preferencia sostiene, y los seeds escribirían en el store del DUEÑO si el
        // mount todavía es el suyo. El usuario ya recibió su respuesta en la puerta.
        guard writePreferences(displayName: displayName,
                               writer: writer ?? LiveGroupsOrganizerPreferenceWriter()) else { return }

        // Espejo en memoria: el proceso vivo tiene que ver el modo nuevo YA (el tab bar se reduce a
        // [.groups] en el mismo render), no en el próximo arranque.
        sessionState.onboardingMode = .groupInvite
        sessionState.selectedPeriod = .thisMonth

        // Seeds idénticos al camino del invitado: categorías personales (para tener subcategorías en los
        // gastos de grupo) + las de sistema del bridge. Sin cuenta ni presupuesto personal.
        seedCategoriesIfNeeded(in: context)
        seedSystemGroupCategoriesIfNeeded(in: context)
        NotificationService.shared.seedDefaultNotificationsIfNeeded(context: context)

        do {
            SaveBreadcrumb.willSave("GroupsOrganizerOnboarding.completeSetup")
            try context.save()
            SaveBreadcrumb.didSave("GroupsOrganizerOnboarding.completeSetup")
        } catch {
            #if DEBUG
            print("GroupsOrganizerOnboarding: Error saving organizer setup: \(error)")
            #endif
        }

        // KPI registros/día — el mismo evento que el alta del onboarding de 8 pasos, con su propio modo para
        // separar esta entrada de aquélla.
        MetricsService.localRegistrationCompleted(mode: "groupsOrganizer")
        PreferenceSyncService.shared.signalOnboardingCompleted()

        // Aterrizar en el tab Grupos: con `.groupInvite` el tab bar se reduce a [.groups] y el
        // `selectedMainTab` persistido (.panel) no está montado (gotcha bde61bb2).
        sessionState.selectedMainTab = .groups
    }
}
