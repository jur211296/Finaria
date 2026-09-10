//
//  WelcomeFlowContainer.swift
//  Yala
//
//  Contenedor unificado del flow Welcome (Hero + Chooser) bajo un solo
//  `fullScreenCover`. Resuelve el "azul vacío" entre dismiss del Hero y
//  present del Chooser que aparecía con dos covers separados — el background
//  gradient persiste y la transición entre steps es un cross-fade smooth.
//
//  **El Hero desemboca SIEMPRE en el chooser** (decisión del owner 2026-08-11,
//  punto 2 de MODO-NUBE-REVISION-FLUJOS-NOTAS): aquí vivía el alert "Detectamos
//  tu cuenta", que empujaba hacia la cuenta iCloud del container a quien podía
//  tener su cuenta en la nube. La reentrada la elige el usuario en
//  "Ya tengo una cuenta", que ofrece las tres vías.
//

import SwiftUI

/// `Equatable` explícito desde que `.mirrorRelaunch` lleva payload: hasta entonces el `==` de `goTo`
/// venía de la síntesis automática de los enums sin valores asociados, que deja de aplicar en cuanto uno
/// los tiene.
enum WelcomeFlowStep: Equatable {
    case hero
    case chooser
    /// 2º nivel de "Ya tengo una cuenta" (H4): Restaurar iCloud | Sign in with Apple.
    /// Solo alcanzable con >1 opción visible (bypass en `handleExistingBranch`).
    case existingChooser
    /// 2º nivel de "Soy nuevo" (A4 de D-A7, §k.2): privacidad total (iCloud) | cuenta en la nube.
    /// Solo alcanzable con >1 opción visible (bypass en `handleNewBranch`).
    case newChooser
    /// G2 · 2º nivel de «Vengo por un grupo»: los dos caminos con los que se empieza un grupo —crearlo o
    /// entrar con la invitación—. La rama `.invite` del chooser deja de salir por el portal para venir
    /// aquí; el que ya tiene enlace sale por el MISMO `Destination .inviteRecovery` desde la card.
    case groupsChooser
    /// G3 · la PUERTA de la rama organizador: re-mide el canal de Grupos con `force` y comprueba que el
    /// device no tenga datos de otro humano. Es un step y no un alert porque el source-scan de W1 prohíbe
    /// `.alert(` en este fichero, y porque una pantalla de bloqueo con salida no es un camino muerto.
    /// **Nada se escribe hasta que esta puerta dice que sí.**
    case groupsGate
    /// La rama privada, en sesión secundaria: **informa y sigue**. No es una puerta como `.groupsGate` —no
    /// hay nada que impedir desde que el dominio de preferencias por sesión cerró las escrituras al dueño—
    /// sino el paso que faltaba para que la app no se contradijera según por dónde entres.
    case privateSecondaryNotice
    /// Paso 4 del rediseño · **la puerta de la rama privada: le pregunta a iCloud qué hay ANTES de que
    /// nadie vea una pantalla de reinicio** (ADR §9). Es un step y no un alert por las mismas razones que
    /// `.groupsGate`, más una medida: un `.alert` del anchor de `ContentView` desmonta este cover entero.
    case privateICloudGate
    /// R2 · TERMINAL: hay que reabrir la app. Vive DENTRO de este cover a propósito: un cover propio sería
    /// una presentación nueva colgando del anchor de `ContentView` (matriz de readiness, regla (3) de
    /// Presentaciones) para enseñar dos párrafos; aquí es un step más del contenedor que ya está montado.
    ///
    /// **Lleva el motivo desde el paso 5-b (2026-09-10)**, y no un `@State` paralelo: son DOS terminales
    /// con la misma forma y promesas distintas —encender el espejo para el destino elegido, o dejar el
    /// teléfono limpio para Grupos— y un estado suelto al lado del step se desincroniza en cuanto alguien
    /// navegue desde un tercer sitio. Con el motivo dentro, el compilador obliga a nombrarlo al navegar.
    case mirrorRelaunch(WelcomeRelaunchReason)
}

/// Por qué se le pide a la persona que reabra Yala. El copy del terminal es lo único que cambia.
enum WelcomeRelaunchReason: Equatable {
    /// R2 · el destino elegido necesita el espejo de CloudKit y este proceso montó neutro.
    case attachMirror
    /// Paso 5-b · el espejo está vivo (o hay corpus local sin respaldo) y la entrada por Grupos exige un
    /// store neutro: el borrado de arranque ya está armado y corre ANTES de montar, en el arranque
    /// siguiente.
    case cleanForGroups
}

