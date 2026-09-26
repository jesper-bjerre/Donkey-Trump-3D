# Donkey Trump 3D — Product specification

Updated: 2026-09-26. This specification describes the native iOS implementation in [src](../src), replacing the imported plan for the 2D browser game. Implemented behavior and outstanding release checks are distinguished below. Documentation and player-facing UI remain in English.

## Product and audience

Donkey Trump 3D is a single-player arcade platformer for **iPhone, running iOS 26 or later in landscape**. The player controls Jumpman Løkke, climbs the sloping girders of Trump Tower in Nuuk, dodges barrels marked `TARIFFS`, and rescues Motzfeldt. Donkey Trump is the satirical antagonist.

The app renders a three-dimensional world with procedural character models, lighting, shadows, animated scenery, particles and cinematic cameras. Movement and collisions use a side-on gameplay plane within that 3D world; the player does not move freely into the scene's depth.

The primary audience is players who enjoy short arcade sessions and the political satire. Touch is the primary input. Game controllers and external keyboards are additional input options. There is no account, multiplayer, advertising or gameplay analytics integration. Optional public highscores use a separate backend; gameplay never depends on its availability. Game content is bundled for offline play after installation.

The Xcode target also includes iPad. iPhone is the primary product and validation target; iPad layout and device testing remain separate release checks.

## Current product decisions

| Area | Current behavior |
|---|---|
| App | Native Swift app using SceneKit, SwiftUI, UIKit, AVFoundation and GameController |
| Project | `src/DonkeyTrump3D.xcodeproj`, scheme `DonkeyTrump3D`; development baseline Xcode 27 |
| Display | Landscape left and right; English UI |
| Presentation | 3D Nuuk construction site, aurora, sea, mountains, houses, crane, snow and themed lighting |
| Characters | Procedural, jointed 3D caricatures of Jumpman Løkke, Donkey Trump and Motzfeldt |
| Controls | Floating thumb stick, jump touch zone, optional controller and keyboard |
| Progression | Three authored layouts repeated endlessly, with bounded increases in barrel difficulty |
| Scoring | Three starting lives, +100 per barrel jumped, +1000 per rescue |
| Local storage | Best score and sound/haptics preferences in `UserDefaults` |
| Sound | Original synthesized WAVs, background music, looping intro march and eight synchronized intro effects |
| Silent mode | With in-game sound enabled and device volume audible, audio is configured to play even when the iPhone Ring/Silent switch is silent |
| Distribution | Local Xcode builds are supported. TestFlight/App Store setup and release status are not established by this repository |

## Player journey

1. Launch to a title screen with an animated demonstration, Start Game, Highscores, How to Play, sound and haptics controls, and the local best score.
2. Choose Start Game to watch the opening cutscene: Trump carries Motzfeldt up the tower, puts her down, returns to his platform, signs an executive order, and the girders tilt from top to bottom.
3. Use Skip, controller confirm/menu, or keyboard Enter/P/Esc to leave the intro and enter level 1. Reduce Motion skips the choreography to the level card.
4. Move along girders, jump barrels and climb ladders to reach Motzfeldt. The camera follows the action.
5. A hit costs one life. With lives left, the current level restarts after hit/retry feedback, preserving the score and generating fresh barrel randomness.
6. A rescue adds 1000 points, shows celebration effects, saves the best score and advances to the next, harder level.
7. At zero lives, Game Over shows the score and level reached. Play Again starts level 1 with three lives and zero score. Returning to the title allows a new game with the intro.

There is no terminal victory screen after layout 3. The rescue celebration and victory jingle accompany each successful level; play continues until the player loses all lives or leaves the run. Restart from the pause menu and Play Again bypass the intro.

## Controls

| Input | Action |
|---|---|
| Left thumb | Drag the floating stick to move horizontally; push up/down while overlapping a ladder to climb |
| Right thumb | Tap/hold the jump zone to jump; releasing early shortens the jump |
| Multi-touch | Move or climb with one thumb while using the jump zone with the other |
| Controller | D-pad/left stick for movement and climbing, A/B for jump, Menu for pause/resume; A confirms |
| Keyboard | Arrows/WASD for movement and climbing, Space for jump, P/Esc for pause/resume, Enter to confirm |
| Pause menu | Resume, restart from level 1, return to title, sound and haptics toggles |

