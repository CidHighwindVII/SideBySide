# lib/engine

- `cycle_engine.dart` owns date-based estimates, phase/confidence/band and notification suppression rules; `models.dart` owns enums and JSON models. Use current code + `STATUS.md` for current behavior, not historical spec sections.
- Pure Dart: zero Flutter imports; keep `test/engine_test.dart` runnable with `dart test`. Add focused regression coverage when rules change.
- Do not reorder `Phase`, `Traffic`, or `OutlookAxis`; `Traffic` green < yellow < red is required for worst-of folds. Match persisted model `toJson`/`fromJson` and defaults when changing fields.
- Catalog phase axes are authoritative after load via `engineProvider`; `_axisMap` is the pre-load fallback. Keep fallback aligned with `assets/catalog.json`.
- Compare calendar days rather than elapsed 24-hour blocks across DST; forecasts are estimates, not medical facts.
