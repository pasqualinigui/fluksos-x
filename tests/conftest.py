# conftest for 005 — no global fixtures yet
#
# Determinismo de render CLI (ADR-030 §4, espelho de LC_ALL=C nos oráculos):
# largura de terminal pinada para que --help tenha os mesmos bytes em
# qualquer ambiente (runner resolve ~0 colunas e corta marcadores; Rich le
# COLUMNS do env, logo default nao basta — forca).
import os

os.environ["COLUMNS"] = "80"
