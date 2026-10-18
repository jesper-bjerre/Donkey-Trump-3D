# Highscore Score-Domain Contract Addendum

Design date:2026-10-18. This feature supersedes only the old multiples-of-100 score restriction in the [001 API schema](../../001-global-highscores/contracts/highscores.openapi.yaml). The [current moderation/authentication contract](../../002-app-store-release/contracts/moderation-api.md) and existing [iOS failure flow](../../001-global-highscores/contracts/ios-flow.md) continue to govern unchanged behaviour. Reconcile the active older score schema/docs during implementation; do not rewrite their historical review/test evidence.

## Numeric domain and exactness

The [score schema](highscore-score.schema.json) is the single planned numeric domain:

- Integer multiple of5, minimum0, maximum2,147,483,600 (existing int32-compatible ceiling).
- This applies to POST score, every GET/POST snapshot row, qualification/ranking, schema1/2 aggregate deserialization/validation and serialization. No submission-only exception.
- Existing multiples-of-100 values remain valid and retain their exact value. New values such as10 and1,005 must persist, read back and display exactly; no rounding, multiplication, projection/filtering or modulo-based inference of rules provenance.
- Invalid numbers (fractional, negative, not divisible by5 or beyond ceiling) retain existing validation/failure semantics. The new backend validation message describes multiples of5. Local run totals above the remote ceiling remain local, exact, and unpublished under existing unsupported-result behaviour.

This is input/domain validation, not proof of honest gameplay. Do not infer that every accepted number is achievable or server-verified.

## Unchanged public interface and storage

| Interface | Preserved contract |
| --- | --- |
| GET `/api/v1/highscores` | Public read-only complete top100 snapshot: entries(entryId,rank,displayName,score), revision,fetchedAtUtc; no-store |
| POST `/api/v1/highscores` | Existing installation authorization and strict JSON fields submissionId,displayName,score,levelReached; same ranked/notQualified and exact returned snapshot |
| Ranking | Score descending; successful-save sequence ascending for ties; full-list cutoff must be beaten |
| Identity / moderation | Existing stable run ID, bounded deduplication scope, installation attribution, blocks, removals, reports, retention and capacity unchanged |
| Blob | Same private container/name, schema1/2, fields and existing identities/sequences/timestamps; widening numeric validation needs no schema rewrite |
| Writes | Storage-enforced ETag/If-None-Match, current finite retry/deadline rules, no unconditional fallback |
| Failed acknowledgement | Potentially committed POST is unconfirmed; never infer no-save from a malformed mixed-list response, never automatically replay |
| Privacy / client | Existing explicit publication action, HTTPS, independent local best, no credentials in logs/code/arguments, no background/deferred upload |

## Compatibility decision and deployment dependency

Evolve v1 in place and rebuild/reinstall participating clients, matching the [2026-09-28 owner decision](../../../docs/releases/app-store/backend-single-api-rollout.md). Keep one all-time ranking; no season, new board/service, deletion or automatic re-scoring. Explain in relevant English help/release notes that retained historical and current totals use different scoring rules. Existing entries have no trustworthy rules tag; do not manufacture one.

Old strict iPhone decoders cannot read a snapshot containing a non-hundred score; their online browsing/submission is not compatible. Old POST responses may fail decoding after a real committed write, so current unconfirmed/no-replay behaviour remains necessary. Dated owner-only/unreleased evidence is not current distribution verification. Before any later rollout, verify actual installation/distribution constraints; continued support for old binaries, if required, is a new prerequisite. No deployment is performed by this feature's planning workflow.

Future coordinated order: widened backend reader/writer first, rebuilt clients next, then new-score publication. Validate old aggregate read plus mixed write/read on isolated real storage before relying on that sequence. Never enable new publication against an old strict backend.

**Rollback invariant**: After the first non-hundred value persists, every rollback/recovery backend must still read/validate the widened domain and preserve the aggregate. An old strict100 validator would turn the existing document into storage_invalid. Prepare a widened-reader rollback artifact; do not delete, round or repair data to fit an old binary. Do not confuse an old client reinstall with backend data rollback.

## Implementation surfaces and acceptance

Update the common Swift predicate in HighscoreModels, the backend common predicate/message in HighscoreValidation, the active 001 OpenAPI Score component, shared fixture cases and active numeric documentation. HighscoreDocument and ranking call the common predicate; verify both paths rather than adding disconnected exceptions. No changes to publication transport/auth/ETags are required.

Future boundary evidence must traverse parser→ranking→serialize→real Blob read→deserialize→GET→Swift decode for10/1,005 mixed with unchanged old entries. Confirm exact returned value, historical identities/tie order, bounds, invalid values, stable submission IDs and existing unconfirmed/no-replay paths. Injected fixtures are separate UI evidence, not real API/storage acceptance. See [quickstart](../quickstart.md).
