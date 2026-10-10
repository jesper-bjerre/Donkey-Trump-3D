# Independent Implementation Review: Donkey Trump 3D 1.0 (2) Store Artwork, Configuration and Connect Draft

**Role:** Independent reviewer only. I did not take part in the implementation, and I launched no other agents. I ran no tools or tests and changed nothing.
**Mode:** Implementation review of the finished store-artifact change and its acceptance evidence. This is not a whole-project feature audit or a release-readiness sign-off.
**Candidate:** Base `368d7001…`, plus the frozen manifest in the packet. I viewed the images downscaled to 2000 px wide.

## Missing context

These items were not in the packet. The conclusions that depend on them are qualified below.

1. **Declaration and readback records** (`declarations.md`, `territories.md`, `connect-readback.md`; T051/T052). I could assess declarations only through the summary at `release-record.md:59-78`.
2. **EU trader (DSA) status** in Connect, and who set it, if anyone.
3. **Icon source hashes and history:**
   - SHA-256 of the supplied `01_App_Icons` / `02_Xcode` source icons. Without them I cannot confirm the "byte for byte" claim.
   - Whether `AppIcon.png` was tracked at the base commit.
4. **Screenshot and manifest sources:** `build_screenshots.py` output logs and `candidate-source-manifest.json` contents.
5. **Physical testing details:** the owner's device, OS, build and scenarios.

## Findings

### R-01 — HIGH — The content-rights declaration and rights gate have no reconciled basis for the final shipped and marketed content

**Locations:**
- `rights-assessment.md:3`, `:14`, `:23`, `:27`
- `release-record.md:63-66`
- `HighscoreStarters.cs:8-13`
- `screenshots-en/05-highscores.jpg`
- `AppIcon-*.png`, with provenance in the artwork README at `:71`

**Evidence:**
- **The rights gate is still open.** The rights assessment still reads "DISTRIBUTION BLOCKED". It requires reassessing "the final candidate, added starter catalog and every final store asset before T040/T055". Its last entry (`:27`) says the final naming/content and media assessment "still need reconciliation before distribution".
- **The owner's attestation is narrow.** It covers only the owner-made cover and music.
- **Content introduced or exposed by this task falls outside that attestation:**
  - A new icon that is a photoreal caricature of a real public figure, produced by a third-party image generator on 29 September.
  - Store screenshot 05, which shows Bugs Bunny, Daffy Duck, Scooby-Doo, Fred Flintstone and Garfield in App Store metadata.
  - A starter catalog that also contains Disney character names.
- **The saved declaration goes beyond that basis.** Connect's Content Rights answer ("necessary rights to third-party content") was saved on the basis of the owner's cover/music assertion only.

**Governing requirements:**
- FR-006 and FR-009: "Missing facts MUST be obtained before attestation."
- US3-AS4: no rights claim or legal acceptance is invented.
- T008 and T055: an explicit rights PASS, "rechecked for final content", is required before draft assembly.
- Constitution IV, lines 106-108.

**Impact:**
- An agent-saved attestation to Apple goes beyond the recorded owner facts.
- The metadata raises exposure under App Review Guideline 5.2.
- The rights gate the project defined was skipped without any record.

This is not a legal conclusion about infringement. The problem is that the declaration has no recorded factual basis.

**Disposition — a genuine owner-input prerequisite, not a request to adjudicate a review finding:**
1. Update the rights assessment for the final icon, the starter catalog and all five store images.
2. Obtain the owner's explicit confirmation that the Content Rights answer holds for:
   - the public-figure depictions, including the new icon;
   - the cartoon character names in the app and in store screenshot 05.
3. Alternatively, the owner can make a product decision. For example, reseeding the disposable capture dataset with original synthetic names and replacing screenshot 05 would be in scope.

If the lead can show that the owner already confirmed the full-scope answer, this becomes a record correction only.

### R-02 — MEDIUM, conditionally HIGH — The basis for EU trader status and other owner-only declarations is not evidenced

**Locations:**
- `release-record.md:77`: 173 planned territories.
- `owner-inputs.md:7`, `:16`: "No mail/phone/trader answer supplied; never invent them."
- `declarations.md` was not supplied.

