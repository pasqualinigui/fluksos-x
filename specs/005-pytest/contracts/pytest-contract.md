# Contract: Pytest harness — Fase 0, item 005 (0.4)

**Feature**: `005-pytest` · **Data**: 2026-08-31
**Spec**: `specs/005-pytest/spec.md` (FR-001..015) · **Research**: `docs/plan/research/f0-005-pytest.md` D1–D10
**Artefato normativo**: este contrato + `contracts/oracle-cli.md` (deste item) complementam `specs/001-.../contracts/oracle-cli.md`

Este contrato fixa o **schema TOML + layout pytest** que o item `005` introduz e que `006–014` consomem sem reescrever.

---

## 1. Onde vivem os arquivos

```
pyproject.toml                      # [dependency-groups] dev + [tool.pytest.ini_options] + [tool.coverage.*]
uv.lock                             # contém pytest 9.1.1 com hash (universal)
tests/                              # testpaths=["tests"] (raiz, não packages/*)
├── conftest.py                     # py_compile 0, mínimo (sem fixtures globais em 005)
├── test_harness_oracles.py         # FR-005: parametrizado por f0-*.sh
└── test_harness_debts.py           # FR-010: 5 casos ADR-007
scripts/verify/
├── manifest.sha256                 # FR-008: 5 linhas sha256sum 001..005
└── f0-005-pytest.sh                # FR-009..015: oráculo deste item
```

* `tests/` na raiz (não `packages/*/tests` em 005 — D2). `011`/`012` ampliam `testpaths` sem remover raiz (contrato `Transferido`).
* Sem `pytest.toml`/`pytest.ini`/`setup.cfg` separado — fonte única é `pyproject.toml` (D2, `reference/customize.html`).

---

## 2. Schema `pyproject.toml`

### 2.1 `[dependency-groups]`

```toml
[dependency-groups]
dev = ["pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

* **Restrições:**
  * Pins exatos `==` (não `>=`, não `~=`) — determinismo I, D1.
  * Tabela `dependency-groups` PEP 735, não `[tool.uv.dev-dependencies]` legado (D4, FR-002).
  * Não em `[project.dependencies]` — `dev` é local-only, `uv sync --no-dev` omite (release 013).
* **Verificação:** `python3 -c 'import tomllib; assert tomllib.load(open("pyproject.toml","rb"))["dependency-groups"]["dev"] == ["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]'`

### 2.2 `[tool.pytest.ini_options]`

```toml
[tool.pytest.ini_options]
minversion = "9.1"
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
pythonpath = ["."]
addopts = "-ra --strict-markers --strict-config"
markers = ["slow: marks tests as slow", "harness: oracle promotion tests"]
filterwarnings = ["error"]
xfail_strict = true
asyncio_mode = "strict"
asyncio_default_fixture_loop_scope = "function"
```

* **Restrições:**
  * `minversion = "9.1"` — reprova `8.x` que não entende `[tool.pytest]` (D9).
  * `testpaths = ["tests"]` — limita coleta, evita `specs/`/`scripts/` (`Q2`).
  * `addopts` contém `strict-markers` + `strict-config` — falha em marker/config desconhecido (FR-011, SC-005).
  * `filterwarnings = ["error"]` — warning vira erro (FR-011).
  * `xfail_strict = true` — `xfail` que passa vira falha (FR-010 SC-004).
  * `asyncio_mode = "strict"` — exige `@pytest.mark.asyncio` (D3).
* **Verificação:** `python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["pytest"]["ini_options"]["minversion"]=="9.1"'`

### 2.3 `[tool.coverage.*]`

```toml
[tool.coverage.run]
branch = true
source = ["tests"]
parallel = false

[tool.coverage.report]
show_missing = true
skip_covered = false
exclude_lines = ["pragma: no cover", "if TYPE_CHECKING:"]
```

* **Restrições:**
  * `branch = true` — mede branch, não só linha (D5).
  * `source = ["tests"]` em 005 (sem `packages/` ainda); `parallel = false` (sem `xdist`).
  * Sem `fail_under` em 005 — portão é `010` (D5, FR-015 negativo).
* **Verificação:** `python3 -c 'import tomllib; assert tomllib.load(open("pyproject.toml","rb"))["tool"]["coverage"]["run"]["branch"] is True'`

---

## 3. `tests/conftest.py`

```python
# conftest for 005 — no global fixtures yet
```

* **Restrições:**
  * `python -m py_compile tests/conftest.py` exit 0 (FR-004).
  * Sem `pytest_plugins` em 005; fixtures globais entram em `011`+.
  * Não criar `tests/__init__.py` (namespace package implícito).

