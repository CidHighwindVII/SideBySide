# lib/engine

- Keep estimates, selectors, and history matching pure Dart with injected dates; no Flutter, platform APIs, LLM calls, or implicit clock reads.
- Preserve enum order, JSON compatibility/defaults, worst-of `Traffic` ordering, and calendar-day/DST semantics. Catalog axes remain authoritative after load.
- Feeling records belong to dates; derive four-stage history grouping at read time without replacing the existing phase enum. Corrections must update grouping; insufficient data stays unknown.
- Personalization rules are in `new-implementation.md`: match similar stage positions, count distinct cycles, distinguish previous logs from recurrence, and treat missing logs as unknown.
- Keep selection deterministic, deduplicate canonical concepts, and rotate only general items on manual rotation. Document matching windows/weights in the plan.
- Add focused regressions for changed matching/date/model rules; keep `dart test test/engine_test.dart` runnable.
