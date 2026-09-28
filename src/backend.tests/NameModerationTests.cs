namespace DonkeyTrump.Highscores.Tests;
public class NameModerationTests
{
    [Theory]
    [InlineData("f.u.c.k")][InlineData("ＦＵＣＫ")][InlineData("f\u200bu\u0301ck")][InlineData("sh1t")][InlineData("Heil Hitler")][InlineData("KUSSE")]
    public void RejectsKnownAbuseAndComparisonEvasions(string name) => Assert.False(NameModerationPolicy.Allowed(name));
    [Theory]
    [InlineData("Løkke")][InlineData("Pikachu")][InlineData("Spike")][InlineData("Scunthorpe")][InlineData("Bugs Bunny")][InlineData("Søren")]
    public void PreservesBenignNames(string name) => Assert.True(NameModerationPolicy.Allowed(name));
}
