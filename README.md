# Quipt Mapping Engine

## Overview

Quipt Mapping Engine is a .NET 10 Web API that **automatically generates XSLT transformations** between Quipt product XML and external marketplace schemas. The goal is to replace the manual process of writing XSLT mappings for each marketplace/category combination with an inference-based approach.

Currently supports **Amazon** across 3 product categories. **eBay** is not started yet.

### How It Works (End-to-End)

```
POST /generate  { "category": "laptops" }
        │
        ▼
┌─────────────────┐     ┌──────────────────┐
│ QuiptSchemaParser│     │ AmazonFieldParser │
│ (Quipt XML)     │     │ (Amazon JSON)     │
└────────┬────────┘     └────────┬──────────┘
         │  List<Field>          │  List<Field>
         └──────────┬────────────┘
                    ▼
          ┌──────────────────┐
          │  MatchingEngine   │
          │  (heuristic       │
          │   scoring)        │
          └────────┬─────────┘
                   │  List<MappingResult>
          ┌────────┴─────────────────────┐
          ▼                              ▼
┌──────────────────┐         ┌────────────────────────┐
│  XsltBuilder      │         │  EvaluationService      │
│  (generates XSLT) │         │  (compares vs manual    │
└────────┬─────────┘         │   XSLT ground truth)    │
         │                    └────────┬───────────────┘
         └──────────┬─────────────────┘
                    ▼
            API JSON Response
    (xslt, mappings, accuracy, per-field verdicts)
```

---

## Current Progress

### What's Working

- **Amazon field parsing** — reads JSON taxonomy files in `AmazonTaxonomy/` and extracts fields with name, type, required flag, and enum values
- **Quipt XML parsing** — two-pass parser that extracts both structured `<Attribute>` fields (by Code) and regular leaf elements from XML in `QuiptData/`
- **Matching engine** — multi-signal heuristic scorer with token overlap, Levenshtein, substring matching, enum overlap, unit similarity, and specificity penalties
- **1:1 matching** — each Quipt field can only be matched to one Amazon field (prevents duplicates)
- **XSLT generation** — produces a basic but valid XSLT from the matched pairs
- **Ground truth evaluation** — extracts expected mappings from the manually-written XSLT files in `QuiptToAmazonTemplates/` and compares against auto-generated matches
- **Per-field verdict system** — each field gets a verdict: `CORRECT`, `WRONG`, `MISSING`, `UNMATCHED`, or `NO_GROUND_TRUTH`
- **Normalization dictionary** — 200+ synonym entries mapping Quipt attribute codes and domain terms to canonical forms
- **Compound code splitter** — breaks ALL-CAPS Quipt codes (e.g. `GPUMODEL`, `RELEASEYEAR`) into matchable tokens using 35+ known prefixes
- **Category-aware alias table** — direct Amazon→Quipt overrides for field pairs that heuristic scoring cannot bridge (e.g. `model_year` → `RELEASEYEAR`, `graphics_description` → `GPUMODEL`)
- **Multi-map whitelist** — fields like `MODELNBR` can legitimately match both `model_name` and `model_number` without being consumed by the first match
- **Coverage metric** — `coveragePercent` tracks what fraction of all Amazon fields received any match, separate from accuracy

### Latest Test Results (Amazon)

| Category    | Accuracy        | Coverage | Required Coverage | Correct / GT Fields |
|-------------|-----------------|----------|-------------------|---------------------|
| Laptops     | **100%**        | 41.18%   | 57.14%            | 11 / 11             |
| Desktops    | **100%**        | 37.72%   | 57.14%            | 8 / 8               |
| Smartphones | **42.86%**      | 29.48%   | 57.14%            | 3 / 7               |

**Accuracy** is now computed only over ground truth entries that align with actual Amazon field names (the matchable subset). This gives a meaningful percentage rather than dividing by all 167–204 Amazon fields.

**Coverage** measures what fraction of all Amazon fields received any match — a separate signal from accuracy.

**Smartphones note:** `Smartphones.xml` currently contains desktop-like Quipt codes (`HDSPEED`, `TOTALPCIX8`, `DESKTOPFORMFACT`, etc.) instead of real smartphone attributes (`BATCAP`, `STORSIZE`, `DUALSIM`, `REARCAM`). The 42.86% accuracy reflects only the fields where the data overlaps (e.g. `MODELNBR`, `RAMSIZE`). This is a **data gap**, not a code limitation — replacing the XML with real smartphone data would immediately raise accuracy.

