# batch_gsmap

> Batch gsMap spatial transcriptomics GWAS colocalization analysis module for OmniGWAS toolkit.

**Powered by WorkBuddy AI Assistant**

## Overview

This module provides tools for running [gsMap](https://github.com/gaozhangyang/gsMap) spatial transcriptomics GWAS colocalization analysis across multiple samples in batch mode. It supports parallel processing, error handling, and comprehensive result logging.

## Features

- Batch processing of multiple spatial transcriptomics samples
- Parallel execution with configurable process limits
- Comprehensive error handling and logging
- Configurable via YAML files
- Export results to CSV and JSON formats
- Integration with Python CLI and R API

## Installation

### Python Dependencies

```bash
pip install pyyaml
```

### R Dependencies

```r
# Install required R packages
install.packages("yaml")
install.packages("jsonlite")

# Install gsMap package (follow gsMap documentation)
# devtools::install_github("gaozhangyang/gsMap")
```

## Quick Start

### Python CLI

```bash
# Method 1: Specify samples directly
python -m batch_gsmap.src \
    --samples E9.5_E1S1 E10.5_E1S1 E11.5_E1S1 \
    --sumstats GWAS.sumstats.gz \
    --trait NAFLD \
    --h5ad-dir /data/ST/ \
    --output /results/NAFLD/

# Method 2: Auto-detect samples from h5ad directory
python -m batch_gsmap.src \
    --samples-dir /data/ST/ \
    --sumstats GWAS.sumstats.gz \
    --trait NAFLD \
    --h5ad-dir /data/ST/ \
    --output /results/NAFLD/

# Method 3: Use configuration file
python -m batch_gsmap.src --config config.yaml
```

### Python API

```python
from batch_gsmap.src import wrapper

# Run batch analysis
result = wrapper.run_batch_gsmap(
    sample_names=["E9.5_E1S1", "E10.5_E1S1", "E11.5_E1S1"],
    sumstats_file="GWAS.sumstats.gz",
    trait_name="NAFLD",
    h5ad_dir="/data/ST/",
    save_base_path="/results/NAFLD/",
    max_processes=10
)

print(f"Success: {len(result['success_list'])}")
print(f"Failed: {len(result['failed_list'])}")
```

### R API

```r
source("batch_gsmap/R/batch_gsmap.R")

# Define sample names
sample_names <- c(
  "E9.5_E1S1", "E9.5_E2S1", "E9.5_E2S2",
  "E10.5_E1S1", "E10.5_E1S2",
  "E11.5_E1S1", "E11.5_E1S2"
)

# Run batch analysis
result <- run_gsmap_batch(
  sample_names = sample_names,
  sumstats_file = "GWAS.sumstats.gz",
  trait_name = "NAFLD",
  h5ad_dir = "/data/ST/",
  annotation = "annotation",
  data_layer = "count",
  max_processes = 10,
  save_base_path = "/results/NAFLD/"
)

# Access results
print(result$success)
print(result$failed)
```

## Configuration

### YAML Configuration File

Create a `config.yaml` file:

```yaml
sumstats_file: "path/to/summary_statistics.gz"
trait_name: "YourTrait"
samples:
  - "Sample1"
  - "Sample2"
  - "Sample3"
h5ad_dir: "path/to/h5ad/files/"
annotation: "annotation"
data_layer: "count"
max_processes: 10
save_base_path: "path/to/output/"
```

## Output

### Directory Structure

```
output_dir/
├── batch_summary.csv          # Summary of all samples
├── batch_results.json         # Detailed results in JSON format
├── Sample1/
│   └── gsMap output files...
├── Sample2/
│   └── gsMap output files...
└── Sample3/
    └── gsMap output files...
```

### Summary CSV Format

| sample | status | error_msg | trait | timestamp |
|--------|--------|-----------|-------|-----------|
| E9.5_E1S1 | success | NA | NAFLD | 2026-04-08 |
| E9.5_E2S1 | failed | h5ad not found | NAFLD | 2026-04-08 |

## Module Structure

```
batch_gsmap/
├── R/
│   └── batch_gsmap.R         # Core R functions
├── src/
│   ├── __init__.py           # Python module init
│   └── wrapper.py            # Python CLI/API wrapper
├── example/
│   └── config.yaml           # Example configuration
├── docs/
│   └── (documentation)
└── README.md                 # This file
```

## Key Functions

### R Functions

| Function | Description |
|----------|-------------|
| `run_gsmap_batch()` | Execute batch gsMap analysis |
| `generate_batch_summary()` | Create summary report |
| `parse_sample_names()` | Extract sample names from h5ad directory |
| `load_batch_config()` | Load YAML configuration |
| `export_batch_results()` | Export results to CSV/JSON |

### Python Functions

| Function | Description |
|----------|-------------|
| `run_batch_gsmap()` | Run batch analysis from Python |
| `parse_sample_names_from_dir()` | Auto-detect samples from directory |
| `load_config()` | Load YAML configuration |
| `main()` | CLI entry point |

## Development Notes

This module was developed with assistance from **WorkBuddy AI Assistant**, which helped with:

- Module architecture design and code structure
- R/Python integration patterns
- Error handling and logging strategies
- CLI argument parsing
- Batch processing workflows

## License

Same as OmniGWAS toolkit.

## Citation

If you use this module in your research, please cite:

1. gsMap: [Zhang et al., Nature Genetics](https://www.nature.com)
2. OmniGWAS: [Your Lab/Publication]
