using Azure.Core;
using Azure.Core.Pipeline;

namespace DonkeyTrump.Highscores.Tests.Support;

/// Barriers/faults wrap the real transport so a lost acknowledgement can follow a committed emulator write.
public sealed class BlobFaultTransport : HttpPipelineTransport
{
    private readonly HttpPipelineTransport inner = new HttpClientTransport();
    public Func<HttpMessage, ValueTask>? Before { get; set; }
    public Func<HttpMessage, ValueTask>? After { get; set; }
    public override Request CreateRequest() => inner.CreateRequest();
    public override void Process(HttpMessage message) => ProcessAsync(message).AsTask().GetAwaiter().GetResult();
    public override async ValueTask ProcessAsync(HttpMessage message)
    {
        if (Before is not null) await Before(message);
        await inner.ProcessAsync(message);
        if (After is not null) await After(message);
    }
}

public sealed class AsyncBarrier(int count)
{
    private int remaining = count;
    private readonly TaskCompletionSource completion = new(TaskCreationOptions.RunContinuationsAsynchronously);
    public async ValueTask ArriveAsync(CancellationToken cancellationToken)
    {
        if (Interlocked.Decrement(ref remaining) == 0) completion.TrySetResult();
        await completion.Task.WaitAsync(cancellationToken);
    }
}

public sealed class FixedTimeProvider : TimeProvider
{
    public DateTimeOffset Now { get; set; } = DateTimeOffset.Parse("2026-09-26T12:00:00.000Z");
    public override DateTimeOffset GetUtcNow() => Now;
    public static Task NoBackoff(CancellationToken cancellationToken) {
        cancellationToken.ThrowIfCancellationRequested(); return Task.CompletedTask;
    }
}
