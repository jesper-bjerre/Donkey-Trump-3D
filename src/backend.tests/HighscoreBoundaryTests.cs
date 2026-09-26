using System.Diagnostics;
using System.Net;
using System.Net.Http.Json;
using DonkeyTrump.Highscores.Tests.Support;
namespace DonkeyTrump.Highscores.Tests;

public class HighscoreBoundaryTests
{
    private sealed class Store(bool throws=false) : IHighscoreStore {
        public Task<HighscoreSnapshot> ReadAsync(CancellationToken token) => throws?throw new Exception("secret fixture 198.51.100.5 private-payload"):Task.FromResult(HighscoreSnapshot.From(HighscoreDocument.Empty,"empty",DateTimeOffset.UtcNow));
        public Task<HighscoreResult> SubmitAsync(HighscoreSubmission submission,CancellationToken token) => throws?throw new Exception(submission.DisplayName):Task.FromResult(HighscoreResult.From(HighscoreSnapshot.From(HighscoreRanking.Evaluate(HighscoreDocument.Empty,submission,DateTimeOffset.UtcNow).Document,"saved",DateTimeOffset.UtcNow),submission.SubmissionId));
    }
    [Theory][InlineData(false,40)][InlineData(true,10)]
    public async Task ConfiguredBucketsRejectImmediatelyWithIntegerRetryAfter(bool post,int capacity) {
        await using var factory=new HighscoreApiFactory(new Store());using var client=factory.CreateClient();
        var watch=Stopwatch.StartNew();
        // Concurrent requests exhaust the configured burst before replenishment; no test-only limits.
        var responses=await Task.WhenAll(Enumerable.Range(0,capacity+40).Select(_=>post?client.PostAsJsonAsync("/api/v1/highscores",new HighscoreSubmission(Guid.NewGuid(),"Burst",100,1)):client.GetAsync("/api/v1/highscores")));
        Assert.Contains(responses,r=>r.StatusCode==HttpStatusCode.OK);Assert.Contains(responses,r=>r.StatusCode==HttpStatusCode.TooManyRequests);
        Assert.True(watch.Elapsed<TimeSpan.FromSeconds(2));
        foreach(var response in responses) {if(response.StatusCode==HttpStatusCode.TooManyRequests) {Assert.True(int.TryParse(response.Headers.GetValues("Retry-After").Single(),out var seconds)&&seconds>=1);Assert.Equal("application/problem+json",response.Content.Headers.ContentType?.MediaType);}response.Dispose();}
    }
    [Fact] public async Task SafeErrorsAndDiagnosticsDoNotExposeSubmittedDataOrExceptions() {
        await using var factory=new HighscoreApiFactory(new Store(true));using var client=factory.CreateClient();
        Assert.Equal("Healthy",await client.GetStringAsync("/health/live"));
        using var get=await client.GetAsync("/api/v1/highscores");
        using var post=await client.PostAsJsonAsync("/api/v1/highscores",new HighscoreSubmission(Guid.NewGuid(),"PRIVATE_PLAYER",123400,42));
        var combined=await get.Content.ReadAsStringAsync()+await post.Content.ReadAsStringAsync()+string.Join("\n",factory.Logs);
        foreach(var excluded in new[]{"PRIVATE_PLAYER","123400","198.51.100.5","private-payload","System.Exception","secret fixture"})Assert.DoesNotContain(excluded,combined);
        Assert.Contains(factory.Logs,line=>line.Contains("highscore_request"));
    }
    [Fact] public void ProductionUsesHttpsManagedIdentityAndEmulatorIsLocalOnly() {
        Assert.False(new HighscoreOptions {UseAzurite=true}.IsValid("Production"));
        Assert.True(new HighscoreOptions {UseAzurite=true}.IsValid("Development"));
        Assert.False(new HighscoreOptions {UseAzurite=true,AzuriteEndpoint="http://example.com/devstoreaccount1"}.IsValid("Test"));
        foreach(var uri in new[]{"http://account.blob.core.windows.net","https://localhost","https://account.blob.core.windows.net/?sig=private","https://user:password@account.blob.core.windows.net"})Assert.False(new HighscoreOptions {BlobServiceUri=uri}.IsValid("Production"));
        var valid=new HighscoreOptions {BlobServiceUri="https://fixture.blob.core.windows.net"};Assert.True(valid.IsValid("Production"));
        Assert.Equal("https",valid.CreateClient().Uri.Scheme);Assert.Equal(0,valid.ClientOptions().Retry.MaxRetries);
        Assert.False(new HighscoreOptions {UseAzurite=true,MaxWriteAttempts=6}.IsValid("Test"));
        Assert.False(new HighscoreOptions {UseAzurite=true,OperationTimeoutSeconds=7}.IsValid("Test"));
    }
}
