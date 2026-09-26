# Backend deployment: DEV and PROD

The backend runs as a .NET 10 App Service app in each environment. This supersedes
the earlier Container Apps proposal in feature 001. The iOS app and its App Store
release are separate; deploying the API does not distribute an iPhone build.

## Existing convention and resource mapping

The reference is `byens-hemmeligheder/.github/workflows/backend-deploy-dev.yml`
and `backend-deploy.yml`: DEV on `main`, manual PROD, Azure OIDC authentication,
ZIP deployment through Azure CLI, and a post-deployment HTTPS/API check. This
repository follows those conventions and promotes the tested DEV ZIP to PROD
instead of rebuilding it. Action versions are pinned to commit IDs.

[The resource manifest](../infra/backend-environments.json) is the source of truth.
All resources are in West Europe in the existing private subscription.

| Resource | DEV | PROD |
|---|---|---|
| GitHub environment | `development` | `production` |
| App in `Gulvet` | `donkeytrump-api-d` | `donkeytrump-api-p` |
| Existing Linux plan | `asp-vejles-koder-d` (F1) | `asp-vejles-koder-p` (B1) |
| Storage resource group | `donkeytrump-d_rg` | `donkeytrump-p_rg` |
| Hot/LRS storage account | `donkeytrumpd` | `donkeytrumpp` |
| Private container / blob | `highscores` / `global-v1.json` | `highscores` / `global-v1.json` |
| GitHub deployment identity | `oidc-donkeytrump-d` | `oidc-donkeytrump-p` |

No shared plan is created, resized, reconfigured or restarted. The pre-existing
`byensgaader-api-d` and `byensgaader-api-p` remain on their plans. New apps share
plan capacity; DEV F1 can sleep and has Free-tier quotas, while PROD has Always On
and `/health/live` as its platform health check. DEV uses the same endpoint in
pipeline smoke checks, without claiming platform Health Check support on F1.

## Provisioning and credentials

An authorized operator with existing Azure and GitHub CLI sessions runs from the
repository root:

```sh
python3 infra/provision-backend.py development
python3 infra/provision-backend.py production
```

The script refuses name collisions with resources not tagged for this repository,
checks existing app/plan relationships, and never creates or changes a plan.
Provisioning is separate from deployment: workflow identities cannot grant RBAC,
create storage or resize compute. Inspect a failure before rerunning; there is no
automatic deletion of partially provisioned resources.

Each API has its own system-assigned managed identity with Storage Blob Data
Contributor scoped to its own container. Each GitHub identity has Website
Contributor scoped only to its app. Storage is private, HTTPS/TLS 1.2, shared-key
authorization disabled; the API uses managed identity rather than SAS or keys.
Both cloud environments set `ASPNETCORE_ENVIRONMENT=Production` and
`Highscores__UseAzurite=false`. Development emulator settings are omitted from the
release ZIP. No HTTP access logs, detailed errors or failed-request tracing are
enabled by provisioning.

Each GitHub environment accepts only the `main` branch and contains the public
identifiers `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as variables.
There are no publish-profile or Azure password secrets. SCM/FTP basic publishing
authentication is disabled; Azure CLI deploys using Entra authentication.

This repository uses GitHub's immutable OIDC subject prefix, discovered from the
repository API rather than guessed from its name:

```text
repo:jesper-bjerre@260194575/Donkey-Trump-3D@1386156234:environment:development
repo:jesper-bjerre@260194575/Donkey-Trump-3D@1386156234:environment:production
```

See [GitHub OIDC subjects](https://docs.github.com/en/actions/reference/security/oidc),
[Microsoft's OIDC deployment guidance](https://learn.microsoft.com/en-gb/azure/app-service/deploy-github-actions?tabs=openid)
and [deployment with basic authentication disabled](https://learn.microsoft.com/en-us/azure/app-service/configure-basic-auth-disable).

## Pipelines and promotion

- [Backend CI](../.github/workflows/backend-ci.yml): PRs and relevant `main` changes;
  all backend tests, including real Azurite storage/concurrency tests, and release
  validation tests. It has no Azure credentials or deployment environment.
- [Backend Deploy DEV](../.github/workflows/backend-deploy-dev.yml): relevant `main`
  pushes or manual dispatch. Tests, publishes once, embeds the source commit,
  creates a SHA-256 manifest, retains the ZIP artifact for 30 days, deploys and
  checks liveness, storage-backed GET, `no-store` and HTTP-to-HTTPS redirection.
- [Backend Deploy PROD](../.github/workflows/backend-deploy-prod.yml): manual only.
  Supply a successful DEV run ID and `dev_verified=true`. It checks repository,
  workflow ID, branch, event and successful completion before downloading the exact
  artifact. It verifies both embedded commit and package digest, deploys without
  rebuilding, and runs the same smoke checks. A failed smoke makes deployment fail;
  it does not silently report success or overwrite the highscore blob.

```sh
gh workflow run backend-deploy-dev.yml --ref main
# After the selected DEV run has succeeded and its behavior is verified:
gh workflow run backend-deploy-prod.yml --ref main \
  -f dev_run_id=SUCCESSFUL_DEV_RUN_ID -f dev_verified=true
