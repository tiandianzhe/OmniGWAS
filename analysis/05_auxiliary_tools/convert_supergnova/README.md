# convert_supergnova

Version 0.1.0

`convert_supergnova` converts whitespace-delimited SuperGNOVA result rows to a deterministic CSV representation. It is a maintained Python package in OmniGWAS.

## Data contract

Each input row must contain exactly these 10 fields:

| Position | CSV column |
| --- | --- |
| 1 | `chr` |
| 2 | `start` |
| 3 | `end` |
| 4 | `rho` |
| 5 | `corr` |
| 6 | `h2_1` |
| 7 | `h2_2` |
| 8 | `var` |
| 9 | `p` |
| 10 | `m` |

The converter writes this fixed header and preserves the 10 field values as text. Rows with any other field count are skipped and reported without echoing source contents. Fields that could become active formulas when a CSV is opened in spreadsheet software are also rejected, while ordinary signed numeric values remain valid. The converter does not infer or validate scientific units.

## Reproducible setup

Run the locked project setup from the repository root:

```sh
uv sync --locked --all-groups
Rscript -e 'renv::restore(prompt=FALSE)'
```

The converter itself is Python-only. Restoring the R lock also prepares the complete maintained OmniGWAS test environment.

## Command line

Run source-tree module commands from `analysis/05_auxiliary_tools`:

```sh
cd analysis/05_auxiliary_tools

../../.venv/bin/python -m convert_supergnova.src \
  convert_supergnova/example/example_data.txt \
  --output converted.csv \
  --quiet
```

Batch conversion processes `*.txt` files:

```sh
../../.venv/bin/python -m convert_supergnova.src \
  --batch path/to/input_dir \
  --out path/to/output_dir
```

## Python API

```python
from convert_supergnova import SuperGNOVAConverter, convert_supergnova_to_csv

stats = convert_supergnova_to_csv(
    "results.txt",
    "results.csv",
    skip_warnings=True,
)

converter = SuperGNOVAConverter("results.txt", "results.csv")
stats = converter.convert(skip_warnings=True)
```

The returned mapping reports `total_lines`, `converted_lines`, `skipped_lines`, `input_path`, and `output_path`.

## Public deterministic fixture

The tracked input and expected output provide a public validation path:

```sh
cd analysis/05_auxiliary_tools

../../.venv/bin/python -m convert_supergnova.src \
  convert_supergnova/example/example_data.txt \
  --output external-validation.csv \
  --quiet

cmp external-validation.csv convert_supergnova/example/expected_output.csv
shasum -a 256 external-validation.csv
```

Expected SHA-256:

```text
695cdafed2fe4c6b84e0ce099e865a7a519daef9d4414be32ee53543eb558242
```

The fixture comparison is covered by the package tests. It verifies deterministic file conversion, not the scientific validity of upstream SuperGNOVA estimates.

## License

This module is part of OmniGWAS and uses the repository MIT license. SuperGNOVA remains an independent upstream project with its own license and citation requirements.
