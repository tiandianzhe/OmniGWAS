"""
manhattan_plot module for OmniGWAS
Python wrapper for R-based Manhattan plot generation
"""

from .wrapper import create_manhattan, create_qq, main

__version__ = "0.1.0"
__author__ = "OmniGWAS contributors"
__all__ = ["create_manhattan", "create_qq", "main"]
