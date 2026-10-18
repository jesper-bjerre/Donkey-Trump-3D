# Independent implementation review: mandatory `--expected-name` for manual highscore rename

**Role:** Independent Anthropic reviewer. I did not implement this change.
**Mode:** Implementation review. Read-only, no tools or MCP.
**Reviewed content:** The seven-file manifest in the packet (captured uncommitted before state → candidate SHA-256 values as listed), against Git base `368d7001b9…`.

I separated the previously approved before state from the incremental diff. Only the incremental changes are assessed as new this turn.

## Verdict

**APPROVE.** I found no material correctness, security or data-integrity defects in the follow-up. There are two low, non-blocking advisories. Neither is a requirement violation, and both fail safely.

## Assessment of the review focus

| Focus | Evidence | Result |
|---|---|---|
| Mandatory argument checked before credential/store access | `ModerationCommand.cs:42` calls `ValidateArguments` before options, `ValidateTarget` and `CreateOperatorClientAsync` (`:43–51`). The rename branch runs `ExpectedName(args)` (`HighscoreAdministration.cs:34`), which throws 400 `operator_arguments_invalid` when the argument is missing or has an invalid format (`:21–22`). The new negative case is `HighscoreAdministrationTests.cs:40`. | Met. The test is compiled, not executed. |
| Stable identity despite rank shifts | Rename's allowed keys exclude `--rank` (`HighscoreAdministration.cs:28`). The ID comes only from `EntryId` (`:61`), and all lookups go through `Find` by `SubmissionId` (`:53–54`). The live preview showed the same UUID now at rank 7. | Met. Supported by an executed read-only PROD preview. |
| Stale mismatch checked before the no-op | `Rename` compares ordinally (`:46–47`) before `if(entry.DisplayName==name) return document;` (`:48`). In `RunAsync`, the preview `Rename` (`:73`) runs before any `Write`, so a mismatch produces no output and no mutation. Test `:67–69` covers expected `"Old name"` with new name equal to the current `"Player"`. | Met. Compiled only. |
| Match rechecked in the conditional transition | The mutation lambda calls `Rename(current,id,expectedName,name)` (`:80`). In `BlobHighscoreStore.MutateAsync`, the transition runs at `:103` while `uncertain` is still false, so `HighscoreFailure` is rethrown as 409 `entry_changed` (`:118`) and is not converted to `operation_unconfirmed`. The ETag pin (`:101`) normally rejects first with `revision_changed`, so the in-transition recheck is defense-in-depth. The test fake (`:116–119`) skips the ETag check to exercise that path. | Met. Compiled only. |
| Existing ETag and uncertain-write behavior preserved | `expected` and `expectedETag:expected` are unchanged (`:70–71`, `:80`). The `uncertain` handling and `If-Match` behavior are untouched (`BlobHighscoreStore.cs:97–117`). Normalization moved out of the lambda, which is behavior-neutral. | Preserved. |
| Existing prohibited name can be corrected | `ExpectedName` uses only `NormalizeName` and never calls `NameModerationPolicy.Allowed`. Neither `HighscoreDocument.Validate` nor `HighscoreStarters.Fill` filters stored entry names. Test `:59–60` covers this. | Met. Compiled only. |
| Canonical, case-sensitive matching | Stored names are fixed points of `NormalizeName` (`HighscoreDocument.cs:31`). Normalizing the input (NFC plus Zs trimming) and then comparing with `StringComparison.Ordinal` is consistent. Test `:56–58` covers this. | Met. |
| Docs, wrapper and contract accuracy | The wrapper usage (`highscore-admin.sh:12–15`), the doc (`docs/highscore-administration.md:31–46, 56–73`), the contract (`moderation-api.md:96–108`) and the README (`:56–58`) all match the code: mandatory, case-sensitive after trim/NFC, 409 `entry_changed`, no write even when the new name already matches, filter applied only to the new name, checked in preview and mutation. | Accurate. |
| No public route or iOS work | The changes are limited to the operator CLI, docs and tests. No `Program`/route or Swift files are in the manifest. | Met. |

## Findings (non-blocking)

**R1 — Low, advisory.** Existing names that begin with `--` cannot be passed literally.
- **Location:** `ModerationCommand.cs:17` (`value.StartsWith("--")`). This check is pre-existing parser behavior that now also applies to `--expected-name`.
- **Impact:** A stored name such as `--Erik` passes `NormalizeName`, but `--expected-name '--Erik'` is rejected with 400. The operation fails closed and nothing is written.
- **Workaround:** Pass the name with a leading space, for example `--expected-name ' --Erik'`. Parse accepts it, and `NormalizeName` trims the space so it matches the stored name.
- **Disposition:** Not material to the requirement because correction remains possible. Optionally document the workaround. No change is required for approval.

**R2 — Low, advisory, depends on context I do not have.** Copying `displayName` from the console may not reproduce the stored string.
- **Location:** `docs/highscore-administration.md:25` ("Copy its `entryId` and current `displayName`").
- **Impact:** If `HighscoreJson.Options` uses the default `JavaScriptEncoder`, non-ASCII characters are printed escaped (for example `Ren\u00E9`). Names containing invisible `Cf` characters (allowed by `HighscoreValidation.cs:27`) would also not match a visually typed name. Copying the text literally gives a 409 `entry_changed` with no write, so it fails safe.
- **Workaround:** The operator can use bash `$'…'` escapes.
- **Disposition:** Non-blocking. I could not confirm the encoder because `HighscoreJson.Options` was not supplied.

**Excluded as cosmetic:** `moderation-api.md:164` still says "ID/ETag-based rename" while `:108` says ID/expected-name/ETag. This has no behavioral impact.

## Evidence classification

- **Executed:**
  - Release compile of the backend and test projects: 0 warnings, 0 errors.
  - Publish.
  - `git diff --check`.
  - `bash -n` on the wrapper and installer.
  - One read-only PROD preview (`changed:false`, rank 7, score 4000). This preview exercised the matching expected-name path.
- **Compiled but not executed:** All new or changed test assertions, covering mismatch, case sensitivity, the prohibited-old-name case, the in-transition recheck and the missing-argument rejection.
- **Not exercised at runtime:** Mismatch handling, `--apply`, the ETag conflict path and the uncertain-write path. These are verified by source inspection only.

## Limitations and missing context

- I did not have the source for `HighscoreJson.Options`, `NameModerationPolicy`, `ModerationRetention.Purge` or `HighscoreFailure`. I assumed `Purge` removes only expired reports, audit records and spam receipts and does not alter entry display names. This is consistent with the docs but not inspected.
- The packet does not link the installed DLL SHA-256 (`60b5c449…`) to the build or publish of the candidate source. `publish.txt` has no hash. I cannot independently confirm that the PROD-installed tool matches the reviewed candidate.
- The PROD tool installation happened before this review. This approval covers the candidate source. It covers the installed binary only to the extent the lead's provenance record ties that hash to this candidate.