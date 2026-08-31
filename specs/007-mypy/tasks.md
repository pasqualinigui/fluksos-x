---
description: "Task list for 007 — MyPy 2.3.1 strict — type checker"
---

# Tasks: MyPy 2.3.1 strict — type checker

**Input**: Design documents from `/specs/007-mypy/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md` (D1–D10), `data-model.md` (5 entidades), `contracts/mypy-contract.md`, `contracts/oracle-cli.md`, `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-004). A prova é `f0-007-mypy.sh` 12–16 asserções + `uv run mypy --strict` reprovando (🔴) e aprovando (🟢) — não recuperável depois. `mypy --strict` é o teste.

**Artefatos deste item**: `pyproject.toml` alterado (`[tool.mypy]` `python_version 3.12` `strict true` + `[[tool.mypy.overrides]]` `tests.*`), `uv.lock` com `mypy 2.3.1`, `.mypy_cache/`/`.dmypy.json` efêmeros, `scripts/verify/f0-007-mypy.sh` (12–16 asserções), `scripts/verify/manifest.sha256` 7 linhas, `specs/README.md` índice `007 ✅`, `specs/007-mypy/evidence/` (`red.txt`, `green.txt`). Nenhum `lefthook`/`packages/`/`mypy.ini`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. `pyproject.toml` fonte única (sem `mypy.ini`). Oráculo em `scripts/verify/f0-007-mypy.sh` segue ADR-002. `tests/` já existe (005/006) e será checado com `overrides`. Spec dir `specs/007-mypy/` segue Spec-Kit.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `005`/`006`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oracle completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..016 antes de `pyproject.toml` ter `[tool.mypy]`. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (III, SC-004) |
| `mypy` por história | **Fase C materializa `[tool.mypy]` + `mypy` juntos** | `mypy` e `overrides` partilham `pyproject.toml` e `uv.lock`; dividir criaria colisão de escrita |
| US2/US3 após US1 | **US2/US3 verificação após verde** | Depois do verde, US2/US3 não mutam `pyproject.toml` além de verificação estática (strict, cache, fronteira) |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T016 (vermelho) antes de T017** — criar `[tool.mypy]` antes do vermelho satisfaz FR-002 e ainda assim falha SC-004/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T015** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON_ORDER, FKX_ORACLE_NESTED, EPOCHSECONDS) é pré-requisito de qualquer asserção.
3. **T027 (verde) após T017–T025** — verde só é verde depois da última mutação (`pyproject.toml` + `uv.lock` + `manifest` + `README` + `git ls-files`).

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T016 | US1+US2+US3 (oracle) |
| Fase C — MyPy verde 🟢 | Phase 4 + Phase 5 | T017–T022 | US1 (MVP) + US2 |
| Fase D — Verde e convergência | Phase 6 + Phase 7 | T023–T032 | US3, Polish |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (ruff 006) está verde e que os artefatos-alvo ainda não existem; preparar evidências e medir hashes.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com `f0-001` 30/30 `f0-002` 33/33 `f0-003` 14/14 `f0-004` 14/14 `f0-005` 15/15 `f0-006` 14/14 + `uv run mypy --version` 2.3.1 + `uv run ruff check` 0 + `uv run pytest -q` 12 passed. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausência de `[tool.mypy]` em `pyproject.toml` (`! grep -q "tool.mypy" pyproject.toml`), ausência de `mypy.ini` (`! test -f mypy.ini`), ausência de `mypy` em `uv.lock` (`! grep -q 'name = "mypy"' uv.lock`), e que `docs/plan/research/f0-007-mypy.md` 340 linhas e `.gitignore` já cobre `.mypy_cache` (`grep -q .mypy_cache .gitignore`) — registra fronteira FR-002/004/005 (plan.md Fase A:2)
- [x] T003 Criar diretório de evidências `specs/007-mypy/evidence/` (`mkdir -p specs/007-mypy/evidence`) para `red.txt`, `green.txt` e medir hashes `sha256sum scripts/verify/f0-*.sh` → devem bater `63412ca7…` `b63ac3c8…` `d10c61…` `2f8839de…` `ab26f233…` `ee85cfdf…` (Q1/Q8, D8)

**Checkpoint**: pré-requisitos satisfeitos — harness 006 íntegro, alvo inexistente, hashes congelados, evidências endereçáveis.

---

## Phase 2: Foundational (Esqueleto do oráculo) ⚠️ BLOQUEANTE

**Purpose**: criar o invólucro que todo FR vai usar. **Nenhuma asserção de Phase 3 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: este esqueleto implementa o contrato `specs/001-.../contracts/oracle-cli.md` herdado via `contracts/oracle-cli.md` deste item e `scripts/verify/README.md`. Sem ele, `--list`/`--quiet`/códigos não são decidíveis.

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-007-mypy.sh` com esqueleto do contrato herdado: parsing de `--quiet` e `--list`, resolução da raiz por `SCRIPT_DIR`/`REPO_ROOT` (nunca `$PWD`), códigos `0` conforme / `1` não conforme / `2` erro de uso, formato `<emoji> FR-XXX <descrição>` uma linha por REQ-ID, linha de resultado `X/Y passed`, mapa `CANON` único 12–16 IDs com `CANON_ORDER` (inclui `FR-015` `README` e `FR-016` `git ls-files`), guarda `FKX_ORACLE_NESTED`, `EPOCHSECONDS` para `<5s` (não `date +%s`), sem efeitos além de stdout/stderr (FR-011, oracle-cli.md §1–§6, data-model.md Manifest)

