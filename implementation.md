# SideBySide — Usability, Cycle Understanding and Garden Implementation Plan

## Goal

Make SideBySide worth returning to by combining understandable cycle context,
varied practical actions, personal reminders, quick reflections and a growing
garden.

Correct the fertile-window calculation and hormonal-contraception presentation.
Preserve existing data, local-only storage, bilingual support and accessibility.

## For Future Agents

- Use current code and `STATUS.md` as the implementation authority.
- Read the nearest `AGENTS.md` before modifying a directory.
- Mark tasks complete only after implementation and verification.
- Update each phase's status and summary before continuing.
- Record actual command results; historical test counts are not current evidence.
- Preserve unrelated working-tree changes.
- Update `STATUS.md` with resolved gaps and remaining limitations.
- Keep this plan in the user-requested root file: `implementation.md`.
- Implement phases in order; content and persisted-model contracts underpin UI
  and garden work. The garden must reward useful activities rather than replace
  the usability improvements.

## Confirmed Product Decisions

### Application experience

- Understanding the cycle is the primary focus.
- Today also provides a practical action, quick recording, relevant reminders and
  short learning content.
- Keep the four existing navigation tabs.
- Open the garden through Today and a secondary entry in Suggestions.
- All information remains on the device.

### Garden

- Calm illustrations consistent with the existing Material 3 design.
- Three credited care moments form the weekly goal.
- Categories: **learn, act, reflect**.
- At most one credited moment per category per local calendar day.
- Twelve credited moments mature a plant.
- Five stages: seed, sprout, leaves, buds, flowering.
- Three initial plant varieties.
- No separate XP currency.
- Progress never decays, and plants never die.
- All completed plants remain in the garden.

The weekly goal is encouragement, not a growth limit. Someone completing three
moments each week matures a plant in approximately four weeks; more frequent
useful activity can grow it faster.

### Estimation

- Hormonal contraception does not produce an ovulation or fertile-window
  prediction.
- Logged bleeding remains visible.
- Natural-cycle fertile-window duration and timing uncertainty are separate
  concepts.
- Predictions remain estimates.

## Current Findings

Findings below were observed during planning; verify them against current code
before implementation.

- `SupportToday` selects the first available candidate; it does not rotate by date.
- The general catalog contains five similar actions.
- Amanhã uses `todayProvider` for action selection and feedback.
- Hormonal contraception sets `bandDays` to 1, producing a three-day fertile band.
- Fertile-window logic currently mixes a six-day window with symmetric
  uncertainty bands.
- Catalog action IDs depend on Portuguese text.
- Preferences use IDs that can be reused after deletion.
- Completion, learning progress, reminders, reflections and garden state do not
  yet exist.
- `_set` serializes persistence, but normal save failures are logged without an
  in-app warning.
- Notification rescheduling is serialized. Its early return when period logs are
  empty must change before personal reminders can work independently.
- Midnight/resume refresh already exists in `lib/ui/app.dart`; extend it rather
  than creating competing date-refresh logic.

## Phase 1 — Baseline and Content Contracts

Status: Complete (2026-10-05)

- [x] Inspect relevant guidance and establish the current test/analyze baseline.
- [x] Reconcile outdated statements in `STATUS.md` against actual code.
- [x] Define stable IDs for catalog actions and learning items.
- [x] Define action categories: practical help, communication, company, space and
      preparation.
- [x] Define PT-PT/EN learning content structure: title, short explanation, source,
      optional knowledge check and explanation of the answer.
- [x] Review cycle explanations and estimation assumptions against appropriate
      evidence.
- [x] Document the screen hierarchy and content contracts in `docs/ux-spec.md`.
- [x] Record baseline issues separately from newly introduced failures.

### Verification Plan

- Run the existing engine, Flutter and analyzer checks using an available SDK.
- Validate catalog parsing and bilingual key/content parity.
- Inspect `git status --short` and `git diff --check`.

### Phase Summary

