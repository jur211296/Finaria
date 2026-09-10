---
id: groups-entry-on-a-mirrored-store-still-blocks-the-owner
status: blocked
priority: high
area: "modo-nube, groups"
created: 2026-09-10
source: "mitad 2 de `groups-only-second-launch-mounts-icloud-mirror`, separada por decisión de Jürgen (2026-09-10) tras medir que el desmontaje en caliente no es viable"
blocked_by: session-exits-one-verb-per-session
blocked_reason: "necesita el verbo «Salir de Yala en este dispositivo» (paso 9): subir lo pendiente, borrar lo local y dejar iCloud intacto. Medido el 2026-09-10: ni el borrado de sign-out ni la señal de export sirven para este camino. Decisión de Jürgen del 2026-09-10: esperar al 9 y NO construir un borrado propio aquí."
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


## Segunda pasada (2026-09-10): implementado, revisado y PARADO en la puerta del borrado

Se recorrió el camino completo —diseño, implementación, tests, tres lentes adversariales— y **el resultado
es que esta mitad depende del paso 9**. Decisión de Jürgen del 2026-09-10: esperar al verbo «Salir de Yala
en este dispositivo» y no construir un borrado propio aquí. El código de esa pasada vive en la rama
`encargo/2026-09-10-groups-entry-on-a-mirrored-store-still-blocks-the-owner`, **sin PR**.

### Lo que la medición CORRIGIÓ del Paso 0 anterior (D3)

**«Borrar lo local con el espejo montado borra también iCloud» es cierto de `wipeAllUserData` —que borra
FILAS— y falso del borrado de arranque, que borra ARCHIVOS.** Lo dice el propio
`SwiftDataConfiguration:610-617`: se hace así porque «los deletes de filas quedan en la History y el
remount los replayaría hacia iCloud». ⇒ por esa vía el contenedor de iCloud no se toca, y la objeción 2
de D3 no aplica al camino de archivos. Eso es lo que reabrió el diseño.

### Los DOS bloqueantes que quedan, y ninguno es de cableado

**1. El borrado de arranque que existe no es reusable aquí.** `performSignOutWipeIfArmed` declara en su
docblock (`SwiftDataConfiguration:619-622`) tres precondiciones —«el coordinador de sign-out ya subió TODO
el outbox (verificado), cerró la sesión y armó»— y la puerta de Grupos no cumple ninguna. Lo que arrastra,
medido:

- **Borra `YalaSyncMeta` incondicionalmente** (`:689-690`), y ahí viven `GroupSyncOutbox` y
  `GroupSyncCursor`: las mutaciones de grupo pendientes de subir al backend. O sea que «el store de Grupos
  sobrevive» es cierto para sus FILAS y falso para su CANAL — las filas se quedan y lo que las empujaría
  desaparece.
- **`purgeInboundSurfaces()`** (`:798`) borra las colas pendientes de Apple Pay y Siri y las imágenes
  compartidas. **Nunca pasaron por SwiftData, así que nunca estuvieron en iCloud**: ninguna subida las
  puede salvar, y el copy de esta rama promete justo lo contrario.
- `write(.icloud)` + borrado de `mirrorOffArmed` (`:703-704`) **revierten un device en Modo Nube** en
  silencio; `clearGroupsConsent` (`:730`) le quita el consent a quien va entrando a Grupos; `resetPrefs`
  (`:732`) se lleva la foto de perfil, los tres consents de IA, TipKit y ~114 preferencias.
- **Y mientras el arm está puesto, la app queda a medias:** `AppBootstrapper.handleBecameActive:1611`
  sale en su primera línea, `NotificationService` descarta todo `add` y el widget se congela — con
  `clearSignOutWipeArm` teniendo **un solo llamador**: el propio borrado cuando termina bien. Si aborta
  (guard S3), no hay salida. → ticket propio: `sign-out-boot-wipe-has-no-way-back-if-it-aborts`.

**2. «Esperar a que suba» no se puede demostrar con las señales de hoy.**

- `forceSync` devuelve `.ok` **sin tocar la red ni guardar** si ya hay sync en vuelo
  (`iCloudSyncService:521`) — y «el espejo importando durante el Welcome» es exactamente el estado que
  dispara esta rama. → ticket: `forcesync-returns-ok-without-touching-the-network`.
- Su watchdog devuelve el estado a `.idle` a los 8 s cuando no llega ningún evento (`:349-360`), así que
  «ya no está sincronizando» también significa «todavía no ha empezado».
- `lastExportError` **no se limpia en ningún camino de producción**, así que un blip de red deja
  «Reintentar» inservible el resto del proceso. → ticket: `icloud-export-error-latch-never-clears`.
