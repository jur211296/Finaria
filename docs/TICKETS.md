# Tickets

Index of `tickets/`. Folder name **is** `status`. Filename **is** `id` + `.md` (English kebab-case). Ids assigned by Claude since 2026-08-29.

## Schema

```yaml
---
id: <slug>                          # = filename without .md
status: backlog|in-progress|qa|done|blocked|discarded
priority: high|medium|low           # only if the source had it
area: (if present on the source)
created: (if present on the source)
updated: 2026-08-26
source: YalaWiki/<origin path>
---
# Title
<original body>
```

Rules:

- `status` equals the parent folder. Moving the file and editing `status` is the same act.
- Omit `priority` when the source did not have a real value (`high` / `medium` / `low`). Do not invent it.
- Closed write-ups (bugs `closed`/`fixed`, backlog `done`/`cancelled`) are **not** copied.
- Last line of a migrated body: `migrated from YalaWiki <path> @ 1934e8ad`.
- Do not invent PASS or close a ticket.

Source repo for absorption: `jur211296/YalaWiki` @ `1934e8ad`. This environment could not read that repo (GitHub App sees only `jur211296/Yala`). Bodies are **not** invented. Paths below are the owner map.

## Index (177)

| id | status | path |
|----|--------|------|
| account-goldens-freeze-read-test-times-out | backlog | tickets/backlog/account-goldens-freeze-read-test-times-out.md |
| adopt-terminal-claims-ready-without-checking-engine | backlog | tickets/backlog/adopt-terminal-claims-ready-without-checking-engine.md |
| ai-recommended-budgets | backlog | tickets/backlog/ai-recommended-budgets.md |
| apple-watch | backlog | tickets/backlog/apple-watch.md |
| applepay-shortcut-warm-launch-empty-data | qa | tickets/qa/applepay-shortcut-warm-launch-empty-data.md |
| apppreferences-rewritten-on-launch | blocked | tickets/blocked/apppreferences-rewritten-on-launch.md |
| approximate-mark-ors-over-whole-period | qa | tickets/qa/approximate-mark-ors-over-whole-period.md |
| appstorage-onboarding-desarma-el-aislamiento-de-tests | backlog | tickets/backlog/appstorage-onboarding-desarma-el-aislamiento-de-tests.md |
| aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app | qa | tickets/qa/aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app.md |
| bridge-de-grupos-pierde-la-marca-de-sus-patas | backlog | tickets/backlog/bridge-de-grupos-pierde-la-marca-de-sus-patas.md |
| budget-days-left-counts-today | backlog | tickets/backlog/budget-days-left-counts-today.md |
| budget-tied-to-income-or-expense | backlog | tickets/backlog/budget-tied-to-income-or-expense.md |
| bulk-update-account-leaves-converted-amount-stale | backlog | tickets/backlog/bulk-update-account-leaves-converted-amount-stale.md |
| canarios-y-breadcrumbs-sin-emisor | backlog | tickets/backlog/canarios-y-breadcrumbs-sin-emisor.md |
| cashflow-spend-prediction | backlog | tickets/backlog/cashflow-spend-prediction.md |
| chat-assistant-plants-exchange-rate-one | qa | tickets/qa/chat-assistant-plants-exchange-rate-one.md |
| chat-draft-drops-the-expense-sign | backlog | tickets/backlog/chat-draft-drops-the-expense-sign.md |
| chat-rows-sealed-before-the-fix-have-no-repair-path | backlog | tickets/backlog/chat-rows-sealed-before-the-fix-have-no-repair-path.md |
| ci-allowlist-no-cubre-encargos-ni-qa-scripts | backlog | tickets/backlog/ci-allowlist-no-cubre-encargos-ni-qa-scripts.md |
| ci-checkout-v4-runs-on-deprecated-node | backlog | tickets/backlog/ci-checkout-v4-runs-on-deprecated-node.md |
| ci-destination-assumes-a-simulator-that-may-not-exist | backlog | tickets/backlog/ci-destination-assumes-a-simulator-that-may-not-exist.md |
| ci-no-corre-la-suite-del-gateway | backlog | tickets/backlog/ci-no-corre-la-suite-del-gateway.md |
| ci-suite-simulador-duplicada-y-allowlist-incompleta | done | tickets/done/ci-suite-simulador-duplicada-y-allowlist-incompleta.md |
| ci-verde-con-la-suite-en-rojo | done | tickets/done/ci-verde-con-la-suite-en-rojo.md |
| ci-warns-but-does-not-block | backlog | tickets/backlog/ci-warns-but-does-not-block.md |
| ci-workflow-cites-missing-testing-strategy | backlog | tickets/backlog/ci-workflow-cites-missing-testing-strategy.md |
| cloud-fx-rates-blob-two-faces | qa | tickets/qa/cloud-fx-rates-blob-two-faces.md |
| cloud-tx-epoch-orphan-relations | backlog | tickets/backlog/cloud-tx-epoch-orphan-relations.md |
| cobertura-ui-diaria-cuelga-del-push | backlog | tickets/backlog/cobertura-ui-diaria-cuelga-del-push.md |
| creategroup-throw-after-commit-loses-owner | backlog | tickets/backlog/creategroup-throw-after-commit-loses-owner.md |
| currency-change-asks-rates-for-the-old-currency | backlog | tickets/backlog/currency-change-asks-rates-for-the-old-currency.md |
| currency-change-service-tests-mirror-the-logic | backlog | tickets/backlog/currency-change-service-tests-mirror-the-logic.md |
| debounce-sync-imported-transactions | backlog | tickets/backlog/debounce-sync-imported-transactions.md |
| debt-simplification-nondeterministic-ties | backlog | tickets/backlog/debt-simplification-nondeterministic-ties.md |
| debt-tracking | backlog | tickets/backlog/debt-tracking.md |
| device-handover-groups-leak | discarded | tickets/discarded/device-handover-groups-leak.md |
| diez-worktrees-comparten-un-simulador | backlog | tickets/backlog/diez-worktrees-comparten-un-simulador.md |
| distribucion-recalcula-dos-veces-por-toque-y-sin-debounce | backlog | tickets/backlog/distribucion-recalcula-dos-veces-por-toque-y-sin-debounce.md |
| distribution-balance-kpi-skips-fx | qa | tickets/qa/distribution-balance-kpi-skips-fx.md |
| dmarc-sube-la-politica-tras-observar | backlog | tickets/backlog/dmarc-sube-la-politica-tras-observar.md |
| doble-conteo-dia1-previo-thismonth | done | tickets/done/doble-conteo-dia1-previo-thismonth.md |
| dos-criterios-de-aproximado-en-la-misma-pantalla | backlog | tickets/backlog/dos-criterios-de-aproximado-en-la-misma-pantalla.md |
| edgecases-extreme-minimum-flaky-under-load | backlog | tickets/backlog/edgecases-extreme-minimum-flaky-under-load.md |
| el-job-de-tests-del-ci-no-tiene-timeout | done | tickets/done/el-job-de-tests-del-ci-no-tiene-timeout.md |
| el-saldo-de-distribucion-no-se-entera-de-un-registro-nuevo | backlog | tickets/backlog/el-saldo-de-distribucion-no-se-entera-de-un-registro-nuevo.md |
| ensure-rates-for-existing-transactions-has-no-callers | backlog | tickets/backlog/ensure-rates-for-existing-transactions-has-no-callers.md |
| entitlement-sync-forzado-es-noop-si-hay-otro-en-vuelo | backlog | tickets/backlog/entitlement-sync-forzado-es-noop-si-hay-otro-en-vuelo.md |
| exchange-rate-detail-shows-zero-for-low-denomination-currencies | backlog | tickets/backlog/exchange-rate-detail-shows-zero-for-low-denomination-currencies.md |
| exportable-insights | backlog | tickets/backlog/exportable-insights.md |
| filtro-de-cuentas-se-colapsa-al-navegar-a-registros | backlog | tickets/backlog/filtro-de-cuentas-se-colapsa-al-navegar-a-registros.md |
| fx-approximate-mark-missing-on-secondary-surfaces | backlog | tickets/backlog/fx-approximate-mark-missing-on-secondary-surfaces.md |
| fx-manual-writes-seal-approximate-as-final | qa | tickets/qa/fx-manual-writes-seal-approximate-as-final.md |
| fx-partial-rate-rows-silent-1to1 | qa | tickets/qa/fx-partial-rate-rows-silent-1to1.md |
| fx-pnl-education-card | qa | tickets/qa/fx-pnl-education-card.md |
| fx-presentation-still-shows-1to1 | qa | tickets/qa/fx-presentation-still-shows-1to1.md |
| fx-rate-derivation-threshold-reseals-one-to-one | backlog | tickets/backlog/fx-rate-derivation-threshold-reseals-one-to-one.md |
| fx-unknown-currency-code-collapses-to-usd | backlog | tickets/backlog/fx-unknown-currency-code-collapses-to-usd.md |
| fx-widget-drops-missing-currency | backlog | tickets/backlog/fx-widget-drops-missing-currency.md |
| gate-doc-says-swift-testing-only | backlog | tickets/backlog/gate-doc-says-swift-testing-only.md |
| gateway-has-no-telemetry | backlog | tickets/backlog/gateway-has-no-telemetry.md |
| gateway-typecheck-roto-y-fuera-del-ci | backlog | tickets/backlog/gateway-typecheck-roto-y-fuera-del-ci.md |
| goldens-de-staging-solo-pasan-a-trozos | backlog | tickets/backlog/goldens-de-staging-solo-pasan-a-trozos.md |
| group-balance-service-shares-not-deduped | backlog | tickets/backlog/group-balance-service-shares-not-deduped.md |
| group-joiner-flag-consumers-still-narrow | qa | tickets/qa/group-joiner-flag-consumers-still-narrow.md |
| group-notif-credits-payer-not-editor | done | tickets/done/group-notif-credits-payer-not-editor.md |
| groups-approval-banner-stays | done | tickets/done/groups-approval-banner-stays.md |
| groups-archived-group-rejects-join | qa | tickets/qa/groups-archived-group-rejects-join.md |
| groups-archived-still-accepts-changes | backlog | tickets/backlog/groups-archived-still-accepts-changes.md |
| groups-background-emitter-no-upload | done | tickets/done/groups-background-emitter-no-upload.md |
| groups-batch-facts-plural-identity | backlog | tickets/backlog/groups-batch-facts-plural-identity.md |
| groups-budget | qa | tickets/qa/groups-budget.md |
| groups-canal-sin-capability-set | backlog | tickets/backlog/groups-canal-sin-capability-set.md |
| groups-cloud-identity-loss-on-migrate | discarded | tickets/discarded/groups-cloud-identity-loss-on-migrate.md |
| groups-cloud-mode-hardening-v1 | discarded | tickets/discarded/groups-cloud-mode-hardening-v1.md |
| groups-consent-door-spec | qa | tickets/qa/groups-consent-door-spec.md |
| groups-deleted-group-detail-stays-open | qa | tickets/qa/groups-deleted-group-detail-stays-open.md |
| groups-equal-split-shows-not-participating-on-peer | qa | tickets/qa/groups-equal-split-shows-not-participating-on-peer.md |
| groups-expense-notif-only-on-foreground | qa | tickets/qa/groups-expense-notif-only-on-foreground.md |
| groups-ghost-tx-on-delete | done | tickets/done/groups-ghost-tx-on-delete.md |
| groups-guest-currency-from-region | backlog | tickets/backlog/groups-guest-currency-from-region.md |
| groups-import-splitwise-tricount | backlog | tickets/backlog/groups-import-splitwise-tricount.md |
| groups-in-group-search | backlog | tickets/backlog/groups-in-group-search.md |
| groups-invite-skips-unirme-sheet-if-onboarded | qa | tickets/qa/groups-invite-skips-unirme-sheet-if-onboarded.md |
| groups-join-intent-reconciler | blocked | tickets/blocked/groups-join-intent-reconciler.md |
| groups-leave-rpc-error-10 | qa | tickets/qa/groups-leave-rpc-error-10.md |
| groups-log-expense-via-chat-voice | backlog | tickets/backlog/groups-log-expense-via-chat-voice.md |
| groups-owner-debt-no-heir-dead-end | qa | tickets/qa/groups-owner-debt-no-heir-dead-end.md |
| groups-owner-transfer-and-leave | qa | tickets/qa/groups-owner-transfer-and-leave.md |
| groups-pending-member-can-open-group | qa | tickets/qa/groups-pending-member-can-open-group.md |
| groups-pending-member-sees-detail-chrome | backlog | tickets/backlog/groups-pending-member-sees-detail-chrome.md |
| groups-reconnect-prune-or-rewire | done | tickets/done/groups-reconnect-prune-or-rewire.md |
| groups-settlement-reminder | qa | tickets/qa/groups-settlement-reminder.md |
| groups-settlement-reminder-discoverability | qa | tickets/qa/groups-settlement-reminder-discoverability.md |
| groups-settlement-reminder-stale-clock | backlog | tickets/backlog/groups-settlement-reminder-stale-clock.md |
| groups-shareable-summary | qa | tickets/qa/groups-shareable-summary.md |
| groups-stats-no-deduplica-gastos | backlog | tickets/backlog/groups-stats-no-deduplica-gastos.md |
| groups-tab-missing-panel-perf | qa | tickets/qa/groups-tab-missing-panel-perf.md |
| groups-transfer-leave-write-ahead | backlog | tickets/backlog/groups-transfer-leave-write-ahead.md |
| guest-decline-has-no-screen | qa | tickets/qa/guest-decline-has-no-screen.md |
| guest-journey-dead-screens | done | tickets/done/guest-journey-dead-screens.md |
| hero-estadisticas-stock-vs-flujo-entre-pestanas | qa | tickets/qa/hero-estadisticas-stock-vs-flujo-entre-pestanas.md |
| history-token-guard-echo-blind-spot | backlog | tickets/backlog/history-token-guard-echo-blind-spot.md |
| hoja-del-saldo-vivo-ignora-los-filtros-de-sesion | backlog | tickets/backlog/hoja-del-saldo-vivo-ignora-los-filtros-de-sesion.md |
| inbox-convert-draft-to-group-expense | done | tickets/done/inbox-convert-draft-to-group-expense.md |
| inbox-crash-convert-to-group-expense | done | tickets/done/inbox-crash-convert-to-group-expense.md |
| insights-precomputed-icon-lookup | backlog | tickets/backlog/insights-precomputed-icon-lookup.md |
| invite-aasa-requires-s-param | backlog | tickets/backlog/invite-aasa-requires-s-param.md |
| invite-backend-stale-config | qa | tickets/qa/invite-backend-stale-config.md |
| invite-link-five-causes-one-message | qa | tickets/qa/invite-link-five-causes-one-message.md |
| invite-refresh-forzado-es-noop-si-hay-otro-en-vuelo | qa | tickets/qa/invite-refresh-forzado-es-noop-si-hay-otro-en-vuelo.md |
| joiner-flag-residuals-cosmetic-and-service-guard | backlog | tickets/backlog/joiner-flag-residuals-cosmetic-and-service-guard.md |
| la-nocturna-de-ui-no-ha-disparado-ni-una-vez | done | tickets/done/la-nocturna-de-ui-no-ha-disparado-ni-una-vez.md |
| notifications-not-delivered-testflight | done | tickets/done/notifications-not-delivered-testflight.md |
| only-testing-filters-may-be-silently-empty | backlog | tickets/backlog/only-testing-filters-may-be-silently-empty.md |
| orphan-alerts-behind-fullscreen-covers | backlog | tickets/backlog/orphan-alerts-behind-fullscreen-covers.md |
| panel-accounts-redesign | backlog | tickets/backlog/panel-accounts-redesign.md |
| panel-colapsa-la-seleccion-de-cuentas-a-la-primera | qa | tickets/qa/panel-colapsa-la-seleccion-de-cuentas-a-la-primera.md |
| panel-defaults-four-sections-four-widgets | qa | tickets/qa/panel-defaults-four-sections-four-widgets.md |
| panel-lee-el-filtro-de-cuentas-en-singular-fuera-del-saldo | backlog | tickets/backlog/panel-lee-el-filtro-de-cuentas-en-singular-fuera-del-saldo.md |
| panel-no-recalcula-al-llegar-tasas-nuevas | backlog | tickets/backlog/panel-no-recalcula-al-llegar-tasas-nuevas.md |
| prefs-domain-per-secondary-session | qa | tickets/qa/prefs-domain-per-secondary-session.md |
| prefs-synced-keys-upload-not-download | qa | tickets/qa/prefs-synced-keys-upload-not-download.md |
| push-client-ignores-yala-kind | backlog | tickets/backlog/push-client-ignores-yala-kind.md |
| qa-cloud-readme-sin-entradas-g13-04-y-g13-05 | backlog | tickets/backlog/qa-cloud-readme-sin-entradas-g13-04-y-g13-05.md |
| qa-guion-tanda-no-cubre-17-tickets | backlog | tickets/backlog/qa-guion-tanda-no-cubre-17-tickets.md |
| records-standalone-amount-discrepancy | backlog | tickets/backlog/records-standalone-amount-discrepancy.md |
| reentry-counts-as-fresh-install | qa | tickets/qa/reentry-counts-as-fresh-install.md |
| reentry-killswitch-closes-both-doors | qa | tickets/qa/reentry-killswitch-closes-both-doors.md |
| registros-calendario-cuenta-gastos-por-signo | qa | tickets/qa/registros-calendario-cuenta-gastos-por-signo.md |
| rejected-member-cold-tap-does-nothing | qa | tickets/qa/rejected-member-cold-tap-does-nothing.md |
| rejoin-tap-renotifies-admins | qa | tickets/qa/rejoin-tap-renotifies-admins.md |
| repair-queue-has-no-exit-for-partial-rate-rows | qa | tickets/qa/repair-queue-has-no-exit-for-partial-rate-rows.md |
| reparacion-de-tasas-no-avisa-al-panel | backlog | tickets/backlog/reparacion-de-tasas-no-avisa-al-panel.md |
| rescue-discarded-groups-pull | discarded | tickets/discarded/rescue-discarded-groups-pull.md |
| restore-beacon-outlives-account-deletion | backlog | tickets/backlog/restore-beacon-outlives-account-deletion.md |
| rojo-heroBuckets-thisWeek-trailing-window | done | tickets/done/rojo-heroBuckets-thisWeek-trailing-window.md |
| rojo-xcuitest-runner-muere-tras-el-primer-caso | done | tickets/done/rojo-xcuitest-runner-muere-tras-el-primer-caso.md |
| rules-testing-habla-de-ios-27-que-no-existe | backlog | tickets/backlog/rules-testing-habla-de-ios-27-que-no-existe.md |
| saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas | backlog | tickets/backlog/saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas.md |
| savings-tracking | backlog | tickets/backlog/savings-tracking.md |
| scheduled-payment-once-labeled-monthly | backlog | tickets/backlog/scheduled-payment-once-labeled-monthly.md |
| scheduled-payments-notif-dedup | qa | tickets/qa/scheduled-payments-notif-dedup.md |
| secondary-entry-healing-writes-owner-not-session | backlog | tickets/backlog/secondary-entry-healing-writes-owner-not-session.md |
| secondary-groups-off-wipes-owner | qa | tickets/qa/secondary-groups-off-wipes-owner.md |
| secondary-guest-exit-lock-and-outbox | qa | tickets/qa/secondary-guest-exit-lock-and-outbox.md |
| secondary-onboarding-still-crosses-owner-domain | backlog | tickets/backlog/secondary-onboarding-still-crosses-owner-domain.md |
| secondary-visit-data-lost-on-signout-unannounced | backlog | tickets/backlog/secondary-visit-data-lost-on-signout-unannounced.md |
| secondary-visitor-writes-owner-domain | qa | tickets/qa/secondary-visitor-writes-owner-domain.md |
| siri-intent-dual-container | qa | tickets/qa/siri-intent-dual-container.md |
| smart-ai-notifications | backlog | tickets/backlog/smart-ai-notifications.md |
| staging-test-credentials-in-public-repo | done | tickets/done/staging-test-credentials-in-public-repo.md |
| staging-test-user-c-does-not-exist | backlog | tickets/backlog/staging-test-user-c-does-not-exist.md |
| storekit-appgroup-siri-pro-gate | qa | tickets/qa/storekit-appgroup-siri-pro-gate.md |
| subscription-success-without-pro | done | tickets/done/subscription-success-without-pro.md |
| synced-prefs-outside-prefsynckey | discarded | tickets/discarded/synced-prefs-outside-prefsynckey.md |
| tests-borran-el-store-sqlite-abierto | backlog | tickets/backlog/tests-borran-el-store-sqlite-abierto.md |
| transaction-save-helper-flake-one-per-suite | backlog | tickets/backlog/transaction-save-helper-flake-one-per-suite.md |
| trends-comparison-kpi-vs-curve | done | tickets/done/trends-comparison-kpi-vs-curve.md |
| trends-insight-card-v2-bullets | backlog | tickets/backlog/trends-insight-card-v2-bullets.md |
| uitest-compara-fechas-sin-fijar-locale | backlog | tickets/backlog/uitest-compara-fechas-sin-fijar-locale.md |
| undercount-dias-intervalos-cerrados | qa | tickets/qa/undercount-dias-intervalos-cerrados.md |
| unit-suite-nondeterministic-reds | done | tickets/done/unit-suite-nondeterministic-reds.md |
| update-banner-appstore-criteria | qa | tickets/qa/update-banner-appstore-criteria.md |
| verify-dual-channel-zone-in-supabase | backlog | tickets/backlog/verify-dual-channel-zone-in-supabase.md |
| vigilante-margen-menor-que-el-retraso-real-del-cron | backlog | tickets/backlog/vigilante-margen-menor-que-el-retraso-real-del-cron.md |
| web-domain-has-no-spf-dkim-dmarc | done | tickets/done/web-domain-has-no-spf-dkim-dmarc.md |
| welcome-beacon-reads-owner-icloud-in-secondary | backlog | tickets/backlog/welcome-beacon-reads-owner-icloud-in-secondary.md |
| welcome-copy-blames-owner | qa | tickets/qa/welcome-copy-blames-owner.md |
| welcome-fresh-start-alert-leaves-blank-screen | qa | tickets/qa/welcome-fresh-start-alert-leaves-blank-screen.md |
| welcome-privacy-branch-has-no-secondary-door | qa | tickets/qa/welcome-privacy-branch-has-no-secondary-door.md |
| welcome-private-card-promises-icloud-in-visit | backlog | tickets/backlog/welcome-private-card-promises-icloud-in-visit.md |
| welcome-start-fresh-wipes-before-ask | qa | tickets/qa/welcome-start-fresh-wipes-before-ask.md |
| widget-de-tc-no-localiza-separadores | backlog | tickets/backlog/widget-de-tc-no-localiza-separadores.md |
| widget-snapshot-visitor-overwrites-owner | qa | tickets/qa/widget-snapshot-visitor-overwrites-owner.md |
| wire-decoder-accepts-non-finite-money | backlog | tickets/backlog/wire-decoder-accepts-non-finite-money.md |
| yala-android | backlog | tickets/backlog/yala-android.md |
| zone-decisions-still-per-row | backlog | tickets/backlog/zone-decisions-still-per-row.md |

