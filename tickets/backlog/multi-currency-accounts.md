---
id: multi-currency-accounts
status: backlog
priority: medium
area: "accounts, currency"
created: 2026-09-09
source: idea Jürgen 2026-09-09
---

# Una cuenta con más de una divisa: la tarjeta que cobra en soles y en dólares

## La idea

Que una misma cuenta pueda llevar saldos en varias divisas a la vez. El caso de Jürgen es una
tarjeta de crédito peruana: cobra en soles y en dólares **por separado**, cada línea con su propio
saldo, pero es una sola tarjeta y el usuario la piensa como una.

## Por qué importa

Hoy la única salida es partir la tarjeta en dos cuentas: dos filas, dos saldos y ninguna vista de
«cuánto debo en esta tarjeta». En Perú la tarjeta bimoneda es lo normal, no un borde.

## Lo medido (2026-09-09)

El supuesto de una divisa por cuenta está en el modelo, no en la pantalla:

- `Yala/Models/Account.swift:17` — `var currencyCode: String = "USD"`. Una propiedad, un `String`.
  Sin arrays de divisas, sin sub-saldos, sin relación a saldos por divisa.
- El saldo se calcula sobre esa premisa: `AccountBalanceCalculator`
  (`Yala/Utils/AccountBalanceCalculator.swift:13`) y `LiveBalanceCalculator`
  (`Yala/App/Logic/Calculators/LiveBalanceCalculator.swift:18`).
- Falso amigo a no confundir: `currencyToSuggestAsSecondary`
  (`AccountFormViewModel.swift:64,394`) **no** es multi-divisa de la cuenta — es una preferencia
  global de visualización (`"secondaryCurrencies"` en `SessionDefaults`).

## Estado

Idea capturada, **sin spec**. Es un cambio de modelo de datos antes que de pantalla: al hacer spec,
**medir** todo lo que cuelga de `Account.currencyCode` (saldo, conversión a la divisa preferida,
informes, widgets, bridge de grupos, CSV, migración SwiftData) antes de prometer alcance.

## Relacionados

- [[changing-an-account-currency-orphans-its-whole-history]] (**high**) — el mismo supuesto visto
  por su lado roto: hoy cambiar la divisa de una cuenta deja su histórico en la divisa vieja.
- [[preferred-currency-has-three-different-defaults]] — la otra pata suelta de divisa por defecto.
