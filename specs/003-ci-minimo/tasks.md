---
description: "Task list for 003 — CI mínimo — harness da Fase 0 em runner limpo"
---

# Tasks: CI mínimo — harness da Fase 0 em runner limpo

**Input**: Design documents from `/specs/003-ci-minimo/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md` (D1–D10), `data-model.md` (6 entidades), `contracts/ci-workflow.md` (10 checks), `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-005 plan.md Fase B/C). A prova é o oráculo `scripts/verify/f0-003-ci-minimo.sh` executado e preservado **antes** da implementação (🔴) e **depois** (🟢) — não recuperável depois.

**Artefatos deste item**: um arquivo produtivo (`.github/workflows/ci.yml`), um oráculo (`scripts/verify/f0-003-ci-minimo.sh`), uma linha em `scripts/verify/README.md`, diretório `specs/003-ci-minimo/evidence/`. Nenhum `src/`, nenhuma dependência nova além de shell/git/Python 3.12 stdlib.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. Este item **não produz código de aplicação** — produz infra de CI (`.github/workflows/`) e a terceira peça do harness (`scripts/verify/`).

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena por prioridade P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa:

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 (P1) primeiro | **Oracle completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo os 14 FRs antes de qualquer `ci.yml`. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (Princípio III, SC-005) |
| Workflow por história | **Workflow único após vermelho** | `.github/workflows/ci.yml` é um arquivo só — dividi-lo por história criaria colisão de escrita e reescrita de `010`. A criação é aditiva e única (FR-013) |
| US2/US3 após US1 | **US2/US3 verificação após workflow** | Depois do workflow verde, US2/US3 não mutam arquivo; apenas inspeção estática adicional (pins, fronteira) — independência lógica preservada sem colisão |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T015 (vermelho) antes de T016** — criar `ci.yml` antes de registrar o vermelho satisfaz todos os FR e ainda assim falha `SC-005`/Princípio III de forma irrecuperável (plan.md Fase B › *"Pular esta fase satisfaz os FR e ainda assim falha"*).
2. **T004 antes de T005–T014** — esqueleto do contrato `oracle-cli.md` (exit 0/1/2, --quiet/--list, determinismo, somente leitura) é pré-requisito de qualquer asserção nos grupos.
3. **T026 (verde) após T016–T018** — o verde só é verde depois da última mutação (workflow + README). Verde antes disso mede estado incompleto.

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo em reprovação 🔴 | Phase 2 + Phase 3 | T004–T015 | US1+US2+US3 (oracle) |
| Fase C — Workflow verde 🟢 | Phase 4 | T016–T019 | US1 (MVP) |
| Fase D — Verde e convergência local | Phase 5 + Phase 6 + Phase 7 | T020–T029 | US2, US3, Polish |
| Fase E — Entrega remota (pós-merge) | Phase 7 (T030) | T030 | — (SC-002 remoto) |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness que o workflow vai orquestrar está verde e que o diretório-alvo ainda não existe; preparar evidências.

- [ ] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` — deve sair `0` com `f0-001` (30/30) e `f0-002` (33/33). Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [ ] T002 Confirmar ausência de `.github/` (`ls .github` deve falhar, Q1) e que `docs/plan/research/f0-003-ci-minimo.md` (288 linhas, Q1–Q10 D1–D10) e `specs/003-ci-minimo/research.md` (140 linhas) existem — registra fronteira FR-002
- [ ] T003 Criar diretório de evidências `specs/003-ci-minimo/evidence/` (`mkdir -p specs/003-ci-minimo/evidence`) para `red.txt` e `green.txt` (Princípio III, plan.md Fase B:3 / Fase D:1)

**Checkpoint**: pré-requisitos satisfeitos — oráculo anterior íntegro, alvo inexistente, evidências endereçáveis.

---

## Phase 2: Foundational (Esqueleto do oráculo) ⚠️ BLOQUEANTE

**Purpose**: criar o invólucro que todo FR vai usar. **Nenhuma asserção de Phase 3 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: este esqueleto implementa o contrato `specs/001-git-branching-strategy/contracts/oracle-cli.md` herdado via `specs/003-ci-minimo/contracts/ci-workflow.md` §10 e `scripts/verify/README.md`. Sem ele, `--list`/`--quiet`/códigos não são decidíveis.