Counts by folder: backlog 88 · in-progress 1 · qa 49 · blocked 3 · done 19 · discarded 5 = 165. *(Recontados sobre disco con `find` el 2026-09-08 por la sesión de `repair-queue-has-no-exit-for-partial-rate-rows`, que aporta cuatro de los cambios: el propio ticket pasa a `qa/` y entran tres hallazgos de su review adversarial —`wire-decoder-accepts-non-finite-money`, `currency-change-asks-rates-for-the-old-currency` y `ensure-rates-for-existing-transactions-has-no-callers`—, ninguno suyo. La línea anterior decía 152 con 162 filas en el índice: seguía desviada, como avisaba ella misma.)*

Frank 2026-09-07 (timeout del CI + UI a nocturna): la suite entera de UI sale del PR y pasa a una
corrida nocturna sobre `2.1`; el PR se queda con build + unit y **ya tiene tope de tiempo**, que era el
agujero del ticket: sin `timeout-minutes`, GitHub aplica su default de 360 min, así que un cuelgue real
era indistinguible de una corrida lenta y nadie se enteraba hasta las seis horas. **La cifra del ticket
se volvió a medir y estaba corta**: decía «~80 min de media» sobre 4 runs; sobre 39 runs y leyendo los
tiempos POR PASO, la mediana del job es 89 min y el paso de UI se lleva 67 de ellos — el 76 % del reloj.
El PR baja a ~22 min. Topes: 45 min el job en un PR (1,5× el máximo medido de build+unit), 150 en la
nocturna, más uno por paso. **Un hallazgo de camino sale a ticket propio**
(`ci-workflow-cites-missing-testing-strategy`): el workflow manda tres veces a `TESTING-STRATEGY.md`,
que no está en el repo desde que se retiró el espejo de `.planning/` y vive en el vault que `CLAUDE.md`
declara no-SSOT. Y lo que casi rompo sin que nadie lo pidiera: `outcome` vale `skipped` tanto para
«saltado a propósito» como para «no llegó a correr», así que saltar la UI en los PR habría hecho que el
aviso gritara «la suite NO llegó a correr» en cada uno — se distingue ahora con `UI_TOCABA`.

