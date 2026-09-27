using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using DonkeyTrump.Highscores.Tests.Support;
namespace DonkeyTrump.Highscores.Tests;

public class HighscoreReadContractTests
{
    private sealed class Store(Func<CancellationToken,Task<HighscoreSnapshot>> read) : IHighscoreStore {
        public Task<HighscoreSnapshot> ReadAsync(CancellationToken token) => read(token);
        public Task<HighscoreResult> SubmitAsync(HighscoreSubmission submission,CancellationToken token) => throw new NotSupportedException();
    }
    [Theory][InlineData("storage_invalid")][InlineData("service_unavailable")][InlineData("operation_timed_out")]
    public async Task FailedReadIsNeverAValidEmptyList(string code) {
        await using var factory = new HighscoreApiFactory(new Store(_ => throw new HighscoreFailure(503,code,"Highscores are unavailable")));
        using var client = factory.CreateClient(); using var response = await client.GetAsync("/api/v1/highscores");
        Assert.Equal(HttpStatusCode.ServiceUnavailable,response.StatusCode);
        var data=await response.Content.ReadFromJsonAsync<JsonElement>();Assert.False(data.TryGetProperty("entries",out _));
        Assert.Equal(code,data.GetProperty("code").GetString());Assert.True(response.Headers.CacheControl?.NoStore);
    }
    [Theory][InlineData(0)][InlineData(1)]
    public async Task ConditionalGetReturnsFreshPublicSnapshotInsteadOf304(int count) {
        var document=HighscoreStarters.Fill(HighscoreDocument.Empty);
        if(count>0) document=HighscoreRanking.Evaluate(document,new(Guid.NewGuid(),"Løkke",100,2),DateTimeOffset.UtcNow).Document;
        var snapshot=HighscoreSnapshot.From(document,"\"revision\"",DateTimeOffset.UtcNow);
        await using var factory=new HighscoreApiFactory(new Store(_=>Task.FromResult(snapshot)));
        using var client=factory.CreateClient();client.DefaultRequestHeaders.TryAddWithoutValidation("If-None-Match","\"revision\"");
        using var response=await client.GetAsync("/api/v1/highscores");Assert.Equal(HttpStatusCode.OK,response.StatusCode);
        var json=await response.Content.ReadAsStringAsync();var data=JsonDocument.Parse(json).RootElement;
        Assert.Equal(10+count,data.GetProperty("entries").GetArrayLength());Assert.DoesNotContain("sequence",json);Assert.DoesNotContain("levelReached",json);
    }
}
