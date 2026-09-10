# Tasks: `core/harness.py` — controles feedforward + feedback

**Input**: Design documents from `/specs/017-harness/`

**Prerequisites**: plan.md (required), spec.md (user stories P1–P3), research.md (D1–D7), data-model.md (4 entidades), contracts/ (mapa identidade 12 FRs)

**Tests**: TDD mandatório da casa (Regra 3) — oráculo PRIMEIRO (desvio deliberado: oracle-first), pytest em `tests/test_fkx_core_harness.py`, vermelho antes do verde em commits separados (Regra 2)

**Organization**: Tasks are grouped by user story (US1 veredito P1 🎯 MVP, US2 recusa P2, US3 composição P3); fronteira paga na Fase C via ADR prévia (10ª execução do molde ADR-017)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: base verde + branch + evidência

- [ ] T001 [P] Confirmar harness 16/16 + manifest 16/16 (`for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done; sha256sum -c scripts/verify/manifest.sha256`)
- [ ] T002 [P] Re-verificar fronteira no disco (`grep -rn 'alem dos 4|EXTRA=' scripts/verify/f0-*.sh` → só `f0-011` sobre `core/`; confirma o ponto único do plan)
- [ ] T003 Verificar branch `feature/f1-harness-engine` desde `main` + diretório `specs/017-harness/evidence/`

---

## Phase 2: Foundational — esqueleto do oráculo

**Purpose**: infraestrutura de teste que BLOQUEIA todo o resto (sem oráculo, sem vermelho)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Criar `scripts/verify/f1-017-harness.sh` com esqueleto (cabeçalho Q1–Q8/D1–D7, CANON 12 IDs, contrato `specs/017-harness/contracts/oracle-cli.md`, self-check `f0-001…f0-016` em série ADR-031 — prefixo `f1-`, primeiro da Fase 1)
- [ ] T005 Acrescer 17ª linha a `scripts/verify/manifest.sha256` (junto do esqueleto — precedente E5: separar faria `f0-009/010/011/012` reprovarem junto)
- [ ] T006 Implementar asserts auto-verificáveis em `scripts/verify/f1-017-harness.sh` (`--list` 12 IDs, `--invalido` exit 2, 2× byte-idêntico <5s, self-check `f0-001…f0-016`)

**Checkpoint**: Foundation ready — oráculo existe e fala o contrato

---

## Phase 3: Asserções por story + vermelho 🔴 (fronteira declarada, ainda não aplicada)

**Goal**: oráculo + pytest reprovando sobre estado sem `harness.py` (o vermelho que a Regra 2 exige)

**Independent Test**: `scripts/verify/f1-017-harness.sh` → NÃO-CONFORME com FRs de comportamento vermelhas e guardas verdes; `pytest tests/test_fkx_core_harness.py` → collection ERROR/falhas; saídas preservadas em `specs/017-harness/evidence/red.txt`

### Tests (oráculo PRIMEIRO — TDD do projeto) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T007 [US1] FR-002/FR-003/FR-005/FR-006 em `scripts/verify/f1-017-harness.sh` (feedback com returncode preservado; literais `0/1/2`; veredito nomeia requisito+evidência; `HarnessError`)
- [ ] T008 [US2] FR-001/FR-012 em `scripts/verify/f1-017-harness.sh` (feedforward recusa sem processo; portão não-POSIX fail-closed)
- [ ] T009 [US3] FR-003/FR-007 em `scripts/verify/f1-017-harness.sh` (equivalência Python↔shell; nenhum exit fora de `{0,1,2}`)
- [ ] T010 FR-004/FR-008/FR-011 em `scripts/verify/f1-017-harness.sh` (zero retry tentativa-única; contrato auto-verificável; só-stdlib) + `tests/test_fkx_core_harness.py` com os casos US1–US3 (molde `tests/test_fkx_core_*.py`, importa de `fkx_core`)
- [ ] T011 **VERMELHO** — executar `scripts/verify/f1-017-harness.sh` + `pytest tests/test_fkx_core_harness.py`, preservar `specs/017-harness/evidence/red.txt`, commit `test(harness)` separado (com a 17ª linha do manifest no mesmo ato; fronteira AINDA intocada) + **PUSH do vermelho** (disciplina §6 do checkpoint: durabilidade da prova)

**Checkpoint**: vermelho genuíno preservado e empurrado; fronteira declarada, nada autorizado ainda

---

## Phase 4: ADR prévia + verdes por story 🟢

**Goal**: `harness.py` que apaga o vermelho, com a fronteira paga pelo procedimento

**Independent Test**: `scripts/verify/f1-017-harness.sh` → CONFORME 12/12; `pytest tests/test_fkx_core_harness.py` → verde

### Prerequisite (bloqueia a Fase C)

- [ ] T012 Redigir ADR-042 prévia de fronteira em `docs/plan/decisions.md` (10ª execução do molde ADR-017, forma exata do plan: `f0-011` FR-002 admite `harness.py` sob jurisdição 017; nada além)

### Implementation

