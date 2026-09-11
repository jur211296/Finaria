---
id: detach-failure-looks-like-success
status: backlog
priority: high
area: "settings, groups, modo-nube"
created: 2026-09-11
source: "review adversarial de `detach-history-replay-can-tombstone-groups-on-next-launch` (lentes de contrato y de producto)"
---

# Si el desasociar falla al borrar, la app dice que lo soltó y no avisa de nada

## El problema, en lenguaje de usuario

Toco «Desasociar» en Ajustes → «¿Dónde viven tus datos?» → Grupos. La pantalla me dice que ya no hay cuenta
asociada. Pero si el borrado local falló, **mis grupos siguen enteros en el teléfono** —la pestaña Grupos,
los gastos, todo— y nadie me lo dice. La app y el teléfono cuentan cosas distintas, y la que se equivoca es
la app.

## Lo medido (2026-09-11)

`CloudSessionSignOut.purgeGroupsDomainForDetach` traga el error (solo lo imprime bajo `#if DEBUG`) y
`detachGroupsAccount` sigue adelante: `GroupsAccountAssociation.shared.clear()`,
`GroupsSessionHistoryMarker.markSessionSeen()`, `WidgetDataCache.updateCache` y `phase = .idle`. La UI
(`GroupsAssociationSection`) solo muestra aviso cuando la fase queda en `.blocked`, así que `.idle` se lee
como éxito.

Estado resultante: **sesión de grupos cerrada + asociación borrada + todas las filas `Split*`, el outbox y
el cursor intactos**, sin un solo mensaje. Y como el borrado es una sola transacción con rollback, el fallo
es todo-o-nada: no queda a medias, queda **entero**, que es justo lo que la pantalla niega.

No es regresión: el comportamiento es el mismo desde el paso 10.

## El contraste que enseña la salida

Su hermano, el «Empiezo de cero» del Welcome, sí lo hace bien: `ShellDataAlertsModifier` envuelve la llamada
en `do/catch`, enseña el alert de fallo, **no navega** al onboarding y dispara el canario
`MetricsService.canary(.freshStartWipeFailed)`. El desasociar necesita las tres cosas.

## Lo que se espera

1. `purgeGroupsDomainForDetach` propaga en vez de tragar (o devuelve un veredicto).
2. `detachGroupsAccount` **no** sigue a `clear()` si el borrado falló: la asociación tiene que seguir en pie,
   porque los datos siguen en pie. Ojo con el orden — la sesión en la nube ya se cerró en ese punto, así que
   hay que decidir qué se le ofrece: reintentar el borrado, o rehacer la asociación.
3. Un aviso propio de esta pantalla, del molde del de «No pudimos soltar la cuenta», y su canario.

## Cómo se prueba

Con el seam de UITest que ya existe para el wipe (`-uitest-fail-wipe`, `UITestHooks.shouldFailWipeNow`) o uno
equivalente para este camino; unit del veredicto + XCUITest del aviso.
