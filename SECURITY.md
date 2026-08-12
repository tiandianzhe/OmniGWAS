# Security Policy

## Supported versions

Security reports are accepted for the default branch and any published `0.1.x` GitHub release.

| Version | Supported |
| --- | --- |
| Default branch | Yes |
| Published 0.1.x | Yes |
| Source before 0.1.0 | No |

## Reporting a vulnerability

Report suspected vulnerabilities privately to **tiandianzhe@outlook.com** with the subject `OmniGWAS security report`. Please include:

- the affected version, commit, module, and operating system;
- the security property that fails and the realistic impact;
- minimal reproduction steps using synthetic or public data;
- any relevant logs, with credentials and personal data removed;
- whether the report may be shared with an affected upstream maintainer.

Do not open a public issue, discussion, or pull request for an uncoordinated vulnerability disclosure. Do not publish a proof of concept before remediation is available. Never send API keys, access tokens, private keys, credentials, identifiable genomic data, or other sensitive research data. If a secret may have been exposed, revoke it before reporting and send only a redacted description.

The maintainer aims to acknowledge a report within 7 calendar days, provide an initial assessment within 14 calendar days, and provide an update at least every 30 calendar days until the report is resolved or closed. These are response targets, not a guarantee of a particular fix date.

## System and scope

OmniGWAS is a local R and Python research toolkit. Its command-line wrappers accept paths, configuration values, and analysis parameters, invoke fixed R entry points or external scientific tools, read local data, and write analysis outputs. Some workflows may use network resources or optional third-party packages when a researcher explicitly configures them. OmniGWAS does not provide a hosted service, account system, or authorization layer.

Security review should cover maintained source code, command-line interfaces, Python-to-R boundaries, repository automation, dependency metadata, and release artifacts. Relevant assets include local files, research datasets, environment variables, credentials used by external tools, and the integrity of computed outputs.

## Threat model and security invariants

Configuration files, command-line values, input files, filenames, archives, and third-party contributions must be treated as untrusted. The following properties must hold:

- User-controlled values must be transferred as data, not interpolated into generated R, Python, shell, or workflow source.
- External commands must use explicit argument vectors and fixed entry points. Shell interpretation must not be enabled for untrusted values.
- Temporary files must be created safely and must not become executable source controlled through a predictable path.
- File writes and deletions must be limited to paths requested by the user, with symlink and overwrite behavior considered.
- Network access must be documented, attributable to an explicit operation, and limited to the intended endpoint and data.
- Logs, exceptions, examples, tests, and CI output must not expose credentials or sensitive genomic data.
- Dependencies and CI actions must be reviewable and pinned or locked where the ecosystem supports it.

## Reportable findings

Examples of reportable issues include:

- R, Python, or shell command injection through configuration, paths, data, or environment values;
- arbitrary file overwrite, deletion, traversal, or unsafe symlink handling;
- unintended network requests, credential forwarding, or data exfiltration;
- unsafe parsing or deserialization of attacker-controlled content;
- exposure of credentials or sensitive data in source, logs, fixtures, or release artifacts;
- dependency, build, CI, or release-chain compromise that can affect users;
- a vulnerable integration pattern that makes an optional third-party component exploitable through OmniGWAS.

Severity is assessed from demonstrated reachability, required user interaction, data sensitivity, execution context, and impact on confidentiality, integrity, or availability.

## Upstream and non-security issues

Issues confined to an optional dependency, including easyGWAS, should normally be reported to that dependency's maintainer. Please also notify OmniGWAS privately when its integration increases reachability or impact. Scientific-method disagreements, result interpretation, and performance problems without a security impact belong in the public issue tracker.

## Coordinated disclosure

After a fix is available, the reporter and maintainer may agree on a public advisory. Public credit is optional. Remediation notes should explain affected versions and defensive changes without exposing secrets, private data, or unnecessary exploit detail.
