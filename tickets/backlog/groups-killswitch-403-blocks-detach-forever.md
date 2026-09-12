---
id: groups-killswitch-403-blocks-detach-forever
status: backlog
priority: high
area: "groups, modo-nube, settings"
created: 2026-09-11
source: "review adversarial de `cloud-killswitch-hides-the-only-door-to-detach-groups`, lente del incidente"
---

# Con el canal de Grupos en pausa, quien tiene cambios sin subir no puede soltar su cuenta

## El problema, en lenguaje de usuario

Jürgen baja el kill-switch de **Grupos** por un incidente. Yo decido soltar mi cuenta de grupos desde
Ajustes → «¿Dónde viven tus datos?». Si tengo cambios de grupos sin subir, el botón no funciona: sale un
aviso que dice que **el problema es mi cuenta**, y no hay reintento posible mientras dure el incidente.
El aviso miente sobre la causa, y el gesto queda imposible hasta que alguien vuelva a subir el flag.

## Lo medido (2026-09-11)

Cadena completa, con el kill servido **server-side** como 403 (`yala_groups_disabled`,
`GroupsSyncClient.swift:159-171`) y el outbox NO vacío:

1. el ciclo devuelve `.accountUnavailable`;
2. `CloudSignOutFlowLogic.classify` → `.permanent` (`CloudSignOutFlowLogic.swift:214`);
3. `pushAllVerdict` → `.blocked(reason: .permanent)` (:242-244);
4. `GroupsSignOutRetryDecision.decide` → `.surfacePermanent` **sin un solo reintento** (:279);
5. `pushGroupsForSignOut` devuelve `false` (`CloudSessionSignOut.swift:1031-1035`);
6. `detachGroupsAccount` sale por su guard (:218) con `.blockedBeforeWriting`;
7. la sección enciende `blockedReason = .permanent` y el alert dice
   `L10n.Storage.Groups.detachBlockedPermanent` (`GroupsAssociationSection.swift:165, 324-326`).

**Con el outbox vacío —el caso dominante— no pasa nada**: el pre-check corta en `.drained`
(`CloudSessionSignOut.swift:1195`) sin una sola petición y el gesto completa. La exposición es la cohorte
con cambios de grupos pendientes de subir.

**No deja estado a medias** (medido): el aborto ocurre antes del punto de no retorno (:232), así que no
hay nada que reparar. El daño es que el gesto no existe mientras dure el incidente, y que el aviso
atribuye la causa a la cuenta.

## Lo que se espera

Decidir, y dejarlo escrito:

1. **Distinguir el 403 de kill-switch del resto de lo `permanent`.** Un canal en pausa no es «tu cuenta
   ya no vale»: es «vuelve en un rato». Copy propio y, si procede, reintento.
2. **O permitir soltar dejando lo pendiente sin subir**, con el usuario avisado de qué se pierde. Hoy el
   orden es «lo pendiente sube ANTES de cortar nada» (`CloudSessionSignOut.swift:216-218`), que es una
   decisión deliberada y no se cambia sin ratificarla.

Lo que NO procede es dejarlo como está: el ticket hermano
(`cloud-killswitch-hides-the-only-door-to-detach-groups`) abrió la puerta para que este gesto exista
durante un incidente de la NUBE; éste es el mismo agujero por el eje de Grupos, con la puerta abierta y
el gesto imposible.
