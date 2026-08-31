---
description: "Task list for 008 — pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades"
---

# Tasks: pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades

**Input**: Design documents from `/specs/008-pip-audit-trivy/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md` (D1–D10), `data-model.md` (5 entidades), `contracts/pip-audit-contract.md`, `contracts/oracle-cli.md`, `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-004). A prova é `f0-008-pip-audit.sh` 12–16 asserções + `uv run pip-audit`/`pip-audit --dry-run` reprovando (🔴) e aprovando (🟢) — não recuperável depois. `pip-audit` + `Trivy fs` são o teste.

**Artefatos deste item**: `pyproject.toml` alterado (`pip-audit==2.10.1` em `[dependency-groups] dev`), `uv.lock` com `pip-audit 2.10.1` + `cyclonedx-python-lib`/`cachecontrol`, `Trivy 0.74.0` pin documentado `aquasec/trivy:0.74.0` (não em `pyproject.toml`), `scripts/verify/f0-008-pip-audit.sh` (12–16 asserções), `scripts/verify/manifest.sha256` 8 linhas, `specs/README.md` índice `008 ✅`, `specs/008-pip-audit-trivy/evidence/` (`red.txt`, `green.txt`). Nenhum `lefthook.yml`/`gitleaks`/`packages/`/`docker-compose.yml`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. `pip-audit` em `[dependency-groups] dev` fonte única (sem `requirements.txt`). Oráculo em `scripts/verify/f0-008-pip-audit.sh` segue ADR-002. `tests/` já existe (007) e será auditado (41 pacotes). Spec dir `specs/008-pip-audit-trivy/` segue Spec-Kit.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `007`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oracle completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..016 antes de `pyproject.toml` ter `pip-audit`. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (III, SC-004) |
| `pip-audit` por história | **Fase C materializa `pip-audit` + `Trivy` pin juntos** | `pip-audit` e `Trivy pin` partilham `pyproject.toml`/`uv.lock` vs doc; `Trivy` não entra em `pyproject.toml`, mas `f0-008` cobre ambos no mesmo arquivo |
| US2/US3 após US1 | **US2/US3 verificação após verde** | Depois do verde, US2/US3 não mutam `pyproject.toml` além de verificação estática (Trivy fs, cache, fronteira) |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T016 (vermelho) antes de T017** — criar `pip-audit` em `dev` antes do vermelho satisfaz FR-001 e ainda assim falha SC-004/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T015** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON_ORDER, FKX_ORACLE_NESTED, EPOCHSECONDS) é pré-requisito de qualquer asserção.
3. **T029 (verde) após T017–T028** — verde só é verde depois da última mutação (`pyproject.toml` + `uv.lock` + `manifest` + `README` + `git ls-files`).

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T016 | US1+US2+US3 (oracle) |
| Fase C — pip-audit verde 🟢 | Phase 4 + Phase 5 | T017–T022 | US1 (MVP) + US2 |
| Fase D — Verde e convergência | Phase 6 + Phase 7 | T023–T038 | US3, Polish |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (mypy 007) está verde e que os artefatos-alvo ainda não existem; preparar evidências e medir hashes.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com `f0-001` 30/30 `f0-002` 33/33 `f0-003` 14/14 `f0-004` 14/14 `f0-005` 15/15 `f0-006` 14/14 `f0-007` 16/16 + `uv run pip-audit --version` 2.10.1 (quando instalado, senão skip) + `uv run ruff check` 0 + `uv run mypy --strict .` 0 + `uv run pytest -q` 13 passed. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausência de `pip-audit` em `pyproject.toml` (`! grep -q pip-audit pyproject.toml`), ausência de `pip-audit` em `uv.lock` (`! grep -q 'name = "pip-audit"' uv.lock`), ausência de `requirements.txt`/`pylock.toml`/`pip-audit.toml` (`! test -f requirements.txt`), e que `docs/plan/research/f0-008-pip-audit-trivy.md` 332 linhas e `.gitignore` não ignora `uv.lock` — registra fronteira FR-001/002/004 (plan.md Fase A:2)
- [x] T003 Criar diretório de evidências `specs/008-pip-audit-trivy/evidence/` (`mkdir -p specs/008-pip-audit-trivy/evidence`) para `red.txt`, `green.txt` e medir hashes `sha256sum scripts/verify/f0-*.sh` → devem bater `63412ca7…` `b63ac3c8…` `d10c61…` `759376ee…` `dccb114a…` `5f268846…` `54fa8199…` (Q1/Q8, D8)

**Checkpoint**: pré-requisitos satisfeitos — harness 007 íntegro, alvo inexistente, hashes congelados, evidências endereçáveis.

---

## Phase 2: Foundational (Esqueleto do oráculo) ⚠️ BLOQUEANTE

**Purpose**: criar o invólucro que todo FR vai usar. **Nenhuma asserção de Phase 3 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: este esqueleto implementa o contrato `specs/001-.../contracts/oracle-cli.md` herdado via `contracts/oracle-cli.md` deste item e `scripts/verify/README.md`. Sem ele, `--list`/`--quiet`/códigos não são decidíveis.

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-008-pip-audit.sh` com esqueleto do contrato herdado: parsing de `--quiet` e `--list`, resolução da raiz por `SCRIPT_DIR`/`REPO_ROOT` (nunca `$PWD`), códigos `0` conforme / `1` não conforme / `2` erro de uso, formato `<emoji> FR-XXX <descrição>` uma linha por REQ-ID, linha de resultado `X/Y passed`, mapa `CANON` único 12–16 IDs com `CANON_ORDER` (inclui `FR-014` `README` e `FR-015` `git ls-files`), guarda `FKX_ORACLE_NESTED`, `EPOCHSECONDS` para `<5s` (não `date +%s`), sem efeitos além de stdout/stderr (FR-010, oracle-cli.md §1–§6, data-model.md Manifest)

