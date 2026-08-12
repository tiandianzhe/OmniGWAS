# Third-Party Notices

OmniGWAS includes original repository code offered under the [MIT License](LICENSE). Some workflows call external software that has its own authors, licenses, installation process, and citation requirements. The OmniGWAS license does not grant rights to those external components.

## easyGWAS

| Field | Notice |
| --- | --- |
| Project | easyGWAS |
| Public source | No publicly accessible authoritative distribution is documented by OmniGWAS as of 2026-08-12 |
| Role | Optional external runtime dependency for selected GWAS and post-GWAS workflows |
| License | Not asserted here because public upstream license metadata is unavailable |
| Bundled in this repository | No |

OmniGWAS does not vendor or redistribute the easyGWAS package. The experimental adapters require a compatible installation supplied from a source the user is authorized to access. Users must verify that source, version, license, integrity, and citation terms before use. Do not install a similarly named package from an unverified repository or registry.

Calls, adapters, examples, and workflow descriptions in OmniGWAS do not mean that easyGWAS algorithms were created or independently implemented by OmniGWAS. Functions provided by easyGWAS remain the work of its upstream authors and should be attributed accordingly.

## gsMap

| Field | Notice |
| --- | --- |
| Project | gsMap |
| Upstream source | <https://github.com/JianYang-Lab/gsMap> |
| Role | External spatial-transcriptomics method and resources referenced by the experimental batch adapter |
| License | MIT, as declared by the public upstream repository on 2026-08-12 |
| Bundled in this repository | No |

OmniGWAS does not vendor gsMap or its reference resources. Review the upstream release, license, documentation, resource provenance, and citation instructions before use.

## Other dependencies

R packages, Python packages, command-line tools, reference datasets, and web resources used by individual workflows remain subject to their respective licenses and terms. Lock files record selected dependency versions for reproducibility but do not replace upstream notices or licenses. Contributors should document the source and license of each newly introduced dependency or bundled asset.
