using System.Text.RegularExpressions;

namespace QuiptMappingEngine.Evaluation;

public static class GroundTruthXsltExtractor
{
    private static readonly Regex TagNameParamRx = new(
        @"<xsl:with-param\s+name\s*=\s*""tagName""\s*>([^<]+)</xsl:with-param>",
        RegexOptions.Compiled);

    private static readonly Regex InlineSelectRx = new(
        @"select\s*=\s*""[^""]*?(q:Catalog[^""]+|q:ShippingInfo[^""]+)""",
        RegexOptions.Compiled);

    private static readonly Regex VariableSelectRx = new(
        @"<xsl:variable[^>]+select\s*=\s*""[^""]*?(q:Catalog/q:Attributes/q:Attribute\[q:Code='([^']+)'\][^""]*?)""",
        RegexOptions.Compiled);

    private static readonly Regex ValueOfSelectRx = new(
        @"<xsl:value-of[^>]+select\s*=\s*""[^""]*?(q:Catalog[^""]+|q:ShippingInfo[^""]+)""",
        RegexOptions.Compiled);

    private static readonly Regex OpenTagRx = new(
        @"<(?<tag>[a-zA-Z][a-zA-Z0-9_\-]*)(?:\s[^>]*)?>",
        RegexOptions.Compiled);

    private static readonly Regex CloseTagRx = new(
        @"</(?<tag>[a-zA-Z][a-zA-Z0-9_\-]*)>",
        RegexOptions.Compiled);

    private static readonly HashSet<string> IgnoreTags = new(StringComparer.OrdinalIgnoreCase)
    {
        "xsl", "Root", "header", "messages", "message", "attributes",
        "sellerId", "items", "item", "value", "unit", "length", "width", "height",
        "media_location", "currency", "feature"
    };

    public static Dictionary<string, string> ExtractFromFile(string xsltPath)
    {
        if (!File.Exists(xsltPath))
            throw new FileNotFoundException($"XSLT not found: {xsltPath}");

        var text = File.ReadAllText(xsltPath);
        var lines = File.ReadAllLines(xsltPath);
        var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        ExtractArrayItemMappings(text, dict);
        ExtractRenderAttributeMappings(lines, dict);

        return dict;
    }

    /// <summary>
    /// Extracts mappings from xsl:call-template name="ArrayItem" blocks.
    /// Pattern: tagName param gives the field name, then the nearest q: select gives the path.
    /// </summary>
    private static void ExtractArrayItemMappings(string text, Dictionary<string, string> dict)
    {
        var callTemplateRx = new Regex(
            @"<xsl:call-template\s+name\s*=\s*""ArrayItem"">(.*?)</xsl:call-template>",
            RegexOptions.Compiled | RegexOptions.Singleline);

        foreach (Match block in callTemplateRx.Matches(text))
        {
            var body = block.Groups[1].Value;

            var tagMatch = TagNameParamRx.Match(body);
            if (!tagMatch.Success) continue;

            var fieldName = tagMatch.Groups[1].Value.Trim();

            string? quiptPath = null;

            var inlineMatch = InlineSelectRx.Match(body);
            if (inlineMatch.Success)
            {
                quiptPath = CleanPath(inlineMatch.Groups[1].Value);
            }

            if (quiptPath == null)
            {
                var valueOfMatch = ValueOfSelectRx.Match(body);
                if (valueOfMatch.Success)
                    quiptPath = CleanPath(valueOfMatch.Groups[1].Value);
            }

            if (quiptPath == null)
            {
                var varMatch = VariableSelectRx.Match(body);
                if (varMatch.Success)
                    quiptPath = CleanPath(varMatch.Groups[1].Value);
            }

            if (!string.IsNullOrWhiteSpace(quiptPath) && !dict.ContainsKey(fieldName))
                dict[fieldName] = quiptPath;
        }
    }

    /// <summary>
    /// Extracts mappings from the render-attributes template section.
    /// Pattern: direct XML tags (color, size, etc.) containing xsl:variable or xsl:value-of with q: paths.
    /// </summary>
    private static void ExtractRenderAttributeMappings(string[] lines, Dictionary<string, string> dict)
    {
        var tagStack = new Stack<string>();

        foreach (var line in lines)
        {
            foreach (Match cm in CloseTagRx.Matches(line))
            {
                var ctag = cm.Groups["tag"].Value;
                if (ctag.StartsWith("xsl:")) continue;
                if (tagStack.Count > 0 && tagStack.Peek() == ctag)
                    tagStack.Pop();
            }

            string? parentTag = tagStack.Count > 0 ? tagStack.Peek() : null;

            if (parentTag != null && !parentTag.StartsWith("xsl:") && !IgnoreTags.Contains(parentTag))
            {
                var varMatch = VariableSelectRx.Match(line);
                if (varMatch.Success && !dict.ContainsKey(parentTag))
                {
                    dict[parentTag] = CleanPath(varMatch.Groups[1].Value);
                }

                var voMatch = ValueOfSelectRx.Match(line);
                if (voMatch.Success && !dict.ContainsKey(parentTag))
                {
                    dict[parentTag] = CleanPath(voMatch.Groups[1].Value);
                }
            }

            foreach (Match om in OpenTagRx.Matches(line))
            {
                var otag = om.Groups["tag"].Value;
                if (otag.StartsWith("xsl") || otag == "xsl") continue;
                if (om.Value.TrimEnd().EndsWith("/>")) continue;
                tagStack.Push(otag);
            }
        }
    }

    private static string CleanPath(string path)
    {
        path = path.Trim();

        // Strip normalize-space(...) wrapper
        var nsMatch = Regex.Match(path, @"^normalize-space\((.+)\)$");
        if (nsMatch.Success) path = nsMatch.Groups[1].Value;

        // Strip format-number(PATH, 'format') wrapper
        var fnMatch = Regex.Match(path, @"^format-number\((.+?),\s*'[^']*'\s*\)$");
        if (fnMatch.Success) path = fnMatch.Groups[1].Value;

        // Remove trailing parentheses/format artifacts from partial regex captures
        path = Regex.Replace(path, @"[,\s]*'[^']*'\s*\)\s*$", "");
        path = path.TrimEnd(')', ' ');

        // Strip [1] index predicates for consistency
        path = Regex.Replace(path, @"\[\d+\]", "");

        return path.Trim();
    }
}
