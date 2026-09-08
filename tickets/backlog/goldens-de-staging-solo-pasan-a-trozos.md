---
id: goldens-de-staging-solo-pasan-a-trozos
status: backlog
priority: medium
area: "backend, testing"
created: 2026-09-08
updated: 2026-09-08
source: medido al aplicar las tres migraciones de staging (2026-09-08)
---

# Los 25 goldens de staging dan 15/25, y la causa NO está encontrada

## El hecho, reproducible

`gateway/test/groups.goldens.test.ts` está anotado en varios sitios como **«25/25 contra staging»**.
Medido el 2026-09-08, **dos corridas completas independientes** dieron lo mismo:

| | Resultado | Duración |
|---|---|---|
| Corrida 1 (suite entera) | 15 passed · **10 failed** | 1715 s |
| Corrida 2 (suite entera, sin nada en paralelo) | 15 passed · **10 failed** | 1706 s |
| `G10` sola (3 tests) | 3 passed | 7,8 s |
| `G2 · 6. merkle` solo (1 test) | 1 passed | 7,8 s |

**Los mismos 10 tests, las dos veces.** Es determinista, no flaky.

**Los 10 fallos son timeouts. Cero aserciones fallidas** — ni una en ninguna corrida. Eso importa:
**no hay ningún fallo de lógica**. Lo que falla es el tiempo.

Los 10: `G2` 2/3/6/7/8 · `G3` 3-bis/3-ter · `G7` roundtrip · `G10` 1/3. Todos hacen push/pull,
merkle o paginación.

## Lo que NO es (descartado con medición, no por descarte lógico)

Se probaron tres hipótesis y **las tres cayeron**. Se dejan escritas para que nadie las repita:

1. **No son las migraciones de ese día** (`g13_04`, `g13_05`, `g14_01`). Fue el primer sospechoso
   porque los fallos caen en `pull` y `merkle`, que es justo lo que tocan. Pero los tres md5 son los
   esperados, `groups_pull_rows_split_groups` llamada a mano por SQL responde al instante, y los
   tests que fallan **pasan en 1,3 s al correrlos solos**, con las migraciones ya aplicadas.
2. **No es contención entre corridas.** La primera vez había 5 procesos `vitest` solapados —error de
   método al comprobar en segundo plano sin esperar—. Se mataron todos y la corrida limpia dio
   **exactamente el mismo resultado**: mismos 10, misma duración.
3. **No es el volumen acumulado en la base.** Los usuarios de prueba arrastran **677 y 511 grupos**
   de meses de corridas, así que parecía la explicación. Pero `explain analyze` sobre el barrido por
   usuario da **0,559 ms** con índice (664 filas). La base no es el cuello.

También descartado: sin locks (`pg_locks` sin esperas), sin transacciones colgadas
(`idle in transaction = 0`), y el gateway corre **en proceso** desde el repo (`app.fetch`), con el
manifest `c2` que ya conoce la columna nueva — no es un Worker desalineado.

## Lo que queda por medir

Si la base responde en menos de un milisegundo y el test tarda 60 s, el coste está en el **número de
round-trips HTTP** o en la latencia de cada uno. La siguiente medición —que no se hizo por tiempo— es
**cronometrar las peticiones individuales** dentro de un test que falla, y contar cuántas hace. Con
677 grupos en el corpus del usuario, un merkle que pida grupo a grupo son cientos de viajes.

**Hipótesis a comprobar, no conclusión:** los tests que fallan son los que barren corpus, y el corpus
creció hasta que el barrido no cabe en el timeout. Si se confirma, hay dos arreglos posibles y son
distintos: limpiar los datos de test acumulados (decisión del owner: es destructivo) o que el barrido
deje de ser lineal en el número de grupos.

## Por qué importa

**Un golden que no da verde no es una red, y uno que dice «25/25» sin serlo es peor: se consulta
creyendo que es cierto.** El número está escrito en varios tickets como evidencia de que staging
está sano.

## Acceptance Criteria

- [ ] Medido dónde se va el tiempo (round-trips y latencia por petición), no supuesto.
- [ ] La suite entera da verde, **o** el número documentado deja de ser «25/25» en todos los sitios
      donde aparece y dice qué pasa de verdad.
- [ ] Si la causa es el corpus acumulado, decisión del owner sobre limpiarlo.
