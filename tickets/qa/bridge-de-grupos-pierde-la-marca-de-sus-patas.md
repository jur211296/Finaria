---
id: bridge-de-grupos-pierde-la-marca-de-sus-patas
status: qa
priority: medium
area: "groups, currency, fx"
created: 2026-09-08
updated: 2026-09-09
source: review adversarial de approximate-mark-ors-over-whole-period (2026-09-08)
---

# Un gasto de grupo puede salir «exacto» aunque el 90 % de su cálculo venga de una tasa dudosa

## Qué pasa

`GroupBridgeStatsAdjustment` sintetiza el importe que ven las estadísticas como
`preferred = pata real + Σ patas de préstamo`. Las patas de préstamo están **suprimidas** del
recorrido, así que su `isExchangeRateProvisional` **no lo lee nadie**.

Caso concreto: pata real de −1.000 con tasa exacta, pata de préstamo de +900 con tasa provisional.
El importe ajustado son −100, y se contabiliza como **100 % exacto** — cuando el 90 % de la
aritmética que lo produjo salió de una tasa dudosa.

## Por qué importa MÁS desde el 2026-09-08

**Es preexistente**: con el OR anterior la ceguera era la misma. Lo que cambia es la consecuencia.
Antes la marca era booleana y cualquier otra transacción aproximada del período la encendía igual.
Ahora el importe entra en un **cociente** (`ApproximateMarkThreshold`), así que una atribución mal
hecha no solo se pierde: **desplaza el umbral** y puede apagar la marca de todo el bucket.

## Acceptance Criteria

- [x] Un gasto de grupo con la pata real exacta y una pata de préstamo provisional cuenta como
      aproximado en el numerador del umbral.
- [x] Test con `adjustment` distinto de `.none` — no había **ninguno** en `ApproximateAmountMarkTests`
      (medido: 0 menciones de `adjustment` en sus 1.125 líneas).
- [x] No cambia el importe mostrado, solo su marca.

## Qué se hizo (2026-09-09)

La síntesis del bridge acumula ahora, junto al importe, la **magnitud dudosa** que hay detrás:
`Σ|patas provisionales|` en divisa preferida. La sirve `approximateMagnitude(_:magnitude:)`, hermano
de `amountInPreferredCurrency(_:)`, y la usan los **cuatro** numeradores del umbral:
`HeroBucketsCalculator`, `CashFlowCalculator` (rama «misma divisa»),
`RecordsViewModel.calculateSummary` y `WidgetDataCache.buildPeriodSummary`. El importe mostrado no
cambia en ningún caso.

Dos superficies siguen leyendo el flag de la fila **a propósito**, porque su importe tampoco lleva
ajuste: el saldo histórico del widget y la fila cruda de `WidgetTransaction`. Un test lo fija, para
que el arreglo no invite a cablearlas.

### El escenario es alcanzable, y por dónde

Las dos patas nacen con la misma divisa y la misma fecha (`GroupTransactionBridge.swift:428` exige
`providedAccount.currencyCode == expense.currencyCode`), así que **nacen con el mismo flag**. La
asimetría llega después, y hay al menos tres caminos medidos:

1. **La real llega tarde.** `createVirtualLent` se llama siempre (`:477`), incluso cuando el sync
   remoto no encuentra cuenta local y deja un draft. Cuando el usuario aprueba ese draft días más
   tarde, la pata real nace con la cobertura de tasas de **ese** día.
2. **El reparador trabaja por cola.** `TransactionUpdateService` / `FXRepairQueueLogic` pueden curar
   una pata y dejar la otra para la siguiente pasada.
3. **Editar la pata real la reconvierte** con la escalera de hoy y deja la de préstamo atrás.

## Review adversarial (3 lentes + la rule de área) — lo que cazó

1. **El numerador que yo había escrito era el NETO, y eso está prohibido por contrato.**
   `ApproximateMarkThreshold` documenta —con esta misma pareja de números— que numerador y
   denominador son «magnitudes sumadas, nunca netos», porque los errores de dos conversiones no se
   cancelan. Mi primera versión marcaba `abs(net)`, que es el error gemelo del que la sesión anterior
   cometió con el denominador. Falla en las **dos** direcciones, y las dos están medidas:
   - **Se queda corto**: viaje, adelanto el hotel de diez (10.000, mi parte 1.000, préstamo 9.000
     dudoso) sobre un mes de 26.000 ⇒ 3,8 %, **sin marca**, con un tercio de la aritmética dudosa.
   - **Se pasa**: cena de dos, mi parte 9.700 y 300 prestados dudosos sobre 10.300 ⇒ 94 %, **marca el
     mes entero por 300**. En el límite, dos céntimos dudosos marcarían el mes — la erosión exacta
     que el umbral del 2026-09-08 vino a evitar.

   Corregido a `Σ|patas provisionales|`. Los tres tests que distinguen una versión de la otra son
   nuevos y están verificados con mutante.
2. **Los tests de Registros pasaban a solas y daban cero en la suite completa.** `makeTestContext()`
   reusa el container por `#fileID` y **vacía el store en cada llamada**; `.serialized` ordena dentro
   de una suite, no entre suites hermanas del mismo archivo. La suite se mudó a archivo propio. La
   regla está en `.claude/rules/testing.md`, con el síntoma: **verde a solas, cero acompañado**.
