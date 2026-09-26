namespace DonkeyTrump.Highscores;

public interface IHighscoreStore
{
    Task<HighscoreSnapshot> ReadAsync(CancellationToken cancellationToken);
    Task<HighscoreResult> SubmitAsync(HighscoreSubmission submission, CancellationToken cancellationToken);
}