- [ ] T013 [US1] `HarnessError(FkxError)` em `packages/core/src/fkx_core/exceptions.py` + exports em `packages/core/src/fkx_core/__init__.py`
- [ ] T014 [US1] Feedback em `packages/core/src/fkx_core/harness.py` (`check=False` + captura + returncode preservado + veredito; depends on T013 — concepção deriva do erro)
- [ ] T015 [US2] Feedforward + portão POSIX em `packages/core/src/fkx_core/harness.py` (depends on T014 — mesmo arquivo, NUNCA paralelo)
- [ ] T016 Aplicar ajuste autorizado em `scripts/verify/f0-011-core.sh` FR-002 (whitelist `harness.py` sob jurisdição 017, citando ADR-042) + regenerar `scripts/verify/manifest.sha256` citando ADR-042 (**exclusivamente na Fase C**; nenhum outro oráculo tocado)
- [ ] T017 Executar cenários 1–4 de `specs/017-harness/quickstart.md` (depends on T013–T015)

**Checkpoint**: oráculo verde + pytest verde + quickstart verde

---

## Phase 5: Convergência (abre a Fase 1)

**Purpose**: fechar a lista (Regra 10) e publicar o estado

- [ ] T018 **VERDE** — oráculo CONFORME + pytest verde, preservar `specs/017-harness/evidence/green.txt`, commit `feat(harness)` separado do vermelho
- [ ] T019 `specs/README.md` `017 ✅` + hash do commit de convergência
- [ ] T020 Re-executar harness 17/17 + `sha256sum -c scripts/verify/manifest.sha256`
- [ ] T021 Confirmar `tasks.md` zero `[ ]` + atualizar `AGENTS.md` (Fase 1 1/8)
- [ ] T022 SC-006 🧑 — roteiro de `specs/017-harness/quickstart.md` com saídas verbatim (divergência declarada aceitável, silenciosa não)
- [ ] T023 PR + auto-merge servidor (merge no verde; sem squash/rebase por construção — ADR-035)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **Tests+Red (Phase 3)**: Depends on Foundational; fronteira declarada mas NÃO aplicada (T011 sem toques herdados)
- **ADR+Green (Phase 4)**: Depends on Red (T011) + ADR-042 escrita (T012) ANTES de qualquer verde que toque `f0-011`
- **Converge (Phase 5)**: Depends on Green; PR só aqui (norma §6: pushes no vermelho T011 e no converge)

### User Story Dependencies

- **User Story 1 (P1)**: Veredito nomeado — base de tudo; sem ela US2/US3 não têm o que recusar/compor
- **User Story 2 (P2)**: Recusa pré-execução — consome o veredito (erro de uso é um veredito)
- **User Story 3 (P3)**: Composição shell — propriedade emergente de US1 (mesmos literais), sem código próprio além de asserts

### Within Each Story

- Oráculo assertions (Phase 3) MUST FAIL before implementation (Phase 4)
- `HarnessError` (T013) before feedback (T014) before feedforward (T015) — mesmo arquivo, sequencial
- Pytest red (T010) before green (T018) — sem modificação do teste entre eles salvo defeito do próprio teste (vira ADR)

### Parallel Opportunities

- T001 + T002 ([P], leituras independentes)
- T010 pytest (arquivo distinto do oráculo) pode ser escrito em paralelo a T007–T009
- US1/US2/US3 assertions (T007–T009) em arquivos? Não — mesmo oráculo: sequencial na escrita, mas ordem livre
- Nada em Phase 4 é paralelo (mesmo `harness.py` + 1 oráculo de fronteira)

---

## Parallel Example: Setup

```bash
# Leituras independentes, sem escrita:
# T001: for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done
# T002: grep -rn 'alem dos 4|EXTRA=' scripts/verify/f0-*.sh
```

---

## Implementation Strategy

### MVP First (US1)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006, oráculo esqueleto + manifest)
3. Complete Phase 3: assertions US1 (T007) + vermelho (T011) + PUSH
4. ADR-042 (T012) → T013+T014 → verde parcial US1 verificável pelo oráculo
5. **STOP and VALIDATE**: US1 (veredito sobre morte/erro) funciona sem feedforward

### Incremental Delivery

1. Setup + Foundational → oráculo fala o contrato
2. Red (T007–T011) → PUSH → prova durável
3. ADR-042 → Green US1 → Green US2/US3 → quickstart
4. Converge (T018–T023) → PR → servidor mergeia → Fase 1 1/8

### Frontier Discipline (molde ADR-017, 10ª execução)

1. PLAN declara (feito: `plan.md` › Declaração, 1 ponto)
2. ADR-042 autoriza a forma exata (T012, ANTES do verde)
3. Verde aplica (T016, SÓ na Fase C, citando ADR-042)
4. Manifest cita (T016, regenerado)
5. Qualquer vermelho herdado fora do ponto = conflito novo, ADR própria, nunca fix direto

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Oráculo antes de pytest antes de implementação (TDD da casa: Regras 2–3)
- Commit após cada fase (test/vermelho/feat separados); push SÓ em T011 (vermelho) e Phase 5 (converge) — norma §6
- Stop at any checkpoint to validate story independently
- Avoid: tocar oráculo anterior fora de T016; retry em qualquer forma; `check=True` fora de pré-condição
