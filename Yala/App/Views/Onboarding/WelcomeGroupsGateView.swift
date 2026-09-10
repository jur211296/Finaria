//
//  WelcomeGroupsGateView.swift
//  Yala
//
//  G3 de Grupos-first · **el primer paso de la rama organizador no pide nada: comprueba la puerta.**
//
//  Es un STEP del `WelcomeFlowContainer` y no una pantalla propia de `ContentView`, por las tres razones
//  medidas que el spec fija para `.groupsChooser` y `.mirrorRelaunch`: el portal `leaveWelcome` es el
//  único punto de salida del cover, una presentación nueva del anchor de `ContentView` tendría que entrar
//  a la matriz de readiness (regla 3 de Presentaciones), y un step que se queda DENTRO ya está cubierto
//  por `showWelcomeFlow`, que es el blocker de la cadena entera.
//
//  Y **no puede ser un `.alert(`**: `WelcomeHeroReentryTests` lo prohíbe por source-scan en el container.
//  Aquí no hace falta ninguna excepción — un alert además contaría como camino muerto en un flujo que el
//  spec exige que jamás lo tenga. Por eso el segundo gesto de la rama sin iCloud es una PANTALLA más
//  (`.confirmingWipe`), el mismo molde que usa la puerta privada del paso 4.
//
//  **El `force: true` del refresh no es cosmético.** Sin él, `refreshIfDue` es un no-op exactamente en el
//  caso del bug: el min-interval es de 6 h y el arranque ya gastó la ventana con su propio refresh
//  fire-and-forget. La regla —«la intención del usuario ES evidencia de que el canal debería estar
//  encendido»— está escrita en `GroupInviteChannelRoutingLogic`, que la aplica al recibir un link backend.
//
//  ## Paso 5-b (2026-09-10): esta puerta ya no bloquea al dueño de los datos
//
//  Hasta hoy, un teléfono que ya había bajado su iCloud por otra rama recibía «aquí ya hay datos
//  guardados… crea el grupo desde la app que ya usas», con un solo botón «Volver» — y la app que ya usa
//  **es ésta**. Medido en device el 2026-09-09 sobre el propio Jürgen. Ahora ese caso **vuelve al
//  neutro**: se sube a iCloud lo que faltara, se arma el borrado de arranque
//  (`StorageModePersistence.armSignOutWipe`, que borra ARCHIVOS pre-mount y jamás filas, así que nada se
//  exporta como delete) y se le pide reabrir. El contenedor de iCloud queda intacto.
//
//  **⚠️ Sin terminar: la rama `.returnToNeutral` NO llega a borrar nada** — el borrado que necesita espera
//  al paso 9 (decisión de Jürgen, 2026-09-10). Ver el aviso de `GroupsNeutralReturnLogic` y el ticket
//  `tickets/blocked/groups-entry-on-a-mirrored-store-still-blocks-the-owner.md`.
//
//  **Esta vista no escribe nada**, igual que antes: quien arma y persiste el destino es `ContentView`
//  (`onNeedsNeutralReturn`), por la misma razón que `onNeedsMirrorRelaunch` — el container y sus steps no
//  tocan `UserDefaults` ni los flags de onboarding.
//

import SwiftUI

struct WelcomeGroupsGateView: View {

    /// Fetch VIVO del corpus personal, no un snapshot: el mirror de iCloud puede estar re-importando
    /// mientras el usuario mira estas pantallas.
    ///
    /// **Es el detector ESTRECHO** (`checkHasPersonalData`) y no el ancho: el ancho cuenta grupos y filas
    /// puenteadas, que el borrado de arranque no se lleva (ADR §6), así que con él quien tenga grupos
    /// locales volvería a esta puerta tras reabrir y la app le pediría reabrir otra vez, para siempre.
    let hasPersonalDataNow: @MainActor @Sendable () -> Bool
    /// Sube a iCloud lo que quede pendiente y devuelve si ya es seguro borrar lo local. Vive en
    /// `ContentView` porque necesita el `modelContext` (`forceSync` hace `save()`), igual que
    /// `performICloudCorpusWipe`; el veredicto lo da `GroupsNeutralReturnLogic`.
    let attemptPersonalUpload: @MainActor () async -> GroupsNeutralReturnLogic.Verdict
    /// La puerta abrió: seguir a `leaveWelcome(to: .groupsOrganizer)`.
    var onProceed: () -> Void
    /// Vuelta al neutro autorizada: armar el borrado de arranque, persistir el destino y montar el
    /// terminal de «reabre Yala». Es el ÚNICO efecto durable de este step, y no lo hace él.
    var onNeedsNeutralReturn: () -> Void
    /// Vuelta al step de los dos caminos. También es el CTA de las pantallas de bloqueo — «vuelve al
    /// chooser con todas las demás vías intactas», que es la mitad de «ningún camino muerto».
    var onBack: () -> Void

