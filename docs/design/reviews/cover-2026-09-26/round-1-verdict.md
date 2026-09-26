# Independent Implementation Review: Donkey Trump cover as launch screen

**Role:** independent reviewer (Anthropic, Opus 5.5, `claude-opus-5-5`). I did not implement this change. I reviewed read-only with no tools and did not recursively review. The lead implementer is OpenAI Codex; its exact model and reasoning metadata are unavailable, as stated.

**Candidate:** `manifest.json` SHA-256 `339f27e10b8e32779a3041318d0cd294e5d733fe29794b2e9c998e8aa61ca4ed`, on base `e323551c…` plus the captured-before hashes.

## What I checked independently

- **Configuration (`project.pbxproj:291`, `:324`).** Both app configurations replace `UILaunchScreen_Generation` with `UILaunchStoryboardName = LaunchScreen`. No other project settings changed. The folder is a synchronized root group, so the new `Resources/` files are picked up without adding file references. The built plist check confirms no `UILaunchScreen` dictionary is left over from `Configuration/*-Info.plist`.
- **Storyboard (`LaunchScreen.storyboard:17–31`).**
  - The image view uses `scaleAspectFit` and is pinned to all four safe-area edges over an opaque navy background.
  - It has no runtime code, timer, gesture or network use, and the accessibility element is disabled.
  - Aspect-fit inside the safe area structurally guarantees no cropping or distortion on any landscape size.
  - The design-time device (`retina6_1`) and placeholder frames don't match iPhone 13. That only matters at design time and is not material.
- **Asset (`LaunchCover.imageset/Contents.json`).** A single universal image. The source hash (captured before and after) equals the bundled hash `89a81128…`, so the master is unchanged. The compiled 1672×941 image at scale 1 is consistent with this.
- **Images, inspected myself:**
  - **`launch-layout.png`:** the complete illustration is visible, with the whole title, Trump with barrel, Løkke and Motzfeldt with flag. Navy borders show on all sides, with no cropping or distortion.
    - The fitted image is about 550×309 pt, smaller than the roughly 656×369 pt the landscape safe area would allow. Its top/bottom insets (about 47/34 pt) match portrait safe-area values applied during launch.
    - That is a system layout characteristic, not a cropping defect. The motif stays whole and proportional, which is what the acceptance criteria require.
  - **`ordinary-launch-frame.png`:** the same composition, rotated on the portrait video canvas, with an identical fitted size. It is consistent with the held capture.
  - **`title-after-launch.png`:** the existing 3D title shows Start Game, Highscores, How to Play, Sound and Haptics, plus the parody and no-affiliation footer. The menu is preserved.
- **Regressions.** No Swift, gameplay, intro, menu or settings source changed. The full `HighscoreBrowsingUITests` suite passed 3/3, and the focused signed Start/hung-fetch test passed again. Both are proportionate for a resource-only change.
- **The -67056 black screen with an unsigned build.** This is a local signing and environment artifact. It is correctly excluded from acceptance evidence, and ordinary Xcode runs sign locally.
- **Specification changes.**
  - US1 scenario 5, FR-024 and SC-008 are testable.
  - They keep store use subordinate to FR-004–FR-006 and forbid presenting the cover as gameplay or as a substitute for screenshots, consistent with Guideline 2.3.3.
  - The historical review record is explicitly not relabeled (`requirements.md:39`), and the Assumptions scope carve-out (`spec.md:159–161`) is accurate.
- **Provenance and store boundaries (`cover-art.md`).**
  - The prompt is retained.
  - The unknown generation tool and terms are stated honestly, with no legal clearance claimed.
  - The cover is not presented as a store screenshot or icon, and nothing was uploaded.

## Findings

### F1: Medium, blocking. README originality statement is now inaccurate

- **Location:** `README.md:82–84` ("Asset originality").
- **What's wrong:** this section still says *"Every model, texture and effect is generated in code … No Nintendo or Donkey Kong material is used."* This change adds the project's first bundled raster artwork. It was not generated in code, it is an owner-supplied AI-generated illustration explicitly prompted "i donkey kong stil", and its generation and licensing terms are unknown (`cover-art.md:9`).
- **Impact:** the repository's main originality claim now misdescribes the shipped bundle. The release work in FR-006 and FR-009 (content-rights declaration) will draw on this project provenance, so the stale sentence invites an unsupported "all assets code-generated" assertion.
- **Requirement:**
  - Constitution V: implementation completion MUST include documentation describing actual behaviour.
  - Constitution IV: bundled visual material must be original project material or have documented permission.
  - The task's own acceptance item: "prompt provenance retained".
  - The README was edited in this change (line 7), so fixing it is in scope.
- **Required fix:**
  - Limit the "generated in code" claim to the 3D game's models, textures and effects.
  - State that the launch screen bundles the owner-supplied, prompt-generated cover, and link to `docs/design/cover-art.md`.
  - Note that its generation terms and rights assessment remain open under FR-006.
  - Do not assert clearance. The "No Nintendo or Donkey Kong material is used" sentence can remain as a no-copied-assets statement if the wording makes clear the cover's arcade style is inspiration, not permission.
- **Re-check needed:** refresh the manifest and run the local link and document check. No build or UI test rerun is needed.

I found no other important defects. Specifically:

- Byte identity holds.
- Proportional, uncropped display is shown by the images.
- The transition is automatic and local, with no timer.
- Flows and settings are preserved.
- The Debug/Release scope is limited to the launch setting.
- The store-use boundary is truthful.

Once F1 is fixed, I agree the focused implementation satisfies the applicable requirements.

## Missing context and limitations

- **Player-facing copy not supplied.** I did not receive `src/DonkeyTrump3D/UI/Copy.swift` or the privacy and How to Play text. I cannot verify whether any in-app statement also claims all art is generated in code. If one does, the same fix as F1 applies. If none does, F1 stays limited to the README.
- **No video.** I saw only the recording frame at 1.6 s, not the video itself. Automatic dismissal rests on the lead's recording description plus the title screenshot showing the 3D menu. The flow is plausible and consistent, but I did not observe it directly.
- **Prompt not compared.** I cannot compare the retained prompt against the owner's original message and accept it as supplied.
- **Simulator only.** All evidence is from an iOS 27 iPhone 13 simulator in one orientation. The following remain outstanding future release gates and do not block this focused change:
  - physical-device display, including very large launch-image handling on hardware;
  - both orientations on hardware;
  - iOS 26 minimum behavior;
  - distribution signing;
  - FR-006 content and rights assessment of the cover's likenesses and arcade resemblance.

## Verdict

**BLOCKED**, pending F1 (Medium): the README asset-originality statement at `README.md:82–84` contradicts the newly bundled AI-generated cover. Everything else in the focused change is acceptable. A focused re-review needs only the corrected README diff (plus any in-app copy correction, if applicable), the refreshed manifest and the document-check output.
