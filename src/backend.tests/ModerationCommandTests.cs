namespace DonkeyTrump.Highscores.Tests;
public class ModerationCommandTests
{
    [Fact]
    public void CloudTargetRequiresMatchingAppAndManagedIdentityContext()
    {
        var options=new HighscoreOptions {BlobServiceUri="https://donkeytrumpp.blob.core.windows.net"};
        Assert.Throws<HighscoreFailure>(()=>ModerationCommand.ValidateTarget("prod",options,_=>null));
        string? Environment(string name)=>name switch {"WEBSITE_SITE_NAME"=>"donkeytrump-api-p","IDENTITY_ENDPOINT"=>"fixture","IDENTITY_HEADER"=>"fixture",_=>null};
        ModerationCommand.ValidateTarget("prod",options,Environment);
        Assert.Throws<HighscoreFailure>(()=>ModerationCommand.ValidateTarget("dev",options,Environment));
        options.ContainerName="other";Assert.Throws<HighscoreFailure>(()=>ModerationCommand.ValidateTarget("prod",options,Environment));
    }
    [Fact]
    public void LocalOperatorRefusesCloudOrUnownedContainersAndUnknownArguments()
    {
        Assert.Throws<HighscoreFailure>(()=>ModerationCommand.ValidateTarget("local",new(){UseAzurite=true,ContainerName="highscores"},_=>null));
        ModerationCommand.ValidateTarget("local",new(){UseAzurite=true,ContainerName="highscores-release-validation"},_=>null);
        Assert.Throws<HighscoreFailure>(()=>ModerationCommand.Parse(["list","--target","local","--storage-key","fixture"]));
        Assert.Throws<HighscoreFailure>(()=>ModerationCommand.Parse(["list","--target","local","--target","prod"]));
    }
}
