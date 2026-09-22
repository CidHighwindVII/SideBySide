# SideBySide — Specification

**Tagline:** A cycle-aware companion app for boyfriends and husbands.
**Version:** 1.1 (frozen for v0.1.0 build) · **Platform:** Android (Flutter) · **Languages:** Português (PT-PT, default), English

---

## 1. Problem

Partners of menstruating people often don't know what phase of the cycle their
partner is in — and miss the signals. "Is it a good day to ask for a favor,
plan a trip, or bring up bad news?" depends a lot on where the cycle is.
SideBySide turns simple period data into a daily status estimate and concrete
suggestions for **him**.

## 2. Who it's for

- Men (boyfriends/husbands) who want to be considerate and prepared.
- MVP data source: **he logs it manually**. She does not install anything.
- Overt positioning: this is a "for him" tool, in the store listing and icon (§10).

## 3. Honesty principle (core design rule)

Everything shown is an **estimate from cycle-phase heuristics, not knowledge
about her**. The app must:
- Label statuses as predictions ("provavelmente"), never facts.
- Show a confidence level derived from data quality (cycles logged, regularity).
- Never present itself as medical advice or a surveillance tool.

## 4. Core model

### 4.1 Inputs
- Average cycle length (default 28) and average period length (default 5).
  After ≥3 completed logs, averages **auto-recompute from the last 6 logs**;
  he can pin a manual override (flag `pinned`, survives auto-update).
- **Contraception type**: `nenhum | hormonal | desconhecido` (asked in onboarding;
  see §4.7 for what it changes).
- **Cohabitation**: `moram juntos? sim | não` — filters the suggestion catalog (§6).
- Period logs: **start + end date** per cycle.
- Logs may be **future-dated** (e.g. "o próximo período começa terça dia 4,
  termina dia 9") because the start weekday shifts month to month.

### 4.2 Derived cycle phases
From last known start date and averages:

| Phase | Window (approx.) |
|---|---|
| Menstrual | Day 1 → period end |
| Follicular | Period end → ovulation − 2 |
| Ovulação | Cycle length − 14 (± fertile window of 5 days) |
| Luteal | After ovulation → 5 days before next period |
| Late luteal (PMS) | Last ~5 days before next expected period |

### 4.3 Status engine (phase → estimate)
Fixed mapping in v0.1.0 (no ML, no personalization yet):

| Phase | Likely status |
|---|---|
| Menstrual | Cansaço, cólicas, precisa de conforto |
| Follicular | Energia a subir, aberta a novidades |
| Ovulação | Melhor humor, mais sociável |
| Luteal | Energia em queda, mais seletiva |
| PMS | Irritabilidade, stress, desejos |

**Confidence:** High = ≥3 logs with low variance; Medium = some logs;
Low = only initial setup. Low confidence = explicit "estimativa limitada" messaging.

### 4.4 Suggestions engine (phase → do's and don'ts)
Suggestions come from a **content catalog** (§6), not from code. Two kinds:
- **Actionable** — he can prepare/act: "Comprar chocolate hoje", "Adiar a
  conversa sobre ginásio", "Lavar a loiça antes de ela ver".
- **Non-actionable** — context only: "Hoje ela provavelmente está mais sensível".

Catalog style: PT-PT, infinitive for instructions, concrete, warm, slightly
funny, never condescending toward her.

### 4.5 Week outlook ("quando pedir")
7-day strip with green/yellow/red rating for three axes:
**pedir favores / dar más notícias / sair e planear**. Derived purely from the
phase mapping. This is the app's signature feature.

### 4.6 Briefing de amanhã (evening notification)
Every evening at a configurable time (**default 21:00**), if tomorrow is
"noteworthy" under the hybrid rule below, the app sends **one generic
notification**:

- Content: traffic light + teaser only, e.g.
  "SideBySide — Previsão de amanhã: 🔴 dia delicado. Vê as recomendações."
  **No cycle words, no specifics on the lock screen.** All detail lives in-app.
- Tap → **Amanhã view** (Today screen layout, shifted +1 day) with the ≤3
  actionable warnings/context items for tomorrow.

**Hybrid suppression rules (confirmed):**
- Always notify on: day before expected period start, first day of PMS window,
  any phase change between today and tomorrow, day after a red day.
- Follicular/ovulation stretches with no change and no warning → **no ping**.
- A red-flag day (bad-news warning) is always notified, even in "quiet" phases.

### 4.7 Contraception & irregularity handling (v0.1.0)
Hormonal contraception can suppress or reshape the cycle — the phase model may
not apply. In v0.1.0:
- The field is stored from day one (schema ready for real modeling later).
- If `hormonal`: phase predictions still run, but a permanent banner shows —
  "Com contracetivo hormonal, as fases podem não refletir a realidade" — and
  confidence is capped at Low.
- Full modeling of contraceptive impact on status/recommendations = top
  backlog item (§9), needs research on which types (pill, IUD, implant) change what.

### 4.8 Uncertainty, silence and health
- **Bands, not days:** the calendar shows the expected period as a shaded
  ±2-day band (and ovulation window likewise), never a single confident day.
- **Silence mode:** if a predicted period start passes without a log, the app
  stops nagging — a neutral in-app card on Hoje asks "confirma a data real?"
  (data-correction loop, never a notification). After **10 days** without a
  log: all predictions halt, calendar shows "sem previsão", briefings stop.
  **Zero pregnancy language anywhere, ever** — a late period can mean many
  things, wanted or not; the app stays out of it.
- **Health nudge:** if logged cycles vary wildly (e.g. <21 or >35 days
  repeatedly), show once, in-app only: "Ciclos muito irregulares valem uma
  conversa com um médico. Não é alarme — é só informação." Not a diagnosis, not a notification.

## 5. MVP scope (v0.1.0)

### Screens
1. **Hoje** — phase, status estimate + confidence chip, actionable vs context
   suggestions, week outlook, "amanhã" preview card, **👍/👎 "a previsão
   acertou?"** (stored locally — seed for backlog personalization), and the
   §4.8 confirmation card when a prediction was missed.
2. **Calendário** — month grid, phase-colored days, expected period/ovulation
   markers as ±bands, logged & future-dated periods.
3. **Registo** (FAB) — add/edit period start+end (past or future), view auto-averages
   with optional manual pin, edit contraception and cohabitation.
4. **Definições** — language (PT-PT/EN, default device locale), briefing time,
   notification toggles, "apagar tudo".
5. **Onboarding** (first run) — 5 steps: averages + contraception + moram juntos?
   → log last period → pick briefing time → show a sample briefing so the value
   lands before any data exists.

### Notifications (all toggleable, no others in MVP)
- **21:00 Briefing de amanhã** — generic, hybrid suppression (§4.6), silent in §4.8 silence mode.
- "Período esperado em ~2 dias" — morning, one-shot heads-up.
- (No "late period" notification — correction loop is in-app only, §4.8.)

### i18n
- **PT-PT is the source language** (not a translation). EN is the second locale.
  No PT-BR in v0.1.0.
- Mechanism: Flutter's built-in `flutter gen-l10n` (ARB files, no third-party
  i18n package) for UI strings; content catalog ships as a JSON with `pt`/`en`
  fields so it stays reviewable outside the l10n pipeline.

