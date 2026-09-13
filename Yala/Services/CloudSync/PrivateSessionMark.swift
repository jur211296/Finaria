//
//  PrivateSessionMark.swift
//  Yala
//
//  EL EJE 1 del ADR 2026-09-09 «Sesiones — dos ejes»: ¿hay sesión privada en ESTE dispositivo?
//
//  POR QUÉ EXISTE. Hasta el 2026-09-12 este eje no tenía fuente propia: las nueve veces que la app
//  lo necesitaba lo construía como `!SessionState.isGroupInviteMode`, o sea a partir de un flag de
//  ONBOARDING («por dónde entró») que el rediseño retira. Derivar un eje del flag que va a morir es
//  lo que hacía inejecutable el paso 12: al borrarlo, nueve decisiones de producto —incluida qué se
//  borra al cerrar sesión— se quedaban sin fuente. Aquí el eje se PERSISTE.
//
//  POR QUÉ UNA MARCA POSITIVA Y NO LA PRESENCIA DEL STORE (decisión de Jürgen, 2026-09-12). La
//  alternativa era derivarlo de si existe el archivo del store personal. **Un gate derivado de una
//  AUSENCIA falla abierto**: si el fichero falta porque el montaje falló, o porque iCloud todavía no
//  ha bajado, la app trataría a alguien con una vida personal entera como si solo hubiera venido por
//  un grupo, y le escondería sus cuentas. La marca se escribe cuando la sesión privada NACE.
//
//  DÓNDE VIVE, Y POR QUÉ NO VIAJA. `UserDefaults` local, con el prefijo `cloudSync.` que el barrido
//  de preferencias excluye a propósito (ver abajo «la vida de la marca»). **Nunca al iCloud-KV**:
//  `onboardingMode` sí viaja por el KV del Apple ID con merge never-downgrade, y por ahí un
//  `.groupInvite` de OTRO dispositivo le recorta la shell al dueño de éste — el daño que
//  `DataWipeService.clearHandoverOnboardingMode` documenta y tiene que reparar a mano. «¿Hay vida
//  personal EN ESTE teléfono?» es un hecho del dispositivo, no del Apple ID.
//
//  **Y el límite de esa promesa, que hay que decir entero: vale para la marca ESCRITA, no para su
//  semilla.** El backfill del parque existente no tiene más fuente que `onboardingMode`, que para
//  entonces ya puede traer un valor mergeado del KV en un arranque anterior (`PreferenceSyncService`
//  lo persiste en `UserDefaults` local), así que la primera marca de un dispositivo legacy puede
//  heredar el modo de otro teléfono del mismo Apple ID. Es una limitación de la MIGRACIÓN, no del
//  diseño, y muere con el flag: a partir de la primera escritura la marca ya no vuelve a derivarse
//  de nada. Lo mismo vale para la rama `.groupsOnly` de restaurar (`ContentView`), cuyo destino lo
//  decide `RestoreRouter` con ese mismo modo sincronizado.
//
//  El precedente del repo para un hecho de sesión persistido es `AccountKindStore` (el eje 2), y la
//  diferencia con él importa: allí el dato describe la CUENTA, así que va SELLADO con el `userID` y
//  un snapshot sin sello se lee como «no sé». Aquí el dato describe el DISPOSITIVO, que no tiene
//  identidad que sellar — misma conclusión sobre el iCloud-KV, por un camino distinto.
//
//  LAS DOS LECTURAS, Y POR QUÉ SON DOS. La marca puede estar AUSENTE (una instalación anterior a
//  este código que aún no ha arrancado, o un dispositivo recién barrido), así que hace falta un
//  default — y **no hay un default que sirva para las dos preguntas**:
//
//    · `hasPrivateSession` (ausente ⇒ `true`) responde «¿hay vida personal que PROTEGER?». Fallar a
//      `true` hace esperar de más y conservar de más, que es el lado barato.
//    · `confirmedPrivateSession` (ausente ⇒ `false`) responde «¿puedo AFIRMAR que esta sesión es
//      privada?». Su único cliente es `DestructiveScopeLogic.wipeSignalsAppleIDDevices`, que decide
//      si «Vaciar datos» ORDENA a los demás dispositivos del Apple ID vaciarse también. Ahí `true`
//      por ausencia vacía el iPad del dueño — exactamente el daño que la review adversarial del paso
//      9 cazó y que `wipeSignalsAppleIDDevices` existe para impedir.
//
//  Un solo default con un solo nombre habría metido ese segundo caso en la dirección equivocada sin
//  que nada lo dijera. Por eso el tipo obliga a elegir, y el nombre de cada lectura dice hacia dónde
//  falla.
//
//  LA VIDA DE LA MARCA. Tres reglas, y la de en medio es la que no se ve venir:
//    · NACE / CAMBIA en los NUEVE `set` donde el modelo dice que la sesión privada empieza o deja
//      de existir. Cinco la encienden —onboarding personal terminado, restaurar de iCloud a la app,
//      adoptar una cuenta existente, activar Yala completo— y cuatro la apagan: las DOS puertas de
//      entrada por grupo (invitación y organizador), la reposición tras vaciar en solo-grupos, y el
//      seam de uitest. Si añades un décimo, el conteo de `PrivateSessionMarkWiringTests` se pone
//      rojo y te obliga a decidir de qué lado va.
//    · SOBREVIVE a «Vaciar datos», local o remoto. Vaciar no cambia QUIÉN eres: un solo-grupos que
//      vacía sigue siendo un solo-grupos. Por eso la key lleva el prefijo `cloudSync.`, que
//      `DataWipeService.removeUserPreferenceKeys` excluye — no es un accidente de nombre.
//    · MUERE en los dos sitios que devuelven el teléfono a «recién instalado»:
//      `SwiftDataConfiguration.performSignOutWipeIfArmed` (todo cierre de sesión) y
//      `DataWipeService.clearHandoverOnboardingMode` (el relevo de humano de «Empiezo de cero»).
//
//  ADR 2026-09-09 «Sesiones — dos ejes» §2 · ticket `shell-derives-from-two-session-axes`.
//

