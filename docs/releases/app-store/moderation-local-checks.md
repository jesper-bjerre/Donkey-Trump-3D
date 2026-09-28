# Moderation local execution evidence — 2026-09-27

IN PROGRESS. Base94dc44d89929137c4ff02649da58ba8fefa29f1e plus uncommitted code; not reviewed, deployed or distribution-ready.

- Added contract/domain tests first: initial expected compile failure recorded in `/tmp/dt3d-moderation-red.log` because new moderation types did not exist.
- Backend suite progressed to89 passed,0failed,0skipped with `HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release --nologo` (`/tmp/dt3d-moderation-integration6.log`). Includes real two-store conditional races, lost report acknowledgement, schema migration/backup verification, private receipt ownership, canonical duplicate reports and capture isolation. Additional changes after that run require affected recheck.
- `python3 src/scripts/release-moderation-smoke.py` PASS: created its own previously absent loopback `highscores-release-validation`, seeded schema1, migrated through published-DLL operator mode, exercised HTTP publication/report, operator acknowledgement/removal/block and reporter status, checked blocked changed name and minimum-ten continuity. Deleted only its owned container and process. This is a synthetic operator rehearsal, not the actual owner's one-working-day acceptance.
- Pipeline contract tests first failed as intended for missing schema2 support; after changes10/10 passed. Local package roundtrip succeeded with a fixture source identifier; `/tmp/dt3d-release-package` is only packaging-test output from dirty sources and MUST NOT be deployed or treated as a candidate for that commit.
- New Swift tests first failed to compile for absent credential/receipt implementations. Focused credential/receipt/name-correction/cancellation tests now4/4 passed (`/tmp/dt3d-ios-moderation-focused2.log`). A full unit run had a simulator audio startup failure; audio retry output is not a replacement full-suite pass. Final regression remains pending.
- New report UI tests2/2 passed on iPhone13/iOS27 simulator (`/tmp/dt3d-ios-report-ui.log`): both landscape form navigation, no keyboard/free text, cancel/history and Start after unconfirmed report.
- Existing iOS baseline had63 passed test cases,0failed,3 explicit integration skips. Owned transport/performance fixtures must remove those skips before final release checks.

Unfinished checks include full error mapping, maximum-field reserve/outage cases, all operator replay cases, final Swift/real-HTTP/performance regression, live MI migration/retention, exact candidate physical acceptance and independent review. No task checkbox may imply these passed.

## 2026-09-28 — single public API, backend rollout checks

Owner approved DEV/PROD deployment and clarified that the app is unreleased and
only owner-tested: evolve `/api/v1` in place; remove HTTP v2 and 426 retirement.
Internal storage conversion preserves saved data and does not add an API version.

- `HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release`: 106 passed, 0 failed, 0 skipped (`/tmp/dt3d-single-api-backend5.log`). Includes already-tombstoned report closure, lost migration acknowledgement, unowned-backup refusal and explicit first-provisioning preview/no-overwrite.
- `python3 src/scripts/backend-release-tests.py -v`: 11 passed (`/tmp/dt3d-single-api-pipeline-final.log`). Deployment smoke requires only `/api/v1/highscores`.
- `python3 src/scripts/release-moderation-smoke.py`: PASS real owned loopback schema1 conversion → v1 score → report → operator acknowledgement/removal/block → private receipt; minimum-ten projection preserved (`/tmp/dt3d-single-api-smoke-final.log`).
- Focused `xcodebuild ... -scheme 'DonkeyTrump3D Local' -destination 'platform=iOS Simulator,id=31C13DEB-E27B-46F9-8598-BB36342D54A6' -only-testing:DonkeyTrump3DTests/HighscoreServiceTests -only-testing:DonkeyTrump3DTests/ModerationTests test`: 8 tests passed (`/tmp/dt3d-single-api-ios.log`). This is not physical acceptance or the full iOS regression suite.
- `/support` and `/privacy`, with or without trailing slash, now serve HTML successfully: tests caught and fixed an endpoint/static-file redirect loop.

Cloud operator prerequisite: Azure control-plane tunnel plus standard SSH worked
for a DEV in-container metadata read using the app MI. Schema1, one stored entry,
no reports/guards. PROD first attempt timed out, second returned storage_invalid;
readonly inventory investigation remains in progress. No data mutation or new
backend deployment has been performed for this rollout at this point. Final
independent review and actual deployment evidence remain separate gates.

Final backend rollout2026-09-28:109 backend tests/0skip,11 pipeline tests and8 focused
Swift simulator tests passed. Source27aa810 deployed to DEV/PROD with actual mounted
file identity and live read/write/moderation checks; see backend-single-api-rollout.md.
Physical-device and complete App Store acceptance remain unfinished.