struct WelcomeFlowContainer: View {
    /// Step inicial. Para flujo normal `.hero`; para casos como "back" desde
    /// InviteRecovery (rama C → vuelve al Chooser) se pasa `.chooser`.
    let initialStep: WelcomeFlowStep

    var onSelectBranch: (WelcomeChooserView.Branch) -> Void
    /// Sub-elección de "Ya tengo una cuenta" (también el resultado del bypass).
    var onSelectExistingOption: (WelcomeAccountChoiceLogic.ExistingOption) -> Void
    /// "Soy nuevo" con la opción PRIVADA elegida (también el resultado del bypass, que es el
    /// recorrido de producción de hoy).
    var onSelectPrivateAccount: () -> Void
    /// A5: "Soy nuevo" con la opción NUBE elegida ⇒ alta born-cloud (consent → sign-in → claim →
    /// par → relanzamiento). El destino es el MISMO cover que la re-entrada, con `Entry.bornCloud`.
    var onSelectCloudAccount: () -> Void
    /// A26 (§k.2): el faro de iCloud-KV dice que este Apple ID YA tiene cuenta nube ⇒ el Welcome
    /// NO ofrece la elección y encamina al returning-user con el provider del propio faro.
    var onBeaconRoutesToCloudSignIn: (CloudSignInProvider) -> Void
    /// G3: «Crear mi primer grupo» con la puerta ya CONFIRMADA abierta (canal encendido y sin datos de
    /// otro humano en el device). El container no comprueba nada aquí: eso es del step `.groupsGate`, que
    /// es el único que puede llamarlo.
    var onSelectGroupsOrganizer: () -> Void
    /// R2: el destino elegido necesita el mirror y este proceso montó neutro ⇒ el container va a su step
    /// terminal y ContentView PERSISTE el destino para retomarlo tras el relanzamiento. Se separa en dos
    /// responsabilidades porque el container no debe tocar `UserDefaults` ni los flags de onboarding.
    var onNeedsMirrorRelaunch: (WelcomeMirrorRelaunchLogic.Destination) -> Void
    /// G3: fetch VIVO del corpus PERSONAL para la puerta (cuentas y categorías no-`isSystem`; un
    /// snapshot no vale, el mirror puede estar re-importando). **Estrecho a propósito desde el paso 5-b**:
    /// el detector ancho cuenta grupos y filas puenteadas, que el borrado de arranque no se lleva, y con
    /// él la puerta pediría reabrir la app en bucle a quien tenga grupos locales.
    var hasPersonalDataNow: @MainActor @Sendable () -> Bool
    /// Paso 5-b: sube a iCloud lo pendiente antes de que la puerta arme ningún borrado, y devuelve si ya
    /// es seguro. Vive en `ContentView` porque necesita el `modelContext`, igual que el wipe del paso 4.
    var attemptPersonalUpload: @MainActor () async -> GroupsNeutralReturnLogic.Verdict
    /// Paso 5-b: la puerta autorizó la vuelta al neutro ⇒ `ContentView` arma el borrado de arranque y
    /// persiste el destino. El container solo navega al terminal.
    var onNeedsNeutralReturn: () -> Void
    /// Paso 4: el borrado del corpus de iCloud. Vive en `ContentView` —es quien tiene el `modelContext`,
    /// y el borrado tiene que llevarse también las filas que el espejo hubiera bajado ya—; el container
    /// solo lo reenvía a la puerta.
    var performICloudCorpusWipe: @MainActor () async -> String?

