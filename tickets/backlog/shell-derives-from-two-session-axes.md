---
id: shell-derives-from-two-session-axes
status: backlog
priority: high
area: "arquitectura, modo-nube, groups, settings"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §2 y consecuencias"
---

# La app deriva todo de dos ejes (¿sesión privada? × sesión nube activa): se retiran los tres flags de modo y la sesión de visita

## Por qué

Hoy 19 vistas y 14 ficheros de servicio deciden por **tres estados con nombres distintos** —
`StorageMode` (icloud/cloud, `CloudSyncFlags.swift:28-29`), `OnboardingMode` (full/groupInvite/completed,
`OnboardingMode.swift:13-17`) y `UsageFocus` (full/groupsOnly, `UsageFocus.swift:21-22`)— más
`SecondarySessionStore.isActive()`. `ShellModeLogic.effective` ya es una derivación de dos de ellos
(`Yala/App/Logic/ShellModeLogic.swift`). Cada vista los combina a su manera, y esa es la fuente de la
confusión que el ADR describe. Este ticket es el último del rediseño: los anteriores dejan el estado
nuevo escrito; este lo convierte en la única fuente.

## Lo medido (2026-09-09, árbol `3a94604e`) — las superficies

Vistas (19): `Settings/` StorageSettingsView, UserDataResetView, GroupsRetentionView,
NotificationsSettingsView, ThemeSettingsView · `Groups/` FullModeActivationView, GroupInviteOnboardingView,
GroupExpenseFormView, GroupRecordsView, SettlementFormView · `Onboarding/` OnboardingView,
WelcomeFlowContainer, WelcomeGroupsGateView, WelcomeRestoreView · `Profile/` ProfileView, YalaAccountView ·
`More/MoreView` · `ExportWizard/GroupsExportView` · `Shared/SecondaryHydrationBanner`.
Fuera de vistas: 9 ficheros en `Yala/Services/CloudSync`, 3 en `Yala/Utils` (incluida la decisión de
mount, `SwiftDataConfiguration.personalStoreDecision`), 2 en `Yala/App/Services`, 2 en
`Yala/Services/Groups`. (Grep: `\.groupInvite|usageFocus|SecondarySessionStore.isActive|isGroupInviteMode|storageMode == \.|ShellMode`.)

## Alcance

1. **Un solo tipo de estado de sesión**, leído desde un único sitio:
   `SessionShape { hasPrivateSession: Bool; cloud: CloudSession? }` con `CloudSession { sub, provider,
   kind: complete|groups_only }`. Se deriva de lo persistido (archivo del store + `storageMode` +
   sesión de `CloudAuthService` + `kind` cacheado + asociación) y se expone por `SessionState`.
2. **Derivaciones**, todas puras y testeadas: `ShellMode` (pestañas), qué ve Ajustes (dos botones,
   «Tu cuenta de Yala», la sección Grupos de «¿Dónde viven tus datos?»), si el bridge corre (privada o
   nube completa), la decisión de mount (sin espejo salvo sesión privada), qué onboarding falta.
3. **Retirar** `OnboardingMode.groupInvite` y `UsageFocus.groupsOnly` como *entradas* (pueden quedar
   como valores persistidos legacy que se migran a `SessionShape` en el primer arranque, y se borran
   después); retirar lo que quede de `WelcomeGroupsGateView` (`GroupsOrganizerGateLogic`): el término
   «datos ajenos» ya se fue en `groups-only-second-launch-mounts-icloud-mirror`; aquí caen el de sesión
   secundaria y el step entero si solo queda el canal (que puede ser un estado del sign-in).
4. **Retirar la sesión de visita (M1):** `SecondarySessionStore`, `SessionDefaults`, el archivo
   `YalaModel-Secondary`, `SECONDARY_SESSION_ROLLOUT_PERCENT` en cliente y gateway, `SecondaryHydrationBanner`,
   `.signOutSecondary`, y los seams de uitest que los alimentan. Los 12 tickets de «secundaria» ya
   están descartados con el ADR como motivo; sus tests se retiran con el código.
5. Las 19 vistas pasan a leer `SessionShape` (o una derivación). Sin cambios visuales fuera de lo que
   los tickets anteriores ya definieron.
6. **Cambio de Apple ID en el teléfono** con sesión privada = cierre de sesión privada (borrar local,
   neutro). Hoy `AppBootstrapper.checkForICloudMismatch` (`Yala/App/AppBootstrapper.swift:1046`) y
   `iCloudSyncService.accountDidChange` reaccionan a `NSUbiquityIdentityDidChange` con un aviso: medir qué
   hacen exactamente y alinearlos con el verbo único. `RestoreRouter.decide` pierde su rama `.groupsOnly`
   (dependía de `onboardingMode == .groupInvite`).
