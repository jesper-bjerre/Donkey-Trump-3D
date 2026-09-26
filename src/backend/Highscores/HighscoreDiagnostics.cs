namespace DonkeyTrump.Highscores;

/// Deliberately bounded fields: never log bodies, names, run IDs, scores, IPs or raw exceptions.
public sealed class HighscoreDiagnostics(ILogger<HighscoreDiagnostics> logger)
{
    public void Request(string method,int status,double durationMs) => logger.LogInformation(
        "highscore_request route={Route} method={Method} outcome={Status} duration_ms={DurationMs}",
        "/api/v1/highscores",method,status,Math.Round(durationMs,2));
    public void WriteAttempt(int attempt) => logger.LogInformation("highscore_cas attempt={Attempt}",attempt);
    public void Failure(string errorClass) => logger.LogWarning("highscore_storage error_class={ErrorClass}",errorClass);
}