**Checkpoint**: foundation ready — asserções de história podem ser acrescentadas sem recriar contrato.

---

## Phase 3: Oracle completo — 12–16 asserções + vermelho 🔴 (US1+US2+US3)

**Goal**: oráculo que responda por código de saída cobrindo **todos** os FR-001..016 antes de existir qualquer coisa para aprovar. É a única prova auditável de test-first.

**Independent Test**: executar em estado com `pip-audit`/`manifest 8` inexistentes → `exit 1` com reprovação nominal por FR; `--list` enumera 12–16 IDs sem executar; `FKX_ORACLE_NESTED=1` evita recursão `f0-007`/`f0-008`.

### Implementation por grupo (mesmo arquivo, sequencial — não paralelizável)

- [x] T005 [US1] Implementar em `scripts/verify/f0-008-pip-audit.sh` **Grupo FR-001** — `[dependency-groups] dev` contém `pip-audit==2.10.1` exato via `tomllib` (`d["dependency-groups"]["dev"]` contém `pip-audit==2.10.1`), sem `pip-audit` em `[project.dependencies]` nem `requirements*.txt`/`pylock.toml` (FR-001, D1/D5)
- [x] T006 [US1] Implementar **Grupo FR-002** — `pip-audit.toml` não existe (`! test -f pip-audit.toml && ! test -f .pip-audit.toml`) — sem config separada, auditoria via `uv run pip-audit` (FR-002, D2)
- [x] T007 [US1] Implementar **Grupo FR-003** — `uv.lock` contém `pip-audit` (`grep 'name = "pip-audit"'`) + `tomllib` válido + `uv lock --check` quando `uv` presente + `pip-audit --version` 2.10.1 e `--help` lista `cyclonedx-json`/`cyclonedx-xml` e `--fix` (FR-003, D1/D5)
- [x] T008 [US1] Implementar **Grupo FR-004** — `Trivy 0.74.0` pin `aquasec/trivy:0.74.0` documentado (não em `[dependency-groups] dev` nem `requirements*.txt`), verificável via `docker image inspect aquasec/trivy:0.74.0` ou `trivy --version` quando disponível; `Trivy` MUST NOT em `dev` (FR-004, D3)
- [x] T009 [US1] Implementar **Grupo FR-005** — `uv.lock` contém `pip-audit` e transitivos `cyclonedx-python-lib`/`cachecontrol`/`packaging` + `tomllib` válido + `uv lock --check` (FR-005, D1/D5)
- [x] T010 [US1] Implementar **Grupo FR-006** — `pip-audit` cache (`~/.cache/pip`) e `Trivy` DB (`~/.cache/trivy`) fora do repo (`! git ls-files | grep pip-audit`, `git check-ignore` não precisa) e `uv.lock` não ignorado (FR-006, D8)
- [x] T011 [US1] Implementar **Grupo FR-007/008** — `uv run pip-audit` 0 sem vulns (`No known vulnerabilities found` para 41 pacotes) + `uv run pip-audit --dry-run` `would have audited` + `uv run pip-audit -f json` com `dependencies[].vulns[]` + `pip-audit -f cyclonedx-json` `bomFormat CycloneDX` válido (FR-007/008, D2/D4)
- [x] T012 [US1] Implementar **Grupo FR-009** — `Trivy fs --severity HIGH,CRITICAL --format json .` skip `⏭️` se Docker/binary ausente, 0 com `Results` vazio quando disponível; não exige `lefthook.yml`/`gitleaks` (FR-009, D3)
- [x] T013 [US2] Implementar **Grupo FR-010** — oráculo self-check `0/1/2` `quiet` `list` `FKX_ORACLE_NESTED` `EPOCHSECONDS <5s` `2× cmp` idêntico (FR-010, D9, oracle-cli.md)
- [x] T014 [US2] Implementar **Grupo FR-014** — `specs/README.md` `grep -iq "008.*pip-audit.*✅" specs/README.md` (inquebrável, D8) (FR-014)
- [x] T015 [US2] Implementar **Grupo FR-015** — `git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md` 0 (inquebrável, `??` reprova) e `docs/plan/research/f0-008-pip-audit-trivy.md` 0 (FR-015, D8)
- [x] T016 [US3] Implementar **Grupo FR-011/012/013/016** — CI glob `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` + CONVERGE `grep -E "^- \[ \]" specs/008-pip-audit-trivy/tasks.md` 0 + fronteira `! test -f lefthook.yml` `! test -f gitleaks.toml` `! test -d packages` `! test -f docker-compose.yml` `! test -f requirements.txt` com `pip-audit` + `! grep -q "0.69.4"` (FR-011/012/013/016, D9/D10)

