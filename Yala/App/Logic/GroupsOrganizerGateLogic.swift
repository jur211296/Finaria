//
//  GroupsOrganizerGateLogic.swift
//  Yala
//
//  G3 de Grupos-first · **la puerta que se comprueba ANTES de escribir nada.**
//
//  La rama organizador del Welcome («Crear mi primer grupo») no puede empezar pidiendo datos: si el
//  canal de Grupos está apagado no hay grupo que crear, y hasta C4 el intento tenía DOS finales, los dos
//  malos y el primero PERMANENTE — con cuenta iCloud del OS nacía un grupo LOCAL con
//  `isBackendGroup = false` en silencio (y no hay ninguna llamada cliente a `migrate_group` en el
//  árbol, así que moría huérfano aunque el flag se encendiera un minuto después: un grupo de una sola
//  persona, para siempre); sin ella, el seed de identidad lanzaba y el form pintaba un `CKError` crudo.
//  **C4 cerró esa fábrica** (`GroupCreateRoutingLogic.route` devuelve `.channelOff` y `.cloudKit` ya no
//  existe), así que esta puerta ya no es lo único que separa al organizador del grupo zombi. Sigue
//  siendo necesaria por lo otro que hace: bloquear ANTES de pedir nombre e identidad, y sin escribir.
//
//  Y el flag está **OFF garantizado** en el primer render de un fresh install de producción:
//  `absentDefault = false` en release (`CloudRemoteConfig.swift`) y los dos `refreshIfDue` que existen
//  —boot y el `.task` del Welcome— son fire-and-forget SIN `force`, con min-interval de 6 h. Por eso el
//  paso 1 de la rama es un `refreshIfDue(force: true)`: la intención del usuario **ES** evidencia de que
//  el canal debería estar encendido, que es la misma regla que ya usa
//  `GroupInviteChannelRoutingLogic` con un link backend.
//
//  **El segundo término es la enmienda del punto de control (spec M1-revival §6.1).** La rama reusa
//  `GroupsSignInView`, que NO consulta el guard cross-cuenta (regla dura de su docblock). Sobre un
//  device CON DATOS de otro humano —la ventana M1: Welcome visible tras un `.privateReset` con el corpus
//  del dueño vivo— la rama firmaría a la invitada solo-grupos SOBRE el store personal del dueño: su
//  bridge metería los gastos de ella en el Panel de él, y el trío del paso 7
//  (`onboardingMode = .groupInvite`) viajaría al iKV del Apple ID del dueño por never-downgrade,
//  contaminando sus otros devices. Aquí solo se BLOQUEA; ofrecer la sesión secundaria es de la ola M.
//
//  **El orden de los tres términos es load-bearing y no estético:** el canal va primero porque es el que
//  el `force` acaba de re-medir, y porque su copy («ahora mismo no puedo abrirte grupos») describe un
//  estado transitorio, mientras que los otros dos describen estados del dispositivo. Invertirlos le
//  diría a la invitada de la ventana M1 que el problema es la conexión.
//
//  **El TERCER término (C3, 2026-08-12) es la sesión secundaria, y va DELANTE de los datos ajenos.** No
//  es una variante del segundo: en secundaria el detector de corpus mide el store de la INVITADA
//  (`YalaModel-Secondary`), que en una sesión recién montada está VACÍO ⇒ `hasExistingData` da `false` y
//  la puerta abría. Y detrás de la puerta el alta escribe SEIS preferencias por
//  `PreferenceSyncService`, que en `.localOnly` sigue escribiendo el espejo local — o sea el
//  `UserDefaults.standard` del DUEÑO —, incluida `groupsBetaUnlocked`, que **el wipe de salida no
//  repone**: `removeGroupsDomainPreferenceKeys` tiene un único call-site, dentro del «empiezo de cero»
//  del Welcome, así que cerrar la sesión de la invitada le deja al dueño el dominio Grupos adoptado.
//  Se bloquea con copy PROPIO (`welcome.groups.secondary*`) y no reusando el de datos ajenos: el hecho
//  es distinto —«estás de visita», no «hay datos de otro humano»— y la salida también, porque aquí sí
//  la hay (cerrar la sesión de invitado y volver desde su propio dispositivo).
//
//  **El término de los datos DEJÓ DE BLOQUEAR el 2026-09-10 (paso 5-b del rediseño de sesiones).** Hasta
//  entonces era un camino muerto medido en device: al propio dueño del teléfono, que ya había bajado su
//  iCloud por otra rama, la puerta le decía «aquí ya hay datos guardados… crea el grupo desde la app que
//  ya usas» — y la app que ya usa **es ésta**, con un único botón «Volver». El ADR §2-3 no admite bloquear
//  ahí: si se ve el Welcome no hay sesión privada, y lo que haya en el store es una importación que nadie
//  pidió. Ahora ese término manda a la **vuelta al neutro** (esperar el export, armar el borrado de
//  arranque, avisar sin preguntar, reabrir) y el contenedor de iCloud no se toca.
//
//  Con eso, la enmienda D2 del 2026-09-02 —`restoreInProgress` corrigiendo el término de los datos para
//  no acusar a la dueña que restauraba de SU iCloud— **se retira por innecesaria**: existía para no
//  bloquear mal, y ya no se bloquea. La señal sigue viva como ACCIÓN (la vuelta al neutro la apaga), no
//  como veredicto. Su gemela de `CrossAccountEntryGuardLogic`, que consume el mismo detector, NO se
//  toca: aquella sí sigue bloqueando.
//

