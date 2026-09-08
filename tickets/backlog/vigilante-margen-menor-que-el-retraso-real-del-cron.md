---
id: vigilante-margen-menor-que-el-retraso-real-del-cron
status: backlog
priority: medium
area: ci
created: 2026-09-08
updated: 2026-09-08
source: medido al preparar la decisión de `cobertura-ui-diaria-cuelga-del-push` (2026-09-08)
---

# El vigilante comprobará la nocturna antes de que la nocturna nazca

## Qué pasa

`nocturna-vigilante.yml` avisa si la nocturna de `qa.yml` no corrió. Comprueba a las **11:43 UTC**,
y su propio comentario (`:33-41`) explica el número: 3 h 26 min después de la ventana de las 08:17,
«margen de sobra para el retraso con el que GitHub sirve los `schedule` bajo carga».

**Ese margen se quedó corto el primer día que el cron disparó de verdad.** Medido el 2026-09-08:

| | |
|---|---|
| cron declarado de la nocturna (`qa.yml:37`) | `17 8 * * *` → 08:17 UTC |
| nacimiento real del run (`id=34228530861`) | **12:52 UTC** |
| retraso real | **4 h 35 min** |
| margen del vigilante | 3 h 26 min |
| **⇒ el vigilante habría mirado** | **1 h 09 min ANTES de que la nocturna naciera** |

Habría reportado «la nocturna no corrió» sobre una nocturna que corrió. Un rojo falso en el único
canal que vigila que la cobertura de UI sigue viva — y el peor sitio donde tener uno, porque el
canal que cría lobos se acaba ignorando.

## Por qué no ha explotado todavía

Porque **el vigilante nunca ha disparado por `schedule`**: 0 runs, medido con
`gh api '…/nocturna-vigilante.yml/runs?event=schedule'`. Hoy vive del `push`, que ocurre cuando
ocurre y por eso nunca ha caído en la ventana mala. El fallo está armado, no detonado: se detona el
día que su cron despierte — que es justo lo que empezó a pasar hoy con el de `qa.yml`.

## Por qué subir el margen no es la respuesta

Porque el retraso de GitHub no tiene tope publicado. 4 h 35 min es lo que midió **un** día; elegir
5 h, o 6, es volver a apostar contra un número desconocido, y cada hora que se le suma es una hora
más que tarda el aviso en llegar cuando el fallo es real.

La forma que no depende del retraso es **preguntar por una ventana, no por un instante**: ¿ha nacido
algún run de `qa.yml` en las últimas 24 h? Eso es cierto tanto si nació puntual como si nació con
cinco horas de retraso, y sigue siendo falso el día que de verdad no corrió.

## Acceptance Criteria

- [ ] El vigilante deja de depender de que la nocturna haya nacido antes de una hora fija.
- [ ] Un run nacido con 5 h de retraso **no** produce aviso.
- [ ] Un día sin ningún run **sí** lo produce (control positivo — se comprueba forzando la ventana
      con el input `horas`, que para eso existe: `nocturna-vigilante.yml:44-47`).
- [ ] Verificado con una corrida real, no solo leyendo el YAML.

## Relacionados

- [[cobertura-ui-diaria-cuelga-del-push]] — la decisión donde salió esto. Se arregla **pase lo que
  pase** con esa decisión: si el cron sirve, este falso rojo aparece; si no sirve, el vigilante sigue
  colgando del push.
- [[la-nocturna-de-ui-no-ha-disparado-ni-una-vez]] — el abuelo, que midió que el `schedule` no servía.
