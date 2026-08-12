#!/usr/bin/env python3
"""Python API and CLI for the OmniGWAS R utility functions.

Values cross the Python to R boundary as JSON data on standard input. The
wrapper never constructs executable R source from caller-controlled strings.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

MODULE_DIR = Path(__file__).resolve().parent.parent
R_DRIVER = MODULE_DIR / "R" / "cli_driver.R"
VERSION = "0.1.0"


def _run_r_operation(
    operation: str,
    payload: Dict[str, Any],
    *,
    r_executable: str = "Rscript",
    timeout: int = 300,
) -> tuple[bool, str, str]:
    """Execute one allowlisted operation through the fixed R driver."""
    if not R_DRIVER.is_file():
        return False, "", f"R driver not found: {R_DRIVER}"

    request = json.dumps(
        {"operation": operation, "payload": payload},
        ensure_ascii=False,
    )

    try:
        result = subprocess.run(
            [r_executable, str(R_DRIVER)],
            input=request,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return False, "", "R operation timed out"
    except FileNotFoundError:
        return False, "", f"{r_executable} not found. Please install R."
    except OSError as exc:
        return False, "", str(exc)

    return result.returncode == 0, result.stdout, result.stderr


def run_read_table(
    input_file: str,
    header: bool = True,
    sep: str = "auto",
    na_strings: str = "NA",
    check_names: bool = False,
    as_dataframe: bool = True,
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Read a tabular file with the R utility layer and report its shape."""
    del as_dataframe
    if sep not in {"auto", "tab", "comma", "space"}:
        raise ValueError("sep must be one of: auto, tab, comma, space")

    success, output, error = _run_r_operation(
        "read",
        {
            "input_file": input_file,
            "header": header,
            "sep": sep,
            "na_strings": na_strings,
            "check_names": check_names,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "input": input_file,
        "output": output,
        "error": error,
        "message": f"Read {input_file}" if success else f"Failed: {error}",
    }


def run_convert_numeric(
    input_file: str,
    output_file: Optional[str] = None,
    columns: Optional[List[str]] = None,
    to_type: str = "numeric",
    check_na: bool = True,
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Convert selected columns in an RDS data frame."""
    if to_type not in {"numeric", "integer", "character"}:
        raise ValueError("to_type must be numeric, integer, or character")
    selected_columns = columns or ["pos.outcome"]

    success, output, error = _run_r_operation(
        "convert",
        {
            "input_file": input_file,
            "output_file": output_file,
            "columns": selected_columns,
            "to_type": to_type,
            "check_na": check_na,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "input": input_file,
        "output": output_file,
        "columns_converted": selected_columns,
        "output_data": output,
        "error": error,
        "message": output if success else error,
    }


def run_export_excel(
    input_file: str,
    output_file: str,
    sheet_name: str = "Sheet1",
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Export an RDS data frame to an Excel workbook."""
    success, output, error = _run_r_operation(
        "export_excel",
        {
            "input_file": input_file,
            "output_file": output_file,
            "sheet_name": sheet_name,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "input": input_file,
        "output": output_file,
        "error": error,
        "message": output if success else error,
    }


def run_rename_columns(
    input_file: str,
    output_file: Optional[str] = None,
    pattern: Optional[str] = None,
    replacement: Optional[str] = None,
    column: Optional[str] = None,
    mode: str = "str_replace",
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Replace values in one column using stringr-compatible matching."""
    if mode != "str_replace":
        raise ValueError("Only mode='str_replace' is supported")
    if not pattern or column is None:
        raise ValueError("pattern and column are required")

    success, output, error = _run_r_operation(
        "rename",
        {
            "input_file": input_file,
            "output_file": output_file,
            "pattern": pattern,
            "replacement": replacement or "",
            "column": column,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "error": error,
        "message": output if success else error,
    }


def run_export_rds(
    input_file: str,
    output_file: str,
    compress: str = "gzip",
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Copy an RDS object using the requested R compression format."""
    if compress not in {"none", "gzip", "bzip2", "xz"}:
        raise ValueError("Unsupported RDS compression type")

    success, output, error = _run_r_operation(
        "export_rds",
        {
            "input_file": input_file,
            "output_file": output_file,
            "compress": compress,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "error": error,
        "message": output if success else error,
    }


def run_clean_compress(
    input_file: str,
    output_file: str,
    drop_cols: Optional[List[str]] = None,
    keep_cols: Optional[List[str]] = None,
    compress: bool = True,
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Subset columns and write a text or gzip-compressed result."""
    success, output, error = _run_r_operation(
        "clean",
        {
            "input_file": input_file,
            "output_file": output_file,
            "drop_cols": drop_cols or [],
            "keep_cols": keep_cols or [],
            "compress": compress,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "error": error,
        "message": output if success else error,
    }


def run_export_txt(
    input_file: str,
    output_file: str,
    sep: str = "tab",
    header: bool = True,
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Export an RDS data frame to a delimited text file."""
    if sep not in {"tab", "comma", "space"}:
        raise ValueError("sep must be tab, comma, or space")

    success, output, error = _run_r_operation(
        "export_txt",
        {
            "input_file": input_file,
            "output_file": output_file,
            "sep": sep,
            "header": header,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "error": error,
        "message": output if success else error,
    }


def run_quick_clean_gwas(
    input_file: str,
    output_file: str,
    essential_cols: Optional[List[str]] = None,
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Keep essential GWAS columns and write a compressed text file."""
    selected_columns = essential_cols or [
        "SNP",
        "chr.outcome",
        "pos.outcome",
        "pval.outcome",
        "effect_allele.outcome",
        "other_allele.outcome",
        "beta.outcome",
        "se.outcome",
    ]
    success, output, error = _run_r_operation(
        "clean_gwas",
        {
            "input_file": input_file,
            "output_file": output_file,
            "essential_cols": selected_columns,
        },
        r_executable=r_executable,
    )
    return {
        "success": success,
        "error": error,
        "message": output if success else error,
    }


def run_batch_convert(
    input_file: str,
    output_file: str,
    columns: List[str],
    to_type: str = "numeric",
    *,
    r_executable: str = "Rscript",
) -> Dict[str, Any]:
    """Compatibility wrapper for conversion of multiple columns."""
    return run_convert_numeric(
        input_file=input_file,
        output_file=output_file,
        columns=columns,
        to_type=to_type,
        r_executable=r_executable,
    )


def create_parser() -> argparse.ArgumentParser:
    """Create the command-line parser."""
    parser = argparse.ArgumentParser(
        prog="python -m utils.src",
        description="OmniGWAS auxiliary data-processing tools",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    subparsers = parser.add_subparsers(dest="command")

    read_parser = subparsers.add_parser("read", help="Read a tabular data file")
    read_parser.add_argument("--input", "-i", required=True)
    read_parser.add_argument(
        "--header",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    read_parser.add_argument(
        "--sep",
        choices=["auto", "tab", "comma", "space"],
        default="auto",
    )
    read_parser.add_argument("--na", default="NA")

    convert_parser = subparsers.add_parser("convert", help="Convert column types")
    convert_parser.add_argument("--input", "-i", required=True)
    convert_parser.add_argument("--output", "-o")
    convert_parser.add_argument("--col", "-c", action="append", dest="columns", default=[])
    convert_parser.add_argument(
        "--type",
        choices=["numeric", "integer", "character"],
        default="numeric",
    )

    excel_parser = subparsers.add_parser("export-excel", help="Export to Excel")
    excel_parser.add_argument("--input", "-i", required=True)
    excel_parser.add_argument("--output", "-o", required=True)
    excel_parser.add_argument("--sheet", default="Sheet1")

    rename_parser = subparsers.add_parser("rename", help="Replace values in a column")
    rename_parser.add_argument("--input", "-i", required=True)
    rename_parser.add_argument("--output", "-o")
    rename_parser.add_argument("--col", required=True)
    rename_parser.add_argument("--pattern", "-p", required=True)
    rename_parser.add_argument("--replacement", "-r", default="")

    rds_parser = subparsers.add_parser("export-rds", help="Save as RDS")
    rds_parser.add_argument("--input", "-i", required=True)
    rds_parser.add_argument("--output", "-o", required=True)
    rds_parser.add_argument(
        "--compress",
        choices=["none", "gzip", "bzip2", "xz"],
        default="gzip",
    )

    clean_parser = subparsers.add_parser("clean", help="Clean and compress data")
    clean_parser.add_argument("--input", "-i", required=True)
    clean_parser.add_argument("--output", "-o", required=True)
    clean_parser.add_argument("--drop", "-d", action="append", dest="drop_cols", default=[])
    clean_parser.add_argument("--keep", "-k", action="append", dest="keep_cols", default=[])

    gwas_parser = subparsers.add_parser("clean-gwas", help="Keep essential GWAS columns")
    gwas_parser.add_argument("--input", "-i", required=True)
    gwas_parser.add_argument("--output", "-o", required=True)

    txt_parser = subparsers.add_parser("export-txt", help="Export to delimited text")
    txt_parser.add_argument("--input", "-i", required=True)
    txt_parser.add_argument("--output", "-o", required=True)
    txt_parser.add_argument(
        "--sep",
        choices=["tab", "comma", "space"],
        default="tab",
    )

    return parser


def main(argv: Optional[List[str]] = None) -> int:
    """Run the CLI and return a process exit code."""
    parser = create_parser()
    args = parser.parse_args(argv)
    if not args.command:
        parser.print_help()
        return 0

    if args.command == "read":
        result = run_read_table(args.input, args.header, args.sep, args.na)
    elif args.command == "convert":
        if not args.columns:
            parser.error("--col is required for convert")
        result = run_convert_numeric(args.input, args.output, args.columns, args.type)
    elif args.command == "export-excel":
        result = run_export_excel(args.input, args.output, args.sheet)
    elif args.command == "rename":
        result = run_rename_columns(
            args.input,
            args.output,
            args.pattern,
            args.replacement,
            args.col,
        )
    elif args.command == "export-rds":
        result = run_export_rds(args.input, args.output, args.compress)
    elif args.command == "clean":
        result = run_clean_compress(
            args.input,
            args.output,
            args.drop_cols or None,
            args.keep_cols or None,
        )
    elif args.command == "clean-gwas":
        result = run_quick_clean_gwas(args.input, args.output)
    elif args.command == "export-txt":
        result = run_export_txt(args.input, args.output, args.sep)
    else:
        parser.error(f"unknown command: {args.command}")

    stream = None if result["success"] else sys.stderr
    print(result.get("message", ""), file=stream)
    return 0 if result["success"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
