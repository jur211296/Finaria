---
id: session-exits-one-verb-per-session
status: backlog
priority: high
area: "settings, modo-nube, groups"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §5-6"
---

# Cierres de sesión: dos botones («Cerrar sesión», «Vaciar datos»), un verbo por sesión, y la sesión privada que sale borra lo local

## El síntoma, en lenguaje de usuario

Según cómo entré a Yala veo botones distintos con nombres distintos: «Cerrar sesión», «Cerrar sesión
de grupos», «Salir de Yala en este dispositivo», «Vaciar datos», «Eliminar mi cuenta», y algunos
hacen cosas que no dicen. El peor: en privado, «Cerrar sesión» **no cierra nada** — me devuelve a la
pantalla de bienvenida con todos mis datos vivos en el teléfono, a la vista del siguiente que lo abra.

## Lo medido (2026-09-09, árbol `3a94604e`)

- 7 verbos visibles sobre **11 operaciones** (`DestructiveScopeLogic.Operation`,
  `Yala/App/Logic/DestructiveScopeLogic.swift`), **4 caminos** (`CloudSignOutFlowLogic.Path`,
  `Yala/App/Logic/CloudSignOutFlowLogic.swift`) y **4 layouts** de filas (`RowLayout`), elegidos por
  `storageMode`, `isGroupInviteMode`, `hasLiveSession` y `secondarySessionActive`.
- `.privateReset` (`Yala/Services/CloudSync/CloudSessionSignOut.swift:9-12`): «NO toca datos —
  teardown, signOut local, reset de onboarding → Welcome». Es la ventana «Welcome con corpus del dueño
  vivo» que obliga a la puerta de «datos ajenos» de grupos y origina los tickets de «secundaria».
- `.groupsOnlySignOut` cierra solo grupos también cuando hay iCloud privado con cuenta de grupos
  (la fila «Cerrar sesión de grupos» + «Salir de Yala» en `RowLayout.groupsSignOutPlusExitYala`).
- Sitios: `DestructiveScopeSheet.swift` (todas las operaciones), `ProfileView.swift`,
  `YalaAccountView.swift` («Tu cuenta de Yala»: método, dónde viven los datos, salir, volver a
  iCloud, eliminar), `UserDataResetView.swift`, `GroupsRetentionView.swift` («Seguir con mis grupos»
  tras vaciar), `SignOutRelaunchView.swift`.

## Lo que Jürgen decidió (ADR §5-6)

| Sesión | Verbo | Qué hace |
|---|---|---|
| Privada, sin grupos | **Cerrar sesión** | borra lo local; iCloud intacto; Welcome |
| Privada + grupos asociados («equipo») | **Cerrar sesión** | sube cambios de grupos, borra lo local, iCloud intacto; Welcome. **No hay «salir solo de grupos»** |
| Nube completa | **Cerrar sesión** | sube cambios, borra lo local, cuenta intacta; Welcome (= `cloudSecureSignOut` de hoy) |
| Nube solo grupos (sin sesión privada) | **Cerrar sesión** | sube cambios de grupos, borra lo local; Welcome |
| Datos | **Vaciar datos** | privada: local **e** iCloud; nube: contenido de la cuenta. **Grupos, nunca** |
| Cuenta en la nube | Eliminar mi cuenta | **dentro de «Tu cuenta de Yala»**, no como botón principal (App Store 5.1.1 v: obligatorio mientras la app cree cuentas) |
| Grupo | Salir del grupo | dentro de cada grupo, como hoy |

Dos botones en Ajustes y nada más. El texto de confirmación de cada uno dice exactamente qué se
borra y qué queda (el `DestructiveScopeSheet` ya sabe pintar eso por ubicación).

## Alcance

