---
id: diez-worktrees-comparten-un-simulador
status: backlog
priority: high
area: qa
created: 2026-09-07
updated: 2026-09-11
source: causa raíz de rojo-xcuitest-runner-muere-tras-el-primer-caso
---

# Diez worktrees comparten un solo simulador, y el gate no se serializa

## El hecho

**Subido a `high` el 2026-09-11: ya cobró su primera factura.** El ticket
`welcome-chooser-uitests-cannot-reach-the-chooser` nació `high` diciendo que siete XCUITest del
Welcome estaban rotos en `2.1`, con su bisección y todo. Los siete **pasan**: en `2.1` de hoy
(11/11), en la revisión exacta que se bisecó (11/11) y en la nocturna de CI sobre los 149 casos.
El rojo era de la máquina, no del árbol — y la sesión que lo midió estaba corriendo su propio
gate a la vez. Coste: un ticket `high` falso en el board y una sesión entera para refutarlo.

```
worktrees vivos:                 14   (2026-09-11; eran 10 el 07-sep)
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

**Y el 2026-09-11 se le añadió el modo `--vigilar <pid>`**, un centinela que muestrea durante toda
la corrida y dice al final si estuviste solo. Tapa el agujero que dejaba la foto instantánea —una
corrida dura entre 3 y 40 minutos y la comprobación caducaba al segundo siguiente— pero sigue
siendo **detección, no prevención**: cuando canta, la corrida ya se perdió y hay que repetirla.

**El síntoma medido resultó ser más ancho de lo que decía este ticket.** No es solo que el runner
de la segunda mate al de la primera: la segunda **instala su `.app` sobre el mismo bundle id**, así
que la primera puede seguir viva tapeando un binario ajeno. Eso da rojos **con** su línea de fallo
y su mensaje de aserto —no el `Restarting after unexpected exit` sin veredicto— y por eso se leen
como bugs del producto. Es el modo de fallo que produjo el `high` falso de arriba.

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
- [[welcome-chooser-uitests-cannot-reach-the-chooser]] — descartado el 11-sep: el `high` falso que
  costó esta contención, y el modo de fallo «la otra corrida instala su app encima»
- `.claude/rules/testing.md` — la regla y el criterio de clasificación del rojo
