---
name: decisiones-que-esperan-a-jurgen
description: Dos tandas de decisiones contestadas (2026-09-02 y 2026-09-06) y el método que funcionó; quedan sin preguntar las dos de Grupos del ESTADO
metadata:
  type: project
---

**Las decisiones que bloqueaban `tickets/in-progress/` desde el 6 y el 12–13 de agosto están
contestadas: Jürgen las respondió todas la noche del 2026-09-02.** Lo que decidió vive en cada
ticket, que es su sitio; aquí sólo queda por qué se destrabaron y qué funcionó.

**Why:** llevaban tres semanas quietas porque nadie se las había puesto delante como decisiones.
Un ticket que espera una respuesta y uno que espera trabajo se ven idénticos en el tablero.

**How to apply — lo que funcionó y conviene repetir:**

- **Se destrabaron todas en una sentada** porque fueron con opciones concretas, consecuencia
  escrita por opción, y una recomendación marcada. No en abstracto y no de una en una.
- **Agrúpalas por lo que comparten, no por ticket.** Dos tickets distintos pedían lo mismo al
  servidor (romper el no-oráculo de `join_group`); presentados juntos, fue una sola respuesta.
- **La recomendación no es un trámite: se apartó de ella en 3 de 8.** Pidió arreglar los ocho
  rojos ANTES de tocar tickets, eligió la opción cara en el móvil prestado, y mandó commitear
  un fichero que yo proponía dejar quieto. Márcala igual —le ahorra tiempo— pero no des por
  hecho que la toma.
- **Verifica el bloqueo antes de citarlo.** Al medirlo, tres de los ocho «bloqueados» no
  esperaban decisión ninguna, una de las cinco ni siquiera estaba en `in-progress`, y faltaba
  una que nadie había listado (la custodia del consent legacy, RGPD). El `ESTADO.md` decía
  «cinco decisiones bloquean 8 tickets»; eran cuatro y bloqueaban cinco.

**Segunda tanda, 2026-09-06 (PR #79):** seis decisiones en dos preguntas agrupadas (4 + 2 extra),
mismo formato —opción, coste, recomendada primero— y **tomó la recomendada en las seis**. No es
señal de que la recomendación sea un trámite (el 2-sep se apartó en 3 de 8): es que las seis
tenían una salida barata y coherente con algo que él ya había decidido antes (el 26-ago, el 2-sep,
el 3-sep). **Cuando la opción recomendada se apoya en una decisión SUYA anterior, la toma sin
pensarlo; cítala.** Un ticket de dos decisiones dentro (kill-switch) se parte en dos preguntas.

**Y una tercera tanda el mismo día, que enseña lo importante:** tras las seis, Jürgen preguntó
«¿estamos seguros de que ya ninguna necesita decisión mía?». Mi «sí» habría salido del encargo
(acotado a 3+2) y de un grep de «decisión». **Leer los 94 tickets vivos enteros destapó 13 más** —seis
de ellas frenaban bugs— repartidas en `backlog/` Y en `qa/` (tickets ya implementados que dejaban un
residual «decisión aparte» sin ticket propio). Las contestó todas (13/13 la recomendada). ⇒ **«¿queda
alguna?» se responde leyendo, con lectores en paralelo y control positivo de las citas; y el
residual de un ticket de `qa/` que dice «decisión aparte» es una decisión huérfana: sácala a ticket.**
Quedan como abiertas del ESTADO solo las dos de la web (legal de Grupos, Vercel `1.0`/`2.1`).

Relacionado: [[el-tablero-antes-que-el-bug]] · [[jurgen-levanta-sus-reglas]]
