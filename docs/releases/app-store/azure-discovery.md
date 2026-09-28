# Azure discovery — 2026-09-27

PARTIAL; no capacity/MI gate pass and no provisioning authorization inferred.
Source inventory: `infra/backend-environments.json`; subscription `6b6dcc04-7490-42ed-bedf-68f60946485e`, app RG `Gulvet`, West Europe.

| Environment | App | Existing shared plan | Existing neighbor | Storage / RG |
|---|---|---|---|---|
| DEV | donkeytrump-api-d | asp-vejles-koder-d | byensgaader-api-d | donkeytrumpd / donkeytrump-d_rg |
| PROD | donkeytrump-api-p | asp-vejles-koder-p | byensgaader-api-p | donkeytrumpp / donkeytrump-p_rg |

Current management-plane reads confirm game and neighbor apps Running on the recorded plans. PROD plan is B1, capacity 1; game runtime DOTNETCORE|10.0, Always On true, HTTP/2 true. Plan tier/scale and other workloads were not changed. Existing inventory identifiers require no correction from these observations.

Initial supported DEV `az webapp ssh` probe with 40-second timeout failed: `SSH endpoint unreachable, your app must be running before it can accept SSH connections.` Azure Running status alone is not proof of SSH availability. Managed-identity context availability inside SSH is NOT verified. No human Blob credentials or data-plane fallback was used. Conclusive MI aggregate read also remains unexecuted.

Outstanding T003: current MI-role scope, storage history/retention/backups, current shared capacity/neighbor HTTP baseline and supported MI context. Historical memory metrics are not current acceptance. No PROD promotion or draft readiness without capacity and neighboring-app checks. The owner removed the budget constraint on 2026-09-27 and monitors Azure costs; billing baselines and cost estimates are no longer gates.

Follow-up: DEV `/health/live` returned HTTP 200 after warming. Retried the supported SSH command; it exited 0 without exposing an interactive process or any MI-context boolean. This does not establish the required in-session managed-identity access. No secret/environment inspection was attempted.

Fresh PROD management checks: Blob soft delete disabled; versioning/container delete retention/restore/change feed unset. This is configuration evidence only, not enumeration of historical versions/deleted backups. Application filesystem/Blob/Table logs Off, HTTP filesystem/Blob logs disabled, detailed error pages and failed-request tracing disabled. No retention value was configured; seven-day/provider retention is still not a completed gate. Latest returned hourly shared-plan metrics: average memory76.43%, maximum79%; average CPU23.32%, maximum54%, timestamp2026-09-27T17:08:00Z. This short window does not establish peak-load capacity.

Historical observation made before the owner removed financial gates; no refresh required for release: actual cost query (CostManagement2023-03-01, ActualCost/MonthToDate, filter only existing PROD plan ResourceId): DKK9.7039404 pre-tax billed so far in September2026, no continuation page. Equivalent DKK12.1299255 with25% VAT. This is observed month-to-date usage, not a full-month recurring price or a spend cap; billing delay and remaining-month charges must remain distinguished. Query/result retained locally at `/tmp/dt3d-plan-cost-query.json` and `/tmp/dt3d-plan-cost-result.json`. No plan charge was attributed to the game's incremental cost.
