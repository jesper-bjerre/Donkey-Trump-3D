# Global highscores implementation evidence

Date: 2026-09-26. Implementation and local acceptance checks completed. Independent review is recorded separately. No deployment or release claim.

## Setup — T001–T004

- Microsoft release metadata selected SDK 10.0.401 and runtime 10.0.12; downloaded macOS arm64 SDK archive SHA-512 matched official metadata. Installed beside the existing user SDK; no credentials or shell profile changes.
- Root `global.json`: 10.0.401, latestPatch, previews disabled. `dotnet --version` from root, `src/backend` and `src/backend.tests`: **10.0.401**, all exit 0.
- Azure.Storage.Blobs 12.29.2, Azure.Identity 1.21.0, Microsoft.AspNetCore.Mvc.Testing 10.0.12, Microsoft.NET.Test.Sdk 18.10.1, xUnit 2.9.3, runner 4.0.0; stable versions checked against official NuGet feeds.
- `dotnet build src/backend.tests/DonkeyTrump.Highscores.Api.Tests.csproj --configuration Release`: **passed**, 0 warnings/errors. The sibling test project references the existing API.
- `plutil -lint` on Xcode project and Debug/Release Info plists: **passed**.
- `xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D -destination 'platform=iOS Simulator,id=31C13DEB-E27B-46F9-8598-BB36342D54A6' -derivedDataPath /tmp/dt3d-highscores-build build-for-testing`: **passed**, Xcode 27.0 (27A266a), iPhone 13 / iOS 27.0. Existing Swift tests and new UI-test target build. No feature test assertion is claimed at this setup checkpoint.
- Shared JSON fixtures include Unicode/byte/grapheme/integer/UUID boundaries, empty/99/100-row snapshots, equal scores and duplicate names. Linked as a Swift test resource and copied into backend test output.
- `.specify/extensions.yml` absent: no pre-implementation hooks registered. Requirements checklist: 16/16 checked; left unchanged.

## Foundation — T005–T012

- Added canonical request validation, strict private document/public DTOs, injectable store boundary, validated Development/Test versus production configuration, SDK retry/network budgets and shared Swift models/states/clock.
- Added isolated emulator container ownership, real transport fault/barrier helpers, fixed clock/no-backoff helpers, injected Swift service/clock/URLProtocol spies and Debug-only fixture selection.
- Repeated backend Release build: **passed**, 0 warnings/errors. Repeated iPhone 13 `build-for-testing`: **passed**; only Xcode's informational AppIntents extraction warning (no AppIntents dependency).
- Fixtures compile without storage or SceneKit access. The explicit integration selector accepts only a loopback origin and has no production fallback; transport enforcement and app injection remain T021/T025.
- Task-owned Azurite 3.37.0 started on `127.0.0.1:10020` with an isolated temporary data directory; storage tests will verify its availability rather than assume startup success.

## Initial publication tests — T013–T016

- Backend tests were written before ranking/routes. With a behaviourless ranker seam, **10 assertions failed / 5 passed**: missing GET/POST routes and ranking/no-op behaviour. After implementation, **15/15 passed** (`dotnet test ... --configuration Release --filter 'Category!=StorageIntegration'`).
- Swift tests and the consent UI test ran against behaviourless coordinator/transport/run seams before implementation. Run identity, publication, timeout and malformed-save assertions failed; UI failed because the name form was absent. Compilation issues in the test harness were corrected before recording the failing behavioural run.
- After implementation, **10 Swift tests passed** (run identity/final-life capture, shared wire fixtures, ranked identity, name correction, one POST, independent timeout). **4 XCUITests passed**: public consent/invalid name/cancel plus ranks 1, 50, 100, exact selected row, boundary visibility, interior centre and keyboard dismissal. Xcode finished with **TEST SUCCEEDED**, exit 0. Its optional simulator diagnostic collector stalled after the tests; that task-owned diagnostic subprocess was terminated, and Xcode finalized the successful result. Subsequent runs use `-collect-test-diagnostics never` to avoid that collector.
- Real Azurite smoke: **1/1 passed**, explicit StorageIntegration opt-in, isolated container on port 10020. Two independent API/store instances saw the same zero-score save/revision; identical replay did not write a new revision; a fresh store instance retained the ranking. No cloud identity claim.
- Debug synthetic Game Over uses an isolated UserDefaults suite for personal bests, preserving normal simulator player preferences.

## Initial implementation — T017–T024

