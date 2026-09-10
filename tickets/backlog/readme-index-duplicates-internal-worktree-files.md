---
id: readme-index-duplicates-internal-worktree-files
status: backlog
priority: low
area: "docs"
created: 2026-09-09
source: visto al reindexar en el cierre del candado anti-atribución
---

# El índice del README duplica cada fichero grande

## Qué pasa

`scripts/indice_readme.py` escanea el árbol entero, y dentro hay un worktree interno
(`.claude/worktrees/elastic-ritchie-9f2188/`) con una copia del repo. Resultado: la lista
de «ficheros de más de 60 KB» sale con cada entrada **dos veces**, una real y otra dentro
de ese worktree.

```
✓ docs/DECISIONS.md (246 KB) · ✓ .claude/worktrees/elastic-ritchie-9f2188/docs/DECISIONS.md (243 KB) · …
```

Son 6 ficheros reales y 12 filas, y las copias además traen **tamaños desfasados** (243 KB
frente a 246), porque el worktree se quedó en un commit anterior. Un lector que siga esa
ruta llega a una copia vieja.

## Qué haría falta

Excluir del escaneo `.claude/worktrees/` y cualquier otro worktree anidado —lo mismo vale
para `scripts/frescura.py` y `glosario.py` si comparten el recorrido, conviene mirarlo—.

## Criterio de hecho (AC)

- [ ] El índice del README lista cada fichero una sola vez.
- [ ] Comprobado que ningún otro generador arrastra el mismo doble conteo.
