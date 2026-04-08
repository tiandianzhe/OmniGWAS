"""Unit tests for SuperGNOVA converter."""

import os
import sys
import tempfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
from converter import SuperGNOVAConverter, convert_supergnova_to_csv


class TestSuperGNOVAConverter:
    """Test suite for SuperGNOVAConverter class."""

    @pytest.fixture
    def sample_txt_content(self):
        """Valid SuperGNOVA TXT content."""
        return (
            "chr1\t100000\t200000\t0.5234\t0.4891\t0.0123\t0.0145\t0.0021\t0.0012\t1500\n"
            "chr1\t200000\t300000\t0.6102\t0.5876\t0.0156\t0.0178\t0.0025\t0.0008\t2000\n"
            "chr2\t100000\t200000\t0.4501\t0.4234\t0.0101\t0.0112\t0.0019\t0.0025\t1200\n"
        )

    @pytest.fixture
    def malformed_txt_content(self):
        """Malformed SuperGNOVA TXT content with inconsistent columns."""
        return (
            "chr1\t100000\t200000\t0.5234\t0.4891\t0.0123\t0.0145\t0.0021\t0.0012\t1500\n"
            "chr1\t200000\t300000\t0.6102\t0.5876\t0.0156\t0.0178\t0.0025\n"
            "chr2\t100000\t200000\t0.4501\t0.4234\t0.0101\t0.0112\t0.0019\t0.0025\t1200\n"
        )

    @pytest.fixture
    def sample_file(self, sample_txt_content):
        """Create a temporary TXT file with sample content."""
        fd, path = tempfile.mkstemp(suffix=".txt")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(sample_txt_content)
        yield path
        os.unlink(path)

    @pytest.fixture
    def malformed_file(self, malformed_txt_content):
        """Create a temporary malformed TXT file."""
        fd, path = tempfile.mkstemp(suffix=".txt")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(malformed_txt_content)
        yield path
        os.unlink(path)

    def test_convert_valid_file(self, sample_file):
        """Test conversion of a valid SuperGNOVA TXT file."""
        csv_path = sample_file.replace(".txt", ".csv")
        converter = SuperGNOVAConverter(sample_file, csv_path)
        stats = converter.convert(skip_warnings=True)

        assert stats["total_lines"] == 3
        assert stats["converted_lines"] == 3
        assert stats["skipped_lines"] == 0
        assert Path(csv_path).exists()

        with open(csv_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
            assert lines[0].strip() == "chr,start,end,rho,corr,h2_1,h2_2,var,p,m"
            assert len(lines) == 4  # header + 3 data rows

        os.unlink(csv_path)

    def test_convert_malformed_file(self, malformed_file):
        """Test that malformed rows are skipped and reported."""
        csv_path = malformed_file.replace(".txt", ".csv")
        converter = SuperGNOVAConverter(malformed_file, csv_path)
        stats = converter.convert(skip_warnings=True)

        assert stats["total_lines"] == 3
        assert stats["converted_lines"] == 2
        assert stats["skipped_lines"] == 1
        assert len(converter.skipped_lines) == 1
        assert converter.skipped_lines[0][0] == 2  # line 2 is malformed

        os.unlink(csv_path)

    def test_auto_output_path(self, sample_file):
        """Test that CSV path is auto-generated when not specified."""
        converter = SuperGNOVAConverter(sample_file)
        assert converter.csv_path == Path(sample_file).with_suffix(".csv")

    def test_file_not_found(self):
        """Test that FileNotFoundError is raised for missing input."""
        with pytest.raises(FileNotFoundError):
            SuperGNOVAConverter("nonexistent_file.txt")


class TestConvenienceFunction:
    """Test suite for the convert_supergnova_to_csv convenience function."""

    @pytest.fixture
    def sample_file(self):
        """Create a temporary sample file."""
        fd, path = tempfile.mkstemp(suffix=".txt")
        content = (
            "chr1\t100000\t200000\t0.5234\t0.4891\t0.0123\t0.0145\t0.0021\t0.0012\t1500\n"
            "chr1\t200000\t300000\t0.6102\t0.5876\t0.0156\t0.0178\t0.0025\t0.0008\t2000\n"
        )
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        yield path
        os.unlink(path)
        csv_path = path.replace(".txt", ".csv")
        if os.path.exists(csv_path):
            os.unlink(csv_path)

    def test_function_returns_stats(self, sample_file):
        """Test that convenience function returns statistics dict."""
        stats = convert_supergnova_to_csv(sample_file, skip_warnings=True)
        assert "total_lines" in stats
        assert "converted_lines" in stats
        assert "output_path" in stats
        assert stats["converted_lines"] == 2
