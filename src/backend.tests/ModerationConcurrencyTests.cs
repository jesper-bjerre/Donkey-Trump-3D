using DonkeyTrump.Highscores;
using static DonkeyTrump.Highscores.Tests.ModerationContractTests;

namespace DonkeyTrump.Highscores.Tests;

public class ModerationConcurrencyTests
{
    [Fact]
    public void BlockingClosesAllRemovedRowReportsWithoutInventingAcknowledgement()
    {
        var d=WithRun(out var first); var second=Guid.NewGuid();
        d=ModerationService.Submit(d,new(second,"Player Two",6000,2),Producer,Now);
        var reports = new[] { Guid.NewGuid(),Guid.NewGuid(),Guid.NewGuid() };
        d=ModerationService.Report(d,new(reports[0],first,"other"),Reporter,Now).Document;
        d=ModerationService.Report(d,new(reports[1],first,"offensiveName"),new string('c',64),Now).Document;
        d=ModerationService.Report(d,new(reports[2],second,"other"),Reporter,Now).Document;
        var operation=Guid.NewGuid();
        d=ModerationService.Resolve(d,reports[0],"remove-and-block",operation,Now.AddHours(1));
        Assert.All(d.Reports, r => { Assert.Equal("resolved",r.Status); Assert.Equal("removedAndBlocked",r.Disposition); Assert.Equal(operation,r.ResolvedOperationId); Assert.Null(r.AcknowledgedAtUtc); });
        Assert.Contains(first,d.RemovedSubmissionIds); Assert.Contains(second,d.RemovedSubmissionIds);
        Assert.Equal("publication_blocked",Assert.Throws<HighscoreFailure>(() => ModerationService.Submit(d,new(Guid.NewGuid(),"New Name",9000,1),Producer,Now)).Code);
        // Blocking publication does not block report reads or submissions.
        Assert.Equal("resolved",ModerationService.Receipt(d,reports[0],Reporter,Now).Status);
        var starter=d.Entries.First();
        Assert.Equal("pending",ModerationService.Report(d,new(Guid.NewGuid(),starter.SubmissionId,"other"),Producer,Now).Receipt.Status);
    }

    [Fact]
    public void AlreadyRemovedEntryCanCloseAnOutstandingReportWithoutRestoringTheRow()
    {
        var d=WithRun(out var id); var report=Guid.NewGuid();
        d=ModerationService.Report(d,new(report,id,"other"),Reporter,Now).Document;
        d=d with {Entries=d.Entries.Where(e=>e.SubmissionId!=id).ToList(),RemovedSubmissionIds=[id]};
        var operation=Guid.NewGuid();
        var repaired=ModerationService.Remove(d,id,operation,Now.AddHours(1));
        Assert.Equal("removed",repaired.Reports.Single().Disposition);
        Assert.Equal(operation,repaired.Reports.Single().ResolvedOperationId);
        Assert.Null(repaired.Reports.Single().AcknowledgedAtUtc);
        Assert.DoesNotContain(repaired.Entries,e=>e.SubmissionId==id);
        Assert.Single(repaired.RemovedSubmissionIds);
    }

    [Fact]
    public void OldUnblockCannotLiftNewBlockAfterAuditExpiry()
    {
        var d=WithRun(out var id); var report=Guid.NewGuid();
        d=ModerationService.Report(d,new(report,id,"other"),Reporter,Now).Document;
        d=ModerationService.Resolve(d,report,"remove-and-block",Guid.NewGuid(),Now);
        var oldBlock=d.BlockedInstallations.Single().BlockId;
        d=ModerationService.Unblock(d,Producer,oldBlock,Guid.NewGuid(),Now);
        var next=Guid.NewGuid();
        d=ModerationService.Submit(d,new(next,"New Player",7000,1),Producer,Now);
        report=Guid.NewGuid(); d=ModerationService.Report(d,new(report,next,"other"),Reporter,Now).Document;
        d=ModerationService.Resolve(d,report,"remove-and-block",Guid.NewGuid(),Now);
        d=ModerationRetention.Purge(d,Now.AddDays(31));
        Assert.NotEqual(oldBlock,d.BlockedInstallations.Single().BlockId);
        Assert.Equal("block_changed",Assert.Throws<HighscoreFailure>(()=>ModerationService.Unblock(d,Producer,oldBlock,Guid.NewGuid(),Now.AddDays(31))).Code);
    }