- Run capture/HUD handoff, canonical ranking, bounded conditional Blob writes, strict API/limits, bounded URLSession transport, main-actor coordinator and public-name/list views implemented against the preceding tests.
- Release simulator build: **passed**. Built Release Info.plist has no ATS exception and the production base URL is empty/unavailable until supplied; Debug has only NSAllowsLocalNetworking. Release binary contains none of the synthetic fixture/integration launch override strings or fixture symbols checked.
- T025 focused checks: 4 Swift wire/configuration tests and 1 real HTTP redirect XCUITest **passed**, Xcode exit 0. Explicit test origin `http://127.0.0.1:51924`; source GET=1/POST=1, redirected origin `http://127.0.0.1:51923` received **0 requests**. Invalid origins fail closed; no production fallback. This test used the committed loopback-only HTTP fixture helper.
- T026 initial slice passed the API/ranking, real isolated Azurite, Swift and rank/name UI checks above. This is not full US1 acceptance: cutoff-race evidence remains T031 and two app installations remain T054.

## Release environment limitations

Docker is not installed on this Mac. No Azure deployment identity/hostname or physical-device results are supplied. Container execution, real Azure identity/storage and physical iPhone accessibility/audio remain release checks requiring their actual environments; local emulator/simulator tests cannot replace them.

## Independent review — historical checkpoint after T026 (2026-09-26)

At this checkpoint, independent review was pending completion of the remaining implementation and required local checks. No unfinished candidate was submitted for completion review. The later review findings and final dispositions are recorded separately.

## T031 — nonqualification and cutoff race (2026-09-26)

PASS: three coordinator cases (including below/equal parameter cases) and three XCUITests on iPhone 13 / iOS 27.0. Fresh misses do not prompt or POST; rank 100 is visible with final score and immediate Play Again. A qualifying GET followed by a higher cutoff POST shows the changed-list explanation without success/highlight. Refresh transition uses entry ID and preserves final score when displaced. Test-first run failed on cutoff fixture and displacement transition, then passed after correction. Command: xcodebuild with shared scheme, simulator `31C13DEB-E27B-46F9-8598-BB36342D54A6`, `-only-testing:DonkeyTrump3DTests/HighscoreNonqualificationTests -only-testing:DonkeyTrump3DUITests/HighscoreNonqualificationUITests test`; diagnostics disabled. Local log: `/tmp/dt3d-us2-green.log`. This completes the internal MVP slice, not full feature/release acceptance.

## T038 — title browsing and bounded lifecycle (2026-09-26)

PASS: five GET contract cases, three Swift browsing cases and three title UI tests. Empty and populated reads return 200/no-store even with If-None-Match; storage failures return Problem Details without an empty list. Fake-clock expiry bounds an uncooperative task; generation guards reject late completion after close/start. Refresh cannot requalify a published run, and a displaced ID moves to the bottom. Simulator UI verified top positioning, read-only refresh, stale label, Start during a hung fetch, and reachable Close/Start at accessibility XXXL in both landscape orientations. Header icon labels and content sizing were adjusted after the first UI run. Logs: `/tmp/dt3d-read-contract.log`, `/tmp/dt3d-us3-green.log` (Swift passed; initial UI failures), `/tmp/dt3d-us3-ui-fixed.log` (3/3 UI passed). Real-time deadline/stream tests are included in T050; physical VoiceOver/keyboard remains a release check.

## T044 — concurrency, faults, boundaries, packaging (2026-09-26)

PASS: all 49 backend cases, SDK 10.0.401/runtime 10.0.12, Azurite 3.37.0 at owned loopback port 10020. Command: `HighscoresTests__UseAzurite=true HighscoresTests__AzuriteEndpoint=http://127.0.0.1:10020/devstoreaccount1 ~/.dotnet/dotnet test src/backend.tests --logger 'console;verbosity=detailed'`. Log `/tmp/dt3d-backend-us4.log`.

21 deterministic SDK-transport cases prove conditional single Put Blob, same-read ETag, first creation, recognized-conflict reread/recompute, five uploads/four backoffs, no reread after save, no retry after a committed-but-lost response, bounded deadline, oversized/chunked/corrupt/unknown-schema documents, duplicate IDs/sequences, bad ordering, sequence overflow, missing container and authorization failure. Missing container/auth failures never replace storage with an empty document.

Two independent writers both succeeded in deterministic first-create and update races; equal scores retain successful-save order and ranked replay preserves revision. The 100-writer run seeded 100 existing entries: 10 acknowledged writers, 90 explicit contention rejections; one additional confirmed committed/unacknowledged fault. The final 100 IDs matched the independent oracle exactly; new stores read identical ranking/revision `"0x279664FA16715C0"`. Process restart and two app installations remain T054, distinct from fresh-store persistence.