### Captura do vermelho (não recuperável)

- [x] T017 🔴 **Executar** `scripts/verify/f0-008-pip-audit.sh` e `scripts/verify/f0-008-pip-audit.sh --quiet` e preservar saída íntegra em `specs/008-pip-audit-trivy/evidence/red.txt`. Esperado `exit=1` com reprovação em massa (FR-001 sem `pip-audit` + FR-003 sem `pip-audit` em `uv.lock` + FR-007 sem `pip-audit` instalado). Conferir `--list` enumera 12–16 IDs sem executar. Este `red.txt` é a prova de TDD — se não existir antes de T018, o par vermelho→verde é irrecuperável (Princípio III, SC-004, plan.md Fase B:3)

**Checkpoint**: existe oráculo completo e existe prova registrada de que ele reprova. A partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Auditoria verde em clone limpo (Priority: P1) 🎯 MVP

**Goal**: clone limpo obtém `pip-audit 2.10.1` com `uv sync` + `uv run pip-audit` 0 determinístico sem vulns (SC-001, SC-003, SC-004).

**Independent Test**: `quickstart.md` Cenário 1 + 3 (FR-001/003/005/007): `uv add --dev pip-audit==2.10.1` → `dev` exato, `uv.lock` com hash, `pip-audit --version` 2.10.1, `pip-audit -f json` válido.

