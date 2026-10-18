# Quickstart and Future Acceptance: Score, Timer and Level Pressure

Date:2026-10-18. **Design/validation guide, not executed evidence.** No application tests, builds, helper services, emulator, simulator or physical gameplay were run for this plan. Test commands, contract/smoke scripts and manual gameplay acceptance below may run only when explicitly requested in the then-current prompt, and only within that scope. A future implementation request alone does not authorize them.

## Prerequisites and working directory

Run every command below from the repository root, where `global.json` applies:

```sh
cd /Users/jesperhyldenbrandtbjerre/Documents/Development/Donkey-Trump-3D
xcodebuild -version
dotnet --version
xcrun simctl list devices available
```

Baseline: Xcode27.0, iOS26+, .NET SDK10.0.401/latestPatch, existing backend project/packages, Azurite3.37.0 for isolated integration. Set `DT3D_SIM_ID` to an available iPhone simulator UUID from the list, not a physical-device UUID. The reference physical acceptance device is iPhone13. These are prerequisites, not a claim that a selected simulator/device has run this feature.

The implementation must first add the planned state/timeline, feature tests and Debug-only gameplay fixtures described in the contracts. Named new suites/fixtures in this guide are intended implementation outputs and do not exist merely because this document contains commands.

## Build commands for a future authorized implementation

These compile, not test or publish; none were run by speckit-plan:

```sh
dotnet restore src/backend
dotnet build src/backend -c Release --no-restore
: "${DT3D_SIM_ID:?Set DT3D_SIM_ID from simctl device listing}"
xcodebuild -project src/DonkeyTrump3D.xcodeproj \
  -scheme 'DonkeyTrump3D Local' -configuration 'Debug Local' \
  -destination "platform=iOS Simulator,id=$DT3D_SIM_ID" \
  -derivedDataPath /tmp/dt3d-score-timer-build \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project src/DonkeyTrump3D.xcodeproj \
  -scheme DonkeyTrump3D -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/dt3d-score-timer-build \
  CODE_SIGNING_ALLOWED=NO build
```

A build does not establish clock correctness, physics playability, successful storage integration or release readiness.

## Explicitly requested focused automated validation

The following suites are planned additions within the existing targets. Implement observable journeys/boundaries rather than assertions that only repeat formula implementation. New Swift suites: `ScoreTimerDifficultyTests` (core), `GameplayTimelineTests` (actual clock/input adapter) and `ScoreTimerDifficultyUITests` (HUD/lifecycle/fixtures). New backend class: `ScoreGranularityTests` (parser/rank/document/endpoint domain). Extend existing contract/storage suites for real read/write and unchanged failure behaviour.

```sh
: "${DT3D_SIM_ID:?Set DT3D_SIM_ID from simctl device listing}"
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D \
  -destination "platform=iOS Simulator,id=$DT3D_SIM_ID" \
  -derivedDataPath /tmp/dt3d-score-timer-tests \
  -only-testing:DonkeyTrump3DTests/ScoreTimerDifficultyTests \
  -only-testing:DonkeyTrump3DTests/GameplayTimelineTests test

dotnet test src/backend.tests -c Release \
  --filter 'FullyQualifiedName~ScoreGranularityTests&Category!=StorageIntegration'
```

Run UI or real-storage scopes only when those scopes were explicitly requested. Do not expand a request for a pure scoring check into the full app/backend suite. Existing `src/tests/support/validate-highscore-contract.py` and release/smoke scripts execute assertions/tests and need the same explicit authorization; they are not planning document checks.

## Isolated real API/storage setup — future authorized integration only

Use the existing helper-owned loopback API; never publish synthetic runs to DEV/PROD. Restore Debug dependencies first because the helper performs `dotnet build --no-restore` using `~/.dotnet/dotnet`:

```sh
~/.dotnet/dotnet restore src/backend
```

Terminal A, from repository root:

```sh
DT3D_AZURITE_DATA=$(mktemp -d /tmp/dt3d-score-timer-azurite.XXXXXX)
npx --yes --package azurite@3.37.0 azurite-blob \
  --blobHost 127.0.0.1 --blobPort 10000 \
  --location "$DT3D_AZURITE_DATA" --silent --disableTelemetry
```

Terminal B, from repository root:

```sh
python3 src/tests/support/local-highscores.py \
  --port 5281 --state-file /tmp/dt3d-score-timer-local-api.json
```

