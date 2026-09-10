---
name: rediseno-sesiones-dos-ejes
description: El 9-sep Jürgen rediseñó el modelo de sesiones (privada × nube, dos botones, Grupos mini-app, M1 retirada); vive en el ADR 2026-09-09 y 13 tickets. Qué espera de él y qué NO se reprodujo aún.
metadata:
  type: project
---

**El modelo de sesiones está decidido y escrito: `docs/DECISIONS.md` → «[2026-09-09] Sesiones — dos
ejes (privada × nube), un verbo por sesión, y Grupos como mini-app».** De ahí salen 13 tickets en
`tickets/backlog/` con el orden de implementación dentro del ADR, y 12 tickets de la sesión de visita
(M1) descartados. El acta del dictado está en `docs/sessions/2026-09-09-onboarding-lo-que-jurgen-espera.md`.

**Why:** un device-QA guiado destapó que la confusión no era de pantalla sino de modelo: tres flags
(`StorageMode`/`OnboardingMode`/`UsageFocus`) + secundaria, 7 verbos de salida sobre 11 operaciones.
Jürgen prefirió rediseñar a parchear.

**How to apply:**
- Cualquier trabajo en Welcome, onboarding, cierres de sesión, Grupos-cuenta o mount del store
  **empieza leyendo ese ADR**; los tickets viejos de esa familia que no cite el ADR son sospechosos.
- **Esperan a Jürgen (2):** ratificar que la sesión de visita (M1) se retira —es la única consecuencia
  que no dictó palabra por palabra; está marcada en el ADR y en `prefs-domain-per-secondary-session`
  (descartado)— y la palabra «sesión en la nube» vs «pública» (`retire-guest-vocabulary-for-session-terms`).
- **Dos hallazgos medidos en código y NO reproducidos en device todavía:** el segundo arranque de un
  solo-grupos adjunta el espejo de iCloud (`groups-only-second-launch-mounts-icloud-mirror`) y
  «Activar Yala completo» no pregunta dónde viven los datos (`full-mode-activation-must-ask-where-personal-data-lives`).
  Si Jürgen reporta lo contrario desde el móvil, el código gana solo si se vuelve a medir.
- **El faro se queda como encaminador**; la decisión A26 (2026-08-09) que lo hacía bloquear queda
  superada por el ADR §10.
- Producción sirve `cloudOnboardingChoiceRolloutPercent: 100` (curl 9-sep) aunque el repo diga `"0"`:
  `wrangler-prod-onboarding-choice-percent-drift` va PRIMERO, antes de cualquier deploy del gateway.