### Non-goals for v0.1.0
Accounts, cloud, partner-facing features, iOS, import from other apps, ML/personalization,
contraception-aware predictions, multiple partner profiles (one partner only).

## 6. Content catalog

A single reviewable data file (PT-PT + EN), per phase:
status labels, actionable suggestions, warnings (the "don't do" list),
context lines, 3-axis week ratings. Every item carries a tag:
`sempre | juntos | apartados` so suggestions fit the couple's reality (§4.1).
Ship with ~10 suggestions and ~8 warnings
per phase, seeded with the user's examples (más notícias, irritar, comentários
sobre peso/ginásio). **Drafted by the developer, reviewed by you** before freeze.

## 7. Design

- **Metaphor: weather forecast for her cycle.** "Previsão", "probabilidade de
  tempestade", semáforo. Reinforces honesty (§3): it's a forecast, not a fact.
- **Material 3**, fixed brand palette (not dynamic color), phase colors used
  consistently everywhere:
  menstrual `#C2333D` · follicular `#3E8E5A` · ovulação `#D9A404` ·
  luteal `#B26A2B` · PMS `#7B4FA6`.
- **Dark mode from day one** — the briefing is read at 21:00.
- **Navigation:** 3 bottom tabs (Hoje / Calendário / Definições) + FAB "Registar período".
- **Today card:** phase color band, one-line status, confidence chip (●●○),
  ≤3 suggestions, "amanhã ↓" preview.
- **Tone:** tools-app, not medical, not cutesy. No uterus imagery in UI chrome.
  Icon/listing: overt boyfriend tool (confirmed) — e.g. two-figure mark +
  forecast motif; final design in a separate visual pass.
- **Typography:** Roboto defaults, zero custom fonts in MVP.
- **Accessibility:** never color-only — every phase/traffic light has icon + label.
- **Design process:** no mockup phase — build straight in Flutter M3; every
  milestone ends in screenshots reviewed by you ("screens are the mockups").
  Visual polish (icon, illustrations, store shots) deferred to the public-launch
  backlog item. Dogfood tolerates boring-but-clear, not ugly.

## 8. Technical

- **Flutter**, Android first. Min SDK: Android 8 (API 26).
- **State:** Riverpod. Locked — no "or Provider".
- **Persistence:** one JSON file via `path_provider` (schema below). Locked —
  Hive is ceremony for a data set that fits in memory.
  `{settings: {avgLength, periodLength, pinnedAverages, contraception,
    liveTogether, lang, briefingTime},
    logs: [{start, end, futureDated?}],
    feedback: [{date, thumbs}]}`.
  Uninstall safety = Android Auto Backup (on by default for app files) — no custom export in MVP.
