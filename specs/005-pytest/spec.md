# Feature Specification: Pytest 9.1.1 — harness TDD

**Feature Branch**: `005-pytest`

**Created**: 2026-08-31

**Status**: Draft

**Input**: User description: "Fase 0, item 0.4 (005/016 na ordem de execução): Pytest 9.1.1 — harness TDD com pytest, pytest-asyncio e pytest-cov via dependency-groups, promoção dos oráculos shell a testes, manifest.sha256 e pagamento das dívidas ADR-007/015 (tempo <5s, determinismo, par vermelho→verde, contratos, FR-001 branch). Sem Ruff/MyPy/Lefthook/packages."

**Item do plano**: 0.4 (§17 Fase 0, Itens 0.1–0.12) · **Ordem de execução**: 005 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-005-pytest.md` (decisões D1–D10, Q1–Q10, nenhuma NEEDS CLARIFICATION)
**Contrato de entrada**: `specs/004-uv-workspace/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-006, ADR-007, ADR-011, ADR-014, ADR-015) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`
**Cópia derivada**: `specs/005-pytest/research.md` (consolidação local de `docs/plan/research/f0-005-pytest.md`, não fonte primária)

---

## Contexto

O motor prometido no plano (§1, §15) é validado por **Harness Engineering** (§14) com o oráculo determinístico `scripts/verify/f0-*.sh` (contrato `oracle-cli.md`: exit `0`/`1`/`2`, `--quiet`/`--list`, uma linha por FR). Até aqui o harness é só shell+git+Python 3.12 stdlib — as ferramentas que o comporiam (pytest, Ruff, MyPy, pip-audit) só chegam nos itens `005–008` (`scripts/verify/README.md:69`). Sem `pytest`, cada spec prova TDD via `red.txt`/`green.txt` do `.sh`; com `pytest` a prova vira `uv run pytest -q` e cada oráculo é promovido a módulo de teste parametrizado (`--list` existe para isso, `README.md:124`).

Este item é **o primeiro de qualidade e o pagador de dívidas do bootstrap**: a auditoria `f0-audit-001-004.md` encontrou 4 achados acionáveis (A1 cadeia hash quebrada pós-002, A2 drift FR `001..017→001..014`, M3/M4 self-check incompleto) e a ADR-007 transferiu 5 lacunas do item `001` (SC-003 tempo `<5s` empírico, SC-003 determinismo byte-a-byte, SC-004 par vermelho→verde, SC-007 contratos, FR-001 mede `HEAD` não `refs/heads/main`). A ADR-015 fixa o **padrão corrigido a partir de 005**: `manifest.sha256` único (`sha256sum -c`), mapa FR↔asserção obrigatório quando não for identidade, vocabulário `Entregue/Transferido`, `CONVERGE` fecha lista (`tasks.md` zero `[ ]`), self-check cobre `001..N-1` todos.

Entrega exclusivamente `pytest` via `uv`: root `pyproject.toml` com `[dependency-groups] dev` + `[tool.pytest.ini_options]` + `[tool.coverage.*]` + `tests/conftest.py` + `tests/test_harness_oracles.py` + `tests/test_harness_debts.py` + `manifest.sha256` + oráculo `f0-005-pytest.sh` com 12–16 asserções. Não cria `ruff`/`mypy`/`lefthook.yml`/`pip-audit`/`trivy`, não cria `packages/` nem `pytest.toml` separado, não introduz `--cov-fail-under` como portão (é `010`), não introduz `pytest-xdist` (rejeitado D9). Cada pacote futuro nasce em sua própria spec e amplia `testpaths` sem remover `tests/` raiz (contrato `Transferido`, não oral).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (`[dependency-groups]` pin exato + `minversion` + `strict-markers`/`strict-config` + `EPOCHSECONDS`/`time.monotonic` + `testpaths=["tests"]`), **II** especificação precede código, **III** vermelho→verde preservado (`.sh` + `pytest`), **V** Lei Zero (trava versionada, `.pytest_cache`/`htmlcov` ignorados, `dev` local-only), **VI** harness oráculo com 12–16 asserções novas + promoção 1:1 nomeando FR, **VIII** elo verificado (PyPI `pytest==9.1.1` + docs.pytest.org + docs.astral.sh + `uv --help` local, Q1–Q10 2026-08-31), **X** observabilidade (falha nomeia `FR-XXX` + evidência `subprocess`).

---

## Clarifications

### Session 2026-08-31

- Q: Criar `packages/core/tests/` e `packages/cli/tests/` já em 005 para adiantar? → A: **Não.** Antecipa responsabilidade de `011`/`012`, viola Escada e SDD. `005` entrega só `tests/` raiz + `tests/conftest.py`; membros surgem nos itens que os exigem e ampliam `testpaths` (D2, contrato `Transferido`).
- Q: Incluir `pytest-xdist -n auto` para paralelizar harness? → A: **Não.** Para ~80 asserts o ganho é 0s e introduz `execnet` + scheduling `load`/`worksteal` não determinístico, quebra `coverage parallel` e `tmp_path` compartilhado. Deferido a `010` se suite >30s (D9). Local deve convergir ao pin, não o pin ao local.
- Q: Impor `pytest --cov-fail-under=80` como portão já em 005? → A: **Não.** Sem `packages/core` não há baseline mensurável; portão sem código reprova por tautologia. `005` configura `branch=true` relatório; portão é `010` (D5).
- Q: Criar `pytest.toml` separado além de `pyproject.toml`? → A: **Não.** `pytest.toml` (novidade 9.0) tem precedência e esconderia `[tool.pytest.ini_options]` — fragmenta config. Fonte única permanece `pyproject.toml` (D2, `reference/customize.html` 51KB).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Harness pytest verde em clone limpo (Priority: P1)

Desenvolvedor clona o repositório em máquina limpa (sem `tests/` pré-existente além do versionado, sem `.venv` cache) e precisa obter **verificação TDD** com um único `uv sync` seguido de `uv run pytest -q` — saída determinística, sem ativar manualmente, sem divergência entre Linux/macOS/Windows, e com `asyncio` configurado em `strict` mesmo sem teste async ainda.

**Why this priority**: é o habilitador de TDD real (ADR-001). Sem `pytest` cada item seguinte (Ruff, MyPy, Lefthook) validaria só via `.sh`; com `pytest` o par vermelho→verde vira `pytest -q` auditável e o lock passa a conter `pytest==9.1.1` determinístico (implementation_plan §4). É a base para `010` (`uv sync --frozen`) e `014` (Renovate agrupa `pytest*`).

**Independent Test**: em clone limpo, executar `uv sync` e `uv run pytest -q` e verificar `X passed` e `uv.lock` contém `pytest==9.1.1`; executar `uv run pytest --co -q` e verificar que `harness` marker existe; executar `pytest -q` duas vezes e comparar stdout byte-a-byte (determinismo D7).

**Acceptance Scenarios**:

1. **Given** clone sem `tests/` e `uv.lock` vazio (`[[package]] fluksos-x` virtual), **When** executa `uv add --dev pytest==9.1.1 pytest-asyncio==1.4.0 pytest-cov==7.1.0` e `uv sync`, **Then** `pyproject.toml` contém `[dependency-groups] dev` exato, `uv.lock` contém `pytest 9.1.1` com hash, e `.venv` existe com `pytest` importável (`uv run python -c "import pytest; print(pytest.__version__)"` → `9.1.1`).
2. **Given** `tests/conftest.py` inexistente, **When** cria `tests/conftest.py` mínimo e executa `uv run pytest -q`, **Then** `pytest` coleta `tests/` ( `python_files = test_*.py` ) e não coleta `specs/` nem `scripts/` (`testpaths=["tests"]`), e `async def test_x` sem `@pytest.mark.asyncio` em `strict` reprova (não silencioso).
3. **Given** `pyproject.toml` com `addopts = "-ra --strict-markers --strict-config"` e `markers = ["harness"]`, **When** executa `pytest -q` com marker typo `@pytest.mark.harnes`, **Then** falha com `strict-markers` nomeando marker desconhecido (observabilidade Princípio X).
4. **Given** repo conforme, **When** executa `uv run pytest -q` duas vezes consecutivas, **Then** stdout e `returncode` coincidem byte-a-byte e cada execução <5s (`time.monotonic`, não `date +%s`).

---

### User Story 2 — Promoção 1:1 dos oráculos shell a pytest (Priority: P2)

Arquiteto precisa que **cada oráculo** `scripts/verify/f0-*.sh` tenha **teste pytest equivalente** — um caso por oráculo (parametrizado) que executa o `.sh` via `subprocess` com `FKX_ORACLE_NESTED=1`, asserindo `exit 0/1` e formato `✅ FR-XXX`/`🔴 FR-XXX`, e que `--list` enumere `CANON_ORDER` idêntico. Falha em pytest deve nomear o `FR-XXX` da spec (Princípio X), sem remapeamento silencioso.

**Why this priority**: valida o contrato `oracle-cli.md` que o item `004` declarou como promoção (`--list` existe para isso) e fecha a lacuna A2 (drift `001..017→001..014`). Sem promoção, `pytest` seria paralelo ao harness, não oráculo dele.

**Independent Test**: `uv run pytest tests/test_harness_oracles.py -v` lista `f0-001-foundation`, `f0-002-constitution`, `f0-003-ci-minimo`, `f0-004-uv-workspace` cada como caso `parametrize`; injetar `chmod -x scripts/verify/f0-001-foundation.sh` → `FAILED` com `FR-001`.

**Acceptance Scenarios**:

1. **Given** `tests/test_harness_oracles.py` existe, **When** executa `uv run pytest --co -q`, **Then** coleta ≥1 teste por oráculo em `scripts/verify/f0-*.sh` (`ORACLES = glob("f0-*.sh")`).
2. **Given** cada oráculo, **When** executa `pytest -k "test_oracle_exit_codes_and_format" -v`, **Then** `subprocess.run([oracle], env={"FKX_ORACLE_NESTED":"1"})` retorna `0` conforme ou `1` violação, e stdout casa `re ^(✅|🔴|⏭️) FR-\d+` (oracle-cli §3).
3. **Given** `f0-004-uv-workspace.sh` com `CANON_ORDER="FR-001 ... FR-014"`, **When** executa `test_oracle_list_enumerates_canon`, **Then** `oracle --list` (stdout) split `FR-XXX` casa `CANON_ORDER` idêntico; se `spec FR-001..015` fragmentar em `FR-001a/b` no oráculo, o mapa está em `specs/005-pytest/contracts/oracle-cli.md` (ADR-015b), não silencioso.
4. **Given** oráculo quebrado (ex.: `pyproject.toml` removido), **When** `pytest -q` roda, **Then** `FAILED` reporta `🔴 FR-001` com evidência `pyproject.toml ausente`, não genérico.

---

### User Story 3 — Integridade, dívidas pagas e CONVERGE fecha a lista (Priority: P3)

Mantenedor roda `sha256sum -c manifest.sha256` ou `uv run pytest -q` e precisa ver **cadeia de integridade** (A1), **self-check total** (M4), **5 dívidas ADR-007** (tempo, determinismo, red→green, contratos, `main` branch) e **zero pendências** (`tasks.md` sem `[ ]`, ADR-015d) — tudo via `pytest` e via `.sh`, sem tocar oráculos `001–004`.

**Why this priority**: princípio **VI** — um item nunca modifica oráculo anterior, e divergência sobe para ADR (ADR-006 hash, ADR-015 manifesto). Sem `manifest.sha256` e sem casos nomeados, `003`/`004` só aprovam (não provam integridade) e `SC-003`/`SC-004`/`SC-007` de `001` permanecem descobertos.

**Independent Test**: `pytest tests/test_harness_debts.py -v` todos PASS + `sha256sum -c scripts/verify/manifest.sha256` exit 0 + `grep -c "\[ \]" specs/005-pytest/tasks.md` → `0`.

**Acceptance Scenarios**:

1. **Given** 4 oráculos `001..004` com hashes `63412ca7…`, `406d72…`, `d10c61…`, `3db362…` (re-medidos 2026-08-31), **When** `005` cria `scripts/verify/manifest.sha256` com 5 linhas (`001..005` ordem ADR-011) e `f0-005-pytest.sh` executa `sha256sum -c manifest.sha256`, **Then** exit 0; editar 1 byte em `f0-001` → `manifest` diverge e pytest `FAILED` nomeando hash, sem `sed -i` silencioso.
2. **Given** `f0-005-pytest.sh`, **When** executa `--quiet`, **Then** internamente roda `f0-001`..`f0-004 --quiet` **todos** (não subconjunto como `004` fez com `002`), e CI `for f in f0-*.sh; do "$f" || exit 1; done` o inclui via glob sem editar `ci.yml`.
3. **Given** `tests/test_harness_debts.py`, **When** `pytest -k "runtime_lt_5s"`, **Then** `time.monotonic()` mede cada `f0-001` `<5s` (usa `EPOCHSECONDS`/`time.monotonic`, não `date +%s`, B2); `test_deterministic_output` roda 2× `subprocess` e `cmp` byte-a-byte idêntico.
4. **Given** `specs/005-pytest/spec.md` com `### Entregue por este item` e `### Transferido a itens posteriores`, **When** `pytest -k "contracts_section_exists"` e `test_red_green_pair_distinct`, **Then** `grep -q "Entregue por este item" spec.md` e `test_main_branch_exists` usa `git show-ref --verify refs/heads/main` (não `HEAD`, ADR-007 lacuna 5); `tasks.md` zero `[ ]` asserido por `f0-005` (CONVERGE fecha lista).