- [x] T018 [US1] Materializar `pip-audit` **via `uv`** (D1/D5): `uv add --dev pip-audit==2.10.1` e `uv sync` (sem `--locked` em 008) — acrescenta `pip-audit==2.10.1` em `[dependency-groups] dev` com `ruff`/`mypy`/`pytest` coexistindo e gera `uv.lock` com `pip-audit 2.10.1` + `cyclonedx-python-lib`/`cachecontrol`/`packaging`/`requests`/`rich` com hash; fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub TOML válido com `[[package]] name="pip-audit"` (FR-001/003/005, contracts/pip-audit-contract.md §2)
- [x] T019 [US1] Validar `uv run pip-audit --version` 2.10.1 e `pip-audit --help` lista `cyclonedx-json`/`cyclonedx-xml` e `--fix` (`pip-audit --help | grep -q cyclonedx-json`) (FR-003, D1/D5, quickstart Cenário 3)
- [x] T020 [US1] Validar `uv run pip-audit --dry-run` coleta `would have audited` sem falhar e `uv run pip-audit` 0 com `No known vulnerabilities found` para 41 pacotes (FR-007, D2, quickstart Cenário 1/2)
- [x] T021 [US1] Validar `uv run pip-audit -f json` 0 com `json` válido `dependencies[].vulns[]` e `uv run pip-audit -f cyclonedx-json -o /tmp/sbom.json` com `bomFormat CycloneDX` válido mesmo sem vulns (FR-008, D4, quickstart Cenário 2)

**Checkpoint**: MVP entregue — `uv run pip-audit` passa sem `requirements.txt`; `uv.lock` contém `pip-audit==2.10.1`.

---

## Phase 5: User Story 2 — Trivy fs e compatibilidade ruff/mypy/pytest (Priority: P2)

**Goal**: `Trivy 0.74.0` `fs` para `HIGH,CRITICAL`/`secret`/`config` sem quebrar `ruff`/`mypy`/`pytest` (SC-002, FR-004/009).

**Independent Test**: `quickstart.md` Cenário 2: `trivy fs --severity HIGH,CRITICAL --format json .` lista `Results[].Vulnerabilities` quando provocado com `Dockerfile` vulnerável, mas não em repo limpo; `pip-audit` e `ruff S` coexistem.

- [x] T022 [US2] Validar `Trivy 0.74.0` pin documentado: `! grep -q "trivy" pyproject.toml` (não em `dev`) e `grep -q "0.69.4" pyproject.toml` reprova (FR-004, D3); quando Docker disponível, `docker run --rm aquasec/trivy:0.74.0 --version` → `0.74.0`, caso contrário `⏭️` skip validado via `docker info` falha (FR-009, D3)
- [x] T023 [US2] Validar `Trivy fs` skip: `trivy fs --severity HIGH,CRITICAL --format json .` ou `docker run aquasec/trivy:0.74.0 fs ...` 0 com `Results` vazio em repo limpo quando Docker presente, `⏭️` skip quando `docker info` falha; não exige `lefthook.yml`/`gitleaks` (FR-009, D3)
- [x] T024 [P] [US2] Validar compatibilidade quádrupla: `uv run ruff check .` 0 + `uv run mypy --strict .` 0 + `uv run pytest -q` 13 passed + `uv run pip-audit` 0 — todos green simultâneos sem conflito `exclude`/`cache` (FR-007, D6, quickstart Cenário 2)

---

## Phase 6: User Story 3 — Fronteira, cache, README e commit inquebráveis (Priority: P3)

**Goal**: `lefthook.yml`/`gitleaks.toml`/`packages`/`docker-compose.yml`/`requirements.txt` ausentes + `pip-audit` cache fora do repo + `specs/README.md` `008 ✅` + `git ls-files` 0 + `tasks.md` zero `[ ]` (SC-005/007/008, FR-002/006/013/014/015).

**Independent Test**: `quickstart.md` Cenário 5 + 6: `! test -f lefthook.yml` + `! test -f gitleaks.toml` + `! test -d packages` + `! test -f docker-compose.yml` + `! test -f requirements.txt` + `! git ls-files | grep pip-audit` + `grep -E "^- \[ \]" tasks.md` → 0 + `grep -iq "008.*pip-audit.*✅" specs/README.md` + `git ls-files --error-unmatch`.

