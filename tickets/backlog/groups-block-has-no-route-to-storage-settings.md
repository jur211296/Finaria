---
id: groups-block-has-no-route-to-storage-settings
status: backlog
priority: low
area: "onboarding, groups, settings"
created: 2026-09-10
source: "medido durante `cloud-sign-in-discovers-account-kind` (bloque [I])"
---

# La segunda salida del bloqueo de Grupos es texto, porque no hay forma de navegar a Ajustes

## El problema, en lenguaje de usuario

Tengo mi Yala privado y quiero asociar una cuenta para grupos. Entro con una cuenta que ya lleva Yala
completo y Yala me lo bloquea bien: me explica por qué y me deja usar otra cuenta. Pero la otra salida
—«si quieres que esa cuenta lleve tus finanzas, se decide en Ajustes»— me la dan **escrita**, y me toca
encontrar la pantalla yo.

## Lo medido (2026-09-10, árbol `8964c734`)

La fila «¿Dónde viven tus datos?» se alcanza **solo** por `NavigationLink(value: ProfileDestination.storageMode)`
(`Yala/App/Views/Profile/ProfileView.swift:983` y `YalaAccountView.swift:149`). **No existe ningún
`RouterIntent`** que navegue hasta ahí: `Yala/App/Models/RouterIntent.swift` no tiene ningún caso de
Ajustes, y tampoco hay deep link (`yala://settings…` no existe).

Por eso el ADR pide dos salidas y el bloqueo entrega una como botón
(`GroupsAccountIsCompleteBlockView.onUseAnotherAccount`) y la otra como instrucción exacta
(`L10n.Groups.AccountIsComplete.settingsHint`). Mandar a la persona con la instrucción es mejor que un
botón que no lleva a donde dice, pero es media salida.

## Lo que se espera

Un intent de router que abra Ajustes en la fila de almacenamiento, y el botón que lo use. Sirve además
a los tickets 8, 9 y 10, que mandan al usuario a esa misma fila desde otras pantallas.

## Criterios de aceptación

- [ ] `RouterIntent` gana un caso que abre Ajustes → «¿Dónde viven tus datos?», drenado por `ContentView`.
- [ ] Entra en la matriz de readiness si presenta algo del anchor de `ContentView`.
- [ ] El bloqueo de Grupos cambia su instrucción por un botón real.
- [ ] Un XCUITest recorre botón → fila de almacenamiento.
