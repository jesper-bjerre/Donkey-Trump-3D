using System.Text.Json;
using System.Text.Json.Serialization;

namespace DonkeyTrump.Highscores;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record HighscoreDocument
{
    public required int SchemaVersion { get; init; }
    public required long NextSequence { get; init; }
    public required List<StoredEntry> Entries { get; init; }
    public const int MaximumBytes = 256 * 1024;
    public static HighscoreDocument Empty => new() { SchemaVersion = 1, NextSequence = 1, Entries = [] };

    public void Validate()
    {
        if (SchemaVersion != 1 || NextSequence < 1 || Entries is null || Entries.Count > 100) throw HighscoreFailure.InvalidStorage();
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
            previous = entry;
        }
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
    public required Guid SubmissionId { get; init; }
    public required string DisplayName { get; init; }
    public required int Score { get; init; }
    public required int LevelReached { get; init; }
    public required long Sequence { get; init; }
    public required DateTimeOffset AcceptedAtUtc { get; init; }
}
