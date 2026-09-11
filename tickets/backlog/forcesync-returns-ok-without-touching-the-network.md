---
id: forcesync-returns-ok-without-touching-the-network
status: backlog
priority: medium
area: "modo-nube, sync"
created: 2026-09-10
source: "review adversarial de la primera pasada de `groups-entry-on-a-mirrored-store-still-blocks-the-owner` (2026-09-10); rescatado a `2.1` el 2026-09-11 — vivía solo en una rama sin PR"
---

# `forceSync` contesta `.ok` sin tocar la red, y eso hace inservible cualquier «ya está subido»

## Lo medido (2026-09-10)

`iCloudSyncService.forceSync` devuelve `.ok` **sin tocar la red ni guardar** si ya hay un sync en vuelo. Y
su watchdog devuelve el estado a `.idle` a los 8 s cuando no llega ningún evento, así que «ya no está
sincronizando» significa también «todavía no ha empezado».

Las dos cosas juntas hacen que `forceSync` **no pueda usarse como testigo de que algo subió**: el estado
que más lo dispara —el espejo importando durante el Welcome— es justo donde miente.

## Por qué sigue vivo después del paso 9

El paso 9 (`session-exits-one-verb-per-session`) construyó un testigo propio para SU caso —el historial de
SwiftData contra el ancla del último export con éxito— y **no usa `forceSync`**. Pero el método sigue
teniendo sus otros consumidores, y para ellos el `.ok` mentiroso sigue ahí.

## Lo que hay que mirar

- Los call-sites de `forceSync` y cuáles interpretan su `.ok` como «llegó».
- Si el `.ok` del early-return debería ser un caso propio (`.coalesced`) para que el llamador decida.
- El watchdog de 8 s: distinguir «terminó» de «no empezó» necesita otra señal, no un timeout.

## Criterios de aceptación

- [ ] Ningún consumidor puede confundir «coalescido» con «subido».
- [ ] El caso «no ha empezado» es distinguible de «terminó» en el estado que publica el servicio.
