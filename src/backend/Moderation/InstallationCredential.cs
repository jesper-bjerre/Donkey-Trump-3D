using System.Security.Cryptography;

namespace DonkeyTrump.Highscores;

public static class InstallationCredential
{
    public static bool ValidHash(string? hash) => hash is { Length: 64 } && hash.All(c => c is >= '0' and <= '9' or >= 'a' and <= 'f');
    public static string Hash(string? authorization)
    {
        static HighscoreFailure Invalid() => new(401, "installation_credential_invalid", "Online publication is unavailable");
        if (authorization is null || authorization.Length != 50 || !authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) throw Invalid();
        var secret = authorization[7..];
        if (secret.Any(c => !(char.IsAsciiLetterOrDigit(c) || c is '-' or '_'))) throw Invalid();
        byte[] bytes;
        try { bytes = Convert.FromBase64String(secret.Replace('-', '+').Replace('_', '/') + "="); }
        catch (FormatException) { throw Invalid(); }
        if (bytes.Length != 32 || Convert.ToBase64String(bytes).TrimEnd('=').Replace('+','-').Replace('/','_') != secret) throw Invalid();
        try { return Convert.ToHexStringLower(SHA256.HashData(bytes)); }
        finally { CryptographicOperations.ZeroMemory(bytes); }
    }
}