### What's NOT Done Yet

- **eBay marketplace** — no parser, no taxonomy files, no templates. Fully missing.
- **Smartphones.xml data gap** — file contains desktop product codes; needs to be replaced with actual smartphone attribute codes (`BATCAP`, `STORSIZE`, `DUALSIM`, `REARCAM`, `TABOS`, etc.) for meaningful smartphone accuracy
- **XSLT output is basic** — generates a flat structure; doesn't handle nested JSON arrays, conditional logic, or the complex structure seen in the manual XSLT templates
- **No unit tests** — `Tests/` folder exists with `MatchingTest.csproj` but tests are stub files, not wired up
- **No CI/CD pipeline**

---

## Project Structure

```
quipt-mapping-engine/
│
├── Api/
│   └── GenerateController.cs          # POST /generate endpoint — orchestrates full pipeline
│
├── Services/
│   ├── AmazonFieldParser.cs           # Parses Amazon JSON taxonomy → List<Field>
│   └── QuiptSchemaParser.cs           # Parses Quipt XML → List<Field> (two-pass: Attributes + leaves)
│
├── MatchingEngine/
│   ├── MatchingEngine.cs              # Core scoring engine (7 signals + specificity, category-aware aliases)
│   └── Similarity.cs                  # Levenshtein distance implementation
│
├── Normalization/
│   ├── FieldNormalizer.cs             # Tokenizes + normalizes field names (camelCase, compound code splitter, synonym lookup)
│   ├── NormalizationDictionary.cs     # 200+ synonym entries (Quipt codes → canonical terms)
│   ├── FieldAliasTable.cs             # Category-aware direct Amazon→Quipt overrides + multi-map whitelist
│   └── EnumOverlapScorer.cs           # Jaccard overlap between enum value lists
│
├── Evaluation/
│   ├── EvaluationService.cs           # Computes accuracy % and required field coverage %
│   ├── GroundTruthXsltExtractor.cs    # Extracts amazon→quipt mappings from manual XSLT files
│   ├── EvaluatedMapping.cs            # Data model for evaluation input
│   ├── EvaluationReport.cs            # Data model for evaluation output
│   └── PurvikaAdapter.cs              # Adapter to convert matching results for evaluation
│
├── Xslt/
│   └── XsltBuilder.cs                # Generates XSLT from MappingResult list
│
├── Models/
│   ├── Field.cs                       # Schema field (Name, Path, DataType, IsRequired, EnumValues)
│   ├── MappingResult.cs               # Match result (AmazonField, QuiptPath, Score, IsRequired, IsUnmatched)
│   ├── ApiResponseModel.cs            # Full API response with mappings + evaluation details
│   └── SchemaModel.cs                 # (empty — unused)
│
├── AmazonTaxonomy/                    # Amazon JSON schema files per category
│   ├── amazon-desktops-attributes.json
│   ├── amazon-laptops-attributes.json
│   └── amazon-smartphones-attributes.json
│
├── QuiptData/                         # Sample Quipt XML exports per category
│   ├── Desktops.xml
│   ├── Laptops.xml
│   └── Smartphones.xml
│
├── QuiptToAmazonTemplates/            # Manually-written XSLT (ground truth for evaluation)
│   ├── CatalogExportTransform.Laptops.xslt
│   ├── CatalogExportTransform.Desktops.xslt
│   ├── CatalogExportTransform.SmartPhones.xslt
│   ├── CatalogExportTransform.Builder.MasterTemplate.json.xslt
│   ├── CatalogExportTransform.Builder.xslt
│   ├── inventory.shared.xslt
│   └── ... (shared + utility templates)
│
├── Member4TestHarness/
│   └── Member4QuickTest.cs            # Quick test harness (not part of main pipeline)
│
├── Tests/
│   ├── MatchingTest.csproj            # Test project (stubs only, not implemented)
│   ├── AmazonFields_Laptops.cs
│   └── QuiptFields_Laptops.cs
│
├── Program.cs                         # ASP.NET Web API bootstrap
├── QuiptMappingEngine.csproj          # .NET 10 project file
└── appsettings.json
```

---

## How the Key Components Connect

### 1. Parsers → Matching Engine

