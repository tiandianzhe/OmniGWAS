# Contributing to OmniGWAS

OmniGWAS welcomes focused fixes, tests, documentation, and reproducible workflow improvements. Contributions should preserve scientific traceability and the security of local data and execution.

## Before opening a pull request

1. Search existing issues and pull requests for related work.
2. For a behavior change, open an issue that describes the use case and affected module.
3. Use synthetic or public data in reproductions. Do not submit identifiable genomic, clinical, institutional, or credential-bearing data.
4. Keep the change scoped. Separate unrelated refactoring from a bug fix or new feature.

Bug reports should identify the commit or version, operating system, Python and R versions, exact command, minimal input schema, expected result, and observed result. Redact local usernames, absolute private paths, tokens, and sensitive data.

## Development and tests

Use the repository lock files so local results match CI. From the repository root, the maintained checks are:

```sh
uv sync --locked --all-groups
uv run --frozen ruff check .
uv run --frozen pytest
Rscript scripts/ci/check_r_sources.R
Rscript scripts/ci/check_r_dependencies.R
Rscript -e 'testthat::test_dir("tests/r", reporter = "summary")'
```

Run only reviewed commands and use synthetic fixtures. A pull request should add or update tests for changed behavior. Cross-language changes must test both the Python caller and the fixed R entry point, including spaces, quotes, Unicode, and shell metacharacters in values. Domain workflows that require private datasets or optional tools should provide a small public or synthetic validation path.

## Dependency changes

Explain why a new dependency is necessary, its license, source, and runtime exposure. Update the appropriate lock file in the same pull request. Do not add runtime package installation, unpinned CI actions, remote script execution, or an undeclared network download. Optional tools must remain explicit and documented.

## Security requirements for contributed code

Treat issue text, pull request content, configuration, paths, input files, archives, environment values, and generated content as untrusted.

- Pass data through structured formats and fixed entry points. Do not build executable R, Python, shell, SQL, or workflow source from user values.
- Invoke subprocesses with argument arrays and without shell interpretation.
- Validate file type, path, overwrite behavior, resource limits, and archive members before processing.
- Use secure temporary-file APIs. Do not execute a predictable temporary file.
- Make network access explicit, document the destination, use timeouts, and avoid forwarding credentials.
- Never commit secrets, real patient data, private datasets, access URLs, or copied proprietary code.
- Preserve upstream attribution and license notices. Do not describe an upstream algorithm as an OmniGWAS implementation.

Security-sensitive reports must follow [SECURITY.md](SECURITY.md), not the public issue tracker.

## Pull request content

A pull request should state what changed, why it is needed, how it was tested, any dependency or network impact, and any user-visible compatibility change. CI must pass before merge. Maintainers may request a smaller reproduction or additional tests before reviewing scientific behavior.

## Independent validation

Non-maintainers who run OmniGWAS on public or synthetic data can submit an [external validation report](docs/EXTERNAL_VALIDATION.md). A maintainer-run test, automated report, star, fork, or private assertion is not independent validation.

By contributing, you agree that your contribution is provided under the repository's MIT license and that you have the right to submit it.
