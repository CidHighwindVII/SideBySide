# lib/state

- Use `providers.dart` for state and provider-backed estimates; `engineProvider` injects catalog axes. Do not construct an alternate UI engine with fallback-only axes.
- Route every mutation through `AppDataNotifier._set`, including feeling edits, custom merges, rotation, and wipe. Maintain save/wipe ordering and failure recovery.
- Persistence and notification/widget listeners are separate pipelines, not one atomic transaction. Ensure stale work cannot overwrite newer state or resurrect wiped data.
- Invalidate derived history/ranking after log edits, period corrections, or custom merges. Keep manual general-item rotation stable across reopening; language remains device-derived and unpersisted.
- Optional summarization must not block load/save or ranking; cancel/invalidate generated output when source notes change or disappear.
