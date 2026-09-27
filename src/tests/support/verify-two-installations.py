#!/usr/bin/env python3
"""Verify two installed iPhone apps show identical persisted rows after an owned API restart."""
import argparse, json, os, pathlib, signal, subprocess, time, urllib.request
from urllib.parse import urlsplit
p = argparse.ArgumentParser()
p.add_argument('--state-file', required=True)
p.add_argument('--app', required=True)
p.add_argument('--devices', nargs=2, required=True)
p.add_argument('--output-dir', required=True)
a = p.parse_args()
state_file = pathlib.Path(a.state_file); before = json.loads(state_file.read_text()); origin = before['origin']
assert urlsplit(origin).hostname in ('127.0.0.1', 'localhost', '::1') and urlsplit(origin).scheme == 'http'
assert before['container'].startswith('dt3d-owned-') and len(set(a.devices)) == 2
output = pathlib.Path(a.output_dir); output.mkdir(parents=True, exist_ok=True)

def get():
    with urllib.request.urlopen(origin + '/api/v1/highscores', timeout=8) as response:
        data = json.load(response)
        return {key: data[key] for key in ('revision', 'entries')}

expected = get(); assert expected['entries'] and expected['revision'] != 'empty', 'Publish from the first app before checking persistence'
os.kill(before['ownerPid'], signal.SIGUSR1)
for _ in range(100):
    after = json.loads(state_file.read_text())
    if after['restarts'] > before['restarts'] and after['apiPid'] != before['apiPid']: break
    time.sleep(.1)
else: raise RuntimeError('Owned API did not restart')
assert get() == expected
installations = []
for index, device in enumerate(a.devices):
    subprocess.run(['xcrun','simctl','boot',device], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(['xcrun','simctl','bootstatus',device,'-b'], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(['xcrun','simctl','install',device,a.app], check=True)
    folder = pathlib.Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'com.hyldenbrandt.donkeytrump3d','data'], text=True).strip())
    snapshot = folder / 'Documents/highscore-integration-snapshot.json'
    snapshot.unlink(missing_ok=True)
    subprocess.run(['xcrun','simctl','terminate',device,'com.hyldenbrandt.donkeytrump3d'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(['xcrun','simctl','launch',device,'com.hyldenbrandt.donkeytrump3d','-highscoreIntegration','-highscoreLocalOrigin',origin,'-highscoreUITest','-highscoreOpenOnLaunch'], check=True, stdout=subprocess.DEVNULL)
    for _ in range(300):
        if snapshot.exists(): break
        time.sleep(.1)
    else: raise RuntimeError('App did not display a fresh integration snapshot')
    observed = json.loads(snapshot.read_text()); assert observed == expected
    (output / f'installation-{index+1}.json').write_text(json.dumps(observed, indent=2))
    time.sleep(.3) # Let the mounted list finish its first layout before visual evidence.
    subprocess.run(['xcrun','simctl','io',device,'screenshot',str(output / f'installation-{index+1}.png')], check=True, stdout=subprocess.DEVNULL)
    installations.append({'device':device,'dataContainer':str(folder),'revision':observed['revision'],'rows':len(observed['entries'])})
assert installations[0]['dataContainer'] != installations[1]['dataContainer']
assert get() == expected
record = {'origin':origin,'container':before['container'],'apiPidBefore':before['apiPid'],'apiPidAfter':after['apiPid'],'installations':installations,'result':'PASS'}
(output / 'two-installations.json').write_text(json.dumps(record, indent=2))
print(json.dumps(record, indent=2))
