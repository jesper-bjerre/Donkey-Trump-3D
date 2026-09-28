namespace DonkeyTrump.Highscores;

public sealed record AggregateRead(HighscoreDocument Document, string ETag);
public interface IModerationStore
{
    Task<AggregateRead> ReadAggregateAsync(CancellationToken token);
    Task<HighscoreResult> PublishAsync(HighscoreSubmission run,string installationHash,CancellationToken token);
    Task<(ReportReceipt Receipt,bool Created)> ReportAsync(ReportSubmission report,string reporterHash,CancellationToken token);
    Task<ReportReceipt> ReceiptAsync(Guid reportId,string reporterHash,CancellationToken token);
    Task<AggregateRead> MutateAsync(Func<HighscoreDocument,DateTimeOffset,HighscoreDocument> transition,string unconfirmedCode,CancellationToken token, bool migration = false, string? expectedETag = null);
}
public sealed class ModerationOptions
{
    public bool Maintenance { get; set; }
}
