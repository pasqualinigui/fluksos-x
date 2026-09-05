---
description: "Task list for 006 — Ruff 0.16.5 — linter + formatter"
---

# Tasks: Ruff 0.16.5 — linter + formatter

**Input**: Design documents from `/specs/006-ruff/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md` (D1–D10), `data-model.md` (4 entidades), `contracts/ruff-contract.md`, `contracts/oracle-cli.md`, `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-004). A prova é `f0-006-ruff.sh` 10–14 asserções + `uv run ruff check`/`format` reprovando (🔴) e aprovando (🟢) — não recuperável depois. `ruff check`/`format` são o teste.

**Artefatos deste item**: `pyproject.toml` alterado (`[tool.ruff]` + `[tool.ruff.lint]` + `[tool.ruff.format]`), `uv.lock` com `ruff 0.16.5`, `.ruff_cache/` efêmero, `scripts/verify/f0-006-ruff.sh` (10–14 asserções), `scripts/verify/manifest.sha256` 6 linhas, `scripts/verify/README.md` (+1 linha), `specs/006-ruff/evidence/` (`red.txt`, `green.txt`). Nenhum `mypy`/`lefthook`/`packages/`/`ruff.toml`/`D`/`ANN`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. `pyproject.toml` fonte única (sem `ruff.toml`). Oráculo em `scripts/verify/f0-006-ruff.sh` segue ADR-002. `tests/` já existe (005) e será lintado com `per-file-ignores`. Spec dir `specs/006-ruff/` segue Spec-Kit.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `005`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oracle completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..014 antes de `pyproject.toml` ter `[tool.ruff]`. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (III, SC-004) |
| `ruff` por história | **Fase C materializa `[tool.ruff]` + `ruff` juntos** | `ruff` e `format` partilham `pyproject.toml` e `uv.lock`; dividir criaria colisão de escrita |
| US2/US3 após US1 | **US2/US3 verificação após verde** | Depois do verde, US2/US3 não mutam `pyproject.toml` além de verificação estática (rules, cache, fronteira) |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T015 (vermelho) antes de T016** — criar `[tool.ruff]` antes do vermelho satisfaz FR-002 e ainda assim falha SC-004/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T014** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON_ORDER, FKX_ORACLE_NESTED, EPOCHSECONDS) é pré-requisito de qualquer asserção.
3. **T026 (verde) após T016–T022** — verde só é verde depois da última mutação (`pyproject.toml` + `uv.lock` + `manifest` + `README`).

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T015 | US1+US2+US3 (oracle) |
| Fase C — Ruff verde 🟢 | Phase 4 + Phase 5 | T016–T022 | US1 (MVP) + US2 |
| Fase D — Verde e convergência | Phase 6 + Phase 7 | T023–T031 | US3, Polish |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (pytest 005) está verde e que os artefatos-alvo ainda não existem; preparar evidências e medir hashes.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com `f0-001` 30/30 `f0-002` 33/33 `f0-003` 14/14 `f0-004` 14/14 `f0-005` 15/15 + `uv run pytest -q` 11 passed. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausência de `[tool.ruff]` em `pyproject.toml` (`! grep -q "tool.ruff" pyproject.toml`), ausência de `ruff.toml` (`! test -f ruff.toml`), ausência de `ruff` em `uv.lock` (`! grep -q 'name = "ruff"' uv.lock`), e que `docs/plan/research/f0-006-ruff.md` 376 linhas e `.gitignore` já cobre `.ruff_cache` (`grep -q .ruff_cache .gitignore`) — registra fronteira FR-002/005/006 (plan.md Fase A:2)
- [x] T003 Criar diretório de evidências `specs/006-ruff/evidence/` (`mkdir -p specs/006-ruff/evidence`) para `red.txt`, `green.txt` e medir hashes `sha256sum scripts/verify/f0-*.sh` → devem bater `63412ca7…` `b63ac3c8…` `d10c61…` `42e2d36…` `e39a1f1c…` (Q1/Q8, D8)

**Checkpoint**: pré-requisitos satisfeitos — harness 005 íntegro, alvo inexistente, hashes congelados, evidências endereçáveis.

---

## Phase 2: Foundational (Esqueleto do oráculo) ⚠️ BLOQUEANTE

**Purpose**: criar o invólucro que todo FR vai usar. **Nenhuma asserção de Phase 3 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: este esqueleto implementa o contrato `specs/001-.../contracts/oracle-cli.md` herdado via `contracts/oracle-cli.md` deste item e `scripts/verify/README.md`. Sem ele, `--list`/`--quiet`/códigos não são decidíveis.

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-006-ruff.sh` com esqueleto do contrato herdado: parsing de `--quiet` e `--list`, resolução da raiz por `SCRIPT_DIR`/`REPO_ROOT` (nunca `$PWD`), códigos `0` conforme / `1` não conforme / `2` erro de uso, formato `<emoji> FR-XXX <descrição>` uma linha por REQ-ID, linha de resultado `X/Y passed`, mapa `CANON` único 10–14 IDs com `CANON_ORDER`, guarda `FKX_ORACLE_NESTED`, `EPOCHSECONDS` para `<5s` (não `date +%s`), sem efeitos além de stdout/stderr (FR-011, oracle-cli.md §1–§6, data-model.md Manifest)