```

Deployment is serialized separately per environment and does not cancel an active
deployment. GitHub may replace a pending run with a newer pending run. A manual run
on another branch does not deploy. Public PRs never receive an Azure token.

The GitHub environment URL comes from Azure's actual `defaultHostName`; do not
assume that Azure always allocates the legacy non-randomized hostname format.
`WEBSITE_RUN_FROM_PACKAGE=1` mounts the validated ZIP read-only. The ZIP contains
publish output at its root, as required by
[App Service run from package](https://learn.microsoft.com/en-us/azure/app-service/deploy-run-package).
App Service supplies the serviced .NET 10 runtime; the local Dockerfile is an
alternative packaging path, not a requirement of these pipelines.

## Verification and rollback

Use the real origin shown by the completed deployment:

```sh
python3 src/scripts/backend-release.py smoke https://ACTUAL_APP_HOSTNAME
python3 src/scripts/backend-release-tests.py -v
```

The deployed GET checks authenticated access to the real container. On an empty
list it checks a BlobNotFound response from the existing container; it does not
prove a successful write. Keep emulator concurrency evidence distinct from live
managed-identity write/persistence evidence. Smoke checks do not create fake PROD
players or print existing player names. The initial deployment evidence records
which additional live checks were actually performed.

To roll back, select a previous successful DEV run whose artifact remains available
and compatible with the current storage schema, then dispatch PROD with that ID.
The workflow validates it in the same way as a new release. Expired or removed
artifacts cannot be used; build and verify a source revert through DEV first.
The API app restarts during deployment. B1 has no deployment slots, so do not promise
zero downtime. Failure after deployment requires inspection and, where warranted,
explicit rollback; automated rollback could hide an external storage outage.

Rollback never restores, clears or rewrites the ranking blob. Preserve ambiguous
submission outcomes; do not replay POST requests. Never turn a missing container
or corrupt document into an empty list to make a smoke check pass. Record revision,
DEV/PROD run IDs, artifact digest, check results and any limitations.

## Capacity and cost

Compute uses the existing F1 and B1 plans without a new compute charge or size
change. This is shared capacity, not free extra capacity: the PROD plan was already
at approximately 70–75% memory during the baseline hour, with a 92% maximum in the
preceding day. Check CPU/memory and the existing application's health after changes.
Do not resize the shared plan without a separate decision.

Incremental storage cost depends on reads, conditional-write retries, retained data
and egress. The stored ranking is bounded to 256 KiB. For a small launch, use 1,000
GETs and 100 POSTs per day across both environments as a planning assumption, not a
rate limit or a traffic measurement. Sustained traffic at the API's per-process
limits is a different, more expensive scenario. The owner's ceiling is DKK 100 per
month including VAT for incremental operation; existing plan charges are separate.
Microsoft's [Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices)
returned these West Europe General Block Blob v2 Hot/LRS DKK rates on 2026-09-26:
0.1258 per GB/month (first tier), 0.0276 per 10,000 reads and 0.3466 per
10,000 writes. At the small-launch assumption, 33,000 reads plus 3,000 writes/month
cost about DKK 0.20 before VAT (about DKK 0.25 after 25% VAT), excluding retries,
egress and other operations. Even budgeting 1 GB stored adds only about DKK 0.16
including VAT. These are list-price planning inputs, not an invoice or a guaranteed
cap; actual subscription pricing, tax, traffic and egress determine the bill.
No paid log analytics, extra compute, Front Door or monitoring service is provisioned.
A budget is a warning, not an enforceable spending cap. Review actual project-tagged
and storage-resource-group costs after launch; do not claim the public endpoint's
rate limits guarantee a monthly bill.

The deployment [evidence and independent review](reviews/backend-deployment-2026-09-26.md)
records the executed checks and observed resources. App Store moderation, physical
iPhone acceptance and the iOS production endpoint are separate release work.