Frank 2026-09-06 (decisiones): Jürgen respondió en una sentada las **seis** decisiones de producto que tenían
tickets parados sin código que escribir; cada una está en su ticket bajo «Decisión Jürgen (2026-09-06)», con
la opción elegida, las descartadas y el AC ya resuelto. Los tres del encargo:
**`hero-estadisticas-stock-vs-flujo-entre-pestanas`** (etiquetar el número en las 4 pestañas;
`blocked → backlog`, counts `blocked 3 → 2`, `backlog 55 → 56`), **`groups-pending-member-can-open-group`**
(cerrar la puerta solo en cliente; el DDL no se toca) y **`reentry-killswitch-closes-both-doors`** (bajo el
kill las dos puertas cerradas es lo deseado y se arregla el mensaje; la re-entrada arranca el motor en
sesión). Dos extra que también decían «decisión antes de código»: **`fx-presentation-still-shows-1to1`**
(número con marca de aproximado) y **`welcome-privacy-branch-has-no-secondary-door`** (pantalla propia
«estás de visita», sin bloquear). De los cinco, **`reentry-killswitch-closes-both-doors` pasó a `qa/` el 2026-09-07** (PR de esa
sesión: las dos puertas escritas, el mensaje de pausa en 16 idiomas y el motor arrancando en sesión;
le queda solo el device-QA, que necesita conmutar el kill desde el backend). Los otros cuatro siguen
en `backlog/` **listos para lanzar**; todos piden device-QA al final, tres copy en 16 idiomas y uno
review adversarial. **Siguen en `blocked/` por
device, no por decisión:** `apppreferences-rewritten-on-launch` y `groups-join-intent-reconciler`.

