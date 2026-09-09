---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` — Merge #115: la familia FX recorrida entera en simulador
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**La familia FX ya no espera montaje: espera red y decisiones.** Los siete tickets recorridos con
el seam de #114 más dos fixtures nuevos — `-uitest-seed-chat-sealed-rate` y
`-uitest-seed-group-bridge-fx`. **5 PASS con evidencia en pantalla**, 2 parciales por causa propia.

Lo que vale de cada veredicto, en una línea: el «≈» aparece con el arg y no sin él, y las tres
diferencias son los importes del fixture al céntimo; la fila envenenada del chat pasa de `TC 1.0000`
a `0.0237` **sin mover el importe**; y el gasto de grupo marca mientras su ingreso no, que es la
prueba de que la magnitud dudosa de la pata suprimida sí llega al numerador.

**Las tres trampas del montaje están ahora en `.claude/rules/testing.md`**, que es donde se cargan
solas: `-uitest-seed` siempre siembra (relanzar sin reset duplica el corpus), `-uitest-reset` no
rebobina un one-shot de arranque, y un fixture tiene que ser **discriminante** y no solo sembrar.
La cuarta es de lectura y vale aquí: **con «Todo el tiempo» el fixture NO marca** (0,36 % < 5 %) —
acota el período o lees un falso negativo, y ese mismo par es el umbral de `approximate-mark-ors`
visto en pantalla.

## Abiertos

1. **La cola física de Jürgen**: push APNs real (4 tickets), RPC de producción (3), sign-in real
   SIWA/Google (6), Apple Pay y carreras de red (4). Nada de eso se simula; lo demás sí.
2. **De FX quedan cuatro cosas, y ninguna es montaje**: el **widget de inicio** (simulable, no cupo
   en la tanda), el **asistente** (pide LLM real), la **red** —aquí `ExchangeRateService` falla por
   AppAttest en todos los arranques— y el seam **`-uitest-preferred-currency`**, que no existe y es
   lo único que le falta a `fx-partial-rate-rows-silent-1to1`.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **El avisador de rojos advisory del CI no puede avisar** (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`,
   **high**): `Invalid API key`. Mientras siga así, un `tests: fail` no distingue «hay tests rotos»
   de «la credencial está mal».
5. **El aviso de cierre cita el PR de OTRA sesión** (`el-aviso-de-cierre-cita-el-pr-de-otra-sesion`,
   **medium**): falla en silencio, con `HTTP 200` y aspecto bueno.
6. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

**Cuatro tickets nuevos, y tres son la misma forma**: una superficie que la tabla de su ticket padre
no nombraba. `live-anchor-breakdown-doubles-the-approximate-glyph` (el «≈» del copy y el de la marca
se suman: la divisa dudosa sale «≈ ≈» y la buena «≈», o sea que se distinguen por *cuántas veces*
aparece el símbolo — en los 16 `.lproj`), `pie-header-total-unmarked` (4.673 sin marca donde otras
tres pantallas lo marcan) y `weekday-bar-daily-average-unmarked` (dos tarjetas «Promedio diario»,
una marcada y otra no). El cuarto es de proceso:
`uitest-seed-reseeds-the-corpus-without-reset`.

`pie-header-total-unmarked` corrige además la premisa con la que `fx-category-totals-unmarked`
justifica su prioridad baja — dice que «el total que agrega estas líneas sí avisa», y no avisa.

Del board anterior siguen abiertos `preferred-currency-has-three-different-defaults`,
`financial-report-amounts-unmarked`, `widget-fallback-summary-uses-ten-rows`,
`bridge-synthesis-trusts-a-zero-converted-amount`, `fx-historical-balance-curve-unmarked` y
`records-summary-mixes-preferred-currencies`.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso; sigue siendo el hueco grande de esta familia),
`el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo` (**high**, toca a todos los agentes —
los **cuatro** commits de esta sesión se verificaron con un grep a mano, y el cuerpo del PR salió
sucio hasta que se editó: el grep del commit no cubre `gh pr create`),
`corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.
