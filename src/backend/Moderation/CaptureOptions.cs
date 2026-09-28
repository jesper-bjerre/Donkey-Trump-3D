namespace DonkeyTrump.Highscores;

public sealed class CaptureOptions
{
    public bool Enabled { get; set; }
    public bool IsValid(HighscoreOptions storage,string environment,string? site)
    {
        if(!Enabled) return true;
        if(storage.UseAzurite) return environment=="Test" && storage.IsValid("Test") && storage.ContainerName.StartsWith("dt3d-test-",StringComparison.Ordinal);
        return storage.IsValid("Production") && site=="donkeytrump-api-d" &&
            storage.BlobServiceUri.TrimEnd('/')=="https://donkeytrumpd.blob.core.windows.net" &&
            storage.ContainerName=="highscores" && storage.BlobName=="global-v1.json";
    }
    public static HighscoreOptions Storage(HighscoreOptions normal) => new() {
        UseAzurite=normal.UseAzurite,AzuriteEndpoint=normal.AzuriteEndpoint,BlobServiceUri=normal.BlobServiceUri,
        ContainerName=normal.UseAzurite?normal.ContainerName+"-capture":"highscores-capture",BlobName="global-v1.json",
        ManagedIdentityClientId=normal.ManagedIdentityClientId,OperationTimeoutSeconds=normal.OperationTimeoutSeconds,
        NetworkTimeoutSeconds=normal.NetworkTimeoutSeconds,MaxWriteAttempts=normal.MaxWriteAttempts
    };
    public static T Store<T>(HttpContext context,T normal,bool capture) where T:class =>
        capture?context.RequestServices.GetRequiredKeyedService<T>("capture"):normal;
}