- [ ] T004 [US1+US2+US3] Criar `scripts/verify/f0-003-ci-minimo.sh` com esqueleto do contrato herdado: parsing de `--quiet` e `--list`, resolução da raiz pela localização do script (`SCRIPT_DIR`/`REPO_ROOT`, nunca `$PWD`), códigos `0` conforme / `1` não conforme / `2` erro de uso, formato `<emoji> FR-XXX <descrição>` uma linha por REQ-ID, linha de resultado final `X/Y passed`, mapa canônico único de descrições, guarda de recursão `FKX_ORACLE_NESTED`, sem efeitos além de stdout/stderr (FR-020a/b/c, FR-018, contrato oracle-cli §1–§3, data-model.md Entidade Harness)

**Checkpoint**: foundation ready — asserções de história podem ser acrescentadas sem recriar contrato.

---

## Phase 3: Oracle completo — 14 asserções + vermelho 🔴 (US1+US2+US3)

**Goal**: oráculo que responda por código de saída cobrindo **todos** os FR-001..014 antes de existir qualquer coisa para aprovar. É a única prova auditável de test-first.

**Independent Test**: executar em estado com `.github/workflows/ci.yml` inexistente → `exit 1` com reprovação nominal por FR; executar duas vezes → saída idêntica; `--list` enumera 14 IDs sem executar.

### Implementation por grupo (mesmo arquivo, sequencial — não paralelizável)

- [ ] T005 [US1] Implementar em `scripts/verify/f0-003-ci-minimo.sh` **Grupo FR-001/002** — existência e localização: `test -f .github/workflows/ci.yml`, diretório `.github/workflows/` existe, chaves top-level `name`/`on`/`permissions`/`jobs` presentes via `grep`/`python3` fallback (FR-001/002, SC-001, data-model Workflow)
- [ ] T006 [US1] Implementar **Grupo FR-008** — gatilhos: `on.push.branches == [main, develop]` e `on.pull_request.branches == [main, develop]`, ausência de `merge_group`/`tags`, verifica que `on: [push]` sem filtro reprova (FR-008, D7, data-model Trigger)
- [ ] T007 [US1] Implementar **Grupo FR-009/010** — job e Run harness: `jobs.verify` existe (FR-009), steps nomeados `Checkout`/`Setup Python 3.12`/`Run harness` nesta ordem, `Run harness` contém `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` (glob, sem lista hardcoded) (FR-009/010, D8/D10)
- [ ] T008 [US1] Implementar **Grupo FR-011** — propagação de falha: ausência de `continue-on-error: true` em qualquer step, verifica que `exit 1` não é mascarado (FR-011, D10, SC-006)
- [ ] T009 [US2] Implementar **Grupo FR-003/004/005** — pins determinísticos: `runs-on: ubuntu-24.04` (não `ubuntu-latest`) (FR-003/D2), `uses: actions/checkout@v7` + `with: fetch-depth: 0` (FR-004/D3/D5), `uses: actions/setup-python@v7` + `with: python-version: '3.12'` (FR-005/D4/D9), referência a versões verificadas `7.0.1`/`7.0.0` node24 em comentário (Q3/Q4)
- [ ] T010 [US2] Implementar **Grupo FR-012** — ausência de não-determinismo: grep negativo para `\$RANDOM`, `date` em lógica, `GITHUB_RUN_NUMBER` (FR-012, SC-007, data-model validação cruzada)
- [ ] T011 [US3] Implementar **Grupo FR-006** — fronteira: grep negativo global para `ruff|mypy|pytest|pip-audit|trivy|gitleaks|uv |matrix:|cache:|pull_request_target|workflow_run` ; qualquer ocorrência reprova (FR-006, D5/D8, SC-004, contracts §6, C1)
- [ ] T012 [US3] Implementar **Grupo FR-007** — privilégio mínimo: `permissions: contents: read` top-level presente, ausência de `write` e `id-token: write` (FR-007, D6, SC-008, data-model Workflow.permissions)
- [ ] T013 [US3] Implementar **Grupo FR-013/014** — escalabilidade e rastreabilidade: id `verify` estável (não `ci`/`build`) (FR-013/D8), seção `## Contratos` em `specs/003-ci-minimo/spec.md` declara entregas a `010`/`013`/`014` (FR-014, spec Contratos)
- [ ] T014 [US3] Implementar **Grupo meta** — integridade do harness herdado: `f0-001-foundation.sh --quiet` e `f0-002-constitution.sh --quiet` aprovam quando invocados pelo oráculo (não regressão, princípio VI, SC-006) + `FR-018` determinismo interno (duas execuções idênticas)

