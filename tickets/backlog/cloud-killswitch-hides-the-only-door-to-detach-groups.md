---
id: cloud-killswitch-hides-the-only-door-to-detach-groups
status: backlog
priority: high
area: "modo-nube, settings, groups"
created: 2026-09-11
source: "review adversarial del paso 10 (`groups-account-association-in-storage-row`), lente de estados"
---

# Con el kill-switch de la nube bajado, quien tiene cuenta de grupos asociada se queda sin poder soltarla

## El problema, en lenguaje de usuario

Tengo mis datos en mi iCloud y una cuenta de Yala asociada para Grupos. Si Jürgen baja el kill-switch de
la nube por un incidente, la fila «¿Dónde viven tus datos?» desaparece de mis Ajustes — pero **Grupos
sigue funcionando**, porque tiene su propio interruptor. Me quedo con la cuenta asociada y sin ninguna
pantalla desde la que soltarla.

## Lo medido (2026-09-11)

- `StorageRowGateLogic.isVisible` = `isConfigured && (remoteEnabled || isEngaged)`. Para una sesión
  privada, `isEngaged` es **falso** (`storageMode != .cloud` y `uiState == .idle`), así que la fila
  depende entera de `remoteEnabled` (`CloudRemoteFlags.cloudModeEnabled`).
- Hoy no muerde: `CLOUD_MODE_ROLLOUT_PERCENT = "100"` en producción (`gateway/wrangler.toml`), y
  `CloudBackendConfig.isConfigured` es `true` siempre. La fila se ve y la sección es alcanzable
  (verificado además por XCUITest, `GroupsAssociationRowUITests`).
- Grupos va por `GROUPS_BACKEND_ROLLOUT_PERCENT`, que es otro flag: bajar uno no baja el otro.
- La otra pantalla de cuenta (`profile_yala_account`) no sirve de repuesto: solo ofrece cerrar sesión o
  borrar la cuenta, y además exige sesión viva.
- Variante corta del mismo caso: en una instalación fresca, antes del primer `/config`, el
  `absentDefault` de producción es `false`, así que la fila nace oculta hasta que llegue la primera
  respuesta remota.

**Hasta el paso 10 esconder esa fila bajo el kill era inocuo** —solo hablaba del almacenamiento
personal—; ahora el kill de la nube apaga un control de Grupos.

## Lo que se espera

Decidir cuál de las dos, y dejarlo escrito:

1. El gate de la fila gana un término: visible también si hay una cuenta de grupos asociada
   (`GroupsAccountAssociation.shared.hasAssociation`). Es el mismo criterio del `isEngaged` —«un usuario
   ya dentro conserva su panel de gestión»— aplicado al otro eje.
2. O la sección «Grupos» se muda a una fila propia de Ajustes, con su propio gate.

La (1) es más barata y respeta el porqué del gate actual, que es el escape ante incidente.
