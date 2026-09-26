# iOS implementation review: Anthropic reviewer verdict

**Reviewer:** claude-opus-5-5 at high effort. I did not take part in the implementation and made no edits.
**Scope:** iOS manifest, candidate digest `316a7f40…54f8`, Git base `e323551c`, with a captured pre-edit base for untracked files.
**Method:** I inspected the source independently. Recorded checks are treated as executed evidence attributed to the lead, not as runs I performed.

## Material finding

### HS-IOS-01 (Medium, blocking): a failed list read can say the score may have been saved

**Location:** `HighscoreCoordinator.swift:126-129`, in the `begin(submission:success:)` catch path.

**Defect.** For a `HighscoreServiceError.rejected(problem)`, the code sets:

```swift
unconfirmed = problem.code == "submission_unconfirmed" || ![…known codes…].contains(problem.code)
```

This does not check `submission != nil`. On the read path, `URLSessionHighscoreService` passes `.rejected` through for any `application/problem+json` response whose status matches its body. So a GET returning the contract's `500 internal_error`, or any unknown problem code, calls `fail(unconfirmed: true)`. The player then sees `Copy.highscoreUnconfirmed`: "We couldn't confirm whether your score was saved."

**Impact.** This happens in two places:
- **Title browsing.** A read failure shows copy about a score save that is meaningless there.
- **Qualification check after Game Over.** No name was entered, no consent was given and no POST was sent, yet the player is told their score may have been published.

This contradicts:
- `ios-flow.md:33`: the unconfirmed wording applies only "if a save was attempted"; a failure known before any save uses the "unavailable" copy.
- US5-1 and FR-017: a failed qualification check shows an error and makes no claim about the outcome.
- FR-008 and Constitution IV: publication requires explicit consent. Implying a possible publication without consent misstates the data flow.

**Why tests missed it.** The existing tests take this path only for POSTs (`HighscoreFailureTests` codes `internal_error` and `submission_unconfirmed`). The read-failure tests use `.unavailable`, not `.rejected`.

**Fix.**
- Change the assignment to `unconfirmed = submission != nil && (problem.code == "submission_unconfirmed" || !known.contains(problem.code))`.
- Add Swift tests for a read rejected with `internal_error` and with an unknown code, from both a `.title` source and a `.completedRun` source. Assert `Copy.highscoreUnavailable`, no name prompt and no POST.
- Rerun the Failure, Browsing, Nonqualification and Publication suites.
- Send a focused re-review.

## Scope areas checked with no material issue found

**Run identity and capture** (`Simulation.swift`)
- A run ID is created on start, restart or first play, and cleared on return to title.
- `CompletedRun` is created only when the final life is lost, using the final score rather than the personal best.
- Rescues, pause-menu restarts and abandoned runs do not complete a run.
- The fixture hook and synthetic Game Over command are compiled only in DEBUG.
- Autopilot, autostart, icon-shot and intro-at launches null `completedRun` and use `UnavailableHighscoreService`.

**Ownership and threading**
- `GameModel` and `HighscoreCoordinator` run on the main actor, and the HUD sink hops to main.
- Network I/O and body streaming happen in a nonisolated async service, off the main thread.
- The engine command queue sits behind its existing lock.
- The render loop is never gated on network work.

**Stale and late responses**
- Each request captures its generation and source. `stopOperation` increments the generation on every begin, success, failure and invalidate.
- `GameModel.send` invalidates synchronously on start, restart and return to title.
- `receive` invalidates when the run ID changes or the phase leaves Game Over, which also covers controller-initiated restarts.
- Scene backgrounding invalidates.
- `complete` is guarded by `outcomes[run.id]`, so retired runs, including cancelled ones, can never prompt or POST again.

**Deadline**
- An independent 7.8 s coordinator timer runs alongside the URLSession 8 s request and resource limits.
- The UI does not await an uncooperative task, and the manual-clock tests show this.
- The streamed-body deadline evidence (7.93 s) is consistent with this design.

**No deferred upload**
- Nothing is persisted as pending work, and there is no retry-publication action.
- `Retry-After` is ignored.
- Refresh is read-only and cannot reopen a retired opportunity.

**Acknowledgement handling**
- Transport errors, malformed responses and refused redirects on POST map to "unconfirmed".
- A ranked response must name this exact run and row, with matching score and name.
- A contradictory `notQualified` response is treated as unconfirmed.
- Snapshot invariants are validated.
- Redirects are refused and the response origin is checked.

**Configuration**
- Release has default ATS, an empty base URL (so highscores are unavailable) and no fixture or integration code.
- The Debug local-origin allowlist fails closed, and the tests cover it.

**UI**
- Consent notice, explicit Submit, disabled repeat submit and Cancel with no POST.
- Rows are highlighted and scrolled by entry ID; no-longer-listed entries show the bottom instead; the stale label appears when appropriate.
- An empty list is shown only for a confirmed empty response.
- Game Over navigation stays outside the scrolling content.
- Names are shown with verbatim text and exposed through accessibility labels.
- Accessibility focus moves to the selected row once.
- The privacy copy is updated.

**Evidence** is consistent with the source. Simulator results are not presented as physical-device results.

## Non-blocking observations

**N1: residual risk of one row blocking the whole list.**
- `HighscoreSnapshot.validate` rejects the entire snapshot if any row's name fails Swift re-validation. The data model mandates this.
- If .NET and iOS count grapheme clusters differently (their Unicode versions differ), one anonymous name that the backend accepts but Swift rejects would make the list unreadable for every client until that row is displaced. A saved POST would also be reported as unconfirmed, which is at least the safe direction.
- Consider adding backend-accepted edge cases to the shared fixtures, such as Indic conjuncts and newer emoji ZWJ sequences.

**N2: server name errors clear the typed name.** A server-side name validation error returns to a freshly created form, because the view is rebuilt after `.submitting`, so the player must retype. This is a UX issue only.

**N3: boundary dependency on the backend.** iOS treats POST problems `service_unavailable`, `operation_timed_out` and `contention_exhausted` as known not saved, and shows the "unavailable" copy. That is correct only if the backend emits `submission_unconfirmed` for every failure after an upload attempt (data-model step 7). The backend review must confirm this.

**N4: retained evidence differs from the script output.** The retained `two-installations.json` uses `dataContainerID`, whereas `verify-two-installations.py` writes a full `dataContainer` path. The post-processing is disclosed in `validation.md`, but it means the retained record is not the script's raw output.

**N5: backgrounding retires the name-entry opportunity.** Backgrounding while entering a name retires that run's chance to publish. This is consistent with `ios-flow.md` and the data model.

## Limitations

- I executed nothing.
- `GameEngine.swift` was supplied only as excerpts, and fixture row contents only as summaries.
- Release gates remain open, as T054 permits: physical iPhone (VoiceOver, touch and keyboard, audio, thermals, start latency on hardware), Docker and live Azure.

## Verdict

**Not approved yet for the iOS scope.** HS-IOS-01 is a confirmed in-scope defect. After the one-line fix, the added read-path tests and rerun suites, I expect to approve in a focused re-review. The re-review packet should include this verdict, the diff and the new test output. No other material issues were found.