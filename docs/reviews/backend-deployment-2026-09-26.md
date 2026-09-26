# Backend App Service deployment evidence — 2026-09-26

Scope: the owner's request to deploy DEV and PROD backends, add GitHub pipelines
using the existing reference actions and Azure naming convention, and reuse the
existing PROD App Service Plan. The existing DEV plan is also reused.

Base: `a47af91b5f6e9c9514613f7e55b3e593367116ab`. App Store clarification files
are unrelated work and are excluded from this deployment change.

## Checks completed before the first pipeline run

- `dotnet test src/backend.tests -c Release --filter 'Category!=StorageIntegration'`:
  45 passed, no failures/skips.
- `HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release`:
  49 passed, no failures/skips, real isolated Azurite 3.37.0.
- `python3 src/scripts/backend-release-tests.py -v`: nine tests passed; failed,
  foreign, non-main and wrong-workflow runs, changed ZIPs, wrong source identity,
  unsafe archive paths and invalid smoke origins are rejected.
- Local `dotnet publish` and package verification passed.
- actionlint 1.7.12: all three workflows passed.
- Python compilation and `git diff --check`: passed.
- DEV provisioning completed, with isolated storage/managed identity and GitHub OIDC.
- Before deployment: existing PROD `/health` returned 200. Existing DEV initially
  exceeded a 30-second cold-start probe, then returned 200 in the follow-up probe.
  Shared PROD plan: last-hour memory 70–75%; preceding-day maximum 92%. No plan
  mutation is part of provisioning or deployment.

## Completion state

Initial implementation is being activated in GitHub to obtain actual pipeline and
Azure deployment evidence. PROD provisioning, pipeline deployments, final live
checks and independent implementation review are not yet claimed complete.
