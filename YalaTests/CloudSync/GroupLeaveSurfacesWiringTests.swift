//
//  GroupLeaveSurfacesWiringTests.swift
//  YalaTests / CloudSync
//
//  Source-scan de CABLEADO, molde `AttestWiringTests`. Existe porque el test de comportamiento no puede
//  ver esto: `GroupLeaveErrorLogicTests` seguiría verde si alguien devolviera `error.localizedDescription`
//  a cualquiera de las dos vistas de salida — la clasificación seguiría siendo correcta y el alert volvería
//  a pintar «(Error de Yala.GroupsRPCError 11.)». Lo que se fija aquí es que las superficies SIGAN
//  cableadas al clasificador, que es la mitad que un verde de unit test no prueba.
//

import Foundation
import Testing

@testable import Yala

@Suite("Salir de un grupo · las superficies no pintan el error crudo (source-scan)")
struct GroupLeaveSurfacesWiringTests {

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // YalaTests/CloudSync/
            .deletingLastPathComponent()  // YalaTests/
            .deletingLastPathComponent()  // repo root
    }

    private func fuente(_ ruta: String) throws -> String {
        try String(contentsOf: repoRoot.appendingPathComponent(ruta), encoding: .utf8)
    }

    /// Las DOS superficies de salida asignan su mensaje desde `GroupLeaveErrorLogic`, nunca desde el
    /// `localizedDescription` del error.
    @Test(arguments: [
        "Yala/App/Views/Groups/GroupSettingsView.swift",
        "Yala/App/Views/Groups/GroupsContainerView.swift",
    ])
    func leaveSurfaces_areWiredToTheClassifier(ruta: String) throws {
        let src = try fuente(ruta)

        // Control POSITIVO: si el fichero deja de contener la marca, el scan mide otra cosa (fichero
        // movido o renombrado) y hay que arreglar el test, no darlo por bueno.
        #expect(src.contains("leaveErrorMessage"), "\(ruta) ya no tiene el estado del alert de salir")

        #expect(src.contains("GroupLeaveErrorLogic.classify"),
                "\(ruta) debe elegir el copy con GroupLeaveErrorLogic")
        #expect(!src.contains("leaveErrorMessage = error.localizedDescription"),
                "\(ruta) volvió a pintar el discriminante crudo del enum")
    }

    /// Y el destino al que manda el copy de `ownerCannotLeave` («…puedes eliminarlo») tampoco puede
    /// recibir al usuario con una dev-string en inglés de `GroupServiceError`.
    @Test func softDelete_doesNotShowDevStrings() throws {
        let src = try fuente("Yala/App/Views/Groups/GroupSettingsView.swift")
        let cuerpo = try #require(src.range(of: "private func performSoftDelete()").map {
            String(src[$0.lowerBound...].prefix(1400))
        })
        #expect(cuerpo.contains("GroupLeaveErrorLogic.classify"))
        #expect(!cuerpo.contains("actionErrorMessage = error.localizedDescription"))
    }
}