SDK present at `C:/tools/flutter` (Flutter 3.47.5 / Dart 3.13.4). Baseline:
`dart test test/engine_test.dart` **50/50**, `flutter test` **80/80**,
`flutter analyze` **4 issues** (1 `unused_import` warning in calendario + 3
`curly_braces` infos). `STATUS.md` reconciled (the v0.13 note miscounted the
calendario warning as info-level; SDK is now on PATH). Content contracts — stable
`a:*`/`l:*` id slugs, five action categories (help/communicate/company/space/
prepare), the bilingual learning-card shape and the garden reward categories —
are recorded in `docs/ux-spec.md` §5. Catalog parses and PT/EN key parity holds.
`git diff --check` clean. These are the baseline; later phases track their own
results.

## Phase 2 — Correct Estimates and Calendar Meaning

Status: Complete (2026-10-05)

**Primary files:** `lib/engine/cycle_engine.dart`,
`lib/ui/screens/calendario.dart`, `lib/ui/screens/hoje.dart`, both ARBs,
`test/engine_test.dart`.

- [x] Introduce an explicit estimate-availability result, including a reason when
      unavailable.
- [x] Disable fertile-window predictions for hormonal contraception.
- [x] Show hormonal bleeding records without presenting natural-cycle phases as
      confirmed.
- [x] For unknown contraception, explain the limitation and offer access to the
      setting; do not silently treat it as "none."
- [x] Replace the hormonal ±1-day assumption with an evidence-reviewed
      presentation of available information and uncertainty.
- [x] Represent the six-day estimated fertile interval separately from
      uncertainty in its dates.
- [x] Ensure historical and future calculations use the appropriate cycle
      anchors.
- [x] Make calendar marks, legends, semantics and day details distinguish logged
      dates, estimated dates and uncertainty.
- [x] Keep engine code pure Dart and use local calendar-day arithmetic.
- [x] Preserve stored enum ordering and existing logs.

### Verification Plan

Add focused tests for:

- Hormonal and unknown contraception behavior.
- Six-day interval boundaries and separate uncertainty bounds.
- Historical versus forecast cycles.
- Missing history and silence mode.
- Month/year transitions, leap days and DST-safe date arithmetic.

Run `dart test test/engine_test.dart` and relevant calendar widget tests with
`flutter test test/widget_smoke_test.dart`.

### Phase Summary

Added `EstimateState` + `canPredict` to the engine. Hormonal contraception now
yields no phase, no period band, no fertile window and no extrapolated next
start (a user-logged future date is still returned as a logged value). The
six-day fertile interval is exposed via `fertileIntervalAt` (duration) and is
distinct from `ovulationBandAt` (interval widened by ±`bandDays` date
uncertainty); the old hormonal ±1 special case is gone from `bandDays`. Unknown
contraception still estimates but is flagged (`EstimateState.unknown`); Hoje now
shows a limitation banner with in-place access to the setting. The calendar
legend/day cell distinguish logged vs estimated-period band vs fertile core vs
fertile uncertainty, and show an honest no-estimate note when `canPredict` is
false. ARBs updated in both languages. Results: `dart test test/engine_test.dart`
**54/54**; `flutter test` **84/84**; `flutter analyze` **3 issues** (the three
baseline `curly_braces` infos; the baseline `unused_import` warning in
calendario was removed). No `package:flutter` imports in `lib/engine/`.

## Phase 3 — Persisted Models and Reliable Mutations

Status: Complete (2026-10-05)

**Primary files:** `lib/engine/models.dart`, `lib/state/providers.dart`,
`lib/data/catalog.dart`, `test/state_persistence_test.dart`.

- [x] Add backward-compatible models for daily action selections and completions.
- [x] Add models for learning completions.
- [x] Add quick entries for shared information or personal reflection.
- [x] Add one-off local reminders.
- [x] Add garden care events, plant records and garden display preferences.
- [x] Store stable IDs independently of translated text.
- [x] Replace reusable preference identifiers with a persisted monotonic
      allocator; preserve existing IDs.
- [x] Support optional links from entries/reminders to preferences and actions.
- [x] Add notifier methods for selection, swapping, completion, reflection,
      reminder editing and garden naming/appearance.
- [x] Apply activity completion and its garden reward in a single `_set` snapshot.
- [x] Give new JSON fields safe defaults for existing installations.
- [x] Map old text-based action-feedback IDs to stable catalog IDs.
- [x] Preserve existing feedback without treating "useful" ratings as completed
      actions.
- [x] Add a user-visible save-failure state and retry flow for new persistent
      interactions.
