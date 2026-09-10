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

## Index (259)

| id | status | path |
|----|--------|------|
| account-currency-change-leaves-scheduled-and-favorites-stale | backlog | tickets/backlog/account-currency-change-leaves-scheduled-and-favorites-stale.md |
| account-currency-conversion-overlay-has-no-ceiling | backlog | tickets/backlog/account-currency-conversion-overlay-has-no-ceiling.md |
| account-form-as-medium-detent-sheet | backlog | tickets/backlog/account-form-as-medium-detent-sheet.md |
| account-goldens-freeze-read-test-times-out | backlog | tickets/backlog/account-goldens-freeze-read-test-times-out.md |
| accounts-need-more-visibility-in-the-ui | backlog | tickets/backlog/accounts-need-more-visibility-in-the-ui.md |
| adopt-terminal-claims-ready-without-checking-engine | backlog | tickets/backlog/adopt-terminal-claims-ready-without-checking-engine.md |
| adr-013-does-not-know-yala-has-its-own-commit-msg | backlog | tickets/backlog/adr-013-does-not-know-yala-has-its-own-commit-msg.md |
| after-session-redesign-review-widgets-siri-applepay-and-web-copy | backlog | tickets/backlog/after-session-redesign-review-widgets-siri-applepay-and-web-copy.md |
| ai-recommended-budgets | backlog | tickets/backlog/ai-recommended-budgets.md |
| apple-watch | backlog | tickets/backlog/apple-watch.md |
| applepay-shortcut-warm-launch-empty-data | qa | tickets/qa/applepay-shortcut-warm-launch-empty-data.md |
| apppreferences-rewritten-on-launch | blocked | tickets/blocked/apppreferences-rewritten-on-launch.md |
| approximate-mark-ors-over-whole-period | qa | tickets/qa/approximate-mark-ors-over-whole-period.md |
| appstorage-onboarding-desarma-el-aislamiento-de-tests | backlog | tickets/backlog/appstorage-onboarding-desarma-el-aislamiento-de-tests.md |
| aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app | qa | tickets/qa/aviso-de-nuevo-miembro-no-llega-hasta-abrir-la-app.md |
| backend-account-kind-complete-or-groups-only | backlog | tickets/backlog/backend-account-kind-complete-or-groups-only.md |
| beacon-routes-only-never-blocks | backlog | tickets/backlog/beacon-routes-only-never-blocks.md |
| bridge-de-grupos-pierde-la-marca-de-sus-patas | qa | tickets/qa/bridge-de-grupos-pierde-la-marca-de-sus-patas.md |
| bridge-synthesis-trusts-a-zero-converted-amount | backlog | tickets/backlog/bridge-synthesis-trusts-a-zero-converted-amount.md |
| bridge-virtual-only-currency-mismatch-is-silent | backlog | tickets/backlog/bridge-virtual-only-currency-mismatch-is-silent.md |
| budget-days-left-counts-today | backlog | tickets/backlog/budget-days-left-counts-today.md |
| budget-tied-to-income-or-expense | backlog | tickets/backlog/budget-tied-to-income-or-expense.md |
| bulk-update-account-leaves-converted-amount-stale | done | tickets/done/bulk-update-account-leaves-converted-amount-stale.md |
| canarios-y-breadcrumbs-sin-emisor | backlog | tickets/backlog/canarios-y-breadcrumbs-sin-emisor.md |
| cashflow-spend-prediction | backlog | tickets/backlog/cashflow-spend-prediction.md |
| cerrar-total-para-ante-un-check-rojo-que-no-bloquea | backlog | tickets/backlog/cerrar-total-para-ante-un-check-rojo-que-no-bloquea.md |
| changing-an-account-currency-orphans-its-whole-history | qa | tickets/qa/changing-an-account-currency-orphans-its-whole-history.md |
| chat-assistant-is-down | backlog | tickets/backlog/chat-assistant-is-down.md |
| chat-assistant-plants-exchange-rate-one | qa | tickets/qa/chat-assistant-plants-exchange-rate-one.md |
| chat-creates-only-one-transaction-per-message | backlog | tickets/backlog/chat-creates-only-one-transaction-per-message.md |
| chat-draft-drops-the-expense-sign | qa | tickets/qa/chat-draft-drops-the-expense-sign.md |
| chat-draft-sign-can-contradict-its-subcategory | qa | tickets/qa/chat-draft-sign-can-contradict-its-subcategory.md |
| chat-draft-stamps-its-own-currency-not-the-account | qa | tickets/qa/chat-draft-stamps-its-own-currency-not-the-account.md |
| chat-ignores-expenses-only-mode | backlog | tickets/backlog/chat-ignores-expenses-only-mode.md |
| chat-rows-sealed-before-the-fix-have-no-repair-path | qa | tickets/qa/chat-rows-sealed-before-the-fix-have-no-repair-path.md |
| chat-rows-with-unsigned-amount-have-no-repair-path | qa | tickets/qa/chat-rows-with-unsigned-amount-have-no-repair-path.md |
| ci-allowlist-no-cubre-encargos-ni-qa-scripts | backlog | tickets/backlog/ci-allowlist-no-cubre-encargos-ni-qa-scripts.md |
| ci-avisador-de-rojos-advisory-tiene-la-clave-mal | done | tickets/done/ci-avisador-de-rojos-advisory-tiene-la-clave-mal.md |
| ci-checkout-v4-runs-on-deprecated-node | backlog | tickets/backlog/ci-checkout-v4-runs-on-deprecated-node.md |
| ci-destination-assumes-a-simulator-that-may-not-exist | backlog | tickets/backlog/ci-destination-assumes-a-simulator-that-may-not-exist.md |
| ci-no-corre-la-suite-del-gateway | backlog | tickets/backlog/ci-no-corre-la-suite-del-gateway.md |
| ci-runner-se-queda-sin-simuladores-y-tumba-build-for-testing | backlog | tickets/backlog/ci-runner-se-queda-sin-simuladores-y-tumba-build-for-testing.md |
| ci-suite-simulador-duplicada-y-allowlist-incompleta | done | tickets/done/ci-suite-simulador-duplicada-y-allowlist-incompleta.md |
| ci-verde-con-la-suite-en-rojo | done | tickets/done/ci-verde-con-la-suite-en-rojo.md |
| ci-warns-but-does-not-block | backlog | tickets/backlog/ci-warns-but-does-not-block.md |
| ci-workflow-cites-missing-testing-strategy | backlog | tickets/backlog/ci-workflow-cites-missing-testing-strategy.md |
| cloud-fx-rates-blob-two-faces | qa | tickets/qa/cloud-fx-rates-blob-two-faces.md |
| cloud-sign-in-discovers-account-kind | backlog | tickets/backlog/cloud-sign-in-discovers-account-kind.md |
| cloud-tx-epoch-orphan-relations | backlog | tickets/backlog/cloud-tx-epoch-orphan-relations.md |
| cloudsync-account-currency-orphans-receiver-history | backlog | tickets/backlog/cloudsync-account-currency-orphans-receiver-history.md |
| cobertura-ui-diaria-cuelga-del-push | backlog | tickets/backlog/cobertura-ui-diaria-cuelga-del-push.md |
| converted-amount-sweep-blind-to-input-changes | backlog | tickets/backlog/converted-amount-sweep-blind-to-input-changes.md |
| corpus-de-test-de-staging-crece-sin-limite | backlog | tickets/backlog/corpus-de-test-de-staging-crece-sin-limite.md |
| creategroup-throw-after-commit-loses-owner | backlog | tickets/backlog/creategroup-throw-after-commit-loses-owner.md |
| csv-import-rows-fall-in-the-chat-sign-sweep | qa | tickets/qa/csv-import-rows-fall-in-the-chat-sign-sweep.md |
| currency-change-asks-rates-for-the-old-currency | backlog | tickets/backlog/currency-change-asks-rates-for-the-old-currency.md |
| currency-change-service-tests-mirror-the-logic | backlog | tickets/backlog/currency-change-service-tests-mirror-the-logic.md |
| debounce-sync-imported-transactions | backlog | tickets/backlog/debounce-sync-imported-transactions.md |
| debt-simplification-nondeterministic-ties | backlog | tickets/backlog/debt-simplification-nondeterministic-ties.md |
| debt-tracking | backlog | tickets/backlog/debt-tracking.md |
| device-handover-groups-leak | discarded | tickets/discarded/device-handover-groups-leak.md |
| diez-worktrees-comparten-un-simulador | backlog | tickets/backlog/diez-worktrees-comparten-un-simulador.md |
| distribucion-recalcula-dos-veces-por-toque-y-sin-debounce | backlog | tickets/backlog/distribucion-recalcula-dos-veces-por-toque-y-sin-debounce.md |
| distribution-balance-kpi-skips-fx | done | tickets/done/distribution-balance-kpi-skips-fx.md |
| distribution-subviews-miss-the-new-panel-hero | backlog | tickets/backlog/distribution-subviews-miss-the-new-panel-hero.md |
| dmarc-sube-la-politica-tras-observar | backlog | tickets/backlog/dmarc-sube-la-politica-tras-observar.md |
| doble-conteo-dia1-previo-thismonth | done | tickets/done/doble-conteo-dia1-previo-thismonth.md |
| dos-criterios-de-aproximado-en-la-misma-pantalla | backlog | tickets/backlog/dos-criterios-de-aproximado-en-la-misma-pantalla.md |
| dry-run-del-avisador-envia-igual | backlog | tickets/backlog/dry-run-del-avisador-envia-igual.md |
| edgecases-extreme-minimum-flaky-under-load | backlog | tickets/backlog/edgecases-extreme-minimum-flaky-under-load.md |
| el-aviso-de-cierre-cita-el-pr-de-otra-sesion | backlog | tickets/backlog/el-aviso-de-cierre-cita-el-pr-de-otra-sesion.md |
| el-gate-no-corre-un-check-que-el-ci-si-bloquea | backlog | tickets/backlog/el-gate-no-corre-un-check-que-el-ci-si-bloquea.md |
| el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo | done | tickets/done/el-hook-que-prohibe-atribuir-a-una-ia-no-corre-en-este-repo.md |
| el-job-de-tests-del-ci-no-tiene-timeout | done | tickets/done/el-job-de-tests-del-ci-no-tiene-timeout.md |
| el-saldo-de-distribucion-no-se-entera-de-un-registro-nuevo | backlog | tickets/backlog/el-saldo-de-distribucion-no-se-entera-de-un-registro-nuevo.md |
| ensure-rates-for-existing-transactions-has-no-callers | backlog | tickets/backlog/ensure-rates-for-existing-transactions-has-no-callers.md |
| entitlement-sync-forzado-es-noop-si-hay-otro-en-vuelo | backlog | tickets/backlog/entitlement-sync-forzado-es-noop-si-hay-otro-en-vuelo.md |
| exchange-rate-detail-shows-zero-for-low-denomination-currencies | backlog | tickets/backlog/exchange-rate-detail-shows-zero-for-low-denomination-currencies.md |
| exportable-insights | backlog | tickets/backlog/exportable-insights.md |
| fab-appears-without-animation | backlog | tickets/backlog/fab-appears-without-animation.md |
| filtro-de-cuentas-se-colapsa-al-navegar-a-registros | backlog | tickets/backlog/filtro-de-cuentas-se-colapsa-al-navegar-a-registros.md |
| financial-report-amounts-unmarked | backlog | tickets/backlog/financial-report-amounts-unmarked.md |
| full-mode-activation-must-ask-where-personal-data-lives | backlog | tickets/backlog/full-mode-activation-must-ask-where-personal-data-lives.md |
| fx-approximate-mark-missing-on-secondary-surfaces | qa | tickets/qa/fx-approximate-mark-missing-on-secondary-surfaces.md |
| fx-category-totals-unmarked | backlog | tickets/backlog/fx-category-totals-unmarked.md |
| fx-historical-balance-curve-unmarked | backlog | tickets/backlog/fx-historical-balance-curve-unmarked.md |
| fx-manual-writes-seal-approximate-as-final | qa | tickets/qa/fx-manual-writes-seal-approximate-as-final.md |
| fx-partial-rate-rows-silent-1to1 | qa | tickets/qa/fx-partial-rate-rows-silent-1to1.md |
| fx-per-bucket-approximate-signal-missing | backlog | tickets/backlog/fx-per-bucket-approximate-signal-missing.md |
| fx-pnl-education-card | done | tickets/done/fx-pnl-education-card.md |
| fx-presentation-still-shows-1to1 | qa | tickets/qa/fx-presentation-still-shows-1to1.md |
| fx-previous-period-amounts-unmarked | backlog | tickets/backlog/fx-previous-period-amounts-unmarked.md |
| fx-rate-derivation-threshold-reseals-one-to-one | backlog | tickets/backlog/fx-rate-derivation-threshold-reseals-one-to-one.md |
| fx-repair-sweep-has-no-canary | backlog | tickets/backlog/fx-repair-sweep-has-no-canary.md |
| fx-repair-sweep-is-the-only-boot-sweep-without-a-uitest-gate | backlog | tickets/backlog/fx-repair-sweep-is-the-only-boot-sweep-without-a-uitest-gate.md |
| fx-repair-sweep-seals-on-a-partially-restored-store | backlog | tickets/backlog/fx-repair-sweep-seals-on-a-partially-restored-store.md |
| fx-unknown-currency-code-collapses-to-usd | backlog | tickets/backlog/fx-unknown-currency-code-collapses-to-usd.md |
| fx-widget-drops-missing-currency | backlog | tickets/backlog/fx-widget-drops-missing-currency.md |
| gate-doc-says-swift-testing-only | backlog | tickets/backlog/gate-doc-says-swift-testing-only.md |
| gateway-has-no-telemetry | backlog | tickets/backlog/gateway-has-no-telemetry.md |
| gateway-typecheck-roto-y-fuera-del-ci | backlog | tickets/backlog/gateway-typecheck-roto-y-fuera-del-ci.md |
| goldens-de-staging-solo-pasan-a-trozos | done | tickets/done/goldens-de-staging-solo-pasan-a-trozos.md |
| group-balance-service-shares-not-deduped | backlog | tickets/backlog/group-balance-service-shares-not-deduped.md |
| group-joiner-flag-consumers-still-narrow | qa | tickets/qa/group-joiner-flag-consumers-still-narrow.md |
| group-notif-credits-payer-not-editor | done | tickets/done/group-notif-credits-payer-not-editor.md |
| groups-account-association-in-storage-row | backlog | tickets/backlog/groups-account-association-in-storage-row.md |
| groups-approval-banner-stays | done | tickets/done/groups-approval-banner-stays.md |
| groups-archived-group-rejects-join | qa | tickets/qa/groups-archived-group-rejects-join.md |
| groups-archived-still-accepts-changes | backlog | tickets/backlog/groups-archived-still-accepts-changes.md |
| groups-background-emitter-no-upload | done | tickets/done/groups-background-emitter-no-upload.md |
| groups-batch-facts-plural-identity | backlog | tickets/backlog/groups-batch-facts-plural-identity.md |
| groups-budget | done | tickets/done/groups-budget.md |
| groups-canal-sin-capability-set | backlog | tickets/backlog/groups-canal-sin-capability-set.md |
| groups-cloud-identity-loss-on-migrate | discarded | tickets/discarded/groups-cloud-identity-loss-on-migrate.md |
| groups-cloud-mode-hardening-v1 | discarded | tickets/discarded/groups-cloud-mode-hardening-v1.md |
| groups-consent-door-spec | qa | tickets/qa/groups-consent-door-spec.md |
| groups-deleted-group-detail-stays-open | qa | tickets/qa/groups-deleted-group-detail-stays-open.md |
| groups-equal-split-shows-not-participating-on-peer | qa | tickets/qa/groups-equal-split-shows-not-participating-on-peer.md |
| groups-expense-notif-only-on-foreground | qa | tickets/qa/groups-expense-notif-only-on-foreground.md |
| groups-ghost-tx-on-delete | done | tickets/done/groups-ghost-tx-on-delete.md |
| groups-guest-currency-from-region | discarded | tickets/discarded/groups-guest-currency-from-region.md |
| groups-import-splitwise-tricount | backlog | tickets/backlog/groups-import-splitwise-tricount.md |
| groups-in-group-search | backlog | tickets/backlog/groups-in-group-search.md |
| groups-invite-skips-unirme-sheet-if-onboarded | qa | tickets/qa/groups-invite-skips-unirme-sheet-if-onboarded.md |
| groups-join-intent-reconciler | blocked | tickets/blocked/groups-join-intent-reconciler.md |
| groups-leave-rpc-error-10 | qa | tickets/qa/groups-leave-rpc-error-10.md |
| groups-log-expense-via-chat-voice | backlog | tickets/backlog/groups-log-expense-via-chat-voice.md |
| groups-only-second-launch-mounts-icloud-mirror | backlog | tickets/backlog/groups-only-second-launch-mounts-icloud-mirror.md |
| groups-owner-debt-no-heir-dead-end | done | tickets/done/groups-owner-debt-no-heir-dead-end.md |
| groups-owner-transfer-and-leave | qa | tickets/qa/groups-owner-transfer-and-leave.md |
| groups-pending-member-can-open-group | done | tickets/done/groups-pending-member-can-open-group.md |
| groups-pending-member-sees-detail-chrome | backlog | tickets/backlog/groups-pending-member-sees-detail-chrome.md |
| groups-pull-cuesta-cinco-viajes-por-grupo | backlog | tickets/backlog/groups-pull-cuesta-cinco-viajes-por-grupo.md |
| groups-reconnect-prune-or-rewire | done | tickets/done/groups-reconnect-prune-or-rewire.md |
| groups-settlement-reminder | qa | tickets/qa/groups-settlement-reminder.md |
| groups-settlement-reminder-discoverability | qa | tickets/qa/groups-settlement-reminder-discoverability.md |
| groups-settlement-reminder-stale-clock | backlog | tickets/backlog/groups-settlement-reminder-stale-clock.md |
| groups-shareable-summary | done | tickets/done/groups-shareable-summary.md |
| groups-stats-no-deduplica-gastos | backlog | tickets/backlog/groups-stats-no-deduplica-gastos.md |
| groups-tab-missing-panel-perf | qa | tickets/qa/groups-tab-missing-panel-perf.md |
| groups-transfer-leave-write-ahead | backlog | tickets/backlog/groups-transfer-leave-write-ahead.md |
| guest-decline-has-no-screen | qa | tickets/qa/guest-decline-has-no-screen.md |
| guest-journey-dead-screens | done | tickets/done/guest-journey-dead-screens.md |
| hero-estadisticas-stock-vs-flujo-entre-pestanas | done | tickets/done/hero-estadisticas-stock-vs-flujo-entre-pestanas.md |
| history-token-guard-echo-blind-spot | backlog | tickets/backlog/history-token-guard-echo-blind-spot.md |
| hoja-del-saldo-vivo-ignora-los-filtros-de-sesion | backlog | tickets/backlog/hoja-del-saldo-vivo-ignora-los-filtros-de-sesion.md |
| inbox-convert-draft-to-group-expense | done | tickets/done/inbox-convert-draft-to-group-expense.md |
| inbox-crash-convert-to-group-expense | done | tickets/done/inbox-crash-convert-to-group-expense.md |
| initial-balance-date-move-leaves-converted-amount-stale | backlog | tickets/backlog/initial-balance-date-move-leaves-converted-amount-stale.md |
| insights-precomputed-icon-lookup | backlog | tickets/backlog/insights-precomputed-icon-lookup.md |
| invite-aasa-requires-s-param | backlog | tickets/backlog/invite-aasa-requires-s-param.md |
| invite-backend-stale-config | qa | tickets/qa/invite-backend-stale-config.md |
| invite-link-five-causes-one-message | qa | tickets/qa/invite-link-five-causes-one-message.md |
| invite-refresh-forzado-es-noop-si-hay-otro-en-vuelo | qa | tickets/qa/invite-refresh-forzado-es-noop-si-hay-otro-en-vuelo.md |
| ipad-native-app | backlog | tickets/backlog/ipad-native-app.md |
| iphone-duo-native-app | backlog | tickets/backlog/iphone-duo-native-app.md |
| joiner-flag-residuals-cosmetic-and-service-guard | backlog | tickets/backlog/joiner-flag-residuals-cosmetic-and-service-guard.md |
| la-nocturna-de-ui-no-ha-disparado-ni-una-vez | done | tickets/done/la-nocturna-de-ui-no-ha-disparado-ni-una-vez.md |
| live-anchor-breakdown-doubles-the-approximate-glyph | backlog | tickets/backlog/live-anchor-breakdown-doubles-the-approximate-glyph.md |
| merchant-memory-suggests-across-natures-in-three-more-places | backlog | tickets/backlog/merchant-memory-suggests-across-natures-in-three-more-places.md |
| multi-currency-accounts | backlog | tickets/backlog/multi-currency-accounts.md |
| no-hay-seed-con-miembro-rechazado | backlog | tickets/backlog/no-hay-seed-con-miembro-rechazado.md |
| nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo | backlog | tickets/backlog/nocturna-del-9-sep-dejo-cuatro-xcuitest-en-rojo.md |
| notifications-not-delivered-testflight | done | tickets/done/notifications-not-delivered-testflight.md |
| onboarding-purpose-drops-groups-card | backlog | tickets/backlog/onboarding-purpose-drops-groups-card.md |
| only-testing-filters-may-be-silently-empty | backlog | tickets/backlog/only-testing-filters-may-be-silently-empty.md |
| open-worktrees-lack-the-attribution-hook | backlog | tickets/backlog/open-worktrees-lack-the-attribution-hook.md |
| orphan-alerts-behind-fullscreen-covers | backlog | tickets/backlog/orphan-alerts-behind-fullscreen-covers.md |
| panel-accounts-redesign | backlog | tickets/backlog/panel-accounts-redesign.md |
| panel-colapsa-la-seleccion-de-cuentas-a-la-primera | qa | tickets/qa/panel-colapsa-la-seleccion-de-cuentas-a-la-primera.md |
| panel-defaults-four-sections-four-widgets | done | tickets/done/panel-defaults-four-sections-four-widgets.md |
| panel-lee-el-filtro-de-cuentas-en-singular-fuera-del-saldo | backlog | tickets/backlog/panel-lee-el-filtro-de-cuentas-en-singular-fuera-del-saldo.md |
| panel-no-recalcula-al-llegar-tasas-nuevas | backlog | tickets/backlog/panel-no-recalcula-al-llegar-tasas-nuevas.md |
| pie-header-total-unmarked | backlog | tickets/backlog/pie-header-total-unmarked.md |
| preferred-currency-has-three-different-defaults | backlog | tickets/backlog/preferred-currency-has-three-different-defaults.md |
| prefs-domain-per-secondary-session | discarded | tickets/discarded/prefs-domain-per-secondary-session.md |
| prefs-synced-keys-upload-not-download | qa | tickets/qa/prefs-synced-keys-upload-not-download.md |
| push-client-ignores-yala-kind | backlog | tickets/backlog/push-client-ignores-yala-kind.md |
| qa-cloud-readme-sin-entradas-g13-04-y-g13-05 | backlog | tickets/backlog/qa-cloud-readme-sin-entradas-g13-04-y-g13-05.md |
| qa-guion-tanda-no-cubre-17-tickets | backlog | tickets/backlog/qa-guion-tanda-no-cubre-17-tickets.md |
| qa-no-puede-crear-cuenta-en-otra-divisa | done | tickets/done/qa-no-puede-crear-cuenta-en-otra-divisa.md |
| qa-yml-no-cancela-la-corrida-anterior-de-la-misma-rama | backlog | tickets/backlog/qa-yml-no-cancela-la-corrida-anterior-de-la-misma-rama.md |
| readme-index-duplicates-internal-worktree-files | backlog | tickets/backlog/readme-index-duplicates-internal-worktree-files.md |
| rebase-and-cherry-pick-skip-the-attribution-hook | backlog | tickets/backlog/rebase-and-cherry-pick-skip-the-attribution-hook.md |
| records-standalone-amount-discrepancy | backlog | tickets/backlog/records-standalone-amount-discrepancy.md |
| records-summary-chips-hide-their-amount-from-voiceover | backlog | tickets/backlog/records-summary-chips-hide-their-amount-from-voiceover.md |
| records-summary-mixes-preferred-currencies | backlog | tickets/backlog/records-summary-mixes-preferred-currencies.md |
| reentry-counts-as-fresh-install | qa | tickets/qa/reentry-counts-as-fresh-install.md |
| reentry-killswitch-closes-both-doors | qa | tickets/qa/reentry-killswitch-closes-both-doors.md |
| registros-calendario-cuenta-gastos-por-signo | qa | tickets/qa/registros-calendario-cuenta-gastos-por-signo.md |
| rejected-member-cold-tap-does-nothing | qa | tickets/qa/rejected-member-cold-tap-does-nothing.md |
| rejoin-tap-renotifies-admins | qa | tickets/qa/rejoin-tap-renotifies-admins.md |
| repair-queue-has-no-exit-for-partial-rate-rows | qa | tickets/qa/repair-queue-has-no-exit-for-partial-rate-rows.md |
| reparacion-de-tasas-no-avisa-al-panel | backlog | tickets/backlog/reparacion-de-tasas-no-avisa-al-panel.md |
| rescue-discarded-groups-pull | discarded | tickets/discarded/rescue-discarded-groups-pull.md |
| restore-beacon-outlives-account-deletion | backlog | tickets/backlog/restore-beacon-outlives-account-deletion.md |
| retire-guest-vocabulary-for-session-terms | backlog | tickets/backlog/retire-guest-vocabulary-for-session-terms.md |
| rojo-heroBuckets-thisWeek-trailing-window | done | tickets/done/rojo-heroBuckets-thisWeek-trailing-window.md |
| rojo-xcuitest-runner-muere-tras-el-primer-caso | done | tickets/done/rojo-xcuitest-runner-muere-tras-el-primer-caso.md |
| rules-testing-habla-de-ios-27-que-no-existe | backlog | tickets/backlog/rules-testing-habla-de-ios-27-que-no-existe.md |
| saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas | backlog | tickets/backlog/saldo-con-seleccion-no-contable-diverge-entre-panel-y-estadisticas.md |
| save-error-alert-lies-when-the-context-autosaves | backlog | tickets/backlog/save-error-alert-lies-when-the-context-autosaves.md |
| saving-a-mismatched-transaction-relabels-it-without-converting | backlog | tickets/backlog/saving-a-mismatched-transaction-relabels-it-without-converting.md |
| savings-tracking | backlog | tickets/backlog/savings-tracking.md |
| scheduled-payment-once-labeled-monthly | backlog | tickets/backlog/scheduled-payment-once-labeled-monthly.md |
| scheduled-payments-notif-dedup | qa | tickets/qa/scheduled-payments-notif-dedup.md |
| secondary-entry-healing-writes-owner-not-session | discarded | tickets/discarded/secondary-entry-healing-writes-owner-not-session.md |
| secondary-groups-off-wipes-owner | discarded | tickets/discarded/secondary-groups-off-wipes-owner.md |
| secondary-guest-exit-lock-and-outbox | discarded | tickets/discarded/secondary-guest-exit-lock-and-outbox.md |
| secondary-onboarding-still-crosses-owner-domain | discarded | tickets/discarded/secondary-onboarding-still-crosses-owner-domain.md |
| secondary-visit-data-lost-on-signout-unannounced | discarded | tickets/discarded/secondary-visit-data-lost-on-signout-unannounced.md |
| secondary-visitor-writes-owner-domain | discarded | tickets/discarded/secondary-visitor-writes-owner-domain.md |
| seeds-de-grupos-no-escriben-userid-ni-memberkey | backlog | tickets/backlog/seeds-de-grupos-no-escriben-userid-ni-memberkey.md |
| session-exits-one-verb-per-session | backlog | tickets/backlog/session-exits-one-verb-per-session.md |
| session-redesign-implementation-order | backlog | tickets/backlog/session-redesign-implementation-order.md |
| session-redesign-web-and-store-copy | backlog | tickets/backlog/session-redesign-web-and-store-copy.md |
| shell-derives-from-two-session-axes | backlog | tickets/backlog/shell-derives-from-two-session-axes.md |
| siri-ai-integration-ios-27 | backlog | tickets/backlog/siri-ai-integration-ios-27.md |
| siri-intent-dual-container | qa | tickets/qa/siri-intent-dual-container.md |
| smart-ai-notifications | backlog | tickets/backlog/smart-ai-notifications.md |
| staging-test-credentials-in-public-repo | done | tickets/done/staging-test-credentials-in-public-repo.md |
| staging-test-user-c-does-not-exist | backlog | tickets/backlog/staging-test-user-c-does-not-exist.md |
| stats-per-account-branch-keeps-stale-live-anchor | backlog | tickets/backlog/stats-per-account-branch-keeps-stale-live-anchor.md |
| storage-row-gate-comment-says-rollout-zero | backlog | tickets/backlog/storage-row-gate-comment-says-rollout-zero.md |
| storekit-appgroup-siri-pro-gate | qa | tickets/qa/storekit-appgroup-siri-pro-gate.md |
| subscription-success-without-pro | done | tickets/done/subscription-success-without-pro.md |
| synced-prefs-outside-prefsynckey | discarded | tickets/discarded/synced-prefs-outside-prefsynckey.md |
| tests-borran-el-store-sqlite-abierto | backlog | tickets/backlog/tests-borran-el-store-sqlite-abierto.md |
| transaction-save-helper-flake-one-per-suite | backlog | tickets/backlog/transaction-save-helper-flake-one-per-suite.md |
| transaction-service-bulk-block-is-dead-code | backlog | tickets/backlog/transaction-service-bulk-block-is-dead-code.md |
| trends-comparison-kpi-vs-curve | done | tickets/done/trends-comparison-kpi-vs-curve.md |
| trends-insight-card-v2-bullets | backlog | tickets/backlog/trends-insight-card-v2-bullets.md |
| two-qa-benches-nobody-runs | backlog | tickets/backlog/two-qa-benches-nobody-runs.md |
| uitest-compara-fechas-sin-fijar-locale | backlog | tickets/backlog/uitest-compara-fechas-sin-fijar-locale.md |
| uitest-seed-reseeds-the-corpus-without-reset | backlog | tickets/backlog/uitest-seed-reseeds-the-corpus-without-reset.md |
| undercount-dias-intervalos-cerrados | done | tickets/done/undercount-dias-intervalos-cerrados.md |
| unit-suite-nondeterministic-reds | done | tickets/done/unit-suite-nondeterministic-reds.md |
| update-banner-appstore-criteria | done | tickets/done/update-banner-appstore-criteria.md |
| verify-dual-channel-zone-in-supabase | backlog | tickets/backlog/verify-dual-channel-zone-in-supabase.md |
| vigilante-calla-si-no-puede-comprobar-la-nocturna | backlog | tickets/backlog/vigilante-calla-si-no-puede-comprobar-la-nocturna.md |
| vigilante-margen-menor-que-el-retraso-real-del-cron | backlog | tickets/backlog/vigilante-margen-menor-que-el-retraso-real-del-cron.md |
| vision-amount-sign-contract-is-only-a-prompt-example | backlog | tickets/backlog/vision-amount-sign-contract-is-only-a-prompt-example.md |
| web-domain-has-no-spf-dkim-dmarc | done | tickets/done/web-domain-has-no-spf-dkim-dmarc.md |
| weekday-bar-daily-average-unmarked | backlog | tickets/backlog/weekday-bar-daily-average-unmarked.md |
| welcome-beacon-reads-owner-icloud-in-secondary | discarded | tickets/discarded/welcome-beacon-reads-owner-icloud-in-secondary.md |
| welcome-copy-blames-owner | discarded | tickets/discarded/welcome-copy-blames-owner.md |
| welcome-fresh-start-alert-leaves-blank-screen | qa | tickets/qa/welcome-fresh-start-alert-leaves-blank-screen.md |
| welcome-privacy-branch-has-no-secondary-door | discarded | tickets/discarded/welcome-privacy-branch-has-no-secondary-door.md |
| welcome-private-card-promises-icloud-in-visit | discarded | tickets/discarded/welcome-private-card-promises-icloud-in-visit.md |
| welcome-private-fresh-start-skips-icloud-check | backlog | tickets/backlog/welcome-private-fresh-start-skips-icloud-check.md |
| welcome-start-fresh-wipes-before-ask | qa | tickets/qa/welcome-start-fresh-wipes-before-ask.md |
| widget-de-tc-no-localiza-separadores | backlog | tickets/backlog/widget-de-tc-no-localiza-separadores.md |
| widget-fallback-summary-uses-ten-rows | backlog | tickets/backlog/widget-fallback-summary-uses-ten-rows.md |
| widget-period-balance-ignores-group-bridge-adjustment | backlog | tickets/backlog/widget-period-balance-ignores-group-bridge-adjustment.md |
| widget-snapshot-visitor-overwrites-owner | discarded | tickets/discarded/widget-snapshot-visitor-overwrites-owner.md |
| wire-decoder-accepts-non-finite-money | backlog | tickets/backlog/wire-decoder-accepts-non-finite-money.md |
| wrangler-prod-onboarding-choice-percent-drift | backlog | tickets/backlog/wrangler-prod-onboarding-choice-percent-drift.md |
| yala-android | backlog | tickets/backlog/yala-android.md |
| zone-decisions-still-per-row | backlog | tickets/backlog/zone-decisions-still-per-row.md |


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
| Bugs/qa_welcome-copy-acusa-al-dueno-de-traer-datos-ajenos.md | tickets/discarded/welcome-copy-blames-owner.md |
| Bugs/qa_welcome-empiezo-de-cero-borra-antes-de-preguntar-y-falla-mudo.md | tickets/qa/welcome-start-fresh-wipes-before-ask.md |
| Bugs/qa_widget-snapshot-sin-sello-la-visita-pisa-los-datos-del-dueno.md | tickets/discarded/widget-snapshot-visitor-overwrites-owner.md |
| Bugs/reentrada-la-vuelta-cuenta-como-instalacion-nueva.md | tickets/qa/reentry-counts-as-fresh-install.md |
| Bugs/secundaria-canal-apagado-la-visita-borra-los-grupos-del-dueno.md | tickets/discarded/secondary-groups-off-wipes-owner.md |
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
| Backlog/groups-invitado-moneda-region-red-muerta.md | tickets/discarded/groups-guest-currency-from-region.md |
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
| Backlog/qa_prefs-dominio-por-sesion-secundaria.md | tickets/discarded/prefs-domain-per-secondary-session.md |
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
