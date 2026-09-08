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

## Segundo caso, el mismo día, y más fuerte: el defecto YA estaba arreglado

El encargo de `groups-pending-member-can-open-group` (2026-09-06) pedía «cerrar la puerta en el
cliente: la tarjeta del grupo no abre el detalle mientras el miembro esté en `pendingApproval`».
Medido antes de escribir código: **la tarjeta ya no lo abría**. `GroupCardView.handleTap` tenía un
`case .pendingApproval` que no navegaba desde `#26`, y el doc del helper lo decía con todas las
letras.

Lo que fallaba en el reporte de campo (TestFlight build 12, 28-ago) era la **identidad** que
alimentaba ese gate: `currentMemberStatus` resolvía por el flag `isCurrentUser`, que
`GroupsSyncClient.applyMember` **nunca enciende**, así que a quien llegaba por el pull le devolvía
`nil`, el modo caía en `.active` y la tarjeta abría. Y eso lo arregló **otro ticket**, `5ca4dd47`
(4-sep), ya en `2.1`. Dos comandos lo zanjaron: `git log -L '/func currentMemberStatus/,+4:<f>'` y
`git branch -a --contains`.

**Why:** el encargo describía el síntoma de un build de hace nueve días como si fuera el estado de
hoy. En un repo donde entran varios PR al día, **un reporte de campo caduca**, y el trabajo que
describe puede haberlo hecho ya un vecino sin saberlo. Si hubiera «cerrado la puerta» sin medir,
habría escrito un gate encima de otro y declarado arreglado algo que ya lo estaba — sin tocar
ninguna de las tres cosas que sí seguían rotas.

**How to apply:**
- Cuando el encargo venga de un **reporte de device con fecha y build**, lo primero es preguntarse
  «¿sigue vivo en `2.1`?». `git log -L` sobre la función sospechosa y `git branch --contains` sobre
  el commit que salga cuestan un minuto y contestan.
- **Que la premisa sea falsa casi nunca cancela el trabajo**: aquí quedaban tres cosas reales (el
  tap era un muro mudo, había dos puertas más sin gate, y el copy prometía lo que la decisión
  eliminaba). Lo que cambia es **cuál es el trabajo**, no si lo hay.
- Y díselo a Jürgen en esos términos: «el bug que reportaste ya no se reproduce, lo cerró X; lo que
  encontré abierto es esto otro». Ver [[mis-mediciones-fallan-por-el-filtro]].

## 2026-09-07 — la variante silenciosa: la cifra no era falsa, era de la magnitud equivocada

En `el-job-de-tests-del-ci-no-tiene-timeout` el ticket traía una tabla de duraciones y una
conclusión: «~80 minutos de media», con la recomendación de «un `timeout-minutes` alrededor de 120».
Nada de eso era mentira. Pero:

- **la muestra eran 4 runs.** Con los 39 que había (todos los que dispararon el job en dos días), la
  mediana real es **89**, no 80, y el p95 sube a 99,5. Cuatro puntos no sostienen un percentil, y el
  ticket llamaba «percentil alto» a lo que era el máximo de cuatro.
- **y sobre todo, medía el objeto equivocado.** La decisión que el propio ticket recogía sacaba la
  UI del PR; en cuanto la sacas, el número que gobierna el tope del PR ya no es el del job entero
  sino el de **build + unit**, que nadie había medido: p95 **27,2**, máximo **29,9**. El «alrededor
  de 120» del ticket habría sido un tope cuatro veces mayor que el peor caso real — o sea, ninguno.

La única forma de ver esto fue medir **por paso**, no por job (`/actions/runs/<id>/jobs` trae cada
step con `started_at`/`completed_at`). Coste: un bucle de `gh api` y un script de 30 líneas.

⇒ a la lista de premisas verificables se añade una que no parece premisa: **una cifra correcta pero
agregada al nivel equivocado**. La pregunta no es «¿es cierto este número?» sino «¿mide el objeto
que mi decisión va a acotar?». Cuando la decisión cambia la forma del trabajo —aquí, partirlo en dos
corridas—, las mediciones del ticket describen un mundo que ya no existe, y sirven de línea base, no
de respuesta. Y desconfía de un percentil con menos de ~20 puntos: dilo como «máximo observado».
