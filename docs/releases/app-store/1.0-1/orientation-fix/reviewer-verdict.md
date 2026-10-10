# Independent review: iPhone-only fix for the iPad multitasking Validate App error

**Verdict: APPROVED, no material findings.**

The lead may record consensus on this unchanged candidate. No further review round is needed.

## Scope and context

- **Role:** independent reviewer only. I did not implement this change and launched no other reviewer.
- **Mode:** implementation review of a bounded configuration fix. This is not a release-readiness assessment.
- **Context:** the packet was sufficient. Nothing necessary was missing.

## Independent verification

**1. The fix addresses the reported error.**
- The original archive declared `UIDeviceFamily [1,2]` with landscape-only `~ipad` orientations.
- The iPad multitasking rule, which requires all four orientations unless full-screen is required, applies only when the bundle declares iPad family 2.
- With `TARGETED_DEVICE_FAMILY = 1`, Xcode emits `UIDeviceFamily [1]`, so the rule no longer applies.
- The replacement archive extract shows `UIDeviceFamily: [1]`. This matches the cited Apple Info.plist key reference.

**2. The change is complete across all five app target configurations.** I inspected the full `project.pbxproj`:

| Config | Family | iPad orientation key removed |
|---|---|---|
| Debug | `project.pbxproj:339` | yes |
| Release | `project.pbxproj:371` | yes |
| Debug Local | `project.pbxproj:528` | yes |
| Debug PROD | `project.pbxproj:560` | yes |
| AppStoreCapture | `project.pbxproj:726` | yes |

- No `UISupportedInterfaceOrientations_iPad` key remains anywhere in the file.
- `src/Configuration/Release-Info.plist` adds no orientation or device keys.
- There is no `UIRequiresFullScreen` or portrait workaround.

**3. Landscape is preserved.**
- `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` still lists LandscapeLeft and LandscapeRight in all five configurations.
- The archive shows `UISupportedInterfaceOrientations~iphone` with both landscapes.
- This matches constitution line 91 and contract line 5.

**4. The change stays in scope.**
- Test and UI-test targets keep `"1,2"` (lines 446, 463, 479, 495, 642, 659, 675, 691, 768, 784). These bundles are never distributed, so this does not affect the shipped app.
- Nothing else in the file differs from what the diff describes.

**5. Requirements and the history prerequisite are satisfied.**
- **FR-002 and contract step 1:** device-support history had to be checked before narrowing to family 1.
  - The 2026-09-28 discovery record shows no prior Connect app and no prior bundle ID.
  - The app ID 6817091486, version 1.0 (Prepare for Submission) was newly created.
  - No build was uploaded.
  - So no earlier iPad-capable release blocks the narrowing.
- **Owner decision:** iPhone-only is recorded in owner-inputs line 12 and spec line 185.
- **Constitution:** the "platform change requires an explicit design decision" rule (line 92–94) is met by that recorded owner decision. iPhone remains the primary acceptance target.

**6. The evidence supports the claims.**
- The archive validator enforces `UIDeviceFamily == [1]` (`validate-ios-release.py:28`), iPhoneOS platform, the exact PROD URL, no capture flag, and a privacy manifest. It exited 0.
- The build-phase boundary check (`project.pbxproj:269`) must also have passed, because the Release archive succeeded.
- The AppIntents metadata warning is benign.
- `plutil -lint` and `git diff --check` are appropriate format checks.
- None of these is a test, so the no-tests rule (AGENTS.md:9–27) was respected. Stating that no tests ran is accurate.

## Non-blocking notes

These need no implementation or re-review.

- **N1 – distribute the right archive.** The `2026-09-28` Archives folder holds both the old universal archive (`PROD 28-09-2026,22.35`) and the replacement. Make sure Organizer uploads or validates only `DonkeyTrump3D PROD iPhone-only.xcarchive`. The old one will reproduce the error.
- **N2 – don't tick T032.** `tasks.md:70` is much broader: it also covers compile-outs and `ReleaseConfigurationTests`. This fix satisfies only its family-1 and landscape portion.
- **N3 – constitution wording is now stale.** Constitution line 92 still says "iPad is enabled in the project." That is no longer true, but it is a descriptive baseline rather than a MUST, so there is no conflict. Reconcile it in a later governance edit if desired. No amendment is needed for this fix.
- **N4 – iPad compatibility-mode behavior is unverified.** How the landscape-only iPhone build presents on iPad in compatibility mode is untested. Contract lines 98–100 already require a labelled iPad-simulator compatibility smoke test before draft readiness.

## Limitations

- I could not recompute the SHA-256 or open the archive. I relied on the lead's command results and the Info.plist extract, whose filtering command was not shown. The `pbxproj` source independently confirms that no iPad orientation key exists.
- Apple's server-side Validate App was not rerun, so its acceptance is not established.
- There was no upload and there is no claim of App Store approval.
- Simulator and physical-device runtime behavior of this archive are unverified.
- This review is not release-readiness acceptance.
- My own model and effort self-report does not verify reviewer configuration. The lead must record that from session metadata, per AGENTS.md:112–118.