Default configured token buckets reject bursts without queues and supply integer Retry-After. Error/diagnostic capture excludes submitted names/payload values, fixture IP and raw exceptions. Diagnostic test failed before instrumentation and passed afterward. Production options reject HTTP/SAS/user-info and emulator use; managed identity is selected by code.

Dockerfile uses SDK 10.0.401 with an explicit global.json selection check, ASP.NET runtime 10.0.12, non-root APP_UID and port 8080; root build context has a Dockerfile-specific allowlist. Container execution is PENDING: Docker is unavailable locally. Real Azure managed identity/RBAC and physical device checks are also PENDING, not inferred from emulator/simulator results.

## T049 — failed publication and regressions (2026-09-26)

PASS: all 38 Swift tests in 11 suites, including existing Core/IntroAudio tests, failure matrix, editable name errors, invalid score, failed read, 409/429/5xx, timeout, cancellation, background/new-run and late acknowledgement. The background test failed with a no-op handler, then passed after lifecycle invalidation. Three UI cases now pass: failed qualification followed by a fresh read, backgrounding a pending read, and lost save acknowledgement followed by refresh/background/relaunch. Persisted fixture personal best remains >=1200; persistent POST counter stays unchanged after failed qualification and increases exactly once for the unconfirmed save. No second prompt or deferred POST on reopening.

Logs: `/tmp/dt3d-us5-green.log` (38 Swift and 2 UI pass; remaining UI counter parser failed on localized thousands), `/tmp/dt3d-us5-fixed.log` (remaining UI passes after diagnostic text uses verbatim integers). Public UI data was unaffected. Physical silent-switch/audio and VoiceOver tests remain pending actual iPhone hardware.

## T050–T051 — visible timing and sustained load

PASS on iPhone 13 / iOS 27.0 (24A434), arm64 simulator, Xcode 27.0 (27A266a), macOS 26.6.2. The ordinary gameplay/render/audio configuration remains enabled. The Debug harness uses the production coordinator and real loopback URLSession service with an isolated Azurite container; measurements end at the second display refresh of mounted, laid-out SwiftUI content. The test alternates paired baseline and normal/delayed/unavailable cases: 50 starts and 50 restarts. It asserts every difference, not just an average. The slow service cannot gate the gameplay command.

| Measure | Final observed result | Target |
|---|---:|---:|
| Largest additional start/restart latency, 100 pairs | 85.58 ms | <100 ms for every pair |
| Warm GET visible p95, 100 samples | 102.14 ms | <=2,000 ms |
| Confirmed POST visible p95, 100 samples | 106.76 ms | <=2,000 ms |
| Hung service visible failure | 7,945.89 ms | <=8,000 ms |
| Continuously chunked HTTP visible failure | 7,931.82 ms | <=8,000 ms |

Raw samples: [final performance JSON](evidence/performance-final.json), [initial passing run](evidence/performance-initial.json), [stream deadline](evidence/stream-deadline.json). The independent coordinator timer fires at 7.8 s, reserving presentation time; URLSession still has an eight-second resource/request bound. The real stream delivered 140 chunks before cancellation; ongoing progress did not reset the UI deadline. Synthetic hang/normal/unavailable services are separate from the 100 real GET/POST samples. No automated call used a production origin.

Integration origin `http://127.0.0.1:53262`, private owned container `dt3d-owned-254c0b9094d5493083c0e2089267e582`, Azurite endpoint `http://127.0.0.1:10020/devstoreaccount1`. Loopback supplied the <=100 ms network RTT environment. No mobile-network or live-Azure latency claim. The test explicitly paced confirmed submissions inside unchanged production POST limits.

Sustained load ran separately against origin `http://127.0.0.1:52985`, owned container `dt3d-owned-534be6ccd2854e1eb2f21ec567cee47f`, with k6 2.2.0: 10 GET/s + 1 POST/s for five minutes followed by ten simultaneous POSTs. **3,312 HTTP 200; 0 HTTP errors; 0 throttles; 0 dropped iterations.** HTTP p95 5.07 ms, maximum 80.30 ms. Default rate limits were unchanged. [k6 summary](evidence/load-summary.json); detailed raw samples remain `/tmp/dt3d-load-samples.jsonl`, log `/tmp/dt3d-load.log`. HTTP latency is not substituted for UI visibility evidence.

## T052–T054 — final local acceptance and documentation