import Foundation

/// La marca persistida del eje 1. `nonisolated` porque se lee desde vistas `@MainActor` y se limpia
/// desde el boot-wipe pre-mount, que corre fuera del main actor.
nonisolated enum PrivateSessionMark {

    static let userDefaultsKey = "cloudSync.hasPrivateSession"

    // MARK: - Lecturas

    /// **¿Hay vida personal que PROTEGER en este dispositivo?** Ausente ⇒ `true`.
    ///
    /// Es la lectura por defecto y la que usan los NUEVE consumidores que deciden qué se conserva,
    /// qué se espera antes de borrar y qué se le enseña a la persona. Su dirección de fallo es
    /// conservar de más.
    static func hasPrivateSession(_ defaults: UserDefaults = .standard) -> Bool {
        if SecondarySessionStore.isActive(defaults) { return false }
        return raw(defaults) ?? true
    }

    /// **¿Puedo AFIRMAR que esta sesión es privada?** Ausente ⇒ `false`.
    ///
    /// Para las decisiones que, al equivocarse hacia `true`, alcanzan datos que están FUERA de este
    /// teléfono. Hoy hay una: la señal de vaciado a los demás dispositivos del Apple ID.
    static func confirmedPrivateSession(_ defaults: UserDefaults = .standard) -> Bool {
        if SecondarySessionStore.isActive(defaults) { return false }
        return raw(defaults) ?? false
    }

    // **Las dos lecturas cortan en M1 ANTES de mirar la marca, y no es simetría con `set`: es que la
    // pregunta cambia de sujeto.** La marca vive en el `UserDefaults.standard` del DUEÑO —`set` tiene
    // su guard justo para que la visita no la escriba—, así que leerla desde una sesión secundaria
    // contesta «¿tiene el dueño vida personal?» cuando lo que se pregunta es «¿tiene ESTA sesión vida
    // personal?». Y la respuesta de esa pregunta es `false` por definición del modelo: una sesión
    // secundaria es una sesión en la nube en el móvil de otra persona.
    //
    // Sin este corte, la hoja de «Vaciar datos» de la visita pasaba de `.wipeDataGroupsOnly` a
    // `.wipeDataFull` —prometiendo un corpus personal que su wipe no toca, porque solo borra los
    // archivos `-Secondary`— y su aterrizaje, de la shell de grupos al onboarding personal del dueño.
    // Antes del eje persistido eso no pasaba: la visita leía su `onboardingMode` EN MEMORIA, que sí
    // era suyo.

    /// Lo persistido tal cual, sin default. `nil` = la marca no se ha escrito nunca en este
    /// dispositivo. Lo consume el backfill y los tests; producción elige una de las dos de arriba.
    static func raw(_ defaults: UserDefaults = .standard) -> Bool? {
        guard defaults.object(forKey: userDefaultsKey) != nil else { return nil }
        return defaults.bool(forKey: userDefaultsKey)
    }

    // MARK: - Escrituras

    /// La sesión privada nace (`true`) o deja de existir (`false`) en este dispositivo.
    ///
    /// **Lleva el guard de M1 por el mismo motivo que `OnboardingMode.setCurrent`**, y aquí el daño
    /// es peor: la key vive en el `UserDefaults.standard` que la visita COMPARTE con el dueño, así
    /// que un `false` escrito desde una sesión secundaria le diría al dueño que no tiene vida
    /// personal — y con eso su cierre de sesión dejaría de esperar al export de iCloud. La visita no
    /// se pronuncia sobre la sesión privada de otro.
    static func set(_ value: Bool, _ defaults: UserDefaults = .standard) {
        guard !SecondarySessionStore.isActive(defaults) else { return }
        defaults.set(value, forKey: userDefaultsKey)
    }

    /// El dispositivo vuelve a «recién instalado». Sin guard de M1 a propósito: borrar deja las dos
    /// lecturas en su lado conservador (`hasPrivateSession` protege, `confirmedPrivateSession` no
    /// avisa a nadie), así que no hay dirección en la que este camino pueda hacer daño.
    static func clear(_ defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Backfill

    /// **El backfill de un arranque** (decisión de Jürgen, 2026-09-12): escribe por primera vez la
    /// celda NORMAL del modelo nuevo, que es la de casi todo el parque.
    ///
    /// No contradice la derogación del punto 7 del ticket —aquélla retiraba estados legacy MUERTOS,
    /// y quien tenga uno reinstala—: sin esto, TODO el mundo despertaría sin marca, y aunque el
    /// default conservador los trataría bien, los dispositivos solo-grupos quedarían leídos como si
    /// tuvieran vida personal en cuanto el PR-B retire el flag viejo.
    ///
    /// **`hasCompletedOnboarding` es el gate, y no es cosmético: es lo que hace que la AUSENCIA
    /// exista de verdad en producción.** Sin él, el backfill escribía una marca positiva en dos
    /// sitios donde no hay nada que migrar y donde el modelo dice que NO hay sesión privada:
    ///  - la instalación fresca (celda A), donde este método corría antes de que nadie se diera de
    ///    alta y se convertía en el primer escritor de la marca, contradiciendo el invariante de la
    ///    cabecera («la marca se escribe cuando la sesión privada NACE»);
    ///  - el arranque siguiente a un cierre de sesión (celda G), donde `performSignOutWipeIfArmed`
    ///    acaba de llamar a `clear()` pre-mount y su `resetPrefs()` ha borrado `onboardingMode` ⇒ el
    ///    backfill leía `.full` y **resucitaba la marca en el mismo lanzamiento**. Con eso el default
    ///    estricto de `confirmedPrivateSession` era inalcanzable: la ausencia duraba milisegundos y
    ///    «Vaciar datos» podía ordenar a los demás dispositivos del Apple ID vaciarse en un teléfono
    ///    que acababa de volver a «recién instalado».
    ///
    /// Ese mismo barrido borra `hasCompletedOnboarding` (`DataWipeService.removeUserPreferenceKeys`),
    /// así que el gate es exacto: distingue «parque existente» de «dispositivo que empieza de cero»
    /// sin necesitar ninguna marca propia.
    ///
    /// `legacyIsGroupsOnly` lo pasa el llamador desde el `onboardingMode` de `UserDefaults`. Ese
    /// valor puede venir mergeado del iCloud-KV en un arranque anterior, y es la limitación heredada
    /// que la cabecera declara: no hay otra fuente para el parque legacy.
    ///
    /// Idempotente por PRESENCIA de la key, no por su valor: una marca escrita a `false` por una
    /// entrada solo-grupos no se puede re-derivar del flag en el arranque siguiente, o un flag que el
    /// KV haya movido entretanto la pisaría.
    @discardableResult
    static func backfillIfNeeded(legacyIsGroupsOnly: Bool,
                                 hasCompletedOnboarding: Bool,
                                 _ defaults: UserDefaults = .standard) -> Bool {
        guard hasCompletedOnboarding else { return false }
        guard raw(defaults) == nil else { return false }
        set(!legacyIsGroupsOnly, defaults)
        return raw(defaults) != nil
    }
}