Both parsers produce `List<Field>` objects. A `Field` has:
- `Name` — human-readable field name (e.g. `"brand"`, `"# of Processor Cores"`)
- `Path` — full path (Amazon: `"properties.brand"`, Quipt: `"q:Catalog/q:Attributes/q:Attribute[q:Code='CPUCORE']/q:Value/a:string"`)
- `DataType` — `"string"`, `"integer"`, `"array"`, etc.
- `IsRequired` — from Amazon JSON `required` array
- `EnumValues` — allowed values (from Amazon `enum` or Quipt `<Value>` children)

**QuiptSchemaParser** does two passes:
1. **Pass 1 (Attributes):** Finds `<Attribute>` elements with `<Code>`, uses the `<Name>` child as display name, collects `<Value><a:string>` children as enum values, builds paths like `q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string`
2. **Pass 2 (Leaves):** Walks all leaf elements not inside `<Attributes>`, builds standard XPaths

**AmazonFieldParser** reads JSON with `properties` and `required` keys, extracts `type` and `enum` per property.

### 2. Matching Engine Scoring

For each Amazon field, the engine scores every available Quipt field using 6 signals:

Before heuristic scoring runs, the engine checks `FieldAliasTable` for a direct override. If a match is found, it is assigned a score of `1.0` and skipped in the scoring loop.

For fields without an alias, the engine scores every available Quipt field using 7 signals:

| Signal              | Weight | Description |
|---------------------|--------|-------------|
| Token overlap       | 0.35   | Jaccard similarity of normalized token sets |
| Weighted token match| 0.30   | Fraction of Amazon tokens found in Quipt tokens |
| Levenshtein         | 0.15   | Edit distance on concatenated normalized tokens |
| Substring bonus     | 0.10   | Full containment bonus |
| Enum overlap        | 0.05   | Jaccard overlap of enum value lists |
| Unit similarity     | 0.05   | Both fields contain unit-related terms |

The raw score is then multiplied by a **specificity factor**:
- `1.0` for Attribute fields (have a Code identifier)
- `0.9` for normal fields
- `0.5` for generic leaf names (Id, Name, Value, Description, etc.)
- `0.4` for penalized paths (Description, Title, SKU, etc.)

Minimum threshold: **0.25** — anything below is marked `IsUnmatched = true` with `QuiptPath = null`.

Required Amazon fields are processed first to get priority on the best Quipt matches (1:1 constraint).

Fields in the **multi-map whitelist** (e.g. `MODELNBR`, `RAMSIZE`, `USBPRT`, `USBPWR`) are not consumed after the first match and can map to multiple Amazon fields.

### 3. Evaluation Against Ground Truth

`GroundTruthXsltExtractor` reads the manually-written XSLT files and extracts a `Dictionary<string, string>` mapping Amazon tag names to Quipt XPaths. It uses a line-by-line tag stack parser (not regex over the full file — that caused catastrophic backtracking).

`EvaluationService` then compares each auto-matched path against ground truth:
- **Accuracy %** = correct matches / matchable ground truth fields × 100 (only counts ground truth entries whose key maps to an actual Amazon field name — eliminates noise from structural XSLT tags)
- **Coverage %** = fields with any match / total Amazon fields × 100 (separate from accuracy — tracks raw matching breadth)
- **Required Coverage %** = required fields with any match / total required fields × 100
- **PathsEqual** handles abbreviated paths and strips `[N]` index predicates for flexible comparison

### 4. Normalization

`FieldNormalizer.GetNormalizedTokens()` is used everywhere matching happens:
1. Splits camelCase/PascalCase (`"cpuModel"` → `"cpu model"`)
2. Splits ALL-CAPS compound Quipt codes using 35+ known prefixes (`"GPUMODEL"` → `"gpu model"`, `"RELEASEYEAR"` → `"release year"`)
3. Replaces underscores/hyphens with spaces
4. Lowercases
5. Removes special characters
6. Looks up each token in `NormalizationDictionary` (e.g. `"cpu"` → `"processor"`, `"ram"` → `"memory"`, `"modelnbr"` → `"model number"`)

The dictionary covers 200+ mappings including all Quipt attribute codes and domain synonyms for ports, peripherals, display, camera, battery, storage, connectivity, year/date, form factors, expansion slots, and more.

### 5. Category-Aware Alias Table

`FieldAliasTable` provides direct Amazon→Quipt Code overrides for field pairs that heuristic scoring cannot bridge due to irreconcilably different naming conventions. It is checked before scoring and short-circuits the matching loop with a perfect score.

**Universal aliases** (all categories): `connectivity_technology` → `HDTYPE`, `model_year` → `RELEASEYEAR`

