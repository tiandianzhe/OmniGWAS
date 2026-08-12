"""Command-line interface for SuperGNOVA result conversion."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List, Optional

from .converter import convert_supergnova_to_csv


def create_parser() -> argparse.ArgumentParser:
    """Create the converter command-line parser."""
    parser = argparse.ArgumentParser(
        prog="supergnova2csv",
        description="Convert SuperGNOVA text results to CSV",
    )
    parser.add_argument("input", nargs="?", help="Input TXT file")
    parser.add_argument("-o", "--output", help="Output CSV file")
    parser.add_argument("--batch", metavar="DIRECTORY", help="Convert all TXT files")
    parser.add_argument("--out", metavar="DIRECTORY", help="Batch output directory")
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Suppress malformed-row warnings",
    )
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    """Run a single-file or batch conversion."""
    args = create_parser().parse_args(argv)
    if args.batch:
        if args.input or args.output:
            raise ValueError("Positional input and --output cannot be used with --batch")
        if not args.out:
            raise ValueError("--batch requires --out DIRECTORY")
        input_dir = Path(args.batch)
        if not input_dir.is_dir():
            raise NotADirectoryError(f"Batch input directory not found: {input_dir}")
        output_dir = Path(args.out)
        output_dir.mkdir(parents=True, exist_ok=True)
        inputs = sorted(input_dir.glob("*.txt"))
        if not inputs:
            print(f"No .txt files found in {input_dir}", file=sys.stderr)
            return 1
        failures = 0
        for input_path in inputs:
            try:
                convert_supergnova_to_csv(
                    str(input_path),
                    str(output_dir / f"{input_path.stem}.csv"),
                    skip_warnings=args.quiet,
                )
            except (OSError, ValueError) as exc:
                failures += 1
                print(f"Error converting {input_path}: {exc}", file=sys.stderr)
        return 1 if failures else 0

    if not args.input:
        create_parser().error("provide INPUT or --batch DIRECTORY")
    if args.out:
        raise ValueError("--out is only valid with --batch")
    try:
        convert_supergnova_to_csv(
            args.input,
            args.output,
            skip_warnings=args.quiet,
        )
    except (OSError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
