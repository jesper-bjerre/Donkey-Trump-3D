using Azure.Core;
using Azure.Identity;
using Azure.Storage;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Options;

namespace DonkeyTrump.Highscores;

public sealed class HighscoreOptions
{
    public bool UseAzurite { get; set; }
    public string AzuriteEndpoint { get; set; } = "http://127.0.0.1:10000/devstoreaccount1";
    public string BlobServiceUri { get; set; } = "";
    public string ContainerName { get; set; } = "highscores";
    public string BlobName { get; set; } = "global-v1.json";
    public string? ManagedIdentityClientId { get; set; }
    public double OperationTimeoutSeconds { get; set; } = 6;
    public double NetworkTimeoutSeconds { get; set; } = 2;
    public int MaxWriteAttempts { get; set; } = 5;
    public HighscoreRateLimits RateLimits { get; set; } = new();

    public bool IsValid(string environment)
    {
        bool local = Uri.TryCreate(AzuriteEndpoint, UriKind.Absolute, out var emulator) && emulator.Scheme == "http" &&
            emulator.IsLoopback && emulator.AbsolutePath.TrimEnd('/') == "/devstoreaccount1" && emulator.Query == "" && emulator.Fragment == "" && emulator.UserInfo == "";
        bool production = Uri.TryCreate(BlobServiceUri, UriKind.Absolute, out var storage) && storage.Scheme == "https" &&
            !storage.IsLoopback && storage.Query == "" && storage.Fragment == "" && storage.UserInfo == "" && storage.AbsolutePath == "/";
        return (UseAzurite ? (environment is "Development" or "Test") && local : production) &&
            System.Text.RegularExpressions.Regex.IsMatch(ContainerName ?? "", "^[a-z0-9](?:[a-z0-9]|-(?!-)){1,61}[a-z0-9]$") &&
            !string.IsNullOrWhiteSpace(BlobName) && BlobName.Length <= 1024 && !BlobName.Any(char.IsControl) &&
            OperationTimeoutSeconds is > 0 and <= 6 && NetworkTimeoutSeconds is > 0 and <= 2 &&
            NetworkTimeoutSeconds <= OperationTimeoutSeconds && MaxWriteAttempts is >= 1 and <= 5 &&
            RateLimits is not null && RateLimits.GetCapacity > 0 && RateLimits.GetPerSecond > 0 &&
            RateLimits.PostCapacity > 0 && RateLimits.PostPerSecond > 0;
    }

    public BlobClientOptions ClientOptions() => new(BlobClientOptions.ServiceVersion.V2025_11_05) {
        Retry = { MaxRetries = 0, NetworkTimeout = TimeSpan.FromSeconds(NetworkTimeoutSeconds) },
        Diagnostics = { IsLoggingContentEnabled = false, IsLoggingEnabled = false }
    };

    // Microsoft's public emulator key; never a production credential.
    public const string EmulatorKey = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==";
    // Operator startup may need a cold MI token. Authenticate once before the
    // unchanged six-second data-operation deadline; never print/persist the token.
    public async Task<BlobServiceClient> CreateOperatorClientAsync(CancellationToken cancellationToken)
    {
        if (UseAzurite) return CreateClient();
        using var startup = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        startup.CancelAfter(TimeSpan.FromSeconds(30));
        TokenCredential identity = new ManagedIdentityCredential(string.IsNullOrEmpty(ManagedIdentityClientId)
            ? ManagedIdentityId.SystemAssigned : ManagedIdentityId.FromUserAssignedClientId(ManagedIdentityClientId));
        await identity.GetTokenAsync(new TokenRequestContext(["https://storage.azure.com/.default"]), startup.Token);
        return new BlobServiceClient(new Uri(BlobServiceUri), identity, ClientOptions());
    }

    public BlobServiceClient CreateClient(BlobClientOptions? options = null)
    {
        options ??= ClientOptions();
        if (UseAzurite) return new(new Uri(AzuriteEndpoint), new StorageSharedKeyCredential("devstoreaccount1", EmulatorKey), options);
        TokenCredential identity = new ManagedIdentityCredential(string.IsNullOrEmpty(ManagedIdentityClientId)
            ? ManagedIdentityId.SystemAssigned : ManagedIdentityId.FromUserAssignedClientId(ManagedIdentityClientId));
        return new(new Uri(BlobServiceUri), identity, options);
    }
}
public sealed class HighscoreRateLimits
{
    public int GetCapacity { get; set; } = 40;
    public int GetPerSecond { get; set; } = 20;
    public int PostCapacity { get; set; } = 10;
    public int PostPerSecond { get; set; } = 2;
}
