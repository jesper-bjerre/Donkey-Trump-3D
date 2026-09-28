using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System.Text.Json;

namespace DonkeyTrump.Highscores;

public sealed class BlobHighscoreStore : IHighscoreStore, IModerationStore
{
    private readonly ModerationOptions moderation;
    private readonly HighscoreDiagnostics? diagnostics;
    private readonly BlobClient blob;
    private readonly HighscoreOptions options;
    private readonly TimeProvider clock;
    private readonly Func<CancellationToken, Task> backoff;
    public BlobHighscoreStore(BlobServiceClient client, HighscoreOptions options, TimeProvider clock,
        Func<CancellationToken, Task>? backoff = null, HighscoreDiagnostics? diagnostics = null, ModerationOptions? moderation = null)
    {
        blob = client.GetBlobContainerClient(options.ContainerName).GetBlobClient(options.BlobName);
        this.moderation = moderation ?? new();
        this.options = options; this.clock = clock; this.diagnostics = diagnostics;
        this.backoff = backoff ?? (token => Task.Delay(TimeSpan.FromMilliseconds(Random.Shared.Next(25, 101)), clock, token));
    }

    private async Task<(HighscoreDocument Document, ETag? ETag)> ReadDocument(CancellationToken token)
    {
        try {
            var response = await blob.DownloadStreamingAsync(cancellationToken: token);
            using var rawResponse = response.GetRawResponse();
            if (response.Value.Details.ContentLength > HighscoreDocument.MaximumBytes) throw HighscoreFailure.InvalidStorage();
            using var content = response.Value.Content;
            var bytes = await BoundedRead(content, HighscoreDocument.MaximumBytes, token);
            HighscoreDocument document;
            try { document = HighscoreDocument.Deserialize(bytes); }
            catch (JsonException) { throw HighscoreFailure.InvalidStorage(); }
            document.Validate();
            return (document, response.Value.Details.ETag);
        } catch (RequestFailedException e) when (e.Status == 404 && e.ErrorCode == "BlobNotFound") {
            throw HighscoreFailure.InvalidStorage();
        }
    }

    public static async Task<byte[]> BoundedRead(Stream stream, int limit, CancellationToken token)
    {
        using var output = new MemoryStream(); var buffer = new byte[4096];
        while (true) {
            var read = await stream.ReadAsync(buffer.AsMemory(0, Math.Min(buffer.Length, limit + 1 - (int)output.Length)), token);
            if (read == 0) break;
            output.Write(buffer, 0, read);
            if (output.Length > limit) throw HighscoreFailure.InvalidStorage();
        }
        return output.ToArray();
    }

    public async Task<HighscoreSnapshot> ReadAsync(CancellationToken cancellationToken)
    {
        using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(options.OperationTimeoutSeconds), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, deadline.Token);
        try {
            var (document, tag) = await ReadDocument(linked.Token);
            return HighscoreSnapshot.From(HighscoreStarters.Fill(document), tag?.ToString() ?? "empty", clock.GetUtcNow());
        } catch (HighscoreFailure error) { diagnostics?.Failure(error.Code); throw; }
        catch (OperationCanceledException) { diagnostics?.Failure("operation_timed_out"); throw new HighscoreFailure(503, "operation_timed_out", "Highscores timed out"); }
        catch (Exception) { diagnostics?.Failure("service_unavailable"); throw new HighscoreFailure(503, "service_unavailable", "Highscores are unavailable"); }
    }

    public async Task<AggregateRead> ReadAggregateAsync(CancellationToken cancellationToken)
    {
        using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(options.OperationTimeoutSeconds), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, deadline.Token);
        try {
            var (d,tag)=await ReadDocument(linked.Token);
            return new(d,tag!.Value.ToString());
        } catch(HighscoreFailure) { throw; }
        catch(OperationCanceledException) { throw new HighscoreFailure(503,"operation_timed_out","Highscores timed out"); }
        catch(Exception) { throw new HighscoreFailure(503,"service_unavailable","Highscores are unavailable"); }
    }

    public async Task<AggregateRead> MutateAsync(Func<HighscoreDocument,DateTimeOffset,HighscoreDocument> transition,string unconfirmedCode,
        CancellationToken cancellationToken,bool migration=false,string? expectedETag=null)
    {
        if(moderation.Maintenance && !migration) throw new HighscoreFailure(503,"service_maintenance","Highscores are being maintained");
        if(migration && !moderation.Maintenance) throw new HighscoreFailure(409,"maintenance_required","Enable maintenance before migration");
        using var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(options.OperationTimeoutSeconds),clock);
        using var linked=CancellationTokenSource.CreateLinkedTokenSource(cancellationToken,deadline.Token);
        var token=linked.Token; bool uncertain=false;
        try {
            for(int attempt=1;attempt<=options.MaxWriteAttempts;attempt++) {
                var (current,tag)=await ReadDocument(token);
                if(expectedETag is not null && tag.ToString()!=expectedETag) throw new HighscoreFailure(409,"revision_changed","Aggregate revision changed");
                if(current.SchemaVersion!=2 && !migration) throw new HighscoreFailure(503,"service_maintenance","Highscores are being maintained");
                var next=transition(ModerationRetention.Purge(current,clock.GetUtcNow()),clock.GetUtcNow());
                var bytes=next.Serialize();
                if(current.Serialize().AsSpan().SequenceEqual(bytes)) return new(current,tag!.Value.ToString());
                token.ThrowIfCancellationRequested(); uncertain=true;
                try {
                    var response=await blob.UploadAsync(BinaryData.FromBytes(bytes),new BlobUploadOptions {
                        Conditions=new BlobRequestConditions {IfMatch=tag}, HttpHeaders=new BlobHttpHeaders {ContentType="application/json"}
                    },token);
                    uncertain=false; return new(next,response.Value.ETag.ToString());
                } catch(RequestFailedException e) when(e.Status==412 && e.ErrorCode=="ConditionNotMet") {
                    uncertain=false; if(attempt<options.MaxWriteAttempts) await backoff(token);
                }
            }
            throw new HighscoreFailure(503,"contention_exhausted","Highscores are busy");
        } catch(Exception) when(uncertain) { throw new HighscoreFailure(503,unconfirmedCode,"The operation could not be confirmed"); }
        catch(HighscoreFailure) { throw; }
        catch(OperationCanceledException) { throw new HighscoreFailure(503,"operation_timed_out","Highscores timed out"); }
        catch(Exception) { throw new HighscoreFailure(503,"service_unavailable","Highscores are unavailable"); }
    }

    public async Task<HighscoreResult> PublishAsync(HighscoreSubmission run,string hash,CancellationToken token)
    {
        var saved=await MutateAsync((d,now)=>ModerationService.Submit(d,run,hash,now),"submission_unconfirmed",token);
        return HighscoreResult.From(HighscoreSnapshot.From(HighscoreStarters.Fill(saved.Document),saved.ETag,clock.GetUtcNow()),run.SubmissionId);
    }
    public async Task<(ReportReceipt Receipt,bool Created)> ReportAsync(ReportSubmission report,string hash,CancellationToken token)
    {
        ReportDecision? decision=null;
        await MutateAsync((d,now)=> {decision=ModerationService.Report(d,report,hash,now);return decision.Document;},"report_unconfirmed",token);
        return (decision!.Receipt,decision.Created);
    }
    public async Task<ReportReceipt> ReceiptAsync(Guid id,string hash,CancellationToken token)
    {
        var current=await ReadAggregateAsync(token);
        return ModerationService.Receipt(current.Document,id,hash,clock.GetUtcNow());
    }

}