### Captura do vermelho (não recuperável)

- [ ] T015 🔴 **Executar** `scripts/verify/f0-003-ci-minimo.sh` e `scripts/verify/f0-003-ci-minimo.sh --quiet` e preservar saída íntegra em `specs/003-ci-minimo/evidence/red.txt`. Esperado `exit=1` com reprovação em massa (FR-001/002 base — workflow inexistente) e `FR-011` por ausência. Conferir `--list` enumera 14 IDs sem executar (FR-020b). Este `red.txt` é a prova de TDD — se não existir antes de T016, o par vermelho→verde é irrecuperável (Princípio III, SC-005, plan.md Fase B:3)

**Checkpoint**: existe oráculo completo e existe prova registrada de que ele reprova. A partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Veredito remoto idêntico ao local (Priority: P1) 🎯 MVP

**Goal**: runner limpo reproduz exatamente o oráculo local — check verde quando conforme, vermelho com `🔴 FR-...` quando há violação.

**Independent Test**: `push` para `main` conforme → workflow `ci` dispara, job `verify` success listando cada oráculo; `push` com violação injetada (ex.: FR-006b linha malformada ou `.env` rastreado) → check failure `exit 1` com log nomeando REQ-ID (spec US1 acceptance 1–4, SC-002)

- [ ] T016 [US1] Criar `.github/workflows/ci.yml` exatamente conforme `contracts/ci-workflow.md` §2–§5 e `plan.md` Fase C:1 — `name: ci`, `on: push/pull_request branches [main, develop]`, `permissions: contents: read`, `jobs.verify.runs-on: ubuntu-24.04`, steps `Checkout` (`actions/checkout@v7` `fetch-depth: 0`), `Setup Python 3.12` (`actions/setup-python@v7` `python-version: '3.12'`), `Run harness` (`for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done`), sem `continue-on-error` (D1–D10, FR-001..011)
- [ ] T017 [US1] Validar YAML estático: `python3` stdlib inspeção de chaves top-level (`name`/`on`/`permissions`/`jobs`) com fallback `grep` estrutural quando `yaml` não disponível, conforme `quickstart.md` Cenário 1 1b — falha em YAML inválido reprova FR-001
- [ ] T018 [US1] Atualizar `scripts/verify/README.md` tabela — nova linha `f0-003-ci-minimo.sh | 14 | CI mínimo — harness Fase 0 em runner limpo (.github/workflows/ci.yml)` — conforme `plan.md` Fase C:3 e contrato de crescimento do harness (ADR-002, specs/002)
- [ ] T019 [US1] Executar `scripts/verify/f0-003-ci-minimo.sh` grupo US1 e confirmar **FR-001/002/008/009/010/011 verdes** (inspeção `grep` Cenário 1 1e/1f/1g/1h). Se qualquer um ainda reprovar, `ci.yml` não está conforme contrato

**Checkpoint**: MVP entregue — veredito local tem réplica remota; sem este checkpoint, US2/US3 não têm sobre o que verificar determinismo/fronteira.

---

## Phase 5: User Story 2 — Determinismo de ambiente (Priority: P2)

**Goal**: mesmo commit → mesmo veredito em qualquer máquina/runner, sem alias móvel nem versão flutuante.

**Independent Test**: inspeção de `ci.yml` mostra `runs-on` pinado, `uses:` pinados, `python-version` família; `for f in ...` re-run produz saída byte-idêntica (spec US2 acceptance 1–4, SC-003/SC-007)

- [ ] T020 [P] [US2] Verificar pins determinísticos via inspeção estática `quickstart.md` Cenário 1 1c: `grep -q 'runs-on: ubuntu-24.04'` não `ubuntu-latest` (FR-003), `grep -q 'uses: actions/checkout@v7'` + `fetch-depth: 0` (FR-004), `grep -q 'uses: actions/setup-python@v7'` + `grep -q "python-version: '3.12'"` (FR-005) — 100% dos pins conferem com `research.md` tabela `7.0.1`/`7.0.0` (SC-003)
- [ ] T021 [US2] Executar `quickstart.md` Cenário 4 — determinismo: `scripts/verify/f0-003-ci-minimo.sh > /tmp/run1.txt 2>&1` vs `/tmp/run2.txt` diff idêntico (FR-018/FR-012), `grep -Eq '\$RANDOM|date\(\)|GITHUB_RUN_NUMBER'` negativo, re-run harness `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` duas vezes diff idêntico (SC-007, FR-012)
- [ ] T022 [US2] Executar `quickstart.md` Cenário 5 — regressão `fetch-depth`: `grep -q 'fetch-depth: 0'` PASS, demonstrar local `git log --all` vs `git log --max-count=1` que shallow esconderia violação histórica FR-020b (SC-007, FR-004, Q5). Documenta classe E7 de falso-negativo do item 001

