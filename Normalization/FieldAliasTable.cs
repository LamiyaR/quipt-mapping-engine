namespace QuiptMappingEngine.Normalization;

/// <summary>
/// Direct Amazon→Quipt Code overrides for fields where naming conventions
/// are irreconcilably different and heuristic matching cannot bridge the gap.
/// Checked BEFORE heuristic scoring in the MatchingEngine.
/// </summary>
public static class FieldAliasTable
{
    // Universal aliases that apply to all categories.
    private static readonly Dictionary<string, string> Universal = new(StringComparer.OrdinalIgnoreCase)
    {
        ["connectivity_technology"] = "HDTYPE",
        ["model_year"] = "RELEASEYEAR",
    };

    // Category-specific overrides (key = Amazon field name, value = Quipt attribute Code).
    private static readonly Dictionary<string, Dictionary<string, string>> CategoryAliases =
        new(StringComparer.OrdinalIgnoreCase)
    {
        ["laptops"] = new(StringComparer.OrdinalIgnoreCase)
        {
            ["specific_uses_for_product"] = "LIFESTYLE",
            ["graphics_description"] = "GPUMODEL",
            ["item_display_weight"] = "ITEMWEIGHT",
            ["flash_memory"] = "HDSIZE",
            ["graphics_processor_manufacturer"] = "CPUNUM",
            ["system_ram_type"] = "RAMTYPE",
            ["size"] = "SCRNSIZE",
            ["color"] = "GENERICCOLOR",
            ["memory_storage_capacity"] = "RAMSIZE",
            ["processor_count"] = "CPUCORE",
            ["total_usb_2_0_ports"] = "USBPRT",
            ["total_usb_3_0_ports"] = "USBPWR",
        },

        ["desktops"] = new(StringComparer.OrdinalIgnoreCase)
        {
            ["specific_uses_for_product"] = "PCLIFESTYLE",
            ["graphics_description"] = "GPUTYPE",
            ["memory_storage_capacity"] = "HDSIZE",
            ["size"] = "HDSIZE",
            ["color"] = "GENERICCOLOR",
        },

        ["smartphones"] = new(StringComparer.OrdinalIgnoreCase)
        {
            ["telephone_type"] = "DUALSIM",
            ["effective_still_resolution"] = "REARCAM",
            ["digital_storage_capacity"] = "STORSIZE",
            ["memory_storage_capacity"] = "STORSIZE",
            ["capacity"] = "BATCAP",
            ["size"] = "RAMSIZE",
            ["specific_uses_for_product"] = "LIFESTYLE",
            ["wireless_provider"] = "NETWORKPROVIDER",
            ["color"] = "GENERICCOLOR",
        },
    };

    /// <summary>
    /// Returns the merged alias table for a given category (universal + category-specific).
    /// Key = Amazon field name (lowercase), Value = Quipt attribute Code (e.g. "GPUMODEL").
    /// </summary>
    public static Dictionary<string, string> GetAliases(string category)
    {
        var result = new Dictionary<string, string>(Universal, StringComparer.OrdinalIgnoreCase);

        if (CategoryAliases.TryGetValue(category.ToLowerInvariant(), out var catAliases))
        {
            foreach (var kvp in catAliases)
                result[kvp.Key] = kvp.Value; // category overrides universal if conflict
        }

        return result;
    }

    /// <summary>
    /// Quipt attribute codes that legitimately map to multiple Amazon fields.
    /// These should NOT be removed from the candidate pool after the first match.
    /// </summary>
    public static readonly HashSet<string> MultiMapCodes = new(StringComparer.OrdinalIgnoreCase)
    {
        "MODELNBR",   // model_name + model_number
        "ITEMWEIGHT", // item_weight + item_display_weight
        "HDSIZE",     // hard_disk + flash_memory + memory_storage_capacity
        "RAMSIZE",    // ram_memory + memory_storage_capacity + computer_memory
        "CPUNUM",     // cpu_model + graphics_processor_manufacturer
        "RAMTYPE",    // ram_memory/technology + system_ram_type
        "STORSIZE",   // digital_storage_capacity + memory_storage_capacity + flash_memory
        "GENERICCOLOR", // color + (others)
        "GPUTYPE",    // graphics_description + graphics_card_interface
        "USBPRT",     // total_usb_2_0_ports (+ related usb fields)
        "USBPWR",     // total_usb_3_0_ports (+ related usb fields)
        "CPUCORE",    // processor_count (+ related cpu fields)
    };
}
