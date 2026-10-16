# Manual highscore administration

This is an owner-operated console tool. Open the target App Service in the Azure
portal, choose **Development Tools → SSH → Go**, and use the commands below.
Azure authorizes the SSH session; the tool uses that app's existing managed identity
and validates the app/storage inventory. There is no admin HTTP endpoint, iOS call,
scheduled operation, startup mutation, new credential or additional hosted service.

## Routine use

In the SSH session, define this convenience function once:

```sh
admin() { bash /home/site/tools/highscore-admin/current/highscore-admin.sh "$@"; }
```

Find the current entry at a position, or inspect a known entry ID:

```sh
admin entry --rank 4
admin entry --entry-id ENTRY_ID_FROM_OUTPUT
```

The private console shows only that stored entry's ID, current rank, name, score
and ETag. Copy its `entryId`; positions can change when new scores arrive. A virtual
starter that has never been stored cannot be edited.

Preview a rename, then explicitly apply it:

```sh
admin rename --entry-id ENTRY_ID_FROM_OUTPUT --display-name 'New name'
admin rename --entry-id ENTRY_ID_FROM_OUTPUT --display-name 'New name' --apply
admin entry --entry-id ENTRY_ID_FROM_OUTPUT
```

`--apply` is a manual instruction to perform that invocation's fresh preview.
To require the exact revision from an earlier preview, include its ETag:

```sh
admin rename --entry-id ENTRY_ID_FROM_OUTPUT --display-name 'New name' \
  --expected-etag '"ETAG_FROM_PREVIEW"' --apply
```

The wrapper derives DEV/PROD from `WEBSITE_SITE_NAME`; the backend independently
validates the matching storage account/container and managed-identity context.
It rejects a user-supplied `--target` override. Run neither in CI nor a recorded
application log: the selected public name is intentionally visible to the owner.

## Behavior and failures

- Names use the existing NFC normalization, 1–20 grapheme / 256-byte validation and
  moderation policy. Invalid/prohibited names are rejected before a write.
- Only the identified stored entry's display name changes. ID, score, sequence,
  rank, level, origin, installation attribution and acceptance time are preserved.
  Report snapshots are not renamed. Normal existing pre-mutation retention cleanup
  may remove already-expired reports/audit/spam receipts.
- Preview performs no mutation. Applying an already matching name is a read-only
  no-op. Rename cannot create a missing entry or resurrect a removed one.
- Apply pins the ETag read for its own preview, and storage uses `If-Match`. Any
  intervening update returns `revision_changed` without overwriting it. Inspect the
  entry and make a new deliberate invocation if still appropriate.
- After `operation_unconfirmed` or `operator_unavailable_or_unconfirmed`, inspect
  the entry by ID. The write may have committed; do not blindly repeat `--apply`.
- Rename uses the entry ID and inspected ETag as its concurrency identity. It adds
  no new aggregate audit enum/receipt or schema field, so existing schema-2 readers
  remain compatible. The private command result contains the saved entry and ETag.
  Keep content-free operational evidence (entry ID/revisions/actor/action), not
  prior personal names or complete blob snapshots, in ordinary review records.
- Existing publication deduplication compares the current canonical stored payload;
  replaying the original name for this run after an admin rename can therefore
  return `submission_conflict`. This does not create a score upload/retry path.

The store retains its existing six-second operation/two-second network limits and
disabled SDK retries. Conflicts never fall back to unconditional replacement.
Maintenance blocks changes. The command is not a report resolution and does not
acknowledge/close reports, remove tombstones or unblock installations.

## Installation and updates

The wrapper is included in backend build/publish output. When the new backend
package has been deployed normally, the equivalent direct command is:

```sh
bash /home/site/wwwroot/highscore-admin.sh entry --rank 4
```

For an administrative-only installation without restarting or replacing the HTTP
application, stage the reviewed backend DLL and its `highscore-admin.sh` wrapper
in a private temporary directory in the target App Service. Use the recorded DLL
SHA256 and the matching existing backend dependency/runtime baseline; this narrow
update introduces no package dependencies. Then manually run:

```sh
bash install-highscore-admin.sh STAGING_DIRECTORY EXPECTED_DLL_SHA256
```

The installer is [in the repository](../src/scripts/install-highscore-admin.sh).
It copies the current app's dependency DLLs, dependency/runtime manifests and
runtime assets into `/home/site/tools/highscore-admin/DLL_SHA256`, adds the reviewed
operator assembly/wrapper, verifies the assembly hash, and switches `current`.
Existing revisions are immutable and retained. It never runs a data command,
rewrites `/home/site/wwwroot`, restarts the app or changes Azure permissions.
The wrapper reads the live app's configuration by setting its working directory
to `/home/site/wwwroot`. Install a reviewed matching tool revision again if a
future storage/dependency contract changes; do not reuse an incompatible old tool.

The dated review record is the authority for what was actually built, installed
and checked. A source build is not proof of a live installation or a tested rename.
