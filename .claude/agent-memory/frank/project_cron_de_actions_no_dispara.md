---
name: cron-de-actions-no-dispara
description: El `schedule` de GitHub Actions no sirve ventanas en Yala (medido 8-sep, con control positivo). La cobertura diaria de UI la sostiene `nocturna-vigilante.yml` por su disparador de push; el hueco de los días sin commits espera una decisión de Jürgen.
metadata:
  type: project
---

**El `cron` de GitHub Actions no dispara en `jur211296/Yala`** — medido el 2026-09-08, y la
cobertura de UI ya no depende de que lo haga.

**Why:** al mudar la suite de UI a una nocturna (`cron: '17 8 * * *'`), su primera ventana no
disparó con casi 8 h de margen, y un canario `*/5` montado para contestar en minutos en vez de en
días dio **siete ventanas y cero runs**. Cero `event: schedule` en todo el repositorio, nunca. El
coste real fue que la app pasó de 24-31 corridas de UI al día a **cero automáticas**, sin que nada
lo dijera: cuando un `schedule` no dispara no hay run, no hay rojo y no hay aviso.

**How to apply:**

- **Esta hipótesis CADUCA y la comprobación cuesta un comando.** Antes de apoyarte en ella:
  ```
  gh api 'repos/jur211296/Yala/actions/runs?event=schedule&per_page=100' --jq .total_count
  ```
  Deja de ser cero ⇒ el reloj volvió, y el `schedule` de `nocturna-vigilante.yml` empieza a servir
  solo, sin tocar nada. Re-comprobada por última vez: **2026-09-08, 10:42 UTC**.
- **No propongas mover nada a un `schedule` en este repo** sin comprobar antes esa cifra. Y si lo
  haces, deja algo que avise cuando la corrida falte — es un modo de fallo silencioso.
- **Lo que sostiene hoy la cobertura es el disparador de `push`** de `nocturna-vigilante.yml`, no
  su `schedule`. Su punto ciego está medido: 8 de los últimos 30 días sin commits en `2.1`, con
  rachas de hasta 3.

**Lo que espera a Jürgen:** el ticket `cobertura-ui-diaria-cuelga-del-push` (medium, backlog) — tres
salidas escritas: un `launchd` en la Mini que haga `gh workflow run qa.yml` (es acceso suyo),
aceptar que la cobertura vaya atada al ritmo de trabajo, o esperar a que el `schedule` vuelva. No
corre prisa y no bloquea nada.

**Dos cosas que no hay que volver a hacer,** las dos ya cometidas aquí:

1. **Leer un `workflow_dispatch` en verde como prueba de que el reloj funciona.** Corre el mismo
   contenido, así que no distingue nada. La nocturna se dio por verificada así una vez.
2. **Preguntar «¿corrió el workflow?» sin filtrar por evento.** Responde que sí todos los días: 59
   runs de QA en 26 h y solo 1 con la UI dentro.

La forma de medirlo, con sus dos trampas de API, está en `docs/aprendizajes-tecnicos.md`
(«Una corrida programada que no ocurre no deja rastro»).

Relacionado: [[mis-mediciones-fallan-por-el-filtro]] (caso 15: el canario necesitaba control
positivo), [[el-ci-se-verifica-en-local]].
