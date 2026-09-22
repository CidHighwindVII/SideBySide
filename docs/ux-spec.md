# SideBySide UX specification — partner-support companion

> Historical v0.12 UX direction. The support-first implementation described in
> `STATUS.md` and `docs/support-evidence.md` supersedes the phase/action matrix,
> fertility cues, traffic widget and first-run forecast priorities below. Use
> current code and STATUS for implemented behavior.

## 1. User persona and information architecture

An Android user wants a quick, private, respectful way to prepare for and offer useful support to his partner. She does not have to install an app. He enters period dates himself, so the forecast is **his estimate**, never a claim about her feelings, preferences, or medical state. Ask rather than assume. No server, account, partner sync, or background monitoring.

Design reference: Flo for Partners foregrounds brief education and things a partner can do ([product page](https://flo.health/product-tour/flo-for-partners)); Clue foregrounds cycle context, clear predictions and privacy ([product page](https://helloclue.com/)). These are product-pattern references, not a mandate to copy their branding or features.

Navigation: **Hoje/Today** (current estimate, confidence, one picked support action, optional preparation and tomorrow) → **Calendário/Calendar** (read estimated vs logged days, tap to mark dates/notes) → **Sugestões/Suggestions** (three capped catalog sections, personal notes, search) → **Definições/Settings** (profile, scheduling, lock, device surfaces, wipe). Notification opens an in-app forecast; no cycle detail is shown on the lock screen.

Design tokens: Material 3, warm neutral surfaces, restrained primary chrome, phase/traffic swatches only as state with icon and label. PT-PT source and EN fallback. Support dark mode and readable scaling without shrinking text. Distinguish logged (solid mark) from estimated (lighter mark plus explicit legend); never use colour alone.

## 2. Screen-by-screen UX specification and wireframes

**First run** — Five steps, progress and Back/Skip where applicable: profile → period dates → briefing time → generic sample → optional OS permission. Accessible choice chips can wrap. Do not infer partner consent from the user's setup.

```text
progress · step title and explanation
profile choices / date tiles / time / generic sample
Back    Skip (if available)     Continue
```

**Hoje / Amanhã** — Likely phase, confidence and estimated next date first; support action immediately below, using `phasePicks`/`PhaseCatalog.pick`. Include rationale only when catalog `why` exists. Near the estimated next start, show a small in-app preparation prompt; frame it as asking what is helpful. Keep the Tomorrow view compact and shared with Today.

```text
phase icon + label    confidence label
likely status · date · estimated next start
[one actionable support card + optional why]
[optional preparation prompt, in-app only]
[optional context]  [tomorrow preview]
variance / feedback (Today only)
```

**Calendário** — Swipe or arrows between months. Sunday-first weekday headings must match the grid. Cell semantics announce the full localized date, estimated or logged state and note markers, with an accessible tap action. The legend explains each icon and colour. Tap opens marking options; a notes sheet contains optional user-owned observations. Low-confidence estimates use engine bands; high confidence still says *predicted*, never certain.

```text
previous     MONTH YEAR      next
S  M  T  W  T  F  S
[7-column touchable dated grid]
pattern of your notes (when available)
icon + label legend
```

**Sugestões + search** — A single highlighted support action followed by actionable, warning and context sections. Filter by cohabitation, priority and <=3 per section exclusively through `PhaseCatalog.pick`; do not confuse authored notes with catalog advice. Search across phases and content types *before* applying per-section caps. Optional catalog rationale provides lightweight education, not a diagnosis.

**Definições + lock** — Separate profile from notification/privacy/device settings; destructive wipe requires confirmation. Briefing and heads-up controls describe generic lock-screen text. Keep app lock honest: a local snooper deterrent, not encryption. Calendar export must warn when the selected device calendar syncs externally.

**Empty, silence and failure** — With no log, offer a route to mark a day. After the silence threshold, avoid presenting stale estimates or preparation prompts. On catalog load failure, show a localized error rather than an endless spinner. Preserve keyboard, screen-reader and large-text usability for all states.

## 3. Contextual action matrix

All displayed suggestions must originate in `assets/catalog.json` and be selected by `PhaseCatalog.pick`. The examples here are editorial direction only, **not** extra hard-coded suggestions. Never assume a person's mood from a phase.

| Estimated phase | Companion's useful approach | UI treatment |
| --- | --- | --- |
| Menstrual | Ask what would help; offer practical help without presuming symptoms | One picked action plus optional why |
| Follicular | Offer a plan while leaving her free to decline | One picked action; context if available |
| Ovulation | Continue listening rather than assigning fixed traits | One picked action with uncertainty visible |
| Luteal | Prioritize support-tagged items when support preference is enabled | Re-ranked picked action, <=3 per section |
| PMS | Check what she wants and lighten practical load if welcomed | One picked action and warnings without predictions of behaviour |
| Unknown / silence | Do not render phase-specific advice | No forecast + neutral path to update logs |

Preparation appears only in-app when an expected start is nearby; its copy stays conditional. Notification titles/bodies remain generic. No cycle-specific content should appear on the lock screen.

## 4. Flutter state and local-storage architecture

Riverpod `appDataProvider` owns mutations through `AppDataNotifier._set`; persistence is one JSON via `Store`, with sequential saves and wipe. `engineProvider` derives estimates in pure Dart; never import Flutter into `lib/engine/` or reorder phase/traffic/axis enums. `catalogProvider` loads bilingual phase data and injected axes. `phasePicks` wraps `PhaseCatalog.pick` for screen rendering. `ref.listen` in `ui/app.dart` initiates serialized notification and Android-widget updates; no UI control schedules them directly. Date differences use engine calendar-day arithmetic rather than elapsed local hours. PT and EN UI copy lives in both ARBs; generated localization code is build output.

Verification when an SDK is available: `dart test test/engine_test.dart`, `flutter test test/widget_smoke_test.dart`, `flutter test test/state_persistence_test.dart`, `flutter analyze`, then Android device review for accessibility, timezone changes, lock-screen notification privacy and visual consistency. Current host has Flutter 3.47.5 at `C:/tools/flutter` (on PATH); these checks now run — see `STATUS.md` for the live baseline rather than the historical "absent" note.

## 5. Content contracts (implementation.md Phase 1)

These contracts are the shared vocabulary between the catalog, the persisted
models and the garden. They are language-independent so translated copy can be
edited without orphaning stored records.

### 5.1 Stable identifiers

- **Catalog actions** carry a stable `id` slug (`a:ask-what-helps`,
  `a:take-a-chore`, …). Selection, completion and feedback reference the slug,
  never the PT text. Legacy data keyed by `general:<pt text>` is mapped to the
  new slug on load (Phase 3).
- **Learning cards** carry a stable `id` slug (`l:phases-vary`, …). Completions
  are keyed by the slug.
- **User records** (preferences, entries, reminders, plants) use a persisted
  monotonic allocator id (`nextId` in `AppData`), so deleting a record can never
  let a new one reuse an old id. Existing preference ids are preserved.

### 5.2 Action categories

Every general action is tagged with exactly one category (`cat`):

| Category | Meaning |
| --- | --- |
| `help` | Practical help (chores, tasks, errands) |
| `communicate` | Asking, listening, checking in |
| `company` | Presence and shared time |
| `space` | Giving room / not crowding |
| `prepare` | Getting ready ahead of an estimated date |

Categories drive the Suggestions grouping and the selector's variety rules;
they never change the cohabitation `tag` filter or the ≤3 `pick` cap.

### 5.3 Learning-card shape (PT-PT source + EN)

Each card: `id`, `title`, `body` (short explanation), `source` (plain-language
evidence note, never a certainty claim), and an optional knowledge check
(`question`, `options[]`, `answer` index, `explain`). Opening a card is **not**
completion — the user explicitly marks a card done (and may answer the check),
which is the only thing that can earn a garden `learn` care moment.

### 5.4 Garden reward categories

Three care categories mirror the plan: `learn`, `act`, `reflect`. A reward
event stores `{id, category, date}` only — never note text or cycle detail.
See `implementation.md` Phase 6 for the full award/derivation rules.
