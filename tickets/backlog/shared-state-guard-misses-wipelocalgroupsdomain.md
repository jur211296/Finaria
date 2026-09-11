---
id: shared-state-guard-misses-wipelocalgroupsdomain
status: backlog
priority: medium
area: "testing"
created: 2026-09-11
source: "review adversarial de `detach-history-replay-can-tombstone-groups-on-next-launch` (lente de contrato)"
---

# El guard que obliga al trait de aislamiento busca `wipeAllUserData(` y se le escapa `wipeLocalGroupsDomain(`

## Lo medido (2026-09-11)

`SharedStateIsolationTests.todaSuiteQueEjecutaElWipeLlevaSuTrait` exige el trait
`.wipeAppGroupMirrorIsolated` a toda suite cuyo fuente contenga `wipeAllUserData(`. Pero
`DataWipeService.wipeLocalGroupsDomain` **también** toca estado compartido: su parámetro `resetSyncState`
tiene por defecto `GroupsOutboxMirror()?.purgeAll()`, que purga el espejo REAL del App Group.

⇒ una suite que llame a `wipeLocalGroupsDomain` **sin** inyectar `resetSyncState` pasa el guard y borra el
espejo de las demás. El fallo que produciría es de los que no se parecen a su causa: otra suite se queda sin
sus filas de outbox y falla por «no encontró lo que sembró», en una corrida completa y no en solitario — la
misma firma que el repo ya documenta en `testing.md` («verde a solas, cero acompañado»).

Hoy no hay ninguna suite en esa situación (las que la llaman inyectan el seam), así que es un guard con un
hueco, no un rojo.

## Lo que se espera

Que el escáner cuente también `wipeLocalGroupsDomain(` — y que se mire si hay un tercer escritor del espejo
con el mismo perfil antes de cerrar. La aserción del guard tiene que seguir muriendo con su mutante: quitar
el trait de una suite listada debe dar rojo.
