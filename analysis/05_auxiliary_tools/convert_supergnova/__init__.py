"""Source-tree shim for the installable convert_supergnova package."""

from .src import SuperGNOVAConverter, convert_supergnova_to_csv

__version__ = "0.1.0"
__all__ = ["SuperGNOVAConverter", "convert_supergnova_to_csv"]
