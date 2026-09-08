---
description: "Task list for 015 — docker-compose sob demanda"
---

# Tasks: docker-compose — Postgres + Redis sob demanda, observabilidade em profiles

**Input**: Design documents from `/specs/015-docker-compose/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/oracle-cli.md`, `quickstart.md`

**Tests**: oráculo-primeiro (desvio deliberado do projeto para o TDD — o oráculo `f0-015` é o teste, vermelho antes do verde, em commits separados).

**Organization**: molde 014 (esqueleto → asserções 🔴 → ADR → verdes 🟢 → converge) com labels [US1..US5] por user story da spec.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1..US5)
- Exact file paths in descriptions

## Phase 1: Setup

**Purpose**: base verde + branch + evidência

- [x] T001 [P] Confirmar harness 14/14 + manifest 14/14 (`for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done`)
- [x] T002 [P] Re-verificar fronteira Q10 no disco (`grep -n -i "docker-compose|docker/|compose" scripts/verify/f0-*.sh` → só `f0-008:80,509`; literais `Dockerfile`, `privileged`, `docker.sock` → zero)
- [x] T003 Criar branch `feature/f0-docker-compose` desde `main` + diretório `specs/015-docker-compose/evidence/`

---

## Phase 2: Foundational — esqueleto do oráculo

**Purpose**: infraestrutura de teste que BLOQUEIA todo o resto (sem oráculo, sem vermelho)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Criar `scripts/verify/f0-015-docker-compose.sh` com esqueleto (cabeçalho Q1–Q10/D1–D7, CANON 16 IDs, contrato `contracts/oracle-cli.md`, self-check série ADR-031)
- [x] T005 Acrescer 15ª linha a `scripts/verify/manifest.sha256` (junto do esqueleto — precedente E5: separar faria `f0-009/010/011/012` reprovarem junto)
- [x] T006 Implementar asserts auto-verificáveis em `scripts/verify/f0-015-docker-compose.sh` (`--list` 16 IDs, `--invalido` exit 2, 2× byte-idêntico <5s modo estático, self-check `f0-001…f0-014`)

**Checkpoint**: Foundation ready — oráculo existe e fala o contrato

---

## Phase 3: Asserções por story + vermelho 🔴 + ADR

**Goal**: oráculo reprovando sobre estado sem compose (o vermelho que a Regra 2 exige)

**Independent Test**: `scripts/verify/f0-015-docker-compose.sh` → NÃO-CONFORME com FRs de comportamento vermelhos e guardas verdes; saída preservada em `specs/015-docker-compose/evidence/red.txt`

### Tests (oráculo PRIMEIRO — TDD do projeto) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T007 [US1] FR-001/FR-002-núcleo/FR-003/FR-004 em `scripts/verify/f0-015-docker-compose.sh` (pins `tag@digest`, profiles, `restart: "no"`, `depends_on`+healthcheck)
- [x] T008 [US2] FR-005/FR-006/FR-007/FR-008 em `scripts/verify/f0-015-docker-compose.sh` (zero segredo, portas `127.0.0.1` no mapa fixo, limites+logs, hardening)
- [x] T009 [US3] FR-009/FR-012 em `scripts/verify/f0-015-docker-compose.sh` (profile `llm` pinado, `TELEMETRY_ENABLED=false`, bancos `fkx`+`langfuse` sem SUPERUSER)
- [x] T010 [US4] FR-010 em `scripts/verify/f0-015-docker-compose.sh` (6 pins observability + provisioning)
- [x] T011 [US5] FR-011/FR-002-gateway em `scripts/verify/f0-015-docker-compose.sh` (ausência de `gateway`/`litellm` — vermelho se existir)
- [x] T012 FR-014/FR-015 em `scripts/verify/f0-015-docker-compose.sh` (`trivy image` por pin com ⏭️ sem daemon, `compose config` 2× byte-idêntico)
- [x] T013 **VERMELHO** — executar `scripts/verify/f0-015-docker-compose.sh`, preservar `specs/015-docker-compose/evidence/red.txt`, commit `test(harness)` separado (com a 15ª linha do manifest no mesmo ato)
- [x] T014 Redigir ADR de fronteira em `docs/plan/decisions.md` (1 ponto `f0-008` FR-003→FR-013, forma exata do plan) — PRÉVIA ao verde, nunca depois

**Checkpoint**: vermelho genuíno preservado + ADR autoriza o único toque em oráculo anterior

---

## Phase 4: Verdes por story 🟢

**Goal**: manifesto que apaga o vermelho, sem tocar o que já convergiu

**Independent Test**: `scripts/verify/f0-015-docker-compose.sh` → CONFORME (estáticas; lives verdes com daemon ou ⏭️ nomeado sem)

### Implementation

