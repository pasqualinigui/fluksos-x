# RESEARCH — F0/005 · Pytest 9.1.1 — harness TDD

> **Item do plano:** 0.4 (§17 Fase 0) · **Ordem de execução:** 005/016 (ADR-011)
> **Data da verificação:** 2026-08-31 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/004-uv-workspace/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-006, ADR-007, ADR-011, ADR-014, ADR-015) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-.../contracts/oracle-cli.md` + `scripts/verify/README.md`

Este item entrega **a primeira ferramenta de qualidade que habilita TDD real** (ADR-001, `scripts/verify/README.md` Restrição). Até aqui o harness é só shell+git+Python 3.12 stdlib. A partir dele `pytest` é o verificador que promove cada `f0-NNN-*.sh` a módulo de teste equivalente (`--list` existe para isso). É também o **item pagador de dívidas**: 5 casos da ADR-007 + 4 achados da auditoria `f0-audit-001-004.md` (A1/A2/M4/B2) + padrão corrigido da ADR-015 (manifesto, mapa FR, CONVERGE, self-check total). Não cria `ruff`/`mypy`/`lefthook`/`pip-audit`/`trivy` nem `packages/` — estes são specs 006–009 e 011/012 (Escada, constitution Additional Constraints).

---

## Q1 — Qual pin canônico de `pytest` + plugins em 2026-08-31?

**Fonte:** `https://pypi.org/pypi/pytest/json` + `.../pytest/9.1.1/json` + `.../pytest-asyncio/json` + `.../pytest-cov/json` + `.../coverage/json` + `.../pluggy/json` + `.../iniconfig/json` + `https://pypi.org/pypi/uv/json` — HTTP 200, fetch 2026-08-31.

Evidências:

```
pytest           9.1.1  requires_python='>=3.10' upload 2026-06-19T10:58:31Z
  releases: ['9.0.1', '9.0.2', '9.0.3', '9.1.0', '9.1.1']  → 9.1.1 é latest estável
  requires_dist: ['iniconfig>=1.0.1', 'packaging>=22', 'pluggy<2,>=1.5',
                  'pygments>=2.7.2', 'tomli>=1; python_version < "3.11"',
                  'colorama>=0.4; sys_platform=="win32"',
                  'exceptiongroup>=1; python_version<"3.11"']
pytest-asyncio   1.4.0  requires_python='>=3.10' upload 2026-05-26T09:56:02Z
  requires_dist: ['pytest<10,>=8.4', 'backports-asyncio-runner; py<3.11', 'typing-extensions>=4.12; py<3.13']
pytest-cov       7.1.0  requires_python='>=3.9' upload 2026-03-21T20:11:14Z
  requires_dist: ['coverage[toml]>=7.10.6', 'pytest>=7', 'pluggy>=1.2']
coverage         7.16.0 requires_python='>=3.10' upload 2026-08-28T21:50:37Z
pluggy           1.6.0  >=3.9
iniconfig        2.3.0  >=3.10
uv               0.12.7 >=3.8  (confirma implementation_plan §4 pin)
```

Docs: `https://docs.pytest.org/en/stable/changelog.html` 1 185 361 bytes, HTTP 200 — lista `9.1.1` como release estável com `minversion` e `pytest.toml`/`[tool.pytest]` novidades 9.0.

**Achado estrutural hoje:** `pyproject.toml` com `dependencies=[]`, sem `[dependency-groups]` nem `[tool.pytest]`; `ls tests/ → inexistente`; `ls packages/ → inexistente`; local `Python 3.12.3`, `uv 0.12.1` (desatualizado 6 patches atrás, D5 de 004).

**Decisão (D1):** pin canônico em **2026-08-31**:

```toml
[dependency-groups]
dev = ["pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

* `pytest==9.1.1` — latest, `>=3.10` compatível com `requires-python >=3.12,<3.14`.
* `pytest-asyncio==1.4.0` — latest, `pytest<10,>=8.4` casa com 9.1.1; sem `pytest-asyncio` o oráculo promovido que usa `async def` falharia silenciosamente.
* `pytest-cov==7.1.0` — traz `coverage[toml]>=7.10.6` (resolve para `coverage 7.16.0`).
* Não pinar `pluggy`/`iniconfig`/`packaging` transitivos — resolvidos pelo lock.
* `uv` permanece `0.12.7` (`uv_build>=0.12.7,<0.13` em `build-system`); local `0.12.1` deve convergir via `uv self update` (D5 de 004).

**Alternativa rejeitada:** `pytest>=9` flutuante — indeterminístico, lock mudaria sem mudança no `pyproject.toml`; `requirements-dev.txt` — duplica lock, fora do modelo `dependency-groups` PEP 735; `pytest 8.x` — perde `pytest.toml`/`[tool.pytest]` e `minversion` 9.0.

---

## Q2 — Onde vivem os testes e como `pytest` os descobre?

**Fonte:** `https://docs.pytest.org/en/stable/how-to/usage.html` (discovery, `testpaths`) + `https://docs.pytest.org/en/stable/reference/customize.html` (`python_files`, `python_classes`, `python_functions`, `pythonpath`, `import-mode`) — HTTP 200, 41 444 e 51 717 bytes, fetch 2026-08-31.

