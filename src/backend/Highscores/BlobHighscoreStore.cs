using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System.Text.Json;

namespace DonkeyTrump.Highscores;

public sealed class BlobHighscoreStore : IHighscoreStore
{
    private readonly HighscoreDiagnostics? diagnostics;
    private readonly BlobClient blob;
    private readonly HighscoreOptions options;
    private readonly TimeProvider clock;
    private readonly Func<CancellationToken, Task> backoff;
    public BlobHighscoreStore(BlobServiceClient client, HighscoreOptions options, TimeProvider clock,
        Func<CancellationToken, Task>? backoff = null, HighscoreDiagnostics? diagnostics = null)
    {
        blob = client.GetBlobContainerClient(options.ContainerName).GetBlobClient(options.BlobName);
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
            try { document = JsonSerializer.Deserialize<HighscoreDocument>(bytes, HighscoreJson.Options) ?? throw HighscoreFailure.InvalidStorage(); }
            catch (JsonException) { throw HighscoreFailure.InvalidStorage(); }
            document.Validate();
            return (document, response.Value.Details.ETag);
        } catch (RequestFailedException e) when (e.Status == 404 && e.ErrorCode == "BlobNotFound") {
            return (HighscoreDocument.Empty, null);
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
            return HighscoreSnapshot.From(document, tag?.ToString() ?? "empty", clock.GetUtcNow());
        } catch (HighscoreFailure error) { diagnostics?.Failure(error.Code); throw; }
        catch (OperationCanceledException) { diagnostics?.Failure("operation_timed_out"); throw new HighscoreFailure(503, "operation_timed_out", "Highscores timed out"); }
        catch (Exception) { diagnostics?.Failure("service_unavailable"); throw new HighscoreFailure(503, "service_unavailable", "Highscores are unavailable"); }
    }

    public async Task<HighscoreResult> SubmitAsync(HighscoreSubmission run, CancellationToken cancellationToken)
    {
        using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(options.OperationTimeoutSeconds), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, deadline.Token);
        var token = linked.Token;
        bool uncertainWrite = false;
        try {
            for (int attempt = 1; attempt <= options.MaxWriteAttempts; attempt++) {
                token.ThrowIfCancellationRequested();
                var (current, tag) = await ReadDocument(token);
                var decision = HighscoreRanking.Evaluate(current, run, clock.GetUtcNow());
                if (!decision.RequiresWrite)
                    return HighscoreResult.From(HighscoreSnapshot.From(current, tag?.ToString() ?? "empty", clock.GetUtcNow()), run.SubmissionId);
                var bytes = decision.Document.Serialize();
                var conditions = tag is { } etag ? new BlobRequestConditions { IfMatch = etag } : new BlobRequestConditions { IfNoneMatch = ETag.All };
                token.ThrowIfCancellationRequested();
                diagnostics?.WriteAttempt(attempt);
                uncertainWrite = true;
                try {
                    // A bounded byte payload uses a single Put Blob, never staged blocks.
                    var write = await blob.UploadAsync(BinaryData.FromBytes(bytes), new BlobUploadOptions {
                        Conditions = conditions, HttpHeaders = new BlobHttpHeaders { ContentType = "application/json" }
                    }, token);
                    uncertainWrite = false;
                    return HighscoreResult.From(HighscoreSnapshot.From(decision.Document, write.Value.ETag.ToString(), clock.GetUtcNow()), run.SubmissionId);
                } catch (RequestFailedException e) when (
                    e.Status == 412 && e.ErrorCode == "ConditionNotMet" ||
                    tag is null && e.Status == 409 && e.ErrorCode == "BlobAlreadyExists") {
                    uncertainWrite = false; // This response proves this conditional write was rejected.
                    if (attempt < options.MaxWriteAttempts) await backoff(token);
                }
            }
            throw new HighscoreFailure(503, "contention_exhausted", "Highscores are busy; please play again");
        } catch (Exception) when (uncertainWrite) { diagnostics?.Failure("submission_unconfirmed"); throw HighscoreFailure.Unconfirmed(); }
        catch (HighscoreFailure error) { diagnostics?.Failure(error.Code); throw; }
        catch (OperationCanceledException) { diagnostics?.Failure("operation_timed_out"); throw new HighscoreFailure(503, "operation_timed_out", "Highscores timed out"); }
        catch (Exception) { diagnostics?.Failure("service_unavailable"); throw new HighscoreFailure(503, "service_unavailable", "Highscores are unavailable"); }
    }
}
