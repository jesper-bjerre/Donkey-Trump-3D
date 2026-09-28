using System.Text.Json;
using Microsoft.Extensions.Options;

namespace DonkeyTrump.Highscores;

public static class ModerationCommand
{
    private static HighscoreFailure Invalid() => new(400,"operator_arguments_invalid","Invalid operator arguments or target");
    public static Dictionary<string,string> Parse(string[] args)
    {
        if(args.Length==0) throw Invalid();
        var result=new Dictionary<string,string> { ["command"]=args[0] };
        for(int i=1;i<args.Length;i++) {
            var name=args[i];
            if(name is not ("--target" or "--report-id" or "--report-ids" or "--operation-id" or "--entry-id" or "--decision" or "--installation-hash" or "--expected-block-id" or "--expected-etag" or "--apply")) throw Invalid();
            var value=name=="--apply"?"true":++i<args.Length?args[i]:throw Invalid();
            if(value.StartsWith("--") || !result.TryAdd(name,value)) throw Invalid();
        }
        if(!result.ContainsKey("--target")) throw Invalid();return result;
    }
    public static void ValidateTarget(string target,HighscoreOptions o,Func<string,string?> environment)
    {
        if(target=="local") {
            if(!o.UseAzurite || !o.IsValid("Test") || !(o.ContainerName=="highscores-release-validation" || o.ContainerName.StartsWith("dt3d-test-",StringComparison.Ordinal))) throw Invalid();
            return;
        }
        if(target is not ("dev" or "prod") || o.UseAzurite || !o.IsValid("Production")) throw Invalid();
        using var stream=typeof(ModerationCommand).Assembly.GetManifestResourceStream("BackendEnvironments.json") ?? throw Invalid();
        using var inventory=JsonDocument.Parse(stream);
        var entry=inventory.RootElement.GetProperty("environments").GetProperty(target=="dev"?"development":"production");
        if(environment("WEBSITE_SITE_NAME")!=entry.GetProperty("appName").GetString() ||
           string.IsNullOrEmpty(environment("IDENTITY_ENDPOINT")) || string.IsNullOrEmpty(environment("IDENTITY_HEADER")) ||
           o.BlobServiceUri.TrimEnd('/')!="https://"+entry.GetProperty("storageAccount").GetString()+".blob.core.windows.net" ||
           o.ContainerName!="highscores" || o.BlobName!="global-v1.json" || !string.IsNullOrEmpty(o.ManagedIdentityClientId)) throw Invalid();
    }
    private static string Value(Dictionary<string,string> args,string name) => args.GetValueOrDefault(name) ?? throw Invalid();
    private static Guid Id(Dictionary<string,string> args,string name) => Guid.TryParseExact(Value(args,name),"D",out var id) && id!=Guid.Empty?id:throw Invalid();
    public static async Task<int> RunAsync(string[] raw,IConfiguration configuration,TextWriter output,CancellationToken token)
    {
        try {
            var args=Parse(raw);var command=args["command"];
            var options=configuration.GetSection("Highscores").Get<HighscoreOptions>() ?? new();
            var moderation=configuration.GetSection("Moderation").Get<ModerationOptions>() ?? new();
            ValidateTarget(args["--target"],options,Environment.GetEnvironmentVariable);
            if(command is "capture-seed" or "capture-delete") {
                await CaptureCommand.ExecuteAsync(command,args["--target"],args.ContainsKey("--apply"),options,
                    configuration.GetSection("Capture").Get<CaptureOptions>() ?? new(),output,token); return 0;
            }
            var client=options.CreateClient();var clock=TimeProvider.System;
            var store=new BlobHighscoreStore(client,options,clock,moderation:moderation);
            if(command=="initialize") {
                await ModerationMigration.InitializeAsync(client,options,args.ContainsKey("--apply"),output,token);return 0;
            }
            var read=await store.ReadAggregateAsync(token);
            var d=ModerationRetention.Purge(read.Document,clock.GetUtcNow());
            void Write(object value)=>output.WriteLine(JsonSerializer.Serialize(value,HighscoreJson.Options));
            if(command=="inspect") {Write(new {schemaVersion=d.SchemaVersion,etag=read.ETag,entries=d.Entries.Count,reports=d.Reports.Count,removed=d.RemovedSubmissionIds.Count,blocks=d.BlockedInstallations.Count,bytes=d.Serialize().Length});return 0;}
            if(command=="list") {Write(d.Reports.Where(r=>r.Status!="resolved").GroupBy(r=>r.EntryId).Select(g=>new {entryId=g.Key,count=g.Count(),reports=g.Select(r=>new {r.ReportId,r.Status,r.Reason,r.CreatedAtUtc,deadlineUtc=ModerationResponseDeadline.For(r.CreatedAtUtc)})}));return 0;}
            if(command=="show") {var report=d.Reports.FirstOrDefault(r=>r.ReportId==Id(args,"--report-id")) ?? throw new HighscoreFailure(404,"report_not_found","Report not found");Write(report);return 0;}
            if(command=="show-block") {Write(d.BlockedInstallations.Where(b=>b.InstallationHash==Value(args,"--installation-hash")));return 0;}
            if(command=="migrate") {
                var expected=Value(args,"--expected-etag");
                if(expected!=read.ETag) throw new HighscoreFailure(409,"revision_changed","Aggregate revision changed");
                if(!args.ContainsKey("--apply")) {Write(new {preview=true,action=command,fromSchema=d.SchemaVersion,toSchema=2});return 0;}
                var result=await ModerationMigration.ApplyAsync(store,client,options,moderation,expected,clock,token);
                Write(new {applied=true,schemaVersion=result.Document.SchemaVersion,etag=result.ETag});return 0;
            }
            Func<HighscoreDocument,DateTimeOffset,HighscoreDocument> transition=command switch {
                "acknowledge" => (current,now)=>ModerationService.Acknowledge(current,Id(args,"--report-id"),Id(args,"--operation-id"),now),
                "resolve" => (current,now)=>ModerationService.Resolve(current,Id(args,"--report-id"),Value(args,"--decision"),Id(args,"--operation-id"),now),
                "remove" => (current,now)=>ModerationService.Remove(current,Id(args,"--entry-id"),Id(args,"--operation-id"),now),
                "unblock" => (current,now)=>ModerationService.Unblock(current,Value(args,"--installation-hash"),Id(args,"--expected-block-id"),Id(args,"--operation-id"),now),
                "dismiss-spam" => (current,now)=>ModerationService.DismissSpam(current,Value(args,"--report-ids").Split(',').Select(v=>Guid.TryParseExact(v,"D",out var id)?id:throw Invalid()).ToArray(),Id(args,"--operation-id"),now),
                "purge-expired" => ModerationRetention.Purge,
                _=>throw Invalid()
            };
            var preview=transition(d,clock.GetUtcNow());
            Write(new {preview=true,action=command,rowsBefore=d.Entries.Count,rowsAfter=preview.Entries.Count,pendingAfter=preview.Reports.Count(r=>r.Status!="resolved"),blocksAfter=preview.BlockedInstallations.Count});
            if(!args.ContainsKey("--apply")) return 0;
            var saved=await store.MutateAsync(transition,"operation_unconfirmed",token);
            if(command=="purge-expired") await ModerationMigration.PurgeBackupAsync(client,options,clock.GetUtcNow(),token);
            Write(new {applied=true,etag=saved.ETag});return 0;
        } catch(HighscoreFailure error) {await output.WriteLineAsync(JsonSerializer.Serialize(new {error.Code,error.Status},HighscoreJson.Options));return 1;}
        catch(Exception) {await output.WriteLineAsync("{\"code\":\"operator_unavailable_or_unconfirmed\"}");return 1;}
    }
}
