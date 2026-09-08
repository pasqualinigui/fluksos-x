---
description: "Task list for 014 — atualização automática de dependências"
---

# Tasks: Atualização automática de dependências

**Input**: Design documents from `/specs/014-dependency-updates/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/oracle-cli.md`, `quickstart.md`

**Tests**: oráculo-primeiro (desvio deliberado do projeto para o TDD — o oráculo `f0-014` é o teste, vermelho antes do verde, em commits separados).

**Organization**: molde 013 (esqueleto → asserções 🔴 → verdes 🟢 → converge) com labels [US1..US4] por user story da spec.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1..US4)
- Exact file paths in descriptions

## Phase 1: Setup

**Purpose**: base verde + branch + evidência

- [ ] T001 [P] Confirmar harness 13/13 + manifest 13/13 (`for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done`)
- [ ] T002 [P] Re-verificar fronteira Q9 no disco (`grep -rn "dependabot|renovate" scripts/verify/` → zero; conferir literais `lefthook`, `pip-audit`, `[tool.pip-audit]`)
- [ ] T003 Criar branch `feature/f0-dependency-updates` desde `main` + diretório `specs/014-dependency-updates/evidence/`

---

## Phase 2: Foundational — esqueleto do oráculo

**Purpose**: infraestrutura de teste que BLOQUEIA todo o resto (sem oráculo, sem vermelho)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Criar `scripts/verify/f0-014-dependabot.sh` com esqueleto (cabeçalho Q1–Q9/D1–D7, CANON 11 IDs, contrato `oracle-cli.md`, self-check série ADR-031)
- [ ] T005 Acrescer 14ª linha a `scripts/verify/manifest.sha256` (junto do esqueleto — precedente E5: separar faria `f0-009/010/011/012` reprovarem junto)
- [ ] T006 Implementar asserts auto-verificáveis FR-009 em `scripts/verify/f0-014-dependabot.sh` (`--list` 11 IDs, `--invalido` exit 2, 2× byte-idêntico <5s, self-check `f0-001…f0-013`)

**Checkpoint**: Foundation ready — oráculo existe e fala o contrato

---

## Phase 3: User Story 1 — Updates triviais pelo portão (Priority: P1) 🎯 MVP + User Story 2/3/4 — asserções 🔴

**Goal**: oráculo reprovando sobre estado sem bot (o vermelho que a Regra 2 exige)

**Independent Test**: `scripts/verify/f0-014-dependabot.sh` → NÃO-CONFORME com FRs de comportamento vermelhos e guardas verdes; saída preservada em `specs/014-dependency-updates/evidence/red.txt`

### Tests (oráculo PRIMEIRO — TDD do projeto) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T007 [US1] FR-001/FR-002-version em `scripts/verify/f0-014-dependabot.sh` (uv + grupos `dev-minor-patch`/`security`)
- [ ] T008 [US2] FR-002-major/FR-003 em `scripts/verify/f0-014-dependabot.sh` (major isolado + `github-actions` SHA)
- [ ] T009 [US3] FR-004/FR-006 em `scripts/verify/f0-014-dependabot.sh` (prefixo `build(deps)` + zero supressão)
- [ ] T010 [US1] FR-005/FR-011 em `scripts/verify/f0-014-dependabot.sh` (gate de ator + tripwire actions)
- [ ] T011 [US4] FR-008 em `scripts/verify/f0-014-dependabot.sh` (`pip-audit` no `pre-push` — vermelho esperado: ainda está no `pre-commit`)
- [ ] T012 FR-007 em `scripts/verify/f0-014-dependabot.sh` (override `click` + lock — guarda, verde-desde-nascimento esperado)
- [ ] T013 **VERMELHO** — executar `scripts/verify/f0-014-dependabot.sh`, preservar `specs/014-dependency-updates/evidence/red.txt`, commit `test(harness)` separado (com a 14ª linha do manifest no mesmo ato)
- [ ] T014 Redigir ADR de fronteira em `docs/plan/decisions.md` (1 ponto `f0-009` FR-003, forma exata do plan) — PRÉVIA ao verde, nunca depois

**Checkpoint**: vermelho genuíno preservado + ADR autoriza o único toque em oráculo anterior

---

## Phase 4: Verdes por story 🟢

**Goal**: configuração que apaga o vermelho, sem tocar o que já convergiu

**Independent Test**: `scripts/verify/f0-014-dependabot.sh` → 11/11 CONFORME

### Implementation

