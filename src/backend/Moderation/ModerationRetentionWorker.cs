using Azure.Storage.Blobs;
using Microsoft.Extensions.Options;

namespace DonkeyTrump.Highscores;

public sealed class ModerationRetentionWorker(IModerationStore store, BlobServiceClient blobs, IOptions<HighscoreOptions> options,
    ModerationOptions moderation,TimeProvider clock,ILogger<ModerationRetentionWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer=new PeriodicTimer(TimeSpan.FromMinutes(59),clock);
        do {
            if(!moderation.Maintenance) {
                try {
                    var before=await store.ReadAggregateAsync(stoppingToken);
                    logger.LogInformation("moderation_cleanup oldest_overdue_seconds={Seconds}",
                        Math.Ceiling(ModerationRetention.OldestOverdueSeconds(before.Document,clock.GetUtcNow())));
                    await store.MutateAsync((d,now)=>ModerationRetention.Purge(d,now),"operation_unconfirmed",stoppingToken);
                    await ModerationMigration.PurgeBackupAsync(blobs,options.Value,clock.GetUtcNow(),stoppingToken);
                    logger.LogInformation("moderation_cleanup status={Status}","complete");
                } catch(OperationCanceledException) when(stoppingToken.IsCancellationRequested) {break;}
                catch(Exception) {logger.LogWarning("moderation_cleanup status={Status}","deferred");}
            }
        } while(await timer.WaitForNextTickAsync(stoppingToken));
    }
}
