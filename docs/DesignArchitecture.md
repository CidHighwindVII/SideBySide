# SideBySide — Architecture Design

Status: accepted, 2026-10-10. Decisions locked: **Option A + C (harden the modular
monolith + package decomposition), Option B (embedded store) rejected**; entitlement
flag stored **outside** `sidebyside.json`; **wipe covers all device surfaces**.
Supersedes nothing; `lib/*/AGENTS.md` remain the binding module contracts.

## 1. Current-state assessment (verified against code)

**Layering.** `ui → state → engine → data` holds mostly, with three leaks:
- `ui/app.dart` and `ui/screens/definicoes.dart` call `Device` statics directly
  (ui→data bypass).
- `notify/notifications.dart` imports generated l10n (Flutter inside notify;
  makes `Notifications` untestable headlessly).
- `engine` is genuinely pure (`cycle_engine.dart` imports only `dart:math`;
  `schedule_plan.dart` is pure and `dart test`-covered) — but constraint 3
  (engine purity) holds **by convention**, not mechanically.

**Persistence.** One file, `temp+rename`, `flush: true` (`store.dart:33-39`).
Gap: `load()` swallows corruption and returns `const AppData()`
(`store.dart:26-30`) — the next save then overwrites the corrupt file, making
transient corruption permanent. No schema version field; forward compatibility
rests entirely on `fromJson` null-defaults (`models.dart:515-592`), which works
(tested) but is undocumented per-version.

**Ordering/races.** The `lib/state/AGENTS.md` warning is partly stale, partly live:
- Persistence is serialized (`_pending` chain, `providers.dart:37-56`) — ordered
  saves, failed-write recovery, wipe-last are tested
  (`state_persistence_test.dart:69-146`).
- Notification reschedule is serialized with revision-collaring (`_drain`,
  `notifications.dart:94-118`).
- Widget sync is serialized with identity-collaring (`app.dart:222-240`).
- **Live gap:** the three pipelines are serialized among themselves but not
  jointly. `ref.listen(appDataProvider)` fires reschedule/widget on state
  publish — before the disk wipe completes. A failed disk wipe leaves
  notifications cancelled and widget blanked while the file still exists
  (privacy-safe direction, inconsistent state); a successful wipe racing a
  mid-dialog edit leaves memory holding data the disk no longer has until the
  next mutation.

**nextId.** Monotonic, rebuilt past the high-water mark on load
(`models.dart:538-562`), survives delete+restart — tested
(`state_persistence_test.dart:200-217`). Sound.

**Wipe footprint — incomplete.** `Store.wipe()` deletes the JSON; the listener
cancels notifications and blanks widget labels. But:
- Calendar events written by `MainActivity.kt` ("SxS", 14 days) are never
  deleted — they outlive the wipe in the user's calendar.
- Widget prefs live in a separate `HomeWidgetPreferences` SharedPreferences file
  that is blanked, not cleared (`deleteWidgetData` unused).
- `android:allowBackup` is not disabled in the manifest — the JSON may ride into
  Google cloud backup, silently breaking hard constraint 1.

**Growth.** ~13 logs/yr + a few KB of entries/care events → single-digit MB after
a decade. Full-file rewrite is fine at this scale for years. The embedded-store
problem does not yet exist.

**Monetisation.** Zero entitlement code today. `docs/business-development.md` §4
fixes free-core + one-time unlock.

**No external API is needed.** The app's contract surface is in-process only —
Riverpod providers, a pure-Dart engine API, and one Kotlin MethodChannel
(`sidebyside/calendar`). There is no second process, no peer, no server;
designing an "API" would invent a network boundary the product promises not to
have.

## 2. Options considered

### A — Harden the modular monolith (single JSON store)

- **Boundaries.** Keep `ui / state / engine / data / notify`. Enforce direction
  `ui → state → {engine, data, notify}`; `engine → dart: only`;
  `data → engine(models)`; `notify → engine`. Wrap `Device` in a `DeviceService`
  exposed through providers (no direct ui→data imports); inject a
  `NotificationScheduler` interface so the l10n dependency moves to a
  copy-resolver at the state boundary; enforce bans via lint/CI checks.
