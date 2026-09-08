---
name: mi-docblock-tambien-es-una-premisa
description: Lo que YO escribo en un docblock mientras implemento es una afirmación sin medir; cuatro falsas el 8-sep. La variante nueva: inventar una JUSTIFICACIÓN técnica para una línea que está ahí por otra razón.
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

**Cuarta y quinta, el mismo día, en `chat-assistant-plants-exchange-rate-one` — y la cuarta estrena
una FORMA distinta: la justificación inventada.** Escribí que el guard `abs(monto) > 0.0001` estaba
ahí porque «divide, y un monto que redondee a cero daría infinito o NaN». Falso y medible en diez
segundos: la guard de entrada ya exige `isFinite` y `> 0`, y `0.000372 / 0.00005` son 7,44. La razón
REAL de esa línea es la paridad con `recalculatePreferredCurrency` — si rompes el umbral en un solo
sitio, la fila cambia de número al repararse. Escribí una razón plausible en vez de la verdadera, y
eso es peor que no comentar: el comentario aseguraba que la rama protegía de algo de lo que no
protege, y **tapaba que la rama es alcanzable y ahí escribe un número falso** (la banda
`0 < monto <= 0.0001`, que acabó siendo ticket propio). La quinta, en la cabecera del test: afirmé
que el fichero «no comparte estado» con la suite hermana — cierto para el store de SwiftData y falso
para `SessionState` y los defaults compartidos.

**How to apply:** cuando escribas *por qué* existe una línea defensiva, la prueba es intentar
refutarla con un ejemplo numérico concreto. Si no consigues construir el caso del que dices que
protege, la razón que has escrito no es la razón — y la verdadera suele ser «paridad con X», que es
además la que el yo-futuro necesita para no romperla. Y cuando escribas «esto está aislado», di
aislado *de qué*: casi siempre lo está de una cosa y no de las otras tres.
