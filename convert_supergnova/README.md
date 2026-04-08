# convert_supergnova

Convert [SuperGNOVA](https://github.com/yanqiliu1995/Supergnova) TXT output files to structured CSV format for downstream GWAS analysis.

## Features

- Convert SuperGNOVA TXT output to properly formatted CSV
- Preserve all 10 output columns: chr, start, end, rho, corr, h2_1, h2_2, var, p, m
- Skip malformed rows with detailed warnings
- Batch conversion support for multiple files
- Programmatic API for integration into pipelines

## Installation

```bash
# From source
git clone https://github.com/tiandianzhe/OmniGWAS.git
cd OmniGWAS/convert_supergnova
pip install -e .

# Or install directly
pip install .
```

## Quick Start

### Python API

```python
from convert_supergnova import convert_supergnova_to_csv

# Convert a single file
stats = convert_supergnova_to_csv(
    txt_path="results.txt",
    csv_path="results.csv"
)
# Conversion Report
# Total rows : 1000
# Converted  : 998
# Skipped    : 2
```

### Command Line

```bash
# Single file
python -m src.cli input.txt -o output.csv

# Batch conversion
python -m src.cli --batch input_dir --out output_dir

# Install as command (after pip install)
supergnova2csv input.txt -o output.csv
```

## Output Columns

| Column | Description |
|--------|-------------|
| chr    | Chromosome number |
| start  | Region start position (bp) |
| end    | Region end position (bp) |
| rho    | Genetic correlation coefficient |
| corr   | Correlation estimate |
| h2_1   | Heritability estimate for trait 1 |
| h2_2   | Heritability estimate for trait 2 |
| var    | Variance estimate |
| p      | P-value for significance test |
| m      | Number of SNPs in the region |

## Citation

If you use this tool in your research, please cite:

- Liu Y, et al. SuperGNOVA: dissecting genetic covariance across the human phenome. *bioRxiv* (2024).
- OmniGWAS: https://github.com/tiandianzhe/OmniGWAS
