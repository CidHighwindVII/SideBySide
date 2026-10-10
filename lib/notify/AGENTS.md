# lib/notify

- `notifications.dart` schedules Android-local briefings/heads-ups for a rolling 14 days. Engine `shouldBriefTonight` and silence rules govern suppression; keep exact-to-inexact scheduling fallback.
- Lock-screen title/body (`notif*` keys in **both** ARBs) must reveal no cycle details or specifics. Payloads `tomorrow` and `today` route through `ui/app.dart`, which also accepts the legacy `amanha`/`hoje` payloads from pre-rename schedules.
- Every data/settings mutation, including wipe, must reschedule via app state; serialize overlapping cancel/schedule passes so the newest state wins. Check local time zone, calendar dates, DST, weekend hours and device locale when touching scheduling. Android permissions/receivers live in `android/app/src/main/AndroidManifest.xml`.
