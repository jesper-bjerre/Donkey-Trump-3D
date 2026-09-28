import urllib.request,urllib.error,json,secrets,base64,uuid,subprocess,shlex
import sys
env=sys.argv[1];assert env in ["dev","prod"]
suffix="d" if env=="dev" else "p"
port="49155" if env=="dev" else "49156"
origin=f"https://donkeytrump-api-{suffix}.azurewebsites.net"
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args):return None
opener=urllib.request.build_opener(NoRedirect)
def operator(args):
 cmd="cd /home/site/wwwroot && dotnet DonkeyTrump.Highscores.Api.dll moderation "+shlex.join(args+["--target",env])
 result=subprocess.run(["ssh","-o","BatchMode=yes","-S","/tmp/dt3d-"+env+"-control","-p"+port,"root@127.0.0.1","bash -lc "+shlex.quote(cmd)],capture_output=True,text=True,timeout=60)
 if result.returncode:raise RuntimeError("Operator command failed: "+args[0])
 return result.stdout
operator(["inspect"])
with opener.open(origin+"/api/v1/highscores",timeout=10) as r:before=json.load(r)
run=str(uuid.uuid4());credential=base64.urlsafe_b64encode(secrets.token_bytes(32)).decode().rstrip("=")
body={"submissionId":run,"displayName":"Release Check","score":2600,"levelReached":1}
print(json.dumps({"testSubmissionId":run,"testScore":2600}),flush=True)
request=urllib.request.Request(origin+"/api/v1/highscores",data=json.dumps(body).encode(),headers={"Content-Type":"application/json","Authorization":"Bearer "+credential},method="POST")
# One explicit request only, never replay a possibly committed submission.
with opener.open(request,timeout=10) as r:
 result=json.load(r);assert r.status==200 and r.headers.get("Cache-Control")=="no-store"
 assert result["outcome"] in ["ranked","notQualified"]
print(json.dumps({"environment":env,"postStatus":200,"outcome":result["outcome"]}),flush=True)
with opener.open(origin+"/api/v1/highscores",timeout=10) as r: persisted=json.load(r)
assert any(e["entryId"]==run and e["score"]==2600 for e in persisted["entries"])
print(json.dumps({"readbackStatus":200,"persistedScore":2600}),flush=True)
if result["outcome"]=="ranked":operator(["remove","--entry-id",run,"--operation-id",str(uuid.uuid4()),"--apply"])
with opener.open(origin+"/api/v1/highscores",timeout=10) as r:after=json.load(r)
assert before["entries"]==after["entries"] and len(after["entries"])>=10
assert run not in {e["entryId"] for e in after["entries"]}
print(json.dumps({"result":"PASS","credentialedPost":200,"outcome":result["outcome"],"rankedEntriesRestored":True,"syntheticRankedRows":0,"entries":len(after["entries"])}))
