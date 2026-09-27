# App Store release plan — independent review, 2026-09-27

## Task and scope

User invoked `speckit-plan` for [002 App Store release](spec.md). Deliverable is Phase0
research and Phase1 design: technical/constitution plan, research, data model, interface
contracts and validation quickstart. Runtime implementation, tasks generation, deployment,
store mutations, submission and release are outside this command. Owner submits Apple
review and public release later; planned agent handoff is a complete unsent draft.

Governing instructions: [AGENTS.md](../../AGENTS.md), constitution v1.0.0 and the invoked
plan skill. Prior dirty spec/clarification records were preserved. Plan uses actual Git
branch main with feature pointer002-app-store-release. No commit/push performed.

## Participants and verified configuration

| Role | Tool/vendor | Model and reasoning | Evidence |
|---|---|---|---|
| Lead author | Codex / OpenAI | Exact runtime model ID and reasoning setting not exposed in this session; not inferred from product name | Current session author; research helpers supported Phase0, not independent approval |
| Independent reviewer | Claude Code2.1.283 / Anthropic firstParty | `claude-opus-5-5`; explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high` | [Route probe](reviews/plan-2026-09-27/route.json) and round metadata |

Reviewer did not author these artifacts. Safe-mode tool-less sessions received full
line-numbered candidate/context and actual check evidence from an isolated temporary
directory. No repository autoload, MCP, credential extraction or hidden reasoning in
this record. Harmless text probe succeeded without effort warnings; stream-json probe
returned actual canonical model and nonzero firstParty usage. The provider does not
separately attest effective effort; explicit flags/environment and warning-free probe
are recorded accurately. Focused rounds reused this unchanged verified configuration;
actual model/result checked again each time. No fallback was needed.

## Revision identity and findings

Base commit: `05238815a11e55650f459cd469856afcd5d99094`.
Seven plan artifacts are new untracked files; their task base is empty, not falsely
represented as committed content. Initial full patch and manifest preserve round1;
focused patch records remediation; final manifest/full patch identify final contents.
Governing context hashes are separate. This record/evidence bookkeeping is excluded
from candidate identity; substantive plan/spec/contracts are included.

| Finding | Severity | Confirmed problem and remedy |
|---|---|---|
| F-01 | CRITICAL | Human Azure CLI Blob identity contradicted constitution. Cloud operator now runs inside target App Service via control-plane SSH and uses scoped MI only; maintenance/restart migration keeps SSH alive while quiescing writers. |
| F-02 | HIGH | Historical versions/backups retention was undefined. Read-only DEV/PROD properties inspected; versioning/soft delete stay disabled, private migration backup bounded24h/early deletion, inventory of historical copies and privacy/cost evidence required. |
| F-03 | MEDIUM | Manual-only purge could miss expiry. Logical expiry on reads, purge-before-write and hourly/startup worker enforce cleanup with explicit outage/recovery limits and retention evidence. |
| F-04 | MEDIUM | Full spam queues lacked prompt owner remedy. Explicit bulk spam dismissal removes snapshots, retains bounded minimal24h receipts separately and restores ordinary admission without evicting genuine reports. |
| F-05 | MEDIUM | Capture configuration/data isolation undefined. Simulator-only AppStoreCapture and separate DEV route/container, archive/PROD rejection and fixture/pixel checks; no resetting real player data. |
| F-06 | LOW | Read-only list described as fixture migration. Corrected quickstart to explicit owned-fixture smoke helper and conditional migration. |
| F-07 | MEDIUM | Multiple genuine reports on a removed entry lacked defined resolution. Every tombstoning transaction now atomically closes all affected unresolved reports with truthful snapshot-derived disposition, preserves actual acknowledgements and frees pending capacity. |

Lead accepted each original finding and applied design corrections; see original
review, lead response and focused reviewer verdict for reasoning and disposition.

## Checks actually run

- Document validation on seven generated files: balanced fences, local links, no
  template/unknown markers; source context SHA checks unchanged; scoped diffs/manifests.
- Reviewed26FR/10SC design coverage and existing request contract (four fields), deadlines,
  caps/reserve, migration/rollback, retention, capture and owner submission boundaries.
- `git diff --check` passed after corrections. No app/backend build or runtime test
  executed for this documentation-only command; quickstart tests are future obligations.
- Read-only Azure management-plane Blob service properties on donkeytrumpd/donkeytrumpp:
  soft delete false; versioning/container delete/restore/change feed unset. No account
  settings changed; historical data/backup inventory remains an implementation gate.
- Supported Chrome bootstrap attempted before and after owner's reported Connect login;
  both failed before browser selection: `Importing module "node:process" is not allowed
  in node_repl`. No account page read or Connect change. This is tool access failure,
  not evidence against the owner's login. No repeated login request or bypass.
- `.specify/extensions.yml` absent on post-plan check, so no after_plan hooks dispatched.

Future execution gates include account/history/roles, genuine contact/trader/licence
facts, signing, physical exact-build acceptance, current Azure billing/capacity and
saved Connect readback. Planning review does not claim these gates passed.

## Evidence and final verdict

- [Final candidate manifest](reviews/plan-2026-09-27/final-candidate.json),
  [complete generated-file patch](reviews/plan-2026-09-27/final.diff),
  [governing context](reviews/plan-2026-09-27/context.json) and
  [final validation](reviews/plan-2026-09-27/final-validation.json).
- [Round1 findings](reviews/plan-2026-09-27/round1-reviewer.md),
  [lead response](reviews/plan-2026-09-27/round2-lead.md),
  [round2 dispositions/new F07](reviews/plan-2026-09-27/round2-reviewer.md),
  [F07 response](reviews/plan-2026-09-27/round3-lead.md) and
  [final independent APPROVE](reviews/plan-2026-09-27/round3-reviewer.md).
- Final review session `cc22e47e-5eb7-4edb-826b-a27da306aaa9`: exit0, no stderr,
  actual canonical `claude-opus-5-5`, nonzero firstParty usage, explicit high effort;
  see [metadata](reviews/plan-2026-09-27/round3-metadata.json).
- **Lead agreement:** I agree with the independent final APPROVE. F01–F07 are resolved
  in the frozen design; no material disagreement remains. Phase0/1 planning and its
  independent review are complete. No runtime implementation or release readiness
  is claimed. Source and candidate hashes rechecked unchanged after review.
- Three non-blocking interpretation notes are retained for task generation: per-snapshot
  dispositions govern already-removed targets; direct pending-to-resolved is allowed
  without fabricated acknowledgement; early SSH/MI probe must use a read-only mechanism
  or the first DEV deployment containing operator read mode. These do not require
  another review or an owner adjudication and do not weaken the agreed contracts.
- Post-plan extension file rechecked absent. Next workflow is `speckit-tasks`.

Chrome execution remains blocked by the supported runtime import error despite the
owner's confirmed login. No Connect fields/builds/drafts were inspected or changed.
Account-dependent implementation resumes when that supported connection works;
independent preparation may continue. No user permission is being requested here.
