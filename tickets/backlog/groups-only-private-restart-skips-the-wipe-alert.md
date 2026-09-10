---
id: groups-only-private-restart-skips-the-wipe-alert
status: backlog
priority: high
area: "modo-nube, onboarding, groups"
created: 2026-09-10
source: "review adversarial del paso 5 (`groups-only-second-launch-mounts-icloud-mirror`), lente de mount"
---

# Desde una sesión solo-grupos, «Primera vez → privado» se salta el aviso de datos existentes

## El síntoma, en lenguaje de usuario

Uso Yala solo para grupos. Cierro la sesión de Grupos («Salir de Yala en este dispositivo») y la app me
devuelve a la pantalla de bienvenida. Elijo «Es mi primera vez → Tu cuenta en tu iCloud privado». La app
me pide reabrirla, la reabro, y **entro a un onboarding de cero sin que nadie me avise de que aquí ya hay
datos** — los grupos y las categorías de la etapa anterior siguen dentro. Antes, en ese punto, salía
«Detectamos datos previos, ¿los borro?».

## Lo medido (2026-09-10)

Es una **regresión introducida por el paso 5** del rediseño, y su causa es una premisa que dejó de ser
cierta.

`ContentView`, callback `onNeedsMirrorRelaunch`, justifica saltarse el aviso así:

> «El alert de datos existentes que esa función también monta NO hace falta — **el mount neutro exige que
> no haya archivo de store**, así que en este camino no puede haber datos que confirmar.»

Eso valía con los dos términos viejos del neutro: `isFreshInstallForNeutralMount` exige que el archivo del
store no exista. **El término nuevo (`groupsOnlySessionArmed`) rompe la equivalencia**: una sesión
solo-grupos tiene archivo de store con datos dentro (categorías sembradas por `completeSetup`, filas
`SplitGroup`, transacciones puenteadas) y monta neutro igual.

Cadena: alta solo-grupos ⇒ marca armada ⇒ `CloudSessionSignOut.performPrivateReset` devuelve al Welcome
**sin relanzar** ⇒ el proceso vivo sigue montado `.neutralNoMirror` ⇒ «privado» llama a
`WelcomeFlowContainer.leaveWelcome`, y ahí `shouldRelaunch` da `true` ⇒ se va por `onNeedsMirrorRelaunch`
y **`proceed()` nunca corre** ⇒ nunca corre `startFreshPrivateOnboarding`, y con él ni el alert ni
`DataWipeService.wipeAllUserData` ni `wipeLocalGroupsDomain`. Al reabrir,
`presentNextOnboardingScreen` consume el destino y monta el onboarding sin volver a mirar
`hasExistingData`.

Antes del paso 5 ese camino montaba `.iCloudMirror` ⇒ `shouldRelaunch == false` ⇒ `proceed()` ⇒ el alert
salía y el borrado corría.

**Lo que ya se mitigó en el paso 5, y por qué no basta:** `resetOnboardingFlagsPreservingData` desarma
ahora la marca, así que el fallo **no persiste** entre arranques — al reabrir, el mount vuelve a la tabla
normal. Pero el testigo del mount del proceso VIVO ya se capturó, así que dentro de esa misma sesión el
hueco sigue abierto.

## Por qué importa

El sello de handover (`groupsDomainSealedForFreshStart`) tampoco se escribe, y en el arranque siguiente
—con el espejo ya reactivado— ese corpus **sube al iCloud del Apple ID**. Es exactamente lo que el
comentario de `ShellDataAlertsModifier` existe para impedir.

## Por dónde va el arreglo (y la decisión que hace falta)

El camino no puede a la vez relanzar (para adjuntar el espejo) y correr un borrado por filas (que con el
espejo montado exportaría los deletes). La salida natural es la misma que propone
`late-icloud-wipe-can-re-export-between-its-two-halves`: **armar el boot-wipe**
(`StorageModePersistence.armSignOutWipe`), que borra archivos **pre-mount** y es kill-safe.

**La decisión pendiente es si se le pregunta.** Hoy el borrado del camino privado va con doble
confirmación; armar el wipe en silencio sería destructivo sin aviso. Lo coherente con el paso 4 es que
este camino pase por la misma puerta (`WelcomePrivateICloudGateView`), que ya sabe validar iCloud, contar
lo que hay y pedir confirmación — pero eso lo toca, y por eso no se hizo dentro del paso 5.

## Criterios de aceptación

- [ ] Sesión solo-grupos → cerrar sesión → «Primera vez → privado»: **sale el aviso de datos existentes**
      (o su equivalente en la puerta de iCloud) antes de cualquier relanzamiento.
- [ ] Si la persona confirma, al reabrir el store está vacío y el sello de handover escrito.
- [ ] Si cancela, no se borra nada y vuelve a la elección.
- [ ] En el arranque siguiente **no sube a iCloud** ningún dato de la etapa solo-grupos.
- [ ] El camino equivalente desde una instalación fresca (sin datos) sigue sin preguntar nada.

## Cómo se prueba

- Unit: la decisión es pura (`WelcomeMirrorRelaunchLogic.shouldRelaunch` + el predicado de datos).
- Device-QA: el único sitio donde se puede ver que iCloud no recibe el corpus viejo.
