# lib/data

- `store.dart`: exactly one durable app-data JSON file; temp+rename is an atomic-write mechanism, not a second persistence surface. Keep writes/wipe ordered with state changes; `engine/models.dart` JSON defaults must remain backward-compatible.
- `device.dart`: Android calendar writes and home-screen widget only; no backup export/import or QR sync. No cloud/server storage.
- `assets/catalog.json` supplies PT-PT + EN suggestion content and phase axes, parsed in `catalog.dart`. Once loaded, its axes override `CycleEngine._axisMap` fallback. Render suggestions through `PhaseCatalog.pick` for cohabitation tags, support priority and caps; keep status wording tentative and free of pregnancy wording.
