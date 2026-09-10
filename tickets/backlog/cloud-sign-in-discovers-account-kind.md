---
id: cloud-sign-in-discovers-account-kind
status: backlog
priority: high
area: "modo-nube, onboarding, groups"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §7 — el bloque [I]"
---

# Un solo bloque de identidad en la nube: todo sign-in descubre si la cuenta es nueva, completa o solo grupos, y rutea

## El problema, en lenguaje de usuario

Tengo una cuenta de Yala completa en la nube. Cambio de móvil y, como lo que quiero es ver un grupo,
entro por «Vengo por un grupo». Yala me trata como si solo tuviera grupos: sin Panel, sin mis cuentas,
sin avisarme de que mi cuenta tiene todo eso. Al revés también: entro por «Ya tengo cuenta → Google»
con una cuenta que solo usé para grupos y Yala me adopta como completa. Y si no tengo cuenta, «Ya tengo
cuenta» me dice «No encontramos una cuenta» y me deja mirando un botón de volver.

## Lo medido (2026-09-09, árbol `3a94604e`)

- El único sitio que pregunta al backend si la cuenta existe es `WelcomeCloudSignInView.runSignInFlow`
  (`Yala/App/Views/Onboarding/WelcomeCloudSignInView.swift:730-800`): `CloudAccountClient().exists` en
  `:743`, fase `.notFound` en `:764` con copy «Este Apple ID aún no tiene una cuenta Yala en la nube» y
  solo «volver» (`messageContent`, `:634-651`, sin acción).
- La rama «Vengo por un grupo» firma con `GroupsSignInView` (`Yala/App/Views/Groups/GroupsSignInView.swift`,
  192 líneas: botones Apple/Google → `CloudAuthService.signIn`, nada más) y sigue por
  `GroupsGateLogic.nextStep` (`Yala/App/Logic/GroupsGateLogic.swift`): consentimiento → nombre → grupo.
  Ninguna consulta al backend sobre la cuenta.
- El alta born-cloud (`runBornCloudFlow`, `:697-726`) ya distingue «existía» (`.continueAsReturningUser`)
  de «nueva» (`.activateStorageAndRelaunch`) — es la mitad del bloque que ya está.

## Lo que se espera (ADR §7)

**[I]** = Apple/Google → `¿existe? + kind` → uno de tres resultados **excluyentes**: *nueva* /
*completa* / *solo grupos*. **Todo** sign-in en la nube pasa por [I], y cada puerta declara qué hace
con cada resultado:

| Puerta | nueva | completa | solo grupos |
|---|---|---|---|
| Primera vez → nube | crear (`kind=complete`) → [P] | = «Ya tengo cuenta» (adopta) | entra solo-grupos y ofrece «Activar Yala completo» |
| Ya tengo cuenta → Apple/Google | «No hay cuenta» **con botón** a «Primera vez → nube» | adopta y entra | entra solo-grupos |
| Vengo por un grupo (crear / invitación) | crear (`kind=groups_only`) → [G] → grupo / unirse | entra completa y abre Grupos (y la invitación, si la había) | entra y sigue a [G] o a unirse |
| Privada + asociar grupos (desde Grupos **o al llegar una invitación**) | crear (`groups_only`) → [G] → asociada (→ unirme) | **bloquea**: «esa cuenta ya tiene Yala completo» + dos salidas: «Ya tengo cuenta» / «asociar otra cuenta» | [G] si falta → asociada (→ unirme) |
| Privada → Ajustes «migrar a la nube» | cutover existente → nube completa | **bloquea** (sería una fusión): salidas «Ya tengo cuenta» (reemplaza lo privado) / cancelar | es mi asociada → **promover** + cutover; otra → bloquear (una cuenta a la vez) |

## Alcance

1. Extraer de `WelcomeCloudSignInView` la parte «firmar → exists+kind → guard cross-cuenta» a un
   componente reusable (vista + `CloudWelcomeSignInFlow` ampliado con `kind`), y que `GroupsSignInView`
   lo use en vez de firmar a pelo. El consentimiento y el resto del recorrido de grupos no cambian.
2. La tabla de arriba como lógica pura testeable (`enum`, entrada: puerta × resultado × ¿hay sesión
   privada? → destino).
3. `.notFound` en «Ya tengo cuenta» gana un botón primario que lleva a «Primera vez → nube» con el
   proveedor ya elegido (no un callejón).
4. El bloqueo del flujo «privada + asociar → completa» con copy propio y sus dos salidas.
5. «Completa» entrando por grupos: adopta como en «Ya tengo cuenta» (mismo `CrossAccountEntryGuardLogic`)
   y aterriza en la pestaña Grupos con la invitación pendiente re-emitida (`reEmitInviteAfterRestore`
   ya existe para el restore de iCloud).

## Criterios de aceptación

- [ ] Las 15 celdas de la tabla tienen test unitario sobre la lógica pura.
- [ ] Invitación (link) con sesión privada y sin cuenta asociada → [I] → asociada → hoja «unirme»; con
      una cuenta completa → bloqueo, la invitación sigue pendiente en `PendingJoinStore`.
- [ ] En staging: cuenta completa entrando por «Vengo por un grupo» → app completa, pestaña Grupos.
- [ ] Cuenta solo-grupos entrando por «Ya tengo cuenta → Google» → solo-grupos (no adopción).
- [ ] Cuenta inexistente por «Ya tengo cuenta» → pantalla con botón que lleva al alta; el alta crea.
- [ ] Sesión privada + asociar una cuenta completa → bloqueo con las dos salidas; ninguna escritura.
- [ ] `WelcomeCloudSignInView` conserva byte-idéntico el guard cross-cuenta y el provider-mismatch (sus
      tests actuales siguen verdes).

## Cómo se prueba

Unit (lógica pura + `CloudWelcomeSignInFlowTests`), XCUITest del chooser con el seam
`-uitest-cloud-chooser`, y device-QA contra staging para los cuatro recorridos con cuentas reales.

## Depende de

`backend-account-kind-complete-or-groups-only`.

## Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)

Preguntadas una a una antes de soltar la cola autónoma. **Mandan sobre lo escrito arriba.**

- **La adopción de una cuenta completa entrando por «Vengo por un grupo» es SILENCIOSA.** Sin aviso, sin
  banner y sin preguntar: entra completa y aterriza en Grupos, tal cual dice el ADR §7. No añadas
  ceremonia «por prudencia» — es una decisión tomada con el riesgo delante (alguien que solo quería ver
  un grupo se encuentra sus finanzas en ese móvil); el guard cross-cuenta sigue siendo la única red.
- **`.notFound` en «Ya tengo cuenta» lleva DIRECTO AL CONSENTIMIENTO** de nube con el proveedor ya
  firmado; no repite el chooser de proveedor. El consentimiento **no se salta** (es el único paso que no
  se recorta). Si el usuario quiere otro proveedor, retrocede.
- **`GroupsSignInView` cambia de motor, no de aspecto.** Por dentro usa el componente [I]; por fuera la
  puerta de Grupos se sigue viendo como hoy, con su tono de mini-app. Si algún día debe unificarse
  visualmente, eso es del ticket 12, no de éste.
- **Tests: las 15 celdas de la tabla + los bordes donde «hay sesión privada» cambia el destino**
  (asociar, migrar a la nube, los dos bloqueos). No hace falta escribir las 30 combinaciones ni afirmar
  las imposibles; sí hace falta que el eje «sesión privada sí/no» quede cubierto donde decide algo.
