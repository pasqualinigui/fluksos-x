# Contract: Ruff — Fase 0, item 006 (0.2)

**Feature**: `006-ruff` · **Data**: 2026-08-31
**Spec**: `specs/006-ruff/spec.md` (FR-001..014) · **Research**: `docs/plan/research/f0-006-ruff.md` D1–D10
**Herda**: `specs/001-.../contracts/oracle-cli.md`

Este contrato fixa o **schema TOML + invocação ruff** que 006 introduz e que 007–014 consomem.

---

## 1. Onde vivem os arquivos

```
pyproject.toml              # [dependency-groups] dev + [tool.ruff] + [tool.ruff.lint] + [tool.ruff.format]
uv.lock                     # contém ruff 0.16.5 com hash (universal)
.ruff_cache/                # cache efêmero, exclude + .gitignore 254
scripts/verify/
├── manifest.sha256         # 6 linhas (001..006) sha256sum -c 0
└── f0-006-ruff.sh          # 10–14 asserções FR-001..014
```

* Sem `ruff.toml`/` .ruff.toml` — fonte única `pyproject.toml` (D2).
* `tests/` já existe (005), `ruff` deve lintar `tests/` com `per-file-ignores`.

---

## 2. Schema `pyproject.toml`

### 2.1 `[dependency-groups]`

```toml
[dependency-groups]
dev = ["pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0", "ruff==0.16.5"]
```

* Pins exatos `==`, PEP 735, `uv sync` instala `ruff` em `.venv/bin/ruff`.

### 2.2 `[tool.ruff]`

```toml
[tool.ruff]
line-length = 88
target-version = "py312"
exclude = [".bzr", ".direnv", ".eggs", ".git", ".hg", ".ipynb_checkpoints", ".mypy_cache", ".nox", ".pants.d", ".pyenv", ".pytest_cache", ".pytype", ".ruff_cache", ".svn", ".tox", ".venv", ".vscode", "__pypackages__", "_build", "buck-out", "build", "dist", "node_modules", "site-packages", "venv"]
```

### 2.3 `[tool.ruff.lint]`

```toml
[tool.ruff.lint]
select = ["E", "F", "W", "C90"]
extend-select = ["I", "UP", "B", "SIM", "S", "C4", "A", "RUF"]
ignore = ["E501", "S101", "S603"]
[tool.ruff.lint.per-file-ignores]
"tests/**/*" = ["S101", "S603"]
```

* `E501` ignorado (format cuida), `S101`/`S603` ignorados em `tests/**/*` (assert/subprocess com `FKX_`).

### 2.4 `[tool.ruff.format]`

```toml
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"
docstring-code-format = false
docstring-code-line-length = "dynamic"
```

**Verificação:**

```bash
python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["ruff"]["line-length"]==88'
python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert "RUF" in str(d["tool"]["ruff"]["lint"]["extend-select"])'
```

---

## 3. Invocação

```bash
uv run ruff check .                          # linter, sem --fix (harness)
uv run ruff check --fix .                    # linter com fix (local)
uv run ruff check --output-format=concise .  # harness parseável
uv run ruff format .                         # formatter idempotente
uv run ruff format --check --diff .          # CI verifica diff (exit 1 se não formatado)
uv run ruff check --no-cache .               # determinismo sem cache
```

* `ruff check` sem `--fix` no harness (apenas leitura, `oracle-cli.md`).
* `ruff format` idempotente: segunda `format` não altera `sha256sum`.

---

## 4. Fronteira (FR-014)

Em 006 **MUST NOT** existir:

* `[tool.mypy]`/`mypy.ini`, `lefthook.yml`, `pip-audit`/`trivy`, `packages/` com `pyproject.toml`, `ruff.toml` separado, `D`/`ANN` em `select`.

---

## 5. Evolução para 007/009

```
[tool.ruff]            # 006
→ 007: + [tool.mypy] python_version 3.12 (coexiste, UP/I compatível)
→ 009: lefthook.yml: ruff check --fix + ruff format (orquestra)
```

Sem reescrever `[tool.ruff]` em 007/009.

---

## 6. Cache e determinismo

* `.ruff_cache/` em `exclude` + `.gitignore` 254, `git check-ignore -q` positivo.
* `ruff check --no-cache` para teste de determinismo (sem cache, mesma saída).
* `ruff format` segunda vez `sha256sum` idêntico 100% (SC-003).