Frank 2026-09-06 (barrido completo, misma sesión): Jürgen preguntó si YA no quedaba ningún ticket
esperando una decisión suya. **Medido, no supuesto:** los 94 tickets vivos leídos enteros por cuatro
lectores independientes, las 13 citas de «sí» re-comprobadas con grep. Quedaban **13 decisiones más**,
y las respondió todas en cuatro tandas (misma forma: opciones, coste, recomendada primero). Escritas
en su ticket bajo «Decisión Jürgen (2026-09-06)»: `panel-colapsa-la-seleccion-de-cuentas-a-la-primera`
(el Panel respeta el conjunto de cuentas), `records-standalone-amount-discrepancy` (sin categoría →
por el signo), `groups-guest-currency-from-region` (sí a adoptar la moneda del grupo si fue adivinada),
`joiner-flag-residuals-cosmetic-and-service-guard` (manda la fila activa; no se borra),
`groups-settlement-reminder` (al deudor, tono suave), `groups-shareable-summary` (todo el historial,
botón en Ajustes), `groups-budget` (un límite por grupo), `fx-pnl-education-card` (Free),
`el-job-de-tests-del-ci-no-tiene-timeout` (UI a nocturna; PR = build + unit con tope), y en `qa/`
`secondary-guest-exit-lock-and-outbox` (ratificado: el dueño no tiene reintento) y
`distribution-balance-kpi-skips-fx` (puntero al hero). **Tres decisiones sobre tickets de `qa/`
generaban trabajo nuevo y salen a ticket propio en `backlog/`** para que la cola los pueda lanzar sin
tocar lo que espera verificación: `groups-owner-transfer-and-leave` (high; de `groups-leave-rpc-error-10`),
`groups-archived-group-rejects-join` (de `rejected-member-cold-tap-does-nothing`) y
`budget-days-left-counts-today` (low; de `undercount-dias-intervalos-cerrados`). Counts: backlog 56 → 59,
total 115 → 118. **Tres dudosas se quedaron sin preguntar a propósito, por técnicas:**
`secondary-entry-healing-writes-owner-not-session`, `staging-test-user-c-does-not-exist` y el residual
del faro en `prefs-domain-per-secondary-session` — las decide quien las implemente.

Frank 2026-09-02 (altas): dos hallazgos del QA de hoy entran en `backlog/`, para que no se pierdan
al cerrar la sesion.

- **`welcome-fresh-start-alert-leaves-blank-screen`** (**high**) — cerrar el alert de «Empezar desde
  cero» por CUALQUIERA de sus dos botones deja el Welcome sin un solo control: hay que matar la app.
  Preexistente y **alcanzable en produccion** (onboarding de quien reinstala teniendo datos). Medido
  con tres lanzamientos y control negativo: pasa con y sin el seam `-uitest-fail-wipe`, y en la rama
  «Cancelar», que no invoca ningun wipe ⇒ no es un fallo del borrado, es el alert. Contradice el
  comentario del propio codigo en `ShellDataAlertsModifier.swift:105` («user queda en el Chooser»).
