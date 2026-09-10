---
id: no-test-seam-for-account-exists-blocks-xcuitest-of-identity
status: backlog
priority: medium
area: "testing, modo-nube, onboarding"
created: 2026-09-10
source: "medido durante `cloud-sign-in-discovers-account-kind` (bloque [I])"
---

# El bloque de identidad en la nube no tiene cobertura XCUITest, y no es por falta de tests

## El problema

Las quince celdas del bloque [I] están probadas como lógica pura, pero **ningún XCUITest recorre una
sola de ellas de punta a punta**. No es una decisión de esfuerzo: hoy es **inalcanzable**.

## Lo medido (2026-09-10, árbol `8964c734`)

- **No existe ningún seam que stubee `GET /account/exists`.** `CloudAccountClient` acepta un
  `urlSession` inyectable (y los unit tests lo usan), pero **no hay ningún launch argument** que lo
  cablee: `Yala/App/UITestHooks.swift` no tiene ni una ocurrencia de `exists`, `accountKind` ni
  `gateway`.
- **El sign-in real jamás se tapea en XCUITest**, y está declarado en la cabecera de
  `YalaUITests/Flows/WelcomeChooserUITests.swift:8-9`. Sus cuatro tests llegan a la pantalla de intro
  y paran ahí.
- `-uitest-cloud-chooser` (`UITestHooks.swift:53`) **sí existe** y destapa las cards de nube del
  chooser, así que la mitad de camino está hecha: lo que falta es fingir la identidad y la respuesta.
- `-uitest-fake-cloud-session` (`:91`) ya finge la sesión. Lo que no hay es cómo fingir **qué contesta
  el backend sobre esa cuenta**.

## Lo que se espera

Un seam que permita a un XCUITest declarar el resultado de `exists` —`nueva` / `completa` / `solo
grupos` / `sin red`— para recorrer las celdas de [I] sin red ni SIWA reales. Con eso, las cuatro celdas
que hoy solo verifica el owner en device pasan a ser deterministas.

## Criterios de aceptación

- [ ] Un launch argument declara el resultado de `exists`, y `CloudAccountClient` lo respeta **solo**
      bajo `-uitest` (jamás un camino de producción que pueda mentir sobre una cuenta real).
- [ ] XCUITest: «Ya tengo cuenta» + cuenta inexistente → la pantalla con su botón al alta.
- [ ] XCUITest: «Ya tengo cuenta» + cuenta solo-grupos → no adopta.
- [ ] XCUITest: privada + asociar una cuenta completa → el bloqueo, y ninguna de las keys de la puerta
      de Grupos queda escrita.
- [ ] El área `cloud-born-cloud-signup` de `qa/coverage-index.json` deja de ser `manual` en la parte
      que este seam cubre, y el ratchet baja.
