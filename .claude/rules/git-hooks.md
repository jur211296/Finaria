---
description: Los hooks de git de Yala — por qué el repo tiene su propio commit-msg, qué bloquea y qué no, y la trampa de core.hooksPath. Se cargan al tocar .githooks/ o los scripts del gate.
paths:
  - ".githooks/**"
  - "qa/scripts/commit-msg-test.sh"
  - "qa/scripts/precommit-gate.sh"
  - "qa/scripts/worktree-stamp*.sh"
---

# Hooks de git en Yala

## `core.hooksPath` NO es acumulativo: el local SUSTITUYE al global

Es la trampa que costó este ticket. Yala pone `core.hooksPath = .githooks` en su config
local para el `pre-commit` del gate, y con eso **el directorio global entero queda fuera**
— no se fusionan, gana el local y punto.

```
global : /Users/jur/.claude/git-hooks   →  commit-msg   (ADR-013, anti-atribución)
local  : .githooks                      →  pre-commit   (el sello del gate)
        ⇒ efectivo: .githooks. El commit-msg global NO CORRE AQUÍ.
```

Se comprueba en un comando, y conviene hacerlo antes de dar por puesto cualquier hook:

```bash
git config --show-origin --show-scope --get-all core.hooksPath
```

Consecuencia medida el 2026-09-09: **Yala es el único repo del Mac con `core.hooksPath`
local**, así que es el único donde el candado global no llegaba. Los otros 24 lo heredan.
Si algún día otro repo pone el suyo, hereda también este problema.

## El candado anti-atribución vive aquí, y es propio

`.githooks/commit-msg` rechaza los commits que dicen que los escribió una IA. **No es una
copia del global**: es más ancho en atribución y más estrecho en mención.

| | Global (ADR-013) | Yala |
|---|---|---|
| Trailer `Co-Authored-By:` con Claude | rechaza | rechaza |
| Trailer cuyo NOMBRE es Claude (`Claude-Session:`) | **pasa** | rechaza |
| URL `claude.ai/code/session_…` suelta | **pasa** | rechaza |
| `🤖 Generated with…` | rechaza | rechaza |
| Nombrar `CLAUDE.md` o `.claude/rules/…` | **rechaza** | pasa |

Las dos diferencias son deliberadas y están medidas sobre los 3348 commits del repo:

- **Más ancho**: el trailer `Claude-Session:` no es un `co-authored-by` y `claude.ai` no
  casa con el patrón `claude.com/claude-code` del global, así que el nivel 1 global no lo
  ve. Ya se coló **7 veces**, la última el 2026-09-02.
- **Más estrecho**: el global prohíbe la mención a secas fuera de `casa`, `~/.claude` y
  `tim`. Aplicarlo aquí rechazaría **216 commits legítimos** que citan rutas del propio
  árbol. Decisión de Jürgen (2026-09-09): en Yala el sistema de Claude también es objeto
  de trabajo, así que se permite nombrarlo. Lo que no pasa es la **firma**.

## Si tocas los patrones, el banco tiene que seguir en verde

```bash
bash qa/scripts/commit-msg-test.sh      # 17 casos + divergencia con el global
```

Lo corre el CI en cada push (job `coverage-index`). Sus casos 11-17 son los que impiden
"arreglar" un fallo endureciendo a lo bruto: un `grep -qi claude` los tumba, y con ellos
el derecho a citar `CLAUDE.md` en un mensaje.

La segunda mitad compara con el hook global **sobre los mensajes reales del repo**, no
sobre los 17 casos: en esos Yala ya rechaza por su cuenta, así que compararlos no puede
dar señal. Y el corpus se elige por contenido, no por recencia — los últimos 400 commits
de este repo tienen **cero** atribución (el más reciente con trailer está en la posición
408), así que un corpus «los últimos N» sale verde sin medir nada.

En el CI esa comparación no corre: allí no hay `~/.claude`. Se dice en la salida.

## La trampa que queda abierta: el hook vive en el árbol de trabajo

`core.hooksPath` apunta a un directorio del **working tree**, así que un worktree cuya
rama no traiga `.githooks/commit-msg` **no tiene candado** — medido, no supuesto. Al
abrir un worktree desde una rama vieja, o rebasa sobre `2.1`, o comprueba:

```bash
test -x .githooks/commit-msg && echo "candado puesto" || echo "SIN CANDADO"
```

## El otro hook: `pre-commit`

Corre `qa/scripts/precommit-gate.sh`, que comprueba el sello de `/gate`. Sale 0 sin
mirar nada si no hay ficheros `.swift` en staging: un cambio de solo docs no necesita
gate. Su banco es `qa/scripts/worktree-stamp-test.sh`, y a ése **no lo corre nadie**
automáticamente.