The current touch implementation allocates the leftmost 45% of the view to the stick and the remainder to jumping. Instructional copy describes these as the left and right halves. Controls account for safe-area insets; physical iPhone usability still requires testing.

## Gameplay rules and content

| Rule | Specification |
|---|---|
| Jump height | Approximately 44.1 level-coordinate units at full height; cannot reach the next floor |
| Jump behavior | No double jump; short coyote-time allowance and early-release jump cut |
| Ladders | Require overlap. Holding up/down can catch a ladder while airborne; climbing suppresses gravity |
| Slopes | Player feet and rolling barrels follow line-segment girder geometry |
| Hazards | The boss occupies the right side; rolling barrels start leftward, follow slopes, drop from girder ends and may take ladders. Direct throws target the player |
| Hit and retry | One life lost per hit; 1.4-second hit phase plus 0.6-second retry phase when lives remain |
| Rescue | +1000 points and a 3.2-second celebration before the next level |
| Barrel points | +100 once per cleared barrel. No time bonus or active combo multiplier is implemented |
| Best score | Updated in memory during play and persisted on rescue or game over; active runs are not saved for relaunch |
| Restart | Level 1, zero score and three lives; retained local best score |

| Layout | Name | Initial barrel speed range | Initial spawn interval | Initial active-barrel cap |
|---|---|---|---|---|
| 1 | Girder Warm-Up | 90–120 level units/s | 3200 ms | 5 |
| 2 | Press Room Scramble | 100–140 level units/s | 2600 ms | 6 |
| 3 | Summit Showdown | 110–165 level units/s | 2000 ms | 8 |

Each layout contains six girders. Later levels reuse layouts 1, 2 and 3 while the difficulty ramp approaches limits: 240–280 level units/s for barrel speed, 800 ms between spawns, 55% direct-throw probability and at most 12 active barrels. These are code bounds, not proof of fairness on every later level.

## 3D presentation and feedback

- SceneKit builds the tower, ladders, barrels, environment and character rigs in code. Materials and procedural textures provide surfaces, faces and signs.
- Character poses cover walking, carrying, climbing, jumping, hits, signing, throwing and celebrations.
- Rendering uses physically based materials, HDR/bloom, ambient occlusion, soft shadows, vignette and depth of field in selected camera shots.
- Camera modes include the title orbit, intro close-ups, gameplay follow, rescue and game over.
- Feedback includes hit sparks, girder/landing dust, trails on direct throws, score text, confetti, screen shake and optional haptics.
- The three layouts use different environment colour themes.

The asset requirement remains original satirical work: procedural caricatures, models, textures and effects, plus the project's own synthesized audio. Do not substitute copied Nintendo/Donkey Kong sprites, models, music or sound recordings. The app identifies itself as an original parody without affiliation to a game publisher or politician.

## Audio requirements and latest changes

The app uses `AVAudioSession.Category.playback` with `.mixWithOthers`. The physical Ring/Silent switch must not mute enabled game audio; other apps' audio can mix with it. The app's own sound setting remains authoritative, persists across launches, and immediately silences active effects, jingles and music. Device output volume and the selected audio route still apply.

The opening march now loops throughout the carrying/climbing path and stops for the signing phase. Eight new effects follow the cutscene timeline:

| Effect | Trigger |
|---|---|
| Heavy footsteps | Walking segments, with alternating pitch |
| Ladder tones | Climbing segments, with rising/falling pitch patterns |
| Put-down cue | Motzfeldt is placed on the top platform |
| Pen strokes | Signature begins |
| Stamp | Signature reaches 80% of the signing phase |
| Girder creak | Each girder begins tilting |
| Girder impact | Each girder finishes tilting, aligned with dust and haptics |
| Ready cue | Final level card |

Skipping the intro or returning to the title stops all intro voices. Reduce Motion and the intro seek launch argument omit earlier cues rather than replaying a backlog of sounds. Audio loading failure must not block gameplay.

## Acceptance criteria

