---
id: bridge-de-grupos-pierde-la-marca-de-sus-patas
status: backlog
priority: medium
area: "groups, currency, fx"
created: 2026-09-08
updated: 2026-09-08
source: review adversarial de approximate-mark-ors-over-whole-period (2026-09-08)
---

# Un gasto de grupo puede salir «exacto» aunque el 90 % de su cálculo venga de una tasa dudosa

## Qué pasa

`GroupBridgeStatsAdjustment` (`:143-146`) sintetiza el importe que ven las estadísticas como
`preferred = pata real + Σ patas de préstamo`. Las patas de préstamo están **suprimidas** del
recorrido, así que su `isExchangeRateProvisional` **no lo lee nadie**.

Caso concreto: pata real de −1.000 con tasa exacta, pata de préstamo de +900 con tasa provisional.
El importe ajustado son −100, y se contabiliza como **100 % exacto** — cuando el 90 % de la
aritmética que lo produjo salió de una tasa dudosa.

## Por qué importa MÁS desde el 2026-09-08

**Es preexistente**: con el OR anterior la ceguera era la misma. Lo que cambia es la consecuencia.
Antes la marca era booleana y cualquier otra transacción aproximada del período la encendía igual.
Ahora el importe entra en un **cociente** (`ApproximateMarkThreshold`), así que una atribución mal
hecha no solo se pierde: **desplaza el umbral** y puede apagar la marca de todo el bucket.

## Qué habría que hacer

Que la síntesis del bridge propague la marca de **todas** las patas que contribuyen al importe, no
solo de la que sobrevive al filtro. La forma natural es que `amountInPreferredCurrency(_:)` tenga un
hermano que devuelva también «alguna de las patas sumadas era provisional», y que los calculadores
usen ese en vez de `tx.isExchangeRateProvisional` cuando hay `adjustment`.

## Acceptance Criteria

- [ ] Un gasto de grupo con la pata real exacta y una pata de préstamo provisional cuenta como
      aproximado en el numerador del umbral.
- [ ] Test con `adjustment` distinto de `.none` — hoy **no hay ninguno** en
      `ApproximateAmountMarkTests`.
- [ ] No cambia el importe mostrado, solo su marca.

## Relacionados

- [[approximate-mark-ors-over-whole-period]] — el cambio que convirtió esta ceguera en un peso.
