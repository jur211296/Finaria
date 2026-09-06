---
id: el-job-de-tests-del-ci-no-tiene-timeout
status: backlog
priority: medium
area: ci
created: 2026-09-06
updated: 2026-09-06
source: medido esperando el CI del PR #78
---

# El job `tests` del CI puede ocupar un runner seis horas sin que nadie se entere

## Qué se midió

Esperando los checks del PR #78 (2026-09-06): el job `tests` llevaba **más de 60 minutos** con el
paso de UI tests en `in_progress`. No estaba colgado —los tres pasos anteriores (build, unit
pure-logic, unit context-based) habían pasado—, pero al buscar cuándo cortaría salió esto:

**`grep -n "timeout-minutes" .github/workflows/qa.yml` no devuelve nada.** Ni en el job ni a nivel de
workflow. Sin `timeout-minutes`, GitHub Actions aplica su default de **360 minutos**.

## Por qué importa

El paso que tarda es:

```yaml
- name: UI tests (YalaUITests) — advisory (flaky en runner frío, ver Lista Negra)
  continue-on-error: true
  run: |
    xcodebuild test-without-building -scheme "Yala Dev" \
      -only-testing:YalaUITests -parallel-testing-enabled NO -retry-tests-on-failure
```

La suite entera (~110 tests), **sin paralelismo** y **con reintentos**. Que tarde una hora larga es
esperable. El problema no es la lentitud: es que **un cuelgue real es indistinguible de esto** y
nadie se entera hasta las seis horas.

Y hay un segundo efecto, más silencioso: los tres pasos de test son `continue-on-error: true` a
propósito, así que el job **acaba en verde pase lo que pase**. O sea que el único coste visible de un
cuelgue es tiempo de runner y un PR que parece "pendiente" durante horas — justo el estado en el que
alguien acaba mergeando sin esperar, porque el check nunca cierra.

## Qué hacer

Dos cosas, y la segunda importa más que la primera:

1. Poner `timeout-minutes` al job (y quizá al paso de UI). Un valor por encima del percentil alto
   real, no a ojo: hay que medir cuánto tarda normalmente antes de elegirlo.
2. **Decidir si ese paso debe correr en cada PR.** La duración ya está medida (abajo): el CI no da
   señal dentro de una sesión de trabajo, así que la pregunta real es si la suite completa de UI
   pertenece al PR o a una corrida nocturna.

## Duración medida (2026-09-06)

`gh run list --workflow qa.yml --limit 12`, quedándome con los runs que sí dispararon el job:

| Run | Minutos |
|---|---|
| 4 runs completos consecutivos | **77, 80, 82, 83** |
| El más lento de la muestra | **90** |

Los runs de 0 minutos son los que no disparan `tests` (diffs de solo documentación).

**~80 minutos de media.** Eso es más que cualquier sesión de trabajo razonable esperando un PR, y
explica el patrón que hay que evitar: el check no cierra, el PR parece pendiente, y se acaba
mergeando sin él. Un `timeout-minutes` alrededor de 120 dejaría margen sobre el percentil alto sin
permitir que un cuelgue ocupe seis horas.

## Distinto de

- `ci-no-corre-la-suite-del-gateway` — otro hueco de cobertura del CI.
- `ci-warns-but-does-not-block` — va del `continue-on-error`, que aquí es intencional; esto va del
  tiempo sin límite.

## Acceptance Criteria

- [ ] El job `tests` tiene `timeout-minutes` explícito, elegido a partir de duraciones medidas.
- [x] Queda escrito cuánto tarda hoy la suite en CI (~80 min, muestra de 4 runs) — hecho el
      2026-09-06 al abrir este ticket.
- [ ] Decidido si la suite completa de UI corre en cada PR o pasa a nocturno.
