---
id: chat-rows-sealed-before-the-fix-have-no-repair-path
status: qa
priority: medium
area: "currency, chat"
created: 2026-09-08
updated: 2026-09-08
source: hallazgo de camino en chat-assistant-plants-exchange-rate-one (2026-09-08)
---

# Las transacciones que el chat ya guardó con la tasa falsa no tienen quien las cure

## Qué le pasa al usuario

`chat-assistant-plants-exchange-rate-one` arregló la ruta **hacia delante**: desde el 2026-09-08 el
chat guarda la tasa que usó. Pero las transacciones que ya se guardaron con el `1.0` plantado siguen
ahí, y **el detalle de esas transacciones va a seguir diciendo «1,0000» para siempre**.

## Por qué no se curan solas (medido el 2026-09-08 en este árbol)

Hay dos mecanismos que deberían cogerlas, y ninguno lo hace:

1. **El reparador de arranque** (`TransactionUpdateService.updateProvisionalTransactions`) tiene un
   `#Predicate` que solo busca `isExchangeRateProvisional == true`. Cuando la conversión del chat fue
   **exacta** —el caso normal— el flag quedó en `false`, así que la fila nunca entra en esa cola. Ése
   es justamente el daño que describía el ticket padre.

2. **El barrido legacy** (`TransactionUpdateService.repairLegacyOneToOneRatesIfNeeded`) sí las
   reconocería: `ExchangeRateRepairLogic.needsRepair` pide `exchangeRate == 1.0` **y** divisa distinta
   de la preferida, que es exactamente la forma de estas filas. Pero es **one-shot por dispositivo**:

   ```swift
   private static let repairSweepKey = "fxOneToOneRepairSweep.v1"
   guard !defaults.bool(forKey: repairSweepKey) else { return }
   ```

   y el flag **se marca aunque no hubiera candidatas** (`TransactionUpdateService.swift`, comentario
   propio: «El flag se marca aunque no hubiera candidatas: el barrido HIZO su trabajo»). En cualquier
   instalación donde ese barrido ya corrió, no vuelve.

## La ventana afectada

Las filas creadas desde el chat, en divisa distinta de la preferida, **entre** el arranque en que
corrió `fxOneToOneRepairSweep.v1` y la build que traiga el fix del ticket padre. Las anteriores al
barrido sí se curaron. La ventana es corta pero real, y TestFlight build 12 está dentro.

## Corrección a una creencia del ticket padre

El ticket padre decía que estas filas «parecen candidatas del barrido legacy **sin serlo**». Medido:
es al revés — son candidatas **legítimas**, con el daño exacto que `needsRepair` busca. Lo que las
deja sin cura no es que sean falsos positivos, sino que el barrido no vuelve a correr.

## Criterio de hecho (AC)

- [x] Las filas ya selladas por el chat con `exchangeRate == 1.0` y divisa ≠ preferida vuelven a
      tener una ruta de reparación.
- [x] Si la vía elegida es un `fxOneToOneRepairSweep.v2`, que quede escrito **por qué** se rebobina
      el flag y qué corpus alcanza — un barrido que se re-dispara sin criterio es un aluvión de
      emisiones al canal nube por nada (`exchangeRate` viaja en el grupo de coherencia `money`).
- [x] Un test del barrido legacy. Hoy **no existe ninguno**: `grep -rn "fxOneToOneRepairSweep\|repairLegacyOneToOne" YalaTests/`
      da cero, y su única llamada de producción es `AppBootstrapper`.

## Decisión que puede necesitar Jürgen

Si el corpus afectado es pequeño, puede no compensar el riesgo de re-disparar un barrido sobre toda
la tabla. Esa es una decisión suya, no del código.

## Cerrado el 2026-09-08

**Lo que cambia para el usuario:** un gasto que dictó al chat en otra divisa y que quedó diciendo
«1,0000» en su detalle vuelve a enseñar el tipo de cambio que de verdad se usó — y lo hace **sin
tocar el importe convertido**, que estaba bien.

**La vía es la que el AC contemplaba**, `fxOneToOneRepairSweep.v2`: subir el número de la clave
rebobina el one-shot y el dispositivo que ya barrió vuelve a barrer una vez. Pero **lo que el barrido
HACE con cada fila cambió**, y ésa es la parte que vale.

### El plan obvio hacía daño, y lo destapó la review adversarial

Reabrir la fila —marcarla provisional para que el reparador de arranque la recalcule— es lo que hacía
la `.v1` y era el plan de partida. Medido: **para este corpus es peor que no hacer nada.**

Las filas de la `.v1` tenían el monto convertido **crudo** (la conversión había fallado), así que
recalcular solo podía mejorarlas. Las del chat tienen `amountInPreferredCurrency` **correcto** y solo
mienten en la columna `exchangeRate`. Y `recalculatePreferredCurrency` pisa el monto con lo que dé la
conversión de HOY: si la tasa de aquella fecha ya no está en disco, baja los escalones hasta la tabla
estática, que es un snapshot congelado (`ars: 1050.0` en `CurrencyUtils`, a un orden de magnitud del
valor de 2025). Cambiar un número bueno por uno peor es más daño que el que el ticket venía a curar.
Y hay camino a **pérdida permanente**: el pase siguiente ya no cambia nada, `allFetchesSucceeded`
sella la huella futile de `FXRepairQueueLogic` y la cola deja de reintentarlo.

