# Independent review record template

Use this structure in an existing task evidence document or a scoped review record
only when file writes are authorized. For a read-only analysis, provide the same
information in conversation output; do not create a repository record. Replace
placeholders with observed evidence or an explicit unavailable/not-applicable value.
Follow [AGENTS.md](../../AGENTS.md); this template does not grant remediation scope.

## Task and scope

- Authorized task and acceptance criteria: <reference>
- Mode: <implementation | read-only assessment>
- Governing instructions, constitution version and contracts: <references>
- Scope exclusions and material input limitations: <details>

## Participants and verified route

| Role | Tool/version | Vendor | Exact model | Reasoning | Evidence |
|---|---|---|---|---|---|
| Lead implementer/analyst | <tool> | <vendor> | <model ID> | <setting> | <session metadata> |
| Independent reviewer | <tool> | <different vendor> | <model ID> | <setting> | <verified route/session metadata> |

- Reviewer did not implement the change or author the assessment: <basis>
- Authenticated harmless probe, date and actual model/effort verification: <result>
- Primary/fallback route attempts and limitations: <results; no secrets>

## Frozen review inputs

- Base commit: <SHA or explanation if no Git base exists>
- Candidate and final commit/worktree identity: <SHA or scoped content manifest>
- Scoped staged/unstaged diff and relevant untracked contents: <references>
- Assessment source snapshot and exact report version, when applicable: <identity>
- Review packet and permitted evidence: <references>

## Findings and dispositions

| ID | Severity | Location and requirement | Concrete impact/evidence | Discussion and disposition | Re-review |
|---|---|---|---|---|---|
| <ID> | <severity> | <file:line, requirement> | <repro/source> | <fixed / dismissed with evidence / confirmed assessment finding / unresolved> | <reviewer verdict on final version> |

Confirmed assessment findings remain reportable defects until separately remediated.
They are not fixed merely because both agents agree that they are valid.

## Checks actually run

| Check/command | Revision/environment | Result | Evidence/limitations |
|---|---|---|---|
| <check> | <identity> | <pass/fail/not run> | <observed output/reference> |

List planned checks separately. Record affected reruns after fixes; do not reuse
results from a different revision without a stated and valid basis.

## Final verdict

- Review status: <consensus reached | blocked>
- Reviewer verdict on the exact final implementation/report: <explicit statement>
- Lead's agreement and evidence: <explicit statement>
- Confirmed source findings still requiring remediation, for assessments: <IDs>
- Unresolved material disagreements, both positions and evidence: <details or none>
- Implementation/release status and remaining limitations: <separate from review>
- Concrete blocker, if any: <missing input/access/check or unresolved disagreement>

Consensus is agent agreement on the authorized deliverable. It is not authorization
to edit during a read-only assessment, merge protected branches or deploy/release.