---

## Phase 6: User Story 3 — Privilégio mínimo e fronteira preservada (Priority: P3)

**Goal**: `GITHUB_TOKEN` com menor privilégio possível e nenhuma ferramenta de item `010` antecipada.

**Independent Test**: inspeção estática contra lista de proibições; `grep` de `permissions` e de `ruff/mypy/...` (spec US3 acceptance 1–4, SC-004/SC-008)

- [ ] T023 [P] [US3] Verificar privilégio mínimo via `quickstart.md` Cenário 1 1d: `grep -q 'permissions:'` + `grep -q 'contents: read'` PASS, `! grep -q 'id-token: write'` e `! grep -q 'contents: write'` (FR-007, D6, SC-008). Ausência reprova (default indeterminístico entre orgs, Q6)
- [ ] T024 [P] [US3] Verificar fronteira via `quickstart.md` Cenário 1 1i: `! grep -Eq 'ruff|mypy|pytest|pip-audit|trivy|gitleaks|uv |matrix:|cache:|pull_request_target|workflow_run'` em `ci.yml` — 100% fronteira preservada (FR-006, D5/D8, SC-004, contracts §6, C1). Falha aqui violaria escada de dependências e TDD de 005–010
- [ ] T025 [US3] Verificar escalabilidade e rastreabilidade: `grep -q 'verify:'` id estável (FR-013) + `grep -q '## Contratos'` em `spec.md` com linhas para `010`/`013`/`014` (FR-014, spec Contratos). Renomear `verify` reprova (quebraria `required check` futuro)

---

## Phase 7: Polish & Convergência 🟢

**Purpose**: fechar ciclo vermelho→verde, provar determinismo e registrar o que a máquina não decide.