7. Migración de datos en el dispositivo: un usuario que hoy está en `groupInvite`/`groupsOnly` tiene
   que despertar en la celda «sin privada + nube solo grupos» sin perder nada; uno en `.cloud`, en
   «nube completa»; uno en `.icloud` con sesión de grupos viva, en «privada + asociada» (la asociación
   se infiere una vez del `sub` vivo).

## Criterios de aceptación

- [ ] `grep` de las entradas retiradas en `Yala/App/Views` devuelve 0; `SessionShape` es el único
      punto de lectura fuera de la capa de persistencia.
- [ ] Las cuatro celdas del ADR tienen seed de uitest y un XCUITest que recorre pestañas + Ajustes.
- [ ] Migración: los tres estados legacy de arriba aterrizan en su celda (unit sobre la lógica de
      migración con fixtures de `UserDefaults`).
- [ ] La suite entera en verde (`/gate` completo): al borrar código se corre todo, no lo tocado.
- [ ] `docs/glosario.md` y `.claude/rules/swiftdata-cloudkit.md` sin «secundaria», «visita» ni
      «invitada» como estados vivos (ticket `retire-guest-vocabulary-for-session-terms`).

Antes de empezar: leer `docs/sessions/2026-09-09-matriz-escenarios-sesiones.md` y marcar cada fila como
cubierta por un test o un device-QA.

## Depende de

Todos los tickets anteriores del ADR (orden de implementación en `docs/DECISIONS.md`, entrada
2026-09-09 «Sesiones — dos ejes»). Va último.

## Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)

Preguntadas una a una antes de soltar la cola autónoma. **Mandan sobre lo escrito arriba.**

- **NO se escribe la migración de estados legacy del dispositivo.** El punto 7 del alcance queda
  **derogado**: quien tenga un estado viejo reinstala. Motivo: producción queda vacía tras el fresh start
  del ticket 2 y el parque real es el iPhone de Jürgen más los testers de TestFlight. Riesgo aceptado:
  un tester con la app puesta puede encontrarse un estado raro al actualizar.
- **Un solo PR**, como el resto de la cola, aunque toque 19 vistas y 14 servicios. La app nunca queda
  medio migrada. Asume que la review adversarial de este PR es la más dura de las trece.
- **`YalaModel-Secondary` se borra del disco al actualizar.** M1 está al 0 % en producción, así que ahí
  no debería haber datos de nadie — **compruébalo, no lo des por hecho** antes de borrar. (Ojo: en
  `[env.staging.vars]` el percent está en **100**, así que un dispositivo de pruebas contra staging sí
  puede tener datos ahí.)
- **El grep de los flags retirados tiene que dar CERO de verdad, comentarios y docblocks incluidos.** Si
  el flag no existe, nombrarlo confunde a quien llegue después. Se acepta perder ese rastro histórico en
  los docblocks; lo que merezca sobrevivir va a `.claude/rules/` o a `docs/aprendizajes-tecnicos.md`, que
  es donde vive la memoria durable — no en un comentario que cita un símbolo inexistente.

### Hallazgos de esta pasada que aterrizan aquí

- **`GroupsRetentionView` escribe `UsageFocus.groupsOnly`** (`GroupsRetentionView.swift:64`), uno de los
  tres flags que este ticket retira. Viene del ticket 7, que lo dejó explícitamente para este barrido.
  (El ticket 9 además retira esa vista entera; comprueba cuál llega antes.)
- ~~**El docblock de `OnboardingGroupsPurposeGateLogic:15` es falso**~~ — **resuelto el 2026-09-10 en el
  paso 7**: el fichero se borró entero con la card, así que no queda nada que corregir.
- **Del paso 7 (2026-09-10): el guard de sesión secundaria de `ContentView.advanceGroupsOrganizerFlow`
  ya solo es defensa en profundidad.** Existía por la segunda puerta a la rama del organizador —la card
  «Solo grupos» del onboarding, que no pasaba por `WelcomeGroupsGateView`— y esa puerta se retiró. Se
  dejó en pie porque retirar un guard M1 era ampliar a otro objeto; cae con M1 en este barrido (su
  `showOnboarding = false` solo servía a la card). Lo pinnea
  `GroupsOrganizerBranchTests.organizerFlowStopsUnderASecondarySession`: retíralos juntos.

## Decisiones de Jürgen (2026-09-12, tras el mapa del alcance real)