- [x] T015 [US1] Criar `docker-compose.yml` com núcleo (`postgres`+`redis` pinados, `restart: "no"`, healthchecks, rede `backend`+`edge`, volumes, limites, logging) — implementa também as propriedades de US2 (F1: label único por formato; US2 sem arquivo próprio)
- [x] T016 [P] [US1] Criar `docker/postgres/01-users-dbs.sh` (bancos `fkx`+`langfuse`, usuários sem SUPERUSER) + estender `.env.example` (todas as chaves, placeholders) + verificar/adicionar `secrets/` ao `.gitignore` (C1: `.env` já ignorado; `secrets/` sem entrada é Lei Zero por omissão)
- [x] T017 [US3] Adicionar profile `llm` em `docker-compose.yml` (web+worker `4.30.0`, ClickHouse `25.12`, MinIO, `TELEMETRY_ENABLED=false`) (depends on T015 — mesmo arquivo)
- [x] T018 [US4] Adicionar profile `observability` em `docker-compose.yml` (6 pins + provisioning) (depends on T015 — mesmo arquivo)
- [x] T019 [P] [US4] Criar `docker/prometheus/prometheus.yml` + `docker/alloy/config.alloy` + `docker/grafana/provisioning/` (montes `:ro`, arquivos distintos)
- [x] T020 Executar cenários 1–2 de `specs/015-docker-compose/quickstart.md` (depends on T015–T016; com daemon: up→prova→down sem resíduo; sem daemon: registra ⏭️ e segue — E2, precedente 008 FR-009)
- [x] T021 [P] Re-verificar digests contra registry API (tabela de pins do `research.md`; divergência = bump pelo molde ADR-037, nunca `latest`)

**Checkpoint**: oráculo verde (estáticas) + quickstart local verde

---

## Phase 5: Convergência

**Purpose**: fechar a lista (Regra 10) e publicar o estado

- [ ] T022 **VERDE** — oráculo CONFORME, preservar `specs/015-docker-compose/evidence/green.txt`, commit `feat(compose)` separado do vermelho (com o ponto ADR-017 aplicado AQUI)
- [ ] T023 `specs/README.md` `015 ✅` + hash do commit de convergência
- [ ] T024 Re-executar harness 15/15 + `sha256sum -c scripts/verify/manifest.sha256`
- [ ] T025 Confirmar `tasks.md` zero `[ ]` + atualizar `AGENTS.md` (015 concluída, próxima 016)
- [ ] T026 SC-006 🧑 — ciclos live com daemon (núcleo + `llm` até trace visível + `observability` até Grafana com dados + `down` final sem resíduo; saídas verbatim; divergência declarada aceitável, silenciosa não)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **Asserções 🔴 (Phase 3)**: Depends on Foundational; vermelho antes de qualquer manifesto
- **Verdes 🟢 (Phase 4)**: Depends on red (T013) + ADR (T014); ponto de fronteira SOMENTE em T022
- **Convergência (Phase 5)**: Depends on green; T026 exige daemon (divergência declarada se indisponível)

### User Story Dependencies

- **US1 (P1)**: after Foundational; oráculo T007 → manifesto T015/T016
- **US2 (P1)**: after Foundational; oráculo T008 → propriedades do mesmo manifesto (sem arquivo próprio; provado via asserts estáticos + trivy)
- **US3 (P2)**: after Foundational; oráculo T009 → profile T017 (mesmo arquivo que US1 — sequencial); fallback PG17 vive aqui se TESTS mandar
- **US4 (P2)**: after Foundational; oráculo T010 → profile T018 + configs T019
- **US5 (P3)**: after Foundational; oráculo T011 → ausência provada (sem arquivo; deferral documentado)

### Within Each Story

- Oráculo (teste) FIRST, FAIL before implementation (Regra 2 > template: aqui o teste é o oráculo, não pytest)
- Vermelho em commit separado do verde (irrecuperável depois)
- Um item nunca toca oráculo anterior fora da ADR prévia

### Parallel Opportunities

- T001 + T002 (leituras independentes, arquivos distintos)
- T016 + T019 (arquivos distintos, sem dependência — T016 vs T015 também, mas T015 cria o compose que T016 referencia; permitido em paralelo por arquivos distintos)
- T007–T012 são SEQUENCIAIS (mesmo arquivo-oráculo — [P] proibido)
- T015 → T017 → T018 SEQUENCIAIS (mesmo arquivo)
- T021 [P] com qualquer tarefa verde (só leitura de registry)

---

## Parallel Example: Setup

```bash
# Leituras independentes, sem escrita:
Task: "T001 Confirmar harness 14/14 + manifest 14/14"
Task: "T002 Re-verificar fronteira Q10 no disco"
```

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006 — blocks everything)
3. Complete Phase 3: asserções + vermelho + ADR (T007–T014)
4. **STOP and VALIDATE**: red genuíno? ADR autoriza exatamente 1 ponto?
5. Verdes US1/US2 (T015, T016) → núcleo operando sob demanda → MVP
6. US3/US4/US5 (T017–T019, T011) → converge (T022–T026)

### Incremental Delivery

1. Setup + Foundational → oráculo existe
2. Vermelho + ADR → prova + autorização
3. Verde por story → cada manifesto apaga seus FRs sem quebrar anteriores
4. Converge → 15/15 + README + AGENTS

---

## Notes

- [P] tasks = different files, no dependencies (T007–T012 e T015/T017/T018 NUNCA paralelos — mesmo arquivo)
- [Story] label maps task to US1..US5 for traceability
- T013 (vermelho) e T022 (verde) em commits SEPARADOS — é a única prova auditável do TDD
- T014 (ADR) entre vermelho e verde: PLAN declara → ADR autoriza → verde aplica → manifest cita
- T026 (SC-006 🧑) exige daemon Docker; sem daemon, divergência declarada (precedente 010/SC-005)
- A1: sobreposição FR-002/FR-011 (ausência do `gateway`) é intencional (defesa em profundidade) — o ANALYZE futuro não deve reabri-la sem evidência nova
- F6: `deploy.resources` (citado no research Q4) é swarm-only e o `up` o ignora — FR-007 usa `mem_limit`/`mem_reservation`/`cpus`/`pids_limit`; o research permanece como registro histórico (precedente ADR-017 B1: não se reescreve), a spec é a fonte vigente
- Stop at any checkpoint to validate independently
