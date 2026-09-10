//
//  WelcomeMirrorRelaunchView.swift
//  Yala
//
//  R2 · el terminal del Welcome cuando hay que reabrir la app. Quién decide es
//  `WelcomeMirrorRelaunchLogic` (motivo `.attachMirror`: el destino elegido necesita el mirror y este
//  proceso montó NEUTRO) o la puerta de Grupos (motivo `.cleanForGroups`, paso 5-b: el espejo está vivo y
//  la entrada por Grupos exige lo contrario). Esta vista solo lo cuenta.
//
//  **Los dos motivos comparten pantalla y no copy**, porque las promesas son opuestas: allí se enciende
//  algo, aquí se limpia. Lo que NO cambia entre ellos es la instrucción —ve al inicio y vuelve— ni el
//  hecho de que el trabajo real ocurre en el arranque siguiente.
//
//  COPY PROPIO, y no el `Storage.Relaunch.*` de la migración, porque el hecho que describe es otro: allí el
//  usuario está migrando un corpus que ya existe y la app se lo dice a mitad de una operación larga; aquí
//  acaba de elegir dónde quiere que vivan sus datos y todavía no tiene ninguno. Reusar aquel copy («estamos
//  terminando de mover tus datos») sería mentirle. Tono BRAND-VOICE: segunda persona, motivo antes que
//  instrucción, cero jerga — ni "mirror", ni "CloudKit", ni "contenedor".
//
//  R0 · AUTO-EXITA en background, y por eso el cuerpo dice «ve a la pantalla de inicio y vuelve» en vez de
//  pedir que mates la app. Quien lo decide es `RelaunchNetLogic.shouldExitOnBackground`, y su testigo es el
//  DESTINO PENDIENTE (`WelcomePendingDestinationStore`), no esta vista: el `handleScenePhase` de `YalaApp`
//  ve el scenePhase agregado del proceso y no puede leer el estado de una pantalla. El destino se persiste
//  en la misma vuelta que monta este step, así que «hay destino» ≡ «este terminal está puesto».
//
//  Solo `.background` — `.inactive` (app switcher, centro de notificaciones) JAMÁS mata el proceso.
//

import SwiftUI

struct WelcomeMirrorRelaunchView: View {

    /// Por qué se le pide reabrir. **Sin valor por defecto a propósito**: es la única diferencia entre las
    /// dos pantallas, y un default lo elegiría por quien navegue sin pensarlo.
    let reason: WelcomeRelaunchReason

    private var title: String {
        switch reason {
        case .attachMirror: return L10n.Welcome.MirrorRelaunch.title
        case .cleanForGroups: return L10n.Welcome.MirrorRelaunch.cleanTitle
        }
    }

    private var bodyText: String {
        switch reason {
        case .attachMirror: return L10n.Welcome.MirrorRelaunch.body
        case .cleanForGroups: return L10n.Welcome.MirrorRelaunch.cleanBody
        }
    }

    var body: some View {
        WelcomeFlowScreen { logoTopSpacing in
            VStack(spacing: 0) {
                Spacer(minLength: logoTopSpacing)

                Image("YalaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 128)
                    .colorMultiply(.white)
                    .accessibilityHidden(true)

                Spacer(minLength: DS.Spacing.lg)

                VStack(spacing: DS.Spacing.lg) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.8))
                        .accessibilityHidden(true)

                    Text(title)
                        .font(DS.Typography.title2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.lg)

                    Text(bodyText)
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.xl)
                }

                Spacer(minLength: DS.Spacing.xl)
            }
        }
        .accessibilityIdentifier("welcome_mirror_relaunch")
        .interactiveDismissDisabled()
    }
}
