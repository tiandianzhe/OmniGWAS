"""Functional tests that execute both Python and R."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest
from manhattan_plot.src.wrapper import create_manhattan, create_qq
from utils.src.wrapper import run_read_table


def _r_has(packages: list[str]) -> bool:
    if not shutil.which("Rscript"):
        return False
    expression = " && ".join(
        f'requireNamespace("{package}", quietly=TRUE)' for package in packages
    )
    result = subprocess.run(
        ["Rscript", "-e", f"quit(status=if ({expression}) 0 else 1)"],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode == 0


@pytest.mark.integration
def test_json_stdin_prevents_r_source_injection(tmp_path: Path) -> None:
    if not _r_has(["jsonlite"]):
        pytest.skip("R and jsonlite are required")
    input_file = tmp_path / "input.tsv"
    input_file.write_text("SNP\tP\nrs1\t0.05\n", encoding="utf-8")
    attack = '\"); stop("injected"); #\nnot-code'

    result = run_read_table(str(input_file), sep="tab", na_strings=attack)

    assert result["success"] is True, result["error"]
    assert "ROWS: 1" in result["output"]
    assert not (tmp_path / "owned").exists()


@pytest.mark.integration
def test_plotting_bridge_creates_real_files(tmp_path: Path) -> None:
    packages = ["jsonlite", "data.table", "dplyr", "ggplot2", "ggrepel", "scales"]
    if not _r_has(packages):
        pytest.skip("The locked R plotting environment is required")
    input_file = tmp_path / "gwas.csv"
    input_file.write_text(
        "SNP,CHR,BP,P\nrs1,1,100,0.5\nrs2,1,200,0.001\nrs3,2,100,0.02\n",
        encoding="utf-8",
    )
    manhattan_output = tmp_path / "manhattan.png"
    qq_output = tmp_path / "qq.png"

    create_manhattan(str(input_file), output=str(manhattan_output), threshold=0.05)
    create_qq(str(input_file), output=str(qq_output))

    assert manhattan_output.stat().st_size > 0
    assert qq_output.stat().st_size > 0
