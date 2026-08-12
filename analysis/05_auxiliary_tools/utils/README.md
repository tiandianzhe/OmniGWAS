# OmniGWAS utils

Version 0.1.0

`utils` is the maintained auxiliary data-processing layer for OmniGWAS. It contains small R functions plus a Python API and CLI for common GWAS file operations.

## Maintained operations

| Python function | Operation |
| --- | --- |
| `run_read_table()` | Read a CSV, TSV, text, or gzip-compressed table |
| `run_convert_numeric()` | Convert selected RDS data-frame columns to numeric, integer, or character |
| `run_export_excel()` | Export an RDS data frame to XLSX |
| `run_rename_columns()` | Replace values in one RDS data-frame column |
| `run_export_rds()` | Re-save an RDS object with an explicit compression mode |
| `run_clean_compress()` | Keep or drop columns and write delimited output |
| `run_export_txt()` | Export an RDS data frame to delimited text |
| `run_quick_clean_gwas()` | Keep the maintained essential GWAS column set |
| `run_batch_convert()` | Compatibility API for multi-column conversion |

The underlying R files also expose focused functions for table reading, type conversion, Excel export, value and column renaming, RDS I/O, column subsetting, compressed output, and text export.

## Reproducible setup

Run the locked project setup from the repository root:

```sh
uv sync --locked --all-groups
Rscript -e 'renv::restore(prompt=FALSE)'
```

Dependencies such as `jsonlite`, `data.table`, `stringr`, and `writexl` are restored from `renv.lock`. The module does not install packages at runtime.

## Command line

Run the wrapper from `analysis/05_auxiliary_tools`:

```sh
cd analysis/05_auxiliary_tools

# Inspect a table
../../.venv/bin/python -m utils.src read \
  --input path/to/results.tsv \
  --sep tab

# Convert two columns in an RDS data frame
../../.venv/bin/python -m utils.src convert \
  --input path/to/input.rds \
  --output path/to/converted.rds \
  --col chr.outcome \
  --col pos.outcome \
  --type numeric

# Export an RDS data frame
../../.venv/bin/python -m utils.src export-txt \
  --input path/to/input.rds \
  --output path/to/output.tsv \
  --sep tab

# Keep the default GWAS columns
../../.venv/bin/python -m utils.src clean-gwas \
  --input path/to/input.rds \
  --output path/to/fuma-input.txt.gz
```

Other subcommands are `export-excel`, `rename`, `export-rds`, and `clean`. Use `../../.venv/bin/python -m utils.src --help` and the subcommand help for current options.

## Python API

```python
from utils.src.wrapper import (
    run_clean_compress,
    run_convert_numeric,
    run_read_table,
)

read_result = run_read_table("path/to/results.tsv", sep="tab")

convert_result = run_convert_numeric(
    input_file="path/to/input.rds",
    output_file="path/to/converted.rds",
    columns=["chr.outcome", "pos.outcome"],
    to_type="numeric",
)

clean_result = run_clean_compress(
    input_file="path/to/input.rds",
    output_file="path/to/cleaned.txt.gz",
    keep_cols=["SNP", "chr", "pos", "pval", "beta", "se"],
)
```

Each wrapper returns a result mapping with a `success` flag and captured output or error information.

## R API

From `analysis/05_auxiliary_tools`:

```r
source("utils/R/utils.R")
load_utils("utils/R", quiet = TRUE)

data <- read_data("path/to/results.tsv", sep = "\t")
data <- convert_columns_to_numeric(data, c("chr", "pos"))
export_to_txt(data, "path/to/cleaned.tsv")
```

Use `list_utils_functions()` after loading to inspect the available R function names.

## Security boundary

The Python wrapper serializes an allowlisted operation and its values as JSON on standard input. A fixed R driver dispatches only known operations. The wrapper does not generate executable R source, does not invoke `Rscript -e`, and does not create predictable executable temporary scripts. Paths and input files remain untrusted and should be reviewed before use.

Cross-language tests exercise this boundary with quotes, Unicode, and shell metacharacters, and also run real file-output operations through R.

## License

This module is part of OmniGWAS and uses the repository MIT license.
