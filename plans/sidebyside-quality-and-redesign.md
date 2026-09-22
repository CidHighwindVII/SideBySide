# SideBySide reliability and redesign

Goal: preserve the local Android companion app while making persistence and notifications reliable, improving accessibility and partner-support hierarchy, and keeping future-agent guidance current. Current code plus `STATUS.md` outrank historical `SPEC-COMPACT.md`; preserve pre-existing launcher-icon edits.

## For Future Agents
Mark items complete only after verifying them. Record phase summaries, checks run or unavailable, and follow-up work here. Do not touch `lib/l10n/gen/`; update both ARBs for UI copy. Maintain pure Dart engine, stable enum order, single JSON store, and catalog picking via `PhaseCatalog.pick`.

## Phase 1: Audit and product boundaries
Status: Complete

- [x] Inspect current code, STATUS and nearest AGENTS files; identify stale references and race/privacy/accessibility gaps.
- [x] Compare the product positioning with official Flo for Partners and Clue material; choose familiar cycle-app clarity without partner sync or medical claims.
- [x] Agree on broader refactor, full redesign, in-app explanations/preparation, and a standalone UX spec.

### Verification Plan
- Confirm referenced documentation paths exist and original icon modifications remain untouched.

### Phase Summary
`specification.md` is absent; historical compact spec includes removed features. State writes and notification jobs can race, one notification exposes cycle information, calendar semantics and large-text handling need improvement. Flutter/Dart tools are not on PATH on this host.

## Phase 2: Reliability and privacy
Status: In progress

- [x] Serialize `_set` saves and wipe; add fake Store cases for rapid writes, failure, concurrent edit and wipe.
- [x] Serialize notification scheduling and eliminate UI duplicate reschedules; ensure the newest snapshot wins.
- [x] Remove cycle-specific lock-screen notification copy in BOTH ARBs; add assertions for both bodies.
- [x] Handle catalog-load errors and calendar-day/locale/timezone changes, without changing enum/model ordering.
- [ ] Execute runtime tests and analyzer on a Flutter-enabled host; resolve any findings.

### Verification Plan
- `dart test test/engine_test.dart`, `flutter test test/state_persistence_test.dart`, `flutter test test/widget_smoke_test.dart` and `flutter analyze` when SDK is available.

### Phase Summary
_(pending runtime verification; see unrun SDK checks above)_

## Phase 3: Design and accessible implementation
Status: In progress

- [x] Write `docs/ux-spec.md` (persona/IA, screen wireframes, phase/action matrix, state/storage guidance), grounded in current product constraints.
- [x] Improve Today hierarchy and Suggestions explanations, while rendering catalog items ONLY through `PhaseCatalog.pick`.
- [x] Clarify calendar semantics and text wrapping; retain existing logged/estimated colours pending device review.
- [x] Add a bounded in-app preparation affordance without revealing details on notifications or adding sync/medical claims.
- [ ] Verify PT/EN, light/dark, screen readers, narrow layouts and text scale on Flutter/Android; resolve visual or accessibility defects.

### Verification Plan
- `flutter test test/widget_smoke_test.dart` and `flutter analyze`; manually review on Android once available.

### Phase Summary
_(pending runtime/device verification; new widget tests written, not run)_

## Phase 4: Durable guidance and handoff
Status: In progress

- [x] Fix root and nested AGENTS instructions and README; eliminate missing/stale doc links and retired features.
- [x] Record closed/new gaps in `STATUS.md`; check intended file list and preserve user icon changes.
- [x] Run available static checks and record the absent Dart/Flutter toolchain.
- [ ] Run Flutter generation, tests, analyzer and Android device review on a future SDK-equipped host.

### Verification Plan
- `git diff --check`, `git status --short`, `flutter gen-l10n`, `dart test test/engine_test.dart`, `flutter test test/state_persistence_test.dart`, `flutter test test/widget_smoke_test.dart`, `flutter analyze` when toolchains are available.

### Phase Summary
_(pending SDK/device checks; `git diff --check` passed for intended text files)_

## Final Recap
_(write when all phases complete)_

## Deployment Plan
_(write when all phases complete; do not claim an Android build until it runs)_
