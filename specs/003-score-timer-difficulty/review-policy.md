# Owner-directed review policy

**Effective**: 2026-10-18
**Feature**: [Score, Attempt Timer and Level Pressure](spec.md)

The owner instructed:

> Denne spec skal ikke have review af Claude Code. Heller ikke ved implementering.

Do not run or require Claude Code review for this feature, including specification,
clarification, planning, analysis, implementation and remediation. The feature is
exempt from the corresponding cross-vendor completion gate; do not require a
substitute review to work around this owner instruction. Ordinary lead inspection
and checks authorized by the current prompt still apply. Tests require an explicit
request under [AGENTS.md](../../AGENTS.md).

This policy covers application/backend files changed for this feature as well as
its documentation. It does not authorize commits, pushes, deployment, publication
or additional implementation scope.

The planning review that was already in progress was stopped when this instruction
arrived. It has no accepted verdict and is not completion evidence. Earlier
specification/clarification reviews remain historical evidence for their recorded
revisions; the exception does not rewrite those reviews or their hashes. The policy
metadata added to the specification is not independently reviewed or presented as
part of those earlier reviewed revisions.
