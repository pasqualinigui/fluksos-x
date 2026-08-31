# Data Model: MyPy 2.3.1 strict — type checker

**Feature**: `007-mypy` | **Date**: 2026-08-31
**Source**: `spec.md` FR-001..016, `research.md` D1–D10, `contracts/` (Phase 1)

---

## Entidades

### 1. MyPy strict

Configuração de type check em `pyproject.toml` `[tool.mypy]`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `python_version` | `str` | `"3.12"` | FR-002, D4 |
| `strict` | `bool` | `true` (11 flags) | FR-002, D3 |
| `warn_unused_configs` | `bool` | `true` | FR-002, D4 |
| `exclude` | `str` (regex) | `"(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"` | FR-002, D4/D8 |
| `overrides` | `list[Override]` | `module tests.*` `disallow_untyped_defs false` `disallow_untyped_calls false` `warn_return_any false` | FR-003, D4 |

**Validações:**

* `tomllib` parse `pyproject.toml` OK, sem `mypy.ini` (`! test -f mypy.ini`, FR-004).
* `uv run mypy --strict tests/` 0 com `overrides` relaxado, fora de `tests/` reprova `disallow_untyped_defs`.
* `warn_unused_configs` detecta `module = "foo.bar"` typo.

**Relações:**

* `1 1` para `MyPy cache` (mesmo `exclude`).
* `1 1` para `Manifest` (7 linhas após 007).

---

### 2. MyPy cache

Cache efêmero `.mypy_cache/` + `.dmypy.json`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `path` | `str` | `.mypy_cache/` na raiz | FR-007 |
| `dmypy` | `str` | `.dmypy.json` na raiz | FR-007 |
| `gitignored` | `bool` | `git check-ignore -q` 1 | FR-007 |
| `excluded` | `bool` | `"(?x)^\\.mypy_cache/"` em `exclude` | FR-002 |

**Validações:**

* `git ls-files | grep .mypy_cache` vazio (Lei Zero).
* `mypy --no-error-summary` determinístico.

---

### 3. Manifest de integridade (estendido)

`scripts/verify/manifest.sha256` 7 linhas (001..007) após 007.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `lines` | `int` | `7` | FR-008 |
| `files` | `list[str]` | `f0-001..007` ordem ADR-011 | FR-008 |
| `verification` | `cmd` | `sha256sum -c` 0 | FR-008 |
| `readme` | `str` | `specs/README.md` contém `007 ✅` | FR-015 |
| `tracked` | `bool` | `git ls-files --error-unmatch specs/007-mypy/spec.md` 0 | FR-016 |

---

### 4. Spec index inquebrável

`specs/README.md` + `git ls-files`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `readme` | `str` | `grep -q "007.*mypy.*✅" specs/README.md` | FR-015 |
| `tracked` | `bool` | `git ls-files --error-unmatch` 0 | FR-016 |

**Validações:**

* `specs/README.md` flat `001-007` com `007 ✅` (não `⏳`).
* `specs/007-mypy/spec.md` rastreado (não `??`).

---

### 5. Dependency-group dev (estendido)

`[dependency-groups] dev` agora com 5 entradas.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `dev` | `list[str]` | `["mypy==2.3.1","ruff==0.16.5","pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]` | FR-001 |
| `uv.lock` | `bool` | contém `mypy` `mypy_extensions` `pathspec` | FR-005/006 |

---

## Relações

```
[dependency-groups] dev ──1──> uv.lock ──1──> .mypy_cache (exclude)
      │
      ├─1──> MyPy strict ──1──> mypy --strict . (overrides tests.*)
      │
      └─1──> Manifest 7 linhas ──1──> mypy --strict determinístico
                                │
Spec index ──1──> git ls-files (commit inquebrável)
```

## Ciclo de vida

* **Criação:** 007 cria `[tool.mypy]` + `mypy==2.3.1` em `dev` + `.mypy_cache` (via `mypy --strict`).
* **Mutação:** `mypy.ini` nunca criado (fonte única); `exclude` só acrescenta, não remove; `overrides` só para `tests.*`.
* **Idempotência:** `mypy --strict` segunda vez não altera cache hash.

## Volume / escala

* `tests/` 12 arquivos, `mypy --strict` <2s, `f0-007` 12–16 asserções <5s.
* `mypy` cache `.mypy_cache/` <5MB, ignorado.
