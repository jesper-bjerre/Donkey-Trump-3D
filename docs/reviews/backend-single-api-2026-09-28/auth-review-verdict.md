# Focused re-review: operator MI token pre-acquisition

## Verdict: **APPROVE**

This approval covers the four files identified by the supplied MANIFEST hashes, as shown in the FILE sections. It does not cover the DIFF as supplied, which misrepresents the candidate (see R9). I found no material defect in the code. R10 is a rollout gate, not a code blocker.

## Code assessment

I reconstructed the delta by comparing the DIFF pre-images with the FILE contents. Only three things changed:

- **ModerationCommand.cs:49**: `CreateClient()` is replaced by `await CreateOperatorClientAsync(token)`.
- **CaptureCommand.cs:15** and **:18**: capture now uses the pre-acquired client.
- **HighscoreOptions.cs:44-55** and **moderation-api.md:82-85**: the new factory method and its contract text.

Everything else in both command files is byte-identical to the pre-image.

What I confirmed:

- **Validation runs before authentication.**
  - `ValidateTarget` (ModerationCommand.cs:44) runs before the token request at :49.
  - Capture's target and isolation checks (CaptureCommand.cs:11-14) run before :15.
  - The capture token is obtained before its 6-second deadline starts at :16.
- **No mutation or ambiguity is introduced at startup.**
  - A failed token request or the 30-second cancellation throws before any Blob request.
  - It is caught at ModerationCommand.cs:84 as a fixed code with exit 1.
  - The ambiguous-acknowledgement semantics of `MutateAsync` (BlobHighscoreStore.cs:79-110) are unchanged.
- **No credential is exposed.**
  - The `AccessToken` result at HighscoreOptions.cs:53 is discarded.
  - Blob client diagnostics logging is off (:39).
  - Exception text is never written.
- **The credential is reused correctly.**
  - The same `TokenCredential` instance goes into the returned client (:54).
  - The scope `https://storage.azure.com/.default` matches the default Blob audience, so the client can reuse the cached token.
  - The linked cancellation source is disposed on return, and the client does not capture its token.
- **Deadlines are unchanged.**
  - `IsValid` still bounds `OperationTimeoutSeconds` to 6 or less and network time to 2 or less (:31).
  - The store's 6-second deadlines are untouched.
  - Within the packet, the only call sites are the two operator paths. The public DI path still uses `CreateClient`.
- **The identity choice is consistent.** `ValidateTarget` rejects a user-assigned client ID for dev/prod (ModerationCommand.cs:34), so the cloud path is always system-assigned, the same as `CreateClient`.
- **The Azurite path bypasses cloud authentication** (:48). This path is exercised by the owned loopback operator smoke.
- **Capture still targets the same account.** Building the service client from `options` rather than `selected` matches the previous behavior; `CaptureOptions.Storage` copies `BlobServiceUri`.

## Findings

### R9 — MEDIUM — Revision identity (the DIFF misrepresents the candidate)

**Location:** DIFF headers for `ModerationCommand.cs` (`index 4a44923..0000000`, "deleted file mode") and `CaptureCommand.cs` (`ac31015..0000000`).

**Problem:**
- The supplied diff shows both operator files as deleted and never shows their new contents.
- The MANIFEST and FILE sections show both files present and modified.

**Impact:**
- If the Git index or worktree really does stage these deletions, a commit would remove operator mode. The pipeline would then either fail to build or ship without the reviewed code.
- Either way, the DIFF does not satisfy the AGENTS.md "scoped staged/unstaged diff" identity requirement.

**Required action:**
1. Regenerate the scoped diff, including staged and untracked files.
2. Confirm `git status` shows both files as modified, not as deleted or untracked.
3. Confirm the committed blob hashes and the pipeline-built artifact match the MANIFEST.
4. Record the corrected diff.

The verdict applies only to the MANIFEST content. Different content is a different candidate.

### R10 — MEDIUM — Rollout gate (a green pipeline does not prove the new code is loaded)

**Evidence:** The PROD pipeline was green while the old package was still mounted, and a manual app-only stop/start was needed. The repaired code will go through the same unchanged pipelines.

**Required before any PROD conversion:**
1. **DEV:** after the pipeline runs, verify that the running package is the new ZIP digest (deployment.json plus the loaded artifact, restarting if needed). Then rerun a cold, separate-process operator `inspect` from `/home/site/wwwroot` and a capture/operator smoke.
2. **PROD:** deploy the identical ZIP digest and verify it is actually loaded, as in step 1.
3. **PROD:** confirm maintenance is still true after restart, then run a cold `inspect` from `/home/site/wwwroot`.
4. Only then run `migrate`, followed by the remaining prior verification steps 4–7.

**Two notes on the /tmp run:**
- The read-only run of the DLL copied into `/tmp` is valid diagnostic evidence only. The contract (moderation-api.md:78) requires running the wwwroot DLL, so it is not conversion or artifact evidence.
- Remove that `/tmp` copy.

### R11 — LOW — Traceability of the R8 claim

The prior approval's R8 covers the CI publish step and inspect/expected-ETag recovery, not cold MI authentication latency. Record this repair as a new operational finding. Do not record it as resolving R8.

## Non-blocking observations

- **No new automated test** (still 109 tests). The managed-identity branch is covered only by the PROD read-only run, and the Azurite branch by the loopback smoke. This is acceptable because the branch depends on the environment and fails closed.
- **Token cache reuse depends on the Azure.Identity version**, and the csproj is not in this packet. If the credential does not cache, the second token fetch falls inside the 6-second read. At worst that gives a fail-closed read error with no mutation. The PROD `/tmp` success mitigates this in practice.
- **Error code wording:** an authentication failure reports `operator_unavailable_or_unconfirmed`. This is conservative: the resulting `inspect` is harmless.
- **Contract wording:** "prints/stores no token" (line 84) means *persists*. The token does sit in an in-process memory cache. Wording only.
- **Test row in PROD:** the zero-score test row written by the old-code probe is publicly visible until it is removed. `remove` requires schema 2 with maintenance off, so remove it right after conversion and record it along with the step-7 test row.

## Limitations

- I reviewed the supplied text only and ran nothing. The 109/0/0 result, loopback smoke, publish, and all DEV/PROD observations are the lead's reported evidence.
- I could not see the csproj or Azure.Identity version, Program/DI wiring, `ModerationMigration`, or the pipelines. So I cannot confirm there are no other `CreateOperatorClientAsync` callers or verify that the public path is unchanged beyond these files.
- Lead model and effort are not recorded. My own statement of model identity is not verification under AGENTS.md.