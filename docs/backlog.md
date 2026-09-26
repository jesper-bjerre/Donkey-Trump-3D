# Donkey Trump 3D — Implementation and release backlog

Updated: 2026-09-26. This replaces the imported web-game work orders, estimates and launch dates. The baseline is the current Swift/SceneKit iOS app in [src](../src), not a new Phaser project.

**Status meanings:** Implemented means present in source, not automatically certified on physical hardware. Open means work or verification remains. Priorities below apply to release preparation; they do not assert an approved launch date or distribution channel.

## Implemented baseline

| ID | Capability | Status and evidence |
|---|---|---|
| IOS-001 | Native iOS app and project | Implemented: [Xcode project](../src/DonkeyTrump3D.xcodeproj/project.pbxproj), shared scheme, iOS 26+, landscape, SwiftUI/SceneKit; iPhone primary, iPad also enabled |
| IOS-002 | 3D world and characters | Implemented: [Render](../src/DonkeyTrump3D/Render) builds procedural character rigs, tower, ladders, barrels, Nuuk scenery, aurora, snow, lighting, materials and particles |
| IOS-003 | Touch, controller and keyboard | Implemented: [Input.swift](../src/DonkeyTrump3D/Input/Input.swift) merges floating-stick/jump touches with controller/keyboard input |
| IOS-004 | Slopes, jumps and ladders | Implemented: [Player.swift](../src/DonkeyTrump3D/Core/Player.swift) and [Slope.swift](../src/DonkeyTrump3D/Core/Slope.swift); short jumps, no double jump, slope contacts and mid-air ladder grabs |
| IOS-005 | Barrel hazards | Implemented: [Barrels.swift](../src/DonkeyTrump3D/Core/Barrels.swift); rolling, end drops, ladder routing and direct throws |
| IOS-006 | Score, lives and run flow | Implemented: [Simulation.swift](../src/DonkeyTrump3D/Core/Simulation.swift); three lives, +100/barrel, +1000/rescue, retry preserving score, pause, game over and restart |
| IOS-007 | Three layouts and endless progression | Implemented: [Level.swift](../src/DonkeyTrump3D/Core/Level.swift) and bundled JSON; layouts repeat with bounded increases in difficulty |
| IOS-008 | Cinematic intro | Implemented: [IntroTimeline.swift](../src/DonkeyTrump3D/Core/IntroTimeline.swift) and engine; carrying, signing, girder tilt, level card, Skip and reduced-motion shortcut |
| IOS-009 | Sound through physical silent mode | Implemented: [AudioSystem.swift](../src/DonkeyTrump3D/Audio/AudioSystem.swift) uses playback mode with mixing; in-game mute persists and silences active voices. Physical switch verification remains open |
| IOS-010 | Expanded intro soundtrack | Implemented: [IntroSoundtrack.swift](../src/DonkeyTrump3D/Core/IntroSoundtrack.swift), looping march and eight new WAV effects; cleanup on Skip/title; [reproducible generator](../src/scripts/generate-intro-audio.py) |
| IOS-011 | Local preferences and feedback | Implemented: local best score, sound/haptics toggles, camera shake, confetti and score feedback; some accessibility labels and Reduce Motion handling |
| IOS-012 | Automated coverage | Implemented: [CoreTests.swift](../src/DonkeyTrump3DTests/CoreTests.swift) and [IntroAudioTests.swift](../src/DonkeyTrump3DTests/IntroAudioTests.swift), 18 tests across five suites |
| IOS-013 | iPhone 13 simulator | Available locally with iOS 26.5 and 27.0; Xcode lists both as compatible destinations. This is development-machine configuration, not a bundled app feature |

The audio change was built and all 18 tests passed on the iPhone 18 Pro/iOS 27 simulator on 2026-09-25. A simulator smoke check reached gameplay after the full intro. Those results are historical evidence for that build, not physical-device acceptance or a release sign-off. Re-run the suite for each release candidate.

## Implemented global highscores

The [top-100 specification](../specs/001-global-highscores/spec.md) and [technical proposal](../specs/001-global-highscores/technical-proposal.md) cover anonymous names/scores, Game Over positioning, title-screen access, asynchronous loading and safe concurrent storage updates. The user chose no deferred submission after a connection failure. The [ASP.NET Core service](../src/backend/README.md) and native iPhone flow are implemented, including ETag concurrency, asynchronous title/Game Over views, optional public names, failure retirement and no deferred uploads. Client scores are validated but not cheat-proof. See [tasks](../specs/001-global-highscores/tasks.md) and [executed evidence](../specs/001-global-highscores/validation.md). Remaining release inputs/checks include the real HTTPS hostname, live managed identity/container permissions, container execution and physical iPhone accessibility/audio. Implementation is not deployment approval.

## Open release checks

### IOS-QA-01 — Physical iPhone 13 audio and silent switch

**Priority:** P0. **Status:** Open. **Scope:** Validate IOS-009 and IOS-010 on a real device.

Acceptance checks:

- With audible output volume and in-game Sound enabled, intro effects, music and gameplay sounds work with the Ring/Silent switch in both positions.
- In-game Sound off silences currently playing audio; switching back on restores audio correctly. The setting survives relaunch.
- The march covers the carrying/climbing sequence; all eight new effects are audible and appropriately balanced against animation and music.
- Skip during movement, signing and girder tilt stops intro audio without leaking effects into gameplay. Test normal completion and Reduce Motion too.
- Another app's audio can mix as intended. Record behaviour with speakers, headphones and Bluetooth routes that are available for testing.
- Save device model, iOS version, app version/build and observations. Do not substitute simulator category assertions for this check.

### IOS-QA-02 — iPhone touch controls and full run

