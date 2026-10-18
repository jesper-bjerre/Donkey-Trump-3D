using System.Text.Json;
using DonkeyTrump.Highscores;
namespace DonkeyTrump.Highscores.Tests;

public class ScoreGranularityTests
{
    [Theory]
    [InlineData(0)][InlineData(5)][InlineData(10)][InlineData(1005)][InlineData(2600)][InlineData(2147483600)]
    public void ParserRankingAndBothDocumentSchemasPreserveExactScores(int score)
    {
        var id = Guid.NewGuid();
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new { submissionId=id, displayName="Exact", score, levelReached=1 }));
        var submission = HighscoreValidation.Parse(json.RootElement);
        Assert.Equal(score, submission.Score);
        foreach (var schema in new[] {1, 2}) {
            var original = HighscoreRanking.Evaluate(HighscoreDocument.Empty, new(Guid.NewGuid(),"Historical",2700,1), DateTimeOffset.UtcNow).Document;
            if (schema == 2) original = ModerationMigration.Convert(original);
            var next = HighscoreRanking.Evaluate(original, submission, DateTimeOffset.UtcNow, new string('a',64)).Document;
            var restored = HighscoreDocument.Deserialize(next.Serialize());
            Assert.Equal(score, Assert.Single(restored.Entries,e=>e.SubmissionId==id).Score);
            Assert.Equal(original.Entries[0], Assert.Single(restored.Entries,e=>e.SubmissionId==original.Entries[0].SubmissionId));
            Assert.Equal(schema,restored.SchemaVersion);
        }
    }
    [Theory][InlineData("-5")][InlineData("1.5")][InlineData("1001")][InlineData("2147483605")]
    public void InvalidDomainCannotEnterParser(string score)
    {
        using var json = JsonDocument.Parse($$"""{"submissionId":"{{Guid.NewGuid()}}","displayName":"Exact","score":{{score}},"levelReached":1}""");
        Assert.Throws<HighscoreFailure>(()=>HighscoreValidation.Parse(json.RootElement));
    }
}
