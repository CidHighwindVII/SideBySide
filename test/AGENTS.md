# test

- Follow phase verification in `new-implementation.md`; assert observable behavior and meaningful boundaries rather than mirroring implementation.
- Keep engine/history/model rules pure-Dart testable: date corrections, DST, sparse records, distinct cycles, aliases/custom merges, and deterministic general-only rotation.
- Persistence tests use fake stores: old JSON, ordered saves/wipe, failure recovery, and stale async results. Never touch the device data file.
- Widget tests reuse file-backed `catalogOverride`; pin dispatcher `locale` and `locales`. Cover EN/PT, normal phone size, large text, light/dark, and Calendar/History/Learn flows.
- Validate catalog IDs/translations/aliases and lesson source/quiz metadata. Fake summary availability/language/failure states; report real-device coverage separately.
- Run `dart test test/engine_test.dart`, `flutter test`, and `flutter analyze` as applicable; report actual results or blockers, never historical pass counts.
