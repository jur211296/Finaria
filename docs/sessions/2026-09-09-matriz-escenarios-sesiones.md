---
updated: 2026-09-09
tags: [sesiones, onboarding, cierres, matriz, verificacion-de-spec]
estado: referencia del ADR 2026-09-09 «Sesiones — dos ejes»; se archiva cuando `shell-derives-from-two-session-axes` esté en 2.1
---

# Matriz de escenarios del modelo de sesiones — ¿qué ticket cubre cada celda?

> Pedida por Jürgen el 2026-09-09 tras ver en su móvil «Aquí ya hay datos guardados» al intentar crear
> un grupo: «escenarios como ese son los que me preocupan». Cada fila es un **estado del móvil × una
> acción**, lo que el ADR espera, y el ticket que lo cubre. Las filas marcadas **HUECO** no estaban
> cubiertas al escribir los 13 tickets y se añadieron a su ticket el mismo día (columna «añadido en»).
> Lo que dice «hoy» está medido en `3a94604e`.

## Estados del móvil

| # | Estado | Cómo se llega |
|---|---|---|
| A | Instalación fresca: sin store, sin sesión | instalar |
| B | Store con espejo de iCloud y datos importados, onboarding NO completado (Welcome visible) | A → «privado» o «Restaurar» → reabrir → volver atrás / matar la app |
| C | Sesión privada activa, sin grupos | onboarding completado en iCloud |
| D | Sesión privada + cuenta de grupos asociada («equipo») | C → asociar |
| E | Sesión en la nube completa | born-cloud, o migración desde C |
| F | Sesión en la nube solo grupos (sin privada) | «Vengo por un grupo» |
| G | Tras «Cerrar sesión»: neutro duradero, iCloud con datos | C/D/E/F → cerrar sesión |
| H | Tras «Vaciar datos» | cualquiera → vaciar |
| I | Restaurando de iCloud (datos bajando) | «Ya tengo cuenta → iCloud» → Continuar |
| J | Kill-switch remoto de nube (`cloudModeRolloutPercent = 0`) | decisión de Jürgen en el gateway |
| K | iCloud no disponible en el dispositivo (sin cuenta / desactivado) | ajustes del teléfono |
| L | Faro puesto (este Apple ID ya tuvo cuenta en la nube) | cualquier alta nube previa con este Apple ID |
| M | Sin red | — |
| N | Segundo dispositivo del mismo Apple ID | — |

## Filas

