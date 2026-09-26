#!/usr/bin/env python3
"""Package, validate and smoke-test backend releases without printing player data."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile


def validate_dev_run(run, repository, workflow_id):
    if not (run.get("status") == "completed" and run.get("conclusion") == "success"
            and run.get("workflow_id") == workflow_id and run.get("head_branch") == "main"
            and run.get("head_repository", {}).get("full_name") == repository
            and run.get("event") in ("push", "workflow_dispatch")
            and re.fullmatch(r"[0-9a-f]{40}", run.get("head_sha", ""))):
        raise ValueError("Select a successful main-branch DEV deployment from this repository")
    return run["head_sha"]


def validate_package(directory, commit):
    directory = Path(directory)
    manifest = json.loads((directory / "release.json").read_text())
    if not re.fullmatch(r"[0-9a-f]{40}", commit) or manifest["commit"] != commit:
        raise ValueError("Artifact commit does not match the verified DEV run")
    digest = hashlib.sha256((directory / "app.zip").read_bytes()).hexdigest()
    if manifest["sha256"] != digest:
        raise ValueError("Artifact digest mismatch")
    with zipfile.ZipFile(directory / "app.zip") as archive:
        if "DonkeyTrump.Highscores.Api.dll" not in archive.namelist():
            raise ValueError("API assembly missing from package root")
        if any(n.startswith("/") or ".." in Path(n).parts for n in archive.namelist()):
            raise ValueError("Unsafe archive path")
        if json.loads(archive.read("deployment.json"))["commit"] != commit:
            raise ValueError("Embedded release identity mismatch")
    return digest


def package(source, output, commit):
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("A full commit SHA is required")
    source, output = Path(source), Path(output)
    output.mkdir(parents=True, exist_ok=True)
    (source / "deployment.json").write_text(json.dumps({"commit": commit}) + "\n")
    with zipfile.ZipFile(output / "app.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(source.rglob("*")):
            if path.is_file() and path.name != "appsettings.Development.json":
                archive.write(path, path.relative_to(source))
    digest = hashlib.sha256((output / "app.zip").read_bytes()).hexdigest()
    (output / "release.json").write_text(json.dumps({"commit": commit, "sha256": digest}, indent=2) + "\n")
    validate_package(output, commit)
    print(f"Packaged commit {commit}; SHA-256 {digest}")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def smoke(origin, attempts=20):
    url = urllib.parse.urlsplit(origin)
    if url.scheme != "https" or not url.hostname or url.username or url.password or url.query or url.fragment or url.path not in ("", "/"):
        raise ValueError("Smoke target must be an HTTPS origin without credentials")
    origin = origin.rstrip("/")
    opener = urllib.request.build_opener(NoRedirect)
    for attempt in range(1, attempts + 1):
        try:
            with opener.open(origin + "/health/live", timeout=15) as response:
                if response.status != 200 or response.read(1024).decode().strip() != "Healthy":
                    raise ValueError("Liveness contract failed")
            with opener.open(origin + "/api/v1/highscores", timeout=15) as response:
                if response.status != 200 or response.headers.get("Cache-Control") != "no-store":
                    raise ValueError("Snapshot status/cache contract failed")
                data = json.loads(response.read(262145))
                if not isinstance(data.get("entries"), list) or len(data["entries"]) > 100 or not data.get("revision"):
                    raise ValueError("Snapshot contract failed")
            break
        except (urllib.error.URLError, TimeoutError, ValueError, OSError):
            # Never emit the response body, exceptions, player names or network addresses.
            if attempt == attempts:
                raise RuntimeError("Liveness/storage smoke failed within the startup deadline") from None
            print(f"Waiting for liveness and storage ({attempt}/{attempts})", flush=True)
            time.sleep(10)
    try:
        opener.open("http://" + url.netloc + "/health/live", timeout=15)
    except urllib.error.HTTPError as response:
        if response.code not in (301, 302, 307, 308) or not response.headers.get("Location", "").startswith(origin + "/"):
            raise RuntimeError("Expected platform HTTPS redirect") from None
    else:
        raise RuntimeError("HTTP did not redirect to HTTPS")
    print("PASS: process liveness, authenticated storage snapshot, no-store and HTTPS redirect")


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    pack = sub.add_parser("package"); pack.add_argument("source"); pack.add_argument("output"); pack.add_argument("commit")
    verify = sub.add_parser("verify"); verify.add_argument("directory"); verify.add_argument("commit")
    probe = sub.add_parser("smoke"); probe.add_argument("origin")
    promote = sub.add_parser("validate-dev-run"); promote.add_argument("run_json"); promote.add_argument("repository"); promote.add_argument("workflow_id", type=int)
    args = parser.parse_args()
    if args.command == "package": package(args.source, args.output, args.commit)
    elif args.command == "verify": print("Verified artifact SHA-256 " + validate_package(args.directory, args.commit))
    elif args.command == "smoke": smoke(args.origin)
    else:
        sha = validate_dev_run(json.loads(Path(args.run_json).read_text()), args.repository, args.workflow_id)
        with open(os.environ["GITHUB_OUTPUT"], "a") as output: output.write("sha=" + sha + "\n")
        print("Verified successful DEV deployment for commit " + sha)


if __name__ == "__main__":
    main()
