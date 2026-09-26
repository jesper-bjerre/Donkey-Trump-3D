# Donkey Trump 3D — iOS smoke test and recovery runbook

Updated: 2026-09-26. This replaces the copied static-web deployment runbook. The product is the native iOS app built from `src/DonkeyTrump3D.xcodeproj`, scheme `DonkeyTrump3D`, bundle identifier `com.hyldenbrandt.donkeytrump3d`.

## Current delivery status

Local Xcode build, test and device installation are the established development workflow. The repository has [backend DEV/PROD deployment workflows](backend-deployment.md), but no iOS signed distribution pipeline or verified TestFlight/App Store release configuration. A push does not publish an iOS build. Backend HTTPS origins and smoke checks are described in the deployment guide. They do not validate an iOS release.

This runbook covers candidate verification and recovery preparation. It does not claim that the app has been published. Store recovery depends on a new build and the distribution process; there is no guaranteed 15-minute rollback to every installed device.

## Prepare the candidate

1. Record the source revision and whether the working tree contains uncommitted changes. A commit identifier alone does not describe an uncommitted build.
2. Open [the Xcode project](../src/DonkeyTrump3D.xcodeproj/project.pbxproj) in Xcode 27 and choose `DonkeyTrump3D`.
3. Confirm iOS 26.0 minimum deployment target, landscape orientations, intended device families and the signing team for physical-device builds.
4. Record `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`. The current project declares version 1.0, build 1; choose appropriate new values when preparing a distributed update.
5. Choose an installed simulator runtime explicitly. A simulator pass is followed by physical iPhone QA, particularly for sound, haptics, touch and performance.

Run commands below from the repository root.

```sh
xcodebuild -version
xcrun simctl list runtimes
xcrun simctl list devices available
xcodebuild -project src/DonkeyTrump3D.xcodeproj \
  -scheme DonkeyTrump3D -showdestinations
```

The current development machine has iPhone 13 simulators for iOS 26.5 and iOS 27.0, plus an iPhone 18 Pro simulator for iOS 27.0. Select the OS explicitly because device names can repeat. On another machine, use a destination returned by `-showdestinations`.

If an iPhone 13 is absent for an installed, compatible iOS 27 runtime, create it once:

```sh
xcrun simctl create 'iPhone 13' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-13 \
  com.apple.CoreSimulator.SimRuntime.iOS-27-0
```

Do not recreate a device that already exists. Its UUID is local machine state, not a project setting.

## Automated checks

```sh
xcodebuild -project src/DonkeyTrump3D.xcodeproj \
  -scheme DonkeyTrump3D \
  -destination 'platform=iOS Simulator,name=iPhone 13,OS=27.0' \
  test
```

Repeat on the available iOS 26.x runtime when checking the minimum supported major version; on this machine use `OS=26.5`. Keep the test result bundle path printed by Xcode with the candidate's validation record.

There are currently 18 Swift Testing tests across five suites:

- Authored-level loading, floor connections, jump/floor separation and bounded endless difficulty.
- Slope ordering/contact/tilt and player walking, jumping and ladder climbing.
- Life loss/retry, autopilot completion of level 1 and intro phase ordering.
- Intro cue delivery across frame intervals, movement and girder-impact timing, and seek/Reduce Motion cue selection.
- Decoding/duration checks for the eight new WAVs and playback-session category/mixing options.

These tests do not listen to the speaker, operate a physical Ring/Silent switch, measure device frame rate or automate the full SwiftUI interface. Unit coverage for Reduce Motion cue selection is not equivalent to a complete accessibility test.

When deliberately changing the generated intro effects, regenerate them and review the resulting audio before re-running tests:

```sh
python3 src/scripts/generate-intro-audio.py
```

The generator uses the Python standard library and updates the eight `intro-*.wav` effects, leaving the original `intro.wav` march and other web-origin sounds unchanged.

## Manual simulator and iPhone smoke test

Use normal launch for the full journey. Repeat essential checks on a physical iPhone 13 with an installed supported iOS version. Record Pass, Fail or Not tested for each row.