**Checkpoint**: foundation ready — asserções de história podem ser acrescentadas sem recriar contrato.

---

## Phase 3: Oracle completo — 12–16 asserções + vermelho 🔴 (US1+US2+US3)

**Goal**: oráculo que responda por código de saída cobrindo **todos** os FR-001..016 antes de existir qualquer coisa para aprovar. É a única prova auditável de test-first.

**Independent Test**: executar em estado com `[tool.mypy]`/`mypy`/`manifest 7` inexistentes → `exit 1` com reprovação nominal por FR; `--list` enumera 12–16 IDs sem executar; `FKX_ORACLE_NESTED=1` evita recursão `f0-006`/`f0-007`.

### Implementation por grupo (mesmo arquivo, sequencial — não paralelizável)

- [x] T005 [US1] Implementar em `scripts/verify/f0-007-mypy.sh` **Grupo FR-001** — `[dependency-groups] dev` contém `mypy==2.3.1` exato via `tomllib` (`d["dependency-groups"]["dev"]` contém `mypy==2.3.1`), sem `mypy` em `[project.dependencies]` (FR-001, D1/D6)
- [x] T006 [US1] Implementar **Grupo FR-002** — `[tool.mypy]` `python_version 3.12` `strict true` `warn_unused_configs true` `exclude "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"` via `tomllib` (FR-002, D4)
- [x] T007 [US1] Implementar **Grupo FR-003** — `[[tool.mypy.overrides]]` `module tests.*` `disallow_untyped_defs false` `disallow_untyped_calls false` `warn_return_any false` via `tomllib` (FR-003, D4)
- [x] T008 [US1] Implementar **Grupo FR-004** — `! test -f mypy.ini && ! test -f .mypy.ini` (fonte única `pyproject.toml`, FR-004, D2)
- [x] T009 [US1] Implementar **Grupo FR-005/006** — `uv.lock` contém `mypy` (`grep 'name = "mypy"'`) + `tomllib` válido + `uv lock --check` quando `uv` presente + `mypy --version` 2.3.1 (`mypy --help` lista `strict`) (FR-005/006, D1/D6)
- [x] T010 [US1] Implementar **Grupo FR-007** — `.mypy_cache`/`dmypy.json` gitignored (`git check-ignore -q` positivo, `! git ls-files | grep`) e `uv.lock` não ignorado (FR-007, D8)
- [x] T011 [US1] Implementar **Grupo FR-008/009/010** — `uv run mypy --strict .` 0 em conforme (com `overrides`) + `uv run mypy --strict tests/` 0 com `overrides` relaxado + `mypy --version` 2.3.1 (FR-008/009/010, D3/D4)
- [x] T012 [US1] Implementar **Grupo FR-011** — oráculo self-check `0/1/2` `quiet` `list` `FKX_ORACLE_NESTED` `EPOCHSECONDS <5s` `2× cmp` idêntico (FR-011, D9, oracle-cli.md)
- [x] T013 [US2] Implementar **Grupo FR-015** — `specs/README.md` `grep -q "007.*mypy.*✅" specs/README.md` (inquebrável, D8) (FR-015)
- [x] T014 [US2] Implementar **Grupo FR-016** — `git ls-files --error-unmatch specs/007-mypy/spec.md` 0 (inquebrável, `??` reprova) (FR-016, D8)
- [x] T015 [US3] Implementar **Grupo FR-012/013/014** — CI glob `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` + CONVERGE `grep -E "^- \[ \]" specs/007-mypy/tasks.md` 0 + fronteira `! grep -q '^\[tool\.mypy\]' mypy.ini` etc. `! test -f lefthook.yml` `! test -d packages` (FR-012/013/014, D9/D10)

