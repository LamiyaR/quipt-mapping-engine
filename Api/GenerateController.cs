using Microsoft.AspNetCore.Mvc;
using QuiptMappingEngine.Models;
using QuiptMappingEngine.Services;
using QuiptMappingEngine.Xslt;
using QuiptMappingEngine.Evaluation;

namespace QuiptMappingEngine.Api
{
    [ApiController]
    [Route("generate")]
    public class GenerateController : ControllerBase
    {
        // eBay taxonomy filenames use inconsistent naming — map them explicitly.
        private static readonly Dictionary<string, string> EbayTaxonomyFiles =
            new(StringComparer.OrdinalIgnoreCase)
        {
            ["laptops"]     = "eBayTaxonomy/ebay-laptops-attributes.json",
            ["desktops"]    = "eBayTaxonomy/ebay-desktop-attributes.json",
            ["smartphones"] = "eBayTaxonomy/ebay-smartphones-attributes.json",
        };

        private static readonly Dictionary<string, string> EbayGroundTruthFiles =
            new(StringComparer.OrdinalIgnoreCase)
        {
            ["laptops"]     = "QuiptToEbayTemplates/CatalogExportTransform.Laptops.xml",
            ["desktops"]    = "QuiptToEbayTemplates/CatalogExportTransform.Desktops.xml",
            ["smartphones"] = "QuiptToEbayTemplates/CatalogExportTransform.SmartPhones.xml",
        };

        [HttpPost]
        public IActionResult Generate([FromBody] GenerateRequest request)
        {
            var category    = request.Category.ToLower();
            var marketplace = request.Marketplace.ToLower();

            // 1) Parse marketplace schema fields
            List<Field> marketplaceFields;

            if (marketplace == "ebay")
            {
                if (!EbayTaxonomyFiles.TryGetValue(category, out var ebayPath) || !System.IO.File.Exists(ebayPath))
                    return BadRequest($"eBay taxonomy not found for category '{category}'. Expected file: {(EbayTaxonomyFiles.TryGetValue(category, out var ep) ? ep : "unknown")}");

                try
                {
                    marketplaceFields = new EbayFieldParser().Parse(ebayPath);
                }
                catch (Exception ex)
                {
                    return BadRequest($"eBay parse failed: {ex.Message}");
                }
            }
            else // amazon (default)
            {
                var amazonPath = $"AmazonTaxonomy/amazon-{category}-attributes.json";
                if (!System.IO.File.Exists(amazonPath))
                    return BadRequest($"Amazon schema not found: {amazonPath}");

                try
                {
                    marketplaceFields = new AmazonFieldParser().Parse(amazonPath);
                }
                catch (Exception ex)
                {
                    return BadRequest($"Amazon parse failed: {ex.Message}");
                }
            }

            // 2) Quipt parser (Srushti module) — same XML data for both marketplaces
            var quiptParser = new QuiptSchemaParser();

            // Normalise category name for file lookup (SmartPhones.xml uses capital P)
            var quiptFileName = category switch
            {
                "smartphones" => "Smartphones",
                "desktops"    => "Desktops",
                _             => "Laptops"
            };
            var quiptPath = $"QuiptData/{quiptFileName}.xml";
            if (!System.IO.File.Exists(quiptPath))
                return BadRequest($"Quipt XML not found: {quiptPath}");

            List<Field> quiptFields;
            try
            {
                quiptFields = quiptParser.ParseFields(quiptPath);
            }
            catch (Exception ex)
            {
                return BadRequest($"Quipt parse failed: {ex.Message}");
            }

            // 3) Matching engine — same pipeline, marketplace-aware alias table
            var matcher  = new MatchingEngine();
            var mappings = matcher.Match(quiptFields, marketplaceFields, category, marketplace);

            // 4) Ground truth extraction — different source per marketplace
            var groundTruth = new Dictionary<string, string>();

            if (marketplace == "ebay")
            {
                if (EbayGroundTruthFiles.TryGetValue(category, out var ebayXmlPath)
                    && System.IO.File.Exists(ebayXmlPath))
                {
                    groundTruth = EbayGroundTruthExtractor.ExtractFromFile(ebayXmlPath);
                }
            }
            else
            {
                var xsltLookup = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["laptops"]     = "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt",
                    ["desktops"]    = "QuiptToAmazonTemplates/CatalogExportTransform.Desktops.xslt",
                    ["smartphones"] = "QuiptToAmazonTemplates/CatalogExportTransform.SmartPhones.xslt"
                };

                if (xsltLookup.TryGetValue(category, out var xsltPath)
                    && System.IO.File.Exists(xsltPath))
                {
                    groundTruth = GroundTruthXsltExtractor.ExtractFromFile(xsltPath);
                }
            }

            // 5) Evaluation
            var evaluatedMappings = mappings.Select(m => new EvaluatedMapping
            {
                MarketplaceFieldName = m.MarketplaceField,
                MatchedQuiptXPath    = m.QuiptPath,
                IsRequired           = m.IsRequired
            }).ToList();

            var report = EvaluationService.Evaluate(category, evaluatedMappings, groundTruth);

            var accuracy         = report.AccuracyPercent;
            var requiredCoverage = report.RequiredCoveragePercent;

            // 6) XSLT generation
            var xslt = new XsltBuilder().Build(category, mappings);

            // 7) Per-field evaluation details
            var evalDetails = new List<MappingEvalDetail>();
            foreach (var m in mappings)
            {
                var detail = new MappingEvalDetail
                {
                    MarketplaceField = m.MarketplaceField,
                    IsRequired       = m.IsRequired,
                    AutoMatchedPath  = m.QuiptPath,
                    Score            = Math.Round(m.Score, 4)
                };

                if (groundTruth.TryGetValue(m.MarketplaceField, out var expected))
                {
                    detail.ExpectedPath = expected;
                    if (string.IsNullOrWhiteSpace(m.QuiptPath))
                        detail.Verdict = "MISSING";
                    else if (EvaluationService.PathsEqual(m.QuiptPath, expected))
                        detail.Verdict = "CORRECT";
                    else
                        detail.Verdict = "WRONG";
                }
                else
                {
                    detail.Verdict = string.IsNullOrWhiteSpace(m.QuiptPath) ? "UNMATCHED" : "NO_GROUND_TRUTH";
                }

                evalDetails.Add(detail);
            }

            // Sort: required first, matched before unmatched, then score descending
            var sortedMappings = mappings
                .OrderByDescending(m => m.IsRequired)
                .ThenBy(m => m.IsUnmatched)
                .ThenByDescending(m => m.Score)
                .ToList();

            var response = new ApiResponseModel
            {
                Category               = request.Category,
                Marketplace            = marketplace,
                MarketplaceFieldCount  = marketplaceFields.Count,
                QuiptFieldCount        = quiptFields.Count,
                MappingCount           = mappings.Count(m => !m.IsUnmatched),
                Accuracy               = Math.Round(accuracy, 2),
                CoveragePercent        = Math.Round(report.CoveragePercent, 2),
                RequiredFieldCoverage  = Math.Round(requiredCoverage, 2),
                GroundTruthCount       = report.GroundTruthFields,
                CorrectMatches         = report.CorrectMatches,
                UnmatchedRequiredFields = report.UnmatchedRequiredFields,
                GeneratedXslt          = xslt,
                Mappings               = sortedMappings,
                EvaluationDetails      = evalDetails
            };

            return Ok(response);
        }
    }

    public class GenerateRequest
    {
        public string Category    { get; set; } = "laptops";
        public string Marketplace { get; set; } = "amazon";
    }
}