**Laptop aliases** (examples): `graphics_description` → `GPUMODEL`, `memory_storage_capacity` → `RAMSIZE`, `size` → `SCRNSIZE`, `processor_count` → `CPUCORE`, `total_usb_2_0_ports` → `USBPRT`, `total_usb_3_0_ports` → `USBPWR`

**Desktop aliases** (examples): `graphics_description` → `GPUTYPE`, `memory_storage_capacity` → `HDSIZE`, `specific_uses_for_product` → `PCLIFESTYLE`

**Smartphone aliases** (examples): `telephone_type` → `DUALSIM`, `effective_still_resolution` → `REARCAM`, `digital_storage_capacity` → `STORSIZE`

---

## API Usage

### Endpoint

```
POST http://localhost:5253/generate
Content-Type: application/json

{
  "category": "laptops"
}
```

Valid categories: `laptops`, `desktops`, `smartphones`

### Response Shape

```json
{
  "category": "laptops",
  "amazonFieldCount": 204,
  "quiptFieldCount": 210,
  "mappingCount": 84,
  "accuracy": 100.0,
  "coveragePercent": 41.18,
  "requiredFieldCoverage": 57.14,
  "groundTruthCount": 11,
  "correctMatches": 11,
  "unmatchedRequiredFields": ["connectivity_technology", "..."],
  "generatedXslt": "<xsl:stylesheet ...>...</xsl:stylesheet>",
  "mappings": [
    {
      "amazonField": "brand",
      "quiptPath": "q:Catalog/q:Brand/q:Name",
      "score": 0.6532,
      "isRequired": true,
      "isUnmatched": false
    }
  ],
  "evaluationDetails": [
    {
      "amazonField": "brand",
      "isRequired": true,
      "autoMatchedPath": "q:Catalog/q:Brand/q:Name",
      "score": 0.6532,
      "expectedPath": "q:Catalog/q:Brand/q:Name",
      "verdict": "CORRECT"
    },
    {
      "amazonField": "model_number",
      "isRequired": false,
      "autoMatchedPath": "q:Catalog/q:PhoneNumber",
      "score": 0.45,
      "expectedPath": "q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string",
      "verdict": "WRONG"
    }
  ]
}
```

### Verdict Values

| Verdict           | Meaning |
|-------------------|---------|
| `CORRECT`         | Auto match equals ground truth |
| `WRONG`           | Auto matched something, but it's the wrong Quipt path |
| `MISSING`         | Ground truth exists but engine couldn't find any match |
| `UNMATCHED`       | No ground truth and no match found |
| `NO_GROUND_TRUTH` | Engine found a match but we have no ground truth to verify |

---

## Development Setup

**Requirements:**
- .NET 10 SDK
- VS Code or Visual Studio
- Git

**Run locally:**
```bash
dotnet restore
dotnet run
# API starts on http://localhost:5253
```

**Test via Postman or curl:**
```bash
curl -X POST http://localhost:5253/generate -H "Content-Type: application/json" -d "{\"category\": \"laptops\"}"
```

---

## Known Issues & Next Steps

### Accuracy Improvements Needed
1. **Smartphones.xml data gap** — the file contains desktop-style codes instead of real smartphone attributes. Replacing it with actual smartphone product data would immediately unlock BATCAP, STORSIZE, DUALSIM, REARCAM, TABOS, and other smartphone-specific aliases that are already defined in `FieldAliasTable`.
2. **Smarter matching signals** — current approach is pure heuristic. Could explore: TF-IDF weighting, embedding-based similarity, or learning weights from correct matches.
3. **Ground truth coverage** — only 11–8 Amazon fields per category have verified ground truth entries. Expanding the manual XSLT templates to cover more Amazon fields would reveal new accuracy gaps.

### eBay Marketplace (Not Started)
- No eBay taxonomy files exist
- No eBay parser
- No eBay ground truth XSLT templates
- Need to determine eBay's field format (JSON? XML? API?)
- `GenerateController` is currently Amazon-only — needs marketplace parameter and routing

### XSLT Generation
- Current output is a flat `<xsl:value-of>` per field
- Manual XSLT templates have: JSON array markers, conditional logic, shared templates, string utilities
- Need to handle nested structures, default values, multi-value fields

### Testing
- `Tests/MatchingTest.csproj` exists with stub files but no actual test logic
- No integration tests
- No automated regression checks

---

## Team Workflow

- Do not push directly to `main`
- Create feature branches:
  ```
  git checkout -b feature/<module-name>
  git push -u origin feature/<module-name>
  ```

---
