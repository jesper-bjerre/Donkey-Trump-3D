namespace DonkeyTrump.Highscores;

/// Pure transitions. Callers must re-run the entire transition after every ETag conflict.
/// Every returned collection is new; rejected transitions cannot mutate their input.
public static class ModerationService
{
    private static HighscoreFailure Failure(int status,string code,string title) => new(status,code,title);
    private static HighscoreDocument Ready(HighscoreDocument d,DateTimeOffset now)
    {
        d.Validate();
        if(d.SchemaVersion!=2) throw Failure(503,"service_maintenance","Highscores are being maintained");
        return ModerationRetention.Purge(d,now);
    }
    private static void Hash(string hash) { if(!InstallationCredential.ValidHash(hash)) throw Failure(401,"installation_credential_invalid","Online publication is unavailable"); }
    private static void Operation(HighscoreDocument d,Guid id)
    {
        if(id==Guid.Empty) throw HighscoreFailure.Malformed();
        if(d.OperatorAudit.Any(a=>a.OperationId==id)) throw Failure(409,"operation_conflict","Operation identity has already been used");
    }
    private static HighscoreDocument Finish(HighscoreDocument d,Guid operation,string action,int count,DateTimeOffset now)
    {
        d=d with { OperatorAudit=d.OperatorAudit.Append(new(operation,action,now,count)).TakeLast(ModerationLimits.MaximumAudit).ToList() };
        // Audit is optional trace. Never compact guards or genuine reports for space.
        while(System.Text.Json.JsonSerializer.SerializeToUtf8Bytes(d,HighscoreJson.Options).Length>ModerationLimits.MaximumBytes && d.OperatorAudit.Count>0)
            d=d with {OperatorAudit=d.OperatorAudit.Skip(1).ToList()};
        ModerationLimits.CheckGrowth(d,true); return d;
    }
    public static HighscoreDocument Submit(HighscoreDocument d,HighscoreSubmission run,string hash,DateTimeOffset now)
    {
        Hash(hash); d=Ready(d,now);
        if(d.BlockedInstallations.Any(b=>b.InstallationHash==hash)) throw Failure(403,"publication_blocked","Publication is blocked for this installation");
        if(d.RemovedSubmissionIds.Contains(run.SubmissionId)) throw Failure(409,"submission_removed","This result has been removed");
        if(HighscoreStarters.ReservedIds.Contains(run.SubmissionId)) throw Failure(409,"submission_conflict","This result identity is reserved");
        var existing=d.Entries.FirstOrDefault(e=>e.SubmissionId==run.SubmissionId);
        if(existing is not null && (existing.Origin!="installation" || existing.InstallationHash!=hash)) throw Failure(409,"submission_conflict","This run belongs to another installation");
        if(!NameModerationPolicy.Allowed(run.DisplayName)) throw Failure(422,"name_rejected","Choose a different name");
        if(existing is null) ModerationLimits.AdmitScore(d);
        var decision=HighscoreRanking.Evaluate(HighscoreStarters.Fill(d),run,now,hash);
        ModerationLimits.CheckGrowth(decision.Document,false); return decision.Document;
    }
    public static ReportDecision Report(HighscoreDocument d,ReportSubmission request,string reporter,DateTimeOffset now)
    {
        Hash(reporter); d=Ready(d,now);
        if(request.ReportId==Guid.Empty || request.EntryId==Guid.Empty || !ModerationReport.ValidReason(request.Reason)) throw HighscoreFailure.Malformed();
        var same=d.Reports.FirstOrDefault(r=>r.ReportId==request.ReportId);
        if(same is not null) {
            if(same.ReporterHash!=reporter || same.EntryId!=request.EntryId || same.Reason!=request.Reason) throw Failure(409,"report_conflict","Report identity has already been used");
            return new(d,same.Receipt(),false);
        }
        // Minimal spam receipt deliberately cannot prove payload equality.
        if(d.SpamReceipts.Any(r=>r.ReportId==request.ReportId)) throw Failure(409,"report_conflict","Report identity has already been used");
        var pending=d.Reports.FirstOrDefault(r=>r.ReporterHash==reporter && r.EntryId==request.EntryId && r.Status!="resolved");
        if(pending is not null) return new(d,pending.Receipt(true),false);
        if(d.Reports.Count>=ModerationLimits.MaximumReports || d.Reports.Count(r=>r.Status!="resolved")>=ModerationLimits.MaximumPending) throw ModerationLimits.Capacity();
        d=HighscoreStarters.Fill(d);
        var entry=d.Entries.FirstOrDefault(e=>e.SubmissionId==request.EntryId) ?? throw Failure(404,"entry_not_found","This entry is no longer available");
        var report=new ModerationReport { ReportId=request.ReportId, EntryId=request.EntryId, Reason=request.Reason, ReporterHash=reporter,
            CreatedAtUtc=now,DisplayName=entry.DisplayName,Origin=entry.Origin!,InstallationHash=entry.InstallationHash,Status="pending" };
        d=d with {Reports=d.Reports.Append(report).ToList()};
        ModerationLimits.CheckGrowth(d,false); return new(d,report.Receipt(),true);
    }
    public static ReportReceipt Receipt(HighscoreDocument d,Guid id,string reporter,DateTimeOffset now)
    {
        Hash(reporter); d.Validate(); d=ModerationRetention.Purge(d,now);
        var report=d.Reports.FirstOrDefault(r=>r.ReportId==id && r.ReporterHash==reporter);
        if(report is not null) return report.Receipt();
        var spam=d.SpamReceipts.FirstOrDefault(r=>r.ReportId==id && r.ReporterHash==reporter);
        return spam?.Receipt() ?? throw Failure(404,"report_not_found","Report not found or expired");
    }
    public static HighscoreDocument Acknowledge(HighscoreDocument d,Guid reportId,Guid operation,DateTimeOffset now)
    {
        d=Ready(d,now); var r=Find(d,reportId);
        if(r.Status=="resolved") throw Failure(409,"report_resolved","This report has been resolved");
        if(r.Status=="acknowledged") return d;
        Operation(d,operation);
        d=d with {Reports=d.Reports.Select(x=>x.ReportId==reportId?x with { Status="acknowledged",AcknowledgedAtUtc=now }:x).ToList()};
        return Finish(d,operation,"acknowledge",1,now);
    }
    private static ModerationReport Find(HighscoreDocument d,Guid id) => d.Reports.FirstOrDefault(r=>r.ReportId==id) ?? throw Failure(404,"report_not_found","Report not found or expired");
    public static HighscoreDocument Resolve(HighscoreDocument d,Guid reportId,string decision,Guid operation,DateTimeOffset now)
    {
        d=Ready(d,now); var report=Find(d,reportId);
        if(decision is not ("remove" or "remove-and-block" or "no-action")) throw HighscoreFailure.Malformed();
        if(decision=="remove-and-block" && report.Origin!="installation") throw Failure(409,"installation_unknown","Legacy and starter rows have no attributable installation");
        if(report.Status=="resolved") {
            var matches=decision switch {"no-action"=>report.Disposition=="noAction","remove-and-block"=>report.Disposition=="removedAndBlocked",_=>report.Disposition is "removed" or "legacyRemoved" or "starterRemoved"};
            if(operation!=Guid.Empty && report.ResolvedOperationId==operation && matches) return d;
            throw Failure(409,"report_resolved","This report has been resolved");
        }
        Operation(d,operation);
        if(decision=="no-action") d=d with {Reports=d.Reports.Select(r=>r.ReportId==reportId?Close(r,"noAction",operation,now):r).ToList()};
        else {
            HashSet<Guid> ids=[report.EntryId];
            if(decision=="remove-and-block") {
                var producer=report.InstallationHash!;
                if(!d.BlockedInstallations.Any(b=>b.InstallationHash==producer))
                    d=d with {BlockedInstallations=d.BlockedInstallations.Append(new(producer,now,Guid.NewGuid())).ToList()};
                ids.UnionWith(d.Entries.Where(e=>e.InstallationHash==producer).Select(e=>e.SubmissionId));
            }
            d=Tombstone(d,ids,operation,now);
        }
        return Finish(d,operation,"resolve",1,now);
    }
    private static ModerationReport Close(ModerationReport r,string disposition,Guid operation,DateTimeOffset now) =>
        r with {Status="resolved",ResolvedAtUtc=now,Disposition=disposition,ResolvedOperationId=operation};
    private static HighscoreDocument Tombstone(HighscoreDocument d,HashSet<Guid> ids,Guid operation,DateTimeOffset now)
    {
        var removed=d.RemovedSubmissionIds.Concat(ids).Distinct().ToList();
        return d with { RemovedSubmissionIds=removed,Entries=d.Entries.Where(e=>!ids.Contains(e.SubmissionId)).ToList(),
            Reports=d.Reports.Select(r=>r.Status=="resolved" || !ids.Contains(r.EntryId) ? r : Close(r,r.Origin switch {
                "legacy"=>"legacyRemoved", "starter"=>"starterRemoved", _=>d.BlockedInstallations.Any(b=>b.InstallationHash==r.InstallationHash)?"removedAndBlocked":"removed"
            },operation,now)).ToList() };
    }
    public static HighscoreDocument Remove(HighscoreDocument d,Guid entryId,Guid operation,DateTimeOffset now)
    {
        d=Ready(d,now);
        if(entryId==Guid.Empty || operation==Guid.Empty) throw HighscoreFailure.Malformed();
        if(d.RemovedSubmissionIds.Contains(entryId) && !d.Reports.Any(r=>r.EntryId==entryId && r.Status!="resolved")) return d;
        if(!d.Entries.Any(e=>e.SubmissionId==entryId) && !d.Reports.Any(r=>r.EntryId==entryId) && !HighscoreStarters.ReservedIds.Contains(entryId))
            throw Failure(404,"entry_not_found","This entry is no longer available");
        Operation(d,operation); return Finish(Tombstone(d,[entryId],operation,now),operation,"remove",1,now);
    }
    public static HighscoreDocument Unblock(HighscoreDocument d,string hash,Guid expectedBlock,Guid operation,DateTimeOffset now)
    {
        Hash(hash); d=Ready(d,now);
        if(expectedBlock==Guid.Empty || operation==Guid.Empty) throw HighscoreFailure.Malformed();
        var block=d.BlockedInstallations.FirstOrDefault(b=>b.InstallationHash==hash);
        if(block is null) return d;
        if(block.BlockId!=expectedBlock) throw Failure(409,"block_changed","Block changed; inspect its current identity");
        Operation(d,operation);
        return Finish(d with {BlockedInstallations=d.BlockedInstallations.Where(b=>b.InstallationHash!=hash).ToList()},operation,"unblock",1,now);
    }
    public static HighscoreDocument DismissSpam(HighscoreDocument d,IReadOnlyList<Guid> selected,Guid operation,DateTimeOffset now)
    {
        d=Ready(d,now);
        if(selected.Count is <1 or >100 || selected.Distinct().Count()!=selected.Count || selected.Contains(Guid.Empty) || operation==Guid.Empty) throw HighscoreFailure.Malformed();
        var reports=new List<ModerationReport>();
        foreach(var id in selected) {
            if(d.SpamReceipts.Any(r=>r.ReportId==id)) continue;
            var r=Find(d,id);
            if(r.Status=="resolved") throw Failure(409,"report_resolved","Selection includes a resolved report");
            reports.Add(r);
        }
        if(reports.Count==0) return d;
        Operation(d,operation);
        d=d with { Reports=d.Reports.Where(r=>!selected.Contains(r.ReportId)).ToList(),
            SpamReceipts=d.SpamReceipts.Concat(reports.Select(r=>new SpamReceipt(r.ReportId,r.ReporterHash,"resolved",now,operation))).TakeLast(100).ToList() };
        return Finish(d,operation,"dismiss-spam",reports.Count,now);
    }
}
