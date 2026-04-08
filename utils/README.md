# OmniGWAS utils

Auxiliary data processing tools for GWAS analysis. A comprehensive suite of R functions with Python CLI/API wrappers for common data manipulation tasks.

## Module Overview

The `utils` module provides 7 functional sub-modules covering data reading, type conversion, export, renaming, and cleaning operations.

### Sub-Modules

| Module | File | Description |
|--------|------|-------------|
| Data Reading | `R/read_table.R` | Read tabular data files (txt, tsv, csv, gz) |
| Type Conversion | `R/convert_pos.R` | Convert columns to numeric/integer/character |
| Excel Export | `R/export_excel.R` | Export to Excel (.xlsx) with writexl |
| Column Renaming | `R/rename_columns.R` | Rename columns and values |
| RDS Export | `R/export_rds.R` | Save/load R objects to RDS format |
| Data Cleaning | `R/clean_compress.R` | Remove columns and compress files |
| TXT Export | `R/export_txt.R` | Export to text files with format options |

## Quick Start

### R Usage

```r
# Load all functions
source("utils/R/utils.R")

# Or source individual modules
source("utils/R/read_table.R")
source("utils/R/export_excel.R")

# Show module info
print_utils_info()

# List all functions
list_utils_functions()
```

### Python CLI

```bash
# Read data file
python -m utils.src read --input results.txt.gz

# Convert columns to numeric
python -m utils.src convert --input data.rds --col pos.outcome --col chr.outcome --output cleaned.rds

# Export to Excel
python -m utils.src export-excel --input data.rds --output results.xlsx

# Rename column values
python -m utils.src rename --input data.rds --col outcome --pattern "Nonalcoholic_steatohepatitis" --replacement "NASH" --output renamed.rds

# Clean and compress GWAS data
python -m utils.src clean --input data.rds --output cleaned.txt.gz

# Quick clean for FUMA
python -m utils.src clean-gwas --input data.rds --output FUMA_input.txt.gz
```

### Python API

```python
from utils.src import wrapper

# Read data
result = wrapper.run_read_table("results.txt.gz")

# Convert columns
result = wrapper.run_convert_numeric(
    input_file="data.rds",
    columns=["pos.outcome", "chr.outcome"],
    to_type="numeric",
    output_file="cleaned.rds"
)

# Export to Excel
wrapper.run_export_excel("data.rds", "results.xlsx")

# Clean and compress
wrapper.run_clean_compress(
    input_file="data.rds",
    keep_cols=["SNP", "chr", "pos", "pval", "beta", "se"],
    output_file="cleaned.txt.gz"
)
```

## Function Reference

### Data Reading

#### `read_data(file_path, header=TRUE, sep="auto", ...)`
Read tabular data with automatic separator detection.

```r
# Read tab-separated file
data <- read_data("C:/data/results.txt")

# Read gzipped file
data <- read_data("results.txt.gz")

# Read with custom settings
data <- read_data("results.csv", sep = ",", na.strings = c("NA", "-"))
```

#### `read_gwas_sumstats(file_path, ...)`
Specialized reader for GWAS summary statistics.

```r
data <- read_gwas_sumstats("GWAS_summary_stats.txt.gz")
```

### Type Conversion

#### `convert_to_numeric(data, col_name, quiet=FALSE)`
Convert column to numeric with NA reporting.

```r
# Convert and report
data <- convert_to_numeric(data, "pos.outcome")
# Output: [2024-01-01 10:00:00] Converted 'pos.outcome': character -> numeric | NAs: 0 (new: 0)

# Check NA count
result <- convert_to_numeric(data, "pos.outcome", quiet = FALSE)
cat("NA count:", sum(is.na(result$pos.outcome)))
```

#### `convert_columns_to_numeric(data, col_names)`
Batch convert multiple columns.

```r
data <- convert_columns_to_numeric(data, c("pos.outcome", "chr.outcome", "pval.outcome"))
```

#### `check_column_types(data)`
Display column types and NA statistics.

```r
check_column_types(data)
# Output:
# Column Name                  Type           NAs
# SNP                          character      0 (0%)
# chr.outcome                  numeric        0 (0%)
# pos.outcome                  numeric        5 (0.1%)
# pval.outcome                 numeric        0 (0%)
```

### Excel Export

#### `export_to_excel(data, output_path, sheet_name="Sheet1", ...)`
Export data frame to Excel file.

```r
# Basic export
export_to_excel(data, "E:/results/output.xlsx")

# With custom sheet name
export_to_excel(data, "report.xlsx", sheet_name = "GWAS Results")
```

#### `export_sheets_to_excel(sheet_list, output_path)`
Export multiple data frames to separate sheets.

```r
sheets <- list(
    "Summary" = summary_data,
    "Top Hits" = top_hits,
    "QC" = qc_results
)
export_sheets_to_excel(sheets, "complete_report.xlsx")
```

### Column Renaming

