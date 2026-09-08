---
id: ensure-rates-for-existing-transactions-has-no-callers
status: backlog
priority: low
area: "currency, fx, limpieza"
created: 2026-09-08
source: review adversarial de repair-queue-has-no-exit-for-partial-rate-rows (2026-09-08)
---

# `ensureRatesForExistingTransactions` no la llama nadie

## Qué pasa

Medido el 2026-09-08 sobre `Yala/`, `YalaTests/` y `YalaUITests/`: `ensureRatesForExistingTransactions`
no tiene ni un llamador. Está declarada en `ExchangeRateServiceProtocol` y definida en el servicio, y
ahí se acaba.

Su docblock dice que debería llamarse «después del onboarding o al cambiar las divisas secundarias».
Ninguno de los dos caminos la llama hoy.

## Por qué merece un ticket y no un borrado a ciegas

Son dos posibilidades opuestas y hay que decidir cuál:

1. **Es código muerto** y se retira (con su línea del protocolo).
2. **Es una llamada que se perdió en algún refactor**, y entonces falta cobertura de tasas justo
   después del onboarding — que es cuando el usuario acaba de elegir divisas y todavía no tiene
   histórico.

La segunda tiene consecuencias para el usuario, así que no es un borrado mecánico.

## Criterio de hecho (AC)

- [ ] Decidir cuál de las dos es, mirando el historial de git de sus llamadores.
- [ ] Si es muerta: retirarla del servicio y del protocolo.
- [ ] Si falta el cableado: reponerlo donde corresponda, con test.
