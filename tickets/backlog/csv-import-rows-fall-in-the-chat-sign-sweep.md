---
id: csv-import-rows-fall-in-the-chat-sign-sweep
status: backlog
priority: high
area: "data, import"
created: 2026-09-08
source: review adversarial de chat-rows-with-unsigned-amount-have-no-repair-path (2026-09-08)
---

# El barrido del signo del chat también alcanza a lo que se importó por CSV, y eso no es lo que se aceptó

## La decisión que hay que revisar

Jürgen aprobó el 2026-09-08 migrar a ciegas el corpus del chat, **aceptando expresamente un daño
concreto**: «los reembolsos legítimos en esa ventana también se voltean». La review adversarial midió
que el criterio alcanza a más que eso, y el resto no cae bajo esa frase.

## Lo medido (2026-09-08, en este árbol)

**1. Una fila importada por CSV/XLSX toma como `createdAt` el instante del import, no la fecha de sus
datos.** Los cuatro sitios de creación de `Yala/Utils/TransactionCSVImportService.swift` (`:187`,
`:1107`, `:1502`, `:1663`) **no asignan `createdAt`**, así que toma el default `Date.now`. Las cuatro
apariciones de `createdAt` en ese fichero son lecturas (`$0.createdAt >= importStart`), lo que además
confirma la semántica: el propio importador lo usa como «cuándo se importó».

⇒ **Un CSV con años de historia importado dentro de la ventana entra ENTERO en el criterio**, sin que
importe la columna `date`.

**2. El importador reusa categorías por nombre sin mirar `isIncome`.** En modo estricto
(`TransactionCSVImportService.swift:492-508`) busca por nombre con un `#Predicate` que solo compara
`cat.name`, y su propio comentario lo dice: «sin filtrar por isIncome para soportar categorías
"neutrales" como "Otros"». Ése es además **el modo por defecto**
(`ImportIntroSheet.swift:104`: `allowCreatingNewCategories = false`). El modo permisivo hace lo mismo
(`CategoryImportHelper.swift:45-66`).

**3. Ninguna de esas filas lleva marcador de sistema.** El importador solo escribe
`balanceAdjustmentType` cuando la subcategoría `isAnySystem` (`:203`), que compara contra 16 cadenas
literales de «Ajuste de saldo» y «Transferencia entre cuentas». Una subcategoría normal no lo es.

## Qué le pasa al usuario

Dos formas, y **la segunda no es un reembolso bajo ninguna lectura**:

1. Un abono archivado bajo la categoría de gasto que compensa (devolución, cashback). El barrido lo
   voltea y el saldo se mueve el doble, en la dirección contraria. Esto sí cae dentro de lo aceptado.
2. **Un ingreso cuyo nombre de categoría colisiona con una de gasto.** «Otros», «Salud»,
   «Educación» y «Viajes» están sembradas con `isIncome: false`. Una fila
   `2026-05-10, 1500.00, PEN, Otros, Bonificación` se cuelga de la «Otros» de gasto, y el barrido la
   deja en −1500. Es un ingreso convertido en gasto.

El cambio es silencioso y solo se deshace editando fila a fila.

## Por qué no se resolvió en el PR del barrido

Porque **no hay señal estructural que separe una fila del chat de una del CSV** — que es el corazón
del ticket padre: `TransactionItem` no tiene campo de origen. Las alternativas evaluadas (acotar
también por `date`, o por la distancia entre `date` y `createdAt`) son heurísticas frágiles: el chat
admite dictar «un café en marzo» y un CSV puede traer fechas recientes.

## Qué necesita decidir Jürgen

- **¿Se acepta también este daño?** Es más ancho que el que aprobó, y su tamaño depende de si ha
  importado CSV/XLSX desde el 2026-04-27.
- **¿O se acota el barrido de otra forma?** Por ejemplo, no volteando filas cuya `date` diste mucho de
  su `createdAt` (que es la firma de un import histórico) — con el coste de perder alguna del chat.
- **¿O se arregla antes el importador**, para que estampe `createdAt` coherente y no reuse categorías
  de la naturaleza contraria? Eso es un arreglo bueno por sí mismo, pero no cura lo ya importado.

## Criterio de hecho (AC)

- [ ] Decisión de Jürgen sobre las tres salidas.
- [ ] Si se acota: criterio nuevo con test que fije qué sobrevive.
- [ ] Ticket aparte para que el importador estampe `createdAt` y valide la naturaleza de la categoría.
