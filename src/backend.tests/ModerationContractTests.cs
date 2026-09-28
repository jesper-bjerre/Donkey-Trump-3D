using System.Text.Json;
using DonkeyTrump.Highscores;

namespace DonkeyTrump.Highscores.Tests;

public class ModerationContractTests
{
    internal static readonly DateTimeOffset Now = new(2026, 9, 27, 12, 0, 0, TimeSpan.Zero);
    internal static readonly string Producer = new('a', 64);
    internal static readonly string Reporter = new('b', 64);
    internal static HighscoreDocument Document() => HighscoreStarters.Fill(ModerationMigration.Convert(HighscoreDocument.Empty));
    internal static HighscoreDocument WithRun(out Guid id)
    {
        id = Guid.NewGuid();
        return ModerationService.Submit(Document(), new(id, "Player", 5000, 1), Producer, Now);
    }

    [Fact]
    public void CredentialRequiresCanonicalRandomByteEncoding()
    {
        var secret = Convert.ToBase64String(new byte[32]).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        Assert.Equal("66687aadf862bd776c8fc18b8e9f8e20089714856ee233b3902a591d0d5f2925", InstallationCredential.Hash("Bearer " + secret));
        foreach (var invalid in new[] { secret, "Bearer " + secret + "=", "Bearer " + secret[..42] + "B", "Bearer " + new string('!',43), "Bearer " + secret + ",Bearer " + secret })
            Assert.Equal("installation_credential_invalid", Assert.Throws<HighscoreFailure>(() => InstallationCredential.Hash(invalid)).Code);
    }

    [Fact]
    public void MigrationPreservesOrderAndSeparatesPrivateMetadata()
    {
        var original = HighscoreStarters.Fill(HighscoreDocument.Empty);
        var migrated = ModerationMigration.Convert(original);
        Assert.Equal(2, migrated.SchemaVersion);
        Assert.Equal(original.NextSequence, migrated.NextSequence);
        Assert.Equal(original.Entries.Select(x => x.SubmissionId), migrated.Entries.Select(x => x.SubmissionId));
        migrated.Validate();
        var json = JsonSerializer.Serialize(HighscoreSnapshot.From(migrated, "etag", Now), HighscoreJson.Options);
        Assert.DoesNotContain("installationHash", json);
        Assert.DoesNotContain("reports", json);
        Assert.DoesNotContain("origin", json);
    }

    [Fact]
    public void RankedIdentityCannotBeClaimedAndRemovalSurvivesAnotherCredential()
    {
        var document = WithRun(out var id);
        Assert.Equal("submission_conflict", Assert.Throws<HighscoreFailure>(() => ModerationService.Submit(document, new(id,"Player",5000,1),Reporter,Now)).Code);
        document = ModerationService.Remove(document, id, Guid.NewGuid(), Now);
        Assert.Equal("submission_removed", Assert.Throws<HighscoreFailure>(() => ModerationService.Submit(document, new(id,"Player",6000,1),Reporter,Now)).Code);
        Assert.DoesNotContain(HighscoreStarters.Fill(document).Entries, x => x.SubmissionId == id);
    }

    [Fact]
    public void DuplicatePendingUsesCanonicalIdAndReceiptsArePrivate()
    {
        var document = WithRun(out var id); var first = Guid.NewGuid();
        document = ModerationService.Report(document, new(first,id,"other"), Reporter, Now).Document;
        var duplicate = ModerationService.Report(document, new(Guid.NewGuid(),id,"offensiveName"), Reporter, Now);
        Assert.Equal(first, duplicate.Receipt.ReportId); Assert.True(duplicate.Receipt.AlreadyPending);
        Assert.Equal("report_not_found", Assert.Throws<HighscoreFailure>(() => ModerationService.Receipt(document,first,Producer,Now)).Code);
        Assert.Equal("report_conflict", Assert.Throws<HighscoreFailure>(() => ModerationService.Report(document,new(first,id,"impersonation"),Reporter,Now)).Code);
    }

    [Fact]
    public void ExpiryIsLogicalOnReadButNeverExpiresPendingOrGuards()
    {
        var document = WithRun(out var id); var report = Guid.NewGuid();
        document = ModerationService.Report(document,new(report,id,"other"),Reporter,Now).Document;
        Assert.Equal("pending", ModerationService.Receipt(document,report,Reporter,Now.AddYears(1)).Status);
        document = ModerationService.Resolve(document,report,"remove-and-block",Guid.NewGuid(),Now);
        Assert.Equal("report_not_found",Assert.Throws<HighscoreFailure>(() => ModerationService.Receipt(document,report,Reporter,Now.AddDays(30))).Code);
        var purged = ModerationRetention.Purge(document, Now.AddDays(31));
        Assert.Empty(purged.Reports); Assert.Empty(purged.OperatorAudit);
        Assert.Contains(id,purged.RemovedSubmissionIds); Assert.Single(purged.BlockedInstallations);
    }
}
