# RESEARCH — F0/006 · Ruff 0.16.5 — linter + formatter

> **Item do plano:** 0.2 (§17 Fase 0) · **Ordem de execução:** 006/016 (ADR-011)
> **Data da verificação:** 2026-08-31 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/005-pytest/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-.../contracts/oracle-cli.md` + `pyproject.toml` (005) + `scripts/verify/README.md` (restrição)

Este item entrega **o linter e formatter único do monorepo** (implementation_plan §4: `Ruff 0.16.5` substitui `flake8+black+isort`+...). Até aqui o harness é `pytest` + shell; `Ruff` é a primeira ferramenta que **re-escreve** código (formatter) — por isso a fronteira com `MyPy` (007) e `Lefthook` (009) precisa ser fechada agora. Não cria `mypy.ini`/`lefthook.yml`/`pip-audit` nem `packages/` — estes são specs 007–009 e 011/012 (Escada, constitution Additional Constraints).

---

## Q1 — Qual pin canônico de `ruff` 0.16.5 e compatibilidade Python?

**Fonte:** `https://pypi.org/pypi/ruff/json` + `.../ruff/0.16.5/json` + `https://pypi.org/simple/ruff/` (simple index) + `https://pypi.org/pypi/mypy/json` — HTTP 200, fetch 2026-08-31.

Evidências:

```
ruff             0.16.5  requires_python='>=3.7' upload 2026-08-27T16:33:41Z
  simple index last 10: ['0.15.19','0.15.20','0.15.21','0.15.22','0.16.0','0.16.1','0.16.2','0.16.3','0.16.4','0.16.5'] → 0.16.5 é latest estável
  summary: An extremely fast Python linter and code formatter, written in Rust.
  requires_dist: None (sem deps Python, binário Rust)
mypy             2.3.1   requires_python='>=3.10' (compatível com 0.16.5, ambos suportam 3.12)
```

Docs: `https://docs.astral.sh/ruff/` 33 701 bytes, HTTP 200 — `0.16.5` é a versão estável documentada em `docs.astral.sh/ruff/configuration/` e `rules/`.

**Achado estrutural hoje:** `pyproject.toml` sem `[tool.ruff]` nem `ruff.toml`; `which ruff → not installed`; `ls ruff.toml → inexistente`; `.gitignore` já ignora `.ruff_cache/` (254), `.mypy_cache/` (217), `.pytest_cache/` (99) — correto para Ruff.

**Decisão (D1):** pin canônico em **2026-08-31**:

```toml
# via uv
[dependency-groups]
dev = ["ruff==0.16.5", "pytest==9.1.1", ...]
# ou via uv add --dev ruff==0.16.5
```

* `ruff==0.16.5` — latest, `>=3.7` compatível com `requires-python >=3.12,<3.14` do workspace.
* Não pinar via `[project.dependencies]` — `ruff` é `dev` local-only (não publicado, `uv sync --no-dev` omite para `013` release).

**Alternativa rejeitada:** `ruff>=0.16` flutuante — indeterminístico, lock mudaria sem `pyproject.toml`; `pip install ruff` sem `uv` — fora do lock universal; `ruff 0.15.x` — perde `preview` fixes de 0.16.5.

---

## Q2 — `ruff.toml` vs `pyproject.toml` `[tool.ruff]`?

**Fonte:** `https://docs.astral.sh/ruff/configuration/` (129 186 bytes, HTTP 200) + `https://docs.astral.sh/ruff/linter/` (93 978 bytes) + `https://docs.astral.sh/ruff/formatter/` (95 170 bytes) — fetch 2026-08-31.

Evidências (texto extraído):

> *"Ruff can be configured through a `pyproject.toml`, `ruff.toml`, or `.ruff.toml` file. Whether you're using Ruff as a linter, formatter, or both, the underlying configuration strategy and semantics are the same."*
> *"If left unspecified, Ruff's default configuration is equivalent to: `pyproject.toml` `[tool.ruff]` `exclude = [".bzr", ".direnv", ..., ".ruff_cache", ".venv", ...]` `line-length = 88` `indent-width = 4` `target-version = \"py310\"` `[tool.ruff.lint]` ... `[tool.ruff.format]` ..."*

