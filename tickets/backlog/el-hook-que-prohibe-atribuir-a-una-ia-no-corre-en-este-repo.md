---
id: el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo
status: backlog
priority: high
area: "proceso"
created: 2026-09-08
source: medido el 2026-09-05; escalado a ticket el 2026-09-08 al colarse un commit real
---

# El candado que prohíbe atribuir un commit a una IA no está puesto en Yala

## Qué pasa

ADR-013 dice que la regla «ningún commit dice que lo escribió una IA» **no depende de acordarse**,
porque hay un hook `commit-msg` global que la impone. En este repo ese hook **no corre**, y la única
razón de que el historial esté limpio desde el 2026-09-02 es que las sesiones se han acordado.

El 2026-09-08 una sesión commiteó con `Co-Authored-By: … <noreply@anthropic.com>` y el hook no dijo
nada. Se detectó al comparar el mensaje con los commits vecinos —ninguno de los últimos lo lleva— y
se corrigió con `--amend` antes de subir nada, así que no hay daño en el historial: el último commit
con atribución sigue siendo `f09689b2`, del 2026-09-02. Pero la detección dependió de mirar, y eso
no se puede prometer.

## La cronología importa, y no deja bien al método

**Esto se midió el 2026-09-05** y quedó anotado — en la memoria del agente, que es un sitio que solo
lee él. El 2026-09-08 la misma sesión que tenía la nota delante commiteó igualmente con el trailer:
la instrucción por defecto de la herramienta pide ponerlo, y en el instante de redactar el mensaje
ganó ella. Se corrigió con `--amend` antes de subir nada.

O sea que el fallo tiene **dos capas**, y la segunda es la que crea este ticket: el candado no está
puesto, y saberlo no bastó. Una nota que solo evita el error cuando alguien se acuerda de leerla es
justo lo que ADR-013 dice que no quiere. Por eso pasa de nota privada a ticket del repo.

## Por qué no corre (medido el 2026-09-05, re-comprobado el 2026-09-08 en este árbol)

`core.hooksPath` no es acumulativo: **el valor local gana y sustituye al global**, no se fusionan.

```
core.hooksPath (global) = /Users/jur/.claude/git-hooks   →  commit-msg          (ADR-013)
core.hooksPath (local)  = .githooks                      →  pre-commit          (el sello del gate)
```

Yala pone `core.hooksPath` local para su `pre-commit` —el que corre `qa/scripts/precommit-gate.sh`,
añadido el 2026-08-30 en `3fb52618`— y con eso deja fuera **todo** el directorio global, incluido el
`commit-msg` del 2026-09-04. Los dos hooks son correctos por separado; lo que falla es que no pueden
convivir así.

Es probable que afecte a **cualquier repo con `core.hooksPath` local**, no solo a éste. Sin
comprobar en los demás.

## El volumen histórico, medido el 2026-09-09

El ticket dice arriba que «el historial está limpio desde el 2026-09-02», y es cierto en el sentido
que importa —no se han sumado más—. Pero el acumulado de antes no se había contado, y conviene
tenerlo delante al elegir camino: **768 de 3335 commits (23 %)** llevan `Co-Authored-By: Claude` o
`🤖 Generated with` como línea propia del mensaje. El más antiguo es del 2026-01-13 (`40e7c3ce`).

Medido con dos métodos independientes que coinciden. **No cambia el arreglo** —reescribir la
historia rompería todos los SHAs y no se plantea—, pero sí el tamaño de lo que ya viaja en cualquier
clon, que es el argumento de confidencialidad de abajo.

## Por qué importa

No es cosmético: engancha con la regla de confidencialidad del `CLAUDE.md` global —«no se revela el
uso de IA al cliente ni al equipo, **tampoco en el historial de git**»—. Un trailer es permanente,
viaja con el repo y sale en cualquier clon. Y Yala es el repo donde más se commitea.

## Caminos, con su coste

1. **`.githooks/commit-msg` como shim de una línea** que delega en el global
   (`exec bash ~/.claude/git-hooks/commit-msg "$@"`). No duplica la lógica, y si el global cambia el
   repo hereda el cambio. Contra: fija una ruta absoluta del Mac dentro del repo.
2. **Copiar el hook global a `.githooks/`.** Simple hoy, dos copias que divergen en tres meses.
3. **Quitar el `core.hooksPath` local** y llevar el `pre-commit` del gate al directorio global, con
   un guard que compruebe que el repo es Yala. Contra: mete algo de Yala en la config de la casa.
4. **Dejarlo y documentarlo.** Es lo que hay hoy sin saberlo; al menos pasaría a estar escrito.

Elegir es de Jürgen: ADR-013 es suyo y el arreglo toca infraestructura común a todos los agentes.

## Criterio de hecho (AC)

- [ ] Decidido el camino.
- [ ] Un commit de prueba con el trailer se rechaza en este repo (control positivo: uno sin él pasa).
- [ ] Comprobado si hay otros repos con `core.hooksPath` local en la misma situación.