- **Persistence.** Stay on `sidebyside.json`. Write `"schema": 1`, ignore-with-
  default on read (backward-compatible). Corruption path: rename to
  `sidebyside.json.corrupt-<ts>` and start empty — never overwrite unreadable
  data. Optional rolling `.bak` of the previous good snapshot. Growth acceptable
  to ~10 years; revisit only past ~50k per-record entries.
- **Interfaces.** `Store` becomes `abstract class Persistence { load(); save();
  wipe(); }` with `JsonPersistence` the only implementation — a seam, not a
  migration. `AppDataNotifier` keeps its command surface; add a single
  `SideEffectsCoordinator` keyed to *committed* persistence events (not raw
  state) running ordered: disk → cancelAll → reschedule → widget →
  calendar-cleanup. Engine API unchanged. Catalog seam unchanged; premium
  variant is a second asset behind `Catalog.parse`.
- **Entitlement.** `in_app_purchase` non-consumable. `queryPurchasesAsync` at
  launch is the single permitted network call; result cached in a local flag
  stored outside the cycle JSON, so offline works after first online
  verification and reinstall on the same Play account re-entitles via
  `queryPurchases`. Offline-fresh-install: stays locked until one connectivity
  window. Privacy cost: Google sees only a purchase of `premium_unlock`; cycle
  data never enters the billing code path (auditable). License-key/server
  verification is disqualified (it is a server).
- **Platform.** Unchanged: 14-day rolling plan, exact→inexact fallback
  (`notifications.dart:121-124`), boot receiver, tz re-resolution per pass,
  midnight timer + lifecycle resume. Additions: `deleteEvents` on the calendar
  channel, `HomeWidget.deleteWidgetData` on wipe, `allowBackup="false"` +
  `dataExtractionRules`.
- **Delivery.** Unchanged: CI `flutter analyze` + `dart test` + `flutter test` +
  AAB; PT closed track → open testing → production; semver `0.x` per phase.
- **Pros:** zero migration risk; preserves the one-file trust story; every
  current test stays valid; smallest diff.
- **Cons:** full-file rewrite forever (fine at this scale); O(n) scans for
  per-record deletes (irrelevant at n<10⁴); hardening is discipline, not
  machinery.
- **Constraints:** satisfies 1–6 outright; no breach; no material NFR trade-off.
- **Offline risks:** cross-pipeline race fixed by the coordinator (side effects
  keyed to committed persistence; wipe = one atomic unit of intent). `nextId`,
  stale-save ordering, midnight/DST already handled/tested.
- **Wipe:** file + cancelAll + `deleteWidgetData` + calendar `deleteEvents` +
  entitlement flag (purchase itself stays with Play — disclosed in the confirm
  dialog) + `allowBackup=false` closes the cloud leak.
- **Team:** solo–2 devs, ~1–2 weeks.
- **Roadmap:** unblocks premium catalog (second asset + flag gate), calendar
  polish (channel extension); blocks nothing.

### B — Embedded-store migration (Hive/Isar/SQLite behind a DAO seam) — REJECTED

- **Boundaries.** `data` splits into `domain` (repository interfaces) +
  `data_impl` (DAOs, migrations); `AppData` stops being the persistence unit;
  `state` orchestrates 8–12 DAOs instead of one snapshot.
- **Persistence.** Store-native versioning; one-shot transactional import of
  `sidebyside.json` (kept read-only as `sidebyside.json.imported` until N
  successful launches = rollback); migration runner with down-migrations; WAL
  journaling.
- **Interfaces.** `AppDataNotifier` re-platformed onto per-collection
  repositories; engine API unchanged (aggregates rebuilt per read).
- **Why rejected.** Not a hard-constraint breach, but: the JSON→relational split
  is the riskiest migration the app could take, paid now to avoid a cost the
  roadmap never creates; two persistence surfaces during rollout (violates the
  spirit of "one durable file" in `lib/data/AGENTS.md`); plugin supply-chain
  churn (Isar maintenance); `sqflite` not `dart test`-able, Isar needs native
  libs — persistence tests need a per-DAO in-memory fake, doubling the test
  surface; loses the human-readable "open the file, see your data, delete it"
  trust affordance; the persistence-vs-reschedule race gets worse (per-DAO
  events, more orderings). Unlocks nothing on the current roadmap.
- **Revisit trigger:** measured need (dataset past a few MB or write latency
  visible on low-end devices) — not before.

