using QuiptMappingEngine.Normalization;

namespace QuiptMappingEngine.Evaluation;

public static class EvaluationService
{
    // We compare auto results vs ground truth (manual mapping)
    // Ground truth format: MarketplaceFieldName -> Correct QuiptXPath
    public static EvaluationReport Evaluate(
        string category,
        List<EvaluatedMapping> autoMappings,
        Dictionary<string, string> groundTruth
    )
    {
        // Build a version of ground truth with "cleaned keys"
        // so item_weight and itemWeight still match each other.
        // Use first-wins to handle duplicate keys after canonicalization.
        var truthByKey = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var kvp in groundTruth)
        {
            var canon = CanonKey(kvp.Key);
            if (!truthByKey.ContainsKey(canon))
                truthByKey[canon] = kvp.Value;
        }

        // Only count ground truth entries that match an actual Amazon field name.
        // The XSLT extractor may pick up nested/structural tags that aren't real fields.
        var amazonKeys = new HashSet<string>(
            autoMappings.Select(m => CanonKey(m.MarketplaceFieldName)),
            StringComparer.OrdinalIgnoreCase);
        var matchableTruth = truthByKey.Keys.Where(k => amazonKeys.Contains(k)).ToHashSet(StringComparer.OrdinalIgnoreCase);

        int total = autoMappings.Count;
        int correct = 0;

        int totalRequired = 0;
        int matchedRequired = 0;

        var unmatchedRequired = new List<string>();

        foreach (var m in autoMappings)
        {
            var key = CanonKey(m.MarketplaceFieldName);

            // Required coverage stats
            if (m.IsRequired)
            {
                totalRequired++;
                if (!string.IsNullOrWhiteSpace(m.MatchedQuiptXPath))
                    matchedRequired++;
                else
                    unmatchedRequired.Add(m.MarketplaceFieldName);
            }

            // Accuracy stats: only count as correct if it matches ground truth
            if (!string.IsNullOrWhiteSpace(m.MatchedQuiptXPath) && truthByKey.TryGetValue(key, out var correctPath))
            {
                if (PathsEqual(m.MatchedQuiptXPath!, correctPath))
                    correct++;
            }
        }

        int groundTruthCount = matchableTruth.Count;
        int matched = autoMappings.Count(m => !string.IsNullOrWhiteSpace(m.MatchedQuiptXPath));

        return new EvaluationReport
        {
            Category = category,

            TotalMarketplaceFields = total,
            CorrectMatches = correct,
            GroundTruthFields = groundTruthCount,
            // Accuracy over ground-truth fields only (meaningful %)
            AccuracyPercent = groundTruthCount == 0 ? 0 : (double)correct / groundTruthCount * 100.0,
            // Coverage: how many Amazon fields got any match at all
            CoveragePercent = total == 0 ? 0 : (double)matched / total * 100.0,

            TotalRequiredFields = totalRequired,
            MatchedRequiredFields = matchedRequired,
            RequiredCoveragePercent = totalRequired == 0 ? 0 : (double)matchedRequired / totalRequired * 100.0,

            UnmatchedRequiredFields = unmatchedRequired
        };
    }

    // Makes field names comparable even if styles differ: item_weight vs itemWeight
    private static string CanonKey(string name)
    {
        var tokens = FieldNormalizer.GetNormalizedTokens(name);
        return string.Join("", tokens); // "itemweight"
    }

    /// <summary>
    /// Compares paths flexibly:
    /// - Ground truth may be abbreviated (e.g. "q:Catalog/q:Brand/q:Name")
    ///   while auto-matched paths are fully qualified.
    /// - Ground truth may have XPath index predicates like [1] that auto paths don't.
    /// Returns true if either path ends with the other after stripping index predicates.
    /// </summary>
    public static bool PathsEqual(string a, string b)
    {
        a = NormalizePath(a);
        b = NormalizePath(b);

        if (string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
            return true;

        if (a.EndsWith(b, StringComparison.OrdinalIgnoreCase)
            || b.EndsWith(a, StringComparison.OrdinalIgnoreCase))
            return true;

        // Compare by extracting the Attribute Code if present in both paths
        var codeA = ExtractCode(a);
        var codeB = ExtractCode(b);
        if (codeA != null && codeB != null)
            return string.Equals(codeA, codeB, StringComparison.OrdinalIgnoreCase);

        // Compare last meaningful segments (handles ISO3 vs ISO, Name vs Name etc.)
        var lastA = a.Split('/').LastOrDefault()?.Replace("q:", "") ?? "";
        var lastB = b.Split('/').LastOrDefault()?.Replace("q:", "") ?? "";
        var secondLastA = a.Split('/').Reverse().Skip(1).FirstOrDefault()?.Replace("q:", "") ?? "";
        var secondLastB = b.Split('/').Reverse().Skip(1).FirstOrDefault()?.Replace("q:", "") ?? "";
        if (secondLastA.Length > 0 && secondLastB.Length > 0
            && secondLastA.Equals(secondLastB, StringComparison.OrdinalIgnoreCase)
            && (lastA.StartsWith(lastB, StringComparison.OrdinalIgnoreCase)
                || lastB.StartsWith(lastA, StringComparison.OrdinalIgnoreCase)))
            return true;

        return false;
    }

    private static string? ExtractCode(string path)
    {
        var m = System.Text.RegularExpressions.Regex.Match(path, @"Code='([^']+)'");
        return m.Success ? m.Groups[1].Value : null;
    }

    private static string NormalizePath(string path)
    {
        path = path.Trim();
        // Strip [N] index predicates
        path = System.Text.RegularExpressions.Regex.Replace(path, @"\[\d+\]", "");
        // Strip format-number / normalize-space artifacts that may leak from extraction
        path = path.TrimEnd(')', ' ', ',');
        path = System.Text.RegularExpressions.Regex.Replace(path, @"[,\s]*'[^']*'\s*$", "");
        // Normalize whitespace around = in predicates: [q:Type = 'MPN'] → [q:Type='MPN']
        path = System.Text.RegularExpressions.Regex.Replace(path, @"\s*=\s*", "=");
        // Strip XPath filter predicates like [normalize-space(.)!='']
        path = System.Text.RegularExpressions.Regex.Replace(path, @"\[normalize-space[^\]]*\]", "");
        // Normalize a:string → string (array namespace prefix)
        path = path.Replace("/a:string", "/string");
        return path.Trim();
    }
}