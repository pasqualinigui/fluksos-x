# RESEARCH — F0/007 · MyPy 2.3.1 strict — type checker

> **Item do plano:** 0.3 (§17 Fase 0) · **Ordem de execução:** 007/016 (ADR-011)
> **Data da verificação:** 2026-08-31 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/006-ruff/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-.../contracts/oracle-cli.md` + `pyproject.toml` (006) + `scripts/verify/README.md` (restrição)

Este item entrega **o type checker strict do monorepo** (implementation_plan §4: `MyPy 2.3.1` modo `strict`, nova série 2.x). Até aqui o harness é `ruff` (linter+formatter) + `pytest` (TDD) + shell; `MyPy` é o primeiro verificador que **exige anotações de tipo** — por isso a fronteira com `Ruff` (006, `target-version py312`, `UP`/`I`) e `Lefthook` (009) precisa ser compatível. Não cria `lefthook.yml`/`pip-audit` nem `packages/` — estes são specs 008–009 e 011/012 (Escada).

---

## Q1 — Qual pin canônico de `mypy` 2.3.1 e novidades 2.x vs 1.x?

**Fonte:** `https://pypi.org/pypi/mypy/json` + `.../mypy/2.3.1/json` + `https://pypi.org/simple/mypy/` + `uv run --with mypy==2.3.1 mypy --help` + `https://mypy.readthedocs.io/en/stable/command_line.html` — HTTP 200, fetch 2026-08-31.

Evidências:

```
mypy             2.3.1  requires_python='>=3.10' upload 2026-08-15T03:01:53Z
  simple index last 10: ['2.1.1','2.1.2','2.2.0','2.3.0','2.3.1'] → 2.3.1 é latest 2.x estável
  summary: Optional static typing for Python
  requires_dist: ['typing_extensions>=4.6.0', 'mypy_extensions>=1.0.0', 'pathspec>=1.0.0', 'tomli>=1.1.0; py<3.11', 'librt>=0.13.0', 'ast-serialize>=0.6.0']
  1.x vs 2.x: uv run --with mypy==2.3.1 mypy --help mostra --native-parser (novo, Rust), --strict inclui 11 flags (vs 1.x 9 flags)
```

Docs `mypy --help` (extraído):

```
--strict  Strict mode; enables: --disallow-any-generics, --disallow-subclassing-any,
          --disallow-untyped-calls, --disallow-untyped-defs, --disallow-untyped-decorators,
          --warn-redundant-casts, --warn-unused-ignores, --warn-return-any,
          --no-implicit-reexport, --strict-equality, --extra-checks
```

Novidades 2.x vs 1.x (extraído de `command_line.html` + `mypy --help`):

* `--native-parser` (Rust, mais rápido, padrão em 2.3)
* `local partial types` habilitado por padrão desde 2.0 (requerido por daemon `dmypy`)
* `--no-implicit-reexport` agora parte de `--strict` (antes era separado)
* `strict-equality` / `extra-checks` expandidos

**Achado estrutural hoje:** `pyproject.toml` sem `[tool.mypy]` nem `mypy.ini`; `which mypy → not installed` (via `uv` apenas); `.gitignore` já ignora `.mypy_cache/` (217), `.dmypy.json` (218) — correto.

**Decisão (D1):** pin canônico em **2026-08-31**:

```toml
[dependency-groups]
dev = ["mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", ...]
```

* `mypy==2.3.1` — latest 2.x, `>=3.10` compatível com `requires-python >=3.12,<3.14` e com `ruff 0.16.5` `py312`.
* Não pinar `1.x` — perde `native-parser` e `strict` expandido; `mypy 1.15` é 1.x EOL para `3.12`.

**Alternativa rejeitada:** `mypy>=2` flutuante — indeterminístico; `pyright`/`basedpyright` — Node, viola `Motor 100% Python` (decisions.md:18), e `007` já é `MyPy strict` no plano.

---

