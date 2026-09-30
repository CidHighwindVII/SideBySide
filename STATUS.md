# STATUS

## Support-first working-tree redesign (unverified on Flutter)
- General PT/EN catalog actions now lead without a period log; phase-specific
  social advice and fertile-window UI have been removed. Approximate phase
  labels are optional detail on Hoje. Old enum/JSON representations remain for
  backwards compatibility; old observations and phase-bound notes remain stored
  and accessible. Older suggestions are replaced, not migrated as saved data.
- One-JSON persisted phase-neutral support preferences and action usefulness
  feedback use `AppDataNotifier._set`. A negative rating rotates the selected
  suggestion and suppresses it for seven calendar days. A direct start-date picker now opens from Hoje;
  missed-start confirmation asks for the real date instead of saving a forecast.
- Period estimates show history/assumptions and uncertainty; one log is low
  confidence and the calendar retains a buffer even for regular histories.
  Generic lock-screen messages stay unchanged. The Android widget now gives
  only a neutral prompt. Source/limitations: `docs/support-evidence.md`.
- Current checks: JSON validity and PT/EN key parity passed; `git diff --check`
  passed; no Flutter imports found in `lib/engine/`. Dart/Flutter are not on
  PATH on this host, so `dart test test/engine_test.dart`,
  `flutter test test/widget_smoke_test.dart` and `flutter analyze` could not
  run. Generated l10n, Android/device and partner research remain unverified.
- Risks to revisit: existing `periodTooShort` and `cycleTooShort` input floors
  reject some real-world logs; app lock is not encryption. No backup/sync was
  added, so losing the device still loses the data. Product effectiveness is
  unproven; test acceptability with both partners before making impact claims.

Current build: **v0.12.0** (Material 3 restyle on top of v0.11.0; working tree).

## Current working-tree pass (not yet verified with Flutter)
- Implementing a partner-support redesign: warmer M3 surfaces, accessible
  calendar day actions, readable wrapping controls, a picked action + catalog
  rationale on Hoje/Amanhã, and an in-app preparation prompt near the next
  estimated start. `docs/ux-spec.md` records IA, screens and boundaries. The
  v0.12 fixed-green chrome seed is superseded by the warm tonal seed in
  `theme.dart`; **phase/traffic state hexes remain unchanged**. The missing
  calendar logged-vs-estimated colour discussion is now open for device review,
  not a blocker to incremental accessibility fixes.
- Reliability work: `_set` serializes JSON writes including wipe; a failed wipe
  restores visible state and reports failure. Notifications have one serialized,
  latest-snapshot scheduler (catalog axes when loaded), resume/locales trigger
  rescheduling, and the Android widget sync is ordered. Settings no longer
  independently re-schedule. Both notification bodies are generic in both ARBs;
  explicit period information stays in-app only. Calendar dates use local
  calendar-day construction to avoid 24-hour DST shifts.
- New regression tests cover persistence ordering, failure/wipe, locale copy,
  accessibility and preparation. **Not run here:** `dart`/`flutter` commands
  are absent from PATH. The changes are not a verified release; Flutter test,
  analyze, Android rendering and device notification/widget checks remain.
- Outstanding: normal (non-wipe) save failures are logged and kept in memory,
  but users do not yet receive an in-app persistence warning. On-device review
  is needed for contrast and large-font calendar layout. No accounts, partner
  sync or new remote data surfaces were added.

## Built
- v0.12.0 (owner design pass):
  - Stock Material 3: tonal colour scheme from the fixed brand-green seed
    (`0xFF3E8E5A`), default M3 shapes/elevation/typography/ink ripple. The
    v0.7.0 "Paper & Ink" skin (D24/§A: monochrome chrome, zero radius, 2px
    rules, heavy letter-spaced type) is gone. Phase/traffic hexes unchanged
    (contract) and still only mark state; icon+label everywhere (D25).
  - Typography unified on the M3 scale: `titleMedium` section/card headers,
    `bodyMedium` content, `bodySmall` captions, `titleLarge` today-card
    status; all w700–w900/letterSpacing overrides removed.
  - Pixel 10 (412×915 dp): new smoke test walks all tabs, day sheet, wipe
    dialog and search at 1.0× and 1.3× text scale asserting zero overflow.
    Fixed three real overflowers found by it: feedback row (Expanded),
    calendar legend labels (Flexible), badge/confidence chip row (both
    Flexible+FittedBox).
  - Goldens: `dart test test/engine_test.dart` 48/48 · `flutter test` 62/62 ·
    `flutter analyze` 0 issues.