| Estado × acción | Lo que el ADR espera | Cubre | Hueco / añadido en |
|---|---|---|---|
| A · Primera vez → privado, iCloud con datos | validar → alert doble → borrar+reinicio+onboarding limpio / cancelar→chooser | `welcome-private-fresh-start-skips-icloud-check` | — |
| A · Primera vez → privado, iCloud vacío | onboarding directo (reinicio si hace falta) | ídem | — |
| A · Primera vez → privado, **K** (sin iCloud) | no se puede validar: informar y seguir en local (`.localNoMirror`), como hace «Restaurar» con `.iCloudDisabled` | ídem | **HUECO** → añadido |
| A · Primera vez → privado, matar la app entre «borrar» y el reinicio | el borrado y el destino son kill-safe (armar + boot), nunca onboarding sobre datos a medio borrar | ídem | **HUECO** → añadido |
| A · Primera vez → nube (Apple/Google) | consentimiento → [I]: nueva → crear `complete` → [P]; completa → adopta; solo grupos → entra y ofrece activar | `cloud-sign-in-discovers-account-kind` + born-cloud existente | — |
| A · Primera vez con **L** (faro) | encamina a entrar con esa cuenta + «Crear otra cuenta» visible | `beacon-routes-only-never-blocks` | — |
| A · Ya tengo cuenta → iCloud | reinicio → buscar → found: continuar / desde cero; notFound; cloudPaused (J); iCloudDisabled (K) | existente + `reentry-*` | — |
| A · Ya tengo cuenta → Apple/Google | [I]: completa → adopta; solo grupos → entra F; no existe → botón a «Primera vez → nube» | `cloud-sign-in-discovers-account-kind` | — |
| A · Ya tengo cuenta → Google con **L** de Apple, cuenta inexistente | informa «se creó con Apple» + dos salidas (entrar con Apple / crear con Google) | `beacon-routes-only-never-blocks` | — |
| A · Vengo por un grupo → crear | canal on → [I] → nueva: [G]; solo grupos: entra; completa: entra completa + Grupos. Store sin espejo en TODOS los arranques | `groups-only-second-launch-mounts-icloud-mirror` + `cloud-sign-in-discovers-account-kind` | — |
| A · Vengo por un grupo → invitación (link o pegar) | igual que crear, con «unirme» forzado al terminar | ídem + `GroupBackendInviteEntryLogic` existente | invitación nombrada explícitamente → añadido en el ticket del mount |
| **B** · Vengo por un grupo (crear o invitación) | **sin bloqueo**: vuelta al neutro (borra local, iCloud intacto, relanza) y sigue | `groups-only-second-launch-mounts-icloud-mirror` | era el hueco de la captura de Jürgen → añadido |
| **B** · Primera vez → privado | = A: validar contra iCloud (no contra el store) → alert | `welcome-private-fresh-start-skips-icloud-check` | — |
| **B** · Ya tengo cuenta → iCloud | restaurar (los datos ya están bajando: `found`) | existente | — |
| **I** · Vengo por un grupo | cancelar la señal de restore, vuelta al neutro, seguir | ticket del mount | **HUECO** → añadido |
| C · Grupos (pestaña) → asociar cuenta | [I]: nueva/solo grupos → [G] → asociada; **completa → bloqueo** con 2 salidas | `cloud-sign-in-discovers-account-kind` + `groups-account-association-in-storage-row` | — |
| C · llega una **invitación** (link) | misma regla que asociar: [I] → asociar → unirme; completa → bloqueo | `cloud-sign-in-discovers-account-kind` | **HUECO** (solo cubría el Welcome) → añadido |
| C · Ajustes → «migrar a la nube» | [I]: nueva → cutover existente (E); solo grupos (mi asociada) → **promover ESA cuenta** + cutover; completa → bloqueo | `cloud-sign-in-discovers-account-kind` + `groups-account-association-in-storage-row` + backend | **HUECO** → añadido a los tres |
| C · Cerrar sesión | **espera al último export a CloudKit** → borra local → neutro duradero → Welcome. Sin red: «un momento más», nunca borra sin subir | `session-exits-one-verb-per-session` | **HUECO grave** (medido: nadie espera al export hoy; `.privateReset` no borraba y por eso no lo necesitaba) → añadido |
| C · Vaciar datos | local + iCloud; grupos no aplica; → onboarding | ídem | — |
| C · cambia el Apple ID del teléfono | la sesión privada termina (es del Apple ID): cerrar sesión. Hoy `AppBootstrapper.checkForICloudMismatch` avisa; alinear | `shell-derives-from-two-session-axes` | **HUECO** → añadido |
| D · Cerrar sesión | pushAll grupos verificado → export CloudKit → cerrar nube → borrar local → Welcome | `session-exits-one-verb-per-session` | export CloudKit añadido |
| D · Desasociar | grupos se van; filas puenteadas se quedan con enlace dormido | `groups-account-association-in-storage-row` | — |
| D · Re-asociar la misma / otra cuenta | misma: re-enlaza por `splitExpenseID`; otra: no toca | ídem | — |
| D · Vaciar datos | personal local + iCloud; **grupos y asociación intactos** → onboarding [P] → sigue D | `session-exits-one-verb-per-session` | **HUECO** (no decía qué pasa con la asociación) → añadido |
| D · Eliminar mi cuenta (la de grupos) | en «Tu cuenta de Yala» de la cuenta asociada: desasociar + borrar en backend; personal intacto | ídem + asociación | **HUECO** → añadido |
| D · Ajustes → «migrar a la nube» | promover la asociada a `complete` + cutover → E | ver fila C·migrar | añadido |
| D · **N** (segundo móvil) → Ya tengo cuenta → iCloud | restaura personal y **ofrece entrar con la cuenta de grupos asociada** (la asociación viaja por iCloud-KV) | `groups-account-association-in-storage-row` | **HUECO** (la asociación se persistía solo local) → añadido |
| E · Cerrar sesión | = hoy (`cloudSecureSignOut`) | existente | — |
| E · «Volver a iCloud» (reverse cutover existente) | lo personal vuelve a iCloud (C); la cuenta pasa a `groups_only` y queda **asociada** si tiene grupos (D). Única degradación permitida | `backend-account-kind-complete-or-groups-only` (decía «no hay degradación») | **HUECO / contradicción** → añadido |
| E · Eliminar mi cuenta | en «Tu cuenta de Yala» (5.1.1 v) | `session-exits-one-verb-per-session` | — |
| E · Vaciar datos | contenido de la cuenta; grupos no | ídem | — |
| F · Activar Yala completo → privado | chooser → validar iCloud → alert / **o restaurar** → [P] → D | `full-mode-activation-must-ask-where-personal-data-lives` | «restaurar» como tercera salida: ratificada por Jürgen el 2026-09-09 |
| F · Activar Yala completo → nube | promover a `complete` → [P] → E | ídem + backend | — |
| F · Cerrar sesión | pushAll grupos → borrar local → neutro | `session-exits-one-verb-per-session` | — |
| F · llega una invitación | unirse con la sesión activa | existente | — |
| F · Ya tengo cuenta → iCloud (quiere sus datos privados) | no se ofrece desde F: cerrar sesión → Welcome → restaurar → asociar de nuevo (una nube activa, conmutable) | modelo | — (por diseño) |
| G · cualquier puerta | = A, con neutro duradero ya armado | existente (R4) | — |
| H · tras vaciar en C/D/E | onboarding [P]; en D la asociación sigue | `session-exits-one-verb-per-session` | añadido (D) |
| **J** · puertas de nube | se ocultan; «Restaurar» dice «nube en pausa» al que tiene faro; grupos con su propio kill | `reentry-killswitch-closes-both-doors` (qa) + política ratificada 6-sep | — |
| **L** · dos cuentas creadas desde el mismo Apple ID | el faro guarda la última reclamada; encamina a esa y sigue ofreciendo «crear otra» | `beacon-routes-only-never-blocks` | nota añadida |
| **M** · cualquier [I] | error reintentable, sin crear ni borrar nada | existente | — |
| **M** · Cerrar sesión (C/D/E/F) | bloqueado con «un momento más» hasta subir (grupos) / exportar (CloudKit) | `session-exits-one-verb-per-session` | export añadido |
| Faro stale (cuenta borrada server-side) | [I] → «no existe» → botón a crear | `restore-beacon-outlives-account-deletion` (kept) + [I] | — |
| Widgets / Siri / Apple Pay / notificaciones en F y tras cerrar sesión | por medir | `after-session-redesign-review-…` | — (después) |

## Lo que la matriz NO cubre a propósito

- El detalle de cada pantalla (copy, layout): va en cada ticket y en `BRAND-VOICE.md`.
- Escenarios de la sesión de visita (M1): retirada por el ADR, ratificada el 2026-09-09.
