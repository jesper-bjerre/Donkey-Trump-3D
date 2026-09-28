using Azure.Storage.Blobs;
using DonkeyTrump.Highscores;

namespace DonkeyTrump.Highscores.Tests.Support;

public sealed class AzuriteFixture : IAsyncLifetime
{
    public HighscoreOptions Options { get; } = new() {
        UseAzurite = true, ContainerName = "dt3d-test-" + Guid.NewGuid().ToString("N"),
        AzuriteEndpoint = Environment.GetEnvironmentVariable("HighscoresTests__AzuriteEndpoint") ?? "http://127.0.0.1:10000/devstoreaccount1"
    };
    public BlobContainerClient Container { get; private set; } = null!;
    public async Task InitializeAsync()
    {
        if (Environment.GetEnvironmentVariable("HighscoresTests__UseAzurite") != "true")
            throw new InvalidOperationException("StorageIntegration explicitly requires HighscoresTests__UseAzurite=true and a running local emulator.");
        if (!Options.IsValid("Test")) throw new InvalidOperationException("Tests require an isolated loopback Azurite endpoint.");
        Container = Options.CreateClient().GetBlobContainerClient(Options.ContainerName);
        await Container.CreateAsync(cancellationToken: new CancellationTokenSource(TimeSpan.FromSeconds(6)).Token);
        await Container.GetBlobClient(Options.BlobName).UploadAsync(BinaryData.FromBytes(ModerationMigration.Convert(HighscoreDocument.Empty).Serialize()));
    }
    public async Task DisposeAsync()
    {
        // This fixture owns only this unique local container, never a shared or production ranking.
        if (Container is not null) await Container.DeleteIfExistsAsync(cancellationToken: new CancellationTokenSource(TimeSpan.FromSeconds(6)).Token);
    }
}