### Captura do vermelho (não recuperável)

- [x] T016 🔴 **Executar** `scripts/verify/f0-007-mypy.sh` e `scripts/verify/f0-007-mypy.sh --quiet` e preservar saída íntegra em `specs/007-mypy/evidence/red.txt`. Esperado `exit=1` com reprovação em massa (FR-001 sem `mypy` + FR-002 sem `[tool.mypy]` + FR-005 sem `mypy` em `uv.lock`). Conferir `--list` enumera 12–16 IDs sem executar. Este `red.txt` é a prova de TDD — se não existir antes de T017, o par vermelho→verde é irrecuperável (Princípio III, SC-004, plan.md Fase B:3)

**Checkpoint**: existe oráculo completo e existe prova registrada de que ele reprova. A partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Type check verde em clone limpo (Priority: P1) 🎯 MVP

**Goal**: clone limpo obtém `mypy 2.3.1` com `uv sync` + `uv run mypy --strict .` 0 determinístico (SC-001, SC-003, SC-004).

**Independent Test**: `quickstart.md` Cenário 1 + 3 (FR-001/002/005/008): `uv add --dev mypy==2.3.1` → `dev` exato, `uv.lock` com hash, `mypy --version` 2.3.1, `mypy --strict` lista `strict` 11 flags.

- [x] T017 [US1] Materializar `mypy` **via `uv`** (D1/D6): `uv add --dev mypy==2.3.1` e `uv sync` (sem `--locked` em 007) — acrescenta `mypy==2.3.1` em `[dependency-groups] dev` com `ruff 0.16.5`/`pytest 9.1.1` coexistindo e gera `uv.lock` com `mypy 2.3.1` + `mypy_extensions`/`pathspec`/`tomli` com hash; fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub TOML válido com `[[package]] name="mypy"` (FR-001/005/006, contracts/mypy-contract.md §2)
- [x] T018 [US1] Acrescentar `[tool.mypy]` + `[[tool.mypy.overrides]]` em `pyproject.toml` conforme `contracts/mypy-contract.md` §2 (python_version 3.12, strict true, warn_unused_configs true, exclude "(?x)^(docs/|specs/|\\.venv/)", overrides tests.* disallow_untyped_defs false etc.) — validar via `python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["mypy"]["strict"] is True'` (FR-002/003, D4)
- [x] T019 [US1] Validar `uv run mypy --version` 2.3.1 e `mypy --help` lista `strict` com 11 flags (`disallow-untyped-defs` etc.) — `uv run mypy --help | grep -q "strict"` (FR-010, D1/D3, quickstart Cenário 3)
- [x] T020 [US1] Validar `uv run mypy --strict .` 0 em `tests/` com `overrides` relaxado — criar `tests/` limpo, `mypy --strict` deve passar; injetar `e.py` com `def foo(x): return x` sem anotação fora de `tests/` → `mypy --strict` reprova `disallow_untyped_defs` (FR-008/009, quickstart Cenário 1)

**Checkpoint**: MVP entregue — `uv run mypy --strict .` passa sem `mypy.ini`; `uv.lock` contém `mypy==2.3.1`.

---

## Phase 5: User Story 2 — Strict sênior e compatibilidade ruff/pytest (Priority: P2)