The helper owns a unique private emulator container, initializes an empty schema2 aggregate, builds/launches the real API on loopback and writes its owned process/origin state. Expect the normal starter projection and a real revision, not necessarily `empty`. Ctrl-C stops only its API and removes only its container; stop Azurite separately. Port conflicts require selecting a free port, not terminating unrelated processes.

For future read checks in that authorized integration scope:

```sh
curl --fail http://127.0.0.1:5281/health/live
curl --fail http://127.0.0.1:5281/api/v1/highscores
```

Use the Debug app with the existing integration arguments:

```text
-highscoreUITest -highscoreIntegration
-highscoreLocalOrigin http://127.0.0.1:5281
-highscoreCompletedRun -highscoreRunScore 1005
```

Repeat with a fresh completed-run UUID and score10. The list has fewer than100 rows, so both can qualify despite the starter scores. Enter a synthetic name and submit once using the app's existing installation-credential flow. Do not put credentials into shell commands, logs or recorded packet bodies. Read the exact returned snapshot, restart only the owned API while preserving its container using the helper's documented SIGUSR1 interface, then confirm the same scores/IDs via a fresh read. Do not send a second POST as a readback.

The injected CompletedRun proves encoding/transport/ranking/storage/decoding, not that actual gameplay earned1,005. Separately prove gameplay score formation through core/engine checks. Ordinary injected `-highscoreFixture` services prove UI/failures only, not API/Blob behaviour. `DonkeyTrump3D Local` Run points at loopback5281; its Test action still uses existing Debug fixtures and is not retargeted merely by the scheme name. Explicit integration arguments/harness are required. Physical iPhone loopback is the phone, not the Mac; do not add a LAN HTTP or production-submission exception to make this recipe work.

## Acceptance matrix

All rows are planned. Execute only the requested check scope and record exact command, source/build identity, environment, real/fixture target, inputs, observed result and limitations. The scenario references below map every entry in all four stories; intent numbers refer to the original19 acceptance items.

| Check | Story scenarios / intent | Required observable outcome |
| --- | --- | --- |
| V01 Reference journeys/visible L | US1.1–1.2; intent1–3 | 10 distinct level1 barrels + rescue at60s =1,700; level2 five barrels at120s adds2,700; total4,400; repeated layouts use current visible L |
| V02 Cap/retry | US1.3–1.4; intent4,7 | First20 level1 barrels total200; 21st pays0; after12 then death only8 remain; score retained |
| V03 Lifetime/multi-clearance | US1.5–1.6; intent5–6 | Repeated callbacks/same lifetime pay once; fresh pool release pays below cap; empty jump0; multiple eligible barrels pay normal rewards only within cap; immutable feedback positions/values survive reuse |
| V04 Fractional/time/completion once | US1.7–1.8; intent10–11 | T60.2 has119 bonus seconds; exact60/120 retain reference points; just before/at/after integer boundary floors correctly; T≥180 stays0 after retry; duplicate completion no bonus duplication |
| V05 Attempt reset/timeout/final life | US2.1–2.4; intent8–10 | Fresh/retry3:00; R expires once at180 active seconds; no timeout bonuses; final life Game Over/no replacement;60+death+60 gives T120/R120 |
| V06 Inactive/lifecycle/real clock | US2.5, US3.3; intent14–15 | Actual adapter at30/60/120Hz meets0.02s tolerance and equal points away from rounding edges;60s pause/background changes T/R/pressure by0; app-inactive during intro/death/retry/celebration freezes phase progression; foreground stalls retain debt within32-slice budget, no lost active time or imported background interval |
| V07 Terminal races/stale events | US2.6–2.8; intent16 | Permute callback arrays: expiry+hit loses≤1 life; goal before expiry completes once; equal/after expires; collision+goal same stamp loses; older valid completion wins later timeout; no rewards at/after a loss or stale attempt; no later debt advances replacement attempt |
| V08 Pressure checkpoints/drift | US3.1–3.2,3.6; intent12–13 | Desired factors at0/60/120/180 match within.01pp; active/new rolling/drop derive from immutable bases; direct aiming preserved through pre-landing falling; no compounding; position does not change p; max retained after retry |
| V09 New level/state reset | US3.4; intent17 | T/history reset, R180, new immutable base/floor and lifetime generation; prior score/bonuses retained; whole restart resets score/state |
| V10 Floor/scheduling/playability | US3.5; intent19 | Research floor/actual interval table reproduced from current geometry/base inputs; first delay1.5s, capped opportunity consumed, no resume catch-up release; held/cut jumps, both movement directions and direct/rolling/mixed routes at maximum T each layout and ramp limits allow representative jumps/landings |
| V11 HUD/result feedback | US4.1; intent18 | M:SS uses positive ceiling, starts3:00; exact awarded text only; current completion banner shows completion/time including0/total once; HUD/Game Over/CompletedRun/local best use same total; older best need not equal lower current run |
| V12 Score boundary/storage | US4.2; intent18 | App encode + real local POST/rank/Blob serialize/read/deserialize/GET/Swift decode preserve10/1,005 and mixed historical values/identities/ties; reject fractional/negative/non5/out-of-range; above remote bound stays exact locally with no upload |
| V13 History/failure continuity | US4.3,4.5 | Existing stored and best values unaltered; offline/hung/unconfirmed publication cannot block play/restart or create deferred/next-launch POST; ambiguous acknowledgement remains unconfirmed |
| V14 Copy/accessibility/device | US4.4, US3.5 | English help matches cap/level/time rules; timeout message accurate including hit tie; landscape iPhone13 timer/score/actions readable and reachable, applicable VoiceOver/larger text/settings retained; sustained gameplay/frame pacing and real jumps checked physically |

