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
