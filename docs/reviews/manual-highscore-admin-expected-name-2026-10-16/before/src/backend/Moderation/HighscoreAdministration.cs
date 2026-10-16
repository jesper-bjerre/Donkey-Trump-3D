using System.Globalization;
using System.Text.Json;

namespace DonkeyTrump.Highscores;

/// Manually invoked operator commands; never mapped to HTTP or called by the app.
public static class HighscoreAdministration
{
    private static HighscoreFailure Arguments() => new(400,"operator_arguments_invalid","Invalid highscore administration arguments");
    private static Guid EntryId(Dictionary<string,string> args) =>
        Guid.TryParseExact(args.GetValueOrDefault("--entry-id"),"D",out var id) && id!=Guid.Empty ? id : throw Arguments();
    private static int Rank(Dictionary<string,string> args) =>
        int.TryParse(args.GetValueOrDefault("--rank"),NumberStyles.None,CultureInfo.InvariantCulture,out var rank) && rank is >=1 and <=100
            ? rank : throw Arguments();
    private static string Name(Dictionary<string,string> args)
    {
        var name=HighscoreValidation.NormalizeName(args.GetValueOrDefault("--display-name")) ?? throw Arguments();
        if(!NameModerationPolicy.Allowed(name)) throw new HighscoreFailure(422,"name_rejected","Choose a different name");
        return name;
    }

    public static void ValidateArguments(string command,Dictionary<string,string> args)
    {
        var allowed=command=="entry"
            ? new[]{"command","--target","--entry-id","--rank"}
            : new[]{"command","--target","--entry-id","--display-name","--expected-etag","--apply"};
        if(command is not ("entry" or "rename") || args.Keys.Any(key=>!allowed.Contains(key))) throw Arguments();
        if(command=="entry") {
            if(args.ContainsKey("--entry-id")==args.ContainsKey("--rank")) throw Arguments();
            if(args.ContainsKey("--entry-id")) _=EntryId(args);else _=Rank(args);
        } else {
            _=EntryId(args);_=Name(args);
            if(args.TryGetValue("--expected-etag",out var etag) && string.IsNullOrWhiteSpace(etag)) throw Arguments();
        }
    }

    public static HighscoreDocument Rename(HighscoreDocument document,Guid entryId,string displayName)
    {
        document.Validate();
        if(document.SchemaVersion!=2) throw new HighscoreFailure(503,"service_maintenance","Highscores are being maintained");
        var name=Name(new() {["--display-name"]=displayName});
        var entry=Find(document,entryId);
        if(entry.DisplayName==name) return document;
        var renamed=document with {Entries=document.Entries.Select(e=>e.SubmissionId==entryId ? e with {DisplayName=name} : e).ToList()};
        renamed.Validate();return renamed;
    }

    private static StoredEntry Find(HighscoreDocument document,Guid entryId) =>
        document.Entries.FirstOrDefault(e=>e.SubmissionId==entryId) ?? throw new HighscoreFailure(404,"entry_not_found","This stored entry is no longer available");

    public static async Task RunAsync(string command,Dictionary<string,string> args,IModerationStore store,TextWriter output,CancellationToken token)
    {
        ValidateArguments(command,args);
        var read=await store.ReadAggregateAsync(token);
        var document=read.Document;
        var id=args.ContainsKey("--entry-id") ? EntryId(args)
            : HighscoreStarters.Fill(document).Entries.ElementAtOrDefault(Rank(args)-1)?.SubmissionId ?? throw new HighscoreFailure(404,"entry_not_found","This stored entry is no longer available");
        var entry=Find(document,id);
        void Write(object value)=>output.WriteLine(JsonSerializer.Serialize(value,HighscoreJson.Options));
        object View(HighscoreDocument d,string etag) {
            var current=Find(d,id);
            return new {entryId=id,rank=HighscoreStarters.Fill(d).Entries.FindIndex(e=>e.SubmissionId==id)+1,displayName=current.DisplayName,score=current.Score,etag};
        }
        if(command=="entry") {Write(View(document,read.ETag));return;}
        var expected=args.GetValueOrDefault("--expected-etag",read.ETag);
        if(expected!=read.ETag) throw new HighscoreFailure(409,"revision_changed","Refresh the entry before renaming");
        var preview=Rename(document,id,Name(args));
        bool changed=entry.DisplayName!=Find(preview,id).DisplayName;
        Write(new {preview=true,changed,before=View(document,read.ETag),after=View(preview,read.ETag)});
        if(!args.ContainsKey("--apply")) return;
        if(!changed) {Write(new {applied=false,alreadyMatches=true,entry=View(document,read.ETag)});return;}
        // Pin the exact aggregate just inspected. A conflict returns revision_changed;
        // never recompute against a different admin's rename or replay an uncertain write.
        var saved=await store.MutateAsync((current,_)=>Rename(current,id,Name(args)),"operation_unconfirmed",token,expectedETag:expected);
        Write(new {applied=true,entry=View(saved.Document,saved.ETag)});
    }
}
