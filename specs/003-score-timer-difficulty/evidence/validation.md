# Validation disposition — 2026-10-18

Current prompt: speckit-implement only. Tests/manual gameplay were not explicitly requested. Every runtime execution below is **not run**. No service/emulator, app, UI runner, test runner, physical game or deployment was launched. Test sources and test bundles were authored/compiled; compilation is not an executed test. Source inspection and compile-only results are separate evidence.

| Check | Boundary | Authored source / future evidence | Execution |
| --- | --- | --- | --- |
|V01|Reference scores/visible L|ScoreTimerDifficultyTests.referenceJourneys; CoreTests; CompletedRunTests|Not run — not requested|
|V02|Cross-life cap|ScoreTimerDifficultyTests.capAndDistinctLifetimesSurviveDeath|Not run — not requested|
|V03|Lifetime/empty/multiple clearances|ScoreTimerDifficultyTests.emptyJumpMultiBarrelAndCompletionOnce; pooledReleaseCopiesIdentityAndBallisticAimSurvivesFalling|Not run — not requested|
|V04|Fractional/time/completion once|ScoreTimerDifficultyTests.wholeBonusBoundaries; emptyJumpMultiBarrelAndCompletionOnce|Not run — not requested|
|V05|Attempt reset/timeout/final life|ScoreTimerDifficultyTests.retainedTimeAndExactTimeout; timeoutFinalLifeAndStaleEventsFreezeResult|Not run — not requested|
|V06|Actual timeline/inputs/inactivity/stalls|GameplayTimelineTests; ScoreTimerDifficultyUITests.testTimerStartsAndPauseExcludesElapsedTime|Not run — not requested|
|V07|Terminal races and late events|ScoreTimerDifficultyTests.terminalOrderAndLossBoundaryNeverAwardClearance; GameplayTimelineTests.terminalRetirementStillDeliversPendingLifecycle|Not run — not requested|
|V08|Pressure/modes/drift|ScoreTimerDifficultyTests.pressureCheckpointsAndFloors; pooledReleaseCopiesIdentityAndBallisticAimSurvivesFalling|Not run — not requested|
|V09|New level/restart state|GameplayStateTests.retryRetainsLevelButRestartReplacesIt; ScoreTimerDifficultyTests.referenceJourneys|Not run — not requested|
|V10|Floor/scheduling/sequences|ScoreTimerDifficultyTests.firstDelayAndCappedOpportunitiesDoNotAccumulate; DifficultySequenceTests; physical acceptance separately|Not run — not requested|
|V11|HUD/exact/zero result feedback|ScoreTimerDifficultyUITests.testRetainedMaximumTimeRescueShowsZeroBonusAndExactTotal; core result tests|Not run — not requested|
|V12|Five-point numeric/storage boundary|ScoreDomainTests; ScoreGranularityTests (pure schema1/2); ScoreGranularityStorageTests (real isolated schema2); HighscoreRealSubmissionUITests|Not run — not requested|
|V13|History/failure/privacy/no replay|HighscoreFailureTests; HighscorePublicationTests; HighscoreServiceTests; GameplayFixtureBoundaryTests; fixture UI best/relaunch cases|Not run — not requested|
|V14|Copy/accessibility/physical iPhone|ScoreTimerDifficultyUITests; existing UI accessibility suites; physical180s upper/max-pressure/landing/touch/readability/frame-pacing checks|Not run — not requested|

## Target distinctions and limits

- GameplayTimeline is the production adapter used by GameEngine, driven with controlled stamps in authored checks. Pure candidate/session checks alone do not establish render/input/lifecycle integration. Normal30/60/120Hz timing and arbitrary foreground-debt recovery remain unexecuted. Large debt can delay visible clocks while it drains.
- Pure document domain checks cover schema1/2; real storage scope uses an owned loopback Azurite schema2 container. A fresh store/API factory provides separate readback without replaying POST. The external helper restart recipe remains an explicitly requested integration procedure. No production target or schema migration was used.
- Synthetic CompletedRun API checks prove transport/ranking/storage when run, not gameplay earning. Gameplay fixtures cannot use that publication exception and isolate real best/settings. Release compilation/source exclusion is not a passing runtime launch-boundary check.
- Physical iPhone13 full180s upper attempts, retained-maximum retries, every layout/ramp limit, actual touch/readability/frame pacing and settings are not run. Simulator compilation is not physical acceptance.
- No existing same-run restore exists in inspected source; runs remain memory-only. No persistence system added.

Implementation source/build completion does not establish gameplay, integration or release acceptance. Unrequested tests alone do not block authorized implementation under AGENTS.md.
