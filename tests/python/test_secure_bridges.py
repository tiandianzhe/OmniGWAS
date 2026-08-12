"""Regression tests for the Python to R command boundary."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any

import pytest
from batch_gsmap.src import wrapper as gsmap
from batch_smr_dynamic.src import wrapper as smr
from manhattan_plot.src import wrapper as manhattan
from utils.src import wrapper as utility

ATTACK_TEXT = '\"); stop("injected"); system("touch owned"); #\nsecond-line'


def _capture_run(monkeypatch: pytest.MonkeyPatch, module: Any) -> dict[str, Any]:
    captured: dict[str, Any] = {}

    def fake_run(command: list[str], **kwargs: Any) -> subprocess.CompletedProcess[str]:
        captured["command"] = command
        captured.update(kwargs)
        return subprocess.CompletedProcess(command, 0, stdout="", stderr="")

    monkeypatch.setattr(module.subprocess, "run", fake_run)
    return captured


def _assert_fixed_json_driver(captured: dict[str, Any], expected_driver: Path) -> dict[str, Any]:
    assert captured["command"] == ["Rscript", str(expected_driver)]
    assert "-e" not in captured["command"]
    assert captured["text"] is True
    assert captured["capture_output"] is True
    return json.loads(captured["input"])


def test_gsmap_values_remain_json_data(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    sumstats = tmp_path / "sumstats.tsv"
    sumstats.write_text("SNP\tP\nrs1\t0.1\n", encoding="utf-8")
    h5ad_dir = tmp_path / "h5ad"
    h5ad_dir.mkdir()
    captured = _capture_run(monkeypatch, gsmap)

    gsmap.run_batch_gsmap(
        sample_names=[ATTACK_TEXT],
        sumstats_file=str(sumstats),
        trait_name=ATTACK_TEXT,
        h5ad_dir=str(h5ad_dir),
        save_base_path=str(tmp_path / "results"),
        verbose=False,
    )

    payload = _assert_fixed_json_driver(captured, gsmap.R_DRIVER)
    assert payload["sample_names"] == [ATTACK_TEXT]
    assert payload["trait_name"] == ATTACK_TEXT
    assert not list(tmp_path.rglob("_temp*.R"))


def test_smr_values_remain_json_data(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    outcome = tmp_path / "outcome.rds"
    outcome.touch()
    captured = _capture_run(monkeypatch, smr)

    smr.run_smr_dynamic_batch(
        xqtl_resources=[ATTACK_TEXT],
        out_filename=str(outcome),
        outcome_name=ATTACK_TEXT,
        save_base_path=str(tmp_path / "results"),
        verbose=False,
    )

    payload = _assert_fixed_json_driver(captured, smr.R_DRIVER)
    assert payload["xqtl_resources"] == [ATTACK_TEXT]
    assert payload["outcome_name"] == ATTACK_TEXT
    assert not list(tmp_path.rglob("_temp*.R"))


def test_utility_values_remain_json_data(monkeypatch: pytest.MonkeyPatch) -> None:
    captured = _capture_run(monkeypatch, utility)
    result = utility.run_read_table("input.tsv", na_strings=ATTACK_TEXT)

    request = _assert_fixed_json_driver(captured, utility.R_DRIVER)
    assert request["operation"] == "read"
    assert request["payload"]["na_strings"] == ATTACK_TEXT
    assert result["success"] is True


def test_manhattan_uses_fixed_driver(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    input_file = tmp_path / "input.csv"
    input_file.write_text("SNP,CHR,BP,P\nrs1,1,100,0.1\n", encoding="utf-8")
    captured = _capture_run(monkeypatch, manhattan)

    manhattan.create_manhattan(
        str(input_file),
        output=str(tmp_path / "plots" / "plot.png"),
        title=ATTACK_TEXT,
    )

    request = _assert_fixed_json_driver(captured, manhattan.R_DRIVER)
    assert request["operation"] == "manhattan"
    assert request["payload"]["title"] == ATTACK_TEXT


def test_yaml_resource_lists_reject_scalar_values() -> None:
    with pytest.raises(ValueError, match="non-empty YAML list"):
        gsmap._as_string_list("sample-one", "samples")
    with pytest.raises(ValueError, match="non-empty YAML list"):
        smr._string_list("resource-one", "xqtl_resources")


def test_batch_identifiers_reject_path_traversal() -> None:
    with pytest.raises(ValueError, match="path separators"):
        gsmap._validate_path_components(["../../outside"], "sample_names")
    with pytest.raises(ValueError, match="safe path components"):
        smr._validate_path_components(["../outside"], "xqtl_resources")
    with pytest.raises(ValueError, match="unique"):
        gsmap._validate_path_components(["sample", "sample"], "sample_names")


def test_all_wrapper_cli_parsers_construct() -> None:
    assert utility.create_parser().prog == "python -m utils.src"
    assert manhattan.create_parser().prog == "python -m manhattan_plot.src"
    assert gsmap.create_parser().prog == "python -m batch_gsmap.src"
    assert smr.create_parser().prog == "python -m batch_smr_dynamic.src"


def test_runnable_r_sources_do_not_install_dependencies() -> None:
    root = Path("analysis/05_auxiliary_tools")
    for path in root.glob("*/R/*.R"):
        source = path.read_text(encoding="utf-8")
        assert "install.packages(" not in source, path
        assert "install_github(" not in source, path