**Goal**: `mypy` `strict` aplica `disallow-untyped-defs/calls` `warn-return-any` `strict-equality` além do default sem quebrar `tests/` (SC-002, FR-003).

**Independent Test**: `quickstart.md` Cenário 2: `uv run mypy --strict --show-error-codes` lista `no-untyped-def` quando provocado em `src/` futuro, mas não em `tests/` com `overrides`.

- [x] T021 [US2] Validar `strict` sênior: criar `f.py` com `x: list` sem param (`list` vs `list[int]`) fora de `tests/` → `mypy --strict` reprova `disallow-any-generics` (`misc`) (FR-002, D3, quickstart Cenário 2)
- [x] T022 [US2] Validar `overrides` `tests.*`: `uv run mypy --strict tests/test_harness_debts.py` com `def test_foo():` sem `-> None` não reprova `disallow_untyped_defs` em `tests/`, mas reprovaria em `packages/core/src.py` sem `overrides` (FR-003, D4)
- [x] T023 [P] [US2] Validar `warn_unused_configs`: criar `[[tool.mypy.overrides]] module = "foo.bar"` typo → `mypy` avisa `unused config` (FR-002, D4, quickstart Cenário 2)

---

## Phase 6: User Story 3 — Fronteira, cache, README e commit inquebráveis (Priority: P3)

**Goal**: `mypy.ini` ausente + `.mypy_cache` ignorado + `lefthook`/`packages` ausentes + `specs/README.md` `007 ✅` + `git ls-files` 0 + `tasks.md` zero `[ ]` (SC-005/007/008, FR-004/007/014/015/016).

**Independent Test**: `quickstart.md` Cenário 5 + 6: `! test -f mypy.ini` + `git check-ignore -q .mypy_cache` + `! test -f lefthook.yml` + `grep -q "007.*mypy.*✅" specs/README.md` + `git ls-files --error-unmatch specs/007-mypy/spec.md` + `grep -E "^- \[ \]" tasks.md` → 0.

- [x] T024 [US3] Validar `mypy.ini` ausente: `! test -f mypy.ini && ! test -f .mypy.ini` (fonte única) e `mypy` lê `pyproject.toml` sem `--config-file` (FR-004, D2)
- [x] T025 [US3] Validar `.mypy_cache`/`dmypy.json` ignorados: `uv run mypy --strict .` cria `.mypy_cache/`, `git check-ignore -q .mypy_cache` positivo, `git status --porcelain` não lista `.mypy_cache/`, `! git ls-files | grep .mypy_cache` (FR-007, D8)
- [x] T026 [US3] Validar `specs/README.md` `007 ✅`: `grep -q "007.*mypy.*✅" specs/README.md` (inquebrável, D8) — `README` desatualizado (`⏳`) reprova FR-015
- [x] T027 [US3] Validar `git ls-files` `spec 007` rastreado: `git ls-files --error-unmatch specs/007-mypy/spec.md` 0 (inquebrável, `??` reprova FR-016)
- [x] T028 [US3] Validar fronteira: `! test -f lefthook.yml && ! test -d packages && ! grep -q '^\[tool\.mypy\]' mypy.ini` (FR-014, D10, Escada)

---

## Phase 7: Polish & Convergência 🟢

**Purpose**: fechar ciclo vermelho→verde, provar determinismo, atualizar harness e versionar evidências.

