#!/usr/bin/env bash
set -euo pipefail

case "${1:-help}" in
  entry|rename) ;;
  help|--help|-h)
    cat <<'USAGE'
Manual highscore administration (authenticated App Service SSH only)

  bash highscore-admin.sh entry --rank 4
  bash highscore-admin.sh entry --entry-id UUID
  bash highscore-admin.sh rename --entry-id UUID --display-name 'New name'
  bash highscore-admin.sh rename --entry-id UUID --display-name 'New name' --apply

Rename previews by default. --apply writes. To pin an earlier preview, also pass
--expected-etag '"ETAG"'. After operation_unconfirmed, inspect the entry; do not
blindly repeat --apply. Names are printed only in this private operator console.
USAGE
    exit 0 ;;
  *) printf '%s\n' 'Expected entry, rename or help.' >&2; exit 1 ;;
esac

case "${WEBSITE_SITE_NAME:-}" in
  donkeytrump-api-p) target=prod ;;
  donkeytrump-api-d) target=dev ;;
  *) printf '%s\n' 'Run inside the matching Azure App Service SSH session.' >&2; exit 1 ;;
esac

admin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd /home/site/wwwroot
exec dotnet "$admin_dir/DonkeyTrump.Highscores.Api.dll" moderation "$@" --target "$target"
