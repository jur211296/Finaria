---
id: private-sign-out-keeps-legacy-cloudkit-groups
status: backlog
priority: low
area: "groups, settings"
created: 2026-09-11
source: "paso 9 del rediseño de sesiones (`session-exits-one-verb-per-session`), decisión D10 del Paso 0"
---

# Cerrar una sesión privada sin cuenta de grupos conserva los grupos de la era CloudKit

El cierre privado sin sesión en la nube (celda C) borra el store de grupos solo si guarda filas del canal
backend (`CloudSessionSignOut.hasBackendGroupRows`): esas se pueden volver a bajar. Las de la era CloudKit
que nunca migraron (`isBackendGroup == false`, `movedToBackendAt == nil`) no tienen de dónde volver desde que
la Fase 3 retiró el transporte, y se quedan en el dispositivo tras el cierre.

## La decisión que falta (Jürgen)

¿Se borran igual («cerrar sesión borra lo local», ADR §5) aunque no se puedan recuperar, o se conservan?
Hoy la población es teórica: producción tuvo un fresh start el 2026-09-10.
