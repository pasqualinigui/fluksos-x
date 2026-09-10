"""Promoção 1:1 dos oráculos shell a pytest — Fase 0, item 005 (FR-005).

Cada f0-*.sh é orquestrado via subprocess com FKX_ORACLE_NESTED=1;
f[1-9]-*.sh entra pelo mesmo caminho desde a ADR-043 (cobertura de fase).
"""

import pathlib
import re
import subprocess

import pytest

_VERIFY = pathlib.Path("scripts/verify")
# Dois padrões, uma razão (ADR-043): o literal `f0-*.sh` é congelado por
# f0-005 FR-005; `f[1-9]-*.sh` cobre as fases que ele não alcança.
ORACLES = sorted(
    p for pattern in ("f0-*.sh", "f[1-9]-*.sh") for p in _VERIFY.glob(pattern)
)


def _canon_ids(oracle: pathlib.Path) -> list[str]:
    out = subprocess.run(
        [str(oracle), "--list"],
        capture_output=True,
        text=True,
        env={"FKX_ORACLE_NESTED": "1"},
    )
    return [line.split()[0] for line in out.stdout.splitlines() if line.strip()]


@pytest.mark.harness
@pytest.mark.parametrize("oracle", ORACLES, ids=lambda p: p.name)
def test_oracle_exit_codes_and_format(oracle: pathlib.Path):
    r = subprocess.run(
        [str(oracle)], capture_output=True, text=True, env={"FKX_ORACLE_NESTED": "1"}
    )
    assert r.returncode in (0, 1), f"{oracle} exit {r.returncode} not in (0,1)"
    assert re.search(r"^(✅|🔴|⏭️) FR-\d+", r.stdout, re.M), (
        f"format mismatch in {oracle}:\n{r.stdout[:500]}"
    )


def test_oracle_list_enumerates_canon():
    for oracle in ORACLES:
        # CANON_ORDER do .sh deve casar --list
        out = subprocess.run(
            [str(oracle), "--list"],
            capture_output=True,
            text=True,
            env={"FKX_ORACLE_NESTED": "1"},
        )
        assert out.returncode == 0, f"{oracle} --list failed"
        ids = [line.split()[0] for line in out.stdout.splitlines() if line.strip()]
        assert len(ids) >= 1, f"{oracle} --list empty"
        # verifica formato FR-XXX ou SC-XXX (f0-001 tem SC-002)
        for fid in ids:
            assert re.match(r"(FR|SC)-\d+", fid), f"bad id {fid} in {oracle}"
