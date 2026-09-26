# Independent focused re-review: backend DEV/PROD deployment

**Role:** independent reviewer (Anthropic, `claude-opus-5-5`). I stayed read-only, used only the supplied packet, and launched no other reviewer.
**Reviewed:** the 14-file final candidate manifest, the tracked diff since `db52f2b`, full contents of `infra/configure-backend-budget.py`, `infra/test_backend_budget.py` and `evidence.json`, both final docs, and the lead's responses.

## Verdict: APPROVED

BD-01 and BD-02 are resolved, and CTX-1, CTX-2 and CTX-3 are satisfied. I found no new material in-scope problems. The approval covers only the backend DEV/PROD deployment, its pipelines and the operator budget helper. It does not cover iPhone or App Store readiness.

## Dispositions

### BD-01: Resolved

**What the evidence now shows:**
- **Pre-change hour** (`evidence.json:965-982`): 60 samples, CPU 10–41% (mean 18.92), memory 70–75%.
- **Raw settled series** (`evidence.json:614-819`, 15:36–15:55): CPU 16–39%. I computed the mean as about 23.4%. Memory was 81–83%.
- **Final window summary** (`evidence.json:983-1000`, 15:39:28–15:59:28): 20 samples, CPU 16–54% (mean 26.1), memory 77–83%.

**Consistency check.** The final window's minute samples run from 15:40 to 15:59. The raw series covers 15:40–15:55, which is 16 samples summing to 374. A 20-sample mean of 26.1 requires a total of 522. That leaves 148 for 15:56–15:59, about 37% on average, which includes the 54% maximum. Those minutes overlap the twelve health probes at 15:56. The summary and the raw series are arithmetically compatible, and the doc (`docs/backend-deployment.md:149-154`) quotes the newer summary accurately.

**Why this resolves the finding:**
- My concern was a sustained idle state of 70–99% CPU. Idle CPU is now about 5–7 points above baseline. That is proportionate to one more idle .NET app with Always On and Health Check pings.
- The existing `byensgaader-api-p` returned 200 three times at 0.13–0.20 s, and all four apps were healthy (`evidence.json:891-964`).
- The pre-package spike overlaps the recorded site starts at 15:20:58 and 15:22:51 (`evidence.json:1002-1009`). That is a plausible attribution, and the evidence states it honestly as unproven per process.
- No SKU change or existing-app change occurred (`evidence.json:432-453`).

**Residual:** memory headroom is lower. See NB-4, which does not block approval.

### BD-02: Resolved

**Detection is now in place and within scope.** A subscription-level Consumption budget with a `Project=DonkeyTrump` tag filter costs nothing and changes no plan or SKU (`evidence.json:821-865`).

**Amount and thresholds.**
- DKK 80 net corresponds to DKK 100 including 25% VAT. That is appropriate, because Cost Management costs are pre-tax.
- For the abuse scenario in my earlier round (about DKK 11/day net), the 50% actual warning fires after about 4 days. Even with the usual ingestion delay of up to a day, the owner has several days before reaching 100%. The 90% forecast warning may fire earlier. This is adequate detection.

**Helper correctness** (`infra/configure-backend-budget.py`):
- **Fails closed:**
  - on a non-DKK currency (`:21-22`);
  - on a recipient who is not already on the existing budget (`:23-26`);
  - on a non-user session (`:47-48`);
  - on missing project tags for any app or storage account (`:49-52`);
  - on a missing reference budget (HTTP 404 becomes `RuntimeError`, `:65-68`);
  - on a conflicting amount, filter, category or grain (`:73-74`).
- **Safe updates:** it uses an ETag-guarded update (`:75`), preserves the existing period (`:76`), and does a field-by-field readback (`:78-81`). Python treats `80 == 80.0` and `50 == 50.0` as equal, so a float readback does not cause false mismatches. This agrees with the recorded successful idempotent rerun.
- **No secret exposure:**
  - The token appears only in the header.
  - `HTTPError` is re-raised `from None` with only the status code.
  - `CalledProcessError` shows the argv, which contains no token or email.
  - The printed output excludes the address (`:82-87`).
  - This satisfies Constitution IV.