Evidências:

> *"`testpaths` — list of paths to search for tests when no path given on command line."*
> *"`python_files = test_*.py  *_test.py` — glob for test module file names."*
> *"`pythonpath` — list of paths to prepend to `sys.path`."*
> *"`[tool.pytest.ini_options]` supported since 6.0; `[tool.pytest]` native TOML since 9.0; `pytest.toml`/`.pytest.toml` new in 9.0 take precedence even when empty."*

Exemplo canônico da fonte (`reference/customize.html`):

```toml
# pyproject.toml
[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q"
testpaths = ["tests", "integration"]
```

> *"If `pytest.toml` exists, `pyproject.toml` settings are ignored."* — implicação: não criar `pytest.toml` separado se `pyproject.toml` já é fonte única.

**Achado estrutural:** `tests/` inexistente; `specs/` existe mas não é coleta; `packages/` inexistente (workspace vazio válido, 004). `.gitignore` já ignora `.pytest_cache/`, `htmlcov/`, `.coverage*` (linhas 86–99, 217) — correto para pytest.

**Decisão (D2):**

* **Raiz:** `tests/` na **raiz do repositório** (fora de `packages/`). Motivo: `005` antecede `011` (`packages/core`) e `012` (`packages/cli`); criar `packages/core/tests/` agora antecipa responsabilidade de `011` e viola Escada. `tests/` raiz é o padrão pytest + `src` layout e é o que `uv workspace` com zero membros já suporta.
* **Config:** em `pyproject.toml`, **sem** `pytest.toml`/`pytest.ini`/`setup.cfg` separados:

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
```

* `tests/conftest.py` mínimo ( fixtures globais futuras ), com `pytest_plugins` vazio; `tests/__init__.py` **não** criado (namespace package implícito desde pytest 3, evita `pkg_resources` ).
* `import-mode` default `prepend` é correto; não fixar `importlib` sem necessidade.

**Alternativa rejeitada:** `pytest.toml` separado — fragmenta config (lock já está em `pyproject.toml`), e take-precedence esconderia `[tool.pytest.ini_options]`; `tests` dentro de `specs/` — confunde spec (artefato versionado) com execução (verificação); `pythonpath = ["src"]` — não existe `src/` no root virtual (004 `tool.uv.package=false`).

---

## Q3 — Como configurar `pytest-asyncio` sem quebrar determinismo?

**Fonte:** `https://pytest-asyncio.readthedocs.io/en/latest/` (6 503 bytes) + `.../reference/configuration.html` (10 701 bytes, HTTP 200) + `.../how-to-guides/index.html` (7 317 bytes) — fetch 2026-08-31. + `https://pypi.org/pypi/pytest-asyncio/json` `requires_dist: pytest<10,>=8.4`.

Evidência:

> *"`asyncio_mode = auto` — all `async def test_*` are run without marker."*
> *"`asyncio_mode = strict` (default since 0.23) — require `@pytest.mark.asyncio`."*
> *"`asyncio_default_fixture_loop_scope = function|class|module|package|session"` — scope do loop para fixtures async."*
> Pesquisa local: `pytest-asyncio 1.4.0` declara `backports-asyncio-runner` apenas para `python_version < "3.11"` — em `3.12` não é instalado, sem overhead.

**Decisão (D3):**

```toml
[tool.pytest.ini_options]
asyncio_mode = "strict"
asyncio_default_fixture_loop_scope = "function"
```

* `strict` exige `@pytest.mark.asyncio` explícito — cada teste async fica **grepeável** (`grep -r asyncio`), rastreável a requisito, e não executa async escondido. É a aplicação do Princípio X (observabilidade por FR).
* `function` é o scope mais isolado; `session` reutilizaria loop entre testes e esconderia vazamento de estado — indeterminístico.
* Em `005` não há teste async real ainda, mas a config entra agora para que `006+` (agentes com `asyncio`) não reescreva `pyproject.toml` sem spec.

**Alternativa rejeitada:** `asyncio_mode = "auto"` — comodidade à custa de observabilidade; executa `async def test_*` sem marcador, e um teste esquecido sem `await` vira falso-positivo silencioso; `trio`/`anyio`/`pytest-anyio` — sem caso de uso em 005, antecipa stack de agente (Fase 2).

---

## Q4 — Como declarar `dev` deps no workspace UV (`dependency-groups` vs legado)?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/dependencies/` (169 450 bytes) + `.../concepts/projects/layout/` (72 980 bytes) + `.../concepts/projects/sync/` (81 839 bytes) + `uv add --help` + `uv sync --help` — fetch 2026-08-31.

