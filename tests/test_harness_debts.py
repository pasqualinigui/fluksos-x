"""5 dívidas ADR-007 — Fase 0, item 005 (FR-010).

Cobre SC-003 tempo, SC-003 determinismo, SC-004 red→green, SC-007 contratos, FR-001 branch.
"""

import pathlib
import subprocess
import time


def test_f0_001_runtime_lt_5s():
    oracle = pathlib.Path("scripts/verify/f0-001-foundation.sh")
    start = time.monotonic()
    subprocess.run([str(oracle)], capture_output=True, env={"FKX_ORACLE_NESTED": "1"})
    elapsed = time.monotonic() - start
    assert elapsed < 5.0, f"f0-001 took {elapsed:.2f}s >=5s"


def test_f0_001_deterministic_output():
    oracle = pathlib.Path("scripts/verify/f0-001-foundation.sh")
    r1 = subprocess.run([str(oracle)], capture_output=True, text=True)
    r2 = subprocess.run([str(oracle)], capture_output=True, text=True)
    assert r1.stdout == r2.stdout, "determinismo falhou: stdout divergiu"
    assert r1.returncode == r2.returncode, "determinismo falhou: returncode divergiu"


def test_red_green_pair_distinct():
    # Em 005, verifica que evidence/red.txt e green.txt serão distintos quando existirem;
    # por enquanto, verifica que specs/005-pytest/evidence/red.txt existe e green ainda não, ou ambos existem e são distintos.
    red = pathlib.Path("specs/005-pytest/evidence/red.txt")
    green = pathlib.Path("specs/005-pytest/evidence/green.txt")
    assert red.exists(), "red.txt ausente — TDD vermelho não registrado"
    # green may not exist yet in red phase; if exists, must be distinct
    if green.exists():
        assert red.read_bytes() != green.read_bytes(), (
            "red.txt e green.txt idênticos — vermelho→verde não distinto"
        )
        assert red.stat().st_size > 0 and green.stat().st_size > 0


def test_contracts_section_exists():
    spec = pathlib.Path("specs/005-pytest/spec.md")
    assert spec.exists()
    text = spec.read_text(encoding="utf-8")
    assert "### Entregue por este item" in text, "seção Entregue por este item ausente"
    assert "### Transferido a itens posteriores" in text, "seção Transferido ausente"


def test_main_branch_exists():
    # FR-001 lacuna 5: mede refs/heads/main, não HEAD
    r = subprocess.run(
        ["git", "show-ref", "--verify", "refs/heads/main"],
        capture_output=True,
    )
    assert r.returncode == 0, (
        "refs/heads/main não existe — FR-001 deve medir branch, não HEAD"
    )
