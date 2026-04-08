#!/usr/bin/env python3
"""
OmniGWAS utils - Python wrapper for R utility functions

This module provides Python CLI and API access to R functions for:
- Data reading and parsing
- Column type conversion
- Excel/RDS/TXT export
- Column renaming
- Data cleaning and compression

Usage:
    python -m utils.src --help
    python -m utils.src read --input data.txt
    python -m utils.src convert --input data.rds --col pos
    python -m utils.src export-excel --input data.rds --output results.xlsx
"""

import argparse
import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Optional, List, Dict, Any, Union


# R script directory
R_SCRIPT_DIR = Path(__file__).parent.parent / "R"


def run_r_script(
    r_code: str,
    input_file: Optional[str] = None,
    output_file: Optional[str] = None,
    return_output: bool = True
) -> tuple:
    """
    Execute R code using subprocess.

    Args:
        r_code: R code to execute
        input_file: Optional input file path
        output_file: Optional output file path
        return_output: Whether to capture stdout

    Returns:
        (success: bool, output: str, error: str)
    """
    try:
        result = subprocess.run(
            ["Rscript", "-e", r_code],
            capture_output=True,
            text=True,
            timeout=300
        )

        success = result.returncode == 0
        output = result.stdout if return_output else ""
        error = result.stderr

        return success, output, error

    except subprocess.TimeoutExpired:
        return False, "", "R script execution timed out"
    except FileNotFoundError:
        return False, "", "Rscript not found. Please install R."
    except Exception as e:
        return False, "", str(e)


def run_read_table(
    input_file: str,
    header: bool = True,
    sep: str = "auto",
    na_strings: str = "NA",
    check_names: bool = False,
    as_dataframe: bool = True
) -> Dict[str, Any]:
    """
    Read tabular data file using R.

    Args:
        input_file: Path to input file
        header: Has header row
        sep: Separator (auto, tab, comma, space)
        na_strings: NA string representation
        check_names: Check column names
        as_dataframe: Return as dict/DataFrame

    Returns:
        Dictionary with status, message, and optionally data
    """
    sep_map = {"auto": '"auto"', "tab": '"\\t"', "comma": '","', "space": '"\\s+"'}
    sep_code = sep_map.get(sep, f'"{sep}"')

    r_code = f'''
    source("{R_SCRIPT_DIR}/read_table.R")
    data <- read_data(
        file_path = "{input_file.replace("\\", "/")}",
        header = {str(header).upper()},
        sep = {sep_code},
        na.strings = "{na_strings}",
        check.names = {str(check_names).upper()}
    )
    cat("ROWS:", nrow(data), "\\n")
    cat("COLS:", ncol(data), "\\n")
    cat("HEAD:\\n")
    print(head(data, 3))
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "input": input_file,
        "output": output,
        "error": error,
        "message": f"Read {input_file}" if success else f"Failed: {error}"
    }


def run_convert_numeric(
    input_file: str,
    output_file: Optional[str] = None,
    columns: List[str] = None,
    to_type: str = "numeric",
    check_na: bool = True
) -> Dict[str, Any]:
    """
    Convert columns to numeric or other types.

    Args:
        input_file: Input RDS file
        output_file: Output RDS file
        columns: Columns to convert
        to_type: Target type (numeric, integer, character)
        check_na: Report NA counts

    Returns:
        Dictionary with conversion results
    """
    if columns is None:
        columns = ["pos.outcome"]

    cols_str = f'c({", ".join(f\'"{c}"\' for c in columns)})'
    output_code = f'saveRDS(data, "{output_file.replace(chr(92), "/")}")' if output_file else ""

    r_code = f'''
    library(dplyr)

    # Load data
    data <- readRDS("{input_file.replace(chr(92), "/")}")

    # Convert columns
    convert_{to_type}_safe <- function(df, col) {{
        if (col %in% names(df)) {{
            df[[col]] <- as.{to_type}(df[[col]])
            na_count <<- sum(is.na(df[[col]]))
            cat("Converted:", col, "->", typeof(df[[col]]), "| NAs:", na_count, "\\n")
        }}
        return(df)
    }}

    na_count <- 0
    for (col in {cols_str}) {{
        data <- convert_{to_type}_safe(data, col)
    }}

    {output_code}

    cat("DONE\\n")
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "input": input_file,
        "output": output_file,
        "columns_converted": columns,
        "output_data": output,
        "error": error
    }


