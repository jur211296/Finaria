---
id: groups-archived-group-rejects-join
status: backlog
priority: medium
area: groups
created: 2026-09-06
updated: 2026-09-06
source: decisión de Jürgen del 2026-09-06 sobre tickets/qa/rejected-member-cold-tap-does-nothing.md
---

# Un grupo archivado no acepta miembros nuevos

## Qué le pasa al usuario

Un enlace de invitación a un grupo que su dueño ya archivó **sigue funcionando**: el servidor deja
unirse (`join_group` no mira `is_archived`; medido en el ticket de origen). Y la app tiene un texto ya
traducido a 16 idiomas —`groups.reconnect.archived.body`— que promete lo contrario. Hoy ese texto no se
puede enseñar sin mentir.

## Decisión Jürgen (2026-09-06)

**Se hace verdad el comportamiento: un grupo archivado no acepta miembros nuevos.** Elegida entre eso
y reescribir el texto para permitir la entrada. Motivo, tal como se le puso delante y ratificó: es lo que «archivado» significa para cualquiera, y
el copy ya existe.

## Criterio de hecho (AC)

- [ ] `join_group` rechaza la unión cuando el grupo está archivado, con un error propio (no un
      genérico), aplicado en **los dos entornos** (staging y prod) con su test de RPC.
- [ ] El cliente mapea ese error a `groups.reconnect.archived.*` (copy existente; revisar que el
      cuerpo siga siendo verdad palabra por palabra) y lo enseña como estado, no como error crudo.
- [ ] Un miembro que YA está dentro de un grupo archivado no se ve afectado (solo se cierra la
      entrada nueva).
- [ ] Desarchivar vuelve a abrir la entrada sin más.
- [ ] Device-QA: enlace de un grupo archivado desde un segundo teléfono.

## Relacionados

- [[rejected-member-cold-tap-does-nothing]] — donde se midió que el copy mentía.
