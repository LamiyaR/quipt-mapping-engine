using System.Text.RegularExpressions;

namespace QuiptMappingEngine.Normalization;

public static class FieldNormalizer
{
    // Known prefixes for splitting ALL-CAPS compound codes like GPUMODEL → GPU + MODEL.
    // Ordered longest-first so "BLUETOOTH" matches before "BLU", etc.
    private static readonly string[] CompoundPrefixes = new[]
    {
        "BLUETOOTH", "CELLULAR", "NOTEBOOK", "KEYBOARD", "DESKTOP", "NETWORK",
        "RELEASE", "WIRELESS", "STORAGE", "GENERIC", "SPECIAL", "WEBCAM",
        "NATIVE", "SCREEN", "PHONE", "MOUSE", "TOTAL", "AVAIL", "MEDIA",
        "FRONT", "EXACT", "REAR", "DUAL", "GPU", "CPU", "RAM", "USB",
        "BAT", "SCR", "MIC", "NFC", "VGA", "DVI", "DSP", "HD", "PC"
    };

    // Main method you will use in matching
    public static List<string> GetNormalizedTokens(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return new List<string>();

        // Step 1: Convert camelCase or PascalCase to spaced words
        var spaced = Regex.Replace(input, "([a-z0-9])([A-Z])", "$1 $2");
        spaced = Regex.Replace(spaced, "([A-Z]+)([A-Z][a-z])", "$1 $2");

        // Step 2: Replace underscores and hyphens with spaces
        spaced = spaced.Replace("_", " ").Replace("-", " ");

        // Step 3: Lowercase everything
        spaced = spaced.ToLowerInvariant();

        // Step 4: Remove special characters
        spaced = Regex.Replace(spaced, @"[^a-z0-9\s]", " ");

        // Step 5: Remove extra spaces
        spaced = Regex.Replace(spaced, @"\s+", " ").Trim();

        // Step 6: Split into tokens
        var tokens = spaced.Split(" ", StringSplitOptions.RemoveEmptyEntries);

        // Step 6b: Split compound ALL-CAPS codes (e.g. "gpumodel" → "gpu" + "model")
        var expanded = new List<string>();
        foreach (var t in tokens)
        {
            var parts = SplitCompoundCode(t);
            expanded.AddRange(parts);
        }

        // Step 7: Normalize each token using dictionary
        var normalizedTokens = expanded
            .Select(t =>
            {
                if (NormalizationDictionary.Map.TryGetValue(t, out var normalized))
                    return normalized;
                return t;
            })
            .ToList();

        return normalizedTokens;
    }

    /// <summary>
    /// Splits a lowercased compound code on known prefixes.
    /// e.g. "gpumodel" → ["gpu", "model"], "releaseyear" → ["release", "year"]
    /// Only triggers for tokens ≥ 4 chars where a known prefix leaves a remainder ≥ 2 chars.
    /// </summary>
    private static List<string> SplitCompoundCode(string token)
    {
        if (token.Length < 4)
            return new List<string> { token };

        // Try each prefix (they are stored uppercase — compare case-insensitively)
        foreach (var prefix in CompoundPrefixes)
        {
            var lowerPrefix = prefix.ToLowerInvariant();
            if (token.StartsWith(lowerPrefix) && token.Length > lowerPrefix.Length)
            {
                var remainder = token.Substring(lowerPrefix.Length);
                if (remainder.Length >= 2)
                {
                    // Recursively split the remainder (e.g. "hdtypehware" → "hd" + "typehware" → "hd" + "type" + "hware")
                    var result = new List<string> { lowerPrefix };
                    result.AddRange(SplitCompoundCode(remainder));
                    return result;
                }
            }
        }

        return new List<string> { token };
    }
}