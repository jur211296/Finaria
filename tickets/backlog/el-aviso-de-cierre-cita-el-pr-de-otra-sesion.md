---
id: el-aviso-de-cierre-cita-el-pr-de-otra-sesion
status: backlog
priority: medium
area: infra
created: 2026-09-09
source: medido al cerrar fx-approximate-mark-missing-on-secondary-surfaces (2026-09-09)
---

# El aviso de cierre cita el PR de otra sesión, y `--rama` no lo arregla

## Qué pasa

El aviso de «la sesión ha llegado a su fin» que llega al móvil lleva arriba y en negrita el PR de la
sesión, y **puede ser el de otra**. En el cierre del 2026-09-09 el aviso citó **PR #109** —de una
sesión anterior— cuando los de esa sesión eran **#111 y #112**.

Para quien lo lee desde el móvil, el aviso es correcto en todo lo demás: el resumen es el suyo. Solo
el puntero al trabajo está mal, que es justo lo único que no se puede reconstruir después.

## Medido el 2026-09-09

El hook indexa por `repo + rama` en `~/.claude/cache/avisos-grok/ultimas/`, y la anotación de la
sesión estaba **bien**:

| puntero | sesión | PRs anotados |
|---|---|---|
| `Yala__encargo-2026-09-09-fx-approximate-…` | `3cce8309…` | **#111, #112** ✅ |
| `Yala__2.1` | `84afc49e…` | #109 |

El aviso salió del árbol principal —donde la rama es `2.1`— **con `--rama` puesto y apuntando a la
del encargo**, y aun así resolvió por `Yala__2.1`. `--dry-run` da `#109` con `--rama` y sin él: el
resultado no cambia, así que el flag no llega a la resolución del puntero.

`~/.claude/skills/cerrar-total/SKILL.md` §9 documenta `--rama` como **obligatorio** por este motivo
exacto («sin `--rama` la clave no coincide y el PR no viaja»). La documentación describe la
intención; el comportamiento medido es otro.

## Por qué es `medium` y no `low`

Afecta a **todas** las sesiones lanzadas que cierran con `/cerrar-total`, que es el flujo normal, y
falla en silencio: el envío responde `HTTP 200` y la línea del PR sale con aspecto correcto. Solo se
ve comparando el número con el PR real. El canal existe para las sesiones que Jürgen no ve trabajar;
un puntero equivocado ahí manda a leer el trabajo de otro.

## Qué hay que mirar

- Si `--rama` se usa para componer el aviso pero no para **resolver la sesión** en `ultimas/`.
- Si la normalización del nombre difiere entre quien escribe el puntero (`encargo/x` → `encargo-x`)
  y quien lo lee con el flag.
- El respaldo por «sesión más reciente del repo» es el que acaba ganando; conviene que **avise**
  cuando cae en él, en vez de servir un PR ajeno con la misma cara que el bueno.

## Criterio de hecho (AC)

- [ ] `--avisar cierre-resumen --rama <rama>` resuelve el puntero de ESA rama, y hay un caso que lo
      fija contra dos sesiones del mismo repo.
- [ ] Cuando el puntero no resuelve, el aviso lo dice en vez de caer al de otra sesión en silencio.
- [ ] El §9 de `cerrar-total` describe lo que hace, no lo que se quiso que hiciera.

## Nota de la sesión que lo encontró

El aviso del 2026-09-09 02:41 (`ENVIADO destino=frank motivo=cierre-resumen HTTP 200`) es el que
lleva el `#109` equivocado. **No se mandó un segundo aviso corregido a propósito**: ADR-021 protege
ese canal y un duplicado por una línea vale menos que el ruido que mete. Los PR buenos son #111 y
#112.