| Check | Expected result | Required evidence |
|---|---|---|
| Launch and offline play | Landscape title, readable controls and playable bundled content with networking unavailable | Simulator and physical device |
| Intro | Carry/climb, put-down, signature, top-down girder tilt and level card all complete | Visual and listening check |
| Expanded intro audio | March loops during movement; footsteps, ladder tones, drop, pen, stamp, creak, impact and ready cues align | Physical listening check |
| Skip and replay | Skip at different phases immediately enters play without residual intro audio; return to title/start works again | Simulator and physical device |
| Silent switch | Sound enabled plus audible volume produces intro, music and effects with Ring/Silent in both positions | Physical iPhone; simulator cannot establish this |
| In-game mute | Title/pause sound controls silence active audio and restore it when enabled; preference survives relaunch | Physical device |
| Touch | Movement, jump, simultaneous input and ladder grabs work; releasing/cancelling input does not stick | Physical device, both landscape orientations |
| Slopes and jump height | Feet/barrels follow girders; jumps cannot reach the next floor | Playtest |
| Hits and retry | One life lost; retry on the same level with score retained and fresh hazards | Playtest |
| Rescue and endless flow | +1000, celebration, next level; layout 3 leads to layout 1 at a higher level number | Play through or use autopilot to assist |
| Score and Game Over | +100 per cleared barrel; zero lives leads to Game Over; Play Again resets run | Playtest |
| Saved best | Best survives relaunch after rescue or Game Over; active run is not restored | Update/relaunch check without uninstalling |
| Pause and lifecycle | Pause/resume preserves run; background, lock, interruptions and route changes recover without stale input/audio | Physical device; investigate failures in intro/transition phases |
| Haptics | Feedback works where supported and stops when disabled; preference persists | Physical device |
| Reduce Motion | Enable before launch: intro starts at card and camera shake is suppressed; review remaining motion | Physical accessibility check |
| Controller/keyboard | Mappings work in menus, intro, play, pause and restart; disconnects recover safely | Available input hardware |
| Performance and layout | Legible HUD/safe areas and acceptable measured frame pacing/memory/thermals in busy scenes | Physical profiling, not simulator FPS |

If iPad remains a supported distribution family, add iPad layout/input checks before release. VoiceOver, larger text and contrast review are tracked in the [backlog](backlog.md).

The current implementation only accepts lifecycle pause during `.play` and has no dedicated audio-interruption/route-change handling. Record any failures and fix them before claiming those scenarios are supported. See the [architecture boundaries](architecture_options.md).

## Development launch options

Set these under the scheme's Run arguments in Xcode, or append them to a `simctl launch` command for an already installed app.

| Argument | Use |
|---|---|
| `-autostart` | Skip title and intro and enter gameplay |
| `-autopilot` | Let the bot play; combine with `-autostart` for flow checks |
| `-introAt 0` | Start the full intro directly |
| `-introAt 7.5` | Start at a specified cutscene time without replaying earlier sound cues |
| `-iconShot` | UI-free title close-up for icon capture |

Do not use `-autostart` to validate the intro, or substitute autopilot for physical touch testing. Launch arguments are parsed by the app; only debug logging is compile-gated, so remove test arguments from normal release-validation launches.

## Archive and distribution preparation

After candidate checks, choose the intended signing team and a generic iOS device destination in Xcode, then use Product → Archive. Validate the resulting Release archive in Organizer. Distribution through TestFlight/App Store is a separate step once the account, app record and channel are configured; this document does not establish their current external state.

Retain the source revision, version/build, Xcode version, archive and dSYMs, automated results, manual device matrix and known issues. Check the actual upload/submission outcome rather than treating archive creation as publication.

## Recover from a bad build

