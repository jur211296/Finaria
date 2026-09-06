//
//  GroupSettingsView.swift
//  Yala
//
//  Sheet de ajustes del grupo — info, miembros, opciones, acciones destructivas.
//

import SwiftUI
import SwiftData

struct GroupSettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.yalaTheme) private var theme
    @Environment(AppPreferences.self) private var appPreferences
    @Environment(SessionState.self) private var sessionState

    // MARK: - Input

    let group: SplitGroup
    @Bindable var viewModel: GroupDetailViewModel

    // MARK: - State

    @State private var editName: String = ""
    @State private var editIconName: String = ""
    @State private var editColorHex: String = ""
    @State private var showIconPicker: Bool = false
    @State private var simplifyDebts: Bool = false
    @State private var showDebtsInSingleCurrency: Bool = false
    @State private var selectedCurrency: CurrencyCode = .pen
    @State private var showCurrencyPicker: Bool = false
    @State private var defaultSplitType: SplitType = .equal

    @State private var showArchiveConfirm = false

    /// Cache del check `anyMemberHasOutstandingBalance` para evitar 4 fetches SwiftData
    /// por cada re-evaluación del body de SwiftUI. Se recalcula en `.onAppear` +
    /// `.onChange(of: sessionState.dataVersion)`.
    @State private var hasOutstandingDebt: Bool = false

    // Leave group
    @State private var showLeaveGroupConfirm = false
    @State private var isLeavingGroup = false
    @State private var showLeaveError = false
    @State private var leaveErrorMessage: String = ""
    @State private var showActionError = false
    @State private var actionErrorMessage: String = ""

    // FU-02: soft-delete owner-only.
    @State private var showDeleteConfirm: Bool = false
    @State private var isDeleting: Bool = false

    // Transferir y salir (owner con co-members en canal backend).
    /// Cache de `GroupService.ownerExitOffer`, recalculado en el MISMO sitio que `hasOutstandingDebt`
    /// (del que depende). `nil` hasta el primer `.onAppear` → el body cae al `fallbackOffer`, que es
    /// byte-a-byte lo que esta pantalla hacía antes de existir la transferencia.
    @State private var ownerExitOffer: GroupOwnerExitLogic.Offer?
    /// A quién iría el grupo. Se NOMBRA en la confirmación: el servidor elige heredero por su cuenta
    /// y el usuario tiene derecho a saber quién antes de confirmar algo irreversible para él.
    @State private var designatedHeirName: String?
    @State private var showTransferConfirm = false
    @State private var isTransferring = false
    /// El servidor ya dijo `no_eligible_owner` en esta sesión. Apaga la oferta hasta que llegue dato
    /// nuevo: los conteos locales no cambian con ese rechazo, así que sin esto la pantalla vuelve a
    /// ofrecer la transferencia y a nombrar al mismo heredero fantasma, en bucle.
    @State private var transferRefusedByServer = false


    // MARK: - Qué salida se ofrece

    /// El offer cacheado, o —antes del primer cálculo— exactamente lo que esta pantalla ofrecía
    /// hasta ahora. El fallback NO es defensivo por costumbre: `ownerExitOffer` necesita fetches de
    /// SwiftData y se calcula en `.onAppear`, así que hay un primer render sin él. Sin este camino,
    /// ese render escondería «Salir» y «Eliminar» a todo el mundo durante un frame.
    private var currentOffer: GroupOwnerExitLogic.Offer {
        ownerExitOffer ?? GroupOwnerExitLogic.Offer(
            showsLeave: !group.isOwner,
            showsTransferAndLeave: false,
            showsDelete: group.isOwner,
            deleteEnabled: !hasOutstandingDebt,
            deleteHint: hasOutstandingDebt ? .debtNoTransferAvailable : nil)
    }

    /// Mensaje de la confirmación de «Transferir y salir»: quién hereda, y —si el usuario tiene saldo
    /// propio— el aviso de que sale con él.
    ///
    /// El aviso va como PÁRRAFO aparte y no como frase compuesta: son dos hechos independientes y
    /// concatenarlos dentro de una sola clave obligaría a cuatro variantes (con/sin nombre ×
    /// con/sin deuda) en dieciséis idiomas.
    ///
    /// Que exista es lo que iguala esta salida con las otras dos: «Salir del grupo» avisa con
    /// `leaveGroupWithDebtWarning` y «Archivar» con `archiveWithDebtWarning`. Ésta era la única que
    /// callaba, y encima es la que borra el histórico local del grupo al salir — el usuario perdía
    /// de vista quién le debía sin que nadie se lo hubiera dicho.
    private var transferConfirmMessage: String {
        // La llamada va explícita y no como referencia a función (`.map(L10n…transferAndLeaveConfirm)`):
        // pasarla como valor la saca del contexto `@MainActor` y el compilador avisa.
        let base: String
        if let name = designatedHeirName {
            base = L10n.Groups.Settings.transferAndLeaveConfirm(name)
        } else {
            base = L10n.Groups.Settings.transferAndLeaveConfirmUnknownHeir
        }
        guard hasOutstandingBalance else { return base }
        return base + "\n\n" + L10n.Groups.Settings.transferAndLeaveDebtWarning
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xxl) {
                    // Info section
                    infoSection

                    // Group options section — visible para todos los miembros activos.
                    // simplify/split los edita cualquiera; moneda única queda owner-only (dimmed).
                    if viewModel.canCurrentUserParticipate {
                        optionsSection
                    }

                    // Integración personal (F4): visible solo para members .isActive.
                    if viewModel.canCurrentUserParticipate {
                        personalIntegrationSection
                    }

                    // Leave group (non-owner)
                    if currentOffer.showsLeave {
                        leaveGroupSection
                    }

                    // Danger zone (archive)
                    if viewModel.isCurrentUserAdmin {
                        dangerZoneSection
                    }

                    // Transferir y salir — la salida del DUEÑO. Va antes de «Eliminar» a propósito:
                    // es la acción reversible para el grupo (sigue vivo, con sus saldos), y el hint
                    // del borrado bloqueado apunta aquí arriba.
                    if currentOffer.showsTransferAndLeave {
                        transferAndLeaveSection
                    }

                    // FU-02: soft-delete (owner-only).
                    if currentOffer.showsDelete {
                        deleteGroupSection
                    }

                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.xl)
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .yalaScreenBackground(.subtle)
            .onDisappear { saveIdentity() }
            .onAppear { recomputeOwnerExit() }
            .onChange(of: sessionState.dataVersion) { _, _ in
                // Llegó dato nuevo: el rechazo del servidor deja de ser la información más fresca
                // que tenemos, así que la oferta puede volver a evaluarse con los conteos de ahora.
                transferRefusedByServer = false
                recomputeOwnerExit()
            }
            .navigationTitle(L10n.Groups.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    YalaToolbarButton(systemName: "xmark", label: L10n.Action.close) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCurrencyPicker) {
                NavigationStack {
                    CurrencySelectorView(selectedCurrency: $selectedCurrency)
                }
            }
            .confirmationDialog(
                L10n.Groups.Settings.leaveGroup,
                isPresented: $showLeaveGroupConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.Groups.Settings.leaveGroup, role: .destructive) {
                    Task { await leaveGroup() }
                }
            } message: {
                if hasOutstandingBalance {
                    Text(L10n.Groups.Settings.leaveGroupWithDebtWarning)
                } else {
                    Text(L10n.Groups.Settings.leaveGroupConfirm)
                }
            }
            .confirmationDialog(
                L10n.Groups.Settings.archive,
                isPresented: $showArchiveConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.Groups.Settings.archive, role: .destructive) {
                    performArchiveToggle(isArchiving: true)
                }
            } message: {
                if hasOutstandingDebt {
                    Text(L10n.Groups.Settings.archiveWithDebtWarning)
                } else {
                    Text(L10n.Groups.Settings.archiveConfirm)
                }
            }
            .alert(L10n.Common.error, isPresented: $showLeaveError) {
                Button(L10n.Common.ok) {}
            } message: {
                Text(leaveErrorMessage)
            }
            .alert(L10n.Common.error, isPresented: $showActionError) {
                Button(L10n.Common.ok) {}
            } message: {
                Text(actionErrorMessage)
            }
            .confirmationDialog(
                L10n.Groups.Settings.deleteGroupConfirm,
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.Action.delete, role: .destructive) {
                    Task { await performSoftDelete() }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Groups.Settings.deleteGroupFinalConfirm)
            }
            .confirmationDialog(
                L10n.Groups.Settings.transferAndLeave,
                isPresented: $showTransferConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.Groups.Settings.transferAndLeave, role: .destructive) {
                    Task { await transferAndLeave() }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                // El nombre del heredero es el punto del diálogo. Si por lo que sea no se pudo
                // resolver, se dice el hecho sin nombre en vez de callarlo: nombrar a quien no toca
                // sería peor que no nombrar.
                Text(transferConfirmMessage)
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        SectionBox(title: L10n.Groups.Settings.info) {
            HStack(spacing: DS.Spacing.md) {
                if viewModel.isCurrentUserAdmin {
                    // Group icon — tappable to change (admin only)
                    Button {
                        showIconPicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: editColorHex))
                                .frame(width: 48, height: 48) // A11Y-DT: fixed icon size matching CategoryDetailView pattern

                            Image(systemName: editIconName)
                                .font(DS.Typography.title2)
                                .foregroundStyle(.white)

                            // A11Y-DT: decorative edit badge on group icon
                            Image(systemName: "pencil.circle.fill")
                                .font(DS.Typography.label)
                                .foregroundStyle(Color(hex: editColorHex))
                                .background(Circle().fill(.white).frame(width: 16, height: 16))
                                .offset(x: 16, y: 16)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Groups.Form.icon)

                    // Group name — editable inline (admin only)
                    TextField(L10n.Groups.Form.namePlaceholder, text: $editName)
                        .font(DS.Typography.headline)
                        .onSubmit { saveIdentity() }
                } else {
                    // Group icon — static (non-admin)
                    ZStack {
                        Circle()
                            .fill(Color(hex: editColorHex))
                            .frame(width: 48, height: 48) // A11Y-DT: fixed icon size matching CategoryDetailView pattern

                        Image(systemName: editIconName)
                            .font(DS.Typography.title2)
                            .foregroundStyle(.white)
                    }

                    // Group name — read-only (non-admin)
                    Text(editName)
                        .font(DS.Typography.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.FormRow.paddingH)
            .padding(.vertical, DS.FormRow.paddingV)
        }
        .onAppear {
            editName = group.name
            editIconName = group.iconName
            editColorHex = group.colorHex
        }
        .sheet(isPresented: $showIconPicker, onDismiss: {
            saveIdentity()
        }) {
            IconColorPickerSheet(
                selectedIconName: $editIconName,
                selectedColorHex: $editColorHex
            )
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        SectionBox(title: L10n.Groups.Settings.options) {
            VStack(spacing: DS.Spacing.none) {
                // Simplify Debts — cualquier miembro activo
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Toggle(L10n.Groups.Form.simplifyDebts, isOn: $simplifyDebts)
                        .font(DS.Typography.body)

                    Text(L10n.Groups.Form.simplifyDebtsHint)
                        .font(DS.Typography.captionSmall)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .onChange(of: simplifyDebts) { _, newValue in
                    // Guard de igualdad: el `.onAppear` siembra el @State desde el group, lo que
                    // dispararía un save+sync espurio en cada apertura sin este check.
                    guard newValue != group.simplifyDebts else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        updateMemberOption { $0.simplifyDebts = newValue }
                    }
                }

                Divider()
                    .padding(.leading, DS.FormRow.paddingH)

                // Show debts in single currency — owner-only (visible para todos, dimmed si no-owner)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Toggle(L10n.Groups.Form.showDebtsInSingleCurrency, isOn: $showDebtsInSingleCurrency)
                        .font(DS.Typography.body)

                    Text(L10n.Groups.Form.showDebtsInSingleCurrencyHint)
                        .font(DS.Typography.captionSmall)
                        .foregroundStyle(.secondary)

                    if showDebtsInSingleCurrency {
                        Button {
                            showCurrencyPicker = true
                        } label: {
                            HStack(spacing: DS.Spacing.md) {
                                let info = currencyInfo(for: selectedCurrency)
                                Text(info.flag)
                                    .font(DS.Typography.body)

                                Text(info.code)
                                    .font(DS.Typography.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(info.name.capitalized)
                                    .font(DS.Typography.captionSmall)
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(DS.Typography.captionSmall)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, DS.Spacing.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if !group.isOwner {
                        Text(L10n.Groups.Options.ownerOnlyHint)
                            .font(DS.Typography.captionSmall)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!group.isOwner)
                .opacity(group.isOwner ? 1 : 0.5)
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .onChange(of: showDebtsInSingleCurrency) { _, newValue in
                    guard newValue != group.showDebtsInSingleCurrency else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        updateGroupOption { group in
                            group.showDebtsInSingleCurrency = newValue
                            if !newValue {
                                group.currencyCode = appPreferences.defaultCurrencyCode.rawValue
                            }
                        }
                        if !newValue {
                            selectedCurrency = appPreferences.defaultCurrencyCode
                        }
                    }
                }
                .onChange(of: selectedCurrency) { _, newValue in
                    guard newValue.rawValue != group.currencyCode else { return }
                    updateGroupOption { $0.currencyCode = newValue.rawValue }
                }

                Divider()
                    .padding(.leading, DS.FormRow.paddingH)

                // Default split type — cualquier miembro activo
                HStack {
                    Text(L10n.Groups.Form.defaultSplitType)
                        .font(DS.Typography.body)

                    Spacer()

                    Picker("", selection: $defaultSplitType) {
                        ForEach(SplitType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .onChange(of: defaultSplitType) { _, newValue in
                    guard newValue.rawValue != group.defaultSplitType else { return }
                    updateMemberOption { $0.defaultSplitType = newValue.rawValue }
                }
            }
        }
        .onAppear {
            simplifyDebts = group.simplifyDebts
            showDebtsInSingleCurrency = group.showDebtsInSingleCurrency
            selectedCurrency = CurrencyCode(rawValue: group.currencyCode) ?? .pen
            defaultSplitType = SplitType(rawValue: group.defaultSplitType) ?? .equal
        }
    }

    // MARK: - Personal Integration (Bridge Override per-grupo, F4)

    @State private var showPerGroupDeactivationSheet: Bool = false

    private var personalIntegrationState: OverrideStateLogic.UIState {
        OverrideStateLogic.compute(
            global: appPreferences.bridgeGroupExpensesToPersonalAccounts,
            override: BridgeModeResolver.shared.override(forZoneID: group.cloudKitZoneID, context: modelContext),
            memberIsActive: viewModel.canCurrentUserParticipate
        )
    }

    /// Binding al estado visual del toggle. Lectura: deriva del state computed.
    /// Escritura: invoca el resolver para persistir override.
    private var personalIntegrationToggle: Binding<Bool> {
        Binding(
            get: {
                switch personalIntegrationState {
                case .enabledOnInheriting, .enabledOnLocal: return true
                case .enabledOffLocal, .disabledOff, .hiddenSection: return false
                }
            },
            set: { newValue in
                let global = appPreferences.bridgeGroupExpensesToPersonalAccounts
                guard global else { return }  // disabled cuando global OFF
                do {
                    // ON estando OFF → setOverride(nil) (volver a heredar).
                    // OFF estando ON → setOverride(false) (override OFF explícito).
                    let override: Bool? = newValue ? nil : false
                    try BridgeModeResolver.shared.setOverride(for: group, override: override, in: modelContext)
                    // Si user desactivó (newValue==false) Y hay TX bridgeadas para este
                    // grupo, presenta BridgeDeactivationSheet scoped (plan F4) para que
                    // el user decida freeze vs delete.
                    if !newValue && hasBridgedTransactionsForGroup() {
                        showPerGroupDeactivationSheet = true
                    }
                } catch {
                    #if DEBUG
                    print("personalIntegrationToggle: setOverride failed: \(error)")
                    #endif
                }
            }
        )
    }

    @ViewBuilder
    private var personalIntegrationSection: some View {
        let state = personalIntegrationState
        if state != .hiddenSection {
            SectionBox(title: L10n.Groups.Settings.personalIntegrationSectionTitle) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Toggle(
                        L10n.Groups.Settings.personalIntegrationToggleLabel,
                        isOn: personalIntegrationToggle
                    )
                    .font(DS.Typography.body)
                    .disabled(state == .disabledOff)

                    Text(personalIntegrationHint(for: state))
                        .font(DS.Typography.captionSmall)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
            }
            .sheet(isPresented: $showPerGroupDeactivationSheet) {
                BridgeDeactivationSheet(
                    scope: .perGroup(zoneID: group.cloudKitZoneID, groupName: group.name),
                    onConfirm: { /* cleanup hecho dentro del sheet */ },
                    onCancel: revertPerGroupOverride
                )
            }
        }
    }

    /// Revierte el override per-grupo cuando user cancela el sheet de deactivation
    /// (restauración del intent: si user cancela, no quiere desactivar).
    private func revertPerGroupOverride() {
        do {
            try BridgeModeResolver.shared.setOverride(for: group, override: nil, in: modelContext)
        } catch {
            #if DEBUG
            print("revertPerGroupOverride failed: \(error)")
            #endif
        }
    }

    /// Conteo de TX bridgeadas para este grupo (`splitGroupZoneID == cloudKitZoneID`).
    private func hasBridgedTransactionsForGroup() -> Bool {
        let zoneID = group.cloudKitZoneID
        let descriptor = FetchDescriptor<TransactionItem>(
            predicate: #Predicate<TransactionItem> {
                $0.splitGroupZoneID == zoneID &&
                ($0.splitExpenseID != nil || $0.splitSettlementID != nil)
            }
        )
        do {
            return try modelContext.fetchCount(descriptor) > 0
        } catch {
            #if DEBUG
            print("hasBridgedTransactionsForGroup: fetchCount failed: \(error)")
            #endif
            return false
        }
    }

    private func personalIntegrationHint(for state: OverrideStateLogic.UIState) -> String {
        switch state {
        case .hiddenSection: return ""
        case .disabledOff: return L10n.Groups.Settings.personalIntegrationHintBlockedByGlobal
        case .enabledOnInheriting, .enabledOnLocal: return L10n.Groups.Settings.personalIntegrationHintInheritOn
        case .enabledOffLocal: return L10n.Groups.Settings.personalIntegrationHintLocalOff
        }
    }

    // MARK: - Danger Zone (Archive)

    private var dangerZoneSection: some View {
        VStack(spacing: DS.Spacing.none) {
            Button {
                toggleArchive()
            } label: {
                HStack {
                    Image(systemName: group.isArchived ? "archivebox.fill" : "archivebox")
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Text(group.isArchived ? L10n.Groups.Settings.unarchive : L10n.Groups.Settings.archive)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Spacer()
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .solidCard(radius: DS.Radius.card)
    }

    // MARK: - Leave Group

    private var leaveGroupSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Button {
                showLeaveGroupConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Text(L10n.Groups.Settings.leaveGroup)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Spacer()
                    if isLeavingGroup {
                        ProgressView()
                    }
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isLeavingGroup)
        }
        .solidCard(radius: DS.Radius.card)
    }

    // MARK: - Transferir y salir (owner con heredero, canal backend)

    private var transferAndLeaveSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Button {
                // Refresca antes de abrir el diálogo — simétrico con `deleteGroupSection` y
                // `toggleArchive`. Aquí importa doble: si el sync trajo la salida del último
                // co-member, el heredero que íbamos a nombrar ya no existe.
                recomputeOwnerExit()
                guard currentOffer.showsTransferAndLeave else { return }
                showTransferConfirm = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Text(L10n.Groups.Settings.transferAndLeave)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Spacer()
                    if isTransferring {
                        ProgressView()
                    }
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isTransferring || isDeleting)

            Text(L10n.Groups.Settings.transferAndLeaveHint)
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.bottom, DS.FormRow.paddingV)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .solidCard(radius: DS.Radius.card)
    }

    private func transferAndLeave() async {
        guard !isTransferring else { return }
        isTransferring = true
        defer { isTransferring = false }

        do {
            switch try await GroupService.shared.transferOwnershipThenLeave(group) {
            case .left:
                DS.Haptic.success()
                dismiss()
            case .needsDecision:
                // El servidor no encontró heredero (el último co-member elegible se fue entre que
                // pintamos el botón y el usuario confirmó). NO es un error del usuario ni del canal:
                // es un cambio de estado, y el copy lo dice tal cual. La pantalla se queda abierta y
                // se recalcula, así que el botón desaparece solo.
                DS.Haptic.warning()
                actionErrorMessage = L10n.Groups.Errors.transferNoHeir
                showActionError = true
                transferRefusedByServer = true
                recomputeOwnerExit()
            }
        } catch {
            DS.Haptic.warning()
            // Mismo contrato que `leaveGroup()`: nunca un número crudo ni una dev-string.
            actionErrorMessage = GroupLeaveErrorLogic.classify(error).localizedMessage
            showActionError = true
        }
    }

    // MARK: - FU-02 Soft-delete (owner-only)

    private var deleteGroupSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Button {
                // Refresh cache antes de mostrar el dialog — simétrico con toggleArchive,
                // evita falsos negativos si el sync trajo deuda después del último
                // onAppear/dataVersion change.
                recomputeOwnerExit()
                guard currentOffer.deleteEnabled else { return }
                showDeleteConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Text(L10n.Groups.Settings.deleteGroup)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Semantic.errorForeground)
                    Spacer()
                    if isDeleting {
                        ProgressView()
                    }
                }
                .padding(.horizontal, DS.FormRow.paddingH)
                .padding(.vertical, DS.FormRow.paddingV)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!currentOffer.deleteEnabled || isDeleting || isTransferring)

            if let hint = currentOffer.deleteHint {
                // El copy del bloqueo depende de si hay salida: pedirle «liquida las deudas» a un
                // dueño al que lo que le frena es un saldo ENTRE TERCEROS le manda a hacer algo que
                // no puede hacer. Con heredero, se le apunta a «Transferir y salir».
                Text(hint == .debtTransferInstead
                     ? L10n.Groups.Settings.deleteGroupDisabledHintTransfer
                     : L10n.Groups.Settings.deleteGroupDisabledHint)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Semantic.errorForeground)
                    .padding(.horizontal, DS.FormRow.paddingH)
                    .padding(.bottom, DS.FormRow.paddingV)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .solidCard(radius: DS.Radius.card)
    }

    private func performSoftDelete() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try GroupService.shared.softDelete(group)
            DS.Haptic.warning()
            dismiss()
        } catch {
            // El copy de `ownerCannotLeave` manda AQUÍ («…puedes eliminarlo»), así que este camino no
            // puede seguir pintando la dev-string en inglés de `GroupServiceError` («GroupService: Only
            // the group owner…»): sería mandar al usuario a un callejón con cartel técnico. Las otras
            // cuatro acciones de esta pantalla (renombrar, archivar, opciones) tienen el mismo defecto y
            // se dejan a propósito: no las nombra este cambio. Anotadas en el ticket.
            actionErrorMessage = GroupLeaveErrorLogic.classify(error).localizedMessage
            showActionError = true
        }
    }

    private func hasNonZeroBalance(for memberID: String) -> Bool {
        viewModel.balances
            .filter { $0.memberID == memberID }
            .contains { abs($0.netBalance) > 0.01 }
    }

    /// 2.6 — una sola resolución de identidad, la canónica del write-side. La versión anterior probaba
    /// PRIMERO el `cachedRecordName` de iCloud y, si no casaba ningún member, devolvía nil SIN caer al
    /// fallback: en un grupo del canal backend eso da siempre nil (`cloudKitUserRecordID` está vacío por
    /// diseño, pero el recordName de iCloud SÍ existe) ⇒ el usuario aparecía sin deuda aunque debiera
    /// dinero, y esta propiedad es la que decide si se le deja archivar o salir del grupo.
    private var hasOutstandingBalance: Bool {
        guard let memberID = GroupExpenseService.selectCurrentUserMemberID(
            from: viewModel.members,
            cachedRecordName: GroupUserIdentityService.shared.cachedRecordName,
            currentUserID: CloudSyncFlags.groupsBackendEnabled ? CloudAuthService.shared.currentUserID : nil
        ) else { return false }
        return hasNonZeroBalance(for: memberID)
    }

    /// Alcance global: cualquier miembro con balance pendiente. Cubre cross-currency
    /// automáticamente porque `MemberBalance` tiene una entry por memberID×currencyCode.
    ///
    /// Bypass del cache `viewModel.balances` con fetches directos del context — defense
    /// in depth para casos donde `loadData` no haya corrido al momento del tap archive
    /// (race con sync, cold launch del settings, etc). Fallback graceful al cache del VM
    /// si los fetches throw. El resultado se cachea en `hasOutstandingDebt`
    /// (recalculado en `.onAppear` + `onChange(dataVersion)` + pre-tap de archive/delete)
    /// para evitar fetches por cada re-evaluación del body de SwiftUI.
    private func recomputeOutstandingDebt() {
        let zoneID = group.cloudKitZoneID
        do {
            // Early exit: si el grupo no tiene expenses, no hay deuda posible — skip los
            // otros 3 fetches + `calculateBalances`. `fetchCount` es O(1) en SwiftData
            // (delega a SQL COUNT). Ahorra ~50ms en grupos vacíos/recién creados.
            let expensesCount = try modelContext.fetchCount(FetchDescriptor<SplitExpense>(
                predicate: #Predicate { $0.groupZoneID == zoneID }
            ))
            guard expensesCount > 0 else {
                hasOutstandingDebt = false
                return
            }

            let expenses = try modelContext.fetch(FetchDescriptor<SplitExpense>(
                predicate: #Predicate { $0.groupZoneID == zoneID }
            ))
            let shares = try modelContext.fetch(FetchDescriptor<SplitShare>(
                predicate: #Predicate { $0.groupZoneID == zoneID }
            ))
            let settlements = try modelContext.fetch(FetchDescriptor<SplitSettlement>(
                predicate: #Predicate { $0.groupZoneID == zoneID }
            ))
            let members = try modelContext.fetch(FetchDescriptor<SplitMember>(
                predicate: #Predicate { $0.groupZoneID == zoneID }
            ))
            let balances = GroupBalanceService.calculateBalances(
                expenses: expenses,
                shares: shares,
                members: members,
                settlements: settlements
            )
            hasOutstandingDebt = balances.contains { abs($0.netBalance) > 0.01 }
        } catch {
            #if DEBUG
            print("GroupSettingsView: recomputeOutstandingDebt fetch error \(error), fallback to cache")
            #endif
            hasOutstandingDebt = viewModel.balances.contains { abs($0.netBalance) > 0.01 }
        }
    }

    /// Recalcula la deuda del grupo Y, con ella, qué salida se le ofrece al dueño. Van juntos porque
    /// el offer DEPENDE de la deuda: calcularlos por separado dejaría un frame en el que el botón de
    /// eliminar y su hint discrepan sobre si hay saldos.
    private func recomputeOwnerExit() {
        recomputeOutstandingDebt()
        do {
            let result = try GroupService.shared.ownerExitOffer(
                group, groupHasOutstandingDebt: hasOutstandingDebt,
                serverRefusedTransfer: transferRefusedByServer)
            ownerExitOffer = result.offer
            designatedHeirName = result.heir?.displayName
        } catch {
            #if DEBUG
            print("GroupSettingsView: ownerExitOffer error \(error), fallback al offer previo")
            #endif
            // Se deja el offer ANTERIOR: ponerlo a `nil` haría desaparecer «Transferir y salir»
            // ante un fetch fallido, que es justo el callejón que este ticket viene a cerrar.
            //
            // Y lo que este camino NO puede hacer, dicho porque es el hueco de verdad: si el throw
            // ocurre en el PRIMER `.onAppear` no hay offer anterior, así que el body cae al fallback
            // —sin transferencia— y el dueño con deuda vuelve a ver las tres salidas cerradas. No se
            // puede hacer mejor sin los datos que el fetch no trajo: la alternativa sería ofrecer una
            // transferencia sin saber si hay heredero, y eso acaba en un `no_eligible_owner` tras
            // confirmar. El estado es recuperable —cualquier `dataVersion` reintenta— y degrada al
            // comportamiento anterior al ticket, no a uno peor.
        }
    }

    private func leaveGroup() async {
        guard !isLeavingGroup else { return }
        isLeavingGroup = true
        defer { isLeavingGroup = false }

        do {
            try await GroupService.shared.leaveGroup(group)
            DS.Haptic.success()
            dismiss()
        } catch {
            DS.Haptic.warning()
            // Copy propio por caso: el `localizedDescription` de un `GroupsRPCError` es el número del
            // discriminante («…GroupsRPCError 10.»), y el de un `GroupServiceError` es una dev-string en
            // inglés. Ninguno de los dos es un mensaje para el usuario.
            let kind = GroupLeaveErrorLogic.classify(error)
            // El servidor acaba de decir «eres el dueño», y `reconcileServerSideOwnership` ya corrigió
            // el flag y bumpeó `dataVersion` — así que la pantalla, detrás de este alert, se ha
            // repintado con las salidas del dueño. Hay que recalcular ANTES de elegir el copy: con la
            // transferencia disponible, el texto por defecto («…puedes eliminarlo») manda a un botón
            // que en ese momento está en gris y cuyo hint devuelve a «transfiérelo y sal». El usuario
            // daba vueltas entre dos mensajes que se remitían el uno al otro.
            recomputeOwnerExit()
            leaveErrorMessage = (kind == .ownedByCurrentUser && currentOffer.showsTransferAndLeave)
                ? L10n.Groups.Errors.ownerCannotLeaveCanTransfer
                : kind.localizedMessage
            showLeaveError = true
        }
    }

    // MARK: - Actions

    private func saveIdentity() {
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let nameChanged = trimmedName != group.name
        let iconChanged = editIconName != group.iconName
        let colorChanged = editColorHex != group.colorHex
        guard nameChanged || iconChanged || colorChanged else { return }

        do {
            try GroupService.shared.updateGroup(
                group,
                name: trimmedName,
                iconName: editIconName,
                colorHex: editColorHex,
                currencyCode: group.currencyCode,
                simplifyDebts: group.simplifyDebts,
                showDebtsInSingleCurrency: group.showDebtsInSingleCurrency,
                defaultSplitType: group.defaultSplitType,
                membersCanInvite: group.membersCanInvite
            )
            viewModel.loadData()
        } catch {
            actionErrorMessage = error.localizedDescription
            showActionError = true
        }
    }

    private func toggleArchive() {
        let willArchive = !group.isArchived
        // Refresca el cache antes del check para evitar valor stale si el sync trajo
        // data después del último onAppear/dataVersion change. Tiene que ser `recomputeOwnerExit`
        // y no solo la deuda: desde que «Eliminar» lee `currentOffer` en vez del `@State` vivo,
        // refrescar únicamente `hasOutstandingDebt` deja el botón habilitado y sin hint mientras el
        // diálogo de archivar, en la misma pantalla, ya avisa de que hay deudas.
        if willArchive { recomputeOwnerExit() }
        if willArchive && hasOutstandingDebt {
            showArchiveConfirm = true
            return
        }
        performArchiveToggle(isArchiving: willArchive)
    }

    private func performArchiveToggle(isArchiving: Bool) {
        do {
            try GroupService.shared.setArchived(group, isArchived: isArchiving)
            DS.Haptic.success()
            viewModel.loadData()
            if group.isArchived {
                dismiss()
            }
        } catch {
            actionErrorMessage = error.localizedDescription
            showActionError = true
        }
    }

    private func updateGroupOption(_ update: (SplitGroup) -> Void) {
        update(group)
        do {
            try GroupService.shared.updateGroup(
                group,
                name: group.name,
                iconName: group.iconName,
                colorHex: group.colorHex,
                currencyCode: group.currencyCode,
                simplifyDebts: group.simplifyDebts,
                showDebtsInSingleCurrency: group.showDebtsInSingleCurrency,
                defaultSplitType: group.defaultSplitType,
                membersCanInvite: group.membersCanInvite
            )
            viewModel.loadData()
        } catch {
            actionErrorMessage = error.localizedDescription
            showActionError = true
        }
    }

    /// Variante de `updateGroupOption` para las opciones que cualquier miembro activo puede
    /// cambiar (simplify/split). Usa `updateMemberEditableOptions` (guard de miembro activo, no
    /// admin) para no reintroducir el alert "solo admins" de B-19.
    private func updateMemberOption(_ update: (SplitGroup) -> Void) {
        update(group)
        do {
            try GroupService.shared.updateMemberEditableOptions(
                group,
                simplifyDebts: group.simplifyDebts,
                defaultSplitType: group.defaultSplitType
            )
            viewModel.loadData()
        } catch {
            actionErrorMessage = error.localizedDescription
            showActionError = true
        }
    }

}