---

### Edge Cases

- **Máquina com `uv 0.12.1` vs pin `0.12.7`.** `uv_build>=0.12.7,<0.13` em `build-system.requires` deve falhar até `uv self update` — local converge ao pin (D5 de 004).
- **`pytest.toml` existe além de `pyproject.toml`.** Deve reprovar — `pytest.toml` (novidade 9.0) tem precedência e esconderia `[tool.pytest.ini_options]` (`reference/customize.html` 51KB).
- **`async def test_x` sem `@pytest.mark.asyncio` em `strict`.** Deve reprovar — `strict` exige marker explícito; `auto` esconderia async (D3).
- **Marker typo `@pytest.mark.harnes`.** Deve reprovar via `strict-markers`, não silencioso (D9).
- **`.pytest_cache` versionado acidentalmente.** `git check-ignore -q .pytest_cache` deve ser positivo; `git status --porcelain | grep .pytest_cache` deve ser vazio (já em `.gitignore` 99).
- **`packages/` criado com `pyproject.toml` sem teste.** `uv sync` deve falhar se dir casado por `packages/*` não contiver `pyproject.toml` (workspaces.md), mas `f0-005` deve reprovar se `packages/` existir — é responsabilidade de `011`/`012`, não `005` (Fronteira).
- **Re-tentativa sem rede após `uv sync`.** `--frozen` recria `.venv` sem resolver; sem lock, falha explícita — `005` materializa lock sem `--frozen`, `010` impõe `--frozen` (Q6 de 004).
- **`git add .venv` acidental.** `git check-ignore -q .venv` positivo + `f0-005` reprova se `git ls-files | grep .venv` (Lei Zero).