**Evidence:** The planned availability includes EU storefronts. The record does not say what the DSA trader status is, whether it is set, or who set it.

**Governing requirements:** FR-009, US3-AS4 and T051, which requires a field/answer/source record.

**Impact depends on who set the status:**
- **If the agent set it without owner facts:** it is an invented legal attestation, and this finding becomes a HIGH submission blocker.
- **If the owner set it earlier:** the record only needs the basis.
- **If it is unset:** the "173 territories" status overstates actual EU availability.

**Disposition:** The lead must state the actual Connect trader status and its source.

### R-03 — MEDIUM — Release-acceptance gates are unmet and not listed individually

**Locations:**
- `release-record.md:108-111`, which gives only a generic caveat.
- `owner-inputs.md:39-49`.

**Unmet gates:**
- **T042 (exact-build physical testing).** The owner's iPhone 13 statement is dated 2026-09-28. Build 2 was archived and uploaded on 2026-09-29, so that testing cannot have covered the selected build. Build 2 differs only in icon and build number, which lowers the practical risk but does not change the evidence rule.
- **T044 (iPad compatibility smoke check).** Not run. It was also noted in the orientation review as N4.
- **T043 (demonstrated report-to-disposition workflow).**
- **T008 (rights).** See R-01.

**Governing requirements:**
- Constitution V, lines 80-82 and 126-128.
- FR-016: "Unperformed physical checks remain readiness blockers."
- FR-020 ("Once readiness gates pass…"), T055 and US2-AS5.

**Impact:** "Ready for Review" could be read as release readiness.

**Disposition:** Record correction.
- The owner's explicit instruction authorizes submission. Manual release keeps publication separate, and submitting is not releasing.
- Under Constitution V, these gates remain unmet release-acceptance requirements. The owner's instruction does not turn them into passes.
- They must be named individually wherever status is reported, including when the owner is about to release manually.

### R-04 — LOW — The release record contains stale, contradictory status

**Locations:** `release-record.md:1` ("preparation in progress"), `:81-86`, `:100-105`, `:113-117`, all against `:120-135`.

**Evidence:** Earlier sections still describe the screenshot upload failure, the failed Add for Review and "independent review has not started" as current. The resumed section supersedes them.

**Governing requirements:** FR-022, T061 and SC-007, which require the record to identify completed work and the next action without reconstruction from chat.

**Disposition:** Keep the history, but relabel it as superseded and add one final, dated status block.

### R-05 — LOW — Revision-identity evidence is incomplete for the icon replacement

**Locations:** `git-base.diff`, `pre-edit-manifest.json`, `release-record.md:13-14`.

**Evidence:**
- The record says `AppIcon.png` was removed, but neither diff shows the deletion.
- The pre-edit manifest captures only `project.pbxproj` and `Contents.json`.
- Either the Git diff was limited to certain paths and omits a tracked deletion, or an untracked file was deleted without a recorded pre-edit copy.
- The "byte for byte" claim has no hashes for the supplied source files.

**Governing requirement:** AGENTS.md lines 212-220.

**Impact:** The before/after patch cannot be fully reproduced. Nothing in the shipped result is affected: the archive shows `CFBundleIconName AppIcon`, and Connect shows the new icon.

**Disposition:** Record the deletion, the pre-edit copy if one exists, and the supplied source hashes.

### R-06 — LOW — Screenshot 03 deviates from the store contract's composition item 3

**Locations:** `contracts/store-release.md:48` and T048 item 3 (another real level or rescue moment), against `screenshots-en/03-controls.jpg`.

**Assessment:**
- **The deviation is disclosed.** The record (`release-record.md:44-46`) states it honestly and makes no claim that the rescue scene was captured.
- **The governing spec requirements are still met** (FR-004, SC-002, US1-AS2):
  - There are five ordered, real, opaque 2868×1320 images.
  - The image shows real app UI with no fabrication.
  - The caption "Touch controls, keyboards and game controllers" is backed by `Copy.swift:14-17`.
  - Contract item 2 (readable controls) is already covered by images 01 and 02.