Conditional same-run restore check is unnecessary while code remains memory-only; if an existing restore path is discovered, add restart-of-that-same-run evidence retaining T/R/history/outcome. Do not add a new persistence system to satisfy a conditional scenario.

## Debug gameplay fixtures and physical acceptance

The [gameplay contract](contracts/gameplay.md#debug-acceptance-fixtures) defines planned fixtures for reaching upper areas and maximum retained pressure without hours of progression. They must simulate actual movement/hazards with controlled initial state/seed, not replace gameplay outcomes with a precomputed pass. The enforcing components are Debug-only launch parsing in GameEngine and matching GameModel service selection; any gameplay fixture selects UnavailableHighscoreService before production configuration. Release builds compile out the flags/state injection and reject these launch overrides. Repeatable future boundary checks must prove no credentialed POST/public service selection for any fixture/autopilot and no fixture code/behaviour in Release.

GameEngine uses an in-memory best/save closure for any gameplay-fixture flag, including invalid input. Verify the real saved personal best is identical before/after fixture play, Game Over and restart; test setup must not contaminate ordinary local best data.

For a future explicitly requested physical gameplay check, install the Debug build on the actual reference iPhone13 and select the documented fixture/seed. Run each authored layout/upper area through a full180-active-second attempt, then retry at retained maximum pressure and exercise each ramp-limit layout. Record actual falls/hits/jump and landing windows, safe subsequent jumps, direct/rolling convergence, touch input, readability, frame pacing and settings. A source-derived floor, simulator run or synthetic score submission is not physical acceptance. If a sequence fails, tune within the approved movement/spacing constraints and recheck affected authorized scenarios before claiming gameplay completion. If physical hardware is unavailable, record that gate as not executed.

## Future coordinated rollout and rollback

No deploy/release is performed here. Before a separately authorized rollout, confirm actual installed-client/distribution constraints using current evidence, apply widened-reader backend first and replace participating strict clients. The dated owner decision permits in-placev1 and promises no old-client online compatibility; do not turn that into a claim of present distribution. Keep one historical list and explain score comparability. Prepare a rollback backend that still accepts/reads multiples of5 before the first new-score write; never restore strict100 validation over mixed stored data. Deployment checks/workflows themselves may execute tests and need explicit current-prompt authorization for that scope.

## Implemented suite inventory (2026-10-18)

Authored sources: GameplayStateTests, GameplayTimelineTests (the production adapter, not a second timing model), ScoreTimerDifficultyTests, GameplayFixtureBoundaryTests, DifficultySequenceTests, ScoreDomainTests, ScoreTimerDifficultyUITests and the extended Core/CompletedRun/highscore failure/publication/service/real-submission suites. Backend ScoreGranularityTests covers pure parser/ranking/schema1/2; ScoreGranularityStorageTests is Category=StorageIntegration with real isolated schema2 POST→Blob→fresh-store→GET.

Gameplay fixture syntax is exactly the nine cases in the gameplay contract plus required unsigned seed. Any fixture flag presence, including malformed/combined input, disables publication and real best writes. Runtime outcomes and physical gates remain not run unless explicitly requested. Compile-only test-bundle compilation, if recorded, is not test execution. The build-settings phase runs only the existing configuration guard; no test runner or contract/smoke suite is invoked by a build.
