using System.Text.Json;
using DonkeyTrump.Highscores;

namespace DonkeyTrump.Highscores.Tests;

public class HighscoreRankingTests
{
    private static readonly DateTimeOffset Now = DateTimeOffset.Parse("2026-09-26T12:00:00.000Z");
    public static HighscoreSubmission Run(int score = 100, string name = "Løkke", Guid? id = null) => new(id ?? Guid.NewGuid(), name, score, 1);

    [Fact] public void SharedNamesAndScoresMatchCanonicalContract()
    {
        using var data = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Fixtures/highscores.json")));
        foreach (var item in data.RootElement.GetProperty("names").EnumerateArray()) {
            var actual = HighscoreValidation.NormalizeName(item.GetProperty("input").GetString());
            if (item.GetProperty("valid").GetBoolean()) Assert.Equal(item.GetProperty("canonical").GetString(), actual);
            else Assert.Null(actual);
        }
        foreach (var item in data.RootElement.GetProperty("scores").EnumerateArray())
            Assert.Equal(item.GetProperty("valid").GetBoolean(), HighscoreValidation.ValidScore(item.GetProperty("value").GetInt32()));
    }

    [Fact] public void EmptyListAcceptsZeroAndReplayDoesNotChangeTieOrder()
    {
        var run = Run(0);
        var first = HighscoreRanking.Evaluate(HighscoreDocument.Empty, run, Now);
        Assert.True(first.RequiresWrite); Assert.Single(first.Document.Entries); Assert.Equal(2, first.Document.NextSequence);
        var replay = HighscoreRanking.Evaluate(first.Document, run, Now.AddDays(1));
        Assert.False(replay.RequiresWrite); Assert.Equal(first.Document, replay.Document);
        Assert.Equal("submission_conflict", Assert.Throws<HighscoreFailure>(() => HighscoreRanking.Evaluate(first.Document, run with { DisplayName = "Other" }, Now)).Code);
    }

    [Fact] public void Best100PreserveEarlierEqualScoresAndNonUniqueNames()
    {
        var document = HighscoreDocument.Empty;
        var first = Run(1000, "Same");
        document = HighscoreRanking.Evaluate(document, first, Now).Document;
        for (int i = 0; i < 99; i++) document = HighscoreRanking.Evaluate(document, Run(1000, "Same"), Now).Document;
        var tied = HighscoreRanking.Evaluate(document, Run(1000), Now);
        Assert.False(tied.RequiresWrite); Assert.Equal(first.SubmissionId, tied.Document.Entries[0].SubmissionId);
        var higher = HighscoreRanking.Evaluate(document, Run(1100), Now);
        Assert.True(higher.RequiresWrite); Assert.Equal(100, higher.Document.Entries.Count);
        Assert.Equal(first.SubmissionId, higher.Document.Entries[1].SubmissionId);
        Assert.Equal(Enumerable.Range(1, 99).Select(i => (long)i), higher.Document.Entries.Skip(1).Select(e => e.Sequence));
    }

    [Theory]
    [InlineData("{}")]
    [InlineData("{\"submissionId\":\"00000000-0000-0000-0000-000000000001\",\"displayName\":\"A\",\"score\":\"100\",\"levelReached\":1}")]
    [InlineData("{\"submissionId\":\"00000000-0000-0000-0000-000000000001\",\"displayName\":\"A\",\"score\":0,\"levelReached\":1,\"rank\":1}")]
    [InlineData("{\"score\":0,\"score\":100}")]
    public void MalformedOrIncompleteRequestsFail(string json) {
        using var doc = JsonDocument.Parse(json);
        Assert.Throws<HighscoreFailure>(() => HighscoreValidation.Parse(doc.RootElement));
    }

    [Fact] public void CanonicalReplayComparesNormalizedNameAndLevel()
    {
        var id = Guid.NewGuid();
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(new { submissionId = id.ToString().ToUpperInvariant(), displayName = "  A\u030Ase  ", score = 100, levelReached = 2 }));
        var run = HighscoreValidation.Parse(json.RootElement); Assert.Equal("Åse", run.DisplayName);
        var doc = HighscoreRanking.Evaluate(HighscoreDocument.Empty, run, Now).Document;
        Assert.False(HighscoreRanking.Evaluate(doc, run, Now).RequiresWrite);
        Assert.Throws<HighscoreFailure>(() => HighscoreRanking.Evaluate(doc, run with { LevelReached = 3 }, Now));
    }
}