**Checkpoint**: foundation ready — asserções de história podem ser acrescentadas sem recriar contrato.

---

## Phase 3: Oracle completo — 10–14 asserções + vermelho 🔴 (US1+US2+US3)

**Goal**: oráculo que responda por código de saída cobrindo **todos** os FR-001..014 antes de existir qualquer coisa para aprovar. É a única prova auditável de test-first.

**Independent Test**: executar em estado com `[tool.ruff]`/`ruff`/`manifest 6` inexistentes → `exit 1` com reprovação nominal por FR; `--list` enumera 10–14 IDs sem executar; `FKX_ORACLE_NESTED=1` evita recursão `f0-005`/`f0-006`.

### Implementation por grupo (mesmo arquivo, sequencial — não paralelizável)

- [x] T005 [US1] Implementar em `scripts/verify/f0-006-ruff.sh` **Grupo FR-001** — `[dependency-groups] dev` contém `ruff==0.16.5` exato via `tomllib` (`d["dependency-groups"]["dev"]` contém `ruff==0.16.5`), sem `ruff` em `[project.dependencies]` (FR-001, D1/D6)
- [x] T006 [US1] Implementar **Grupo FR-002/003/004** — `[tool.ruff]` `line-length 88` `target-version py312` `exclude` lista + `[tool.ruff.lint]` `select E,F,W,C90` `extend-select I,UP,B,SIM,S,C4,A,RUF` `ignore E501,S101,S603` `per-file-ignores tests/**/* S101,S603` + `[tool.ruff.format]` `quote-style double` `indent-style space` `line-ending auto` `docstring-code-format false` via `tomllib` (FR-002/003/004, D2/D3/D4)
- [x] T007 [US1] Implementar **Grupo FR-005** — `! test -f ruff.toml && ! test -f .ruff.toml` (fonte única `pyproject.toml`, FR-005, D2)
- [x] T008 [US1] Implementar **Grupo FR-006/007** — `uv.lock` contém `ruff` (`grep 'name = "ruff"'`) + `tomllib` válido + `uv lock --check` quando `uv` presente + `.ruff_cache` gitignored (`git check-ignore -q .ruff_cache` positivo, `! git ls-files | grep .ruff_cache`, `! git check-ignore -q uv.lock`) (FR-006/007, D1/D8)
- [x] T009 [US1] Implementar **Grupo FR-008/009/010** — `uv run ruff check .` 0 em conforme (quando `ruff` instalado, senão apenas verifica config) + `uv run ruff format --check --diff .` 0 + `ruff format .` idempotente `sha256sum` segunda vez idêntico (FR-008/009/010, D5, Q5/Q10)
- [x] T010 [US1] Implementar **Grupo FR-011** — oráculo self-check `0/1/2` `quiet` `list` `FKX_ORACLE_NESTED` `EPOCHSECONDS <5s` `2× cmp` idêntico (FR-011, D9, oracle-cli.md)
- [x] T011 [US2] Implementar **Grupo FR-014** — fronteira `! grep -q '\[tool\.mypy\]' pyproject.toml && ! test -f mypy.ini && ! test -f lefthook.yml && ! test -d packages && ! grep -q 'ruff.*ALL' pyproject.toml` (FR-014, D10, Escada)
- [x] T012 [US3] Implementar **Grupo FR-012** — CI glob `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` passa (FR-012, D9)
- [x] T013 [US3] Implementar **Grupo FR-013** — CONVERGE `grep -E "^- \[ \]" specs/006-ruff/tasks.md` → 0 quando tasks.md tem zero `[ ]` (FR-013, ADR-015d)

