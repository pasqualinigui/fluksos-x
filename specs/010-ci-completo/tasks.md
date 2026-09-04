---
description: "Task list for 010 — CI completo + branch protection — portão servidor"
---

# Tasks: CI completo + branch protection — portão servidor

**Input**: Design documents from `/specs/010-ci-completo/`
**Prerequisites**: `plan.md` (required), `spec.md` (required, US1 P1/US2 P2/US3 P3), `research.md` (5 decisões), `data-model.md` (5 entidades), `contracts/oracle-cli.md` (mapa identidade FR-001..013), `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-005, FR-013). A prova é `f0-010-ci-completo.sh` 13 asserções reprovando (🔴) e aprovando (🟢) em **commits separados** — exceção M3 não se estende. O oráculo é o teste. Lado servidor (proteção) é cenário humano 🧑 com checklist (precedente 003-T031) — o oráculo nunca usa token (Lei Zero).

**Artefatos deste item**: `.github/workflows/ci.yml` estendido (8 jobs, SHA pins, matriz, quarentena), `commitlint.config.js` (11 tipos), `pyproject.toml` (`pytest-cov==7.1.0` dev), `uv.lock` com hash, procedimento de proteção 🧑 versionado, `scripts/verify/f0-010-ci-completo.sh` (13 asserções), `scripts/verify/manifest.sha256` 10 linhas, `specs/README.md` índice `010 ✅` + hash, `specs/010-ci-completo/evidence/` (`red.txt`, `green.txt`). Job `verify` jamais renomeado (fronteira 003). Nenhum `packages/`/release/renovate/token/runner.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. Oráculo em `scripts/verify/f0-010-ci-completo.sh` segue ADR-002/015. Spec dir `specs/010-ci-completo/` segue Spec-Kit. Dono designado de `.github/` (Emenda 1).

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `007`/`008`/`009`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oráculo completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..013 antes do workflow existir estendido. Sem cobertura total, o vermelho seria parcial e o verde não prova TDD (III, SC-005, FR-013) |
| Jobs por história | **Fase C materializa workflow + cov + commitlint juntos** | partilham `ci.yml`/`pyproject.toml`/`uv.lock` indivisíveis; commitlint e cobertura entram no mesmo movimento verde |
| US2/US3 após US1 | **US2/US3 verificação após verde** | Depois do verde, US2/US3 não mutam além de verificação (cobertura simulada, commitlint no histórico, procedimento 🧑) |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T013 (vermelho) antes de T014** — estender `ci.yml` antes do vermelho satisfaz FRs e ainda assim falha SC-005/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T012** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON 13 FRs, FKX_ORACLE_NESTED, determinismo 2×) é pré-requisito de qualquer asserção.
3. **T020 (verde) após T014–T019** — verde só é verde depois da última mutação (`ci.yml` + cov + commitlint + procedimento + manifest). Renomear job `verify` em qualquer fase exige ADR prévia (fronteira 003).

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T013 | US1+US2+US3 (oracle) |
| Fase C — CI verde 🟢 | Phase 4 + Phase 5 | T014–T020 | US1 (MVP) + US2/US3 |
| Fase D — Verde e convergência | Phase 6 | T021–T025 | Polish/CONVERGE |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (009) está verde e que os artefatos-alvo ainda não existem estendidos; preparar evidências.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` 9/9 + `sha256sum -c scripts/verify/manifest.sha256` 9/9 SUCESSO. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar fronteira: `ci.yml` com 1 job `verify` (sem 8 jobs, sem SHA pins, sem matriz, sem `timeout-minutes`), ausência de `commitlint.config.js`, ausência de `scripts/verify/f0-010-ci-completo.sh` — e REGISTRAR que `pytest-cov==7.1.0` já está em dev desde 005 (este item adiciona o portão `--fail-under`, não a dependência) — registra fronteira FR-001..007/010 (plan.md Fase A)
- [x] T003 Criar `specs/010-ci-completo/evidence/` para `red.txt`/`green.txt` (Princípio III, plan.md Fase A:3)

---

## Phase 2: Foundational — esqueleto do oráculo (blocking)

