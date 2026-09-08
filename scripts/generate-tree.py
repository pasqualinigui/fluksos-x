#!/usr/bin/env python3
"""Emite o esqueleto de docs/tree.md a partir do indice git (016, FR-002/003).

Uso: python3 scripts/generate-tree.py   (somente stdout, sem escrita)
Determinismo: sorted() por code points + git ls-files; 2 execucoes => bytes iguais.
Portabilidade: stdlib puro (subprocess, sys); sem `tree`, sem tokenizador (D5).
"""

import shutil
import subprocess
import sys


def tracked_paths() -> list[str]:
    # S607: caminho resolvido em runtime (nunca literal parcial no call).
    git = shutil.which("git") or "git"
    out = subprocess.run(
        [git, "ls-files"],
        capture_output=True,
        text=True,
        check=False,
    )
    if out.returncode != 0:
        print("generate-tree: git ls-files falhou", file=sys.stderr)
        sys.exit(1)
    paths = sorted(p for p in out.stdout.splitlines() if p)
    return paths


def main() -> None:
    for path in tracked_paths():
        sys.stdout.write(path + "\n")


if __name__ == "__main__":
    main()
