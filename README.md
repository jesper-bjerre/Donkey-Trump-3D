# Donkey Trump 3D

A native iPhone 3D remake of the [Donkey Trump](../Donkey-Trump) browser game, and the same political satire. You play Jumpman Løkke, climbing sloped red truss girders and ladders up a half-built **Trump Tower, Nuuk** to rescue Motzfeldt. Donkey Trump throws barrels stencilled `TARIFFS` down at you from the top. Every new game opens with the cutscene: Trump carries Motzfeldt to the top, then signs an **EXECUTIVE ORDER: ALL GIRDERS SLANTED**, and the girders tilt one by one.

Swift + SceneKit + SwiftUI. The iOS app has no third-party dependencies, accounts or tracking. It includes optional [global top-100 highscores](specs/001-global-highscores/spec.md) backed by a small [ASP.NET Core/Blob service](src/backend/README.md). Gameplay works independently of backend availability; a production HTTPS service URL must be configured before online use.

Cold startup shows the owner's [Donkey Trump cover](docs/design/images/DonkeyTrumpCover.png), fitted without cropping over a dark background, then proceeds directly to the game. The [cover record](docs/design/cover-art.md) preserves its source prompt and possible use alongside App Store gameplay captures.

## Run

Open `src/DonkeyTrump3D.xcodeproj` in Xcode 27 or later and run the `DonkeyTrump3D` scheme on an iPhone or simulator (iOS 26+, landscape). To run on a device, set your team under *Signing & Capabilities*.

```sh
cd src
xcodebuild -project DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D \
  -destination 'platform=iOS Simulator,name=iPhone 13,OS=27.0' test
```

Debug launch arguments (set them in the scheme, or pass them to `simctl launch`):

| Argument | Effect |
|---|---|
| `-autostart` | Skip the title screen and the intro |
| `-autopilot` | The bot plays (used for automated playtests) |
| `-introAt 7.5` | Start the intro cutscene at a given second |
| `-iconShot` | UI-free close-up of the boss, used to render the app icon |

## Global highscores

Open Highscores from the title, or finish a run. A fresh qualifying result offers optional public-name entry; Submit publishes and centres/highlights that exact run. A nonqualifying result shows the bottom and final score. Ties retain earlier successful saves. Close, Start and Play Again work during network requests; list refresh is read-only and stale data is labelled. Failed or unconfirmed submissions are never queued or sent later, while the local best is retained. Scores are client-reported without login or cheat-proof verification.

Set the Xcode `HIGHSCORE_API_BASE_URL` build setting to the real HTTPS backend origin. It is intentionally empty by default. Debug accepts loopback development transport; Release keeps ATS enabled and excludes synthetic fixtures and integration overrides. See the [reproducible local guide](specs/001-global-highscores/quickstart.md) and [validation evidence](specs/001-global-highscores/validation.md). Backend delivery uses [DEV/PROD App Service pipelines](docs/backend-deployment.md). Physical iPhone and App Store release checks remain separate prerequisites.

## Controls

| Input | Action |
|---|---|
| Left thumb, anywhere on the left half | A floating stick. Move, and push up/down on a ladder to climb (hold up mid-jump to grab one) |
| Right thumb, anywhere on the right half | Jump (it can't reach the next floor, so use the ladders) |
| Game controller | Stick/D-pad, A/B jump, Menu pauses |
| Keyboard | Arrows/WASD, Space jumps, P/Esc pauses, Enter confirms |

## What's "3D" about it

- **Rendering:** physically based materials, HDR with bloom, SSAO, vignette and chromatic fringe, and soft deferred shadows from a moonlit key light, with image-based lighting generated per level theme.
- **World:** a Greenland night. An animated aurora shader in the sky, reflected in an icy sea, plus low-poly procedural icebergs, snowy mountains, colourful Nuuk houses, a rotating tower crane with blinking beacons, falling snow, and a gold "TRUMP TOWER" sign on the roof.
- **Characters:** procedural caricatures with jointed rigs (walk, climb, jump, tumble, cheer, rage, wind-up/throw, signing, carrying).
- **Themes:** each of the three layouts has its own sky and aurora (green, violet, ember).
- **Cameras:** a follow camera in play, and cinematic cameras for the title orbit, the intro, the rescue (with depth of field) and game over.
- **Effects:** sparks on a hit, dust when girders land and when thrown barrels touch down, fire trails on barrels hurled straight at you, Greenland red-and-white confetti on a rescue, and floating score text.
- **Feel:** haptics, screen shake (off with Reduce Motion), and iOS 26 Liquid Glass UI.

## Gameplay: a faithful port

The gameplay core in `src/DonkeyTrump3D/Core` is a direct Swift port of the web game's pure systems. It keeps the same 800×600 level coordinates, the same `level1–3.json` files and the same tuning:

- `Slope.swift` is the line-segment slope resolver.
- `Player.swift` covers movement, the short 44 px jump (it can never clear a floor gap), coyote time, jump cut and overlap-gated ladders.
- `Barrels.swift` handles rolling, dropping off girder ends, taking ladders, and direct throws aimed at the player.
- `Simulation.swift` handles hits, barrel-jump points, the rescue, and `GameSession` (lives, score, retry, endless levels).
- `Level.swift` holds the endless difficulty ramp: layouts repeat 1, 2, 3, 1, … and the barrels approach fair limits.
- `IntroTimeline.swift` is the executive-order cutscene choreography.

Scoring follows the web game: 3 lives, +100 per barrel jumped, +1000 per rescue, a hit retries the level and keeps the score, and game over restarts from level 1. The best score is stored on the device. The simulation runs at a fixed 120 Hz step on SceneKit's render loop (`App/GameEngine.swift`). Each retry gets fresh barrel randomness.

## Layout

| Path | Responsibility |
|---|---|
| `src/DonkeyTrump3D/Core` | Framework-free gameplay (testable) |
| `src/DonkeyTrump3D/Render` | Materials and procedural textures, world builder (environment, girders, ladders, barrels, aurora shader, icebergs), character rigs, particle effects |
| `src/DonkeyTrump3D/App` | App entry, `GameEngine` (loop, scene sync, cameras, cutscene, events) |
| `src/DonkeyTrump3D/UI` | SwiftUI title, HUD, intro overlays, pause and game-over menus, all copy |
| `src/DonkeyTrump3D/Input` | Multi-touch controls, game controller and keyboard polling |
| `src/DonkeyTrump3D/Audio` | Sound and music (the web game's original synthesized WAVs) and haptics |
| `src/DonkeyTrump3DTests` | Swift Testing suite for levels, slopes, player, flow and intro |
| `src/backend` | .NET 10 Minimal API, private Blob persistence and conditional writes |
| `src/DonkeyTrump3D/Highscores` | Async service/coordinator, DTOs and Debug-only fixtures |
| `src/backend.tests`, `src/DonkeyTrump3DUITests` | Contract, concurrency, lifecycle and UI acceptance tests |
| `specs/001-global-highscores` | Highscore requirements, implementation tasks, contracts and validation evidence |

## Asset originality

The 3D gameplay models, textures and effects are generated in code, and the soundtrack uses the project's synthesized audio. The launch screen also bundles the owner's prompt-generated cover illustration; its source and prompt are retained in [the cover provenance record](docs/design/cover-art.md). The generation tool and licensing terms were not supplied, and the release content/rights assessment remains open under [FR-006](specs/002-app-store-release/spec.md).

References to the classic arcade game's style are design inspiration, not authorization to copy Nintendo/Donkey Kong assets or a claim of rights clearance. This is an original satirical parody, not affiliated with any game publisher or politician.
