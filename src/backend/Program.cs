using DonkeyTrump.Highscores;
using Microsoft.Extensions.Options;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;
using Azure.Storage.Blobs;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.AddFilter("Microsoft.AspNetCore", LogLevel.Warning);
builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddSingleton<HighscoreDiagnostics>();
builder.Services.AddOptions<HighscoreOptions>().BindConfiguration("Highscores")
    .Validate(o => o.IsValid(builder.Environment.EnvironmentName), "Invalid highscore service configuration")
    .ValidateOnStart();
builder.Services.AddSingleton(sp => sp.GetRequiredService<IOptions<HighscoreOptions>>().Value.CreateClient());
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddSingleton<IHighscoreStore>(sp => new BlobHighscoreStore(sp.GetRequiredService<BlobServiceClient>(),
    sp.GetRequiredService<IOptions<HighscoreOptions>>().Value, sp.GetRequiredService<TimeProvider>(), diagnostics: sp.GetRequiredService<HighscoreDiagnostics>()));
builder.Services.AddRateLimiter();
builder.Services.AddOptions<RateLimiterOptions>().Configure<IOptions<HighscoreOptions>>((limiter, config) => {
    var limits = config.Value.RateLimits;
    limiter.AddTokenBucketLimiter("highscore-reads", bucket => {
        bucket.TokenLimit = limits.GetCapacity; bucket.TokensPerPeriod = limits.GetPerSecond;
        bucket.ReplenishmentPeriod = TimeSpan.FromSeconds(1); bucket.AutoReplenishment = true; bucket.QueueLimit = 0;
    });
    limiter.AddTokenBucketLimiter("highscore-posts", bucket => {
        bucket.TokenLimit = limits.PostCapacity; bucket.TokensPerPeriod = limits.PostPerSecond;
        bucket.ReplenishmentPeriod = TimeSpan.FromSeconds(1); bucket.AutoReplenishment = true; bucket.QueueLimit = 0;
    });
    limiter.OnRejected = async (context, _) => {
        var seconds = context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var delay) ? Math.Max(1, (int)Math.Ceiling(delay.TotalSeconds)) : 1;
        context.HttpContext.Response.Headers.RetryAfter = seconds.ToString(System.Globalization.CultureInfo.InvariantCulture);
        await HighscoreEndpoints.Problem(new(429, "rate_limited", "Highscores are busy; please try a list refresh later")).ExecuteAsync(context.HttpContext);
    };
});
var app = builder.Build();
app.UseExceptionHandler();
app.Use(async (context, next) => {
    bool highscore = context.Request.Path == "/api/v1/highscores" || context.Request.Path == "/api/v2/highscores";
    if (highscore) context.Response.Headers.CacheControl = "no-store";
    var started = System.Diagnostics.Stopwatch.GetTimestamp();
    await next(context);
    if (highscore) context.RequestServices.GetRequiredService<HighscoreDiagnostics>().Request(
        context.Request.Method is "GET" or "POST" ? context.Request.Method : "OTHER", context.Response.StatusCode,
        System.Diagnostics.Stopwatch.GetElapsedTime(started).TotalMilliseconds);
});
app.UseRateLimiter();
app.MapHealthChecks("/health/live");
app.MapHighscores();
app.Run();
public partial class Program { }
