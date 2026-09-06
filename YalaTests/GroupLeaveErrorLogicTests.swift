//
//  GroupLeaveErrorLogicTests.swift
//  YalaTests
//
//  Tabla completa de `GroupLeaveErrorLogic`: los 14 casos de `GroupsRPCError` + los 20 de
//  `GroupServiceError` → 4 `Kind`. El cableado de las dos superficies lo fija `GroupLeaveSurfacesWiringTests`.
//

import Foundation
import Testing

@testable import Yala

struct GroupLeaveErrorLogicTests {

    typealias L = GroupLeaveErrorLogic

    // MARK: - GroupsRPCError (los 14 casos)

    @Test func classify_rpc_allFourteenCases() {
        // El caso protagonista del device-QA 2026-08-28: el servidor rechaza la salida porque el
        // usuario es el dueño server-side. No es transitorio y reintentar no sirve nunca.
        #expect(L.classify(GroupsRPCError.ownerCannotLeave) == .ownedByCurrentUser)

        #expect(L.classify(GroupsRPCError.sessionExpired) == .sessionExpired)

        // Transitorios: red/5xx y el kill-switch del canal comparten kind porque comparten consejo
        // («vuelve en un rato») y ninguno es culpa del usuario. Mismo criterio que ya se tomó para
        // `channelDisabled` en el enlace de invitación.
        #expect(L.classify(GroupsRPCError.transient(status: 503)) == .retryLater)
        #expect(L.classify(GroupsRPCError.transient(status: -1)) == .retryLater)
        #expect(L.classify(GroupsRPCError.channelDisabled) == .retryLater)

        // Resto → generic.
        #expect(L.classify(GroupsRPCError.notAuthorized) == .generic)
        #expect(L.classify(GroupsRPCError.invalidInvite) == .generic)
        #expect(L.classify(GroupsRPCError.groupDeleted) == .generic)
        #expect(L.classify(GroupsRPCError.badInput) == .generic)
        #expect(L.classify(GroupsRPCError.groupExists) == .generic)
        #expect(L.classify(GroupsRPCError.invalidGroupID) == .generic)
        #expect(L.classify(GroupsRPCError.memberNotFound) == .generic)
        #expect(L.classify(GroupsRPCError.cannotRemoveOwner) == .generic)
        #expect(L.classify(GroupsRPCError.permanentRejected(code: "yala_desconocido")) == .generic)
        #expect(L.classify(GroupsRPCError.decoding) == .generic)
    }

    // MARK: - GroupServiceError

    /// El guard LOCAL (`isOwner == true`) tiene que contar la misma historia que el rechazo del
    /// servidor: para el usuario es el mismo hecho, y de dónde salió la afirmación es cosa nuestra.
    @Test func classify_serviceOwnerCannotLeave_matchesServerVerdict() {
        #expect(L.classify(GroupServiceError.ownerCannotLeave) == .ownedByCurrentUser)
        #expect(L.classify(GroupServiceError.ownerCannotLeave) == L.classify(GroupsRPCError.ownerCannotLeave))
    }

    /// Los que `leaveGroup` puede lanzar por el camino local, y una muestra del resto. Ninguno debe
    /// llegar al usuario como dev-string en inglés: todos caen a copy genérico honesto.
    @Test func classify_serviceOtherCases_areGeneric() {
        #expect(L.classify(GroupServiceError.noContext) == .generic)
        #expect(L.classify(GroupServiceError.saveFailed(GroupServiceError.noContext)) == .generic)
        #expect(L.classify(GroupServiceError.currentUserMemberNotFound) == .generic)
        #expect(L.classify(GroupServiceError.outstandingBalance) == .generic)
        #expect(L.classify(GroupServiceError.movedToBackend) == .generic)
        #expect(L.classify(GroupServiceError.notOwner) == .generic)
        #expect(L.classify(GroupServiceError.backendActionUnavailable) == .generic)
    }

    /// Un error de fuera de las dos familias (p. ej. el `saveFailed` de SwiftData ya desenvuelto, o
    /// cualquier `NSError` de transporte) NO puede tumbar la clasificación.
    @Test func classify_unknownError_isGeneric() {
        struct Cualquiera: Error {}
        #expect(L.classify(Cualquiera()) == .generic)
        #expect(L.classify(NSError(domain: "test", code: 42)) == .generic)
    }
}