Preguntadas con la medición delante. **Mandan sobre todo lo escrito arriba**, incluidas las del 9-sep
en lo que las contradigan.

- **El eje «¿hay sesión privada?» se escribe como MARCA POSITIVA persistida, con backfill de un
  arranque.** Es el punto que hacía el ticket inejecutable: hoy ese eje no tiene fuente propia — las
  seis veces que `hasPrivateSession` aparece en producción se construye como
  `!SessionState.shared.isGroupInviteMode`, o sea a partir del flag que este ticket borra, y dos tests
  pinnean ese literal (`CloudSignOutFlowLogicTests:679` y `:683`). Se descartó derivarlo de la
  presencia del store en disco: un gate derivado de una AUSENCIA falla abierto, y si el fichero falta
  por un fallo de montaje la app trataría a un usuario con vida personal como si solo hubiera venido
  por un grupo. **El backfill NO contradice la derogación del punto 7**: aquella retiraba estados
  legacy muertos (`groupInvite`/`groupsOnly`); esto escribe por primera vez la celda NORMAL del modelo
  nuevo, que es la de casi todo el parque. Sin él, todo el mundo despierta sin marca.
- **Dos entregas, no una.** El tercio mecánico —retirar el dominio de preferencias por sesión— sale
  en su propio PR porque es un no-op **demostrable** en producción, y separarlo hace que un rojo del
  gate diga de qué mitad viene. No deja la app medio migrada, que es lo que protegía la decisión del
  9-sep: en producción no cambia un byte. El resto (M1 + `OnboardingMode` + `SessionShape`) va junto.
- **`StorageMode` se ACOTA: sale de este ticket.** `SessionShape` lo sustituye solo como entrada de la
  UI; el motor de Modo Nube sigue leyendo su modo persistido. Motivo medido: no es dark —el gateway
  sirve `CLOUD_MODE_ROLLOUT_PERCENT=100` en producción y un alta born-cloud escribe `.cloud` hoy— y es
  el SSOT del mount, la autoridad de quiescencia y los gates de arranque. Retirarlo de verdad es varias
  veces el tamaño del resto del ticket.
- **El cambio de Apple ID (§6) sale a ticket propio**:
  `apple-id-change-should-close-the-private-session`. No comparte código con el barrido y es el cambio
  de comportamiento más caro de la cola.

### Premisas del ticket que NO se sostienen (medidas el 2026-09-12 en `ad2c9d0f`)

- **El alcance está subestimado ~4×.** «19 vistas y 14 ficheros de servicio» son hoy **115 ficheros de
  producción** más **46 de tests**, más gateway, 16 locales, `qa/coverage-index.json` y una línea del
  `pbxproj`. (Medido con `git grep`: `grep -r` desde la raíz miente, porque hay un worktree vivo
  DENTRO del árbol, en `.claude/worktrees/`.)
- **`Yala/Utils/CloudSyncFlags.swift` no existe**: está en `Yala/Services/CloudSync/CloudSyncFlags.swift`.
- **`GroupsRetentionView` ya no existe** — la borró el paso 9, así que su escritura de
  `UsageFocus.groupsOnly` (que este ticket listaba como hallazgo pendiente) está resuelta. Hoy no
  queda **ni un escritor** de `.groupsOnly`: la única asignación viva es `FullModeActivationView:534`
  poniendo `.full`, que es no-op permanente.
- **`SessionState` ya está ocupado**: hay un tipo con ese nombre de 815 líneas que es otra cosa
  (notificaciones de inbox, deep links de widgets). `SessionShape` necesita otro sitio.
- **`SessionDefaults` NO es una pieza de M1 que se retire sin más.** Aparecía en 63 ficheros porque era
  la puerta que decidía el dominio de TODAS las preferencias. Lo retira el PR mecánico de arriba.

## PR-A entregado (2026-09-12): el eje 1 ya tiene fuente propia

Esto es lo que desbloquea el ticket. **No es el barrido**: M1 y `OnboardingMode` siguen en pie y son el
PR-B.

**Qué entra.** `PrivateSessionMark` (`Yala/Services/CloudSync/`), la marca positiva persistida que
Jürgen decidió el 12-sep, con backfill de un arranque. Los **nueve** constructores del eje pasan a
leerla, y los **tres source-scans** que clavaban el literal viejo pinnean ahora la forma nueva.

**El eje eran 9 constructores, no 6.** Los seis del encargo son los de `hasPrivateSession:`; los otros
tres son las funciones de `DestructiveScopeLogic` que recibían el eje bajo el nombre viejo
(`wipeOperation`, `wipeSignalsAppleIDDevices`, `wipeLanding`) — su propio docblock decía que distinguen
«sin vida personal» de «con vida personal». Jürgen aprobó incluirlas: dejarlas con el flag habría partido
el eje en dos nombres justo antes del PR-B.

