# Data Model: Ruff 0.16.5 — linter + formatter

**Feature**: `006-ruff` | **Date**: 2026-08-31
**Source**: `spec.md` FR-001..014, `research.md` D1–D10, `contracts/` (Phase 1)

---

## Entidades

### 1. Ruff linter

Configuração de lint em `pyproject.toml` `[tool.ruff.lint]`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `select` | `list[str]` | `["E","F","W","C90"]` exato | FR-003, D3 |
| `extend-select` | `list[str]` | `["I","UP","B","SIM","S","C4","A","RUF"]` | FR-003 |
| `ignore` | `list[str]` | `["E501","S101","S603"]` | FR-003 |
| `per-file-ignores` | `dict[str, list[str]]` | `{"tests/**/*": ["S101","S603"]}` | FR-003 |
| `line-length` | `int` | `88` em `[tool.ruff]` | FR-002 |
| `target-version` | `str` | `"py312"` | FR-002 |
| `exclude` | `list[str]` | `[".git",".hg",".mypy_cache",".pytest_cache",".ruff_cache",".venv", ...]` | FR-002 |

**Validações:**

* `tomllib` parse `pyproject.toml` OK, sem `ruff.toml` (`! test -f ruff.toml`, FR-005).
* `uv run ruff check --output-format=concise` 0 em `tests/` com `S101`/`S603` ignorados, mas reprovaria em `packages/` sem `per-file-ignores`.

**Relações:**

* `1 1` para `Ruff formatter` (mesmo `pyproject.toml` `[tool.ruff]`).
* `1 1` para `Manifest` (6 linhas após 006).
* `1 1` para `Ruff cache`.

---

### 2. Ruff formatter

Configuração de format em `[tool.ruff.format]`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `quote-style` | `enum` `double/single` | `"double"` | FR-004 |
| `indent-style` | `enum` `space/tab` | `"space"` | FR-004 |
| `line-ending` | `enum` `auto/lf/crlf` | `"auto"` | FR-004 |
| `docstring-code-format` | `bool` | `false` | FR-004 |
| `docstring-code-line-length` | `str` | `"dynamic"` | FR-004 |

**Validações:**

* `uv run ruff format --check --diff .` 0 em repo conforme, 1 com `x='a'` (FR-009).
* `uv run ruff format .` idempotente `sha256sum` (FR-010).

---

### 3. Ruff cache

Cache efêmero `.ruff_cache/` + `exclude`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `path` | `str` | `.ruff_cache/` na raiz | FR-007 |
| `gitignored` | `bool` | `git check-ignore -q .ruff_cache` 0 | FR-007 |
| `excluded` | `bool` | `".ruff_cache"` em `exclude` | FR-002 |
| `deterministic` | `bool` | `ruff format` segunda vez não altera hash, `ruff check --no-cache` para teste | D5/D10 |

**Validações:**

* `git ls-files | grep .ruff_cache` vazio (Lei Zero).
* `ruff check --no-cache` determinístico.

---

### 4. Manifest de integridade (estendido)

`scripts/verify/manifest.sha256` 6 linhas (001..006) após 006.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `lines` | `int` | `6` | FR-008 |
| `files` | `list[str]` | `f0-001..006` ordem ADR-011 | FR-008 |
| `verification` | `cmd` | `sha256sum -c` 0 | FR-008 |

**Valores congelados (re-medidos 2026-08-31):**

```
63412ca7…  f0-001
b63ac3c8…  f0-002
d10c61…  f0-003
42e2d36…  f0-004
e39a1f1c…  f0-005
<hash-006>  f0-006
```

---

### 5. Dependency-group dev (estendido)

`[dependency-groups] dev` agora com 4 entradas.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `dev` | `list[str]` | `["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0","ruff==0.16.5"]` | FR-001 |
| `uv.lock` | `bool` | contém `ruff` hash | FR-006 |

---

## Relações

```
[dependency-groups] dev ──1──> uv.lock ──1──> .ruff_cache (exclude)
      │
      ├─1──> Ruff linter ──1──> ruff check . (concise)
      │
      └─1──> Ruff formatter ──1──> ruff format --check --diff (idempotente)
                                │
Manifest 6 linhas ──1──> ruff check/format determinístico
```

## Ciclo de vida

* **Criação:** 006 cria `[tool.ruff.*]` + `ruff==0.16.5` em `dev` + `.ruff_cache` (via `ruff check`).
* **Mutação:** `ruff.toml` nunca criado (fonte única); `exclude` só acrescenta, não remove.
* **Idempotência:** `ruff format` segunda vez `sha256sum` idêntico (D5).

## Volume / escala

* `tests/` 11 arquivos, `ruff check` <1s, `format --check` <1s, `f0-006` 10–14 asserções <5s.
* `ruff` cache `.ruff_cache/` <10MB, ignorado.
