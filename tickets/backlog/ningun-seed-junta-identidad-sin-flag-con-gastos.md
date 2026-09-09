---
id: ningun-seed-junta-identidad-sin-flag-con-gastos
status: backlog
priority: medium
area: "groups, testing, seeds"
created: 2026-09-09
source: guion de device-QA de Grupos del 2026-09-09 (hallazgo de camino)
---

# Ningún perfil de seed junta «identidad sin flag» con gastos, y por eso un bug de Grupos solo se ve en un teléfono

## Qué pasa

`groups-equal-split-shows-not-participating-on-peer` necesita un estado muy concreto: un grupo del
canal backend **con gastos y shares** en el que mi propia fila de miembro haya llegado del pull con
`isCurrentUser` **apagado** — que es como llega siempre, porque el pull nunca lo enciende.

Ninguno de los perfiles de seed produce esa combinación:

| Perfil | Identidad sin flag | Gastos | Sirve |
|---|---|---|---|
| `grupos-sin-flag` | sí (`DevSeedGroups.createAsBackendJoiner`) | **cero `SplitExpense`** | no |
| `grupos-pendiente` | sí | uno, pero soy `pendingApproval` y la puerta del grupo está cerrada | no |
| `grupos` · `grupos-invitado` | **no** (`isCurrentUser: true`) | sí | no — con el flag puesto, el bug viejo y el código arreglado se ven **idénticos** |

## Por qué importa

No es un hueco de cobertura cualquiera: es un ticket que **acaba en la cola física del owner sin
necesitarla**. El estado es 100 % local y no interviene ningún RPC — lo único que falta es sembrarlo.
Es la misma familia que [[seeds-de-grupos-no-escriben-userid-ni-memberkey]], y como aquél, lo que
parece «no se puede probar aquí» es en realidad «no se puede **todavía** aquí».

Y tiene un agravante: con el flag puesto, un QA en simulador **pasa en verde sin haber ejercitado la
rama arreglada**. Es una aserción que no puede fallar.

## Qué haría falta

Un perfil que combine lo de `grupos-sin-flag` (identidad que solo resuelve por el resolvedor canónico,
con `-uitest-icloud-identity` sembrando el `recordName` que casa) **con** al menos un `SplitExpense` de
reparto igualitario y sus shares. Con eso, el criterio del ticket —fila con «Te prestaron» + monto, y
nunca «No participaste»— se comprueba sin tocar un teléfono.

Control positivo obligatorio al escribirlo: revertir el fix debe hacer aparecer el literal
`groups.expense.notIncluded` («No participaste»). Si con el mutante puesto el escenario sigue verde,
el perfil no está discriminando y no vale.
