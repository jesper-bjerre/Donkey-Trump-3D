# Focused re-review: revision identity correction

## Verdict: **APPROVE**, with no new material findings

The corrected diff matches the MANIFEST candidate I approved earlier. The approval applies to delivery commit `27aa8104de27c998526e5844e3264457ca9f1d7a` on base `b04ffe3ddaca067554bae649f7984c21ff08a718`. It is conditional on the R10 rollout gate, which is a deployment gate, not a code blocker.

I reviewed text only and ran nothing. All git, hash, test and cloud observations are the lead's reported evidence.

## Disposition of prior findings

### R9 (MEDIUM): **Resolved**

The corrected diff matches the delta I reconstructed last round, down to the line numbers:

| File | Hunk | +/− | Matches prior reconstruction |
|---|---|---|---|
| `moderation-api.md` | `-79,6 +79,10` | +4 | Added lines 82–85 |
| `HighscoreOptions.cs` | `-41,6 +41,19` | +13 | Method at 44–55; `GetTokenAsync` at :53, return at :54, Azurite bypass at :48 |
| `CaptureCommand.cs` | `-12,9 +12,10` | +2 / −1 | Pre-acquire at :15, deadline at :16, client use at :18 |
| `ModerationCommand.cs` | `-46,7 +46,7` | +1 / −1 | Replacement at :49 |

- The totals are 20 insertions and 2 deletions, which matches the lead's statement.
- There are no deletions, mode changes or new files.
- The per-file blob SHA256 check against the MANIFEST links the committed content to the reviewed content.
- The explanation for the earlier diff (a stale index in the WIP checkout, with the files present but untracked) is plausible and consistent with what was shown.
- Keeping the bad diff as labeled incorrect evidence is the right handling.

**Two things to put in the record (not blockers):**

1. **What "MODIFIED" means.** I'm reading it as `git diff --name-status b04ffe3 27aa810` showing `M` for all four paths. A clean worktree checked out at the commit would show nothing in `git status`, so the record should name the actual command.
2. **Diff scope.** If the corrected diff was pathspec-limited, also record that `git diff --stat b04ffe3 27aa810` lists only these four files. Otherwise the commit, and therefore the artifact, could carry unreviewed changes.

**Artifact identity:** this is closed by R10, not by source hashes. The record should link three things: the pipeline run's source revision (`27aa810`), the ZIP digest that run produced, and the same digest loaded in DEV and then PROD.

### R10 (MEDIUM): **Agreed plan accepted**

The sequence covers what I required:
- **DEV:** confirm the loaded deployment and ZIP digest, run a cold `inspect` from wwwroot, then run the normal publication, report, operator and receipt smoke.
- **PROD:** deploy the identical ZIP, confirm it is loaded and that maintenance is still on, run a cold `inspect`, then convert, read back, check backup absence, turn maintenance off, and clean up the test-owned POSTs.

Three points on the plan:

- **Capture staying disabled in cloud is acceptable.**
  - The capture change only swaps in the client from the shared factory.
  - The factory's managed-identity branch is exercised by the cloud moderation cold `inspect`.
  - The capture-specific wiring is covered by the local Azurite integration checks and the owned smoke.
  - Record it as you described: not enabled and not live-verified.
- **The /tmp copy:** the record should say it has actually been removed, not just that it will be removed after use.
- **The zero-score test row from the old-code probe** is included in the "test-owned POST cleanup". Record it explicitly.

### R11 (LOW): **Accepted**

Record the cold managed-identity startup defect as its own new finding. R8 stays historical and unchanged.

## Newly supplied context: previous limitations now closed

- **Program.cs:**
  - Operator mode branches off before any service registration, `Build()`, hosted service or `ValidateOnStart`. This confirms "exits without HTTP hosting".
  - The public DI singleton still uses `CreateClient()`, so the public path is unchanged.
  - The operator passes `CancellationToken.None`. The 30-second linked deadline is therefore the only bound on startup authentication, and it is sufficient.
- **Other callers of `CreateOperatorClientAsync`:** the method is new in this delta. Any other caller would therefore have to appear in the diff, subject to the scope point under R9.
- **csproj:**
  - The project uses Azure.Identity 1.21.0 with `TreatWarningsAsErrors`, and `ManagedIdentityId` compiles.
  - In this version line, `ManagedIdentityCredential` should cache tokens in memory for each instance. That makes the second token fetch inside the 6-second read a cache hit.
  - This downgrades my earlier token-reuse observation further. The DEV and PROD cold `inspect` runs will confirm it empirically, and failure still fails closed.

## Remaining limitations

- The 109 passed / 0 skipped test result and the owned local smoke are reported as actual passes. They are unchanged because the code is unchanged.
- The /tmp read-only PROD `inspect` is diagnostic only.
- Full App Store and physical acceptance are not claimed, and are not covered by this approval.
- The lead is recorded as OpenAI Codex, as supplied. Effort level is still not stated.