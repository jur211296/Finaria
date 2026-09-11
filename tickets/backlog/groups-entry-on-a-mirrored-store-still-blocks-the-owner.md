---
id: groups-entry-on-a-mirrored-store-still-blocks-the-owner
status: backlog
priority: high
area: "modo-nube, groups"
created: 2026-09-10
source: "mitad 2 de `groups-only-second-launch-mounts-icloud-mirror`, separada por decisión de Jürgen (2026-09-10) tras medir que el desmontaje en caliente no es viable"
---

# «Vengo por un grupo» sobre un store que ya lleva espejo sigue bloqueando al dueño de los datos

## El síntoma, en lenguaje de usuario

Mi teléfono ya bajó datos de iCloud por otra rama (elegí «privado» y no terminé, o probé «Restaurar
desde iCloud»). Ahora toco «Vengo por un grupo → Crear mi primer grupo» y la app me dice **«Aquí ya hay
datos guardados… Si son tuyos, crea el grupo desde la app que ya usas»**, con un único botón «Volver».
La app que ya uso **es ésta**. No hay salida.

Captura: `evidencia-groups-only-mount/2026-09-09-puerta-datos-ajenos-bloquea-al-dueno.png` (en el
ticket padre).

## Lo que debería pasar (ADR 2026-09-09 §2-3)

Nunca bloquear. Si al elegir «Vengo por un grupo» el store personal ya lleva espejo o datos, la app
**vuelve al neutro** —espera el export pendiente, avisa sin pedir confirmación, borra lo local, deja
iCloud intacto, arma el neutro duradero— y sigue al sign-in. En el modelo, si se ve el Welcome no hay
sesión privada, y lo que haya en el store es una importación que nadie pidió.

## Por qué se separó del ticket padre (medido el 2026-09-10)

El padre cerró la mitad 1 (el alta solo-grupos deja neutro duradero, PR de la sesión). Esta mitad se
paró porque **los dos mecanismos que el padre daba por disponibles no cubren este caso**:

1. **El desmontaje en caliente lo rechaza su propio guard de alcance.** `PersonalContainerSwap`
   (`Yala/Services/CloudSync/PersonalContainerSwap.swift:178-255`) está completo y device-validado, pero
   `PersonalSwapReleaseLogic.mountAdmitsSwap` (`Yala/App/Logic/PersonalSwapReleaseLogic.swift:84-88`) es
   `!mountedDecision.attachesCloudKitMirror`: admite el swap **solo si ningún extremo lleva mirror**.
   Aquí el extremo de SALIDA es `.iCloudMirror` ⇒ `.skippedMountHasMirror`. El motivo está medido en
   device (spike R3, eje 3, citado en `PersonalContainerSwap.swift:19-23`): con el mirror vivo el release
   cierra los descriptores, **pero CloudKit siguió emitiendo 5 eventos en los 10 s POSTERIORES** — el
   trabajo en vuelo sobrevive al container.
2. **Borrar lo local con el espejo montado BORRA TAMBIÉN iCloud.** `wipeAllUserData`
   (`DataWipeService.wipeAllUserData`) borra el corpus personal **por filas**, y el propio
   fichero declara el invariante (`:257-263`): «borrar filas con el mirror montado exporta los deletes a
   iCloud». Eso contradice el criterio «el contenedor de iCloud sigue intacto». Y **«esperar al export»
   no existe en el repo**: cero `waitForExport`/`pendingExport`/`drainExport`/`hasCompletedFirstExport`;
   lo más cercano, `MigrationWorkExecutor.isMarkerExported()` , mira **una** fila de
   marcador, y las dos esperas reales (`waitForImportQuiescence`, `awaitQuiescence`) son de IMPORT.

## La salida que sí existe, y su precio

El ticket hermano `late-icloud-wipe-can-re-export-between-its-two-halves` propone —para su propio
caso— **no borrar filas: borrar la zona y armar el boot-wipe** (`StorageModePersistence.armSignOutWipe`),
que borra **archivos pre-mount** y es kill-safe por construcción. Ese mecanismo resuelve las dos
objeciones de arriba a la vez: pre-mount no hay mirror que exporte nada, y no hace falta soltar ningún
container vivo.

**Su precio es el relanzamiento**, que es exactamente lo que Jürgen pidió evitar («que el alta de Grupos
no se interrumpa nunca con una pantalla de reabre Yala»). ⇒ **la decisión pendiente es esa**: aceptar
un relanzamiento en este camino (raro: solo lo pisa quien ya adjuntó espejo por otra rama), o abrir el
trabajo de ensanchar `mountAdmitsSwap` a transiciones CON espejo, que reabre el residual del eje 3 del
spike R3 en la capa que menos perdona.

Los dos tickets convergen en el mismo mecanismo, así que conviene decidirlos juntos.

## Alcance

- La vuelta al neutro (espera de export · aviso sin confirmación · borrado local · iCloud intacto ·
  neutro duradero armado · cancelar `ICloudRestoreSessionSignal` si hay restore en curso).
- **Retirar el término «datos ajenos»** de `GroupsOrganizerGateLogic.decide`
  (`Yala/App/Logic/GroupsOrganizerGateLogic.swift:96-114`, el `hasExistingData && !restoreInProgress`) y
  su pantalla `welcome_groups_gate_foreign_data`. **No antes**: sin la vuelta al neutro, retirar el
  bloqueo deja al usuario creando un grupo encima de datos ajenos, que es peor. Los otros dos términos
  (canal apagado, sesión secundaria) siguen hasta que M1 se retire.
- La misma regla para la entrada por **invitación**.

## Criterios de aceptación

- [ ] Store con espejo y datos importados + «Vengo por un grupo» → sin pantalla de bloqueo: vuelta al
      neutro y sign-in; el contenedor de iCloud sigue intacto («Restaurar desde iCloud» en otra
      instalación lo encuentra).
- [ ] Invitación (link) en ese mismo estado → mismo resultado, y la hoja «unirme» al terminar.
- [ ] Restauración en curso + «Vengo por un grupo» → la señal de restore se cancela, vuelta al neutro, y
      «Restaurar desde iCloud» en otra instalación sigue encontrando todo.
- [ ] Lo que el usuario escribió en este móvil y no llegó a subir **no se pierde**.
- [ ] La pantalla `welcome_groups_gate_foreign_data` ya no es alcanzable, y sus dos hermanas sí.

## Cómo se prueba

- Device-QA (CloudKit): es el único sitio donde el espejo existe. En simulador se puede verificar la
  DECISIÓN y el borrado local, nunca que iCloud quedó intacto.
- Unit: la vuelta al neutro debería tener su lógica pura, como la tienen las dos puertas de hoy.

## Lo que hereda la activación de Yala completo (paso 8, 2026-09-11)

La puerta privada de «Activar Yala completo» borra **solo la zona de iCloud**, porque el store de una
sesión solo-grupos nunca espejó y el borrado local (`wipeAllUserData`) resetearía además su onboarding.
Esa premisa falla exactamente en el estado de este ticket: una sesión solo-grupos montada sobre un store que
YA importó el corpus (instalaciones anteriores al paso 5, o una invitación aceptada sobre un store con
espejo). Ahí, tras «borrar mis datos de iCloud», lo ya importado sigue en local y el espejo lo vuelve a
subir; y por la rama de nube, la promoción sube lo importado a la cuenta. **La vuelta al neutro de este
ticket lo cierra de raíz**: con ella, una sesión solo-grupos nunca tiene corpus importado debajo.
