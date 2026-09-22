# lib/state

- `providers.dart`: `main.dart` overrides `appDataProvider` after `Store.load`; `engineProvider` injects catalog axes. Use the provider in UI, not a separate engine with missing axes.
- Route every data/settings mutation through `AppDataNotifier._set`, **including wipe**, so listeners see it. Coordinate wipe's file deletion with saving; serialize async persistence and the resulting notification reschedules so stale operations cannot win. Current implementation may not yet satisfy this: inspect before relying on it.
- `ui/app.dart` listens to `appDataProvider` for local notification/widget refresh. `langCodeProvider` follows the device locale for catalog/date text (EN fallback); language is not persisted.
