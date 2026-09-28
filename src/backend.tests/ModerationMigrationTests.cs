using DonkeyTrump.Highscores.Tests.Support;
namespace DonkeyTrump.Highscores.Tests;

[Trait("Category","StorageIntegration")]
public class ModerationMigrationTests(AzuriteFixture fixture) : IClassFixture<AzuriteFixture>
{
    [Fact]
    public async Task MigrationRequiresMaintenancePreservesDataAndDeletesVerifiedBackup()
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        var client=options.CreateClient();var blob=fixture.Container.GetBlobClient(options.BlobName);
        var original=HighscoreRanking.Evaluate(HighscoreDocument.Empty,new(Guid.NewGuid(),"Before Migration",5000,3),DateTimeOffset.UtcNow).Document;
        await blob.UploadAsync(BinaryData.FromBytes(original.Serialize()));
        var tag=(await blob.GetPropertiesAsync()).Value.ETag.ToString();
        var settings=new ModerationOptions();var store=new BlobHighscoreStore(client,options,TimeProvider.System,moderation:settings);
        await Assert.ThrowsAsync<HighscoreFailure>(()=>ModerationMigration.ApplyAsync(store,client,options,settings,tag,TimeProvider.System,default));
        settings.Maintenance=true;
        var after=await ModerationMigration.ApplyAsync(store,client,options,settings,tag,TimeProvider.System,default);
        Assert.Equal(2,after.Document.SchemaVersion);Assert.Equal(original.NextSequence,after.Document.NextSequence);
        Assert.Equal(original.Entries.Select(e=>e.SubmissionId),after.Document.Entries.Select(e=>e.SubmissionId));
        Assert.Equal("legacy",after.Document.Entries.Single().Origin);
        Assert.False(await fixture.Container.GetBlobClient(ModerationMigration.BackupName(options)).ExistsAsync());
        var replay=await ModerationMigration.ApplyAsync(store,client,options,settings,after.ETag,TimeProvider.System,default);
        Assert.Equal(after.ETag,replay.ETag);
        Assert.Equal("service_maintenance",(await Assert.ThrowsAsync<HighscoreFailure>(()=>store.PublishAsync(new(Guid.NewGuid(),"New",100,1),new string('a',64),default))).Code);
    }

    [Fact]
    public async Task LostMigrationAcknowledgementRequiresReadbackAndPreservesScores()
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        var original=HighscoreRanking.Evaluate(HighscoreDocument.Empty,new(Guid.NewGuid(),"Existing",5000,2),DateTimeOffset.UtcNow).Document;
        var blob=fixture.Container.GetBlobClient(options.BlobName);
        await blob.UploadAsync(BinaryData.FromBytes(original.Serialize()));
        var tag=(await blob.GetPropertiesAsync()).Value.ETag.ToString();
        int writes=0;
        var transport=new BlobFaultTransport {After=message=> {
            if(message.Request.Method==Azure.Core.RequestMethod.Put && message.Request.Uri.ToUri().AbsolutePath.EndsWith("/"+options.BlobName) && message.Response.Status==201) {
                writes++;throw new IOException("Lost migration acknowledgement fixture");
            }
            return ValueTask.CompletedTask;
        }};
        var sdk=options.ClientOptions();sdk.Transport=transport;
        var settings=new ModerationOptions {Maintenance=true};var client=options.CreateClient();
        var faulty=new BlobHighscoreStore(options.CreateClient(sdk),options,TimeProvider.System,moderation:settings);
        Assert.Equal("migration_unconfirmed",(await Assert.ThrowsAsync<HighscoreFailure>(()=>ModerationMigration.ApplyAsync(faulty,client,options,settings,tag,TimeProvider.System,default))).Code);
        Assert.Equal(1,writes);
        var store=new BlobHighscoreStore(client,options,TimeProvider.System,moderation:settings);
        var read=await store.ReadAggregateAsync(default);
        Assert.Equal(2,read.Document.SchemaVersion);
        Assert.Equal(original.Entries.Single().SubmissionId,read.Document.Entries.Single().SubmissionId);
        var verified=await ModerationMigration.ApplyAsync(store,client,options,settings,read.ETag,TimeProvider.System,default);
        Assert.Equal(read.ETag,verified.ETag);
        Assert.False(await fixture.Container.GetBlobClient(ModerationMigration.BackupName(options)).ExistsAsync());
    }

    [Fact]
    public async Task UnownedBackupNeverPermitsMigrationOrReplacement()
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        var client=options.CreateClient();var blob=fixture.Container.GetBlobClient(options.BlobName);
        await blob.UploadAsync(BinaryData.FromBytes(HighscoreDocument.Empty.Serialize()));
        var tag=(await blob.GetPropertiesAsync()).Value.ETag.ToString();
        var backup=fixture.Container.GetBlobClient(ModerationMigration.BackupName(options));
        await backup.UploadAsync(BinaryData.FromString("unrelated"));
        var settings=new ModerationOptions {Maintenance=true};var store=new BlobHighscoreStore(client,options,TimeProvider.System,moderation:settings);
        Assert.Equal("backup_conflict",(await Assert.ThrowsAsync<HighscoreFailure>(()=>ModerationMigration.ApplyAsync(store,client,options,settings,tag,TimeProvider.System,default))).Code);
        Assert.Equal(tag,(await blob.GetPropertiesAsync()).Value.ETag.ToString());
        Assert.Equal("unrelated",(await backup.DownloadContentAsync()).Value.Content.ToString());
    }

    [Fact]
    public async Task ExplicitFirstProvisioningIsPreviewedAndNeverOverwritesExistingData()
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName="dt3d-test-"+Guid.NewGuid().ToString("N")};
        var client=options.CreateClient();var container=client.GetBlobContainerClient(options.ContainerName);
        await container.CreateAsync();
        try {
            using var output=new StringWriter();var blob=container.GetBlobClient(options.BlobName);
            await ModerationMigration.InitializeAsync(client,options,false,output,default);
            Assert.False(await blob.ExistsAsync());
            await ModerationMigration.InitializeAsync(client,options,true,output,default);
            var before=await blob.DownloadContentAsync();
            Assert.Equal(1,HighscoreDocument.Deserialize(before.Value.Content.ToArray()).SchemaVersion);
            Assert.Equal("storage_not_empty",(await Assert.ThrowsAsync<HighscoreFailure>(()=>ModerationMigration.InitializeAsync(client,options,true,output,default))).Code);
            Assert.Equal(before.Value.Details.ETag,(await blob.GetPropertiesAsync()).Value.ETag);
        } finally {await container.DeleteAsync();}
    }

    [Fact]
    public async Task SchemaOneRejectsEveryWriterBeforeAnyUploadWithoutMaintenanceFlag()
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        var source=HighscoreStarters.Fill(HighscoreDocument.Empty);
        var blob=fixture.Container.GetBlobClient(options.BlobName);
        await blob.UploadAsync(BinaryData.FromBytes(source.Serialize()));
        var etag=(await blob.GetPropertiesAsync()).Value.ETag;int writes=0;
        var transport=new BlobFaultTransport {Before=message=> {
            if(message.Request.Method==Azure.Core.RequestMethod.Put) writes++;
            return ValueTask.CompletedTask;
        }};
        var sdk=options.ClientOptions();sdk.Transport=transport;
        var store=new BlobHighscoreStore(options.CreateClient(sdk),options,TimeProvider.System,moderation:new() {Maintenance=false});
        var run=new HighscoreSubmission(Guid.NewGuid(),"New Player",5000,1);
        var report=new ReportSubmission(Guid.NewGuid(),source.Entries[0].SubmissionId,"other");
        Assert.Equal("service_maintenance",(await Assert.ThrowsAsync<HighscoreFailure>(()=>store.PublishAsync(run,new string('a',64),default))).Code);
        Assert.Equal("service_maintenance",(await Assert.ThrowsAsync<HighscoreFailure>(()=>store.ReportAsync(report,new string('b',64),default))).Code);
        Assert.Equal(0,writes);Assert.Equal(etag,(await blob.GetPropertiesAsync()).Value.ETag);
        Assert.Equal(10,(await store.ReadAsync(default)).Entries.Count);
    }

    [Fact]
    public async Task MissingSourceIsNeverInitializedByMigration()
    {
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        var settings=new ModerationOptions {Maintenance=true};var client=options.CreateClient();
        var store=new BlobHighscoreStore(client,options,TimeProvider.System,moderation:settings);
        Assert.Equal("storage_invalid",(await Assert.ThrowsAsync<HighscoreFailure>(()=>ModerationMigration.ApplyAsync(store,client,options,settings,"\"missing\"",TimeProvider.System,default))).Code);
        Assert.False(await fixture.Container.GetBlobClient(options.BlobName).ExistsAsync());
    }
}
