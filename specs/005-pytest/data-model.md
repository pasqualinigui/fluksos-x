# Data Model: Pytest 9.1.1 — harness TDD

**Feature**: `005-pytest` | **Date**: 2026-08-31
**Source**: `spec.md` FR-001..015, `research.md` D1–D10, `contracts/` (Phase 1)

---

## Entidades

### 1. Harness pytest

O verificador TDD do motor. Vive em `pyproject.toml` + `tests/` + `uv.lock`. Único ponto de verdade para `pytest` pinado.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `dependency_groups_dev` | `list[str]` | Exato `["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]`, PEP 735, local-only | FR-001, D1/D4 |
| `minversion` | `str` | `"9.1"` em `[tool.pytest.ini_options]` | FR-003, D9 |
| `testpaths` | `list[str]` | `["tests"]` em 005; ampliado para `["tests","packages/core/tests"]` só em 011 sem remover raiz | FR-003, D2 |
| `python_files` | `list[str]` | `["test_*.py"]` | FR-003 |
| `python_classes` | `list[str]` | `["Test*"]` | FR-003 |
| `python_functions` | `list[str]` | `["test_*"]` | FR-003 |
| `pythonpath` | `list[str]` | `["."]` | FR-003 |
| `addopts` | `str` | `"-ra --strict-markers --strict-config"` | FR-003, D9 |
| `markers` | `list[str]` | ao menos `["slow","harness"]` registrados | FR-003 |
| `filterwarnings` | `list[str]` | `["error"]` | FR-003 |
| `xfail_strict` | `bool` | `true` | FR-003 |
| `asyncio_mode` | `enum` `strict\|auto` | `strict` | FR-003, D3 |
| `asyncio_default_fixture_loop_scope` | `enum` | `function` | FR-003, D3 |
| `coverage_branch` | `bool` | `true` em `[tool.coverage.run]` | FR-003, D5 |
| `coverage_show_missing` | `bool` | `true` em `[tool.coverage.report]` | FR-003 |

**Validações:**

* `pyproject.toml` TOML válido (`tomllib.load` 0), sem `pytest.toml` separado (`! test -f pytest.toml`, FR-004).
* `tests/conftest.py` `py_compile` 0 (FR-004).
* `uv lock --check` 0 quando `uv` presente (FR-006).
* `addopts` contém `strict-markers` ⇒ `pytest` falha em marker typo (FR-011, SC-005).

**Relações:**

* `1 N` para `Oracle promotion` (cada `test_*` parametriza N oráculos).
* `1 1` para `Manifest` (pytest assere `sha256sum -c` via `test_harness_debts.py`).
* `1 1` para `Dependency-group dev` (fonte de `pytest`).

---

### 2. Manifest de integridade

Arquivo único `scripts/verify/manifest.sha256` que congela todos os oráculos convergidos.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `path` | `str` | `scripts/verify/manifest.sha256` | FR-008, ADR-015a |
| `lines` | `list[Line]` | 5 linhas em 005, ordem execução `001..005` (ADR-011) | FR-008 |
| `Line.sha256` | `str[64 hex]` | `/^[0-9a-f]{64}$/` | FR-008 |
| `Line.sep` | `str` | `"␣␣"` dois espaços (canônico `sha256sum`) | FR-008 |
| `Line.file` | `str` | `scripts/verify/f0-NNN-<slug>.sh` | FR-008 |
| `verification` | `cmd` | `sha256sum -c manifest.sha256` exit 0 | FR-008 |

**Valores congelados (re-medidos 2026-08-31):**

```
63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22  scripts/verify/f0-001-foundation.sh
406d72528ddebba417887a65f553c99d9c7df8982fb2b72672904b3ec09386a7  scripts/verify/f0-002-constitution.sh
d10c61e8623fcf3f7c706ab8ca7387303c2d5282da0afaee50bf5c6401b6f7d4  scripts/verify/f0-003-ci-minimo.sh
3db36208b4e13fb24bace3aaa3247224f163ca02a070d8b15e64084b1bafd88e  scripts/verify/f0-004-uv-workspace.sh
<hash-005>  scripts/verify/f0-005-pytest.sh   # calculado em Fase C
```

**Validações:**

