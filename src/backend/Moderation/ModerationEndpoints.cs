using System.Text.Json;

namespace DonkeyTrump.Highscores;

public static class ModerationEndpoints
{
    public static string Credential(HttpContext context)
    {
        var values=context.Request.Headers.Authorization;
        return InstallationCredential.Hash(values.Count==1?values[0]:null);
    }
    public static async Task<JsonDocument> Body(HttpRequest request,CancellationToken token)
    {
        if(!string.Equals(request.ContentType?.Split(';')[0].Trim(),"application/json",StringComparison.OrdinalIgnoreCase))
            throw new HighscoreFailure(415,"unsupported_media_type","Use application/json");
        if(request.ContentLength>4096) throw new HighscoreFailure(413,"payload_too_large","Submission is too large");
        byte[] bytes;
        try {bytes=await BlobHighscoreStore.BoundedRead(request.Body,4096,token);}
        catch(HighscoreFailure) {throw new HighscoreFailure(413,"payload_too_large","Submission is too large");}
        return JsonDocument.Parse(bytes,new JsonDocumentOptions {MaxDepth=16});
    }
    public static ReportSubmission Parse(JsonElement body)
    {
        if(body.ValueKind!=JsonValueKind.Object) throw HighscoreFailure.Malformed();
        var seen=new HashSet<string>();
        foreach(var p in body.EnumerateObject()) if(p.Name is not ("reportId" or "entryId" or "reason") || !seen.Add(p.Name)) throw HighscoreFailure.Malformed();
        if(!body.TryGetProperty("reportId",out var r) || r.ValueKind!=JsonValueKind.String || !Guid.TryParseExact(r.GetString(),"D",out var report) || report==Guid.Empty ||
           !body.TryGetProperty("entryId",out var e) || e.ValueKind!=JsonValueKind.String || !Guid.TryParseExact(e.GetString(),"D",out var entry) || entry==Guid.Empty ||
           !body.TryGetProperty("reason",out var why) || why.ValueKind!=JsonValueKind.String || !ModerationReport.ValidReason(why.GetString()!)) throw HighscoreFailure.Malformed();
        return new(report,entry,why.GetString()!);
    }
    public static async Task<IResult> Guard(Func<Task<IResult>> work)
    {
        try {return await work();}
        catch(JsonException) {return HighscoreEndpoints.Problem(HighscoreFailure.Malformed());}
        catch(HighscoreFailure e) {return HighscoreEndpoints.Problem(e);}
        catch(OperationCanceledException) {return HighscoreEndpoints.Problem(new(503,"operation_timed_out","Highscores timed out"));}
        catch(Exception) {return HighscoreEndpoints.Problem(new(500,"internal_error","Highscores are unavailable"));}
    }
    public static void MapModeration(this WebApplication app, string prefix = "")
    {
        app.MapPost(prefix + "/api/v1/highscore-reports",(HttpContext context,IModerationStore store,TimeProvider clock)=>Guard(async()=> {
            using var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(6),clock);
            using var linked=CancellationTokenSource.CreateLinkedTokenSource(context.RequestAborted,deadline.Token);
            var hash=Credential(context);
            using var json=await Body(context.Request,linked.Token);
            var saved=await CaptureOptions.Store(context,store,prefix != "").ReportAsync(Parse(json.RootElement),hash,linked.Token);
            return Results.Json(saved.Receipt,HighscoreJson.Options,statusCode:saved.Created?201:200);
        })).RequireRateLimiting("highscore-reports");
        app.MapGet(prefix + "/api/v1/highscore-reports/{reportId:guid}",(Guid reportId,HttpContext context,IModerationStore store)=>Guard(async()=>
            Results.Json(await CaptureOptions.Store(context,store,prefix != "").ReceiptAsync(reportId,Credential(context),context.RequestAborted),HighscoreJson.Options)))
            .RequireRateLimiting("highscore-reads");
    }
}