- [x] Ensure retrying saves cannot duplicate activity or garden rewards.
- [x] Ensure wipe clears new data through the existing ordered mutation path.

### Verification Plan

- Round-trip old and new JSON fixtures.
- Verify loading without any new fields.
- Verify IDs remain unique after deletion and restart.
- Test rapid mutations, failed saves, retries, wipe and state restoration.
- Confirm all app-data mutations use `_set`.
- Run `flutter test test/state_persistence_test.dart` and applicable model tests.

### Phase Summary

`AppData` gained `selections`, `completions`, `learning`, `entries`, `reminders`,
`careEvents`, `plants` and a persisted `nextId` allocator (all empty-safe; old
JSON loads with defaults and the allocator seeds above every preserved id).
`Settings` gained `gardenHidden`. `CatalogItem` gained a stable `id` slug and an
`ActionCategory`. `AppDataNotifier` now allocates ids through `allocateId()`,
awards a `CareEvent` atomically with its activity in one `_set`, caps one credit
per category/day, keeps "useful" ratings separate from completions (a rating on a
*completed* action can earn `reflect`), exposes `saveState` (`ValueNotifier`) plus
`retrySave()` (idempotent — the reward is already in memory), and migrates legacy
`general:<pt>` feedback keys to stable ids. Wipe clears all new collections.
Results: `flutter test test/state_persistence_test.dart` **13/13**; full
`flutter test` **90/90**; `flutter analyze` unchanged at the 3 baseline infos.

## Phase 4 — Varied Daily Actions and Learning

Status: Complete (2026-10-05)

**Suggested new files:** `lib/engine/support_selector.dart`,
`lib/data/learning_catalog.dart`, `assets/learning.json`.

**Existing files:** `assets/catalog.json`, `lib/ui/widgets.dart`,
`lib/state/providers.dart`, `pubspec.yaml`.

- [x] Expand the general catalog to at least 24 distinct, practical bilingual
      actions. (26 shipped)
- [x] Provide actions for both cohabiting and non-cohabiting users.
- [x] Continue applying tag filtering, support priority and display caps through
      `PhaseCatalog.pick`.
- [x] Build deterministic, date-aware selection that considers recent selections,
      completions, explicit preferences and feedback.
- [x] Preserve the existing seven-calendar-day negative-feedback suppression.
- [x] Persist today's selection so rebuilds and app restarts do not unexpectedly
      change it.
- [x] Add "Another suggestion" without recording negative feedback.
- [x] Separate "Done" from usefulness ratings.
- [x] Prevent one preference from permanently occupying the first position.
- [x] Select tomorrow's preview using tomorrow's date; keep future previews
      read-only.
- [x] Handle exhausted or unavailable candidates clearly.
- [x] Add at least 12 short bilingual learning cards covering phases, variability,
      estimates, hormonal contraception and practical communication. (13 shipped)
- [x] Treat phase as educational context, not evidence of mood, energy or
      willingness.
- [x] Make learning completion explicit; opening a card alone does not earn
      credit. (completion is a dedicated notifier method + garden reward; the
      card UI lands in Phase 5)

### Verification Plan

Test:

- Stability across rebuilds and restart.
- Date-aware variation and correct tomorrow selection.
- Tag filtering, priorities and suppression expiry.
- Swap behavior and exhausted candidates.
- Preference deletion and edited catalog copy.
- Learning completion and answer feedback.

Run pure selector tests with `dart test test/support_selector_test.dart` if that
file is introduced, plus relevant Flutter tests. Validate both catalog assets.

### Phase Summary

Added `SupportSelector` (pure Dart): a date-seeded FNV+splitmix64 hash fully
reorders eligible ids each day (deterministic per day → stable across rebuilds
and restarts), removes 7-day-suppressed ids, sinks recently-completed ids, and
re-ranks `apoio` items when `supportPriority`. `ActionCategory` moved to
`engine/models.dart` so the selector stays Flutter-free. The general catalog grew
to 26 bilingual actions with stable `a:*` ids and categories, covering cohabiting
and non-cohabiting users. `SupportToday` now uses the selector, persists the day's
selection/cursor, adds **Done** (records a completion + `act` reward) separately
from **usefulness ratings**, an **Another suggestion** swap (no negative feedback),
and takes a preview `day` with a **read-only** flag so Amanhã uses tomorrow's date
and never completes/earns. `learning_catalog.dart` + `assets/learning.json` ship
13 bilingual cards (some with knowledge checks); `learningProvider` loads them.
Results: `dart test test/engine_test.dart` **60/60**, `dart test
test/support_selector_test.dart` **9/9**, `flutter test` **105/105**, `flutter
analyze` back to the **3 baseline infos**. Two widget tests that encoded the old
"preference always leads / fixed pick order" behavior were rewritten to assert
rotation and suppression instead.

