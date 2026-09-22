# SideBySide

SideBySide is an Android-local Flutter companion app for following a partner's menstrual cycle with **estimated** phase forecasts and practical suggestions. It offers Hoje, Calendário, Sugestões and Definições, local briefings, optional calendar events and a home-screen widget. Predictions are not medical facts; notification previews reveal no cycle details.

## Setup

Install a Flutter SDK compatible with `pubspec.yaml` (Dart `^3.11.0`) and an Android SDK/device or emulator. From the repository root:

```sh
flutter pub get
flutter run
```

Flutter generates localization sources from `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb` (`generate: true`); do not edit `lib/l10n/gen/`. The app uses the device language (Portuguese or English, English fallback). User data persists locally in a single JSON file; there is no account or cloud sync.

## Checks

With the Flutter SDK/Dart toolchains available, run:

```sh
dart test test/engine_test.dart
flutter test
flutter analyze
```

`lib/engine/` has no Flutter imports. On hosts without the toolchains, report the unavailable checks rather than treating previous results as current. For current build scope consult code and `STATUS.md`; `SPEC-COMPACT.md` is historical context only. Repository conventions and a file map are in `AGENTS.md`. The implemented UX direction and follow-up device checks are in `docs/ux-spec.md` and `plans/sidebyside-quality-and-redesign.md`.
