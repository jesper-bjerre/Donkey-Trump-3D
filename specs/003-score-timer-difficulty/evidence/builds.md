# Compile-only results — 2026-10-18

Working directory: repository root. Xcode27.0(27A266a), Swift5, iOS26+; .NET SDK10.0.401 from global.json. Candidate application/test source hashes: [build-source-sha256.json](build-source-sha256.json). No signing, emulator/service, simulator boot, application launch or test execution.

| Command | Actual result |
| --- | --- |
| `xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme 'DonkeyTrump3D Local' -configuration 'Debug Local' -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/dt3d-score-timer-build CODE_SIGNING_ALLOWED=NO build-for-testing` | Exit0, `TEST BUILD SUCCEEDED`; app, unit and UI bundles compiled only |
| `xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/dt3d-score-timer-release-build CODE_SIGNING_ALLOWED=NO build` | Exit0, `BUILD SUCCEEDED` |
| `dotnet build src/backend.tests -c Release` | Exit0, `Build succeeded`; API and test assembly compiled;0 warnings,0 errors |
| `git diff --check` | Exit0; no whitespace errors |

Xcode emitted only the standard AppIntents metadata-extraction warning (no AppIntents.framework dependency). A first Release compile also reported a constant-false fixture branch; service selection now reads the compiled LaunchOptions value and the final build has no such warning. No compilation error occurred. Focused source-inspection corrections were recompiled; final source hashes correspond to the last successful builds. Raw build logs remain under /tmp/dt3d-score-timer-{debug,release,backend}-build.log, not claimed durable repository evidence.

The existing Xcode build phase invokes only validate-ios-release.py **build-settings** as a configuration guard. It does not execute its archive boundary check, any test runner or any contract/smoke suite. `build-for-testing` compiles bundles without launching tests; no `test`/`test-without-building`/`dotnet test` action was used.

Compilation does not establish180s timing, playable mixed sequences, physical iPhone behaviour, successful real storage writes or release readiness. See [validation.md](validation.md).
