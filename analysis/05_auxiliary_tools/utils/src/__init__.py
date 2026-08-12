"""Python API for the OmniGWAS R utility module."""

from .wrapper import (
    main,
    run_batch_convert,
    run_clean_compress,
    run_convert_numeric,
    run_export_excel,
    run_export_rds,
    run_export_txt,
    run_quick_clean_gwas,
    run_read_table,
    run_rename_columns,
)

__version__ = "0.1.0"
__all__ = [
    "main",
    "run_batch_convert",
    "run_clean_compress",
    "run_convert_numeric",
    "run_export_excel",
    "run_export_rds",
    "run_export_txt",
    "run_quick_clean_gwas",
    "run_read_table",
    "run_rename_columns",
]
