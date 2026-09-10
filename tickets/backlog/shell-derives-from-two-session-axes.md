---
id: shell-derives-from-two-session-axes
status: backlog
priority: high
area: "arquitectura, modo-nube, groups, settings"
created: 2026-09-09
source: "ADR 2026-09-09 «Sesiones — dos ejes» §2 y consecuencias"
---

# La app deriva todo de dos ejes (¿sesión privada? × sesión nube activa): se retiran los tres flags de modo y la sesión de visita

## Por qué

Hoy 19 vistas y 14 ficheros de servicio deciden por **tres estados con nombres distintos** —
`StorageMode` (icloud/cloud, `CloudSyncFlags.swift:28-29`), `OnboardingMode` (full/groupInvite/completed,
`OnboardingMode.swift:13-17`) y `UsageFocus` (full/groupsOnly, `UsageFocus.swift:21-22`)— más
`SecondarySessionStore.isActive()`. `ShellModeLogic.effective` ya es una derivación de dos de ellos
(`Yala/App/Logic/ShellModeLogic.swift`). Cada vista los combina a su manera, y esa es la fuente de la
confusión que el ADR describe. Este ticket es el último del rediseño: los anteriores dejan el estado
nuevo escrito; este lo convierte en la única fuente.

## Lo medido (2026-09-09, árbol `3a94604e`) — las superficies

Vistas (19): `Settings/` StorageSettingsView, UserDataResetView, GroupsRetentionView,
NotificationsSettingsView, ThemeSettingsView · `Groups/` FullModeActivationView, GroupInviteOnboardingView,
GroupExpenseFormView, GroupRecordsView, SettlementFormView · `Onboarding/` OnboardingView,
WelcomeFlowContainer, WelcomeGroupsGateView, WelcomeRestoreView · `Profile/` ProfileView, YalaAccountView ·
`More/MoreView` · `ExportWizard/GroupsExportView` · `Shared/SecondaryHydrationBanner`.
Fuera de vistas: 9 ficheros en `Yala/Services/CloudSync`, 3 en `Yala/Utils` (incluida la decisión de
mount, `SwiftDataConfiguration.personalStoreDecision`), 2 en `Yala/App/Services`, 2 en
`Yala/Services/Groups`. (Grep: `\.groupInvite|usageFocus|SecondarySessionStore.isActive|isGroupInviteMode|storageMode == \.|ShellMode`.)

## Alcance

1. **Un solo tipo de estado de sesión**, leído desde un único sitio:
   `SessionShape { hasPrivateSession: Bool; cloud: CloudSession? }` con `CloudSession { sub, provider,
   kind: complete|groups_only }`. Se deriva de lo persistido (archivo del store + `storageMode` +
   sesión de `CloudAuthService` + `kind` cacheado + asociación) y se expone por `SessionState`.
2. **Derivaciones**, todas puras y testeadas: `ShellMode` (pestañas), qué ve Ajustes (dos botones,
   «Tu cuenta de Yala», la sección Grupos de «¿Dónde viven tus datos?»), si el bridge corre (privada o
   nube completa), la decisión de mount (sin espejo salvo sesión privada), qué onboarding falta.
3. **Retirar** `OnboardingMode.groupInvite` y `UsageFocus.groupsOnly` como *entradas* (pueden quedar
   como valores persistidos legacy que se migran a `SessionShape` en el primer arranque, y se borran
   después); retirar la puerta «datos ajenos» de `WelcomeGroupsGateView` (`GroupsOrganizerGateLogic`),
   que en el modelo no tiene caso: si hay sesión privada no se ve el Welcome, y grupos se asocia desde
   la app.
4. **Retirar la sesión de visita (M1):** `SecondarySessionStore`, `SessionDefaults`, el archivo
   `YalaModel-Secondary`, `SECONDARY_SESSION_ROLLOUT_PERCENT` en cliente y gateway, `SecondaryHydrationBanner`,
   `.signOutSecondary`, y los seams de uitest que los alimentan. Los 12 tickets de «secundaria» ya
   están descartados con el ADR como motivo; sus tests se retiran con el código.
5. Las 19 vistas pasan a leer `SessionShape` (o una derivación). Sin cambios visuales fuera de lo que
   los tickets anteriores ya definieron.
6. Migración de datos en el dispositivo: un usuario que hoy está en `groupInvite`/`groupsOnly` tiene
   que despertar en la celda «sin privada + nube solo grupos» sin perder nada; uno en `.cloud`, en
   «nube completa»; uno en `.icloud` con sesión de grupos viva, en «privada + asociada» (la asociación
   se infiere una vez del `sub` vivo).

## Criterios de aceptación

- [ ] `grep` de las entradas retiradas en `Yala/App/Views` devuelve 0; `SessionShape` es el único
      punto de lectura fuera de la capa de persistencia.
- [ ] Las cuatro celdas del ADR tienen seed de uitest y un XCUITest que recorre pestañas + Ajustes.
- [ ] Migración: los tres estados legacy de arriba aterrizan en su celda (unit sobre la lógica de
      migración con fixtures de `UserDefaults`).
- [ ] La suite entera en verde (`/gate` completo): al borrar código se corre todo, no lo tocado.
- [ ] `docs/glosario.md` y `.claude/rules/swiftdata-cloudkit.md` sin «secundaria», «visita» ni
      «invitada» como estados vivos (ticket `retire-guest-vocabulary-for-session-terms`).

## Depende de

Todos los tickets anteriores del ADR (orden de implementación en `docs/DECISIONS.md`, entrada
2026-09-09 «Sesiones — dos ejes»). Va último.