**Dos lecturas, no una, y es lo que más costó.** `hasPrivateSession` (ausente ⇒ `true`) y
`confirmedPrivateSession` (ausente ⇒ `false`). No hay un default que sirva para las dos preguntas:
`wipeSignalsAppleIDDevices` decide si «Vaciar datos» ORDENA a los demás dispositivos del Apple ID
vaciarse, y ahí un `true` por ausencia vacía el iPad del dueño — el daño exacto que la review del paso 9
cazó. Es el único consumidor de la lectura estricta, y un test cuenta que siga siendo uno.

### Lo que la review adversarial cazó, y era MÍO

Tres lentes independientes, 14 hallazgos, ninguno sin juzgar. Los seis que cambiaron código:

1. **El seam `-uitest-group-invite` envenenaba el simulador para siempre.** Elegí el prefijo `cloudSync.`
   para que la marca sobreviviera a «Vaciar datos», y con eso la dejé fuera del único barrido que la
   habría limpiado entre corridas. La corrida siguiente —y el arranque MANUAL de Yala Dev en ese
   simulador— arrancaba creyendo que no hay sesión privada. Se purga en el bloque de `-uitest-reset`,
   junto a su gemela `onboardingMode`.
2. **La copy de «Vaciar datos» leía el flag viejo mientras su alcance leía la marca.** Divergían justo en
   el caso que el eje existe para cubrir, y la pantalla prometía «solo tu perfil y tus preferencias»
   sobre un `.wipeDataFull`. El bug se había movido una línea, no cerrado.
3. **El backfill resucitaba la marca que el cierre de sesión acababa de borrar**, en el mismo
   lanzamiento: el boot-wipe pre-mount llama a `clear()` y su `resetPrefs()` borra `onboardingMode`, así
   que el backfill leía `.full` y escribía `true`. Con eso la AUSENCIA no existía nunca en producción y
   el default estricto no protegía nada. Se cierra gateando el backfill por `hasCompletedOnboarding`:
   el backfill es para el parque existente, y un teléfono recién barrido no lo es.
4. **La visita podía borrar la marca del dueño.** El cinturón de `wipeLocalGroupsDomain` solo lanza si el
   store montado no es el secundario, así que una visita operativa llegaba al `clear` del handover. Ese
   camino es in-session y ahora lleva guard de M1; el del boot-wipe no lo necesita y no lo lleva.
5. **Las lecturas contestaban por el dueño en sesión secundaria.** La marca vive en su `UserDefaults`, así
   que la visita leía «¿tiene el dueño vida personal?» cuando la pregunta es «¿la tiene ESTA sesión?».
   Las dos lecturas cortan ahora en M1 antes de mirar la marca: `false` por definición del modelo.
6. **Mis docblocks afirmaban de más.** «Los siete puntos» eran nueve; «sus tres puertas» eran dos; y la
   promesa de que la marca «nunca viaja por el iCloud-KV» vale para la marca ESCRITA, no para su semilla
   — el backfill no tiene más fuente que `onboardingMode`, que sí pudo venir mergeado del KV. Es una
   limitación de la migración, no del diseño, y ahora está escrita.

**Verificado:** build ×2 (`Yala` y `Yala Dev`) con cero warnings nuevos —medido contra un worktree del
árbol base con DerivedData limpio, porque el primer intento fue incremental y dio un cero falso— y **10
mutantes que caen**: 4 sobre el diseño y 6 sobre las correcciones de la review.

### Lo que el PR-B hereda (medido aquí, no lo redescubras)

- **`CloudIdentityRoutingLogic.deviceState` (`:257-265`) es una SEGUNDA fuente del mismo eje**, derivada
  de `onboardingMode`, cableada en `ContentView`. Su propio docblock ya dice que el paso 12 la absorbe.
  Queda fuera a propósito: entra con el barrido, no antes.
- **`ProfileView.isExportEnabled` / `exportDisabledHint` siguen en `isGroupInviteMode`**, y es correcto:
  su eje es «qué hay que exportar», no «hay vida personal».
- **El flag y la marca divergen en el vaciado REMOTO.** El barrido borra `onboardingMode` local y la marca
  sobrevive a propósito, así que un dispositivo solo-grupos que recibe la señal conserva su eje (bien) con
  la shell completa (la decide `ShellModeLogic`, que aún lee el flag). Se cierra solo cuando el PR-B
  retire el flag; no hay nada que arreglar antes.
