"""
batch_smr_dynamic: Batch SMR dynamic immune single-cell analysis.

This module provides tools for running SMR (Summary-based Mendelian Randomization)
analysis across multiple dynamic immune cell populations in batch mode.

Example:
    >>> from batch_smr_dynamic.src import wrapper
    >>> wrapper.run_smr_dynamic_batch(
    ...     xqtl_resources=["TN_0h", "TN_16h", "TN_40h"],
    ...     out_filename="GWAS.rds",
    ...     outcome_name="NAFLD",
    ...     save_base_path="/results/"
    ... )
"""

from .wrapper import (
    run_smr_dynamic_batch,
    get_default_dynamic_resources,
    parse_resources_by_celltype,
    load_config,
    main as cli_main
)

__all__ = [
    "run_smr_dynamic_batch",
    "get_default_dynamic_resources",
    "parse_resources_by_celltype",
    "load_config",
    "cli_main"
]
