---
id: chat-rows-sealed-before-the-fix-have-no-repair-path
status: backlog
priority: medium
area: "currency, chat"
created: 2026-09-08
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

- [ ] Las filas ya selladas por el chat con `exchangeRate == 1.0` y divisa ≠ preferida vuelven a
      tener una ruta de reparación.
- [ ] Si la vía elegida es un `fxOneToOneRepairSweep.v2`, que quede escrito **por qué** se rebobina
      el flag y qué corpus alcanza — un barrido que se re-dispara sin criterio es un aluvión de
      emisiones al canal nube por nada (`exchangeRate` viaja en el grupo de coherencia `money`).
- [ ] Un test del barrido legacy. Hoy **no existe ninguno**: `grep -rn "fxOneToOneRepairSweep\|repairLegacyOneToOne" YalaTests/`
      da cero, y su única llamada de producción es `AppBootstrapper`.

## Decisión que puede necesitar Jürgen

Si el corpus afectado es pequeño, puede no compensar el riesgo de re-disparar un barrido sobre toda
la tabla. Esa es una decisión suya, no del código.
