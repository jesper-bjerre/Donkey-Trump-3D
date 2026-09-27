# Independent Review: Xcode Local/DEV/PROD backend selection

**Role:** Independent Anthropic reviewer (Claude Opus 5.5, `claude-opus-5-5`). I did not take part in the implementation. OpenAI Codex implemented this change.
**Reviewed:** Base `4c191a6c8998c37b6765362b9b17c957fb8ae61f` plus the frozen 13-file manifest in the packet. I used only the packet contents and ran no tools or builds.

## Verdict: **CHANGES REQUIRED**

There is one material in-scope gap, F1. It may need only evidence, not a code change. Everything else meets the acceptance criteria based on the supplied evidence.

## Finding

### F1: Medium, blocking. The default Test path changed behaviour and was not run

**Where:**
- `src/DonkeyTrump3D.xcodeproj/project.pbxproj:291`: the `Debug` app configuration now takes `Backend-DEV.xcconfig`, and the empty `HIGHSCORE_API_BASE_URL` was removed.
- `DonkeyTrump3D.xcscheme:26`, `DonkeyTrump3D DEV.xcscheme:26`, `DonkeyTrump3D Local.xcscheme:26` and `DonkeyTrump3D PROD.xcscheme:26`: every `TestAction` uses `Debug`.
- `docs/ios-backend-environments.md:20-22`: says the Run environment "does not retarget automated tests".

**Impact:**
- Before this change, a Debug test-host or UI-test launch without fixture or integration arguments went through `HighscoreConfiguration.bundled()` and returned `nil`. That selected `UnavailableHighscoreService` (`DonkeyTrump3DApp.swift:53-54`).
- Now the same launch selects a real `URLSessionHighscoreService` pointed at `https://donkeytrump-api-d.azurewebsites.net`. This applies to every shared scheme's Test action, including the README's documented command (`README.md:15-16`).
- As a result, any unit test that builds `GameModel()` without injecting a service can now make real network requests to Azure DEV instead of failing closed offline. So can any UI test that reaches Highscores or Game Over without `-highscoreFixture`/`-highscoreUITest`, and any harness path that wraps `selected`, such as `HighscorePerformanceHarness` at `DonkeyTrump3DApp.swift:61-64`.
- If that happens, tests become non-deterministic, depend on DEV F1 cold starts and quotas, and could write to DEV. This weakens the quickstart's statement that ordinary Debug fixture runs never contact the backend (`quickstart.md:62`).

**Requirement:**
- Acceptance: "existing tests/configs remain valid" and "ordinary scheme remains usable".
- Constitution V: run the affected build and tests, using deterministic substitutes.

**Evidence gap:**
- Check 3 ran only `DonkeyTrump3DTests`, and only under `Debug Local`. There, the bundled origin is loopback port 5281, which is a different and effectively inert target.
- The changed default path was not executed: the `Debug` Test action with a DEV-bundled host.
- `DonkeyTrump3DUITests` was not run in any configuration.

**To close F1:**
1. Run the unchanged default command, `xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D -destination <iPhone 13 iOS 27 UDID> test`, with no configuration override. It must cover both the unit and UI targets. The existing documented skips for the integration, redirect, stream and performance cases are acceptable if they are reported as skips.
2. Show that no request reaches DEV during that run. Either:
   - supply `HighscoreCoordinator.swift`, `HighscorePerformanceHarness`, and the UI-test launch helpers, showing that no test-host or UI-test launch path can reach the bundled service, or
   - record DEV request evidence for the test window, or
   - run the tests with networking blocked and show the same results.
3. If a path does reach the bundled service, make Test fail closed. For example, give the test-host launch an empty or unavailable backend. Do not let Test inherit DEV.

Missing context I need to dismiss F1 by inspection instead: the sources for `HighscoreCoordinator`, `HighscorePerformanceHarness` and its enabling condition, the UI-test launch helpers, and any unit test that calls `GameModel()` without a service.

## Criteria I checked and found satisfied

- **Run routing (Local/DEV/PROD):**
  - The LaunchAction configurations match the design: `Local.xcscheme:54` uses `Debug Local`, `DEV.xcscheme:55` uses `Debug`, and `PROD.xcscheme:54` uses `Debug PROD`.
  - The xcconfig values use the `:/$()/` form, and check 2 read the expected origins from the built Info.plist.
  - `bundled()` sends the `http` loopback origin to `init(localOrigin:)` and the HTTPS origins to `init(baseURL:)`.
  - The code path is unchanged.
- **Ordinary scheme usable:** The scheme is unchanged, and Run resolves to DEV as documented.
- **Local transport:** Local reuses the existing loopback-only `NSAllowsLocalNetworking` exception in `Debug-Info.plist:5`. No LAN or HTTP widening was introduced.
- **Production distribution:**
  - Archive and Profile use `Release` in all four schemes.
  - `Release` takes `Backend-PROD.xcconfig` (`pbxproj:324`) and `Release-Info.plist`, which has no ATS exception.
  - The built Release app had an empty `SWIFT_ACTIVE_COMPILATION_CONDITIONS` and no ATS dictionary (check 2), so the `#if DEBUG` fixture and integration code is compiled out.
  - The Debug PROD Run build keeps DEBUG fixtures by design. That is acceptable because it is Run-only, and the docs warn that PROD submissions are public (`ios-backend-environments.md:18`).
- **Cloned configurations:** The project-level and target-level `Debug Local`/`Debug PROD` blocks match `Debug`, apart from the xcconfig base. Check 3 confirms the test-target clones build.
- **Helper `--port`:** The range is validated. An occupied fixed port fails at `probe.bind` before the container `PUT`, so no emulator container is orphaned. Default `0` keeps the existing dynamic behaviour.
- **Docs:** The guide, README and runbook changes match the implementation. The links were checked in check 5.

## Non-blocking observation

`local-highscores.py:33-34` probes the fixed port without `SO_REUSEADDR`. Restarting the helper on 5281 within about 30 seconds of Ctrl-C may occasionally fail with `EADDRINUSE`, because the port can still be in server-side TIME_WAIT. The doc's advice to stop the previous helper would not help in that case. This is optional and does not block.

## Limitations

- I did not independently build, test or inspect any file outside the packet.
- There is no end-to-end evidence of UI → Local API traffic, and no physical-device or signed-archive evidence. The lead disclosed these gaps.
- This verdict makes no release-readiness claim.
- If the F1 evidence shows no path to DEV and the default suite passes, I expect to approve the unchanged candidate in a focused re-review.
