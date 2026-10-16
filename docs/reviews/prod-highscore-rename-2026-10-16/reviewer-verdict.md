# Independent Review: PROD Highscore Rank 4 Rename

**Reviewer role:** independent final reviewer. I inspected the supplied packet text only. I executed nothing and inspected no raw blob payload.

## Context sufficiency

The packet is sufficient for a verdict. Some items are inputs I cannot independently confirm (see Limitations), but none would change the verdict:

- the SSH screenshot;
- that the shown `Program.cs` text hashes to `D607…547A`;
- that the DLL was built from it;
- the deployed read path and the `HighscoreValidation.NormalizeName` rules.

## Material findings

**None.** I found no material defect in correctness, concurrency, data preservation or security for this operation.

## Assessment

### Scope
- **Target:** the target is pinned four ways before any write: `entries[3]`, the exact `submissionId`, the exact prior `displayName` and `score==4000` (editor:9–11).
- **Fields changed:** only `displayName` changes. Score and sequence are untouched, so the ordering rule in `HighscoreDocument.Validate` (contract:34) and position 4 cannot change.
- **Moderation report:** the report keeps its original `displayName` snapshot. That matches the "all other blob content preserved" criterion. Rewriting a moderation record would have changed audit evidence beyond scope.
- **Excluded work:** no application source, configuration, RBAC, restart or deployment changes were made. The endpoint discussion was correctly left out.

### Data preservation
- **Text edit (editor:13–18):** this is a byte-preserving substitution, not a reserialization, so formatting, property order, escaping and all other bytes stay identical. The edit is applied only within the single innermost object containing that `submissionId`.
- **Regex safety:** `StoredEntry` (contract:104–114) has only scalar members, so the `[^{}]*` regex is sufficient. Any ambiguity aborts rather than mis-edits:
  - braces inside strings;
  - escaped `@`;
  - a second `submissionId` occurrence;
  - a duplicate name literal.
- **Semantic check (editor:19–20):** `JsonNode.DeepEquals` against a clone with only `entries[3].displayName` changed independently proves:
  - the textual edit landed on index 3 (tying the regex match to the rank-4 check);
  - nothing else changed semantically.
- **Size:** the document shrank, so `MaximumBytes` cannot be exceeded.
- **Blob properties:** `Put Blob` replaces properties. The header inventory showed no metadata, tags or special content/cache properties, and the script aborts if any exist (script:12). Lease enforcement would have produced 412, not 201.

### Concurrency
- **Conditional write:** the single PUT is conditioned with `If-Match` on the ETag from the same GET that produced `before.json` (script:11, 13, 18). This is storage-enforced optimistic concurrency, so a concurrent app write yields 412 and no overwrite.
- **No retries:** there is no unconditional fallback.
- **Lost acknowledgement:** a transport failure is reported as `WRITE_UNCONFIRMED_NO_RETRY`, consistent with Constitution III.
- **Readback:** the readback is conditioned on the saved ETag and is followed by an exact `cmp` (script:25–26). This proves the committed version is byte-identical to the candidate.
- **Later app writes:** they will carry the new ETag after rereading, per the existing conditional-write design, so the rename is not exposed to lost update.

### Security
- **Token:** the token is passed to curl via `--config -` on stdin and is never placed in argv or printed. It is unset on exit, `umask 077` is set, and `set -x` is absent.
- **Environment guard:** the PROD site name is asserted (script:3).
- **Identity:** the existing managed identity was used, consistent with Constitution IV.
- **Output:** the observed output contains hashes and ETags only, with no credentials.

### Acceptance
Each criterion is met:

| Criterion | Evidence |
|---|---|
| Exact entry ID | `8070dc7a-…` |
| Name | `ErikB` |
| Rank and score unchanged | rank 4, score 4000 |
| Entry count | 35 |
| Content preserved | DeepEquals plus byte-exact readback |
| Conditional write | one attempt, 201 |
| Hashes consistent | candidate = verified = `aad7cadf…` |

The public GET reports `revision` = saved ETag `0x8DF2B7BF4A6EF9E`. This shows the deployed service served the new blob and its read path accepted the document.

## Non-blocking notes (no fix required)

- **N-1 Review record must not contain personal data.** The prior name is an email address. The forthcoming review record should not contain it or any private payload content (Constitution IV data minimization). Reference it as "email-valued prior name" and use hashes.
- **N-2 Remote temp copies are pending deletion.** They contain private installation and report data in the PROD container's `/tmp`. Record their deletion as performed, or as not performed, factually. This is a follow-up cleanup, not an acceptance criterion.
- **N-3 Storage logs attribute the write to the app's identity.** Because human data-plane access was denied and the app MI was used, storage logs attribute this write to the app. Note this in the record for audit traceability. The owner authorized the PROD change, and no permissions were added.
- **N-4 Rollback depends on blob versioning or soft delete.** No pre-change backup was retained. That is reasonable for data minimization, and a reverse rename of the single known field is trivial. Whether blob versioning or soft delete exists is unstated.

## Limitations

- I did not inspect the screenshot, the raw before/after payloads or the deployed artifact. Their contents are accepted by the supplied SHA-256 and the lead-observed output.
- I could not verify the source-to-hash and source-to-DLL correspondence.
- `NormalizeName` and submission-time name rules were not supplied. The served public state is the evidence of validity.
- No tests were run, per AGENTS.md; this is not treated as a blocker.
- This review covers the operation, not release readiness or the future endpoint.

## Verdict

**APPROVE.** There are no material findings. The notes N-1 to N-4 are non-blocking.