    [Fact]
    public void StarterExhaustionDoesNotUndoRemovalOrResurrectNames()
    {
        var d=Document();
        foreach(var id in HighscoreStarters.ReservedIds) d=ModerationService.Remove(d,id,Guid.NewGuid(),Now);
        Assert.Equal(32,d.RemovedSubmissionIds.Count);
        Assert.Equal("moderation_capacity",Assert.Throws<HighscoreFailure>(()=>HighscoreStarters.Fill(d)).Code);
    }

    [Fact]
    public void BulkSpamRejectsWholeSelectionAndThenFreesQueueWithoutSnapshots()
    {
        var d=WithRun(out var id); var report=Guid.NewGuid();
        d=ModerationService.Report(d,new(report,id,"other"),Reporter,Now).Document;
        Assert.Throws<HighscoreFailure>(()=>ModerationService.DismissSpam(d,[report,Guid.NewGuid()],Guid.NewGuid(),Now));
        Assert.Single(d.Reports);
        d=ModerationService.DismissSpam(d,[report],Guid.NewGuid(),Now);
        Assert.Empty(d.Reports); Assert.Single(d.SpamReceipts);
        Assert.Equal("dismissedSpam",ModerationService.Receipt(d,report,Reporter,Now).Disposition);
        Assert.Empty(ModerationRetention.Purge(d,Now.AddDays(1)).SpamReceipts);
    }
}

[Trait("Category","StorageIntegration")]
public class ModerationStorageRaceTests(DonkeyTrump.Highscores.Tests.Support.AzuriteFixture fixture) : IClassFixture<DonkeyTrump.Highscores.Tests.Support.AzuriteFixture>
{
    [Fact]
    public async Task SubmitAndBlockRecomputeOnConflictAndNeverLeaveBlockedRows()
    {
        var d=WithRun(out var id); var report=Guid.NewGuid();
        d=ModerationService.Report(d,new(report,id,"other"),Reporter,Now).Document;
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        await fixture.Container.GetBlobClient(options.BlobName).UploadAsync(BinaryData.FromBytes(d.Serialize()));
        var barrier=new DonkeyTrump.Highscores.Tests.Support.AsyncBarrier(2);
        BlobHighscoreStore Store() {
            var reads=0; var transport=new DonkeyTrump.Highscores.Tests.Support.BlobFaultTransport { After=async message=> {
                if(message.Request.Method==Azure.Core.RequestMethod.Get && Interlocked.Increment(ref reads)==1) await barrier.ArriveAsync(message.CancellationToken);
            }};
            var sdk=options.ClientOptions();sdk.Transport=transport;
            return new(options.CreateClient(sdk),options,TimeProvider.System);
        }
        var first=Store();var second=Store();
        var publication=Task.Run(async()=> {try {await first.PublishAsync(new(Guid.NewGuid(),"Another Name",10000,1),Producer,default);}
            catch(HighscoreFailure e) {Assert.Equal("publication_blocked",e.Code);} });
        var removal=second.MutateAsync((current,time)=>ModerationService.Resolve(current,report,"remove-and-block",Guid.NewGuid(),time),"operation_unconfirmed",default);
        await Task.WhenAll(publication,removal);
        var final=await new BlobHighscoreStore(options.CreateClient(),options,TimeProvider.System).ReadAggregateAsync(default);
        Assert.Single(final.Document.BlockedInstallations);
        Assert.DoesNotContain(final.Document.Entries,e=>e.InstallationHash==Producer);
        Assert.Equal("removedAndBlocked",ModerationService.Receipt(final.Document,report,Reporter,DateTimeOffset.UtcNow).Disposition);
    }

