# Focused re-review: F1 disposition and final consensus

**Verdict: APPROVE.** I agree with the lead that F1 is resolved and F2 is deferred as optional. There are no open material findings and no disagreements.

## Prior findings

### F1: Evidence overstated what the UI test verifies. **Resolved.**

The lead's supplied evidence supports the claim, provided the final report keeps three things separate:

- **XCTest asserted:** `highscoreSelectedRow` exists, and its label contains `UI Score Check` and `2600` (`HighscoreRealSubmissionUITests.swift:18-21`). That label is built from the POST response.
- **Screenshot:** rank 1 was seen in the attached `real-backend-2600-submitted` screenshot, by visual inspection only.
- **Separate lead-run readback:** a loopback `GET http://127.0.0.1:5281/api/v1/highscores` returned 200, with entry `c84f2d38-…` at score 2600, rank 1.
  - That GET goes through `ReadAsync` → `ReadDocument`, which reads the stored Blob. So it confirms persisted state, unlike the POST response, which is built from the uploaded candidate without re-reading.
  - The sanitized output omits the player name, which is consistent with constitution IV.

Two points the report must record accurately (report accuracy only, not blocking):

1. **Which run the readback shows.** State that the preserved output comes from the *repeated* readback. The first GET, run immediately after the test, was not preserved verbatim; describe it as the lead's attributed observation. Also state that `c84f2d38-4d35-46aa-b96b-070944a25f6e` is the `DT3D_SCORE_TEST_RUN` value used for the UI test. Without that, the readback is not visibly tied to the test's submission.
2. **The `independentReadback: true` field.** The script printed this field itself, so it is not evidence. The evidence is the command, the owned origin and container, and the returned score and rank.

The report must also keep these limitations:

- The readback checks only the owned local ASP.NET backend with Azurite (container `dt3d-owned-141d19ee…`), not PROD.
- The test ran on the iPhone 13 simulator (iOS 27), not a physical device.
- The fix is not yet deployed.
- The cause of the user's historical PROD POST failure remains unproven.

### F2: No diagnostics trace when the retry recovers. **Deferred, optional.**

I agree this is non-blocking.

## New content: 001 plan line

The lead quoted one updated line from the 001 plan. It is accurate against `BlobHighscoreStore.cs`:

- **Timed-out read:** it is retried only on `OperationCanceledException` while the linked operation token is still active (lines 27-33).
- **Shared deadline:** the backoff and the second read use the same token.
- **CAS conflicts:** only `412 ConditionNotMet` loops, bounded by `MaxWriteAttempts ≤ 5` (lines 99-114).
- **SDK retries:** still `MaxRetries = 0`.
- **Requirements:** nothing weakens the timeout or no-replay rules, and the plan line matches `moderation-api.md:46-49`.

One non-blocking clarity note: the retry is allowed **once per read call**, which means once per CAS attempt. That allows up to 10 GETs in one operation, all bounded by the 6-second token. Both documents' wording ("a Blob read/GET may retry once") reads correctly as per-read, so no change is required.

**Revision identity (record-keeping, required before completion):** this plan file is a changed in-scope artifact, but it is not in the supplied manifest. Under AGENTS.md "Review inputs and revision identity", the lead must add its path and SHA-256 hash to the final manifest. The record should also note that I reviewed only the quoted changed line, not the whole file. Historical review evidence stays unmodified, as stated.

## Unchanged source

Per the lead, no runtime or test source changed since the prior round, and the five manifest hashes stand. My prior correctness and safety assessment therefore still applies without re-review:

- read-only retry scope;
- shared deadline;
- no upload replay;
- ETag loop unchanged;
- corrupt or missing storage still fails closed;
- the DEBUG-only loopback score argument.

## Consensus

I explicitly **APPROVE** the reviewed candidate. Consensus is complete once the lead does three things:

1. Words the final report with the F1 attribution above.
2. Adds the 001 plan file to the manifest.
3. Records its explicit agreement.

No further review round is needed.

**Reviewer limitations:**
- I read the supplied text only, with no tool access.
- I could not verify the lead's runtime commands, screenshot or first readback. I rely on the lead's attributed statements for them.
- I have not seen the full 001 plan file.