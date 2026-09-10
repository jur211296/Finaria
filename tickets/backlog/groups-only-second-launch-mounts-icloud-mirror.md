---
id: groups-only-second-launch-mounts-icloud-mirror
status: backlog
priority: high
area: "modo-nube, groups"
created: 2026-09-09
source: "medido durante el device-QA guiado del 2026-09-09 · ADR 2026-09-09 «Sesiones — dos ejes» §2-3"
---

# La segunda apertura de una sesión solo-grupos adjunta el espejo de iCloud y se trae los datos personales

## El síntoma, en lenguaje de usuario

Instalo Yala, toco «Vengo por un grupo → Crear mi primer grupo», entro con Google, pongo mi nombre y
creo el grupo. Cierro la app y la vuelvo a abrir. **Sin que yo haya tocado nada, la app se conecta al
iCloud del teléfono y baja todo lo que hubiera ahí** — los datos personales del Apple ID del móvil,
que pueden ser míos de otra época o de otra persona. Yo solo quería usar grupos.

Contradice la regla del ADR: una sesión en la nube solo-grupos **ignora** lo que haya en iCloud.

## Lo medido (2026-09-09, árbol `3a94604e`)

Cadena completa, `Yala/Utils/SwiftDataConfiguration.swift`:

1. **Arranque 1** (instalación fresca): `isFreshInstallForNeutralMount` (`:266-277`) es `true` —no hay
   archivo de store, modo `.icloud` por defecto, chooser no visto— ⇒ `personalStoreDecision` devuelve
   `.neutralNoMirror` (`:341`). Correcto.
2. La rama organizador NO requiere espejo (`WelcomeMirrorRelaunchLogic.requiresMirror(.groupsOrganizer)
   == false`), así que no hay relanzamiento y el alta corre sobre el store neutro. Correcto.
3. El alta solo-grupos (`GroupsOrganizerOnboarding.completeSetup`,
   `Yala/Services/Groups/GroupsOrganizerOnboarding.swift:218`, `writePreferences` `:142`) escribe
   nombre, período, divisa y `onboardingMode = .groupInvite`. **No arma el neutro duradero.**
   `StorageModePersistence.armNeutralMount` tiene UN solo llamador en todo el árbol: el hook de
   boot-wipe del cierre de sesión (`SwiftDataConfiguration.swift:689`).
4. **Arranque 2:** el archivo del store ya existe ⇒ `isFreshInstallForNeutralMount == false`; la marca
   no está armada ⇒ `shouldMountNeutralDurable == false` (`:296-301`); no hay sesión secundaria ni
   `mirrorOffArmed` ⇒ la decisión cae en `iCloudAvailable ? .iCloudMirror : .localNoMirror` (`:342`;
   inputs en `:1172-1178`). **El espejo se adjunta al store personal de la sesión solo-grupos** e
   importa el contenedor privado del Apple ID.

Efectos derivados: `hasExistingData` pasa a `true`; el bridge de grupos escribe en un Panel que ahora
tiene histórico ajeno; y «Activar Yala completo» (ticket
`full-mode-activation-must-ask-where-personal-data-lives`) correría el onboarding encima de esos datos
sin validación.

## Lo que se espera (ADR §2-3)

Una sesión en la nube **solo grupos** no tiene sesión privada: su store personal se monta **sin espejo
de iCloud** en TODOS los arranques, hasta que el usuario elija explícitamente lo personal (privado o
nube) desde «Activar Yala completo».

## Alcance

- Que la decisión de mount deje de inferir «no ha elegido» de la ausencia de archivo y pase a
  derivarse del eje «¿hay sesión privada?» (ADR §2). Mientras ese eje no exista como estado explícito
  (ticket `shell-derives-from-two-session-axes`), el arreglo mínimo es que el alta solo-grupos deje el
  neutro **duradero** —armar la misma marca que arma el boot-wipe— y que esa marca **no caduque** con
  `hasShownWelcomeChooser` en este caso (hoy `shouldMountNeutralDurable` la anula si el chooser se vio;
  leer el docblock de `CloudSyncFlags.armNeutralMount:160-180` antes de tocarla: explica por qué caduca).
- Revisar el mismo patrón en la entrada por **invitación** (`presentGroupBackendInviteOnboarding` →
  `GroupBackendInviteEntryLogic`): es la otra puerta a solo-grupos y hereda el mismo mount.
- La salida de solo-grupos hacia «Yala completo → privado» es la que SÍ adjunta el espejo, y pasa por
  la validación del ticket `welcome-private-fresh-start-skips-icloud-check`.

## Criterios de aceptación

- [ ] Instalación fresca → «Vengo por un grupo» (crear o invitación) → alta → matar y reabrir la app
      ×3: `personalStoreMountedDecision` sigue siendo un mount sin espejo (breadcrumb/canario), y con
      datos en el iCloud del Apple ID **ninguno aparece** en el store personal (`checkHasExistingData
      == false`).
- [ ] «Restaurar desde iCloud» y «Primera vez → privado» siguen adjuntando el espejo cuando toca.
- [ ] El cierre de sesión solo-grupos sigue dejando el dispositivo en neutro duradero.
- [ ] Test unitario sobre `personalStoreDecision` / `shouldMountNeutralDurable` con el escenario
      «solo-grupos, archivo existente, chooser visto» → sin espejo.

## Cómo se prueba

- Unit: la lógica de mount es pura (`personalStoreDecision(storageMode:mirrorOffArmed:iCloudAvailable:
  secondarySessionActive:freshInstall:neutralDurable:)`), con tests en `YalaTests`.
- Device-QA (CloudKit): iPhone con datos en el iCloud del Apple ID → reinstalar → solo-grupos → reabrir.
  En simulador no hay iCloud: solo se puede verificar la DECISIÓN de mount, no la importación.
