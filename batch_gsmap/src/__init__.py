"""
batch_gsmap: Batch gsMap spatial transcriptomics GWAS colocalization analysis.

This module provides tools for running gsMap analysis across multiple
spatial transcriptomics samples in batch mode.

Example:
    >>> from batch_gsmap.src import wrapper
    >>> wrapper.run_batch_gsmap(
    ...     sample_names=["E9.5_E1S1", "E10.5_E1S1"],
    ...     sumstats_file="GWAS.sumstats.gz",
    ...     trait_name="NAFLD",
    ...     h5ad_dir="/data/ST/",
    ...     save_base_path="/results/"
    ... )
"""

from .wrapper import (
    run_batch_gsmap,
    parse_sample_names_from_dir,
    load_config,
    main as cli_main
)

__all__ = [
    "run_batch_gsmap",
    "parse_sample_names_from_dir",
    "load_config",
    "cli_main"
]
