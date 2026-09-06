---
name: la-premisa-del-encargo-tambien-se-mide
description: El encargo de Jürgen puede traer una premisa falsa heredada del ticket; medirla es barato y cambia el trabajo entero
metadata:
  type: feedback
---

La regla «mide antes de obedecer a un documento» **incluye el propio encargo**, no solo el ticket y
las docs del repo. El encargo lo redacta Jürgen leyendo el ticket, así que hereda sus errores y
llega con el tono de un hecho establecido.

**Why:** el 2026-09-06, el encargo de `groups-leave-rpc-error-10` afirmaba en su sección «Contexto»
que el caso #10 era `channelDisabled` (kill-switch) y avisaba «no confundir con `ownerCannotLeave`
(eso sería otra frase)». Era exactamente al revés, y el propio ticket marcaba esa lectura como
*inferencia sin comprobar*. Medirlo costó un script de Swift de 40 líneas: el tag que Foundation
imprime **no sigue el orden de declaración** (los casos con payload van primero). Con la premisa
buena, las dos «caras» que el ticket separaba resultaron ser el mismo defecto, y el punto 4 del
encargo («si el 10 es canal apagado…») se quedó sin objeto.

**How to apply:** cuando el encargo afirme un hecho **verificable** —un número, una coordenada, qué
caso de un enum es cuál—, mídelo antes de construir encima, sobre todo si el ticket de origen lo
marcó como inferido. No bloquea: el trabajo suele seguir siendo el mismo (aquí, «dar copy honesto»),
pero cambia cuál es el caso protagonista y qué hay que arreglar de verdad. Y díselo — no como
corrección, sino como el dato que reordena el ticket. Ver [[review-adversarial-caza-lo-mio]] y
[[mis-mediciones-fallan-por-el-filtro]].
