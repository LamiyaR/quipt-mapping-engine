using QuiptMappingEngine.Models;
using System.Text.Json;

namespace QuiptMappingEngine.Services
{
    public class EbayFieldParser
    {
        public List<Field> Parse(string filePath)
        {
            var json = File.ReadAllText(filePath);

            using JsonDocument doc = JsonDocument.Parse(json);

            var root = doc.RootElement;
            var fields = new List<Field>();

            if (!root.TryGetProperty("aspects", out JsonElement aspects))
                return fields;

            int i = 0;
            foreach (var aspect in aspects.EnumerateArray())
            {
                var field = new Field();

                if (aspect.TryGetProperty("localizedAspectName", out JsonElement nameEl))
                    field.Name = nameEl.GetString() ?? "";

                field.Path = $"aspects[{i}]";

                if (aspect.TryGetProperty("aspectConstraint", out JsonElement constraint))
                {
                    if (constraint.TryGetProperty("aspectRequired", out JsonElement requiredEl))
                        field.IsRequired = requiredEl.GetBoolean();

                    if (constraint.TryGetProperty("aspectDataType", out JsonElement dataTypeEl))
                        field.DataType = dataTypeEl.GetString() ?? "";
                }

                if (aspect.TryGetProperty("aspectValues", out JsonElement values))
                {
                    var enumVals = new List<string>();
                    foreach (var v in values.EnumerateArray())
                    {
                        if (v.TryGetProperty("localizedValue", out JsonElement lv))
                            enumVals.Add(lv.GetString() ?? "");
                    }
                    field.EnumValues = enumVals;
                }

                fields.Add(field);
                i++;
            }

            return fields;
        }
    }
}
