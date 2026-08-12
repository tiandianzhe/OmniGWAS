"""Unit tests for SuperGNOVA converter."""

import os
import tempfile
from pathlib import Path

import pytest
from convert_supergnova import SuperGNOVAConverter, convert_supergnova_to_csv


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

    def test_repository_fixture_matches_expected_output(self, tmp_path):
        """Keep the public validation fixture deterministic."""
        module_root = Path(__file__).parent.parent
        input_path = module_root / "example" / "example_data.txt"
        expected_path = module_root / "example" / "expected_output.csv"
        output_path = tmp_path / "output.csv"

        SuperGNOVAConverter(str(input_path), str(output_path)).convert(
            skip_warnings=True
        )

        assert output_path.read_bytes() == expected_path.read_bytes()

    def test_formula_like_cells_are_skipped_but_signed_numbers_are_allowed(
        self, tmp_path
    ):
        """Prevent active spreadsheet formulas without rejecting negative estimates."""
        input_path = tmp_path / "input.txt"
        output_path = tmp_path / "output.csv"
        input_path.write_text(
            "chr1 1 2 -0.5 +0.2 0.1 0.1 0.1 0.05 10\n"
            "chr1 1 2 =HYPERLINK(unsafe) 0.2 0.1 0.1 0.1 0.05 10\n",
            encoding="utf-8",
        )

        stats = SuperGNOVAConverter(str(input_path), str(output_path)).convert(
            skip_warnings=True
        )

        assert stats["converted_lines"] == 1
        assert stats["skipped_lines"] == 1
        assert "=HYPERLINK" not in output_path.read_text(encoding="utf-8")


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

    def test_quiet_mode_never_echoes_rejected_input(self, tmp_path, capsys):
        """Do not leak malformed source rows when warning output is suppressed."""
        marker = "private-study-marker"
        input_path = tmp_path / "input.txt"
        input_path.write_text(f"{marker} only-two-fields\n", encoding="utf-8")

        stats = convert_supergnova_to_csv(
            str(input_path),
            str(tmp_path / "output.csv"),
            skip_warnings=True,
        )

        assert stats["skipped_lines"] == 1
        assert marker not in capsys.readouterr().out
