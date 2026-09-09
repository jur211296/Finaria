---
id: save-error-alert-lies-when-the-context-autosaves
status: backlog
priority: medium
area: "accounts, swiftdata"
created: 2026-09-09
source: review adversarial de changing-an-account-currency-orphans-its-whole-history (2026-09-09)
---

# «No se pudo guardar» aparece después de que los cambios ya estén en el contexto compartido

## Qué le pasa al usuario

Guarda una cuenta, el guardado falla y sale «No se pudo guardar». Pulsa Entendido y cierra. Pero el
Panel, Registros y los widgets ya enseñan los cambios: se le dijo que no se guardó nada y se guardó
todo.

## Lo medido (2026-09-09)

`Yala/App/ViewModels/Accounts/AccountFormViewModel.saveAccount`: si `try context.save()` lanza, se
enciende `isShowingSaveError` y se devuelve `false`, **sin `context.rollback()`**. Es el
`mainContext` compartido —no hay ningún `autosaveEnabled = false` en el árbol— así que las
mutaciones ya hechas se persisten en el siguiente turno del runloop, y los `@Query` de las demás
pantallas cuelgan de ese mismo contexto.

Precedentes de rollback en el repo: `Yala/Services/CloudSync/SyncApplyEngine.swift:199`,
`Yala/App/Services/CategoryDeduplicationService.swift:403,433`.

**Es preexistente** —la forma es la misma desde que existe el formulario— pero desde
`changing-an-account-currency-orphans-its-whole-history` un guardado fallido puede dejar además el
histórico entero de una cuenta ya reexpresado, así que el mensaje engaña sobre mucho más.

Segundo efecto medido en la misma zona: tras un fallo, `allTransactions` conserva modelos que
`InitialBalanceService.setInitialBalance` ya borró del contexto (`:105-107`), y el array no se
recarga. También preexistente.

## Criterio de hecho (AC)

- [ ] Decidido qué hace el formulario cuando `save()` lanza: revertir, reintentar, o cambiar el
      mensaje para que no prometa una atomicidad que no hay. (Ojo: `rollback()` sobre el
      `mainContext` descarta también lo que hayan escrito otras pantallas.)
- [ ] Test que fije la decisión.

## Relacionados

- `changing-an-account-currency-orphans-its-whole-history` — de donde sale la medición.
