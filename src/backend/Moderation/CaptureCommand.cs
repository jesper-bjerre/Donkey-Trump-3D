using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace DonkeyTrump.Highscores;

public static class CaptureCommand
{
    public static async Task ExecuteAsync(string command,string target,bool apply,HighscoreOptions options,CaptureOptions capture,TextWriter output,CancellationToken cancellationToken)
    {
        if(target=="prod" || target is not ("dev" or "local") || command is not ("capture-seed" or "capture-delete")) throw new HighscoreFailure(400,"capture_target_invalid","Capture is DEV-only");
        var enabled=new CaptureOptions {Enabled=true};
        if(!enabled.IsValid(options,target=="local"?"Test":"Production",Environment.GetEnvironmentVariable("WEBSITE_SITE_NAME")) || command=="capture-seed" && !capture.Enabled)
            throw new HighscoreFailure(400,"capture_target_invalid","Capture isolation is not configured");
        using var deadline=CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);deadline.CancelAfter(TimeSpan.FromSeconds(6));
        var token=deadline.Token;var selected=CaptureOptions.Storage(options);
        var blob=options.CreateClient().GetBlobContainerClient(selected.ContainerName).GetBlobClient(selected.BlobName);
        BlobProperties? previous=null;
        try {previous=(await blob.GetPropertiesAsync(cancellationToken:token)).Value;}
        catch(RequestFailedException error) when(error.Status==404 && error.ErrorCode=="BlobNotFound") { }
        if(previous is not null && (!previous.Metadata.TryGetValue("owner",out var owner) || owner!="dt3d-capture"))
            throw new HighscoreFailure(409,"capture_ownership_unknown","Refusing to replace an unowned capture dataset");
        await output.WriteLineAsync("{\"preview\":true,\"captureOnly\":true}");
        if(!apply) return;
        if(command=="capture-delete") {
            if(previous is not null) await blob.DeleteAsync(conditions:new BlobRequestConditions {IfMatch=previous.ETag},cancellationToken:token);
        } else {
            var document=HighscoreStarters.Fill(ModerationMigration.Convert(HighscoreDocument.Empty));
            await blob.UploadAsync(BinaryData.FromBytes(document.Serialize()),new BlobUploadOptions {
                Conditions=previous is null?new BlobRequestConditions {IfNoneMatch=ETag.All}:new BlobRequestConditions {IfMatch=previous.ETag},
                Metadata=new Dictionary<string,string> {["owner"]="dt3d-capture"},HttpHeaders=new BlobHttpHeaders {ContentType="application/json"}
            },token);
        }
        await output.WriteLineAsync("{\"applied\":true,\"captureOnly\":true}");
    }
}
