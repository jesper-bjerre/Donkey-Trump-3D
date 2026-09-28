import urllib.request, urllib.error, json, uuid, secrets, base64, subprocess, shlex
origin="https://donkeytrump-api-d.azurewebsites.net"
credential=base64.urlsafe_b64encode(secrets.token_bytes(32)).decode().rstrip("=")
run=str(uuid.uuid4());report=str(uuid.uuid4())
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args):return None
opener=urllib.request.build_opener(NoRedirect)
def request(method,path,body=None,auth=True):
 headers={"Authorization":"Bearer "+credential} if auth else {}
 if body is not None:headers["Content-Type"]="application/json"
 req=urllib.request.Request(origin+path,data=None if body is None else json.dumps(body).encode(),headers=headers,method=method)
 try:
  with opener.open(req,timeout=10) as r:return r.status,json.load(r),r.headers.get("Cache-Control")
 except urllib.error.HTTPError as e:return e.code,json.load(e),e.headers.get("Cache-Control")
def operator(*args):
 cmd="bash -lc "+shlex.quote("dotnet /home/site/wwwroot/DonkeyTrump.Highscores.Api.dll moderation "+shlex.join(args)+" --target dev")
 result=subprocess.run(["ssh","-o","BatchMode=yes","-S","/tmp/dt3d-dev-control","-p49155","root@127.0.0.1",cmd],capture_output=True,text=True,timeout=30)
 if result.returncode:raise RuntimeError("Operator command failed: "+args[0])
 return [json.loads(line) for line in result.stdout.splitlines() if line.startswith("{")]
operator("inspect")
print(json.dumps({"testSubmissionId":run,"testReportId":report}),flush=True)
status,before,_=request("GET","/api/v1/highscores",auth=False);assert status==200
beforeids={e["entryId"] for e in before["entries"]}
saved=False
try:
 status,result,cache=request("POST","/api/v1/highscores",{"submissionId":run,"displayName":"Release Check","score":5000,"levelReached":1})
 assert status==200 and result["outcome"]=="ranked" and cache=="no-store";saved=True
 status,receipt,cache=request("POST","/api/v1/highscore-reports",{"reportId":report,"entryId":run,"reason":"other"})
 assert status==201 and receipt["status"]=="pending" and cache=="no-store"
 operation=str(uuid.uuid4())
 operator("acknowledge","--report-id",report,"--operation-id",operation)
 operator("acknowledge","--report-id",report,"--operation-id",operation,"--apply")
 operation=str(uuid.uuid4())
 operator("resolve","--report-id",report,"--decision","remove-and-block","--operation-id",operation)
 operator("resolve","--report-id",report,"--decision","remove-and-block","--operation-id",operation,"--apply")
 status,receipt,cache=request("GET","/api/v1/highscore-reports/"+report)
 assert status==200 and receipt["status"]=="resolved" and receipt["disposition"]=="removedAndBlocked" and receipt["acknowledgedAtUtc"] and cache=="no-store"
 status,problem,_=request("POST","/api/v1/highscores",{"submissionId":str(uuid.uuid4()),"displayName":"Release Check","score":6000,"levelReached":1})
 assert status==403 and problem["code"]=="publication_blocked"
 status,after,_=request("GET","/api/v1/highscores",auth=False)
 assert status==200 and len(after["entries"])>=10 and run not in {e["entryId"] for e in after["entries"]}
 assert beforeids.issubset({e["entryId"] for e in after["entries"]})
 print(json.dumps({"result":"PASS","environment":"DEV","publication":True,"report":True,"operatorAcknowledgement":True,"removalAndBlock":True,"privateReceipt":True,"originalRowsPreserved":True,"minimumTen":True,"submissionId":run,"reportId":report}))
finally:
 if saved:operator("remove","--entry-id",run,"--operation-id",str(uuid.uuid4()),"--apply")
