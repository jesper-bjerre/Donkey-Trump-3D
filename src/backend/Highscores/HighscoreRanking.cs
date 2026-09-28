namespace DonkeyTrump.Highscores;

public sealed record RankingDecision(HighscoreDocument Document, bool RequiresWrite);
public static class HighscoreRanking
{
    public static RankingDecision Evaluate(HighscoreDocument document, HighscoreSubmission run, DateTimeOffset now, string? installationHash = null)
    {
        document.Validate();
        if (run.SubmissionId == Guid.Empty || !HighscoreValidation.ValidScore(run.Score) || run.LevelReached < 1 ||
            HighscoreValidation.NormalizeName(run.DisplayName) != run.DisplayName) throw HighscoreFailure.Malformed();
        var existing = document.Entries.FirstOrDefault(e => e.SubmissionId == run.SubmissionId);
        if (existing is not null) {
            if (existing.DisplayName != run.DisplayName || existing.Score != run.Score || existing.LevelReached != run.LevelReached)
                throw new HighscoreFailure(409, "submission_conflict", "This run was already submitted with different data");
            return new(document, false);
        }
        if (document.Entries.Count == 100 && run.Score <= document.Entries[^1].Score) return new(document, false);
        if (document.NextSequence == long.MaxValue) throw HighscoreFailure.InvalidStorage();
        var entries = new List<StoredEntry>(document.Entries) {
            new() { SubmissionId = run.SubmissionId, DisplayName = run.DisplayName, Score = run.Score,
                Origin = document.SchemaVersion == 2 ? "installation" : null, InstallationHash = installationHash,
                LevelReached = run.LevelReached, Sequence = document.NextSequence, AcceptedAtUtc = now.ToUniversalTime() }
        };
        return new(document with { NextSequence = document.NextSequence + 1,
            Entries = entries.OrderByDescending(e => e.Score).ThenBy(e => e.Sequence).Take(100).ToList() }, true);
    }
}
