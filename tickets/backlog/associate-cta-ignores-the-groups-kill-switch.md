---
id: associate-cta-ignores-the-groups-kill-switch
status: backlog
priority: medium
area: "groups, settings, modo-nube"
created: 2026-09-11
source: "review adversarial de `cloud-killswitch-hides-the-only-door-to-detach-groups`, lente del incidente"
---

# «Asociar una cuenta para grupos» abre un sign-in contra un canal apagado

## El problema, en lenguaje de usuario

Con el canal de Grupos matado remotamente, el botón «Asociar una cuenta» de Ajustes → «¿Dónde viven tus
datos?» sigue llevándome a crear o entrar en una cuenta de Yala. Entro, firmo, y del otro lado no hay
canal: el sign-in es real contra un backend que está en pausa.

## Lo medido (2026-09-11)

- `ProfileView.swift:699` hace `RouterEntryGate.shared.submit(.presentGroupsSignIn(pendingJoin: ""))`
  **sin condición**.
- El drenado lo presenta sin gate: `ContentView.swift:912-914` (`showGroupsSignIn = true`).
- Y eso deja en falso **dos afirmaciones escritas en el propio código**: el comentario del drenado
  («DARK: con `groupsBackendEnabled` OFF los intents jamás se submitean», `ContentView.swift:906`) y el
  docblock de `GroupsSignInView.swift:36-37`.

No lo introdujo el ticket del kill-switch de la nube, pero ese ticket multiplica la población que llega
al botón: ahora la fila también se abre con el kill de la nube bajado.

## Lo que se espera

O el CTA respeta `CloudRemoteFlags.groupsBackendEnabled` (y la sección dice por qué no está disponible),
o los dos comentarios se corrigen para que no prometan un gate que no existe. **Lo segundo solo si se
decide que el sign-in con el canal apagado es aceptable**, y entonces conviene decir por qué.
