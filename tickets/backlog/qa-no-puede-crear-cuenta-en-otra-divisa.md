---
id: qa-no-puede-crear-cuenta-en-otra-divisa
status: backlog
priority: high
area: "testing, currency, qa"
created: 2026-09-08
source: barrido de QA en simulador del 2026-09-08 (bloqueo medido)
---

# Sin poder elegir divisa desde la automatización, cuatro tickets de FX no se pueden cerrar

## Qué pasa

Toda la familia FX pendiente necesita el mismo estado de partida: **una cuenta en una divisa que no
esté en la fila de tasas del día** (las filas sembradas traen solo `PEN`, `EUR` y `USD` —
`DevSeedExchangeRates.swift:56-60` — así que cualquier otra sirve: JPY, CLP…).

El camino de usuario es Perfil → Cuentas → Añadir → **Moneda**. Medido el 2026-09-08: ese selector
es un `NavigationLink` (`AccountFormView.swift:250-253`) y **no responde a los taps sintéticos de
la automatización de QA**. Se intentó cuatro veces (tap, tap tras cerrar teclado, `touch` down/up
con retardo, y `wait_for_ui` a `settled`) y la pila de navegación no cambia.

**No es un bug de la app**, y conviene dejarlo escrito para que nadie lo persiga por ahí: en la
misma pantalla el campo de texto del nombre **sí** acepta escritura, y los botones normales
(«Añadir», «Cuentas») **sí** responden. El control cruzado lo confirma: el otro `NavigationLink`
del mismo formulario («Tipo») tampoco abre, así que el fallo va con el patrón, no con la moneda.

## Qué bloquea, concretamente

Cuatro tickets que hoy siguen en `qa/` y que **no** necesitan un teléfono, solo este estado:

- `fx-manual-writes-seal-approximate-as-final` (high)
- `fx-partial-rate-rows-silent-1to1` (high)
- `fx-presentation-still-shows-1to1`
- `approximate-mark-ors-over-whole-period`

Los cuatro se verifican mirando si el importe convertido lleva «≈» y si la tasa guardada no es 1,0.
El control negativo ya está medido y disponible: con el corpus PEN+USD el hero del Panel **no**
lleva «≈» (visto el 2026-09-08), así que la marca que apareciera al añadir la divisa ausente sería
señal de verdad y no una aserción que no puede fallar.

## Salidas posibles (elegir una)

1. **Un launch arg** tipo `-uitest-seed-foreign-account <ISO>` que siembre una cuenta en esa divisa
   con saldo. Es lo más barato y lo que deja los cuatro tickets cerrables en una tarde.
2. **Un perfil de seed** `multi-divisa-parcial` que ya traiga la cuenta y un par de movimientos con
   fecha dentro del histórico sembrado.
3. **Cambiar la divisa preferida por arg** (`-uitest-preferred-currency <ISO>`): ejercita además
   `CurrencyChangeService`, que el ticket `fx-manual-writes` señala como «el peor de los diez
   sitios» porque reescribe el histórico entero.

La 1 y la 3 son complementarias y cubren lados distintos del problema.

## Cómo se sabe que está bien

Desde un solo launch, sin tocar la UI de creación de cuentas, se puede llegar a un estado donde
existe una transacción en una divisa ausente de la fila del día, y comprobar en su detalle que la
tasa guardada **no** es 1,0000 y que el importe convertido aparece marcado como aproximado.
