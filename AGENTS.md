# SideBySide — implementation guidance

## Source of truth
- Read the relevant phase in `new-implementation.md` before implementation; it holds approved product decisions, checklists, and handoff status. Update its checkboxes and verification results as work completes.
- Current code defines existing behavior; the plan defines target behavior. Scoped `AGENTS.md` files refine this guidance. Historical docs and agent/skill templates must not override these constraints.
- Implement in reviewable phases, starting with theme + Today. Obtain the planned rendered-prototype review before broader feature work.

## Code map
- `lib/engine/`: pure date estimates, selectors, persisted models, and future history matching.
- `lib/data/`: JSON store, catalog parsers, Android integrations; `assets/`: packaged content.
- `lib/state/providers.dart`: state mutations/providers; `lib/notify/`: local scheduling.
- `lib/ui/`: shell, theme, screens, shared widgets, garden; `lib/l10n/`: EN/PT localization.
- `test/`: regression and widget checks. Read each area's scoped guidance when editing it.

## Invariants
- Keep engine code pure Dart. Never reorder `Phase`, `Traffic`, or `OutlookAxis`; use calendar-day arithmetic across DST. Catalog axes override engine fallback after load.
- All app-data/settings mutations, including wipe, go through notifier `_set`. Keep one durable app-data JSON file, backward-compatible models, ordered persistence, and stale async work protection.
- Render support suggestions through `PhaseCatalog.pick` with filtering, priority, and caps. Preserve explicit learning/action credit and garden progress.
- Android-local data/inference only: no cloud sync or cloud AI fallback. Optional on-device summaries must not block core features or become feeling records/predictions.
- Forecasts are estimates; historical recurrence is not clinical accuracy. No medical certainty or pregnancy wording. Lock-screen notifications reveal no cycle, feeling, or note details.
- Device locale is primary with EN fallback; never persist language. Update both ARBs for UI copy changes; never hand-edit `lib/l10n/gen/`. Keep identifiers/file names in English.

## Verification and handoff
- For applicable code changes run `dart test test/engine_test.dart`, `flutter test`, and `flutter analyze`; report unavailable checks explicitly. Documentation-only changes need reference and diff checks.
- Report touched files, behavior/guidance changes, actual verification results, and remaining gaps; confirm only intended files changed. Do not commit or push unless requested.
