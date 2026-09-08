---
description: "Task list for 016 — docs/tree.md, mapa da árvore para IA"
---

# Tasks: `docs/tree.md` — mapa da árvore para IA

**Input**: Design documents from `/specs/016-tree-docs/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/oracle-cli.md`, `quickstart.md`

**Tests**: oráculo-primeiro (desvio deliberado do projeto para o TDD — o oráculo `f0-016` é o teste, vermelho antes do verde, em commits separados).

**Organization**: molde 015 (esqueleto → asserções 🔴 → verdes 🟢 → converge) com labels [US1..US3] por user story da spec. Sem ADR de fronteira (varredura com zero pontos, declarada no plan).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1..US3)
- Exact file paths in descriptions

## Phase 1: Setup

**Purpose**: base verde + branch + evidência

- [x] T001 [P] Confirmar harness 15/15 + manifest 15/15 (`for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done`)
- [x] T002 [P] Re-verificar fronteira no disco (`grep -rn "tree\.md|generate-tree|tree-docs" scripts/verify/ .github/ lefthook.yml pyproject.toml` → zero; confirma fronteira zero do plan)
- [x] T003 Criar branch `feature/f0-tree-docs` desde `main` + diretório `specs/016-tree-docs/evidence/`

---

## Phase 2: Foundational — esqueleto do oráculo

**Purpose**: infraestrutura de teste que BLOQUEIA todo o resto (sem oráculo, sem vermelho)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Criar `scripts/verify/f0-016-tree.sh` com esqueleto (cabeçalho Q1–Q5/D1–D5, CANON 9 IDs, contrato `contracts/oracle-cli.md`, self-check série ADR-031)
- [x] T005 Acrescer 16ª linha a `scripts/verify/manifest.sha256` (junto do esqueleto — precedente E5: separar faria `f0-009/010/011/012` reprovarem junto)
- [x] T006 Implementar asserts auto-verificáveis em `scripts/verify/f0-016-tree.sh` (`--list` 9 IDs, `--invalido` exit 2, 2× byte-idêntico <5s, self-check `f0-001…f0-015`)

**Checkpoint**: Foundation ready — oráculo existe e fala o contrato

---

## Phase 3: Asserções por story + vermelho 🔴 (sem ADR — fronteira zero)

**Goal**: oráculo reprovando sobre estado sem mapa (o vermelho que a Regra 2 exige)

**Independent Test**: `scripts/verify/f0-016-tree.sh` → NÃO-CONFORME com FRs de comportamento vermelhos e guardas verdes; saída preservada em `specs/016-tree-docs/evidence/red.txt`

### Tests (oráculo PRIMEIRO — TDD do projeto) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T007 [US1] FR-001/FR-006 em `scripts/verify/f0-016-tree.sh` (H1+resumo+árvore+ponteiros; destinos herdados 013/014/015)
- [x] T008 [US2] FR-002/FR-003/FR-005 em `scripts/verify/f0-016-tree.sh` (esqueleto==gerador, 2× determinístico, zero segredo/fora-do-índice)
- [x] T009 [US3] FR-008 em `scripts/verify/f0-016-tree.sh` (auditoria `f0-audit-013-016.md` + cabeçalhos — vermelho esperado: relatório ainda não existe)
- [x] T010 FR-004/FR-007 em `scripts/verify/f0-016-tree.sh` (curadoria ≤120 linhas + total ≤25600 bytes; contrato auto-verificável)
- [x] T011 **VERMELHO** — executar `scripts/verify/f0-016-tree.sh`, preservar `specs/016-tree-docs/evidence/red.txt`, commit `test(harness)` separado (com a 16ª linha do manifest no mesmo ato; sem ADR — fronteira zero declarada no plan)

**Checkpoint**: vermelho genuíno preservado; nada a autorizar (zero toques em oráculo anterior)

---

## Phase 4: Verdes por story 🟢

**Goal**: mapa + gerador que apagam o vermelho, sem tocar o que já convergiu

**Independent Test**: `scripts/verify/f0-016-tree.sh` → CONFORME (com auditoria presente; sem ela, só FR-008 aberta)

### Implementation

