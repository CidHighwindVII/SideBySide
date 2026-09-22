# test

- `engine_test.dart`: pure Dart engine regression tests; add focused coverage for changed rules, calendar-day/DST boundaries and enum ordering as applicable. Run `dart test test/engine_test.dart` when Dart is available.
- `widget_smoke_test.dart`: Flutter UI flows and layout; reuse `catalogOverride` (file-backed catalog) instead of rootBundle loading across widget tests. Pin both test dispatcher `locale` and `locales` when asserting translated text; cover PT/EN changes as appropriate.
- `state_persistence_test.dart`: fake Store regression checks for ordered saves, wipe, failure recovery and generic heads-up copy in both ARBs. Do not touch the device file in these tests.
- For applicable changes run `flutter test` and `flutter analyze` with an available Flutter SDK. Report actual results or explicitly state which toolchain/check is unavailable; do not use old pass counts as evidence.
