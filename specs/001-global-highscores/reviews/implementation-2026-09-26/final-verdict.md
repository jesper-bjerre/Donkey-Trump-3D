# Final focused re-review: HS-IOS-01 disposition and documentation/acceptance review

**Reviewer:** Opus 5.5 (`claude-opus-5-5`, high effort), acting as an independent read-only reviewer. I executed nothing. All test results below are the lead's recorded evidence.
**Candidate:** final global digest `509481d1…b264`. Git base is `e323551c`, plus the captured pre-edit base for untracked files.

## 1. HS-IOS-01: **Fixed.** I agree it is closed.

I checked the fix myself rather than relying on the lead's summary.

- **The fix at `HighscoreCoordinator.swift:128`:**
  - `unconfirmed` is now `submission != nil && (…)`.
  - The other two paths into `fail` already had the same guard: the non-rejected catch (`:129`) and the deadline timer (`:106`).
  - The editable-name branch (`:121-122`) also requires `submission != nil`.
  - So no read failure can reach `Copy.highscoreUnconfirmed`: not a rejection, a transport error, an invalid response or a timeout.
- **POST behaviour is unchanged.** `submission_unconfirmed`, unknown codes and `internal_error` still produce the unconfirmed copy. `TerminalSaveFailuresCannotBeResent` still checks this for exactly `submission_unconfirmed` and `internal_error`, and it passes.
- **Run retirement still holds after a failed qualification read.** `fail` sets `outcomes[run.id] = .failed` (`:144`). A repeated `complete(run)` therefore returns at `:22`. The test's `reads == 1` assertion checks this, as does the no-POST assertion.
- **The regression test (`HighscoreFailureTests.swift:29-47`) matches what I asked for.**
  - It covers `internal_error`, an unknown code and a misleading `submission_unconfirmed` code.
  - It runs each code from both the title and a completed run.
  - It asserts the exact unavailable copy, no POST and no second qualification read.
- **The red/green evidence is consistent.**
  - Red: 12 issues, which is 3 codes × 2 sources × 2 message expectations, all at lines 40–41.
  - Green: all 14 declarations in the four requested suites pass, and the Release rebuild succeeded.
  - The zero-test filter run is correctly excluded from the evidence.
- **The fix did not weaken any requirement.** Only this one line changed in production code.

I also accept the lead's explanation for not rerunning the UI, storage and timing suites. The change only narrows how failed reads are classified. No contract allows a failed read to produce unconfirmed-save copy, so no valid UI assertion could rely on the old behaviour.

## 2. Documentation and acceptance findings

### DOC-01 (Low, material, documentation-only): feature docs still say the feature is not implemented

**Where:**
- `specs/001-global-highscores/spec.md:9` says: `Status: Draft — requirements reviewed; feature not implemented`.
- `spec.md:159` says: "current gameplay remains unchanged until implementation".
- `spec.md` is not in the changed-file manifest, so it was never updated.
- Secondary: `validation.md:43-45` ("Independent review — Pending … No unfinished candidate has been submitted") reads as a current status. It contradicts `validation.md:3` and `:135`, which say the review is recorded separately.

**Impact:**
- The governing specification now states something false about implementation status.
- It contradicts `plan.md`, `tasks.md`, `validation.md`, `README.md`, `prd_spec.md` and `backlog.md`, which all say the feature is implemented.
- Constitution V requires documentation to distinguish planned, implemented, tested and deployed behaviour. T052 omitted `spec.md` from its list of documents to reconcile.

**Fix:**
- Update the `spec.md` status line to say the feature is implemented and locally validated. Point to `validation.md` and state that physical-device, container and live Azure release checks are pending.
- Reword `spec.md:159` so it no longer says gameplay is unchanged "until implementation".
- Either date-stamp `validation.md:43-45` as a historical checkpoint or replace it with a pointer to the review record.
- Change no requirement text.
- Validation needed: a document-consistency and link check only. No build or test rerun is needed.

### Checked with no material issue

**Privacy and consent**
- README, `prd_spec`, architecture and the runbook all describe:
  - optional public names;
  - scores reported by the client, which are not cheat-proof;
  - no deferred upload;
  - a local best that is kept independently.
- The runbook requires logs to exclude names, full payloads, IPs and credentials.
- This matches FR-008, FR-020 and Constitution IV.

**Configuration**
- The docs agree on:
  - an empty `HIGHSCORE_API_BASE_URL` by default;
  - Release keeping default ATS;
  - Debug loopback only;
  - managed identity with container-scoped RBAC;
  - no SAS or account key;
  - no invented hostname, subscription or region.
- The per-replica limiter is described consistently with backend N4.

**Pending release gates**
- The following are consistently marked pending in `validation.md:129-131`, `tasks.md` T054, `plan.md`, `quickstart.md`, `backlog.md` and the runbook:
  - Docker build and run;
  - live Azure managed identity, RBAC, ingress and cold start;
  - physical iPhone 13 VoiceOver, touch and keyboard, thermals and silent switch.
- None of them is relabelled as a pass.
- Simulator and loopback results are identified as such (`validation.md:75,87`).

**Task and evidence traceability**
- The `[X]` marks on T001–T054 are consistent with T054's explicit permission to leave environment gates pending.
- The requirement-to-evidence table covers FR-001–FR-020 and SC-001–SC-006.

**Runbook recovery**
- The rollback guidance forbids score resets and replaying lost-acknowledgement submissions, and it fails closed on corrupt storage.
- This matches Constitution III.

**Non-blocking, no action required:**
- The `validation.md` audit rows for SC-001 and SC-004 would read more clearly with a "(simulator/loopback)" qualifier. The section header already states this.
- The `ios-flow.md:54` fixture list omits `offline-first` and `refresh-fails`, which `quickstart.md` lists.
- `architecture_options.md` has a stray space before a full stop ("dependencies .").

## 3. Final verdict

- **HS-IOS-01:** fixed and verified. The iOS scope now has no unresolved material code finding.
- **Backend scope:** the backend is unchanged, so my earlier approval still applies. Its N1–N4 and the iOS N1, N2, N4 and N5 notes stay non-blocking, and iOS N3 is confirmed.
- **Code acceptance:** I explicitly agree that the final authorized local implementation (backend and iOS source, tests and executed evidence) meets FR-001–FR-020 and SC-001–SC-006 within the stated limits. Those limits are simulator and loopback evidence only, with physical iPhone, Docker and live Azure left as pending release gates.
- **Overall completion:** agreed once DOC-01 is corrected. The fix touches documentation only. A focused re-review limited to that doc diff and the updated manifest is enough, and no code or test rerun is needed.

## Limitations and missing context

These were not in this packet:
- `src/backend/README.md`
- `Copy.swift` (so I could not see the `highscoreUnavailable` text)
- `data-model.md`
- `technical-proposal.md`
- the UI test sources
- the separate review record

I relied on the earlier iOS and backend reviews for those. None of them is needed for the conclusions above.