Product docs, root/backend README, quickstart, iOS/HTTP contracts and recovery guidance describe the implemented native 3D iPhone feature, optional public names, client-reported scores, scoped deduplication, private conditional storage and no deferred upload. No production hostname, credentials or Azure resources were introduced.

- Backend Release: `HighscoresTests__UseAzurite=true HighscoresTests__AzuriteEndpoint=http://127.0.0.1:10020/devstoreaccount1 ~/.dotnet/dotnet test src/backend.tests -c Release --logger 'console;verbosity=detailed'`: **49 passed**, no skipped/failed cases. Final 100-writer run: 9 acknowledged, 91 explicit contention rejections, plus one known committed/unacknowledged write; exact oracle/restart snapshot match, revision `"0x1E18A8A20F44660"`. Log `/tmp/dt3d-final-backend.log`.
- Full iPhone run: shared Xcode scheme on simulator `31C13DEB-E27B-46F9-8598-BB36342D54A6`, Debug DerivedData `/tmp/dt3d-highscores-build`, `-collect-test-diagnostics never -parallel-testing-enabled NO test`; all three `TEST_RUNNER_DT3D_*_ORIGIN` variables pointed to owned loopback fixtures/API. **63 expanded test cases passed; 0 failed; 0 skipped** ([xcresult summary](evidence/ios-test-summary.json)). Swift Testing reported 38 test declarations, including parameter cases; XCUITest ran 16 cases. Log `/tmp/dt3d-final-ios.log`; result `Test-DonkeyTrump3D-2026.09.26_12-16-41-+0200.xcresult`. Existing Core/IntroAudio regressions pass.
- Additional largest-text/keyboard UI case: **1 passed**, confirming Submit, Close, Play Again and Return to Title are reachable while the keyboard is open, then selected result appears and keyboard closes. Log `/tmp/dt3d-large-form.log`. This supplements both-landscape large-text browsing and the standard rank 1/50/100 geometry checks. Physical VoiceOver/focus/audio remain untested.
- Final malformed-acknowledgement hardening: a new test first reproduced a response claiming `notQualified` while containing the submitted run. The transport/coordinator now retire it as unconfirmed, also rejecting a nonqualification response whose cutoff still qualifies the score. **11 affected Swift test declarations passed** (wire, nonqualification and failure suites), log `/tmp/dt3d-semantic-response-green.log`. No happy-path rendering or persistence behavior changed.
- Release simulator build with `CODE_SIGNING_ALLOWED=NO`: **passed**. Built Info.plist retains default ATS, no insecure exception, empty production URL. Binary inspection confirms all fixture/integration/performance/synthetic-run override strings are absent. Debug allows only local networking; invalid origins/redirects fail closed. Redirect fixture observed one POST per test and zero target requests.
- OpenAPI 3.1: **12 schemas and 8 media/header examples passed** Draft 2020-12 validation using the committed `validate-highscore-contract.py` helper and isolated PyYAML/jsonschema tools. Relative links in changed guides and Python helper syntax passed; `git diff --check` passed.
- Two actual app installations: the first app published 100 confirmed runs during real integration. The owned API then restarted **PID 29621 -> 30329**, with no intervening writes. iPhone 13 simulators `31C13DEB-E27B-46F9-8598-BB36342D54A6` and `DCBCCF0B-650D-47D8-A0D4-74B2AF70E03E` used separate application data containers. Both fresh rendered lists and a fresh API read contained the same 100 ordered rows and revision `"0x224DEE9D202F5C0"`. [Record](evidence/two-installations.json), [first snapshot](evidence/installation-1.json), [second snapshot](evidence/installation-2.json), [first screenshot](evidence/installation-1.png), [second screenshot](evidence/installation-2.png). Lead visually inspected both landscape screenshots. Full local paths are omitted from the retained record; distinct container UUIDs remain. Reproduction uses `verify-two-installations.py`; log `/tmp/dt3d-two-installations.log`.

## Requirement-to-evidence audit

