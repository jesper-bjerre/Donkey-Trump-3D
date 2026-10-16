set -euo pipefail
umask 077
[ "$WEBSITE_SITE_NAME" = donkeytrump-api-p ]
work=/tmp/dt3d-prod-name-20261016
url=https://donkeytrumpp.blob.core.windows.net/highscores/global-v1.json
dt3d_token="$(curl --fail --silent --show-error --max-time 30 --header "X-IDENTITY-HEADER: $IDENTITY_HEADER" "$IDENTITY_ENDPOINT?resource=https%3A%2F%2Fstorage.azure.com%2F&api-version=2019-08-01" | perl -ne 'print $1 if /"access_token"\s*:\s*"([A-Za-z0-9_.-]+)"/')"
[ -n "$dt3d_token" ]
trap 'unset dt3d_token' EXIT
blobcurl() { printf 'header = "Authorization: Bearer %s"
' "$dt3d_token" | curl --config - --silent --show-error --max-time 10 --header 'x-ms-version: 2023-11-03' "$@"; }
blobcurl --fail "$url" --dump-header "$work/before.headers" --output "$work/before.json"
if grep -qiE '^(x-ms-meta-|x-ms-tag-count: [1-9]|Content-Encoding:|Content-Language:|Content-Disposition:|Cache-Control:)' "$work/before.headers"; then echo UNSUPPORTED_BLOB_PROPERTIES; exit 1; fi
dt3d_etag="$(perl -ne 'print $1 if /^ETag:\s*("[^"\r\n]+")/i' "$work/before.headers")"
[ -n "$dt3d_etag" ]
dotnet "$work/editor/RenameProdHighscore.dll" "$work/before.json" "$work/candidate.json"
printf 'IF_MATCH=%s
' "$dt3d_etag"
if ! dt3d_status="$(blobcurl --request PUT "$url" --header "If-Match: $dt3d_etag" --header 'x-ms-blob-type: BlockBlob' --header 'Content-Type: application/json' --data-binary "@$work/candidate.json" --dump-header "$work/put.headers" --output "$work/put.body" --write-out '%{http_code}')"; then echo WRITE_UNCONFIRMED_NO_RETRY; exit 1; fi
printf 'PUT_HTTP=%s
' "$dt3d_status"
[ "$dt3d_status" = 201 ] || { echo WRITE_REJECTED_OR_UNCONFIRMED_NO_RETRY; exit 1; }
dt3d_saved="$(perl -ne 'print $1 if /^ETag:\s*("[^"\r\n]+")/i' "$work/put.headers")"
printf 'SAVED_ETAG=%s
' "$dt3d_saved"
blobcurl --fail "$url" --header "If-Match: $dt3d_saved" --output "$work/verified.json"
cmp "$work/candidate.json" "$work/verified.json"
echo VERIFIED_EXACT_BLOB_NAME_ERIKB_RANK4_SCORE4000
sha256sum "$work/verified.json"
