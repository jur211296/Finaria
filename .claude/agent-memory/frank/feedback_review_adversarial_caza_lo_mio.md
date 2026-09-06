---
name: review-adversarial-caza-lo-mio
description: La review adversarial no es para auditar código ajeno: en el ticket del invitado (2026-09-05) cazó cuatro defectos que introducía MI cambio, incluido el propio defecto del ticket colado por la puerta de atrás. Cómo montarla para que sirva.
metadata:
  type: feedback
---

**La review adversarial se corre sobre lo que acabo de escribir yo, y esperando que encuentre algo.** No
es un trámite de calidad sobre código heredado.

**Why:** en `groups-invite-skips-unirme-sheet-if-onboarded` (2026-09-05) tenía el fix implementado, 127
tests verdes y la mutación hecha. Dos lentes independientes encontraron **cuatro defectos que introducía
ese mismo cambio**, y el peor era el defecto del propio ticket colado por la puerta de atrás: confirmar
UNA invitación sellaba TODAS las demás, porque el CTA llamaba a `reconcile` sin decir de qué grupo
hablaba. Mi test de esa propiedad estaba **verde** — probaba el store llamando a la función a mano, no el
camino real. Además refutaron una afirmación que yo había escrito en tres sitios como si la hubiera
medido, y que era falsa.

**How to apply:**

- **Las dos lentes coincidieron, sin verse, en los dos hallazgos gordos.** Esa coincidencia es la señal
  de que un hallazgo es real; lo que solo dice una lente merece que yo lo mida antes de creerlo. Y de
  hecho **medí la refutación yo mismo antes de corregir** — la lente también puede equivocarse.
- **Dales una lente distinta a cada una, no «revisa esto».** Lo que funcionó: una sobre la máquina de
  estados (¿bucles?, ¿caminos donde no aparece?, ¿qué pasa si mata la app aquí?) y otra sobre regresiones
  y daño colateral en preferencias (¿qué escribe?, ¿a qué dominio?, ¿viaja cross-device?).
- **Pídeles que refuten su propio hallazgo antes de reportarlo, y que digan si sobrevivió.** Las dos
  descartaron cosas por su cuenta y marcaron una con «confianza media», que resultó ser real y estrecha.
- **Y el corolario que más duele:** un test verde escrito por mí sobre una propiedad que yo mismo definí
  puede estar montando el estado a mano y saltarse justo al caller que lo rompe. Cuando el test llama
  directamente a la función que quiero proteger, **no está probando el camino**.

Relacionado: [[mutante-compilado-zanja-hipotesis]] (la mutación prueba que el test vale; la review prueba
que el test mira donde hay que mirar — no se sustituyen) · [[mis-mediciones-fallan-por-el-filtro]].

**Refuerzo medido el 2026-09-06** (`groups-leave-rpc-error-10`, tres lentes: SwiftData/concurrencia,
producto/UX, y la mía de patrón). Cazó **seis** defectos míos, y dos hacían el fix **peor que el bug**:
(1) el reconciliador de ownership se convertía en una cárcel — tras el primer rechazo, el guard local
cortaba todo intento futuro antes de la red y ningún pull reabre `isOwner`; (2) un `save()` fallido
dejaba el flag vivo EN MEMORIA, con la UI ya ofreciendo una acción irreversible sobre un dato que no
estaba en disco. Los otros cuatro: copy circular que mandaba a la pantalla en la que ya estabas, un
comentario que prometía una reanudación que no ocurre, un docblock cierto para la función y falso como
efecto, y un doc-comment que mi propia inserción se había comido.

Dos cosas que aprendí del formato: **la lente refuta además de acusar** —me confirmó que NO debía usar
`saveUnderOutboxAuthor` (habría marcado con autor de eco ediciones ajenas pendientes, que el drain
descarta) y que el `incrementDataVersion` no ciclaba—, y eso vale tanto como los hallazgos. Y **una
lente de PRODUCTO encuentra lo que las técnicas no ven**: el callejón del dueño con deuda ajena y el
copy que apuntaba a una pantalla inalcanzable no los vio ninguna lente de código.
