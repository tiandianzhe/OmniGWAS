"""convert_supergnova: Convert SuperGNOVA TXT results to CSV format."""

__version__ = "0.1.0"
__author__ = "Dianzhe Tian"
__email__ = "tiandianzhe@outlook.com"

from .converter import SuperGNOVAConverter, convert_supergnova_to_csv

__all__ = ["SuperGNOVAConverter", "convert_supergnova_to_csv"]
