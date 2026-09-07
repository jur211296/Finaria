---
id: restore-beacon-outlives-account-deletion
status: backlog
created: 2026-09-07
source: review adversarial de `reentry-killswitch-closes-both-doors` (2026-09-07)
---

# El faro promete una cuenta que puede ya no existir

Sale de la review adversarial del chip del kill-switch. El chip nuevo usa el faro
(`CloudBeacon.isCloudAccountLinked`, iCloud-KV) para decidir si una búsqueda vacía significa «no hay
datos» o «la nube está en pausa». El detector es el correcto —es lo único de la cuenta nube que
sobrevive a una reinstalación— pero **su durabilidad es asimétrica entre encender y apagar**, y el
copy nuevo afirma más de lo que el device puede verificar.

## 1 · El clear del faro es best-effort y el set no

Solo hay **dos** limpiadores de `clearCloudAccountLinked`:

1. `MigrationWorkExecutor` — la reversa (efecto `.clearCloudBeacon`).
2. `AccountDeletionService` — el borrado de cuenta, **declarado best-effort en su propio docblock**
   («higiene post-delete BEST-EFFORT»).

**No lo borran** (medido recorriendo cada camino): `DataWipeService.resetForSignOutWipe` (solo
`UserDefaults`, cero iKV), `performSignOutWipeIfArmed`, `OnboardingResetHelper` (sus
`safeKeysToClear` son dos) ni `wipeAllUserData`.

El caso que muerde: **borrar la cuenta con el device sin red**. `removeObject` + `synchronize()`
sobre `NSUbiquitousKeyValueStore` solo *programa* la propagación. El `set` tuvo toda la vida de la
cuenta para propagarse; el `clear` tuvo segundos. Si el usuario borra la cuenta y acto seguido borra
la app, al reinstalar bajo el kill lee **«Tus datos siguen a salvo en tu cuenta de Yala»** sobre una
cuenta que ya no existe — y ese borrado era un ejercicio de derecho RGPD.

Del sign-out puro (sin borrar cuenta) no hay nada que arreglar: la cuenta sigue viva server-side y el
mensaje es correcto.

## 2 · `.iCloudDisabled` manda a activar iCloud a quien no lo necesita

`startSearch()` corta por `isAccountAvailable` **antes que nada**, y su copy dice «Necesitas tener
iCloud activado para recuperar tus datos». Para un nacido-en-nube eso es **falso**: sus datos están
en el backend de Yala e iCloud es irrelevante.

Y ahí está el límite estructural del detector: **el faro vive en el iCloud-KV, así que la única señal
que probaría que la cuenta existe es ilegible justo cuando iCloud está apagado.** El defecto es
preexistente; el chip del kill lo vuelve visible como incoherencia entre dos ramas contiguas de la
misma pantalla.

## 3 · El usuario MIGRADO no llega nunca al mensaje nuevo, y su desenlace es peor

`hasAnyData` incluye las categorías. Un usuario **migrado** (iCloud → nube) conserva su copia
CloudKit **congelada pre-migración** (afirmado en `SwiftDataConfiguration` y en
`AccountDeletionDebtLogic`), así que su búsqueda **no** sale vacía: sale `.found` con los conteos de
antes de migrar, y «Continuar» le restaura datos rancios **sin decirle que lo son**.

⇒ el residual escrito habla de «un usuario nube que REINSTALA» y eso **junta dos poblaciones que se
comportan al revés**: el nacido-en-nube (ve el mensaje nuevo, correcto) y el migrado (ve `.found` con
datos viejos). Hoy en producción no existe ningún born-cloud —el percent está en 0— así que **la
única población real es la que sigue sin cubrir**.

## Qué haría falta decidir

- ¿El faro debe apagarse de forma durable al borrar la cuenta (reintento con outbox, en vez de
  best-effort)? ¿O el copy debe dejar de afirmar que los datos están a salvo y limitarse a decir que
  la nube está en pausa?
- ¿El restore debe avisar de que la copia de iCloud es **anterior a la migración** cuando el faro
  dice que hay cuenta nube? Ese es el §3 y es el que afecta a usuarios reales hoy.
- El §2 probablemente solo necesita copy propio para el caso «faro puesto + iCloud apagado».

## Relacionados

- [[reentry-killswitch-closes-both-doors]] — el chip del que sale