- **`scheduled-payment-once-labeled-monthly`** (low) — un pago «una sola vez» se rotula «Mensual»:
  `recurrenceBadge` pinta `recurrenceType` y nunca mira `isRecurring`, y `RecurrenceType` no tiene
  caso `once`. Presentacion, no calculo.

Counts recontados sobre disco: backlog 39 → 41, total 76 → 78.

Frank 2026-09-02 (QA): `inbox-convert-draft-to-group-expense` **PASA y se cierra a `done/`** — los 12
ACs verificados EN PANTALLA (sim iPhone 17 Pro), incluida la FECHA, que era el punto ciego y que hasta
hoy solo estaba «medida en el código». Lo desbloqueó el seam `DevSeedDrafts.draftBDaysInThePast`
(`3ba69eab`): antes los dos borradores del fixture nacían en `.now`, así que un falso verde era
indistinguible de uno real. Con esto caen los cuatro puntos que la entrada del 2026-08-14 (más abajo)
dejaba pendientes: guardar, cancelar, los dos negativos y la fecha. **Aviso para quien lo repita:**
tras guardar, el Inbox vuelve a mostrar un pendiente con el mismo nombre y el contador vuelve a 2 —
NO es el draft sin borrar, es la contraparte del bridge; está documentado en el ticket.
Fuera de esta cola: el negativo de INGRESO no es alcanzable desde la UI (el seed no siembra drafts de
ingreso) y el sync real al grupo es cross-device.

**Counts RECONTADOS sobre disco, y corrigen un desfase que venía de antes:** el índice decía
`backlog 34 · qa 15 · done 8 = 69` y el disco tiene `backlog 39 · qa 14 · done 11 = 76`. Mi
movimiento solo explica `qa 15 → 14` y `done 10 → 11`; los otros 7 eran drift acumulado sin
registrar.

Jurgen 2026-08-28 (alta): `groups-invite-skips-unirme-sheet-if-onboarded` entra en `backlog/` con
prioridad **high** — reporte de device del owner (Lima, TF 2.1 build 12): B, con la cuenta **ya creada**,
abrió un enlace de invitación y **no vio la hoja de «Unirme»**; el alta se hizo sola. El owner pide que
esa hoja aparezca **siempre**, venga de primer plano, de segundo plano o estando ya dentro de la app. Sin
implementación: cero Swift. **Medido** en `2.1` @ `2175e53e`, y escrito en el ticket como medición y no
como causa única de esa corrida (no hubo captura de Console): con `hasCompletedOnboarding` el camino del
invite puede devolver `.join` y saltarse `.presentInviteOnboarding` — el corte vive en
`GroupsGateLogic.nextStep:121`, que es lo que `GroupBackendInviteEntryLogic.nextStep` consume, y se repite
en el drain de `ContentView:960`. Lo que hay hoy **cumple su propio contrato** (ese paso existe para el
usuario FRESCO), así que lo que el owner pide es un cambio de contrato con dos tests que habrá que
actualizar a propósito. **No** se dobla con `groups-join-intent-reconciler` (member que no nacía / «¡Todo
listo!» falso), ni con `groups-pending-member-can-open-group` (ya en el árbol vía PR 46), ni con
`invite-link-five-causes-one-message` (copy de enlace inválido). Counts tras el alta en este árbol:
backlog 33 → 34, total 68 → 69.

Jurgen 2026-08-28 (alta): `groups-expense-notif-only-on-foreground` entra en `backlog/` con prioridad
**high** — reporte de device del owner en TF **2.1 build 12**: A crea/edita un gasto de grupo y la
notificación llega a B **solo al abrir la app**, nada mientras B está fuera; a A no le llega (era el
actor). Sin causa declarada y sin implementación: el ticket lleva el mapa **medido** del camino
(la notif de grupo es LOCAL y nace tras el pull —
`GroupsSyncClient.applyPulledPage:1937` → `GroupNotificationService.processRemoteChanges`) y las
hipótesis con su señal discriminante. **No** se declara el silent push roto: no está medido.
`group-notif-credits-payer-not-editor` ya está `done/` (PR 47, PASS de atribución/eco); este alta **no**
lo reabre. Counts tras el alta en este árbol: backlog 32 → 33, total 67 → 68.

Jurgen 2026-08-28 (alta): `groups-equal-split-shows-not-participating-on-peer` entra en `backlog/`
con prioridad **high** — device-QA del owner en TF 2.1 build 12, dos teléfonos, grupo ya en uso ese
día: el gasto que A reparte mitad y mitad se ve en B como si B no hubiera participado, y solo se
actualiza tras force-quit + reentrada en B. Es **un** ticket con dos tiempos (primera apertura
equivocada / tras force-quit actualizado), **sin causa raíz declarada** y **sin** convertirlo en el
bug de notificaciones (B no recibió aviso; el owner lo deja fuera a propósito). Mismo día se añaden
**dos observaciones de contraste** al mismo ticket: un gasto posterior creado en A convirtiendo un
borrador del Inbox, y una edición del importe de un gasto ya existente — las dos llegaron bien a B
**sin** matar la app (PASS del owner **de ese gasto** y **de esa edición**, no del ticket). Una de tres
observaciones falló: el defecto queda como **condicional, no constante** (no es una medida de
frecuencia), y el ticket **no** se cierra: qué distingue el caso que falla de los que no sigue sin
resolver. Sin implementación: cero Swift. Counts tras el alta en este árbol: backlog 31 → 32, total
66 → 67. Sin tocar `qa/coverage-index.json` (no hay código nuevo bajo `Yala/`).

Jurgen 2026-08-28 (alta, la segunda del día): `groups-leave-rpc-error-10` entra en `backlog/` con
prioridad **high** — hallazgo de device en Lima (TF `2.1` build 12, dos teléfonos): en uno «Salir del
grupo» funciona y en el otro falla con el alert crudo «Error de Yala.GroupsRPCError 10», y en esa
pantalla no hay botón de borrar el grupo. Es **un** ticket con dos caras (el número crudo del canal y
el agujero de UX de último dueño / `isOwner` local que solo escribe el creador) porque comparten
setup, pantalla y callejón sin salida. Sin implementación: cero Swift, `qa/coverage-index.json`
intacto. **Nada se declara como causa**: el mapeo del discriminante 10 → `channelDisabled` está
medido en el árbol `2.1` @ `2175e53e` (orden de declaración del enum), y el ticket deja escrito qué
parte de esa lectura es inferencia y cómo zanjarla. Counts tras el alta en este árbol: backlog 30 → 31,
total 65 → 66.

Jurgen 2026-08-28 (cierre): `inbox-crash-convert-to-group-expense` pasa a `done/` por **QA device PASS**
del owner — TF 2.1 build 12, teléfono A: convertir un borrador de la Bandeja en gasto compartido de un
grupo en uso **no crasheó**, el borrador salió de la bandeja y el gasto quedó en el grupo. El fix ya
estaba en `2.1` (`88a43237`, medido hoy como ancestro), así que **este cierre es QA, no un fix nuevo**, y
hoy no hubo subida a TestFlight. El PASS cubre el path de **conversión**, no los 4 sheets de finalización
de grupo a los que el fix se amplió (esos los sostiene `InboxRowPruneCoordinatorTests`, determinista). El
hermano de feature `inbox-convert-draft-to-group-expense` **se evaluó y se queda en `qa/`**: su guion
pendiente tiene cuatro puntos y hoy solo se tocó uno (cancelar, los dos casos negativos y la fecha en
pantalla siguen sin ejercitar) ⇒ AC distinta, no se cierra por inferencia; queda anotado en el ticket.
Counts RECONTADOS sobre disco tras el movimiento: qa 16 → 15, done 7 → 8; el total sigue en 65 porque es
un movimiento, no un ticket nuevo.

