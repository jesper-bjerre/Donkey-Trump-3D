# Independent Implementation Review: Manual Highscore Name Administration

**Reviewer:** Claude Code, `claude-opus-5-5`, high effort, as requested. I did not take part in the implementation. I used no tools, ran no checks and launched no sub-reviewers. Every statement below comes from reading the supplied packet. My statement of my own model identity is not verification; the lead's recorded probe metadata governs that.

**Verdict: APPROVE.** I found no material defects and no unmet in-scope requirements. One condition applies: the lead should confirm that the replacement characters in the packet are a transport artifact (C-01 below). Nothing listed needs changing before completion.

## Missing or uncertain context

None of the following prevents a conclusion.

- **Character encoding.** The packet contains `U+FFFD` replacement characters:
  - `HighscoreAdministrationTests.cs:15` and `:22`
  - the quoted user text ("l�sning")
  - `docs/highscore-administration.md:4`, where the arrows are missing between "Development Tools  SSH  Go"
  
  Because the user's own quote is damaged the same way, this is most likely transport damage. I cannot check the file bytes against the manifest SHA. See C-01.
- **Live HTTP build.** The packet does not say which source revision the live HTTP assembly `d2c2eb54…` was built from. It only shows that its package and runtime versions match. See L-03.

## Traced and confirmed behavior

**Concurrency and data integrity**
- `HighscoreAdministration.cs:65-66,74` always sends `expectedETag` to `MutateAsync`.
- `BlobHighscoreStore.cs:101` checks the expected ETag on every attempt.
- When an upload is rejected with 412 (`:112-113`), the store re-reads, sees a different tag and returns 409 `revision_changed`. It never recomputes the rename against someone else's change and never writes unconditionally.
- A lost acknowledgement while `uncertain=true` maps to `operation_unconfirmed` (`:117`).
- Maintenance (`:93`) and non-schema-2 documents (`:102`; also `HighscoreAdministration.cs:40`) block the write.
- The only side effect beyond the rename is the existing pre-mutation purge (`:103`), which is documented.

**Rename scope**
- Only `DisplayName` of the entry with the given `SubmissionId` changes, via `with`.
- Sequence, score, origin, hash, level, timestamps, `NextSequence`, reports, tombstones, blocks and audit are carried through unchanged.
- The result is re-validated (`:45`), and `Serialize()` enforces the hard size cap.

**Name rules**
- Names go through the existing `NormalizeName` and `NameModerationPolicy` checks.
- They are validated before target or credential setup (`ModerationCommand.cs:42`) and again inside the transition.

**Rejected inputs**
- A virtual or unstored starter is found by rank through `Fill`, then rejected by `Find` against the stored document (`:57-58`).
- Removed IDs are not in `Entries`, so they return 404. This means a rename cannot create or resurrect an entry.
- A matching name returns before any mutation (`:71`).

**Argument checks and target derivation**
- Each command accepts only its own allow-list of arguments. `entry` requires exactly one selector.
- The wrapper appends `--target`. A target supplied by the user collides in `Parse`'s `TryAdd` (`ModerationCommand.cs:17`) and is rejected. A missing value swallows `--target` and is also rejected by the `--` check.
- `ValidateTarget` independently checks the site, storage account, container, blob and managed identity against the embedded inventory.

**No public surface**
- `Program.cs` is unchanged.
- `HighscoreAdministration` is reachable only from `ModerationCommand.cs:53`.
- No HTTP route, iOS call or hosted-service invocation exists.

**Wrapper and installer**
- The wrapper sets the working directory to `/home/site/wwwroot`, so the live configuration is loaded from the content root.
- The installer:
  - refuses to overwrite an existing revision (`mkdir`, `set -e`);
  - re-verifies the DLL hash after copying;
  - switches the symlink atomically (`mv -Tf`);
  - uses `umask 077`;
  - never writes to `wwwroot`.
- The unchanged HTTP assembly SHA before and after installation supports this.

**Tests (compiled, never run)**
I read all five tests. Their logic is consistent with the implementation. For example, the lowest-score starter ends up at rank 10 after `Fill`, and the fake store records the pinned `revision-1`. This holds subject to C-01.

## Findings

**No material findings.**

### Conditional item C-01

| Field | Detail |
|---|---|
| Severity if confirmed | Medium |
| Location | `src/backend.tests/HighscoreAdministrationTests.cs:15,22` |
| Requirement | Accurate regression evidence (Constitution V) |

- **The issue:** if the file really contains `U+FFFD`, both assertions are wrong. NFC of `"Rene\u0301"` is `"René"` (U+00E9), and renaming to a `U+FFFD` name would not return the same instance.
- **Likely status:** probably a packet artifact, given the identical damage elsewhere.
- **What I ask:** the lead should confirm the bytes are `U+00E9`. If they are, close C-01 with no action. If not, fix it and send a focused re-review.
- The same byte check applies to the arrows on `docs/highscore-administration.md:4`, but that issue is cosmetic only.

## Non-blocking observations

These are not required for completion.

- **N-01:** The installer hash-verifies the DLL but not the staged `highscore-admin.sh`. Using the staging directory already requires authenticated SSH access, so this is optional hardening.
- **N-02:** `Parse` now accepts `--rank` and `--display-name` for the older commands, which ignore them. Those commands already ignored irrelevant keys before this change, so this is not a new kind of behavior.
- **N-03:** An oversized name would surface as `storage_invalid` rather than a capacity code. The name bounds are the same as for public submissions, so this cannot cause corruption.

## Limitations: do they block completion?

| Limitation | Blocks completion? | Reason |
|---|---|---|
| **L-01:** The five new tests were compiled but never run, and no other tests were run. | No | `AGENTS.md:9-21` forbids running tests without an explicit request and says unrun tests are not a blocker. The tests have not been shown to pass. |
| **L-02:** The live apply path has not been exercised and there is no runtime race verification. | No | The task asked for no further live data change. The write path reuses the existing `MutateAsync`/`If-Match` code shared with the other operator commands. The live write behavior of rename itself remains unverified. |
| **L-03:** The live read shows the tool's model can read the current PROD aggregate. It does not prove the reverse: that the live HTTP reader accepts everything the tool serializes, given strict deserialization that rejects unknown members. | No | The candidate changes no model files. |

For L-03, I recommend recording before the first live `--apply` that the deployed HTTP assembly was built from a revision with the same document model as base `368d700`.

## Other limitations of this review

- I relied on the lead's representation that installing the private tool on PROD was authorized. I cannot verify that authorization.
- I did not see the screenshot of the console output.
- My review is limited to the supplied source and context.
