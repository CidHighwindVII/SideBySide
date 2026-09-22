# lib/ui

- `app.dart` hosts the four tabs (Hoje, Calendário, Sugestões, Definições), notifications listener and locale; `screens/` holds screens; `widgets.dart` shares forecast/suggestion UI; `theme.dart` uses fixed-seed Material 3 with dark mode. Preserve phase/traffic state hexes and icon + label accessibility.
- Predictions are estimates: avoid medical certainty, pregnancy wording and uterus imagery. Keep lock-screen notification copy free of cycle details.
- For **any** UI string change, even edits to existing keys, update `lib/l10n/app_pt.arb` (PT-PT, tu) and `lib/l10n/app_en.arb`; never hand-edit `lib/l10n/gen/`. Device locale selects copy, EN fallback; keep displayed dates in the resolved locale.
- Hoje/Amanhã share `ForecastView` (today offset 0, tomorrow compact offset 1). Suggestions live on the Sugestões tab and go through `PhaseCatalog.pick`, including tag/priority filtering and display caps.