Jurgen 2026-08-28 (cierre): `group-notif-credits-payer-not-editor` pasa a `done/` con **PASS del owner**
(Lima). Dos teléfonos, el mismo grupo que el resto del QA de hoy, **TF 2.1 build 12**: **A** fue quien actuó
(crear/editar) y **A no recibió notificación** —ningún eco que atribuyera su cambio a **B**—, mientras **B sí
la recibió**. **Lo que el PASS no cubre, escrito en el ticket:** la notificación de B llegó **solo al abrir la
app**, que es *cuándo* se entrega y no *a quién* se atribuye ⇒ va en ticket aparte
(`groups-expense-notif-only-on-foreground`, en alta separada) y **no se dobla aquí** ni como PASS ni como
FAIL; el escenario original (gasto pagado por Pia, editado por el owner) **no consta re-corrido palabra por
palabra** —el reporte no fija quién pagaba, y con pagador = A el silencio ya existía antes del fix, así que
esa variante no discrimina—; el **texto** de la notificación de B no está medido; y liquidaciones, gasto
nuevo, terceros y 2º device siguen sin correr. Cierre de **QA**, no fix nuevo: sin cambio de código, sin
subida a TestFlight, A7/M5 en HOLD. Counts medidos tras el movimiento: qa 17 → 16, done 6 → 7; el total sigue
en 65 porque es un movimiento, no un ticket nuevo.

Jurgen 2026-08-28 (alta, hallazgo de la MISMA corrida de device): `groups-pending-member-can-open-group`
entra en `backlog/` con prioridad **high** — estando **pendiente de aprobación**, B veía el grupo en su
lista y **al tocarlo podía entrar y verlo**. Owner: está mal. **No se dobla** dentro del ticket del aviso
(allí el defecto era que el aviso no se retiraba DESPUÉS de aprobar, y hoy se retiró) ni se reusa
`groups-join-intent-reconciler` (allí el miembro no nacía). Sin implementación y sin causa inventada: lo
único medido del mecanismo es que entregar **grupo + roster** a un pendiente es **intencional** en el DDL
(`supabase-groups-staging.ddl:125`, `:153`, comentario en `:814`) mientras el contenido financiero **no**
baja (`:817`, `:819`, `:821`) ⇒ lo que queda abierto es una **decisión de producto**, y choca con
`guest-decline-has-no-screen`, que trata el mismo hecho como problema de copy. Counts tras el alta en
este árbol (ya con ghost-tx cerrado y deleted-group-detail dentro): backlog 29 → 30, total 64 → 65.

Jurgen 2026-08-28 (cierre): `groups-approval-banner-stays` pasa a `done/` con **PASS del owner** (Lima,
**TF 2.1 build 12**): B se une, ve «1 solicitudes pendientes» y el aviso de esperar al admin, A aprueba y
**B —sin forzar el cierre de la app ni reabrirla— ve irse solos el aviso y el mensaje naranja**, con el
grupo normal y 2 miembros activos. Es el escenario que ningún test podía cerrar, y **medido**: el fix
`479e8e81` es ancestro de `f4cf3d2b` («Build 12 para TestFlight de 2.1») ⇒ el binario que probó el owner
lleva el código. **Fuera del PASS**, escrito en el ticket: el rechazo y la contra-prueba del tercer
miembro no se corrieron hoy (tienen unit, no device), B no era install limpia, y esto **no** cierra al
hermano `groups-join-intent-reconciler`, que sigue en `qa/`. Counts medidos tras el movimiento: qa 18 →
17, done 5 → 6; el total no se mueve por el cierre porque es un movimiento, no un ticket nuevo.

Jurgen 2026-08-28 (cierre): `groups-ghost-tx-on-delete` pasa a `done/` con **PASS en device del owner**
(Lima). Dos teléfonos, mismo grupo, **TF 2.1 build 12**: A crea un gasto al 50/50, B lo ve en el grupo y
en su Panel, A lo borra y en B —sin reabrir A— el gasto se va del grupo **y** la transacción puenteada
desaparece del Panel, sin huérfana atascada. Dos comprobaciones posteriores del mismo día completan la
liquidación: A la registra y B la ve sin force-quit con los balances cuadrando, y después A la borra y en
B desaparece sin dejar balances colgados (las dos PASS). ⇒ la clase de fantasma del ticket queda cubierta
en device para las **dos** entidades del reporte original, gasto y liquidación. **Lo que estos PASS no
cubren, escrito en el ticket:** los dos borrados salieron de **A**, así que el sentido contrario (borrar
desde B, el bug era bidireccional) **no se corrió**; en la liquidación el reporte llega al grupo y a los
balances, no al Panel de B; no hay PASS de cola C (d)(e) más allá de esos tres escenarios; no hubo subida
nueva a TestFlight y A7/M5 sigue en HOLD.
Counts medidos tras el movimiento: qa 19 → 18, done 4 → 5; el total sigue en 64 porque es un
movimiento, no un ticket nuevo. `groups-background-emitter-no-upload` ya está `done/` (PR 41); este
cierre no lo toca.

Jurgen 2026-08-28 (alta): `groups-deleted-group-detail-stays-open` entra en `backlog/` con prioridad
**high** — reporte de device del owner (TF 2.1 build 12, teléfono A, Lima): tras borrar el grupo el
detalle **se quedó abierto**, y el grupo solo desapareció de la lista después de tocar Atrás. En esta
corrida el botón de borrar **sí** apareció. Sin implementación y **sin causa declarada**: el reporte no
distingue si lo que quedó delante era la sheet de Ajustes o el detalle en push, y esa distinción es la
que decide dónde va el fix. Contraste con `groups-leave-rpc-error-10`: esa es otra corrida y otro
teléfono (B), donde falló **salir** con «GroupsRPCError 10» y no había botón de borrar — ese ticket no
se toca aquí, y **medido**: hoy no tiene fichero en este árbol (vive en una PR abierta a `2.1`, sin
mergear). **Medido** en el alta, sobre `2175e53e`: el índice previo (63 filas) coincidía exactamente
con disco en id y status en las 63, y el único delta era este ticket nuevo (backlog 28 → 29, total
63 → 64). **Re-medido** tras traer `2.1` @ `7ddf87fc` a esta rama —que ya incluye el cierre del emisor
de abajo—: 64 filas ↔ 64 ficheros, sin huérfanos por ninguno de los dos lados, y los counts de arriba
son los de este árbol ya fusionado. Nota de alcance: siguen abiertas otras PRs a `2.1` que mueven
tickets de estado; nada de ellas está incorporado aquí, así que estos counts volverán a moverse a
medida que entren.

Jurgen 2026-08-28 (cierre): `groups-background-emitter-no-upload` pasa a `done/` por **QA device PASS**
del owner — dos teléfonos, TF 2.1 build 12: A crea el gasto de grupo y se va al Home de iOS sin
force-quit, B lo ve en ~30 s sin que A se reabra. El código ya estaba en `2.1` vía PR 19, así que **este
cierre es QA, no un fix nuevo**, y hoy no hubo subida a TestFlight. Counts medidos tras el movimiento,
ya con el alta de `fx-partial-rate-rows-silent-1to1` dentro: in-progress 10 → 9, done 3 → 4; el total
sigue en 63 porque es un movimiento, no un ticket nuevo. (El 63 de esa línea es el de su propio árbol:
en esta rama el total es 64 con el alta de arriba dentro.)

