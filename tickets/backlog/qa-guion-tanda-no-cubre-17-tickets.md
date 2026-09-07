---
id: qa-guion-tanda-no-cubre-17-tickets
status: backlog
priority: low
area: qa
created: 2026-09-06
updated: 2026-09-06
source: hallazgo al añadir groups-archived-group-rejects-join al guion (2026-09-06)
---

# El guion de la tanda de QA deja fuera a 17 tickets sin decirlo

## Qué pasa

`qa/guion-tanda.md` agrupa por **montaje** los tickets que esperan comprobación en aparato real, y su
valor es justo ése: montar dos teléfonos una vez en lugar de siete. Pero solo nombra a una parte.

Medido el 2026-09-06: **`tickets/qa/` tiene 39 tickets y el guion nombra 22.** Los otros 17 no
aparecen en ningún grupo, así que quien haga la tanda siguiendo el guion —que es para lo que existe—
los deja fuera **sin que nada avise**. Un ticket sin montaje asignado no se ve distinto de uno ya
verificado.

## Por qué se descuelga

El propio guion lleva la instrucción («al mover algo a `qa/` o sacarlo de ahí, actualiza también este
guion»), y es una instrucción que depende de que alguien se acuerde. Su cabecera decía «2026-09-03 ·
20 tickets» mientras `qa/` había crecido a 39: no es que se ignorara una vez, es que el recordatorio
no basta cuando varias sesiones mueven tickets a `qa/` el mismo día.

## Qué haría falta

1. Repartir los 17 en los grupos existentes (A dos teléfonos · B móvil prestado · C simulador
   bienvenida · D simulador con datos), o crear el montaje que les falte.
2. Y valorar si esto lo sostiene un **comprobador** en vez de la memoria: un script que compare
   `ls tickets/qa/*.md` contra los ids nombrados en el guion y falle si alguno no está. Sería el mismo
   patrón que ya usa `qa/validate-coverage.sh` con el índice de cobertura, y convertiría «acuérdate»
   en «no se puede olvidar».

La opción 2 es la que quita el problema de raíz; la 1 hay que hacerla igualmente una vez.

## No es urgente

`low` a propósito: no rompe nada en la app y el trabajo pendiente sigue registrado en sus tickets.
Lo que cuesta es que la tanda de QA parezca completa cuando no lo es.
