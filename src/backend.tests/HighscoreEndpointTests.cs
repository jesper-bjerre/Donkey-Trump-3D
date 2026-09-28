using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using DonkeyTrump.Highscores;
using DonkeyTrump.Highscores.Tests.Support;

namespace DonkeyTrump.Highscores.Tests;

public class HighscoreEndpointTests
{
    private sealed class Store : IHighscoreStore {
        public int Calls;
        private HighscoreDocument document = HighscoreStarters.Fill(HighscoreDocument.Empty);
        public Task<HighscoreSnapshot> ReadAsync(CancellationToken token) { Calls++; return Task.FromResult(HighscoreSnapshot.From(document, "empty", DateTimeOffset.UtcNow)); }
        public Task<HighscoreResult> PublishAsync(HighscoreSubmission run,string hash,CancellationToken token) {
            Calls++; document = HighscoreRanking.Evaluate(document, run, DateTimeOffset.UtcNow).Document;
            return Task.FromResult(HighscoreResult.From(HighscoreSnapshot.From(document, "\"test\"", DateTimeOffset.UtcNow), run.SubmissionId));
        }
    }
    [Fact] public async Task LivenessDoesNotTouchStorageAndGetIsUncached() {
        var store = new Store(); await using var factory = new HighscoreApiFactory(store); using var client = factory.CreateClient(); client.DefaultRequestHeaders.Authorization = new("Bearer", new string('A',43));
        Assert.Equal("Healthy", await client.GetStringAsync("/health/live")); Assert.Equal(0, store.Calls);
        using var response = await client.GetAsync("/api/v1/highscores"); Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(response.Headers.CacheControl?.NoStore); var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(10,json.GetProperty("entries").GetArrayLength()); Assert.Equal("empty", json.GetProperty("revision").GetString());
        Assert.Matches(@"\.\d{3}Z$", json.GetProperty("fetchedAtUtc").GetString()!);
    }
    [Fact] public async Task SaveReplayAndConflictUseExactPublicContract() {
        await using var factory = new HighscoreApiFactory(new Store()); using var client = factory.CreateClient(); client.DefaultRequestHeaders.Authorization = new("Bearer", new string('A',43));
        var run = new { submissionId = Guid.NewGuid(), displayName = " Løkke ", score = 0, levelReached = 1 };
        for (int i=0;i<2;i++) {
            using var response = await client.PostAsJsonAsync("/api/v1/highscores", run); Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var data = await response.Content.ReadFromJsonAsync<JsonElement>(); Assert.Equal("ranked", data.GetProperty("outcome").GetString());
            Assert.Equal(run.submissionId, data.GetProperty("entryId").GetGuid()); var row = Assert.Single(data.GetProperty("entries").EnumerateArray(),e=>e.GetProperty("entryId").GetGuid()==run.submissionId);
            Assert.Equal(new[] {"displayName","entryId","rank","score"}, row.EnumerateObject().Select(p=>p.Name).Order().ToArray());
            Assert.Equal("Løkke", row.GetProperty("displayName").GetString());
        }
        using var conflict = await client.PostAsJsonAsync("/api/v1/highscores", run with { score = 100 });
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode); Assert.Equal("submission_conflict", (await conflict.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("code").GetString());
    }
    [Theory]
    [InlineData("{}", "application/json",400,"validation_failed")]
    [InlineData("{", "application/json",400,"malformed_request")]
    [InlineData("{}", "text/plain",415,"unsupported_media_type")]
    public async Task InvalidRequestIsRejectedBeforeStorage(string body,string media,int status,string code) {
        var store = new Store(); await using var factory = new HighscoreApiFactory(store); using var client = factory.CreateClient(); client.DefaultRequestHeaders.Authorization = new("Bearer", new string('A',43));
        using var response = await client.PostAsync("/api/v1/highscores",new StringContent(body,Encoding.UTF8,media));
        Assert.Equal(status,(int)response.StatusCode);Assert.Equal(0,store.Calls);
        Assert.Equal("application/problem+json",response.Content.Headers.ContentType?.MediaType);
        var data = await response.Content.ReadFromJsonAsync<JsonElement>();Assert.Equal(code,data.GetProperty("code").GetString());
    }
    [Theory][InlineData(false)][InlineData(true)]
    public async Task OversizedKnownOrStreamingBodyIsBounded(bool chunked) {
        var store = new Store(); await using var factory = new HighscoreApiFactory(store); using var client = factory.CreateClient(); client.DefaultRequestHeaders.Authorization = new("Bearer", new string('A',43));
        HttpContent content = chunked ? new UnknownLengthContent(new string(' ',4097)) : new StringContent(new string(' ',4097),Encoding.UTF8,"application/json");
        using var response = await client.PostAsync("/api/v1/highscores",content);
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge,response.StatusCode);Assert.Equal(0,store.Calls);
    }
    private sealed class UnknownLengthContent : HttpContent {
        private readonly string text;
        public UnknownLengthContent(string text) { this.text = text; Headers.ContentType = new("application/json"); }
        protected override bool TryComputeLength(out long length) {length=0;return false;}
        protected override async Task SerializeToStreamAsync(Stream stream,TransportContext? context) {
            Headers.ContentType = new("application/json"); await stream.WriteAsync(Encoding.UTF8.GetBytes(text));
        }
    }
}