---

## Requirements *(mandatory)*

### Functional Requirements

**Artefato raiz e descoberta (D2)**

- **FR-001**: O sistema MUST declarar `[dependency-groups] dev` em `pyproject.toml` com `pytest==9.1.1` (exato), `pytest-asyncio==1.4.0` (exato) e `pytest-cov==7.1.0` (exato) (PEP 735, Q1/Q4, D1/D4).
- **FR-002**: O sistema MUST NOT declarar `pytest` em `[project.dependencies]` nem em `[tool.uv.dev-dependencies]` legado nem em `requirements*.txt` — `dev` é local-only (Q4, D4).
- **FR-003**: O sistema MUST prover `[tool.pytest.ini_options]` em `pyproject.toml` com `minversion = "9.1"`, `testpaths = ["tests"]`, `python_files = ["test_*.py"]`, `python_classes = ["Test*"]`, `python_functions = ["test_*"]`, `pythonpath = ["."]`, `addopts = "-ra --strict-markers --strict-config"`, `markers = ["slow", "harness"]` (ao menos), `filterwarnings = ["error"]`, `xfail_strict = true`, `asyncio_mode = "strict"`, `asyncio_default_fixture_loop_scope = "function"` (Q2/Q3/Q9, D2/D3/D9).
- **FR-004**: O sistema MUST prover `tests/conftest.py` importável (`python -m py_compile tests/conftest.py` exit 0) e MUST NOT prover `pytest.toml`/`pytest.ini`/`setup.cfg` com `[pytest]` separado — fonte única é `pyproject.toml` (Q2, D2).
- **FR-005**: O sistema MUST prover `tests/test_harness_oracles.py` que coleta ≥1 caso por oráculo `scripts/verify/f0-*.sh` via `parametrize` e `subprocess.run(..., env={"FKX_ORACLE_NESTED":"1"})`, asserindo `returncode in (0,1)` e `re ^(✅|🔴|⏭️) FR-\d+` (Q6, D6, oracle-cli.md §3).