Jurgen 2026-08-28 (alta): `fx-partial-rate-rows-silent-1to1` entra en `backlog/` con prioridad
**high** — familia FX del audit de Frank sobre `2.1` @ `68a7221c` (filas de tasas incompletas +
conversión 1:1 que se declara exacta). Es **un** ticket, no tres: las tres caras (lectura, cambio de
moneda preferida, `persistRate`) comparten el predicado `rateExists` vs `rateHasAllCurrencies`. Sin
implementación. **Medido** antes y después: el índice previo (62 filas) coincidía exactamente con
disco en id y status en las 62; el único delta era este ticket nuevo. Counts tras el alta:
backlog 27 → 28, total 62 → 63.

Jurgen 2026-08-27 (cierre): `notifications-not-delivered-testflight` pasa a `done/` como **no es bug de
entrega** — en el device el permiso de notificaciones de iOS estaba en OFF y la app no volvió a pedirlo.
**No es PASS**: no hubo cambio de código ni subida. Counts medidos tras el movimiento: in-progress
11 → 10, done 2 → 3; el total sigue en 62 porque es un movimiento, no un ticket nuevo.

Jurgen 2026-08-27: la línea de counts anterior decía `backlog 26 · in-progress 11 · qa 18` (= 60) con
61 filas en el índice y 61 ficheros en disco. **Medido**: índice y disco coincidían exactamente
(mismo id y mismo status en los 61); lo único desalineado era esa línea. Corregida a los valores
medidos, ya con este ticket dentro.

Jurgen 2026-08-26: `groups-cloud-mode-hardening-v1`, `groups-cloud-identity-loss-on-migrate`, `device-handover-groups-leak` are **discarded** (CloudKit dead / no remaining written AC). Not PASS. Not `done/`.

## Origin map (YalaWiki → tickets/)

| origin | destination |
|--------|-------------|
| Bugs/crash-inbox-convertir-a-gasto-grupo-draft-borrado.md | tickets/done/inbox-crash-convert-to-group-expense.md |
| Bugs/groups-notif-actualizo-atribuye-al-pagador-no-al-autor.md | tickets/done/group-notif-credits-payer-not-editor.md |
| Bugs/grupos-enlace-de-invitacion-cinco-causas-un-solo-mensaje.md | tickets/qa/invite-link-five-causes-one-message.md |
| Bugs/grupos-invitado-el-no-no-tiene-pantalla.md | tickets/qa/guest-decline-has-no-screen.md |
| Bugs/grupos-recorrido-del-invitado-codigo-muerto-y-docblock-caducado.md | tickets/done/guest-journey-dead-screens.md |
| Bugs/ok_applepay-shortcut-ios27-warm-launch-datos-vacios.md | tickets/qa/applepay-shortcut-warm-launch-empty-data.md |
| Bugs/ok_siri-intent-dual-container-refactor.md | tickets/qa/siri-intent-dual-container.md |
| Bugs/prefs-cinco-keys-synced-suben-y-no-vuelven.md | tickets/qa/prefs-synced-keys-upload-not-download.md |
| Bugs/qa_cloud-fx-rates-blob-dos-caras.md | tickets/qa/cloud-fx-rates-blob-two-faces.md |
| Bugs/qa_cloud-tx-epoca-relaciones-huerfanas.md | tickets/backlog/cloud-tx-epoch-orphan-relations.md |
| Bugs/qa_groups-aprobacion-no-retira-banner.md | tickets/done/groups-approval-banner-stays.md |
| Bugs/qa_groups-join-intent-reconciler.md | tickets/blocked/groups-join-intent-reconciler.md |
| Bugs/qa_groups-tab-no-perf-patterns.md | tickets/qa/groups-tab-missing-panel-perf.md |
| Bugs/qa_groups-tx-fantasma-al-borrar-gasto-de-grupo.md | tickets/done/groups-ghost-tx-on-delete.md |
| Bugs/qa_invite-backend-mudo-config-stale.md | tickets/qa/invite-backend-stale-config.md |
| Bugs/qa_pagos-planificados-notifs-incoherentes-y-dedup-sin-entrega.md | tickets/qa/scheduled-payments-notif-dedup.md |
| Bugs/qa_storekit-appgroup-siri-pro-gate.md | tickets/qa/storekit-appgroup-siri-pro-gate.md |
| Bugs/qa_welcome-copy-acusa-al-dueno-de-traer-datos-ajenos.md | tickets/qa/welcome-copy-blames-owner.md |
| Bugs/qa_welcome-empiezo-de-cero-borra-antes-de-preguntar-y-falla-mudo.md | tickets/qa/welcome-start-fresh-wipes-before-ask.md |
| Bugs/qa_widget-snapshot-sin-sello-la-visita-pisa-los-datos-del-dueno.md | tickets/qa/widget-snapshot-visitor-overwrites-owner.md |
| Bugs/reentrada-la-vuelta-cuenta-como-instalacion-nueva.md | tickets/qa/reentry-counts-as-fresh-install.md |
| Bugs/secundaria-canal-apagado-la-visita-borra-los-grupos-del-dueno.md | tickets/qa/secondary-groups-off-wipes-owner.md |
| Bugs/secundaria-la-visita-escribe-en-el-dominio-del-dueno.md | tickets/in-progress/secondary-visitor-writes-owner-domain.md |
| Bugs/secundaria-salida-de-la-invitada-bloqueo-permanente-y-outbox-de-grupos.md | tickets/in-progress/secondary-guest-exit-lock-and-outbox.md |
| Bugs/tf-suscripcion-exito-sin-pro.md | tickets/done/subscription-success-without-pro.md |
| Bugs/ux_update-banner-appstore-criterios-y-forzado.md | tickets/qa/update-banner-appstore-criteria.md |
| Backlog/alerts-huerfanos-detras-de-fullscreencovers.md | tickets/backlog/orphan-alerts-behind-fullscreen-covers.md |
| Backlog/debounce-transactions-imported-from-sync-observer.md | tickets/backlog/debounce-sync-imported-transactions.md |
| Backlog/future_yala-android.md | tickets/backlog/yala-android.md |
| Backlog/groups-busqueda-interna.md | tickets/backlog/groups-in-group-search.md |
| Backlog/groups-emisor-segundo-plano-no-sube.md | tickets/done/groups-background-emitter-no-upload.md |
| Backlog/groups-import-splitwise-tricount.md | tickets/backlog/groups-import-splitwise-tricount.md |
| Backlog/groups-invitado-moneda-region-red-muerta.md | tickets/backlog/groups-guest-currency-from-region.md |
| Backlog/groups-presupuesto-de-grupo.md | tickets/backlog/groups-budget.md |
| Backlog/groups-reconexion-poda-o-recableado.md | tickets/done/groups-reconnect-prune-or-rewire.md |
| Backlog/groups-recordatorio-liquidacion.md | tickets/qa/groups-settlement-reminder.md |
| Backlog/groups-registrar-gasto-por-chat-voz.md | tickets/backlog/groups-log-expense-via-chat-voice.md |
| Backlog/groups-resumen-compartible-exportable.md | tickets/backlog/groups-shareable-summary.md |
| Backlog/insights-calculator-iconlookup-precomputed.md | tickets/backlog/insights-precomputed-icon-lookup.md |
| Backlog/p20-13_records-standalone-discrepancy.md | tickets/backlog/records-standalone-amount-discrepancy.md |
| Backlog/p20-15_comparativa-kpi-vs-curva-descuadre.md | tickets/done/trends-comparison-kpi-vs-curve.md |
| Backlog/qa_apppreferences-lavado-general.md | tickets/blocked/apppreferences-rewritten-on-launch.md |
| Backlog/qa_groups-endurecimiento-modo-nube-v1.md | tickets/discarded/groups-cloud-mode-hardening-v1.md |
| Backlog/qa_grupos-nube-perdida-identidad-y-migracion.md | tickets/discarded/groups-cloud-identity-loss-on-migrate.md |
| Backlog/qa_handover-dispositivo-grupos-fuga.md | tickets/discarded/device-handover-groups-leak.md |
| Backlog/qa_inbox-convertir-a-gasto-de-grupo.md | tickets/done/inbox-convert-draft-to-group-expense.md |
| Backlog/qa_prefs-dominio-por-sesion-secundaria.md | tickets/qa/prefs-domain-per-secondary-session.md |
| Backlog/trends-insight-card-v2-bullets.md | tickets/backlog/trends-insight-card-v2-bullets.md |
| Ideas/idea-fx-pnl-card.md | tickets/backlog/fx-pnl-education-card.md |
| Ideas/Insights exportable basado en comando insights de Claude con diseño muy basico y amigable.md | tickets/backlog/exportable-insights.md |
| Ideas/Integración con Apple Watch.md | tickets/backlog/apple-watch.md |
| Ideas/Notificaciones Smart con IA.md | tickets/backlog/smart-ai-notifications.md |
| Ideas/Predicción de gasto dentro de línea de gasto en flujo de caja.md | tickets/backlog/cashflow-spend-prediction.md |
| Ideas/Presupuesto adaptado a ingreso o egreso (?).md | tickets/backlog/budget-tied-to-income-or-expense.md |
| Ideas/Presupuestos recomendados con IA.md | tickets/backlog/ai-recommended-budgets.md |
| Ideas/Rediseño cuentas en Panel.md | tickets/backlog/panel-accounts-redesign.md |
| Ideas/Tracking de ahorros.md | tickets/backlog/savings-tracking.md |
| Ideas/Tracking de deudas.md | tickets/backlog/debt-tracking.md |
| Backlog/modo-nube/qa_MODO-NUBE-SPEC-CONSENT-GRUPOS.md | tickets/qa/groups-consent-door-spec.md |
| Backlog/modo-nube/qa_rescate-pull-grupos-descartados.md | tickets/discarded/rescue-discarded-groups-pull.md |

