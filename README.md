# OmniGWAS

> An integrated GWAS (Genome-Wide Association Study) analysis toolkit combining R and Python for genetic research.

## Overview

OmniGWAS is a modular, open-source toolkit designed for geneticists and bioinformaticians conducting GWAS and related analyses. The project is structured with independent submodules for different analysis tasks, making it easy to use specific components without installing the entire suite.

## Features

- **Modular Design**: Each analysis module is self-contained with its own documentation, tests, and examples
- **Multi-language Support**: Combines the statistical power of R with the flexibility of Python
- **Bioinformatics Focused**: Comprehensive tools for GWAS and post-GWAS analysis
- **Beginner Friendly**: Clear documentation, example data, and comprehensive README files
- **Comprehensive Coverage**: Five major analysis categories covering basic GWAS to multi-omics integration

## Analysis Categories

The analysis code is organized into five main categories in the `analysis/` directory:

### 1. Basic GWAS Analysis (`analysis/01_basic_gwas/`)
Core GWAS data processing, quality control, locus extraction, and basic statistical analysis.
- GWAS locus extraction (`get_loci`, `get_loci2`)
- Format conversion (`convert_format`, `liftover_convert_data`)
- GWAS Meta-analysis (`metal_gwas`)
- Gene-based analysis (`run_magmar`, `run_gcta_gene_based_analysis`)
- Fine-mapping (`focus_finemaping`, `gsmap_format`)
- Quality control (`run_EasyQC_munge`, `run_ldsc_EFA`)

### 2. Multi-omics GWAS (`analysis/02_multiomics_gwas/`)
Integration of eQTL, pQTL, mQTL and other omics data with GWAS.
- GTEx/PsychENCODE data extraction
- TWAS analysis (`SPrediXcan`, `SMulTiXcan`, `UTMOST`)
- HESS analysis
- MR-JTI cross-tissue analysis
- XWAS/FUSION analysis

### 3. Single-cell GWAS (`analysis/03_singlecell_gwas/`)
Single-cell and spatial transcriptomics GWAS analysis.
- Dynamic immune single-cell SMR (`batch_xqtl_smr`)
- pQTL/mQTL/eQTL SMR analysis
- Multi-omics SMR (`multi_omic_MR`, `multi_omic_SMR`)
- scTenifoldKnk virtual knockout analysis

### 4. Comorbidity GWAS (`analysis/04_comorbidity_gwas/`)
Disease comorbidity and two-sample MR analysis.
- Two-sample MR (`mr_modified`)
- Colocalization (`data_to_coloc`, `run_hyprcoloc`)
- LDSC and MRlap
- Advanced MR methods (HDL, pleioFDR, CAUSE, LCV, PLACO)
- Genetic correlation (GNOVA, SuperGNOVA)
- Multi-trait analysis (MTAG, CPASSOC, Mixer, LAVA)
- Multivariate MR (`run_mvmr`)

### 5. Auxiliary Tools (`analysis/05_auxiliary_tools/`)
Supporting analysis tools including data processing and visualization.
- Data I/O and cleaning
- Excel/TXT export
- Proteomics MR (`PWMR3`)
- Result visualization
- Multi-omics data processing

## Project Structure

```
OmniGWAS/
├── README.md                    # Main project README
├── LICENSE                      # MIT License
├── docs/                        # Project-wide documentation
├── data/                        # Example datasets
└── analysis/                    # Analysis code (5 categories)
    ├── 01_basic_gwas/          # Basic GWAS analysis
    ├── 02_multiomics_gwas/     # Multi-omics GWAS
    ├── 03_singlecell_gwas/     # Single-cell GWAS
    ├── 04_comorbidity_gwas/    # Comorbidity GWAS
    └── 05_auxiliary_tools/    # Auxiliary tools
        ├── utils/                      # [Module] Auxiliary data processing tools
        ├── manhattan_plot/           # [Module] Manhattan plot and QQ plot
        ├── batch_gsmap/              # [Module] Batch gsMap spatial colocalization
        ├── batch_smr_dynamic/        # [Module] Batch SMR dynamic immune analysis
        └── convert_supergnova/       # [Module] SuperGNOVA TXT to CSV converter
```

