---
name: android-local-integrations
description: Use when implementing Android notifications, calendar writes, home-screen widgets, platform bridges, or capability-aware on-device note summaries in SideBySide.
---

# Android Local Integrations

Keep platform features isolated, capability-aware, and independent of core app functionality.
Read `new-implementation.md` and scoped data/notification/state guidance.

## Workflow
1. Inspect Android manifests/build configuration, existing adapters, app lifecycle, and supported SDK versions.
2. Verify current official provider documentation and dependency compatibility before choosing APIs.
3. Place platform calls behind an adapter/Flutter bridge; keep engine code platform-free.
4. Define availability, permission, preparation, success, failure, and cancellation states.
5. Coordinate async work using source revision/state identity so outdated completions cannot win.
6. Test adapter contracts with fakes; separately verify actual device behavior when hardware is available.

## On-Device Summaries
- Check actual API availability for the requested device configuration and language, not installed AI apps.
- Detect available/downloadable/preparing/unavailable states; show explicit setup for required model provisioning.
- Recheck language and input-length limits. The candidate ML Kit summarizer's Portuguese support is unverified.
- Keep inference local; model downloads are distinct from submitting user notes. No cloud fallback.
- Offer concise labeled History summaries with source-note access; retain normal history if unsupported or failed.
- Keep summaries out of loading, saving, scheduling, and feeling-ranking critical paths.
- Never create feeling records from generated output or overwrite the original notes.
- Handle resource cleanup, timeout/cancellation, and stale output after source edit/delete/wipe.
- Document cache/storage decisions under the single app-data-file constraint.

## Existing Integrations
- Notifications retain generic lock-screen content, suppression, timezone/DST handling, and scheduling fallback.
- Preserve legacy/current payload routing when navigation changes.
- Widget/calendar operations must respect the latest state and permission/capability failures.
- Do not log raw notes or feelings as platform diagnostics.

## Verification and Handoff
Exercise capability/permission combinations, setup failure, unsupported language, disposal, concurrent work, and wipe.
Report Android build results and actual tested device/API/language configurations separately from mocked tests.
Reference: https://developers.google.com/ml-kit/genai/summarization/android — recheck before integration.