def run_export_excel(
    input_file: str,
    output_file: str,
    sheet_name: str = "Sheet1"
) -> Dict[str, Any]:
    """
    Export data to Excel file.

    Args:
        input_file: Input RDS file
        output_file: Output xlsx file
        sheet_name: Sheet name

    Returns:
        Dictionary with export status
    """
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_file) or ".", exist_ok=True)

    r_code = f'''
    library(writexl)

    # Load data
    data <- readRDS("{input_file.replace(chr(92), "/")}")

    # Export to Excel
    write_xlsx(data, path = "{output_file.replace(chr(92), "/")}")

    file_size <- file.size("{output_file.replace(chr(92), "/")}") / 1024
    cat("Exported:", nrow(data), "rows x", ncol(data), "cols\\n")
    cat("File:", "{output_file}"\\n)
    cat("Size:", round(file_size, 1), "KB\\n")
    cat("DONE\\n")
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "input": input_file,
        "output": output_file,
        "message": output if success else error
    }


def run_rename_columns(
    input_file: str,
    output_file: Optional[str] = None,
    pattern: str = None,
    replacement: str = None,
    column: str = None,
    mode: str = "str_replace"
) -> Dict[str, Any]:
    """
    Rename columns or values in dataset.

    Args:
        input_file: Input RDS file
        output_file: Output RDS file
        pattern: Pattern to replace
        replacement: Replacement string
        column: Column to modify (for value replacement)
        mode: Rename mode (str_replace, direct_mapping)

    Returns:
        Dictionary with rename results
    """
    output_code = f'saveRDS(data, "{output_file.replace(chr(92), "/")}")' if output_file else 'cat("No output file specified\\n")'

    if mode == "str_replace" and pattern:
        r_code = f'''
        library(stringr)

        data <- readRDS("{input_file.replace(chr(92), "/")}")

        if ("{column}" %in% names(data)) {{
            data$"{column}" <- str_replace_all(data$"{column}", "{pattern}", "{replacement}")
            cat("Renamed values in column: {column}\\n")
        }}

        {output_code}
        cat("DONE\\n")
        '''
    else:
        r_code = f'''
        data <- readRDS("{input_file.replace(chr(92), "/")}")
        cat("Columns:", paste(names(data), collapse=", "), "\\n")
        {output_code}
        cat("DONE\\n")
        '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "message": output if success else error
    }


def run_export_rds(
    input_file: str,
    output_file: str,
    compress: str = "gzip"
) -> Dict[str, Any]:
    """
    Save data to RDS file.

    Args:
        input_file: Input RDS file
        output_file: Output RDS file
        compress: Compression type (none, gzip, bzip2, xz)

    Returns:
        Dictionary with save status
    """
    r_code = f'''
    # Load data
    data <- readRDS("{input_file.replace(chr(92), "/")}")

    # Save with compression
    saveRDS(data, file = "{output_file.replace(chr(92), "/")}", compress = "{compress}")

    file_size <- file.size("{output_file.replace(chr(92), "/")}") / 1024
    obj_size <- object.size(data) / 1024
    cat("Saved:", nrow(data), "rows x", ncol(data), "cols\\n")
    cat("File size:", round(file_size, 1), "KB\\n")
    cat("Object size:", round(obj_size, 1), "KB\\n")
    cat("DONE\\n")
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "message": output if success else error
    }


def run_clean_compress(
    input_file: str,
    output_file: str,
    drop_cols: List[str] = None,
    keep_cols: List[str] = None,
    compress: bool = True
) -> Dict[str, Any]:
    """
    Clean data by removing columns and optionally compress.

    Args:
        input_file: Input RDS file
        output_file: Output file (.txt, .txt.gz, etc.)
        drop_cols: Columns to remove
        keep_cols: Columns to keep (takes precedence over drop_cols)
        compress: Compress output if .gz extension

    Returns:
        Dictionary with cleaning results
    """
    if drop_cols:
        cols_str = f'c({", ".join(f\'"{c}"\' for c in drop_cols)})'
        cols_code = f"drop_cols = {cols_str}"
    elif keep_cols:
        cols_str = f'c({", ".join(f\'"{c}"\' for c in keep_cols)})'
        cols_code = f"keep_cols = {cols_str}"
    else:
        cols_code = "drop_cols = NULL"

    r_code = f'''
    source("{R_SCRIPT_DIR}/clean_compress.R")

    data <- readRDS("{input_file.replace(chr(92), "/")}")
    cat("Input:", nrow(data), "rows x", ncol(data), "cols\\n")

    clean_and_compress(
        data = data,
        {cols_code},
        output_path = "{output_file.replace(chr(92), "/")}"
    )

    cat("DONE\\n")
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "message": output if success else error
    }


