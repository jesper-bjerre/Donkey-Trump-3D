namespace DonkeyTrump.Highscores;

public sealed record HighscoreSubmission(Guid SubmissionId, string DisplayName, int Score, int LevelReached);
