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
4. **No es el manifest desincronizado**, y ésta parecía la buena. `gateway/group_capability_manifest.json`
   está en `.gitignore` (es copia generada por `sync:manifest`) y llevaba **desde el 3-sep en `c1`**,
   porque el sync solo corre desde `npm test` / `npm run deploy:*` y las corridas se lanzaron con
   `npx vitest`, que no dispara `pretest`. O sea: el gateway probaba con 11 columnas contra una base
   que desde hoy devuelve 12 — la divergencia falsa de Merkle que el bump a `c2` existe para evitar,
   y encajaba con que fallara justo pull/merkle/paginación. Se sincronizó a `c2` y se volvió a correr:
   **14 passed · 11 failed**, ligeramente PEOR y con la misma duración. No era eso.

También descartado: sin locks (`pg_locks` sin esperas), sin transacciones colgadas
(`idle in transaction = 0`), y el gateway corre **en proceso** desde el repo (`app.fetch`), con el
manifest `c2` que ya conoce la columna nueva — no es un Worker desalineado.

## El único hecho robusto, medido tres veces

| Corrida | Manifest | Resultado | Duración |
|---|---|---|---|
| 1 (con otras corridas solapadas) | c1 | 15 · 10 fallos | 1715 s |
| 2 (limpia, nada en paralelo) | c1 | 15 · 10 fallos | 1706 s |
| 3 (limpia, manifest sincronizado) | **c2** | 14 · 11 fallos | 1736 s |

**~69 segundos por test de media en tanda; 1-8 segundos por test al correrlos solos.** Un factor
~70x que no depende del manifest, ni del solapamiento, ni de los datos de la base. Ese es el hecho
que hay que explicar, y ninguna de las cuatro hipótesis lo hace.

## Lo medido al final, y por dónde seguir (2026-09-08, última hora)

**La latencia por petición NO es el problema y NO degrada.** 20 peticiones seguidas al REST de
staging desde esta Mac, cronometradas:

```
436 276 130 170 185 137 132 124 174 139 164 176 120 129 132 128 165 167 120 123   (ms)
```

Estable en **~130 ms** tras el arranque en frío, sin crecer. Eso mata el rate-limiting acumulativo
como explicación.

**Y la aritmética que queda apunta a un sitio concreto.** Si una petición son 130 ms y hay tests que
tardan 20-55 s **pasando** (no solo los que dan timeout), esos tests hacen **150-400 peticiones**. La
pregunta ya no es «por qué va lento» sino **«por qué hace tantos viajes»**.

**El sospechoso número uno es el corpus del usuario de prueba.** `G2 · 7. paginación` hace:

```ts
const baseline = (await pull(jwtA, {}, 1000)).cursors;   // pull COMPLETO del usuario
...
for (; iterations < 15; iterations++) { const p = await pull(jwtA, cursors, 1); }  // limit=1
```

Y `jwtA` tiene **677 grupos** acumulados de meses de corridas (`jwtB`, 511). Un pull que recorra el
corpus a razón de una petición por página es O(corpus), y el corpus solo crece: **cada corrida de los
goldens añade ~15 grupos más y nadie los limpia**. Eso explicaría por qué el 7-sep daba 25/25 y hoy
no, sin que nadie tocara el código.

**La siguiente medición, concreta:** instrumentar `pull()` en el test para contar peticiones y
cronometrarlas, y correr **un** test que falla. Si el número de viajes escala con los 677 grupos,
está encontrado — y entonces hay dos arreglos distintos: limpiar el corpus de test (destructivo,
decisión del owner) o que el baseline deje de traerse el corpus entero.

**Aviso para quien lo retome:** los tests se lanzan con `npx vitest`, que **no dispara `pretest`** y
por tanto **no sincroniza el manifest**. Si vas a comparar corridas, corre `npm run sync:manifest`
antes o usa `npm test`, o estarás midiendo con un manifest viejo sin saberlo (a mí me costó una
hipótesis entera).

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