### Captura do vermelho (não recuperável)

- [x] T014 🔴 **Executar** `scripts/verify/f0-006-ruff.sh` e `scripts/verify/f0-006-ruff.sh --quiet` e preservar saída íntegra em `specs/006-ruff/evidence/red.txt`. Esperado `exit=1` com reprovação em massa (FR-001 sem `ruff` + FR-002 sem `[tool.ruff]` + FR-006 sem `ruff` em `uv.lock`). Conferir `--list` enumera 10–14 IDs sem executar. Este `red.txt` é a prova de TDD — se não existir antes de T016, o par vermelho→verde é irrecuperável (Princípio III, SC-004, plan.md Fase B:3)
- [x] T015 [P] **Executar** `uv run ruff check --output-format=concise .` em estado vermelho (sem `ruff`) deve falhar ou `ruff` não encontrado — evidência de que linter ainda não instalado (SC-002, FR-008)

**Checkpoint**: existe oráculo completo e existe prova registrada de que ele reprova. A partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Lint e format verde em clone limpo (Priority: P1) 🎯 MVP

**Goal**: clone limpo obtém `ruff 0.16.5` com `uv sync` + `uv run ruff check`/`format --check` determinísticos (SC-001, SC-003, SC-004).

**Independent Test**: `quickstart.md` Cenário 1 + 3 (FR-001/002/006/008/009): `uv add --dev ruff==0.16.5` → `dev` exato, `uv.lock` com hash, `ruff check` 0, `format --check` 0, `format` idempotente.

- [x] T016 [US1] Materializar `ruff` **via `uv`** (D1/D6): `uv add --dev ruff==0.16.5` e `uv sync` (sem `--locked` em 006) — acrescenta `ruff==0.16.5` em `[dependency-groups] dev` com `pytest 9.1.1` coexistindo e gera `uv.lock` com `ruff 0.16.5` + deps; fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub TOML válido com `[[package]] name="ruff"` (FR-001/006, contracts/ruff-contract.md §2)
- [x] T017 [US1] Acrescentar `[tool.ruff]` + `[tool.ruff.lint]` + `[tool.ruff.format]` em `pyproject.toml` conforme `contracts/ruff-contract.md` §2 (line-length 88, py312, select E,F,W,C90, extend-select I,UP,B,SIM,S,C4,A,RUF, ignore E501,S101,S603, per-file-ignores tests/**/*, format double/space) — validar via `python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["tool"]["ruff"]["line-length"]==88'` (FR-002/003/004, D2/D3/D4)
- [x] T018 [US1] Validar `uv run ruff check .` 0 em `tests/` (com `per-file-ignores` S101/S603) — criar `tests/` limpo, `ruff check` deve passar; injetar `a.py` com `import os, sys` desordenado → `ruff check` reprova `I001` (FR-008, quickstart Cenário 1)
- [x] T019 [US1] Validar `uv run ruff format --check --diff .` 0 e `uv run ruff format .` idempotente — criar `b.py` com `x='a'` → `format --check` reprova diff `"'a'"`, `ruff format .` corrige para `"` e segunda `format` não altera `sha256sum` (FR-009/010, quickstart Cenário 3)

