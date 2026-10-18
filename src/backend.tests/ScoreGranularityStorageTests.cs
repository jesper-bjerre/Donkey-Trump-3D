using System.Net.Http.Json;
using System.Text.Json;
using DonkeyTrump.Highscores;
using DonkeyTrump.Highscores.Tests.Support;
namespace DonkeyTrump.Highscores.Tests;

[Trait("Category", "StorageIntegration")]
public class ScoreGranularityStorageTests(AzuriteFixture fixture) : IClassFixture<AzuriteFixture>
{
    [Fact] public async Task PublicFivePointWritesSurviveFreshStoreAndPreserveHistoryAndTies()
    {
        var store = new BlobHighscoreStore(fixture.Options.CreateClient(),fixture.Options,TimeProvider.System);
        await using var api = new HighscoreApiFactory(store);
        using var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new("Bearer",new string('A',43));
        var initial = await client.GetFromJsonAsync<JsonElement>("/api/v1/highscores");
        var ids = new List<Guid>();
        foreach(var score in new[]{10,1005,1005}) {
            var id = Guid.NewGuid(); ids.Add(id);
            using var response = await client.PostAsJsonAsync("/api/v1/highscores",new {submissionId=id,displayName="Exact",score,levelReached=1});
            response.EnsureSuccessStatusCode();
            var returned = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(score,Assert.Single(returned.GetProperty("entries").EnumerateArray(),e=>e.GetProperty("entryId").GetGuid()==id).GetProperty("score").GetInt32());
        }
        var content = await fixture.Container.GetBlobClient(fixture.Options.BlobName).DownloadContentAsync();
        var stored = HighscoreDocument.Deserialize(content.Value.Content.ToArray());
        Assert.Equal(2,stored.SchemaVersion);
        var fresh = new BlobHighscoreStore(fixture.Options.CreateClient(),fixture.Options,TimeProvider.System);
        await using var restarted = new HighscoreApiFactory(fresh); using var read = restarted.CreateClient();
        var snapshot = await read.GetFromJsonAsync<JsonElement>("/api/v1/highscores");
        var rows = snapshot.GetProperty("entries").EnumerateArray().ToArray();
        foreach(var old in initial.GetProperty("entries").EnumerateArray()) {
            var found=Assert.Single(rows,e=>e.GetProperty("entryId").GetGuid()==old.GetProperty("entryId").GetGuid());
            Assert.Equal(old.GetProperty("score").GetInt32(),found.GetProperty("score").GetInt32());
            Assert.Equal(old.GetProperty("displayName").GetString(),found.GetProperty("displayName").GetString());
        }
        Assert.Equal(10,Assert.Single(rows,e=>e.GetProperty("entryId").GetGuid()==ids[0]).GetProperty("score").GetInt32());
        Assert.True(Array.FindIndex(rows,e=>e.GetProperty("entryId").GetGuid()==ids[1]) < Array.FindIndex(rows,e=>e.GetProperty("entryId").GetGuid()==ids[2]));
    }
}
