---
name: mi-fix-hereda-la-forma-del-bug
description: Al arreglar un bug tiendo a repetir su misma forma en el arreglo. Antes de dar por cerrado un fix, aplicarle al arreglo la pregunta que definía el bug original.
metadata:
  type: feedback
---

**Cuando arreglo un bug, el arreglo tiende a cometer el mismo error que el bug.** No uno parecido:
**el mismo**, con otras piezas. Antes de cerrar, coge la frase que describe el bug original y
pregúntasela al arreglo.

**Why:** medido el 2026-09-06 en `fx-presentation-still-shows-1to1`. El bug era *«una fuente peor
TAPA una mejor y presenta el resultado como bueno»*: una tabla de tipos de cambio incompleta
escondía los escalones de respaldo que sí tenían el dato. Mi arreglo sembraba la caché con la tabla
estática **entera** — y como esa tabla cubre todas las divisas, hacía **vacua la comprobación de
cobertura que yo acababa de escribir**: la tasa real de ayer no se usaba nunca por esa vía. Otra
fuente peor tapando una mejor, en el commit que existía para impedirlo. Medido: 24,79 por una ruta,
**40** por la otra, en el mismo instante.

Y no fue casualidad ni descuido puntual — el mismo día, la misma sesión:

- El comentario que escribí decía *«sin fila la caché se llena con la tabla estática, que cubre
  todas las divisas y convierte bien»*: **describía el bug nuevo como si fuera la solución**. Un
  comentario seguro de sí mismo es una señal, no una garantía.
- Mi test del acumulador ponía la transacción aproximada **la última**, así que pasaba igual con
  `=` en vez de `||`: medía el orden del array, no la acumulación que su propio docstring afirmaba.
- Dos de mis greps de auditoría dieron cero por el filtro (un glob sin comillas en zsh, una
  asignación multilínea que el patrón no cogía), no por el código.

**How to apply:** al terminar un fix, antes del gate:

1. **Enuncia el bug en una frase** y aplícasela al arreglo, literalmente. «¿Mi arreglo tapa una
   fuente mejor?» «¿Mi arreglo silencia algo?» «¿Mi arreglo tiene un default que miente?».
2. **Muta el arreglo y exige rojo.** No basta con que los tests pasen: el mutante que reintroduce el
   defecto tiene que ponerlos rojos. Los dos que corrí ese día cazaron los dos defectos.
3. **Lanza la review adversarial aunque el cambio te parezca cerrado.** Tres lentes cazaron cinco
   defectos míos ahí, y ninguno lo veía la suite en verde. Es la tercera vez que pasa
   ([[review-adversarial-caza-lo-mio]]): no es mala suerte, es el modo normal de fallar.

Relacionado: [[mis-mediciones-fallan-por-el-filtro]] (el control positivo también va en los greps de
auditoría) · [[la-premisa-del-encargo-tambien-se-mide]] (medir la premisa ajena; ésta es su gemela,
medir la propia).
