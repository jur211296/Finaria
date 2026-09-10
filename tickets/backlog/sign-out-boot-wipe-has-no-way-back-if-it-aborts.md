---
id: sign-out-boot-wipe-has-no-way-back-if-it-aborts
status: backlog
priority: high
area: "modo-nube, onboarding"
created: 2026-09-10
source: "review adversarial del paso 5-b (`groups-entry-on-a-mirrored-store-still-blocks-the-owner`), lente de ciclo de vida"
---

# Si el borrado de arranque falla, la app se queda a medias y no hay forma de sacarla de ahí

## El síntoma, en lenguaje de usuario

Cierro sesión. Al reabrir, Yala intenta dejar el teléfono limpio y **no puede** (el disco está lleno, o
el archivo está bloqueado). La app abre igual, y a partir de ese momento: no me llegan recordatorios
nuevos, el widget se queda congelado con datos viejos y los gastos que capturo por Apple Pay o Siri no
entran nunca. Nada me lo dice, y no hay nada que yo pueda hacer.

## Lo medido (2026-09-10, en este árbol)

`SwiftDataConfiguration.performSignOutWipeIfArmed` tiene un guard de aborto (S3, `:689-693`): si no puede
borrar el archivo base del store personal o el de sync-meta, **aborta sin desarmar** y deja un breadcrumb
(`signOutWipeAborted`). Eso es correcto y deliberado: reintentar en el arranque siguiente es mejor que
seguir con el borrado a medias.

Lo que no está resuelto es qué pasa **mientras** el arm sigue puesto, porque tres subsistemas lo leen
como «este store está condenado, no escribas nada»:

- `AppBootstrapper.handleBecameActive` (`:1611`) sale en su primera línea **en cada vuelta a primer
  plano**: sin drain de Apple Pay/Siri, sin reconciles, sin re-arranque del canal de Grupos.
- `NotificationService.isPersonalWipeArmed` descarta **todo** `add` en el choke point (`:134`, `:231`):
  ningún recordatorio nuevo se programa, en silencio.
- `WidgetDataCache.updateCache` queda suspendido: el widget se congela.

Y el desarme: **`clearSignOutWipeArm` tiene UN solo llamador en producción** — el propio
`performSignOutWipeIfArmed` cuando termina bien (`:811`). Si aborta, no hay ninguna otra vía.

## Por qué no se ve hoy

El único productor del arm es un cierre de sesión de nube, que deja la app en un cover terminal
(`.awaitingRelaunch`) sin salida: la persona relanza y el borrado se reintenta enseguida. La ventana es
corta y el estado degradado casi no se habita. El paso 5-b iba a añadir un segundo productor desde el
Welcome —con un botón «Volver» al lado— y ahí la ventana se vuelve indefinida; ese camino se paró, pero
el agujero del desarme es del mecanismo y no de su call-site.

## Por dónde va el arreglo

Dos piezas, y la segunda es la que falta de verdad:

1. **Que el fallo se vea.** Hoy solo hay un breadcrumb; el canario del disco (`disk-report`) no lo mira
   nadie desde la app.
2. **Un camino de desarme deliberado**, con la condición que lo hace seguro: si el store personal **ya no
   existe** (o está vacío), el borrado no tiene nada que hacer y el arm puede retirarse. Eso lo puede
   comprobar el propio hook antes de abortar.

## Criterios de aceptación

- [ ] Un arranque cuyo borrado aborta deja rastro visible (canario, no solo breadcrumb).
- [ ] Existe una vía de desarme cuya precondición está medida, y un test la fija en las dos direcciones.
- [ ] La no-regresión: el camino normal (borrado que termina bien) sigue desarmando al final.
