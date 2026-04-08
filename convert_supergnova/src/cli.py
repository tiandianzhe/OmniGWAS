#!/usr/bin/env python3
"""
Command-line interface for convert_supergnova.

Usage:
    python -m convert_supergnova.cli input.txt [-o output.csv] [-q]
    python -m convert_supergnova.cli input.txt --batch input_dir --out output_dir
"""

import sys
import os
from pathlib import Path

# Add src to path for direct execution
sys.path.insert(0, str(Path(__file__).parent))

from converter import convert_supergnova_to_csv, SuperGNOVAConverter


def main():
    """CLI entry point."""
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Single file: python cli.py <input.txt> [-o <output.csv>] [-q]")
        print("  Batch mode:  python cli.py --batch <input_dir> --out <output_dir>")
        sys.exit(1)

    args = sys.argv[1:]

    # Batch mode
    if "--batch" in args:
        batch_idx = args.index("--batch")
        input_dir = args[batch_idx + 1]
        output_dir = args[batch_idx + 2] if batch_idx + 2 < len(args) else None

        if not output_dir:
            print("Error: --batch mode requires --out <output_dir>")
            sys.exit(1)

        os.makedirs(output_dir, exist_ok=True)
        txt_files = list(Path(input_dir).glob("*.txt"))

        if not txt_files:
            print(f"No .txt files found in {input_dir}")
            sys.exit(1)

        print(f"Batch mode: found {len(txt_files)} file(s) to convert\n")

        for txt_file in txt_files:
            csv_path = Path(output_dir) / (txt_file.stem + ".csv")
            print(f"Processing: {txt_file.name}")
            try:
                convert_supergnova_to_csv(str(txt_file), str(csv_path))
            except Exception as e:
                print(f"  Error: {e}")

    else:
        # Single file mode
        input_txt = args[0]
        output_csv = None
        quiet = False

        if "-o" in args:
            oi = args.index("-o")
            output_csv = args[oi + 1]
        if "-q" in args or "--quiet" in args:
            quiet = True

        try:
            convert_supergnova_to_csv(input_txt, output_csv, skip_warnings=quiet)
        except FileNotFoundError as e:
            print(f"Error: {e}")
            sys.exit(1)


if __name__ == "__main__":
    main()