- No hay contador de deltas pendientes: cero `hasUnsyncedChanges` / `pendingExport` / `isExportQuiescent`
  en el árbol. La pieza que lo resuelve es la del **paso 9**, que la matriz marca como «HUECO grave:
  nadie espera al export hoy».

### El defecto de diseño que la rule de área cazó, y que hay que no repetir

El primer diseño disparaba con `mirrorsToICloud` (solo `.iCloudMirror`). **`.localNoMirror` adjunta el
espejo igual** —cae en `.automatic`, medido en la auditoría R1(c)— y se elige solo porque
`ubiquityIdentityToken == nil`, que mide **iCloud Drive**, no CloudKit. Consecuencias: a quien tiene Drive
apagado y CloudKit vivo se le dice «esto solo vive en este teléfono» (falso), y si su store está vacío la
puerta le deja pasar **con el espejo puesto**, así que sus gastos de grupo acabarían en el iCloud del dueño
del teléfono. ⇒ **el disparador tiene que ser el eje ANCHO (`attachesCloudKitMirror`), y «¿hay respaldo?»
solo lo contesta CloudKit** (`ICloudPersonalCorpusProbe.probe()`, que el paso 4 ya construyó). Está escrito
en `.claude/rules/swiftdata-cloudkit.md`, párrafo «`ubiquityIdentityToken` mide iCloud DRIVE».

### Qué queda hecho y sirve, en la rama

- `GroupsOrganizerGateLogic.decide` con cinco términos y seis salidas, 32 celdas exhaustivas. El mutante
  que invierte sus dos ramas nuevas tumba 8 aserciones (verificado).
- `GroupsNeutralReturnLogic`: la tabla de 12 celdas de «¿se puede borrar ya?», que falla CERRADO.
- El seam `ICloudPersonalCorpusProbe.mirrorsToICloudNow`, que corrige que el testigo del mount **miente en
  los hosts de test** (default `.iCloudMirror`), con su hook `-uitest-groups-gate-mirror-live`.
- 14 claves de copy en 16 idiomas, y las dos de «datos ajenos» retiradas. Paridad en verde.
- Dos XCUITest que recorren las ramas nuevas en simulador, y **el flujo de la rama sin respaldo verificado
  en pantalla** (snapshot del árbol: aviso → segundo gesto → confirmación).
- La purga del arm en el arranque de UITest: es una key `cloudSync.*`, que ni `-uitest-reset` ni
  `DataWipeService` limpian, y el hook que la consume está apagado bajo UITest ⇒ sin purga, una corrida que
  armara contaminaba todas las siguientes.

### Los defectos MÍOS que la review cazó y que ya están arreglados en la rama

Tres lentes independientes, ~30 hallazgos. Los que no dependían del paso 9 se corrigieron:

- **El botón «Reintentar» abría un `Task {}` no estructurado**, que nadie cancela al desmontar el step ⇒
  podía armar el borrado cuando la persona ya estaba en otra pantalla. Ahora es un `.task(id:)`, y el
  segundo gesto también.
- **Un mutante sobrevivía a la suite entera**: traducir `.unreachable` a `.reachedICloud` (un swap de dos
  identificadores que compila) armaba el borrado sin red. Fijado con un scan que exige el emparejamiento
  completo y en orden.
- **Un test que no podía fallar**: aserjar «no se escribió nada» sobre una función pura que no tiene acceso
  a ningún store. Sustituido por el veredicto, con su control.
- **Un test existente en rojo** (`NeutralMountWiringTests`): el literal del portal ahora lleva payload.
- `noteRestoreFinished()` estaba **documentado y no llamado** (criterio de aceptación de este ticket).
- El seam solo excluía `isUITesting`, no `isRunningTests`.
- Los dos `switch` de fase usaban `default:` ⇒ una fase nueva pintaría la pantalla equivocada sin aviso
  del compilador, y en `noBackupContent` eso era retroceder desde la confirmación.
- El XCUITest tapeaba `element(boundBy: 0)` —el chevron de volver, probablemente—: el id del contenedor
  pisa el del botón, **medido con un snapshot del árbol real**.

### Lo que NO se hizo, y hay que hacer cuando el paso 9 esté

- La entrada por **invitación** (`GroupBackendInviteEntryLogic`), que este ticket pide y que hoy no tiene
  ningún término de corpus.
- El disparador por el eje ancho + la sonda de CloudKit para separar «avisar» de «preguntar».
- Y lo que el paso 9 traiga: la espera de export verificada y un borrado local acotado.
