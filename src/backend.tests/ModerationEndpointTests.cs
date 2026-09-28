using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using DonkeyTrump.Highscores.Tests.Support;
using static DonkeyTrump.Highscores.Tests.ModerationContractTests;
namespace DonkeyTrump.Highscores.Tests;

[Trait("Category","StorageIntegration")]
public class ModerationEndpointTests(AzuriteFixture fixture) : IClassFixture<AzuriteFixture>
{
    [Fact]
    public async Task ReportsUseCanonicalReceiptsOwnershipAndNeverLeakSnapshotOrSecret()
    {
        var d=WithRun(out var id);
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        await fixture.Container.GetBlobClient(options.BlobName).UploadAsync(BinaryData.FromBytes(d.Serialize()));
        var store=new BlobHighscoreStore(options.CreateClient(),options,TimeProvider.System);
        await using var app=new HighscoreApiFactory(store);using var client=app.CreateClient();
        client.DefaultRequestHeaders.Authorization=new("Bearer",new string('A',43));
        var report=Guid.NewGuid();var path="/api/v1/highscore-reports";
        using var saved=await client.PostAsJsonAsync(path,new {reportId=report,entryId=id,reason="other"});
        Assert.Equal(201,(int)saved.StatusCode);Assert.True(saved.Headers.CacheControl?.NoStore);
        using var duplicate=await client.PostAsJsonAsync(path,new {reportId=Guid.NewGuid(),entryId=id,reason="offensiveName"});
        Assert.Equal(200,(int)duplicate.StatusCode);
        var receipt=await duplicate.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(report,receipt.GetProperty("reportId").GetGuid());Assert.True(receipt.GetProperty("alreadyPending").GetBoolean());
        using var status=await client.GetAsync(path+"/"+report);status.EnsureSuccessStatusCode();
        var all=await status.Content.ReadAsStringAsync()+await client.GetStringAsync("/api/v1/highscores")+string.Join('\n',app.Logs);
        Assert.DoesNotContain("installationHash",all);Assert.DoesNotContain(Producer,all);Assert.DoesNotContain(new string('A',43),all);
        client.DefaultRequestHeaders.Authorization=new("Bearer",Convert.ToBase64String(Enumerable.Repeat((byte)1,32).ToArray()).TrimEnd('='));
        using var foreign=await client.GetAsync(path+"/"+report);Assert.Equal(404,(int)foreign.StatusCode);Assert.True(foreign.Headers.CacheControl?.NoStore);
    }

    [Theory]
    [InlineData("highscores")]
    [InlineData("highscore-reports")]
    public async Task SchemaOneHttpWritesReturnMaintenanceWithoutChangingStorage(string resource)
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        var source=HighscoreStarters.Fill(HighscoreDocument.Empty);var blob=fixture.Container.GetBlobClient(options.BlobName);
        await blob.UploadAsync(BinaryData.FromBytes(source.Serialize()));var etag=(await blob.GetPropertiesAsync()).Value.ETag;
        int writes=0;var transport=new BlobFaultTransport {Before=message=> {
            if(message.Request.Method==Azure.Core.RequestMethod.Put) writes++;
            return ValueTask.CompletedTask;
        }};
        var sdk=options.ClientOptions();sdk.Transport=transport;
        var store=new BlobHighscoreStore(options.CreateClient(sdk),options,TimeProvider.System,moderation:new() {Maintenance=false});
        await using var app=new HighscoreApiFactory(store);using var client=app.CreateClient();
        client.DefaultRequestHeaders.Authorization=new("Bearer",new string('A',43));
        object body=resource=="highscores" ? new {submissionId=Guid.NewGuid(),displayName="New Player",score=5000,levelReached=1}
            : new {reportId=Guid.NewGuid(),entryId=source.Entries[0].SubmissionId,reason="other"};
        using var response=await client.PostAsJsonAsync("/api/v1/"+resource,body);
        Assert.Equal(503,(int)response.StatusCode);Assert.True(response.Headers.CacheControl?.NoStore);
        var problem=await response.Content.ReadFromJsonAsync<JsonElement>();Assert.Equal("service_maintenance",problem.GetProperty("code").GetString());
        Assert.Equal(0,writes);Assert.Equal(etag,(await blob.GetPropertiesAsync()).Value.ETag);
    }

    [Fact]
    public async Task CurrentWriterStrictlyAuthenticatedBeforeBodyAndNoSecondApiVersion()
    {
        await using var app=new HighscoreApiFactory();using var client=app.CreateClient();
        using var obsolete=await client.GetAsync("/api/v2/highscores");Assert.Equal(404,(int)obsolete.StatusCode);
        using var missing=await client.PostAsync("/api/v1/highscores",new StringContent("{}",Encoding.UTF8,"application/json"));Assert.Equal(401,(int)missing.StatusCode);
        client.DefaultRequestHeaders.Authorization=new("Bearer",new string('A',43));
        foreach(var body in new[]{"{\"reportId\":\"00000000-0000-0000-0000-000000000000\"}","{\"x\":0}","{\"reason\":\"other\",\"reason\":\"other\"}",new string('[',18)+new string(']',18)}) {
            using var response=await client.PostAsync("/api/v1/highscore-reports",new StringContent(body,Encoding.UTF8,"application/json"));
            Assert.Equal(400,(int)response.StatusCode);Assert.True(response.Headers.CacheControl?.NoStore);
        }
    }
}
