"""Python API and CLI for dynamic single-cell SMR batch analysis.

Caller-controlled values are serialized as JSON and sent to a fixed R driver
over standard input. No generated R source or predictable temporary script is
created.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

MODULE_DIR = Path(__file__).resolve().parent.parent
R_DRIVER = MODULE_DIR / "R" / "cli_driver.R"
VERSION = "0.1.0"


def run_smr_dynamic_batch(
    xqtl_resources: List[str],
    out_filename: str,
    outcome_name: str,
    xqtl_type: str = "sc_eqtl",
    save_base_path: str = ".",
    pval: float = 5e-8,
    diff_freq_prop: float = 0.9,
    diff_freq: float = 0.2,
    ancestry: str = "EUR",
    quick_smr: bool = True,
    smr_HEIDI_p: float = 0.05,
    plot_col: str = "#B4D151",
    plot_highlight_col: str = "#8680C0",
    verbose: bool = True,
    stop_on_error: bool = False,
    *,
    r_executable: str = "Rscript",
    timeout: Optional[int] = 86400,
) -> Dict[str, Any]:
    """Run SMR analysis for one or more xQTL resources."""
    if not xqtl_resources:
        raise ValueError("xqtl_resources must contain at least one resource")
    if not all(isinstance(item, str) and item.strip() for item in xqtl_resources):
        raise ValueError("Every xQTL resource must be a non-empty string")
    _validate_path_components(xqtl_resources, "xqtl_resources")
    if not Path(out_filename).is_file():
        raise FileNotFoundError(f"GWAS file not found: {out_filename}")
    if not 0 < pval <= 1:
        raise ValueError("pval must be in the interval (0, 1]")
    if not 0 <= diff_freq_prop <= 1 or not 0 <= diff_freq <= 1:
        raise ValueError("Frequency thresholds must be in the interval [0, 1]")
    if not 0 <= smr_HEIDI_p <= 1:
        raise ValueError("smr_HEIDI_p must be in the interval [0, 1]")
    if not R_DRIVER.is_file():
        raise FileNotFoundError(f"R driver not found: {R_DRIVER}")

    output_dir = Path(save_base_path)
    output_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "xqtl_resources": xqtl_resources,
        "out_filename": str(out_filename),
        "outcome_name": outcome_name,
        "xqtl_type": xqtl_type,
        "save_base_path": str(output_dir),
        "pval": pval,
        "diff_freq_prop": diff_freq_prop,
        "diff_freq": diff_freq,
        "ancestry": ancestry,
        "quick_smr": quick_smr,
        "smr_HEIDI_p": smr_HEIDI_p,
        "plot_col": plot_col,
        "plot_highlight_col": plot_highlight_col,
        "verbose": verbose,
        "stop_on_error": stop_on_error,
    }

    try:
        result = subprocess.run(
            [r_executable, str(R_DRIVER)],
            input=json.dumps(payload, ensure_ascii=False),
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(f"{r_executable} was not found") from exc
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"R batch SMR driver timed out after {timeout} seconds") from exc

    if result.returncode != 0:
        raise RuntimeError(
            "R batch SMR driver failed with code "
            f"{result.returncode}: {result.stderr.strip()}"
        )
    if verbose and result.stdout:
        print(result.stdout, end="")

    result_file = output_dir / "smr_batch_results.json"
    if result_file.is_file():
        with result_file.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    return {
        "status": "completed",
        "n_resources": len(xqtl_resources),
        "output_dir": str(output_dir),
    }


def get_default_dynamic_resources() -> List[str]:
    """Return the documented dynamic immune xQTL resources."""
    return [
        "CD4_Memory_stim_16h", "CD4_Memory_stim_40h", "CD4_Memory_stim_5d",
        "CD4_Memory_uns_0h", "CD4_Naive_uns_0h", "CD4_Naive_stim_16h",
        "CD4_Naive_stim_40h", "CD4_Naive_stim_5d", "HSP_16h",
        "nTreg_0h", "nTreg_16h", "nTreg_40h", "T_ER-stress_5d",
        "TCM_0h", "TCM_16h", "TCM_40h", "TCM_5d", "TCM_LA",
        "TEM_0h", "TEM_16h", "TEM_40h", "TEM_5d",
        "TEM_HLApositive_40h", "TEM_HLApositive_5d", "TEM_LA",
        "TEMRA_0h", "TEMRA_16h", "TEMRA_40h", "TEMRA_5d", "TEMRA_LA",
        "TM_cycling_5d", "TM_ER-stress_40h", "TN2_40h",
        "TN_0h", "TN_16h", "TN_40h", "TN_5d",
        "TN_cycling_40h", "TN_cycling_5d", "TN_HSP_5d",
        "TN_IFN_16h", "TN_IFN_40h", "TN_IFN_5d", "TN_IFN_LA",
        "TN_LA", "TN_NFKB",
    ]


def parse_resources_by_celltype(resources: List[str]) -> Dict[str, List[str]]:
    """Group resource names by their final underscore-delimited suffix."""
    grouped: Dict[str, List[str]] = {}
    for resource in resources:
        parts = resource.rsplit("_", 1)
        cell_type, timepoint = parts if len(parts) == 2 else (resource, "NA")
        grouped.setdefault(cell_type, []).append(timepoint)
    return grouped


def load_config(config_file: str) -> Dict[str, Any]:
    """Load a YAML mapping without constructing arbitrary Python objects."""
    import yaml

    with Path(config_file).open("r", encoding="utf-8") as handle:
        config = yaml.safe_load(handle)
    if not isinstance(config, dict):
        raise ValueError("Configuration must contain a YAML mapping")
    return config


def _required(config: Dict[str, Any], name: str) -> Any:
    value = config.get(name)
    if value is None or value == "":
        raise ValueError(f"Missing required configuration value: {name}")
    return value


def _string_list(value: Any, name: str) -> List[str]:
    if not isinstance(value, list) or not value:
        raise ValueError(f"{name} must be a non-empty YAML list")
    if not all(isinstance(item, str) and item.strip() for item in value):
        raise ValueError(f"Every {name} entry must be a non-empty string")
    return value


def _validate_path_components(values: List[str], name: str) -> None:
    """Reject traversal and ambiguous output-directory components."""
    if len(set(values)) != len(values):
        raise ValueError(f"{name} entries must be unique")
    for value in values:
        if value in {".", ".."} or "/" in value or "\\" in value:
            raise ValueError(f"{name} entries must be safe path components")


def create_parser() -> argparse.ArgumentParser:
    """Create the batch SMR command-line parser."""
    parser = argparse.ArgumentParser(
        prog="python -m batch_smr_dynamic.src",
        description="Batch dynamic single-cell SMR analysis",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    parser.add_argument("--resources", nargs="+")
    parser.add_argument("--resources-file")
    parser.add_argument("--default-resources", action="store_true")
    parser.add_argument("--out-filename")
    parser.add_argument("--outcome-name")
    parser.add_argument("--xqtl-type", default="sc_eqtl")
    parser.add_argument("--output", default=".")
    parser.add_argument("--pval", type=float, default=5e-8)
    parser.add_argument("--diff-freq-prop", type=float, default=0.9)
    parser.add_argument("--diff-freq", type=float, default=0.2)
    parser.add_argument("--ancestry", default="EUR")
    parser.add_argument(
        "--quick-smr",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument("--smr-heidi-p", type=float, default=0.05)
    parser.add_argument("--plot-col", default="#B4D151")
    parser.add_argument("--plot-highlight-col", default="#8680C0")
    parser.add_argument("--stop-on-error", action="store_true")
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--config")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    """Run the batch SMR CLI."""
    args = create_parser().parse_args(argv)
    if args.config:
        config = load_config(args.config)
        resources = _string_list(
            _required(config, "xqtl_resources"),
            "xqtl_resources",
        )
        out_filename = _required(config, "out_filename")
        outcome_name = _required(config, "outcome_name")
        values = {
            "xqtl_type": config.get("xqtl_type", "sc_eqtl"),
            "save_base_path": config.get("save_base_path", "."),
            "pval": float(config.get("pval", 5e-8)),
            "diff_freq_prop": float(config.get("diff_freq_prop", 0.9)),
            "diff_freq": float(config.get("diff_freq", 0.2)),
            "ancestry": config.get("ancestry", "EUR"),
            "quick_smr": bool(config.get("quick_smr", True)),
            "smr_HEIDI_p": float(config.get("smr_HEIDI_p", 0.05)),
            "plot_col": config.get("plot_col", "#B4D151"),
            "plot_highlight_col": config.get("plot_highlight_col", "#8680C0"),
            "stop_on_error": bool(config.get("stop_on_error", False)),
        }
    else:
        if args.resources:
            resources = args.resources
        elif args.resources_file:
            resources = [
                line.strip()
                for line in Path(args.resources_file).read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
        elif args.default_resources:
            resources = get_default_dynamic_resources()
        else:
            raise ValueError(
                "Specify --resources, --resources-file, or --default-resources"
            )
        if not args.out_filename or not args.outcome_name:
            raise ValueError("--out-filename and --outcome-name are required")
        out_filename = args.out_filename
        outcome_name = args.outcome_name
        values = {
            "xqtl_type": args.xqtl_type,
            "save_base_path": args.output,
            "pval": args.pval,
            "diff_freq_prop": args.diff_freq_prop,
            "diff_freq": args.diff_freq,
            "ancestry": args.ancestry,
            "quick_smr": args.quick_smr,
            "smr_HEIDI_p": args.smr_heidi_p,
            "plot_col": args.plot_col,
            "plot_highlight_col": args.plot_highlight_col,
            "stop_on_error": args.stop_on_error,
        }

    verbose = not args.quiet
    result = run_smr_dynamic_batch(
        xqtl_resources=resources,
        out_filename=out_filename,
        outcome_name=outcome_name,
        verbose=verbose,
        **values,
    )
    if verbose:
        print(f"Processed resources: {result.get('n_resources', len(resources))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
