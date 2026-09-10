---
id: groups-organizer-intent-is-lost-on-relaunch
status: backlog
priority: low
area: "onboarding, groups"
created: 2026-09-10
source: "medido durante `cloud-sign-in-discovers-account-kind` (bloque [I])"
---

# Quien venía a crear un grupo lo pierde si la app tiene que relanzarse

## El problema, en lenguaje de usuario

Entro por «Vengo por un grupo → crear mi primer grupo» y firmo con una cuenta que ya tenía Yala
completo. Yala adopta mi cuenta —correcto— y me pide cerrar y reabrir la app. Al volver, estoy en el
Panel: **lo de crear el grupo se perdió** y tengo que empezar de nuevo desde la pestaña Grupos.

## Lo medido (2026-09-10, árbol `8964c734`)

- La rama del organizador vive en dos flags **en memoria**: `groupsOrganizerFlowActive` (`@State` de
  `ContentView`) y el intent `.presentGroupsOrganizerStep`, que la cola del router no persiste.
- La rama del **invitado**, en cambio, **sí sobrevive**: su intención vive en `PendingJoinStore`
  (`UserDefaults`, TTL 7 días) y `GroupJoinReconciler` la retoma en el arranque
  (`AppBootstrapper.swift:524`, `trigger: .boot`). Medido: la invitación no se pierde.
- El caso solo aparece cuando el adopt **termina pidiendo relanzamiento**. En un móvil recién instalado
  el store nace neutro y el adopt cae en `.reentryReady` (sin relanzar), y ahí el paso 3 ya deja la
  pestaña Grupos seleccionada por debajo del cover.

## Lo que se espera

Que la intención «venía a crear un grupo» sobreviva a un relanzamiento, con el mismo molde que ya
funciona para el invitado: un testigo durable que el boot lea y retome.

## Por qué no se hizo en el paso 3

Inventar ahí un testigo durable nuevo es alcance de `shell-derives-from-two-session-axes` (paso 12),
que es quien barre los flags de entrada y decide cuáles pasan a ser estado derivado. Añadir uno suelto
antes de ese barrido es exactamente lo que ese ticket existe para deshacer.

## Criterios de aceptación

- [ ] Tras un relanzamiento del adopt, quien venía a crear un grupo aterriza en la pestaña Grupos con
      el formulario, no en el Panel.
- [ ] El testigo caduca (o se limpia) para que no reabra el formulario semanas después.
- [ ] Un unit test cubre «testigo puesto + boot → retoma» y «sin testigo → no retoma».

## Depende de

`shell-derives-from-two-session-axes` (paso 12), o su decisión sobre dónde vive ese estado.
