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


def _audit_gap(readme: pathlib.Path, audit_dir: pathlib.Path) -> tuple[int, int, int]:
    # Trava ADR-027: conta por máquina, nunca por memória.
    # Retorna (convergidas, cobertas, descobertas).
    import re

    converged = sum(
        1
        for line in readme.read_text(encoding="utf-8").splitlines()
        if re.match(r"^\| `0", line) and "✅" in line
    )
    covered = 0
    for report in audit_dir.glob("f0-audit-*-*.md"):
        text = report.read_text(encoding="utf-8")
        if "Veredito" in text and "Achados" in text and "Destino" in text:
            m = re.search(r"f0-audit-\d+-(\d+)", report.name)
            if m:
                covered = max(covered, int(m.group(1)))
    return converged, covered, converged - covered


def test_audit_cadence():
    # Estado vivo: falha quando >=4 specs convergidas sem relatório cobrindo.
    converged, covered, gap = _audit_gap(
        pathlib.Path("specs/README.md"), pathlib.Path("docs/plan/audit")
    )
    assert gap < 4, (
        f"AUDIT DUE: {converged} convergidas, cobertura até {covered} "
        f"({gap}/4 sem relatório) — executar auditoria não-item antes de prosseguir (ADR-027)"
    )


def test_audit_cadence_detects_uncovered_range(tmp_path):
    # Prova 🔴→🟢 do detector sobre fixtures (repo jamais avermelha):
    # 4 convergidas sem relatório DEVEM ser detectadas.
    readme = tmp_path / "README.md"
    readme.write_text(
        "| `009` | **0.5** | F0 | X | ✅ concluída (`aaa1111`) |\n"
        "| `010` | **0.14** | F0 | X | ✅ concluída (`bbb2222`) |\n"
        "| `011` | **0.6** | F0 | X | ✅ concluída (`ccc3333`) |\n"
        "| `012` | **0.7** | F0 | X | ✅ concluída (`ddd4444`) |\n",
        encoding="utf-8",
    )
    audit_dir = tmp_path / "audit"
    audit_dir.mkdir()
    _, _, gap = _audit_gap(readme, audit_dir)
    assert gap >= 4, "detector cego: 4 descobertas sem relatório e gap < 4"
