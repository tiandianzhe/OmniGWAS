"""
Python wrapper for batch SMR dynamic immune single-cell analysis.

This module provides a Python interface to run SMR (Summary-based Mendelian
Randomization) analysis across multiple dynamic immune cell populations.

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
    stop_on_error: bool = False
) -> Dict[str, Any]:
    """
    Run batch SMR dynamic immune analysis from Python.

    Parameters
    ----------
    xqtl_resources : List[str]
        List of xQTL resource names (cell types + timepoints)
    out_filename : str
        Path to GWAS summary statistics RDS file
    outcome_name : str
        Name of the GWAS trait
    xqtl_type : str, optional
        Type of xQTL (default: "sc_eqtl")
    save_base_path : str, optional
        Base directory for saving results (default: ".")
    pval : float, optional
        P-value threshold (default: 5e-8)
    diff_freq_prop : float, optional
        Proportion threshold for differential frequency (default: 0.9)
    diff_freq : float, optional
        Frequency difference threshold (default: 0.2)
    ancestry : str, optional
        Population ancestry (default: "EUR")
    quick_smr : bool, optional
        Use quick SMR mode (default: True)
    smr_HEIDI_p : float, optional
        HEIDI test P-value threshold (default: 0.05)
    plot_col : str, optional
        Plot color (default: "#B4D151")
    plot_highlight_col : str, optional
        Highlight color (default: "#8680C0")
    verbose : bool, optional
        Print progress messages (default: True)
    stop_on_error : bool, optional
        Stop on first error (default: False)

    Returns
    -------
    Dict[str, Any]
        Results containing success/failed lists and summary
    """
    # Validate inputs
    if not os.path.exists(out_filename):
        raise FileNotFoundError(f"GWAS file not found: {out_filename}")

    # Create output directory
    os.makedirs(save_base_path, exist_ok=True)

    # Build R code
    resources_str = ','.join(f'"{r}"' for r in xqtl_resources)

    r_code = f'''
source("{os.path.join(os.path.dirname(__file__), '..', 'R', 'batch_smr_dynamic.R')}")

xqtl_resources <- c({resources_str})

result <- run_smr_dynamic_batch(
    xqtl_resources = xqtl_resources,
    out_filename = "{out_filename}",
    outcome_name = "{outcome_name}",
    xqtl_type = "{xqtl_type}",
    save_base_path = "{save_base_path}",
    pval = {pval},
    diff_freq_prop = {diff_freq_prop},
    diff_freq = {diff_freq},
    ancestry = "{ancestry}",
    quick_smr = {str(quick_smr).upper()},
    smr_HEIDI_p = {smr_HEIDI_p},
    plot_col = "{plot_col}",
    plot_highlight.col = "{plot_highlight_col}",
    verbose = {str(verbose).upper()},
    stop_on_error = {str(stop_on_error).upper()}
)

# Export results
write.csv(result$summary, file.path("{save_base_path}", "smr_batch_summary.csv"), row.names = FALSE)
'''

    # Write temporary R script
    temp_r_file = os.path.join(save_base_path, "_temp_smr_dynamic.R")
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
            print(f"Error running batch SMR:\n{result.stderr}", file=sys.stderr)
            raise RuntimeError(f"R script failed with code {result.returncode}")

        if verbose:
            print(result.stdout)

        return {
            "status": "completed",
            "n_resources": len(xqtl_resources),
            "output_dir": save_base_path
        }

    finally:
        # Clean up
        if os.path.exists(temp_r_file):
            os.remove(temp_r_file)


def get_default_dynamic_resources() -> List[str]:
    """
    Get default dynamic immune cell resources.

    Returns
    -------
    List[str]
        List of default xQTL resource names
    """
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
        "TN_LA", "TN_NFKB"
    ]


def parse_resources_by_celltype(
    resources: List[str]
) -> Dict[str, List[str]]:
    """
    Group resources by cell type.

    Parameters
    ----------
    resources : List[str]
        List of xQTL resource names

    Returns
    -------
    Dict[str, List[str]]
        Resources grouped by cell type
    """
    grouped = {}
    for r in resources:
        parts = r.rsplit('_', 1)
        if len(parts) == 2:
            cell_type, timepoint = parts
        else:
            cell_type = r
            timepoint = "NA"

        if cell_type not in grouped:
            grouped[cell_type] = []
        grouped[cell_type].append(timepoint)

    return grouped


def load_config(config_file: str) -> Dict[str, Any]:
    """
    Load configuration from YAML file.

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
    """Command-line interface for batch SMR dynamic analysis."""
    parser = argparse.ArgumentParser(
        description="Batch SMR dynamic immune single-cell analysis"
    )

    parser.add_argument(
        "--resources",
        nargs="+",
        help="xQTL resource names (cell_type_timepoint)"
    )
    parser.add_argument(
        "--resources-file",
        help="File containing resource names (one per line)"
    )
    parser.add_argument(
        "--default-resources",
        action="store_true",
        help="Use all default dynamic immune resources"
    )
    parser.add_argument(
        "--out-filename",
        required=True,
        help="Path to GWAS RDS file"
    )
    parser.add_argument(
        "--outcome-name",
        required=True,
        help="Name of the GWAS trait"
    )
    parser.add_argument(
        "--xqtl-type",
        default="sc_eqtl",
        help="Type of xQTL (default: sc_eqtl)"
    )
    parser.add_argument(
        "--output",
        default=".",
        help="Output directory (default: current directory)"
    )
    parser.add_argument(
        "--pval",
        type=float,
        default=5e-8,
        help="P-value threshold (default: 5e-8)"
    )
    parser.add_argument(
        "--ancestry",
        default="EUR",
        help="Population ancestry (default: EUR)"
    )
    parser.add_argument(
        "--config",
        help="YAML configuration file"
    )

    args = parser.parse_args()

    # Load config if provided
    if args.config:
        config = load_config(args.config)
        xqtl_resources = config.get("xqtl_resources", [])
        out_filename = config.get("out_filename")
        outcome_name = config.get("outcome_name")
        save_base_path = config.get("save_base_path", ".")
        xqtl_type = config.get("xqtl_type", "sc_eqtl")
        pval = config.get("pval", 5e-8)
    else:
        # Get resources
        if args.resources:
            xqtl_resources = args.resources
        elif args.resources_file:
            with open(args.resources_file, 'r') as f:
                xqtl_resources = [line.strip() for line in f if line.strip()]
        elif args.default_resources:
            xqtl_resources = get_default_dynamic_resources()
        else:
            raise ValueError("Must specify --resources, --resources-file, or --default-resources")

        out_filename = args.out_filename
        outcome_name = args.outcome_name
        save_base_path = args.output
        xqtl_type = args.xqtl_type
        pval = args.pval

    # Run analysis
    print(f"Starting batch SMR analysis for {len(xqtl_resources)} resources...")

    result = run_smr_dynamic_batch(
        xqtl_resources=xqtl_resources,
        out_filename=out_filename,
        outcome_name=outcome_name,
        xqtl_type=xqtl_type,
        save_base_path=save_base_path,
        pval=pval,
        verbose=True
    )

    print(f"\nBatch SMR analysis completed!")
    print(f"Total resources processed: {result.get('n_resources', 'N/A')}")


if __name__ == "__main__":
    main()
