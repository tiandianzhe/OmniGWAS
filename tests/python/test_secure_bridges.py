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

    with pytest.raises(RuntimeError, match="did not write the expected result file"):
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

    with pytest.raises(RuntimeError, match="did not write the expected result file"):
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


@pytest.mark.parametrize("value", ["false", "true", 0, 1, None])
def test_yaml_boolean_values_are_not_coerced(value: Any) -> None:
    with pytest.raises(ValueError, match="YAML boolean"):
        gsmap._as_bool(value, "stop_on_error")
    with pytest.raises(ValueError, match="YAML boolean"):
        smr._as_bool(value, "quick_smr")
    assert gsmap._as_bool(False, "stop_on_error") is False
    assert smr._as_bool(True, "quick_smr") is True


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


@pytest.mark.parametrize(
    ("module", "result", "total_key"),
    [
        (
            gsmap,
            {"success_count": 1, "failed_count": 0, "total_samples": 1},
            "total_samples",
        ),
        (
            smr,
            {"success_count": 1, "failed_count": 0, "total_resources": 1},
            "total_resources",
        ),
    ],
)
def test_batch_clis_succeed_only_with_stable_zero_failure_counts(
    module: Any,
    result: dict[str, int],
    total_key: str,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    input_file = tmp_path / "input.rds"
    input_file.touch()
    h5ad_dir = tmp_path / "h5ad"
    h5ad_dir.mkdir()
    if module is gsmap:
        monkeypatch.setattr(module, "run_batch_gsmap", lambda **_: result)
        argv = [
            "--samples",
            "sample",
            "--sumstats",
            str(input_file),
            "--trait",
            "trait",
            "--h5ad-dir",
            str(h5ad_dir),
            "--quiet",
        ]
    else:
        monkeypatch.setattr(module, "run_smr_dynamic_batch", lambda **_: result)
        argv = [
            "--resources",
            "resource",
            "--out-filename",
            str(input_file),
            "--outcome-name",
            "trait",
            "--quiet",
        ]
    assert module.main(argv) == 0

    result["failed_count"] = 1
    assert module.main(argv) == 1

    result.pop("failed_count")
    assert module.main(argv) == 1

    result["failed_count"] = False
    assert module.main(argv) == 1

    result["failed_count"] = 0
    result[total_key] = 2
    assert module.main(argv) == 1


def test_runnable_r_sources_do_not_install_dependencies() -> None:
    root = Path("analysis/05_auxiliary_tools")
    for path in root.glob("*/R/*.R"):
        source = path.read_text(encoding="utf-8")
        assert "install.packages(" not in source, path
        assert "install_github(" not in source, path