def run_export_txt(
    input_file: str,
    output_file: str,
    sep: str = "tab",
    header: bool = True
) -> Dict[str, Any]:
    """
    Export data to TXT/CSV file.

    Args:
        input_file: Input RDS file
        output_file: Output file path
        sep: Separator (tab, comma, space)
        header: Include header row

    Returns:
        Dictionary with export status
    """
    sep_map = {"tab": '"\\t"', "comma": '","', "space": '" "'}
    sep_code = sep_map.get(sep, '"\\t"')

    r_code = f'''
    source("{R_SCRIPT_DIR}/export_txt.R")

    data <- readRDS("{input_file.replace(chr(92), "/")}")

    export_to_txt(
        data = data,
        output_path = "{output_file.replace(chr(92), "/")}",
        sep = {sep_code},
        col.names = {str(header).upper()}
    )

    cat("DONE\\n")
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "message": output if success else error
    }


def run_quick_clean_gwas(
    input_file: str,
    output_file: str,
    essential_cols: List[str] = None
) -> Dict[str, Any]:
    """
    Quick clean for GWAS: keep essential columns and compress.

    Args:
        input_file: Input RDS file
        output_file: Output file (.gz recommended)
        essential_cols: Essential columns to keep

    Returns:
        Dictionary with cleaning results
    """
    if essential_cols is None:
        essential_cols = [
            "SNP", "chr.outcome", "pos.outcome", "pval.outcome",
            "effect_allele.outcome", "other_allele.outcome",
            "beta.outcome", "se.outcome"
        ]

    cols_str = f'c({", ".join(f\'"{c}"\' for c in essential_cols)})'

    r_code = f'''
    source("{R_SCRIPT_DIR}/clean_compress.R")

    data <- readRDS("{input_file.replace(chr(92), "/")}")
    cat("Input:", nrow(data), "rows x", ncol(data), "cols\\n")

    quick_clean_gwas(
        data = data,
        output_path = "{output_file.replace(chr(92), "/")}",
        chr_col = "chr.outcome",
        pos_col = "pos.outcome"
    )

    cat("DONE\\n")
    '''

    success, output, error = run_r_script(r_code)

    return {
        "success": success,
        "message": output if success else error
    }


def run_batch_convert(
    input_file: str,
    output_file: str,
    columns: List[str],
    to_type: str = "numeric"
) -> Dict[str, Any]:
    """
    Batch convert multiple columns.

    Args:
        input_file: Input RDS file
        output_file: Output RDS file
        columns: Columns to convert
        to_type: Target type

    Returns:
        Dictionary with batch conversion results
    """
    return run_convert_numeric(
        input_file=input_file,
        output_file=output_file,
        columns=columns,
        to_type=to_type
    )


def create_parser() -> argparse.ArgumentParser:
    """Create command-line argument parser."""
    parser = argparse.ArgumentParser(
        prog="python -m utils.src",
        description="OmniGWAS utils - Auxiliary data processing tools",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Read data file
  python -m utils.src read --input results.txt.gz

  # Convert columns to numeric
  python -m utils.src convert --input data.rds --col pos.outcome --col chr.outcome --output cleaned.rds

  # Export to Excel
  python -m utils.src export-excel --input data.rds --output results.xlsx

  # Rename column values
  python -m utils.src rename --input data.rds --col outcome --pattern "Nonalcoholic_steatohepatitis" --replacement "NASH" --output renamed.rds

  # Clean and compress GWAS data
  python -m utils.src clean --input data.rds --output cleaned.txt.gz

  # Quick clean for FUMA
  python -m utils.src clean-gwas --input data.rds --output FUMA_input.txt.gz
        """
    )

    parser.add_argument("--version", action="version", version="%(prog)s 1.0.0")

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # read command
    read_parser = subparsers.add_parser("read", help="Read tabular data file")
    read_parser.add_argument("--input", "-i", required=True, help="Input file path")
    read_parser.add_argument("--header/--no-header", dest="header", default=True,
                             help="File has header row (default: True)")
    read_parser.add_argument("--sep", choices=["auto", "tab", "comma", "space"],
                            default="auto", help="Separator (default: auto)")
    read_parser.add_argument("--na", default="NA", help="NA string (default: NA)")

    # convert command
    convert_parser = subparsers.add_parser("convert", help="Convert column types")
    convert_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    convert_parser.add_argument("--output", "-o", help="Output RDS file")
    convert_parser.add_argument("--col", "-c", action="append", dest="columns",
                                default=[], help="Column to convert (can specify multiple)")
    convert_parser.add_argument("--type", choices=["numeric", "integer", "character"],
                               default="numeric", help="Target type (default: numeric)")

    # export-excel command
    excel_parser = subparsers.add_parser("export-excel", help="Export to Excel")
    excel_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    excel_parser.add_argument("--output", "-o", required=True, help="Output xlsx file")
    excel_parser.add_argument("--sheet", default="Sheet1", help="Sheet name")

    # rename command
    rename_parser = subparsers.add_parser("rename", help="Rename columns/values")
    rename_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    rename_parser.add_argument("--output", "-o", help="Output RDS file")
    rename_parser.add_argument("--col", help="Column to rename values in")
    rename_parser.add_argument("--pattern", "-p", help="Pattern to replace")
    rename_parser.add_argument("--replacement", "-r", help="Replacement string")

    # export-rds command
    rds_parser = subparsers.add_parser("export-rds", help="Save as RDS")
    rds_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    rds_parser.add_argument("--output", "-o", required=True, help="Output RDS file")
    rds_parser.add_argument("--compress", choices=["none", "gzip", "bzip2", "xz"],
                           default="gzip", help="Compression type")

    # clean command
    clean_parser = subparsers.add_parser("clean", help="Clean and compress data")
    clean_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    clean_parser.add_argument("--output", "-o", required=True, help="Output file")
    clean_parser.add_argument("--drop", "-d", action="append", dest="drop_cols",
                             default=[], help="Columns to drop")
    clean_parser.add_argument("--keep", "-k", action="append", dest="keep_cols",
                             default=[], help="Columns to keep")

    # clean-gwas command
    gwas_parser = subparsers.add_parser("clean-gwas", help="Quick GWAS clean")
    gwas_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    gwas_parser.add_argument("--output", "-o", required=True, help="Output file (.gz)")

    # export-txt command
    txt_parser = subparsers.add_parser("export-txt", help="Export to TXT")
    txt_parser.add_argument("--input", "-i", required=True, help="Input RDS file")
    txt_parser.add_argument("--output", "-o", required=True, help="Output file")
    txt_parser.add_argument("--sep", choices=["tab", "comma", "space"],
                           default="tab", help="Separator")

    return parser


def main():
    """Main entry point for CLI."""
    parser = create_parser()
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 0

    # Execute command
    try:
        if args.command == "read":
            result = run_read_table(
                input_file=args.input,
                header=args.header,
                sep=args.sep,
                na_strings=args.na
            )

        elif args.command == "convert":
            if not args.columns:
                print("Error: --col is required for convert command")
                return 1
            result = run_convert_numeric(
                input_file=args.input,
                output_file=args.output,
                columns=args.columns,
                to_type=args.type
            )

        elif args.command == "export-excel":
            result = run_export_excel(
                input_file=args.input,
                output_file=args.output,
                sheet_name=args.sheet
            )

        elif args.command == "rename":
            if not args.pattern:
                print("Error: --pattern is required for rename command")
                return 1
            result = run_rename_columns(
                input_file=args.input,
                output_file=args.output,
                pattern=args.pattern,
                replacement=args.replacement,
                column=args.col
            )

        elif args.command == "export-rds":
            result = run_export_rds(
                input_file=args.input,
                output_file=args.output,
                compress=args.compress
            )

        elif args.command == "clean":
            result = run_clean_compress(
                input_file=args.input,
                output_file=args.output,
                drop_cols=args.drop_cols if args.drop_cols else None,
                keep_cols=args.keep_cols if args.keep_cols else None
            )

        elif args.command == "clean-gwas":
            result = run_quick_clean_gwas(
                input_file=args.input,
                output_file=args.output
            )

        elif args.command == "export-txt":
            result = run_export_txt(
                input_file=args.input,
                output_file=args.output,
                sep=args.sep
            )

        else:
            print(f"Unknown command: {args.command}")
            return 1

        # Print result
        if result.get("success"):
            print(f"[OK] {result.get('message', 'Success')}")
            return 0
        else:
            print(f"[ERROR] {result.get('error', result.get('message', 'Unknown error'))}")
            return 1

    except Exception as e:
        print(f"[ERROR] {str(e)}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
