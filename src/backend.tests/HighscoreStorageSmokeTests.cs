using DonkeyTrump.Highscores;
using DonkeyTrump.Highscores.Tests.Support;
using System.Net.Http.Json;
using System.Text.Json;

namespace DonkeyTrump.Highscores.Tests;

[Trait("Category", "StorageIntegration")]
public class HighscoreStorageSmokeTests(AzuriteFixture fixture) : IClassFixture<AzuriteFixture>
{
    [Fact] public async Task IndependentApisSharePersistentZeroScoreAndReplay()
    {
        var firstStore = new BlobHighscoreStore(fixture.Options.CreateClient(), fixture.Options, TimeProvider.System);
        var secondStore = new BlobHighscoreStore(fixture.Options.CreateClient(), fixture.Options, TimeProvider.System);
        await using var first = new HighscoreApiFactory(firstStore); await using var second = new HighscoreApiFactory(secondStore);
        using var a = first.CreateClient(); using var b = second.CreateClient();
        var empty = await a.GetFromJsonAsync<JsonElement>("/api/v1/highscores"); Assert.Empty(empty.GetProperty("entries").EnumerateArray());
        var run = new { submissionId = Guid.NewGuid(), displayName = "Løkke", score = 0, levelReached = 1 };
        using var saved = await a.PostAsJsonAsync("/api/v1/highscores", run); saved.EnsureSuccessStatusCode();
        var written = await saved.Content.ReadFromJsonAsync<JsonElement>(); Assert.Equal("ranked", written.GetProperty("outcome").GetString());
        var loaded = await b.GetFromJsonAsync<JsonElement>("/api/v1/highscores");
        Assert.Equal(written.GetProperty("revision").GetString(), loaded.GetProperty("revision").GetString());
        Assert.Equal(run.submissionId, Assert.Single(loaded.GetProperty("entries").EnumerateArray()).GetProperty("entryId").GetGuid());
        using var replay = await b.PostAsJsonAsync("/api/v1/highscores",run); replay.EnsureSuccessStatusCode();
        var repeated = await replay.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(written.GetProperty("revision").GetString(), repeated.GetProperty("revision").GetString());
        Assert.Single(repeated.GetProperty("entries").EnumerateArray());
        // Fresh store instance models an API process losing all in-memory state.
        var restarted = new BlobHighscoreStore(fixture.Options.CreateClient(), fixture.Options, TimeProvider.System);
        Assert.Equal(loaded.GetProperty("revision").GetString(), (await restarted.ReadAsync(default)).Revision);
    }
}
