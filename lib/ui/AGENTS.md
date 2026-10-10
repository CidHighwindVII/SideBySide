# lib/ui

- `app.dart` hosts the four tabs (Today, Calendar, Suggestions, Settings), notifications listener and locale; `screens/` holds screens; `widgets.dart` shares forecast/suggestion UI; `theme.dart` uses fixed-seed Material 3 with dark mode. Preserve phase/traffic state hexes and icon + label accessibility.
- Predictions are estimates: avoid medical certainty, pregnancy wording and uterus imagery. Keep lock-screen notification copy free of cycle details.
- For **any** UI string change, even edits to existing keys, update `lib/l10n/app_en.arb` (template) and `lib/l10n/app_pt.arb` (PT-PT, tu); never hand-edit `lib/l10n/gen/`. Device locale selects copy, EN fallback; keep displayed dates in the resolved locale. Identifiers, ARB keys and file names stay in English; only user-facing copy is localized.
- Today/Tomorrow share `ForecastView` (today offset 0, tomorrow compact offset 1). Suggestions live on the Suggestions tab and go through `PhaseCatalog.pick`, including tag/priority filtering and display caps.
