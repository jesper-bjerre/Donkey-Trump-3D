# Select the iOS backend in Xcode

Open `src/DonkeyTrump3D.xcodeproj`. Choose a shared scheme beside the Run button,
choose an iPhone simulator or device, then Run (Cmd-R). No launch arguments or
source edits are needed to switch environment.

| Scheme | Run configuration | Highscore backend |
|---|---|---|
| `DonkeyTrump3D Local` | `Debug Local` | `http://127.0.0.1:5281` |
| `DonkeyTrump3D DEV` | `Debug` | `https://donkeytrump-api-d.azurewebsites.net` |
| `DonkeyTrump3D PROD` | `Debug PROD` | `https://donkeytrump-api-p.azurewebsites.net` |
| `DonkeyTrump3D` (existing) | `Debug` | Same as DEV |

Local is configured for the iPhone simulator: its loopback address reaches the
Mac. On a physical iPhone, loopback points to the phone, so use DEV or PROD.
LAN HTTP addresses are not accepted by the existing loopback-only development
policy. All schemes install the same app and retain its local personal best.
PROD runs use the real public list; submitting a name/score publishes it there.

Archive and Profile use **Release with PROD** in every shared scheme. Test uses
the existing Debug configuration and test fixtures/integration harness. The
scheme's Run environment does not retarget automated tests. Release contains no
Debug fixtures or integration overrides and has no local HTTP ATS exception.

The three [xcconfig files](../src/Configuration/) own `HIGHSCORE_API_BASE_URL`.
The app reads the expanded value from its built Info.plist. To change the local
port, edit `Backend-Local.xcconfig` and start the API on the matching port. Preserve
the `:/$()/` notation: `$()` expands to nothing and prevents `//` being interpreted
as an xcconfig comment. HTTPS origins contain no credentials.

## Start the local backend

From the repository root, restore the pinned .NET SDK's backend dependencies once:

```sh
~/.dotnet/dotnet restore src/backend
```

In terminal A, start the storage emulator on a free port:

```sh
DT3D_AZURITE_DATA=$(mktemp -d /tmp/dt3d-highscores-azurite.XXXXXX)
npx --yes --package azurite@3.37.0 azurite-blob \
  --blobHost 127.0.0.1 --blobPort 10000 \
  --location "$DT3D_AZURITE_DATA" --silent --disableTelemetry
```

In terminal B:

```sh
python3 src/tests/support/local-highscores.py \
  --port 5281 --state-file /tmp/dt3d-local-api.json
```

Wait for the helper to print `http://127.0.0.1:5281`, then run the Local scheme in
the simulator and open Highscores. Each helper session owns a new private emulator
container. Ctrl-C stops its API and deletes that container's scores; it never
touches Azure. Stop Azurite separately with Ctrl-C. Without `--port`, the helper
still selects a free port for the existing integration tests.

If 5281 is occupied, stop only your previous helper or select another local port
in both the command and xcconfig. Do not terminate unrelated processes. To check
the API directly:

```sh
curl --fail http://127.0.0.1:5281/health/live
curl --fail http://127.0.0.1:5281/api/v1/highscores
```

The game remains playable when the selected backend is stopped or unavailable.
Highscores report the existing unavailable/timeout state. For the complete test
harness, see the [highscore quickstart](../specs/001-global-highscores/quickstart.md).
Backend delivery is described in the [deployment guide](backend-deployment.md).