## Available Modules

### convert_supergnova

Convert SuperGNOVA TXT output files to CSV format for downstream analysis.

**Quick start:**
```python
from convert_supergnova import convert_supergnova_to_csv
stats = convert_supergnova_to_csv("input.txt", "output.csv")
```

### manhattan_plot

Generate publication-ready Manhattan plots and Q-Q plots from GWAS summary statistics. Supports both P-values and FDR values with customizable visualization parameters.

**Quick start:**
```python
from manhattan_plot.src import wrapper

# Create Manhattan plot
wrapper.create_manhattan(
    input_file="data.csv",
    fdr_col="FDR",
    threshold=0.05,
    output="manhattan.png"
)

# Create Q-Q plot
wrapper.create_qq(
    input_file="data.csv",
    pval_col="P",
    output="qq_plot.png"
)
```

**R API:**
```r
source("manhattan_plot/R/manhattan_plot.R")
create_manhattan_plot(data, fdr_col="FDR", threshold=0.05)
```

### batch_gsmap

Batch gsMap spatial transcriptomics GWAS colocalization analysis. Execute gsMap analysis across multiple spatial transcriptomics samples in batch mode with parallel processing and comprehensive result logging.

**Quick start:**
```bash
# Python CLI
python -m batch_gsmap.src \
    --samples E9.5_E1S1 E10.5_E1S1 \
    --sumstats GWAS.sumstats.gz \
    --trait NAFLD \
    --h5ad-dir /data/ST/ \
    --output /results/NAFLD/

# Or use config file
python -m batch_gsmap.src --config example/config.yaml
```

**Python API:**
```python
from batch_gsmap.src import wrapper
result = wrapper.run_batch_gsmap(
    sample_names=["E9.5_E1S1", "E10.5_E1S1"],
    sumstats_file="GWAS.sumstats.gz",
    trait_name="NAFLD",
    h5ad_dir="/data/ST/",
    save_base_path="/results/"
)
```

**R API:**
```r
source("batch_gsmap/R/batch_gsmap.R")
result <- run_gsmap_batch(
  sample_names = c("E9.5_E1S1", "E10.5_E1S1"),
  sumstats_file = "GWAS.sumstats.gz",
  trait_name = "NAFLD",
  h5ad_dir = "/data/ST/",
  save_base_path = "/results/"
)
```

### batch_smr_dynamic

Batch SMR (Summary-based Mendelian Randomization) dynamic immune single-cell analysis. Execute SMR analysis across multiple dynamic immune cell populations (T cells, NK cells, etc.) with time-course data support.

**Quick start:**
```bash
# Python CLI - use default dynamic immune resources
python -m batch_smr_dynamic.src \
    --default-resources \
    --out-filename GWAS.rds \
    --outcome-name NAFLD \
    --output /results/NAFLD/dynamic/

# Or specify specific resources
python -m batch_smr_dynamic.src \
    --resources TN_0h TN_16h TN_40h TEM_0h TEM_16h \
    --out-filename GWAS.rds \
    --outcome-name NAFLD \
    --output /results/
```

**Python API:**
```python
from batch_smr_dynamic.src import wrapper
result = wrapper.run_smr_dynamic_batch(
    xqtl_resources=["TN_0h", "TN_16h", "TN_40h"],
    out_filename="GWAS.rds",
    outcome_name="NAFLD",
    save_base_path="/results/"
)
```

**R API:**
```r
source("batch_smr_dynamic/R/batch_smr_dynamic.R")
result <- run_smr_dynamic_batch(
  xqtl_resources = c("TN_0h", "TN_16h", "TN_40h"),
  out_filename = "GWAS.rds",
  outcome_name = "NAFLD",
  save_base_path = "/results/"
)
```

### utils - Auxiliary Analysis Tools

