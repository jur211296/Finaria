---
id: onboarding-purpose-drops-groups-card
status: backlog
priority: medium
area: onboarding
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §7"
---

# La card «Grupos» del paso *propósito* del onboarding personal sobra: solo-grupos es una sesión, no un propósito

## Qué pasa

En el onboarding personal, el paso *«¿Qué te gustaría hacer?»* ofrece tres cards: control, gastos y
**grupos**. Elegir «grupos» convierte a la persona en solo-grupos desde DENTRO del onboarding privado
(`OnboardingPurposeCard.groups` → `OnboardingUsageMode.groupsOnly`,
`Yala/App/Logic/OnboardingPurposeSelectionLogic.swift`; el paso es `OnboardingStep.purpose`,
`Yala/App/Logic/OnboardingStepPlan.swift`).

En el modelo del ADR, «solo grupos» es una **celda** (sin sesión privada + nube solo grupos), no un
propósito de la sesión privada: quien llega a [P] ya eligió tener finanzas personales. La puerta a
solo-grupos es «Vengo por un grupo» en el Welcome, y solo ella.

## Lo que hay que hacer

- [ ] Retirar la card `groups` del paso *propósito* (`OnboardingPurposeCard` pasa a dos casos, o la
      card se oculta y el caso se marca deprecated hasta `shell-derives-from-two-session-axes`).
- [ ] `OnboardingUsageMode.groupsOnly` deja de ser alcanzable desde el onboarding; revisar
      `OnboardingStepPlan.skippedSteps` y `OnboardingNextEnablement` para que no queden ramas muertas
      que dependan de él.
- [ ] Textos: retirar los strings de esa card en los 16 `.strings` (`onboarding.purpose.groups*` o el
      nombre que tengan; grep antes) — o dejarlos si `l10n-check` los sigue exigiendo por paridad.
- [ ] Tests: `OnboardingPurposeSelectionLogicTests` y los XCUITest del onboarding que tapean la card.

## Criterios de aceptación

- [ ] El paso *propósito* muestra dos cards y `groupsOnly` no se puede elegir desde [P].
- [ ] «Vengo por un grupo» sigue llevando a solo-grupos.
- [ ] `l10n-check` en verde.

## Fuera de alcance

El resto del rediseño. Este ticket es pequeño a propósito para que pueda ir en cualquier momento.

## Decisiones de Jürgen (2026-09-09, pasada de desbloqueo)

Preguntadas una a una antes de soltar la cola autónoma. **Mandan sobre lo escrito arriba.**

### Lo medido antes de decidir (2026-09-09, en este árbol)

- **`OnboardingUsageMode.groupsOnly` NO se persiste**: es `@State private var selectedUsageMode`
  (`OnboardingView.swift:39`), estado efímero del onboarding. Borrar el case **no rompe a ningún
  usuario** ni exige migración de preferencias.
- **La card ya está gateada** por `OnboardingGroupsPurposeGateLogic.shouldShowGroupsCard(isInitialFlow:
  storageMode:)` (`OnboardingView.swift:566-569`): hoy ya desaparece en modo nube y en la reutilización
  de `FullModeActivation`.
- **`OnboardingUsageMode` y `UsageFocus` son DOS enums distintos con un case homónimo.** El docblock de
  `OnboardingGroupsPurposeGateLogic:15` dice que «las otras escrituras de ese valor son
  `GroupsRetentionView:64`» y **eso es falso**: esa vista escribe `appPreferences.usageFocus =
  .groupsOnly`, que es `UsageFocus` (`Yala/App/Models/UsageFocus.swift:22`, persistido en
  `AppPreferences:403`). ⇒ **borrar `OnboardingUsageMode.groupsOnly` no rompe `GroupsRetentionView`.**
  Corrige ese docblock de paso.

### Las decisiones

- **Se borra el caso `groupsOnly` de `OnboardingUsageMode` del todo**, y con él la card del paso
  *propósito*. Que el compilador señale cada uso; no dejar ramas muertas ni un caso «deprecated».
  Ojo a `OnboardingPurposeSelectionLogic.selectedCard(for:)`, que es **total** por invariante: al
  quitar el caso, sigue devolviendo una card para todos los modos restantes.
- **`OnboardingGroupsPurposeGateLogic` se borra con sus tests**, si al medirlo no le quedan llamadores
  vivos. Su docblock avisa de que ese gate **sí bloqueaba en producción**, así que compruébalo antes de
  borrar, no después.
- **`GroupsRetentionView` NO es de este ticket**: escribe el otro enum. Se mira en el **ticket 12**, que
  ya barre las 19 vistas y los tres flags de modo. Anótalo allí como hallazgo de esta pasada.
- **Los textos de la card se retiran de los 16 `.strings`**, con `l10n-check` en verde.
