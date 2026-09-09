---
id: el-commit-msg-global-no-corre-en-yala
status: backlog
priority: medium
area: "proceso, tooling"
created: 2026-09-09
source: hallazgo de camino al capturar las ideas de Jürgen (2026-09-09)
---

# El hook que prohíbe decir «lo escribió una IA» no corre en Yala, y nada lo sustituye

## Qué pasa

ADR-013 de `casa` dice que ningún commit puede decir que lo escribió una IA, y añade la parte
importante: **«no depende de acordarse: un hook `commit-msg` global lo rechaza»**. En Yala ese hook
no llega a ejecutarse nunca.

## Lo medido (2026-09-09)

```
$ git config --show-origin --get core.hooksPath
file:/Users/jur/Yala/.git/config    .githooks
$ ls ~/.claude/git-hooks/     → commit-msg
$ ls .githooks/               → pre-commit
```

`core.hooksPath` es **un solo valor, no una cadena**: el del repo pisa al global. Yala lo apunta a
`.githooks/` para instalar su gate de pre-commit (`.githooks/pre-commit` →
`qa/scripts/precommit-gate.sh`), y con eso deja fuera todo el directorio global — incluido el
`commit-msg` de ADR-013, que sigue existiendo pero para otros repos.

Efecto en la historia, medido con dos métodos independientes que coinciden: **768 de 3335 commits**
(23 %) llevan `Co-Authored-By: Claude` o `🤖 Generated with` como línea propia del mensaje. El más
antiguo es del 2026-01-13 (`40e7c3ce`) y el más reciente del 2026-09-02 (`f09689b2`).

## Por qué importa

La regla es de las inquebrantables de Jürgen y toca confidencialidad, no estilo. Hoy se cumple sólo
porque el agente se acuerda — que es exactamente lo que ADR-013 quería evitar. El prompt del sistema
de cada sesión, además, **pide activamente** añadir ese trailer, así que la regla depende de que el
agente lo desobedezca cada vez.

## Lo accionable

Los 768 commits son historia: reescribirla rompería todos los SHAs y no es lo que se pide. Lo que
falta es **que no se sumen más**.

- [ ] Un `commit-msg` en `.githooks/` que rechace esas líneas (el global sirve de fuente; enlazarlo
      o copiarlo son las dos salidas, con la contrapartida obvia: una copia diverge).
- [ ] Comprobado con control negativo: un mensaje con el trailer se rechaza, uno sin él pasa.
- [ ] Decidir si el gate de pre-commit y este comparten instalación, para que instalar uno no vuelva
      a desactivar al otro sin avisar.

## Notas

Este ticket sale de camino al capturar las cinco ideas del 2026-09-09; no formaba parte del encargo.
No se implementa aquí: toca `.githooks/`, que va por PR y no por commit directo.
