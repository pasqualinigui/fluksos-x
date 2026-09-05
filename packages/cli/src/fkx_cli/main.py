"""Entry point fkx (item 0.7 — callback-raiz, sem subcomandos)."""

from __future__ import annotations

import importlib.metadata as _metadata

import typer
from fkx_core.exceptions import FkxError
from rich.markup import escape

PACKAGE_NAME = "fkx-cli"

app = typer.Typer(
    help="Motor deterministico fkx — entry point (Fase 0).",
    add_completion=False,
    pretty_exceptions_show_locals=False,
    invoke_without_command=True,
)


def _version() -> str:
    try:
        return _metadata.version(PACKAGE_NAME)
    except _metadata.PackageNotFoundError as exc:
        raise FkxError("version", f"pacote {PACKAGE_NAME} nao instalado") from exc


@app.callback(invoke_without_command=True)
def _root(
    ctx: typer.Context,
    version: bool = typer.Option(False, "--version", help="Mostra a versao do pacote."),
) -> None:
    try:
        if version:
            typer.echo(_version())
            raise typer.Exit(0)
        if ctx.invoked_subcommand is None:
            typer.echo(ctx.get_help())
            raise typer.Exit(0)
    except FkxError as exc:
        typer.echo(f"erro: {escape(str(exc))}", err=True)
        raise typer.Exit(1) from exc


if __name__ == "__main__":
    app()
