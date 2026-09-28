using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace DonkeyTrump.Highscores;

public static class ModerationMigration
{
    // Explicit first provisioning only: never invoked by a read, write or startup.
    // The operator must establish that this is a new, unused store, not data recovery.
    public static async Task InitializeAsync(BlobServiceClient client,HighscoreOptions options,bool apply,TextWriter output,CancellationToken cancellationToken)
    {
        using var deadline=CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);deadline.CancelAfter(TimeSpan.FromSeconds(6));
        var token=deadline.Token;var container=client.GetBlobContainerClient(options.ContainerName);
        await foreach(var item in container.GetBlobsAsync(BlobTraits.None,BlobStates.Deleted|BlobStates.Snapshots|BlobStates.Version,prefix:null,cancellationToken:token))
            throw new HighscoreFailure(409,"storage_not_empty","First provisioning requires an empty store");
        if(!apply) {await output.WriteLineAsync("{\"preview\":true,\"action\":\"initialize\",\"schemaVersion\":1}");return;}
        // Persist the original three-field format so the currently deployed writer can
        // keep serving until the new artifact is installed and explicitly converted.
        var bytes=System.Text.Json.JsonSerializer.SerializeToUtf8Bytes(new {schemaVersion=1,nextSequence=1,entries=Array.Empty<object>()});
        try {
            await container.GetBlobClient(options.BlobName).UploadAsync(BinaryData.FromBytes(bytes),new BlobUploadOptions {
                Conditions=new BlobRequestConditions {IfNoneMatch=ETag.All},HttpHeaders=new BlobHttpHeaders {ContentType="application/json"}
            },token);
        } catch(RequestFailedException e) when(e.Status is 409 or 412) {
            throw new HighscoreFailure(409,"storage_not_empty","The store has been initialized concurrently");
        }
        await output.WriteLineAsync("{\"applied\":true,\"action\":\"initialize\",\"schemaVersion\":1}");
    }

    // Pure conversion; storage backup/maintenance/conditional orchestration is separate.
    public static HighscoreDocument Convert(HighscoreDocument current)
    {
        current.Validate();
        if(current.SchemaVersion==2) return current;
        var migrated=current with { SchemaVersion=2, Entries=current.Entries.Select(e=>e with {
            Origin=HighscoreStarters.ReservedIds.Contains(e.SubmissionId)?"starter":"legacy", InstallationHash=null
        }).ToList() };
        migrated.Validate(); return migrated;
    }
    public static string BackupName(HighscoreOptions options) => "release-backups/" + System.Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(options.BlobName))) + ".json";
    public static async Task<AggregateRead> ApplyAsync(IModerationStore store,BlobServiceClient client,HighscoreOptions options,
        ModerationOptions moderation,string expectedETag,TimeProvider clock,CancellationToken cancellationToken)
    {
        if(!moderation.Maintenance) throw new HighscoreFailure(409,"maintenance_required","Enable maintenance before migration");
        using var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(6),clock);
        using var linked=CancellationTokenSource.CreateLinkedTokenSource(cancellationToken,deadline.Token);
        var token=linked.Token;
        var current=await store.ReadAggregateAsync(token);
        if(current.ETag!=expectedETag) throw new HighscoreFailure(409,"revision_changed","Aggregate revision changed");
        var backup=client.GetBlobContainerClient(options.ContainerName).GetBlobClient(BackupName(options));
        if(current.Document.SchemaVersion==2) {
            // Re-entry after a lost migration acknowledgement: do not restore the snapshot.
            await DeleteOwnedBackup(backup,token);return current;
        }
        var bytes=current.Document.Serialize();var checksum=System.Convert.ToHexStringLower(SHA256.HashData(bytes));
        try {
            await backup.UploadAsync(BinaryData.FromBytes(bytes),new BlobUploadOptions {
                Conditions=new BlobRequestConditions {IfNoneMatch=ETag.All},
                HttpHeaders=new BlobHttpHeaders {ContentType="application/json"},
                Metadata=new Dictionary<string,string> { ["owner"]="dt3d-schema2",["sourceetag"]=System.Convert.ToBase64String(Encoding.UTF8.GetBytes(expectedETag)),
                    ["sha256"]=checksum,["expiresutc"]=clock.GetUtcNow().AddHours(24).ToString("O",CultureInfo.InvariantCulture) }
            },token);
        } catch(RequestFailedException e) when(e.Status is 409 or 412) {
            var existing=await backup.GetPropertiesAsync(cancellationToken:token);
            if(!Owned(existing.Value.Metadata) || !existing.Value.Metadata.TryGetValue("sha256",out var saved) || saved!=checksum ||
               !existing.Value.Metadata.TryGetValue("sourceetag",out var etag) || etag!=System.Convert.ToBase64String(Encoding.UTF8.GetBytes(expectedETag)))
                throw new HighscoreFailure(409,"backup_conflict","A different backup already exists");
        }
        // Verify private backup content before changing the only authoritative aggregate.
        var downloaded=await backup.DownloadStreamingAsync(cancellationToken:token);
        using(var content=downloaded.Value.Content) {
            var actual=await BlobHighscoreStore.BoundedRead(content,HighscoreDocument.MaximumBytes,token);
            if(System.Convert.ToHexStringLower(SHA256.HashData(actual))!=checksum) throw HighscoreFailure.InvalidStorage();
        }
        var converted=Convert(current.Document);
        await store.MutateAsync((d,_)=>Convert(d),"migration_unconfirmed",token,migration:true,expectedETag:expectedETag);
        var verified=await store.ReadAggregateAsync(token);
        if(!verified.Document.Serialize().AsSpan().SequenceEqual(converted.Serialize())) throw HighscoreFailure.InvalidStorage();
        await DeleteOwnedBackup(backup,token);return verified;
    }
    private static bool Owned(IDictionary<string,string> metadata) => metadata.TryGetValue("owner",out var owner) && owner=="dt3d-schema2";
    private static async Task DeleteOwnedBackup(BlobClient backup,CancellationToken token)
    {
        try {
            var properties=await backup.GetPropertiesAsync(cancellationToken:token);
            if(!Owned(properties.Value.Metadata)) throw new HighscoreFailure(409,"backup_conflict","Backup ownership is unknown");
            await backup.DeleteAsync(conditions:new BlobRequestConditions {IfMatch=properties.Value.ETag},cancellationToken:token);
        } catch(RequestFailedException e) when(e.Status==404 && e.ErrorCode=="BlobNotFound") { }
    }
    public static async Task PurgeBackupAsync(BlobServiceClient client,HighscoreOptions options,DateTimeOffset now,CancellationToken cancellationToken)
    {
        using var deadline=CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);deadline.CancelAfter(TimeSpan.FromSeconds(6));
        var token=deadline.Token;var backup=client.GetBlobContainerClient(options.ContainerName).GetBlobClient(BackupName(options));
        try {
            var properties=await backup.GetPropertiesAsync(cancellationToken:token);
            if(Owned(properties.Value.Metadata) && properties.Value.Metadata.TryGetValue("expiresutc",out var text) &&
               DateTimeOffset.TryParse(text,CultureInfo.InvariantCulture,DateTimeStyles.RoundtripKind,out var expires) && expires<=now)
                await backup.DeleteAsync(conditions:new BlobRequestConditions {IfMatch=properties.Value.ETag},cancellationToken:token);
        } catch(RequestFailedException e) when(e.Status==404 && e.ErrorCode=="BlobNotFound") { }
    }

}
