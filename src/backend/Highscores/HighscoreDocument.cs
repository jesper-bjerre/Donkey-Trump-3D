using System.Text.Json;
using System.Text.Json.Serialization;

namespace DonkeyTrump.Highscores;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record HighscoreDocument
{
    public required int SchemaVersion { get; init; }
    public required long NextSequence { get; init; }
    public required List<StoredEntry> Entries { get; init; }
    public const int MaximumBytes = ModerationLimits.MaximumBytes;
    public List<Guid> RemovedSubmissionIds { get; init; } = [];
    public List<InstallationBlock> BlockedInstallations { get; init; } = [];
    public List<ModerationReport> Reports { get; init; } = [];
    public List<SpamReceipt> SpamReceipts { get; init; } = [];
    public List<OperatorAudit> OperatorAudit { get; init; } = [];
    public static HighscoreDocument Empty => new() { SchemaVersion = 1, NextSequence = 1, Entries = [] };

    public void Validate()
    {
        if (SchemaVersion is not (1 or 2) || NextSequence < 1 || Entries is null || Entries.Count > 100) throw HighscoreFailure.InvalidStorage();
        ValidateModeration();
        HashSet<Guid> ids = []; HashSet<long> sequences = [];
        StoredEntry? previous = null;
        foreach (var entry in Entries)
        {
            if (entry is null || entry.SubmissionId == Guid.Empty || !ids.Add(entry.SubmissionId) ||
                entry.Sequence < 1 || entry.Sequence >= NextSequence || !sequences.Add(entry.Sequence) ||
                !HighscoreValidation.ValidScore(entry.Score) || entry.LevelReached < 1 ||
                entry.DisplayName is null || HighscoreValidation.NormalizeName(entry.DisplayName) != entry.DisplayName ||
                entry.AcceptedAtUtc == default || entry.AcceptedAtUtc.Offset != TimeSpan.Zero)
                throw HighscoreFailure.InvalidStorage();
            if (previous is not null && (entry.Score > previous.Score || entry.Score == previous.Score && entry.Sequence < previous.Sequence))
                throw HighscoreFailure.InvalidStorage();
            if (SchemaVersion == 2 && (!ValidOrigin(entry.Origin, entry.InstallationHash) || RemovedSubmissionIds.Contains(entry.SubmissionId) ||
                entry.Origin == "installation" && BlockedInstallations.Any(b => b.InstallationHash == entry.InstallationHash))) throw HighscoreFailure.InvalidStorage();
            if (SchemaVersion == 1 && (entry.Origin is not null || entry.InstallationHash is not null)) throw HighscoreFailure.InvalidStorage();
            previous = entry;
        }
    }