- [ ] T015 [US1] Criar `.github/dependabot.yml` (ecossistema `uv`, grupos, schedule, prefixo — sem literal `lefthook`)
- [ ] T016 [US2] Completar `.github/dependabot.yml` (`github-actions` separado, majors isolados, bloco de comentário `TRIPWIRE-014-actions` com o fallback) (depends on T015 — mesmo arquivo)
- [ ] T017 [P] [US1] Criar `.github/workflows/dependabot-automerge.yml` (gate `dependabot[bot]` + `fetch-metadata@<40hex>` + `merge --auto --merge`; sem squash/rebase/vetores)
- [ ] T018 [US4] Mover `uv run pip-audit` para `pre-push` em `lefthook.yml` (ordem fail-fast do `pre-commit` intacta — SÓ na Fase C, ponto ADR-017)
- [ ] T019 [P] Re-verificar Q6 (`pypi.org/pypi/python-semantic-release/json` + `uv.lock` click) e registrar veredito no commit (mantém override ou remove pelo gatilho)
- [ ] T020 Executar cenários 1–3 de `specs/014-dependency-updates/quickstart.md` (depends on T015–T018)

**Checkpoint**: oráculo 11/11 + quickstart local verde

---

## Phase 5: Convergência

**Purpose**: fechar a lista (Regra 10) e publicar o estado

- [ ] T021 **VERDE** — oráculo 11/11, preservar `specs/014-dependency-updates/evidence/green.txt`, commit `feat(deps)` separado do vermelho
- [ ] T022 `specs/README.md` `014 ✅` + hash do commit de convergência
- [ ] T023 Re-executar harness 14/14 + `sha256sum -c scripts/verify/manifest.sha256`
- [ ] T024 Confirmar `tasks.md` zero `[ ]` + atualizar `AGENTS.md` (014 concluída, próxima 015)
- [ ] T025 SC-007 🧑 — primeiro PR real do bot validado via GitHub MCP (saídas verbatim; divergência declarada aceitável, silenciosa não)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **Asserções 🔴 (Phase 3)**: Depends on Foundational; vermelho antes de qualquer config
- **Verdes 🟢 (Phase 4)**: Depends on red (T013) + ADR (T014); T018 SOMENTE aqui
- **Convergência (Phase 5)**: Depends on green; T025 pode estender-se além do merge se nenhum bump existir (divergência declarada)

### User Story Dependencies

- **US1 (P1)**: after Foundational; oráculo T007/T010 → config T015/T017
- **US2 (P2)**: after Foundational; oráculo T008 → config T016 (mesmo arquivo que US1 — sequencial)
- **US3 (P2)**: after Foundational; oráculo T009 → sem arquivo próprio (propriedade da config US1, provada no TESTS via `commitlint`)
- **US4 (P2)**: after Foundational + ADR; oráculo T011 → config T018 (ponto de fronteira)

### Within Each Story

- Oráculo (teste) FIRST, FAIL before implementation (Regra 2> template: aqui o teste é o oráculo, não pytest)
- Vermelho em commit separado do verde (irrecuperável depois)
- Um item nunca toca oráculo anterior fora da ADR prévia

### Parallel Opportunities

- T001 + T002 (leituras independentes, arquivos distintos)
- T017 + T019 (arquivos/fontes distintos, sem dependência)
- T007–T012 são SEQUENCIAIS (mesmo arquivo-oráculo — [P] proibido)
- T015 → T016 SEQUENCIAIS (mesmo arquivo)

---

## Parallel Example: Setup

```bash
# Leituras independentes, sem escrita:
Task: "T001 Confirmar harness 13/13 + manifest 13/13"
Task: "T002 Re-verificar fronteira Q9 no disco"
```

## Implementation Strategy

### MVP First (US1 + US3)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006 — blocks everything)
3. Complete Phase 3: asserções + vermelho + ADR (T007–T014)
4. **STOP and VALIDATE**: red genuíno? ADR autoriza exatamente 1 ponto?
5. Verdes US1/US3 (T015, T017) → oráculo parcial verde → MVP do bot operando
6. US2/US4 (T016, T018) → converge (T021–T025)

### Incremental Delivery

1. Setup + Foundational → oráculo existe
2. Vermelho + ADR → prova + autorização
3. Verde por story → cada config apaga seus FRs sem quebrar anteriores
4. Converge → 14/14 + README + AGENTS

---

## Notes

- [P] tasks = different files, no dependencies (T007–T012 e T015–T016 NUNCA paralelos — mesmo arquivo)
- [Story] label maps task to US1..US4 for traceability
- T013 (vermelho) e T021 (verde) em commits SEPARADOS — é a única prova auditável do TDD
- T014 (ADR) entre vermelho e verde: PLAN declara → ADR autoriza → verde aplica → manifest cita
- T025 (SC-007 🧑) via GitHub MCP (API estruturada), nunca scraping — Assumptions da spec
- Stop at any checkpoint to validate independently
