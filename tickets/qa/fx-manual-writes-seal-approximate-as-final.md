---
id: fx-manual-writes-seal-approximate-as-final
status: qa
priority: high
area: currency
created: 2026-09-06
updated: 2026-09-09
source: hallazgo de camino en fx-presentation-still-shows-1to1 (2026-09-06)
---

# Diez escrituras sellan como definitiva una tasa que fue aproximada

## Qué le pasa al usuario

Crear una transacción a mano —el flujo principal de la app— guarda el monto convertido y lo marca
como **definitivo**, aunque la tasa que se usó no fuera la del día. Si ese día a la fila de tasas le
faltaba la divisa, el converter baja al escalón siguiente (fila anterior real, o tabla estática) y
devuelve un número **aproximado**. La transacción se sella con `isExchangeRateProvisional = false`, y
el reparador —cuyo `#Predicate` es `== true` (`TransactionUpdateService.swift:96`)— **no vuelve a
mirarla nunca**. El número aproximado se queda para siempre, viaja por la nube y alimenta informes.

## Por qué esto no lo cerró `fx-partial-rate-rows-silent-1to1`

Aquel ticket arregló el converter y el **punto de paso** de la escritura:
`TransactionItem.recalculatePreferredCurrency` (24 llamadas) más las cuatro rutas del import CSV.
Los diez sitios de abajo **no pasan por ese punto de paso**: llaman a `CurrencyConverter.convert(...)`
—que devuelve `Decimal` a secas y tira la calidad— y escriben `amountInPreferredCurrency`,
`exchangeRate` y `preferredCurrencyCode` a mano, sin tocar el flag.

## Medido el 2026-09-06 (worktree de `fx-presentation-still-shows-1to1`, HEAD `6d87123e`)

Las doce escrituras a `amountInPreferredCurrency` en `Yala/`; **diez** son escritura a mano con
`convert` a ciegas y ninguna fija `isExchangeRateProvisional`:

| fichero:línea | flujo |
|---|---|
| `NewTransactionViewModel.swift:645` | crear/editar transacción (**flujo principal**) |
| `NewTransactionViewModel.swift:730` | transferencia, pata de salida |
| `NewTransactionViewModel.swift:745` | transferencia, pata de entrada |
| `DraftService.swift:245` | aprobar borrador de liquidación de grupo |
| `DraftService.swift:314` | aprobar borrador genérico |
| `DraftService.swift:446` | aprobación masiva de borradores |
| `DraftService.swift:738` | aprobar gasto de grupo con cuenta |
| `DraftService.swift:926` | aprobar opt-in personal de liquidación |
| `InboxDraftEditSheet.swift:970` | editar y aprobar desde Inbox |
| `CurrencyChangeService.swift:77` | cambio de moneda preferida (**reescribe TODO el histórico**) |

Las otras dos no son el bug: `TransactionItem.swift:175` es el init (recibe el flag como parámetro) y
`CloudSyncReconciler.swift:101` copia del ganador, junto al flag (`:104`).

**El caso de `CurrencyChangeService` es el peor de los diez**: reescribe en bucle transacciones ya
persistidas sin tocar el flag, así que puede **degradar** a aproximada una transacción que sí estaba
marcada como provisional, quitándole la ruta de auto-cura que tenía.

**El grep que mide esto falla si se escribe ingenuamente**: seis de las diez asignaciones están
partidas en dos líneas, y `grep "\.amountInPreferredCurrency = "` (con espacio) devuelve seis, no
doce. El patrón que mide es `"\.amountInPreferredCurrency\s*="`.

## Criterio de hecho (AC)

- [x] Los ~~diez~~ **catorce** sitios usan `convertChecked` y fijan
      `isExchangeRateProvisional = !quality.isExact`.
- [x] `CurrencyChangeService` no baja el flag de una transacción que ya lo tenía en alto —
      **con un matiz medido, abajo**.
- [x] Un test por familia con una fila de tasas a la que le falte la divisa: la transacción nace
      marcada. Cubiertas por comportamiento **borrador** y **cambio de preferida**; creación y
      transferencia, por barrido de fuente (ver «Qué quedó fuera»).
- [x] Barrido con control positivo: ninguna escritura de `amountInPreferredCurrency` fuera del init,
      del reconciler y de los seeds deja el flag sin decidir.

## Cerrado el 2026-09-07 — lo que el ticket no traía

