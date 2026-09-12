---
id: groups-purge-save-crosses-two-stores-without-atomicity
status: backlog
priority: medium
area: "modo-nube, groups, swiftdata"
created: 2026-09-11
source: "review adversarial de `detach-failure-looks-like-success` (lente de datos y sync)"
---

# El borrado del dominio Grupos promete «todo o nada» y su `save()` cruza dos archivos distintos

## El problema, en lenguaje de usuario

Suelto mi cuenta de grupos, o dejo el teléfono en blanco para otra persona. Si el borrado falla a
mitad, la app promete que no queda nada a medias. Puede no ser verdad: lo que se borra vive en **dos
archivos** y el teléfono podría terminar con los grupos todavía puestos pero su marcador de
sincronización borrado — el par que la regla de área marca como el peligroso.

## Lo medido (2026-09-11)

`DataWipeService.deleteLocalGroupsRows` hace un solo `context.save()` que abarca:

- las cinco entidades `Split*`, del `groupsSchema` (archivo `groups.sqlite`), y
- lo que el llamador mete en `alsoDeleting`: `GroupSyncOutbox` y `GroupSyncCursor`, del
  `syncMetaSchema` (archivo `syncmeta.sqlite`).

Su docblock y el de `CloudSessionSignOut.purgeGroupsDomainForDetach` afirman que el borrado es **UNA
transacción**, y de ahí cuelga el argumento de la regla `L211` de `.claude/rules/swiftdata-cloudkit.md`:
«el par coherente en una frontera de CUENTA es *filas borradas + cursor borrado*, atómico». Un
`ModelContext` de SwiftData con varias `ModelConfiguration` reparte el save entre los stores; **no está
comprobado** que un fallo del segundo deshaga lo comiteado en el primero, y `context.rollback()` solo
repone lo que sigue en memoria.

El par malo —«cursor borrado + filas VIVAS»— es el que la misma regla describe como el que re-emite
upserts con HLC nuevos al re-asociar.

## Cómo se prueba

Con el andamio de `GroupsDetachPurgeFailureTests`: tres stores on-disk y el **`syncmeta` en solo
lectura** (`allowsSave: false`), el de grupos escribible. Correr `purgeGroupsDomainForDetach` y contar
después las filas de `SplitGroup` y de `GroupSyncCursor`. Si `SplitGroup` sale en 0 con el cursor vivo
(o al revés), la atomicidad prometida no existe y hay que escribirla: dos `save()` con un orden que
haga inocuo morir entre ellos, o un sello que deje el par reparable en el arranque.

Los tests de hoy inyectan el fallo en `alsoDeleting`, o sea **antes** del `save()`: miden el rollback en
memoria, no la atomicidad del save.

## Por qué no se arregló en su ticket

`detach-failure-looks-like-success` cierra que el fallo se vea; la atomicidad cross-store es anterior a
él (viene de `detach-history-replay-can-tombstone-groups-on-next-launch`) y afecta también al «Empiezo
de cero», así que es su propio objeto.
