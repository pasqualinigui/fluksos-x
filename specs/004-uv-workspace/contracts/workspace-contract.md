# Contrato — Workspace UV 004

**Spec**: [spec.md](../spec.md) (FR-001..017) · **Plan**: [plan.md](../plan.md) · **Research**: [research.md](../research.md) (D1–D10)
**Tipo**: filesystem + TOML schema + git invariants · **Version**: `004` (root virtual)

Este contrato fixa o que cada consumidor (005 Pytest, 006 Ruff, 007 MyPy, 010 CI, 013 Release, 014 Renovate) recebe de 004 sem reescrever.

---

## 1. pyproject.toml — schema canónico 004

Arquivo MUST existir em `pyproject.toml` na raiz, TOML válido (`tomllib.load` sem erro).

```toml
[project]
name = "fluksos-x"
version = "0.1.0"
description = "Motor determinístico multiagente — workspace root virtual"
requires-python = ">=3.12,<3.14"
dependencies = []
# readme / authors / license opcionais — não verificados por harness 004

[build-system]
requires = ["uv_build>=0.12.7,<0.13"]
build-backend = "uv_build"

[tool.uv.workspace]
members = ["packages/*"]
# exclude ausente em 004; só introduzido quando membro precisar ser excluído

# tool.uv.sources ausente em 004 (sem inter-dep antes de haver membros)
# [dependency-groups] ausente em 004 (introduzido por 005 Pytest como dev deps)
```

### Invariantes (harness verifica)

| Campo | Operador | Valor esperado | FR | Como verificar |
|---|---|---|---|---|
| `project.name` | `==` | `fluksos-x` | FR-001 | `tomllib` |
| `project.version` | `==` | `0.1.0` | FR-001 | `tomllib` |
| `project.requires-python` | `==` | `>=3.12,<3.14` | FR-002 | `tomllib` |
| `build-system.requires[0]` | `==` | `uv_build>=0.12.7,<0.13` | FR-003 | `tomllib` + `grep -F` |
| `build-system.build-backend` | `==` | `uv_build` | FR-003 | `tomllib` |
| `tool.uv.workspace.members` | `==` | `["packages/*"]` | FR-004 | `tomllib` |
| `tool.uv.workspace.exclude` | inexistente | — | FR-004 | `tomllib` ausência |
| `tool.uv.sources` | inexistente | — | FR-015 | contrato documentado |

### Evolução sem quebra (005–014)

| Item futuro | Adição compatível em `pyproject.toml` |
|---|---|
| 005 Pytest 9.1.1 | `[dependency-groups] dev = ["pytest>=9.1.1", ...]` — não conflita com `tool.uv.workspace` |
| 006 Ruff 0.16.5 | `[tool.ruff]` seção coexistindo com `[tool.uv]` |
| 007 MyPy 2.3.1 | `mypy.ini` ou `[tool.mypy]` lendo `packages/*` |
| inter-membro | `[tool.uv.sources.<name>] = { workspace = true }` (nunca `{ path = ... }` dentro de workspace) |

---

## 2. uv.lock — contrato de trava

| Propriedade | Valor | FR |
|---|---|---|
| Path | `uv.lock` ao lado de `pyproject.toml` | FR-006 |
| Formato | TOML válido legível, específico de `uv` (não `pylock.toml`) | FR-006 |
| Versionado | `! git check-ignore -q uv.lock` (não ignorado) | FR-011 |
| Mutação | só via `uv lock`/`uv sync`/`uv add` | FR-007 |
| Universal | cross-platform markers | D10 |
| Idempotência | `sha256sum` idêntico após `uv sync` duplo | SC-002 |

**Export (não em 004, sem config extra):**
```bash
uv export --format requirements.txt
uv export --format pylock.toml      # PEP 751 — 013
uv export --format cyclonedx1.5     # SBOM — 013
```

---

## 3. .venv — contrato de ambiente

| Propriedade | Valor | FR |
|---|---|---|
| Path | `.venv/` ao lado de `pyproject.toml` | FR-008 |
| Interpreter | `.venv/bin/python` executável POSIX, `python --version` == `3.12.x` | FR-008 |
| Interno | `.venv/.gitignore` existe e contém `*` | FR-008 |
| Git | `git check-ignore -q .venv` positivo; `git status --porcelain` não lista `.venv/` | FR-011 |
| Descartável | `rm -rf .venv && uv sync` recria sem alterar `uv.lock` | FR-009 |
| Activation | `uv run python --version` funciona sem `source .venv/bin/activate` | SC-001 |

---

## 4. .python-version — contrato

| Propriedade | Valor | FR |
|---|---|---|
| Path | `.python-version` na raiz | FR-005 |
| Conteúdo | `3.12` ou `3.12.x` (ex.: `3.12.3`), `grep -Eq '^3\.12(\.[0-9]+)?$'` | FR-005 |
| Versionado | `! git check-ignore -q .python-version` (`# .python-version` no `.gitignore` é comentário) | D7 |
| Precedência | `requires-python` é fonte de verdade do workspace | FR-005 |

---

## 5. .gitignore — invariante 004

| Regra | Valor | FR |
|---|---|---|
| `*.lock` / `uv.lock` | MUST NOT existir em `.gitignore` | FR-010 |
| `.venv` | já ignorado via `.venv/.gitignore:*` interno; não exigir `.venv` literal no `.gitignore` raiz | FR-011 |
| Diff em 004 | `git diff .gitignore` vazio (`0` linhas) — 001 já fixou exclusões | FR-012 |

---

## 6. Fronteira de escopo (o que NÃO existe em 004)

| Artefato | Status em 004 | Dono futuro |
|---|---|---|
| `packages/` / `packages/*/pyproject.toml` | MUST NOT existir (`! test -d packages`) | 006+ |
| `ruff.toml` / `[tool.ruff]` | ausente | 006 |
| `mypy.ini` / `[tool.mypy]` | ausente | 007 |
| `pytest` / `[dependency-groups] dev` | ausente | 005 |
| `lefthook.yml` | ausente | 009 |
| `pip-audit` / `trivy` | ausente | 008/010 |
| `pylock.toml` / `requirements.txt` / SBOM | ausente (exportável) | 013 |

---

## 7. CI — invariante

`FR-017` — `.github/workflows/ci.yml` job `verify` de 003 inclui `f0-004` automaticamente via glob sem edição:

```bash
for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done
```

---

## Consumidores (contratos expostos)

| Consumidor | O que recebe de 004 |
|---|---|
| **005 Pytest 9.1.1** | Root para `[dependency-groups] dev` e ponto de montagem `packages/core` |
| **006 Ruff 0.16.5** | `pyproject.toml` onde `[tool.ruff]` coexistirá sem conflito com `[tool.uv]` |
| **007 MyPy 2.3.1** | `requires-python` single já fixado; `mypy.ini` futuro lê `packages/*` |
| **010 CI completo** | `uv.lock` para `uv sync --frozen` determinístico; `verify` já inclui `f0-004` |
| **013 Release** | `uv build` + `uv export --format pylock.toml\|cyclonedx` sem config extra |
| **014 Renovate** | `uv_build>=0.12.7,<0.13` pin para agrupamento e automerge |