#### `rename_values(data, col_name, old_values, new_values)`
Rename specific values within a column.

```r
# Rename disease identifiers
data <- rename_values(data, "outcome",
    old_values = c("Nonalcoholic_steatohepatitis_R11", "Liver_cancer"),
    new_values = c("NASH", "HCC")
)
```

#### `standardize_colnames(data, style="snake")`
Standardize column names to consistent format.

```r
# Convert to snake_case
data <- standardize_colnames(data, style = "snake")
# "EffectAlleleFreq" -> "effect_allele_freq"
```

### RDS Operations

#### `save_to_rds(data, output_path, compress="gzip", ...)`
Save R object to RDS file.

```r
# Save with default gzip compression
save_to_rds(data, "E:/mr/comorbidity/data.rds")

# Save with xz compression (smaller but slower)
save_to_rds(data, "data.rds", compress = "xz")
```

#### `save_with_timestamp(data, base_name, output_dir, ...)`
Save with automatic timestamp in filename.

```r
# Creates: processed_data_20240101_143022.rds
path <- save_with_timestamp(data, "processed_data", "E:/results/")
```

### Data Cleaning

#### `clean_and_compress(data, drop_cols=NULL, keep_cols=NULL, output_path, ...)`
Remove columns and save as compressed file.

```r
# Drop specific columns
clean_and_compress(data,
    drop_cols = c("outcome", "id.outcome", "mr_keep.outcome"),
    output_path = "cleaned.txt.gz"
)

# Keep only essential columns
clean_and_compress(data,
    keep_cols = c("SNP", "chr", "pos", "pval", "beta", "se"),
    output_path = "simple_data.txt.gz"
)
```

#### `quick_clean_gwas(data, output_path, ...)`
Quick clean for GWAS: keep essential columns.

```r
quick_clean_gwas(data, "FUMA_input.txt.gz")
```

### TXT Export

#### `export_to_txt(data, output_path, sep="\t", ...)`
Export data frame to text file.

```r
# Tab-separated
export_to_txt(data, "E:/results/output.txt")

# CSV
export_to_txt(data, "results.csv", sep = ",")
```

#### `export_for_fuma(data, output_path)`
Export in FUMA GWAS annotation format.

```r
export_for_fuma(data, "E:/mr/liver/HCC/FUMA/VATV_FUMA.txt")
```

## Example Workflows

### Complete GWAS Data Processing

```r
source("utils/R/utils.R")

# 1. Read raw data
raw_data <- read_data("C:/GWAS/LF_HCC_results.txt")

# 2. Convert position columns
processed <- convert_columns_to_numeric(raw_data, c("pos.outcome", "chr.outcome"))

# 3. Rename identifiers
processed <- rename_values(processed, "outcome",
    old_values = "Nonalcoholic_steatohepatitis_R11",
    new_values = "NASH"
)

# 4. Save as RDS
save_to_rds(processed, "E:/mr/comorbidity/LF_liver_disease/GWAS/NASH.rds")

# 5. Export to Excel
export_to_excel(processed, "E:/mr/liver/HCC/Imaging/supergnova/LV_LC.xlsx")

# 6. Clean and compress for FUMA
quick_clean_gwas(processed, "E:/mr/liver/HCC/FUMA/liver_cancer.txt.gz")
```

### Python Batch Processing

```bash
#!/bin/bash
# batch_process.sh

# Convert columns
python -m utils.src convert -i raw_data.rds -o temp1.rds -c pos.outcome -c chr.outcome

# Rename values
python -m utils.src rename -i temp1.rds -o temp2.rds -c outcome -p "Nonalcoholic_steatohepatitis" -r "NASH"

# Clean and export
python -m utils.src clean-gwas -i temp2.rds -o cleaned_results.txt.gz

# Export to Excel
python -m utils.src export-excel -i temp2.rds -o final_report.xlsx

# Cleanup
rm temp1.rds temp2.rds
```

## Configuration

The module can be configured via YAML files:

```yaml
# config.yaml
example_1:
  description: "Read and convert GWAS data"
  steps:
    - action: read
      input: "GWAS_results.txt.gz"
    - action: convert
      columns:
        - "pos.outcome"
        - "pval.outcome"
    - action: export
      format: "rds"
      output: "cleaned_GWAS.rds"
```

## Requirements

### R Packages
- `dplyr` - Data manipulation
- `stringr` - String operations
- `writexl` - Excel export (optional)

### Python
- Python 3.7+
- `subprocess` (standard library)
- R installation with Rscript in PATH

## Installation

```bash
# Clone repository
git clone https://github.com/tiandianzhe/OmniGWAS.git

# Install R packages (in R)
install.packages(c("dplyr", "stringr", "writexl"))
```

## License

MIT License - see main repository for details.

## See Also

- [OmniGWAS main repository](https://github.com/tiandianzhe/OmniGWAS)
- [batch_gsmap module](../batch_gsmap/)
- [batch_smr_dynamic module](../batch_smr_dynamic/)
