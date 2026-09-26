# Cover startup validation — 2026-09-26

Scope: the owner's supplied cover as the local iOS launch/loading screen, its provenance and optional App Store reuse. The wider App Store release remains specification work. No store assets were uploaded and no submission was sent.

## Implemented behavior

`LaunchCover` bundles the original PNG unchanged. Both app configurations select `LaunchScreen.storyboard`. Its image view uses aspect fit and safe-area edge constraints on navy, without runtime code, network access or an artificial minimum display time. The existing title menu, SceneKit scene, intro and settings code are unchanged.

Original and bundled SHA-256: `89a8112846e8cfa154feaf486f990d024af9d218b5b773b790eea84099e7674d`.

## Executed checks

Environment: Xcode 27.0 (27A266a), iOS 27.0 simulator, iPhone 13. A disposable simulator named `Donkey Trump Cover Check` (`A49BD606-3350-4A5D-9D16-57DAE73D3B6F`) isolated the capture from the owner's simulator data. These are simulator results, not physical-device or distribution-signing evidence.

| Check | Result |
|---|---|
| Debug and Release simulator builds | Passed, including storyboard/asset compilation. |
| Built configuration | Both select `UILaunchStoryboardName=LaunchScreen`, have no generated `UILaunchScreen` dictionary, and contain `LaunchScreen.storyboardc`. The compiled asset catalog contains the 1672 × 941 opaque `LaunchCover`. |
| Original / bundled image | Exact byte match; original master unchanged. |
| Normal launch of locally signed Release build after reinstall | Cover visible, whole title and all three figures present, proportional image with navy borders. Automatically reaches the 3D title menu. No debugger or imposed delay in this recording. |
| Existing `HighscoreBrowsingUITests` | 3 passed, 0 failures: title/list/empty refresh; Start during hung fetch; stale/error and larger-text navigation in both landscape orientations. |
| Focused repeat with locally signed Debug build | `testStartDuringHungFetchAndNoLateReopening` passed again, 0 failures. Start reaches the intro's Skip control while the highscore request is hung. |
| Documents and project | Property-list/XML/JSON syntax, local links, unique specification IDs, 16 quality checklist marks and scoped before/after changes checked. |

Compact actual output: [check-results.txt](evidence/cover-2026-09-26/check-results.txt).

### Visual evidence

- [Ordinary launch frame](evidence/cover-2026-09-26/ordinary-launch-frame.png): frame at 1.6 seconds in the unpaused screen recording. The video canvas retains the simulator's initial portrait orientation, so the landscape app appears rotated in this raw frame.
- [Launch layout](evidence/cover-2026-09-26/launch-layout.png): direct landscape simulator screenshot of the same native launch screen, held using `simctl launch --wait-for-debugger` **only to inspect its layout**. This held capture is not evidence of normal display duration; the ordinary recording above verifies automatic startup.
- [Title after launch](evidence/cover-2026-09-26/title-after-launch.png): direct screenshot after the ordinary Release launch, showing the existing 3D menu and controls.

The lead inspected all three captures against the source illustration. No illustration pixels were edited to create these captures.

### Reproduction

Use an available iPhone 13 simulator ID for `$DT3D_SIM_ID`. Local simulator signing must remain enabled to validate the native launch screen:

```sh
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/dt3d-cover-release -configuration Release \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- build

xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D \
  -destination "platform=iOS Simulator,id=$DT3D_SIM_ID" \
  -derivedDataPath /tmp/dt3d-cover-build -configuration Debug \
  -collect-test-diagnostics never -parallel-testing-enabled NO \
  -only-testing:DonkeyTrump3DUITests/HighscoreBrowsingUITests/testStartDuringHungFetchAndNoLateReopening \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test
```

The initial full three-test run selected `-only-testing:DonkeyTrump3DUITests/HighscoreBrowsingUITests` with `CODE_SIGNING_ALLOWED=NO`. It passed navigation checks, but an unsigned app gave a black native launch screen: SpringBoard logged `Security error -67056` while validating the storyboard. Rebuilding with local ad-hoc signing, verifying with `codesign --verify --deep --strict`, and reinstalling resolved that observation without changing application code. Unsigned captures are not counted as cover acceptance evidence.

For a normal capture, install the signed Release app using `xcrun simctl install`, begin `xcrun simctl io "$DT3D_SIM_ID" recordVideo`, then `xcrun simctl launch "$DT3D_SIM_ID" com.hyldenbrandt.donkeytrump3d`. End recording after the title scene appears. Do not hold the app in a debugger when checking automatic transition.

## Limits and remaining release work

This validates the focused resource/configuration change. Full physical gameplay, both-orientation cold-launch capture on hardware, minimum-supported iOS 26 behavior, distribution signing and the broader release gates remain future release checks. The repeated Start test reaches the intro; it is not a new full-gameplay endurance test. Existing audio-simulator diagnostics and the build's informational App Intents warning do not establish physical audio behavior.

The App Store image set, content-rights assessment and account declarations remain governed by [the release specification](../../specs/002-app-store-release/spec.md). The original prompt and truthful store-use limits are in [cover-art.md](cover-art.md).