Comprehensive suite of 7 sub-modules for data processing: reading, type conversion, Excel/RDS/TXT export, column renaming, and data cleaning. Optimized for GWAS summary statistics and Meta-analysis workflows.

**Quick start:**
```bash
# Read data file
python -m utils.src read --input results.txt.gz

# Convert columns to numeric
python -m utils.src convert --input data.rds --col pos.outcome --col chr.outcome --output cleaned.rds

# Export to Excel
python -m utils.src export-excel --input data.rds --output results.xlsx

# Clean and compress GWAS data
python -m utils.src clean --input data.rds --output cleaned.txt.gz

# Quick clean for FUMA
python -m utils.src clean-gwas --input data.rds --output FUMA_input.txt.gz
```

**Python API:**
```python
from utils.src import wrapper

# Read data
result = wrapper.run_read_table("results.txt.gz")

# Convert columns
wrapper.run_convert_numeric(
    input_file="data.rds",
    columns=["pos.outcome", "chr.outcome"],
    output_file="cleaned.rds"
)

# Export to Excel
wrapper.run_export_excel("data.rds", "results.xlsx")

# Clean and compress
wrapper.run_quick_clean_gwas("data.rds", "FUMA_input.txt.gz")
```

**R API:**
```r
source("utils/R/utils.R")

# Read data
data <- read_data("results.txt.gz")

# Convert columns
data <- convert_to_numeric(data, "pos.outcome")

# Rename values
data <- rename_values(data, "outcome",
    old_values = c("Nonalcoholic_steatohepatitis_R11"),
    new_values = c("NASH")
)

# Export to Excel
export_to_excel(data, "results.xlsx")

# Clean and compress
clean_and_compress(data,
    keep_cols = c("SNP", "chr", "pos", "pval", "beta", "se"),
    output_path = "cleaned.txt.gz"
)
```

**Included Sub-Modules:**

| Module | Description |
|--------|-------------|
| `read_table.R` | Read tabular data (txt, tsv, csv, gz) |
| `convert_pos.R` | Convert columns to numeric/integer/character |
| `export_excel.R` | Export to Excel (.xlsx) with writexl |
| `rename_columns.R` | Rename columns and values |
| `export_rds.R` | Save/load R objects to RDS format |
| `clean_compress.R` | Remove columns and compress files |
| `export_txt.R` | Export to text files (FUMA, etc.) |

## Installation

```bash
# Clone the repository
git clone https://github.com/tiandianzhe/OmniGWAS.git
cd OmniGWAS

# Install a specific module
cd convert_supergnova
pip install -e .

# Install all dependencies (coming soon)
# pip install -r requirements.txt
```

## Requirements

- Python 3.8+
- R 4.0+ (for analysis scripts)

## Getting Started

1. Clone the repository
2. Navigate to the module you need
3. Follow the module-specific README for usage instructions
4. Check the `example/` directory for sample data

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Dianzhe Tian** 
- GitHub: [@tiandianzhe](https://github.com/tiandianzhe)
- Email: tiandianzhe@outlook.com
- Affiliation: Peking Union Medical College Hospital

## Acknowledgments

This toolkit was developed to support GWAS and post-GWAS bioinformatics research. We welcome collaborations and contributions from the research community.

## Development Notes

This analysis codebase is built upon **easyGWAS** (v4.0.0), a post-GWAS analysis package developed by the easyDSM team. The original easyGWAS package was created by Meiyunyun and serves as the foundation for our GWAS analysis workflows.

**easyGWAS Package Information:**
- **Package**: easyGWAS
- **Version**: 4.0.0
- **Author**: Meiyunyun
- **Maintainer**: myy <15985997536@163.com>
- **License**: GPL-3
- **Developed by**: easyDSM Team
- 
**WorkBuddy AI Assistant** - This project was developed with assistance from WorkBuddy AI, which helped with:
- Module architecture design and code structure
- Documentation writing and formatting
- Python/R integration patterns
- Unit test generation