Exemplo canônico da fonte:

```toml
# pyproject.toml
[tool.ruff]
line-length = 88
[tool.ruff.lint]
extend-select = ["B"]
ignore = ["E501"]
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["E402"]
[tool.ruff.format]
quote-style = "single"

# ruff.toml (equivalente)
line-length = 88
[lint]
extend-select = ["B"]
[lint.per-file-ignores]
"__init__.py" = ["E402"]
[format]
quote-style = "single"
```

**Achado:** `pyproject.toml` já é fonte única para `pytest` (`[tool.pytest.ini_options]`) e `coverage` (`[tool.coverage.*]`) após 005. Criar `ruff.toml` separado fragmenta config (2 TOMLs) e esconde `[tool.ruff]` quando `ruff.toml` existe (precedência: `ruff.toml` > `pyproject.toml` se ambos existem).

**Decisão (D2):**

* **Fonte única:** `pyproject.toml` com `[tool.ruff]` + `[tool.ruff.lint]` + `[tool.ruff.format]` — **sem** `ruff.toml`/` .ruff.toml` separado em 006.
* **Por quê:** `uv` + `ruff` + `pytest` + `mypy` já compartilham `pyproject.toml` como lock universal; `ruff check`/`ruff format` leem `pyproject.toml` por padrão sem `--config`. `ruff.toml` só seria justificado se o monorepo precisasse de config por pacote (`packages/*` com `ruff.toml` próprio), mas `tool.ruff` suporta `per-file-ignores` e `exclude` glob para isso.

**Alternativa rejeitada:** `ruff.toml` separado — fragmenta, e `pyproject.toml` deixaria de ser fonte única; `.ruff.toml` hidden — convenção legada, menos descoberta.

---

## Q3 — Quais rule sets sênior para este monorepo (E,F,W,I,UP,S,B,A,C4,RUF)?

**Fonte:** `https://docs.astral.sh/ruff/rules/` (737 932 bytes, HTTP 200) + `https://docs.astral.sh/ruff/linter/` + `implementation_plan.md:417` ("Quais rule sets sênior?") + `docs/plan/research/f0-005-pytest.md` D5 (coverage) — fetch 2026-08-31.

Evidências:

> *"Ruff supports over 900 lint rules, many re-implemented in Rust from Flake8, isort, pyupgrade, etc. By default, Ruff enables rules from the F, E, B, UP, and RUF categories, omitting stylistic rules that overlap with `ruff format`."*
> *"If you're just getting started, the default rule set is a great place to start: it catches unused imports with zero configuration. See Default Rules."*

Default Rules (extraído):

```
F  Pyflakes (unused imports, undefined names)
E  pycodestyle errors
W  pycodestyle warnings (W291 trailing whitespace, W293 blank line)
UP pyupgrade (UP007 use `X | Y` for Union, UP043 use `contextlib.suppress`)
B  flake8-bugbear (B006 mutable defaults, B008 function calls in defaults)
RUF Ruff-specific (RUF001 unused noqa, RUF003 comment)
I  isort (import sorting) — NÃO está no default, requer select
C4 flake8-comprehensions — NÃO default
SIM flake8-simplify — NÃO default
S  flake8-bandit (S101 assert, S603 subprocess) — NÃO default, mas crítico para motor determinístico
A  flake8-builtins (A001 shadowing) — NÃO default
D  pydocstyle — NÃO default
```

