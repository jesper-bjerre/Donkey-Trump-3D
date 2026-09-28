using System.Net;
using DonkeyTrump.Highscores.Tests.Support;
using static DonkeyTrump.Highscores.Tests.ModerationContractTests;
namespace DonkeyTrump.Highscores.Tests;

public class ModerationOperationsTests
{
    [Theory]
    [InlineData("2026-03-27T11:00:00Z","2026-03-30T10:00:00Z")]
    [InlineData("2026-10-23T10:00:00Z","2026-10-26T11:00:00Z")]
    [InlineData("2026-09-28T10:00:00Z","2026-09-29T10:00:00Z")]
    [InlineData("2026-09-27T10:00:00Z","2026-09-28T10:00:00Z")]
    public void OwnerDeadlineUsesNextWeekdaySameCopenhagenTime(string created,string expected)
        => Assert.Equal(DateTimeOffset.Parse(expected),ModerationResponseDeadline.For(DateTimeOffset.Parse(created)));

    [Fact]
    public void CleanupAgeOnlyMeasuresExpiredRecordsAndPurgePreservesPendingAndGuards()
    {
        var document=WithRun(out var id);var first=Guid.NewGuid();
        document=ModerationService.Report(document,new(first,id,"other"),Reporter,Now).Document;
        Assert.Equal(0,ModerationRetention.OldestOverdueSeconds(document,Now.AddYears(1)));
        document=ModerationService.Resolve(document,first,"remove-and-block",Guid.NewGuid(),Now);
        Assert.Equal(60,ModerationRetention.OldestOverdueSeconds(document,Now.AddDays(30).AddMinutes(1)));
        var purged=ModerationRetention.Purge(document,Now.AddDays(31));
        Assert.Equal(0,ModerationRetention.OldestOverdueSeconds(purged,Now.AddDays(31)));
        Assert.Contains(id,purged.RemovedSubmissionIds);Assert.Single(purged.BlockedInstallations);
    }
}

public class PublicPageTests
{
    [Theory][InlineData("/support")][InlineData("/privacy")][InlineData("/support/")][InlineData("/privacy/")]
    public async Task PublicPagesAreAnonymousAccessibleAndDoNotSetCookies(string path)
    {
        await using var app=new HighscoreApiFactory();using var client=app.CreateClient();
        using var response=await client.GetAsync(path);
        Assert.True(response.StatusCode==HttpStatusCode.OK,string.Join("\n",app.Logs));
        Assert.Equal("text/html",response.Content.Headers.ContentType?.MediaType);
        Assert.False(response.Headers.Contains("Set-Cookie"));
        var html=await response.Content.ReadAsStringAsync();
        Assert.Contains("Jesper Bjerre",html);Assert.Contains("lang=\"en\"",html);
        Assert.Contains("/support",html);Assert.Contains("/privacy",html);
        Assert.DoesNotContain("<script",html,StringComparison.OrdinalIgnoreCase);
        Assert.Contains("github.com/jesper-bjerre/Donkey-Trump-3D/issues/new",html);
    }
}
