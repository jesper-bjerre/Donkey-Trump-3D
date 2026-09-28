# Backend redeployment — 2026-09-28

Completed UTC: 2026-09-28T18:54:22.981126+00:00

Owner explicitly requested deployment to DEV and PROD. No tests, smoke tests or
functional API requests were run for this request. The existing GitHub workflows
run tests, so the authorized deployment used Azure CLI directly with the existing
immutable package instead.

Backend source is unchanged between reviewed release `bf3c4165650e9bb4ee8aaf4a9efa2542ac8486a7` and current
checkout `7aa5624`. Existing independent review applies to the unchanged backend.
ZIP SHA256 was checked against release.json: `3ca6bb2fba6f9f5fab30e35f067dd85cb811e938255a9eaeb847310fdae217ba`.

| Environment | Azure deployment ID | Azure status | Successful instances |
|---|---|---|---|
| DEV | 0970e488-c4f8-4bca-a6dc-4fce752aa06e | RuntimeSuccessful | 1 |
| PROD | 9f86295a-6e60-47b5-ab7a-f2bb03fb9a8b | RuntimeSuccessful | 1 |

Both commands used the same ZIP with clean deployment and restart enabled. Azure
reports zero failed instances in both environments. No settings, shared plans or
stored scores were changed by the deployment commands.

This confirms deployment/startup status, not highscore save functionality or
in-container file hashes. The earlier PROD functional-verification limitation is
not relabeled as a passed test by this redeployment.