**Achado estrutural:** `tests/` já existe (005) com `subprocess` (`test_harness_oracles.py` usa `subprocess.run(..., env={"FKX_ORACLE_NESTED":"1"})` sem `shell=True` — seguro, mas `S603`/`S607` flagariam `subprocess` sem `shell=False` explícito se mal configurado. `specs/` tem `*.md` não Python, deve ser excluído.

**Decisão (D3):** `extend-select` sênior **estrito mas não bloqueante** para Fase 0 (sem código de produção ainda, apenas `tests/`):

```toml
[tool.ruff.lint]
select = ["E", "F", "W", "C90"]  # base pycodestyle + mccabe (C90)
extend-select = [
  "I",    # isort — ordena imports (substitui isort)
  "UP",   # pyupgrade — moderniza para 3.12 (X|Y, `contextlib.suppress`)
  "B",    # bugbear — pega B006/B008 que pytest não pega
  "SIM",  # simplify — SIM102/117 reduzem complexidade
  "S",    # bandit — S101/S603/S607 para motor que usa subprocess/git
  "C4",   # comprehensions — C400/C401
  "A",    # builtins — A001/A002
  "RUF",  # Ruff-specific — RUF001/RUF100
  # "D" pydocstyle — deferido a 007+ (sem docstrings ainda)
  # "ARG" flake8-unused-arguments — deferido a 011+ (core)
]
ignore = [
  "E501",   # line-length → ruff format cuida (evita conflito)
  "S101",   # assert permitido em tests/ (BANDIT)
  "S603",   # subprocess sem shell é seguro com FKX_ — mas S603 flagaria subprocess.run sem check; ignorar em 006, reavaliar em 008 (pip-audit)
]
```

* `select = ["E","F","W","C90"]` — base mínima, `C90` (mccabe) pega complexidade >10.
* `extend-select` acima é **sênior**: cobre `pyupgrade` para `3.12`, `bugbear` para defeitos, `bandit` para `subprocess`/`assert`, `isort` para ordenação, `simplify`/`comprehensions` para legibilidade.
* `ignore = ["E501"]` — formatter cuida de `line-length`, linter não deve duplicar (evita `E501` vs `ruff format` conflito).
* `S101`/`S603` ignorados em 006 porque `tests/` usa `assert` e `subprocess` com `FKX_ORACLE_NESTED` (seguro, sem `shell=True`). Em `011` (`packages/core`) `S` será reavaliado.

**Alternativa rejeitada:** `select = ["ALL"]` — 900 regras, `D`/`ANN`/`PT` exigiriam docstrings/annotations que ainda não existem, geraria 100+ violações sem valor em `tests/`; `select = ["E","F"]` apenas — perde `UP`/`B`/`S` que são justamente o ganho sênior de Ruff sobre flake8.

---

## Q4 — Como configurar `line-length`, `target-version`, `exclude` compatível com `pytest`/`mypy`/`uv`?

**Fonte:** `https://docs.astral.sh/ruff/configuration/` (default `line-length=88`, `target-version=py310`, `exclude=[..., ".ruff_cache", ".venv", ...]`) + `pyproject.toml` (005) `requires-python >=3.12,<3.14` + `docs.astral.sh/ruff/formatter/` (Black compat) — fetch 2026-08-31.

Evidências:

> *"If left unspecified, `line-length = 88`, `indent-width = 4`, `target-version = \"py310\"`."*
> *"The Ruff Formatter is a drop-in replacement for Black, available as `ruff format`."*
> *"Exclude a variety of commonly ignored directories: `.git`, `.mypy_cache`, `.pytest_cache`, `.ruff_cache`, `.venv`, ..."* — já em `.gitignore` (`.ruff_cache/` 254, `.mypy_cache/` 217).

**Decisão (D4):**

```toml
[tool.ruff]
line-length = 88
target-version = "py312"
exclude = [".git", ".hg", ".mypy_cache", ".pytest_cache", ".ruff_cache", ".venv", ".tox", "dist", "build", "__pypackages__"]
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"
docstring-code-format = false
docstring-code-line-length = "dynamic"
```

* `line-length = 88` — compatível com Black e com `ruff format` default; `100` seria mais permissivo mas divergiria de `pyproject.toml` histórico (004 `pyproject.toml` sem line-length, default 88).
* `target-version = "py312"` — alinha com `requires-python >=3.12` (005) e com `mypy` `python_version = 3.12` (007). `py310` default seria conservador, mas perderia `X|Y` (`UP007`) que `ruff` pode modernizar para 3.12.
* `exclude` — replica default + garante `.venv`/`dist` não são lintados (já em `.gitignore`).
* `quote-style = "double"` — Black compat; `indent-style = "space"` — idem.

**Alternativa rejeitada:** `line-length = 100` ou `120` — mais permissivo, mas diverge de `ruff format` default e de `implementation_plan` que não especifica; `target-version = "py310"` — conservador, mas `UP` não modernizaria `Union` para `X|Y` (3.10+ vs 3.12).

---

## Q5 — Como funciona `ruff check` vs `ruff format` e como integrar com `uv`?

**Fonte:** `https://docs.astral.sh/ruff/linter/` + `.../formatter/` + `https://docs.astral.sh/ruff/integrations/` + `uv` docs `https://docs.astral.sh/uv/concepts/projects/sync/` — fetch 2026-08-31.

Evidências:

> *"`ruff check` — linter; `ruff check --fix` — auto-fix; `ruff format` — formatter (drop-in Black). `ruff check` e `ruff format` são entradas separadas, mas leem o mesmo `pyproject.toml`."*
> *"`uvx ruff check`" / "`uv run ruff check`" — `uv` pode executar `ruff` sem `pip install` global.*

**Achado:** `ruff` é binário Rust sem `requires_dist` (Q1), `uv` pode instalá-lo via `[dependency-groups] dev` e executá-lo via `uv run ruff check` (como `pytest`). `ruff format` é idempotente (segundo `format` não altera hash).

**Decisão (D5):**

* **Instalação:** `[dependency-groups] dev += ["ruff==0.16.5"]` via `uv add --dev ruff==0.16.5` (mesmo que `pytest` em 005). `uv sync` instala `ruff` em `.venv/bin/ruff`.
* **Invocação determinística:**

```bash
uv run ruff check .          # linter, sem --fix (CI)
uv run ruff check --fix .    # linter com auto-fix (local)
uv run ruff format .         # formatter, idempotente
uv run ruff check --output-format=concise .  # para harness (parseável)
uv run ruff format --check --diff .  # CI verifica se format está aplicado (exit 1 se diff)
```

* Em 006, **sem `--fix` automático no harness**: `f0-006-ruff.sh` deve rodar `ruff check` (sem `--fix`) e `ruff format --check --diff` (sem re-escrever) — apenas leitura, como `oracle-cli.md` exige. `--fix` é conveniência local, não portão.

**Alternativa rejeitada:** `pipx install ruff` global — fora do `uv.lock`, indeterminístico entre máquinas; `pre-commit` hook com `ruff` — é `009` (`lefthook`), não `006`.

---

## Q6 — Como declarar `ruff` via `uv` sem quebrar `pytest`/`mypy`?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/dependencies/` (169KB, PEP 735) + `pyproject.toml` (005) `dev = ["pytest==9.1.1", ...]` + `uv add --help` — fetch 2026-08-31.

Evidência (repetida de Q4 de 005):

> *"`uv add --dev ruff` will create a `dev` group: `[dependency-groups] dev = [\"ruff\"]`"* — `dev` é `default-groups = ["dev"]`, `uv sync` instala `dev` por padrão.

**Decisão (D6):**

```bash
uv add --dev ruff==0.16.5   # → [dependency-groups] dev = ["ruff==0.16.5", "pytest==9.1.1", ...]
uv sync
```

* Resultado `pyproject.toml`:

```toml
[dependency-groups]
dev = ["pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0", "ruff==0.16.5"]
```

* `uv.lock` passa a conter `ruff 0.16.5` com hash (universal). `uv sync --no-dev` omite `ruff` para `013` release.
* `mypy 2.3.1` (007) será `uv add --dev mypy==2.3.1` no mesmo `dev` — sem conflito, ` Ruff` e `MyPy` coexistem no mesmo `dev` porque `ruff` não tem `requires_python` restritivo e `mypy` é `>=3.10`.

**Alternativa rejeitada:** `[tool.ruff]` sem `ruff` em `dev` — `ruff` não estaria no `uv.lock`, `uv run ruff` falharia em CI sem `pip install`; `requirements-dev.txt` — fora do lock universal.

---

## Q7 — Quais vulnerabilidades (`pip-audit`, `trivy`) e como `ruff` ajuda na cadeia?

**Fonte:** `https://pypi.org/pypi/pip-audit/json` + `https://pypi.org/pypi/ruff/json` (sem `requires_dist`, sem CVEs) + `docs/plan/implementation_plan.md:65` (`pip-audit` + `Trivy`) + `https://docs.astral.sh/ruff/rules/#flake8-bandit` (S) — fetch 2026-08-31.

Evidências:

* `ruff` `requires_dist: None` — sem deps Python, superfície de ataque mínima (binário Rust). `pip-audit` (`008`) audita `ruff` via `uv.lock` mas `ruff` raramente tem CVE (vs `pip` deps).
* `S` (bandit) em `ruff` já cobre `S603`/`S607` (subprocess sem shell) e `S101` (assert) — é o `security_scan` que `pip-audit` complementa (vulns em deps, não em código).
* `Trivy` (`008`) escaneia `uv.lock` e `Dockerfile`, não `ruff` especificamente.

**Decisão (D7):**

* Em 006, `ruff` com `S` (`bandit`) é o **primeiro portão de segurança de código** (ex.: `S603` flagaria `subprocess.run(..., shell=True)` que `tests/test_harness_oracles.py` evita com `shell=False` implícito). `pip-audit` e `Trivy` são `008`, não `006` — 006 apenas prepara o `S` que `008` orquestrará via `lefthook` (009).
* Em `006`, `S` é configurado mas `S101`/`S603` são `ignore` em `tests/` (D3) porque `assert` e `subprocess` com `FKX_ORACLE_NESTED` são seguros. Em `011` (`packages/core`) `S` será reavaliado para `src/`.

**Alternativa rejeitada:** `bandit` separado (`pip install bandit`) — redundante, `ruff` já re-implementa `S` em Rust, mais rápido e com `per-file-ignores`.

---

## Q8 — Como `ruff` interage com `.gitignore`, `.venv`, `tests/` e `cache`?

**Fonte:** `https://docs.astral.sh/ruff/configuration/` (default `exclude` lista) + `.gitignore` (`.ruff_cache/` 254, `.venv` 200, `.pytest_cache/` 99) + `pyproject.toml` (005) — fetch 2026-08-31.

Evidências:

> *"Ruff respects `.gitignore` by default? No — `exclude` is separate from `.gitignore`. `ruff` does not read `.gitignore` for linting, but `exclude` defaults to `[".git", ".hg", ..., ".ruff_cache", ".venv", ...]".*
> *"`ruff` cache lives in `.ruff_cache/` (default). `ruff check --no-cache` disables."*

**Achado:** `.gitignore` já ignora `.ruff_cache/` (254), `.venv` (200), `.pytest_cache/` (99) — correto, mas `ruff` **não** lê `.gitignore` para decidir o que lintar; ele usa `exclude`. Portanto `.gitignore` e `exclude` devem estar alinhados, mas são mecanismos distintos.

**Decisão (D8):**

```toml
[tool.ruff]
exclude = [".bzr", ".direnv", ".eggs", ".git", ".git-rewrite", ".hg", ".ipynb_checkpoints", ".mypy_cache", ".nox", ".pants.d", ".pyenv", ".pytest_cache", ".pytype", ".ruff_cache", ".svn", ".tox", ".venv", ".vscode", "__pypackages__", "_build", "buck-out", "build", "dist", "node_modules", "site-packages", "venv"]
```

* Replica default de `ruff` + garante `.venv`/`dist`/`site-packages` não são lintados mesmo se `.gitignore` mudar.
* `tests/` **não** é excluído — `ruff` deve lintar `tests/test_harness_*.py` com `per-file-ignores` para `S101`/`S603`.
* `specs/` e `docs/` são Markdown, não Python — `ruff` ignora por não ser `*.py`, sem `exclude` necessário.

**Alternativa rejeitada:** `extend-exclude` com `.gitignore` — `ruff` não tem `respect_gitignore` para lint; `force-exclude = true` — desnecessário em 006 (sem `packages/`).

---

## Q9 — O que o harness de 006 deve verificar (e o que NÃO verificar)?

**Fonte:** `specs/001-.../contracts/oracle-cli.md` + `scripts/verify/README.md` (restrição `005+ pytest`, `006+ Ruff`) + `specs/005-pytest/contracts/pytest-contract.md` — fetch 2026-08-31.

Evidências:

> *"Um oráculo que exija ferramenta ainda não instalada no seu ponto do bootstrap está errado, ainda que funcione na máquina de quem o escreveu."* — `README.md:79` (restrição por item).

**Decisão (D9):** `f0-006-ruff.sh` com **10–14 asserções** (similar a `f0-005`):

| FR candidato | Verificável por harness | Como |
|---|---|---|
| `[tool.ruff]` existe com `line-length 88` e `target-version py312` | sim | `tomllib` parse |
| `ruff.toml` **não** existe (fonte única) | sim | `! test -f ruff.toml` |
| `ruff==0.16.5` em `[dependency-groups] dev` | sim | `tomllib` + `uv.lock` grep |
| `uv.lock` contém `ruff` | sim | `grep 'name = "ruff"'` |
| `.ruff_cache/` gitignored | sim | `git check-ignore -q` |
| `ruff check --output-format=concise` 0 em repo conforme | sim | `uv run ruff check --quiet` (quando `ruff` instalado) |
| `ruff format --check --diff` 0 (idempotente) | sim | `uv run ruff format --check` |
| `RUF`/`UP`/`B` rules ativas | sim | `grep -q 'extend-select.*RUF'` |
| `E501` ignorada (format cuida) | sim | `grep -q 'ignore.*E501'` |
| Fronteira: sem `mypy.ini`/`lefthook.yml`/`packages/` | sim | `! test -f mypy.ini` etc. |

**NÃO verificar em 006** (Escada):

* `mypy` strict (`007`), `lefthook.yml` (`009`), `pip-audit` (`008`), `packages/` (`011`/`012`).

**Decisão (D9):** oráculo `f0-006-ruff.sh` segue `oracle-cli.md` (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER`, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`). `pytest` (`f0-005`) deve continuar passando (`self-check`).

---

## Q10 — Determinismo e fronteira Escada para `ruff` (compatibilidade `mypy`/`uv`)?

**Fonte:** `constitution.md:176` (Escada) + `docs/plan/implementation_plan.md:835-846` (§17) + `specs/005-pytest/spec.md:190` (Out of Scope) — fetch 2026-08-31.

Evidências Escada:

> *"Nenhum artefato pode exigir ferramenta que ainda não existe no seu ponto do bootstrap."*

**Decisão (D10):**

* **Determinismo:** `ruff check` e `ruff format` são **idempotentes**: `ruff format` segunda vez não altera hash (`sha256sum` idêntico), `ruff check` segunda vez 0 se 0. Harness deve asserir `ruff format --check` idempotente. `ruff` cache `.ruff_cache/` é ignorado (`.gitignore` 254) e não afeta determinismo (`--no-cache` para teste de determinismo).
* **Compatibilidade `mypy` (007):** `ruff` `UP` moderniza `Union` para `X|Y` (3.12), que `mypy 2.3.1` entende; `ruff` `I` ordena imports que `mypy` não verifica; `ruff` `E`/`W` não conflitam com `mypy` `strict` (exceto `ANN`/`D` que estão `ignore` em 006). `per-file-ignores` para `tests/` (`S101`, `S603`) evita conflito com `pytest` `assert`/`subprocess`.
* **Fronteira Escada (006):** **NÃO** cria `mypy.ini`/`[tool.mypy]` (é `007`), `lefthook.yml` (`009`), `pip-audit` (`008`), `packages/` (`011`/`012`), `ruff.toml` separado (é `pyproject.toml` em 006 per D2).

**Decisão (D10):** em 006, garantir apenas `pyproject.toml` `[tool.ruff]` + `ruff==0.16.5` em `dev` + `uv.lock` + `.ruff_cache` ignorado. Escala para `007` (`mypy` lê `pyproject.toml`), `009` (`lefthook` orquestra `ruff check`/`format`), `010` (`ruff` em CI `uv run ruff check`).

---

## Resumo das decisões vinculantes

| # | Decisão | Fonte |
|---|---|---|
| D1 | `ruff==0.16.5` via `[dependency-groups] dev` (PEP 735), `uv sync` | Q1 PyPI 2026-08-27 simple index |
| D2 | `pyproject.toml` `[tool.ruff.*]` fonte única, sem `ruff.toml` | Q2 docs.astral.sh/configuration 129KB |
| D3 | `select = ["E","F","W","C90"]` + `extend-select = ["I","UP","B","SIM","S","C4","A","RUF"]` `ignore = ["E501","S101","S603"]` | Q3 rules/ 737KB |
| D4 | `line-length=88` `target-version=py312` `exclude=[.git,...,.ruff_cache,.venv]` + `[tool.ruff.format] quote-style double` | Q4 docs/formatter 95KB + requires-python |
| D5 | `uv run ruff check` / `uv run ruff format --check --diff` idempotente, sem `--fix` no harness | Q5 docs/linter+formatter 93KB |
| D6 | `uv add --dev ruff==0.16.5` → `dev` com `pytest`+`ruff` coexistindo, `uv.lock` universal | Q6 docs.astral.sh/uv 169KB |
| D7 | `S` (bandit) como portão código, `pip-audit`/`trivy` deferidos a 008 | Q7 bandit docs + plan §65 |
| D8 | `exclude` replica default + `tests/` lintado com `per-file-ignores` | Q8 docs/configuration + .gitignore |
| D9 | Harness `f0-006-ruff.sh` 10–14 asserções só ruff, sem mypy/lefthook | Q9 oracle-cli + README |
| D10 | Determinismo `ruff format` idempotente, compat `mypy` UP/I, fronteira Escada (006 só ruff) | Q10 constitution |

**Nenhum `NEEDS CLARIFICATION` remanescente.** Próxima etapa: `SPECIFY` da spec `006 — Ruff 0.16.5`.

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **007 MyPy 2.3.1** | `pyproject.toml` com `[tool.ruff]` estável onde `[tool.mypy]` coexistirá; `ruff` `UP`/`I` não conflitam com `mypy strict` |
| **008 pip-audit+Trivy** | `uv.lock` com `ruff 0.16.5` hash auditável; `ruff S` já cobre `subprocess`/`assert` |
| **009 Lefthook** | `ruff check`/`format` orquestráveis via `lefthook.yml` (`uv run ruff check --fix`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `ruff` em `uv.lock` para `uv run ruff check` determinístico em CI; `ruff format --check` idempotente |
| **011 core / 012 cli** | `pyproject.toml` `[tool.ruff]` com `per-file-ignores` para `tests/` → escala para `packages/*/tests` sem reescrever |
| **014 Renovate** | `ruff==0.16.5` pin para agrupamento e automerge |

## Pacotes e versões pinadas verificadas em 2026-08-31

| Pacote | Versão verificada | Fonte | Nota |
|---|---|---|---|
| `ruff` | `0.16.5` | PyPI `ruff/json` + simple index last 10 | `>=3.7`, upload 2026-08-27, binário Rust sem deps |
| `mypy` | `2.3.1` | PyPI `mypy/json` | `>=3.10`, compatível com `ruff` 0.16.5 |
| `pytest` | `9.1.1` | PyPI `pytest/json` (re-verificado 2026-08-31) | `dev` já em 005, coexiste com `ruff` |
| `Python` | `3.12.3` local, `3.12` família, `>=3.12,<3.14` | `python --version` + `requires-python` | `ruff target-version py312` alinha |
| `uv` | `0.12.7` | PyPI `uv/json` | `uv add --dev ruff` → `dependency-groups` |
| `ruff config` | `[tool.ruff]` `line-length 88` `target-version py312` | `docs.astral.sh/ruff/configuration` 129KB | `ruff.toml` rejeitado para fonte única |
| `ruff rules` | `E,F,W,C90` + `I,UP,B,SIM,S,C4,A,RUF` | `docs.astral.sh/ruff/rules` 737KB | `D`/`ANN` deferidos a 007+ |
