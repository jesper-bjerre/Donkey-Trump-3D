import subprocess,shlex,json,hashlib,zipfile,sys
from pathlib import Path
env,commit,artifact=sys.argv[1:]
port="49155" if env=="dev" else "49156"
manifest=json.loads((Path(artifact)/"release.json").read_text());assert manifest["commit"]==commit
assert hashlib.sha256((Path(artifact)/"app.zip").read_bytes()).hexdigest()==manifest["sha256"]
with zipfile.ZipFile(Path(artifact)/"app.zip") as z:
 expected={name:hashlib.sha256(z.read(name)).hexdigest() for name in z.namelist() if not name.endswith("/")}
assert all(not name.startswith("/") and ".." not in Path(name).parts for name in expected)
cmd="cd /home/site/wwwroot && cat deployment.json && sha256sum -- "+shlex.join(sorted(expected))
r=subprocess.run(["ssh","-o","BatchMode=yes","-S","/tmp/dt3d-"+env+"-control","-p"+port,"root@127.0.0.1","bash -lc "+shlex.quote(cmd)],capture_output=True,text=True,timeout=30)
assert r.returncode==0,"SSH artifact verification unavailable"
lines=r.stdout.splitlines();actual=json.loads(next(l for l in lines if l.startswith("{")))
assert actual["commit"]==commit,"Loaded source revision differs from pipeline"
observed={line[66:]:line[:64] for line in lines if len(line)>66 and line[64:66]=="  "}
assert observed==expected,"Live artifact files differ from verified ZIP"
print(json.dumps({"environment":env,"commit":commit,"zipSha256":manifest["sha256"],"assemblySha256":expected["DonkeyTrump.Highscores.Api.dll"],"allArtifactFilesVerified":len(expected)}))
