import os,sys,json,uuid,subprocess,socket,time,urllib.request
from pathlib import Path
root=Path.cwd();sys.path.insert(0,str(root/'src/tests/support'))
from azurite_owned import OwnedAzurite
container='dt3d-test-score2600-'+uuid.uuid4().hex[:12];storage=OwnedAzurite('http://127.0.0.1:10000/devstoreaccount1',container)
env=os.environ.copy();env.update(ASPNETCORE_ENVIRONMENT='Test',Highscores__UseAzurite='true',Highscores__AzuriteEndpoint=storage.endpoint,Highscores__ContainerName=container,Highscores__BlobName='global-v1.json',Moderation__Maintenance='true')
dll=root/'src/backend/bin/Release/net10.0/DonkeyTrump.Highscores.Api.dll'
def op(*a):
 p=subprocess.run(['dotnet',str(dll),'moderation',*a,'--target','local'],cwd=root/'src/backend',env=env,capture_output=True,text=True,timeout=20);assert p.returncode==0,p.stdout
 return json.loads(p.stdout.splitlines()[-1])
api=None;created=False
try:
 storage.request('PUT');created=True
 storage.request('PUT','global-v1.json',json.dumps({'schemaVersion':1,'nextSequence':1,'entries':[]}).encode())
 read=op('inspect');op('migrate','--expected-etag',read['etag'],'--apply');env['Moderation__Maintenance']='false'
 with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
 origin=f'http://127.0.0.1:{port}';env['ASPNETCORE_URLS']=origin
 with open('/tmp/dt3d-score2600-isolated-backend.log','w') as log:
  api=subprocess.Popen(['dotnet',str(dll)],cwd=root/'src/backend',env=env,stdout=log,stderr=log)
  for _ in range(100):
   try:
    with urllib.request.urlopen(origin+'/health/live',timeout=.2):break
   except OSError:time.sleep(.1)
  else:raise RuntimeError('backend not ready')
  run=str(uuid.uuid4());testenv=os.environ.copy();testenv.update(TEST_RUNNER_DT3D_SCORE_TEST_ORIGIN=origin,TEST_RUNNER_DT3D_SCORE_TEST_RUN=run)
  with open('/tmp/dt3d-score2600-updated-ui.log','w') as testlog:
   p=subprocess.run(['xcodebuild','test','-project','src/DonkeyTrump3D.xcodeproj','-scheme','DonkeyTrump3D Local','-destination','platform=iOS Simulator,id=31C13DEB-E27B-46F9-8598-BB36342D54A6','-only-testing:DonkeyTrump3DUITests/HighscoreRealSubmissionUITests/test2600PointSubmissionThroughRealBackend','-resultBundlePath','/tmp/dt3d-score2600-updated-ui.xcresult'],cwd=root,env=testenv,stdout=testlog,stderr=subprocess.STDOUT,timeout=180)
   assert p.returncode==0,'UI test failed'
  with urllib.request.urlopen(origin+'/api/v1/highscores',timeout=10) as r:rows=json.load(r)['entries']
  row=next(e for e in rows if e['entryId']==run);assert row['score']==2600 and row['rank']==1
  print(json.dumps({'result':'PASS','backend':'current Release DLL','storage':container,'origin':origin,'submissionId':run,'score':row['score'],'rank':row['rank'],'independentReadback':True}),flush=True)
finally:
 if api:api.terminate();api.wait(timeout=10)
 if created:storage.request('DELETE');print('Owned isolated test container removed',flush=True)
