# manhattan_plot

Version 0.1.0

`manhattan_plot` provides maintained R functions and a Python wrapper for Manhattan and Q-Q plot generation from GWAS summary statistics.

## Input contract

The input must be a CSV or delimited text file with these columns:

| Column | Requirement |
| --- | --- |
| `SNP` | Required variant identifier |
| `CHR` | Required numeric chromosome |
| `BP` | Required base-pair position |
| `P` | Required P value |

`CHR` and `BP` must be positive whole numbers. `P` and any supplied `FDR` values must be finite and lie in `[0, 1]`; Q-Q plots require `P` in `(0, 1]`. Invalid rows fail explicitly instead of being silently dropped. An `FDR` column is optional. When no FDR column is supplied, the Manhattan function computes Benjamini-Hochberg adjusted values from `P`. The default `threshold_type=fdr` uses those adjusted values. Use `threshold_type=pvalue` to threshold directly on `P`.

## Reproducible setup

Run the locked project setup from the repository root:

```sh
uv sync --locked --all-groups
Rscript -e 'renv::restore(prompt=FALSE)'
```

The R lock contains the maintained plotting dependencies, including `jsonlite`, `data.table`, `dplyr`, `ggplot2`, `ggrepel`, and `scales`.

## Command line

Run the wrapper from `analysis/05_auxiliary_tools`:

```sh
cd analysis/05_auxiliary_tools

# Manhattan plot using BH-adjusted FDR
../../.venv/bin/python -m manhattan_plot.src \
  --input manhattan_plot/example/example_data.csv \
  --output manhattan.png \
  --threshold 0.05

# Manhattan plot using the raw P-value threshold
../../.venv/bin/python -m manhattan_plot.src \
  --input manhattan_plot/example/example_data.csv \
  --output manhattan-pvalue.png \
  --threshold-type pvalue \
  --threshold 5e-8

# Q-Q plot
../../.venv/bin/python -m manhattan_plot.src \
  --input manhattan_plot/example/example_data.csv \
  --output qq.png \
  --qq-only
```

Use `--fdr-col FDR` when the input already contains adjusted values. Other options include `--label-snps`, `--title`, `--width`, `--height`, `--dpi`, and `--sig-color`.

## Python API

```python
from manhattan_plot.src.wrapper import create_manhattan, create_qq

create_manhattan(
    input_file="gwas.csv",
    output="manhattan.png",
    threshold=0.05,
    threshold_type="fdr",
)

create_qq(
    input_file="gwas.csv",
    output="qq.png",
)
```

## R API

From `analysis/05_auxiliary_tools`:

```r
source("manhattan_plot/R/manhattan_plot.R")

data <- read.csv("manhattan_plot/example/example_data.csv")
create_manhattan_plot(data, output = "manhattan.png")
create_qq_plot(data, output = "qq.png")
```

## Validation and security boundary

Cross-language integration tests run the Python wrapper through the fixed R driver and verify that real, nonempty Manhattan and Q-Q PNG files are produced. Caller values are encoded as JSON on standard input. The wrapper does not generate executable R source or predictable temporary R scripts.

The smoke tests validate the maintained plotting path on the public example. They do not establish the suitability of a plot or statistical threshold for a particular study.

## License

This module is part of OmniGWAS and uses the repository MIT license.
