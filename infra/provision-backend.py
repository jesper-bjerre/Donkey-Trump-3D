#!/usr/bin/env python3
"""Provision only the named backend resources; never resize existing shared plans.

Uses the operator's existing az/gh sessions. No account keys or publish profiles.
"""
import argparse
import json
from pathlib import Path
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT / "infra/backend-environments.json").read_text())


def run(args, data=None):
    result = subprocess.run(args, input=data, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f"{args[0]} {args[1]} failed: {result.stderr.strip()}")
    return json.loads(result.stdout) if result.stdout.strip() else None


def az(*args):
    return run(["az", *args, "--subscription", CONFIG["subscriptionId"], "--only-show-errors", "-o", "json"])


def mutate(*args):
    run(["az", *args, "--subscription", CONFIG["subscriptionId"], "--only-show-errors", "-o", "none"])


def owned(resources, name):
    matches = [r for r in resources if r["name"].lower() == name.lower()]
    if matches and (matches[0].get("tags") or {}).get("Repository") != CONFIG["repository"]:
        raise RuntimeError(f"Refusing to modify existing unowned resource {name}")
    return bool(matches)


def assign(principal, role, scope):
    identifier = str(uuid.uuid5(uuid.NAMESPACE_URL, principal + role + scope.lower()))
    mutate("role", "assignment", "create", "--name", identifier, "--assignee-object-id", principal,
           "--assignee-principal-type", "ServicePrincipal", "--role", role, "--scope", scope)


