---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` · HEAD `817c27ee` — Merge #113: el gasto de grupo lleva la incertidumbre de sus patas
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**El tercer medium de la cola cierra la familia de la marca** (PR #113). Un gasto compartido que
adelantas y te devuelven en parte ya no se presenta como exacto cuando no lo es: la app calcula «mi
parte» restando lo prestado de lo pagado y solo miraba la calidad de la tasa de la primera mitad —
la otra está oculta del recorrido a propósito, y con ella se iba su señal.

**Lo que hay que recordar de aquí, y es una regla, no una anécdota:**

1. **El numerador de la proporción son MAGNITUDES; el denominador, el número que se muestra.** Es el
   gemelo exacto del aprendizaje de ayer, por el otro lado del cociente. Mi primera versión metía el
   neto en el numerador y la review lo tumbó con dos escenarios medidos: con mi parte pequeña
   (1.000 de 10.000, 9.000 prestados dudosos) se queda en 3,8 % y **no marca** un mes con un tercio
   de aritmética dudosa; con mi parte grande (9.700 de 10.000, 300 dudosos) da 94 % y **marca el mes
   entero por 300** — en el límite, dos céntimos. El contrato ya lo decía, escrito con esta misma
   pareja de números.
2. **`.serialized` no ordena entre suites hermanas del mismo archivo.** `makeTestContext` reusa el
   container por `#fileID` y vacía el store en cada llamada, así que la segunda suite de un archivo
   que pida contexto va en archivo propio. El síntoma: **verde a solas, cero acompañado**.
3. **Una cifra de un documento no se reusa sin re-medirla.** Este NOW decía «cinco de FX bloqueados»
   y yo escribí «el sexto» en el ticket y el PR antes de contar. Medido: **tres** se declaran no
   simulables por esa causa y **dos** más piden el mismo montaje declarándose simulables.

## Abiertos

1. **La cola física de Jürgen**, agrupada por lo que de verdad la bloquea: push APNs real (4
   tickets), RPC de producción (3), sign-in real SIWA/Google (6), Apple Pay y carreras de red (4).
   Nada de eso se simula; lo demás sí.
2. **52 tickets en `qa/`**, buena parte simulables. `qa-no-puede-crear-cuenta-en-otra-divisa`
   (**high**) sigue siendo la palanca con mejor relación coste/desbloqueo: **cinco** tickets esperan
   ese montaje y **tres** están parados por él. Un launch arg que siembre una cuenta en divisa
   ausente los libera de golpe.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **El avisador de rojos advisory del CI no puede avisar** (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`,
   **high**): `Invalid API key`. Mientras siga así, un `tests: fail` no distingue «hay tests rotos»
   de «la credencial está mal».
5. **El aviso de cierre cita el PR de OTRA sesión** (`el-aviso-de-cierre-cita-el-pr-de-otra-sesion`,
   **medium**): falla en silencio, con `HTTP 200` y aspecto bueno. Afecta a toda sesión lanzada que
   cierra sola, así que el número se comprueba a mano en cada cierre.
6. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

La familia de la marca queda cerrada en código. Lo que dejó esta sesión, por tamaño:
`financial-report-amounts-unmarked` (la pantalla de Informes pinta 22 importes y ninguno puede llevar
la marca — es justo donde se va a buscar el detalle del número marcado),
`widget-fallback-summary-uses-ten-rows` y `bridge-synthesis-trusts-a-zero-converted-amount`. Del
board anterior siguen abiertos los dos `medium` de FX: `fx-historical-balance-curve-unmarked` y
`records-summary-mixes-preferred-currencies`.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso; sigue siendo el hueco grande de esta familia), `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo`
(**high**, toca a todos los agentes — los **cuatro** commits de esta sesión se verificaron con un
grep a mano, uno a uno), `corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.