1. `CloudSignOutFlowLogic.path` pasa a decidir por los dos ejes del ADR (¿sesión privada? × sesión
   nube activa y su `kind`), y `.privateReset` deja de existir: la salida privada **borra lo local**
   (`DataWipeService.wipeAllUserData` + dominio grupos local si no hay asociación) y arma el neutro
   duradero, como hoy hace `cloudSecureSignOut` en el boot-wipe (`SwiftDataConfiguration.swift:689`).   El contenedor de iCloud no se toca: «entrar» vuelve a ser «Restaurar desde iCloud».
   **Antes de borrar, esperar al último export a CloudKit.** Medido el 2026-09-09: nadie espera hoy
   (`iCloudSyncService.startObserving` solo observa `NSPersistentCloudKitContainer.eventChangedNotification`
   para pintar estado; `.privateReset` no borraba y por eso no lo necesitaba). Con el borrado local, un
   movimiento guardado hace cinco segundos y aún no exportado **se pierde para siempre**. Regla: el wipe
   solo corre tras un evento `.export` con éxito posterior al último save (o un `exportPending == false`
   equivalente); sin red o con el export atascado, «un momento más» como en la nube, y nunca borrar.
   Kill-safety: reusar el arm del boot-wipe (`SwiftDataConfiguration.swift:689`), que ya es kill-safe.
2. «Equipo»: con asociación, cerrar sesión = `pushAll` verificado de grupos (el mismo de
   `cloudSecureSignOut`, «jamás descartar») → cerrar la sesión nube → wipe local → Welcome.
   `.groupsOnlySignOut` queda solo para la celda «sin sesión privada + solo grupos».
3. `RowLayout` se reduce a un caso: dos filas. `GroupsRetentionView` se retira (con «Vaciar datos»
   sin tocar grupos, no hay nada que retener: la app sigue enseñando los grupos).
4. `DestructiveScopeLogic.Operation` se reduce a lo que la tabla necesita; `deleteFrozenCopy` (copia
   vieja de iCloud del cutover) pasa a un apartado «avanzado» dentro de «Tu cuenta de Yala».
5. «Eliminar mi cuenta» se mueve a `YalaAccountView` (ya está ahí como fila) y desaparece de las
   listas principales; sigue cumpliendo el borrado GDPR (`POST /account/delete`).
6. Copy nuevo en los 16 `.strings`; los strings de las operaciones retiradas se retiran.
7. **«Vaciar datos» en privada + asociada (D):** borra lo personal (local + iCloud), **la asociación y los
   grupos siguen**, y la app abre el onboarding [P]; al terminar sigue en D.
8. **«Eliminar mi cuenta» en D:** vive en «Tu cuenta de Yala» de la cuenta asociada; = desasociar +
   borrado GDPR de esa cuenta; lo personal privado no se toca.
9. Cambio de Apple ID en el teléfono con sesión privada: es un cierre de sesión (la sesión es del Apple
   ID); hoy `AppBootstrapper.checkForICloudMismatch` avisa — alinear en `shell-derives-from-two-session-axes`.

## Criterios de aceptación

- [ ] Ajustes muestra exactamente «Cerrar sesión» y «Vaciar datos» en las cuatro celdas del ADR.
- [ ] Privada: cerrar sesión → Welcome con `checkHasExistingData == false`, `personalStoreMountedDecision`
      neutro duradero al reabrir, y «Restaurar desde iCloud» encuentra los datos (device-QA).
- [ ] Privada: cerrar sesión 2 s después de guardar un movimiento nuevo → el movimiento está en iCloud
      (restaurar en otra instalación lo trae). Sin red → «un momento más», el store sigue intacto.
- [ ] D: «Vaciar datos» deja grupos y asociación; «Eliminar mi cuenta» desasocia y borra solo la nube.
- [ ] Equipo: cerrar sesión con un gasto de grupo sin subir → el gasto llega al backend antes del wipe
      (canario `pushAllVerdict == .drained`); si no puede subir, el cierre se bloquea con el «un momento
      más» existente, nunca descarta.
- [ ] Nube completa y solo-grupos: byte-idéntico a hoy salvo el copy.
- [ ] «Vaciar datos» nunca borra `YalaGroups`; en privada borra el contenedor de iCloud (verificable
      con «Restaurar desde iCloud» → `notFound`).
- [ ] «Eliminar mi cuenta» sigue accesible en ≤ 2 toques desde Ajustes para toda sesión nube.
- [ ] Tests: `CloudSignOutFlowLogicTests`, `DestructiveScopeLogicTests` reescritos sobre la tabla;
      XCUITest de Ajustes por celda (seeds uitest existentes para icloud / cloud / solo-grupos).

## Depende de

`cloud-sign-in-discovers-account-kind` (el `kind` de la sesión activa). Se coordina con
`groups-account-association-in-storage-row` (la asociación es el estado que distingue «equipo»).
