---
id: chat-draft-sign-can-contradict-its-subcategory
status: backlog
priority: medium
area: "chat"
created: 2026-09-08
source: review adversarial de chat-draft-drops-the-expense-sign (2026-09-08)
---

# Un borrador del chat puede nacer marcado «gasto» con una subcategoría de ingreso

## Qué le pasa al usuario

Dicta algo ambiguo, el chat le propone un borrador marcado **Gasto** pero con una subcategoría de
**ingreso** —porque la eligió por el comercio, no por el tipo—, y lo guarda. La transacción entra
como un «ingreso negativo»: **resta** del total de ingresos en Registros, Estadísticas y flujo de
caja, mientras el widget de la pantalla de inicio la suma. **La app y el widget dicen cosas distintas
de la misma fila.**

## Por qué aparece ahora (medido el 2026-09-08, en este árbol)

Este estado ya se podía alcanzar antes, pero era **inofensivo**: hasta el fix de
`chat-draft-drops-the-expense-sign` el chat guardaba todo en positivo, así que un borrador marcado
gasto con categoría de ingreso acababa como un ingreso normal y coherente. Al firmar el monto, ese
mismo desajuste pasa a producir la combinación «signo contrario a su categoría», que
`TransactionClassificationLogic` trata **a propósito** como un reembolso:

> «un monto de signo contrario a su categoría se trata como reembolso/corrección y REDUCE el bucket,
> no como magnitud absoluta»

El fix no crea el desajuste; le quita el disfraz.

## Dónde se origina

`DraftBuilder` tiene dos vías para elegir subcategoría y solo una respeta el tipo:

- **La vía con hint** (`matchSubcategoryByHint(hint:isExpense:)`) **sí** filtra por naturaleza.
- **El fallback por comercio** no:

```swift
static func suggestSubcategory(merchant: String, context: ModelContext) -> Subcategory? {
    …
    switch service.suggest(for: trimmed) {
    case .suggest(let sub), .autoAssign(let sub):
        return sub          // ← sin contrastar con parsed.isExpense
```

Y nada lo detiene después: la validación de naturaleza de `ChatAssistantViewModel.updateDraft` solo
corre si el usuario **cambia** la subcategoría a mano, y el filtro del card limita el **menú**, no lo
que ya viene puesto. Como el prompt del parser dice «por defecto asume gasto», el texto ambiguo
aterriza en `isExpense: true` con la subcategoría que dictó la memoria de comercios.

## Lo que NO se midió

Con qué frecuencia pasa de verdad. Requiere una memoria de comercios que apunte a una subcategoría de
ingreso y un texto cuyo hint no case — estrecho, pero alcanzable, y el daño es silencioso.

## Criterio de hecho (AC)

- [ ] `suggestSubcategory` no devuelve una subcategoría cuya naturaleza contradiga `isExpense`, o
      `saveDraft` rechaza la combinación incoherente en vez de persistirla.
- [ ] Decidido quién manda cuando discrepan: la intención del usuario (`isExpense`) o la categoría.
- [ ] Test con la combinación cruzada.