    /// `nil` mientras se comprueba. No se inicializa a `.proceed` a propósito: un default optimista pinta
    /// medio frame de la rama buena antes de bloquear.
    @State private var decision: GroupsOrganizerGateLogic.Decision?
    @State private var phase: Phase = .idle
    /// **El disparador del `.task`, y existe para que reintentar sea ESTRUCTURADO.** La primera versión
    /// lanzaba `Task { await runNeutralReturn(...) }` desde el botón: una tarea no estructurada que
    /// **nadie cancela al desmontar el step**, así que el `guard !Task.isCancelled` de `runNeutralReturn`
    /// —el que promete que «quien tapea volver no acaba con un borrado armado a sus espaldas»— era código
    /// muerto justo en el único camino con un botón. Cazado por la review adversarial del 2026-09-10.
    ///
    /// Subirlo re-dispara el `.task`, que **re-evalúa la puerta entera** y no solo la subida: entre el
    /// primer intento y el reintento pueden haber cambiado el canal, la sesión o el propio corpus.
    @State private var evaluationToken = 0
    /// El segundo gesto de la rama sin respaldo. **También es un `.task(id:)` y no un `Task {}`**, por lo
    /// mismo que el de arriba: lo que hay al otro lado escribe el arm del borrado, y una tarea que
    /// sobrevive al desmontaje puede armarlo cuando la persona ya se fue a otra pantalla.
    @State private var confirmedWipeWithoutBackup = false

    /// El estado DENTRO de las dos ramas que hacen algo. Separado de `decision` porque el veredicto de la
    /// puerta no cambia mientras la subida se reintenta: lo que cambia es en qué punto va.
    private enum Phase: Equatable {
        case idle
        /// Subiendo a iCloud lo pendiente antes de tocar nada.
        case uploading
        /// No se pudo confirmar la subida. **Nada armado, nada borrado**: el teléfono está como estaba.
        case waitingForUpload
        /// Segundo gesto de la rama sin iCloud, donde el borrado no es reversible.
        case confirmingWipe
    }

