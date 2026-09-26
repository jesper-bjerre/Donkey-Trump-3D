using System.Net;
using System.Text;
using Azure.Core.Pipeline;
namespace DonkeyTrump.Highscores.Tests.Support;

/// Exercises the real Azure SDK request/response pipeline, with deterministic storage responses.
public sealed class BlobHttpHandler : HttpMessageHandler
{
    public int Reads, Writes;
    public Func<HttpRequestMessage,CancellationToken,Task<HttpResponseMessage>> Respond = (_,_) => Task.FromResult(Error(404,"BlobNotFound"));
    public List<(string? Match,string? NoneMatch,string Query)> Conditions { get; } = [];
    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,CancellationToken token) {
        if(request.Method==HttpMethod.Get) Reads++;
        if(request.Method==HttpMethod.Put) {
            Writes++; Conditions.Add((request.Headers.IfMatch.FirstOrDefault()?.ToString(),request.Headers.IfNoneMatch.FirstOrDefault()?.ToString(),request.RequestUri!.Query));
        }
        return Respond(request,token);
    }
    public BlobHighscoreStore Store(HighscoreOptions? options=null, Func<CancellationToken,Task>? backoff=null) {
        options ??= new() {UseAzurite=true,ContainerName="test-container"};
        var clientOptions=options.ClientOptions();clientOptions.Transport=new HttpClientTransport(new HttpClient(this));
        return new(options.CreateClient(clientOptions),options,TimeProvider.System,backoff??FixedTimeProvider.NoBackoff);
    }
    public static HttpResponseMessage Document(byte[] bytes,string etag="\"v1\"",bool chunked=false) {
        var response=new HttpResponseMessage(HttpStatusCode.OK) { Content=chunked ? new StreamContent(new MemoryStream(bytes)) : new ByteArrayContent(bytes) };
        response.Headers.ETag=new(etag); response.Content.Headers.LastModified=DateTimeOffset.UtcNow;
        if(chunked) response.Headers.TransferEncodingChunked=true;
        response.Headers.Add("x-ms-blob-type","BlockBlob");return response;
    }
    public static HttpResponseMessage Saved(string etag="\"saved\"") {
        var response=new HttpResponseMessage(HttpStatusCode.Created);response.Headers.ETag=new(etag);return response;
    }
    public static HttpResponseMessage Error(int status,string code) {
        var response=new HttpResponseMessage((HttpStatusCode)status) {Content=new StringContent($"<Error><Code>{code}</Code><Message>Fixture</Message></Error>",Encoding.UTF8,"application/xml")};
        response.Headers.Add("x-ms-error-code",code);return response;
    }
}
