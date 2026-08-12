# Changelog

All notable changes to OmniGWAS will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases use [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0]

This version establishes the first maintained, version-aligned project baseline.

### Added

- Cross-language CI checks for maintained Python packages, runnable R sources, and Python-to-R integration paths.
- Locked Python and R development environments for reproducible maintenance and CI.
- Security reporting, contribution, third-party attribution, citation, release, and independent-validation documentation.
- Regression coverage for quoted, Unicode, and shell-metacharacter input values crossing the Python-to-R boundary.

### Changed

- Python wrappers pass structured JSON data to fixed R driver scripts instead of generating executable R source from command-line or configuration values.
- Maintained R modules require declared dependencies instead of installing packages during analysis execution.
- Auxiliary Python package metadata and command-line entry points are aligned with the `0.1.0` version.

### Security

- Removed predictable executable temporary R scripts from maintained wrapper paths.
- Reduced command-injection exposure at the Python-to-R boundary by separating untrusted values from executable code.
- Pinned GitHub Actions by commit and added checks intended to detect reintroduction of runtime installers or generated executable source.

### Scope

- The versioned, CI-tested surface focuses on maintained auxiliary modules.
- Broader GWAS files remain reference workflows that require domain-specific tools, datasets, and independent scientific validation.
- easyGWAS remains an optional external dependency and is not bundled with OmniGWAS.
