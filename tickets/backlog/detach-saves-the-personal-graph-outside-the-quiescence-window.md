---
id: detach-saves-the-personal-graph-outside-the-quiescence-window
status: backlog
priority: medium
area: "modo-nube, groups, swiftdata"
created: 2026-09-11
source: "review adversarial del paso 10 (`groups-account-association-in-storage-row`), lente de sync"
---

# El des-puenteo del desasociar escribe el grafo PERSONAL fuera de la ventana de quiescencia que se comprobó

## Lo medido (2026-09-11)

`CloudSessionSignOut.detachGroupsAccount` reusa `pushGroupsForSignOut`, cuya quiescencia del store
personal (`awaitPersonalQuiescenceForGroupsSignOut`) se comprueba **dentro de `attemptGroupsOnlyClose`**,
o sea antes del push-all. Entre esa comprobación y el `context.save()` de
`GroupsAssociationDetach.detachBridge` pueden pasar hasta 20 ciclos de push con red, sus `sleep` de 250 ms
y un `await CloudAuthService.signOut()`.

En `.icloud` el mirror de CloudKit está VIVO y el `mainContext` es compartido por los tres stores: si en
esa ventana arranca un import, el save entra sobre un store a medio asentar — el `_assertionFailure` de
SwiftData que no atrapa ningún `do/catch` y que es la clase del crash-loop de restore.

Dos cosas lo hacen distinto de sus hermanos del paso 9, y las dos empeoran el caso:

- Es el primer camino de la familia que escribe el **grafo personal** (`TransactionItem`, `InboxDraft`) y
  no solo filas de sync-meta.
- Es el único que **no** termina en boot-wipe + relanzamiento, que en los otros enmascara el destrozo.

## Lo que se espera

Re-comprobar la quiescencia justo antes del `save()` del des-puenteo (el gate ya existe y es barato de
volver a pedir), o mover el des-puenteo delante del push-all — con el coste, entonces, de que un bloqueo
del push deje el puente ya soltado, que es peor. La primera opción es la que conserva el orden actual.

## Cómo se prueba

Con el andamio on-disk de los tres stores y el seam del gate de quiescencia: forzar «no quieto» entre el
push y el save, y exigir que el desasociar espere o se bloquee en vez de guardar.
