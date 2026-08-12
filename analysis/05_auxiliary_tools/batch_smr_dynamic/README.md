# batch_smr_dynamic

Version 0.1.0, Experimental

`batch_smr_dynamic` is an experimental Python and R adapter for applying an easyGWAS SMR workflow across named dynamic immune-cell xQTL resources. It records per-resource execution outcomes and provides utilities for summary, consolidation, and heatmap generation.

## Support boundary

The adapter calls `easyGWAS::batch_xqtl_smr`. easyGWAS is optional, is not bundled with OmniGWAS, and is intentionally excluded from the core `renv.lock`. OmniGWAS does not currently document a publicly accessible authoritative easyGWAS distribution. Use only a compatible version obtained from a source you are authorized to access, then verify its source, version, license, and integrity. xQTL resources and study GWAS data are not bundled.

CI covers the JSON Python-to-R boundary and the R batch logic with a mock runner. CI does not claim end-to-end validation against research datasets, remote xQTL resources, or an installed easyGWAS workflow.

## Reproducible setup

Run the locked core setup from the repository root:

```sh
uv sync --locked --all-groups
Rscript -e 'renv::restore(prompt=FALSE)'
```

This restores the tested wrapper and core R environment. It does not install the optional easyGWAS dependency.

## Command line

Run the wrapper from `analysis/05_auxiliary_tools`:

```sh
cd analysis/05_auxiliary_tools

../../.venv/bin/python -m batch_smr_dynamic.src \
  --resources TN_0h TN_16h TEM_0h \
  --out-filename path/to/gwas.rds \
  --outcome-name ExampleTrait \
  --output path/to/results
```

Resources can also come from `--resources-file`, `--default-resources`, or a YAML configuration:

```sh
../../.venv/bin/python -m batch_smr_dynamic.src \
  --config batch_smr_dynamic/example/config.yaml
```

A configuration mapping uses these primary keys:

```yaml
xqtl_resources:
  - TN_0h
  - TN_16h
out_filename: path/to/gwas.rds
outcome_name: ExampleTrait
xqtl_type: sc_eqtl
save_base_path: path/to/results
pval: 5.0e-8
diff_freq_prop: 0.9
diff_freq: 0.2
ancestry: EUR
quick_smr: true
smr_HEIDI_p: 0.05
stop_on_error: false
```

## Python API

```python
from batch_smr_dynamic.src.wrapper import (
    get_default_dynamic_resources,
    run_smr_dynamic_batch,
)

resources = get_default_dynamic_resources()
result = run_smr_dynamic_batch(
    xqtl_resources=resources,
    out_filename="path/to/gwas.rds",
    outcome_name="ExampleTrait",
    save_base_path="path/to/results",
)
```

## R API

```r
source("batch_smr_dynamic/R/batch_smr_dynamic.R")

result <- run_smr_dynamic_batch(
  xqtl_resources = c("TN_0h", "TN_16h"),
  out_filename = "path/to/gwas.rds",
  outcome_name = "ExampleTrait",
  save_base_path = "path/to/results"
)
```

The R function accepts an optional `runner` function for isolated testing. When `runner=NULL`, it resolves `easyGWAS::batch_xqtl_smr`.

## Outputs and post-processing

A wrapper run writes `smr_batch_summary.csv`, `smr_batch_results.json`, and one directory per attempted xQTL resource. The CLI returns a nonzero status if any resource fails or if the result contract is incomplete. The R module also exposes `consolidate_dynamic_smr()` and `plot_dynamic_smr_heatmap()` for local result processing. Output status and plots do not establish causal validity.

## Security boundary

The Python wrapper sends structured JSON to a fixed R driver over standard input. It does not interpolate command-line or YAML values into R source and does not create executable temporary scripts. Paths, configuration, third-party packages, and data resources should still be treated as untrusted input.

## License

The adapter code is part of OmniGWAS and uses the repository MIT license. easyGWAS, SMR methods, xQTL resources, and study datasets retain their own licenses and citation requirements.
