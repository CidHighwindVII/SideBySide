# SideBySide

**App:** cycle-aware companion for men (boyfriends/husbands) — turns manually logged period data into a daily phase estimate + concrete suggestions for *him*. Partner never installs anything. Flutter, Android-only (API 26+, no ios/ target). PT-PT is the source language, EN second — new strings go in BOTH `app_pt.arb` + `app_en.arb`; `lib/l10n/gen/` is regenerated, never hand-edited. One partner profile, local-only, no backend/analytics/accounts.

## Non-negotiables
- **Honesty (§3):** every status is an estimate ("provavelmente"-style), never a fact; confidence from data quality; no medical advice, no surveillance framing.
- **D14:** ZERO pregnancy wording anywhere, ever — strings, catalog, notifications.
- **Notifications never show cycle words** (lock screen = generic teaser; detail in-app).
- Tone: tools-app, warm, PT-PT informal "tu" (D13); no uterus imagery; accessibility = never colour-only (icon + label on every phase/traffic state, D25).

## Core model (§4)
- Inputs: avg cycle (seed 28) + avg period (seed 5); contraception `nenhum|hormonal|desconhecido`; cohabitation `moram juntos? sim|não`; logs = start+end per cycle, future-dated allowed (D2; **D12: trust the log over predictions**).
- Averages (**D20, superseding D16**): history-only — **median** (not mean) of last 6 gaps once ≥3 logs; hidden 28/5 seed while fewer (surfaced as low confidence). Pin/slider UI removed in v0.6; `cyclePinned`/`periodPinned` are dead fields kept only so old JSON parses.
- Phases from last start + averages: Menstrual (day 1→end of period) · Follicular (→ovulation−2) · Ovulação (cycle length−14, ±5 fertile window) · Luteal · PMS (last ~7 days, D28 — clamped after the ovulation window). Fixed phase→status mapping, no ML.
- Confidence: High = ≥3 low-variance logs · Medium = some · Low = setup-only ("estimativa limitada" messaging).
- Suggestions (§6): from `assets/catalog.json`, never code — actionable / context / warnings; tags `sempre|juntos|apartados` filtered by cohabitation (D17); render ONLY via `PhaseCatalog.pick` (≤3 per section, `apoio` re-rank when intensive support on); `nutrition` list = "Na cozinha" section; actionable items have optional `why` (tap-to-expand).
- Outlook axes: `favor|news|out|energy` (D11/D8-history; **enum order load-bearing**, as is `Traffic` green<yellow<red for worst-of folds). v0.6 (D23): 14-day grid replaced by Hoje's "é boa altura para…?" card — intent chips + free text routed by keyword table (news>out>favor>energy, fallback favor); answers with traffic + reason + best of next 14 days.
- Briefing (§4.6, D6/D7): evening (~21:00 configurable; separate weekend time) — hybrid suppression: ALWAYS notify on day before expected period, PMS start, phase change today→tomorrow, day after a red day, any red-flag day; quiet follicular/ovulation stretches = no ping. Tap → Amanhã view (`ForecastView offsetDays:1, compact` — same widget as Hoje offset 0). Plus one-shot morning "período esperado em ~2 dias". `pausedUntil` = one-tap pause running the silence machinery. Exact alarm → ±15min inexact fallback; reboot reschedules.
- Hormonal contraception (D8): predictions run + permanent banner "fases podem não refletir a realidade" + confidence capped Low.
- Uncertainty (§4.8, D14/D19/D27): calendar shows confidence-scaled bands — high ±2 / medium ±3 / low ±4 (`CycleEngine.bandDays`, never re-derived in views), never single confident days; missed predicted period → in-app confirm card only, NO notification; 10 days without log → silence mode ("sem previsão", briefings halt); wildly irregular cycles (<21/>35d ×2) or in-range variability ≥9d across ≥3 gaps (D29) → health nudge shown once, in-app only.
- Extras: observations (per-day tags on calendar, "notas tuas, não dados clínicos", never feed the engine) + read-only pattern card below the calendar grid — last ≤6 cycles' notes bucketed by engine-derived phase, counts only, no new keys (D30) · custom phase-bound notes authored on Hoje (D22) · catalog search with phase filter (cohabitation still applies) · 👍/👎 feedback on Hoje (local; personalization seed, D15) · app lock: biometric + salted-SHA256 PIN in the same JSON, cold-start + resume, no wrong-PIN lockout (snooper deterrent, not a vault) · min period length **≥3 days** (D21, shared `CycleEngine.periodTooShort` guard at both end-setting sites).

## Screens
Onboarding (6 steps: **language first** → contraception+cohabitation → log last period (picker opens today, +365d cap) → briefing time → sample briefing; POST_NOTIFICATIONS asked at END) · Hoje (forecast) · Calendário (tap-to-log — no Registo screen/FAB, final scope) · Definições (pure settings + "Perfil" section: contraception, live-together, averages read-only, support) · Procurar · Sincronizar (QR) · Lock. 3 bottom tabs.