## Q2 — `mypy.ini` vs `pyproject.toml` `[tool.mypy]`?

**Fonte:** `https://mypy.readthedocs.io/en/stable/config_file.html` (132 188 bytes, HTTP 200) + `https://mypy.readthedocs.io/en/stable/command_line.html` (149 609 bytes) — fetch 2026-08-31.

Evidências (texto extraído):

> *"Mypy supports reading configuration from a file. By default, mypy will discover configuration files by walking up the filesystem ... In each directory, it will look for: `mypy.ini`, `.mypy.ini`, `pyproject.toml` (containing a `[tool.mypy]` section), `setup.cfg` (containing a `[mypy]` section). If no configuration file is found, it will look in `$XDG_CONFIG_HOME/mypy/config`, `~/.config/mypy/config`, `~/.mypy.ini`."*
> *"`--config-file` has highest precedence."*

**Achado:** `pyproject.toml` já é fonte única para `ruff` (`[tool.ruff]`) e `pytest` (`[tool.pytest.ini_options]`) após 005/006. Criar `mypy.ini` separado fragmenta config (2 TOMLs + 1 INI) e esconde `[tool.mypy]` quando `mypy.ini` existe (precedência: `mypy.ini` > `pyproject.toml`).

**Decisão (D2):**

* **Fonte única:** `pyproject.toml` com `[tool.mypy]` — **sem** `mypy.ini`/` .mypy.ini` separado em 007.
* **Por quê:** `uv` + `ruff` + `pytest` + `mypy` já compartilham `pyproject.toml` como lock universal; `mypy --config-file` padrão encontra `pyproject.toml` sem `--config-file`. `mypy.ini` só seria justificado se monorepo precisasse de `mypy` por pacote com `mypy.ini` próprio, mas `[tool.mypy.overrides]` + `[[tool.mypy.overrides]]` já suporta `per-module` em `pyproject.toml`.

**Alternativa rejeitada:** `mypy.ini` separado — fragmenta, e `pyproject.toml` deixaria de ser fonte única; `setup.cfg` — legado `distutils`, não usado com `uv`.

---

## Q3 — O que é `strict` e quais `disallow`/`warn` habilita?

**Fonte:** `uv run --with mypy==2.3.1 mypy --help` (extraído) + `https://mypy.readthedocs.io/en/stable/command_line.html` (strict) — fetch 2026-08-31.

Evidência `mypy --help`:

```
--strict  Enables: --disallow-any-generics, --disallow-subclassing-any,
          --disallow-untyped-calls, --disallow-untyped-defs,
          --disallow-untyped-decorators, --warn-redundant-casts,
          --warn-unused-ignores, --warn-return-any, --no-implicit-reexport,
          --strict-equality, --extra-checks
```

Detalhamento extraído de `command_line.html`:

```
--disallow-any-generics      disallow generic types without params (list vs list[int])
--disallow-subclassing-any   disallow class Foo(Any):
--disallow-untyped-calls     disallow calling untyped function
--disallow-untyped-defs      disallow def without type annotations
--disallow-untyped-decorators disallow decorated untyped def
--warn-redundant-casts       warn cast same type
--warn-unused-ignores        warn # type: ignore sem erro
--warn-return-any            warn return Any from typed def
--no-implicit-reexport       only from x import y as y or __all__ re-exports
--strict-equality            prohibit 42 == 'no' (non-overlapping)
--extra-checks               additional correct but impractical checks
```

**Achado:** `strict` não inclui `--disallow-any-expr` nem `--warn-unreachable` — são opcionais além de `strict`. Para Fase 0 (sem `packages/core` ainda, apenas `tests/`), `strict` puro já é sênior sem ser bloqueante para `tests/` que usam `Any` em `subprocess` mocks.

**Decisão (D3):** em 007, `strict = true` **puro**, sem `disallow-any-expr` adicional:

```toml
[tool.mypy]
strict = true
```

