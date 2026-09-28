using System.Diagnostics;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace DonkeyTrump.Highscores;

public static class HighscoreEndpoints
{
    public static void MapHighscores(this WebApplication app)
    {
        // Public snapshots have the same contract in both API versions.
        foreach (var route in new[] { "/api/v1/highscores", "/api/v2/highscores" })
        app.MapGet(route, async (HttpContext context, IHighscoreStore store) => {
            try { return Results.Json(await store.ReadAsync(context.RequestAborted), HighscoreJson.Options); }
            catch (HighscoreFailure error) { return Problem(error); }
            catch (Exception) { return Problem(new(500, "internal_error", "Highscores are unavailable")); }
        }).RequireRateLimiting("highscore-reads");

        app.MapPost("/api/v1/highscores", async (HttpContext context, IHighscoreStore store, IOptions<HighscoreOptions> options, TimeProvider clock) => {
            using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(options.Value.OperationTimeoutSeconds), clock);
            using var linked = CancellationTokenSource.CreateLinkedTokenSource(context.RequestAborted, deadline.Token);
            try {
                var request = context.Request;
                if (!string.Equals(request.ContentType?.Split(';')[0].Trim(), "application/json", StringComparison.OrdinalIgnoreCase))
                    return Problem(new(415, "unsupported_media_type", "Use application/json"));
                if (request.ContentLength > 4096) return Problem(new(413, "payload_too_large", "Submission is too large"));
                byte[] body;
                try { body = await BlobHighscoreStore.BoundedRead(request.Body, 4096, linked.Token); }
                catch (HighscoreFailure) { return Problem(new(413, "payload_too_large", "Submission is too large")); }
                using var json = JsonDocument.Parse(body, new JsonDocumentOptions { MaxDepth = 16 });
                var submission = HighscoreValidation.Parse(json.RootElement);
                return Results.Json(await store.SubmitAsync(submission, linked.Token), HighscoreJson.Options);
            } catch (JsonException) { return Problem(HighscoreFailure.Malformed()); }
            catch (HighscoreFailure error) { return Problem(error); }
            catch (OperationCanceledException) { return Problem(new(503, "operation_timed_out", "Highscores timed out")); }
            catch (Exception) { return Problem(new(500, "internal_error", "Highscores are unavailable")); }
        }).RequireRateLimiting("highscore-posts");
    }

    public static IResult Problem(HighscoreFailure error) => Results.Problem(type: "about:blank", title: error.Title,
        statusCode: error.Status, extensions: new Dictionary<string, object?> {
            ["code"] = error.Code, ["errors"] = error.Errors, ["traceId"] = Activity.Current?.Id
        }.Where(kv => kv.Value is not null).ToDictionary(kv => kv.Key, kv => kv.Value));
}