    var body: some View {
        WelcomeFlowScreen { logoTopSpacing in
            VStack(spacing: 0) {
                Spacer(minLength: logoTopSpacing)

                Image("YalaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 128)
                    .colorMultiply(.white)
                    .accessibilityHidden(true)

                Spacer(minLength: DS.Spacing.xl)

                switch decision {
                case nil, .proceed:
                    // `.proceed` no pinta nada propio: el step se desmonta en la misma vuelta en que se
                    // decide, así que enseñar una pantalla de éxito sería un parpadeo.
                    checkingContent
                case .blockedChannelOff:
                    blockedContent(
                        icon: "person.2.slash",
                        title: L10n.Welcome.Groups.channelOffTitle,
                        body: L10n.Welcome.Groups.channelOffBody,
                        identifier: "welcome_groups_gate_channel_off")
                case .blockedSecondarySession:
                    // C3 · estás de visita en el móvil de otra persona. Copy PROPIO: el hecho no es «hay
                    // datos de otro humano» sino «esta sesión no es de este dispositivo», y aquí sí hay
                    // salida (cerrar la sesión de invitado y volver desde el suyo).
                    blockedContent(
                        icon: "person.crop.circle.badge.clock",
                        title: L10n.Welcome.Groups.secondaryTitle,
                        body: L10n.Welcome.Groups.secondaryBody,
                        identifier: "welcome_groups_gate_secondary_session")
                case .blockedCleanupFailed:
                    // El borrado de arranque estaba armado y este proceso montó igual ⇒ no corrió. Se
                    // dice y se para: pedir «reabre» otra vez sería el bucle.
                    blockedContent(
                        icon: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
                        title: L10n.Welcome.Groups.cleanupFailedTitle,
                        body: L10n.Welcome.Groups.cleanupFailedBody,
                        identifier: "welcome_groups_gate_cleanup_failed")
                case .returnToNeutral:
                    neutralReturnContent
                case .askBeforeWiping:
                    noBackupContent
                }

                Spacer(minLength: DS.Spacing.xl)
            }
        }
        .welcomeBackButton(tint: .white, action: onBack)
        .task(id: evaluationToken) {
            await evaluate()
        }
        .task(id: confirmedWipeWithoutBackup) {
            guard confirmedWipeWithoutBackup else { return }
            await runNeutralReturn(mirrorsToICloud: false)
        }
    }

    // MARK: - Contenido

    private var checkingContent: some View {
        VStack(spacing: DS.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text(L10n.Welcome.Groups.checking)
                .font(DS.Typography.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
        }
        .accessibilityIdentifier("welcome_groups_gate_checking")
    }

    /// La vuelta al neutro con espejo vivo: **se informa, no se pregunta** (decisión de Jürgen,
    /// 2026-09-09). La única pantalla con botón es la de esperar, y su botón es reintentar.
    @ViewBuilder
    private var neutralReturnContent: some View {
        // **Exhaustivo y sin `default:`** (review adversarial, 2026-09-10): con un `default` que agrupe,
        // añadir una fase mañana renderiza la pantalla equivocada sin que el compilador diga nada — y en
        // un flujo que borra datos, la pantalla equivocada puede ser la que confirma.
        switch phase {
        case .waitingForUpload:
            VStack(spacing: DS.Spacing.lg) {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 44)) // A11Y-DT: icono decorativo hero, tamaño fijo (patrón del flow)
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityHidden(true)

                textBlock(title: L10n.Welcome.Groups.neutralReturnWaitTitle,
                          body: L10n.Welcome.Groups.neutralReturnWaitBody)

                YalaPrimaryButton(L10n.Action.retry) {
                    decision = nil
                    phase = .idle
                    evaluationToken += 1
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
            .accessibilityIdentifier("welcome_groups_gate_upload_wait")
        case .idle, .uploading, .confirmingWipe:
            VStack(spacing: DS.Spacing.lg) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                textBlock(title: L10n.Welcome.Groups.neutralReturnTitle,
                          body: L10n.Welcome.Groups.neutralReturnBody)
            }
            .accessibilityIdentifier("welcome_groups_gate_neutral_return")
        }
    }

    /// La rama sin iCloud: aquí el borrado **no es reversible**, así que se pregunta y con segundo gesto.
    @ViewBuilder
    private var noBackupContent: some View {
        switch phase {
        case .confirmingWipe:
            VStack(spacing: DS.Spacing.lg) {
                Image(systemName: "trash")
                    .font(.system(size: 44)) // A11Y-DT: icono decorativo hero, tamaño fijo (patrón del flow)
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityHidden(true)

                textBlock(title: L10n.Welcome.Groups.noBackupConfirmTitle,
                          body: L10n.Welcome.Groups.noBackupConfirmBody)

                YalaPrimaryButton(L10n.Welcome.Groups.noBackupConfirmCta) {
                    confirmedWipeWithoutBackup = true
                }
                // Mismo caso que el botón de la pantalla anterior: el id del contenedor manda.
                .padding(.horizontal, DS.Spacing.xl)
            }
            .accessibilityIdentifier("welcome_groups_gate_no_backup_confirm")
        case .idle, .uploading, .waitingForUpload:
            VStack(spacing: DS.Spacing.lg) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 44)) // A11Y-DT: icono decorativo hero, tamaño fijo (patrón del flow)
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityHidden(true)

                textBlock(title: L10n.Welcome.Groups.noBackupTitle,
                          body: L10n.Welcome.Groups.noBackupBody)

                YalaPrimaryButton(L10n.Welcome.Groups.noBackupWipe) {
                    phase = .confirmingWipe
                }
                // **Sin identifier propio, y no es un olvido: uno aquí NO EXISTIRÍA en runtime.** El id
                // del VStack contenedor pisa el de sus hijos, así que el botón sale del árbol de
                // accesibilidad como `button|…|welcome_groups_gate_no_backup` — medido con un snapshot del
                // árbol real el 2026-09-10, que es lo que `.claude/rules/testing.md` (L95) manda hacer
                // antes de tocar el test. El XCUITest lo tapea por el id del contenedor.
                .padding(.horizontal, DS.Spacing.xl)
            }
            .accessibilityIdentifier("welcome_groups_gate_no_backup")
        }
    }

    private func textBlock(title: String, body: String) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Text(title)
                .font(DS.Typography.title2)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(body)
                .font(DS.Typography.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private func blockedContent(icon: String, title: String, body: String, identifier: String) -> some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 44)) // A11Y-DT: icono decorativo hero, tamaño fijo (patrón del flow)
                .foregroundStyle(.white.opacity(0.8))
                .accessibilityHidden(true)

            textBlock(title: title, body: body)

            YalaPrimaryButton(L10n.Welcome.Groups.gateBack) {
                onBack()
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .accessibilityIdentifier(identifier)
    }

    // MARK: - La puerta

    /// El orden es el del spec y **no se puede reordenar**: primero se re-mide el canal (con `force`),
    /// después se decide, y **solo `.proceed` continúa**. Esta función no escribe nada en `UserDefaults`
    /// — ni ella ni ninguna a la que llame — y eso es la mitad del chip: `onboardingMode` es
    /// never-downgrade cross-device, así que una escritura prematura viaja al iKV y no vuelve.
    private func evaluate() async {
        // Hermeticidad: bajo `-uitest` no se toca red, igual que el `.task` del container. Los getters ya
        // devuelven su default (ON bajo `Yala Dev`), así que el XCUITest recorre la rama buena.
        if !SwiftDataConfiguration.isUITesting {
            await RemoteConfigClient.shared.refreshIfDue(force: true)
        }

        // El `.task` se cancela al desmontar el step, pero la CANCELACIÓN ES COOPERATIVA: `refreshIfDue`
        // solo la mira entre el fetch ajeno que espera y el suyo —nunca dentro de un fetch en curso—, así
        // que sin este guard un usuario que tapea «volver» durante el refresh saldría del Welcome igual
        // cuando la red conteste. Es el único punto de suspensión de la rama.
        guard !Task.isCancelled else { return }

        let mirrorsToICloud = ICloudPersonalCorpusProbe.mirrorsToICloudNow()
        let verdict = GroupsOrganizerGateLogic.decide(
            channelEnabled: CloudSyncFlags.groupsBackendEnabled,
            // C3 · el descriptor, no el corpus: en secundaria el detector de abajo mide el store de la
            // INVITADA (vacío en una sesión recién montada) y daría vía libre justo donde el alta escribe
            // las seis preferencias en el `UserDefaults` del DUEÑO.
            isSecondarySession: SecondarySessionStore.isActive(),
            // El testigo del mount, y no «¿hay iCloud?»: lo que importa es si lo que esta sesión escriba
            // va a subir al iCloud del Apple ID de este teléfono.
            mirrorsToICloud: mirrorsToICloud,
            hasPersonalData: hasPersonalDataNow(),
            cleanupAlreadyArmed: StorageModePersistence.isSignOutWipeArmed())

        decision = verdict
        switch verdict {
        case .proceed:
            onProceed()
        case .returnToNeutral:
            // Se informa y se trabaja en la misma vuelta: esta rama no pide confirmación (decisión de
            // Jürgen) porque lo que hay al otro lado sigue guardado en iCloud.
            await runNeutralReturn(mirrorsToICloud: mirrorsToICloud)
        case .askBeforeWiping, .blockedChannelOff, .blockedSecondarySession, .blockedCleanupFailed:
            // Las cuatro esperan al usuario: `.askBeforeWiping` a su segundo gesto, las otras tres a que
            // vuelva. Ninguna escribe nada.
            break
        }
    }

    /// **El único camino que llega a armar el borrado, y por eso la subida se decide aquí y no en dos
    /// sitios.** Lo llaman las dos ramas: la del espejo vivo (que sube antes) y la del segundo gesto de
    /// la rama sin iCloud (que no tiene dónde subir, y cuya autorización es el gesto).
    private func runNeutralReturn(mirrorsToICloud: Bool) async {
        // **La señal de restore se apaga ANTES de tocar nada, y es un criterio del ticket.** Un restore
        // que nadie declara terminado deja a las otras puertas —`CrossAccountEntryGuardLogic` consume la
        // misma señal— creyendo que este dispositivo está bajando datos de su dueño. Vive en memoria y
        // muere con el proceso, así que el daño está acotado, pero mientras el proceso vive es una
        // afirmación falsa que otra puerta va a leer.
        ICloudRestoreSessionSignal.noteRestoreFinished()

        guard GroupsNeutralReturnLogic.requiresUploadBeforeWipe(mirrorsToICloud: mirrorsToICloud) else {
            onNeedsNeutralReturn()
            return
        }

        phase = .uploading
        let verdict = await attemptPersonalUpload()
        // Misma cancelación cooperativa que arriba: quien tapea «volver» mientras CloudKit contesta no
        // puede acabar con un borrado armado a sus espaldas.
        guard !Task.isCancelled else { return }

        switch verdict {
        case .safeToArmWipe:
            onNeedsNeutralReturn()
        case .waitForUpload:
            phase = .waitingForUpload
        }
    }
}