- [x] T025 [US3] Validar `pip-audit.toml` ausente: `! test -f pip-audit.toml && ! test -f .pip-audit.toml` (sem config separada) e `! test -f requirements.txt` + `! test -f pylock.toml` (fonte única `uv.lock`) (FR-002, D2)
- [x] T026 [US3] Validar `pip-audit`/`Trivy` cache fora do repo: `uv run pip-audit` cria cache em `~/.cache/pip`, `! git ls-files | grep -q pip-audit` (cache não rastreado), `git check-ignore -q uv.lock` negativo (uv.lock não ignorado) (FR-006, D8)
- [x] T027 [US3] Validar `Trivy` não em `dev`: `! grep -q "trivy" pyproject.toml` e `! grep -q 'name = "trivy"' uv.lock` (Go/Docker, não Python) e `! grep -q "0.69.4"` (FR-004/016, D3)
- [x] T028 [US3] Validar `specs/README.md` `008 ✅`: `grep -iq "008.*pip-audit.*✅" specs/README.md` (inquebrável, D8) — `README` desatualizado (`⏳`) reprova FR-014
- [x] T029 [US3] Validar `git ls-files` `spec 008` rastreado: `git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md` 0 e `git ls-files --error-unmatch docs/plan/research/f0-008-pip-audit-trivy.md` 0 (inquebrável, `??` reprova FR-015)
- [x] T030 [US3] Validar fronteira: `! test -f lefthook.yml && ! test -f gitleaks.toml && ! test -d packages && ! test -f docker-compose.yml && ! test -f cyclonedx.json && ! grep -q "0.69.4" pyproject.toml` (FR-013/016, D10, Escada)

---

## Phase 7: Polish & Convergência 🟢

**Purpose**: fechar ciclo vermelho→verde, provar determinismo, atualizar harness e versionar evidências.

