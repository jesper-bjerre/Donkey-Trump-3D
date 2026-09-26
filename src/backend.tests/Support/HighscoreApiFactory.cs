using Microsoft.Extensions.Logging;
using DonkeyTrump.Highscores;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace DonkeyTrump.Highscores.Tests.Support;

public sealed class HighscoreApiFactory(IHighscoreStore? store = null, IDictionary<string, string?>? settings = null) : WebApplicationFactory<Program>
{
    public System.Collections.Concurrent.ConcurrentQueue<string> Logs { get; } = new();
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Test");
        builder.ConfigureLogging(logging => logging.AddProvider(new CapturedLogs(Logs)));
        builder.UseContentRoot(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../backend")));
        builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?> {
            ["Highscores:UseAzurite"] = "true", ["Highscores:ContainerName"] = "highscores-test"
        }).AddInMemoryCollection(settings ?? new Dictionary<string, string?>()));
        builder.ConfigureServices(services => {
            if (store is not null) { services.RemoveAll<IHighscoreStore>(); services.AddSingleton(store); }
        });
    }
}
