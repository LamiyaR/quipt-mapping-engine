namespace QuiptMappingEngine.Evaluation;

public class EvaluationReport
{
    public string Category { get; set; } = "";

    // Overall accuracy (computed over ground-truth fields only)
    public int TotalAmazonFields { get; set; }
    public int CorrectMatches { get; set; }
    public int GroundTruthFields { get; set; }
    public double AccuracyPercent { get; set; }

    // Coverage: % of Amazon fields that got any match
    public double CoveragePercent { get; set; }

    // Required-field coverage
    public int TotalRequiredFields { get; set; }
    public int MatchedRequiredFields { get; set; }
    public double RequiredCoveragePercent { get; set; }

    public List<string> UnmatchedRequiredFields { get; set; } = new();
}