- [x] T031 🟢 Executar `scripts/verify/f0-008-pip-audit.sh` e `scripts/verify/f0-008-pip-audit.sh --quiet` e preservar saída íntegra em `specs/008-pip-audit-trivy/evidence/green.txt`. Esperado `exit=0` com 12–16/12–16 aprovadas (SC-004, plan.md Fase D:1)
- [x] T032 🟢 Executar `uv run pip-audit` e `uv run pip-audit -f json`/`cyclonedx-json` e preservar saída em `specs/008-pip-audit-trivy/evidence/pip_audit_green.txt` (ou stdout). Esperado 0 em repo conforme (FR-007/008, SC-001)
- [x] T033 Executar `quickstart.md` validação determinismo: `scripts/verify/f0-008-pip-audit.sh > /tmp/r1.txt 2>&1` vs `/tmp/r2.txt` `diff` idêntico + `uv run pip-audit > /tmp/m1.txt` vs `/tmp/m2.txt` `diff` idêntico (quando sem vulns, saída idêntica) + `EPOCHSECONDS <5s` (FR-010, SC-004, plan.md Fase D:3)
- [x] T034 Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` e `uv run pip-audit` 0 e `uv run ruff check .` 0 e `uv run mypy --strict .` 0 e `uv run pytest -q` 13 passed (quádruplo) — todos green simultâneos (FR-011, SC-006, plan.md Fase D:4)
- [x] T035 Gerar `scripts/verify/manifest.sha256` 8 linhas: `sha256sum scripts/verify/f0-001-foundation.sh scripts/verify/f0-002-constitution.sh scripts/verify/f0-003-ci-minimo.sh scripts/verify/f0-004-uv-workspace.sh scripts/verify/f0-005-pytest.sh scripts/verify/f0-006-ruff.sh scripts/verify/f0-007-mypy.sh scripts/verify/f0-008-pip-audit.sh > scripts/verify/manifest.sha256` e validar `sha256sum -c scripts/verify/manifest.sha256` exit 0 (FR-003, D8, plan.md Fase C:4)
- [x] T036 Atualizar `scripts/verify/README.md` tabela — nova linha `f0-008-pip-audit.sh | 12–16 | pip-audit 2.10.1 + Trivy 0.74.0 — auditoria (FR-001..016, 008)` — conforme `plan.md` Fase C:5 e ADR-002 crescimento
- [x] T037 Atualizar `specs/README.md` índice — `008 | 0.12 | pip-audit + Trivy | ✅` (FR-014, inquebrável) — conforme `plan.md` Fase C:5 e ADR-011
- [x] T038 Executar `quickstart.md` validação completa em um comando (Cenário 1–6): `uv run pip-audit --version | grep -q "2.10.1" && uv run pip-audit --dry-run 2>&1 | grep -q "would have audited" && sha256sum -c scripts/verify/manifest.sha256 && for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && ! test -f lefthook.yml && grep -iq "008.*pip-audit.*✅" specs/README.md && git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md >/dev/null 2>&1 && git ls-files --error-unmatch docs/plan/research/f0-008-pip-audit-trivy.md >/dev/null 2>&1 && echo "quickstart OK"` → todos `OK` = `contracts/pip-audit-contract.md` satisfeito (SC-001..008)
- [x] T039 Registrar ciclo em commits separados vermelho→verde obedecendo `CONTRIBUTING.md` §1 (`^(feat|fix|docs|chore|refactor)(\(.+\))?: .+`): commit 🔴 com oracle + `red.txt`, commit 🟢 com `pyproject.toml`+`uv.lock`+`Trivy pin doc`+`specs/README.md`+`manifest.sha256`+`README.md`+`green.txt`/`pip_audit_green.txt` — par auditável (Princípio III, plan.md Fase D:6)
- [x] T040 [P] Anotar em `specs/008-pip-audit-trivy/quickstart.md` ou `plan.md` Fase E que Cenário remoto (`push` conforme verde + `PR` com `gitleaks` falso-positivo vermelho, SC-005) só é observável após `push`/`PR` real em `main`/`develop` e fica deferido pós-merge (não bloqueia convergência local, plan.md Fase E)

---

## Dependencies

### Ordem de fases (estrita)

```
Phase 1 (T001–T003)              Setup
   ↓
Phase 2 (T004)                   Foundational — esqueleto oracle (BLOQUEANTE)
   ↓
Phase 3 (T005–T017)              Oracle completo + 🔴 vermelho preservado
   ↓
Phase 4 (T018–T021)              US1 — pip-audit verde (MVP) 🟢
   ↓
Phase 5 (T022–T024)              US2 — Trivy fs e compatibilidade
   ↓
Phase 6 (T025–T030)              US3 — fronteira/cache/README/commit/CONVERGE
   ↓
Phase 7 (T031–T040)              Polish & Convergência (verde + determinismo + harness acumulado)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T004 | T001, T002 | harness íntegro + alvo inexistente são pré-condição do contrato |
| T005–T016 | T004 | asserções exigem esqueleto `oracle-cli` (exit/flags/CANON/EPOCHSECONDS) |
| T017 | T005–T016 | vermelho só é prova se oráculo cobrir FR-001..016 |
| T018 | **T017** | `uv add --dev` antes do vermelho falha SC-004 de forma irrecuperável |
| T019–T021 | T018 | `pip-audit` + `uv.lock` + `pip-audit --dry-run` só fazem sentido com `pip-audit` em `dev` |
| T022–T024 | T019 | `Trivy` pin + `fs` exigem `pip-audit` verde |
| T025–T030 | T022 | fronteira/cache/README/commit/CONVERGE exigem `pip-audit` verde |
| T031 | T018–T030 | verde só é verde após última mutação (`pyproject.toml` + `uv.lock` + `manifest` + `README` + `specs/README.md` + `git ls-files`) |
| T035 | T031 | `manifest.sha256` 8 linhas só após `f0-008` existir |
| T039 | T031 | commits só após verde |

