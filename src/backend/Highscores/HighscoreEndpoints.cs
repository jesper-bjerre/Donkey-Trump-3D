using System.Diagnostics;

namespace DonkeyTrump.Highscores;

public static class HighscoreEndpoints
{
    public static void MapHighscores(this WebApplication app, string prefix = "")
    {
        app.MapGet(prefix + "/api/v1/highscores",(HttpContext context,IHighscoreStore store)=>ModerationEndpoints.Guard(async()=>
                Results.Json(await CaptureOptions.Store(context,store,prefix != "").ReadAsync(context.RequestAborted),HighscoreJson.Options))).RequireRateLimiting("highscore-reads");
        app.MapPost(prefix + "/api/v1/highscores",(HttpContext context,IModerationStore store,TimeProvider clock)=>ModerationEndpoints.Guard(async()=> {
            using var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(6),clock);
            using var linked=CancellationTokenSource.CreateLinkedTokenSource(context.RequestAborted,deadline.Token);
            var hash=ModerationEndpoints.Credential(context);
            using var json=await ModerationEndpoints.Body(context.Request,linked.Token);
            return Results.Json(await CaptureOptions.Store(context,store,prefix != "").PublishAsync(HighscoreValidation.Parse(json.RootElement),hash,linked.Token),HighscoreJson.Options);
        })).RequireRateLimiting("highscore-posts");
    }
    public static IResult Problem(HighscoreFailure error) => Results.Problem(type:"about:blank",title:error.Title,statusCode:error.Status,
        extensions:new Dictionary<string,object?> { ["code"]=error.Code,["errors"]=error.Errors,["traceId"]=Activity.Current?.Id }
            .Where(kv=>kv.Value is not null).ToDictionary(kv=>kv.Key,kv=>kv.Value));
}
