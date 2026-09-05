"""US2 — versao consultavel (spec 012, FR-004). Primeira execucao de --version."""

import importlib.metadata as _metadata
import re

from fkx_cli.main import app
from typer.testing import CliRunner

runner = CliRunner()


def test_version_exit_zero_so_numero() -> None:
    r = runner.invoke(app, ["--version"])
    assert r.exit_code == 0
    assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", r.output.strip()) is not None


def test_version_confere_com_declarada() -> None:
    r = runner.invoke(app, ["--version"])
    assert r.output.strip() == _metadata.version("fkx-cli")
