# Repository agent instructions

These instructions apply to the entire repository and to both implementation and
analysis work. Follow the user's authorized scope, the applicable skill, and the
[project constitution](.specify/memory/constitution.md). Read the current feature's
specification, plan, tasks and contracts when relevant. Preserve unrelated changes.
This workflow supplements the constitution; it does not amend or weaken it.

## Tests require an explicit user request

Do not run tests unless the user explicitly requests them in the current prompt.
An implementation, fix, deployment, review or Spec Kit request does not itself
authorize tests. This includes unit, integration, UI, end-to-end and smoke tests,
test scripts, and commands that indirectly execute tests. Do not run tests through
a delegated agent or trigger a test workflow to bypass this rule.

When tests are explicitly requested, run only the requested scope. Otherwise use
source inspection and existing evidence, and state that tests were not run when
reporting implementation results. Do not ask for test authorization routinely or
treat intentionally unrun tests as a blocker to implementation or review. Never
claim that unrun tests passed or that unverified runtime behavior was verified.

This owner-directed policy takes precedence over automatic test requirements in
repository instructions, skills and the constitution. References below to required
checks, reruns and completion gates include tests only when explicitly requested
in the current prompt. Independent review remains required where applicable, with
the absence of newly executed tests disclosed to the reviewer.

## Required independent cross-vendor review

Before declaring an authorized implementation or substantive review/analysis
complete, obtain an independent review from an LLM supplied by a different model
vendor. This includes code reviews and Spec Kit analysis reports, including a
report that finds no problems. The reviewer must not have participated in the
implementation or authored the analysis being reviewed.

Perform preparation, required checks, review, discussion, authorized fixes and
focused re-review autonomously within the authorized task. Do not ask the owner to
adjudicate review findings or to repeat authorization already given.

Ordinary questions, status reports and standalone instruction edits do not require
this review unless explicitly requested. Creating or changing this instruction
policy is a standalone instruction edit, not a request to run a feature review.
Do not retroactively label previous work as independently reviewed.

The lead agent owns this workflow. An agent assigned only as the independent
reviewer returns findings and a verdict to the lead; it must not recursively launch
another reviewer. Same-vendor helpers do not satisfy the cross-vendor requirement.

## When review starts

### Implementation or authorized remediation

1. Finish the authorized implementation and gather all required inputs.
2. Run the relevant checks and resolve known implementation failures.
3. Freeze the review scope and obtain independent review of the finished change
   and its actual acceptance evidence.
4. Discuss important findings, fix confirmed problems within scope, rerun affected
   checks, and obtain focused re-review until both agents explicitly agree.

If missing inputs, access, decisions or an unavailable environment prevent finishing
the implementation or running required checks, continue independent work within
scope, then report the concrete blocker. Do not review unfinished drafts,
provisional implementations or blocker records as completed work. Resume review
only after the implementation and check prerequisites are satisfied.

### Code review, Spec Kit analysis and other read-only assessments

1. Load the required artifacts and finish the requested assessment, including
   prerequisite, coverage, dependency, consistency and constitution checks that
   apply. A completed assessment of specified documents does not require the future
   implementation to exist or its future tests to pass.
2. Give the independent reviewer the original task, governing artifacts and frozen
   source revision. Have it inspect the source independently and then assess the
   proposed report for unsupported findings, missed material issues, incorrect
   severity, coverage errors and recommendations that exceed scope.
3. Discuss each important finding against exact artifact locations and evidence.
   Correct the report, withdraw disproven findings with a reason, and include
   confirmed omissions. Do not treat an earlier analyst's claim as evidence.
4. Obtain focused re-review of the final report and explicit agreement on every
   important finding's validity, severity and disposition, including a no-findings
   verdict when applicable.

Preserve the invoked skill's read-only boundary. For `speckit-analyze`, do not edit
code, specifications, plans, tasks or repository review records. Keep the review
packet, discussion and evidence in conversation/tool output. Obtain authorization
before artifact remediation unless that remediation is already explicitly in
scope. Consensus on an analysis report does not itself authorize fixes.