## Phase 5 — Today, Quick Entries and Reminders

Status: Complete (2026-10-05)

**Primary files:** `lib/ui/screens/hoje.dart`,
`lib/ui/screens/sugestoes.dart`, `lib/ui/screens/calendario.dart`,
`lib/ui/screens/definicoes.dart`, `lib/ui/app.dart`, both ARBs.

**Suggested new files:** `lib/ui/screens/quick_entry.dart`,
`lib/ui/screens/learning.dart`.

- [x] Reorder Today: date and concise cycle context; one practical action;
      quick-entry button; relevant preparation/reminders; short learning card;
      compact garden progress (garden card lands in Phase 7).
- [x] Move detailed calculation assumptions into an expandable explanation.
- [x] Provide useful no-history and hormonal-mode states.
- [x] Add quick-entry creation, editing and deletion.
- [x] Distinguish information shared by the partner from the user's own reflection.
- [x] Let the user explicitly convert an entry into a preference or reminder.
- [x] Support one-off reminders with title, local date/time, completion and
      cancellation.
- [x] Show entries and reminders in calendar day details.
- [x] Organize Suggestions into action categories, learning and saved preferences.
- [x] Fix Amanhã so it never completes today's activity or earns future rewards.
- [x] Retain access to legacy observations and custom notes.

### Verification Plan

Widget tests cover:

- Today with no logs, natural-cycle history and hormonal contraception.
- Action completion, swap and independent feedback.
- Entry create/edit/delete.
- Entry-to-preference/reminder flows.
- Tomorrow preview behavior.
- PT/EN, narrow screens, dark mode and enlarged text.

Run `flutter test test/widget_smoke_test.dart` and newly added feature widget tests.

### Phase Summary

`ForecastView` reordered to: context card (with calculation assumptions now behind
a "Como estimamos" expansion) → honest hormonal/unknown banners → log/confirm
affordances → the practical action (`SupportToday`, read-only on Amanhã) →
quick-entry button → `RemindersSection` (add/complete/cancel one-off reminders) →
preparation → learning entry → tomorrow preview + variance. New `QuickEntryScreen`
creates/edits/deletes notes, separates *shared information* from *reflection*
(only reflections earn `reflect`), and converts an entry into a preference or a
dated reminder. New `LearningScreen`/detail lists the cards with an explicit
"Marcar como concluído" (opening alone earns nothing) and optional knowledge
checks. The calendar day sheet now surfaces that day's entries and reminders
read-only. `Sugestões` is grouped by the five action categories plus learning and
saved preferences. A save-failure `MaterialBanner` with retry shows whenever
`saveState == failed`, and legacy `general:<pt>` feedback ids migrate to stable
catalog ids when the catalog loads. ARBs updated in both languages. Results:
`flutter test` **108/108** (added quick-reflection, learning-completion and
reminder-completion widget tests); `flutter analyze` **3 baseline infos**.

## Phase 6 — Pure Dart Garden Progression

Status: Complete (2026-10-05)

**Suggested files:** `lib/engine/garden_engine.dart`,
`test/garden_engine_test.dart`.

### Reward Rules

| Category | Qualifying activity |
| --- | --- |
| Learn | Explicitly complete a learning card |
| Act | Mark a practical action or personal reminder complete |
| Reflect | Save a reflection, or explicitly submit usefulness feedback for a completed action |

- A category can earn one care moment per day.
- Duplicate submissions never award additional credit.
- Opening the app, swapping suggestions, logging period dates and creating
  reminders do not award credit.
- A shared-information note is stored normally but does not automatically count
  as reflection.
