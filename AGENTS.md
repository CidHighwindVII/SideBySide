# AGENTS.md — repository guidance

## Authority and scope
- This file holds repo-wide invariants; directory-level `AGENTS.md` (`lib/{engine,data,state,notify,ui}/`, `test/`) refine their own areas and win on conflicts. Current code is the source of truth over docs and historical specs.

## File map
- `lib/engine/`: pure Dart estimates (`cycle_engine`, `garden_engine`, `support_selector`) plus persisted enums/models (`models`).
- `lib/data/`: single-file persistence (`store`), Android calendar/widget integrations (`device`), parsers (`catalog`, `learning_catalog`) for `assets/{catalog,learning}.json`.
- `lib/state/providers.dart`: Riverpod wiring; `lib/notify/`: local notification scheduling (`notifications`, `schedule_plan`); `lib/log.dart`: error logging.
- `lib/ui/`: `app.dart` (shell, tabs, locale listener), `screens/`, `garden/`, `widgets.dart`, Material 3 `theme.dart`; `lib/l10n/{app_pt,app_en}.arb` + generated `gen/`.
- `test/`: engine, garden, notification-plan, persistence, support-selector and widget-smoke tests.

## Cross-cutting invariants
- `lib/engine/` stays pure Dart, zero Flutter imports. Never reorder `Phase`, `Traffic` or `OutlookAxis`; `Traffic` green < yellow < red drives worst-of folds. Catalog axes win once loaded; engine fallback axes are pre-load only.
- Route **all** app-data/settings mutations through `AppDataNotifier._set`, including wipe. Serialize persistence and notification rescheduling so stale async work cannot overwrite newer state; keep exactly one JSON persistence file.
- Render suggestions only through `PhaseCatalog.pick` (tag filtering, priority, caps). Android-local only: no server/cloud sync; calendar and widget are device integrations.
- Language: the device locale is primary with EN fallback (`langCodeProvider`); language is never persisted. Update **both** ARBs for any UI string change; `lib/l10n/gen/` is generated — never hand-edit. Source code, identifiers and file names are written in English; only user-facing copy is localized.
- Predictions are estimates: no pregnancy wording, no medical certainty. Lock-screen notifications reveal no cycle details. Keep calendar-day arithmetic and locale/time-zone handling correct across DST.

## Verification and report checklist
- With toolchains available, run `dart test test/engine_test.dart`, `flutter test` and `flutter analyze` for applicable changes; otherwise state which checks could not run. Never present historical pass counts as current results.
- Report touched files, behavior/guidance changes, test/analyze results (or blocker) and remaining gaps/risks; confirm only intended files changed.
