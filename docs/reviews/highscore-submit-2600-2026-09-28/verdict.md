# Independent review: transient Blob read retry and 2600 UI submission test

**Verdict: APPROVE** for the reviewed source (manifest as supplied). No source change is required. F1 is a correction to the evidence report and must be made before the lead declares completion.

## Findings

### F1: Evidence overstates what the UI test verifies (Medium, report accuracy only)

- **Location:** `src/DonkeyTrump3DUITests/HighscoreRealSubmissionUITests.swift:18-21`, and the packet claim "passes rank1 and persisted2600readback".
- **What the test asserts:** only that `highscoreSelectedRow` exists and its label contains `2600` and `UI Score Check`.
  - It does not assert rank 1.
  - It does not read the data back independently. The selected row is built from the POST response.
  - The backend builds that response from the uploaded candidate without re-reading it (`BlobHighscoreStore.cs:111`; asserted by `ConditionalWriteUsesSameReadEtagAndReturnsSavedCandidateWithoutReread`, `Reads == 1`).
- **What the evidence actually shows:** the backend acknowledged a ranked conditional write, and a person saw rank 1 in the screenshot. Neither is an automated check of rank or of persisted state.
- **Governing rules:** AGENTS.md:21 ("never claim … unverified runtime behavior was verified") and constitution V ("identify what was actually checked").
- **Required disposition:** do one of the following.
  - Attach the separate readback evidence (for example, the loopback `GET /api/v1/highscores` command and its output showing the entry with 2600), if it was actually run.
  - Or restate the evidence as: "UI test asserted the name and 2600 in the selected row from the POST response; rank 1 was observed visually in the screenshot; no independent readback."

No code change is required. Adding rank and readback assertions to the test would be optional.

### F2: The retry leaves no trace in diagnostics (Low, non-blocking, optional)

- **Location:** `BlobHighscoreStore.cs:28-33`.
- A recovered timeout is not recorded, so after deployment you cannot tell whether the cold-read timeout still happens in PROD or how often the retry saves a request.
- An optional content-free counter (for example `diagnostics?.Failure("read_retry")`, or a dedicated metric) would help. It does not affect correctness.

## Correctness and safety assessment

### Retry scope

- `ReadDocument` retries only on `OperationCanceledException` while the linked operation token is still active.
- Azure.Core's `ResponseBodyPolicy` signals a per-try network timeout with a `TaskCanceledException` that is not tied to the caller's token. The filter therefore matches:
  - the per-try network timeout, including timeouts while reading the streamed body through `BoundedRead`.
- It does not match:
  - the 6-second deadline expiring;
  - the client aborting the request (both linked into `token`).
- Exactly one retry is possible. The second `ReadDocumentOnce` call sits outside the try block, so a second timeout propagates.

### Deadline

- The backoff and the second read both use the same `token`. Nothing creates a new deadline.
- If the backoff is cancelled, the resulting `OperationCanceledException` maps to `operation_timed_out`.
- `IsValid` still enforces network timeout ≤ 2 seconds and operation timeout ≤ 6 seconds.
- Worst case with a cold token is roughly 1.9 s + 2 s + 0.1 s plus a warm read, which stays inside 6 s. The iOS 8-second deadline still exceeds the server's.

### No write replay

- `UploadAsync` is untouched.
- `uncertain` is set only after the read, and the read call site at line 100 precedes the `uncertain=true` assignment at line 106. A read timeout therefore can never be reported as `submission_unconfirmed`, and a timeout during upload still maps to unconfirmed with no retry.
- The existing `TotalDeadlineBoundsReadsAndWrites(duringWrite:true)` test (`Writes == 1`) and `CommitThenLostAcknowledgement…` both remain in the passing 24.
- There is no client-side POST retry and no deferred upload.

### ETag loop

- A retried read returns a fresh document and ETag pair, which feeds the unchanged `IfMatch` conditional write.
- Retries stay finite: at most 2 reads per attempt, at most 5 attempts, all under the 6-second token.
- The contract's "≤5 conditional attempts" applies to uploads and is unchanged.

### Corrupt or missing storage

- `InvalidStorage`, 404 `BlobNotFound` and other `RequestFailedException`s are not `OperationCanceledException`, so they are never retried and still fail closed.

### iOS fixture argument

- `-highscoreRunScore` is honoured only when the mode is `.integration`.
- `parse` restricts that mode to plain-http loopback with no userinfo, query or path.
- The code is inside `#if DEBUG`, and the score is validated with `HighscoreRules.validScore`.
- No path exists for synthetic scores to reach the PROD origin from the app.

### Contract update

- `moderation-api.md:46-49` accurately describes the new retry condition, the shared deadline and that uploads are never replayed. This meets constitution III ("define retry conditions and finite retry limits").

### Tests

The four new cases cover:
- recovery on both read and publish, with exactly 2 reads and the correct write count;
- a repeated timeout stopping after 2 reads with 0 writes and returning `operation_timed_out`;
- no second read once the operation deadline has expired.

The reported "3 fail, 1 pass before the fix" pattern is consistent: the expired-deadline case is a regression guard and would pass before the fix. It is a weak guard against someone removing the `when` filter, because with `NoBackoff` a cancelled second `DownloadStreamingAsync` may or may not reach the handler. This is not material.

## Limitations and residual risk (not findings)

- **Other artifacts not supplied:** I could not check the 001 contracts, data model, runbook or architecture docs for statements such as "reads are not retried" or "SDK retries off" without the new qualification. The lead should search for them. If any exist, they need the same qualification. I raise no finding without that evidence.
- **Local backend storage configuration not supplied:** I relied on the lead's statement that the UI test ran against an owned local backend. The test does not itself check which storage that backend used.
- **Scope of what is proven:**
  - Only the transient cold-read timeout class is addressed. Other 503 causes (`service_unavailable`, `contention_exhausted`, rate limiting) are unaffected.
  - The cause of the historical POST failure remains unproven, as the lead states.
  - The iOS test proves the 2600 submit path end to end locally. It does not reproduce the PROD timeout.
- **Not yet in PROD:** the fix is undeployed, so the user's PROD symptom is unchanged until deployment.
- **Simulator only:** the UI evidence comes from an iPhone 13 simulator on iOS 27, not a physical device (constitution V).
- **The user's original score:** by design, it will not be resubmitted automatically. It is absent from the observed PROD GET and was not replayed.