"""Python API and CLI for the R-based GWAS plotting functions."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

MODULE_DIR = Path(__file__).resolve().parent.parent
R_DRIVER = MODULE_DIR / "R" / "cli_driver.R"
VERSION = "0.1.0"


def _run_plot(
    operation: str,
    payload: Dict[str, Any],
    *,
    r_executable: str = "Rscript",
    timeout: Optional[int] = 300,
) -> subprocess.CompletedProcess[str]:
    if not R_DRIVER.is_file():
        raise FileNotFoundError(f"R driver not found: {R_DRIVER}")
    try:
        result = subprocess.run(
            [r_executable, str(R_DRIVER)],
            input=json.dumps(
                {"operation": operation, "payload": payload},
                ensure_ascii=False,
            ),
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(f"{r_executable} was not found") from exc
    if result.returncode != 0:
        raise RuntimeError(
            f"R plotting driver failed with code {result.returncode}: "
            f"{result.stderr.strip()}"
        )
    return result


def _validate_common(input_file: str, output: str, width: float, height: float, dpi: int) -> None:
    if not Path(input_file).is_file():
        raise FileNotFoundError(f"Input data file not found: {input_file}")
    if width <= 0 or height <= 0:
        raise ValueError("width and height must be positive")
    if dpi < 72:
        raise ValueError("dpi must be at least 72")
    Path(output).parent.mkdir(parents=True, exist_ok=True)


def create_manhattan(
    input_file: str,
    output: str = "manhattan_plot.png",
    pval_col: str = "P",
    fdr_col: Optional[str] = None,
    threshold: float = 0.05,
    threshold_type: str = "fdr",
    title: str = "Manhattan Plot",
    width: float = 12,
    height: float = 6,
    dpi: int = 300,
    label_snps: Optional[str] = None,
    sig_color: str = "black",
    r_executable: str = "Rscript",
    timeout: Optional[int] = 300,
) -> subprocess.CompletedProcess[str]:
    """Create a Manhattan plot from CSV or delimited text input."""
    _validate_common(input_file, output, width, height, dpi)
    if threshold_type not in {"pvalue", "fdr"}:
        raise ValueError("threshold_type must be 'pvalue' or 'fdr'")
    if not 0 < threshold <= 1:
        raise ValueError("threshold must be in the interval (0, 1]")
    labels = None
    if label_snps:
        labels = [item.strip() for item in label_snps.split(",") if item.strip()]
    return _run_plot(
        "manhattan",
        {
            "input_file": input_file,
            "output": output,
            "pval_col": pval_col,
            "fdr_col": fdr_col,
            "threshold": threshold,
            "threshold_type": threshold_type,
            "title": title,
            "width": width,
            "height": height,
            "dpi": dpi,
            "label_snps": labels,
            "sig_color": sig_color,
        },
        r_executable=r_executable,
        timeout=timeout,
    )


def create_qq(
    input_file: str,
    output: str = "qq_plot.png",
    pval_col: str = "P",
    title: str = "Q-Q Plot",
    width: float = 6,
    height: float = 6,
    dpi: int = 300,
    r_executable: str = "Rscript",
    timeout: Optional[int] = 300,
) -> subprocess.CompletedProcess[str]:
    """Create a Q-Q plot from CSV or delimited text input."""
    _validate_common(input_file, output, width, height, dpi)
    return _run_plot(
        "qq",
        {
            "input_file": input_file,
            "output": output,
            "pval_col": pval_col,
            "title": title,
            "width": width,
            "height": height,
            "dpi": dpi,
        },
        r_executable=r_executable,
        timeout=timeout,
    )


def create_parser() -> argparse.ArgumentParser:
    """Create the plotting command-line parser."""
    parser = argparse.ArgumentParser(
        prog="python -m manhattan_plot.src",
        description="Generate Manhattan or Q-Q plots with the OmniGWAS R module",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    parser.add_argument("--input", "-i", required=True)
    parser.add_argument("--output", "-o", default="manhattan_plot.png")
    parser.add_argument("--pval-col", default="P")
    parser.add_argument("--fdr-col")
    parser.add_argument("--threshold", type=float, default=0.05)
    parser.add_argument("--threshold-type", choices=["pvalue", "fdr"], default="fdr")
    parser.add_argument("--title", default="Manhattan Plot")
    parser.add_argument("--width", type=float, default=12)
    parser.add_argument("--height", type=float, default=6)
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--label-snps")
    parser.add_argument("--sig-color", default="black")
    parser.add_argument("--qq-only", action="store_true")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    """Run the plotting CLI."""
    args = create_parser().parse_args(argv)
    if args.qq_only:
        create_qq(
            input_file=args.input,
            output=args.output,
            pval_col=args.pval_col,
            title=args.title,
            width=args.width,
            height=args.height,
            dpi=args.dpi,
        )
    else:
        create_manhattan(
            input_file=args.input,
            output=args.output,
            pval_col=args.pval_col,
            fdr_col=args.fdr_col,
            threshold=args.threshold,
            threshold_type=args.threshold_type,
            title=args.title,
            width=args.width,
            height=args.height,
            dpi=args.dpi,
            label_snps=args.label_snps,
            sig_color=args.sig_color,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
