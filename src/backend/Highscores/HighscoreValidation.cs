using System.Globalization;
using System.Text;
using System.Text.Json;

namespace DonkeyTrump.Highscores;

public static class HighscoreValidation
{
    public const int MaximumScore = 2_147_483_600;
    public static bool ValidScore(int score) => score >= 0 && score <= MaximumScore && score % 100 == 0;

    public static string? NormalizeName(string? value)
    {
        if (value is null) return null;
        foreach (var rune in value.EnumerateRunes())
            if (Rune.GetUnicodeCategory(rune) is UnicodeCategory.Control or UnicodeCategory.LineSeparator or UnicodeCategory.ParagraphSeparator)
                return null;
        string name;
        try { name = value.Normalize(NormalizationForm.FormC); }
        catch (ArgumentException) { return null; }
        // Zs characters are all BMP; do not trim controls before rejecting them.
        int start = 0, end = name.Length;
        while (start < end && char.GetUnicodeCategory(name[start]) == UnicodeCategory.SpaceSeparator) start++;
        while (end > start && char.GetUnicodeCategory(name[end - 1]) == UnicodeCategory.SpaceSeparator) end--;
        name = name[start..end];
        if (StringInfo.ParseCombiningCharacters(name).Length is < 1 or > 20 || Encoding.UTF8.GetByteCount(name) > 256) return null;
        if (!name.EnumerateRunes().Any(r => !Rune.IsWhiteSpace(r) && Rune.GetUnicodeCategory(r) != UnicodeCategory.Format)) return null;
        return name;
    }

    public static HighscoreSubmission Parse(JsonElement body)
    {
        if (body.ValueKind != JsonValueKind.Object) throw HighscoreFailure.Malformed();
        var allowed = new HashSet<string>(["submissionId", "displayName", "score", "levelReached"], StringComparer.Ordinal);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var property in body.EnumerateObject())
            if (!allowed.Contains(property.Name) || !seen.Add(property.Name)) throw HighscoreFailure.Malformed();
        var errors = new Dictionary<string, string[]>();
        Guid id = Guid.Empty;
        int score = -1, level = 0;
        string? name = null;
        if (!body.TryGetProperty("submissionId", out var idJson) || idJson.ValueKind != JsonValueKind.String ||
            !Guid.TryParseExact(idJson.GetString(), "D", out id) || id == Guid.Empty)
            errors["submissionId"] = ["A non-zero run UUID is required."];
        if (!body.TryGetProperty("displayName", out var nameJson) || nameJson.ValueKind != JsonValueKind.String ||
            (name = NormalizeName(nameJson.GetString())) is null)
            errors["displayName"] = ["Enter a single-line name containing 1–20 characters (at most 256 UTF-8 bytes)."];
        if (!body.TryGetProperty("score", out var scoreJson) || scoreJson.ValueKind != JsonValueKind.Number ||
            !scoreJson.TryGetInt32(out score) || !ValidScore(score))
            errors["score"] = ["Score must be a multiple of 100 from 0 to 2147483600."];
        if (!body.TryGetProperty("levelReached", out var levelJson) || levelJson.ValueKind != JsonValueKind.Number ||
            !levelJson.TryGetInt32(out level) || level < 1)
            errors["levelReached"] = ["Level must be an integer from 1 to 2147483647."];
        if (errors.Count != 0) throw new HighscoreFailure(400, "validation_failed", "Invalid highscore submission", errors);
        return new(id, name!, score, level);
    }
}
