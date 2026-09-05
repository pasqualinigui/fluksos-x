---
description: "Task list for 005 — Pytest 9.1.1 — harness TDD"
---

# Tasks: Pytest 9.1.1 — harness TDD

**Input**: Design documents from `/specs/005-pytest/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md` (D1–D10), `data-model.md` (5 entidades), `contracts/pytest-contract.md`, `contracts/oracle-cli.md`, `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-003). A prova é dupla: oráculo `scripts/verify/f0-005-pytest.sh` executado antes (🔴) e depois (🟢) + `uv run pytest -q` antes/depois — não recuperável depois. TDD é harness TDD: `.sh` + `pytest` são o teste.

**Artefatos deste item**: `pyproject.toml` alterado (`[dependency-groups] dev` + `[tool.pytest.ini_options]` + `[tool.coverage.*]`), `uv.lock` com `pytest 9.1.1`, `tests/conftest.py`, `tests/test_harness_oracles.py`, `tests/test_harness_debts.py`, `scripts/verify/manifest.sha256` (5 linhas), `scripts/verify/f0-005-pytest.sh` (12–16 asserções), `scripts/verify/README.md` (+1 linha), `specs/005-pytest/evidence/` (`red.txt`, `green.txt`, `pytest_green.txt`). Nenhum `ruff`/`mypy`/`lefthook`/`packages/`/`pytest.toml`/`xdist`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. `tests/` na raiz (não `packages/*/tests` em 005). Oráculo em `scripts/verify/f0-005-pytest.sh` segue ADR-002. Spec dir `specs/005-pytest/` segue Spec-Kit. Não há `src/` porque harness é infra.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `004`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oracle completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..015 antes de `pyproject.toml`/`tests/` existirem. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (III, SC-003) |
| `tests/` por história | **Fase C materializa `tests/` + `manifest` juntos** | `tests/test_harness_oracles.py` e `test_harness_debts.py` partilham `conftest.py` e `pyproject.toml`; dividir criaria colisão de escrita |
| US2/US3 após US1 | **US2/US3 verificação após verde** | Depois do verde, US2/US3 não mutam `tests/` além de verificação estática (manifest, debts) — independência lógica preservada |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T015 (vermelho) antes de T016** — criar `pyproject.toml` `[dependency-groups]` antes do vermelho satisfaz FR-001 e ainda assim falha SC-003/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T014** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON_ORDER, FKX_ORACLE_NESTED, EPOCHSECONDS) é pré-requisito de qualquer asserção.
3. **T027 (verde) após T016–T022** — verde só é verde depois da última mutação (`pyproject.toml` + `tests/` + `manifest` + `README`).

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T015 | US1+US2+US3 (oracle) |
| Fase C — Harness verde 🟢 | Phase 4 + Phase 5 | T016–T022 | US1 (MVP) + US2 |
| Fase D — Verde e convergência | Phase 6 + Phase 7 | T023–T032 | US3, Polish |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado está verde e que os artefatos-alvo ainda não existem; preparar evidências e medir hashes congelados.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` — deve sair `0` com `f0-001` 30/30, `f0-002` 33/33, `f0-003` 14/14, `f0-004` 14/14. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausência de `[dependency-groups]` em `pyproject.toml` (`grep -q "dependency-groups" pyproject.toml` deve falhar), ausência de `tests/` e `manifest.sha256` (`test ! -d tests && test ! -f scripts/verify/manifest.sha256`), e que `docs/plan/research/f0-005-pytest.md` 479 linhas e `pyproject.toml` sem `pytest` (`! grep -q pytest pyproject.toml`) existem — registra fronteira FR-001/004/008 (plan.md Fase A:2)
- [x] T003 Criar diretório de evidências `specs/005-pytest/evidence/` (`mkdir -p specs/005-pytest/evidence`) para `red.txt`, `green.txt`, `pytest_green.txt` (Princípio III, plan.md Fase B:3 / Fase D:1) e medir hashes `sha256sum scripts/verify/f0-*.sh` → devem bater `63412ca7…`, `406d72…`, `d10c61…`, `3db362…` (Q8, D8)

**Checkpoint**: pré-requisitos satisfeitos — oráculos anteriores íntegros, alvo inexistente, hashes congelados, evidências endereçáveis.

---

## Phase 2: Foundational (Esqueleto do oráculo) ⚠️ BLOQUEANTE

**Purpose**: criar o invólucro que todo FR vai usar. **Nenhuma asserção de Phase 3 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: este esqueleto implementa o contrato `specs/001-.../contracts/oracle-cli.md` herdado via `contracts/oracle-cli.md` deste item e `scripts/verify/README.md`. Sem ele, `--list`/`--quiet`/códigos não são decidíveis.

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-005-pytest.sh` com esqueleto do contrato herdado: parsing de `--quiet` e `--list`, resolução da raiz por `SCRIPT_DIR`/`REPO_ROOT` (nunca `$PWD`), códigos `0` conforme / `1` não conforme / `2` erro de uso, formato `<emoji> FR-XXX <descrição>` uma linha por REQ-ID, linha de resultado final `X/Y passed`, mapa `CANON` único 12–16 IDs com `CANON_ORDER`, guarda `FKX_ORACLE_NESTED`, `EPOCHSECONDS` para `<5s` (não `date +%s`), sem efeitos além de stdout/stderr (FR-014, oracle-cli.md §1–§6, data-model.md Manifest)

**Checkpoint**: foundation ready — asserções de história podem ser acrescentadas sem recriar contrato.

---

## Phase 3: Oracle completo — 12–16 asserções + vermelho 🔴 (US1+US2+US3)

**Goal**: oráculo que responda por código de saída cobrindo **todos** os FR-001..015 antes de existir qualquer coisa para aprovar. É a única prova auditável de test-first.

**Independent Test**: executar em estado com `[dependency-groups]`/`tests/`/`manifest` inexistentes → `exit 1` com reprovação nominal por FR; ` --list` enumera 12–16 IDs sem executar; `FKX_ORACLE_NESTED=1` evita recursão.

### Implementation por grupo (mesmo arquivo, sequencial — não paralelizável)

- [x] T005 [US1] Implementar em `scripts/verify/f0-005-pytest.sh` **Grupo FR-001/002** — `[dependency-groups] dev` contém `pytest==9.1.1`, `pytest-asyncio==1.4.0`, `pytest-cov==7.1.0` exatos via `tomllib` (`d["dependency-groups"]["dev"] == [...]`), e `! grep -q "pytest" .venv` não necessário mas `! grep -q '\[project\.dependencies\].*pytest'` e `! grep -q 'tool.uv.dev-dependencies'` (FR-001/002, D1/D4, data-model Dependency-group dev)
- [x] T006 [US1] Implementar **Grupo FR-003** — `[tool.pytest.ini_options]` existe com `minversion=="9.1"`, `testpaths==["tests"]`, `python_files==["test_*.py"]`, `python_classes==["Test*"]`, `python_functions==["test_*"]`, `pythonpath==["."]`, `addopts=="-ra --strict-markers --strict-config"`, `markers` contém `slow`/`harness`, `filterwarnings==["error"]`, `xfail_strict==true`, `asyncio_mode=="strict"`, `asyncio_default_fixture_loop_scope=="function"`; também `[tool.coverage.run]` `branch==true` e `[tool.coverage.report]` `show_missing` (FR-003, D2/D3/D5/D9)
- [x] T007 [US1] Implementar **Grupo FR-004** — `tests/conftest.py` existe (`test -f`), `python -m py_compile tests/conftest.py` 0, `! test -f pytest.toml && ! test -f pytest.ini && ! test -f setup.cfg` com `[pytest]` (FR-004, D2, contracts/pytest-contract.md §3)
- [x] T008 [US1] Implementar **Grupo FR-005/011** — `tests/test_harness_oracles.py` existe, contém `ORACLES = glob("f0-*.sh")` + `@pytest.mark.harness` + `@parametrize` + `subprocess.run(..., env={"FKX_ORACLE_NESTED":"1"})` + `re ^(✅|🔴|⏭️) FR-\d+`, e `uv run pytest --co -q` enumera ≥1 caso por oráculo quando pytest instalado; em vermelho (sem pytest) apenas verifica existência do arquivo (FR-005/011, D6)
- [x] T009 [US1] Implementar **Grupo FR-006/007** — `uv.lock` contém `pytest` (`grep -q 'name = "pytest"' uv.lock`) e `tomllib` válido, `! git check-ignore -q uv.lock` mas `git check-ignore -q .pytest_cache` e `git check-ignore -q htmlcov` positivo quando existirem; `uv lock --check` passa se `uv` presente (FR-006/007, D1, data-model uv.lock)
- [x] T010 [US1] Implementar **Grupo FR-008/009** — `scripts/verify/manifest.sha256` existe com 5 linhas `sha256␣␣path` e `sha256sum -c manifest.sha256` 0, e self-check `f0-001`..`f0-004 --quiet` todos (`FKX_ORACLE_NESTED=1 .../f0-001 --quiet`) aprovam (FR-008/009, D8, ADR-015a/e)
- [x] T011 [US2] Implementar **Grupo FR-010** — `tests/test_harness_debts.py` existe com 5 funções `test_f0_001_runtime_lt_5s`, `test_f0_001_deterministic_output`, `test_red_green_pair_distinct`, `test_contracts_section_exists`, `test_main_branch_exists` (FR-010, D7, data-model Test debt)
- [x] T012 [US3] Implementar **Grupo FR-012** — CI glob `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` passa (FR-012, D8)
- [x] T013 [US3] Implementar **Grupo FR-013** — CONVERGE `grep -c "\[ \]" specs/005-pytest/tasks.md` → 0 quando tasks.md tem zero `[ ]` (FR-013, ADR-015d)
- [x] T014 [US1+US2+US3] Implementar **Grupo FR-014** — determinismo 2× `cmp` stdout idêntico + `<5s` via `EPOCHSECONDS` (não `date +%s`, B2) + `minversion 9.1` já em FR-003 (FR-014, D7/D9)
- [x] T015 [US1] Implementar **Grupo FR-015** — fronteira `! grep -q '\[tool.ruff\]' pyproject.toml && ! test -f ruff.toml && ! grep -q '\[tool.mypy\]' pyproject.toml && ! test -f mypy.ini && ! test -f lefthook.yml && ! test -d packages && ! test -f pytest.toml && ! grep -q xdist pyproject.toml` (FR-015, D10, Escada)

### Captura do vermelho (não recuperável)

- [x] T016 🔴 **Executar** `scripts/verify/f0-005-pytest.sh` e `scripts/verify/f0-005-pytest.sh --quiet` e preservar saída íntegra em `specs/005-pytest/evidence/red.txt`. Esperado `exit=1` com reprovação em massa (FR-001 sem `dependency-groups` + FR-004 sem `tests/conftest.py` + FR-008 sem `manifest`). Conferir `--list` enumera 12–16 IDs sem executar. Este `red.txt` é a prova de TDD — se não existir antes de T017, o par vermelho→verde é irrecuperável (Princípio III, SC-003, plan.md Fase B:3)

**Checkpoint**: existe oráculo completo e existe prova registrada de que ele reprova. A partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Harness pytest verde em clone limpo (Priority: P1) 🎯 MVP

**Goal**: clone limpo obtém `pytest 9.1.1` com `uv sync` + `uv run pytest -q` determinístico (SC-001, SC-005).

**Independent Test**: `quickstart.md` Cenário 1 + 2 (FR-001/003/004/006/011): `uv add --dev pytest==9.1.1` → `dependency-groups` exato, `uv.lock` com hash, `pytest --co -q` lista harness, marker typo reprova.

- [x] T017 [US1] Materializar `pytest` **via `uv`** (D1/D4): `uv add --dev pytest==9.1.1 pytest-asyncio==1.4.0 pytest-cov==7.1.0` e `uv sync` (sem `--locked` em 005, D4) — acrescenta `[dependency-groups] dev` exato em `pyproject.toml` e gera `uv.lock` com `pytest 9.1.1` + deps; fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub TOML válido com `[[package]] name="pytest"` (FR-001/006, contracts/pytest-contract.md §2)
- [x] T018 [US1] Criar `tests/conftest.py` mínimo (vazio ou comentário) e validar `python -m py_compile tests/conftest.py` exit 0; garantir `! test -f pytest.toml` (FR-004, D2)
- [x] T019 [US1] Acrescentar `[tool.pytest.ini_options]` e `[tool.coverage.*]` em `pyproject.toml` conforme `contracts/pytest-contract.md` §2 (minversion 9.1, testpaths, addopts, markers, filterwarnings, xfail_strict, asyncio strict, branch true) — validar via `python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["pytest"]["ini_options"]["asyncio_mode"]=="strict"'` (FR-003, D2/D3/D5/D9)
- [x] T020 [US1] Validar `uv run pytest --co -q` coleta `tests/` e não coleta `specs/`/`scripts/` (`testpaths`), e que `uv run pytest -q` sem marker typo passa quando pytest instalado (FR-005/011, quickstart Cenário 2)

**Checkpoint**: MVP entregue — `uv run pytest -q` passa sem marker typo; `uv.lock` contém `pytest==9.1.1`.

---

## Phase 5: User Story 2 — Promoção 1:1 dos oráculos shell a pytest (Priority: P2)

**Goal**: cada `f0-*.sh` tem teste pytest equivalente parametrizado (SC-002, FR-005/011).

**Independent Test**: `quickstart.md` Cenário 3: `uv run pytest tests/test_harness_oracles.py -v` lista 4 oráculos como casos `parametrize`; injetar `chmod -x f0-001` → `FAILED` nomeando `FR-001`.

- [x] T021 [US2] Criar `tests/test_harness_oracles.py` conforme `contracts/pytest-contract.md` §4 — `ORACLES = sorted(glob("scripts/verify/f0-*.sh"))`, `_canon_ids()` via `--list` + `FKX_ORACLE_NESTED=1`, `test_oracle_exit_codes_and_format` com `returncode in (0,1)` e `re ^(✅|🔴|⏭️) FR-\d+`, `test_oracle_list_enumerates_canon` casa `CANON_ORDER` (FR-005, D6)
- [x] T022 [US2] Validar `uv run pytest --co -q` contém `test_oracle_exit_codes_and_format` com 4 IDs (`f0-001..004`) e `test_oracle_list_enumerates_canon` (FR-005, contracts/oracle-cli.md §3)
- [x] T023 [P] [US2] Verificar marker `harness` registrado em `pyproject.toml` `[tool.pytest.ini_options] markers`: `uv run pytest --markers | grep harness` deve conter `harness: oracle promotion tests` (FR-003, D9, contracts/pytest-contract.md §2)

---

## Phase 6: User Story 3 — Integridade, dívidas pagas e CONVERGE (Priority: P3)

**Goal**: cadeia `manifest.sha256` 5 linhas + 5 dívidas ADR-007 + self-check total + CONVERGE zero `[ ]` (SC-003/004/007, FR-008..014).

**Independent Test**: `quickstart.md` Cenário 4 + 5: `sha256sum -c manifest.sha256` 0, `pytest test_harness_debts.py -v` 5 PASS, `grep -c "\[ \]" tasks.md` 0.

- [x] T024 [US3] Criar `tests/test_harness_debts.py` com 5 funções nomeadas `test_f0_001_runtime_lt_5s` (`time.monotonic() <5`), `test_f0_001_deterministic_output` (2× subprocess cmp), `test_red_green_pair_distinct` (hash red.txt≠green.txt), `test_contracts_section_exists` (`grep Entregue`), `test_main_branch_exists` (`git show-ref refs/heads/main`) (FR-010, D7, data-model Test debt)
- [x] T025 [US3] Gerar `scripts/verify/manifest.sha256` 5 linhas: `sha256sum scripts/verify/f0-001-foundation.sh scripts/verify/f0-002-constitution.sh scripts/verify/f0-003-ci-minimo.sh scripts/verify/f0-004-uv-workspace.sh scripts/verify/f0-005-pytest.sh > scripts/verify/manifest.sha256` e validar `sha256sum -c scripts/verify/manifest.sha256` exit 0 (FR-008, D8, data-model Manifest)
- [x] T026 [US3] Validar self-check total: `FKX_ORACLE_NESTED=1 scripts/verify/f0-005-pytest.sh --quiet` executa `f0-001`..`004 --quiet` todos (não subconjunto, fecha M4) e CI glob `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` passa (FR-009/012, D8, plan.md Fase D:4)

---

## Phase 7: Polish & Convergência 🟢

**Purpose**: fechar ciclo vermelho→verde, provar determinismo, atualizar harness e versionar evidências.

- [x] T027 🟢 Executar `scripts/verify/f0-005-pytest.sh` e `scripts/verify/f0-005-pytest.sh --quiet` e preservar saída íntegra em `specs/005-pytest/evidence/green.txt`. Esperado `exit=0` com 12–16/12–16 aprovadas (SC-006, plan.md Fase D:1)
- [x] T028 🟢 Executar `uv run pytest -q` e preservar saída em `specs/005-pytest/evidence/pytest_green.txt` (ou `pytest` stdout). Esperado `X passed` (FR-011, SC-001)
- [x] T029 Executar `quickstart.md` validação determinismo: `scripts/verify/f0-005-pytest.sh > /tmp/r1.txt 2>&1` vs `/tmp/r2.txt` `diff` idêntico + `time.monotonic()` 2× `pytest -q` `<5s` cada, e `uv run pytest -q > /tmp/p1.txt` vs `/tmp/p2.txt` `cmp` idêntico (FR-014, SC-003, plan.md Fase D:3)
- [x] T030 Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` e `uv run pytest -q` → `0` (dupla) — ambos green simultâneos (FR-012, SC-006, plan.md Fase D:5)
- [x] T031 Atualizar `scripts/verify/README.md` tabela — nova linha `f0-005-pytest.sh | 12–16 | Pytest 9.1.1 — harness TDD + manifest (FR-001..015, ADR-007/015)` — conforme `plan.md` Fase C:7 e ADR-002 crescimento
- [x] T032 Executar `quickstart.md` validação completa em um comando (Cenário 1–6): `uv run pytest -q && sha256sum -c scripts/verify/manifest.sha256 && for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && ! test -f pytest.toml && grep -q 'testpaths.*tests' pyproject.toml` → todos `OK` = `contracts/pytest-contract.md` §7 satisfeito (SC-001..008)
- [x] T033 Registrar ciclo em commits separados vermelho→verde obedecendo `CONTRIBUTING.md` §1 (`^(feat|fix|docs|chore|refactor)(\(.+\))?: .+`): commit 🔴 com oracle + `red.txt`, commit 🟢 com `pyproject.toml`+`uv.lock`+`tests/`+`manifest.sha256`+`README.md`+`green.txt`/`pytest_green.txt` — par auditável (Princípio III, plan.md Fase D:7)
- [x] T034 [P] Anotar em `specs/005-pytest/quickstart.md` ou `plan.md` Fase E que Cenário remoto (`push` conforme verde + `PR` com `pytest.toml` vermelho, SC-005) só é observável após `push`/`PR` real em `main`/`develop` e fica deferido pós-merge (não bloqueia convergência local, plan.md Fase E)

---

## Dependencies

### Ordem de fases (estrita)

```
Phase 1 (T001–T003)              Setup
   ↓
Phase 2 (T004)                   Foundational — esqueleto oracle (BLOQUEANTE)
   ↓
Phase 3 (T005–T016)              Oracle completo + 🔴 vermelho preservado
   ↓
Phase 4 (T017–T020)              US1 — pytest verde (MVP) 🟢
   ↓
Phase 5 (T021–T023)              US2 — promoção 1:1
   ↓
Phase 6 (T024–T026)              US3 — manifest + dívidas + self-check
   ↓
Phase 7 (T027–T034)              Polish & Convergência (verde + determinismo + harness acumulado)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T004 | T001, T002 | harness íntegro + alvo inexistente são pré-condição do contrato |
| T005–T015 | T004 | asserções exigem esqueleto `oracle-cli` (exit/flags/CANON/EPOCHSECONDS) |
| T016 | T005–T015 | vermelho só é prova se oráculo cobrir FR-001..015 |
| T017 | **T016** | `uv add --dev` antes do vermelho falha SC-003 de forma irrecuperável |
| T018–T020 | T017 | `[tool.pytest]` e `conftest.py` só fazem sentido com `[dependency-groups]` existente |
| T021–T023 | T018 | promoção via `subprocess` exige `conftest.py` + `pyproject.toml` com `testpaths` |
| T024–T026 | T021 | dívidas e `manifest` exigem `tests/` já coletável |
| T027 | T017–T026 | verde só é verde após última mutação (`pyproject.toml` + `tests/` + `manifest` + `README`) |
| T031 | T027 | `README.md` só após verde medido |
| T033 | T027 | commits só após verde |

### Oportunidades reais de paralelismo

**Três oportunidades reais**, cobrindo 5 tarefas, verificadas quanto a colisão de arquivo:

- **T023** — `pytest --markers` somente leitura, paralelizável com `T022` (coleção).
- **T030** — `for f in f0-*.sh` vs `uv run pytest -q` — duas verificações independentes (arquivos de saída distintos `/tmp/*`) — paralelizáveis entre si (`[P]` marcado onde seguro).
- **T034** — anotação deferida remota, não toca `pyproject.toml` nem oracle após verde.

As demais **não** são paralelizáveis: T005–T015 editam o mesmo `f0-005-pytest.sh`, T017–T020 tocam `pyproject.toml`/`uv.lock`/`tests/conftest.py` sequencialmente, T016/T027/T028 escrevem `evidence/` ordenadamente. Marcá-las `[P]` criaria colisão real.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T020). Entrega **harness pytest verde** — `uv run pytest -q` passa sem marker typo e `uv.lock` contém `pytest==9.1.1`. Sem ele, `ruff`/`mypy` validariam sobre harness shell apenas. US2/US3 agregam promoção e integridade mas o MVP já materializa `pytest` pinado.

### Entrega incremental

1. Phases 1–2 → pré-requisitos + esqueleto (remoção segura futura)
2. Phase 3 → 🔴 vermelho preservado (prova de test-first garantida)
3. Phase 4 → **pytest verde** — `tests/` raiz coletável existe (MVP)
4. Phase 5 → promoção 1:1 parametrizada — cada `f0-*.sh` é caso `parametrize`
5. Phase 6 → `manifest.sha256` 5 linhas + 5 dívidas ADR-007 nomeadas — cadeia fechada
6. Phase 7 → 🟢 verde, `pytest -q` verde, determinismo, harness acumulado, commits auditáveis

### Critério de conclusão do item

| Condição | Verificação | SC |
|---|---|---|
| `[dependency-groups] dev` exato | T019 + T005 | SC-001 |
| `uv.lock` com `pytest 9.1.1` | T017 + T009 | SC-001 |
| `tests/conftest.py` py_compile 0, sem `pytest.toml` | T018 + T007 | SC-001 |
| `uv run pytest --co -q` ≥5 casos | T020 + T022 | SC-002 |
| 2× `pytest -q` stdout idêntico `<5s` | T029 | SC-003 |
| `sha256sum -c manifest.sha256` 5 linhas | T025 + T029 | SC-004 |
| marker typo `strict-markers` reprova | T020 | SC-005 |
| `f0-005 --quiet` + self-check `001..004` todos | T027 + T026 | SC-006 |
| `tasks.md` zero `[ ]` | T034 + T013 | SC-007 |
| Sem `ruff`/`mypy`/`packages/`/`xdist` | T015 | SC-008 |
| 12–16/12–16 `exit 0` + `pytest -q` `X passed` | T027 + T028 | FR-011/014 |
| Harness acumulado `for f` + `pytest -q` 0 | T030 | FR-012 |
| Commits vermelho→verde separados | T033 | Princípio III |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **2** das 34 tarefas, deliberadamente — este item edita `f0-005-pytest.sh` e `pyproject.toml`/`tests/` muitas vezes sequencialmente.
- Cada tarefa cita o FR/SC que a origina, para que qualquer linha do oráculo seja rastreável até `spec.md` sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits **separados**: é a prova auditável de que o teste veio primeiro, e ela não é recuperável depois (plan.md Fase B).
- T034 é deferido remoto — não bloqueia `T027` verde local, mas SC-005 remoto só fecha após observação em GitHub (plan.md Fase E).
- Nenhuma tarefa introduz `ruff`/`mypy`/`pytest-xdist`/`lefthook` — violaria FR-015 e Escada (constitution Additional Constraints).
