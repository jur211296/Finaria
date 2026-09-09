---
id: account-currency-conversion-overlay-has-no-ceiling
status: backlog
priority: medium
area: "accounts, currency, fx, ux"
created: 2026-09-09
source: review adversarial de changing-an-account-currency-orphans-its-whole-history (2026-09-09)
---

# Convertir una cuenta con años de histórico puede dejar la pantalla tapada varios minutos sin salida

## Qué le pasa al usuario

Confirma la conversión de una cuenta con tres años de movimientos y con mala cobertura. La pantalla
se tapa con un indicador que **da vueltas sin decir cuánto queda**, no hay botón de cancelar, el
gesto de cerrar está desactivado y el aspa de la barra queda debajo del velo. La única salida es
matar la app.

Matarla ahí no corrompe nada —la conversión aún no se ha guardado— pero el usuario no lo sabe.

## Lo medido (2026-09-09)

`Yala/Services/AccountCurrencyMigrationService.prepareRates` pide una fecha por fila y se las pasa a
`ExchangeRateService.fetchRates` (`:317-336`), que agrupa en rangos contiguos y lanza **una petición
HTTP secuencial por rango**, con `Task.sleep(0.3)` entre cada una y timeouts de 30-60 s
(`ExchangeRateAPIService.swift:86,177`). Con ~150 días sueltos son ~150 peticiones en serie.

Tampoco hay guard de red antes de empezar.

El contraste lo invoca el propio código: el overlay del cambio de divisa **preferida**
(`CurrencySettingsView.swift:83-105`), que este espeja, usa `ProgressView(value:total:)`
**determinado**. Aquí no hay ni progreso ni cota porque `fetchRates` no reporta ninguno.

## Criterio de hecho (AC)

- [ ] La conversión enseña progreso real, o una cota, o se puede cancelar. (Decidir cuál.)
- [ ] Si no hay red, se dice antes de empezar en vez de tapar la pantalla y agotar timeouts.

## Relacionados

- `changing-an-account-currency-orphans-its-whole-history` — de donde sale.
