# Loading progress — 2026-09-27

## Outcome and authorized scope

The owner requested a progress bar on the loading cover; approximate progress is acceptable. The prior requirement to minimize loading time remains.

The native launch storyboard now shows “Loading…” and a yellow partially filled bar. Once the app takes over, the same artwork has an approximate moving bar. SceneKit's first rendered frame removes the cover immediately; no minimum time, completion animation, audio wait or highscore wait is introduced. Underlying menu interaction and accessibility are disabled only until readiness. Reduce Motion disables interpolation.

The native launch screen is static by platform design; see [Apple's launch storyboard restrictions](https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen/) and [the first rendered frame callback](https://developer.apple.com/documentation/scenekit/scnscenerendererdelegate/renderer(_:didrenderscene:attime:)). Existing artwork, audio preparation, highscore networking and gameplay remain unchanged.

## Participants and route

- Lead: OpenAI Codex; exact model, tool version and reasoning setting unavailable in this session.
- Reviewer: independent Anthropic Claude Code 2.1.283, model `claude-opus-5-5`, explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`. Did not implement this change.
- Fresh harmless text and JSON probes passed with actual canonical assistant model and nonzero first-party usage, no stderr or effort-cap warning. [Route record](loading-progress-2026-09-27/route.json). Provider does not separately attest effective effort.
- Review ran in isolated temporary directory with safe mode, no tools/MCP, no persistence and explicit configuration. Exit 0, successful final result, expected actual assistant model. [Provider result](loading-progress-2026-09-27/review-metadata.json). No fallback needed.

## Scope identity and supplied evidence

Git base: `4c191a6c8998c37b6765362b9b17c957fb8ae61f`. Earlier unrelated dirty changes were preserved. The review base is captured pre-edit worktree content for seven scoped files, not an assertion that these match HEAD. New `LoadingScreenView.swift` is represented by an empty before hash because it did not exist.

[Before hashes](loading-progress-2026-09-27/before.sha256), [final hashes](loading-progress-2026-09-27/candidate.sha256), [scoped patch](loading-progress-2026-09-27/task.diff).

Packet included governing policy/constitution, complete scoped patch, source listings, relevant dependencies and attributed evidence. `RootView` and `GameEngine` were limited to changed areas and relevant surrounding context; other changed files were supplied fully. The reviewer's phrase “full listings of the 7 changed files” is broader than the actual packet. Reviewer did not inspect pixels, recompute hashes or execute checks. Final source hashes were checked unchanged after approval. This record/evidence copies are excluded from payload identity. No commit, push or deployment.

## Checks actually run

- Xcode 27.0 (27A266a), iPhone 13/iOS 27 simulator: signed Debug app/test build and **all 5 HighscoreBrowsing UI tests passed**. [Exact command/results](loading-progress-2026-09-27/dt3d-progress-final.log).
- New test observes progress, absence of accessible/hittable Start during loading, automatic dismissal, usable Start afterwards and Start during a hung highscore request. The other four tests retain normal startup, Start/Skip, unavailable backend, title/empty/refresh and stale/large-landscape coverage.
- A bounded **8-second Debug-only readiness-notification hold** is enabled only by `-startupProgressTest` + `-highscoreUITest` + an isolated fixture. It permits observing the transient screen; it is not normal loading timing evidence.
- First run: 4/5 passed; new test failed because the parent accessibility identifier overrode the progress identifier. Fixed children containment and separated the hidden game subtree from the visible loading sibling; full final run passed. [Initial results](loading-progress-2026-09-27/dt3d-progress-tests.log).
- **Release simulator build passed**, `codesign --verify --deep --strict` passed, and Release executable strings do not contain `-startupProgressTest`. [Build command/result](loading-progress-2026-09-27/dt3d-progress-release.log).
- `git diff --check` passed and four local links in changed documentation resolved.
- Lead inspected [runtime progress](loading-progress-2026-09-27/runtime-progress.png) from the isolated held test and [native progress](loading-progress-2026-09-27/native-progress.png) from signed Release `simctl launch --wait-for-debugger`. Both show readable label and yellow bar on the original cover. Native safe-area sizing differs slightly. The debugger-held process was terminated and the Debug build restored. Held captures prove layout, not duration.

[Detailed check context](loading-progress-2026-09-27/checks.txt). No physical-device/VoiceOver session, total launch benchmark, distribution archive or deployment is claimed. Existing `cover-validation.md` is dated 2026-09-26 historical evidence; these new captures document the progress-bar change.

## Findings and consensus

[Independent verdict](loading-progress-2026-09-27/reviewer.md): **APPROVE**, no material findings.

Non-blocking observations: the Start assertion also relies on accessibility hiding, so it is not a direct coordinate-tap test; broader launch-path/UI testing remains a release consideration; older cover validation remains historical evidence. None requires an implementation change or another review round.

Lead: **I agree** with the verdict. The progress indicator, immediate first-frame dismissal, production exclusion of the test hold and executed checks satisfy this task. No important unresolved finding remains. Implementation review consensus is complete, separate from physical-device release acceptance.
