namespace DonkeyTrump.Highscores;

/// Server-owned starting opponents. GET remains read-only; the next new score
/// persists these rows with the same conditional write as the player's result.
public static class HighscoreStarters
{
    public const int MinimumEntries = 10;
    private static readonly string[] Names = [
        "Bugs Bunny", "Daffy Duck", "Scooby-Doo", "Fred Flintstone", "Garfield",
        "Snoopy", "Popeye", "Tom", "Jerry", "Tweety", "Pluto", "Goofy", "Donald Duck", "Daisy Duck", "Mickey Mouse", "Minnie Mouse",
        "Winnie the Pooh", "Tigger", "Piglet", "Eeyore", "Bambi", "Thumper", "Dumbo", "Pinocchio", "Jiminy Cricket", "Felix the Cat",
        "Betty Boop", "Mr Magoo", "Yogi Bear", "Boo Boo", "Top Cat", "Benny the Ball"
    ];
    private static readonly DateTimeOffset AcceptedAt = new(2026, 9, 27, 0, 0, 0, TimeSpan.Zero);

    public static readonly IReadOnlyList<Guid> ReservedIds = Array.AsReadOnly(Enumerable.Range(1, Names.Length).Select(i => Guid.Parse($"d7c30000-0000-4000-8000-{i:D12}")).ToArray());

    public static HighscoreDocument Fill(HighscoreDocument document)
    {
        // Never disguise corrupt storage as a fresh starter list.
        document.Validate();
        if (document.Entries.Count >= MinimumEntries) return document;
        var entries = new List<StoredEntry>(document.Entries);
        var next = document.NextSequence;
        for (int i = 0; i < Names.Length && entries.Count < MinimumEntries; i++)
        {
            var id = ReservedIds[i];
            if (entries.Any(e => e.SubmissionId == id) || document.RemovedSubmissionIds.Contains(id) || !NameModerationPolicy.Allowed(Names[i])) continue;
            if (next == long.MaxValue) throw HighscoreFailure.InvalidStorage();
            entries.Add(new StoredEntry {
                SubmissionId = id, DisplayName = Names[i], Score = Math.Max(100, (MinimumEntries - i) * 100),
                Origin = document.SchemaVersion == 2 ? "starter" : null,
                LevelReached = 1, Sequence = next++, AcceptedAtUtc = AcceptedAt
            });
        }
        if (entries.Count < MinimumEntries) throw ModerationLimits.Capacity();
        return document with {
            NextSequence = next,
            Entries = entries.OrderByDescending(e => e.Score).ThenBy(e => e.Sequence).ToList()
        };
    }
}
