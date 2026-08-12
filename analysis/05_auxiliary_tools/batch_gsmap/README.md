# batch_gsmap

Version 0.1.0, Experimental

`batch_gsmap` is an experimental Python and R adapter for running an easyGWAS gsMap workflow over multiple spatial-transcriptomics samples. It validates local paths, records per-sample outcomes, and writes batch summaries.

## Support boundary

The adapter calls `easyGWAS::run_gsmap_quick_mode`. easyGWAS is optional, is not bundled with OmniGWAS, and is intentionally excluded from the core `renv.lock`. OmniGWAS does not currently document a publicly accessible authoritative easyGWAS distribution. Use only a compatible version obtained from a source you are authorized to access, then verify its source, version, license, and integrity. The required gsMap resources, reference data, and study data are also not bundled.

CI covers the JSON Python-to-R boundary and the R batch logic with a mock runner. CI does not claim end-to-end validation against research datasets, external gsMap resources, or an installed easyGWAS workflow.

## Reproducible setup

Run the locked core setup from the repository root:

```sh
uv sync --locked --all-groups
Rscript -e 'renv::restore(prompt=FALSE)'
```

This restores the tested wrapper environment. It does not install the optional easyGWAS dependency.

## Command line

Run the wrapper from `analysis/05_auxiliary_tools`:

```sh
cd analysis/05_auxiliary_tools

../../.venv/bin/python -m batch_gsmap.src \
  --samples Sample1 Sample2 \
  --sumstats path/to/gwas.sumstats.gz \
  --trait ExampleTrait \
  --h5ad-dir path/to/h5ad \
  --output path/to/results \
  --max-processes 4
```

Each sample is resolved as `<h5ad-dir>/<sample>.MOSTA.h5ad`. Samples can also come from `--samples-file`, `--samples-dir`, or a YAML configuration:

```sh
../../.venv/bin/python -m batch_gsmap.src \
  --config batch_gsmap/example/config.yaml
```

A configuration mapping uses these primary keys:

```yaml
samples:
  - Sample1
  - Sample2
sumstats_file: path/to/gwas.sumstats.gz
trait_name: ExampleTrait
h5ad_dir: path/to/h5ad
annotation: annotation
data_layer: count
max_processes: 4
save_base_path: path/to/results
stop_on_error: false
```

## Python API

```python
from batch_gsmap.src.wrapper import run_batch_gsmap

result = run_batch_gsmap(
    sample_names=["Sample1", "Sample2"],
    sumstats_file="path/to/gwas.sumstats.gz",
    trait_name="ExampleTrait",
    h5ad_dir="path/to/h5ad",
    save_base_path="path/to/results",
    max_processes=4,
)
```

## R API

```r
source("batch_gsmap/R/batch_gsmap.R")

result <- run_gsmap_batch(
  sample_names = c("Sample1", "Sample2"),
  sumstats_file = "path/to/gwas.sumstats.gz",
  trait_name = "ExampleTrait",
  h5ad_dir = "path/to/h5ad",
  save_base_path = "path/to/results"
)
```

The R function accepts an optional `runner` function for isolated testing. When `runner=NULL`, it resolves `easyGWAS::run_gsmap_quick_mode`.

## Outputs

A run writes `batch_summary.csv`, `batch_results.json`, and one output directory for each sample whose input file was found and whose runner was attempted. The summary also records samples rejected before runner execution. These records describe execution status, not scientific validity. The CLI returns a nonzero status if any sample fails or if the result contract is incomplete.

## Security boundary

The Python wrapper sends structured JSON to a fixed R driver over standard input. It does not interpolate command-line or YAML values into R source and does not create executable temporary scripts. Paths and third-party datasets should still be treated as untrusted input.

## License

The adapter code is part of OmniGWAS and uses the repository MIT license. easyGWAS, gsMap, datasets, and reference resources retain their own licenses and citation requirements.
