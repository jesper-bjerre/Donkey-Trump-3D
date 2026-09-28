using System.Globalization;
using System.Text;

namespace DonkeyTrump.Highscores;

/// Comparison-only policy. Kept deliberately reviewable; not a claim to catch all abuse.
public static class NameModerationPolicy
{
    private static readonly string[] Prohibited = ["fuck", "shit", "nigger", "nigga", "faggot", "heilhitler", "nazist"];
    public static bool Allowed(string name)
    {
        var key=new StringBuilder();
        foreach(var rune in name.Normalize(NormalizationForm.FormKD).EnumerateRunes()) {
            var category=Rune.GetUnicodeCategory(rune);
            if(category is UnicodeCategory.NonSpacingMark or UnicodeCategory.EnclosingMark or UnicodeCategory.Format) continue;
            var value=Rune.ToLowerInvariant(rune).ToString();
            value=value switch { "0"=>"o", "1" or "!"=>"i", "3"=>"e", "4" or "@"=>"a", "5" or "$"=>"s", "7"=>"t", _=>value };
            if(value.Length==1 && char.IsAsciiLetter(value[0])) key.Append(value);
            else if(Rune.IsLetter(rune)) key.Append(value);
        }
        var normalized=key.ToString();
        return normalized is not ("lort" or "pik" or "kusse") && !Prohibited.Any(word=>normalized.Contains(word,StringComparison.Ordinal));
    }
}