**Trava e ambiente (D1/D4)**

- **FR-006**: O sistema MUST conter `pytest` em `uv.lock` com hash, gerado por `uv` (`uv lock --check` passa quando `uv` presente), TOML válido universal (Q1, D1, `uv.lock` layout).
- **FR-007**: `.pytest_cache/` e `htmlcov/` e `.coverage` e `.coverage.*` MUST ser ignorados por git (`git check-ignore -q`), e `uv.lock` MUST NOT ser ignorado — harness verifica via `check-ignore` (Q2/Q5, .gitignore 86–99).

**Integridade ADR-015 (D8)**

- **FR-008**: O sistema MUST prover `scripts/verify/manifest.sha256` com **5 linhas** (001 `63412ca7…`, 002 `406d72…`, 003 `d10c61…`, 004 `3db362…`, 005 `<hash-005>`) em formato `sha256sum` (`␣␣` dois espaços), e `sha256sum -c manifest.sha256` MUST sair 0; divergência sobe para ADR (Q8, D8, ADR-015a).
- **FR-009**: O oráculo `f0-005-pytest.sh` MUST executar `--quiet` de `f0-001-foundation.sh`, `f0-002-constitution.sh`, `f0-003-ci-minimo.sh`, `f0-004-uv-workspace.sh` **todos** (self-check total, não subconjunto), sem modificar nenhum anterior (VI, Q8, D8, ADR-015e).