def provision(environment):
    cfg = CONFIG["environments"][environment]
    group, location = CONFIG["appResourceGroup"], CONFIG["location"]
    tags = ["Repository=" + CONFIG["repository"], "Project=DonkeyTrump", "Environment=" + environment]
    # Only read the shared plan. Neither this script nor pipeline credentials can resize it.
    plan = az("appservice", "plan", "show", "-g", group, "-n", cfg["planName"])
    if not plan.get("properties", plan).get("reserved") or plan["location"].replace(" ", "").lower() != location:
        raise RuntimeError("Expected existing Linux plan in the configured region")
    sites = az("webapp", "list", "-g", group)
    if not any(s["name"] == cfg["existingApp"] and s["serverFarmId"].lower() == plan["id"].lower() for s in sites):
        raise RuntimeError("Expected existing app/plan relationship has changed; inspect before proceeding")
    exists = owned(sites, cfg["appName"])
    if exists and next(s for s in sites if s["name"] == cfg["appName"])["serverFarmId"].lower() != plan["id"].lower():
        raise RuntimeError("Refusing to move an existing app to a different plan")
    if not exists:
        mutate("webapp", "create", "-g", group, "-n", cfg["appName"], "-p", plan["id"],
               "--runtime", "DOTNETCORE:10.0", "--https-only", "true", "--basic-auth", "Disabled", "--tags", *tags)
    mutate("webapp", "identity", "assign", "-g", group, "-n", cfg["appName"])
    site = az("webapp", "show", "-g", group, "-n", cfg["appName"])
    groups = az("group", "list")
    if not owned(groups, cfg["storageResourceGroup"]):
        mutate("group", "create", "-n", cfg["storageResourceGroup"], "-l", location, "--tags", *tags)
    stores = az("storage", "account", "list")
    if not owned(stores, cfg["storageAccount"]):
        mutate("storage", "account", "create", "-g", cfg["storageResourceGroup"], "-n", cfg["storageAccount"],
               "-l", location, "--kind", "StorageV2", "--sku", "Standard_LRS", "--access-tier", "Hot",
               "--https-only", "true", "--min-tls-version", "TLS1_2", "--allow-blob-public-access", "false",
               "--allow-shared-key-access", "false", "--tags", *tags)
    mutate("storage", "container-rm", "create", "-g", cfg["storageResourceGroup"],
           "--storage-account", cfg["storageAccount"], "-n", "highscores", "--public-access", "off")
    store = az("storage", "account", "show", "-g", cfg["storageResourceGroup"], "-n", cfg["storageAccount"])
    container = store["id"] + "/blobServices/default/containers/highscores"
    assign(site["identity"]["principalId"], "Storage Blob Data Contributor", container)
    mutate("webapp", "config", "set", "-g", group, "-n", cfg["appName"],
           "--linux-fx-version", "DOTNETCORE|10.0", "--always-on", str(environment == "production").lower(),
           "--min-tls-version", "1.2", "--ftps-state", "Disabled", "--http20-enabled", "true",
           "--generic-configurations", json.dumps({"healthCheckPath": "/health/live" if environment == "production" else "", "httpLoggingEnabled": False,
               "detailedErrorLoggingEnabled": False, "requestTracingEnabled": False, "scmMinTlsVersion": "1.2"}))
    mutate("webapp", "config", "appsettings", "set", "-g", group, "-n", cfg["appName"], "--settings",
           "ASPNETCORE_ENVIRONMENT=Production", "Highscores__UseAzurite=false",
           "Highscores__BlobServiceUri=" + store["primaryEndpoints"]["blob"],
           "Highscores__ContainerName=highscores", "Highscores__BlobName=global-v1.json",
           "SCM_DO_BUILD_DURING_DEPLOYMENT=false", "WEBSITE_RUN_FROM_PACKAGE=1")
    for policy in ("scm", "ftp"):
        mutate("resource", "update", "--ids", site["id"] + "/basicPublishingCredentialsPolicies/" + policy,
               "--api-version", "2023-12-01", "--set", "properties.allow=false")
    identities = az("identity", "list", "-g", group)
    if not owned(identities, cfg["deployIdentity"]):
        mutate("identity", "create", "-g", group, "-n", cfg["deployIdentity"], "-l", location, "--tags", *tags)
    identity = az("identity", "show", "-g", group, "-n", cfg["deployIdentity"])
    assign(identity["principalId"], "Website Contributor", site["id"])
    repo = CONFIG["repository"]
    oidc = run(["gh", "api", f"repos/{repo}/actions/oidc/customization/sub"])
    if not oidc.get("use_default") or not oidc.get("use_immutable_subject") or not oidc.get("sub_claim_prefix"):
        raise RuntimeError("Unexpected GitHub OIDC subject configuration; verify actual subject first")
    subject = oidc["sub_claim_prefix"] + ":environment:" + environment
    credentials = az("identity", "federated-credential", "list", "-g", group, "--identity-name", cfg["deployIdentity"])
    fid = "github-" + environment
    existing = next((f for f in credentials if f["name"] == fid), None)
    expected = {"issuer": "https://token.actions.githubusercontent.com", "subject": subject, "audiences": ["api://AzureADTokenExchange"]}
    if existing and any(existing.get(k) != v for k, v in expected.items()):
        raise RuntimeError("Existing federated credential differs; refusing to overwrite trust")
    if not existing:
        mutate("identity", "federated-credential", "create", "-g", group, "--identity-name", cfg["deployIdentity"],
               "-n", fid, "--issuer", expected["issuer"], "--subject", subject, "--audiences", *expected["audiences"])
    endpoint = f"repos/{repo}/environments/{environment}"
    envs = run(["gh", "api", f"repos/{repo}/environments"])["environments"]
    if not any(e["name"] == environment for e in envs):
        run(["gh", "api", "--method", "PUT", endpoint, "--input", "-"],
            json.dumps({"deployment_branch_policy": {"protected_branches": False, "custom_branch_policies": True}}))
    current = run(["gh", "api", endpoint])
    if current.get("deployment_branch_policy") != {"protected_branches": False, "custom_branch_policies": True}:
        raise RuntimeError("Environment must use custom deployment branch policies; inspect existing protection rules")
    policies = run(["gh", "api", endpoint + "/deployment-branch-policies"])["branch_policies"]
    if any(p["name"] != "main" or p.get("type", "branch") != "branch" for p in policies):
        raise RuntimeError("Unexpected deployment branch policy; only main is permitted")
    if not any(p["name"] == "main" and p.get("type", "branch") == "branch" for p in policies):
        run(["gh", "api", "--method", "POST", endpoint + "/deployment-branch-policies", "--input", "-"], json.dumps({"name": "main", "type": "branch"}))
    account = az("account", "show")
    for key, value in {"AZURE_CLIENT_ID": identity["clientId"], "AZURE_TENANT_ID": account["tenantId"], "AZURE_SUBSCRIPTION_ID": CONFIG["subscriptionId"]}.items():
        run(["gh", "variable", "set", key, "--repo", repo, "--env", environment, "--body", value])
    print(json.dumps({"environment": environment, "app": cfg["appName"], "origin": "https://" + site["defaultHostName"],
                      "plan": cfg["planName"], "storage": cfg["storageAccount"], "oidcSubject": subject}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("environment", choices=CONFIG["environments"])
    provision(parser.parse_args().environment)
