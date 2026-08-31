# Contract: MyPy — Fase 0, item 007 (0.3)

**Feature**: `007-mypy` · **Data**: 2026-08-31
**Spec**: `specs/007-mypy/spec.md` (FR-001..016) · **Research**: `docs/plan/research/f0-007-mypy.md` D1–D10
**Herda**: `specs/001-.../contracts/oracle-cli.md`

Este contrato fixa o **schema TOML + invocação mypy** que 007 introduz e que 008–014 consomem.

---

## 1. Onde vivem os arquivos

```
pyproject.toml              # [dependency-groups] dev + [tool.mypy] + [[tool.mypy.overrides]]
uv.lock                     # contém mypy 2.3.1 + mypy_extensions/pathspec/tomli com hash (universal)
.mypy_cache/                # cache efêmero, exclude + .gitignore 217
.dmypy.json                 # dmypy daemon, ignorado 218
scripts/verify/
├── manifest.sha256         # 7 linhas (001..007) sha256sum -c 0
└── f0-007-mypy.sh          # 12–16 asserções FR-001..016
specs/README.md             # índice 007 ✅ (inquebrável)
```

* Sem `mypy.ini`/`.mypy.ini` — fonte única `pyproject.toml` (D2).

---

## 2. Schema `pyproject.toml`

### 2.1 `[dependency-groups]`

```toml
[dependency-groups]
dev = ["mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

### 2.2 `[tool.mypy]`

```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_unused_configs = true
exclude = "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"
```

* `strict = true` habilita 11 flags (`disallow-untyped-defs/calls/decorators`, `warn-return-any`, `strict-equality` etc.).
* `warn_unused_configs = true` detecta `overrides` typo.

### 2.3 `[[tool.mypy.overrides]]`

```toml
[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
disallow_untyped_calls = false
warn_return_any = false
```

* `tests.*` relaxado: `def test_foo():` sem `-> None` e `assert` com `Any` não reprovam; `src` futuro (`packages/core`) sem override, `strict` puro.

**Verificação:**

```bash
python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["mypy"]["python_version"]=="3.12"'
python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["mypy"]["strict"] is True'
```

---

## 3. Invocação

```bash
uv run mypy --version                  # → 2.3.1
uv run mypy --help | grep -q strict    # lista strict
uv run mypy --strict .                 # type check strict (com overrides para tests/)
uv run mypy --strict tests/            # só tests/ com overrides relaxado
uv run mypy --strict --no-error-summary .  # determinístico sem summary
```

* `mypy --strict .` sem `--config-file` lê `pyproject.toml` por padrão.
* `dmypy` (`mypy --dmypy`) não usado no harness (apenas `mypy` batch).

---

## 4. Fronteira (FR-014)

Em 007 **MUST NOT** existir:

* `[tool.mypy]` já existe (007) — mas `007` não deve conter `D`/`ANN` em `select` de `ruff` (já deferido)
* `mypy.ini`/`.mypy.ini` separado
* `lefthook.yml` (`009`), `pip-audit`/`trivy` (`008`), `packages/` com `pyproject.toml` (`011`/`012`)

---

## 5. Evolução para 011/012

```
[tool.mypy] strict true + overrides tests.*  # 007
→ 011: packages/core/src sem overrides (strict puro, sem disallow_untyped_defs false)
→ 012: packages/cli/src idem
```

Sem reescrever `[tool.mypy]` global em 011/012, apenas adicionar `[[tool.mypy.overrides]]` por pacote se necessário.

---

## 6. Cache e determinismo

* `.mypy_cache/` em `exclude` + `.gitignore` 217, `git check-ignore -q` positivo.
* `mypy --strict` segunda vez não altera cache hash (idempotente).
* `mypy --no-error-summary` para teste de determinismo (sem summary com tempo).