| Requirements | Implemented boundary and passing evidence |
|---|---|
| FR-001, FR-002 | Canonical top-100 ranking, stable sequence ties; shared fixtures/ranking tests, two-writer races and 100-writer oracle |
| FR-003 | Private Blob persistence, no automatic container creation; restart and two actual app installations |
| FR-004 | Final-life immutable run identity independent of local best; CompletedRunTests and Core regressions |
| FR-005, FR-006 | Fresh qualification, zero/partial/full cutoff, explicit cancellation; Publication/Nonqualification/Failure suites |
| FR-007, FR-008 | Unicode canonicalization and bounds, literal display, public notice and explicit Submit; shared fixtures and consent/keyboard UI |
| FR-009 | Conditional writes, bounded reread/recompute, POST cutoff recheck; CAS faults, concurrency and cutoff-race UI |
| FR-010, FR-011 | Exact run-ID highlight/centering/boundary visibility or bottom/final score; rank 1/50/100 and below/equal/cutoff UI |
| FR-012, FR-013 | Title entry, closable states and immediate gameplay; title UI and 100 paired start/restart measurements |
| FR-014, FR-015 | Independent visible deadline and generation/source guards; fake-clock uncooperative tasks, real stream/hang UI, background/new-run tests |
| FR-016 | Strict request/storage validation, bounded bodies and configured per-process limiters; endpoint/boundary/storage tests |
| FR-017, FR-018 | Local best survives, no deferred POST, honest unconfirmed/stale states; actual committed/lost write, UI counters across refresh/relaunch, malformed-ack tests |
| FR-019 | iPhone 13 landscape safe areas, semantic text/labels, large text/keyboard/navigation and focus implementation; simulator UI passes, physical VoiceOver pending |
| FR-020 | Public-data notice/help/privacy and updated product/operational docs; consent UI and document consistency checks |
| SC-001 | All 100 added-latency differences <100 ms, maximum 85.58 ms |
| SC-002 | Exact selected rows and bottom/no-name flows verified by XCUITest |
| SC-003 | Non-vacuous 100-writer oracle and deterministic equal-score races pass |
| SC-004 | 100 real visible GET/POST samples, p95 <=2 s; hung/continuous stream visible failure <=8 s; separate 5-minute load run |
| SC-005 | Failed qualification, pre-save rejection and committed/lost ack preserve best with no reconnect/relaunch replay |
| SC-006 | Actual service process restart plus two separate installed apps show identical rows/revision |

Constitution v1.0.0 rechecked: native/offline gameplay and thread ownership preserved; one small .NET service; storage-enforced CAS and bounded errors; original game assets unchanged; public-name consent, HTTPS/managed identity boundaries and diagnostic minimization implemented; evidence separates executed checks from deployment. `.specify/extensions.yml` is absent, so no after-implementation hooks are registered. The 16/16 requirements checklist markers were not changed.

### Remaining release checks (not local implementation blockers)

Docker build/run, real Azure managed identity/container RBAC/HTTPS ingress and cold-start measurements require those actual environments. Subscription, region, hostname, budget/retention settings and signing/distribution inputs remain unspecified. Physical iPhone 13 VoiceOver, both-landscape touch/keyboard, sustained performance/thermals and silent-switch/intro audio require hardware. Xcode continues to emit the pre-existing AVAudioSession main-thread activation warning; simulator tests do not certify physical audio behavior. No resource provisioning, production score reset, deployment, archive publication, commit or push was performed.

## Independent-review remediation — HS-IOS-01

The independent iOS reviewer found that a GET returning a Problem Details code such as `internal_error` could incorrectly show the unconfirmed-save message even though no POST/consent occurred. The lead agrees this was a material error against FR-008/FR-017 and the iOS flow contract. The coordinator now requires an actual submission before classifying any error as an unconfirmed save. Backend source and wire contracts are unchanged.

A parameterized regression covers `internal_error`, an unknown code and even a misleading `submission_unconfirmed` code, each from title browsing and completed-run qualification. It asserts the unavailable copy, no POST/name prompt, and no repeat qualification for the retired run. The suite first failed with 12 assertions across those six source/code combinations, then passed after the one-line production fix. A first method-filter attempt selected zero tests and is explicitly **not** acceptance evidence; the actual red/green runs selected the complete suites.

Rerun command: shared Xcode scheme, iPhone 13 / iOS 27.0 UDID as above, with `-only-testing:DonkeyTrump3DTests/HighscoreFailureTests -only-testing:DonkeyTrump3DTests/HighscoreBrowsingTests -only-testing:DonkeyTrump3DTests/HighscoreNonqualificationTests -only-testing:DonkeyTrump3DTests/HighscorePublicationTests test`. **14 test declarations in four suites passed**, including parameter cases; exit 0 / TEST SUCCEEDED. Logs `/tmp/dt3d-review-fix-red-suite.log` and `/tmp/dt3d-review-fix-green.log`; final result `Test-DonkeyTrump3D-2026.09.26_13-43-11-+0200.xcresult`. Earlier UI, storage and timing evidence remains applicable because the change only corrects failed-read message classification and adds its regression tests. The separate review record contains the final independent disposition.