**Purpose**: contrato de interface executável antes de qualquer asserção (T004 bloqueia T005–T012).

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-010-ci-completo.sh` com esqueleto do contrato herdado: parsing `--quiet`/`--list`, raiz pela localização do script (nunca `$PWD`), códigos 0/1/2, formato `<emoji> FR-XXX <descrição>`, linha de resultado final, mapa CANON com as 13 descrições FR-001..013 de `contracts/oracle-cli.md` §3, guarda `FKX_ORACLE_NESTED`, cabeçalho comentando FRs guardas (FR-001/FR-011) × comportamento (FR-002..010/012/013), sem efeitos além de stdout/stderr, **sem tokens, sem rede autenticada** (FR-011, contrato §1, Lei Zero)
- [x] T005 Acrescer 10ª linha ao `scripts/verify/manifest.sha256` (hash do esqueleto — será regenerada no verde; acréscimo permitido por ADR-015a, nunca reescrita de valor alheio)
- [x] T006 [P] Implementar asserts auto-verificáveis do oráculo em `scripts/verify/f0-010-ci-completo.sh`: `--list` enumera 13 IDs do CANON, `--invalido` sai 2, 2 execuções byte-idênticas e cada uma <5s (FR-011/SC-006, contrato §1)

**Checkpoint**: esqueleto executável — `f0-010 --list` lista 13 FRs; asserções ainda ausentes.

---

## Phase 3: User Stories US1+US2+US3 — asserções do oráculo 🔴 (Priority: todas)

**Goal**: cobertura total FR-001..013 reprovando sobre workflow mínimo (003).

**Independent Test**: `scripts/verify/f0-010-ci-completo.sh` → 11 vermelhas de comportamento + 2 guardas verdes; `evidence/red.txt` preserva a saída.

- [x] T007 [US1] Implementar em `scripts/verify/f0-010-ci-completo.sh` **Grupo FR-001/002** — job `verify` presente e NÃO renomeado + todo `uses:` por SHA + comentário de versão + runner `ubuntu-24.04` (FR-001/002, research D4)
- [x] T008 [US1] Implementar **Grupo FR-003/004** — `setup-uv` oficial + `uv sync --frozen` + cache; matriz exatamente `["3.12","3.13"]` + `fail-fast: false` (FR-003/004, research D3/D5)
- [x] T009 [US1+US2+US3] Implementar **Grupo FR-005** — 8 jobs nominais únicos (harness, lint, types, tests, audit, secrets, coverage, commitlint); unicidade de nomes entre workflows (FR-005, decisão CLARIFY)
- [x] T010 [US2+US3] Implementar **Grupo FR-006/007** — `pytest-cov` em dev + `--fail-under=90` + `commitlint.config.js` com os 11 tipos (FR-006/007, research D6/D7)
- [x] T011 [US1] Implementar **Grupo FR-008/009/010** — procedimento de proteção versionado (checks + sem-bypass, sem reviews) + modo frouxo documentado + `timeout-minutes` por job + ausência de `continue-on-error`/retry + **ausência de token em arquivo algum** (FR-008/009/010, Lei Zero)
- [x] T012 Implementar **Grupo FR-012/013** — `sha256sum -c` 10/10 + self-check `f0-001…f0-009 --quiet` + README `010 ✅`+hash + tasks zero + vermelho-antes-do-verde no log (FR-012/013)
- [x] T013 **VERMELHO** — executar `scripts/verify/f0-010-ci-completo.sh`, preservar saída em `specs/010-ci-completo/evidence/red.txt` (+ `--quiet`), confirmar 11 vermelhas de comportamento + 2 guardas verdes (FR-001/FR-011), e commitar `test(harness)` **separado**: `test(harness): registra o portao vermelho do item 010 — CI completo` (plan.md Fase B; restrição 1 acima)

**Checkpoint**: vermelho preservado em commit próprio — qualquer mutação de `ci.yml`/dev sem verde subsequente é defeito irrecuperável.

---

## Phase 4: User Story 1 — Bypass morre no servidor (Priority: P1) 🎯 MVP

**Goal**: workflow completo executa localmente (via `act`? NÃO — via inspeção + jobs espelhados localmente); checks definidos para o servidor.

**Independent Test**: `f0-010` fora das FRs de convergência (FR-012/013 excluídas) + cada job espelhado via comando local equivalente (quickstart Cenários 1–2).

- [x] T014 [US1] Confirmar `pytest-cov==7.1.0` em dev com hash em `uv.lock` (presente desde 005 — verificar pin exato, sem re-adicionar) + `uv sync`; confirmar `uv run pytest --cov --cov-fail-under=90 -q` → 0 (FR-006; medido 95%)
- [x] T015 [US1] Estender `.github/workflows/ci.yml`: 8 jobs (nomes únicos/estáveis, `verify` preservado), SHA pins + comentário (`checkout v7.0.1`, `setup-python v7.0.0`, `setup-uv v10.0.1` SHA `20cfd1bf…`, `gitleaks-action v3.0.0` SHA `e0c47f4f…`, `trivy-action v0.36.0` `aquasecurity/`), job `secrets` via `gitleaks/gitleaks-action` modo `detect`, `setup-uv v10.0.1` + `uv sync --frozen`, matriz + `fail-fast: false`, `timeout-minutes`, sem `continue-on-error` (FR-001..005/010)
- [x] T016 [US1] Escrever `commitlint.config.js` (11 tipos) + intervalo por evento (`--from ${{ github.event.pull_request.base.sha || github.event.before }} --to ${{ github.event.pull_request.head.sha || github.sha }}`, com `fetch-depth: 0`) + validar 100% do histórico + 3 sintéticas inválidas com regra nomeada (FR-007; quickstart Cenário 3)

**Checkpoint**: US1 funcional (MVP do item; servidor ainda pendente como 🧑).

---

## Phase 5: User Stories 2+3 — cobertura, commitlint, procedimento 🧑 (Priority: P2/P3)

**Goal**: portão de cobertura + gramática + procedimento de proteção versionado.

**Independent Test**: quickstart Cenários 2–4 (simulação de déficit, sintéticas inválidas, checklist 🧑 revisado a seco).

- [x] T017 [US2] Simular déficit (limiar artificial acima do medido) → job falha nomeando; restaurar 90 (FR-006; quickstart Cenário 2)
- [x] T018 [P] [US3] Validar commitlint contra histórico + sintéticas (FR-007; quickstart Cenário 3)
- [x] T019 [US1] Escrever procedimento de branch protection 🧑 versionado em `specs/010-ci-completo/branch-protection.md` (checks frouxos + sem-bypass + sem-force, sem reviews, passos no servidor + evidência a registrar); sem token em arquivo algum (FR-008/009; quickstart Cenário 4)
- [x] T020 **VERDE** — executar `scripts/verify/f0-010-ci-completo.sh` rumo a 13/13 (menos 🧑-proteção se pendente, com divergência declarada), preservar `specs/010-ci-completo/evidence/green.txt`, e commitar `feat(ci)` **separado** do T013: `feat(ci): CI completo + branch protection (010)` (plan.md Fase C/D)

**Checkpoint**: verde em commit próprio, posterior ao vermelho (FR-013 verificará a ordem no log).

---

## Phase 6: Polish & CONVERGE (Final Phase)

**Purpose**: inquebráveis, lista fechada, primeira validação em servidor.

- [ ] T021 `specs/README.md` `010 ✅` + hash do commit T020 (inquebrável FR-013; quickstart Cenário 5)
- [ ] T022 Re-executar harness 10/10 + manifest 10/10 + quickstart "validação completa em um comando" (quickstart Cenários 5–6)
- [ ] T023 Confirmar `tasks.md` zero `^- [ ]` + `git log` com vermelho-antes-do-verde + AGENTS.md rolado (009→010, harness 10/10, próximo 011)
- [ ] T024 [P] Executar cenário 🧑 (proteção no servidor + PR de teste travando + push direto recusado) OU registrar divergência declarada se pendente (SC-005 honesto; fecha resíduo B3 com primeira execução real)
- [ ] T025 [P] Troubleshooting do quickstart (runner sem Docker ⏭️, check ambíguo, histórico inválido) + commit de convergência `docs(specs)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — começa imediato; T001 verde é portão (VI).
- **Foundational+Oracle (Phase 2+3)**: dependem do Setup; T004 bloqueia T005–T012; T013 fecha o vermelho.
- **Green (Phase 4+5)**: dependem do vermelho commitado (T013); renomear `verify` jamais (fronteira 003).
- **Polish (Phase 6)**: depende do verde commitado (T020); cenário 🧑 pode fechar após o commit de convergência com divergência declarada.

