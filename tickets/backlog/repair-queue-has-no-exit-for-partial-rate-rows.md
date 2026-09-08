---
id: repair-queue-has-no-exit-for-partial-rate-rows
status: backlog
priority: high
area: "currency, fx, cloud-sync, arranque"
created: 2026-09-07
source: review adversarial de fx-manual-writes-seal-approximate-as-final (2026-09-07)
---

# La cola del reparador no tiene salida para el caso que más la llena

## Qué pasa

`TransactionUpdateService.updateProvisionalTransactions` corre **en cada arranque**, busca todas las
transacciones con `isExchangeRateProvisional == true` y llama a `ensureRates` para el rango de sus
fechas. Pero `ensureRates` decide qué falta con `findMissingDates` → `rateExists`
(`ExchangeRateService.swift:450-452, 477-493`), que **solo pregunta si la FILA de ese día existe**, no
si trae la divisa que hace falta.

Y el escenario que marca la mayoría de esas transacciones es exactamente **la fila parcial**: existe la
fila del día, pero le falta la divisa. Así que `ensureRates` responde «no falta nada», vuelve en el
acto, la conversión vuelve a degradar, la transacción se re-marca provisional, y **la cola se recorre
entera otra vez en el siguiente arranque. Para siempre.**

No hay `fetchLimit`, ni contador de intentos, ni backoff, ni sentinel por fecha ya intentada. Y como el
log de DEBUG está dentro de `if updatedCount > 0`, **una cola atascada no imprime nada**: es invisible.

`rateHasAllCurrencies` —que sí pregunta por cobertura de divisa— existe en el mismo fichero
(`ExchangeRateService.swift:456-463`) y solo la llama un sitio (`:187`).

## La asimetría que delata que esto ya se sabía

`repairLegacyOneToOneRatesIfNeeded`, en el mismo fichero, **sí** lleva flag one-shot en `UserDefaults`,
y su docblock dice por qué (`TransactionUpdateService.swift:39-42`):

> repetirlo en cada arranque sería recorrer todas las transacciones para siempre a cambio de nada. Y
> `exchangeRate` viaja por el canal nube en el grupo de coherencia `money`, así que cada fila marcada
> emite: conviene que ocurra una vez y no en bucle.

Ese razonamiento **no se aplicó al bucle que ese barrido alimenta**.

## Los tres daños, medidos el 2026-09-07

1. **Coste de arranque, en el camino crítico.** `findMissingDates` hace **un `context.fetch` por día**
   del rango `min...max` de todo lo marcado (`ExchangeRateService.swift:477-493`). Tres años de
   histórico ≈ 1.100 fetches por arranque aunque no falte ni una fila. Va `await`-eado en el paso 2 del
   bootstrap, antes de `isBootstrapSettled`.
2. **Emisión repetida al canal nube.** `TransactionItem.recalculatePreferredCurrency`
   (`TransactionItem.swift:126-152`) asigna las cuatro columnas del grupo `money`
   **incondicionalmente**, aunque el valor recalculado sea idéntico: SwiftData ensucia igual.
   `DeltaEmitter` expande cualquier columna tocada **al grupo entero** y le sella un HLC fresco. El
   `if updatedCount > 0` no lo evita: solo se salta el `save()` explícito, y `autosaveEnabled` no
   aparece **en ningún sitio de `Yala/`** (cero ocurrencias) + hay saves garantizados en el mismo
   arranque sobre el mismo contexto.
3. **Riesgo de pisar la edición de otro dispositivo.** El grupo `money` resuelve por LWW de su propio
   reloj (`CloudSyncReconciler.moneyHLC`). Un dispositivo que arranca sin haber hecho pull re-sella
   toda la población marcada con un HLC nuevo llevando **sus valores locales aproximados**, y al
   pushear ganan a la edición legítima —anterior en HLC— del otro. No hay eco infinito: el apply del
   grupo `money` llega autoritativo y nunca llama `recalculatePreferredCurrency`
   (`EntityApplyMap.swift:15-16`).

## Qué NO es este ticket

**No es una regresión de `fx-manual-writes-seal-approximate-as-final`.** Los tres mecanismos son
anteriores: `recalculatePreferredCurrency` incondicional viene de `85ba0077`
(`fx-partial-rate-rows-silent-1to1`) y el reparador ya corría en cada arranque. Lo que hizo aquel
ticket fue **aumentar la población** que los recorre — que es lo correcto, porque antes esas
transacciones tenían un número aproximado **sellado como definitivo y sin ninguna ruta de cura**. El
trade-off cambió de «dato falso, coste cero» a «dato correcto y marcado, coste de arranque», y este
ticket es el que paga la segunda mitad.

## Criterio de hecho (AC)

- [ ] `findMissingDates` / `rateExists` preguntan por **cobertura de divisa**, no por existencia de
      fila — o `ensureRates` recibe las divisas que hacen falta. Sin esto la cola no tiene salida y lo
      demás es paliativo.
- [ ] `recalculatePreferredCurrency` no asigna si el valor no cambia (guard de igualdad en las cuatro
      columnas del grupo `money`). Corta a la vez la emisión repetida y el clobber por HLC.
- [ ] Un tope o backoff en `updateProvisionalTransactions`: `fetchLimit`, intentos por transacción, o
      sentinel por `dateKey` ya intentado sin éxito.
- [ ] Que una cola atascada sea **visible**: el log de DEBUG sale del `if updatedCount > 0`, o hay un
      canario del tamaño de la cola por arranque.
- [ ] Test: con fila parcial y sin red, dos arranques seguidos no deben reescribir dos veces la misma
      transacción. Hoy la reescriben siempre.
