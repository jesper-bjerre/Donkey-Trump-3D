# Faster startup — 2026-09-27

## Authorized scope and implementation

The owner asked that the loading cover remain only for necessary initialization and never wait for highscores. The native storyboard already had no timer or network gate. Inspection found synchronous audio-session activation and preparation of all audio players triggered by `GameModel.muted` before first display.

Audio preparation now runs on a utility queue without holding the playback lock during loading. The constructor and controls return while preparation is pending. The final short publication step uses the existing lock and latest mute, loop and music intentions. Early one-shots are skipped, not queued; stop, skip and pause prevent obsolete playback. Initial game-scene construction is unchanged. Highscores retain their existing asynchronous on-demand fetch: opening the list may wait, startup and Start do not.

This follows [Apple's recommendation to defer work unnecessary for the initial display](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time). No minimum cover duration, artificial delay or extra startup network request was added.

## Participants and independent review

- Lead: OpenAI Codex; exact model ID, tool version and reasoning setting unavailable in this session.
- Independent reviewer: Anthropic via Claude Code 2.1.283, `claude-opus-5-5`, explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`. Did not implement changes.
- Fresh harmless text and JSON probes succeeded: expected assistant model, first-party nonzero usage, empty stderr and no effort-cap warning. [Route evidence](fast-startup-2026-09-27/route.json). Effective effort is not separately provider-attested.
- Review used safe mode, no tools/MCP, no persistence, an isolated temporary directory, full changed sources/diff plus governing and directly relevant surrounding code. Actual assistant responses and successful final provider result identified the required canonical model. [Provider metadata](fast-startup-2026-09-27/review-metadata.json).
- Reviewer independently inspected the text packet and lead-attributed checks. It did not execute tools or inspect xcresult bundles. No fallback or further review round was needed.

## Frozen revision

Git base: `4c191a6c8998c37b6765362b9b17c957fb8ae61f`.
The worktree contains unrelated earlier changes. The task base is the captured pre-edit worktree for these four files, not an assertion that all contents matched HEAD.

[Before hashes](fast-startup-2026-09-27/before.sha256), [final hashes](fast-startup-2026-09-27/candidate.sha256), [scoped patch](fast-startup-2026-09-27/task.diff). Final hashes were rechecked after review; source stayed frozen. This review record and its evidence copies are excluded from payload identity. No commit, push or deployment was performed.

## Checks and limits

- Baseline, signed Debug, iPhone 13/iOS 27 simulator: temporary component probes measured **audio initialization 0.369 seconds** and engine initializer body 0.062 seconds. Engine stored-property construction is outside that latter measurement. [Timing excerpt](fast-startup-2026-09-27/baseline-component-timing.txt). Probe edits were restored before implementation. This is one component sample, not an end-to-end or hardware before/after benchmark.
- Xcode 27.0 (27A266a): app build, **7 audio tests and 4 highscore UI tests passed**. [Command/results](fast-startup-2026-09-27/dt3d-launch-tests.log).
- Strengthened the pending-audio test to also verify the current intro loop starts once preparation completes. **All 7 audio tests passed again**. App and UI-test source were unchanged, so the preceding four UI results still apply. [Final audio command/results](fast-startup-2026-09-27/dt3d-launch-audio-final.log).
- Deterministic suspended-queue tests verify nonblocking construction/controls, no stopped intro/one-shot/music replay, retained current loop, and paused music waiting for resume. Existing cue timing, decoding and session-category checks pass.
- UI checks cover direct Start/Skip with unavailable service, Start during hung fetch, title/empty/refresh, and stale/large-landscape navigation.
- `git diff --check` passed; four local links in changed documentation resolved. [Detailed evidence](fast-startup-2026-09-27/checks.txt).

No physical silent-switch/acoustic test, total cold-launch comparison, Release/archive, or deployment was performed. OS, debugger and initial renderer setup time remain. Extremely early one-shots can be inaudible until audio is ready, as documented. Simulator evidence does not establish physical-device release acceptance.

## Findings and consensus

[Reviewer verdict](fast-startup-2026-09-27/reviewer.md): **APPROVE**, no material findings; requirements satisfied within the implementation scope. A non-blocking observation notes that the audio test temporarily toggles and restores the test host's persisted mute preference.

Lead: **I agree** with the verdict. The source removes synchronous audio preparation from the launch path, the tests cover the affected startup/playback transitions, and no important finding remains unresolved. The authorized implementation is complete; physical-device release gates remain separate. Raw streams and hidden reasoning are not included in this record.