    public static bool ValidOrigin(string? origin, string? hash) => origin == "installation" ? InstallationCredential.ValidHash(hash) : origin is "legacy" or "starter" && hash is null;
    private static bool Utc(DateTimeOffset time) => time != default && time.Offset == TimeSpan.Zero;
    private void ValidateModeration()
    {
        static void Require(bool condition) { if (!condition) throw HighscoreFailure.InvalidStorage(); }
        Require(RemovedSubmissionIds is not null && BlockedInstallations is not null && Reports is not null && SpamReceipts is not null && OperatorAudit is not null);
        if (SchemaVersion == 1) {
            Require(RemovedSubmissionIds!.Count + BlockedInstallations!.Count + Reports!.Count + SpamReceipts!.Count + OperatorAudit!.Count == 0); return;
        }
        Require(RemovedSubmissionIds!.Count <= ModerationLimits.MaximumRemoved && RemovedSubmissionIds.All(id=>id!=Guid.Empty) && RemovedSubmissionIds.Distinct().Count()==RemovedSubmissionIds.Count);
        Require(BlockedInstallations!.Count <= ModerationLimits.MaximumBlocks && BlockedInstallations.All(b=>b is not null && InstallationCredential.ValidHash(b.InstallationHash) && Utc(b.BlockedAtUtc) && b.BlockId!=Guid.Empty));
        Require(BlockedInstallations.Select(b=>b.InstallationHash).Distinct().Count()==BlockedInstallations.Count && BlockedInstallations.Select(b=>b.BlockId).Distinct().Count()==BlockedInstallations.Count);
        Require(Reports!.Count<=ModerationLimits.MaximumReports && Reports.All(r=>r is not null) && Reports.Count(r=>r.Status!="resolved")<=ModerationLimits.MaximumPending);
        Require(Reports.Select(r=>r.ReportId).Distinct().Count()==Reports.Count);
        foreach(var r in Reports) {
            Require(r.ReportId!=Guid.Empty && r.EntryId!=Guid.Empty && InstallationCredential.ValidHash(r.ReporterHash) && ModerationReport.ValidReason(r.Reason) && Utc(r.CreatedAtUtc) &&
                r.DisplayName is not null && HighscoreValidation.NormalizeName(r.DisplayName)==r.DisplayName && ValidOrigin(r.Origin,r.InstallationHash));
            Require(r.Status is "pending" or "acknowledged" or "resolved");
            Require(r.AcknowledgedAtUtc is null || Utc(r.AcknowledgedAtUtc.Value) && r.AcknowledgedAtUtc>=r.CreatedAtUtc);
            if(r.Status=="resolved") Require(r.ResolvedAtUtc is not null && Utc(r.ResolvedAtUtc.Value) && r.ResolvedAtUtc>=r.CreatedAtUtc && (r.AcknowledgedAtUtc is null || r.ResolvedAtUtc>=r.AcknowledgedAtUtc) &&
                r.ResolvedOperationId is not null && r.ResolvedOperationId!=Guid.Empty && r.Disposition is "removed" or "removedAndBlocked" or "noAction" or "legacyRemoved" or "starterRemoved");
            else Require(r.ResolvedAtUtc is null && r.Disposition is null && r.ResolvedOperationId is null &&
                (r.Status=="acknowledged" ? r.AcknowledgedAtUtc is not null : r.AcknowledgedAtUtc is null));
        }
        var pending=Reports.Where(r=>r.Status!="resolved").ToList();
        Require(pending.Select(r=>(r.ReporterHash,r.EntryId)).Distinct().Count()==pending.Count);
        Require(SpamReceipts!.Count<=ModerationLimits.MaximumSpam && SpamReceipts.All(r=>r is not null && r.ReportId!=Guid.Empty && InstallationCredential.ValidHash(r.ReporterHash) && r.Status=="resolved" && Utc(r.ResolvedAtUtc) && r.OperationId!=Guid.Empty));
        Require(Reports.Select(r=>r.ReportId).Concat(SpamReceipts.Select(r=>r.ReportId)).Distinct().Count()==Reports.Count+SpamReceipts.Count);
        Require(OperatorAudit!.Count<=ModerationLimits.MaximumAudit && OperatorAudit.All(a=>a is not null && a.OperationId!=Guid.Empty && Utc(a.CreatedAtUtc) && a.AffectedCount>=0 &&
            a.Action is "acknowledge" or "resolve" or "remove" or "unblock" or "dismiss-spam"));
        Require(OperatorAudit.Select(a=>a.OperationId).Distinct().Count()==OperatorAudit.Count);
    }

    public static HighscoreDocument Deserialize(byte[] bytes)
    {
        try {
            using var json=JsonDocument.Parse(bytes,new JsonDocumentOptions {MaxDepth=16});
            static void NoDuplicates(JsonElement element) {
                if(element.ValueKind==JsonValueKind.Object) {
                    HashSet<string> names=[];
                    foreach(var p in element.EnumerateObject()) {if(!names.Add(p.Name)) throw HighscoreFailure.InvalidStorage(); NoDuplicates(p.Value);}
                } else if(element.ValueKind==JsonValueKind.Array) foreach(var item in element.EnumerateArray()) NoDuplicates(item);
            }
            NoDuplicates(json.RootElement);
            var d=JsonSerializer.Deserialize<HighscoreDocument>(bytes,HighscoreJson.Options) ?? throw HighscoreFailure.InvalidStorage();
            if(d.SchemaVersion==2) foreach(var field in new[]{"removedSubmissionIds","blockedInstallations","reports","spamReceipts","operatorAudit"})
                if(!json.RootElement.TryGetProperty(field,out _)) throw HighscoreFailure.InvalidStorage();
            d.Validate(); return d;
        } catch(JsonException) {throw HighscoreFailure.InvalidStorage();}
    }

    public byte[] Serialize()
    {
        Validate();
        var bytes = JsonSerializer.SerializeToUtf8Bytes(this, HighscoreJson.Options);
        if (bytes.Length > MaximumBytes) throw HighscoreFailure.InvalidStorage();
        return bytes;
    }
}

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record StoredEntry
{
    public string? Origin { get; init; }
    public string? InstallationHash { get; init; }
    public required Guid SubmissionId { get; init; }
    public required string DisplayName { get; init; }
    public required int Score { get; init; }
    public required int LevelReached { get; init; }
    public required long Sequence { get; init; }
    public required DateTimeOffset AcceptedAtUtc { get; init; }
}
