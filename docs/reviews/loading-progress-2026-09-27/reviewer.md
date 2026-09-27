# Independent review: startup progress bar

**Verdict: APPROVE.** I found no material correctness, regression or acceptance issues in the supplied candidate. The notes at the end are non-blocking.

## Scope and limitations
- **Scope reviewed:** the supplied diff and full listings of the 7 changed files. I also read the supplied dependencies: `AudioSystem` preparation, `HighscoreFixtureLaunch`/`HighscoreFixtureService`, `HighscoreUITestCase`, `AGENTS.md` and the constitution. The listings match the diff hunks.
- **Hashes:** I did not recompute the SHA-256 manifest. The working directory contains no repository copy, so my review covers the packet text only.
- **Checks:** I did not run any builds or tests and did not inspect any pixels. Test results and visual claims below are the lead's supplied evidence, not my observations.
- **Missing context:** I did not have `HUDState`'s default `phase`, `publishHUD`, `ControllerInput`, `HighscorePerformanceHarness`, `cover-validation.md` or the other UI test classes. None of these is needed for my verdict. Where they matter, I list them below.
- **Configuration records:** I cannot verify my own model or effort setting. Per AGENTS.md:97–98, the lead must record that from provider/session metadata. The lead's own exact model and effort are also unrecorded and should be recorded as unavailable.

## Requirements traced to code

| Requirement | Evidence | Status |
|---|---|---|
| Native launch screen shows a static "Loading…" label and a 15% bar | `LaunchScreen.storyboard:23-48` adds a panel with the label and `progress="0.15"`. It is constrained to the safe area: centred at :53, bottom inset 12 at :54. It sits above the cover in z-order. | Met |
| Same artwork, approximate bar moving toward 90% | `LoadingScreenView.swift:11-14` uses the `LaunchCover` image, scaled to fit. `:30-39` moves the bar asymptotically from 0.15 toward 0.9. It never reaches 100%. | Met |
| Removed on the first SceneKit frame, with no minimum hold or completion animation | `GameEngine.swift:304-318` fires once. `RootView.swift:56` removes the cover conditionally. The `.task` is cancelled when the view is removed. | Met |
| Signal captured on the render thread, delivered to main exactly once | `reportedFirstFrame` is only touched by SceneKit's serial delegate callbacks. The sink is captured and dispatched with `DispatchQueue.main.async`. `DonkeyTrump3DApp.swift:71-73` uses `MainActor.assumeIsolated`, which is valid on the main queue. `firstFrameSink` is assigned in `GameModel.init` before `makeUIView` sets the delegate, the same ordering `hudSink` already relies on. | Met |
| New UI state has a main-actor owner (constitution II) | `isSceneReady` is `private(set)` on the `@MainActor` `GameModel`. | Met |
| Nothing awaits optional audio or highscore requests | Readiness depends only on `didRenderScene`. Audio preparation stays on its own queue (`AudioSystem.swift:78`). Highscores are only fetched when the list is opened. | Met |
| Game UI hidden and disabled until ready | `RootView.swift:53-55` applies `allowsHitTesting` and `accessibilityHidden`. The loading screen's full-screen `Color` also intercepts touches. After readiness both modifiers become no-ops. | Met |
| SCNView is not recreated when readiness flips | `gameContent` keeps its structural position in the `ZStack`, and only modifier values change. The loading view is a separate optional sibling. | Met |
| Reduce Motion disables interpolation | `withAnimation(reduceMotion ? nil : …)`. Values still step, as the requirement specifies. | Met |
| Accessible label and value indicate waiting | Label "Loading game", value "Please wait". The `.contain` fix prevents the parent identifier from overriding the child's. | Met |
| Production has no artificial delay | The 8 s hold is inside `#if DEBUG` and needs `-startupProgressTest`, `-highscoreUITest` and a `.fixture` parse. `HighscoreFixtureLaunch` is itself DEBUG-only. The supplied evidence confirms the Release build and the `strings` check. | Met |
| Tests | The first run's failure at line 9 matches the reported identifier-propagation cause. In the final run all 5 tests passed, and the new test took 14.3 s, consistent with the 8 s hold. The existing `testLaunchCanStartWithoutOpeningUnavailableHighscores` asserts `isHittable` immediately after `launch()`. Its pass is useful evidence that the cover is gone in normal launches before XCUITest's launch-idle point. | Met (supplied evidence) |
| Documentation | `cover-art.md:14` accurately describes the native bar, the approximate runtime bar, removal on first frame, and no minimum display time. | Met |

## Findings
None material.

## Non-blocking notes (no change or re-review required)
- **N1 – test strength.** `HighscoreBrowsingUITests.swift:10` checks `isHittable` on an element that `accessibilityHidden` has removed from the accessibility tree. It therefore proves the accessibility hiding, not the hit-test blocking. The code is straightforward, so this is not a defect.
- **N2 – regression breadth.** Only `HighscoreBrowsingUITests` was run. The change is at the root of every launch path, including autostart, introAt, iconShot and the performance harness. Post-readiness behaviour is unchanged, and N-tests show readiness before launch idle, so the risk is low. Running the full UI suite is still worthwhile before release acceptance. It is not required for this implementation's completion.
- **N3 – validation doc.** `cover-art.md:18` points to `cover-validation.md` for simulator captures. Those captures presumably predate the new storyboard panel. If that doc presents them as the current launch screen, add a dated note. I did not see its contents.

## Consensus statement
The candidate satisfies the stated requirements, and I have no material unresolved findings. Per AGENTS.md:265–268, the lead's explicit agreement with this APPROVE completes consensus without a second review round. This is implementation completion only. Physical-device, VoiceOver, launch-timing and distribution evidence remain open, as the lead's own limitations state.
