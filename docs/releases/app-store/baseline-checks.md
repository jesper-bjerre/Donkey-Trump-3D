# Baseline checks — 2026-09-27

Source `94dc44d89929137c4ff02649da58ba8fefa29f1e`, clean worktree, before product changes. These checks cover existing behavior, not future moderation or distribution readiness.

| Command | Actual result |
|---|---|
| `python3 src/scripts/backend-release-tests.py -v` | PASS 9 tests |
| `HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release --nologo` | PASS 59, failed 0, skipped 0; .NET 10.0.401, existing loopback Azurite, tests own isolated containers |
| `xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme 'DonkeyTrump3D Local' -destination 'platform=iOS Simulator,id=31C13DEB-E27B-46F9-8598-BB36342D54A6' -resultBundlePath /tmp/dt3d-release-baseline-20260927.xcresult test` | PASS with 3 explicit integration skips: 63 passed test cases (74 parameterized executions), 0 failed; Xcode 27.0/iOS 27 simulator; log `/tmp/dt3d-release-baseline-20260927.log` |

The existing owner's Azurite process was reused and not stopped. No physical-device, production-moderation or App Store check is implied.

The skipped UI cases require the owned local API/performance/redirect fixtures. They are not passes and must run with the updated v2 integration harness at T035. Simulator baseline is not all release checks.