**Dívidas ADR-007 (D7)**

- **FR-010**: O sistema MUST prover `tests/test_harness_debts.py` com 5 funções nomeadas `test_f0_001_runtime_lt_5s`, `test_f0_001_deterministic_output`, `test_red_green_pair_distinct`, `test_contracts_section_exists`, `test_main_branch_exists` (último usa `git show-ref --verify refs/heads/main`, não `HEAD`) (Q7, D7, ADR-007).

**Harness e CI (D6/D10)**

- **FR-011**: `uv run pytest -q` MUST sair 0 em repo conforme e 1 com violação injetada (ex.: `pytest.toml` presente ou marker typo), com `FR-XXX` nomeado na saída (Princípio X, Q6/Q9).
- **FR-012**: CI `003` (`/.github/workflows/ci.yml` job `verify` `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done`) MUST incluir `f0-005` automaticamente sem editar `ci.yml` (Q10, D8, FR-017 de 004).
- **FR-013**: CONVERGE — `specs/005-pytest/tasks.md` MUST ter zero tarefas `[ ]` (zero `[ ]` literal) quando `f0-005` sai 0 — asserido pelo próprio oráculo (ADR-015d, Q10).
- **FR-014**: Determinismo — duas execuções `f0-005-pytest.sh` (ou `pytest -q`) MUST produzir stdout idêntico byte-a-byte e cada oráculo `<5s` via `EPOCHSECONDS`/`time.monotonic` (não `date +%s`, B2, Q7/Q9, D7).
- **FR-015**: Fronteira Escada — o sistema MUST NOT conter `[tool.ruff]` nem `ruff.toml`, `[tool.mypy]` nem `mypy.ini`, `lefthook.yml`, `pip-audit`/`trivy` configs, `packages/` com `pyproject.toml`, `pytest.toml` separado, nem `pytest-xdist`/`execnet` em `[dependency-groups]` — qualquer presença reprova (constitution Additional Constraints, Q10, D10).

### Key Entities

