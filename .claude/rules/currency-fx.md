---
description: Conversión de divisas — los tres escalones de tasas, la caché del TC actual y la marca de aproximado. Se carga al tocar el converter, las tasas o los calculadores que agregan importes.
paths:
  - "Yala/Services/CurrencyConverter.swift"
  - "Yala/Services/ExchangeRateService.swift"
  - "Yala/Services/CurrencyChangeService.swift"
  - "Yala/Utils/CurrencyUtils.swift"
  - "Yala/Utils/CurrencyFormattingHelper.swift"
  - "Yala/App/Logic/ExchangeRate*.swift"
  - "Yala/App/Logic/Calculators/CashFlowCalculator.swift"
  - "Yala/App/Logic/Calculators/HeroBucketsCalculator.swift"
  - "Yala/App/Logic/Calculators/LiveBalanceCalculator.swift"
---
# Divisas · tasas · la marca de aproximado

## La forma del bug que se repite en este módulo

**Una fuente peor que TAPA una mejor, y presenta el resultado como bueno.** Ha aparecido tres veces
con la misma silueta y distinta puerta, así que conviene reconocerla antes que memorizar sus casos:

1. `fx-partial-rate-rows-silent-1to1` (2026-09-03) — la fila de tasas del día existía pero no traía
   la divisa pedida; el converter cortaba por EXISTENCIA de fila y devolvía el monto **crudo**.
   La tasa estaba disponible dos escalones más abajo: **la fila parcial era estrictamente peor que
   no tener fila.**
2. `fx-presentation-still-shows-1to1` (2026-09-06) — lo mismo en la ruta del **TC actual**, que
   aquel fix no tocó: su caché se sembraba con `needing: []` ⇒ una fila parcial entraba entera y
   `performConversion` salía por su `guard`. Medido: **1000 JPY → 1000 PEN**.
3. El mismo día, al arreglar (2) — sembrar la caché con la tabla estática ENTERA cuando no hay fila
   de hoy hacía **vacua** la comprobación de cobertura (la tabla cubre todas las divisas), y el
   escalón de la fila real anterior no se alcanzaba nunca. Medido: `convertWithLatestRate` daba
   24,79 mientras `convert(_:on:)` daba **40** con la fila de ayer, en el mismo instante.

⇒ **Al tocar la resolución de tasas, la pregunta no es «¿devuelve un número?» sino «¿hay una fuente
mejor que este camino se está saltando?»**. Y la comprobación que lo zanja son **las dos rutas sobre
los mismos datos**: si `convert(_:on:)` y `convertWithLatestRate` no coinciden, una está eligiendo
peor (pinneado en `CurrencyConverterLatestRateQualityTests.bothRoutesAgree`).

## La caché del TC actual

- Se siembra **solo con la fila de hoy**, nunca completada con escalones inferiores: no sabe qué
  divisas le van a pedir después, y rellenar «por si acaso» es lo que mató el carry-forward.
- Guarda **el origen POR DIVISA** (`CachedRates.origins`), no una calidad del conjunto. La calidad de
  una conversión es la **peor de sus dos divisas** (`RateQuality.worse`): decir `.exact` porque una
  de ellas lo era es la verdad a medias que este enum existe para impedir.
- Lo que falta se resuelve **nombrándolo** (`needing: [from, to]`) y se **funde** en la caché. Sin la
  fusión, un día sin fila de tasas paga dos fetches y hasta 30 decodes JSON **por importe
  convertido**, y hay llamadores que convierten dentro de un bucle anidado (pagos × ocurrencias).
- La fusión se **descarta** si la caché fue invalidada mientras se resolvía: escribir ahí resucitaría
  la entrada previa al refresco y la dejaría viva hasta medianoche.
- **Todo escritor de tasas tiene que postear `.yalaExchangeRatesUpdated`.** `forceRefreshRates` no lo
  hacía y dejaba al converter sirviendo lo que sembró antes —y declarándolo aproximado— con la fila
  buena ya en disco.

## Una tasa inservible es una tasa AUSENTE

Un `0` guardado (o negativo, o no finito) pasaba la comprobación de presencia, nunca contaba como
faltante, y `performConversion` acababa devolviendo el monto **crudo** con calidad `.exact` — el bug
de arriba por otra puerta. En el destino era peor: devolvía **0**, que parece un dato real.

⇒ las tres preguntas —cobertura de la caché, `missing()` del escalonado y el guard de la conversión—
tienen que ser **la misma**: `CurrencyConverter.isUsableRate`. Al añadir un camino que lea tasas,
fíltralo por ahí o los escalones no podrán rescatar la divisa.

## La marca de aproximado en un total

**El importe agregado casi nunca pasa por el converter.** Cuando la divisa de destino es la preferida
—el caso normal— se suma el `amountInPreferredCurrency` que ya está en disco, convertido el día que
se creó la transacción. Así que «este total es aproximado» se sabe por dos vías y **hacen falta las
dos**:

| rama | fuente de la señal |
|---|---|
| importe guardado | `tx.isExchangeRateProvisional` |
| conversión en vivo | la `RateQuality` que devuelve `convertChecked…` |

- **La señal va separada por lado (ingreso / gasto)**, no una sola por período: el hero de Tendencias
  pinta uno de tres números según la métrica y el del Panel en modo Solo Gastos pinta solo el gasto.
  Con una señal común, un gasto mal convertido le ponía «≈» al total de INGRESOS.
- **La marca es del número que se pinta.** Antes de pasar un `isEstimate:`, comprueba qué agrega ese
  número concreto: marcar de más erosiona la marca igual que no ponerla.
- **El glifo es `≈` y no lleva copy nuevo**: lo antepone `CurrencyFormattingHelper` y lo conduce
  `AmountText.isEstimate`, que ya existía y ya lo usaban los saldos de Grupos. No inventes un rótulo
  paralelo ni una key localizada.
- **La etiqueta de accesibilidad también.** Si el número lleva «≈» en pantalla y su
  `accessibilityLabel` se formatea sin `isEstimate:`, VoiceOver lo lee como exacto: la marca es
  información, y dejarla solo en el glifo la esconde de quien no lo ve.
- `isEstimate` en los saldos de **Grupos** significa otra cosa —«hubo conversión», no «la tasa era
  mala»— y es una decisión de producto anterior. Es un superconjunto de la nueva, así que no miente;
  no la unifiques sin decisión del owner.

## Al tocar esto, mide

Un verde no prueba nada aquí: hasta el 2026-09-03 **53 pruebas tocaban FX y ninguna podía ponerse
roja** por el bug de la fila parcial, porque ningún fixture omitía una divisa. Antes de dar por bueno
un cambio, **muta y exige rojo** — y el fixture tiene que poder construir la fila incompleta, la fila
de ayer y la tasa cero, o la suite es ciega al único modo en que este módulo falla.
