using System.Text.RegularExpressions;
using System.Xml.Linq;

namespace QuiptMappingEngine.Evaluation;

public static class EbayGroundTruthExtractor
{
    // Regex to extract the first q: XPath from an embedded XSLT select attribute
    private static readonly Regex SelectRx = new(
        @"select=""(q:[^""]+)""",
        RegexOptions.Compiled);

    // Extracts: ebayFieldName -> quiptXPath
    // Parses QuiptToEbayTemplates/CatalogExportTransform.{Category}.xml
    // Each <CatalogTemplateRequest.Attribute> has two <Key>/<Value> pairs:
    //   Key=Name  → eBay aspect name (e.g. "Screen Size")
    //   Key=Value → embedded XSLT with xsl:value-of select="q:..." references
    public static Dictionary<string, string> ExtractFromFile(string xmlPath)
    {
        if (!File.Exists(xmlPath))
            throw new FileNotFoundException($"eBay template not found: {xmlPath}");

        var doc = XDocument.Load(xmlPath);
        var ns = XNamespace.Get("http://schemas.quipt.com/api");

        var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        var attributes = doc.Descendants(ns + "CatalogTemplateRequest.Attribute");
        foreach (var attr in attributes)
        {
            string? fieldName = null;
            string? xsltValue = null;

            var properties = attr.Elements(ns + "Properties")
                                 .SelectMany(p => p.Elements(ns + "CatalogTemplateRequest.Property"));

            foreach (var prop in properties)
            {
                var key   = prop.Element(ns + "Key")?.Value;
                var value = prop.Element(ns + "Value")?.Value;

                if (key == "Name")  fieldName  = value;
                else if (key == "Value") xsltValue = value;
            }

            if (string.IsNullOrWhiteSpace(fieldName) || string.IsNullOrWhiteSpace(xsltValue))
                continue;

            // Find the first xsl:value-of select="q:..." in the embedded XSLT text
            var match = SelectRx.Match(xsltValue);
            if (!match.Success) continue;

            var quiptPath = match.Groups[1].Value.Trim();

            if (!dict.ContainsKey(fieldName))
                dict[fieldName] = quiptPath;
        }

        return dict;
    }
}