## Design (§7 → v0.7 D24–D26)
Material 3, Roboto only (no font packages), dark mode day one. **"Paper & Ink" brutalism:** bg/fg `0xFFF9F9F9`/`0xFF121212` (dark inverts), all chrome monochrome, elevation 0, 1.5–2px ink rules, w800 heavy headings. The ONLY colours are the seven **frozen** hexes: menstrual `#C2333D` · follicular `#3E8E5A` · ovulação `#D9A404` · luteal `#B26A2B` · PMS `#7B4FA6` + traffic green/yellow/red. Wide screens: 640px `_Frame`. Metaphor: weather forecast for her cycle.

## Technical (§8 invariants)
- Riverpod; ALL mutations via `AppDataNotifier._set` (atomic persist + notification reschedule via `ref.listen` in `app.dart`); never instantiate the notifier in UI.
- Persistence = exactly ONE JSON (`sidebyside.json`, path_provider, atomic tmp+rename; export shares a cache COPY only). Keys: `settings{avgLength,periodLength,pinned*(dead),contraception,liveTogether,locale,briefing*,weekend*,pausedUntil,intensiveSupport,appLockEnabled,pinSalt,pinHash,widgetEnabled,onboarded}` · `logs[]` · `feedback[]` · `observations[]` · `customCards[]`. New keys must parse with defaults (zero migration).
- `lib/engine/` is pure Dart — zero `package:flutter` imports, `dart test`-able; `daysBetween` is UTC-calendar-based (DST-safe).
- `assets/catalog.json` is the axis source of truth; `CycleEngine._axisMap` is pre-load fallback only.
- Device surfaces: calendar write = 14 one-off all-day "SxS" events into a picked calendar, auto-sync warning first, own Kotlin MethodChannel (`device_calendar` pkg unusable) · QR sync payload = backup JSON, MERGE only (logs by start, observations by date, cards by (phase,text); settings NEVER sync), chunked `SxS|i|n|text` frames, old single-frame codes still scan · Android 2×1 widget (`CycleWidgetProvider`) gated by `widgetEnabled`, updates on app writes + 30-min floor, no background refresh.
- Validation: `dart test test/engine_test.dart` (engine) · `flutter test test/widget_smoke_test.dart` (UI) · `flutter analyze` clean before done.

## Version history (all shipped unless noted)
- **v0.1.0** — everything above from `specification.md` (frozen). Goal D18: private dogfood 3 cycles before any store work.
- **v0.2.0** — median, atomic write, variance card, pause + weekend briefing, search, nutrition, comm-tactics/chores content.
- **v0.3.0** — energy axis, apoio re-rank, observations, custom cards, app lock (schema bump).
- **v0.4.0** — backup export/import, QR sync, calendar write, widget (`widgetEnabled` bump).
- **v0.5.0** — pin UI (re-removed by v0.6), calendar picker, QR chunking, adaptive icon.
- **v0.6.0** — dogfood: +365d future start, D21 ≥3-day periods, D20 history-only averages, D22 notes on Hoje, phase search, D23 ask card, `why` explanations.
- **v0.7.0** — UI-only Paper & Ink pass (D24–D26); zero strings/schema/logic change.
- **v0.8.0** — language-first onboarding, back button, picker-opens-today, one-line segment labels (8px padding + FittedBox), Definições Perfil split. **NOT DONE: #5 calendar estimated-vs-logged colours, #6 Hoje density cut — blocked on owner design discussion; do not touch `theme.dart` hexes or `hoje.dart` layout until decided.**
- **v0.9.0** — evidence pass (`SPEC-v0.9.0.md`): D27 confidence-scaled bands (±2/3/4), D28 PMS window 5→7 days, D29 variability nudge, D30 read-only pattern card. Zero new persistence keys.

## Decisions log (spec §10)
D1 manual log · D2 future-dated · D3 Flutter/Android · D4 local-only · D5 his tool · D6 hybrid briefing · D7 teaser-only notifications · D8 contraception field + banner · D9 PT-PT only · D10 overt boyfriend positioning · D11 traffic outlook · D12 trust the log · D13 "tu" voice · D14 silence + zero pregnancy language · D15 👍/👎 · D16 median-of-6 (→superseded by D20) · D17 cohabitation tags · D18 dogfood first · D19 ±2-day bands (→widened by D27) · D20 history-only averages · D21 min 3-day period · D22 notes on Hoje · D23 ask card · D24 paper/ink palette · D25 icon+label always · D26 no shadows · D27 bandDays 2/3/4 · D28 PMS 7d · D29 variability nudge · D30 pattern card.

## Known deviations (STATUS)
Dead pin fields kept for parse-compat (drop next release) · `futureDated:true` written when `end==null` (nothing reads it) · `requestPermission` no-ops before `init()` · dialog `TextEditingController`s intentionally undisposed (exit-animation reads) · widget hardcodes home_widget prefs name — rename paired with `Device.widgetName` · QR splits on UTF-16 code units (pathological 3-byte payloads → file-export fallback) · share/QR/calendar success paths untestable on Windows host — on-device dogfood only.

## Done-ness (§12 essentials)
Engine 48/48 · flutter test 62/62 · analyze 0 issues · debug APK builds. Acceptance: phase correct after setup · future log shifts predictions · suppression rules hold (no pings in quiet weeks) · hormonal caps confidence + banner · 10d silence stops everything, no pregnancy wording · median robust to a single outlier · cohabitation filter holds both ways · language switch live, no restart · "apagar tudo" → onboarding · airplane mode fully functional.