**Checkpoint**: MVP entregue — `uv run ruff check` + `format --check` passam sem violação; `uv.lock` contém `ruff==0.16.5`.

---

## Phase 5: User Story 2 — Regras sênior e compatibilidade pytest/mypy (Priority: P2)

**Goal**: `ruff` aplica `UP`/`B`/`S`/`SIM`/`C4`/`A`/`RUF`/`I` além do default `E,F,W` sem quebrar `tests/` (SC-002, FR-003).

**Independent Test**: `quickstart.md` Cenário 2: `uv run ruff check --output-format=concise` lista `I001`/`UP007`/`B006` quando provocado; `grep -q 'per-file-ignores.*S101' pyproject.toml`.

- [x] T020 [US2] Validar `extend-select` sênior: criar `c.py` com `from typing import Union; x: Union[int, str]` → `ruff check` sugere `UP007` `X | Y`; verificar `select` sem `D`/`ANN` (não gera 100+ violações em `tests/`) (FR-003, D3, quickstart Cenário 2)
- [x] T021 [US2] Validar `per-file-ignores` `tests/**/* S101,S603`: `ruff check tests/test_harness_debts.py` com `assert` e `subprocess.run` não reprova `S101`/`S603`, mas `c.py` fora de `tests/` com `assert True` reprovaria `S101` se `S` não fosse `ignore` global (FR-003, D3/Q7)
- [x] T022 [P] [US2] Validar `ignore E501`: criar `d.py` linha 120 chars → `ruff check` não reprova `E501` (format cuida), mas `ruff format --check` reprova se não formatado (FR-003, D3)

---

## Phase 6: User Story 3 — Fronteira, cache e CONVERGE (Priority: P3)

**Goal**: `ruff.toml` ausente + `.ruff_cache` ignorado + `mypy`/`lefthook`/`packages` ausentes + `tasks.md` zero `[ ]` (SC-005/007/008, FR-005/007/014).

**Independent Test**: `quickstart.md` Cenário 5 + 6: `! test -f ruff.toml` + `git check-ignore -q .ruff_cache` + `! test -f mypy.ini` + `grep -E "^- \[ \]" tasks.md` → 0.

- [x] T023 [US3] Validar `ruff.toml` ausente: `! test -f ruff.toml && ! test -f .ruff.toml` (fonte única) e `ruff check` lê `pyproject.toml` sem `--config` (FR-005, D2)
- [x] T024 [US3] Validar `.ruff_cache` ignorado: `uv run ruff check .` cria `.ruff_cache/`, `git check-ignore -q .ruff_cache` positivo, `git status --porcelain` não lista `.ruff_cache/`, `! git ls-files | grep .ruff_cache` (FR-007, D8)
- [x] T025 [US3] Validar fronteira: `! test -f mypy.ini && ! test -f lefthook.yml && ! test -d packages && ! grep -q '^\[tool\.mypy\]' pyproject.toml` (FR-014, D10, Escada)

---

## Phase 7: Polish & Convergência 🟢

**Purpose**: fechar ciclo vermelho→verde, provar determinismo, atualizar harness e versionar evidências.

