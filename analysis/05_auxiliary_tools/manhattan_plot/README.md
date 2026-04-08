# manhattan_plot

> Manhattan plot and Q-Q plot visualization for GWAS results

**Assisted by WorkBuddy AI Assistant** | Version 1.0.0

---

## Overview

This module provides tools for generating publication-ready Manhattan plots and Q-Q plots from GWAS summary statistics. It combines the flexibility of R's ggplot2 with Python's ease of use.

## Features

- Publication-ready Manhattan plots with customizable parameters
- Q-Q plot generation with genomic inflation factor (lambda) calculation
- Batch processing for multiple analyses
- Support for both P-values and FDR values
- Custom SNP labeling
- Flexible color schemes
- High-resolution output (up to 600 DPI)

## Installation

### R Dependencies

The module requires the following R packages (auto-installed on first run):

```r
data.table, dplyr, ggplot2, ggrepel, scales
```

### Python Dependencies

```bash
pip install -r requirements.txt
```

## Quick Start

### Python API

```python
from manhattan_plot.src import wrapper

# Create Manhattan plot
wrapper.create_manhattan(
    input_file="your_data.csv",
    output="manhattan.png",
    fdr_col="FDR",
    threshold=0.05
)

# Create Q-Q plot
wrapper.create_qq(
    input_file="your_data.csv",
    output="qq_plot.png",
    pval_col="P"
)
```

### R API

```r
source("R/manhattan_plot.R")

# Load your data
data <- read.csv("your_data.csv")

# Create Manhattan plot
create_manhattan_plot(
  data = data,
  fdr_col = "FDR",
  threshold = 0.05,
  output = "manhattan.png"
)
```

### Command Line

```bash
# Basic usage
python -m src.wrapper --input data.csv --fdr_col FDR --threshold 0.05

# With p-value threshold
python -m src.wrapper --input data.csv --pval_col P --threshold 5e-8 --threshold_type pvalue

# Custom output
python -m src.wrapper --input data.csv --output my_plot.png --width 14 --height 6 --dpi 600

# Label specific SNPs
python -m src.wrapper --input data.csv --label_snps rs123456,rs234567,rs345678
```

## Input Data Format

The input file should be a CSV or tab-delimited TXT with the following columns:

| Column | Description | Required |
|--------|-------------|----------|
| SNP | SNP identifier (rsID) | Yes |
| CHR | Chromosome number (1-22, X, Y) | Yes |
| BP | Base pair position | Yes |
| P | P-value | Yes (or FDR) |
| FDR | False discovery rate | Yes (or P) |

Example:

```csv
SNP,CHR,BP,P,FDR
rs123456,1,100000,0.001,0.05
rs234567,1,200000,0.0001,0.01
rs345678,2,100000,0.5,0.8
```

## Parameters

### create_manhattan_plot (R) / create_manhattan (Python)

| Parameter | Default | Description |
|-----------|---------|-------------|
| threshold | 0.05 | Significance threshold |
| threshold_type | "fdr" | "fdr" or "pvalue" |
| sig_point_color | "black" | Color for significant points |
| sig_point_size | 0.8 | Size of significant points |
| nonsig_point_size | 0.5 | Size of non-significant points |
| label_fontsize | 3 | Font size for SNP labels |
| width | 12 | Plot width in inches |
| height | 6 | Plot height in inches |
| dpi | 300 | Resolution |
| title | "Manhattan Plot" | Plot title |

## Output

The module generates high-quality PNG images suitable for publication:

- Manhattan plot: Chromosome-wide view with significance threshold
- Q-Q plot: Observed vs expected P-value distribution with lambda

## Example Output

See `example/example_data.csv` for sample input data.

## License

Part of OmniGWAS toolkit. MIT License.