**Priority:** P0. **Status:** Open.

Acceptance checks:

- On iPhone 13, controls and menus fit both landscape orientations and safe areas.
- Test simultaneous movement/jump, short/full jumps, ladder entry/exit, mid-air grabs and finger cancellation.
- No movement or jump remains stuck after releasing fingers, pausing, resuming or returning to the title.
- Complete the three authored layouts and enter level 4; the first layout returns at higher difficulty instead of ending the game.
- Confirm +100 per barrel, +1000 per rescue, one life per hit, score-preserving retry and fresh barrel patterns.
- Confirm Game Over, Play Again, restart from pause and best-score persistence at rescue/game-over save points.

### IOS-QA-03 — App lifecycle and audio recovery

**Priority:** P0. **Status:** Open; implementation gaps may require changes.

The app sends a pause request when its scene becomes inactive, but the engine currently accepts pause only during active gameplay. Dedicated audio-interruption and route-change observers are absent.

Acceptance checks:

- Exercise background/foreground and screen locking during gameplay, intro, hit/retry, rescue and paused states.
- Confirm fair gameplay pause/resume, cleared input and the intended audio state after each transition.
- Test calls and output-route changes where practical; prevent duplicate music loops, permanently silent audio or continued unintended playback.
- Agree and implement intro/transition suspension behaviour if current results are unsuitable. Add focused regression coverage for any resulting logic change.

### IOS-QA-04 — Physical-device performance

**Priority:** P1. **Status:** Open.

Measure startup, frame pacing, memory and sustained thermal/battery behaviour on iPhone 13 with Xcode Instruments. Include title, full intro, all themes, direct-throw trails, rescue particles and later levels approaching the 12-barrel cap. Record actual results and agree release budgets from those measurements. The fixed 120 Hz simulation and requested 120 FPS do not establish measured device performance.

### IOS-QA-05 — Accessibility and alternate inputs

**Priority:** P1. **Status:** Open.

Acceptance checks:

- Review VoiceOver names/navigation, larger text, contrast and target sizes for title, help, pause, sound/haptics, Skip and Game Over.
- Validate Reduce Motion from a fresh launch: intro choreography is skipped and camera shake is absent; review other camera/particle animation separately.
- Verify that necessary gameplay feedback remains understandable with sound or haptics disabled.
- Test controller and keyboard through start, Skip, play, pause/resume and restart, including input-device disconnects.
- Record limitations explicitly; do not carry over web WCAG compliance claims without native-app assessment.

### IOS-QA-06 — Level contracts and flow regression coverage

**Priority:** P1. **Status:** Open.

Existing tests cover key mechanics, but invalid bundled levels currently terminate startup and Codable decoding is not a complete geometry validator.

Add meaningful checks for malformed/missing level data, finite/bounded geometry, spawn/rescue positions, ladder endpoints and usable barrel settings. Extend flow coverage where it reduces risk: layout 3 to level 4, zero-lives game over, restart/reset and best-score save points. Decide whether invalid-content recovery should remain a build-time gate or also receive a player-facing fallback.

### IOS-QA-07 — iPad release decision and layout validation

**Priority:** P1. **Status:** Open.

The target currently includes iPad. Confirm whether it will be distributed on iPad; if so, validate both landscape orientations, HUD/help/menu sizing, camera composition and touch reach on an iPad. If distribution is intentionally iPhone-only, change target configuration as a separate product change rather than documenting an unsupported restriction.

## Open distribution work

### IOS-REL-01 — Establish signed release delivery

**Priority:** P0 before external distribution. **Status:** Open.

Choose the release channel and responsible owner. Verify signing/team configuration, bundle identifier, version/build numbering and required store materials for that channel. Retain the original-asset/parody requirement and ensure privacy descriptions match the local-only implementation. Create a Release archive, retain its source revision and dSYMs, and execute the [iOS smoke/recovery runbook](production-smoke-and-rollback.md) on the exact candidate.

There is no verified TestFlight/App Store setup or automated publishing pipeline in this checkout. Do not treat a successful simulator build, commit or push as publication. A store release requires its own distribution checks and process.

### IOS-REL-02 — Automate repeatable build and test checks

**Priority:** P1. **Status:** Open.

If CI is introduced, use a macOS runner with a selected Xcode/runtime, run the shared scheme's tests, retain useful build/test results and separate unsigned simulator checks from signed distribution. Keep signing secrets outside the repository. No specific CI provider, retention period or production-on-push behaviour is currently configured.

### IOS-REL-03 — Release evidence and recovery rehearsal

**Priority:** P1. **Status:** Open.

Record candidate version/build, source revision, toolchain, device matrix, test evidence and known issues. Rehearse rebuilding a known-good source revision into a replacement candidate. Preserve existing user data while testing updates. Recovery must follow the selected iOS distribution channel; the old static-site redeploy procedure and 15-minute restoration promise do not apply.

## Deferred product work

New authored layouts, Danish localisation, additional accessibility options, cloud saves, multiplayer, monetisation and remote analytics are not implemented commitments. Each needs a separate product decision before scheduling. There is no need to recreate an empty analytics adapter just because the imported web backlog specified one.

## Retired web-specific work

The copied tasks for Phaser/Vite/npm setup, browser boot manifests, sprite sheets, DOM overlays, browser compatibility pages, HTTP security headers, Azure Static Web Apps, static-site smoke tests, analytics event adapters and terminal victory flow have been replaced by the native scope above. Their old work-order IDs, story-point estimates and calendar dates are not current iOS commitments.

Product rules are maintained in [prd_spec.md](prd_spec.md); implementation boundaries are in [architecture_options.md](architecture_options.md).
