namespace QuiptMappingEngine.Normalization;

/// <summary>
/// Direct marketplace→Quipt Code overrides for fields where naming conventions
/// are irreconcilably different and heuristic matching cannot bridge the gap.
/// Checked BEFORE heuristic scoring in the MatchingEngine.
/// </summary>
public static class FieldAliasTable
{
    // ── Amazon aliases ──────────────────────────────────────────────────────

    // Universal Amazon aliases that apply to all categories.
    private static readonly Dictionary<string, string> AmazonUniversal = new(StringComparer.OrdinalIgnoreCase)
    {
        ["connectivity_technology"] = "HDTYPE",
        ["model_year"] = "RELEASEYEAR",
    };

    // Amazon category-specific overrides (key = Amazon field name, value = Quipt attribute Code).
    private static readonly Dictionary<string, Dictionary<string, string>> AmazonCategoryAliases =
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
            ["graphics_card_interface"] = "GPUTYPE",
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
            ["battery_installation_device_type"] = "BATTYPE",
            ["contains_battery_or_cell"] = "BATTYPE",
        },
    };

    // ── eBay aliases ────────────────────────────────────────────────────────

    // Universal eBay aliases (apply to all eBay categories).
    // eBay path-based aliases: field name → exact Quipt XPath (for structural elements with no Code).
    // Used when the target path is not an Attribute Code but a direct element path.
    private static readonly Dictionary<string, string> EbayPathAliases = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Brand"]       = "q:Catalog/q:Brand/q:Name",
        ["MPN"]         = "q:Catalog/q:SKUs/q:SKU[q:Type = 'MPN']/q:Value",
        ["Item Height"] = "q:Catalog/q:Dimensions/q:Height",
        ["Item Length"] = "q:Catalog/q:Dimensions/q:Length",
        ["Item Width"]  = "q:Catalog/q:Dimensions/q:Width",
        ["Item Weight"] = "q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMWEIGHT']/q:Value/a:string",
    };

    private static readonly Dictionary<string, string> EbayUniversal = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Release Year"]      = "RELEASEYEAR",
        ["Model"]             = "MODELNBR",
        ["Color"]             = "GENERICCOLOR",
        ["RAM Size"]          = "RAMSIZE",
        ["Storage Type"]      = "HDTYPEHWARE",
        ["Most Suitable For"] = "PCLIFESTYLE",
    };

    // eBay category-specific overrides.
    private static readonly Dictionary<string, Dictionary<string, string>> EbayCategoryAliases =
        new(StringComparer.OrdinalIgnoreCase)
    {
        ["laptops"] = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Type"]                     = "NOTEBOOKFORMFACT",
            ["GPU"]                      = "GPUMODEL",
            ["Screen Size"]              = "SCRNSIZE",
            ["Hard Drive Capacity"]      = "HDSIZE",
            ["SSD Capacity"]             = "HDTYPEHWARE",
            ["Graphics Processing Type"] = "GPUTYPE",
            ["Most Suitable For"]        = "PCLIFESTYLE",
            ["Features"]                 = "BATLIFE",
            ["Series"]                   = "NOTEBOOKPRODLINE",
            ["Connectivity"]             = "TOTALDSLPRT",
        },

        ["desktops"] = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Form Factor"]              = "DESKTOPFORMFACT",
            ["GPU"]                      = "GPUMODEL",
            ["Graphics Processing Type"] = "GPUTYPE",
            ["Hard Drive Capacity"]      = "HDSIZE",
            ["SSD Capacity"]             = "HDTYPEHWARE",
            ["Maximum RAM Capacity"]     = "RAMMAX",
            ["Most Suitable For"]        = "PCLIFESTYLE",
            ["Features"]                 = "EPEATLVL",
            ["Series"]                   = "DESKTOPPRODLINE",
            ["Connectivity"]             = "TOTALDVI",
        },

        ["smartphones"] = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Color"]             = "EXACTCOLOR",
            ["Model"]             = "PHONEPRODLINE",
            ["RAM"]               = "RAMSIZE",
            ["Connectivity"]      = "WIRELESSTECH",
            ["Contract"]          = "LOCKEDUNLOCKED",
            ["Features"]          = "DSPLYTYPE",
            ["Network"]           = "LOCKEDUNLOCKED",
            ["Storage Capacity"]  = "STORSIZE",
            ["Screen Size"]       = "SCRNSIZE",
            ["Camera Resolution"] = "REARCAM",
            ["Lock Status"]       = "LOCKEDUNLOCKED",
            ["SIM Card Slot"]     = "DUALSIM",
            ["Cellular Band"]     = "CELLULARNETWORK",
            ["Model Number"]      = "SPMFG",
        },
    };

    // ── Amazon path aliases ──────────────────────────────────────────────────
    private static readonly Dictionary<string, string> AmazonPathAliases = new(StringComparer.OrdinalIgnoreCase)
    {
        ["brand"]                   = "q:Catalog/q:Brand/q:Name",
        ["manufacturer"]            = "q:Catalog/q:Manufacturer/q:Name",
        ["item_name"]               = "q:Catalog/q:Title",
        ["product_description"]     = "q:Catalog/q:Description",
        ["country_of_origin"]       = "q:Catalog/q:CountryOfOrigin/q:ISO3",
        ["warranty_description"]    = "q:Catalog/q:Warranty/q:Duration",
        ["list_price"]              = "q:Catalog/q:Pricing/q:MSRP/q:Value",
        ["item_package_weight"]     = "q:ShippingInfo/q:Weight/q:Value",
        ["item_package_dimensions"] = "q:ShippingInfo/q:Dimensions/q:Length",
        ["generic_keyword"]         = "q:Catalog/q:Tags/string",
        ["part_number"]             = "q:SKU[q:Type = 'MPN']/q:Value",
    };

    // ── Public API ──────────────────────────────────────────────────────────

    /// <summary>
    /// Returns path-based aliases for the given marketplace.
    /// Key = marketplace field name, Value = exact Quipt XPath (for structural paths without a Code).
    /// </summary>
    public static Dictionary<string, string> GetPathAliases(string marketplace)
    {
        if (marketplace.Equals("ebay", StringComparison.OrdinalIgnoreCase))
            return EbayPathAliases;
        if (marketplace.Equals("amazon", StringComparison.OrdinalIgnoreCase))
            return AmazonPathAliases;
        return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Returns the merged alias table for a given marketplace + category.
    /// Key = marketplace field name, Value = Quipt attribute Code (e.g. "GPUMODEL").
    /// Defaults to amazon if marketplace is unrecognised.
    /// </summary>
    public static Dictionary<string, string> GetAliases(string marketplace, string category)
    {
        bool isEbay = marketplace.Equals("ebay", StringComparison.OrdinalIgnoreCase);

        var universal    = isEbay ? EbayUniversal    : AmazonUniversal;
        var catAliasMap  = isEbay ? EbayCategoryAliases : AmazonCategoryAliases;

        var result = new Dictionary<string, string>(universal, StringComparer.OrdinalIgnoreCase);

        if (catAliasMap.TryGetValue(category.ToLowerInvariant(), out var catAliases))
        {
            foreach (var kvp in catAliases)
                result[kvp.Key] = kvp.Value;
        }

        return result;
    }

    /// <summary>
    /// Backward-compatible overload — assumes amazon marketplace.
    /// </summary>
    public static Dictionary<string, string> GetAliases(string category)
        => GetAliases("amazon", category);

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