**Ahora la tasa se deduce de los dos montos que ya están guardados**
(`ExchangeRateRepairLogic.rateFromStoredAmounts`) y se corrige en el sitio. Solo vuelve a la cola la
fila cuyo cociente vale 1 — el monto tampoco se convirtió, que es el corpus de
`fx-partial-rate-rows-silent-1to1` y sí necesita reconversión. Las dos poblaciones estaban bajo el
mismo criterio y tratarlas igual era el error.

**Segundo efecto, y lo cierra el mismo cambio.** Reabrir emite el grupo `money` **entero** —cinco
columnas, `DeltaEmitter` expande cualquiera de ellas al grupo— con la tasa envenenada **todavía
puesta** y un HLC fresco: bajo LWW por unidad, este barrido le habría ganado a un dispositivo par que
ya hubiera reparado esa fila. Difundía el veneno. Corrigiendo antes de guardar, lo que viaja es el
valor bueno.

**Tercero, y lo cazaron las rules de divisas, no una lente:** un monto convertido en `0` da cociente
`0`. Sellar eso reproduciría dentro del arreglo la forma exacta del bug del módulo —una tasa
inservible que pasa por dato—. Se filtra con `CurrencyConverter.isUsableRate`, que es la misma
pregunta que hacen la cobertura de la caché y el guard de la conversión.

### Dos guards nuevos, y no son el mismo

El barrido nació el 2026-09-03 (`6ddc4367`), **después** de que `ccbc97e9` gateara por quiescencia
los `save()` del store personal en el arranque, y no lo tenía: hacía `save()` en pleno import del
restore mientras `updateProvisionalTransactions` —tres líneas más abajo— sí salía por el suyo. En ese
arranque el barrido tocaba filas, quemaba el flag, y el reparador que debía curar las reabiertas ni
siquiera corría. Ahora comparte el gate.

Y **sobre un store sin ninguna transacción ya no se sella**: es el punto ciego que
`ChatUnsignedExpenseRepairService` cerró para su propio barrido citando a éste por su nombre. Su
referencia cruzada se actualiza aquí, porque el cambio la dejaba apuntando a otras líneas.

**Residual declarado, no resuelto.** `isImportQuiescent` vale `true` **antes** de que empiece ningún
import (`lastImportDate == nil`, documentado en `BootSaveGateLogic`), así que en el arranque en frío
de un restore el gate está abierto; y el guard de presencia distingue *vacío* de *no vacío*, no
*completo* de *parcial* — un restore que ya entregó 3 filas de 5.000 sella igual. Cerrarlo pedía el
gate de seis entradas de `awaitPersonalStoreReady`, que este barrido no usa porque **no espera nada en
absoluto** → `fx-repair-sweep-seals-on-a-partially-restored-store`.

### Verificación

`YalaTests/FXOneToOneRepairSweepTests` (13 casos), **9 mutantes verificados**, cada uno rojo en su
caso y solo en el suyo. El que más importa es `reabrir-siempre`: reponer el diseño anterior pone en
rojo el caso principal con 4 issues, uno de ellos el del monto — o sea que el hallazgo de diseño está
demostrado, no razonado.

**El agujero de test que cazó la segunda lente:** los 12 casos de comportamiento inyectan
`isQuiescent` y `defaults`, y producción no pasa ninguno de los dos — un mutante `isQuiescent ?? true`
dejaba la suite **entera** verde devolviendo la app al bug del ticket. Lo cierra
`productionCallSite_isWiredToTheSyncService`, que además pinnea el orden barrido → reparador que el
comentario de producción declara crítico y que no cubría nadie.

### Correcciones a este ticket, medidas

1. **El AC nº3 decía que el grep «da cero» y da una línea** (el `// MARK:` de
   `TransactionUpdateServiceTests`). La sustancia se sostiene —ningún test invocaba la función— pero
   la cifra no era la de este árbol.
2. **«Un barrido que se re-dispara es un aluvión de emisiones» estaba mal calibrado en los dos
   sentidos.** El coste no es el tamaño del store sino el número de filas candidatas; pero cada una
   emite **las cinco** columnas del grupo, no una. Y el problema serio no era el volumen: era el
   contenido de lo que se emitía.
3. **La banda del umbral es `0 < |monto| <= 0.0001`**, con valor absoluto: desde el PR #102 los
   gastos del chat se guardan negativos, o sea justo la mitad que un rango sin `abs` dejaría fuera.

### Qué falta

Device-QA. **Sí es simulable**: hace falta una cuenta en otra divisa y una fila sembrada con
`exchangeRate = 1.0` y monto convertido real; al arrancar, el detalle debe pasar de «1,0000» a la tasa
verdadera **sin que cambie el importe convertido**, y sin que aparezca el «≈». El log de DEBUG imprime
el reparto entre curadas en el sitio y reabiertas, que es lo que responde cuántas filas había de
verdad.

### Hallazgos de camino, con ticket propio

- `fx-repair-sweep-seals-on-a-partially-restored-store` (medium)
- `fx-repair-sweep-is-the-only-boot-sweep-without-a-uitest-gate` (low)
- `fx-repair-sweep-has-no-canary` (low)