* `sha256sum -c` 0 (FR-008, SC-004).
* Aditivo: uma linha por oráculo, nunca remove linha anterior (ADR-015a).
* Diverge 1 byte ⇒ `FAILED` nomeando hash (FR-008).

---

### 3. Oracle promotion

Teste pytest que orquestra um `.sh` sem reescrevê-lo.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `oracle_path` | `Path` | `scripts/verify/f0-*.sh` sorted | FR-005, D6 |
| `canon_ids` | `list[str]` | `oracle --list` split `FR-XXX` vs `CANON_ORDER` | FR-005 |
| `env` | `dict` | `{"FKX_ORACLE_NESTED":"1"}` sem `shell=True` | FR-005, D6 |
| `returncode` | `int` | `0` conforme / `1` violação / `2` uso | FR-005, oracle-cli.md |
| `stdout_regex` | `str` | `r"^(✅|🔴|⏭️) FR-\d+"` multiline | FR-005 |
| `parametrize` | `pytest.mark` | `@pytest.mark.harness @parametrize("oracle", ORACLES)` | FR-005 |

**Validações:**

* `pytest --co -q` lista ≥1 caso por oráculo (FR-005, SC-002).
* Mapa FR não-identidade em `contracts/oracle-cli.md` (ADR-015b), não silencioso.

---

### 4. Test debt (ADR-007)

5 casos que pagam SC-003/SC-004/SC-007/FR-001 do item `001`.

| Teste | Assere | Mecanismo | Origem |
|---|---|---|---|
| `test_f0_001_runtime_lt_5s` | `<5s` empírico | `time.monotonic()` + `subprocess` + `EPOCHSECONDS` | FR-010/014, D7 |
| `test_f0_001_deterministic_output` | 2× byte-a-byte | `cmp` stdout+returncode | FR-010/014, D7 |
| `test_red_green_pair_distinct` | `red.txt≠green.txt` | `pathlib` + `hash` distintos em `specs/005-pytest/evidence/` | FR-010, SC-004 |
| `test_contracts_section_exists` | seção Contratos | `grep -q "### Entregue por este item"` em `spec.md` | FR-010, SC-007 |
| `test_main_branch_exists` | `refs/heads/main` | `git show-ref --verify refs/heads/main` | FR-010, D7 |

**Validações:**

* Todos em `tests/test_harness_debts.py`, funções `test_*` coletáveis (FR-010).
* Sem `date +%s` (fork), sem `sleep` (D7/B2).

---

### 5. Dependency-group dev (PEP 735)

Grupo de deps local-only, não publicado.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `table` | `str` | `[dependency-groups]` (não `[tool.uv.dev-dependencies]` legado) | FR-001, D4 |
| `dev` | `list[str]` | exato 3 pins `pytest==9.1.1` etc. | FR-001 |
| `sync_default` | `bool` | `true` (`uv sync` instala `dev` sem flag) | FR-006 |
| `no_dev_flag` | `str` | `uv sync --no-dev` omite (release `013`) | FR-006 |

**Validações:**

* `! grep -q '\[tool.uv.dev-dependencies\]' pyproject.toml` (FR-002).
* `uv.lock` contém `pytest` hash (FR-006).

---

## Relações entre entidades

```
Dependency-group dev  ──1──>  uv.lock  ──1──>  .venv (pytest 9.1.1)
        │
        └─1──>  Harness pytest  ──1──>  Oracle promotion (N)
                                           │
Harness pytest ──1──>  Manifest (sha256sum -c)
       │
       └─1──>  Test debt (5 casos)
```

## Regras de ciclo de vida

* **Criação:** `005` cria `tests/` + `manifest.sha256` (Fase C). `011`/`012` ampliam `testpaths`, não removem `tests/`.
* **Mutação:** `manifest` só acrescenta linha (aditivo); hash diverge ⇒ ADR, não `sed`.
* **Destruição:** `tests/` nunca removido; `manifest` nunca removido.

## Volume / escala

* 4 oráculos `001..004` → 4 casos parametrizados; 5 dívidas → 5 casos; total ~9 `test_*` em 005.
* 91 asserts bash herdados via `subprocess` + 12–16 asserts `f0-005` nativos.
* `pytest -q` <5s; `sha256sum -c` <1s.
