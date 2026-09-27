namespace DonkeyTrump.Highscores;

/// Server-owned starting opponents. GET remains read-only; the next new score
/// persists these rows with the same conditional write as the player's result.
public static class HighscoreStarters
{
    public const int MinimumEntries = 10;
    private static readonly string[] Names = [
        "Bugs Bunny", "Daffy Duck", "Scooby-Doo", "Fred Flintstone", "Garfield",
        "Snoopy", "Popeye", "Tom", "Jerry", "Tweety"
    ];
    private static readonly DateTimeOffset AcceptedAt = new(2026, 9, 27, 0, 0, 0, TimeSpan.Zero);

    public static HighscoreDocument Fill(HighscoreDocument document)
    {
        // Never disguise corrupt storage as a fresh starter list.
        document.Validate();
        if (document.Entries.Count >= MinimumEntries) return document;
        var entries = new List<StoredEntry>(document.Entries);
        var next = document.NextSequence;
        for (int i = 0; i < Names.Length && entries.Count < MinimumEntries; i++)
        {
            var id = Guid.Parse($"d7c30000-0000-4000-8000-{i + 1:D12}");
            if (entries.Any(e => e.SubmissionId == id)) continue;
            if (next == long.MaxValue) throw HighscoreFailure.InvalidStorage();
            entries.Add(new StoredEntry {
                SubmissionId = id, DisplayName = Names[i], Score = (MinimumEntries - i) * 100,
                LevelReached = 1, Sequence = next++, AcceptedAtUtc = AcceptedAt
            });
        }
        return document with {
            NextSequence = next,
            Entries = entries.OrderByDescending(e => e.Score).ThenBy(e => e.Sequence).ToList()
        };
    }
}
