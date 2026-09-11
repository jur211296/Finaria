//
//  GroupsAssociationSection.swift
//  Yala
//
//  Paso 10 · la sección «Grupos» de «¿Dónde viven tus datos?».
//
//  Hasta aquí esa pantalla solo hablaba del almacenamiento PERSONAL (iCloud o nube, migrar, revertir,
//  estado del sync). El ADR §4 le añade la otra mitad: **la cuenta que esta sesión privada usa para
//  grupos se ve, se deshace y se rehace aquí**.
//
//  Vive en su propio fichero por dos razones y ninguna es de tamaño: (1) el estado que pinta lo decide
//  una tabla pura (`GroupsAssociationLogic.sectionState`) que se fija aparte, y (2) el gesto destructivo
//  tiene DOS salidas —conservar o quitar los movimientos del Panel, decisión de Jürgen del 2026-09-09— y
//  mezclarlas con las cuatro confirmaciones de la migración haría de `StorageConfirmations` un nudo.
//

import SwiftData
import SwiftUI

struct GroupsAssociationSection: View {

    /// Qué hace el CTA de asociar. Lo cablea `ProfileView`, que es quien puede cerrar su sheet: el sheet
    /// del sign-in de Grupos tiene **dueño único** (`GroupsBackendInviteModifier`, anclado en
    /// `ContentView`) y presentarlo encima de Ajustes sería un segundo anchor del mismo sheet, que es lo
    /// que el contrato de presentaciones prohíbe. Opcional para previews y para el resto de call-sites.
    var onAssociate: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(AppPreferences.self) private var appPreferences

    @State private var confirmDetach = false
    /// El aviso de bloqueo de ESTE gesto. **Propio y no el de `ProfileView`**: aquel dice «No pudimos
    /// cerrar tu sesión», que es otra cosa y en una secundaria llega a ofrecer salir de la sesión entera a
    /// quien solo pidió soltar una cuenta de grupos. Y sin él, `phase` se queda en `.blocked` y el toque
    /// siguiente cae en el `guard phase == .idle` de `detachGroupsAccount`: **no pasa nada, sin un solo
    /// mensaje**. Cerrarlo llama a `acknowledgeBlocked()`, que es lo que devuelve la fase a `.idle`.
    @State private var blockedReason: CloudSignOutFlowLogic.BlockReason?
    /// Re-lee el estado tras cada gesto. La sesión en la nube NO es observable
    /// (`CloudAuthService` no publica nada), así que la pantalla se refresca por toques, igual que el
    /// resto de esta fila, que vive de un poll de 1 s.
    @State private var refreshTick = false

    private var signOutCoordinator: CloudSessionSignOut { CloudSessionSignOut.shared }

    private var state: GroupsAssociationLogic.SectionState {
        _ = refreshTick
        return GroupsAssociationLogic.sectionState(
            deviceState: CloudIdentityRoutingLogic.deviceState(
                hasCompletedOnboarding: appPreferences.hasCompletedOnboarding,
                storageMode: StorageModePersistence.read(),
                onboardingMode: OnboardingMode.current()),
            hasPersistedAssociation: GroupsAccountAssociation.shared.hasAssociation,
            hasLiveGroupsSession: CloudAuthService.shared.hasSession)
    }

