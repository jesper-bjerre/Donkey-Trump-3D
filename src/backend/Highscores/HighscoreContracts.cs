using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace DonkeyTrump.Highscores;

public sealed record HighscoreEntry(Guid EntryId, int Rank, string DisplayName, int Score);
public record HighscoreSnapshot(IReadOnlyList<HighscoreEntry> Entries, string Revision, DateTimeOffset FetchedAtUtc)
{
    public static HighscoreSnapshot From(HighscoreDocument document, string revision, DateTimeOffset observedAt) =>
        new(document.Entries.Select((e, i) => new HighscoreEntry(e.SubmissionId, i + 1, e.DisplayName, e.Score)).ToArray(), revision, observedAt);
}
public sealed record HighscoreResult(string Outcome, Guid? EntryId, int? Rank,
    IReadOnlyList<HighscoreEntry> Entries, string Revision, DateTimeOffset FetchedAtUtc)
    : HighscoreSnapshot(Entries, Revision, FetchedAtUtc)
{
    public static HighscoreResult From(HighscoreSnapshot snapshot, Guid id)
    {
        var row = snapshot.Entries.FirstOrDefault(e => e.EntryId == id);
        return new(row is null ? "notQualified" : "ranked", row?.EntryId, row?.Rank,
            snapshot.Entries, snapshot.Revision, snapshot.FetchedAtUtc);
    }
}

public sealed class HighscoreFailure(int status, string code, string title, IDictionary<string, string[]>? errors = null) : Exception(code)
{
    public int Status { get; } = status;
    public string Code { get; } = code;
    public string Title { get; } = title;
    public IDictionary<string, string[]>? Errors { get; } = errors;
    public static HighscoreFailure Malformed() => new(400, "malformed_request", "Invalid highscore submission");
    public static HighscoreFailure InvalidStorage() => new(503, "storage_invalid", "Highscores are unavailable");
    public static HighscoreFailure Unconfirmed() => new(503, "submission_unconfirmed", "Score publication could not be confirmed");
}

public static class HighscoreJson
{
    public static readonly JsonSerializerOptions Options = Create();
    private static JsonSerializerOptions Create()
    {
        var options = new JsonSerializerOptions(JsonSerializerDefaults.Web) {
            PropertyNameCaseInsensitive = false, NumberHandling = JsonNumberHandling.Strict,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull, MaxDepth = 16
        };
        options.Converters.Add(new UtcMillisecondsConverter());
        return options;
    }
}
public sealed class UtcMillisecondsConverter : JsonConverter<DateTimeOffset>
{
    public override DateTimeOffset Read(ref Utf8JsonReader reader, Type type, JsonSerializerOptions options)
    {
        if (reader.TokenType != JsonTokenType.String || !DateTimeOffset.TryParseExact(reader.GetString(),
            "yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var date)) throw new JsonException();
        return date.ToUniversalTime();
    }
    public override void Write(Utf8JsonWriter writer, DateTimeOffset value, JsonSerializerOptions options) =>
        writer.WriteStringValue(value.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture));
}