import Foundation

/// ¿Puede esta rama seguir adelante, y si no, por qué?
nonisolated enum GroupsOrganizerGateLogic {

    enum Decision: Equatable {
        /// Canal encendido y device ya neutro → seguir al sign-in.
        case proceed
        /// El canal de Grupos sigue apagado DESPUÉS del refresh forzado. Copy honesto, vuelta al step y
        /// **cero escrituras** — ni `onboardingMode`, ni `groupsBetaUnlocked`, ni `hasCompletedOnboarding`.
        case blockedChannelOff
        /// C3 · sesión secundaria M1 viva: estás de visita en el móvil de otra persona. Copy propio y
        /// **cero escrituras** — las seis del alta caerían en el `UserDefaults` del DUEÑO.
        case blockedSecondarySession
        /// **El espejo de iCloud está VIVO sobre el store personal de este proceso** ⇒ vuelta al neutro:
        /// esperar a que suba lo pendiente, armar el borrado de arranque, avisar SIN preguntar y pedir
        /// que reabra. Lo que hubiera en el store se queda en iCloud, que no se toca.
        case returnToNeutral
        /// **Hay corpus personal local y NINGÚN espejo que lo respalde** (mount sin iCloud). Aquí
        /// «tus datos siguen a salvo en iCloud» sería MENTIRA: ese histórico solo vive en este teléfono.
        /// Se le pregunta, con segundo gesto, antes de borrar nada. Decisión de Jürgen, 2026-09-10.
        case askBeforeWiping
        /// El borrado de arranque ya estaba armado y este proceso montó igualmente ⇒ **no corrió**
        /// (`performSignOutWipeIfArmed` aborta sin desarmar si no puede borrar los archivos base, guard
        /// S3). Repetir el ciclo sería pedir «reabre la app» en bucle, que es el fallo grave de este
        /// camino según el device-QA del ticket padre.
        case blockedCleanupFailed
    }

    /// - Parameters:
    ///   - channelEnabled: `CloudSyncFlags.groupsBackendEnabled` **leído después** del
    ///     `refreshIfDue(force: true)`. Leerlo antes es el no-op que el bug describe.
    ///   - isSecondarySession: `SecondarySessionStore.isActive()`. C3 · va ANTES de los términos del
    ///     store porque el detector mide el store de la INVITADA, que puede estar vacío: sin este
    ///     término la puerta abre justo en el caso que más caro sale.
    ///   - mirrorsToICloud: el TESTIGO del mount de este proceso
    ///     (`personalStoreMountedDecision.mirrorsToICloud`, leído por el seam
    ///     `ICloudPersonalCorpusProbe.mirrorsToICloudNow` — crudo MIENTE bajo UITest, ver su docblock).
    ///     **No es «¿hay filas?»**: mientras el espejo esté adjunto, lo que la sesión de grupos escriba
    ///     —las filas puenteadas del bridge, que corre por defecto— SUBE al iCloud del Apple ID de este
    ///     teléfono. Por eso dispara también con el store vacío: el daño no es lo que hay, es lo que
    ///     va a subir.
    ///   - hasPersonalData: el detector ESTRECHO (`ContentView.checkHasPersonalData`: cuentas y
    ///     categorías no-`isSystem`), **y no el ancho**. El ancho (`checkHasExistingData`) cuenta grupos
    ///     y filas puenteadas, que el borrado de arranque NO se lleva por diseño (ADR §6: grupos,
    ///     nunca) — con él, quien tenga grupos locales vuelve a esta puerta tras reabrir y la app le
    ///     pide reabrir otra vez, para siempre.
    ///   - cleanupAlreadyArmed: `StorageModePersistence.isSignOutWipeArmed()`. Ver `.blockedCleanupFailed`.
    ///
    /// **`restoreInProgress` ya no es un término, y no es un descuido.** Existía para corregir el
    /// bloqueo: a la dueña que estaba bajando SU iCloud, el detector de filas la clasificaba como «datos
    /// de otro humano» y la puerta la acusaba a ella. Sin bloqueo no hay nada que corregir — y con el
    /// espejo vivo la respuesta es la misma esté restaurando o no: volver al neutro. La señal sigue
    /// importando, pero como ACCIÓN y no como veredicto: la vuelta al neutro la apaga
    /// (`ICloudRestoreSessionSignal.noteRestoreFinished()`) antes de armar nada, porque un restore vivo
    /// que nadie apaga deja a las otras puertas creyendo que este device está restaurando.
    static func decide(channelEnabled: Bool,
                       isSecondarySession: Bool,
                       mirrorsToICloud: Bool,
                       hasPersonalData: Bool,
                       cleanupAlreadyArmed: Bool) -> Decision {
        guard channelEnabled else { return .blockedChannelOff }
        guard !isSecondarySession else { return .blockedSecondarySession }
        // Nada que limpiar: ni espejo vivo ni corpus personal. Es el camino de la instalación fresca y
        // el del device que ya volvió al neutro — o sea, el de casi todo el que entra por aquí.
        guard mirrorsToICloud || hasPersonalData else { return .proceed }
        guard !cleanupAlreadyArmed else { return .blockedCleanupFailed }
        // El orden de estas dos ramas es load-bearing: con espejo vivo el corpus está —o estará— en
        // iCloud, así que borrar lo local es reversible y avisar basta. Sin espejo no lo es, y ahí se
        // pregunta.
        return mirrorsToICloud ? .returnToNeutral : .askBeforeWiping
    }
}