    var body: some View {
        if state != .notApplicable {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // **El identifier va en el TÍTULO y no en el `VStack`.** Aplicado al contenedor pisa el
                // de todos sus hijos, y los botones de la sección dejan de existir con su propio id en el
                // árbol de accesibilidad: es la regla medida en `.claude/rules/testing.md`, y aquí costó
                // una corrida de XCUITest con tres rojos mudos.
                Text(L10n.Storage.Groups.title)
                    .font(DS.Typography.headline)
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("storage_groups_section")

                Text(bodyText)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)

                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .storageGroupsCardStyle()
            .confirmationDialog(
                L10n.Storage.Groups.detachTitle,
                isPresented: $confirmDetach,
                titleVisibility: .visible
            ) {
                // Las DOS salidas son botones de la MISMA hoja, y el orden no es casual: conservar va
                // primero porque es la que no destruye nada. Ninguna de las dos es `.destructive` a
                // secas — quitar sí lo es, conservar no lo es en absoluto.
                Button(L10n.Storage.Groups.detachKeep) { detach(.keep) }
                    .accessibilityIdentifier("storage_groups_detach_keep")
                Button(L10n.Storage.Groups.detachRemove, role: .destructive) { detach(.remove) }
                    .accessibilityIdentifier("storage_groups_detach_remove")
                Button(L10n.Common.cancel, role: .cancel) {}
                    .accessibilityIdentifier("storage_groups_detach_cancel")
            } message: {
                Text(L10n.Storage.Groups.detachBody)
            }
            .alert(
                L10n.Storage.Groups.detachBlockedTitle,
                isPresented: Binding(
                    get: { blockedReason != nil },
                    set: { if !$0 { dismissBlocked() } })
            ) {
                // Texto LITERAL en los botones del alert: un label que dependa del `@State` rompe flujos
                // de la app que no tienen nada que ver con esta pantalla (medido el 2026-09-06).
                Button(L10n.Common.ok) { dismissBlocked() }
            } message: {
                Text(blockedMessage)
            }
        }
    }

    /// El aviso se cierra soltando TAMBIÉN la fase del coordinador. Si solo se bajara el `@State`, el
    /// `guard phase == .idle` dejaría inertes el desasociar Y el cierre de sesión de Ajustes.
    private func dismissBlocked() {
        blockedReason = nil
        signOutCoordinator.acknowledgeBlocked()
    }

    private var blockedMessage: String {
        switch blockedReason {
        case .sessionExpired: return L10n.Storage.Groups.detachBlockedSession
        case .permanent: return L10n.Storage.Groups.detachBlockedPermanent
        default: return L10n.Storage.Groups.detachBlockedTransient
        }
    }

    // MARK: - Cuerpo

    private var bodyText: String {
        switch state {
        case .noAccount:
            return L10n.Storage.Groups.noAccountBody
        case .associated:
            guard let cuenta = accountDisplayName else { return L10n.Storage.Groups.associatedUnnamedBody }
            return L10n.Storage.Groups.associatedBody(cuenta)
        case .associatedNeedsSignIn:
            guard let cuenta = accountDisplayName else { return L10n.Storage.Groups.needsSignInUnnamedBody }
            return L10n.Storage.Groups.needsSignInBody(cuenta)
        case .sameAccountAsPersonal:
            return L10n.Storage.Groups.sameAccountBody
        case .notApplicable:
            return ""
        }
    }

    /// Cómo se nombra la cuenta, o `nil` si no hay con qué. **Nunca se inventa un correo**: ver
    /// `GroupsAssociationLogic.DisplayName`.
    ///
    /// Devuelve el NOMBRE y no aplica la plantilla, aunque eso obligue a repetir el `guard` en los dos
    /// casos que la usan: pasar `L10n.Storage.Groups.associatedBody` como valor de primera clase convierte
    /// una función aislada al `MainActor` en un closure, y eso deja un warning de aislamiento en cada
    /// call-site.
    private var accountDisplayName: String? {
        let record = GroupsAccountAssociation.shared.read()
        switch GroupsAssociationLogic.displayName(
            email: record?.email ?? CloudAuthService.shared.capturedEmail(),
            provider: record?.provider ?? CloudAuthService.shared.storedProvider()
        ) {
        case .email(let correo):
            return correo
        case .provider(let metodo):
            return metodo == .apple
                ? L10n.Settings.yalaAccountMethodApple
                : L10n.Settings.yalaAccountMethodGoogle
        case .unnamed:
            return nil
        }
    }

    // MARK: - Acciones

    @ViewBuilder
    private var actions: some View {
        if isWorking {
            HStack(spacing: DS.Spacing.sm) {
                ProgressView()
                Text(signOutCoordinator.waitingForPending
                     ? L10n.Storage.Groups.detachWaiting
                     : L10n.Storage.Groups.detachWorking)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("storage_groups_working")
        } else {
            if GroupsAssociationLogic.offersAssociate(state), let onAssociate {
                Button(action: onAssociate) {
                    Text(L10n.Storage.Groups.associateButton)
                        .font(DS.Typography.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("storage_groups_associate_button")
            }
            if state == .associatedNeedsSignIn, let onAssociate {
                // La sesión no viajó, la asociación sí: entrar es el MISMO gesto que asociar (pasa por
                // [I] con la cuenta que ya está registrada), así que no hay un camino nuevo que probar.
                Button(action: onAssociate) {
                    Text(L10n.Storage.Groups.signInButton)
                        .font(DS.Typography.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("storage_groups_signin_button")
            }
            if GroupsAssociationLogic.offersDetach(state) {
                Button {
                    confirmDetach = true
                } label: {
                    Text(L10n.Storage.Groups.detachButton)
                        .font(DS.Typography.body.weight(.medium))
                        .foregroundStyle(DS.Semantic.warningForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(DS.Semantic.warningForeground)
                .accessibilityIdentifier("storage_groups_detach_button")
            }
        }
    }

    /// `phase` es del coordinador, que también lleva el cierre de sesión: un cierre en curso pintaría
    /// «Desasociando…» aquí. `detachInFlight` acota el spinner a NUESTRO gesto.
    @State private var detachInFlight = false

    private var isWorking: Bool { detachInFlight && signOutCoordinator.phase == .working }

    private func detach(_ choice: GroupsAssociationDetach.BridgedRowsChoice) {
        detachInFlight = true
        Task { @MainActor in
            defer { detachInFlight = false }
            await signOutCoordinator.detachGroupsAccount(context: modelContext, choice: choice)
            // La fase se lee DESPUÉS del `await`, que es cuando el coordinador ya la dejó puesta.
            if case .blocked(_, let reason) = signOutCoordinator.phase { blockedReason = reason }
            refreshTick.toggle()
        }
    }
}

// MARK: - Estilo

private extension View {
    /// Mismo estilo que las cards de esta pantalla. Duplicado del `storageCardStyle` de
    /// `StorageSettingsView`, que es `fileprivate` allí; unificarlo movería un helper de estilo a un
    /// tercer sitio sin que nadie más lo pida.
    func storageGroupsCardStyle() -> some View {
        self
            .padding(DS.Spacing.lg)
            .background(.thCard)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl))
            .padding(.horizontal, DS.Spacing.lg)
    }
}
