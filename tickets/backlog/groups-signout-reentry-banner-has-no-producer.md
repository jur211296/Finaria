---
id: groups-signout-reentry-banner-has-no-producer
status: backlog
priority: low
area: "groups"
created: 2026-09-11
source: "paso 9 del rediseño de sesiones (`session-exits-one-verb-per-session`)"
---

# El aviso «Cerraste tu sesión de grupos» ya no tiene quién lo encienda

Desde el paso 9, cerrar una sesión solo-grupos lleva al Welcome en vez de a la pestaña de Grupos, así que
`CloudSessionSignOut` dejó de llamar a `GroupsSignOutBannerMarker.markPending()`: era su único productor.
El lector (`GroupsContainerView`, `showGroupsSignOutReentryBanner`) y sus strings siguen vivos y leen una
marca que nadie escribe; un dispositivo actualizado con la marca puesta la verá una vez.

## Qué hacer

Retirar la marca, el banner y sus strings, o reusarlo si algún cierre vuelve a aterrizar en Grupos.
