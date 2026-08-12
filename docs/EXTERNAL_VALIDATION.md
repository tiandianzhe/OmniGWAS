# External Validation

## Current status

As of 2026-08-12, the maintainers have not documented an independently verifiable third-party run of OmniGWAS. This repository therefore makes no claim of external adoption or downstream use. The process below is intended to collect future evidence, not to manufacture a signal for an application or release.

## What qualifies

A verified external-use record must:

1. be submitted publicly by the GitHub account of a person who is not the repository owner or a core maintainer;
2. identify the exact OmniGWAS release tag or full commit SHA used;
3. use a public dataset or a documented synthetic fixture that another person can access or regenerate;
4. state the operating system, Python and R versions, dependency state, and exact commands;
5. report the observed result and any deviations from the documentation;
6. provide checkable evidence, such as a redacted log, output checksum, small output artifact, or public downstream repository or CI run.

A successful report can be recorded as a verified external-use signal after a maintainer checks its independence and evidence. Partial or failed runs are valuable for maintenance, but they are not presented as successful external use.

## What does not qualify

The following are not independently verifiable usage signals by themselves:

- stars, watchers, forks, clones, page views, or repository traffic;
- a test run performed by the owner, a core maintainer, an AI agent, or maintenance automation;
- a report written or posted by a maintainer on behalf of another person;
- a private message, unauditable screenshot, or statement without a tested revision and reproduction details;
- an issue generated solely to satisfy an application requirement;
- a run using undisclosed private data that cannot be safely reproduced.

These restrictions prevent circular evidence and protect research participants. Maintainers must not solicit a predetermined positive result or alter a contributor's report.

## How to submit a report

1. Check out a published tag or record the full commit SHA.
2. Run one documented module with public or synthetic data.
3. Retain a redacted command log and a small, non-sensitive output or checksum.
4. Open an [External validation report](https://github.com/tiandianzhe/OmniGWAS/issues/new?template=external-validation.yml) from your own GitHub account.
5. Answer follow-up questions publicly when doing so does not expose sensitive information.

Do not upload credentials, signed URLs, private paths, identifiable genomic data, or clinical records. If reproduction requires private data, create a synthetic fixture that exercises the same input schema.

## Minimal independent run for v0.1.0

The converter fixture is the preferred first validation because it requires no private data or optional R package. After checking out the published `v0.1.0` tag, run:

```sh
uv sync --locked --all-groups
uv run --frozen supergnova2csv \
  analysis/05_auxiliary_tools/convert_supergnova/example/example_data.txt \
  --output external-validation.csv \
  --quiet
```

The expected output has four lines, including the header, and must match the tracked fixture:

```sh
cmp external-validation.csv \
  analysis/05_auxiliary_tools/convert_supergnova/example/expected_output.csv
sha256sum external-validation.csv
```

Expected SHA-256:

```text
695cdafed2fe4c6b84e0ce099e865a7a519daef9d4414be32ee53543eb558242
```

On macOS, use `shasum -a 256 external-validation.csv` when `sha256sum` is unavailable. The tester should record the full tag commit, `uv --version`, `python --version`, the exact command, the checksum, and any deviations. A mismatched result should be reported as observed rather than altered to fit the expected value.

## Verification procedure

The maintainer will confirm that the reporter is not a core maintainer, that the referenced revision exists, and that the evidence is internally consistent. When practical, the maintainer will repeat the commands using the named public or synthetic input. Any maintainer reproduction will be linked as corroboration, not treated as the independent signal itself.

Verified reports will be listed below with a direct public link. The original issue remains the evidence source, including corrections or failures discovered later.

## Verified reports

No verified external validation reports have been recorded.
