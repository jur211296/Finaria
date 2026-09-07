---
id: fx-presentation-still-shows-1to1
status: backlog
priority: medium
area: currency
created: 2026-09-03
updated: 2026-09-06
source: residual explícito de fx-partial-rate-rows-silent-1to1 (decisión del owner, 2026-09-03)
---

# Lo que se guarda ya es correcto; lo que se ve en pantalla todavía puede ser un 1:1 silencioso

## Qué le pasa al usuario

Cuando a la fila de tasas de un día le falta una divisa, el monto que la app **guarda** ya se convierte
bien desde `fx-partial-rate-rows-silent-1to1`. Pero las ~34 llamadas que solo PINTAN números siguen
usando `CurrencyConverter.convert`, que ante una divisa ausente devuelve el monto crudo sin decirlo.

Panel, Tendencias, Estadísticas y los saldos de Grupos pueden mostrar un número plausible y falso.

## Por qué está separado, y no es un olvido

**Decisión del owner del 2026-09-03**, con el coste delante: el daño duradero es el disco —lo guardado
viaja por la nube y alimenta informes—, así que ese se arregló primero. Cubrir la presentación exige
tocar el protocolo `CurrencyConverting` (`CurrencyConverter.swift:26-29`), sus tres dobles de test y
los ~28 ficheros que lo inyectan como parámetro por defecto.

**El efecto que hay que tener presente es que la divergencia se INVIRTIÓ.** Antes de aquel fix, la
pantalla se veía bien (leía de la caché en memoria, con el set completo) y el disco se envenenaba.
Ahora el disco está bien y la pantalla es la que puede mentir. No es una regresión —el número en
pantalla no era más correcto antes— pero sí cambia dónde mirar al diagnosticar.

## Punto de partida medido (2026-09-03, HEAD `85ba0077`)

- `CurrencyConverter.convertChecked` ya existe y devuelve `RateQuality`: la información está, solo hay
  que llevarla al protocolo y decidir qué hace la UI con ella.
- `ExchangeRateWidgetHelper` ya resuelve esto de otra forma —omite la divisa en vez de inventar un
  número— y es el precedente de diseño del repo. Su propio defecto está en
  `fx-widget-drops-missing-currency`.
- La decisión de producto que hay que tomar antes de escribir código: **qué ve el usuario** cuando el
  número es aproximado. Hoy `isExchangeRateProvisional` tiene CERO consumidores de UI (medido): se
  escribe, se lee en un `#Predicate` y se emite por nube. Sin superficie visible, la app pasa de
  mentir con seguridad a callarse.

## No confundir con

- `fx-partial-rate-rows-silent-1to1` (en `qa/`) — la persistencia, ya arreglada.
- `distribution-balance-kpi-skips-fx` — qué base de conversión usa cada vista, no si hay tasa.

## Decisión Jürgen (2026-09-06)

**Número con marca de «aproximado».** Elegida entre: (a) mostrar el mejor número disponible con un
indicador discreto (≈ o rotulito) cuando a alguna divisa le falta tasa, (b) omitir la divisa sin tasa
como hace el widget, (c) no decidir hoy. Eligió (a). Motivo, tal como se le puso delante y ratificó:
no oculta información y deja de mentir; la alternativa del widget da un número exacto pero incompleto.

Lo que implica: `CurrencyConverting` expone la calidad de la conversión (`convertChecked` /
`RateQuality` ya existen), los ~28 puntos de inyección la propagan, y las superficies que pintan totales
—Panel, Tendencias, Estadísticas, saldos de Grupos— muestran la marca cuando la calidad no es plena.
`isExchangeRateProvisional` gana por fin un consumidor de UI. Copy del rótulo en 16 `.lproj`. Cómo se
pinta la marca (símbolo vs texto, dónde) es diseño y se resuelve en el `/spec`, no aquí.

## Lo que se midió al implementar (2026-09-06, worktree sobre `6d87123e`)

**La premisa del ticket era falsa por un lado y se quedaba corta por el otro.** Se ejecutaron las dos
rutas contra un store real con la fila del día trayendo USD y PEN pero **no** JPY:

| ruta | resultado | veredicto |
|---|---|---|
| `convertWithLatestRate` | 1000 JPY → **1000 PEN** | el monto CRUDO, ~40× de más |
| `convertWithLatestRate`, sin fila ninguna | 1000 JPY → 24,79 PEN | convierte bien |
| `convert(_:on:)` | 1000 JPY → 24,99 PEN, `quality = .staticFallback` | convierte, pero no lo declaraba |

- **Para la ruta con fecha la premisa ya no valía**: `fx-partial-rate-rows-silent-1to1` destapó los
  tres escalones de `resolveRates`, así que `convert` ya no devolvía el monto crudo. Lo que faltaba
  ahí era exactamente lo que decidió Jürgen: **declararlo**.
- **Para la ruta del TC actual la premisa se quedaba corta**: ahí no era un número aproximado sin
  marcar, era un número mal. Su caché se llena con `needing: []` —no puede saber qué divisas le van a
  pedir— así que una fila parcial de hoy entraba entera y `performConversion` salía por su `guard`.
  Las dos primeras filas de la tabla juntas son el hallazgo: **la fila parcial volvía a ser
  estrictamente peor que no tener fila**, la misma forma exacta del bug ya cerrado, en la otra ruta.
  Y es la ruta que más pinta: saldo vivo del Panel, saldos de Grupos, presupuestos, pagos programados.

**La marca no hubo que diseñarla: ya existe y ya está en producción.** `AmountText.isEstimate`
antepone «≈ » en el run del símbolo (`AmountText.swift:32,191`) y los saldos de Grupos ya la usan
(`GroupBalancesView.swift:123`). Por eso **no hace falta copy nuevo en 16 `.lproj`**: el símbolo es
universal y el AC se cumple reutilizando el precedente en vez de inventar un rótulo paralelo.

**Los saldos de Grupos ya cumplían el AC y no se tocan.** `balancesWereConverted`
(`GroupDetailViewModel.swift:260`) se enciende cuando alguna divisa difiere del destino — exactamente
la condición bajo la que se llama al converter, o sea un superconjunto perfecto de «la tasa fue
inexacta». Marcan de más (también con tasas perfectas), que es una decisión de producto anterior y
más conservadora; revertirla sería quitarle información al usuario y nadie lo pidió.

**Residual conocido, con ticket propio: la marca infra-reporta.** El camino normal de estos totales
no pasa por el converter —suma el `amountInPreferredCurrency` ya guardado—, así que se apoya en el
flag `isExchangeRateProvisional`. Y hay diez escrituras que sellan ese flag en `false` aunque la tasa
fuera aproximada: `fx-manual-writes-seal-approximate-as-final` (high). Hasta que se cierre, la marca
aparece cuando debe pero **puede faltar** en totales cuyas transacciones nacieron mal selladas.

## Criterio de hecho (AC)

- [ ] Con una divisa sin tasa ese día, todo total que la incluya lleva la marca de aproximado; con el
      set de tasas completo, ninguna marca.
- [ ] El número mostrado es el mismo que hoy (mejor disponible); lo que cambia es que se declara.
- [ ] Ningún sitio de presentación queda usando `convert` a ciegas: barrido de las ~34 llamadas con
      control positivo.
- [ ] Cálculo financiero ⇒ **review adversarial** antes del gate.
