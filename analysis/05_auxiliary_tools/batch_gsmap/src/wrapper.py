"""Python API and CLI for batch gsMap analysis.

The Python wrapper sends structured JSON to a fixed R driver over standard
input. It does not create or execute generated R source files.
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


def run_batch_gsmap(
    sample_names: List[str],
    sumstats_file: str,
    trait_name: str,
    h5ad_dir: str,
    annotation: str = "annotation",
    data_layer: str = "count",
    max_processes: int = 10,
    save_base_path: str = ".",
    verbose: bool = True,
    stop_on_error: bool = False,
    r_library_path: Optional[str] = None,
    *,
    r_executable: str = "Rscript",
    timeout: Optional[int] = 86400,
) -> Dict[str, Any]:
    """Run gsMap over multiple spatial transcriptomics samples."""
    if not sample_names:
        raise ValueError("sample_names must contain at least one sample")
    _validate_path_components(sample_names, "sample_names")
    if not Path(sumstats_file).is_file():
        raise FileNotFoundError(f"Summary statistics file not found: {sumstats_file}")
    if not Path(h5ad_dir).is_dir():
        raise NotADirectoryError(f"H5AD directory not found: {h5ad_dir}")
    if max_processes < 1:
        raise ValueError("max_processes must be at least 1")
    if not R_DRIVER.is_file():
        raise FileNotFoundError(f"R driver not found: {R_DRIVER}")

    output_dir = Path(save_base_path)
    output_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "sample_names": sample_names,
        "sumstats_file": str(sumstats_file),
        "trait_name": trait_name,
        "h5ad_dir": str(h5ad_dir),
        "annotation": annotation,
        "data_layer": data_layer,
        "max_processes": max_processes,
        "save_base_path": str(output_dir),
        "verbose": verbose,
        "stop_on_error": stop_on_error,
        "r_library_path": r_library_path,
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
        raise RuntimeError(f"R batch gsMap driver timed out after {timeout} seconds") from exc

    if result.returncode != 0:
        raise RuntimeError(
            "R batch gsMap driver failed with code "
            f"{result.returncode}: {result.stderr.strip()}"
        )
    if verbose and result.stdout:
        print(result.stdout, end="")

    result_file = output_dir / "batch_results.json"
    if result_file.is_file():
        with result_file.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    raise RuntimeError(
        "R batch gsMap driver exited successfully but did not write "
        f"the expected result file: {result_file}"
    )


def parse_sample_names_from_dir(
    h5ad_dir: str,
    pattern: str = "*.MOSTA.h5ad",
) -> List[str]:
    """Return sorted sample names discovered from H5AD filenames."""
    return sorted(
        path.name.removesuffix(".MOSTA.h5ad")
        for path in Path(h5ad_dir).glob(pattern)
    )


def load_config(config_file: str) -> Dict[str, Any]:
    """Load a YAML mapping without constructing arbitrary Python objects."""
    import yaml

    with Path(config_file).open("r", encoding="utf-8") as handle:
        config = yaml.safe_load(handle)
    if not isinstance(config, dict):
        raise ValueError("Configuration must contain a YAML mapping")
    return config


def _require_config_value(config: Dict[str, Any], name: str) -> Any:
    value = config.get(name)
    if value is None or value == "":
        raise ValueError(f"Missing required configuration value: {name}")
    return value


def _as_string_list(value: Any, name: str) -> List[str]:
    """Validate a YAML value as a non-empty list of strings."""
    if not isinstance(value, list) or not value:
        raise ValueError(f"{name} must be a non-empty YAML list")
    if not all(isinstance(item, str) and item.strip() for item in value):
        raise ValueError(f"Every {name} entry must be a non-empty string")
    return value


def _as_bool(value: Any, name: str) -> bool:
    """Require a real YAML boolean instead of applying Python truthiness."""
    if type(value) is not bool:
        raise ValueError(f"{name} must be a YAML boolean (true or false)")
    return value


def _validate_path_components(values: List[str], name: str) -> None:
    """Reject traversal and ambiguous output-directory components."""
    if len(set(values)) != len(values):
        raise ValueError(f"{name} entries must be unique")
    for value in values:
        if not isinstance(value, str) or not value or value in {".", ".."}:
            raise ValueError(f"Every {name} entry must be a non-empty path component")
        if "/" in value or "\\" in value:
            raise ValueError(f"{name} entries cannot contain path separators")


def create_parser() -> argparse.ArgumentParser:
    """Create the batch gsMap CLI parser."""
    parser = argparse.ArgumentParser(
        prog="python -m batch_gsmap.src",
        description="Batch gsMap spatial-transcriptomics GWAS analysis",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    parser.add_argument("--samples", nargs="+")
    parser.add_argument("--samples-file")
    parser.add_argument("--samples-dir")
    parser.add_argument("--sumstats")
    parser.add_argument("--trait")
    parser.add_argument("--h5ad-dir")
    parser.add_argument("--annotation", default="annotation")
    parser.add_argument("--data-layer", default="count")
    parser.add_argument("--max-processes", type=int, default=10)
    parser.add_argument("--output", default=".")
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--stop-on-error", action="store_true")
    parser.add_argument("--config")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    """Run the batch gsMap CLI."""
    args = create_parser().parse_args(argv)

    if args.config:
        config = load_config(args.config)
        sample_names = _as_string_list(
            _require_config_value(config, "samples"),
            "samples",
        )
        sumstats_file = _require_config_value(config, "sumstats_file")
        trait_name = _require_config_value(config, "trait_name")
        h5ad_dir = _require_config_value(config, "h5ad_dir")
        annotation = config.get("annotation", "annotation")
        data_layer = config.get("data_layer", "count")
        max_processes = int(config.get("max_processes", 10))
        save_base_path = config.get("save_base_path", ".")
        stop_on_error = _as_bool(config.get("stop_on_error", False), "stop_on_error")
    else:
        if args.samples:
            sample_names = args.samples
        elif args.samples_file:
            sample_names = [
                line.strip()
                for line in Path(args.samples_file).read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
        elif args.samples_dir:
            sample_names = parse_sample_names_from_dir(args.samples_dir)
        else:
            raise ValueError("Specify --samples, --samples-file, or --samples-dir")
        if not args.sumstats or not args.trait or not args.h5ad_dir:
            raise ValueError("--sumstats, --trait, and --h5ad-dir are required")
        sumstats_file = args.sumstats
        trait_name = args.trait
        h5ad_dir = args.h5ad_dir
        annotation = args.annotation
        data_layer = args.data_layer
        max_processes = args.max_processes
        save_base_path = args.output
        stop_on_error = args.stop_on_error

    verbose = not args.quiet
    if verbose:
        print(f"Starting batch gsMap analysis for {len(sample_names)} samples...")
    results = run_batch_gsmap(
        sample_names=sample_names,
        sumstats_file=sumstats_file,
        trait_name=trait_name,
        h5ad_dir=h5ad_dir,
        annotation=annotation,
        data_layer=data_layer,
        max_processes=max_processes,
        save_base_path=save_base_path,
        verbose=verbose,
        stop_on_error=stop_on_error,
    )
    if verbose:
        print(f"Success: {results.get('success_count', 'N/A')}")
        print(f"Failed: {results.get('failed_count', 'N/A')}")
    success_count = results.get("success_count")
    failed_count = results.get("failed_count")
    total_samples = results.get("total_samples")
    counts_are_valid = (
        type(success_count) is int
        and type(failed_count) is int
        and type(total_samples) is int
        and success_count >= 0
        and failed_count >= 0
        and total_samples == success_count + failed_count
    )
    return 0 if counts_are_valid and failed_count == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