- [x] T026 🟢 Executar `scripts/verify/f0-006-ruff.sh` e `scripts/verify/f0-006-ruff.sh --quiet` e preservar saída íntegra em `specs/006-ruff/evidence/green.txt`. Esperado `exit=0` com 10–14/10–14 aprovadas (SC-004, plan.md Fase D:1)
- [x] T027 🟢 Executar `uv run ruff check .` e `uv run ruff format --check --diff .` e preservar saída em `specs/006-ruff/evidence/ruff_green.txt` (ou stdout). Esperado 0 em repo conforme (FR-008/009, SC-001)
- [x] T028 Executar `quickstart.md` validação determinismo: `scripts/verify/f0-006-ruff.sh > /tmp/r1.txt 2>&1` vs `/tmp/r2.txt` `diff` idêntico + `uv run ruff check . > /tmp/c1.txt` vs `/tmp/c2.txt` `diff` idêntico + `uv run ruff format --check --diff .` idêntico + `ruff format .` idempotente `sha256sum` (FR-011, SC-003, plan.md Fase D:3)
- [x] T029 Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` e `uv run pytest -q` 11 passed e `uv run ruff check .` 0 (tríplice) — todos green simultâneos (FR-012, SC-006, plan.md Fase D:4)
- [x] T030 Atualizar `scripts/verify/README.md` tabela — nova linha `f0-006-ruff.sh | 10–14 | Ruff 0.16.5 — linter + formatter (FR-001..014)` — conforme `plan.md` Fase C:5 e ADR-002 crescimento
- [x] T031 Gerar `scripts/verify/manifest.sha256` 6 linhas: `sha256sum scripts/verify/f0-001-foundation.sh scripts/verify/f0-002-constitution.sh scripts/verify/f0-003-ci-minimo.sh scripts/verify/f0-004-uv-workspace.sh scripts/verify/f0-005-pytest.sh scripts/verify/f0-006-ruff.sh > scripts/verify/manifest.sha256` e validar `sha256sum -c scripts/verify/manifest.sha256` exit 0 (FR-008, D8, plan.md Fase C:4)
- [x] T032 Executar `quickstart.md` validação completa em um comando (Cenário 1–6): `uv run ruff check . && uv run ruff format --check --diff . && uv run ruff format . && sha256sum -c scripts/verify/manifest.sha256 && for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && ! test -f ruff.toml && grep -q 'per-file-ignores' pyproject.toml` → todos `OK` = `contracts/ruff-contract.md` satisfeito (SC-001..008)
- [x] T033 Registrar ciclo em commits separados vermelho→verde obedecendo `CONTRIBUTING.md` §1 (`^(feat|fix|docs|chore|refactor)(\(.+\))?: .+`): commit 🔴 com oracle + `red.txt`, commit 🟢 com `pyproject.toml`+`uv.lock`+`.ruff_cache`+`manifest.sha256`+`README.md`+`green.txt`/`ruff_green.txt` — par auditável (Princípio III, plan.md Fase D:6)
- [x] T034 [P] Anotar em `specs/006-ruff/quickstart.md` ou `plan.md` Fase E que Cenário remoto (`push` conforme verde + `PR` com `ruff.toml`/`mypy.ini` vermelho, SC-005) só é observável após `push`/`PR` real em `main`/`develop` e fica deferido pós-merge (não bloqueia convergência local, plan.md Fase E)

---

## Dependencies

### Ordem de fases (estrita)

```
Phase 1 (T001–T003)              Setup
   ↓
Phase 2 (T004)                   Foundational — esqueleto oracle (BLOQUEANTE)
   ↓
Phase 3 (T005–T015)              Oracle completo + 🔴 vermelho preservado
   ↓
Phase 4 (T016–T019)              US1 — ruff verde (MVP) 🟢
   ↓
Phase 5 (T020–T022)              US2 — rules sênior
   ↓
Phase 6 (T023–T025)              US3 — fronteira/cache/CONVERGE
   ↓
Phase 7 (T026–T034)              Polish & Convergência (verde + determinismo + harness acumulado)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T004 | T001, T002 | harness íntegro + alvo inexistente são pré-condição do contrato |
| T005–T013 | T004 | asserções exigem esqueleto `oracle-cli` (exit/flags/CANON/EPOCHSECONDS) |
| T014 | T005–T013 | vermelho só é prova se oráculo cobrir FR-001..014 |
| T016 | **T014** | `uv add --dev` antes do vermelho falha SC-004 de forma irrecuperável |
| T017–T019 | T016 | `[tool.ruff]` + `uv.lock` + `ruff check`/`format` só fazem sentido com `ruff` em `dev` |
| T020–T022 | T017 | `extend-select`/`per-file-ignores` exigem `pyproject.toml` com `ruff` |
| T023–T025 | T020 | fronteira/cache/CONVERGE exigem `ruff` verde |
| T026 | T016–T025 | verde só é verde após última mutação (`pyproject.toml` + `uv.lock` + `manifest` + `README`) |
| T030 | T026 | `README.md` só após verde medido |
| T031 | T026 | `manifest.sha256` 6 linhas só após `f0-006` existir |
| T033 | T026 | commits só após verde |

