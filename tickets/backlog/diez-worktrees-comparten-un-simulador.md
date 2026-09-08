---
id: diez-worktrees-comparten-un-simulador
status: backlog
priority: medium
area: qa
created: 2026-09-07
updated: 2026-09-07
source: causa raíz de rojo-xcuitest-runner-muere-tras-el-primer-caso
---

# Diez worktrees comparten un solo simulador, y el gate no se serializa

## El hecho

```
worktrees vivos:                 10
DerivedData de Yala:             13
simuladores booteados:            1   (iPhone 17 Pro 9D0F6D32, iOS 26.5)
```

El paso 3 del `/gate` de **todas** las sesiones apunta al mismo
`-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`. Dos sesiones que lleguen al gate a la
vez corren XCUITest sobre el mismo device y **se derriban entre sí**: comparten bundle id, así que
el runner de la segunda mata al de la primera. Las dos salen exit 65 con casos en `Failing tests`
que nunca imprimieron una línea de fallo. Medido y reproducido 2/2 en
[[rojo-xcuitest-runner-muere-tras-el-primer-caso]].

## Lo que ya se hizo, y por qué no basta

`qa/scripts/sim-libre.sh` **detecta** la colisión y el gate la consulta antes del paso 3. Eso evita
el diagnóstico falso —que era lo caro— pero **no resuelve la contención**: la sesión que llega
segunda tiene que esperar a mano, sin saber cuánto, y nada impide que dos arranquen en el mismo
segundo. Con sesiones autónomas nocturnas, que es justo cuando coinciden, no hay nadie mirando.

## Opciones, para decidir

1. **Un simulador por worktree** — clonar el device y pasar `-destination id=<udid>` propio. Cuesta
   disco (cada clon pesa; el device actual son 9,1 GB) y hay que limpiarlos en `/cerrar`.
2. **Un lock de fichero** — `flock` sobre un lockfile compartido; la segunda sesión espera en vez de
   fallar. Barato y suficiente, pero serializa el gate de todo el equipo.
3. **Dejarlo en la guardia** y aceptar la espera manual.

No lo decide esta sesión: toca cómo trabajan todas las demás.

## Criterio de hecho

- [ ] Elegida una de las tres y escrita como decisión.
- [ ] Si es (1) o (2), implementada y con dos sesiones simultáneas midiéndolo.

## Relacionados

- [[rojo-xcuitest-runner-muere-tras-el-primer-caso]] — la medición que lo destapó
- `.claude/rules/testing.md` — la regla y el criterio de clasificación del rojo