- **Notifications:** `flutter_local_notifications` + `timezone`.
  - Android 13+ `POST_NOTIFICATIONS` permission requested at the **end of
    onboarding** (after value shown, not cold at first launch).
  - Briefing scheduled exact-alarm when granted; **inexact ±15 min fallback**
    accepted — a 21:00 ping does not need minute precision.
  - `RECEIVE_BOOT_COMPLETED`: re-schedule all future briefings after device reboot.
- **Testing:** the phase/suppression/averages engine is pure date math →
  `dart test` unit tests (no widget-test farm, no fixtures). One golden test
  per rule in §4.2/§4.6/§4.8. Run locally before each dogfood build.
- **Distribution (dogfood):** `flutter run` / local APK over USB. No Play Console.
- **No backend, no analytics, no permissions beyond notifications.** All data on-device.

## 9. Goal, Privacy & Backlog

**Goal of v0.1.0:** private **dogfood** — you (and maybe a couple of friends)
use it for **3 full cycles**. Success = briefings opened, thumbs ≥50% positive,
and at least one "good thing I didn't say it that day" anecdote. No Play
Console, no store listing, no Data Safety form, no icon polish until dogfood
says it's worth it. (Store work moves to post-validation backlog.)

**Privacy:** health-adjacent data about a third party. No network in MVP, no
account, one-tap "apagar todos os dados", generic notifications by design.
Future cloud sync must be opt-in with explicit consent messaging.

**Backlog (rough priority):**
1. **Contraception-aware engine**: how each method changes phases/status/recommendations.
2. **Import from other trackers** (CSV/open formats) — manual log stays supported.
3. **Partner check-in**: she taps her actual mood; real data overrides the estimate.
4. **Personalization**: tune catalog per couple using the MVP's 👍/👎 data.
5. **Public Play Store launch** (listing, icon, Data Safety, privacy policy, name-collision check).
6. **Home-screen widget** (tomorrow traffic light).
7. **Cloud sync** (Firebase is the lazy path).
8. **Companion mode** — her data source, his interface.
9. iOS.

## 10. Decisions log

| # | Topic | Decision |
|---|---|---|
| D1 | Data source v0.1.0 | Manual log by him; import from other apps = backlog |
| D2 | Future-dated logs | Supported (start+end, next month, shifted weekday) |
| D3 | Stack | Flutter, Android-first |
| D4 | Accounts/sync | Local-only in v0.1.0; cloud later |
| D5 | Partner involvement | MVP = his tool; her data later (backlog) |
| D6 | Briefing frequency | Hybrid (always on noteworthy days, silent otherwise) |
| D7 | Notification content | Generic teaser only; recommendations in-app |
| D8 | Contraception | Store the field now + honest banner; modeling = backlog #1 |
| D9 | Portuguese | PT-PT only (user is from Portugal); no PT-BR for now |
| D10 | Positioning | Overt "boyfriend tool" in store listing and icon |
| D11 | Week outlook | Signature feature: 3 axes × traffic light |
| D12 | Future-dated log vs average | Trust the log |
| D13 | Copy voice | "tu" ("Vê as recomendações") — PT-PT informal |
| D14 | Missed period | Go silent: in-app confirmation only, silence mode after 10 days, zero pregnancy language, ever |
| D15 | Feedback loop | 👍/👎 per forecast in MVP (seed for personalization) |
| D16 | Averages | Auto-recompute from last 6 logs after ≥3 logs; manual pin override |
| D17 | Cohabitation | Onboarding asks "moram juntos?"; catalog tagged `sempre/juntos/apartados` |
| D18 | v0.1.0 goal | Personal dogfood for 3 cycles; store/compliance work post-validation |
| D19 | Uncertainty display | ±2-day bands in calendar, never single confident days |

## 11. Open questions

None — spec frozen for v0.1.0.

## 12. Acceptance criteria (v0.1.0)

- Setup → Hoje shows correct phase for a known date within 1 tap.
- Future-dated log (next month, shifted weekday) renders in calendar and shifts all predictions.
- 21:00 briefing fires on a hybrid-noteworthy day, shows **no cycle words on the lock screen**, and opens the Amanhã view with ≤3 correct recommendations on tap.
- No briefing pings during a quiet follicular week.
- `contraception = hormonal` → banner visible, confidence capped at Low.
- Predicted period missed → in-app confirmation card, **no notification**; after 10 days → "sem previsão", briefings stop, no pregnancy wording anywhere.
- 4th log changes the computed average automatically; a pinned average does not.
- `moram juntos = não` → no `juntos`-tagged suggestions appear (and vice-versa).
- 👍/👎 tap persists and survives app restart.
- Wildly irregular logs → health nudge shown exactly once, in-app only.
- Language switch updates every string incl. catalog, no restart.
- Airplane mode: fully functional (proves local-only).
- "Apagar tudo" → returns to onboarding.
