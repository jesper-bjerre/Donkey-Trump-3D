# Focused Re-review: Xcode Local/DEV/PROD backend selection (F1)

**Role:** Independent Anthropic reviewer (Claude Opus 5.5, `claude-opus-5-5`). I did not take part in the implementation, which OpenAI Codex wrote.

**Reviewed:** The unchanged candidate: base `4c191a6c8998c37b6765362b9b17c957fb8ae61f` plus the same frozen 13-file SHA-256 manifest. I used new evidence item 6, the lead's F1 response, and the source that was previously missing. I used only the packet contents, ran no tools or builds, and did not invoke another reviewer.

## Verdict: **APPROVE**

F1 is resolved and no new material findings were found. No source change is needed.

## F1 disposition: resolved (evidence gap closed, no defect)

I agree with the lead's premise. The default `Debug` TestAction now builds a test host whose bundled origin is DEV. The question was whether any test path reaches that service. I traced it independently.

**1. The default command was executed (closes item 1).**
- Evidence 6 ran the documented command with no configuration override, so the TestAction used `Debug`.
- Result: exit 0 and `TEST SUCCEEDED`.
  - Unit tests: 40 in 11 suites passed.
  - UI tests: 17 cases, of which 14 passed, 3 were skipped and 0 failed.
- The inventory in the packet is complete:
  - **Unit:** Levels 4, Slopes 3, Player 3, Flow 3, Intro audio 5, Completed run 3, Browsing 3, Wire contract 5, Nonqualification 3, Failures 4, Publication 4. That is 11 suites and 40 tests.
  - **UI:** Publication 5, Nonqualification 3, Browsing 3, Failure 3, Performance 2, Transport 1. That is 17 cases.
- The three skips are the two `HighscorePerformanceTests` cases (`HighscorePerformanceTests.swift:6,18`) and the redirect case (`HighscoreTransportBoundaryUITests.swift:6`). Each is gated on an unset environment variable, and they were reported as skips. This meets the condition I set.

**2. Source-path isolation (closes item 2 by inspection).**

*The `HighscoreCoordinator` is inert until called.*
- `HighscoreCoordinator.swift:16-18`: the initializer only stores the service and clock. State starts `.closed` (`:5`).
- `URLSessionHighscoreService.init` (`URLSessionHighscoreService.swift:14-23`) creates a session but issues no request.
- Service I/O happens only in `begin`, which is reached only from `complete`, `submit`, `openTitle` and `refresh` (`:32,52,68,85`).
- `refresh` needs a source (`:76`). `submit` needs `.enteringName` (`:44`).

*The test host cannot reach `complete`.*
- `GameModel.receive` calls `complete` only when the phase is `.gameOver` and `completedRun` is non-nil (`DonkeyTrump3DApp.swift:86`).
- The engine starts at `.title` (`Simulation.swift:128`). The title attract loop drives `session.sim` directly and never changes `session.phase` (`GameEngine.swift:397-416`).
- Leaving the title requires a `.startGame` command from the UI or from controller/keyboard confirm (`:336-339`). Nothing issues one in the hosted unit run.
- The fixture Game Over command is ignored unless fixture launch arguments are present (`GameEngine.swift:350`).
- The scheme LaunchAction has no arguments, so the test host takes the bundled branch but stays idle.

*Unit tests never use the bundled service.*
- No supplied unit test constructs `GameModel`. All coordinator tests inject `ScriptedHighscoreService` or `HighscoreFixtureService`.
- The two wire tests that construct `URLSessionHighscoreService` use `HighscoreURLProtocol`. Its `canInit` returns `true` for every request (`HighscoreTestSupport.swift:61`), and the target is `https://example.invalid`, so no request leaves the process.

*No UI launch reaches the bundled service.*
- Every non-skipped UI launch passes `-highscoreFixture`, either through `HighscoreUITestSupport.swift:13` or directly at `HighscorePublicationUITests.swift:16` and `HighscoreBrowsingUITests.swift:29`.
- `HighscoreFixtureLaunch.parse` selects `.fixture` (`HighscoreFixtures.swift:22`). `GameModel` resolves that to the in-memory service before it ever consults `bundled()` (`DonkeyTrump3DApp.swift:45-53`).
- `press(.home)` followed by `activate()` resumes the same process with the same arguments. Every relaunch uses the fixture helper.
- Integration launches:
  - They occur only in the three skipped tests.
  - Any non-loopback origin makes the parser return `.unavailable` (`HighscoreFixtures.swift:16-19`).
  - The unit test at `HighscoreServiceTests.swift:11-12` checks that behaviour.

*The performance harness cannot wrap the bundled service.*
- `isEnabled` requires both a performance or deadline flag and a `.integration` parse (`HighscorePerformanceHarness.swift:31-35`).
- When enabled, the base it wraps is the loopback integration service, never the bundled one.
- `HighscoreRenderProbe` is gated the same way (`:121`).

*DEV writes are ruled out.*
- A write needs `submit(name:)` from `.enteringName`. That state requires a completed run, a successful read and explicit name entry. None of these can occur in the hosted unit run.
- The only possible residual would be a DEV read, not a write. This addresses my concern about writes to DEV and Constitution V's requirement for deterministic substitutes.

**3. A fail-closed Test configuration is not required.** No existing test path reaches the bundled service. Giving Test an empty or unavailable backend remains an optional hardening step, not a condition for approval.

## New findings

None.

## Non-blocking observations

- **N1 (optional):** Deferring `SO_REUSEADDR` on the fixed-port probe (`local-highscores.py:33-34`) is acceptable.
- **N2 (optional):** `docs/ios-backend-environments.md:20-22` and `quickstart.md:62` are accurate by the inspection above. One clarifying sentence would help: the Debug test host now bundles the DEV origin but performs no highscore I/O unless a test drives it. Alternatively, the Test action could be pinned to a backend-less configuration. Neither is required.

## Limitations

- **No telemetry.** No live DEV request telemetry was captured and no network-blocked run was performed. Isolation rests on source inspection, which was one of the three closure routes I offered.
- **`RootView` not inspected.** I did not see `RootView` or the other SwiftUI views. If a view called `openTitle()` automatically on appear, the idle test host could make one DEV read. The UI tests, which must tap `highscoreOpen` before a list appears, are consistent with no auto-open. Even in that case the risk would be a read only, never a write. I judge this non-material.
- **Unexercised areas.** There is still no executed evidence of UI → Local API traffic during a normal Run, no physical-device evidence and no signed-archive evidence. The lead disclosed these gaps.
- **Scope of approval.** This approval covers the exact frozen candidate for the authorized implementation scope. It is not a release-readiness claim.