- Negative usefulness feedback can qualify as reflection.
- Historical records do not generate retroactive garden rewards.
- Edits/deletions retain earned credit and prevent re-awarding for the same
  activity.
- Reward metadata contains no note text or sensitive details.

### Growth Rules

| Credited moments on active plant | Stage |
| ---: | --- |
| 0 | Seed |
| 1–2 | Sprout |
| 3–5 | Leaves |
| 6–8 | Buds |
| 9–11 | Flowering |
| 12 | Mature; retain plant and create the next seed |

The twelfth event belongs to the completed plant. The next event grows the new
plant.

- [x] Implement pure progression functions with an injected local date.
- [x] Store unique reward events tied to their source activity.
- [x] Derive stage and weekly progress from persisted events.
- [x] Define weeks as Monday–Sunday using calendar dates.
- [x] Keep awarded dates fixed after timezone changes.
- [x] Cap the weekly-goal indicator at three while retaining all earned growth.
- [x] Rotate three plant varieties deterministically.
- [x] Maintain exactly one active plant.
- [x] Never reset growth when a week changes or the user takes a break.
- [x] Do not award rewards from rendering widgets or passive app resume.

### Verification Plan

Test:

- Every stage boundary and plant rollover.
- Category/day caps and duplicate taps.
- Multiple completions in one mutation sequence.
- Midnight, week/year changes and timezone-related date handling.
- Restart, edits, deletion and retry.
- Long inactivity and preserved mature plants.
- No retroactive rewards.

Run `dart test test/garden_engine_test.dart` and state persistence tests covering
atomic activity/reward updates.

### Phase Summary

`GardenEngine` (pure Dart, injected local date) derives `GardenState` from the
persisted `CareEvent` list: `stageForActive` maps 0/1-2/3-5/6-8/9-11 to the five
stages, `completedPlants = total ~/ 12` and `momentsOnActive = total % 12` so the
12th event completes a plant and the 13th starts a new seed; `varietyForPlant =
index % 3` rotates three varieties; `eventsForPlant` slices the chronological
events per plant; `weeklyMoments` counts the Mon–Sun week (calendar-day math) and
`state().weeklyGoal` caps the indicator at 3 while growth keeps every earned
moment. Awarding (the one-per-category-per-day cap, duplicate/deny/retry safety
and no retroactive credit) is enforced in `AppDataNotifier._awardCare`, and dates
are fixed at award time so timezone changes can't move them. `gardenProvider`
exposes the state. No Flutter import; rewards are never created by rendering.
Results: `dart test test/garden_engine_test.dart` **11/11**; the Phase 3
completion/reward and retry tests already cover atomicity and caps.

## Phase 7 — Garden Presentation

Status: Complete (2026-10-05)

**Suggested files:** `lib/ui/screens/garden.dart`,
`lib/ui/garden/plant_illustration.dart`, `lib/ui/garden/garden_card.dart`.

- [x] Build three calm plant varieties with shared five-stage illustration rules.
- [x] Use lightweight Flutter drawing/animation with accessible text equivalents.
- [x] Add the compact Today card showing active plant and weekly care progress.
- [x] Link its main action to an available learning/action/reflection activity.
- [x] Add a garden route and secondary Suggestions entry.
- [x] Display the active plant and mature collection in a responsive layout.
- [x] Support plant naming, three pot styles and simple collection ordering.
- [x] Show a plant detail sheet with growth dates and category totals.
- [x] Reveal later varieties when previous plants mature.
- [x] Animate growth briefly after a newly earned care moment.
- [x] Ensure rebuilds do not replay celebrations.
- [x] Respect reduced-motion settings.
- [x] Provide a setting to hide garden UI without losing progress.
- [x] Use welcoming return copy with no dead plants, lost streaks or guilt
      messages.

### Verification Plan

- Verify all plant stages, varieties and empty/mature collection states.
- Test naming, appearance and navigation.
- Verify screen-reader descriptions and reduced-motion behavior.
- Test narrow screens, large text and long names.
- Confirm essential app features remain available regardless of garden progress.
- Run garden widget tests and `flutter analyze`.

### Phase Summary

