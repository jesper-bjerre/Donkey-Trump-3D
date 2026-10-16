using System.Text.Json;
using static DonkeyTrump.Highscores.Tests.ModerationContractTests;

namespace DonkeyTrump.Highscores.Tests;

public class HighscoreAdministrationTests
{
    [Fact]
    public void RenamePreservesRankingIdentityAndPrivateReportSnapshot()
    {
        var before=WithRun(out var id);
        before=ModerationService.Report(before,new(Guid.NewGuid(),id,"personalInformation"),Reporter,Now).Document;
        var bytes=before.Serialize();
        var after=HighscoreAdministration.Rename(before,id,"  Rene\u0301  ");
        Assert.Equal("René",after.Entries[0].DisplayName);
        Assert.Equal(before.Entries[0],after.Entries[0] with {DisplayName=before.Entries[0].DisplayName});
        Assert.Equal(before.Entries.Skip(1),after.Entries.Skip(1));
        Assert.Same(before.Reports,after.Reports);
        Assert.Equal("Player",after.Reports[0].DisplayName);
        Assert.Equal(before.NextSequence,after.NextSequence);
        Assert.Equal(bytes,before.Serialize());
        Assert.Same(after,HighscoreAdministration.Rename(after,id,"René"));
    }

    [Fact]
    public void InvalidNamesAndRemovedEntriesCannotBeRenamed()
    {
        var document=WithRun(out var id);
        Assert.Equal("operator_arguments_invalid",Assert.Throws<HighscoreFailure>(()=>HighscoreAdministration.Rename(document,id,"\nBad")).Code);
        Assert.Equal("name_rejected",Assert.Throws<HighscoreFailure>(()=>HighscoreAdministration.Rename(document,id,"shit")).Code);
        var removed=ModerationService.Remove(document,id,Guid.NewGuid(),Now);
        Assert.Equal("entry_not_found",Assert.Throws<HighscoreFailure>(()=>HighscoreAdministration.Rename(removed,id,"New name")).Code);
    }

    [Fact]
    public void RankIsReadOnlyAndRenameRejectsUnrelatedArguments()
    {
        HighscoreAdministration.ValidateArguments("entry",ModerationCommand.Parse(["entry","--target","prod","--rank","4"]));
        foreach(var raw in new[]{
            new[]{"rename","--target","prod","--rank","4","--display-name","New name","--apply"},
            new[]{"entry","--target","prod","--rank","4","--apply"},
            new[]{"entry","--target","prod","--rank","0"},
            new[]{"rename","--target","prod","--entry-id",Guid.NewGuid().ToString(),"--display-name","New name","--operation-id",Guid.NewGuid().ToString()}})
        {
            var args=ModerationCommand.Parse(raw);
            Assert.Throws<HighscoreFailure>(()=>HighscoreAdministration.ValidateArguments(args["command"],args));
        }
    }

    [Fact]
    public async Task LookupUsesPublicRankWhenVirtualStartersFillGaps()
    {
        var full=Document();var stored=full.Entries[^1];
        var store=new CommandStore(full with {Entries=[stored]});
        var args=ModerationCommand.Parse(["entry","--target","local","--entry-id",stored.SubmissionId.ToString()]);
        var output=new StringWriter();
        await HighscoreAdministration.RunAsync("entry",args,store,output,CancellationToken.None);
        using var json=JsonDocument.Parse(output.ToString());
        Assert.Equal(10,json.RootElement.GetProperty("rank").GetInt32());
        args=ModerationCommand.Parse(["entry","--target","local","--rank","1"]);
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>HighscoreAdministration.RunAsync("entry",args,store,new StringWriter(),CancellationToken.None));
        Assert.Equal("entry_not_found",failure.Code);Assert.Equal(0,store.Mutations);
    }

    [Fact]
    public async Task PreviewNeverWritesAndApplyPinsInspectedRevision()
    {
        var document=WithRun(out var id);var store=new CommandStore(document);var output=new StringWriter();
        var args=ModerationCommand.Parse(["rename","--target","local","--entry-id",id.ToString(),"--display-name","New name"]);
        await HighscoreAdministration.RunAsync("rename",args,store,output,CancellationToken.None);
        Assert.Equal(0,store.Mutations);
        using(var preview=JsonDocument.Parse(output.ToString())) Assert.True(preview.RootElement.GetProperty("preview").GetBoolean());
        args["--apply"]="true";
        await HighscoreAdministration.RunAsync("rename",args,store,new StringWriter(),CancellationToken.None);
        Assert.Equal(1,store.Mutations);Assert.Equal("revision-1",store.ExpectedETag);
        Assert.Equal("New name",store.Document.Entries[0].DisplayName);
        await HighscoreAdministration.RunAsync("rename",args,store,new StringWriter(),CancellationToken.None);
        Assert.Equal(1,store.Mutations);
        args["--expected-etag"]="old-preview";
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>HighscoreAdministration.RunAsync("rename",args,store,new StringWriter(),CancellationToken.None));
        Assert.Equal("revision_changed",failure.Code);Assert.Equal(1,store.Mutations);
    }

    private sealed class CommandStore(HighscoreDocument document) : IModerationStore
    {
        public HighscoreDocument Document=document;
        public int Mutations;
        public string? ExpectedETag;
        public Task<AggregateRead> ReadAggregateAsync(CancellationToken token)=>Task.FromResult(new AggregateRead(Document,"revision-1"));
        public Task<AggregateRead> MutateAsync(Func<HighscoreDocument,DateTimeOffset,HighscoreDocument> transition,string code,CancellationToken token,bool migration=false,string? expectedETag=null)
        { Mutations++;ExpectedETag=expectedETag;Document=transition(Document,Now);return Task.FromResult(new AggregateRead(Document,"revision-2")); }
        public Task<HighscoreResult> PublishAsync(HighscoreSubmission run,string hash,CancellationToken token)=>throw new NotSupportedException();
        public Task<(ReportReceipt Receipt,bool Created)> ReportAsync(ReportSubmission report,string hash,CancellationToken token)=>throw new NotSupportedException();
        public Task<ReportReceipt> ReceiptAsync(Guid id,string hash,CancellationToken token)=>throw new NotSupportedException();
    }
}