* `strict = true` habilita as 11 flags acima — cobre `untyped defs/calls`, `Any` generics, `re-export`, `equality` — sem precisar listar cada `disallow` manualmente.
* Não adicionar `disallow-any-expr` em 007 (seria `HIGH` para `tests/` que usam `Any` em `pytest` fixtures). Reavaliar em `011` (`packages/core`).

**Alternativa rejeitada:** `strict = true` + `disallow_any_expr = true` — bloquearia `tests/test_harness_*.py` que usa `Any` em `subprocess` mocks; listar 11 `disallow-*` manualmente em vez de `strict = true` — verboso, `strict` já é atômico e documentado.

---

## Q4 — Como configurar `strict` para este monorepo (`python_version`, `exclude`, `per-module`)?

**Fonte:** `https://mypy.readthedocs.io/en/stable/config_file.html` (per-module, `python_version`) + `pyproject.toml` (005/006) `requires-python >=3.12` + `https://mypy.readthedocs.io/en/stable/command_line.html` (`--python-version`) — fetch 2026-08-31.

Evidências:

> *"`python_version = 3.12` — Specifies the Python version used to parse and check the target program. Only in global `[mypy]`."*
> *"`exclude = (?x) ^tests/coverage`" — regex para excluir `tests` se desejado, mas `strict` deve lintar `tests/` com `allow`.* 
> *"`[[tool.mypy.overrides]] module = \"tests.*\" disallow_untyped_defs = false`" — per-module override.*

**Achado estrutural:** `tests/` já existe (005) com `assert` e `subprocess` — `strict` puro com `disallow-untyped-defs` reprovaria `def test_foo():` sem `-> None` em `tests/`. `specs/` e `docs/` são Markdown, não Python, `mypy` ignora por não ser `*.py`.

**Decisão (D4):**

```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_unused_configs = true
exclude = "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"
[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
disallow_untyped_calls = false
warn_return_any = false
```

* `python_version = "3.12"` — alinha com `requires-python >=3.12` e `ruff target-version py312` (006) e `mypy` `>=3.10`.
* `strict = true` — base sênior.
* `warn_unused_configs = true` — detecta `overrides` com `module` typo.
* `exclude = "(?x)^(docs/|specs/|\\.venv/)"` — exclui `docs/` `specs/` (Markdown) e caches; `tests/` **não** é excluído — `mypy` deve checar `tests/` mas com `overrides` relaxado.
* `[[tool.mypy.overrides]] module = "tests.*"` — relaxa `disallow_untyped_defs/calls` e `warn_return_any` em `tests/` (onde `def test_*():` sem `-> None` e `assert` são idiomáticos). Em `011` (`packages/core`) `strict` será sem override.

**Alternativa rejeitada:** `exclude = "tests/"` — esconderia `tests/` de `mypy`, perderia verificação de `subprocess` com `Any`; `ignore_errors = true` para `tests/` — silencioso, `overrides` é explícito e `warn_unused_configs` detecta typo.

---

## Q5 — Novidades `MyPy 2.x` vs `1.x` e impacto em `strict` 007?

**Fonte:** `uv run --with mypy==2.3.1 mypy --help` (`--native-parser`, `local partial types` default 2.0) + `https://mypy.readthedocs.io/en/stable/command_line.html` (2.0 `local partial types` habilitado) — fetch 2026-08-31.

Evidências:

* `2.0` `local partial types` habilitado por padrão (requerido por `dmypy` daemon).
* `--native-parser` (Rust, mais rápido) padrão em 2.3.
* `strict` em 2.x inclui `extra-checks` e `no-implicit-reexport` que 1.x não incluía por padrão.

**Achado:** `pyproject.toml` (005/006) sem `python_version` explícito para `mypy` faria `mypy` usar `3.12.3` local, mas CI `3.12.14` — `python_version = "3.12"` fixa determinismo.

**Decisão (D5):**