**No eran diez sitios: son catorce.** El grep del ticket buscaba la ASIGNACIÓN
(`.amountInPreferredCurrency =`) y por eso no podía ver las cuatro escrituras que pasan el monto por
**init** (`amountInPreferredCurrency:`). Entre las que faltaban están **las tres ramas de CREACIÓN de
`NewTransactionViewModel`** — el ticket listaba solo las de edición del mismo fichero, así que «el
flujo principal» estaba cubierto a medias — y **`ChatAssistantViewModel:523`** (crear transacción
desde el chat), que no figuraba en ninguna lista.

| añadido | flujo |
|---|---|
| `NewTransactionViewModel.swift:655` | crear transacción (rama nueva del flujo principal) |
| `NewTransactionViewModel.swift:764` | transferencia, pata de salida (creación) |
| `NewTransactionViewModel.swift:781` | transferencia, pata de entrada (creación) |
| `ChatAssistantViewModel.swift:513` | crear transacción desde el chat |

**El AC nº 2 describe un mecanismo que no existía, y el bug real es el contrario.** El código de
`CurrencyChangeService` **no tocaba el flag en absoluto**: una transacción que llegaba en `true` salía
en `true`, así que no podía perder su auto-cura. Lo que sí hacía —y es el daño grave— era dejar en
`false` una transacción que estaba correctamente sellada contra la divisa VIEJA y acababa de
reconvertirse a la nueva con una tasa aproximada. El arreglo decide el flag **incondicionalmente**
(`= !quality.isExact`), igual que `recalculatePreferredCurrency`: el flag describe la calidad del
número que hay AHORA, no un historial. Un `flag = flag || !isExact` —la lectura literal del AC— dejaría
marcadas para siempre transacciones ya exactas, y el reparador las recorrería en cada arranque sin
poder cerrarlas. Hay un test para esa tercera dirección.

**El detector de este bug nació con este bug.** El barrido de fuente contaba CERO inits porque su
regex usaba `^` sin `.anchorsMatchLines`, y declaró «ninguna escritura» justo sobre el único fichero
cuyo sitio es un init. No lo cazó su control positivo —que solo traía la forma de asignación— sino el
barrido real un paso después. El control positivo ahora incluye las dos formas.

**Verificado por mutación, no por verde:** quitar la decisión del flag en `DraftService` y
`CurrencyChangeService` pone 4 casos en rojo (5 issues), y las parejas de control siguen verdes.

## Qué quedó fuera

- **Device-QA: no es simulable**, por el mismo motivo que ya registra el área
  `fx-conversion-persistence` — el recorrido de punta a punta necesita red y un histórico real de
  tasas con una fila a la que le falte una divisa. La verificación es unit + mutación.
- **Creación y transferencia** (`NewTransactionViewModel`) quedan cubiertas por el barrido de fuente
  y no por comportamiento: `save(context:)` arrastra `WidgetDataCache`, `RouterEntryGate`,
  `SessionState` y un `Task` sin await, y montar eso da un test más frágil que la red que aporta.
- **`InitialBalanceService`** (2 inits) y los **seeds de desarrollo** (5) escriben el monto sin
  decidir el flag, y está bien: el primero llama `recalculatePreferredCurrency` justo después —que ya
  lo decide— y los segundos son datos sintéticos que nunca ven una tasa real.
- Dos hallazgos de camino salen con ticket propio: `currency-change-service-tests-mirror-the-logic`
  y `chat-assistant-plants-exchange-rate-one`.

## No confundir con

- `fx-partial-rate-rows-silent-1to1` (en `qa/`) — el converter y el punto de paso, ya arreglados.
- `fx-presentation-still-shows-1to1` — que el número **mostrado** declare que es aproximado.

---

## 2026-09-09 — el montaje que esperabas ya existe

El estado de partida se siembra desde un solo launch con `-uitest -uitest-reset -uitest-skip-onboarding -uitest-seed realista -uitest-seed-foreign-account JPY` (ticket `qa-no-puede-crear-cuenta-en-otra-divisa`, **done**). Deja la cuenta «QA FX» con un ingreso y dos gastos fechados HOY, marcados `isExchangeRateProvisional` por el camino de producción — la fila del día existe y no trae JPY, así que la conversión es `.staticFallback`.

**Aviso para no leer un falso negativo:** con el filtro «Todo el tiempo» el fixture NO marca (750 sobre 206.725 son el 0,36 %, bajo el umbral del 5 %). **Acota el período** — con «Este mes» los tres números del Panel llevan «≈» y sin el arg ninguno.

**Desbloqueado a medias.** El montaje cubre la fila incompleta; lo que tu :108 pide además es **red**, y eso sigue fuera del simulador. Los diez sitios que sellan se pueden verificar con este corpus salvo en la parte que exige que las tasas LLEGUEN.
