using System.Diagnostics;
using System.Net;
using System.Text;
using System.Text.Json;
using DonkeyTrump.Highscores.Tests.Support;
namespace DonkeyTrump.Highscores.Tests;

public class BlobHighscoreStoreTests
{
    private static HighscoreSubmission Run(int score=100) => new(Guid.NewGuid(),"Test",score,1);
    private static HighscoreDocument Add(HighscoreDocument doc,HighscoreSubmission run) => HighscoreRanking.Evaluate(doc,run,DateTimeOffset.UtcNow).Document;
    [Theory][InlineData(false)][InlineData(true)]
    public async Task ConditionalWriteUsesSameReadEtagAndReturnsSavedCandidateWithoutReread(bool missing) {
        using var http=new BlobHttpHandler();byte[]? uploaded=null;
        http.Respond=async(request,_)=> {
            if(request.Method==HttpMethod.Get) return missing?BlobHttpHandler.Error(404,"BlobNotFound"):BlobHttpHandler.Document(HighscoreDocument.Empty.Serialize());
            uploaded=await request.Content!.ReadAsByteArrayAsync();return BlobHttpHandler.Saved();
        };
        var run=Run();var result=await http.Store().SubmitAsync(run,default);
        Assert.Equal("ranked",result.Outcome);Assert.Equal("\"saved\"",result.Revision);Assert.Equal(run.SubmissionId,Assert.Single(result.Entries).EntryId);
        Assert.Equal(1,http.Reads);Assert.Equal(1,http.Writes);Assert.NotNull(uploaded);
        var condition=Assert.Single(http.Conditions);Assert.Equal(missing?null:"\"v1\"",condition.Match);Assert.Equal(missing?"*":null,condition.NoneMatch);Assert.Equal("",condition.Query);
    }
    [Theory][InlineData(412,"ConditionNotMet")][InlineData(409,"BlobAlreadyExists")]
    public async Task RecognizedConflictRereadsAndRecomputes(int status,string code) {
        using var http=new BlobHttpHandler();var competitor=Run(200);var current=Add(HighscoreDocument.Empty,competitor);var backoffs=0;
        http.Respond=(request,_)=>Task.FromResult(request.Method==HttpMethod.Get
            ? http.Reads==1?BlobHttpHandler.Error(404,"BlobNotFound"):BlobHttpHandler.Document(current.Serialize(),"\"competitor\"")
            :http.Writes==1?BlobHttpHandler.Error(status,code):BlobHttpHandler.Saved());
        var result=await http.Store(backoff:_=>{backoffs++;return Task.CompletedTask;}).SubmitAsync(Run(),default);
        Assert.Equal(2,http.Reads);Assert.Equal(2,http.Writes);Assert.Equal(1,backoffs);Assert.Equal(2,result.Entries.Count);
        Assert.Equal(competitor.SubmissionId,result.Entries[0].EntryId);Assert.Equal("\"competitor\"",http.Conditions[1].Match);
    }
    [Fact] public async Task ContentionStopsAtFiveUploadsAndFourBackoffs() {
        using var http=new BlobHttpHandler();int backoffs=0;
        http.Respond=(request,_)=>Task.FromResult(request.Method==HttpMethod.Get?BlobHttpHandler.Document(HighscoreDocument.Empty.Serialize()):BlobHttpHandler.Error(412,"ConditionNotMet"));
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store(backoff:_=>{backoffs++;return Task.CompletedTask;}).SubmitAsync(Run(),default));
        Assert.Equal("contention_exhausted",failure.Code);Assert.Equal(5,http.Writes);Assert.Equal(5,http.Reads);Assert.Equal(4,backoffs);
    }
    [Theory][InlineData(412,"LeaseIdMissing")][InlineData(409,"BlobAlreadyExists")][InlineData(500,"InternalError")]
    public async Task UnrecognizedWriteFailureNeverRetries(int status,string code) {
        using var http=new BlobHttpHandler();http.Respond=(request,_)=>Task.FromResult(request.Method==HttpMethod.Get?BlobHttpHandler.Document(HighscoreDocument.Empty.Serialize()):BlobHttpHandler.Error(status,code));
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store().SubmitAsync(Run(),default));
        Assert.Equal("submission_unconfirmed",failure.Code);Assert.Equal(1,http.Writes);Assert.Equal(1,http.Reads);
    }
    [Fact] public async Task CommitThenLostAcknowledgementNeverRetriesOrRereads() {
        using var http=new BlobHttpHandler();byte[]? committed=null;
        http.Respond=async(request,_)=> {
            if(request.Method==HttpMethod.Get)return BlobHttpHandler.Error(404,"BlobNotFound");
            committed=await request.Content!.ReadAsByteArrayAsync();throw new HttpRequestException("Lost acknowledgement");
        };
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store().SubmitAsync(Run(),default));
        Assert.Equal("submission_unconfirmed",failure.Code);Assert.NotNull(committed);Assert.Equal(1,http.Writes);Assert.Equal(1,http.Reads);
    }
    public static IEnumerable<object[]> InvalidDocuments() {
        yield return [Encoding.UTF8.GetBytes("{"),false];
        yield return [Encoding.UTF8.GetBytes("{\"schemaVersion\":2,\"nextSequence\":1,\"entries\":[]}"),false];
        yield return [new byte[HighscoreDocument.MaximumBytes+1],false];
        yield return [new byte[HighscoreDocument.MaximumBytes+1],true];
        var document=Add(Add(HighscoreDocument.Empty,Run()),Run(200));
        foreach(var invalid in new[]{document with {Entries=[document.Entries[0],document.Entries[0]]},
            document with {Entries=[document.Entries[0],document.Entries[1] with {Sequence=document.Entries[0].Sequence}]},
            document with {Entries=document.Entries.AsEnumerable().Reverse().ToList()},
            HighscoreDocument.Empty with {NextSequence=long.MaxValue}})
            yield return [JsonSerializer.SerializeToUtf8Bytes(invalid,HighscoreJson.Options),false];
    }
    [Theory][MemberData(nameof(InvalidDocuments))]
    public async Task InvalidDocumentFailsClosedWithoutOverwrite(byte[] bytes,bool chunked) {
        using var http=new BlobHttpHandler();http.Respond=(_,_)=>Task.FromResult(BlobHttpHandler.Document(bytes,chunked:chunked));
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store().SubmitAsync(Run(),default));
        Assert.Equal("storage_invalid",failure.Code);Assert.Equal(0,http.Writes);
    }
    [Theory][InlineData(404,"ContainerNotFound")][InlineData(403,"AuthorizationFailure")]
    public async Task MissingContainerAndAuthFailureNeverCreateEmptyRanking(int status,string code) {
        using var http=new BlobHttpHandler();http.Respond=(_,_)=>Task.FromResult(BlobHttpHandler.Error(status,code));
        var store=http.Store();Assert.Equal("service_unavailable",(await Assert.ThrowsAsync<HighscoreFailure>(()=>store.ReadAsync(default))).Code);
        await Assert.ThrowsAsync<HighscoreFailure>(()=>store.SubmitAsync(Run(),default));Assert.Equal(0,http.Writes);
    }
    [Theory][InlineData(false)][InlineData(true)]
    public async Task TotalDeadlineBoundsReadsAndWrites(bool duringWrite) {
        using var http=new BlobHttpHandler();http.Respond=async(request,token)=> {
            if(duringWrite && request.Method==HttpMethod.Get)return BlobHttpHandler.Document(HighscoreDocument.Empty.Serialize());
            await Task.Delay(Timeout.Infinite,token);throw new InvalidOperationException();
        };
        var options=new HighscoreOptions {UseAzurite=true,ContainerName="test-container",OperationTimeoutSeconds=.1,NetworkTimeoutSeconds=.1};
        var watch=Stopwatch.StartNew();var error=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store(options).SubmitAsync(Run(),default));
        Assert.Equal(duringWrite?"submission_unconfirmed":"operation_timed_out",error.Code);Assert.True(watch.Elapsed<TimeSpan.FromSeconds(1));Assert.Equal(duringWrite?1:0,http.Writes);
    }
}