Evidências (texto extraído):

> *"uv uses the `[dependency-groups]` table (as defined in PEP 735) for declaration of development dependencies."*
> *"`$ uv add --dev pytest` will create a `dev` group: `[dependency-groups] dev = ["pytest >=8.1.1,<9"]`"*
> *"`The `dev` group is synced by default. Use `--no-dev` to disable."*
> *"`If a `tool.uv.dev-dependencies` field exists, `uv add --dev` will use the existing section instead of adding a new `dependency-groups.dev` section. Eventually, the `dev-dependencies` field will be deprecated."*
> *"`development dependencies are local-only and will not be included when published to PyPI."*

`uv add --help` confirma flags: `--dev`, `--group <GROUP>`, `--only-dev`, `--no-dev`, `--all-groups`, `--locked`, `--frozen`.

`uv.lock` atual (381 linhas Q7): `requires-python = ">=3.12,<3.14"`, `[[package]] name="fluksos-x" source={virtual="."}` — lock vazio válido, já cobre `dependency-groups` sem reescrever `[project]`.

**Decisão (D4):**

* Em `005`, **`uv add --dev pytest==9.1.1 pytest-asyncio==1.4.0 pytest-cov==7.1.0`** — escreve em **`[dependency-groups]`**, não em `[project.dependencies]` nem `[tool.uv.dev-dependencies]` legado.
* Resultado esperado em `pyproject.toml`:

```toml
[dependency-groups]
dev = ["pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

* `uv sync` instala `dev` por default; `uv sync --no-dev` omitiria (útil para `013` release, sem `pytest` no artefato).
* `uv sync --locked` / `--frozen` permanecem política de `010` (CI completo), não de `005` — `005` materializa lock via `uv sync` sem flag (D6 de 004), idem aqui.
* Cada `packages/<name>/pyproject.toml` futuro declara seu próprio `[dependency-groups] dev` se precisar; `uv.lock` único na raiz unifica resolução (Q4 de 004 `tool.uv.workspace members=["packages/*"]` + `single requires-python`).

**Alternativa rejeitada:** `[project.dependencies]` para pytest — polui runtime, `pip-audit` futuro flagaria `pytest` como vulnerabilidade de produção; `[tool.uv.dev-dependencies]` legado — deprecated, e `uv add --dev` já não o cria se `dependency-groups` não existe; `requirements-dev.txt` — fora do lock universal, quebra `uv sync --frozen` determinístico.

---

## Q5 — Cobertura: `pytest-cov` agora é relatório ou já é portão?

**Fonte:** `https://pytest-cov.readthedocs.io/en/latest/` (22 728 bytes) + `https://coverage.readthedocs.io/en/latest/config.html` + `https://docs.coverage.org` + `implementation_plan.md:862` (CI completo 010 traz *"portão de cobertura"*) + `uv docs` sync (Q6 de 004).

Evidência:

> *"`--cov=PKG --cov-report=term-missing:skip-covered --cov-fail-under=80` — fail if coverage below threshold."*
> *"`[tool.coverage.run] branch = true` — measure branch coverage."*
> *"`[tool.coverage.report] show_missing = true, skip_covered = false"` — reporta linhas não cobertas.*

Plano: `010 (0.14 CI completo)` lista *"portão de cobertura"*; `005` é `pytest` sem Ruff/MyPy ainda, sem pacote `core` para cobrir — exigir `--cov-fail-under` agora reprovaria por ausência de código, não por qualidade.

**Decisão (D5):** em `005` **relatório apenas**, sem portão:

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

* `pytest` invocado como `uv run pytest --cov=tests --cov-report=term-missing` em local/CI, sem `--cov-fail-under`.
* `.gitignore` já cobre `.coverage`, `.coverage.*`, `htmlcov/`, `coverage.xml` (linhas 90–99) — sem edição.
* Portão (`--cov-fail-under=80` + `required check`) entra em `010`, quando `packages/core` existe e baseline é mensurável.

**Alternativa rejeitada:** `--cov-fail-under` em `005` — sem código produtivo, falha por tautologia; `parallel = true` + `coverage combine` — só com `xdist`, que está rejeitado em `005` (D9); `source = ["packages"]` — `packages/` não existe, `coverage` falharia com `No data to report`.

---

## Q6 — Como promover `f0-NNN-*.sh` a pytest sem reescrever oráculo?

**Fonte:** `specs/001-git-branching-strategy/contracts/oracle-cli.md` (§1–§6, 206 linhas) + `scripts/verify/f0-004-uv-workspace.sh:50-110` (`CANON` map + `--list` + `FKX_ORACLE_NESTED`) + `scripts/verify/README.md:124-130` (Promoção a pytest) + `https://docs.pytest.org/en/stable/how-to/parametrize.html` + `https://docs.pytest.org/en/stable/how-to/capture.html` (subprocess).

