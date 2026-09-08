---
id: chat-assistant-plants-exchange-rate-one
status: backlog
priority: medium
area: "currency, chat"
created: 2026-09-07
source: hallazgo de camino en fx-manual-writes-seal-approximate-as-final (2026-09-07)
---

# Crear una transacción desde el chat guarda `exchangeRate = 1.0` sin mirar la tasa

## Qué le pasa al usuario

En `ChatAssistantViewModel.swift:513` la transacción nace con `exchangeRate: 1.0` **literal**, aunque
el monto convertido de al lado sí salga de una conversión real. Las otras seis rutas que crean
transacciones derivan la tasa efectiva del propio resultado
(`amountInPreferred / amount`, con el guard de `abs(amount) > 0.0001`); ésta no.

El número que se ve en el detalle de la transacción dice «1,00» para un gasto en otra divisa.

## Actualizado el 2026-09-07: sube a `medium`, y el bug de la FECHA ya se arregló

La review adversarial de `fx-manual-writes-seal-approximate-as-final` destapó que esta ruta tenía
**dos** defectos, no uno, y que el segundo era peor:

**Arreglado ya (en aquel PR):** convertía con `convertCheckedWithLatestRate` —la tasa de HOY— y
después estampaba la transacción con `draft.date`, que el parseo resuelve como `parsed.date ?? .now`.
Dictar «un café ayer» guardaba el gasto convertido a la tasa de hoy. Peor: **el reparador convierte
`on: date`** (`TransactionItem.swift:130`), así que el número guardado no era reproducible por el
proceso que existe para repararlo — al pasar por él habría cambiado. Ahora convierte `on: draft.date`
como las otras seis rutas de creación.

**Sigue vivo (esto es el ticket), y sube a `medium`:** el `exchangeRate: 1.0` plantado. La razón por la
que estaba en `low` —«el reparador lo cura»— es falsa en el caso NORMAL: cuando la tasa es exacta el
flag queda `false`, la transacción sale de la cola del reparador (`#Predicate` = `== true`) y el 1.0
mentiroso se sella para siempre. O sea que esta ruta guarda una tasa falsa en **la mayoría** de sus
ejecuciones, no en la minoría.

## Por qué NO era `high` (la valoración original, que ya no aplica del todo)

Desde `fx-manual-writes-seal-approximate-as-final` (2026-09-07) esta ruta **marca la provisionalidad**
correctamente, y el reparador (`TransactionUpdateService`) recalcula monto **y tasa** al pasar por una
transacción provisional — así que el 1.0 se cura solo en el arranque siguiente **cuando la conversión
fue aproximada**. Lo que NO se cura es el caso exacto: conversión buena, flag en `false`, y el `1.0`
plantado se queda.

Segundo efecto, menor: `ExchangeRateRepairLogic.needsRepair` usa `exchangeRate == 1.0` como criterio,
así que estas transacciones parecen candidatas del barrido legacy sin serlo. Ese barrido es one-shot y
ya corrió, de modo que hoy no cambia nada — pero es una señal falsa si alguien lo reabre.

## Criterio de hecho (AC)

- [ ] La ruta deriva la tasa efectiva como las demás, con el mismo guard del umbral.
- [ ] Un test: transacción creada desde el chat en divisa distinta de la preferida guarda un
      `exchangeRate` distinto de 1.0 y coherente con `amountInPreferredCurrency / amount`.
- [ ] Buscar el patrón: ninguna otra ruta de creación planta la tasa en vez de derivarla.