- v0.11.0 (owner scope cut):
  - Fourth tab **Sugestões** (Dashboard, Calendário, Sugestões, Definições):
    tip of the day, "Para hoje"/warnings/context sections, phase-bound notes
    and the catalog search moved off Hoje — Dashboard now shows only
    forecast/alerts/today card/variance/tomorrow preview/feedback. Amanhã
    compact view unchanged. Shared bits (`Section`, `SectionHeader`,
    `phasePicks`) live in `ui/widgets.dart`; picks still route through
    `PhaseCatalog.pick`.
  - REMOVED "Pause everything" (v0.2.0 #9): tile, `Settings.pausedUntil`,
    engine `paused` getter. Auto-silence §4.8 (10+ days without logs) stays.
    Old JSON `pausedUntil` keys parse-and-ignore (forward-compat).
  - REMOVED backup export/import + QR sync (v0.4.0 #11/#19): `sincronizar.dart`,
    backup/QR codecs in `device.dart`, `AppData.merge`, `importData`/
    `mergeData`. Deps dropped: share_plus, file_picker, qr_flutter,
    mobile_scanner. Calendar export + widget stay.
  - "Reiniciar a app" → "Apagar todos os dados" / "Delete all data" (label +
    confirm only; `wipe()` behaviour unchanged).
  - Goldens: `dart test test/engine_test.dart` 48/48 · `flutter test` 61/61 ·
    `flutter analyze` 0 issues.
- v0.10.0 (owner UI pass):
  - Calendar: month changes by horizontal swipe (PageView) as well as chevrons;
    follicular/luteal/PMS background tints removed — only logged period,
    expected period, fertile-window dot, today, future-start and observation
    marks remain.
  - D27 superseded for regular cycles: high confidence → definite ranges
    (expected period = predicted start .. +avgPeriod−1; fertile = fixed 6-day
    window ending at ovulation). Medium/low keep the ±bandDays buffer.
  - Hoje: "Porquê?" expansion tiles and the "Na cozinha" section removed; new
    "Dica do dia" card shows the top-ranked actionable for the phase (still
    via `PhaseCatalog.pick`).
- v0.1.0–v0.8.0 — see `SPEC-COMPACT.md` version history.
- **v0.9.0** (`SPEC-v0.9.0.md`, evidence pass):
  - D27 — `CycleEngine.bandDays` (high 2 / medium 3 / low 4); `periodBandAt`,
    `ovulationBandAt`, variance card and calendar legend/bands all read it.
  - D28 — PMS window 5→7 days (`phaseAt`, `pmsStart`, shared `_pmsFirstDay`
    clamp after ovuDay+2); briefing "first PMS day" fires ~2d earlier;
    catalog PMS `status` reworded (PT+EN, estimate phrasing); axes unchanged.
  - D29 — nudge also fires on in-range variability: ≥3 gaps and max−min ≥9;
    `healthNudgeShown` once-gate kept; wording softened to "espreitar com um
    profissional"; in-app only, no notification.
  - D30 — read-only pattern card below the calendar grid: last ≤6 cycles'
    observations bucketed by `eng.phaseOrNull`, counts per phase, icon+label
    (D25), caption "notas tuas, não dados clínicos". No write path, no new
    persistence keys.
- Goldens: `dart test test/engine_test.dart` 48/48 · `flutter test` 62/62 ·
  `flutter analyze` 0 issues.

## Missing / blocked
- v0.8.0 #5 (calendar estimated-vs-logged colours) and #6 (Hoje density cut) —
  blocked on owner design discussion; `theme.dart` hexes / `hoje.dart` layout
  untouched.
- v0.9.0 acceptance "debug APK builds" + on-device dogfood — not run on
  Windows host (same as prior versions).

## Deviations (v0.9.0)
- SPEC-v0.9.0's "Files touched" omitted l10n for D27, but
  `calendarBandPeriod`/`calendarBandOvulation` hard-coded "(±2 dias)" — with
  confidence-scaled bands that string would misstate the estimate (§3). Both
  keys now take `{n}` fed by `eng.bandDays`.
- D28's ovuDay+2 clamp is provably a no-op for cycleLength ≥ 14
  (cycleLength−6 always beats ovuDay+3); kept as the spec's short-cycle
  guard, marked `// ponytail:` in the engine.
- D30 "last ≤6 cycles" boundary resolved as `today − 6 × avgCycle` (spec
  doesn't pin it).
- Widget test probes band width via the calendar legend (same `bandDays`
  source); the variance-card painter is private, so no pixel assertion.
- `STATUS.md` itself was referenced by AGENTS.md but did not exist — created
  here.
- Language selection REMOVED (owner request): no `lang` setting, no picker in
  onboarding/Definições; MaterialApp resolves ARB strings from the device
  locale, EN fallback (first in `supportedLocales`). Spec §5 onbLang step and
  §12 "language switch without restart" acceptance superseded; onboarding is
  now 5 steps.
- v0.10 definite ranges (owner request) override D27's ±band for high
  confidence only. §3 honesty kept via wording: labels still read
  "período/janela fértil **previstos**" (estimates), never facts. `bandDays`
  stays the source for medium/low + the variance card.
- v0.11 (owner request) cuts frozen-spec scope: manual pause (v0.2.0 #9),
  backup export/import (#19) and QR sync (#11) are gone — notifications are
  controlled only via per-toggle settings + OS. Spec §4/§5/§8 sections for
  these features are superseded; no new spec file was opened for the cuts.
- v0.12 (owner request) supersedes the v0.7.0 "Paper & Ink" design decision
  (D24 / §A: monochrome chrome, zero radius, 2px rules): the app now ships
  stock Material 3 tonal styling. Invariants kept: fixed seed (no dynamic
  colour), dark mode, phase/traffic hexes, icon+label for every state, §3
  honesty wording untouched.