Evidência contrato:

```
f0-NNN.sh [--quiet] [--list]  →  exit 0 conforme / 1 não conforme / 2 erro uso
Uma linha por asserção:  ✅ FR-001 ... / 🔴 FR-XXX ... / ⏭️ ...
--list imprime CANON_ORDER sem executar; --quiet só violações
Raiz resolvida por SCRIPT_DIR, nunca $PWD; FR-018 determinismo; FKX_ORACLE_NESTED evita recursão
```

Evidência promoção (README):

> *"O item `004` converte cada `f0-NNN-*.sh` em módulo de teste equivalente, um caso por asserção. `--list` existe exatamente para isso."*

Achado crítico A2 (`f0-audit-001-004.md:78-88`): `spec 004` definiu `FR-001..017` mas oráculo emitiu `FR-001..014` com remapeamento não documentado (`FR-013` cobre `FR-016/017`, `FR-015` sem asserção). Viola Princípio X — falha não nomeia FR da spec.

**Decisão (D6):**

* **Arquivo:** `tests/test_harness_oracles.py` (ou `tests/test_oracle_promotion.py`) — único arquivo para promoção, para não fragmentar.
* **Mecanismo:**

```python
import subprocess, pathlib, re, glob
ORACLES = sorted(pathlib.Path("scripts/verify").glob("f0-*.sh"))

def _canon_ids(oracle: pathlib.Path) -> list[str]:
    out = subprocess.run([str(oracle), "--list"], capture_output=True, text=True, env={"FKX_ORACLE_NESTED":"1", **dict(**{})})
    return [line.split()[1] for line in out.stdout.splitlines() if line.strip()]

@pytest.mark.harness
@pytest.mark.parametrize("oracle", ORACLES, ids=lambda p: p.name)
def test_oracle_exit_codes_and_format(oracle):
    r = subprocess.run([str(oracle)], capture_output=True, text=True, env={"FKX_ORACLE_NESTED":"1"})
    assert r.returncode in (0,1)  # 2 só para uso inválido
    assert re.search(r"^(✅|🔴|⏭️) FR-\d+", r.stdout, re.M)

def test_oracle_list_enumerates_canon():
    # cada oráculo deve ter CANON_ORDER == --list
    ...
```

* **Mapa FR quando não for identidade:** se `spec FR-001..015` for fragmentado em `FR-001a/b` no oráculo, o mapa vai em `specs/005-pytest/contracts/oracle-cli.md` (ADR-015b) — não silencioso.
* **Sem reescrita de `.sh`:** `.sh` permanece fonte de verdade; pytest só orquestra via `subprocess` com `FKX_ORACLE_NESTED=1` (evita recursão `FR-014` que roda `f0-001`/`f0-003` dentro de si, `f0-004:412-446`).

**Alternativa rejeitada:** reescrever `.sh` em Python — quebra ADR-002 *"um item nunca modifica oráculo anterior"* e invalida `manifest.sha256`; parsear `.sh` via regex frágil — `CANON` é fonte única, `--list` é a API; `pytest-shell` plugins — dependência extra sem ganho, `subprocess` stdlib basta.

---

## Q7 — Determinismo empírico e tempo `<5s` (dívida ADR-007 SC-003) como teste pytest?

**Fonte:** `docs/plan/decisions.md:351-404` (ADR-007, 5 lacunas) + `f0-audit-001-004.md:98-104` (M4, B2) + `scripts/verify/f0-004-uv-workspace.sh:449-484` (FR-014 `date +%s` vs `EPOCHSECONDS`) + `constitution.md:57-64` (Princípio I) + `oracle-cli.md:177 FR-018`.

Evidência dívida:

| Lacuna | Origem | FR em 001 |
|---|---|---|
| `SC-003` tempo `<5s` empírico | checagem estática `FR-018` vs execução real | `SC-003` |
| `SC-003` determinismo 2 execuções byte-a-byte | `FR-018` só fonte, não saída | `SC-003` |
| `SC-004` par vermelho→verde | nenhum `evidence/red.txt` | `SC-004` |
| `SC-007` contratos declarados | sem seção Contratos | `SC-007` |
| `FR-001` mede HEAD, não `refs/heads/main` | `f0-001:FR-001` `git rev-parse --abbrev-ref HEAD` | `FR-001` |

B2: `f0-004:449` usou `date +%s` (fork externo) para `<5s` — construção não determinística para asserir determinismo.

**Decisão (D7):**

* **Tempo:** usar `EPOCHSECONDS` (builtin bash, sem fork) — já previsto em `f0-004:467` fallback mas corrigido como padrão em `005`. Em pytest, medir via `time.monotonic()` em Python, não via `date`:

```python
import time, subprocess
def test_oracle_runtime_lt_5s(oracle=pathlib.Path("scripts/verify/f0-001-foundation.sh")):
    start = time.monotonic()
    subprocess.run([str(oracle)], capture_output=True, env={"FKX_ORACLE_NESTED":"1"})
    assert time.monotonic() - start < 5.0
```

* **Determinismo:**

```python
def test_oracle_deterministic():
    r1 = subprocess.run(["scripts/verify/f0-001-foundation.sh"], capture_output=True, text=True)
    r2 = subprocess.run(["scripts/verify/f0-001-foundation.sh"], capture_output=True, text=True)
    assert r1.stdout == r2.stdout and r1.returncode == r2.returncode
```

* **Casos nomeados (5) a criar em `tests/test_harness_debts.py`:**

| Teste | Cobre |
|---|---|
| `test_f0_001_runtime_lt_5s` | SC-003 tempo |
| `test_f0_001_deterministic_output` | SC-003 determinismo |
| `test_red_green_pair_distinct` | SC-004 — exige `specs/*/evidence/red.txt` e `green.txt` distintos quando existirem; em `005` verifica que `f0-005` tem ambos |
| `test_contracts_section_exists` | SC-007 — `grep -q "### Entregue por este item"` em cada `spec.md` |
| `test_main_branch_exists` | FR-001 — `git show-ref --verify refs/heads/main` (não `HEAD`) |

* `red.txt`/`green.txt` de `005` serão gerados nas fases TESTS 🔴 / IMPLEMENT 🟢 do ciclo canônico (constitution `Development Workflow`).

**Alternativa rejeitada:** `date +%s` (fork, B2), `time` externo, `cmp` de arquivos temporários sem `FKX_ORACLE_NESTED` (recursão), `sleep` para "garantir" tempo — esconde indeterminismo.

---

## Q8 — Manifesto `manifest.sha256` e self-check completo (ADR-015a/e)

**Fonte:** `docs/plan/decisions.md:1023-1041` (ADR-015) + `man sha256sum` + `git hash-object` + verificação `sha256sum scripts/verify/f0-*.sh` 2026-08-31.

Evidência congelada 2026-08-30 (re-medida 2026-08-31 idêntica):

```
63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22  scripts/verify/f0-001-foundation.sh
406d72528ddebba417887a65f553c99d9c7df8982fb2b72672904b3ec09386a7  scripts/verify/f0-002-constitution.sh
d10c61e8623fcf3f7c706ab8ca7387303c2d5282da0afaee50bf5c6401b6f7d4  scripts/verify/f0-003-ci-minimo.sh
3db36208b4e13fb24bace3aaa3247224f163ca02a070d8b15e64084b1bafd88e  scripts/verify/f0-004-uv-workspace.sh
```

`MANIFEST INEXISTENTE` em disco 2026-08-31 (`ls scripts/verify/manifest.sha256 → inexistente`) — dívida A1: cadeia parou em `002` (`FR-021a`), `003`/`004` só fazem `f0-001 --quiet` (aprovação, não integridade).

**Decisão (D8):**

* **Criar em `005`:** `scripts/verify/manifest.sha256` com **5 linhas** (001..005, ordem execução ADR-011), formato nativo `sha256sum` (para `sha256sum -c`, sem parser):

```
63412ca7...  scripts/verify/f0-001-foundation.sh
406d725...  scripts/verify/f0-002-constitution.sh
d10c61e...  scripts/verify/f0-003-ci-minimo.sh
3db3620...  scripts/verify/f0-004-uv-workspace.sh
<hash-005>  scripts/verify/f0-005-pytest.sh
```

