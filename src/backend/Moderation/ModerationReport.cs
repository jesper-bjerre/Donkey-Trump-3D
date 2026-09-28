using System.Text.Json.Serialization;

namespace DonkeyTrump.Highscores;

public sealed record ReportSubmission(Guid ReportId, Guid EntryId, string Reason);
public sealed record ReportReceipt(Guid ReportId, string Status, DateTimeOffset? CreatedAtUtc,
    DateTimeOffset? AcknowledgedAtUtc = null, DateTimeOffset? ResolvedAtUtc = null, string? Disposition = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)] bool AlreadyPending = false);
public sealed record ReportDecision(HighscoreDocument Document, ReportReceipt Receipt, bool Created);

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record ModerationReport
{
    public required Guid ReportId { get; init; }
    public required string ReporterHash { get; init; }
    public required Guid EntryId { get; init; }
    public required string Reason { get; init; }
    public required DateTimeOffset CreatedAtUtc { get; init; }
    public required string DisplayName { get; init; }
    public required string Origin { get; init; }
    public string? InstallationHash { get; init; }
    public required string Status { get; init; }
    public DateTimeOffset? AcknowledgedAtUtc { get; init; }
    public DateTimeOffset? ResolvedAtUtc { get; init; }
    public string? Disposition { get; init; }
    public Guid? ResolvedOperationId { get; init; }
    public ReportReceipt Receipt(bool alreadyPending = false) => new(ReportId,Status,CreatedAtUtc,AcknowledgedAtUtc,ResolvedAtUtc,Disposition,alreadyPending);
    public static bool ValidReason(string reason) => reason is "offensiveName" or "impersonation" or "personalInformation" or "other";
}

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record SpamReceipt(Guid ReportId, string ReporterHash, string Status, DateTimeOffset ResolvedAtUtc, Guid OperationId)
{
    public ReportReceipt Receipt() => new(ReportId,Status,null,null,ResolvedAtUtc,"dismissedSpam");
}

public static class ModerationRetention
{
    // Content-free backlog metric. Only expired records contribute; never pending reports or guards.
    public static double OldestOverdueSeconds(HighscoreDocument d, DateTimeOffset now)
    {
        var due=d.Reports.Where(r=>r.ResolvedAtUtc is not null).Select(r=>r.ResolvedAtUtc!.Value.AddDays(30))
            .Concat(d.OperatorAudit.Select(a=>a.CreatedAtUtc.AddDays(30)))
            .Concat(d.SpamReceipts.Select(r=>r.ResolvedAtUtc.AddHours(24)))
            .Where(t=>t<=now).ToArray();
        return due.Length==0 ? 0 : Math.Max(0,(now-due.Min()).TotalSeconds);
    }
    public static HighscoreDocument Purge(HighscoreDocument d, DateTimeOffset now) => d with {
        Reports=d.Reports.Where(r=>r.ResolvedAtUtc is null || r.ResolvedAtUtc > now.AddDays(-30)).ToList(),
        OperatorAudit=d.OperatorAudit.Where(a=>a.CreatedAtUtc>now.AddDays(-30)).TakeLast(ModerationLimits.MaximumAudit).ToList(),
        SpamReceipts=d.SpamReceipts.Where(r=>r.ResolvedAtUtc>now.AddHours(-24)).TakeLast(ModerationLimits.MaximumSpam).ToList()
    };
}

public static class ModerationResponseDeadline
{
    private static readonly TimeZoneInfo Copenhagen=TimeZoneInfo.FindSystemTimeZoneById("Europe/Copenhagen");
    public static DateTimeOffset For(DateTimeOffset createdAtUtc)
    {
        var next=TimeZoneInfo.ConvertTime(createdAtUtc,Copenhagen).DateTime.AddDays(1);
        while(next.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday) next=next.AddDays(1);
        return new DateTimeOffset(next,Copenhagen.GetUtcOffset(next)).ToUniversalTime();
    }
}
