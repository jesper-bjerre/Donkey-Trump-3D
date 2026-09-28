#!/usr/bin/env python3
"""Owned loopback-only API -> report -> private operator -> receipt/migration smoke."""
import argparse
import base64
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'src/tests/support'))
from azurite_owned import OwnedAzurite


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--azurite-endpoint', default='http://127.0.0.1:10000/devstoreaccount1')
    args = parser.parse_args()
    storage = OwnedAzurite(args.azurite_endpoint, 'highscores-release-validation')
    subprocess.run(['dotnet','build','src/backend','-c','Release','--nologo'],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
    dll = ROOT / 'src/backend/bin/Release/net10.0/DonkeyTrump.Highscores.Api.dll'
    environment = os.environ.copy()
    environment.update(ASPNETCORE_ENVIRONMENT='Test',Highscores__UseAzurite='true',
                       Highscores__AzuriteEndpoint=args.azurite_endpoint,Highscores__ContainerName=storage.container,
                       Highscores__BlobName='global-v1.json',Moderation__Maintenance='true')
    api = None
    created = False
    def command(*arguments):
        result = subprocess.run(['dotnet',str(dll),'moderation',*arguments,'--target','local'],cwd=ROOT/'src/backend',
                                env=environment,capture_output=True,text=True,timeout=20)
        if result.returncode: raise RuntimeError('Owned operator command failed: ' + result.stdout.strip())
        return [json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')][-1]
    try:
        storage.request('PUT')  # 409 refuses an existing fixture; never reset someone else's data.
        created = True
        storage.request('PUT','global-v1.json',json.dumps({'schemaVersion':1,'nextSequence':1,'entries':[]}).encode())
        initial = command('inspect')
        migrated = command('migrate','--expected-etag',initial['etag'],'--apply')
        assert migrated['schemaVersion'] == 2
        environment['Moderation__Maintenance'] = 'false'
        with socket.socket() as probe:
            probe.bind(('127.0.0.1',0)); port = probe.getsockname()[1]
        origin = f'http://127.0.0.1:{port}'
        environment['ASPNETCORE_URLS'] = origin
        with tempfile.TemporaryFile() as log:
            api = subprocess.Popen(['dotnet',str(dll)],cwd=ROOT/'src/backend',env=environment,stdout=log,stderr=log)
            for _ in range(100):
                if api.poll() is not None: raise RuntimeError('Owned API exited')
                try:
                    with urllib.request.urlopen(origin+'/health/live',timeout=.2): break
                except (OSError,urllib.error.URLError): time.sleep(.1)
            else: raise RuntimeError('Owned API did not become ready')
            producer = base64.urlsafe_b64encode(os.urandom(32)).decode().rstrip('=')
            reporter = base64.urlsafe_b64encode(os.urandom(32)).decode().rstrip('=')
            def request(path, body=None, credential=None):
                headers = {'Content-Type':'application/json'}
                if credential: headers['Authorization'] = 'Bearer '+credential
                req = urllib.request.Request(origin+path,data=None if body is None else json.dumps(body).encode(),headers=headers)
                try: response = urllib.request.urlopen(req,timeout=8)
                except urllib.error.HTTPError as error: response = error
                with response: return response.status,json.load(response)
            score = {'submissionId':str(uuid.uuid4()),'displayName':'Smoke Player','score':5000,'levelReached':1}
            status,saved = request('/api/v1/highscores',score,producer); assert status == 200 and saved['outcome']=='ranked'
            report_id = str(uuid.uuid4())
            status,_ = request('/api/v1/highscore-reports',{'reportId':report_id,'entryId':score['submissionId'],'reason':'other'},reporter); assert status==201
            command('acknowledge','--report-id',report_id,'--operation-id',str(uuid.uuid4()),'--apply')
            status,receipt = request('/api/v1/highscore-reports/'+report_id,credential=reporter); assert status==200 and receipt['status']=='acknowledged'
            command('resolve','--report-id',report_id,'--decision','remove-and-block','--operation-id',str(uuid.uuid4()),'--apply')
            status,receipt = request('/api/v1/highscore-reports/'+report_id,credential=reporter); assert status==200 and receipt['disposition']=='removedAndBlocked'
            score.update(submissionId=str(uuid.uuid4()),displayName='Changed Name')
            status,problem = request('/api/v1/highscores',score,producer); assert status==403 and problem['code']=='publication_blocked'
            status,snapshot = request('/api/v1/highscores'); assert status==200 and len(snapshot['entries'])==10
            status,_ = request('/api/v1/highscore-reports/'+report_id,credential=producer); assert status==404
            print('PASS: owned schema1 migration, v1 publication, report, operator acknowledgement/removal/block, private receipt and minimum-ten continuity.')
    finally:
        if api and api.poll() is None:
            api.terminate()
            try: api.wait(timeout=10)
            except subprocess.TimeoutExpired: api.kill(); api.wait()
        if created: storage.request('DELETE')

if __name__ == '__main__': main()