* **Oráculo `f0-005-pytest.sh` assere:** `sha256sum -c scripts/verify/manifest.sha256` exit 0 (ADR-015a). Divergência sobe para ADR, nunca `sed -i` no hash.
* **Self-check total (ADR-015e):** `f0-005` executa `--quiet` de `f0-001`, `f0-002`, `f0-003`, `f0-004` — **todos**, não subconjunto (fecha M4 onde `004` pulou `002`). CI `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` já cobre via glob, mas execução isolada de `f0-005` deve provar também.

**Alternativa rejeitada:** `git hash-object` — hash de conteúdo git, não de arquivo em disco (ignora modo executável); `sha256sum` com `*` vs ` ` (binário vs texto) — usar `  ` (dois espaços) canônico; manifesto por item (`f0-NNN.sha256`) — fragmenta, perde atomicidade.

---

## Q9 — Quais flags garantem determinismo entre local e CI (`addopts`, `cacheprovider`, `pythonpath`)?

**Fonte:** `https://docs.pytest.org/en/stable/reference/customize.html` + `.../how-to/cache.html` + `.../how-to/mark.html` (mark `strict`) + `https://docs.pytest.org/en/stable/reference/exit-codes.html` + `scripts/verify/README.md:69-78` (Restrição por item).

Evidências:

> *"`addopts = "-ra --strict-markers --strict-config"` — report all except passed, fail on unknown markers/config."*
> *"`minversion = "9.1"` — fail if pytest older."*
> *"`cache_dir = .pytest_cache"` — `cacheprovider` plugin; `norecursedirs` deprecated."*
> *"`testpaths` limits collection to named dirs — avoids collecting `specs/` or `.venv`."*

Achado: `.gitignore` já ignora `.pytest_cache/` (linha 99), `.coverage*`, `htmlcov/` (linhas 86–99) — correto; `001`–`003` só usavam `python3 -c` stdlib, `005+` pode usar `pytest` mas **não** pode exigir `ruff`/`mypy`.

**Decisão (D9):**

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

* `minversion = "9.1"` — reprova `8.x` que não entende `[tool.pytest]`.
* `addopts = "-ra --strict-markers --strict-config"` — sem `-q` default (observabilidade `🔴` via `oracle-cli.md`); `-ra` reporta `xfail`/`xpass`/`skip`.
* `pythonpath = ["."]` — `tests/` importa projeto como `fluksos_x` se `src` existir, mas em 005 root virtual já basta.
* `testpaths = ["tests"]` — impede coleta em `specs/` (onde `evidence/red.txt` vive) e `scripts/`.
* `markers` registrados — sem `strict-markers`, typo `@pytest.mark.harnes` passaria silencioso.
* `filterwarnings = ["error"]` — warning vira erro, impede `DeprecationWarning` silencioso de `pytest-asyncio` 1.4.0 vs `pytest` 9.1.1.
* `xfail_strict = true` — `xfail` que passa vira falha, útil para dívida SC-004 quando `red.txt` ainda não existe.
* **Rejeitar `xdist` em 005** (`AGENTS.md:9-10` e plano de 2026-08-31): `execnet` + `pytest-xdist -n auto` introduz `load`/`worksteal` scheduling não determinístico, quebra `coverage` `parallel` e `tmp_path` compartilhado. Em 005 suite ≈ 80 asserts, ganho 0s. Reavaliar só em `010` se `harness completo >30s`.

**Alternativa rejeitada:** `addopts = "-v --tb=short"` — `-v` muda saída por versão, quebra `cmp` determinismo; `cache_dir = /tmp` — esconde flake de cache; `norecursedirs = ["specs"]` — redundante com `testpaths`; `pytest-xdist` — indeterminístico para harness oráculo (Princípio I).

---

## Q10 — O que a spec `005` deve e NÃO deve verificar (fronteira Escada)?

**Fonte:** `constitution.md:176 Additional Constraints` (Escada) + `docs/plan/implementation_plan.md:825-879` (§17 + Emenda 1) + `specs/004-uv-workspace/spec.md:190` (Out of Scope) + `scripts/verify/README.md:69-78` + ADR-015d (CONVERGE fecha lista).

Evidência Escada:

> *"Nenhum artefato pode exigir ferramenta que ainda não existe no seu ponto do bootstrap. Um verificador que dependa de ferramenta posterior está errado, ainda que funcione na máquina de quem o escreveu."*

Evidência fronteira 004 (`Out of Scope`): sem `packages/` nem `ruff`/`mypy`/`pytest` em `004` — por isso `f0-004:384-396` reprova `[tool.ruff]`, `[tool.mypy]`, `[dependency-groups]`.

**Decisão (D10):**

**Deve verificar (12–16 asserções em `f0-005-pytest.sh`):**

| FR | Cobertura |
|---|---|
| `FR-001` | `pyproject.toml` contém `[dependency-groups] dev` com `pytest==9.1.1` exato |
| `FR-002` | `pytest-asyncio` e `pytest-cov` pinados em `dev` |
| `FR-003` | `[tool.pytest.ini_options]` existe com `minversion`, `testpaths`, `addopts`, `asyncio_mode=strict` |
| `FR-004` | `tests/conftest.py` existe e é `python -m py_compile` válido |
| `FR-005` | `tests/test_harness_oracles.py` existe e coleta ≥1 teste por oráculo |
| `FR-006` | `uv.lock` contém `pytest` com hash (não editado manualmente, `uv lock --check` quando `uv` presente) |
| `FR-007` | `.pytest_cache/` e `htmlcov/` gitignored (`git check-ignore -q`) |
| `FR-008` | `manifest.sha256` existe com 5 linhas `sha256sum` válidas, `sha256sum -c` exit 0 |
| `FR-009` | Self-check `f0-001`..`f0-004 --quiet` todos aprovam |
| `FR-010` | 5 casos ADR-007 nomeados existem como funções `test_*` em `tests/` |
| `FR-011` | `uv run pytest -q` exit 0 em repo conforme |
| `FR-012` | CI `003` glob inclui `f0-005` sem editar `ci.yml` |
| `FR-013` | CONVERGE: `tasks.md` zero `[ ]` (ADR-015d) — asserido pelo próprio `f0-005` |
| `FR-014` | Determinismo: 2× `pytest -q` saída idêntica, `<5s` por `EPOCHSECONDS` |
| `FR-015` | Fronteira: sem `ruff`/`mypy`/`lefthook`/`pip-audit`/`trivy` configs |

**NÃO deve verificar (reprova se presente — Escada):**

* `ruff.toml` / `[tool.ruff]` / `lefthook.yml` / `.trivyignore` — são `006`–`009`
* `mypy.ini` / `[tool.mypy]` — `007`
* `packages/` com `pyproject.toml` — `011`/`012` (em `005` só `tests/`)
* `--cov-fail-under` como portão — `010`
* `pytest-xdist` / `execnet` — rejeitado em `005`

**Fronteira de performance/segurança em 005:**

* **Determinismo:** cada `test_*` deve ser hermético (sem `time.sleep`, `random`, `date`, `GITHUB_RUN_NUMBER`); `addopts` sem `-n`, `filterwarnings=error` garante que `DeprecationWarning` não seja silencioso.
* **Segurança:** `tests/` não introduz segredo; `uv.lock` versionado (Lei Zero V) + `uv sync --frozen` futuro; `subprocess` com `env={"FKX_ORACLE_NESTED":"1"}` sem `shell=True`.
* **Layout futuro:** `tests/` raiz permanece; `packages/<name>/tests/` entram em `011`/`012` via ampliação de `testpaths = ["tests", "packages/core/tests"]` sem remover raiz — contrato `Transferido` documentado, não oral.

**Decisão (D10):** oráculo `f0-005-pytest.sh` com **12–16 asserções** cobrindo tabela acima, seguindo `oracle-cli.md` (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER`). `FR-015` de 004 (`workspace=true`) permanece contrato documentado, não re-verificado.

---

## Resumo das decisões vinculantes