- **The owner-supplied guide is consistent with this outcome.** `CAPTURE_GUIDE.md:22` allows a different or smaller truthful set.
- **The missing element is marketing coverage of the rescue loop,** not truthfulness, required counts or Apple acceptability.

**Disposition:** Record the deviation as accepted in the media or acceptance record, citing the spec criteria it still meets. It should not be left implicit. No recapture is required, and this does not block submission.

## Checks I confirmed from the sources

- **Build number:** `CURRENT_PROJECT_VERSION = 2` in all five app configurations (`project.pbxproj:318`, `:350`, `:507`, `:539`, `:703`). Test targets stay at 1, which does not matter because they are not distributed. The orientation fix is intact.
- **Icon catalog:** `AppIcon.appiconset/Contents.json` is a valid single-size catalog with light, dark and tinted luminosity variants. The icons are RGB PNGs without alpha, and the tinted variant is grayscale. This is consistent with iOS 26.
- **Screenshots:**
  - Final images are 2868×1320 JPEGs without alpha, an accepted 6.9-inch landscape size.
  - Each frame shows the complete capture at its original aspect ratio with no painted gameplay.
  - The captions are truthful.
  - The highscore image shows only approved starter entries from the disposable DEV capture dataset.
  - There are no debug controls or real-player data.
- **Export compliance:** "None of the algorithms mentioned above" is consistent with the source. `URLSession` HTTPS and `SecRandomCopyBytes` are OS-provided (`InstallationCredentialStore.swift`, `URLSessionHighscoreService.swift`).
- **Privacy labels:** The summarized labels match the backend and pages:
  - User ID for the public handle and Device ID for the installation hash.
  - Gameplay Content and Customer Support for scores and reports.
  - Unlinked diagnostics, consistent with `HighscoreDiagnostics.cs`.
- **Tests:** The statement that no tests were run is accurate. The validator, `codesign`, `sips` and diff checks are not tests.

## Verdicts

1. **Finished artifact implementation: ACCEPTABLE.** I found no material defect in the icon import, the build configuration, the screenshots or the saved Connect draft. R-05 and R-06 are record items only.
2. **Accuracy of evidence and status: NOT YET COMPLETE.** The factual claims I could check are consistent. R-03 and R-04 must be corrected, and R-02 must be answered, before completion is declared.
3. **Submission may proceed: NOT YET.**
   - Connect has no remaining technical blocker, and the owner has authorized submission.
   - One genuine prerequisite remains: **R-01**, the owner's confirmation of the content-rights basis or a product decision.
   - **R-02** must be clarified. If the agent set the trader status, it is also a blocker.
   - Once these are resolved, submission may proceed with manual release kept on.
   - The R-03 gates remain disclosed as unmet release-acceptance requirements. No claim of readiness or acceptance may be made.

## Non-blocking suggestions

- **S1:** Screenshot 05 shows "1.000" (Danish digit grouping) in an English listing, where en-US readers see it as 1. Capture with an en-US region next time.
- **S2:** Images 01 and 02 are nearly identical, and the barrels in 02 are tiny with no jump in progress. A future refresh could show an actual jump and a rescue.
- **S3:** Image 03 has a black pill-shaped artifact at its left edge, and the bottom link is clipped. Both are cosmetic.
- **S4:** Add `ITSAppUsesNonExemptEncryption = NO` to `Release-Info.plist` so Connect does not ask the compliance question for every build. This matches the answer already given.
- **S5:** Review notes could mention the political satire of public figures and explain that the starter highscore entries are generated by the server.

## Limitations

- I did not independently verify the hashes, the processed state in Connect, live URLs, the backend, runtime behavior or the archive contents. I relied on the lead's attributed summaries.
- This review gives no legal clearance and no prediction of App Store approval.
- The whole-product resemblance to the reference game (Guidelines 4.1 and 5.2) is a prior product decision outside this scope.
- My own statement of my model identity does not verify the reviewer configuration. The lead must record that from session metadata, as required by AGENTS.md lines 112-118.
