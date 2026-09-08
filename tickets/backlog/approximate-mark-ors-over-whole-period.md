---
id: approximate-mark-ors-over-whole-period
status: backlog
priority: medium
area: "currency, fx, ui"
created: 2026-09-07
source: review adversarial de fx-manual-writes-seal-approximate-as-final (2026-09-07)
---

# Una sola transacción aproximada pone «≈» al número grande de todo el mes

## Qué le pasa al usuario

`HeroBucketsCalculator` acumula la marca con un **OR sobre todo el bucket del período**
(`HeroBucketsCalculator.swift:102,105`), igual que `CashFlowCalculator` por lado
(`CashFlowCalculator.swift:95`). Basta **una** transacción con la tasa aproximada para que el hero del
Panel —y su etiqueta de VoiceOver, `HeroMonthView.swift:198-205`— declare aproximado el total del mes
entero.

Desde `fx-manual-writes-seal-approximate-as-final` la población marcada es mucho mayor, así que esto
pasa de raro a frecuente para el usuario multidivisa. Tres fuentes nuevas:

- Crear una transacción mientras la fila del día aún no cubre las dos divisas (arranque sin red, o
  antes de que termine el refresco; el fallo de API se traga en silencio).
- **Editar cualquier cosa de una transacción vieja**: cambiar solo la nota de una de hace dos años,
  cuya fila es parcial, la voltea `false → true` y le pone «≈» al hero de aquel mes.
- Cambiar la divisa preferida, que recorre el histórico completo.

`FXPnLLogic` sí degrada bien —marca **por fila de divisa** (`FXPnLLogic.swift:301`)— y es el modelo a
seguir.

## Por qué importa y no es cosmético

Lo dice el propio código en `FXPnLLogic.swift:72-74`: **marcar de más erosiona la marca igual que no
ponerla**. Si el «≈» sale casi siempre, deja de significar nada y el usuario aprende a ignorarlo —
que es justo el final que `fx-presentation-still-shows-1to1` vino a evitar por el otro extremo.

Se agrava con `repair-queue-has-no-exit-for-partial-rate-rows`: mientras esa cola no tenga salida, las
transacciones marcadas no se limpian nunca y la marca se vuelve permanente.

## Lo que NO está afectado (medido)

- **Usuarios monomoneda**: `convertChecked` cortocircuita `fromCode == toCode` a `.exact`
  (`CurrencyConverter.swift:236-239`), y `contextFreeQuality` hace lo mismo antes de `setContext`. El
  problema es exclusivo de multidivisa.
- **El panorama del Panel**: su marca sale del `LiveBalanceCalculator`, no de este flag.

## Criterio de hecho (AC)

- [ ] Decidir con Jürgen el umbral: ¿marca si CUALQUIER transacción es aproximada, si lo es una
      fracción del importe, o se marca por divisa como en `FXPnLLogic`? Es decisión de producto.
- [ ] Sea cual sea, que el hero y la comparativa usen el mismo criterio — hoy los tres calculadores no
      coinciden.
- [ ] Test que fije el criterio elegido con un caso de una sola transacción aproximada entre muchas
      exactas.