### Within Each Phase

- Oráculo antes do que ele mede (T004–T013 antes de T014).
- `uv.lock` antes do que o referencia (T014 antes de T015? `ci.yml` não lê lock; ordem livre — mas frozen exige lock coerente: T014 antes de qualquer run).
- Commitlint antes da validação do histórico (T016 antes de T018).
- README/hash (T021) após o commit verde (hash só existe depois).

### Parallel Opportunities

- [P] T006, T018, T024, T025 (arquivos distintos, sem dependência).
- US2/US3 verificação (T017–T019) em paralelo entre si após T016; convergem em T020.
- Vermelho (T013) e verde (T020) jamais em paralelo — ordem temporal é a prova (III).

---

## Parallel Example: Phase 5 verification

```bash
# T018 + T024 juntos (arquivos distintos):
Task: "Validar commitlint contra histórico + sintéticas"
Task: "Executar cenário 🧑 OU registrar divergência declarada"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup (T001–T003) → 2. Phase 2+3 oráculo vermelho commitado (T004–T013) → 3. Phase 4 US1 (T014–T016) → **STOP e VALIDAR** workflow + cov + commitlint localmente.

### Incremental Delivery

1. Setup + oráculo vermelho → 2. US1 (MVP) → 3. US2/US3 + procedimento 🧑 → 4. Verde commitado → 5. Polish/CONVERGE (README, lista fechada, 10/10, cenário 🧑).

### Rejeitado

Verde sem vermelho separado (M3-recorrente); renomear job `verify` sem ADR (fronteira-003); token em arquivo para asserir servidor (Lei Zero); `continue-on-error`/retry mascarador (003-FR-011 + ADR-019); validar mensagem retroativa reescrevendo passado.