- [x] T012 [US1] Criar `scripts/generate-tree.py` (stdlib, `git ls-files`, `LC_ALL=C`, ordenado, só-stdout, 2× byte-idêntico)
- [x] T013 [US1] Criar `docs/tree.md` com H1+resumo+esqueleto do gerador+tabela de ponteiros (depends on T012 — conteúdo deriva do gerador)
- [x] T014 [US2] Curar `docs/tree.md` (1 linha por diretório + ponteiros, teto ≤120 linhas na curadoria) (depends on T013 — mesmo arquivo, NUNCA paralelo)
- [x] T015 [P] [US3] Produzir `docs/plan/audit/f0-audit-013-016.md` como checkpoint não-item (formato ADR-014: `Veredito`, `Achados`, `Destino`; fora do mapa ADR-011)
- [x] T016 Executar cenários 1–4 de `specs/016-tree-docs/quickstart.md` (depends on T012–T014)

**Checkpoint**: oráculo verde + quickstart verde

---

## Phase 5: Convergência (fecha a Fase 0)

**Purpose**: fechar a lista (Regra 10) e publicar o estado

- [ ] T017 **VERDE** — oráculo CONFORME (re-verificar contagens da pesquisa contra o índice atual antes — E1), preservar `specs/016-tree-docs/evidence/green.txt`, commit `feat(treedocs)` separado do vermelho
- [ ] T018 `specs/README.md` `016 ✅` + hash do commit de convergência
- [ ] T019 Re-executar harness 16/16 + `sha256sum -c scripts/verify/manifest.sha256`
- [ ] T020 Confirmar `tasks.md` zero `[ ]` + atualizar `AGENTS.md` (016 concluída, Fase 0 16/16)
- [ ] T021 SC-007 🧑 — janela nova com só `AGENTS.md` + `tree.md`, localizar 3 artefatos de itens distintos (saídas verbatim; divergência declarada aceitável, silenciosa não)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **Asserções 🔴 (Phase 3)**: Depends on Foundational; vermelho antes de qualquer documento; sem ADR (fronteira zero)
- **Verdes 🟢 (Phase 4)**: Depends on red (T011); T015 (auditoria) pode correr em paralelo por arquivo distinto
- **Convergência (Phase 5)**: Depends on green; T015/auditoria TEM que ter aterrissado antes de T017 (FR-008)

### User Story Dependencies

- **US1 (P1)**: after Foundational; oráculo T007 → gerador T012 → mapa T013
- **US2 (P1)**: after Foundational; oráculo T008 → curadoria T014 (mesmo arquivo que US1 — sequencial)
- **US3 (P2)**: after Foundational; oráculo T009 → auditoria T015 (arquivo distinto — paralelizável)

### Within Each Story

- Oráculo (teste) FIRST, FAIL before implementation (Regra 2 > template: aqui o teste é o oráculo, não pytest)
- Vermelho em commit separado do verde (irrecuperável depois)
- Um item nunca toca oráculo anterior; aqui nem precisa (fronteira zero)

### Parallel Opportunities

- T001 + T002 (leituras independentes, arquivos distintos)
- T015 com qualquer tarefa verde (arquivo distinto, sem dependência)
- T007–T010 são SEQUENCIAIS (mesmo arquivo-oráculo — [P] proibido)
- T013 → T014 SEQUENCIAIS (mesmo arquivo)

---

## Parallel Example: Setup

```bash
# Leituras independentes, sem escrita:
Task: "T001 Confirmar harness 15/15 + manifest 15/15"
Task: "T002 Re-verificar fronteira no disco (expectativa: zero)"
```

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006 — blocks everything)
3. Complete Phase 3: asserções + vermelho (T007–T011, sem ADR)
4. **STOP and VALIDATE**: red genuíno? fronteira segue zero?
5. Verdes US1/US2 (T012–T014) → mapa navegável e honesto → MVP
6. US3 (T015) → converge (T017–T021) → Fase 0 16/16

### Incremental Delivery

1. Setup + Foundational → oráculo existe
2. Vermelho → prova (sem autorização pendente)
3. Verde por story → cada artefato apaga seus FRs sem quebrar anteriores
4. Converge → 16/16 + README + AGENTS + auditoria 013–016

---

## Notes

- [P] tasks = different files, no dependencies (T007–T010 e T013–T014 NUNCA paralelos — mesmo arquivo)
- [Story] label maps task to US1..US3 for traceability
- T011 (vermelho) e T017 (verde) em commits SEPARADOS — é a única prova auditável do TDD
- Sem T-ADR nesta spec: fronteira zero verificada em T002 e declarada no plan (primeira spec desde 008 sem ajuste em oráculo anterior)
- T015 (auditoria) é checkpoint não-item: entra no repo, não no mapa ADR-011
- Stop at any checkpoint to validate independently
