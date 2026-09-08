---
name: mi-docblock-tambien-es-una-premisa
description: Lo que YO escribo en un docblock mientras implemento es una afirmación sin medir, y dos veces el 8-sep describía la intención en vez del comportamiento
metadata:
  type: feedback
---

Trato mis propios comentarios como si fueran documentación de algo verificado. **No lo son mientras
los escribo: son la intención, y el código puede no cumplirla.** Mídelos antes de commitear igual que
mido los del ticket.

**Why:** el 2026-09-08, en `repair-queue-has-no-exit-for-partial-rate-rows`, escribí dos afirmaciones
falsas en docblocks nuevos y ninguna la habría cazado la suite:

1. En `FXRepairQueueLogic`: «un fallo de red no escribe la huella —eso es transitorio y merece
   reintento—». **El código no lo hacía**: `ensureRates` se tragaba el error del fetch y devolvía
   `Void`, así que el barrido no tenía forma de distinguir «el proveedor no tiene esa divisa» de «no
   llegué a preguntar», y sellaba las dos igual. Lo cazaron DOS lentes distintas, las dos citando mi
   propia frase como prueba de la intención incumplida.
2. En `TransactionItem`: «SwiftData ensucia igual, y `updatedAttributes` no compara valores». Medido
   después: `hasChanges` sí se ensucia, pero **el outbox no crece**. Había heredado la premisa del
   ticket sin comprobarla y la reescribí como si fuera un hecho conocido del repo.

La forma es siempre la misma: describo lo que el mecanismo **debería** hacer en el momento en que lo
estoy diseñando, y luego el código sale distinto o la premisa era prestada. Un docblock afirmativo
sobre comportamiento es tan verificable como una coordenada de un informe.

**How to apply:** al terminar de implementar, releer los comentarios NUEVOS buscando las frases con
forma de hecho —«no ocurre», «solo pasa si», «X no compara», «esto corta»— y, por cada una,
preguntarse si la medí o la deduje. Las que no estén medidas: o se miden (suele costar un test o un
grep) o se reescriben como lo que son. Vale doble para el docblock que justifica **por qué** existe un
mecanismo: si su porqué es falso, el mecanismo puede estar de más y nadie lo va a volver a mirar.

Relacionado: [[mi-fix-hereda-la-forma-del-bug]] — misma familia, otra superficie. Y
[[la-premisa-del-encargo-tambien-se-mide]], que cubre las premisas ajenas; ésta cubre las mías.
