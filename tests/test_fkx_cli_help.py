"""US1 — ajuda instalavel (spec 012, FR-003/005). TDD: reprova sem o modulo."""

from fkx_cli.main import app
from typer.testing import CliRunner

from tests.conftest import strip_ansi

runner = CliRunner()


def test_help_exit_zero_com_marcadores() -> None:
    r = runner.invoke(app, ["--help"])
    assert r.exit_code == 0
    assert "--help" in strip_ansi(r.output)
    assert "--version" in strip_ansi(r.output)


def test_sem_argumentos_equivale_a_help() -> None:
    r = runner.invoke(app, [])
    assert r.exit_code == 0
    assert "--version" in strip_ansi(r.output)


def test_opcao_invalida_exit_2_com_dica() -> None:
    r = runner.invoke(app, ["--nope"])
    assert r.exit_code == 2
    assert "--help" in strip_ansi(r.output)