1. **Identify the affected candidate.** Capture version/build, source revision, device/OS, reproduction steps and available crash logs. Distinguish a local development build from a distributed one.
2. **Contain further delivery.** Stop handing out the faulty candidate. If an App Store phased release is active, it can be paused; this does not undo installs or prevent a user from manually downloading the current version. See [Apple's phased-release guidance](https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases).
3. **Prepare a corrected source revision.** Fix or revert the fault in a separate branch/checkout, preserving unrelated work. Use a known-good revision as the behavioural baseline and repeat automated and manual checks.
4. **Create the replacement.** For local development, rebuild and run the corrected app from Xcode. For distribution, assign the required new version/build values, archive/sign and follow the selected channel's validation process.
5. **Verify the installed replacement.** Repeat the failing scenario and smoke checks, including audio, progression and persistence. Test updating in place where possible; uninstalling removes local app data and can hide update problems.
6. **Record the outcome.** Link the bad and corrected revisions/builds, evidence and any remaining device limitations. Keep the fix in the maintained source branch.

An App Store version cannot simply be reverted to an earlier version. Recovering prior behaviour requires a new version containing the corrected or restored code, followed by the normal submission/release process. See [Apple's new-version guidance](https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version). Do not promise that changing source or pausing rollout repairs already installed apps immediately.

## Credentials and release records

Signing identities, certificates, provisioning profiles and any future App Store Connect API credentials must stay in the approved local/build-system credential store. Never put private keys, passwords or tokens in source, docs, command examples or logs. The optional highscore integration needs a real HTTPS API origin in Release; the app never embeds an Azure storage key or service credential. The backend deployment guide records Azure origins; the iOS build setting still needs explicit release configuration.

Release records should distinguish automated passes, simulator smoke results and physical-device checks. The last audio-change validation on 2026-09-25 passed 18 tests on iPhone 18 Pro/iOS 27 and reached gameplay after the intro; physical mute-switch verification was still outstanding. Revalidate the actual candidate rather than treating that earlier run as current release approval.

## Highscore release inputs and recovery

The native highscore UI and .NET 10 API are implemented; see [local validation](../specs/001-global-highscores/validation.md) and [runnable quickstart](../specs/001-global-highscores/quickstart.md). The actual backend resources, GitHub delivery and rollback procedure are described in the
[backend deployment guide](backend-deployment.md); that App Service target supersedes
the original Container Apps proposal. Signing/distribution and iPhone acceptance
remain separate release prerequisites.

- Use the separate DEV and PROD App Service apps, existing shared Linux plans and
  private same-region Hot/LRS containers. Each API identity has only container-scoped
  Blob access; never embed account keys or SAS in app configuration.
- Distinguish local Azurite concurrency results from live Azure RBAC/write/persistence
  results and pipeline smoke checks. Consult the dated deployment evidence.
- Keep platform logs within the privacy boundary. Maintain the deployed DKK 80/month
  pre-tax budget and owner cost warnings covering the project-tagged apps and storage; verify them before
  release and inspect warnings as described in the deployment guide. Per-process
  rate limits and delayed budget alerts do not guarantee a monthly bill.
- DEV F1 may cold-start; PROD uses Always On. Backend delays must never block offline
  gameplay. Shared-plan capacity and existing-app health require operational checks.
- Configure the real `HIGHSCORE_API_BASE_URL` HTTPS origin; verify Release ATS and fixture/integration exclusion. On physical iPhone 13, check ranks 1/50/100, keyboard dismissal, optional public-name notice, VoiceOver focus/labels, large Dynamic Type, both landscapes, buttons during hang/failure, background/reconnect/relaunch without queued uploads, and existing silent-switch/intro audio.

A rollback changes the API/app revision while preserving the private ranking blob. Never reset, delete or overwrite scores to hide a deployment/storage error. Unknown schema/corruption must fail closed; investigate against a protected backup under an explicitly authorized recovery plan. Retain the prior tested release package/configuration and validate compatibility before changing revisions. A lost POST acknowledgement may already have committed; rollback/refresh must not replay that player's submission. Record actual recovery results and remaining limitations.

The initial deployment does not configure Blob versioning or a protected backup.
Any data-recovery operation must first establish an explicitly authorized protected
copy; the rollback pipeline only restores API code and never rewrites scores.