- [ ] T026 🟢 Executar `scripts/verify/f0-003-ci-minimo.sh` e `scripts/verify/f0-003-ci-minimo.sh --quiet` e preservar saída íntegra em `specs/003-ci-minimo/evidence/green.txt`. Esperado `exit=0` com **14/14** aprovadas (SC-001, plan.md Fase D:1)
- [ ] T027 Executar `quickstart.md` Cenário 4 determinismo completo: `diff -u /tmp/run1.txt /tmp/run2.txt` idêntico + `git status` limpo exceto artefatos deste item (`.github/workflows/ci.yml`, `scripts/verify/f0-003-ci-minimo.sh`, `scripts/verify/README.md`, `specs/003-ci-minimo/evidence/`) (FR-018, contracts §8)
- [ ] T028 Executar harness acumulado conforme contrato local e remoto: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0`; cada oráculo abaixo de 5s (FR-018, plan.md Fase D:3, SC-006 agregada)
- [ ] T029 Executar `quickstart.md` validação completa em um comando (Cenário 1 1c–1j + Cenário 2 harness verde) — todos `PASS` = contrato `contracts/ci-workflow.md` §10 (11 checks) satisfeito (SC-001..008)
- [ ] T030 Registrar ciclo em commits separados vermelho→verde obedecendo `CONTRIBUTING.md` §1 (`^(feat|fix|docs|chore|refactor)(\(.+\))?: .+`): commit 🔴 com oracle + `red.txt`, commit 🟢 com `ci.yml` + `README.md` + `green.txt` — par auditável (Princípio III, plan.md Fase D:5)
- [ ] T031 [P] Anotar em `specs/003-ci-minimo/quickstart.md` ou `plan.md` Fase E que **Cenário 6 (SC-002 remoto)** — `push` conforme verde + PR com violação vermelho + re-run idêntico — só é observável após push/PR real em `main`/`develop` e fica deferido pós-merge (não bloqueia convergência local, mas é o único SC que exige GitHub)

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
Phase 4 (T016–T019)              US1 — workflow verde (MVP) 🟢
   ↓
Phase 5 (T020–T022)              US2 — determinismo (verificação estática)
   ↓
Phase 6 (T023–T025)              US3 — fronteira e privilégio (verificação estática)
   ↓
Phase 7 (T026–T031)              Polish & Convergência (verde + determinismo + harness acumulado)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T004 | T001, T002 | harness íntegro + alvo inexistente são pré-condição do contrato |
| T005–T014 | T004 | asserções exigem esqueleto `oracle-cli` (exit/flags/determinismo) |
| T015 | T005–T014 | vermelho só é prova se oráculo cobrir os 14 FRs |
| T016 | **T015** | criar `ci.yml` antes do vermelho falha SC-005 de forma irrecuperável |
| T017–T019 | T016 | inspeção e README só fazem sentido com workflow em disco |
| T020–T025 | T016 | pins/fronteira/permissions são verificados sobre `ci.yml` existente |
| T026 | T016–T018 | verde só é verde após última mutação (workflow + README) |
| T030 | T026 | commits só após verde medido |

### Oportunidades reais de paralelismo

**Três oportunidades reais**, cobrindo 5 tarefas, verificadas quanto a colisão de arquivo:

- **T020, T023, T024** — inspeções `grep` somente leitura sobre `ci.yml`, arquivos distintos de saída (`/tmp/*`) — paralelizáveis entre si (`[P]`).
- **T027 e T028** — leitura/determinismo + harness acumulado (`--quiet`) — sem escrita colidente, paralelizáveis (`[P]` em 028 implícito via leitura).
- **T031** — anotação deferida de Cenário 6, não toca `ci.yml` nem oracle após verde.

As demais tarefas **não** são paralelizáveis: T005–T014 editam o mesmo `f0-003-ci-minimo.sh`, T016–T018 tocam `ci.yml`/`README.md` sequencialmente, T015/T026 escrevem `evidence/` ordenadamente. Marcá-las `[P]` criaria colisão real.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T019). Entrega **veredito remoto idêntico ao local** — o portão remoto mínimo. Sem ele, dez itens são construídos sem rede; a primeira execução do pipeline validaria dez itens de uma vez (spec Contexto). US2/US3 agregam confiança mas o MVP já orquestra o harness.

### Entrega incremental

1. Phases 1–2 → pré-requisitos + esqueleto (remoção segura futura)
2. Phase 3 → 🔴 vermelho preservado (prova de test-first garantida)
3. Phase 4 → **workflow verde** — portão remoto existe (MVP)
4. Phases 5–6 → determinismo e fronteira verificados — CI é oráculo, não loteria
5. Phase 7 → 🟢 verde, determinismo, harness acumulado, commits auditáveis

### Critério de conclusão do item

| Condição | Verificação | SC |
|---|---|---|
| `ci.yml` existe, YAML válido, chaves top-level + `verify` | T017 + T019 | SC-001 |
| `push` conforme verde / PR violação vermelho (remoto) | T031 (pós-merge, observado) | SC-002 |
| `checkout@v7` + `fetch-depth:0` e `setup-python@v7` + `python 3.12` | T020 | SC-003 |
| Nenhuma ferramenta de 010 em `ci.yml` | T024 | SC-004 |
| Triggers exatamente `push`/`pull_request` `[main,develop]` | T006/T019 (FR-008) | SC-005 |
| `Run harness` glob `|| exit 1` sem `continue-on-error`, id `verify` estável | T019 | SC-006 |
| Re-run idêntico + `fetch-depth:0` detecta histórico que shallow esconderia | T021/T022 | SC-007 |
| `permissions: contents: read` sem `write`/`id-token: write` | T023 | SC-008 |
| 14/14 asserções `exit 0`, par vermelho→verde distinto | T015 + T026 | FR-022 análogo |
| Harness acumulado <5s por oráculo, `git status` limpo | T027/T028 | FR-018 |
| Commits separados vermelho→verde em Conventional Commits | T030 | Princípio III |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **5** das 31 tarefas, deliberadamente — este item edita `f0-003-ci-minimo.sh` e `ci.yml` muitas vezes sequencialmente.
- Cada tarefa cita o FR/SC que a origina, para que qualquer linha do oráculo seja rastreável até `spec.md` sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits **separados**: é a prova auditável de que o teste veio primeiro, e ela não é recuperável depois (plan.md Fase B › *"A única prova auditável"*).
- T031 é deferido remoto — não bloqueia `T026` verde local, mas SC-002 só fecha após observação em GitHub (plan.md Fase E).
- Nenhuma tarefa introduz `ruff`/`mypy`/`pytest`/`pip-audit`/`trivy`/`gitleaks`/`uv`/`matrix`/`cache` — violaria FR-006 e escada de dependências (constitution Additional Constraints).