**Tests** (`infra/test_backend_budget.py`) cover VAT, scope, owner-only recipients, thresholds, start date, wrong currency and a new-recipient refusal. The docs (`backend-deployment.md:171-190`, `production-smoke-and-rollback.md:147-150`) correctly state:
- that warnings are delayed and not a cap;
- what the owner should do on a warning;
- the tagging obligation for future resources;
- the expiry date;
- that shared plan charges are excluded.

The earlier removal of the runbook prerequisite is reversed with stronger wording.

### CTX-1: Satisfied

- The recorded `git diff --exit-code db52f2b -- .github/workflows src/scripts/backend-release*.py infra/backend-environments.json infra/provision-backend.py src/backend` returned exit 0 (`evidence.json:886-890`).
- The tracked diff shows changes only in the two docs.
- The three new or untracked files are listed with hashes and supplied in full.
- The deployed runtime and the executed pipeline and provisioning code are therefore the content I reviewed in round 1.

### CTX-2: Satisfied

The reference names (`evidence.json:866-885`) map onto the new names as follows:

| Resource | Reference | New |
|---|---|---|
| Apps | `byensgaader-api-d/p` | `donkeytrump-api-d/p` |
| Storage accounts | `byensgaaderd/p` | `donkeytrumpd/p` |
| Storage resource groups | `byensgaader-d_rg` / `byensgaader-p_rg` | `donkeytrump-d_rg` / `donkeytrump-p_rg` |

App, storage and group naming match exactly. The reference identities (`oidc-msi-<hex>`) are autogenerated, so they carry no environment convention to copy. Keeping the `oidc-` prefix and adding `-d/-p` is a reasonable, documented choice and does not break parity.

### CTX-3: Satisfied

- The linked record already exists in `db52f2b`.
- Committing the evidence, helper, tests and final record after consensus follows the uncommitted-candidate review in AGENTS.md:192-206.
- Excluding the record itself from the payload identity is permitted.
- The evidence and runtime changes are covered by the manifest hashes.

## New findings

**No new material findings.** The following are non-blocking and need no action for approval:

- **NB-4: PROD B1 memory headroom is reduced.** Settled memory averages about 81%, against a baseline mean of 72.77%. The pre-existing 24-hour peak of 92% (`evidence.json:16`), plus about 8 points, could approach saturation at the existing app's daily peak. The docs disclose the increase and already require CPU, memory and existing-app health checks (`backend-deployment.md:145-154`). This is an operational watch item, not an evidence gap.
- **NB-5: Some helper paths are verified only by inspection and the live run.** The conflict-refusal, ETag and readback-mismatch paths in `main()` have no unit tests. The update path was exercised by the live idempotent rerun, and the refusal logic is simple.
  - A rerun also resets `notifications` to owner-only. That matches the intended configuration, but it would discard a recipient added manually later.
- **NB-6: Possible leftover budget from the earlier storage-group scope.** The lead describes the budget as expanded from its initial storage-resource-group scope. The candidate helper refuses scope changes, so an earlier revision or a manual step made that change. If the initial budget was created at resource-group scope rather than as a subscription budget with a filter, an orphaned duplicate could remain. It would be harmless (same owner, no cost), but it is worth checking once.

## Limitations

- I could not independently confirm:
  - the manifest hashes;
  - Azure state, including the budget readback, resource tags and metric values;
  - GitHub runs;
  - the reference repository;
  - the absence of an orphaned earlier budget.

  I relied on the supplied sanitized evidence and the lead's recorded commands.
- I could not verify that App Service egress meters are attributed to the tagged site rather than the untagged shared plan. The doc's hedged phrase "attributed ... bandwidth charges" is acceptable, but coverage of that meter is unconfirmed. Storage transactions, the dominant cost in my earlier estimate, are attributed to the tagged storage accounts.
- Alert email delivery was not tested. It is correctly recorded as not tested.
- I could not see the workflow path filters in this packet. If the follow-up evidence commit triggers Backend CI or DEV deployment, DEV would run a newer SHA with byte-identical runtime. Record that run if it occurs. PROD stays at `db52f2b`.
- The new budget tests are not part of Backend CI. That is acceptable for an operator-only helper.
- The earlier limitations still apply: no sustained-load validation, no PROD writes, and no live rollback exercise.

## Deployment vs App Store readiness

This approval does not cover:
- physical iPhone 13 acceptance;
- the Release `HIGHSCORE_API_BASE_URL` configuration and its ATS checks;
- signing and distribution;
- App Store moderation.
