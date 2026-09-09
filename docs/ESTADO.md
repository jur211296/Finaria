---
updated: 2026-09-09
tags: [now, punto-de-retomada]
---

# NOW — 2026-09-09 (Lima)

**Rama** `2.1` · HEAD `7773d79d` — Merge #114: la familia FX ya tiene estado de partida en simulador
TestFlight build **12** (CPV 12). **Subida Yala (TF/store) = solo Mini.**

## Esta sesión

**La palanca del board, tirada** (PR #114). `-uitest-seed-foreign-account <ISO>` siembra una cuenta
en una divisa **fuera de la fila de tasas del día** desde un solo launch — el estado de partida que
esperaba toda la familia FX y al que no se llegaba ni por UI (el selector de Moneda es un
`NavigationLink` y no responde a los taps sintéticos) ni por seed (el corpus era multi-divisa, pero
nunca producía una divisa fuera de la fila).

**Lo que hay que recordar, y es regla, no anécdota:**

1. **El corpus del seed hace vacua cualquier aserción sobre `isExchangeRateProvisional`.**
   `DevSeedTransactions` escribe `exchangeRate` a mano y deja el flag en su default `false`. Un
   fixture que quiera probar la marca tiene que pasar por `recalculatePreferredCurrency`, o solo
   prueba que sé escribir constantes. Es lo único que separa este seam de los otros.
2. **El peso de la marca es una PROPORCIÓN, así que los importes se derivan de la divisa
   preferida, no se escriben en la nativa.** Con importes nativos fijos el mismo comando pesa ~285
   soles en yenes y ~45 en pesos chilenos: marcaría en una divisa y no en la otra.
3. **Repetí un error que tenía escrito en mi propia memoria**, con el mismo fichero y la misma
   regex: contrasté el índice de tickets con `[a-z0-9-]+`, no vio una fila con mayúsculas y **la
   dupliqué**. Y la re-verificación tampoco lo cazó, porque metía las filas en un `dict` — que
   colapsa duplicados. Cuando lo que puede fallar es «hay de más», se cuentan filas, no claves.

## Abiertos

1. **La cola física de Jürgen**: push APNs real (4 tickets), RPC de producción (3), sign-in real
   SIWA/Google (6), Apple Pay y carreras de red (4). Nada de eso se simula; lo demás sí.
2. **Los siete de FX ya no esperan montaje.** Dos salen enteros
   (`fx-approximate-mark-missing-on-secondary-surfaces`, `fx-presentation-still-shows-1to1`) y **ya
   tienen sesión lanzada**. Dos necesitan **más seed, no teléfono** —
   `bridge-de-grupos-pierde-la-marca-de-sus-patas` (dos patas con coberturas distintas) y
   `chat-rows-sealed-before-the-fix-have-no-repair-path` (una fila envenenada con
   `exchangeRate = 1.0`) —: son los siguientes candidatos baratos. Tres siguen fuera del simulador
   por causa propia: dos piden **red** y uno el **LLM real**.
3. **Tres veredictos de QA escritos en sus propios tickets están caducos**:
   `scheduled-payments-notif-dedup` y `welcome-start-fresh-wipes-before-ask` pedían un seam que **ya
   existe**, y el callout de `siri-intent-dual-container` lo refuta su ticket hermano.
4. **El avisador de rojos advisory del CI no puede avisar** (`ci-avisador-de-rojos-advisory-tiene-la-clave-mal`,
   **high**): `Invalid API key`. Mientras siga así, un `tests: fail` no distingue «hay tests rotos»
   de «la credencial está mal».
5. **El aviso de cierre cita el PR de OTRA sesión** (`el-aviso-de-cierre-cita-el-pr-de-otra-sesion`,
   **medium**): falla en silencio, con `HTTP 200` y aspecto bueno. Comprobado a mano en este cierre.
6. **DMARC el 15-sep** · **cobertura de UI el 22-sep**. Esperan al calendario, no a nadie.

## Siguiente

Nuevo de esta sesión: **`preferred-currency-has-three-different-defaults`** — cuatro sitios leen
`defaultCurrencyCode` y, si la key falta (la borra «Empiezo de cero»), se responden **tres defaults
distintos**: la región, `"PEN"` y `"USD"`. La línea del widget lleva encima el comentario «single
source of truth». Aquí no se ve porque el simulador es `es_PE` y coinciden por casualidad del
entorno — que es justo lo que lo hace invisible en esta Mac y visible fuera.

Del board anterior siguen abiertos `financial-report-amounts-unmarked`,
`widget-fallback-summary-uses-ten-rows`, `bridge-synthesis-trusts-a-zero-converted-amount`,
`fx-historical-balance-curve-unmarked` y `records-summary-mixes-preferred-currencies`.

## Bloqueo

**Las mismas cuatro decisiones tuyas**: `changing-an-account-currency-orphans-its-whole-history`
(**high** — editar la divisa de una cuenta deja su histórico entero en la vieja, en masa y sin
aviso; sigue siendo el hueco grande de esta familia), `el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo`
(**high**, toca a todos los agentes — los **tres** commits de esta sesión se verificaron con un
grep a mano, uno a uno), `corpus-de-test-de-staging-crece-sin-limite` y el filtro de naturaleza.
