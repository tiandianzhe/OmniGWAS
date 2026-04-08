# batch_smr_dynamic

> Batch SMR (Summary-based Mendelian Randomization) dynamic immune single-cell analysis module for OmniGWAS toolkit.

**Powered by WorkBuddy AI Assistant**

## Overview

This module provides tools for running SMR analysis across multiple dynamic immune cell populations in batch mode. It processes single-cell eQTL data from various T cell subsets at different timepoints, enabling analysis of dynamic gene expression changes in response to stimulation.

## Features

- Batch processing of multiple dynamic immune cell populations
- Support for time-course data (0h, 16h, 40h, 5d, LA)
- Integration with easyGWAS::batch_xqtl_smr
- Comprehensive result consolidation
- Heatmap visualization of dynamic SMR results
- Python CLI and R API dual interfaces

## Prerequisites

### R Dependencies

```r
# Install OmniGWAS package
devtools::install_github("tiandianzhe/easyGWAS")

# Install additional R packages
install.packages("yaml")
install.packages("jsonlite")
install.packages("ggplot2")
```

### Python Dependencies

```bash
pip install pyyaml
```

## Quick Start

### Python CLI

```bash
# Method 1: Use all default dynamic immune resources
python -m batch_smr_dynamic.src \
    --default-resources \
    --out-filename GWAS.rds \
    --outcome-name NAFLD \
    --output /results/NAFLD/dynamic/

# Method 2: Specify specific resources
python -m batch_smr_dynamic.src \
    --resources TN_0h TN_16h TN_40h TEM_0h TEM_16h \
    --out-filename GWAS.rds \
    --outcome-name NAFLD \
    --output /results/

# Method 3: Use configuration file
python -m batch_smr_dynamic.src --config config.yaml
```

### Python API

```python
from batch_smr_dynamic.src import wrapper

# Run batch SMR analysis
result = wrapper.run_smr_dynamic_batch(
    xqtl_resources=["TN_0h", "TN_16h", "TN_40h", "TEM_0h", "TEM_16h"],
    out_filename="GWAS.rds",
    outcome_name="NAFLD",
    save_base_path="/results/NAFLD/"
)

# Get default resources
resources = wrapper.get_default_dynamic_resources()
print(f"Total resources: {len(resources)}")
```

### R API

```r
source("batch_smr_dynamic/R/batch_smr_dynamic.R")

# Define resources
xqtl_resources <- c(
  "TN_0h", "TN_16h", "TN_40h", "TN_5d",
  "TEM_0h", "TEM_16h", "TEM_40h", "TEM_5d",
  "TCM_0h", "TCM_16h", "TCM_40h", "TCM_5d"
)

# Run batch analysis
result <- run_smr_dynamic_batch(
    xqtl_resources = xqtl_resources,
    out_filename = "GWAS.rds",
    outcome_name = "NAFLD",
    save_base_path = "/results/NAFLD/"
)

# Access results
print(result$success)
print(result$failed)
```

## Supported Cell Types and Timepoints

The module supports the following dynamic immune cell populations:

| Cell Type | Timepoints | Description |
|-----------|------------|-------------|
| TN | 0h, 16h, 40h, 5d, LA | Naive T cells |
| TN_cycling | 40h, 5d | Cycling naive T cells |
| TN_IFN | 16h, 40h, 5d, LA | IFN-stimulated naive T cells |
| TN_HSP | 5d | HSP-stimulated naive T cells |
| TN_NFKB | - | NFKB-activated T cells |
| TEM | 0h, 16h, 40h, 5d, LA | Effector memory T cells |
| TEM_HLApositive | 40h, 5d | HLA-positive effector memory T cells |
| TEMRA | 0h, 16h, 40h, 5d, LA | Terminally differentiated RA+ T cells |
| TCM | 0h, 16h, 40h, 5d, LA | Central memory T cells |
| nTreg | 0h, 16h, 40h | Natural regulatory T cells |
| CD4_Memory | uns_0h, stim_16h, stim_40h, stim_5d | CD4 memory T cells |
| CD4_Naive | uns_0h, stim_16h, stim_40h, stim_5d | CD4 naive T cells |
| TM | cycling_5d, ER-stress_40h | Transitional memory T cells |
| HSP | 16h | Heat shock protein stimulated |

## Output

### Directory Structure

```
output_dir/
├── smr_batch_summary.csv        # Summary of all resources
├── TN_0h/
│   └── SMR results...
├── TN_16h/
│   └── SMR results...
├── TN_40h/
│   └── SMR results...
└── ...
```

### Summary CSV Format

| resource | status | error_msg | trait | timestamp |
|----------|--------|-----------|-------|-----------|
| TN_0h | success | NA | NAFLD | 2026-04-08 |
| TEM_16h | failed | xQTL data not found | NAFLD | 2026-04-08 |

## Consolidation and Visualization

After batch analysis, consolidate results and create visualizations:

```r
# Consolidate results
consolidated <- consolidate_dynamic_smr(
    result_dirs = c("/results/TN_0h", "/results/TN_16h", "/results/TN_40h"),
    output_file = "consolidated_smr.csv"
)

# Create heatmap
plot_dynamic_smr_heatmap(
    smr_results = consolidated,
    output_file = "dynamic_smr_heatmap.png"
)
```

## Module Structure

```
batch_smr_dynamic/
├── R/
│   └── batch_smr_dynamic.R      # Core R functions
├── src/
│   ├── __init__.py              # Python module init
│   └── wrapper.py               # Python CLI/API wrapper
├── example/
│   └── config.yaml              # Example configuration
├── docs/
│   └── (documentation)
└── README.md                    # This file
```

## Key Functions

### R Functions

| Function | Description |
|----------|-------------|
| `run_smr_dynamic_batch()` | Execute batch SMR analysis |
| `generate_smr_summary()` | Create summary report |
| `parse_dynamic_resources()` | Parse xQTL resources from datasets |
| `consolidate_dynamic_smr()` | Consolidate results across timepoints |
| `plot_dynamic_smr_heatmap()` | Create heatmap visualization |

### Python Functions

| Function | Description |
|----------|-------------|
| `run_smr_dynamic_batch()` | Run batch analysis from Python |
| `get_default_dynamic_resources()` | Get all default resources |
| `parse_resources_by_celltype()` | Group resources by cell type |
| `load_config()` | Load YAML configuration |

## Development Notes

This module was developed with assistance from **WorkBuddy AI Assistant**, which helped with:

- Module architecture design and code structure
- R/Python integration patterns
- Batch processing workflows
- Result consolidation strategies
- Visualization utilities

## License

Same as OmniGWAS toolkit.

## Citation

If you use this module in your research, please cite:

1. OmniGWAS: [Your Lab/Publication]
2. SMR method: [Zhang et al., AJHG]
3. Dynamic single-cell eQTL: [Corresponding studies]
