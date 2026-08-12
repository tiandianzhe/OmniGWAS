# OmniGWAS

[![CI](https://github.com/tiandianzhe/OmniGWAS/actions/workflows/ci.yml/badge.svg)](https://github.com/tiandianzhe/OmniGWAS/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

OmniGWAS is an R and Python repository for GWAS and post-GWAS research workflows. It has two distinct layers:

1. literate analysis recipes covering basic GWAS, multi-omics, single-cell, comorbidity, and auxiliary analyses;
2. maintained auxiliary modules with locked dependencies, tests, command-line interfaces, and fixed Python-to-R drivers.

Repository version metadata is aligned to `v0.1.0`. Consult the GitHub Releases page for the publication status and downloadable artifacts associated with a version.

## Maintained and reference scope

| Component | Status in v0.1.0 | CI coverage | External requirements |
| --- | --- | --- | --- |
| `convert_supergnova` | Maintained Python package and CLI | Unit tests, wheel build, clean-install CLI fixture | None |
| `utils` | Maintained Python and R utilities | R unit tests and Python-to-R JSON integration | Locked core R packages |
| `manhattan_plot` | Maintained plotting bridge | Real Manhattan and Q-Q output smoke tests | Locked core R packages |
| `batch_gsmap` | Experimental adapter | Wrapper security tests and isolated R runner test | easyGWAS, gsMap resources, study data |
| `batch_smr_dynamic` | Experimental adapter | Wrapper security tests and isolated R runner test | easyGWAS, xQTL resources, study data |
| Five category recipe files | Reference workflows | Every fenced R example is syntax parsed | Method-specific packages, tools, datasets, and credentials |

The category files retain their historical `.R` filenames but are Markdown-formatted research recipes. They are not sourceable R modules and are not claimed to run end to end in generic CI. Each study must validate its own data provenance, assumptions, reference build, population, and external method versions.

## Repository layout

```text
analysis/
├── 01_basic_gwas/             # Basic GWAS reference recipes
├── 02_multiomics_gwas/        # eQTL, pQTL, mQTL and TWAS recipes
├── 03_singlecell_gwas/        # Single-cell and spatial recipes
├── 04_comorbidity_gwas/       # MR, colocalization and correlation recipes
└── 05_auxiliary_tools/
    ├── convert_supergnova/    # Installable Python converter
    ├── utils/                 # R utilities with Python API and CLI
    ├── manhattan_plot/        # Manhattan and Q-Q plotting bridge
    ├── batch_gsmap/           # Experimental gsMap batch adapter
    └── batch_smr_dynamic/     # Experimental SMR batch adapter
```

## Reproducible setup

Python 3.10 or later and a current R installation are required for the maintained surface. The committed `uv.lock` and `renv.lock` define the development and CI environments.

```sh
git clone https://github.com/tiandianzhe/OmniGWAS.git
cd OmniGWAS

uv sync --locked --all-groups
Rscript -e 'renv::restore(prompt = FALSE)'
```

The R lock covers the core auxiliary runtime and test dependencies. It deliberately excludes heavy study-specific tools, private resources, and the optional easyGWAS package. A lock file does not replace method-specific citation or license requirements.

## Quick validation

The SuperGNOVA converter provides the smallest public, deterministic run:

```sh
uv run --frozen supergnova2csv \
  analysis/05_auxiliary_tools/convert_supergnova/example/example_data.txt \
  --output supergnova-output.csv \
  --quiet

cmp supergnova-output.csv \
  analysis/05_auxiliary_tools/convert_supergnova/example/expected_output.csv
```

The expected output SHA-256 is `695cdafed2fe4c6b84e0ce099e865a7a519daef9d4414be32ee53543eb558242`.

## Auxiliary command-line interfaces

Run the wrapper modules from the auxiliary-tools directory so Python can resolve their source-tree packages:

```sh
cd analysis/05_auxiliary_tools

# Inspect a table through the fixed R utility driver
../../.venv/bin/python -m utils.src read --input path/to/results.tsv --sep tab

# Generate a Q-Q plot
../../.venv/bin/python -m manhattan_plot.src \
  --input manhattan_plot/example/example_data.csv \
  --output qq.png \
  --qq-only

# Inspect experimental adapter options
../../.venv/bin/python -m batch_gsmap.src --help
../../.venv/bin/python -m batch_smr_dynamic.src --help
```

Values cross the Python-to-R boundary as JSON on standard input. The maintained wrappers execute fixed R drivers and do not generate R source from command-line or YAML values.

## Maintenance checks

```sh
uv run --frozen ruff check \
  analysis/05_auxiliary_tools/*/src \
  tests/python
uv run --frozen pytest -q
Rscript scripts/ci/check_r_sources.R
Rscript scripts/ci/check_r_dependencies.R
Rscript -e 'testthat::test_dir("tests/r", reporter = "summary")'
```

CI tests Python 3.10 and 3.14, restores the locked R environment, parses the runnable R modules and every fenced recipe example, installs the converter wheel in a clean environment, and executes real Python-to-R file-output tests. Optional domain workflows are not labeled tested unless a public fixture can exercise them.

## Security and contributions

Configuration files, paths, filenames, input data, archives, environment variables, and third-party pull requests are treated as untrusted. Do not submit credentials, identifiable human data, private genomic data, or signed download URLs.

- Report vulnerabilities privately through [SECURITY.md](SECURITY.md).
- Follow the test, dependency, and contribution requirements in [CONTRIBUTING.md](CONTRIBUTING.md).
- Review optional dependency and license boundaries in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## External validation status

As of 2026-08-12, no independently verifiable third-party run has been documented. Stars, forks, a maintainer-run test, a DOI, and a GitHub Release are not presented as external use. A non-maintainer can run the deterministic fixture and submit evidence using [the external validation protocol](docs/EXTERNAL_VALIDATION.md).

## Citation and license

Citation metadata is provided in [CITATION.cff](CITATION.cff). Cite both OmniGWAS and every upstream scientific method, dataset, and package used in an analysis.

Original OmniGWAS repository code is available under the [MIT License](LICENSE). Optional external components retain their own licenses and are not bundled by that license.

Maintainer: [Dianzhe Tian](https://github.com/tiandianzhe), Peking Union Medical College Hospital.
