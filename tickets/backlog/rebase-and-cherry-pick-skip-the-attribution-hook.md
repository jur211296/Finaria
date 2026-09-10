---
id: rebase-and-cherry-pick-skip-the-attribution-hook
status: backlog
priority: medium
area: "proceso"
created: 2026-09-09
source: lente adversarial al cerrar el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo
---

# El candado no corre en rebase, cherry-pick ni revert

## Qué pasa

`.githooks/commit-msg` bloquea la atribución al crear un commit, pero **git no lo ejecuta
en todas las operaciones que crean commits**. Medido en laboratorio (git 2.50.1):

| Operación | ¿corre el hook? |
|---|---|
| `git commit`, `--amend`, `--fixup`, `--squash` | **sí** |
| `git merge`, `git merge --squash` + commit | **sí** |
| `git cherry-pick` | **no** |
| `git revert` | **no** |
| `git rebase`, `git rebase --continue` | **no** |
| Botones «Merge / Squash / Rebase» de GitHub | **no** (el commit se crea en servidor) |

Así que un commit con trailer, con el emoji en el asunto o con
`--author="Claude <…>"` entra intacto por cualquiera de esas vías. Y los merges de la web
no pasan por ningún hook local: de los 168 merges del historial, **9 llevan atribución en
el mensaje**.

## Por qué no se cerró en la misma sesión

No se puede desde `commit-msg`: git simplemente no lo invoca. Cerrarlo pide otra
superficie, y elegir cuál es una decisión.

## Caminos

1. **`pre-push`**: escanear los mensajes y los autores de los commits que se van a subir
   (`git rev-list @{u}..HEAD`) y abortar si alguno lleva atribución. Cubre rebase,
   cherry-pick y revert de una vez, y es el último punto local antes de que salga del Mac.
   Contra: el `pre-push` de casa se retiró en ADR-009 por falsos positivos; conviene no
   repetir esa historia.
2. **Un check de CI** que haga lo mismo sobre los commits del PR. Cubre además los merges
   hechos desde la web, que ningún hook local puede ver. Contra: avisa tarde, cuando ya
   está subido — aunque a tiempo de rehacer la rama.
3. **Nada**: el riesgo real es bajo mientras los commits que se rebasan salgan ya limpios
   del `commit-msg`.

## Criterio de hecho (AC)

- [ ] Decidido el camino.
- [ ] Si es 1 o 2: un `cherry-pick` de un commit con trailer se detiene o se marca, y uno
      limpio pasa (control positivo y negativo).

## Nota de flujo, medida de camino

Si el hook tumba un `git merge`, git deja el árbol a medias: `MERGE_HEAD` y `MERGE_MSG`
puestos, el índice con los ficheros staged y `HEAD` sin mover. Hay que volver a commitear
o `git merge --abort` a mano. Y un `--fixup`/`--squash` cuyo commit destino tenga el
disparador en el ASUNTO es incorregible —git copia ese asunto y no te deja editarlo—, así
que la única salida sería `--no-verify`. Hoy es latente: ninguno de los 3348 asuntos del
historial dispara.