### Oportunidades reais de paralelismo

**Três oportunidades reais**, cobrindo 3 tarefas, verificadas quanto a colisão de arquivo:

- **T015** — `ruff check --output-format=concise` somente leitura, paralelizável com `T014` (red) — arquivos de saída distintos `/tmp/*`.
- **T022** — `ignore E501` validação somente leitura, paralelizável com `T020`/`T021` (rules).
- **T034** — anotação deferida remota, não toca `pyproject.toml` nem oracle após verde.

As demais **não** são paralelizáveis: T005–T013 editam o mesmo `f0-006-ruff.sh`, T016–T019 tocam `pyproject.toml`/`uv.lock` sequencialmente, T014/T026 escrevem `evidence/` ordenadamente. Marcá-las `[P]` criaria colisão real.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T019). Entrega **ruff verde** — `uv run ruff check` + `format --check` passam sem violação; `uv.lock` contém `ruff==0.16.5`. Sem ele, `mypy` (007) validaria sobre base não formatada. US2/US3 agregam rules sênior e fronteira mas o MVP já materializa `ruff` pinado.

### Entrega incremental

1. Phases 1–2 → pré-requisitos + esqueleto (remoção segura futura)
2. Phase 3 → 🔴 vermelho preservado (prova de test-first garantida)
3. Phase 4 → **ruff verde** — `ruff` 0.16.5 existe (MVP)
4. Phase 5 → `extend-select` sênior + `per-file-ignores` — sem `E501`/`S101`/`S603` bloqueando `tests/`
5. Phase 6 → `ruff.toml` ausente + `.ruff_cache` ignorado + `mypy`/`lefthook`/`packages` ausentes — fronteira fechada
6. Phase 7 → 🟢 verde, `ruff check`/`format` verdes, determinismo, harness acumulado, commits auditáveis

### Critério de conclusão do item

| Condição | Verificação | SC |
|---|---|---|
| `ruff==0.16.5` em `[dependency-groups] dev` | T016 + T005 | SC-001 |
| `[tool.ruff]` `line-length 88` `py312` | T017 + T006 | SC-001 |
| `uv.lock` com `ruff 0.16.5` | T016 + T008 | SC-001 |
| `uv run ruff check .` 0 + `format --check` 0 | T018 + T019 | SC-001 |
| `ruff check` lista `I001`/`UP007`/`B006` | T020 | SC-002 |
| `E501` não lista (ignore) | T022 | SC-002 |
| `ruff format` idempotente `sha256sum` | T019 | SC-003 |
| `f0-006` 10–14 `exit 0` `<5s` `2× cmp` | T026 | SC-004 |
| `ruff.toml`/`mypy.ini` reprova `FR-005`/`FR-014` | T023 + T025 | SC-005 |
| `for f` + `pytest` + `ruff` 0 | T029 | SC-006 |
| `tasks.md` zero `[ ]` | T013 + T026 | SC-007 |
| Sem `mypy`/`packages/` | T011 + T025 | SC-008 |
| 10–14/10–14 `exit 0` + `ruff` 0 | T026 | FR-011 |
| Harness acumulado `for f` 0 | T029 | FR-012 |
| Commits vermelho→verde separados | T033 | Princípio III |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **3** das 34 tarefas, deliberadamente — este item edita `f0-006-ruff.sh` e `pyproject.toml` muitas vezes sequencialmente.
- Cada tarefa cita o FR/SC que a origina, para que qualquer linha do oráculo seja rastreável até `spec.md` sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits **separados**: é a prova auditável de que o teste veio primeiro, e ela não é recuperável depois (plan.md Fase B).
- T034 é deferido remoto — não bloqueia `T026` verde local, mas SC-005 remoto só fecha após observação em GitHub (plan.md Fase E).
- Nenhuma tarefa introduz `mypy`/`pip-audit`/`trivy` — violaria FR-014 e Escada (constitution Additional Constraints).
