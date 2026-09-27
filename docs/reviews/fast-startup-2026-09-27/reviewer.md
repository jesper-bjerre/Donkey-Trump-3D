# Independent review: asynchronous audio preparation and launch path

**Verdict: APPROVE**

No material findings. I agree the requirements are satisfied for implementation completeness within the stated scope.

## What I checked

**Owner requirement: cover only for necessary preparation; highscores async**
- `GameModel.muted` still initializes `AudioSystem.shared` synchronously on the main thread (`DonkeyTrump3DApp.swift:28`).
- The constructor now only reads `UserDefaults` and enqueues work (`AudioSystem.swift:74-79`). Session activation, file decoding and `prepareToPlay` moved to the utility queue (`AudioSystem.swift:81-103`). This removes the measured component from the UI thread.
- `GameEngine` initial scene building is unchanged. It is plausibly necessary for the first interactive frame.
- `HighscoreCoordinator` has no startup read. `openTitle()` is the only title-path fetch (`HighscoreCoordinator.swift:66`). The contract says a title refresh "may" begin (`ios-flow.md:9`), so not adding a prefetch is compliant.
- The launch storyboard has no gating logic.

**Thread ownership (Constitution II)**
- Players are built in locals without the lock, then published under the existing `NSLock` (`AudioSystem.swift:104-110`).
- `prepared`, `requestedLoops`, `requestedMusicLevel` and `musicPaused` are read and written only under that lock.
- `self` is captured after all stored properties are initialized, and the class is `final`.
- The render thread's `play`/`stop` calls can block only for the short publish section, not during decoding.
- `lastStep`/`stepFlip` remain unlocked. That is pre-existing and render-thread-only.

**Mute and silent switch (Product boundaries)**
- The `.playback` + `.mixWithOthers` category is retained.
- Loaded players start at volume 0. On publish they take the latest `isMuted`, so a toggle during preparation is honored.
- The muted-loop-keeps-sync behavior (`play` guard, line 128) is preserved.

**No replay after skip or exit (Product boundaries)**
- One-shots are never queued.
- `requestedLoops` is cleared by:
  - `stop` (path→sign transition, `GameEngine.swift:451`)
  - `stopIntro` (`finishIntro`, `.toTitle`, `startIntro`)
  - a non-looping `play` of the same key
- I traced `startIntro`, `updateIntro`, `finishIntro`, `.toTitle`, `.restart`, hit/retry, `levelComplete` and `gameOver`. None leaves a stale loop or music intent that preparation would later start.
- The Debug-only `.highscoreFixtureGameOver` path skips `stopIntro`. That already left the loop playing before this change, so it is not a regression.

**Music state**
- `resumeMusic` now requires `requestedMusicLevel != nil`. Previously it checked `currentTime > 0`.
- The new check is stricter and correct for `stopMusic`, because `AVAudioPlayer.stop()` does not rewind.
- The hit→retry, pause→resume, `gameOver` and `levelComplete`→`levelStarted` sequences behave as before.
- A pause issued before preparation keeps music silent until resume (lines 117-120).

**Evidence (Constitution V)**
- Both new unit tests use a suspended serial queue. That makes the before-preparation window deterministic rather than timing-dependent.
- Each test always reaches `queue.resume()`, since `#expect` does not throw. So no suspended queue is deallocated.
- The first log shows the earlier test name `pauseBeforePreparationDoesNotStartMusicUntilResumed`, and the second shows the renamed, strengthened test. This matches the lead's account that only test and doc content changed between runs.
- The UI evidence comes from the first run and is valid for the unchanged app and UI-test source.
- Simulator-only scope, the missing total launch benchmark, and the lack of physical silent-switch or acoustic checks are disclosed. None of these is presented as device or release evidence.

**Documentation**
- `cover-art.md:14` accurately describes the implemented behavior, including the intentional skipping of early one-shots.

## Non-blocking observations (no action required)
- `delayedPreparationDoesNotBlockControlsOrReplayStoppedAudio` briefly writes the shared `muted` `UserDefaults` key in the test host and then restores it. This is harmless in the executed runs.

## Limitations of this review
- This was a read-only inspection of the supplied packet only. I did not execute any build, test or hash check.
- I did not see `HighscoreFixtureService` (the "unavailable"/"hang" fixture behavior), `cover-validation.md`, the Xcode project file, or the full dirty-worktree context outside the four scoped files.
- I did not independently verify the SHA-256 manifest, the Markdown link resolution, or the xcresult bundles. I relied on the lead-attributed logs as quoted.
- The launch-time benefit is inferred from code structure and the lead's single simulator component sample, not from a measured before/after cold launch.
- Physical-device silent-switch, audibility and performance acceptance remain release gates, not part of this implementation verdict.
