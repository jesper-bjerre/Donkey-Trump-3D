#!/usr/bin/env bash
# Run manually in the target App Service SSH session with a reviewed staging folder.
set -euo pipefail
umask 077

case "${WEBSITE_SITE_NAME:-}" in
  donkeytrump-api-p|donkeytrump-api-d) ;;
  *) printf '%s\n' 'Run inside the matching Azure App Service SSH session.' >&2; exit 1 ;;
esac
[ "$#" = 2 ] || { printf '%s\n' 'Usage: bash install-highscore-admin.sh STAGING_DIRECTORY EXPECTED_DLL_SHA256' >&2; exit 1; }
staging="$(cd -- "$1" && pwd)"
expected="$2"
[[ "$expected" =~ ^[a-f0-9]{64}$ ]] || { printf '%s\n' 'Invalid SHA256.' >&2; exit 1; }
printf '%s  %s\n' "$expected" "$staging/DonkeyTrump.Highscores.Api.dll" | sha256sum --check --status
[ -f "$staging/highscore-admin.sh" ]

root=/home/site/tools/highscore-admin
revision="$root/$expected"
mkdir -p -- "$root"
# An existing revision is immutable. Never replace the running HTTP application's files.
mkdir -- "$revision"
cp -- /home/site/wwwroot/*.dll "$revision/"
cp -- /home/site/wwwroot/DonkeyTrump.Highscores.Api.deps.json /home/site/wwwroot/DonkeyTrump.Highscores.Api.runtimeconfig.json "$revision/"
if [ -d /home/site/wwwroot/runtimes ]; then cp -R -- /home/site/wwwroot/runtimes "$revision/"; fi
cp -- "$staging/DonkeyTrump.Highscores.Api.dll" "$staging/highscore-admin.sh" "$revision/"
printf '%s  %s\n' "$expected" "$revision/DonkeyTrump.Highscores.Api.dll" | sha256sum --check --status
# Keep prior revisions available. Switching this link affects manual invocations only.
ln -s -- "$revision" "$root/current.next"
mv -Tf -- "$root/current.next" "$root/current"
printf '%s\n' 'Installed. Manual command:' 'bash /home/site/tools/highscore-admin/current/highscore-admin.sh help'