    [Fact]
    public async Task ReportCommittedWithoutAcknowledgementIsReadableButNeverAutomaticallyRetried()
    {
        var d=WithRun(out var id);var report=Guid.NewGuid();var puts=0;
        var options=new HighscoreOptions {UseAzurite=true,ContainerName=fixture.Options.ContainerName,BlobName=Guid.NewGuid()+".json"};
        await fixture.Container.GetBlobClient(options.BlobName).UploadAsync(BinaryData.FromBytes(d.Serialize()));
        var transport=new DonkeyTrump.Highscores.Tests.Support.BlobFaultTransport {After=message=> {
            if(message.Request.Method==Azure.Core.RequestMethod.Put && message.Response.Status==201) {puts++;throw new IOException("Lost acknowledgement fixture");}
            return ValueTask.CompletedTask;
        }};
        var sdk=options.ClientOptions();sdk.Transport=transport;
        var store=new BlobHighscoreStore(options.CreateClient(sdk),options,TimeProvider.System);
        Assert.Equal("report_unconfirmed",(await Assert.ThrowsAsync<HighscoreFailure>(()=>store.ReportAsync(new(report,id,"other"),Reporter,default))).Code);
        Assert.Equal(1,puts);
        var other=new BlobHighscoreStore(options.CreateClient(),options,TimeProvider.System);
        Assert.Equal("pending",(await other.ReceiptAsync(report,Reporter,default)).Status);
    }
}

public class ModerationCapacityTests
{
    [Fact]
    public void AllPendingClosuresFitReservedBytesWithoutEvictingAcceptedReports()
    {
        var d=Document();var id=d.Entries[0].SubmissionId;
        // A maximum-byte name using one extended grapheme; JSON escaping is much larger than UTF-8.
        var name="A"+new string('\u0301',126);
        name=HighscoreValidation.NormalizeName(name)!;
        var reports=new List<ModerationReport>();
        for(int i=1;i<=100;i++) reports.Add(new() {ReportId=Guid.NewGuid(),ReporterHash=i.ToString("x64"),EntryId=id,Reason="other",CreatedAtUtc=Now,DisplayName=name,Origin="starter",Status="pending"});
        d=d with {Reports=reports};
        while(d.Reports.Count<1000) {
            var next=d with {Reports=d.Reports.Append(new ModerationReport {ReportId=Guid.NewGuid(),ReporterHash=new string('f',64),EntryId=Guid.NewGuid(),Reason="personalInformation",CreatedAtUtc=Now,DisplayName=name,Origin="legacy",Status="resolved",ResolvedAtUtc=Now,Disposition="noAction",ResolvedOperationId=Guid.NewGuid()}).ToList()};
            if(System.Text.Json.JsonSerializer.SerializeToUtf8Bytes(next,HighscoreJson.Options).Length>ModerationLimits.MaximumBytes-ModerationLimits.ReservedBytes) break;
            d=next;
        }
        var count=d.Reports.Count;
        var closed=ModerationService.Remove(d,id,Guid.NewGuid(),Now);
        Assert.Equal(count,closed.Reports.Count);Assert.All(closed.Reports,r=>Assert.Equal("resolved",r.Status));
        Assert.True(closed.Serialize().Length<=ModerationLimits.MaximumBytes);
        Assert.Contains(id,closed.RemovedSubmissionIds);
        Assert.All(closed.Reports.Where(r=>r.EntryId==id),r=>Assert.Null(r.AcknowledgedAtUtc));
    }
    [Fact]
    public void AdmissionStopsBeforeGuardLimitsAndNeverPurgesThem()
    {
        var d=Document() with {RemovedSubmissionIds=Enumerable.Range(1,3800).Select(_=>Guid.NewGuid()).ToList()};
        Assert.Equal("moderation_capacity",Assert.Throws<HighscoreFailure>(()=>ModerationService.Submit(d,new(Guid.NewGuid(),"Player",100,1),Producer,Now)).Code);
        var cleaned=ModerationRetention.Purge(d,Now.AddYears(20));Assert.Equal(d.RemovedSubmissionIds,cleaned.RemovedSubmissionIds);
    }
    [Fact]
    public void OffListSnapshotRemainsActionableAndClosedReceiptStaysImmutable()
    {
        var d=WithRun(out var id);var report=Guid.NewGuid();
        d=ModerationService.Report(d,new(report,id,"other"),Reporter,Now).Document;
        d=d with {Entries=d.Entries.Where(e=>e.SubmissionId!=id).ToList()};
        d=ModerationService.Resolve(d,report,"remove-and-block",Guid.NewGuid(),Now);
        var closed=d.Reports.Single();
        d=ModerationService.Remove(d,id,Guid.NewGuid(),Now.AddDays(1));
        Assert.Equal(closed,d.Reports.Single());Assert.Single(d.BlockedInstallations);
    }
}
