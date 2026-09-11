---
id: groups-invite-on-a-mirrored-store-crosses-data
status: backlog
priority: high
area: "modo-nube, groups"
created: 2026-09-11
source: "mitad 2 de `groups-entry-on-a-mirrored-store-still-blocks-the-owner` (2026-09-11): la rama de CREAR quedó cerrada; la de INVITACIÓN necesita dos piezas que ni ese ticket ni el paso 9 dejan hechas"
---

# Aceptar una invitación sobre un teléfono que ya espeja iCloud manda los gastos del invitado al iCloud del dueño

## El síntoma, en lenguaje de usuario

Presto el móvil, o lo compro de segunda mano, o simplemente entré antes por «privado» y no terminé. El
teléfono ya bajó datos de iCloud. Ahora alguien me pasa un enlace de invitación a un grupo, lo acepto y
empiezo a anotar gastos compartidos. **Esos gastos acaban en el iCloud de la otra persona**, porque el
espejo del store personal sigue adjunto y el bridge de Grupos escribe en él.

Nadie ve nada raro: no hay pantalla de error, ni aviso, ni bloqueo. Se ve en el otro dispositivo del
dueño, días después.

## Por qué no se cerró con la rama de CREAR (medido el 2026-09-11)

La mitad 2 de `groups-entry-on-a-mirrored-store-still-blocks-the-owner` cerró «Crear mi primer grupo»:
la puerta del Welcome vuelve al neutro antes de dejar pasar. La invitación **no pasa por esa puerta** y
cubrirla exige dos piezas de infraestructura, no cableado:

1. **No hay punto de interposición con una persona delante.** Las dos entradas —el universal link
   (`AppBootstrapper.handleInviteLink`) y la card «Tengo una invitación», que empalma en el mismo método
   desde `ContentView`— convergen en `GroupBackendInviteEntryHandler.drive`, y **a ése también lo llama
   el reconciler en el trigger `.boot`** (`GroupJoinReconciler`). Interponer ahí la vuelta al neutro
   sería borrar el corpus de alguien **en el arranque y sin pantalla**, que es justo lo que el ADR
   2026-09-09 prohíbe. Hacerlo con pantalla pide un `RouterIntent` nuevo que atraviese la matriz de
   readiness (regla 3 de Presentaciones).
2. **El intent de la invitación NO sobrevive al borrado.** `PendingJoinStore` guarda una sola key,
   `"yala.groups.pendingJoins"`, que el barrido de `DataWipeService.removeUserPreferenceKeys` **no
   toca** —comprobado— pero que muere igual por la cadena `resetForSignOutWipe` → `resetAllUserPreferences`
   → `AppRouter.resetAll()` → `PendingJoinStore.clearAll()`. Sin una superficie durable nueva, el
   invitado reabre la app **sin su invitación**: el camino muerto, movido un paso más adelante.

## Lo que sí está medido a favor de tratarlo aparte

La rama de invitación **no tiene ningún término de corpus** —ni `GroupsGateLogic.nextStep`, ni
`GroupBackendInviteEntryLogic.nextStep`, ni `InviteRecoveryView`—, así que **nunca bloqueó a nadie**: el
síntoma del ticket padre (el dueño atrapado) no la toca. Lo que queda abierto es solo el cruce de datos,
y es **preexistente**: el PR de la mitad 2 no lo agrava.

## Criterios de aceptación

- [ ] Enlace de invitación aceptado sobre un store con espejo → antes de entrar al grupo, el dispositivo
      vuelve al neutro (espera el export, borra lo local, iCloud intacto) y **la invitación sobrevive** al
      relanzamiento: al reabrir, la hoja «unirme» sale sola.
- [ ] La vuelta al neutro **nunca** se dispara sin pantalla: el trigger `.boot` del reconciler no puede
      borrar nada por su cuenta.
- [ ] Un invitado en un teléfono neutro (instalación fresca) no paga ninguna pantalla de más.
- [ ] Lo que el dueño escribió y no llegó a subir no se pierde.

## Por dónde va

Reusar lo que la rama de CREAR ya dejó: `GroupsOrganizerGateLogic.decide` (con `.returnsToNeutral`), el
step `.groupsGate` del Welcome y `CloudSessionSignOut.signOut(confirmedPath: .privateSignOut, …)`. Lo que
hay que construir es (a) el encaminamiento con pantalla desde `drive`, y (b) la durabilidad del intent a
través del wipe. Para (b), la superficie mínima es una key propia one-shot con `{groupID, token}` —sin
PII— que el arranque reponga en `PendingJoinStore` **después** del boot-wipe, como
`WelcomePendingDestinationStore` hace con el destino.

## Cómo se prueba

- Unit: la decisión y el cableado del encaminamiento; la durabilidad del intent a través de un wipe
  simulado.
- Device-QA (CloudKit): que el iCloud del dueño no reciba nada. Dos Apple IDs.
