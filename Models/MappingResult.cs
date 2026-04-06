public class MappingResult
{
    public string MarketplaceField { get; set; } = "";
    public string? QuiptCode
    {
        get
        {
            if (QuiptPath == null) return null;
            var m = System.Text.RegularExpressions.Regex.Match(QuiptPath, @"Code='([^']+)'");
            return m.Success ? m.Groups[1].Value : null;
        }
    }
    public string? QuiptPath { get; set; }
    public double Score { get; set; }
    public bool IsRequired { get; set; }
    public bool IsUnmatched { get; set; }
}