namespace DonkeyTrump.Highscores;

public interface IHighscoreStore
{
    Task<HighscoreSnapshot> ReadAsync(CancellationToken cancellationToken);
    Task<HighscoreResult> PublishAsync(HighscoreSubmission submission, string installationHash, CancellationToken cancellationToken);
}
