---
id: detach-does-not-verify-the-cloud-session-actually-closed
status: backlog
priority: medium
area: "modo-nube, groups"
created: 2026-09-11
source: "review adversarial del paso 10 (`groups-account-association-in-storage-row`), lente de sync"
---

# El desasociar no comprueba que la sesión en la nube se cerró de verdad

## Lo medido (2026-09-11)

`CloudAuthService.signOut()` envuelve `client.signOut(scope: .local)` en un `do/catch` que **solo
loguea**. Los demás caminos que lo llaman se lo pueden permitir porque acaban en `armSignOutWipe` +
relanzamiento; `detachGroupsAccount` no.

Si la sesión sobrevive al `signOut()`: en el siguiente foreground `startIfEligible` pasa su
`sessionCheck()`, arranca el loop, y como el cursor se purgó **vuelve a bajar el corpus entero** que el
desasociar acaba de borrar. La asociación ya está limpia, así que el libro de conservados no casa y todo
se re-puentea: duplicados junto a los movimientos que el usuario decidió conservar. Estado final peor que
el inicial, y sin ningún aviso.

**Sospecha parcialmente verificada**: el hueco del `catch` y la ausencia de postcondición están medidos;
lo que no se midió es si `supabase-swift` puede lanzar dejando `currentSession != nil`.

## Lo que se espera

Una postcondición antes del punto de no retorno:
`guard !CloudAuthService.shared.hasSession else { phase = .blocked(…); return }`. Con el sign-out fallido,
el desasociar se detiene y se puede reintentar, en vez de dejar el dispositivo a medias.
