---
name: flutter-regression-verification
description: Use when verifying substantial SideBySide features, persistence migrations, multi-layer regressions, or release readiness across pure Dart, Flutter UI, catalogs, and Android adapters.
---

# Flutter Regression Verification

Build a risk-focused verification matrix and record reproducible results.
Read `test/AGENTS.md` and the relevant phase verification plan; routine checks remain part of normal development.

## Workflow
1. Inspect the change and existing tests; identify observable behavior and highest-risk boundaries.
2. Select tests at the lowest appropriate layer, then cover important integration flows.
3. Reuse fixtures/fakes and current catalog overrides rather than creating parallel test infrastructure.
4. Make new regressions fail for the actual bug or missing behavior; avoid assertions mirroring implementation.
5. Run required checks, diagnose failures, and rerun affected checks after fixes.
6. Record exact results, unavailable toolchains/hardware, and unresolved gaps in the implementation plan.

## Verification Matrix
- Engine/history: date arithmetic, corrected periods, uncertain stages, sparse data, distinct cycles, matching boundaries, and stable ranking.
- Persistence: old JSON/defaults, round trips, ordered saves/wipe, failures, custom merges, and stale work.
- Catalogs: stable unique IDs, EN/PT coverage, aliases, canonical counts, evidence/source references, and quiz bounds.
- Widgets: Calendar picker/search/removal, History provenance, general-only rotation, four-tab navigation with the Today-opened Support route, Learn/Garden credit.
- Layout/accessibility: representative phone size, large text, narrow/keyboard-open sheets, light/dark, and semantic labels.
- Android adapters: capability/language/permission states, cancellation, setup failure, and deletion/wipe invalidation.

## Test Discipline
- Use fake stores; never touch live device data in tests.
- Inject time and platform dependencies. Pin both dispatcher locale and locales for localized assertions.
- Test normal-phone layouts, not only artificially tall surfaces that hide navigation/overflow issues.
- Rendered inspection, automated tests, and device checks are separate evidence; name which actually occurred.
- Do not add golden infrastructure or broad test suites for trivial reversible edits without a concrete need.

## Required Commands
For applicable application changes:
```text
dart test test/engine_test.dart
flutter test
flutter analyze
```
For documentation/skill-only work, validate references/metadata and inspect `git diff --check` instead.
Report touched files, current outcomes, remaining gaps, and only intended changes; never substitute historical pass counts.