3. **Un flaky que aún no había disparado:** `RecordsViewModel.applyFilters` lee
   `includeGroupTransactionsInFeed` de `UserDefaults.standard` y, en `false`, descarta toda fila con
   `splitExpenseID` — es decir, el escenario entero. Se fija y se restaura, como el período.
4. **Tres aserciones que no medían su premisa.** Hero, Widgets y Registros afirmaban la marca sin
   comprobar que la pata de préstamo estaba suprimida: borrar la supresión los dejaba verdes midiendo
   otra cosa. Y dos tests del bridge pasaban con el bridge apagado, porque el accessor cae al flag de
   la fila. Los cuatro veredictos de la pareja están ahora parametrizados con la premisa dentro.
5. **Cuatro defectos en el source-scan**: una aserción duplicada literal de otra 150 líneas más
   arriba, un parámetro muerto en el helper del escenario, un ancla de cierre que se rompía con un
   refactor inocuo (`let netCashFlow …` → `var balanceApproximateMagnitude`), y un `for` que abortaba
   el barrido en el primer ancla rota dejando los otros tres ficheros sin comprobar (ahora
   `arguments:`, un caso por fichero).
6. **Un comentario mío quedó falso al arreglar**: `HeroBucketsCalculator` seguía diciendo que el flag
   de la propia transacción «es la única fuente de verdad de esta señal». Corregido.
7. **La rule de área confirmó el diseño**: `.claude/rules/currency-fx.md` ya decía que la calidad de
   una conversión es **la peor de sus dos divisas** — «decir `.exact` porque una de ellas lo era es
   la verdad a medias que este enum existe para impedir». Un importe compuesto es el mismo caso.

### Verificación

Build ×2 y **6.556 tests en 667 suites en verde**. Tres mutantes compilados, cada uno con su conjunto
de rojos y ninguno silencioso: numerador neteado (caen los 4 direccionales + 3 de los 4 veredictos),
sumatorio sin las patas de préstamo (caen los 4 consumidores), y revertir el cableado del hero (cae su
test de comportamiento **y** el source-scan).

## Qué falta

**Device-QA.** Y **no es simulable hoy**: el escenario necesita una cuenta en divisa distinta de la
preferida —la conversión identidad es `.exact` por construcción
(`CurrencyConverter.swift:238`)—, más dos patas selladas con coberturas de tasas distintas. Ningún
seed es multi-divisa ni marca `isExchangeRateProvisional`.

Espera a [[qa-no-puede-crear-cuenta-en-otra-divisa]] (**high**), que sigue siendo la palanca con
mejor relación coste/desbloqueo del board. **La cifra, medida hoy y no heredada** —`docs/ESTADO.md`
decía «cinco»—: en `tickets/qa/` hay **tres** que se declaran *no* simulables por esta causa (éste,
`chat-assistant-plants-exchange-rate-one` y `fx-manual-writes-seal-approximate-as-final`) y **dos**
más que piden el mismo montaje declarándose *sí* simulables (`chat-rows-sealed-before-the-fix-...` y
`fx-approximate-mark-missing-on-secondary-surfaces`). Cinco esperan la misma palanca; tres están
parados por ella.

## Hallazgos que NO se arreglan aquí, con ticket propio

- [[financial-report-amounts-unmarked]] — la pantalla de Informes pinta **22 importes** y ninguno
  puede llevar la marca. Es la pantalla a la que se va a buscar el detalle del número marcado.
- [[widget-fallback-summary-uses-ten-rows]] — el widget, si le falta el resumen precalculado,
  recalcula el total del mes sobre las **diez** filas del snapshot y lo pinta sin salvedad.
- [[bridge-synthesis-trusts-a-zero-converted-amount]] — una pata con el importe convertido en cero
  hace que el gasto salga con el importe del grupo entero, y sin marca.

## Relacionados

- [[approximate-mark-ors-over-whole-period]] — el cambio que convirtió esta ceguera en un peso.
- [[fx-approximate-mark-missing-on-secondary-surfaces]] — la tanda anterior de la familia.

---

## 2026-09-09 — el montaje que esperabas ya existe

El estado de partida se siembra desde un solo launch con `-uitest -uitest-reset -uitest-skip-onboarding -uitest-seed realista -uitest-seed-foreign-account JPY` (ticket `qa-no-puede-crear-cuenta-en-otra-divisa`, **done**). Deja la cuenta «QA FX» con un ingreso y dos gastos fechados HOY, marcados `isExchangeRateProvisional` por el camino de producción — la fila del día existe y no trae JPY, así que la conversión es `.staticFallback`.

**Aviso para no leer un falso negativo:** con el filtro «Todo el tiempo» el fixture NO marca (750 sobre 206.725 son el 0,36 %, bajo el umbral del 5 %). **Acota el período** — con «Este mes» los tres números del Panel llevan «≈» y sin el arg ninguno.

**Desbloqueado a medias.** La cuenta ya la tienes; lo que tu :112 pide además —«dos patas selladas con coberturas de tasas distintas»— el seam no lo produce, porque siembra las tres filas con la misma cobertura.

Y una corrección: tu :113 dice «Ningún seed es multi-divisa ni marca `isExchangeRateProvisional`». La primera mitad es **falsa desde siempre** — `DevSeedAccounts` crea PEN + USD, y `done/fx-pnl-education-card:213` ya lo había medido. La segunda era cierta y ya no lo es.
