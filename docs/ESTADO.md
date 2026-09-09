---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` · HEAD `34c7737a` — Merge #111: la marca de «≈» en las superficies secundarias
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**El segundo medium de la cola** (PR #111). El «≈» de importe aproximado ya no vive solo en los
cuatro totales grandes: llega a la hoja «¿Cuánto tienes hoy?» —la peor omisión, porque esa hoja
existe justo para explicar que el saldo es multimoneda—, al flujo de caja, a Registros, al promedio
diario, al KPI de Distribución, a los widgets de inicio y al asistente. Donde un número no puede
llevarla, queda escrito por qué **con su ticket**. Detalle en el ticket y en el PR.

**Cuatro cosas que cambian cómo se trabaja esta familia, y por eso están aquí:**

1. **La tabla de un ticket nombra un sitio por pantalla, no todos.** Las 7 superficies eran **21**,
   más 2 pantallas que la tabla no nombra —las dos en ficheros que el ticket anterior ya había
   tocado—. En `HeroMonthView` el MISMO `periodSummary.expense` se pintaba dos veces en la misma
   vista y solo una llevaba marca.
2. **Un campo Codable nuevo y NO opcional en el snapshot del App Group apaga TODOS los widgets**
   sobre el payload ya escrito, hasta que el usuario abra la app. Los DTO están duplicados en dos
   targets y los dos decodifican. Lo cazó `WidgetSessionSealTests`, escrito para el sello de sesión.
3. **`YalaTests` no compila `YalaWidgets`.** Cuando el source-scan es la única red posible, grepear
   dos literales no basta: hay que fijar el cuerpo entero normalizado. La primera versión de la
   «paridad» del umbral replicado no comparaba nada del código del widget.
4. **El denominador de una proporción es el número que se MUESTRA.** Si es una resta (un saldo, un
   neto), usar la suma de magnitudes que lo formó apaga la marca justo en quien más historial tiene.

## Abiertos

1. **La cola física de Jürgen**, agrupada por lo que de verdad la bloquea: push APNs real (4
   tickets), RPC de producción (3), sign-in real SIWA/Google (6), Apple Pay y carreras de red (4).
   Nada de eso se simula; lo demás sí.
2. **51 tickets en `qa/`**, buena parte simulables. **Cinco** de FX están bloqueados por
   `qa-no-puede-crear-cuenta-en-otra-divisa` (**high**) — el de esta sesión es el quinto: el selector
   de moneda no responde a la automatización y con un launch arg que siembre una cuenta en divisa
   ausente se cierran los cinco de golpe. Es la palanca con mejor relación coste/desbloqueo del board.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **El avisador de rojos advisory del CI no puede avisar** (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`,
   **high**): `Invalid API key`. Mientras siga así, un `tests: fail` no distingue «hay tests rotos»
   de «la credencial está mal».
5. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

`bridge-de-grupos-pierde-la-marca-de-sus-patas`, que cierra la familia de la marca. De los ocho
tickets que deja esta sesión, los dos `medium` son `fx-historical-balance-curve-unmarked` (el saldo
de un mes cerrado no puede marcar en ninguna pantalla) y `records-summary-mixes-preferred-currencies`
(el resumen de Registros suma divisas preferidas distintas).

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso; sigue siendo el hueco grande de esta familia), `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo`
(**high**, toca a todos los agentes — re-comprobado el 9-sep en el worktree: `.githooks/` solo trae
`pre-commit` y nada mira el trailer; el commit de esta sesión se verificó con un grep a mano, antes
y después), `corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.
