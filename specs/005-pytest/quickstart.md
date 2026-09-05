# Quickstart: Pytest 9.1.1 — harness TDD

**Feature**: `005-pytest` · **Branch**: `005-pytest` · **Date**: 2026-08-31
**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md)

Guia de **validação** (não implementação). Cada cenário roda em clone limpo e prova um `FR`/`SC`. Use como `make quickstart` manual.

---

## Pré-requisitos

```bash
python3 --version  # >=3.12,<3.14 (local 3.12.3, runner 3.12.14)
uv --version       # 0.12.7 (local 0.12.1 converge via `uv self update`)
git --version
sha256sum --version
```

---

## Cenário 1 — Clone limpo obtém pytest verde (SC-001, FR-001/006)

```bash
# já em repo com 004 verde
uv add --dev pytest==9.1.1 pytest-asyncio==1.4.0 pytest-cov==7.1.0
uv sync
uv run python -c "import pytest; print(pytest.__version__)"  # → 9.1.1
uv run pytest -q  # → X passed
python3 -c 'import tomllib; assert tomllib.load(open("pyproject.toml","rb"))["dependency-groups"]["dev"] == ["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]'
grep -q 'pytest==9.1.1' uv.lock && echo "uv.lock contém pytest"
```

**Esperado:** `pyproject.toml` `[dependency-groups] dev` exato, `uv.lock` com hash, `.venv` com `pytest 9.1.1`, sem `pytest.toml` separado (`! test -f pytest.toml`).

---

## Cenário 2 — Coleção e markers strict (SC-002, FR-003/004)

```bash
cat pyproject.toml | grep -A2 "tool.pytest"
uv run pytest --co -q           # → lista ≥5 casos (4 oráculos + 5 dívidas parametrizadas)
uv run pytest --co -q | grep -q harness && echo "marker harness registrado"

# injeta marker typo
echo 'import pytest
@pytest.mark.harnes
def test_typo(): pass' > /tmp/test_typo.py
cp /tmp/test_typo.py tests/test_typo.py
uv run pytest -q 2>&1 | grep -q "Unknown marker" && echo "strict-markers reprova typo"
rm tests/test_typo.py
```

**Esperado:** `testpaths=["tests"]` só coleta `tests/`, não `specs/`; `async def test_x` sem `@pytest.mark.asyncio` em `strict` → `FAILED` (não silencioso).

---

## Cenário 3 — Promoção 1:1 dos oráculos (SC-002, FR-005/011)

```bash
uv run pytest tests/test_harness_oracles.py -v  # → f0-001..004 cada como caso
uv run pytest --co -q | grep f0-001 && echo "f0-001 parametrizado"

# quebra 1 oráculo e vê FAILED nomeando FR
chmod -x scripts/verify/f0-001-foundation.sh
uv run pytest -q 2>&1 | grep -q "FR-001" && echo "FAILED nomeia FR-001"
chmod +x scripts/verify/f0-001-foundation.sh
```

**Esperado:** `subprocess` com `FKX_ORACLE_NESTED=1`, `returncode in (0,1)`, `re ^(✅|🔴|⏭️) FR-\d+`.

---

## Cenário 4 — Manifest e integridade (SC-004, FR-008/009)

```bash
sha256sum scripts/verify/f0-*.sh  # → 63412ca7…, 406d72…, d10c61…, 3db362…, <hash-005>
cat scripts/verify/manifest.sha256  # → 5 linhas
sha256sum -c scripts/verify/manifest.sha256  # → OK exit 0
# diverge 1 byte
cp scripts/verify/f0-001-foundation.sh /tmp/bak.sh
echo "# bump" >> scripts/verify/f0-001-foundation.sh
sha256sum -c scripts/verify/manifest.sha256 && echo "deveria reprovar" || echo "reprova com hash divergente"
mv /tmp/bak.sh scripts/verify/f0-001-foundation.sh
scripts/verify/f0-005-pytest.sh --quiet  # → self-check f0-001..004 todos
```

**Esperado:** `manifest.sha256` 5 linhas, `sha256sum -c` 0, edição 1 byte → `FAILED` com hash, `f0-005 --quiet` roda `f0-001..004 --quiet` todos (não subconjunto).

---

## Cenário 5 — Dívidas ADR-007 e CONVERGE (SC-003, FR-010/013/014)

```bash
uv run pytest tests/test_harness_debts.py -v  # → 5 casos nomeados PASS
# mede <5s
time uv run pytest -q  # → <5s
python3 - << 'PY'
import subprocess, time
start=time.monotonic()
subprocess.run(["scripts/verify/f0-001-foundation.sh"], env={"FKX_ORACLE_NESTED":"1"})
print("elapsed", time.monotonic()-start, "<5s?", time.monotonic()-start < 5)
PY
# CONVERGE
grep -c "\[ \]" specs/005-pytest/tasks.md  # → 0
```

**Esperado:** `test_f0_001_runtime_lt_5s` usa `time.monotonic`/`EPOCHSECONDS` (não `date`), `test_deterministic_output` 2× `cmp` idêntico, `test_main_branch_exists` usa `git show-ref --verify refs/heads/main`.

---

## Cenário 6 — CI glob e fronteira (SC-006/008, FR-012/015)

```bash
grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml && echo "CI glob presente"
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && echo "harness local inclui f0-005"

# fronteira: deve NÃO existir
! grep -q '\[tool.ruff\]' pyproject.toml && echo "sem ruff OK"
! test -f pytest.toml && echo "sem pytest.toml OK"
! grep -q xdist pyproject.toml && echo "sem xdist OK"
! test -d packages && echo "sem packages OK"

# injeção ruído
touch pytest.toml
scripts/verify/f0-005-pytest.sh 2>&1 | grep -q "FR-004" && echo "FR-004 reprova pytest.toml"
rm pytest.toml
```

**Esperado:** CI inclui `f0-005` sem editar `ci.yml`; `f0-005` reprova `ruff`/`mypy`/`lefthook`/`packages/`/`xdist`/`pytest.toml` (Escada).

---

## Validação completa em um comando

```bash
uv run pytest -q && \
sha256sum -c scripts/verify/manifest.sha256 && \
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && \
! test -f pytest.toml && \
grep -q 'testpaths.*tests' pyproject.toml && \
echo "quickstart OK = contracts satisfeitos"
```

**Todos `OK` ⇒ `contracts/pytest-contract.md` §7 + `spec.md` SC-001..008 satisfeitos.**

---

## Troubleshooting

| Sintoma | Causa | Fix |
|---|---|---|
| `uv lock --check` falha | `uv.lock` sem `pytest` | `uv sync` sem `--locked` em 005 (D6) |
| `Unknown marker 'harnes'` não reprova | `strict-markers` ausente | Verificar `addopts` contém `strict-markers` (FR-003) |
| `async def` sem marker passa | `asyncio_mode=auto` | Mudar para `strict` (FR-003) |
| `pytest.toml` esconde `pyproject.toml` | `pytest.toml` presente | `rm pytest.toml` (FR-004) |
| `sha256sum -c` falha com `*` | Formato binário vs texto | Usar dois espaços `␣␣` (FR-008) |
| `uv 0.12.1` falha `uv_build>=0.12.7` | Pin local desatualizado | `uv self update` |
