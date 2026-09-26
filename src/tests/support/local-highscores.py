#!/usr/bin/env python3
"""Own a unique private emulator container and loopback API; SIGUSR1 restarts only this API.
Requires an already running local Azurite. No Azure resources or shared scores are touched.
"""
import argparse, base64, datetime, hashlib, hmac, json, os, pathlib, signal, socket, subprocess, time, urllib.request, urllib.error, uuid
from urllib.parse import urlsplit

parser = argparse.ArgumentParser()
parser.add_argument('--state-file', required=True)
parser.add_argument('--azurite-endpoint', default='http://127.0.0.1:10000/devstoreaccount1')
args = parser.parse_args()
endpoint = urlsplit(args.azurite_endpoint)
if endpoint.scheme != 'http' or endpoint.hostname not in ('127.0.0.1', 'localhost', '::1') or endpoint.path != '/devstoreaccount1' or endpoint.query or endpoint.fragment or endpoint.username:
    raise SystemExit('A loopback Azurite endpoint is required')
root = pathlib.Path(__file__).resolve().parents[3]
state_path = pathlib.Path(args.state_file).resolve(); state_path.parent.mkdir(parents=True, exist_ok=True)
container = 'dt3d-owned-' + uuid.uuid4().hex
key = 'Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==' # public emulator key

def container_request(method):
    date = datetime.datetime.now(datetime.timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT')
    path = endpoint.path + '/' + container
    canonical = method + '\n' * 12 + f'x-ms-date:{date}\nx-ms-version:2025-11-05\n/devstoreaccount1{path}\nrestype:container'
    signature = base64.b64encode(hmac.new(base64.b64decode(key), canonical.encode(), hashlib.sha256).digest()).decode()
    request = urllib.request.Request(args.azurite_endpoint + '/' + container + '?restype=container', method=method,
        headers={'x-ms-date': date, 'x-ms-version': '2025-11-05', 'Authorization': 'SharedKey devstoreaccount1:' + signature})
    with urllib.request.urlopen(request, timeout=6) as response:
        if response.status not in (201, 202): raise RuntimeError('Unexpected emulator status')

with socket.socket() as probe:
    probe.bind(('127.0.0.1', 0)); port = probe.getsockname()[1]
origin = f'http://127.0.0.1:{port}'
dotnet = str(pathlib.Path.home() / '.dotnet/dotnet')
subprocess.run([dotnet, 'build', 'src/backend', '--no-restore'], cwd=root, check=True, stdout=subprocess.DEVNULL)
env = os.environ.copy()
env.update(ASPNETCORE_ENVIRONMENT='Development', ASPNETCORE_URLS=origin, Highscores__UseAzurite='true',
           Highscores__AzuriteEndpoint=args.azurite_endpoint, Highscores__ContainerName=container)
log = open(state_path.with_suffix('.api.log'), 'a')
api = None
stopping = False
restart = False
restarts = 0

def start():
    global api
    api = subprocess.Popen([dotnet, str(root / 'src/backend/bin/Debug/net10.0/DonkeyTrump.Highscores.Api.dll')], cwd=root / 'src/backend', env=env, stdout=log, stderr=log)
    for _ in range(100):
        if api.poll() is not None: raise RuntimeError('Owned API exited; inspect its log')
        try:
            with urllib.request.urlopen(origin + '/health/live', timeout=.2) as response:
                if response.status == 200: break
        except (OSError, urllib.error.URLError): time.sleep(.1)
    else: raise RuntimeError('Owned API readiness timeout')
    state_path.write_text(json.dumps({'origin': origin, 'container': container, 'azuriteEndpoint': args.azurite_endpoint,
                                     'ownerPid': os.getpid(), 'apiPid': api.pid, 'restarts': restarts}, indent=2))

def stop_api():
    if api and api.poll() is None:
        api.terminate()
        try: api.wait(timeout=10)
        except subprocess.TimeoutExpired: api.kill(); api.wait()

def handle(signum, _):
    global stopping, restart
    if signum == signal.SIGUSR1: restart = True
    else: stopping = True

for number in (signal.SIGTERM, signal.SIGINT, signal.SIGUSR1): signal.signal(number, handle)
container_request('PUT')
try:
    start()
    print(json.dumps({'origin': origin, 'stateFile': str(state_path)}), flush=True)
    while not stopping:
        if restart:
            stop_api(); restarts += 1; start(); restart = False
        time.sleep(.1)
finally:
    stop_api(); log.close(); container_request('DELETE')
