---
id: needsrelaunch-hides-the-groups-section
status: backlog
priority: medium
area: "modo-nube, settings, groups"
created: 2026-09-11
source: "review adversarial de `cloud-killswitch-hides-the-only-door-to-detach-groups`, lente de estados"
---

# Con la migración esperando relanzamiento, la cuenta de grupos vuelve a quedarse sin puerta

## El problema, en lenguaje de usuario

Si mi Yala quedó esperando a que cierre y vuelva a abrir la app (tras una migración o una reversa),
Ajustes → «¿Dónde viven tus datos?» enseña solo esa tarjeta. La sección «Grupos» no está, así que
mientras no relance no puedo soltar mi cuenta de grupos. Y ese estado **no es un tránsito**: sobrevive a
todo hasta que mate la app.

## Lo medido (2026-09-11)

`StorageSettingsView.swift:171-172`:

```swift
case .needsRelaunch(let direction):
    relaunchCard(direction)
```

Nada más. El estado se deriva de `mirrorOffArmed` / `phase == .reverseMountMirror`
(`CloudMigrationController.swift:79-88`), **los dos durables**.

El caso con daño real es `.needsRelaunch(.toICloud)` —la reversa—: ahí `storageMode` ya es `.icloud` ⇒
`deviceState == .privateSession` ⇒ la sección **sí aplicaría** (`.associated` o `.associatedNeedsSignIn`,
las dos con `offersDetach == true`) y el `case` no la monta. Se llega por el camino normal:
`promoteAssociatedAccountThenCutover` (`CloudIdentityRoutingLogic.swift:206-208`) deja la asociación
escrita y la reversa devuelve el dispositivo a sesión privada con ella puesta.

`.migrating` / `.reverting` tienen el mismo hueco durante el cutover; en `.reverting` el daño es nulo
(`storageMode == .cloud` ⇒ `.sameAccountAsPersonal`, que no ofrece soltar nada de todos modos).

**El criterio para cerrarlo ya está escrito tres líneas más abajo**, justificando por qué
`.waitingForLeader` y `.failed` SÍ montan la sección (`StorageSettingsView.swift:175-178`): «salen del
journal PERSISTIDO… ocultar aquí la sección dejaría sin poder desasociar —indefinidamente—».
`.needsRelaunch` cumple esa misma descripción y no recibió el mismo trato.

## Lo que se espera

Decidir si la card de relanzamiento sigue siendo **bloqueante** —es su diseño: «cierra Yala y vuelve a
abrirla»— o si la sección de Grupos es la excepción que merece convivir con ella. Si se monta, cuidado
con no convertir una card bloqueante en una pantalla normal.