| ID | Player outcome | Acceptance check |
|---|---|---|
| IOS-US-01 | Start an installed iPhone game | App opens in landscape and reaches title, intro and play without a network dependency |
| IOS-US-02 | Navigate and dodge by touch | Simultaneous movement/jump works; no stuck input after release, pause or resume |
| IOS-US-03 | Climb to the rescue | Ladders require overlap, can be caught in mid-air, and remain necessary for floor progression |
| IOS-US-04 | Understand the 3D scene | Character, barrel, ladder and girder positions remain legible through camera motion on iPhone 13 |
| IOS-US-05 | Recover from a hit | One life is deducted; retry keeps score and restarts the current level |
| IOS-US-06 | Continue after a rescue | Rescue awards 1000 points and transitions through layouts 1, 2, 3, then 1 again at higher difficulty |
| IOS-US-07 | Start another run | Game Over and pause-menu restart reset the run and retain the saved best score |
| IOS-US-08 | Hear the complete intro | March and eight effects follow the animation; Skip stops intro audio before gameplay |
| IOS-US-09 | Control sound explicitly | Enabled audio works with physical silent mode; in-game mute and persisted preferences work |
| IOS-US-10 | Reduce visual motion | System Reduce Motion skips intro choreography and disables gameplay camera shake |
| IOS-US-11 | Play with optional inputs | Controller and keyboard mappings work through start, intro, gameplay, pause and restart |
| IOS-US-12 | Keep data local | Best score/settings stay on-device; gameplay introduces no account or analytics service |

These criteria define validation work. Their inclusion does not mean all physical-device checks have passed.

## Quality, accessibility and privacy

The simulation uses fixed 120 Hz steps, and the view requests up to 120 frames/s. Actual frame rate depends on the device and workload; no measured physical iPhone performance budget is recorded here. Profile iPhone 13 for frame pacing, memory, battery and sustained thermal behaviour before release.

SwiftUI menus have accessibility labels for several controls, and the app reads the system Reduce Motion setting when the engine is created. Full VoiceOver navigation, larger text, contrast, touch targets and reduced-motion behaviour across all scenes remain QA work. A code label or simulator pass is not an accessibility certification.

The app stores its local best score and sound/haptics preferences. A player may explicitly publish a chosen name and completed-run score to the shared top 100; names need not be real. It does not implement an analytics adapter, telemetry endpoint or identity-based leaderboard. Product feedback and difficulty evaluation currently rely on manual playtests. Local debug logs and test results support development; there is no runtime monitoring service.

## Scope and remaining decisions

Implemented scope includes the native 3D app, touch controls, three looping layouts, intro, audio, haptics, local best score and optional controllers/keyboards. Browser hosting, HTML/JavaScript bundles, Phaser, web analytics and web deployment are no longer part of this product specification.

The [global top-100 highscore feature](../specs/001-global-highscores/spec.md) is implemented in the iPhone app and [ASP.NET Core service](../src/backend/README.md). A final-life Game Over obtains a fresh qualification read, asks for an optional public name, and centres the exact published run. Nonqualification shows the bottom and final score; a rising cutoff is explained. Title browsing starts at the top. Reads and writes are asynchronous, with an eight-second UI ceiling; stale cache is explicitly browse-only. Closing, backgrounding or starting a new run retires the old opportunity. Failed/ambiguous submissions never resume or resend; a lost acknowledgement is described as unconfirmed. The local best stays independent.

The backend validates client-reported scores without login or full anti-cheat guarantees. Equal scores retain successful-save order, conditional Blob writes merge concurrent updates, and same-ID deduplication applies only while ranked. No production URL or cloud deployment is invented. [Validation](../specs/001-global-highscores/validation.md) distinguishes executed local checks from physical-device/live-Azure release prerequisites.

The following remain outside current scope: online multiplayer, accounts, cloud saves, in-app purchases, advertisements, free-depth movement, additional languages and new authored layouts. They require separate product decisions.

Before a public release, establish physical-device QA evidence, iPad support expectations, signing/distribution ownership and an actual release channel. No launch date, App Store approval, TestFlight availability or automatic publishing pipeline is asserted here.

See [architecture](architecture_options.md), [implementation and QA backlog](backlog.md), and [iOS smoke/recovery runbook](production-smoke-and-rollback.md).
