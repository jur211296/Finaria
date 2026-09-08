---
id: dos-criterios-de-aproximado-en-la-misma-pantalla
status: backlog
priority: medium
area: "currency, fx, ui"
created: 2026-09-08
updated: 2026-09-08
source: review adversarial de approximate-mark-ors-over-whole-period (2026-09-08)
---

# El «≈» significa dos cosas distintas en el mismo Panel

## Qué le pasa al usuario

Tiene una sola divisa extranjera con la tasa del día sin refrescar. En la **misma pantalla** del
Panel ve:

- **«Tienes X en N cuentas»** (el panorama) **con «≈»** — su marca sale de
  `LiveBalanceCalculator:138`, que sigue siendo un OR: basta una divisa con tasa no exacta.
- **«Disponible» del período, sin «≈»** — desde el 2026-09-08 usa el umbral del 5 %, y los
  movimientos de esa misma divisa no llegan a pesar.

No son el mismo número y las dos marcas son correctas por separado. Lo que se rompe es el
**glifo**: el usuario no tiene forma de saber que «≈» aquí quiere decir «alguna tasa es dudosa» y
allí «una parte que pesa es dudosa». Lo mismo pasa con `FXPnLCard:88`, que usa el OR de
`FXPnLLogic:112`.

## Por qué se dejó así, y por qué aun así es un ticket

**No es un olvido: es la decisión de Jürgen del 2026-09-08.** `LiveBalanceCalculator` conserva su OR
porque **su unidad ya es la divisa, no la transacción** — itera `nativeBalances`, que viene agrupado
—, y una divisa entera sin tasa sí es una ausencia que merece la marca. El razonamiento se sostiene
para ese número.

Lo que la decisión no resolvió —porque no se planteó— es la **coherencia visible entre números
vecinos**. Salió de la review adversarial del cambio, no de un fallo funcional.

## Salidas posibles (decisión de producto, no cerrada)

- **(a) Dejarlo.** Los dos criterios son defendibles cada uno en su número. Coste cero.
- **(b) Llevar el umbral también al panorama**, midiendo el peso del saldo de las divisas sin tasa
  exacta sobre el saldo total. Coherencia completa, y hay que comprobar que no apaga la marca en el
  caso que hoy sí importa: una divisa pequeña con tasa muy vieja.
- **(c) Distinguirlos en la presentación** — dos glifos, o un pie que explique. Es el más caro en
  diseño y el que más ruido añade.

## Acceptance Criteria

- [ ] Decisión escrita.
- [ ] Si se unifica, un test que fije que el panorama y el hero coinciden en el caso de una sola
      divisa extranjera con tasa stale.

## Relacionados

- [[approximate-mark-ors-over-whole-period]] — la decisión que introdujo el segundo criterio.
