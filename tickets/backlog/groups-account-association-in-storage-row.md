---
id: groups-account-association-in-storage-row
status: backlog
priority: high
area: "settings, groups, modo-nube"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §4"
---

# Asociar, ver y desasociar la cuenta de grupos de una sesión privada, en «¿Dónde viven tus datos?»

## Lo que Jürgen quiere (ADR §4)

Un usuario con sesión privada (iCloud) puede **asociar UNA cuenta en la nube para grupos** y
desasociarla cuando quiera. Si su cuenta personal es en la nube, grupos es esa misma cuenta y no se
cambia. La asociación **se ve, se deshace y se rehace** en la fila «¿Dónde viven tus datos?» de
Ajustes, con un copy que diga exactamente qué pasa con los grupos y con los gastos que el bridge metió
en Panel.

## Lo medido (2026-09-09, árbol `3a94604e`)

- Hay UNA sesión nube por dispositivo (`CloudAuthService.shared`) compartida por personal-nube y grupos:
  «una cuenta a la vez» ya es verdad por construcción. Lo que no existe es el **gesto** ni el
  **estado** «asociada a esta sesión privada».
- La fila «Dónde viven tus datos» (`StorageSettingsView.swift`, gate `StorageRowGateLogic.isVisible`,
  `Yala/App/Logic/StorageRowGateLogic.swift:60`) hoy solo habla del almacenamiento personal (iCloud /
  nube, migrar, revertir, estado del sync).
- El sign-in de grupos entra por la pestaña Grupos (`GroupsSignInView`) y no se presenta como
  asociación; el cierre es «Cerrar sesión de grupos» en Ajustes.
- Las filas puenteadas llevan `TransactionItem.splitExpenseID`; `GroupTransactionBridge.unbridgeDeletedRemotely`
  (`GroupsSyncClient.swift:2066`) las borra cuando el gasto de grupo deja de existir en el backend.

## Decisiones tomadas en la conversación (Frank propuso, Jürgen no objetó; se ratifican con el PR)

- **Desasociar:** los grupos **se van con la cuenta** (el store local es caché de la cuenta). Las filas
  puenteadas en Panel **se quedan como movimientos personales normales** —es dinero que pasó—
  conservando su `splitExpenseID` **dormido**: re-asociar la MISMA cuenta re-enlaza en vez de duplicar;
  asociar OTRA cuenta no las toca. Borrarlas dejaría agujeros en los totales de meses cerrados.
- **Asociar una cuenta que ya es completa:** se bloquea (ticket `cloud-sign-in-discovers-account-kind`,
  fila «privada + asociar»).

## Alcance

1. **Estado:** «cuenta de grupos asociada» = hash del `sub` + proveedor + `kind`, escrito al completar
   [G] o al entrar con una `groups_only` existente desde una sesión privada, y borrado al desasociar. Es la
   señal que `session-exits-one-verb-per-session` usa para «equipo». **Viaja con la sesión privada**: se
   persiste en el iCloud-KV del Apple ID (por `OwnerKeyValueStore`, como el faro), no solo en
   `UserDefaults`, para que un segundo móvil o una restauración sepan que existe.
   **Tras «Restaurar desde iCloud»** con asociación registrada, la app ofrece entrar con esa cuenta de
   grupos (la sesión no viaja; la asociación sí).
   **«Migrar a la nube» desde una sesión privada con asociada:** la cuenta que se promueve a `complete`
   es **esa**, nunca una segunda (ADR §4: si la personal es nube, grupos es la misma cuenta).
2. **UI en «¿Dónde viven tus datos?»:** sección «Grupos» con tres estados: *sin cuenta* («Asociar una
   cuenta para grupos» → [I] → [G]), *asociada* (proveedor + nombre, «Desasociar»), y para sesión nube
   completa: «Tus grupos usan esta misma cuenta» sin acción.
3. **Desasociar:** confirmación con copy de alcance (grupos: se van de este móvil, siguen en tu cuenta;
   Panel: tus movimientos se quedan) → `pushAll` de grupos → cerrar sesión nube → vaciar `YalaGroups` →
   dejar las filas puenteadas con el enlace dormido (hoy `unbridge*` las borra: hace falta un camino
   nuevo «detach sin borrar»).
4. **Re-asociar:** [I] → si el `sub` coincide con el enlace dormido, el bridge reconcilia por
   `splitExpenseID` (sin duplicar); si es otra cuenta, las filas dormidas no se tocan y el bridge
   arranca de cero.
5. Grupos desde su pestaña sin cuenta: el CTA lleva al mismo [I] → [G] y escribe la asociación.

## Criterios de aceptación

- [ ] Sesión privada sin cuenta → asociar Google → [G] → la fila muestra la cuenta; los grupos aparecen.
- [ ] Desasociar con 3 gastos puenteados en Panel → los 3 siguen en Panel sin marca de grupo; los grupos
      desaparecen de la pestaña; la cuenta sigue viva en el backend.
- [ ] Re-asociar la misma cuenta → 0 duplicados, los 3 vuelven a estar enlazados a su gasto de grupo.
- [ ] Asociar otra cuenta → los 3 quedan como estaban; los grupos nuevos llegan limpios.
- [ ] Sesión nube completa → la sección informa y no ofrece desasociar.
- [ ] Segundo móvil del mismo Apple ID → «Restaurar desde iCloud» → tras restaurar, ofrece entrar con la
      cuenta de grupos asociada; al entrar, los grupos aparecen y el bridge re-enlaza sin duplicar.
- [ ] «Migrar a la nube» desde D → la asociada pasa a `complete` (backend), sin segunda cuenta.
- [ ] Tests: lógica de reconciliación por `splitExpenseID` (unit, con fixture que tenga filas dormidas
      y vivas); XCUITest de la fila en sus tres estados.

## Depende de

`cloud-sign-in-discovers-account-kind` · `backend-account-kind-complete-or-groups-only`.
