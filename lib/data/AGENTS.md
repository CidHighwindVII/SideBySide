# lib/data

- `store.dart` owns one durable app-data JSON file; temp+rename is an atomic-write mechanism. Preserve ordered save/wipe and backward-compatible model loading.
- Packaged catalogs are content, not additional user-data stores. Validate stable IDs, aliases, EN/PT coverage, and parser defaults; preserve existing observations/completions during migration.
- `catalog.dart`/`PhaseCatalog.pick` remain the support filtering/priority/cap path. Loaded catalog axes override engine fallback.
- Keep Android integrations behind adapters. For summaries check actual device, configuration, language, and input support; preserve normal history on failure/unavailability.
- Model downloads are distinct from note processing: inference stays local, with no cloud fallback. Summaries never silently mutate logs or ranking; discard stale results after edits/deletion/wipe.