    @State private var step: WelcomeFlowStep = .hero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        initialStep: WelcomeFlowStep = .hero,
        onSelectBranch: @escaping (WelcomeChooserView.Branch) -> Void,
        onSelectExistingOption: @escaping (WelcomeAccountChoiceLogic.ExistingOption) -> Void,
        onSelectPrivateAccount: @escaping () -> Void,
        onSelectCloudAccount: @escaping () -> Void,
        onSelectGroupsOrganizer: @escaping () -> Void,
        onBeaconRoutesToCloudSignIn: @escaping (CloudSignInProvider) -> Void,
        onNeedsMirrorRelaunch: @escaping (WelcomeMirrorRelaunchLogic.Destination) -> Void,
        onNeedsNeutralReturn: @escaping () -> Void,
        hasPersonalDataNow: @escaping @MainActor @Sendable () -> Bool,
        attemptPersonalUpload: @escaping @MainActor () async -> GroupsNeutralReturnLogic.Verdict,
        performICloudCorpusWipe: @escaping @MainActor () async -> String?
    ) {
        self.initialStep = initialStep
        self.onSelectBranch = onSelectBranch
        self.onSelectExistingOption = onSelectExistingOption
        self.onSelectPrivateAccount = onSelectPrivateAccount
        self.onSelectCloudAccount = onSelectCloudAccount
        self.onBeaconRoutesToCloudSignIn = onBeaconRoutesToCloudSignIn
        self.onSelectGroupsOrganizer = onSelectGroupsOrganizer
        self.onNeedsMirrorRelaunch = onNeedsMirrorRelaunch
        self.onNeedsNeutralReturn = onNeedsNeutralReturn
        self.hasPersonalDataNow = hasPersonalDataNow
        self.attemptPersonalUpload = attemptPersonalUpload
        self.performICloudCorpusWipe = performICloudCorpusWipe
        self._step = State(initialValue: initialStep)
    }

    private var visibleExistingOptions: [WelcomeAccountChoiceLogic.ExistingOption] {
        // `-uitest-cloud-chooser` (opt-in EXPLÍCITO, sesión 2): destapa las cards cloud bajo
        // uitest SOLO para el XCUITest del chooser — el resto de uitest queda byte-idéntico
        // (bypass a restore intacto). `remoteCloudEnabled` (DIFERIDOS #34): kill-switch de la
        // ENTRADA; bajo uitest/DEV sin fetch el default es ON (byte-idéntico), y si el fetch
        // aterriza con la vista abierta se lee en el siguiente render (sin live-update — asumido).
        WelcomeAccountChoiceLogic.visibleExistingOptions(
            isConfigured: CloudBackendConfig.isConfigured,
            isUITest: SwiftDataConfiguration.isUITesting && !UITestHooks.forceCloudChooser,
            remoteCloudEnabled: CloudRemoteFlags.cloudModeEnabled)
    }

    /// A4: espejo EXACTO de los argumentos del existing (mismo opt-in de uitest, mismo kill-switch)
    /// más los dos términos propios del born-cloud: la constante COMPILADA (hoy `true`) y el
    /// sub-flag remoto de la elección, que es el que sirve `"0"` en producción.
    private var visibleNewOptions: [WelcomeAccountChoiceLogic.NewOption] {
        WelcomeAccountChoiceLogic.visibleNewOptions(
            isConfigured: CloudBackendConfig.isConfigured,
            isUITest: SwiftDataConfiguration.isUITesting && !UITestHooks.forceCloudChooser,
            bornCloudEnabled: CloudSyncFlags.bornCloudChoiceEnabled,
            remoteCloudEnabled: CloudRemoteFlags.cloudModeEnabled,
            remoteOnboardingChoiceEnabled: CloudRemoteFlags.cloudOnboardingChoiceEnabled)
    }

    /// El encaminamiento por faro (A26) va a la MISMA pantalla que la card `.cloudSignIn` del
    /// sub-chooser de "Ya tengo cuenta" ⇒ su disponibilidad se DERIVA de ahí en vez de re-escribir
    /// los tres términos, que es como dos gates que deberían coincidir empiezan a divergir.
    private var cloudEntryAvailable: Bool {
        visibleExistingOptions.contains(.cloudSignIn)
    }

    var body: some View {
        ZStack {
            switch step {
            case .hero:
                WelcomeHeroView {
                    goTo(.chooser)
                }
                .transition(.opacity)
            case .chooser:
                WelcomeChooserView(
                    onSelect: { branch in
                        // "Ya tengo una cuenta" y "Soy nuevo" abren su 2º nivel (o bypass con 1
                        // opción — en producción hoy equivale exactamente al flujo actual).
                        switch branch {
                        case .restore: handleExistingBranch()
                        case .new: handleNewBranch()
                        // G2: la card ya no es «me invitaron» sino «vengo por un grupo», así que no
                        // puede salir directa a la recuperación de invitación — abre el step de los
                        // dos caminos y es ahí donde el invitado elige el suyo.
                        case .invite: goTo(.groupsChooser)
                        }
                    },
                    onBack: { goTo(.hero) }
                )
                .transition(.opacity)
            case .groupsChooser:
                WelcomeGroupsChooserView(
                    // G3: la card de crear ya está cableada y por tanto se pinta. Su handler NO sale del
                    // cover: abre la puerta, que es el step siguiente. El portal se cruza más tarde, y
                    // solo si la puerta abre.
                    onCreate: { goTo(.groupsGate) },
                    onJoin: {
                        leaveWelcome(to: .inviteRecovery) { onSelectBranch(.invite) }
                    },
                    onBack: { goTo(.chooser) }
                )
                .transition(.opacity)
            case .groupsGate:
                WelcomeGroupsGateView(
                    // Re-envuelto en vez de reenviado: pasar la property directa convierte un valor de
                    // función no-Sendable y avisa (`may introduce data races`). El closure nuevo nace ya en
                    // este contexto y no cruza ninguna frontera.
                    hasPersonalDataNow: { hasPersonalDataNow() },
                    attemptPersonalUpload: attemptPersonalUpload,
                    onProceed: {
                        leaveWelcome(to: .groupsOrganizer) { onSelectGroupsOrganizer() }
                    },
                    onNeedsNeutralReturn: {
                        // Dos responsabilidades separadas por la misma razón que en `leaveWelcome`: el
                        // container navega, `ContentView` es quien toca `UserDefaults` (armar el borrado
                        // de arranque y persistir el destino).
                        onNeedsNeutralReturn()
                        goTo(.mirrorRelaunch(.cleanForGroups))
                    },
                    onBack: { goTo(.groupsChooser) }
                )
                .transition(.opacity)
            case .existingChooser:
                WelcomeExistingChooserView(
                    options: visibleExistingOptions,
                    onSelect: { option in handleExistingOption(option) },
                    onBack: { goTo(.chooser) }
                )
                .transition(.opacity)
            case .newChooser:
                WelcomeNewChooserView(
                    options: visibleNewOptions,
                    onSelect: { option in handleNewOption(option) },
                    onBack: { goTo(.chooser) }
                )
                .transition(.opacity)
            case .privateSecondaryNotice:
                WelcomeSecondaryNoticeView(
                    onContinue: {
                        leaveWelcome(to: .privateOnboarding) { onSelectPrivateAccount() }
                    },
                    // Al step del que vino, que es el MISMO término que decidió si se mostraba: con dos
                    // cards visibles el usuario pasó por el sub-chooser, y con bypass —el recorrido de
                    // producción de hoy— nunca lo vio, así que devolverlo ahí sería enseñarle una pantalla
                    // nueva al retroceder. Derivarlo de `visibleNewOptions` en vez de recordarlo en un
                    // `@State` es lo que impide que las dos condiciones diverjan.
                    onBack: { goTo(newBranchOriginStep) }
                )
                .transition(.opacity)
            case .privateICloudGate:
                WelcomePrivateICloudGateView(
                    onProceed: {
                        leaveWelcome(to: .privateOnboarding) { onSelectPrivateAccount() }
                    },
                    // La tercera salida del aviso. Se delega en `handleExistingOption` en vez de cruzar el
                    // portal aquí: ese helper YA es el que traduce «restaurar» a su `Destination`, y
                    // escribir la traducción por segunda vez es como divergen dos caminos que deben acabar
                    // en la misma pantalla.
                    onRestore: { handleExistingOption(.restoreICloud) },
                    // Cancelar → la elección privado / nube, que es de donde vino. Mismo término que usa
                    // el aviso de sesión secundaria, y por el mismo motivo: con bypass nunca vio el
                    // sub-chooser, así que mandarlo ahí sería enseñarle una pantalla nueva al retroceder.
                    onBack: { goTo(newBranchOriginStep) },
                    performWipe: performICloudCorpusWipe
                )
                .transition(.opacity)
            case .mirrorRelaunch(let reason):
                WelcomeMirrorRelaunchView(reason: reason)
                    .transition(.opacity)
            }
        }
        .task {
            // DIFERIDOS #34: refresh del remote-config en la ENTRADA (fresh install pre-onboarding
            // puede no tener cache del boot todavía). Min-interval 6 h.
            // Bajo uitest NO se toca red (hermeticidad — los getters ya devuelven el default).
            guard !SwiftDataConfiguration.isUITesting else { return }
            await RemoteConfigClient.shared.refreshIfDue()
        }
    }

    /// **R2 · el único portal de salida del Welcome.** Toda elección que abandona este cover pasa por aquí,
    /// y aquí se decide si antes hay que reabrir la app.
    ///
    /// Está en el CONTAINER y no en los callbacks de `ContentView` por una razón concreta: los destinos se
    /// producen en SEIS sitios (las dos cards del sub-chooser de grupos —«Tengo una invitación» directa y
    /// «Crear mi primer grupo» a través de su puerta—, el sub-chooser existente, el encaminamiento por faro
    /// y las dos cards del sub-chooser nuevo), varios de ellos con bypass, y repartir la comprobación por
    /// los seis es exactamente cómo divergen. Con un portal único, añadir una salida nueva obliga a nombrar
    /// su `Destination`.
    ///
    /// G2 (2026-08-11) movió el primero de nivel: lo producía la card `.invite` del chooser y ahora lo
    /// produce la card de unirse DENTRO del step de grupos. El `Destination` es el MISMO —`.inviteRecovery`,
    /// con su misma fila `requiresMirror`— así que el invitado no pierde nada; lo que cambia es que
    /// `hasShownWelcomeChooser` deja de marcarse al tapear la card de nivel 1, igual que ya pasaba con las
    /// otras dos ramas cuando muestran su 2º nivel.
    ///
    /// G3 (2026-08-11) añadió el sexto, `.groupsOrganizer`, y es el único que pasa por una PUERTA: la card
    /// de crear no llama aquí, va al step `.groupsGate` y es él quien cruza el portal si —y solo si— el
    /// canal está encendido y el device no tiene datos de otro humano.
    ///
    /// Eran SEIS hasta el 2026-08-11 por otra razón: el alert «Detectamos tu cuenta» tenía el suyo
    /// (`.restoreICloud`), y se fue entero con el alert cuando la reentrada pasó a ser decisión del usuario.
    private func leaveWelcome(to destination: WelcomeMirrorRelaunchLogic.Destination,
                              proceed: () -> Void) {
        guard WelcomeMirrorRelaunchLogic.shouldRelaunch(
            destination: destination,
            mountedDecision: SwiftDataConfiguration.personalStoreMountedDecision) else {
            proceed()
            return
        }
        onNeedsMirrorRelaunch(destination)
        goTo(.mirrorRelaunch(.attachMirror))
    }

    /// "Ya tengo una cuenta": con una sola opción visible (prod DARK / uitest) hace
    /// bypass directo — comportamiento idéntico al flujo restore de hoy; con ambas,
    /// muestra el 2º nivel.
    private func handleExistingBranch() {
        if let single = WelcomeAccountChoiceLogic.bypass(visibleExistingOptions) {
            handleExistingOption(single)
        } else {
            goTo(.existingChooser)
        }
    }

    /// R2: el sub-chooser de "Ya tengo una cuenta" y su bypass comparten portal. Solo `restoreICloud`
    /// necesita el mirror; las dos entradas a la cuenta nube montan el mismo store que el neutro ya es.
    private func handleExistingOption(_ option: WelcomeAccountChoiceLogic.ExistingOption) {
        let destination: WelcomeMirrorRelaunchLogic.Destination
        switch option {
        case .restoreICloud: destination = .restoreICloud
        case .cloudSignIn, .googleSignIn: destination = .cloudSignIn
        }
        leaveWelcome(to: destination) { onSelectExistingOption(option) }
    }

    /// "Soy nuevo" (A4). **El faro se consulta ANTES de ofrecer nada** (§k.2 / A26) y, por tanto,
    /// antes de que `ContentView` limpie las prefs residuales del fresh-start: ese orden es el
    /// contrato. Medido el 2026-08-09: `OnboardingResetHelper.safeKeysToClear` son SOLO `userName`
    /// y `defaultCurrencyCode`, así que la limpieza no toca las `yala.cloud.*` del faro — no hay
    /// bug ahí, y el orden se respeta igual para que siga sin haberlo.
    ///
    /// Con una sola opción visible NO se muestra pantalla intermedia: en producción (percent
    /// remoto en 0) y bajo uitest el recorrido es byte-idéntico al de hoy.
    private func handleNewBranch() {
        switch WelcomeNewBranchRouter.route(
            beacon: CloudBeacon(),
            cloudEntryAvailable: cloudEntryAvailable,
            options: visibleNewOptions
        ) {
        case .cloudSignIn(let provider):
            leaveWelcome(to: .cloudSignIn) { onBeaconRoutesToCloudSignIn(provider) }
        case .single(let option):
            handleNewOption(option)
        case .chooser:
            goTo(.newChooser)
        }
    }

    /// De dónde vino quien está en `.privateSecondaryNotice`, y por tanto a dónde lo devuelve su «volver».
    /// Es el MISMO término que `handleNewBranch` usa para decidir si enseña el sub-chooser: con bypass no
    /// hubo 2º nivel y el origen es el chooser de primer nivel.
    ///
    /// Se RE-DERIVA en el «volver» en vez de capturarse al entrar, y conviene ser exacto sobre lo que eso
    /// compra y lo que cuesta: compra que no haya un segundo sitio donde escribir la condición —un `@State`
    /// que alguien actualice mal manda al usuario a una pantalla que no vio—, y cuesta que un refresco de
    /// remote-config entre el tap y el «volver» cambie la respuesta. Esa ventana es estrecha (min-interval
    /// de 6 h, y el `.task` del container ya gastó el suyo al aparecer) y su peor caso es aterrizar en
    /// `.newChooser` en vez de `.chooser`: una pantalla viva, no un camino muerto. El container ya asume
    /// esa misma falta de live-update para las cards que pinta.
    private var newBranchOriginStep: WelcomeFlowStep {
        WelcomeAccountChoiceLogic.bypass(visibleNewOptions) == nil ? .newChooser : .chooser
    }

    private func handleNewOption(_ option: WelcomeAccountChoiceLogic.NewOption) {
        switch option {
        case .privateAccount:
            // **En sesión secundaria se informa ANTES de salir del cover.** Hasta el 2026-09-07 esta rama
            // llevaba a la visita al onboarding privado sin decirle que estaba en el móvil de otra persona,
            // mientras la rama de al lado sí se lo decía: la app se contradecía según por dónde entraras.
            // El descriptor es el predicado canónico —el MISMO que consulta la puerta de la rama
            // organizador— y no el corpus: el detector mide el store de la INVITADA, que en una
            // sesión recién montada está VACÍO y daría vía libre justo en el caso que hay que atender.
            // Informa y no bloquea: el step sale por este mismo portal en cuanto la visita continúa.
            if SecondarySessionStore.isActive() {
                goTo(.privateSecondaryNotice)
                return
            }
            // **Paso 4 · esta rama ya no sale directa por el portal: pasa por la puerta.** Hasta el
            // 2026-09-10 iba a `leaveWelcome(.privateOnboarding)`, y con el mount neutro eso persiste el
            // destino y **NO llama a `onSelectPrivateAccount`** — el único callback que consultaba «¿hay
            // datos?». Resultado medido en device el 2026-09-09: instalación fresca + iCloud con meses de
            // histórico → pantalla de reinicio CIEGA, y al reabrir el onboarding completo montándose
            // encima mientras el espejo bajaba el corpus viejo por debajo.
            //
            // La puerta no sustituye al portal, va DELANTE: su `onProceed` es el mismo
            // `leaveWelcome(to: .privateOnboarding)` de siempre, con su relanzamiento. Lo que cambia es que
            // ya no se cruza sin haber preguntado a iCloud (ADR §9, punto 4).
            //
            // R2: es «Soy nuevo» sin nube, y el que paga el relanzamiento que el alta nube deja de pagar
            // — el reparto que la Opción C aprueba. **Dejó de ser el bypass de producción**: con el percent
            // de la elección nube EN 100 (medido el 2026-09-09) el sub-chooser SÍ se muestra en prod y esta
            // rama es una de sus dos salidas, no la única. Sigue siendo camino ÚNICO donde el percent no
            // llega: device sin snapshot fetcheado (fail-closed), bajo UITest, y si se vuelve el percent a 0.
            goTo(.privateICloudGate)
        case .cloudAccount:
            // A5: el alta born-cloud. El stub explícito de A4 (`showBornCloudPendingAlert`) queda
            // BORRADO en este mismo commit, no silenciado — era una promesa con fecha.
            // R2: pasa por el portal igual que los demás, y sale sin relanzar — que es el chip entero.
            leaveWelcome(to: .cloudAccount) { onSelectCloudAccount() }
        }
    }

    private func goTo(_ next: WelcomeFlowStep) {
        guard step != next else { return }
        let animation: Animation? = reduceMotion ? nil : .smooth(duration: 0.5, extraBounce: 0.1)
        withAnimation(animation) {
            step = next
        }
    }
}
