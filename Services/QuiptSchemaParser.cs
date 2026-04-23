using System.Xml.Linq;
using QuiptMappingEngine.Models;

namespace QuiptMappingEngine.Services;

public class QuiptSchemaParser
{
    public List<Field> ParseFields(string xmlFilePath)
    {
        var doc = XDocument.Load(xmlFilePath);
        if (doc.Root == null)
            return new List<Field>();

        // Root namespace for Quipt XML
        XNamespace rootNs = doc.Root.Name.Namespace;
        XNamespace arrayNs = "http://schemas.microsoft.com/2003/10/Serialization/Arrays";

        const string prefix = "q";

        var fields = new List<Field>();
        var seenPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // PASS 1: Extract structured Attribute fields.
        var attributeElements = doc.Root.Descendants(rootNs + "Attribute")
            .Where(a => a.Element(rootNs + "Code") != null);

        var attrByCode = new Dictionary<string, (string Name, List<string> Values)>(StringComparer.OrdinalIgnoreCase);

        foreach (var attr in attributeElements)
        {
            var code = attr.Element(rootNs + "Code")?.Value?.Trim();
            var name = attr.Element(rootNs + "Name")?.Value?.Trim();
            if (string.IsNullOrWhiteSpace(code)) continue;

            var valueEl = attr.Element(rootNs + "Value");
            var values = new List<string>();
            if (valueEl != null)
            {
                foreach (var v in valueEl.Elements(arrayNs + "string"))
                {
                    var val = v.Value?.Trim();
                    if (!string.IsNullOrWhiteSpace(val))
                        values.Add(val);
                }
            }

            if (!attrByCode.ContainsKey(code))
                attrByCode[code] = (name ?? code, new List<string>());

            attrByCode[code].Values.AddRange(values);
        }

        foreach (var kvp in attrByCode)
        {
            var code = kvp.Key;
            var name = kvp.Value.Name;
            var distinctValues = kvp.Value.Values
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var path = $"q:Catalog/q:Attributes/q:Attribute[q:Code='{code}']/q:Value/a:string";

            fields.Add(new Field
            {
                Name = name,
                Path = path,
                DataType = DetectDataType(distinctValues),
                IsRequired = false,
                EnumValues = InferEnumValues(distinctValues)
            });

            seenPaths.Add(path);
        }

        // PASS 1.5: Extract typed SKU value paths.
        // Example synthetic path: q:Catalog/q:SKUs/q:SKU[q:Type = 'MPN']/q:Value
        var skuByType = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        var skuElements = doc.Root.Descendants(rootNs + "SKU");
        foreach (var sku in skuElements)
        {
            var type = sku.Element(rootNs + "Type")?.Value?.Trim();
            var value = sku.Element(rootNs + "Value")?.Value?.Trim();

            if (string.IsNullOrWhiteSpace(type) || string.IsNullOrWhiteSpace(value))
                continue;

            if (!skuByType.ContainsKey(type))
                skuByType[type] = new List<string>();

            skuByType[type].Add(value);
        }

        foreach (var kvp in skuByType)
        {
            var skuType = kvp.Key;
            var distinctValues = kvp.Value
                .Where(v => !string.IsNullOrWhiteSpace(v))
                .Select(v => v.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var typedSkuPath = $"q:Catalog/q:SKUs/q:SKU[q:Type = '{skuType}']/q:Value";
            if (seenPaths.Contains(typedSkuPath))
                continue;

            fields.Add(new Field
            {
                Name = skuType,
                Path = typedSkuPath,
                DataType = DetectDataType(distinctValues),
                IsRequired = false,
                EnumValues = InferEnumValues(distinctValues)
            });

            seenPaths.Add(typedSkuPath);
        }

        // PASS 2: Extract regular leaf fields (non-Attribute).
        var valueMap = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

        foreach (var el in doc.Root.DescendantsAndSelf())
        {
            if (el.Elements().Any())
                continue;

            if (IsInsideAttributes(el, rootNs))
                continue;

            var elPath = BuildPath(el, rootNs, prefix);

            if (!valueMap.ContainsKey(elPath))
                valueMap[elPath] = new List<string>();

            var value = el.Value?.Trim();
            if (!string.IsNullOrWhiteSpace(value))
                valueMap[elPath].Add(value);
        }

        foreach (var kvp in valueMap)
        {
            var path = kvp.Key;
            if (seenPaths.Contains(path)) continue;

            var distinctValues = kvp.Value
                .Where(v => !string.IsNullOrWhiteSpace(v))
                .Select(v => v.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            fields.Add(new Field
            {
                Name = GetLeafName(path),
                Path = path,
                DataType = DetectDataType(distinctValues),
                IsRequired = false,
                EnumValues = InferEnumValues(distinctValues)
            });
        }

        return fields;
    }

    private static bool IsInsideAttributes(XElement el, XNamespace ns)
    {
        var current = el.Parent;
        while (current != null)
        {
            if (current.Name == ns + "Attribute" && current.Parent?.Name == ns + "Attributes")
                return true;
            current = current.Parent;
        }
        return false;
    }

    private static string GetLeafName(string path)
    {
        var last = path.Split('/').LastOrDefault() ?? "";
        return last.Replace("q:", "", StringComparison.OrdinalIgnoreCase);
    }

    private static List<string>? InferEnumValues(List<string> distinctValues)
    {
        if (distinctValues.Count >= 2 && distinctValues.Count <= 10)
            return distinctValues;
        return null;
    }

    private static string DetectDataType(List<string> values)
    {
        if (values.Count == 0) return "string";
        if (values.All(v => int.TryParse(v, out _))) return "int";
        if (values.All(v => decimal.TryParse(v, out _))) return "decimal";
        if (values.All(v => bool.TryParse(v, out _))) return "bool";
        return "string";
    }

    private static string BuildPath(XElement element, XNamespace rootNs, string prefix)
    {
        var stack = new Stack<string>();
        XElement? current = element;

        while (current != null)
        {
            var ns = current.Name.Namespace;

            string step = (ns == rootNs)
                ? $"{prefix}:{current.Name.LocalName}"
                : current.Name.LocalName;

            stack.Push(step);
            current = current.Parent;
        }

        return string.Join("/", stack);
    }
}
