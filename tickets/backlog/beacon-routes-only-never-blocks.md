---
id: beacon-routes-only-never-blocks
status: backlog
priority: medium
area: "modo-nube, onboarding"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §10"
---

# El faro de iCloud-KV solo encamina: nunca impide crear otra cuenta con otro usuario

## El problema, en lenguaje de usuario

Este Apple ID ya tuvo una cuenta de Yala en la nube (con Apple). Ahora quiero crear otra con mi
Google, por la razón que sea. «Es mi primera vez» no me deja elegir nada: me manda a entrar con la
cuenta de Apple. Y si voy por «Ya tengo cuenta → Google», Yala me dice «Esa cuenta usa otro método —
vuelve atrás y entra con Apple». No hay forma de crear la segunda cuenta desde este móvil.

## Lo que Jürgen decidió (ADR §10)

El faro **encamina, nada más**: si el Apple ID ya tiene cuenta en la nube, «Primera vez» propone
entrar con ella. Pero el usuario **conserva la libertad de crear otra cuenta con otro proveedor u
otro usuario**.

## Lo medido (2026-09-09, árbol `3a94604e`)

- `WelcomeAccountChoiceLogic.routeNewBranch` (`Yala/App/Logic/WelcomeAccountChoiceLogic.swift`): con
  `beaconLinked && cloudEntryAvailable` devuelve `.cloudSignIn(provider)` **antes** del chooser ⇒ la
  elección privado/nube ni se muestra. Motivo escrito (A26, 2026-08-09): que un nacido-en-nube no
  arranque un dataset privado divergente en su segundo móvil.
- `ProviderMismatchLogic.decide` (`Yala/App/Logic/ProviderMismatchLogic.swift`): con la cuenta
  inexistente, faro puesto y sub distinto ⇒ `.mismatch` ⇒ pantalla «Esa cuenta usa otro método» y
  `signOut`, sin camino hacia el alta. Copy en `welcome.cloud.providerMismatch*`.
- `Sign in with Apple` solo ofrece el Apple ID del teléfono, así que «otro Apple» no se plantea aquí;
  el caso real es **Google** (u otro usuario en general).

## Alcance

1. **«Primera vez» con faro:** encaminar sigue siendo el default, pero la pantalla de sign-in a la que
   llega tiene que ofrecer **«Crear otra cuenta»** (vuelve al chooser privado/nube con la card nube
   activa) además de «Entrar con Apple». El texto dice de dónde viene: «Este Apple ID ya tiene una
   cuenta de Yala con Apple».
2. **Provider mismatch:** deja de ser una pared. Con cuenta inexistente y proveedor distinto al del
   faro, la pantalla informa («Tu cuenta de Yala se creó con Apple») y ofrece las DOS salidas:
   «Entrar con Apple» y «Crear una cuenta con Google» (→ «Primera vez → nube» con Google preelegido,
   que pasa por [I] y crea).
3. El faro se sigue escribiendo y leyendo igual (`CloudBeacon`); no cambia su semántica ni su wire. Con dos
   cuentas creadas desde el mismo Apple ID guarda la **última reclamada**: encamina a esa y sigue
   ofreciendo «crear otra». No se guardan dos.
4. Ticket relacionado que NO se resuelve aquí: `restore-beacon-outlives-account-deletion` (el faro
   puede sobrevivir al borrado de cuenta; con «solo encamina» su daño baja, pero el mensaje bajo el
   kill-switch sigue afirmando de más).

## Criterios de aceptación

- [ ] Con faro puesto, «Primera vez» encamina y la pantalla de destino tiene «Crear otra cuenta».
- [ ] «Crear otra cuenta» → chooser → nube → Google → [I] `nueva` → se crea una segunda cuenta
      (`kind=complete`) sin tocar la primera.
- [ ] Provider mismatch ofrece entrar con el proveedor del faro o crear con el elegido; ninguna de las
      dos deja al usuario con solo «volver».
- [ ] `WelcomeAccountChoiceLogicTests` y `ProviderMismatchLogicTests` actualizados: el resultado
      `.cloudSignIn` sigue existiendo; `.mismatch` lleva ahora las dos salidas.

## Cómo se prueba

Unit sobre las dos lógicas puras; device-QA con un Apple ID que ya tiene faro (el de Jürgen lo tendrá
tras el primer alta en nube) y una cuenta Google nueva.

## Depende de

`cloud-sign-in-discovers-account-kind` (para que «crear con Google» pase por [I]).
