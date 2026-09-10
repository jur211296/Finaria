---
name: puerta-grupos-espejo-bloqueada
description: La mitad 2 de «Vengo por un grupo» sobre un store con espejo quedó BLOQUEADA esperando el verbo del paso 9; el código vive en una rama sin PR con los ~30 defectos anotados
metadata:
  type: project
---

**La mitad 2 de `groups-entry-on-a-mirrored-store-still-blocks-the-owner` está `blocked` esperando el
verbo «Salir de Yala en este dispositivo» del paso 9 (`session-exits-one-verb-per-session`).** Decisión
de Jürgen del 2026-09-10, tomada con la medición delante: **esperar al 9 y NO construir un borrado
propio en la puerta de Grupos.**

**Why:** se implementó entera y la review adversarial (3 lentes, ~30 defectos, todos míos) midió dos
bloqueantes que no son de cableado: el borrado de arranque del cierre de sesión no es reusable en un
camino que no cierra sesión (se lleva el canal de Grupos y las colas de Apple Pay/Siri, que no están en
iCloud), y «esperar a que suba» no se puede demostrar con las señales de hoy. Las dos piezas que faltan
son exactamente las que la matriz asigna al paso 9.

**How to apply:**

- **El código está en la rama `encargo/2026-09-10-groups-entry-on-a-mirrored-store-still-blocks-the-owner`,
  empujada a origin y SIN PR.** Dos commits: el código (con un aviso «no está terminado» en el docblock
  de `GroupsNeutralReturnLogic` y en la vista) y la documentación. El gate pasó en verde: 6750 unit /
  693 suites, 83 XCUITest en 34 suites.
- **No la mergees ni abras PR** hasta que el paso 9 exista. La rama del espejo vivo llega a la pantalla
  de espera y ahí se queda a propósito.
- **Cuando toque retomarla**, la medición está en el ticket (`tickets/blocked/`): los dos bloqueantes,
  el defecto de diseño del disparador (tiene que ser el eje ANCHO `attachesCloudKitMirror`, y «¿hay
  respaldo?» solo lo contesta CloudKit, porque el token de ubiquity mide iCloud **Drive**), y lo que
  falta además — la entrada por **invitación**, que el ticket pide y nunca se tocó.
- **Tres tickets nuevos salieron de aquí y son del repo, no del chip:**
  `icloud-export-error-latch-never-clears` (un export con éxito no limpia `lastExportError`, y dos
  consumidores del cutover lo leen), `forcesync-returns-ok-without-touching-the-network`, y
  `sign-out-boot-wipe-has-no-way-back-if-it-aborts`. Los tres son insumos del paso 9: mirarlos antes de
  escribir su espera.
- El worktree quedó vivo, sin `/cerrar-total`: no hay PR que mergear.
