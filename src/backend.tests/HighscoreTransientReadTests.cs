using DonkeyTrump.Highscores.Tests.Support;
using static DonkeyTrump.Highscores.Tests.ModerationContractTests;
namespace DonkeyTrump.Highscores.Tests;

public class HighscoreTransientReadTests
{
    [Theory][InlineData(false)][InlineData(true)]
    public async Task TransientReadTimeoutRecoversBeforeAnyWrite(bool publish)
    {
        using var http=new BlobHttpHandler();
        http.Respond=async(request,token)=> {
            if(request.Method==HttpMethod.Put)return BlobHttpHandler.Saved();
            if(http.Reads==1)await Task.Delay(Timeout.Infinite,token);
            return BlobHttpHandler.Document(ModerationMigration.Convert(HighscoreDocument.Empty).Serialize());
        };
        var options=new HighscoreOptions {UseAzurite=true,ContainerName="test-container",NetworkTimeoutSeconds=.05};
        var store=http.Store(options);
        if(publish) {
            var id=Guid.NewGuid();
            var result=await store.PublishAsync(new(id,"UI Score Check",2600,2),Producer,default);
            Assert.Equal("ranked",result.Outcome);Assert.Contains(result.Entries,e=>e.EntryId==id && e.Score==2600);
        } else Assert.Equal(10,(await store.ReadAsync(default)).Entries.Count);
        Assert.Equal(2,http.Reads);Assert.Equal(publish?1:0,http.Writes);
    }
    [Fact] public async Task RepeatedReadTimeoutStopsAfterTwoReadsWithoutWriting()
    {
        using var http=new BlobHttpHandler();
        http.Respond=async(_,token)=> {await Task.Delay(Timeout.Infinite,token);throw new InvalidOperationException();};
        var options=new HighscoreOptions {UseAzurite=true,ContainerName="test-container",NetworkTimeoutSeconds=.05};
        var error=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store(options).PublishAsync(new(Guid.NewGuid(),"Test",2600,2),Producer,default));
        Assert.Equal("operation_timed_out",error.Code);Assert.Equal(2,http.Reads);Assert.Equal(0,http.Writes);
    }
    [Fact] public async Task ExpiredOperationDoesNotStartAnotherRead()
    {
        using var http=new BlobHttpHandler();
        http.Respond=async(_,token)=> {await Task.Delay(Timeout.Infinite,token);throw new InvalidOperationException();};
        var options=new HighscoreOptions {UseAzurite=true,ContainerName="test-container",OperationTimeoutSeconds=.05,NetworkTimeoutSeconds=2};
        await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store(options).ReadAsync(default));
        Assert.Equal(1,http.Reads);Assert.Equal(0,http.Writes);
    }
}
