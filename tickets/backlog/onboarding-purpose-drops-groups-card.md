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
