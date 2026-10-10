# lib/notify

- Keep Android-local rolling scheduling, engine suppression/silence rules, and exact-to-inexact fallback.
- Lock-screen titles/bodies reveal no cycle, feeling, history, or note details. Update notification copy in both ARBs.
- Preserve `today`/`tomorrow`, legacy `hoje`/`amanha`, and reminder payload routing through `ui/app.dart` when navigation changes.
- Serialize overlapping cancel/schedule passes so newest state wins, including wipe. Check local dates, DST, weekend hours, locale, and permission behavior when modifying scheduling.
- Manifest permissions/receivers live in `android/app/src/main/AndroidManifest.xml`; optional AI features must not become scheduling prerequisites.
