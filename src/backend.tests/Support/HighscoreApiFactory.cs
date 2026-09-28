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
            services.RemoveAll<Microsoft.Extensions.Hosting.IHostedService>();
            if (store is not null) { services.RemoveAll<IHighscoreStore>(); services.AddSingleton(store);
                services.RemoveAll<IModerationStore>(); services.AddSingleton<IModerationStore>(store as IModerationStore ?? new EndpointTestAdapter(store)); }
        });
    }
}

// Existing endpoint contract fakes exercise validation/DTO boundaries without storage.
internal sealed class EndpointTestAdapter(IHighscoreStore store) : IModerationStore
{
    public Task<HighscoreResult> PublishAsync(HighscoreSubmission run,string hash,CancellationToken token)=>store.PublishAsync(run,hash,token);
    public Task<AggregateRead> ReadAggregateAsync(CancellationToken token)=>throw new NotSupportedException();
    public Task<(ReportReceipt Receipt,bool Created)> ReportAsync(ReportSubmission run,string hash,CancellationToken token)=>throw new NotSupportedException();
    public Task<ReportReceipt> ReceiptAsync(Guid id,string hash,CancellationToken token)=>throw new NotSupportedException();
    public Task<AggregateRead> MutateAsync(Func<HighscoreDocument,DateTimeOffset,HighscoreDocument> change,string code,CancellationToken token,bool migration=false,string? expectedETag=null)=>throw new NotSupportedException();
}