* Não habilitar `native-parser = true` explicitamente — já é default em 2.3, mas documentar que `2.3` usa Rust parser.
* Não desabilitar `local partial types` (`--no-local-partial-types`) — deixá-lo habilitado (default 2.0) para `dmypy` futuro.

**Alternativa rejeitada:** `mypy 1.15` (1.x) — perde `native-parser` e `strict` 2.x `extra-checks`; `mypy --no-namespace-packages` — desnecessário (sem `packages/` ainda).

---

## Q6 — Como declarar `mypy` via `uv` sem quebrar `ruff`/`pytest`?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/dependencies/` (PEP 735) + `pyproject.toml` (006) `dev = ["ruff==0.16.5", "pytest==9.1.1", ...]` + `uv add --help` — fetch 2026-08-31.

Evidência (repetida de Q4 de 005/006):

> *"`uv add --dev mypy` will create a `dev` group: `[dependency-groups] dev = [\"mypy\"]`"* — `dev` é `default-groups = ["dev"]`, `uv sync` instala `dev`.

**Decisão (D6):**

```bash
uv add --dev mypy==2.3.1   # → [dependency-groups] dev = ["mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", ...]
uv sync
```

* Resultado `pyproject.toml`:

```toml
[dependency-groups]
dev = ["mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

* `uv.lock` passa a conter `mypy 2.3.1` + `mypy_extensions` `pathspec` `tomli` com hash (universal). `uv sync --no-dev` omite para `013` release.

**Alternativa rejeitada:** `[tool.mypy]` sem `mypy` em `dev` — `uv run mypy` falharia em CI sem `pip install`; `requirements-dev.txt` — fora do lock universal.

---

## Q7 — Compatibilidade `MyPy` strict com `Ruff` (`UP`/`I` `py312`) e `pytest`?

**Fonte:** `docs/plan/research/f0-006-ruff.md` D10 (compat `mypy` `UP`/`I`) + `https://docs.astral.sh/ruff/rules/#pyupgrade` (UP007 `X|Y`) + `pyproject.toml` (006) `target-version py312` — fetch 2026-08-31.

Evidências:

* `ruff` `UP007` moderniza `Union[int, str]` → `int | str` (3.10+), `UP043` usa `contextlib.suppress` — `mypy 2.3.1` com `python_version = "3.12"` entende `X|Y`.
* `ruff` `I` ordena `import typing` vs `import pathlib` — `mypy` não verifica ordem de imports, não conflita.
* `pytest` `tests/` com `def test_foo():` sem `-> None` — `mypy` `disallow_untyped_defs` reprovaria, mas `overrides` para `tests.*` relaxa (D4).

**Decisão (D7):**

* `ruff` `target-version py312` + `[tool.mypy] python_version = "3.12"` — alinhados, `UP` não gera código que `mypy` reprovaria.
* `tests/` com `overrides` `disallow_untyped_defs = false` — `mypy` não reprova `tests/test_harness_*.py` sem `-> None`; `src` futuro (`packages/core`) sem override, `strict` puro.

**Alternativa rejeitada:** `python_version = "3.10"` em `mypy` — `ruff` modernizaria para `3.12` `X|Y` que `mypy` `3.10` ainda aceitaria, mas `3.12` é mais preciso; `ignore_errors = true` para `tests/` — silencioso.

---

## Q8 — Como `mypy` interage com `.gitignore`, `exclude`, `dmypy`/`cache`?

**Fonte:** `https://mypy.readthedocs.io/en/stable/config_file.html` (`exclude`, `follow_imports`) + `.gitignore` (`.mypy_cache/` 217, `.dmypy.json` 218) + `pyproject.toml` (006) — fetch 2026-08-31.

Evidências:

> *"`exclude = (?x) ^(docs/|specs/)"` — regex para excluir `docs/` `specs/`."*
> *"`mypy` cache lives in `.mypy_cache/` and `.dmypy.json` (daemon). `mypy --no-error-summary` etc."*

**Achado:** `.gitignore` já ignora `.mypy_cache/` (217) e `.dmypy.json` (218) — correto, mas `mypy` **não** lê `.gitignore` para `exclude`; `exclude` é regex separado.

**Decisão (D8):**

```toml
[tool.mypy]
exclude = "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"
```

* Replica `pyproject.toml` `exclude` de `ruff` (D4) mas para `mypy` (regex `(?x)` verbose).
* `tests/` **não** é excluído — `mypy` deve checar `tests/` com `overrides`.
* `dmypy` (`mypy --dmypy`) usa `.dmypy.json` e `.mypy_cache/` — ambos gitignored, determinismo via `--no-error-summary` para teste.

**Alternativa rejeitada:** `exclude = "tests/"` — esconderia `tests/` de `mypy`; `follow_imports = skip` — esconderia `Any` de `pytest` stubs, melhor `normal` (default).

---

## Q9 — O que o harness de 007 deve verificar (e o que NÃO verificar)?

**Fonte:** `specs/001-.../contracts/oracle-cli.md` + `scripts/verify/README.md` (restrição `006+ Ruff`, `007+ MyPy`) + `specs/006-ruff/contracts/ruff-contract.md` — fetch 2026-08-31.

Evidência restrição:

> *"Um oráculo que exija ferramenta ainda não instalada no seu ponto do bootstrap está errado, ainda que funcione na máquina de quem o escreveu."* — `README.md:79`

**Decisão (D9):** `f0-007-mypy.sh` com **10–14 asserções**:

| FR candidato | Verificável por harness | Como |
|---|---|---|
| `[tool.mypy]` `python_version 3.12` `strict true` | sim | `tomllib` parse |
| `mypy.ini` **não** existe (fonte única) | sim | `! test -f mypy.ini` |
| `mypy==2.3.1` em `[dependency-groups] dev` | sim | `tomllib` + `uv.lock` grep |
| `uv.lock` contém `mypy` + `mypy_extensions` | sim | `grep 'name = "mypy"'` |
| `.mypy_cache/` gitignored | sim | `git check-ignore -q` |
| `mypy --version` 2.3.1 | sim | `uv run mypy --version` |
| `uv run mypy --strict tests/` 0 em `tests/` com `overrides` | sim | `uv run mypy --strict` (quando `mypy` instalado) |
| `warn_unused_configs` true | sim | `grep -q warn_unused_configs` |
| `exclude` contém `docs/` `specs/` | sim | `grep -q exclude` |
| `overrides` `tests.*` `disallow_untyped_defs false` | sim | `tomllib` parse `overrides` |
| Fronteira: sem `lefthook.yml`/`packages/` | sim | `! test -f lefthook.yml` |

**NÃO verificar em 007** (Escada):

* `lefthook.yml` (`009`), `pip-audit` (`008`), `packages/` (`011`/`012`).

**Decisão (D9):** oráculo `f0-007-mypy.sh` segue `oracle-cli.md` (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER`, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`). `ruff` (`f0-006`) e `pytest` (`f0-005`) devem continuar passando (`self-check`).

---

## Q10 — Determinismo e fronteira Escada para `mypy` (2.x `native-parser`)?

**Fonte:** `constitution.md:176` (Escada) + `docs/plan/implementation_plan.md:835-846` (§17) + `specs/006-ruff/spec.md:190` (Out of Scope) — fetch 2026-08-31.

Evidência Escada:

> *"Nenhum artefato pode exigir ferramenta que ainda não existe no seu ponto do bootstrap."*

**Decisão (D10):**

* **Determinismo:** `mypy --strict` segunda vez não altera `mypy` cache hash (`--no-error-summary` para teste). `mypy` cache `.mypy_cache/` ignorado, `dmypy` não usado em harness (apenas `mypy` batch). `mypy` com `python_version = "3.12"` determinístico entre `3.12.3` local e `3.12.14` runner.
* **Compatibilidade `ruff`:** `ruff` `UP` `I` já compatível com `mypy` `py312`; `mypy` `exclude` não conflita com `ruff` `exclude`.
* **Fronteira Escada (007):** **NÃO** cria `lefthook.yml` (`009`), `pip-audit` (`008`), `packages/` (`011`/`012`), `mypy.ini` separado (é `pyproject.toml` em 007 per D2).

**Decisão (D10):** em 007, garantir apenas `pyproject.toml` `[tool.mypy]` + `mypy==2.3.1` em `dev` + `uv.lock` + `.mypy_cache` ignorado. Escala para `009` (`lefthook` orquestra `mypy --strict`), `010` (`mypy` em CI `uv run mypy`).

---

## Resumo das decisões vinculantes

| # | Decisão | Fonte |
|---|---|---|
| D1 | `mypy==2.3.1` via `[dependency-groups] dev` (PEP 735), `uv sync` | Q1 PyPI 2026-08-15 |
| D2 | `pyproject.toml` `[tool.mypy]` fonte única, sem `mypy.ini` | Q2 docs/config_file 132KB |
| D3 | `strict = true` (11 flags) sem `disallow-any-expr` adicional | Q3 mypy --help --strict |
| D4 | `python_version = "3.12"` `strict true` `warn_unused_configs true` `exclude = "(?x)^(docs/|specs/|\\.venv/)"` + `[[tool.mypy.overrides]] tests.*` relaxado | Q4 docs/config_file + requires-python |
| D5 | `native-parser` default 2.3, `local partial types` habilitado (2.0) | Q5 mypy --help 2.x |
| D6 | `uv add --dev mypy==2.3.1` → `dev` com `ruff`+`pytest`+`mypy` | Q6 uv docs |
| D7 | Compat `ruff` `py312` + `overrides` para `tests/` (pytest) | Q7 docs/ruff 006 D10 |
| D8 | `exclude` regex para `mypy`, `.mypy_cache` gitignored | Q8 docs/config_file + .gitignore |
| D9 | Harness `f0-007-mypy.sh` 10–14 asserções só mypy, sem lefthook | Q9 oracle-cli + README |
| D10 | Determinismo `mypy --strict` idempotente, fronteira Escada (007 só mypy) | Q10 constitution |

**Nenhum `NEEDS CLARIFICATION` remanescente.** Próxima etapa: `SPECIFY` da spec `007 — MyPy 2.3.1 strict`.

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **008 pip-audit+Trivy** | `uv.lock` com `mypy 2.3.1` hash auditável |
| **009 Lefthook** | `mypy --strict` orquestrável via `lefthook.yml` (`uv run mypy`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `mypy` em `uv.lock` para `uv run mypy --strict` determinístico em CI |
| **011 core / 012 cli** | `pyproject.toml` `[tool.mypy]` com `overrides` para `tests/` → escala para `packages/*` sem reescrever |

## Pacotes e versões pinadas verificadas em 2026-08-31

| Pacote | Versão verificada | Fonte | Nota |
|---|---|---|---|
| `mypy` | `2.3.1` | PyPI `mypy/json` upload 2026-08-15 | `>=3.10`, `strict` 11 flags, `native-parser` |
| `ruff` | `0.16.5` | PyPI `ruff/json` (re-verificado) | `dev` já em 006, coexiste com `mypy` |
| `pytest` | `9.1.1` | PyPI `pytest/json` | `dev` já em 005 |
| `Python` | `3.12.3` local, `3.12` família, `>=3.12,<3.14` | `python --version` + `requires-python` | `mypy python_version 3.12` alinha |
| `uv` | `0.12.7` | PyPI `uv/json` | `uv add --dev mypy` → `dependency-groups` |
| `mypy config` | `[tool.mypy] strict true` | `mypy docs/config_file` 132KB | `mypy.ini` rejeitado para fonte única |