| # | Decisão | Fonte |
|---|---|---|
| D1 | `pytest==9.1.1` + `pytest-asyncio==1.4.0` + `pytest-cov==7.1.0` via `[dependency-groups] dev`, `uv_build>=0.12.7,<0.13` mantido | Q1 PyPI 2026-08-31, docs 9.1.1 2026-06-19 |
| D2 | `tests/` raiz + `tests/conftest.py`, `test_*.py`, config só em `pyproject.toml [tool.pytest.ini_options]`, sem `pytest.toml` separado | Q2 docs.pytest.org 41/51KB |
| D3 | `asyncio_mode = "strict"` + `asyncio_default_fixture_loop_scope = "function"` | Q3 pytest-asyncio 1.4.0 |
| D4 | `uv add --dev` → `[dependency-groups] dev` (PEP 735), `uv sync` default, não `tool.uv.dev-dependencies` | Q4 docs.astral.sh 169KB + `uv add --help` |
| D5 | `pytest-cov` relatório (`branch=true`, `show_missing`) sem `--cov-fail-under`; portão é `010` | Q5 docs coverage + plano §17 |
| D6 | Promoção oráculos via `subprocess` parametrizado + `--list` vs `CANON_ORDER`, mapa FR em `contracts/oracle-cli.md` quando não identidade | Q6 oracle-cli + README |
| D7 | Determinismo `EPOCHSECONDS`/`time.monotonic` `<5s` + 2× `cmp` byte-a-byte + 5 casos ADR-007 nomeados | Q7 ADR-007/B2 |
| D8 | `manifest.sha256` 5 linhas (001..005) nativo `sha256sum -c` + self-check `f0-001..004` todos | Q8 ADR-015 re-medido 2026-08-31 |
| D9 | `minversion=9.1`, `testpaths=["tests"]`, `addopts="-ra --strict-markers --strict-config"`, `filterwarnings=error`, `xfail_strict`, sem `xdist` | Q9 pytest docs |
| D10 | 12–16 asserções só pytest+manifesto+dívidas; sem `ruff`/`mypy`/`lefthook`/`packages/` (Escada) | Q10 constitution |

**Nenhum `NEEDS CLARIFICATION` remanescente.** Próxima etapa: `SPECIFY` da spec `005 — Pytest 9.1.1 — harness TDD`.

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **006 Ruff 0.16.5** | `pyproject.toml` com `[dependency-groups] dev` estável onde `[tool.ruff]` coexistirá; `tests/` já coletável sem reescrever |
| **007 MyPy 2.3.1** | `requires-python >=3.12,<3.14` single + `tests/` com `import-mode` estável; `mypy` futuro lê `packages/*` sem conflito com `pytest` |
| **008 pip-audit+Trivy** | `uv.lock` com hashes de `pytest*` para auditoria; `uv sync --frozen` já validável |
| **009 Lefthook** | `pytest` orquestrável via `lefthook.yml` (`uv run pytest -q`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `manifest.sha256` 5 linhas + `uv.lock` com `pytest` para `uv sync --frozen` determinístico; `pytest --cov` já com `branch=true` para virar portão |
| **011 core / 012 cli** | Workspace `tests/` raiz estável + contrato transferido para `packages/<name>/tests` via ampliação de `testpaths` (não remoção) |
| **013 release** | `uv build` + `uv export --format pylock.toml` sem config extra; `pytest` não entra no artefato publicado (`--no-dev`) |
| **014 Renovate** | Pins `pytest==9.1.1`, `pytest-asyncio==1.4.0`, `pytest-cov==7.1.0`, `coverage==7.16.0` para agrupamento e automerge |

## Pacotes e versões pinadas verificadas em 2026-08-31

| Pacote | Versão verificada | Fonte | Nota |
|---|---|---|---|
| `pytest` | `9.1.1` | PyPI `pytest/json` + `pytest/9.1.1/json` upload 2026-06-19 | `>=3.10`, `requires_dist` iniconfig/pluggy |
| `pytest-asyncio` | `1.4.0` | PyPI `pytest-asyncio/json` upload 2026-05-26 | `pytest<10,>=8.4`, `strict` default |
| `pytest-cov` | `7.1.0` | PyPI `pytest-cov/json` upload 2026-03-21 | `coverage[toml]>=7.10.6`, `pytest>=7` |
| `coverage` | `7.16.0` | PyPI `coverage/json` upload 2026-08-28 | `>=3.10` |
| `pluggy` | `1.6.0` | PyPI `pluggy/json` | transitivo de `pytest` |
| `iniconfig` | `2.3.0` | PyPI `iniconfig/json` | transitivo |
| `packaging` | `24.x` (via `pytest`) | `requires_dist` | |
| `uv` / `uv_build` | `0.12.7` (`uv_build>=0.12.7,<0.13`) | PyPI `uv/json` + docs snippet `guides/projects` | local `0.12.1` desatualizado — deve convergir |
| `Python` | `3.12.3` local, `3.12` família, `>=3.12,<3.14` | `python --version` + `requires-python` plano §4 | `setup-python@v7` já pina `3.12` em `ci.yml` (003) |
| `uv workspace` | `members = ["packages/*"]` globs | `concepts/projects/workspaces` + `reference/settings` | single `requires-python` interseção |
| `pytest config` | `[tool.pytest.ini_options]` `minversion 9.1` | `reference/customize.html` 51KB | `pytest.toml` rejeitado para manter fonte única |
| `GitHub Actions workflow` | `ci.yml` existente `003` | `.github/workflows/ci.yml` 25 linhas | job `verify` estável, inclui `f0-005` automaticamente via glob |
