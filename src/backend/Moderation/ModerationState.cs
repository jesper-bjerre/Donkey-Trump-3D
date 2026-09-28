using System.Text.Json.Serialization;

namespace DonkeyTrump.Highscores;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record InstallationBlock(string InstallationHash, DateTimeOffset BlockedAtUtc, Guid BlockId);

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record OperatorAudit(Guid OperationId, string Action, DateTimeOffset CreatedAtUtc, int AffectedCount);

public static class ModerationLimits
{
    public const int MaximumBytes = 1024 * 1024, ReservedBytes = 64 * 1024;
    public const int MaximumRemoved = 4096, MaximumBlocks = 1024, AdmissionRemoved = 3800, AdmissionBlocks = 800;
    public const int MaximumPending = 100, MaximumReports = 1000, MaximumAudit = 500, MaximumSpam = 100;
    public static HighscoreFailure Capacity() => new(503,"moderation_capacity","Highscore moderation is at capacity");
    public static void AdmitScore(HighscoreDocument d)
    {
        if(d.RemovedSubmissionIds.Count >= AdmissionRemoved || d.BlockedInstallations.Count >= AdmissionBlocks) throw Capacity();
    }
    public static void CheckGrowth(HighscoreDocument d, bool safety)
    {
        if(d.RemovedSubmissionIds.Count > MaximumRemoved || d.BlockedInstallations.Count > MaximumBlocks ||
           d.Reports.Count > MaximumReports || d.Reports.Count(r=>r.Status!="resolved") > MaximumPending) throw Capacity();
        if(System.Text.Json.JsonSerializer.SerializeToUtf8Bytes(d,HighscoreJson.Options).Length > MaximumBytes - (safety ? 0 : ReservedBytes)) throw Capacity();
        d.Validate();
    }
}
