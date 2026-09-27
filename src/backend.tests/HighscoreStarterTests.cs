using DonkeyTrump.Highscores.Tests.Support;

namespace DonkeyTrump.Highscores.Tests;

public class HighscoreStarterTests
{
    [Fact] public void FreshListHasTenStableLowScoreOpponents()
    {
        var empty = HighscoreDocument.Empty;
        var first = HighscoreStarters.Fill(empty);
        var second = HighscoreStarters.Fill(HighscoreDocument.Empty);
        Assert.Empty(empty.Entries);
        Assert.Equal(first.Entries, second.Entries);
        Assert.Equal(10, first.Entries.Count);
        Assert.Equal(Enumerable.Range(1,10).Reverse().Select(i=>i*100), first.Entries.Select(e=>e.Score));
        Assert.Equal(10, first.Entries.Select(e=>e.SubmissionId).Distinct().Count());
        Assert.Equal(10, first.Entries.Select(e=>e.DisplayName).Distinct().Count());
        Assert.Contains(first.Entries,e=>e.DisplayName=="Bugs Bunny");
        Assert.Same(first,HighscoreStarters.Fill(first));
        first.Validate();
    }

    [Theory][InlineData(1)][InlineData(9)][InlineData(10)][InlineData(100)]
    public void ExistingPlayersAndEarlierEqualScoresArePreserved(int count)
    {
        var existing = HighscoreDocument.Empty;
        for (int i=0;i<count;i++) existing=HighscoreRanking.Evaluate(existing,
            new(Guid.NewGuid(),"Real player",1000,1),DateTimeOffset.UtcNow).Document;
        var filled=HighscoreStarters.Fill(existing);
        Assert.Equal(Math.Max(10,count),filled.Entries.Count);
        Assert.Equal(existing.Entries,filled.Entries.Take(count));
        Assert.Equal(count,existing.Entries.Count);
        Assert.Equal(filled.NextSequence-1,filled.Entries.Max(e=>e.Sequence));
        filled.Validate();
    }

    [Fact] public void PartialStarterListDoesNotDuplicateIdsOrReplaceAnExistingRow()
    {
        var seeded=HighscoreStarters.Fill(HighscoreDocument.Empty);
        var existing=seeded with {Entries=[seeded.Entries[0] with {DisplayName="Existing player"}]};
        var filled=HighscoreStarters.Fill(existing);
        Assert.Equal(10,filled.Entries.Count);
        Assert.Equal(10,filled.Entries.Select(e=>e.SubmissionId).Distinct().Count());
        Assert.Equal(existing.Entries[0],filled.Entries[0]);
        filled.Validate();
    }

    [Fact] public void RealPlayersCanDisplaceEveryStarterWithoutReplenishment()
    {
        var document=HighscoreStarters.Fill(HighscoreDocument.Empty);
        var seedIds=document.Entries.Select(e=>e.SubmissionId).ToHashSet();
        for(int i=0;i<100;i++) document=HighscoreRanking.Evaluate(document,
            new(Guid.NewGuid(),"Real player",1100,1),DateTimeOffset.UtcNow).Document;
        Assert.Same(document,HighscoreStarters.Fill(document));
        Assert.Equal(100,document.Entries.Count);
        Assert.DoesNotContain(document.Entries,e=>seedIds.Contains(e.SubmissionId));
    }

    [Theory][InlineData(false)][InlineData(true)]
    public async Task ReadFillsMissingOrPartialStorageWithoutWriting(bool missing)
    {
        using var http=new BlobHttpHandler();
        var player=new HighscoreSubmission(Guid.NewGuid(),"Existing player",0,1);
        var existing=HighscoreRanking.Evaluate(HighscoreDocument.Empty,player,DateTimeOffset.UtcNow).Document;
        http.Respond=(_,_)=>Task.FromResult(missing?BlobHttpHandler.Error(404,"BlobNotFound"):BlobHttpHandler.Document(existing.Serialize()));
        var first=await http.Store().ReadAsync(default);
        var second=await http.Store().ReadAsync(default);
        Assert.Equal(10,first.Entries.Count);Assert.Equal(first.Entries,second.Entries);
        Assert.Equal(missing?"empty":"\"v1\"",first.Revision);
        Assert.Equal(0,http.Writes);
        if(!missing) Assert.Contains(first.Entries,e=>e.EntryId==player.SubmissionId && e.Score==0);
    }

    [Fact] public async Task CorruptReadNeverBecomesAStarterList()
    {
        using var http=new BlobHttpHandler();
        http.Respond=(_,_)=>Task.FromResult(BlobHttpHandler.Document("{"u8.ToArray()));
        var failure=await Assert.ThrowsAsync<HighscoreFailure>(()=>http.Store().ReadAsync(default));
        Assert.Equal("storage_invalid",failure.Code);Assert.Equal(0,http.Writes);
        Assert.Throws<HighscoreFailure>(()=>HighscoreStarters.Fill(HighscoreDocument.Empty with {NextSequence=long.MaxValue}));
    }
}
