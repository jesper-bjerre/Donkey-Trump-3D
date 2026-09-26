using Azure.Core;
using System.Collections.Concurrent;
using System.Text.Json;
using DonkeyTrump.Highscores.Tests.Support;
using Xunit.Abstractions;
namespace DonkeyTrump.Highscores.Tests;

[Trait("Category","StorageIntegration")]
public class HighscoreConcurrencyTests(AzuriteFixture fixture,ITestOutputHelper output) : IClassFixture<AzuriteFixture>
{
    private HighscoreOptions Options() => new() {UseAzurite=true,AzuriteEndpoint=fixture.Options.AzuriteEndpoint,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
    private static BlobHighscoreStore Store(HighscoreOptions options,BlobFaultTransport? transport=null) {
        var clientOptions=options.ClientOptions();if(transport is not null)clientOptions.Transport=transport;
        return new(options.CreateClient(clientOptions),options,TimeProvider.System);
    }
    [Theory][InlineData(false)][InlineData(true)]
    public async Task TwoInstancesRaceOnSameReadAndBothSucceed(bool existing) {
        var options=Options();var baseline=Store(options);
        if(existing)await baseline.SubmitAsync(new(Guid.NewGuid(),"Seed",0,1),default);
        var barrier=new AsyncBarrier(2);int readsA=0,readsB=0;
        var aTransport=new BlobFaultTransport {After=async message=>{if(message.Request.Method==RequestMethod.Get && Interlocked.Increment(ref readsA)==1)await barrier.ArriveAsync(message.CancellationToken);}};
        var bTransport=new BlobFaultTransport {After=async message=>{if(message.Request.Method==RequestMethod.Get && Interlocked.Increment(ref readsB)==1)await barrier.ArriveAsync(message.CancellationToken);}};
        var a=new HighscoreSubmission(Guid.NewGuid(),"Equal",100,1);var b=new HighscoreSubmission(Guid.NewGuid(),"Equal",100,1);
        var results=await Task.WhenAll(Store(options,aTransport).SubmitAsync(a,default),Store(options,bTransport).SubmitAsync(b,default));
        Assert.All(results,r=>Assert.Equal("ranked",r.Outcome));var final=await baseline.ReadAsync(default);
        Assert.Equal(existing?3:2,final.Entries.Count);Assert.Contains(final.Entries,e=>e.EntryId==a.SubmissionId);Assert.Contains(final.Entries,e=>e.EntryId==b.SubmissionId);
        var firstResult=results.Single(r=>r.Entries.Count==(existing?2:1));Assert.Equal(firstResult.EntryId,final.Entries[0].EntryId);
        var replay=await Store(options).SubmitAsync(a,default);Assert.Equal(final.Revision,replay.Revision);
        var restarted=await Store(options).ReadAsync(default);Assert.Equal(final.Entries,restarted.Entries);Assert.Equal(final.Revision,restarted.Revision);
    }
    [Fact] public async Task HundredConcurrentWritersMatchOracleIncludingCommittedUnconfirmedWrite() {
        var options=Options();var seed=Enumerable.Range(1,100).Select(i=>new HighscoreSubmission(Guid.NewGuid(),"Seed",i*100,1)).ToList();
        var doc=HighscoreDocument.Empty;foreach(var run in seed)doc=HighscoreRanking.Evaluate(doc,run,DateTimeOffset.UtcNow).Document;
        await fixture.Container.GetBlobClient(options.BlobName).UploadAsync(BinaryData.FromBytes(doc.Serialize()));
        var lostRun=new HighscoreSubmission(Guid.NewGuid(),"Unconfirmed",25_000,1);int lostPuts=0;
        var lostTransport=new BlobFaultTransport {After=message=> {
            if(message.Request.Method==RequestMethod.Put && message.Response.Status==201) {Interlocked.Increment(ref lostPuts);throw new IOException("Lost acknowledgement after committed emulator write");}
            return ValueTask.CompletedTask;
        }};
        Assert.Equal("submission_unconfirmed",(await Assert.ThrowsAsync<HighscoreFailure>(()=>Store(options,lostTransport).SubmitAsync(lostRun,default))).Code);
        Assert.Equal(1,lostPuts);Assert.Contains((await Store(options).ReadAsync(default)).Entries,e=>e.EntryId==lostRun.SubmissionId);
        var stores=new[]{Store(options),Store(options)};
        ConcurrentBag<HighscoreSubmission> acknowledged=[];ConcurrentBag<string> rejected=[];
        var writers=Enumerable.Range(101,100).Select(i=>new HighscoreSubmission(Guid.NewGuid(),"Concurrent",i*100,1)).ToArray();
        await Task.WhenAll(writers.Select(async (run,i)=> {
            try {var result=await stores[i%2].SubmitAsync(run,default);Assert.Equal("ranked",result.Outcome);acknowledged.Add(run);}
            catch(HighscoreFailure failure) {rejected.Add(failure.Code);}
        }));
        Assert.True(acknowledged.Count>=2,"A contention test must demonstrate real progress by multiple writers.");
        Assert.All(rejected,code=>Assert.Equal("contention_exhausted",code));
        var expected=seed.Concat(acknowledged).Append(lostRun).OrderByDescending(r=>r.Score).Take(100).Select(r=>r.SubmissionId).ToArray();
        var first=await Store(options).ReadAsync(default);var second=await Store(options).ReadAsync(default);
        Assert.Equal(expected,first.Entries.Select(e=>e.EntryId));Assert.Equal(first.Entries,second.Entries);Assert.Equal(first.Revision,second.Revision);
        output.WriteLine($"writers=100 acknowledged={acknowledged.Count} contentionRejected={rejected.Count}; additional confirmed-unacknowledged=1; finalRows={first.Entries.Count}; revision={first.Revision}");
    }
}
