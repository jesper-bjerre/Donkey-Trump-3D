using System.Collections.Concurrent;
using Microsoft.Extensions.Logging;
namespace DonkeyTrump.Highscores.Tests.Support;
public sealed class CapturedLogs(ConcurrentQueue<string> messages) : ILoggerProvider {
    public ILogger CreateLogger(string categoryName)=>new Capture(categoryName,messages);
    public void Dispose() { }
    private sealed class Capture(string category,ConcurrentQueue<string> messages) : ILogger {
        public IDisposable? BeginScope<TState>(TState state) where TState:notnull=>null;
        public bool IsEnabled(LogLevel logLevel)=>true;
        public void Log<TState>(LogLevel level,EventId id,TState state,Exception? exception,Func<TState,Exception?,string> formatter) =>messages.Enqueue(category+": "+formatter(state,exception)+(exception is null?"":exception.ToString()));
    }
}
