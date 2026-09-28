using System.Net.Http.Json;
using DonkeyTrump.Highscores.Tests.Support;
namespace DonkeyTrump.Highscores.Tests;

[Trait("Category","StorageIntegration")]
public class CaptureIsolationTests(AzuriteFixture fixture) : IClassFixture<AzuriteFixture>
{
    [Fact]
    public void ProductionCanNeverEnableCapture()
    {
        var options=new HighscoreOptions {BlobServiceUri="https://donkeytrumpp.blob.core.windows.net"};
        Assert.False(new CaptureOptions{Enabled=true}.IsValid(options,"Production","donkeytrump-api-p"));
        Assert.True(new CaptureOptions().IsValid(options,"Production","donkeytrump-api-p"));
    }
    [Fact]
    public async Task SharedCaptureHandlersNeverMutateNormalAggregate()
    {
        var capOptions=CaptureOptions.Storage(fixture.Options);var capture=fixture.Options.CreateClient().GetBlobContainerClient(capOptions.ContainerName);
        await capture.CreateAsync();
        try {
            await capture.GetBlobClient(capOptions.BlobName).UploadAsync(BinaryData.FromBytes(ModerationMigration.Convert(HighscoreDocument.Empty).Serialize()));
            var normal=(await fixture.Container.GetBlobClient(fixture.Options.BlobName).GetPropertiesAsync()).Value.ETag;
            await using var app=new HighscoreApiFactory(settings:new Dictionary<string,string?> {
                ["Highscores:ContainerName"]=fixture.Options.ContainerName,["Capture:Enabled"]="true"
            });
            using var client=app.CreateClient();client.DefaultRequestHeaders.Authorization=new("Bearer",new string('A',43));
            using var saved=await client.PostAsJsonAsync("/capture/api/v1/highscores",new {submissionId=Guid.NewGuid(),displayName="Capture Player",score=12000,levelReached=1});
            saved.EnsureSuccessStatusCode();
            Assert.Equal(normal,(await fixture.Container.GetBlobClient(fixture.Options.BlobName).GetPropertiesAsync()).Value.ETag);
            using var off=await new HighscoreApiFactory().CreateClient().GetAsync("/capture/api/v1/highscores");
            Assert.Equal(404,(int)off.StatusCode);
        } finally {await capture.DeleteAsync();}
    }
    [Fact]
    public async Task CaptureCommandsRequireOwnershipAndNeverResetNormalData()
    {
        var options=fixture.Options;var capture=options.CreateClient().GetBlobContainerClient(CaptureOptions.Storage(options).ContainerName);
        await capture.CreateAsync();
        try {
            var blob=capture.GetBlobClient(options.BlobName);
            var normal=(await fixture.Container.GetBlobClient(options.BlobName).GetPropertiesAsync()).Value.ETag;
            var settings=new CaptureOptions {Enabled=true};
            await CaptureCommand.ExecuteAsync("capture-seed","local",false,options,settings,TextWriter.Null,default);
            Assert.False(await blob.ExistsAsync());
            await CaptureCommand.ExecuteAsync("capture-seed","local",true,options,settings,TextWriter.Null,default);
            Assert.Equal("dt3d-capture",(await blob.GetPropertiesAsync()).Value.Metadata["owner"]);
            await CaptureCommand.ExecuteAsync("capture-delete","local",true,options,new(),TextWriter.Null,default);
            Assert.False(await blob.ExistsAsync());
            await blob.UploadAsync(BinaryData.FromString("unowned"));
            foreach(var command in new[]{"capture-seed","capture-delete"}) {
                var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>CaptureCommand.ExecuteAsync(command,"local",true,options,settings,TextWriter.Null,default));
                Assert.Equal("capture_ownership_unknown",failure.Code);
            }
            Assert.Equal("unowned",(await blob.DownloadContentAsync()).Value.Content.ToString());
            Assert.Equal(normal,(await fixture.Container.GetBlobClient(options.BlobName).GetPropertiesAsync()).Value.ETag);
            await Assert.ThrowsAsync<HighscoreFailure>(()=>CaptureCommand.ExecuteAsync("capture-seed","prod",true,options,settings,TextWriter.Null,default));
        } finally {await capture.DeleteAsync();}
    }

}
