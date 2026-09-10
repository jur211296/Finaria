---
id: forcesync-returns-ok-without-touching-the-network
status: backlog
priority: medium
area: "modo-nube, sync"
created: 2026-09-10
source: "review adversarial del paso 5-b (`groups-entry-on-a-mirrored-store-still-blocks-the-owner`), dos lentes independientes"
---

# «Sincronizar ahora» dice que fue bien sin haber intentado nada

## Lo medido (2026-09-10)

`iCloudSyncService.forceSync(modelContext:)` (`:517`) empieza con:

```swift
guard !status.isSyncing else { return .ok }
```

Si al entrar ya hay un sync en vuelo —un import, un export o el `.setup` inicial— devuelve `.ok`
**antes** de `allRecordZones()` (la única prueba de red real), **antes** de `modelContext.save()` y
**antes** de despertar el motor de exportación. El valor `.ok` se documenta como «el motor arrancó»,
pero en ese camino nada arrancó: se devuelve el éxito de otro.

Para su consumidor original —la nota contextual de Ajustes (`iCloudSyncSettingsView`)— es inofensivo:
hay un sync en curso, así que decir «va bien» es razonable. El problema es que `.ok` **se lee como
prueba** en cuanto alguien lo reusa: el paso 5-b lo tradujo a «lo local está en iCloud» y con eso
autorizaba un borrado. Ese camino se paró, pero el contrato sigue siendo engañoso para el siguiente.

## Lo que se espera

Que el valor de retorno distinga «lo intenté y llegó» de «ya había algo en curso, no hice nada». Un caso
nuevo (`.alreadySyncing`) deja al consumidor decidir; hoy no puede.

## Criterios de aceptación

- [ ] `forceSync` distingue «no hice nada porque ya había sync» de «intenté y llegué».
- [ ] La nota de Ajustes sigue diciendo lo mismo que hoy en ese caso (no-regresión de copy).
- [ ] Un test cubre el camino del `guard` (hoy no está cubierto).