### Oportunidades reais de paralelismo

**Três oportunidades reais**, cobrindo 2 tarefas, verificadas quanto a colisão de arquivo:

- **T024** — quádrupla `ruff`+`mypy`+`pytest`+`pip-audit` somente leitura, paralelizável com `T022`/`T023` (Trivy).
- **T040** — anotação deferida remota, não toca `pyproject.toml` nem oracle após verde.

As demais **não** são paralelizáveis: T005–T016 editam o mesmo `f0-008-pip-audit.sh`, T018–T021 tocam `pyproject.toml`/`uv.lock` sequencialmente, T017/T031/T032 escrevem `evidence/` ordenadamente. Marcá-las `[P]` criaria colisão real.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T021). Entrega **pip-audit verde** — `uv run pip-audit` passa sem vulns; `uv.lock` contém `pip-audit==2.10.1` com `cyclonedx-python-lib`. Sem ele, `lefthook` (009) orquestraria `pip-audit` sem lock, e `010` (`uv sync --frozen` + `pip-audit` em CI) não teria `uv.lock`.

### Entrega incremental

1. Phases 1–2 → pré-requisitos + esqueleto (remoção segura futura)
2. Phase 3 → 🔴 vermelho preservado (prova de test-first garantida)
3. Phase 4 → **pip-audit verde** — `pip-audit 2.10.1` existe (MVP)
4. Phase 5 → `Trivy 0.74.0` pin + `fs` `HIGH,CRITICAL` `⏭️` skip — Trivy documentado sem quebrar harness sem Docker
5. Phase 6 → `pip-audit.toml` ausente + cache fora do repo + `Trivy` não em `dev` + `README` `008 ✅` + `git ls-files` — fronteira + inquebráveis fechados
6. Phase 7 → 🟢 verde, `pip-audit` verdes, determinismo, harness acumulado, commits auditáveis

### Critério de conclusão do item

| Condição | Verificação | SC |
|---|---|---|
| `pip-audit==2.10.1` em `[dependency-groups] dev` | T018 + T005 | SC-001 |
| `uv.lock` com `pip-audit 2.10.1` | T018 + T009 | SC-001 |
| `uv run pip-audit` 0 sem vulns | T020 | SC-001 |
| `pip-audit --version` 2.10.1 `cyclonedx-json` | T019 | SC-003 |
| `f0-008` 12–16 `exit 0` `<5s` `2× cmp` | T031 | SC-004 |
| `lefthook.yml`/`gitleaks.toml` reprova `FR-013` | T030 | SC-005 |
| `for f` + `pip-audit` + `ruff` + `mypy` + `pytest` 0 | T034 | SC-006 |
| `tasks.md` zero `[ ]` | T016 + T031 | SC-007 |
| `specs/README.md` `008 ✅` | T028 | SC-007 inquebrável |
| `git ls-files` `spec 008` rastreado | T029 | SC-007 inquebrável |
| `Trivy` pin 0.74.0 documentado, não em `dev` | T022 + T027 | SC-008 |
| Sem `lefthook`/`packages`/`docker-compose` | T030 | SC-008 |
| 12–16/12–16 `exit 0` + `pip-audit` 0 | T031 | FR-010 |
| Harness acumulado `for f` 0 | T034 | FR-011 |
| Commits vermelho→verde separados | T039 | Princípio III |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **2** das 40 tarefas, deliberadamente — este item edita `f0-008-pip-audit.sh` e `pyproject.toml` muitas vezes sequencialmente.
- Cada tarefa cita o FR/SC que a origina, para que qualquer linha do oráculo seja rastreável até `spec.md` sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits **separados**: é a prova auditável de que o teste veio primeiro, e ela não é recuperável depois (plan.md Fase B).
- T040 é deferido remoto — não bloqueia `T031` verde local, mas SC-005 remoto só fecha após observação em GitHub (plan.md Fase E).
- Nenhuma tarefa introduz `lefthook`/`gitleaks`/`trivy` binary — violaria FR-013 e Escada (constitution Additional Constraints).