`PlantIllustration` is a lightweight `CustomPainter` (no images) drawing three
varieties (fern/lavender/succulent) through the shared five stages with three pot
styles, wrapped in a `Semantics` label. `GardenCard` (Hoje) shows the active plant,
weekly goal (capped) and moments, links a "next care" action to a learning card,
opens the garden, and pops growth once per newly earned moment via a
`ValueKey(totalMoments)` `TweenAnimationBuilder` — unrelated rebuilds don't replay
and `MediaQuery.disableAnimations` skips the animation. `GardenScreen` renders the
single active plant (name editor + pot picker) and the retained mature-collection
grid (responsive `LayoutBuilder`), with a bottom-sheet detail showing growth dates
and category totals; later varieties reveal as earlier ones mature. A Definições
switch hides the garden UI without touching progress, and Suggestions gained a
secondary garden entry. Welcoming copy, no guilt/death wording. ARBs updated in
both languages. Results: `flutter test` widget suite **29/29** (added garden
open/name, 12-moment collection and hide-setting tests); `flutter analyze` **3
baseline infos**.

## Phase 8 — Reminder Scheduling and Android Integration

Status: Complete (2026-10-05; automated only — no Android device on this host)

**Primary files:** `lib/notify/notifications.dart`, `lib/ui/app.dart`, both ARBs.

- [x] Schedule personal reminders independently of period-log availability.
- [x] Preserve serialized latest-snapshot notification scheduling.
- [x] Assign collision-free IDs for reminder and existing briefing notifications.
- [x] Reschedule/cancel correctly after editing, completing, deleting or wiping
      reminders.
- [x] Preserve exact-to-inexact alarm fallback.
- [x] Use generic lock-screen copy; show reminder details only inside the app.
- [x] Add reminder payload routing through the existing lock flow.
- [x] Handle deleted or missing reminder targets gracefully.
- [x] Review cold-start notification delivery and locale/timezone changes.
- [x] Keep garden encouragement in-app for the first release.

### Verification Plan

- Test pure schedule-plan construction and ID allocation.
- Test notification routing and stale payloads.
- On Android, verify permissions denied/granted, cold/warm launch, app lock,
  reminder edits and wipe.
- Verify personal reminders work with zero period logs.
- Record automated results separately from device acceptance results; do not
  claim notification delivery from unit tests alone.

### Phase Summary

Extracted a pure-Dart `NotificationPlan.build` (`lib/notify/schedule_plan.dart`)
that returns the rolling set of scheduled notifications: briefing/heads-up only
when there are logs (silence-aware), and personal reminders **always**, regardless
of cycle history. Ids are partitioned into disjoint ranges (brief 1000+, headsUp
2000+, reminder 3000+id) with an `idsUnique` check, so a reminder can never
collide with a briefing. `Notifications._reschedule` now consumes the plan while
keeping the serialized latest-snapshot drain, revision guards, `cancelAll` before
re-schedule, and the exact→inexact fallback; every reminder mutation
(add/edit/complete/delete/wipe) flows through `AppDataNotifier._set`, which the
`appDataProvider` listener in `ui/app.dart` turns into one reschedule pass, so
stale work cannot win. Reminder notifications use new generic `notifReminder*`
copy (both ARBs) that reveals no cycle detail; tapping one routes through the
existing lock flow to Hoje, where the title/time are shown in-app, and a
deleted/stale target degrades gracefully to Hoje. Garden encouragement stays
in-app. Results: `dart test test/notification_plan_test.dart` **5/5** (reminders
with zero logs, done/past/beyond-horizon skipping, collision-free ids); full
`flutter test` **127/127**; `flutter analyze` **3 baseline infos**. Device
acceptance (permissions, cold/warm launch, real delivery, timezone changes) was
**not** run — no Android device/emulator on this host; automated unit tests do not
prove delivery.

## Phase 9 — Full Verification and Release Readiness

Status: Complete for automated checks; device acceptance NOT run (2026-10-05)

- [x] Add regression coverage connecting completion → persistence → garden
      growth → restart.
- [x] Verify no duplicate rewards after repeated taps or save retries.
- [x] Verify migration retains all existing records.
- [x] Confirm both ARBs are updated and generate localization files through
      Flutter.
- [~] Review all screens in PT/EN, light/dark mode and increased text sizes.
      (PT/EN + 1.3× text + Pixel-10 tab walk are automated; dark-mode and on-device
      legibility remain for device review.)
