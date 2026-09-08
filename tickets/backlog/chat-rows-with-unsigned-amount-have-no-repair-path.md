---
id: chat-rows-with-unsigned-amount-have-no-repair-path
status: backlog
priority: high
area: "chat, data"
created: 2026-09-08
source: hallazgo de camino en chat-draft-drops-the-expense-sign (2026-09-08)
---

# Las transacciones que el chat ya guardó sin signo siguen rotas, y nada las cura

## Qué le pasa al usuario

`chat-draft-drops-the-expense-sign` arregló la ruta **hacia delante**: desde el 2026-09-08 un gasto
dictado al chat se guarda firmado. Las que ya se guardaron siguen ahí con el monto positivo, y siguen
inflando el saldo, la curva y los totales — para siempre, salvo que el usuario las edite a mano una
a una.

## La ventana afectada

`saveDraft` nació el **2026-04-27** (`52d2ad6b`, «feat(chat): registrar transacciones desde Yala IA
con cards inline») y guardó sin firmar hasta el fix. Son **cuatro meses y medio** de filas, y
TestFlight build 12 está dentro. Cada gasto dictado al chat en esa ventana es una fila afectada.

## Por qué no se curan solas (medido el 2026-09-08 en este árbol)

Ninguno de los cinco mecanismos que tocan estas columnas corrige el signo:

1. **`TransactionItem.recalculatePreferredCurrency`** nunca asigna `self.amount` — es puramente
   derivador. Y como alimenta el converter con `Decimal(amount)`, **propaga** el signo malo a
   `amountInPreferredCurrency`. Pasar una fila del chat por él la deja igual de rota.
2. **El reparador de arranque** (`TransactionUpdateService`) filtra por
   `isExchangeRateProvisional == true`, y estas filas se sellaron con `false` cuando la tasa era
   exacta — el caso normal.
3. **`TransactionService`** preserva el signo existente a propósito:
   `let sign: Double = transaction.amount < 0 ? -1 : 1`.
4. **`RecordsViewModel`** (edición masiva de monto) hace lo mismo:
   `transaction.amount < 0 ? -abs(amount) : abs(amount)`.
5. **`CloudSyncReconciler`** lo dice en su propio comentario: «El SIGNO del perdedor se PRESERVA,
   nunca se corrige».

## Lo que hace difícil la migración, y es la decisión

**`TransactionItem` no tiene campo de origen.** No hay `source`, `origin` ni `createdVia`: una fila
guardada por el chat es indistinguible en el store de una escrita a mano. Lo único que las señala es
la incoherencia «categoría de gasto + monto positivo»…

…y **esa forma también la tiene un dato legítimo**. `TransactionClassificationLogic` lo documenta como
comportamiento intencionado: «un monto de signo contrario a su categoría se trata como
reembolso/corrección y REDUCE el bucket, no como magnitud absoluta». El seed de desarrollo siembra
justamente esa forma como fixture (`DevSeedTransactions`, `insert(amount: -100, sub: salary)` con el
comentario `// DESYNC: categoría income, monto NEGATIVO`).

⇒ **Un barrido que le dé la vuelta al signo de toda fila «gasto positiva» destruiría los reembolsos
que el usuario registró a propósito.** No es un caso teórico: es semántica documentada de la app.

## Qué necesita decidir Jürgen

1. **¿Se migra?** Las tres salidas, y ninguna es obviamente la buena:
   - **No migrar.** Las filas viejas quedan mal para siempre. Es lo más seguro y lo más insatisfactorio.
   - **Migrar a ciegas** (toda fila con categoría de gasto y monto positivo). Cura el corpus del chat
     y **rompe los reembolsos legítimos**, sin poder distinguirlos.
   - **Ofrecérselo al usuario**: una pantalla que liste las filas sospechosas y le deje decidir. Es la
     única que no adivina, y la que más trabajo cuesta.
2. Si se migra: **¿se acota por fecha?** La ventana `2026-04-27 → build del fix` reduce el daño
   colateral pero no lo elimina — un reembolso registrado a mano dentro de esa ventana cae igual.

## Lo que NO se midió

Cuántas filas hay realmente afectadas en el dispositivo de Jürgen o en TestFlight. Se puede acotar
antes de decidir: contar en un store real las transacciones con `category.isIncome == false` y
`amount > 0` creadas después del 2026-04-27, para saber si esto son tres filas o trescientas.

## Una trampa para quien haga la migración

**Cambiar el signo de una fila cambia su ancla de contenido.** `SyncContentAnchor.canonicalAmount` es
`String(describing: amount)`, sin `abs()`, así que dos filas idénticas salvo el signo hashean distinto.
Hoy da igual —la captura de identidad está apagada en producción— pero un barrido que corrija el signo
de filas viejas les cambiará el ancla, y con ella el rebind por ancla del backfill de sync. Quien lo
implemente tiene que mirar eso antes, no después.

## Criterio de hecho (AC)

- [ ] Decisión de Jürgen registrada sobre las tres salidas de arriba.
- [ ] Si se migra: barrido con la forma de `repairLegacyOneToOneRatesIfNeeded` (one-shot con flag en
      defaults), negando `amount` **y** `amountInPreferredCurrency` — `recalculatePreferredCurrency`
      no sirve, propaga el signo.
- [ ] Test que demuestre que un reembolso legítimo **sobrevive** al barrido.
