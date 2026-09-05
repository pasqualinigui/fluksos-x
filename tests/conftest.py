# conftest for 005 — no global fixtures yet
#
# Determinismo de render CLI (ADR-030 §4, espelho de LC_ALL=C nos oráculos):
# largura de terminal pinada para que --help tenha os mesmos bytes em
# qualquer ambiente (runner resolve ~0 colunas e corta marcadores; Rich le
# COLUMNS do env, logo default nao basta — forca).
import os
import re

os.environ["COLUMNS"] = "80"

_ANSI = re.compile(r"\x1b\[[0-9;]*m")


def strip_ansi(text: str) -> str:
    """Remove sequências ANSI (Typer força terminal no CI: spans de estilo
    quebram os marcadores em `-` + `-help`; o contrato é sobre conteúdo)."""
    return _ANSI.sub("", text)
