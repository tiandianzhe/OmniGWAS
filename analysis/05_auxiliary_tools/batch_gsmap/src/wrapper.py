"""
Python wrapper for batch gsMap analysis.

This module provides a Python interface to run gsMap spatial transcriptomics
colocalization analysis in batch mode across multiple samples.

Author: WorkBuddy AI Assistant
Version: 1.0.0
"""

import argparse
import os
import sys
import subprocess
import json
from pathlib import Path
from typing import List, Optional, Dict, Any


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
    r_library_path: Optional[str] = None
) -> Dict[str, Any]:
    """
    Run batch gsMap analysis from Python.

    Parameters
    ----------
    sample_names : List[str]
        List of sample names to process
    sumstats_file : str
        Path to GWAS summary statistics file (.gz supported)
    trait_name : str
        Name of the GWAS trait
    h5ad_dir : str
        Directory containing h5ad spatial transcriptomics files
    annotation : str, optional
        Annotation type (default: "annotation")
    data_layer : str, optional
        Data layer type (default: "count")
    max_processes : int, optional
        Maximum number of parallel processes (default: 10)
    save_base_path : str, optional
        Base directory for saving results (default: ".")
    verbose : bool, optional
        Print progress messages (default: True)
    stop_on_error : bool, optional
        Stop execution on first error (default: False)
    r_library_path : str, optional
        Path to R library containing batch_gsmap functions

    Returns
    -------
    Dict[str, Any]
        Results containing success/failed lists and summary
    """
    # Validate inputs
    if not os.path.exists(sumstats_file):
        raise FileNotFoundError(f"Summary statistics file not found: {sumstats_file}")

    if not os.path.isdir(h5ad_dir):
        raise NotADirectoryError(f"H5AD directory not found: {h5ad_dir}")

    # Create output directory if needed
    os.makedirs(save_base_path, exist_ok=True)

    # Build R code to execute
    r_code = f'''
source("{os.path.join(os.path.dirname(__file__), '..', 'R', 'batch_gsmap.R')}")

sample_names <- c({','.join(f'"{s}"' for s in sample_names)})

result <- run_gsmap_batch(
    sample_names = sample_names,
    sumstats_file = "{sumstats_file}",
    trait_name = "{trait_name}",
    h5ad_dir = "{h5ad_dir}",
    annotation = "{annotation}",
    data_layer = "{data_layer}",
    max_processes = {max_processes},
    save_base_path = "{save_base_path}",
    verbose = {str(verbose).upper()},
    stop_on_error = {str(stop_on_error).upper()}
)

# Export as JSON for Python parsing
export_batch_results(result, output_dir = "{save_base_path}", format = "json")
'''

    # Write temporary R script
    temp_r_file = os.path.join(save_base_path, "_temp_batch_gsmap.R")
    with open(temp_r_file, 'w', encoding='utf-8') as f:
        f.write(r_code)

    try:
        # Run R script
        cmd = ['Rscript', temp_r_file]
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode != 0:
            print(f"Error running batch gsMap:\n{result.stderr}", file=sys.stderr)
            raise RuntimeError(f"R script failed with code {result.returncode}")

        if verbose:
            print(result.stdout)

        # Read results from JSON if available
        json_file = os.path.join(save_base_path, "batch_results.json")
        if os.path.exists(json_file):
            with open(json_file, 'r', encoding='utf-8') as f:
                return json.load(f)

        return {"status": "completed", "message": "Batch analysis finished"}

    finally:
        # Clean up temp file
        if os.path.exists(temp_r_file):
            os.remove(temp_r_file)


def parse_sample_names_from_dir(h5ad_dir: str, pattern: str = "*.MOSTA.h5ad") -> List[str]:
    """
    Parse sample names from h5ad files in a directory.

    Parameters
    ----------
    h5ad_dir : str
        Directory containing h5ad files
    pattern : str, optional
        File pattern to match (default: "*.MOSTA.h5ad")

    Returns
    -------
    List[str]
        List of sample names
    """
    from pathlib import Path

    h5ad_path = Path(h5ad_dir)
    sample_names = []

    for f in h5ad_path.glob(pattern):
        name = f.stem.replace(".MOSTA", "")
        sample_names.append(name)

    return sorted(sample_names)


def load_config(config_file: str) -> Dict[str, Any]:
    """
    Load batch configuration from YAML file.

    Parameters
    ----------
    config_file : str
        Path to YAML configuration file

    Returns
    -------
    Dict[str, Any]
        Configuration parameters
    """
    import yaml

    with open(config_file, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    return config


def main():
    """Command-line interface for batch gsMap analysis."""
    parser = argparse.ArgumentParser(
        description="Batch gsMap analysis for spatial transcriptomics GWAS colocalization"
    )

    parser.add_argument(
        "--samples",
        nargs="+",
        help="Sample names to process (space-separated)"
    )
    parser.add_argument(
        "--samples-file",
        help="File containing sample names (one per line)"
    )
    parser.add_argument(
        "--samples-dir",
        help="Directory containing h5ad files to auto-detect samples"
    )
    parser.add_argument(
        "--sumstats",
        required=True,
        help="Path to GWAS summary statistics file"
    )
    parser.add_argument(
        "--trait",
        required=True,
        help="Name of the GWAS trait"
    )
    parser.add_argument(
        "--h5ad-dir",
        required=True,
        help="Directory containing h5ad spatial transcriptomics files"
    )
    parser.add_argument(
        "--annotation",
        default="annotation",
        help="Annotation type (default: annotation)"
    )
    parser.add_argument(
        "--data-layer",
        default="count",
        help="Data layer type (default: count)"
    )
    parser.add_argument(
        "--max-processes",
        type=int,
        default=10,
        help="Maximum parallel processes (default: 10)"
    )
    parser.add_argument(
        "--output",
        default=".",
        help="Output directory (default: current directory)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        default=True,
        help="Print progress messages"
    )
    parser.add_argument(
        "--stop-on-error",
        action="store_true",
        help="Stop on first error"
    )
    parser.add_argument(
        "--config",
        help="YAML config file with all parameters"
    )

    args = parser.parse_args()

    # Load config if provided
    if args.config:
        config = load_config(args.config)
        sample_names = config.get("samples", [])
        sumstats_file = config.get("sumstats_file")
        trait_name = config.get("trait_name")
        h5ad_dir = config.get("h5ad_dir")
        annotation = config.get("annotation", "annotation")
        data_layer = config.get("data_layer", "count")
        max_processes = config.get("max_processes", 10)
        save_base_path = config.get("save_base_path", ".")
    else:
        # Get sample names
        if args.samples:
            sample_names = args.samples
        elif args.samples_file:
            with open(args.samples_file, 'r') as f:
                sample_names = [line.strip() for line in f if line.strip()]
        elif args.samples_dir:
            sample_names = parse_sample_names_from_dir(args.samples_dir)
        else:
            raise ValueError("Must specify --samples, --samples-file, or --samples-dir")

        sumstats_file = args.sumstats
        trait_name = args.trait
        h5ad_dir = args.h5ad_dir
        annotation = args.annotation
        data_layer = args.data_layer
        max_processes = args.max_processes
        save_base_path = args.output

    # Run analysis
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
        verbose=args.verbose,
        stop_on_error=args.stop_on_error
    )

    print(f"\nBatch analysis completed!")
    print(f"Success: {results.get('success_count', 'N/A')}")
    print(f"Failed: {results.get('failed_count', 'N/A')}")


if __name__ == "__main__":
    main()
