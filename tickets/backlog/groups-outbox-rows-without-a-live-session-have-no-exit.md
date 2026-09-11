---
id: groups-outbox-rows-without-a-live-session-have-no-exit
status: backlog
priority: medium
area: "settings, groups, modo-nube"
created: 2026-09-11
source: "review adversarial del paso 9 (`session-exits-one-verb-per-session`), lente de celdas"
---

# Si mi sesión de grupos caducó con cambios sin subir, no puedo cerrar sesión hasta volver a entrar

## El síntoma, en lenguaje de usuario

Anoté gastos de grupo sin conexión y mi sesión caducó. Toco «Cerrar sesión» y Yala me dice que mi sesión
caducó y que vuelva a entrar. Si puedo entrar, bien: se suben y ya puedo cerrar. Si no puedo —borré la cuenta
desde otro sitio, perdí el acceso a ese correo—, no hay forma de cerrar sesión en este teléfono.

## Lo que hace el código desde el paso 9

- El cierre de la privada (C) y el de solo grupos (F) no descartan filas vivas de `GroupSyncOutbox`: sin
  sesión no se pueden subir, y el boot-wipe borra sync-meta, que es donde viven. Se bloquea con
  `BlockReason.sessionExpired` y el aviso `groups.errors.sessionExpired`.
- Es el criterio del ticket («nunca descarta») y la D15 del paso 9: los grupos no tienen salida de emergencia.
- Antes del paso 9, la fila «Salir de Yala en este dispositivo» purgaba el outbox en silencio.

## Lo que falta decidir (Jürgen)

1. ¿Hay una salida para quien no puede volver a entrar? Por ejemplo, un descarte avisado que cuente las
   filas, como la salida de emergencia del export.
2. El outbox no tiene dueño: si la persona entra con OTRA cuenta, las filas se suben firmadas por esa cuenta.
   ¿Se sellan con el `userID` que las escribió?

## Criterios de aceptación

- [ ] Decisión escrita sobre las dos preguntas.
- [ ] Si hay descarte: aviso con el número, segundo gesto, canario.
- [ ] Si hay sello: una fila de otra cuenta no se sube nunca (test en las dos direcciones).