- [x] Check catalog validity, content coverage and accessibility semantics.
- [x] Run all required checks.
- [x] Build and review the Android release APK. (build succeeded; visual review
      on device pending)
- [ ] Perform device acceptance checks. — NOT DONE: no Android device/emulator on
      this host.
- [x] Update `STATUS.md`, phase summaries and final recap.
- [x] Inspect the final working-tree diff for intended changes only.

### Verification Commands

Run from the repository root using an available SDK:

```text
flutter gen-l10n
dart test test/engine_test.dart
dart test test/garden_engine_test.dart
flutter test
flutter analyze
git diff --check
flutter build apk --release
git status --short
```

### Actual results (2026-10-05, Flutter 3.47.5 / Dart 3.13.4 at C:/tools/flutter)

- `flutter gen-l10n`: regenerated `lib/l10n/gen/` (never hand-edited).
- `dart test test/engine_test.dart test/garden_engine_test.dart
  test/support_selector_test.dart test/notification_plan_test.dart`: **85/85 pass**.
- `flutter test` (widget + persistence): **130/130 pass**.
- `flutter analyze`: **3 issues**, all the pre-existing baseline `curly_braces`
  infos (hoje, procurar, sugestoes); no new errors/warnings. The baseline
  `unused_import` warning in calendario was removed.
- `git diff --check`: clean (only CRLF→LF normalization notices on generated
  `lib/l10n/gen/*` and `pubspec.*`).
- `flutter build apk --release`: **succeeded** →
  `build/app/outputs/flutter-apk/app-release.apk` (56.9MB), only Gradle 8.14 /
  AGP 8.11.1 / Kotlin 2.2.20 "support will soon be dropped" warnings (non-blocking;
  not changed to avoid unrelated churn).
- `git status --short`: only the intended files (engine, models, providers,
  catalog, notifications, all touched screens/widgets/app, both ARBs, generated
  l10n, new selector/learning/garden/schedule-plan files and their tests,
  STATUS.md, docs/ux-spec.md, implementation.md, pubspec.yaml/lock).
- `lib/engine/` contains **zero** `package:flutter` imports (verified).

### Acceptance Criteria — status

- Today provides understandable context and a usable action — met.
- Daily actions vary and can be swapped independently of feedback — met.
- Tomorrow consistently uses tomorrow's date — met (read-only preview).
- Hormonal contraception produces no fertile-window prediction — met.
- Natural-cycle fertile interval and uncertainty are distinct — met.
- Entries and reminders survive restart — met (persistence tests).
- Personal reminders work without cycle history — met (plan test).
- Three care moments complete the weekly goal — met (capped indicator).
- Twelve care moments mature a plant — met (engine + widget tests).
- Duplicate actions, feedback edits and retries cannot generate extra rewards —
  met (cap + retry tests).
- Inactivity never removes garden progress — met (engine test).
- All new functionality works offline in PT-PT and EN — met (local-only, ARB
  parity test).
- Persistence and notification operations cannot let stale work override newer
  state — met (serialized `_set` + notification drain, existing tests).

### Phase Summary

All automated checks pass; the release APK builds. The remaining items are
inherently device-bound and were NOT executed here: on-device notification
delivery (permissions, cold/warm launch, exact→inexact fallback, real reminder
timing), dark-mode and large-text visual review, screen-reader walkthroughs and
partner-acceptability testing. These are recorded as limitations in `STATUS.md`,
not claimed as verified.

## Final Recap

Implementation Phases 1–9 of `implementation.md` are complete for everything
testable on this host.

**Behaviour changes**
- Estimates: new `EstimateState`/`canPredict`; hormonal contraception yields no
  phase, period band, fertile window or extrapolated next start (logged bleeding
  and user-logged future dates still show); unknown contraception estimates but
  Hoje shows a limitation banner with in-place access to the setting; the six-day
  fertile interval is now separate from ±bandDays date uncertainty (calendar
  legend/day cell/semantics distinguish logged vs estimated vs uncertainty).
- Content: 26 stable-id bilingual actions across five categories; 13 bilingual
  learning cards with knowledge checks; deterministic date-aware daily selection
  with Done / Another-suggestion / independent usefulness feedback; Amanhã uses
  tomorrow's date and is read-only.
