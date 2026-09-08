---
id: tests-borran-el-store-sqlite-abierto
status: backlog
priority: medium
area: testing
created: 2026-09-07
updated: 2026-09-07
source: medido de camino durante unit-suite-nondeterministic-reds (2026-09-07)
---

# Los tests borran el directorio del store SQLite con la conexión todavía abierta

## Lo medido

Una corrida completa de `YalaTests` emite **554-556** veces esta línea, y el número es estable entre
corridas (556 · 550 · 554 en tres corridas del 2026-09-07):

```
BUG IN CLIENT OF libsqlite3.dylib: database integrity compromised by API violation:
vnode unlinked while in use:
/Users/jur/Library/CoreSimulatorInternal/Devices/9D0F6D32-…/tmp/CKCapture-685870F2-…/…
```

Es SQLite avisando de que el fichero del store se **borró mientras la conexión seguía abierta**.

Repartido por prefijo del directorio temporal (corrida 1):

| veces | prefijo | veces | prefijo |
|---|---|---|---|
| 96 | `GroupsPendingBridge-` | 36 | `GroupSettlementDeletion-` |
| 90 | `GroupBridgeCaseB-` | 33 | `GroupCleanup-` |
| 63 | `CKCapture-` | 18 | `SyncApplyEngine-` |
| 53 | `GLOR-` | 18 | `GroupBridgeCloudSync-` |
| 45 | `GroupsSync-` | 17 | `SyncIdentity-` |
| 44 | `GroupRouting-` | 16 | `JoinerBridge-` |

El patrón es siempre el mismo: el test crea un directorio temporal con UUID
(p. ej. `CKIdentityCaptureTests.swift:29`, `.appendingPathComponent("CKCapture-\(UUID().uuidString)")`),
abre un store dentro y borra el directorio en el teardown sin cerrar antes la conexión.

## Por qué importa

Hoy **no rompe nada**: las tres corridas dieron 0 rojos. Pero es un uso indebido documentado del API
de SQLite («database integrity compromised»), y es exactamente la clase de cosa que deja de ser
benigna cuando el FS va justo — que es el entorno en el que
[[unit-suite-nondeterministic-reds]] vio cinco rojos que no se pudieron reproducir con el disco sano.
Mientras siga ahí, es una variable de confusión: cualquier rojo raro de esa familia va a costar
descartar esto primero.

Además ensucia el log: son ~550 líneas por corrida escritas desde la app, y son parte del ruido que
parte las líneas del reporter (la causa medida en aquel ticket).

## Qué haría falta

1. Cerrar el `ModelContainer` / la conexión antes de borrar el directorio en el teardown, o
2. no borrar el directorio y dejar que el simulador recicle `tmp/`, o
3. usar un store in-memory donde el test no necesite fichero.

Elegir **una** y aplicarla a los 12 prefijos, no solo al primero que aparezca.

## Criterio de hecho (AC)

- [ ] Una corrida completa de `YalaTests` emite **cero** líneas `vnode unlinked while in use`.
- [ ] La suite sigue en verde y con el mismo conteo (`Test run with` / result bundle).

## Relacionados

- [[unit-suite-nondeterministic-reds]] — de donde salió esta medición.
