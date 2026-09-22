# AGENTS.md — repository guidance

## Authority and scope
- For the current v0.12 build, use current code plus `STATUS.md` as the authority; investigate discrepancies rather than silently assuming either is complete. `SPEC-COMPACT.md` is historical context only and is superseded by current code + `STATUS.md`. `specification.md` is absent; do not direct work to it or its numbered sections.
- Read only the files relevant to the task and the nearest nested `AGENTS.md`. Preserve unrelated working-tree changes. Record discovered/closed product gaps in `STATUS.md` when the task permits edits to it.

## File map
- `lib/engine/{cycle_engine,models}.dart`: pure Dart estimates, enums and persisted models; `test/engine_test.dart`.
- `assets/catalog.json` + `lib/data/catalog.dart`: phase axes, bilingual content and `PhaseCatalog.pick`; `lib/data/{store,device}.dart`: single-file persistence and Android integrations.
- `lib/state/providers.dart`: Riverpod state, catalog/engine wiring; `lib/notify/notifications.dart`: local scheduling.
- `lib/ui/app.dart`, `lib/ui/screens/`, `lib/ui/widgets.dart`, `lib/ui/theme.dart`: navigation, screens and Material 3; `lib/l10n/{app_pt,app_en}.arb`: UI copy; `test/widget_smoke_test.dart`: widget coverage.

## Cross-cutting invariants
- `lib/engine/` stays pure Dart, with zero Flutter imports. Never reorder `Phase`, `Traffic` or `OutlookAxis`; `Traffic` green < yellow < red is used by worst-of folds. Catalog axes win once loaded; engine fallback axes are for pre-load only.
- Route **all** app-data/settings mutations through `AppDataNotifier._set`, including wipe. Serialize persistence and notification rescheduling so an older async operation cannot overwrite or re-schedule after newer state; preserve one JSON persistence file. Verify actual code before claiming this invariant is implemented.
- Display suggestions through `PhaseCatalog.pick` (tag filtering, priority and caps). Android-local only: no server/cloud sync; device calendar and widget are Android integrations.
- PT-PT is source copy; whenever modifying UI strings, including existing strings, update **both** ARBs. Let Flutter generate `lib/l10n/gen/`; never hand-edit it. Device locale selects language, EN fallback.
- No pregnancy wording or medical certainty: predictions remain estimates. Notifications contain no cycle details or specifics on the lock screen. Keep local calendar-day arithmetic and locale/time-zone handling correct (including DST, weekday and language resolution).

## Verification and report checklist
- With Flutter SDK/Dart toolchains available, run `dart test test/engine_test.dart`, `flutter test`, and `flutter analyze` for applicable changes. If unavailable, explicitly state which checks could not run; do not repeat historical pass counts as current results.
- Report touched files, behavior/guidance changes, test/analyze results (or toolchain blocker), and any observed gaps or unresolved risks. Check that only intended files changed before finishing.