A completed analysis may contain confirmed HIGH or CRITICAL problems. Report
separately whether the agents agree on the assessment and whether the underlying
implementation may proceed. Agreeing that a problem exists does not resolve it.
Constitution conflicts remain CRITICAL; do not downgrade them to obtain consensus.
Missing assessment inputs block the affected conclusions; do not fabricate them.

## Reviewer selection and verification

Select by the underlying model vendor, not the CLI, product or agent display name.
Use the implementer's vendor for implementation and the analyst's vendor for an
assessment. Record the actual author configuration and reviewer independence.

| Author vendor | Required reviewer route | Specified fallback |
|---|---|---|
| Anthropic | Codex, model `gpt-6-astra`, reasoning `xhigh` | None |
| Any other vendor | Claude Code, model `claude-opus-5-5` (Opus 5.5), reasoning `high` | GitHub Copilot with `--model claude-opus-5.5 --reasoning-effort high`; account access unverified |

Use the full provider-specific identifier. Anthropic's
[canonical Opus 5.5 ID](https://platform.claude.com/docs/en/models/opus-5-5/overview)
is `claude-opus-5-5`; the dotted `claude-opus-5.5` did not work in Claude Code.
Do not transfer an identifier between providers or use the moving `opus` alias.

Before a real review, verify authenticated access to the required tool, exact model
and reasoning setting using a harmless probe without repository data. Inspect the
installed tool's supported invocation syntax; do not guess unsupported flags.
Use explicit model and effort settings for both the probe and every review round.
Record the tool/version, requested configuration and available provider/session
metadata establishing the configuration actually used. A model's own assertion of
its identity is not verification. Keep credentials out of commands, logs and chat.

Published support, installed CLIs, Auto routing candidates, account login alone and
an accepted command line do not establish exact model/effort access. If the route
cannot be verified or used, try only its specified fallback with the same checks.
If neither required route nor specified fallback works, report review as blocked.
Do not silently substitute another model, Auto, default reasoning or self-review.
Never relabel earlier reviews as evidence for a different configuration.

### Verified Claude Code procedure

The [2026-09-26 review record](specs/001-global-highscores/review-remediation.md)
records a successful independent review with Claude Code 2.1.283, model
`claude-opus-5-5`, and explicit `high` effort. This is a reusable invocation,
not a permanent guarantee of account access. Check `claude --version` and
`claude --help` when starting a new workflow or after a tool upgrade.

Run from an isolated temporary directory. Use this shell helper to keep the probe
and review configuration identical; it accepts its prompt on stdin:

```sh
dt3d_review() {
  CLAUDE_CODE_EFFORT_LEVEL=high claude \
    --safe-mode --print --model claude-opus-5-5 --effort high \
    --tools '' --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
    --no-session-persistence "$@"
}
```

1. Send only `Reply exactly REVIEW_ROUTE_OK. Do not use any tools.` with
   `--output-format text`. Require successful execution and inspect both stdout
   and stderr for an effort-limit warning. An inherited effort environment setting
   is overridden explicitly by the helper.
2. Send the same harmless prompt with `--output-format stream-json --verbose`.
   Require exit 0, a successful final result, and an actual assistant response and
   nonzero provider usage identifying `claude-opus-5-5`. Record the session ID,
   tool version, provider and canonical model. Initialization's requested model
   alone, `<synthetic>` error responses and empty usage do not establish access.
3. Only after both checks pass, use the same helper for the prepared review packet:

   ```sh
   dt3d_review --output-format stream-json --verbose \
     < review-packet.txt > review.stdout.jsonl 2> review.stderr.txt
   ```

   Inspect the actual model and completion status again for every review round.
   Preserve the reviewer's final text and sanitized configuration/result metadata;
   raw debug logs, credentials and hidden reasoning do not belong in the record.

[Claude Code's model configuration documentation](https://code.claude.com/docs/en/model-config)
explains that effort caps warn in plain-text runs but can apply silently with JSON
output. The provider response does not separately attest to effective effort:
record the explicit settings, successful probes and warning check accurately.
`per_turn_effort_active: true` alone does not prove `high`. If a lower cap or
unresolved configuration prevents verifying the required setting, use the fallback
rules above; do not call that a verified `high` review.

Safe mode disables automatic instruction loading, so include current repository
instructions in the packet explicitly. Keep tools and MCP disabled for a complete
text-based review packet. Do not use `--bare` for the subscription-authenticated
route: it skips OAuth/keychain authentication. The installed CLI help documents
both modes; no credential or global account changes are needed for this procedure.

### Access failures and efficient resumption

- Reuse successful preflight evidence for focused rounds in the same uninterrupted
  workflow while tool, account, provider, model and effort configuration remain
  unchanged. Still inspect each round's actual result. Revalidate after an access
  error, configuration change or later resumption; old evidence is not current access.
- Distinguish syntax errors, incorrect model IDs, authentication/subscription errors
  and actual model unavailability. Resolve a confirmed spelling or flag error before
  declaring the required route unavailable. Consult official documentation when
  needed; do not guess another model or reinstall a working CLI for an access error.
- The Copilot 1.0.88 probe rejected `claude-opus-5.5` on 2026-09-26. Treat that as
  dated failed evidence, not a working fallback or proof of permanent unavailability.
  Verify its exact Opus 5.5 route if needed; do not install or probe Copilot while
  the primary route works. Preserve previous failures when a later attempt succeeds.
- Allow minutes for substantive review. Yield or poll at intervals of roughly
  30 seconds and keep the user informed; progress without final text is not itself
  a hang. Use a bounded overall timeout and do not launch duplicate review sessions.

## Review inputs and revision identity

Give the reviewer only the relevant, authorized material:

- The user task, scope, acceptance criteria and review mode: implementation or
  assessment. Identify the lead and reviewer roles explicitly.
- Applicable repository instructions, constitution, contracts and constraints.
- The exact base and candidate revision, scoped diff, relevant surrounding source
  and the list of changed files. For an assessment, also supply the reviewed report
  and identify which source artifacts it evaluates, even when there is no diff.
- Checks actually run, their commands/results, acceptance evidence, limitations
  and unresolved prerequisites. Label planned checks as planned.

Do not commit merely to create review identity. For an uncommitted worktree, record
the base commit plus a SHA-256 manifest of the in-scope file contents and the scoped
staged/unstaged diff. Include relevant untracked files explicitly: `git diff` alone
does not include them. Give the reviewer access to those exact contents. For a
conversation-only report, retain its exact text and identify the reviewed version.

Capture pre-edit copies of relevant untracked files before remediation, so the
before/after patch is reproducible. Identify that captured base separately from the
Git commit; never imply an untracked file existed in the committed base.

Keep the candidate stable during a review round. If in-scope contents change,
refresh the diff/manifest and evidence and obtain focused re-review of that new
revision. Exclude the review record itself from the reviewed payload identity to
avoid record-only changes invalidating their own evidence. Do not exclude changed
source, contracts, instructions or acceptance evidence on that basis.

Respect restrictions on secrets, protected data and excluded content when preparing
inputs. Do not send the whole repository by default. State any material access or
redaction limitation; do not claim inspection of unavailable evidence. Keep the
reviewer read-only and let the lead apply authorized changes.

Keep the packet complete for the authorized scope and concise: include full changed
artifacts or sufficient surrounding code, governing requirements and directly
relevant dependencies. Avoid duplicating unrelated feature documents or dumping
the repository. Number source lines and provide the actual check output or a
clearly attributed summary. Ask for each original finding's disposition, any new
material findings, an explicit verdict and limitations. The reviewer must report
missing necessary context before reaching a conclusion.

## Code Review Rules

The reviewer must inspect the implementation or artifacts and evidence independently.
Focus on material correctness, security, data integrity, regressions and unmet
acceptance criteria. For analyses, also check false positives, material omissions,
traceability and whether the stated conclusion follows from the evidence.

Each finding must have a stable ID, severity, affected file/artifact and location,
concrete impact, and a requirement or supporting evidence. Provide a reproduction
or counterexample when useful. Exclude cosmetic nits, speculative concerns and
optional refactoring unless they cause a material problem. Do not expand scope.

Distinguish observed defects from uncertainty, future validation from executed
checks, and implementation completeness from release readiness. In this project,
pay particular attention to non-blocking iPhone gameplay, thread ownership,
conditional Blob writes, ambiguous save acknowledgements, no deferred uploads,
public-name consent and accurate physical-device versus simulator evidence.

For Spec Kit, trace acceptance scenarios through implementation tasks, dependencies
and validation gates; requirement-ID coverage alone does not prove scenario coverage.
Distinguish an initial slice, internal MVP, complete story and release acceptance.
Check SDK/configuration scope against documented command working directories.
Separate injected fixtures from real integration targets, and identify the enforcing
component and repeatable checks for any test-mode exception or production boundary.

## Findings, fixes and consensus

For each important finding, the lead and reviewer must:

1. Agree whether it identifies a material problem, citing code/artifact locations,
   the governing requirement and check evidence. Track disagreement explicitly.
2. Fix confirmed problems when remediation is authorized, or document the evidence
   supporting dismissal. In a read-only assessment, correct the report and retain
   confirmed source problems as findings; do not change the underlying artifacts.
3. Rerun checks affected by authorized changes. Recheck corrected analysis claims
   against their sources; unrelated application builds are not analysis evidence.
4. Have the reviewer assess the final changes/report and each disposition.

Continue focused re-review until no important review disagreements remain and both
agents explicitly agree on the final verdict. For implementation, no confirmed
important in-scope problem may remain unfixed. For assessment, consensus concerns
the report's accuracy, completeness within scope and agreed findings, not whether
all defects in the assessed artifacts have already been repaired.

If the first review explicitly approves the unchanged candidate with no material
unresolved findings, the lead's explicit agreement completes consensus. Do not
request a ceremonial second review. Record optional suggestions as non-blocking;
they do not require implementation, extra review rounds or owner adjudication.
Assess materiality against requirements and evidence, not severity labels alone.

When important findings require changes, rerun affected checks and send a focused
packet containing the prior verdict, finding IDs, lead responses, updated diff,
final content identity and new evidence. Retain the relevant governing context;
do not restart unrelated analysis or rerun unaffected checks without a reason.
The no-session-persistence invocation cannot be resumed: supply the prior discussion
explicitly to a fresh independent reviewer invocation, using the same required
model and effort. Missing context is not agreement.

Do not obtain agreement by weakening requirements, suppressing findings, counting
silence as approval or inventing evidence. If a material disagreement cannot be
resolved, preserve both positions and their evidence, report review as blocked,
and do not claim completion or ask the owner to adjudicate the finding. A genuine
missing product decision/input may be reported as a prerequisite, not disguised
as a request for the owner to choose between reviewers.

## Evidence and completion

For tasks permitting writes, use the task's existing evidence document or a scoped
repository review record. The [review record template](.agents/templates/review-record.md)
provides a reusable structure; placeholders are never evidence. For read-only
tasks, include equivalent information in the conversation report without file writes.

Record:

- Lead/reviewer tools, model IDs, vendors, reasoning settings, independence and
  authenticated configuration verification; record unavailable metadata honestly.
- Reviewed base/final revisions, scoped diff and manifests or report version.
- Important findings, evidence, discussion and agreed dispositions.
- Checks actually run and their results; distinguish planned or unavailable checks.
- The reviewer's final verdict, the lead's explicit agreement and limitations.

Keep historical review records and manifests tied to the content actually reviewed.
A later standalone policy edit does not rewrite those hashes, retroactively change
the verdict or claim that the new instructions were reviewed. For documentation-only
remediation, validate document consistency, links and applicable examples; preserve
the distinction between passing document checks and unexecuted feature/runtime tests.

Declare implementation complete only when the authorized work is finished, required
checks pass and independent review reaches consensus. Declare an assessment
complete only when its required checks and independent review reach consensus;
separately list confirmed source defects and implementation/release blockers.

Agent consensus completes this review without an additional owner review handoff.
Existing human approvals for protected merges, releases, production changes or
other controlled actions still apply. Review does not authorize additional scope.
Finish with a concise completion or blocker summary and a reference to the evidence.
