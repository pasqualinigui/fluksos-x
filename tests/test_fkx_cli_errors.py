"""US3 — erro nomeado (spec 012, FR-006/009). Primeira execucao do mapeamento."""

import importlib.metadata as _metadata

from fkx_cli import main as cli_main
from fkx_cli.main import app
from fkx_core.exceptions import FkxError
from pytest import MonkeyPatch
from typer.testing import CliRunner

runner = CliRunner()


def test_dominio_exit_1_com_causa_nomeada(monkeypatch: MonkeyPatch) -> None:
    def quebrado(_name: str) -> str:
        raise _metadata.PackageNotFoundError(_name)

    monkeypatch.setattr("fkx_cli.main._metadata.version", quebrado)
    r = runner.invoke(app, ["--version"])
    assert r.exit_code == 1
    assert "erro:" in r.output
    assert "fkx-cli" in r.output


def test_dado_dinamico_escapado_em_markup(monkeypatch: MonkeyPatch) -> None:
    def quebrado() -> str:
        raise FkxError("version", "falha em [bold]origem[/bold]")

    monkeypatch.setattr(cli_main, "_version", quebrado)
    r = runner.invoke(app, ["--version"])
    assert r.exit_code == 1
    assert "\\[" in r.output
