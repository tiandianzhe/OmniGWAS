"""
SuperGNOVA Result Converter

Convert SuperGNOVA TXT output files to structured CSV format.
SuperGNOVA performs genetic correlation and heritability estimation analysis.

Output columns:
    chr     - Chromosome number
    start   - Region start position
    end     - Region end position
    rho     - Genetic correlation coefficient
    corr    - Correlation estimate
    h2_1    - Heritability estimate for trait 1
    h2_2    - Heritability estimate for trait 2
    var     - Variance estimate
    p       - P-value for significance test
    m       - Number of SNPs in the region
"""

import csv
import os
import sys
from pathlib import Path
from typing import Optional, List, Tuple


class SuperGNOVAConverter:
    """Converter class for SuperGNOVA TXT to CSV transformation."""

    COLUMNS = ["chr", "start", "end", "rho", "corr", "h2_1", "h2_2", "var", "p", "m"]
    EXPECTED_COL_COUNT = 10

    def __init__(self, txt_path: str, csv_path: Optional[str] = None):
        """
        Initialize the converter.

        Parameters
        ----------
        txt_path : str
            Path to the input SuperGNOVA TXT file.
        csv_path : str, optional
            Path to the output CSV file. If None, replaces .txt with .csv.
        """
        self.txt_path = Path(txt_path)
        if not self.txt_path.exists():
            raise FileNotFoundError(f"Input file not found: {self.txt_path}")

        if csv_path:
            self.csv_path = Path(csv_path)
        else:
            self.csv_path = self.txt_path.with_suffix(".csv")

        self.skipped_lines: List[Tuple[int, str]] = []
        self.total_lines = 0
        self.converted_lines = 0

    def convert(self, skip_warnings: bool = False) -> dict:
        """
        Perform the TXT to CSV conversion.

        Parameters
        ----------
        skip_warnings : bool
            If True, suppress warning messages for malformed rows.

        Returns
        -------
        dict
            Conversion statistics including total lines, converted lines,
            skipped lines, and output path.
        """
        self.skipped_lines = []
        self.total_lines = 0
        self.converted_lines = 0

        with open(self.txt_path, "r", encoding="utf-8") as txt_file, \
             open(self.csv_path, "w", newline="", encoding="utf-8") as csv_file:

            writer = csv.writer(csv_file)
            writer.writerow(self.COLUMNS)

            for line_num, line in enumerate(txt_file, start=1):
                self.total_lines += 1
                data = line.strip().split()

                if len(data) == self.EXPECTED_COL_COUNT:
                    writer.writerow(data)
                    self.converted_lines += 1
                else:
                    self.skipped_lines.append((line_num, line.strip()))
                    if not skip_warnings:
                        print(f"Warning: Skipping malformed line {line_num}: {line.strip()[:80]}")

        return self.get_stats()

    def get_stats(self) -> dict:
        """Return conversion statistics."""
        return {
            "total_lines": self.total_lines,
            "converted_lines": self.converted_lines,
            "skipped_lines": len(self.skipped_lines),
            "output_path": str(self.csv_path),
            "input_path": str(self.txt_path),
        }

    def print_report(self) -> None:
        """Print a formatted conversion report."""
        stats = self.get_stats()
        print("\n" + "=" * 50)
        print("SuperGNOVA Conversion Report")
        print("=" * 50)
        print(f"Input file : {stats['input_path']}")
        print(f"Output file: {stats['output_path']}")
        print(f"Total rows : {stats['total_lines']}")
        print(f"Converted  : {stats['converted_lines']}")
        print(f"Skipped    : {stats['skipped_lines']}")
        print("=" * 50)

        if self.skipped_lines:
            print("\nSkipped lines (first 5):")
            for line_num, content in self.skipped_lines[:5]:
                print(f"  Line {line_num}: {content[:80]}...")
            if len(self.skipped_lines) > 5:
                print(f"  ... and {len(self.skipped_lines) - 5} more")


def convert_supergnova_to_csv(txt_path: str, csv_path: Optional[str] = None,
                               skip_warnings: bool = False) -> dict:
    """
    Convenient function to convert a SuperGNOVA TXT file to CSV.

    Parameters
    ----------
    txt_path : str
        Path to the input SuperGNOVA TXT file.
    csv_path : str, optional
        Path to the output CSV file.
    skip_warnings : bool
        Whether to suppress malformed line warnings.

    Returns
    -------
    dict
        Conversion statistics.
    """
    converter = SuperGNOVAConverter(txt_path, csv_path)
    stats = converter.convert(skip_warnings=skip_warnings)
    converter.print_report()
    return stats


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Convert SuperGNOVA TXT results to CSV format."
    )
    parser.add_argument("input", help="Input TXT file path")
    parser.add_argument("-o", "--output", help="Output CSV file path", default=None)
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Suppress warnings for malformed rows")

    args = parser.parse_args()

    try:
        convert_supergnova_to_csv(args.input, args.output, skip_warnings=args.quiet)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