- **Harness pytest**: `pyproject.toml [tool.pytest.ini_options]` + `tests/conftest.py` + `tests/test_*.py`. Atributos: `minversion`, `testpaths`, `python_files/classes/functions`, `pythonpath`, `addopts`, `markers`, `filterwarnings`, `xfail_strict`, `asyncio_mode`. Coleção via `pytest --co -q` limitada a `testpaths=["tests"]`.
- **Manifest de integridade**: `scripts/verify/manifest.sha256` — 5 linhas `sha256␣␣path`, nativo `sha256sum -c`, aditivo (uma linha por oráculo, ordem ADR-011). Divergência é incidente ADR, nunca `sed`.
- **Oracle promotion**: `tests/test_harness_oracles.py` — `ORACLES = glob("scripts/verify/f0-*.sh")` parametrizado, `CANON_ORDER` vs `--list`, `FKX_ORACLE_NESTED=1`. Mapa FR↔asserção em `contracts/oracle-cli.md` quando não for identidade (ADR-015b).
- **Dependency-group dev**: `[dependency-groups] dev` (PEP 735) — `pytest==9.1.1`, `pytest-asyncio==1.4.0`, `pytest-cov==7.1.0`, `coverage==7.16.0` transitivo, `uv.lock` único, `uv sync` default, `uv sync --no-dev` omite (release `013`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Desenvolvedor em clone limpo com `uv 0.12.7` obtém `pytest 9.1.1` com `uv sync` e `uv run pytest -q` passa (`X passed`) sem ativar `.venv` manualmente, sem `pytest.toml` separado.
- **SC-002**: `uv run pytest --co -q` enumera ≥9 casos (`4 oráculos` parametrizados + `5 dívidas`) em 100% dos clones — coleção verificável sem executar.
- **SC-003**: Duas execuções `uv run pytest -q` sobre mesmo commit produzem stdout idêntico byte-a-byte em 100% (determinismo empírico) e cada oráculo `<5s` (`time.monotonic`).
- **SC-004**: `sha256sum -c scripts/verify/manifest.sha256` verifica 5 linhas (`001..005`) em 100%; edição de 1 byte em qualquer `f0-*.sh` reprova com hash nomeado.
- **SC-005**: Injeção de `pytest.toml` ou marker typo `@pytest.mark.harnes` → `pytest -q` reprova com `strict-config`/`strict-markers` nomeando o erro em 100% (observabilidade).
- **SC-006**: `f0-005-pytest.sh` executa em `<5s` e self-check `f0-001..004 --quiet` todos aprovam; `for f in f0-*.sh; do "$f" --quiet || exit 1; done` inclui `f0-005` sem diff em `ci.yml`.
- **SC-007**: `specs/005-pytest/tasks.md` com zero `[ ]` quando `f0-005` sai 0 — CONVERGE fecha a lista (ADR-015d), verificável por `grep -c "\[ \]"`.
- **SC-008**: Nenhum artefato de `006–016` (Ruff, MyPy, Lefthook, `packages/`, `xdist`) aparece no diff de `005` — fronteira 100% preservada (Escada).

## Assumptions

- `pytest 9.1.1` latest estável em 2026-08-31 (PyPI `9.1.1` upload `2026-06-19`, `requires_python>=3.10` compatível com `>=3.12,<3.14`); `pytest-asyncio 1.4.0` (`2026-05-26`) e `pytest-cov 7.1.0` (`2026-03-21`) são pins verificados Q1; `coverage 7.16.0` transitivo.
- Python `3.12.3` local e `3.12.14` no runner `setup-python@v7`; `requires-python >=3.12,<3.14` é a faixa suportada; `uv 0.12.1` local converge ao pin `0.12.7` via `uv self update` (D5 de 004).
- `.gitignore` já ignora `.pytest_cache/` (99), `htmlcov/` (87), `.coverage*` (90–91) — sem edição em `005`; `001` D3 (sem `*.lock`) preservado.
- Workspace `members=["packages/*"]` com zero membros em `005` é válido; `tests/` raiz é coleta; `packages/<name>/tests` entra em `011`/`012` via ampliação de `testpaths` sem remover `tests/` (contrato `Transferido`).
- `manifest.sha256` formato é específico de `sha256sum` (dois espaços), não `git hash-object` (que ignora modo).
- Spec futura `006` (Ruff) adicionará `[tool.ruff]` sem conflito com `[tool.pytest]`; `005` deixa `[tool.coverage.*]` relatório sem portão (`--cov-fail-under` é `010`).

## Dependencies

- `001` Git + branching strategy — `.gitignore` sem `*.lock`, regras `harness`/`Law Zero` aprovadas; hash `63412ca7…` congelado.
- `002` Constitution — 10 princípios I–X ratificados 1.0.0; dívidas ADR-007 transferidas a `005`.
- `003` CI mínimo — `ci.yml` job `verify` com glob `f0-*.sh` cobre `f0-005` sem edição; `runs-on: ubuntu-24.04`, `checkout@v7 fetch-depth:0`, `setup-python@v7 python 3.12`.
- `004` UV workspace — `pyproject.toml` virtual `name=fluksos-x version=0.1.0 requires-python>=3.12,<3.14 uv_build>=0.12.7,<0.13 members=["packages/*"]` + `uv.lock` vazio válido + `.venv` (auditado `f0-004` 14/14).
- `uv 0.12.7` e `pytest 9.1.1` — elos verificados `docs/plan/research/f0-005-pytest.md` Q1/Q4 contra PyPI + docs.pytest.org + `uv --help` local.
- ADR-011 mapa 16 posições fixa `005 → 0.4` antes de `006` (Ruff), `007` (MyPy), `008` (pip-audit) — escada.

## Contratos

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **006 Ruff 0.16.5** | `pyproject.toml` com `[dependency-groups] dev` + `[tool.pytest.ini_options]` + `[tool.coverage.*]` estável onde `[tool.ruff]` coexistirá; `tests/` já coletável |
| **007 MyPy 2.3.1** | `requires-python` single + `testpaths` estável; `mypy` futuro lê `packages/*` sem conflito |
| **008 pip-audit+Trivy** | `uv.lock` com hashes `pytest*` auditável; `uv sync --frozen` já validável |
| **009 Lefthook** | `pytest` orquestrável via `lefthook.yml` (`uv run pytest -q`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `manifest.sha256` 5 linhas + `uv.lock` com `pytest` para `uv sync --frozen` determinístico; `pytest --cov branch=true` pronto para virar portão |
| **013 Release** | `uv build` + `uv export` sem config extra; `pytest` não entra no artefato (`--no-dev`) |

### Recebido de itens anteriores

| Item | Contrato recebido |
|---|---|
| `001` | `.gitignore` sem `*.lock`, hashes `f0-001` congelado, Lei Zero |
| `002` | Constitution 1.0.0, 5 dívidas ADR-007 transferidas a `005` |
| `003` | `ci.yml` 25 linhas com job `verify` estável via glob |
| `004` | `pyproject.toml` virtual + `uv.lock` vazio + `.venv` + `.python-version 3.12` |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **011** (`0.6 core`) | Criar `packages/core/tests/` e ampliar `testpaths` para `["tests","packages/core/tests"]` sem remover `tests/` raiz | Só existe quando `packages/core` existe; transferência documentada, não oral |
| **012** (`0.7 cli`) | Idem para `packages/cli/tests/` | Mesmo motivo |
| **010** (`0.14`) | `--cov-fail-under=80` + `required check` + matriz Python `3.12/3.13` | Baseline só existe após alguns pacotes |
| **014** (`0.16`) | Pins `pytest==9.1.1`, `pytest-asyncio==1.4.0`, `pytest-cov==7.1.0`, `coverage==7.16.0` para Renovate agrupar | Pipeline completo necessário para validar |

## Out of Scope

- Criação de `packages/core`, `packages/cli` ou qualquer `packages/*` membro (itens `011`/`012`).
- Configuração de `[tool.ruff]`/`ruff.toml`, `[tool.mypy]`/`mypy.ini`, `lefthook.yml`, `pip-audit`/`trivy` — todos pós-005 (Escada).
- `pytest.toml`/`pytest.ini`/`setup.cfg` separados — fonte única é `pyproject.toml` (D2).
- `pytest-xdist`/`execnet` paralelo — rejeitado D9, reavaliado em `010` se suite >30s.
- `--cov-fail-under` portão — relatório em `005`, portão em `010` (D5).
- `pylock.toml`/`requirements.txt`/SBOM — capability de `013` (`uv export`).

