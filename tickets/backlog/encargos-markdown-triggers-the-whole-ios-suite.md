---
id: encargos-markdown-triggers-the-whole-ios-suite
status: backlog
priority: medium
area: "ci, proceso"
created: 2026-09-10
source: "medido el 2026-09-10 en el PR #126: el job `changes` dijo «CORRE — toca encargos/lanzados/…» sobre un diff sin una sola línea de Swift"
---

# Un fichero de encargo en markdown dispara la suite entera de iOS, y eso pasa en TODA sesión lanzada

## Qué pasa

`lanzar-sesion` deja el encargo en `encargos/lanzados/<slug>.md` y esa carpeta **está trackeada**: cada
sesión lanzada la commitea. Pero `encargos/` no figura en la lista de rutas que el job `changes` de
`.github/workflows/qa.yml` considera «sin código», así que un diff de **solo markdown** clasifica como
«hay que compilar» y arranca `tests` en `macos-26`.

Medido el 2026-09-10 en el PR #126 (documentación pura: `docs/`, `tickets/`, `encargos/`):

```
changes: - CORRE — toca encargos/lanzados/2026-09-09-desbloqueo-preguntas-redisenio-sesiones.md
tests:   pending (0s) · runs-on: macos-26 · el propio workflow se da «hasta 90 min»
```

## Por qué importa

- **Es sistemático, no un caso raro:** toda sesión lanzada commitea su encargo, así que todo PR de una
  sesión lanzada arrastra la suite entera aunque no toque una línea de Swift.
- **Contradice una intención ya escrita en el propio workflow.** El job `aviso` excluye `skipped`
  razonando que «si `changes` decidió que el diff es solo docs, no hay suite de la que informar y un
  aviso ahí sería ruido en cada PR de documentación». La intención está; a la lista se le escapó
  `encargos/`.
- El workflow **no declara `concurrency`**, así que dos pushes seguidos dejan dos runs de 90 min
  compitiendo por el runner de macOS. En el PR #126 hubo que cancelar uno a mano.

## Lo que hay que hacer

- [ ] Añadir `encargos/` a la clasificación de «sin código» del job `changes`.
- [ ] Comprobar si falta alguna ruta más por el mismo motivo: comparar la lista del job `changes` con la
      de «Dónde se commitea» de `CLAUDE.md`, que ya diverge en dos sitios **a propósito** (`.claude/` y
      `.github/`). `encargos/` no está en ninguna de las dos y ése es el olvido.
- [ ] Valorar si el workflow debe declarar `concurrency` con `cancel-in-progress` para la misma rama.
      Ojo antes de tocarlo: el job `aviso` usa `!cancelled()` **precisamente porque hoy no hay
      concurrencia** y las cancelaciones son manuales; su docblock lo explica y hay que releerlo.

## Cómo se verifica

Un PR que toque **solo** `encargos/` tiene que salir con `tests` en `skipped`. Y como tocar
`.github/` sí dispara la suite a propósito, el PR que arregle esto la disparará: eso es correcto.