### C — Package decomposition (pure-Dart packages, JSON store kept) — ACCEPTED as step 2 of A

- **Boundaries.** Move `engine/` → `packages/sidebyside_engine` (models,
  cycle/garden engines, support_selector, schedule_plan) and catalog parsing +
  `assets/catalog.json` + `learning.json` → `packages/sidebyside_catalog`; app
  depends via `path:`. Purity becomes mechanical: a Flutter import in the
  package breaks `dart test` at the package level. Dependency direction enforced
  by the package graph.
- **Persistence:** unchanged — still one JSON file; constraint 4 untouched.
- **Interfaces.** Engine API gains a published version; provider shapes
  unchanged; catalog seam becomes a package API (`Catalog.parse`,
  `PhaseCatalog.pick`).
- **Delivery.** CI adds `dart test` per package before `flutter test` — strictly
  better headlessness; in-repo package versioning (CHANGELOG per package).
- **Pros:** constraint 3 stops depending on AGENTS.md discipline; engine/catalog
  reusable by a future offline content-validation CLI; near-zero runtime risk.
- **Cons:** two more pubspecs; path-dependency friction on Windows; version-skew
  ceremony a small team may skip under deadline; no isolation from the JSON
  store's limits; does not fix the corruption/wipe defects — those are A's job.
- **Team:** ~2–4 days.
- **Roadmap:** premium catalog JSON can ship validated content independently of
  app builds; blocks nothing.

## 3. Decision and rationale

**A, with C folded in as step 2. B rejected.**

The axis that matters for a server-free app is risk to the privacy/trust
invariant, not query performance. The dataset is provably small; B pays a
migration-risk premium on the app's most sensitive asset to solve a problem the
roadmap never creates. C converts constraint 3 from convention to machinery but
leaves the two live defects (corruption overwrite, incomplete wipe) untouched.
A fixes the defects that actually threaten the product promise, and C is a
low-cost hardening move inside A.

## 4. Migration sequence (smallest first step)

1. **Manifest `allowBackup="false"` + `dataExtractionRules` + corrupt-file
   quarantine in `store.dart` load** (rename, don't overwrite) + regression
   test. Two files, no API change — closes the silent cloud leak and the
   permanent-loss path.
2. Schema field: write `"schema": 1` in `toJson`, ignore-on-read; assert
   round-trip in `state_persistence_test.dart`.
3. `SideEffectsCoordinator`: side effects (reschedule, widget) keyed to
   *committed* persistence operations instead of raw state publish; wipe becomes
   one ordered unit (disk → cancelAll → widget clear → calendar delete). Update
   `lib/state/AGENTS.md` line 4 once true.
4. Wipe completion: `Device.deleteCalendarEvents()` (Kotlin channel +
   `MainActivity.kt` query by 'SxS' tag/app id), `HomeWidget.deleteWidgetData`,
   tests with a fake Device.
5. Package extraction (C): `packages/sidebyside_engine`,
   `packages/sidebyside_catalog`; CI runs `dart test` per package.
6. Entitlement: `in_app_purchase` non-consumable; `queryPurchases` at launch →
   local cached flag stored outside the cycle JSON; premium catalog asset gated
   behind it; document the single network call in the Play Data Safety form.

## 5. Locked decisions

| Decision | Choice |
| --- | --- |
| Architecture option | A + C; B rejected until a measured need exists |
| Entitlement flag location | Outside `sidebyside.json` (native prefs) — wipe of cycle data never touches purchase state |
| Wipe scope | All surfaces: file, notifications, widget prefs, calendar 'SxS' events |

## 6. Open decisions (non-blocking, resolve during implementation)

1. Wipe confirm-dialog copy must disclose that a Play purchase record lives with
   Google, not in the app — needs both ARBs (`app_pt.arb`, `app_en.arb`).
2. Keep the all-yellow `_axisMap` pre-load fallback (current tested behavior)
   vs hard-gating phase outlooks on catalog load. Default: keep.
3. Rolling `.bak` previous-good snapshot: optional extra safety vs a second
   durable copy of sensitive data — decide against the "one durable file"
   wording in `lib/data/AGENTS.md` before adding.
4. Calendar event tagging: confirm the Kotlin side can reliably filter
   app-created events (title 'SxS' vs an app-id tag) before wiring wipe.
