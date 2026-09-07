//
//  WelcomeAccountChoiceLogic.swift
//  Yala
//
//  Pure-logic del Welcome Chooser de 2 niveles (decisión owner 2026-07-12):
//  qué opciones muestra cada sub-chooser y cuándo hacer bypass (una sola opción
//  visible → no se muestra pantalla intermedia).
//
//  El botón de nube se oculta con backend no configurado (prod DARK hoy) y bajo
//  UITest (SIWA no funciona en sim; determinismo de los XCUITests existentes).
//
//  **A4 de D-A7 (2026-08-09): `visibleNewOptions` GANA SU CONSUMIDOR** — `WelcomeNewChooserView`
//  vía `WelcomeFlowContainer` — y `bornCloudEnabled` se cablea a la constante COMPILADA
//  `CloudSyncFlags.bornCloudChoiceEnabled`, hoy `true`. El plan de julio que decía «born-cloud
//  está DIFERIDO ⇒ `bornCloudEnabled` queda cableado a `false` en el callsite» queda OBSOLETO:
//  la palanca de release es el PERCENT remoto (`CLOUD_ONBOARDING_CHOICE_ROLLOUT_PERCENT`, hoy
//  `"0"` en producción y fail-closed), igual que con Grupos — así A5 puede ejercitar el alta en
//  staging/DEV sin recompilar, y prod sigue sin ver la card.
//

import Foundation

nonisolated enum WelcomeAccountChoiceLogic {

    /// Sub-opciones de "Soy nuevo".
    enum NewOption: Equatable, CaseIterable {
        case privateAccount
        case cloudAccount
    }

    /// Sub-opciones de "Ya tengo cuenta". `cloudSignIn` = Apple; `googleSignIn` = Google
    /// (sesión 2 — mismo gate: ambas solo con backend configurado y fuera de uitest).
    enum ExistingOption: Equatable, CaseIterable {
        case restoreICloud
        case cloudSignIn
        case googleSignIn
    }

    /// `remoteCloudEnabled`/`remoteOnboardingChoiceEnabled` = flags remote-config (DIFERIDOS #34,
    /// §j.1): la card born-cloud exige AMBOS (el sub-flag de elección es un escalón POSTERIOR del
    /// rollout del flag padre). Kill-switch = corta la ENTRADA: sin flag remoto no hay alta nueva.
    static func visibleNewOptions(
        isConfigured: Bool,
        isUITest: Bool,
        bornCloudEnabled: Bool,
        remoteCloudEnabled: Bool,
        remoteOnboardingChoiceEnabled: Bool
    ) -> [NewOption] {
        var options: [NewOption] = [.privateAccount]
        if isConfigured && !isUITest && bornCloudEnabled
            && remoteCloudEnabled && remoteOnboardingChoiceEnabled {
            options.append(.cloudAccount)
        }
        return options
    }

    /// `remoteCloudEnabled` (DIFERIDOS #34): con el kill-switch OFF las cards de sign-in nube se
    /// ocultan (bypass a restore, = prod DARK de hoy).
    ///
    /// **Residual ratificado por el owner (2026-09-06) — y son DOS puertas, no una.** Bajo el kill,
    /// un usuario nube que REINSTALA no re-entra hasta el re-encendido, y eso ocurre por los dos
    /// caminos a la vez:
    ///  1. **La card del Welcome** — esta función: sin `remoteCloudEnabled` no se ofrece el sign-in.
    ///     Y con ella se va el encaminamiento por faro, porque `cloudEntryAvailable` se DERIVA de
    ///     aquí (`routeNewBranch`, y el callsite en `WelcomeFlowContainer`).
    ///  2. **La fila «Dónde viven tus datos» de Ajustes** — `StorageRowGateLogic.isVisible`, cuyo
    ///     gate es `remoteEnabled || isEngaged`: una reinstalación NO puede estar engaged (el estado
    ///     que lo prueba es local y se fue con la app), así que la fila tampoco aparece.
    ///
    /// Hasta el 2026-09-07 esta línea solo nombraba la primera, y describir media política es como
    /// se acaba «arreglando» la puerta equivocada. Las dos cerradas es lo DESEADO: el kill significa
    /// nube en pausa para todos, también para volver. Lo que sí se corrigió es el mensaje del único
    /// camino que queda abierto —«Restaurar desde iCloud»—, que le decía a un nacido-en-nube con sus
    /// datos intactos que no los encontrábamos: ver `WelcomeRestorePauseLogic`.
    static func visibleExistingOptions(
        isConfigured: Bool,
        isUITest: Bool,
        remoteCloudEnabled: Bool
    ) -> [ExistingOption] {
        var options: [ExistingOption] = [.restoreICloud]
        if isConfigured && !isUITest && remoteCloudEnabled {
            options += [.cloudSignIn, .googleSignIn]
        }
        return options
    }

    /// Bypass del sub-chooser: con una sola opción visible se navega directo a ella.
    static func bypass<Option>(_ options: [Option]) -> Option? {
        options.count == 1 ? options.first : nil
    }

    // MARK: - Rama "Soy nuevo": el faro va ANTES de la elección (A26, §k.2)

    /// Destino de la rama "Soy nuevo". El orden de esta función ES el contrato: el faro se
    /// consulta ANTES de ofrecer nada.
    enum NewBranchRoute: Equatable {
        /// El faro de iCloud-KV dice que este Apple ID YA tiene una cuenta nube ⇒ se encamina al
        /// returning-user que ya existe (§k.4), JAMÁS a la elección: un born-cloud en su 2º device
        /// que eligiera "iCloud privado" arrancaría un dataset divergente que no se reúne con nada
        /// (A26). El provider sale del propio faro.
        case cloudSignIn(CloudSignInProvider)
        /// Bypass: una sola opción visible ⇒ no se monta pantalla intermedia (el recorrido de hoy).
        case single(NewOption)
        /// Dos o más opciones ⇒ sub-chooser.
        case chooser
    }

    /// `cloudEntryAvailable` es la disponibilidad de la MISMA pantalla a la que encamina el faro —
    /// la card `.cloudSignIn` de `visibleExistingOptions`—, no un gate nuevo: sin backend
    /// configurado el sign-in no puede completar (callejón), bajo uitest rompería el determinismo,
    /// y con el kill-switch remoto puesto la política ya ratificada es que la re-entrada nube no se
    /// ofrece (residual del owner en `visibleExistingOptions`). El callsite lo DERIVA de
    /// `visibleExistingOptions` en vez de re-escribir los tres términos.
    ///
    /// **Residual, declarado y no escondido:** bajo el kill remoto un born-cloud en su 2º device
    /// vuelve a poder divergir — es el mismo residual que ya acepta la card de re-entrada, ampliado
    /// a este camino. Sin kill (el caso normal) el faro cierra A26.
    static func routeNewBranch(
        beaconLinked: Bool,
        beaconProvider: String?,
        cloudEntryAvailable: Bool,
        options: [NewOption]
    ) -> NewBranchRoute {
        if beaconLinked && cloudEntryAvailable {
            // Provider desconocido/ausente ⇒ `.apple` (el faro solo ENCAMINA; si el método no casa,
            // `ProviderMismatchLogic` lo dice en la pantalla de destino).
            return .cloudSignIn(CloudSignInProvider(rawValue: beaconProvider ?? "") ?? .apple)
        }
        if let single = bypass(options) { return .single(single) }
        return .chooser
    }
}