Frank 2026-09-05 (implementación): `groups-invite-skips-unirme-sheet-if-onboarded` pasa a `qa/`. La hoja
del invitado se presenta SIEMPRE: el terminal de `.invite` deja de cortar por `hasCompletedOnboarding`
—un PROXY que solo valía para el fresco, porque la propia hoja marcaba su alta al terminar— y pasa a
preguntar el hecho real, `PendingJoinEntry.inviteConfirmedAt`. Las DOS puertas cambian juntas (la tabla y
el drain del router); y lo que la hoja MUESTRA se separa de lo que su CTA ESCRIBE, porque el alta corrida
sobre una cuenta viva le pisa nombre, moneda y periodo, y esos tres SÍ viajan al iKV.

**Tres correcciones a lo que el ticket daba por medido**, re-medidas en este árbol: (1) su punto 5 está
caducado — `AppBootstrapper.inviteRouteDecision` y sus tests dan CERO ocurrencias, se retiraron después de
escribirlo; (2) las coordenadas se desplazaron, como el propio ticket avisaba; (3) su premisa de que
`onboardingMode = .groupInvite` escala al iKV por este camino es **falsa** — `OnboardingMode.setCurrent`
escribe `.standard` a secas, y los dos que empujan esa key al canal sincronizado son
`GroupsOrganizerOnboarding` y `FullModeActivationView`. La conclusión del ticket (no correr el alta) era
correcta; su titular, no.

La **review adversarial** cazó cuatro defectos que este mismo cambio introducía y que ningún grep ve; el
peor, que confirmar UNA invitación sellaba TODAS (`reconcile` barre las 8 entries vivas), o sea el defecto
del ticket colado por la puerta de atrás. Y una decisión de producto nueva y **reversible en un commit**:
la hoja gana salida («Más tarde», copy ya traducido) para quien tiene app detrás — sin ella, ampliar su
audiencia convertía su falta de salida en una jaula que el reconciler remonta durante 7 días.

Gate verde entero: build ×2 schemes sin warnings nuevos · 6134 unit / 623 suites · **130 XCUITest, la
suite completa** · índice de QA validado. Verificado por MUTACIÓN en las dos rondas. **Queda device-QA de
dos teléfonos**, que es lo que los tests no ven.


---

Frank 2026-09-07 (welcome-privacy-branch-has-no-secondary-door): **la rama privada del Welcome deja de
callarse en visita, y el onboarding deja de prometer categorías que no crea.** `backlog → qa` — el código
está hecho y pinneado; falta el e2e con dos cuentas reales, que el seam de simulador no puede fingir
(enciende el descriptor pero **no monta** un store secundario). Counts `backlog 65 → 67`, `qa 41 → 42`,
total `129 → 132`.

**La premisa del ticket se midió otra vez y trajo dos hechos que no estaban escritos.** El primero cambió
el copy: la card que la visita acaba de tocar promete «se sincronizan por tu iCloud privado» y el store
secundario es `cloudKitDatabase: .none` (`SwiftDataConfiguration.swift:1188`) — no se espeja a ninguna
CloudKit, ni a la del dueño ni a la de la visita. El aviso dice por eso «solo para ti y solo en este
dispositivo», que es el hecho verdadero. El segundo era un defecto vivo del mismo patrón: **en visita, el
saldo inicial que la persona teclea se descartaba en silencio** — el seed no corría (cinturón M1), nadie
creaba «Ajuste de saldo» y `createOnboardingAccount` no encontraba dónde colgar el importe. No hizo falta
arreglo aparte: tratar la visita como «sin seed» —que es lo que la decisión pedía— entra por la rama que
ya la crea.

**Y la pantalla cazó lo que el fuente escondía.** La primera captura mostraba el copy VIEJO con el fichero
ya corregido: `es.lproj` y `pt.lproj` son copias regeneradas de `es-419` y `pt-BR`, así que editar los
`.strings` después de correr `add-l10n-key.sh` los dejó atrás, con un `[NEEDS_TRANSLATION]` vivo en `pt`.
Se resincronizó y se volvió a mirar.

Tres tickets nuevos, todos salidos de camino y ninguno colado en este PR:
**`welcome-private-card-promises-icloud-in-visit`** (low — hoy esa card casi no se lee: en producción el
sub-chooser hace bypass; deja de ser low en cuanto el percent suba de 0),
**`secondary-visit-data-lost-on-signout-unannounced`** (medium — el wipe de salida es correcto y borra lo
que la visita apuntó; qué se le cuenta y cuándo es decisión de producto, con cuatro salidas y
contrapartidas reales) y **`welcome-beacon-reads-owner-icloud-in-secondary`** (medium — el faro lee el
iCloud del DUEÑO y decide antes que nada en «Soy nuevo»; medido que no mira la sesión secundaria, **no**
medido dónde aterriza la visita, y el ticket lo dice así).