- [x] T029 🟢 Executar `scripts/verify/f0-007-mypy.sh` e `scripts/verify/f0-007-mypy.sh --quiet` e preservar saída íntegra em `specs/007-mypy/evidence/green.txt`. Esperado `exit=0` com 12–16/12–16 aprovadas (SC-004, plan.md Fase D:1)
- [x] T030 🟢 Executar `uv run mypy --strict .` e `uv run mypy --strict tests/` e preservar saída em `specs/007-mypy/evidence/mypy_green.txt` (ou stdout). Esperado 0 em repo conforme (FR-008/009, SC-001)
- [x] T031 Executar `quickstart.md` validação determinismo: `scripts/verify/f0-007-mypy.sh > /tmp/r1.txt 2>&1` vs `/tmp/r2.txt` `diff` idêntico + `uv run mypy --strict . > /tmp/m1.txt` vs `/tmp/m2.txt` `diff` idêntico + `EPOCHSECONDS <5s` (FR-011, SC-004, plan.md Fase D:3)
- [x] T032 Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` e `uv run mypy --strict .` 0 e `uv run ruff check .` 0 e `uv run pytest -q` 12 passed (quádruplo) — todos green simultâneos (FR-012, SC-006, plan.md Fase D:4)
- [x] T033 Gerar `scripts/verify/manifest.sha256` 7 linhas: `sha256sum scripts/verify/f0-001-foundation.sh scripts/verify/f0-002-constitution.sh scripts/verify/f0-003-ci-minimo.sh scripts/verify/f0-004-uv-workspace.sh scripts/verify/f0-005-pytest.sh scripts/verify/f0-006-ruff.sh scripts/verify/f0-007-mypy.sh > scripts/verify/manifest.sha256` e validar `sha256sum -c scripts/verify/manifest.sha256` exit 0 (FR-008, D8, plan.md Fase C:4)
- [x] T034 Atualizar `scripts/verify/README.md` tabela — nova linha `f0-007-mypy.sh | 12–16 | MyPy 2.3.1 strict — type checker (FR-001..016, 007)` — conforme `plan.md` Fase C:5 e ADR-002 crescimento
- [x] T035 Atualizar `specs/README.md` índice — `007 | 0.3 | MyPy 2.3.1 strict | ✅` (FR-015, inquebrável) — conforme `plan.md` Fase C:5 e ADR-011
- [x] T036 Executar `quickstart.md` validação completa em um comando (Cenário 1–6): `uv run mypy --version | grep -q "2.3.1" && uv run mypy --strict . --no-error-summary >/dev/null 2>&1 && sha256sum -c scripts/verify/manifest.sha256 && for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && ! test -f mypy.ini && grep -q "007.*mypy.*✅" specs/README.md && git ls-files --error-unmatch specs/007-mypy/spec.md` → todos `OK` = `contracts/mypy-contract.md` satisfeito (SC-001..008)
- [x] T037 Registrar ciclo em commits separados vermelho→verde obedecendo `CONTRIBUTING.md` §1 (`^(feat|fix|docs|chore|refactor)(\(.+\))?: .+`): commit 🔴 com oracle + `red.txt`, commit 🟢 com `pyproject.toml`+`uv.lock`+`.mypy_cache`+`specs/README.md`+`manifest.sha256`+`README.md`+`green.txt`/`mypy_green.txt` — par auditável (Princípio III, plan.md Fase D:6)
- [x] T038 [P] Anotar em `specs/007-mypy/quickstart.md` ou `plan.md` Fase E que Cenário remoto (`push` conforme verde + `PR` com `mypy.ini` vermelho, SC-005) só é observável após `push`/`PR` real em `main`/`develop` e fica deferido pós-merge (não bloqueia convergência local, plan.md Fase E)

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
Phase 4 (T017–T020)              US1 — mypy verde (MVP) 🟢
   ↓
Phase 5 (T021–T023)              US2 — strict sênior
   ↓
Phase 6 (T024–T028)              US3 — fronteira/cache/README/commit/CONVERGE
   ↓
Phase 7 (T029–T038)              Polish & Convergência (verde + determinismo + harness acumulado)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T004 | T001, T002 | harness íntegro + alvo inexistente são pré-condição do contrato |
| T005–T015 | T004 | asserções exigem esqueleto `oracle-cli` (exit/flags/CANON/EPOCHSECONDS) |
| T016 | T005–T015 | vermelho só é prova se oráculo cobrir FR-001..016 |
| T017 | **T016** | `uv add --dev` antes do vermelho falha SC-004 de forma irrecuperável |
| T018–T020 | T017 | `[tool.mypy]` + `uv.lock` + `mypy --strict` só fazem sentido com `mypy` em `dev` |
| T021–T023 | T018 | `strict`/`overrides` exigem `pyproject.toml` com `mypy` |
| T024–T028 | T021 | fronteira/cache/README/commit/CONVERGE exigem `mypy` verde |
| T029 | T017–T028 | verde só é verde após última mutação (`pyproject.toml` + `uv.lock` + `manifest` + `README` + `specs/README.md` + `git ls-files`) |
| T033 | T029 | `manifest.sha256` 7 linhas só após `f0-007` existir |
| T037 | T029 | commits só após verde |

### Oportunidades reais de paralelismo

**Três oportunidades reais**, cobrindo 3 tarefas, verificadas quanto a colisão de arquivo:

- **T023** — `warn_unused_configs` somente leitura, paralelizável com `T021`/`T022` (strict).
- **T038** — anotação deferida remota, não toca `pyproject.toml` nem oracle após verde.

As demais **não** são paralelizáveis: T005–T015 editam o mesmo `f0-007-mypy.sh`, T017–T020 tocam `pyproject.toml`/`uv.lock` sequencialmente, T016/T029/T030 escrevem `evidence/` ordenadamente. Marcá-las `[P]` criaria colisão real.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T020). Entrega **mypy verde** — `uv run mypy --strict .` passa sem `mypy.ini`; `uv.lock` contém `mypy==2.3.1`. Sem ele, `lefthook` (009) orquestraria `mypy` sem lock, e `010` (`uv sync --frozen` + `mypy` em CI) não teria `uv.lock`.

### Entrega incremental

1. Phases 1–2 → pré-requisitos + esqueleto (remoção segura futura)
2. Phase 3 → 🔴 vermelho preservado (prova de test-first garantida)
3. Phase 4 → **mypy verde** — `mypy 2.3.1` existe (MVP)
4. Phase 5 → `strict` sênior + `overrides` `tests.*` — sem `disallow_untyped_defs` bloqueando `tests/`
5. Phase 6 → `mypy.ini` ausente + `.mypy_cache` ignorado + `lefthook`/`packages` ausentes + `README` `007 ✅` + `git ls-files` — fronteira + inquebráveis fechados
6. Phase 7 → 🟢 verde, `mypy --strict` verdes, determinismo, harness acumulado, commits auditáveis

### Critério de conclusão do item

| Condição | Verificação | SC |
|---|---|---|
| `mypy==2.3.1` em `[dependency-groups] dev` | T017 + T005 | SC-001 |
| `[tool.mypy]` `python_version 3.12` `strict true` | T018 + T006 | SC-001 |
| `uv.lock` com `mypy 2.3.1` | T017 + T009 | SC-001 |
| `uv run mypy --strict .` 0 | T020 | SC-001 |
| `mypy --version` 2.3.1 `strict` 11 flags | T019 | SC-003 |
| `f0-007` 12–16 `exit 0` `<5s` `2× cmp` | T029 | SC-004 |
| `mypy.ini`/`lefthook.yml` reprova `FR-004`/`FR-014` | T024 + T028 | SC-005 |
| `for f` + `mypy` + `ruff` + `pytest` 0 | T032 | SC-006 |
| `tasks.md` zero `[ ]` | T015 + T029 | SC-007 |
| `specs/README.md` `007 ✅` | T026 | SC-007 inquebrável |
| `git ls-files` `spec 007` rastreado | T027 | SC-007 inquebrável |
| Sem `lefthook`/`packages/` | T028 | SC-008 |
| 12–16/12–16 `exit 0` + `mypy` 0 | T029 | FR-011 |
| Harness acumulado `for f` 0 | T032 | FR-012 |
| Commits vermelho→verde separados | T037 | Princípio III |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **2** das 38 tarefas, deliberadamente — este item edita `f0-007-mypy.sh` e `pyproject.toml` muitas vezes sequencialmente.
- Cada tarefa cita o FR/SC que a origina, para que qualquer linha do oráculo seja rastreável até `spec.md` sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits **separados**: é a prova auditável de que o teste veio primeiro, e ela não é recuperável depois (plan.md Fase B).
- T038 é deferido remoto — não bloqueia `T029` verde local, mas SC-005 remoto só fecha após observação em GitHub (plan.md Fase E).
- Nenhuma tarefa introduz `lefthook`/`pip-audit`/`trivy` — violaria FR-014 e Escada (constitution Additional Constraints).
