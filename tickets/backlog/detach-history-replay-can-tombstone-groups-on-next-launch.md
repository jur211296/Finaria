---
id: detach-history-replay-can-tombstone-groups-on-next-launch
status: backlog
priority: high
area: "modo-nube, groups, settings"
created: 2026-09-11
source: "review adversarial del paso 10 (`groups-account-association-in-storage-row`), lente de sync"
---

# Desasociar borra las filas de grupos por FILAS, y el History del arranque siguiente puede convertirlas en tombstones

## El problema, en lenguaje de usuario

Suelto mi cuenta de grupos en este iPhone. Los grupos siguen en mi cuenta —eso es lo que la app me
promete— y los demás miembros no deberían notar nada. En un arranque posterior, si el canal vuelve a
mirar el historial de cambios locales antes de que nadie le diga que esas zonas ya no son suyas, esos
borrados **locales** pueden viajar al servidor y **borrar los gastos para todos los miembros del grupo**.

## Lo medido (2026-09-11, sobre el árbol del paso 10)

`CloudSessionSignOut.detachGroupsAccount` borra las filas `Split*` con `context.delete` y purga el
cursor en la MISMA transacción, con el canal ya cortado (`teardownForSignOut`) y sin credenciales. En el
proceso vivo nada sale del teléfono. El riesgo está en el SIGUIENTE arranque:

- Al re-asociar, `loadOrCreateCursor` crea un cursor virgen ⇒ `fetchHistory(after: nil, floor: nil)`
  devuelve **todo** el History, esos deletes incluidos.
- Lo único que hoy impide traducirlos a tombstones es que `backendGroupZoneIDs` sale VACÍO porque
  `drainOnce` corre ANTES del pull dentro de `syncCycleOnce`. **Es un efecto colateral del orden, no una
  defensa**: si ese primer drain lanza en cualquiera de sus cuatro fetches, el `catch` traga, no se
  escribe cursor, el ciclo sigue al pull que repuebla las zonas, y el drain siguiente sí emite.
- `purgeQueuedSplitGroupTombstones` no cubre esto: solo barre `split_groups`.

Es la misma familia que «Un gate por ZONA calculado sobre filas VIVAS es la herramienta equivocada para
un tombstone por FILA» (`docs/aprendizajes-tecnicos.md`).

## Lo que se espera

La regla de área ya dice cuál es la forma correcta: **una salida que borra lo local borra ARCHIVOS antes
del mount, nunca FILAS** (`.claude/rules/swiftdata-cloudkit.md`). El paso 9 lo hace así para sus tres
cierres (`armSignOutWipe` + `markSignOutWipeIncludesGroups`, y el boot-hook borra el trío de ficheros).
El desasociar debería usar ese mismo mecanismo —acotado al store de grupos y sin tocar lo personal— o,
si se queda con el borrado por filas, anclar el cursor al token actual DESPUÉS del borrado en vez de
purgarlo, para que el History de esos deletes quede por debajo del high-water.

Lo que NO vale es dejarlo apoyado en el orden de `syncCycleOnce`: un reordenamiento futuro de ese método
reabre el agujero sin que nadie lo note.

## Cómo se prueba

Con el andamio de `CloudSyncEngineTests` (containers on-disk con los tres stores, el History es
por-CONTAINER): desasociar con filas de grupo vivas, forzar el fallo del primer `drainOnce`, re-asociar y
**contar filas de `GroupSyncOutbox` tras el ciclo**. Con el agujero abierto salen tombstones de cada
`SplitExpense` borrado; con el arreglo, cero.