---

## 4. `tests/test_harness_oracles.py` (FR-005, D6)

Promoção 1:1 dos oráculos shell. **Contrato de orquestração:**

```python
import pathlib, subprocess, re, pytest

ORACLES = sorted(pathlib.Path("scripts/verify").glob("f0-*.sh"))

def _canon_ids(oracle: pathlib.Path) -> list[str]:
    out = subprocess.run([str(oracle), "--list"], capture_output=True, text=True, env={"FKX_ORACLE_NESTED":"1"})
    return [line.split()[1] for line in out.stdout.splitlines() if line.strip()]

@pytest.mark.harness
@pytest.mark.parametrize("oracle", ORACLES, ids=lambda p: p.name)
def test_oracle_exit_codes_and_format(oracle: pathlib.Path):
    r = subprocess.run([str(oracle)], capture_output=True, text=True, env={"FKX_ORACLE_NESTED":"1"})
    assert r.returncode in (0, 1)  # 2 só para uso inválido (--list/--invalido)
    assert re.search(r"^(✅|🔴|⏭️) FR-\d+", r.stdout, re.M)

def test_oracle_list_enumerates_canon():
    for oracle in ORACLES:
        # CANON_ORDER do .sh deve casar --list (fonte única)
        ...
```

* **Restrições:**
  * `subprocess` sem `shell=True`, `env={"FKX_ORACLE_NESTED":"1"}` evita recursão `FR-014`.
  * `ORACLES = glob("f0-*.sh")` sorted — ordem determinística, sem `random`.
  * `returncode in (0,1)` — `2` só para `--invalido` (oracle-cli.md §2).
  * `re ^(✅|🔴|⏭️) FR-\d+` — formato `oracle-cli.md` §3 (Princípio X).

---

## 5. `tests/test_harness_debts.py` (FR-010, D7)

5 casos ADR-007, funções `test_*` coletáveis:

| Função | Assere | Mecanismo |
|---|---|---|
| `test_f0_001_runtime_lt_5s` | `<5s` | `time.monotonic()` + `subprocess`, sem `date +%s` |
| `test_f0_001_deterministic_output` | 2× byte-a-byte | `r1.stdout==r2.stdout and r1.returncode==r2.returncode` |
| `test_red_green_pair_distinct` | `red.txt≠green.txt` | `specs/005-pytest/evidence/` hash distintos |
| `test_contracts_section_exists` | seção Contratos | `grep -q "### Entregue por este item"` |
| `test_main_branch_exists` | `refs/heads/main` | `git show-ref --verify refs/heads/main` (não HEAD) |

---

## 6. Invocação

```bash
uv sync                          # instala dev group (pytest 9.1.1)
uv run pytest -q                 # harness TDD (-q override para CI; base addopts "-ra" permanece em pyproject.toml para observabilidade local)
uv run pytest --co -q            # enumera sem executar (≥9 casos)
uv run pytest --cov=tests --cov-report=term-missing  # relatório, sem --cov-fail-under em 005
uv run pytest tests/test_harness_oracles.py -v  # só promoção
```

* `pyproject.toml` `addopts = "-ra --strict-markers --strict-config"` é a base (observabilidade local, `-ra` reporta `xfail`/`xpass`); CLI `-q` em CI (`SC-006`) é override intencional para saída silenciosa — `-q` não remove `strict-*`, apenas suprime `PASSED`. Ambos coexistem: `uv run pytest -q` → addopts `-ra` + CLI `-q` (T1).
* Exit `0` conforme, `1` falha, `2+` erro uso (pytest exit-codes). CI `003` glob `f0-*.sh` inclui `f0-005` sem editar `ci.yml` (FR-012).

---

## 7. Fronteira (FR-015 negativo)

Em 005 **MUST NOT** existir:

* `[tool.ruff]` / `ruff.toml`, `[tool.mypy]` / `mypy.ini`, `lefthook.yml`, `trivy`, `packages/` com `pyproject.toml`, `pytest.toml` separado, `pytest-xdist`/`execnet` em `dev`.

Qualquer presença reprova `f0-005` (Escada).

---

## 8. Evolução para 011/012

```
pyproject.toml testpaths = ["tests"]  # 005
→ 011: testpaths = ["tests", "packages/core/tests"]  # sem remover "tests"
→ 012: testpaths = ["tests", "packages/core/tests", "packages/cli/tests"]
```

Ampliação, não remoção — `tests/` raiz permanece coletável até Fase 4.