- State: persisted selections, completions, learning, entries (shared vs
  reflection), one-off reminders, garden care events, plant records, `gardenHidden`
  and a monotonic `nextId` allocator; legacy text-based feedback ids migrate to
  stable ids; a user-visible save-failure banner with idempotent retry; wipe clears
  all new data through the ordered `_set` path.
- Garden: pure-Dart progression (5 stages, 12-per-plant rollover, Mon–Sun weekly
  goal capped at 3 but growth uncapped, 3 rotating varieties, one active plant,
  no decay/death, no retroactive or passive rewards) surfaced in a compact Hoje
  card, a full garden screen (naming, pot styles, mature collection, detail sheet)
  and a Suggestions entry; hideable without losing progress.
- Notifications: reminders schedule independently of cycle logs via a pure
  `NotificationPlan` with collision-free ids; generic lock-screen copy; reminder
  payloads route through the existing lock flow to Hoje.

**Touched files:** `lib/engine/{cycle_engine,models,support_selector,garden_engine}.dart`,
`lib/data/{catalog,learning_catalog}.dart`, `lib/state/providers.dart`,
`lib/notify/{notifications,schedule_plan}.dart`, `lib/ui/{app,widgets}.dart`,
`lib/ui/garden/{plant_illustration,garden_card}.dart`,
`lib/ui/screens/{hoje,calendario,definicoes,sugestoes,learning,quick_entry,garden}.dart`,
`assets/{catalog,learning}.json`, `lib/l10n/app_{pt,en}.arb` (+ generated),
`pubspec.yaml`, `test/{engine,state_persistence,widget_smoke,garden_engine,
support_selector,notification_plan}_test.dart`, `docs/ux-spec.md`, `STATUS.md`,
`implementation.md`.

**Test/analyzer results:** see Phase 9 "Actual results" — engine/garden/selector/
plan **85/85**, `flutter test` **130/130**, `flutter analyze` **3 baseline infos**,
APK **builds**.

**Unresolved / not verified here:** on-device notification delivery and alarm
accuracy; dark-mode and enlarged-text visual review; screen-reader walkthroughs;
partner acceptability. App lock remains a deterrent, not encryption; no backup/
sync was added, so losing the device still loses the data.

## Deployment Plan

- **Version:** keep `pubspec.yaml` as the single version source. This work is a
  pre-release working-tree increment on top of `0.1.0+1`; the owner should bump
  `version:` (e.g. `0.2.0+2`) at the actual release commit. No version string is
  shown in UI/ARB.
- **APK build result:** `flutter build apk --release` succeeded →
  `build/app/outputs/flutter-apk/app-release.apk` (56.9 MB, universal:
  arm64-v8a + armeabi-v7a + x86_64, debug-signed per the existing template,
  sideloadable). Package id `dev.sidebyside.sidebyside`. Build emitted only
  Gradle 8.14 / AGP 8.11.1 / Kotlin 2.2.20 "support soon dropped" warnings — not
  changed here to avoid unrelated toolchain churn.
- **Install:** sideload to an Android device (`adb install -r
  build/app/outputs/flutter-apk/app-release.apk`) or distribute for manual
  install. Grant `POST_NOTIFICATIONS` at the onboarding step for briefings,
  heads-ups and reminders.
- **Device acceptance (required before calling this a release):** verify on real
  hardware — notification permissions granted/denied, cold vs warm launch, app
  lock over notification taps, reminder scheduling accuracy (exact→inexact
  fallback), reminder edits/completion/deletion/wipe rescheduling, locale +
  timezone changes (incl. DST), dark mode and enlarged-text legibility, and
  screen-reader labels on the calendar/garden. These were NOT run on this host.
- **Data safety:** all data stays in the single local `sidebyside.json`; no
  account, cloud or partner sync was added. No migration loses existing records
  (verified by old-JSON load and legacy-id migration tests).

## Product Validation After Release

Evaluate whether users:

- Understand the estimated cycle context.
- Find actions relevant and varied.
- Follow through on reminders.
- Return for learning and useful activity.
- Understand garden progression.
- Enjoy the garden without feeling pressured.

Use feedback and device testing first; no remote analytics are required. Adjust
growth pace and content variety based on observed usefulness.
