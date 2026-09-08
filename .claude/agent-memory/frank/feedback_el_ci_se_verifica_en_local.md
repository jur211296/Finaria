---
name: el-ci-se-verifica-en-local
description: Un cambio al workflow del CI se prueba ANTES de pushear — el script del paso se extrae del YAML y se corre con matriz de escenarios; actionlint con control negativo zanja las dudas de schema
metadata:
  type: feedback
---

**Un cambio a `.github/workflows/` no se verifica esperando al CI: se verifica en local, y sale más
barato.** Tres gestos, los tres medidos el 2026-09-07 en el ticket del timeout del CI.

**Why:** el bucle «pushear y mirar qué pasa» cuesta ~90 min por intento en este repo, y encima
prueba *una* rama del comportamiento — justo la que se dio ese día. La lógica interesante de un
workflow (a quién avisa, cuándo calla) tiene media docena de combinaciones y ninguna se elige a
voluntad desde un push.

**How to apply:**

1. **El `run:` de un paso es bash y se puede ejecutar.** Extráelo del YAML con un parser, no a ojo
   (`ruby -ryaml -e '...steps.find{...}["run"]'`), y córrelo con las variables del paso puestas a
   mano. Así probé los **8 escenarios** del aviso a Grok —PR verde con UI saltada, PR con unit en
   rojo, PR con el build caído, nocturna verde, nocturna con UI roja, nocturna cancelada— en
   segundos. Truco para leer el resultado sin enviar nada: deja `WEBHOOK_URL` vacío; la rama que
   avisa muere con `::error ... Faltan GROK_WEBHOOK_*` y la que calla sale con su `::notice` y
   exit 0. Eso es un discriminador limpio de qué rama tomó.
2. **Un paso que decide (`if:`, outputs) se corre con el entorno del evento.** El job `changes` de
   Yala decide si la suite corre; ejecutarlo con `GITHUB_EVENT_NAME=schedule` y `GITHUB_OUTPUT`
   apuntando a un fichero temporal confirmó en un segundo que un `schedule` cae en su rama
   fail-closed y devuelve `run_tests=true`. Razonarlo habría bastado *casi* siempre, que es el
   problema.
3. **`actionlint` para lo que la documentación no contesta — con control negativo.** La doc de
   GitHub no dice si `timeout-minutes` admite `${{ }}`; actionlint sí, y lo dice en el mensaje de
   error («expecting a single `${{...}}` expression **or float number literal**»). Pero un linter
   que acepta todo no prueba nada: **antes de creerte el verde, dale de comer algo inválido**
   (texto plano, una expresión de tipo string, una clave mal escrita) y comprueba que protesta por
   los tres. `brew install actionlint`; valida expresiones, contextos disponibles y shellcheck del
   `run:`.

**Y lo que NO se puede verificar así, para no venderlo como probado:** que el valor de un
`timeout-minutes` sea el correcto sólo se observa provocando el cuelgue, que cuesta el tope entero.
Ahí el schema y la semántica de `&&`/`||` es lo que hay; dilo como inferido.

**El corolario que casi me muerde:** cuando el cambio ES al CI, el PR es su propia prueba y eso es
un argumento para ir por PR aunque `CLAUDE.md` permita commitear directo a `2.1` un diff que cae
entero en `.github/`. Si commiteas directo, el workflow nuevo corre por primera vez ya mergeado.

Ver [[mis-mediciones-fallan-por-el-filtro]] (el control negativo es la misma familia) y
[[gate-paso3-no-detecta-cero-casos]].

## El comentario que escribí para justificar mi propio diseño era una inferencia falsa

Al poner los topes de paso escribí en el YAML el porqué: «cuando el JOB agota su tope, el runner lo
mata y el paso final de aviso puede no llegar a ejecutarse **ni con `if: always()`**». Sonaba a
mecanismo de plataforma y lo escribí con tono de hecho. Es **falso**: el servidor re-evalúa las
condiciones de los pasos pendientes y los `always()` sí corren, con una ventana de 5 min.

Lo cazó una verificación contra `actions/runner` que había lanzado *en paralelo*, no yo releyendo.
El diseño se sostenía —los topes de paso siguen siendo lo correcto—, pero **por una razón distinta
de la que dejé escrita**: lo que `continue-on-error` rescata es el `Failed` de un timeout de paso, y
no rescata la cancelación de un timeout de job (`ApplyContinueOnError` abre con
`if (Result != TaskResult.Failed) return;`).

⇒ **la justificación que escribo en un comentario es tan verificable como la premisa de un ticket, y
envejece peor: queda ahí como documentación para el siguiente.** Cuando el porqué de una decisión
apoya en «así se comporta la plataforma», eso es una afirmación que hay que medir o marcar como
inferida — sobre todo cuando es *mi* diseño el que se beneficia de que sea cierta, que es cuando
menos ganas tengo de comprobarla.