/// El estado honesto del restore bajo el kill-switch (decisión owner 2026-09-06).
///
/// **El problema que cierra:** con las dos puertas de nube cerradas, el ÚNICO camino que le queda a
/// quien vuelve es «Restaurar desde iCloud», y esa pantalla busca en **CloudKit**. Un nacido-en-nube
/// jamás tuvo datos ahí —los suyos viven en el backend— así que su búsqueda termina siempre vacía y
/// leía «No encontramos tus datos» con sus datos perfectamente intactos. El hecho es el contrario:
/// los datos existen y lo que está en pausa es la nube.
///
/// **Por qué el faro es el detector correcto** y no un flag local: vive en el iCloud-KV
/// (`CloudBeacon`), así que es lo ÚNICO de la cuenta nube que sobrevive a una reinstalación — que es
/// exactamente el recorrido que este mensaje describe. Cualquier testigo local es `false` en un
/// móvil recién instalado, por construcción.
///
/// **Deliberadamente NO sustituye a `.found`**: solo se consulta cuando la búsqueda no encontró nada.
/// Un usuario de iCloud privado que además tenga el faro puesto (dos devices, dos modos) sigue viendo
/// sus datos de iCloud y su botón de restaurar; taparle eso con un aviso de la nube sería cambiar un
/// mensaje equivocado por otro.
nonisolated enum WelcomeRestorePauseLogic {

    /// ¿La búsqueda vacía se debe a que la nube está en pausa, y no a que no haya datos?
    ///
    /// - Parameters:
    ///   - beaconLinked: `CloudBeacon.isCloudAccountLinked` — este Apple ID YA tiene cuenta nube.
    ///   - remoteCloudEnabled: `CloudRemoteFlags.cloudModeEnabled` — el kill-switch remoto.
    ///   - isSecondaryActive: `SecondarySessionStore.isActive()` — hay una VISITA usando el device.
    ///
    /// **El término M1 no es defensivo: sin él el mensaje habla de la cuenta de otra persona.** El faro
    /// vive en el iCloud-KV del Apple ID, que es el del DUEÑO del teléfono, y `OwnerKeyValueStore` no
    /// bloquea las lecturas a propósito. Una invitada en sesión secundaria monta con
    /// `cloudKitDatabase: .none`, así que su búsqueda sale vacía SIEMPRE — y sin este término leería
    /// «tus datos están a salvo en tu cuenta» sobre una cuenta que no es suya, enterándose de paso de
    /// que el dueño del móvil tiene una. `.notFound` era inexacto para ella; esto habría sido peor,
    /// porque afirma. La rama «Ya tengo cuenta» no tiene cinturón M1 propio (su hermana privada sí:
    /// `WelcomeFlowContainer` la manda a `.privateSecondaryNotice`), así que se pone aquí.
    static func isCloudPaused(
        beaconLinked: Bool,
        remoteCloudEnabled: Bool,
        isSecondaryActive: Bool
    ) -> Bool {
        guard !isSecondaryActive else { return false }
        return beaconLinked && !remoteCloudEnabled
    }
}

/// Adaptador de LECTURA del faro para la rama "Soy nuevo" (A4 de D-A7). Existe para que el callsite
/// no lea `CloudBeacon` a mano y para que el test pueda inyectar el store KV (`BeaconKeyValueStore`):
/// la decisión sigue siendo pura y vive arriba; esto solo la alimenta.
@MainActor
enum WelcomeNewBranchRouter {
    static func route(
        beacon: CloudBeacon,
        cloudEntryAvailable: Bool,
        options: [WelcomeAccountChoiceLogic.NewOption]
    ) -> WelcomeAccountChoiceLogic.NewBranchRoute {
        WelcomeAccountChoiceLogic.routeNewBranch(
            beaconLinked: beacon.isCloudAccountLinked,
            beaconProvider: beacon.linkedProvider,
            cloudEntryAvailable: cloudEntryAvailable,
            options: options)
    }
}
