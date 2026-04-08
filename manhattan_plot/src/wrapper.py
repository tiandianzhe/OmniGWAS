"""
Python wrapper for R-based Manhattan plot generation
Provides CLI interface and Python API for OmniGWAS manhattan_plot module
"""

import subprocess
import os
import argparse
from pathlib import Path


def run_r_script(
    script_path: str,
    args: dict,
    r_executable: str = "Rscript"
) -> subprocess.CompletedProcess:
    """
    Execute R script with arguments

    Args:
        script_path: Path to the R script
        args: Dictionary of arguments to pass to R
        r_executable: R executable name or path

    Returns:
        CompletedProcess object
    """
    cmd = [r_executable, script_path]

    for key, value in args.items():
        if value is not None:
            if isinstance(value, bool):
                if value:
                    cmd.extend([key])
            else:
                cmd.extend([key, str(value)])

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(f"Error running R script: {result.stderr}")
        raise RuntimeError(f"R script execution failed: {result.stderr}")

    return result


def create_manhattan(
    input_file: str,
    output: str = "manhattan_plot.png",
    pval_col: str = "P",
    fdr_col: str = None,
    threshold: float = 0.05,
    threshold_type: str = "fdr",
    title: str = "Manhattan Plot",
    width: float = 12,
    height: float = 6,
    dpi: int = 300,
    label_snps: str = None,
    sig_color: str = "black",
    r_executable: str = "Rscript"
):
    """
    Create a Manhattan plot from GWAS summary statistics

    Args:
        input_file: Path to input CSV/TXT file
        output: Output plot file path
        pval_col: Column name for p-values
        fdr_col: Column name for FDR values
        threshold: Significance threshold
        threshold_type: "pvalue" or "fdr"
        title: Plot title
        width: Plot width in inches
        height: Plot height in inches
        dpi: Resolution in DPI
        label_snps: Comma-separated list of SNP IDs to label
        sig_color: Color for significant points
        r_executable: R executable path
    """
    # Get R script path
    module_dir = Path(__file__).parent.parent
    r_script = module_dir / "R" / "manhattan_plot.R"

    if not r_script.exists():
        raise FileNotFoundError(f"R script not found: {r_script}")

    args = {
        "--input": input_file,
        "--output": output,
        "--pval_col": pval_col,
        "--threshold": threshold,
        "--threshold_type": threshold_type,
        "--title": title,
        "--width": width,
        "--height": height,
        "--dpi": dpi,
        "--sig_color": sig_color
    }

    if fdr_col:
        args["--fdr_col"] = fdr_col

    if label_snps:
        args["--label_snps"] = label_snps

    return run_r_script(str(r_script), args, r_executable)


def create_qq(
    input_file: str,
    output: str = "qq_plot.png",
    pval_col: str = "P",
    title: str = "Q-Q Plot",
    width: float = 6,
    height: float = 6,
    dpi: int = 300,
    r_executable: str = "Rscript"
):
    """
    Create a Q-Q plot from GWAS summary statistics

    Args:
        input_file: Path to input CSV/TXT file
        output: Output plot file path
        pval_col: Column name for p-values
        title: Plot title
        width: Plot width in inches
        height: Plot height in inches
        dpi: Resolution in DPI
        r_executable: R executable path
    """
    module_dir = Path(__file__).parent.parent
    r_script = module_dir / "R" / "manhattan_plot.R"

    if not r_script.exists():
        raise FileNotFoundError(f"R script not found: {r_script}")

    args = {
        "--input": input_file,
        "--output": output,
        "--pval_col": pval_col,
        "--qq_only": True,
        "--title": title,
        "--width": width,
        "--height": height,
        "--dpi": dpi
    }

    return run_r_script(str(r_script), args, r_executable)


def main():
    """CLI entry point"""
    parser = argparse.ArgumentParser(
        description="OmniGWAS Manhattan Plot Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create Manhattan plot with FDR threshold
  python -m src.wrapper --input data.csv --output manhattan.png --fdr_col FDR --threshold 0.05

  # Create Manhattan plot with p-value threshold
  python -m src.wrapper --input data.csv --output manhattan.png --pval_col P --threshold 5e-8 --threshold_type pvalue

  # Create both Manhattan and QQ plots
  python -m src.wrapper --input data.csv --output_dir plots/
        """
    )

    parser.add_argument("--input", "-i", required=True, help="Input data file (CSV/TXT)")
    parser.add_argument("--output", "-o", default="manhattan_plot.png", help="Output plot file")
    parser.add_argument("--pval_col", default="P", help="P-value column name")
    parser.add_argument("--fdr_col", default=None, help="FDR column name")
    parser.add_argument("--threshold", type=float, default=0.05, help="Significance threshold")
    parser.add_argument("--threshold_type", choices=["pvalue", "fdr"], default="fdr",
                       help="Type of threshold")
    parser.add_argument("--title", default="Manhattan Plot", help="Plot title")
    parser.add_argument("--width", type=float, default=12, help="Plot width in inches")
    parser.add_argument("--height", type=float, default=6, help="Plot height in inches")
    parser.add_argument("--dpi", type=int, default=300, help="Resolution in DPI")
    parser.add_argument("--label_snps", default=None,
                       help="Comma-separated SNP IDs to label")
    parser.add_argument("--sig_color", default="black", help="Color for significant points")
    parser.add_argument("--qq_only", action="store_true", help="Generate QQ plot only")

    args = parser.parse_args()

    if args.qq_only:
        create_qq(
            input_file=args.input,
            output=args.output,
            pval_col=args.pval_col,
            title=args.title,
            width=args.width,
            height=args.height,
            dpi=args.dpi
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
            sig_color=args.sig_color
        )


if __name__ == "__main__":
    main()
