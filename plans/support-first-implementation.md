# Support-first implementation handoff

Scope: implement the agreed phase-neutral, consent-first support experience
while preserving the single-file local data model and existing records. Current
code and `STATUS.md` are authoritative; `docs/support-evidence.md` summarizes
research and limitations.

## For Future Agents
Keep checkboxes accurate, run each phase's verification on an SDK-equipped
host, write results here before marking that phase Complete. Do not edit
`lib/l10n/gen/`; update both ARBs for UI copy. Preserve pure Dart engine and
enum order; publish catalog suggestions exclusively through `PhaseCatalog.pick`.

## Phase 1: Support-first behavior
Status: In progress

- [x] Replace prescriptive phase-based content with bilingual ask-first catalog.
- [x] Remove social traffic/fertility UI; keep phase labels in optional detail.
- [x] Show honest period-estimate history, buffers and useful no-log action.
- [x] Restrict reminder triggers to period timing; make widget neutral.
- [ ] Run `dart test test/engine_test.dart` and `flutter test test/widget_smoke_test.dart`.

### Verification Plan
- Run above commands; expect zero failures. Confirm current fallback axes match
  the parsed catalog. Confirm silence does not display an overdue estimate.

### Phase Summary
_(pending SDK verification)_

## Phase 2: Preferences and data integrity
Status: In progress

- [x] Add phase-neutral support preferences and seven-day suggestion suppression.
- [x] Add backward-compatible JSON for action feedback and keep legacy records.
- [x] Add privacy copy to onboarding/settings and a direct date picker.
- [ ] Run `flutter test test/state_persistence_test.dart` and widget CRUD checks.

### Verification Plan
- Expect existing and new JSON records to round-trip; wipe removes new fields,
  old records remain readable and notification bodies stay generic.

### Phase Summary
_(pending SDK verification)_

## Phase 3: UI/device validation and research
Status: Not started

- [ ] Run `flutter analyze` and `flutter test`, resolve all findings.
- [ ] Review Android accessibility, dates/locale/DST, notification privacy and
  the widget on device; inspect light/dark and large text.
- [ ] Test acceptability and task success with users and people whose dates
  might be entered; do not claim clinical or relationship impact from ratings.

### Verification Plan
- Record command output and device/user-research results here and in `STATUS.md`.

### Phase Summary
_(pending)_

## Final Recap
_(pending verification and user study)_

## Deployment Plan
_(pending SDK/device checks; do not claim release readiness yet)_
