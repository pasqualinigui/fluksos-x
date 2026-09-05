---
description: "Task list for 009 — Lefthook — orquestração pre-commit do harness"
---

# Tasks: Lefthook — orquestração pre-commit do harness

**Input**: Design documents from `/specs/009-lefthook/`
**Prerequisites**: `plan.md` (required), `spec.md` (required, US1 P1/US2 P2/US3 P3), `research.md` (5 decisões), `data-model.md` (5 entidades), `contracts/oracle-cli.md` (mapa identidade FR-001..016), `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-005, FR-016). A prova é `f0-009-lefthook.sh` 16 asserções reprovando (🔴) e aprovando (🟢) em **commits separados** — exceção M3 da auditoria 005–008 não se estende. O oráculo é o teste.

**Artefatos deste item**: `lefthook.yml` (jobs pre-commit fail-fast check-only + pre-push harness, `min_version: 2.1.12`), `pyproject.toml` (`lefthook==2.1.12` em `[dependency-groups] dev`), `uv.lock` com hash, `scripts/verify/f0-009-lefthook.sh` (16 asserções), `scripts/verify/manifest.sha256` 9 linhas, `specs/README.md` índice `009 ✅` + hash, `specs/009-lefthook/evidence/` (`red.txt`, `green.txt`). Ajustes 004–008 **somente** os 5 pontos da ADR-018, **somente** na Fase C verde. Nenhum `.github/`, nenhum `packages/`, nenhum `remotes`/`self-update`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. `lefthook` em `[dependency-groups] dev` fonte única (padrão 005–008). Oráculo em `scripts/verify/f0-009-lefthook.sh` segue ADR-002/015. Spec dir `specs/009-lefthook/` segue Spec-Kit.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `007`/`008`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oráculo completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..016 antes de `lefthook.yml` existir. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (III, SC-005, FR-016) |
| Jobs por história | **Fase C materializa `lefthook.yml` + dev juntos** | jobs partilham um único `lefthook.yml`; `uv.lock` é fonte única indivisível |
| US2/US3 após US1 | **US2/US3 verificação após verde** | Depois do verde, US2/US3 não mutam além de verificação (pre-push, trivy condicional, setup) + ajustes ADR-018 |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T016 (vermelho) antes de T017** — criar `lefthook.yml`/dev antes do vermelho satisfaz FRs e ainda assim falha SC-005/Princípio III de forma irrecuperável (plan.md Fase B). Exceção M3 não se estende.
2. **T004 antes de T005–T015** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON 16 FRs, FKX_ORACLE_NESTED, determinismo 2×) é pré-requisito de qualquer asserção.
3. **T029 (verde) após T017–T028** — verde só é verde depois da última mutação (`lefthook.yml` + dev + `uv.lock` + ajustes ADR-018 + manifest + README). Ajustes 004–008 **só** na Fase C (ADR-018).

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T016 | US1+US2+US3 (oracle) |
| Fase C — Lefthook verde 🟢 | Phase 4 + Phase 5 | T017–T028 | US1 (MVP) + US2/US3 |
| Fase D — Verde e convergência | Phase 6 | T029–T034 | Polish/CONVERGE |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (008) está verde e que os artefatos-alvo ainda não existem; preparar evidências; confirmar pré-autorização vigente.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com 30/30, 33/33, 14/14, 14/14, 15/15, 14/14, 16/16, 15/16+1⏭️ + `sha256sum -c scripts/verify/manifest.sha256` 8/8 SUCESSO. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausências de fronteira: `! test -f lefthook.yml`, `! grep -q lefthook pyproject.toml`, `! grep -q 'name = "lefthook"' uv.lock`, `! test -f scripts/verify/f0-009-lefthook.sh`, e que `docs/plan/audit/f0-audit-005-008.md` existe (FR-011/ADR-016) — registra fronteira FR-001/002/010 (plan.md Fase A)
- [x] T003 Confirmar ADR-018 registrada em `docs/plan/decisions.md` (tabela 5 pontos) + criar `specs/009-lefthook/evidence/` para `red.txt`/`green.txt` (Princípio III, plan.md Fase A:2-3)

---

## Phase 2: Foundational — esqueleto do oráculo (blocking)

**Purpose**: contrato de interface executável antes de qualquer asserção (T004 bloqueia T005–T015).

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-009-lefthook.sh` com esqueleto do contrato herdado: parsing `--quiet`/`--list`, raiz pela localização do script (nunca `$PWD`), códigos 0/1/2, formato `<emoji> FR-XXX <descrição>`, linha de resultado final, mapa CANON com as 16 descrições FR-001..016 de `contracts/oracle-cli.md` §3, guarda `FKX_ORACLE_NESTED`, cabeçalho comentando FRs guardas (008/009/010/011/012/013/014) × comportamento (001..007/015/016), sem efeitos além de stdout/stderr, **sem executar jobs do hook** (FR-013, contrato §1)
- [x] T005 Acrescer 9ª linha ao `scripts/verify/manifest.sha256` (hash do esqueleto — será regenerada no verde; acréscimo permitido por ADR-015a, nunca reescrita de valor alheio)
- [x] T006 [P] Implementar asserts auto-verificáveis do oráculo em `scripts/verify/f0-009-lefthook.sh`: `--list` enumera 16 IDs do CANON, `--invalido` sai 2, 2 execuções byte-idênticas e cada uma <5s (FR-013/FR-018, SC-006, contrato §1)

**Checkpoint**: esqueleto executável — `f0-009 --list` lista 16 FRs; asserções ainda ausentes (tudo vermelho por construção).

---

## Phase 3: User Stories US1+US2+US3 — asserções do oráculo 🔴 (Priority: todas)

**Goal**: cobertura total FR-001..016 reprovando sobre estado sem Lefthook.

**Independent Test**: `scripts/verify/f0-009-lefthook.sh` → 16/16 vermelhas com evidência por FR; `evidence/red.txt` preserva a saída.

- [x] T007 [US1] Implementar em `scripts/verify/f0-009-lefthook.sh` **Grupo FR-001/002** — pin e config: `min_version: 2.1.12` em `lefthook.yml` + `lefthook==2.1.12` em dev + `name = "lefthook"` em `uv.lock` concordando; YAML único na raiz; ausência de `remotes`/`self-update` (FR-001/002, data-model Entidades 1–2)
- [x] T008 [US1] Implementar **Grupo FR-003/006** — jobs pre-commit: ordem `ruff check` → `format --check` → `mypy --strict` → `pytest -q` → `pip-audit` via `uv run`, sem cor forçada; **nenhum** `--fix`/`stage_fixed` no config (FR-003/006, decisão check-only CLARIFY)
- [x] T009 [US2] Implementar **Grupo FR-004/005** — `trivy fs` exclusivo no `pre-push` + skip sem Docker; `pre-push` contém `for f in scripts/verify/f0-*.sh` (FR-004/005, precedente 008-FR-009)
- [x] T010 [US3] Implementar **Grupo FR-007/008** — `lefthook validate` + `check-install` saem 0; escape `LEFTHOOK=0` documentado (FR-007/008)
- [x] T011 [US3] Implementar **Grupo FR-009/010** — `.github/` intocado + glob do CI inclui `f0-009`; sem escrita fora do repo, nada global (FR-009/010)
- [x] T012 Implementar **Grupo FR-011 (cadência, ADR-016)** — `docs/plan/audit/f0-audit-005-008.md` presente + cabeçalhos inaugurais grepeáveis; sem relatório, reprova (FR-011)
- [x] T013 Implementar **Grupo FR-012 (fronteira, ADR-017)** — `specs/009-lefthook/plan.md` contém tabela de impacto + `docs/plan/decisions.md` contém ADR-018; sem ambos, reprova (FR-012)
- [x] T014 Implementar **Grupo FR-014** — `sha256sum -c scripts/verify/manifest.sha256` 0 com 9 linhas + self-check `f0-001…f0-008 --quiet` todos 0 (FR-014, ADR-015a/e)
- [x] T015 Implementar **Grupo FR-015/016** — `specs/README.md` `009 ✅` + hash; `grep -E "^- \[ \]" specs/009-lefthook/tasks.md` → 0 (forma ancorada, lição M4/005); ordem vermelho-antes-do-verde verificável em `git log` (FR-015/016)
- [x] T016 **VERMELHO** — executar `scripts/verify/f0-009-lefthook.sh`, preservar saída em `specs/009-lefthook/evidence/red.txt` (+ `--quiet`), confirmar 9 vermelhas de comportamento (FR-001..007/015/016) + 7 guardas verdes (FR-008..014) — nada de Lefthook existe (T001/T002 garantem) — e commitar `test(harness)` **separado**: `test(harness): registra o portao vermelho do item 009 — Lefthook` (plan.md Fase B; restrição 1 acima)

**Checkpoint**: vermelho preservado em commit próprio — a partir daqui, qualquer mutação de `lefthook.yml`/dev sem verde subsequente é defeito irrecuperável.

---

## Phase 4: User Story 1 — Pre-commit barra violação (Priority: P1) 🎯 MVP

**Goal**: `lefthook run pre-commit` reprova nomeadamente sobre staged sujo e zera sobre staged limpo.

**Independent Test**: isca com violação `ruff` em cópia descartável → saída ≠ 0 com job nomeado; sem isca → 0 (quickstart Cenário 1).

- [x] T017 [US1] `uv add --dev lefthook==2.1.12` + `uv sync` (hash em `uv.lock`); confirmar `uv run lefthook version` → `2.1.12` (FR-001, research D2)
- [x] T018 [US1] Escrever `lefthook.yml`: `min_version: 2.1.12`, `pre-commit` fail-fast FR-003 (somente-leitura), sem `remotes`/`self-update` (FR-002/003/006)
- [x] T019 [US1] `uv run lefthook install` + `validate` + `check-install` verdes + `git status --short` limpo exceto `lefthook.yml`/dev/lock/oráculo (install só toca `.git/hooks/`, FR-007/010; quickstart Cenário 3)
- [x] T020 [P] [US1] Teste independente US1 em cópia descartável com isca `ruff` (quickstart Cenário 1) — repo real nunca recebe isca

**Checkpoint**: US1 funcional e testável independentemente (MVP do item).

---

## Phase 5: User Stories 2+3 — push, trivy, setup, fronteira (Priority: P2/P3)

**Goal**: `pre-push` espelha o harness; trivy condicional; setup documentado; fronteiras 004–008 ajustadas **somente** nos 5 pontos ADR-018.

**Independent Test**: `lefthook run pre-push` → 0 com harness 9/9 (ainda sem os ajustes? — os ajustes entram nesta fase antes do verde final); quickstart Cenários 2–4.

- [x] T021 [US2] Declarar `pre-push` em `lefthook.yml` (harness `f0-*.sh` + `trivy fs` condicional FR-004) e validar `lefthook run pre-push` → 0 (FR-005; quickstart Cenário 2)
- [x] T022 [US2] Validar caminho Trivy: com Docker executa, sem Docker skip documentado (FR-004; quickstart Cenário 4)
- [x] T023 [P] [US3] Validar o procedimento de setup do quickstart Cenário 3 em clone/cópia descartável (comandos já escritos — executar e confirmar `validate` + `check-install`)
- [x] T024 [P] [US3] Confirmar `.github/` intocado (`git diff --name-only` sem `.github/`) e escape `LEFTHOOK=0` funcional (FR-008/009; quickstart Cenário 6)
- [x] T025 [US1+US2+US3] Aplicar os 5 ajustes ADR-018 em `f0-004`/`f0-005`/`f0-006`/`f0-007`/`f0-008` (forma exata da tabela, padrão `uv.lock`) — **somente nesta fase, somente estes pontos** (restrição 3; plan.md Fase C:4)
- [x] T026 Regenerar `scripts/verify/manifest.sha256` (9/9) citando ADR-018 na mensagem do verde + `for f in scripts/verify/f0-*.sh` 9/9 (plan.md Fase C:5)
- [x] T027 [P] Rodar cadeia completa: `uv run ruff check .` + `format --check` + `uv run mypy --strict .` + `uv run pip-audit` + `uv run pytest -q` — tudo 0 (higiene pré-verde)
- [x] T028 **VERDE** — executar `scripts/verify/f0-009-lefthook.sh` 16/16, preservar `specs/009-lefthook/evidence/green.txt`, e commitar `feat(harness)` **separado** do T016: `feat(harness): add lefthook 2.1.12 pre-commit orchestration (009)` (plan.md Fase C/D)

**Checkpoint**: verde em commit próprio, posterior ao vermelho (FR-016 verificará a ordem no log).

---

## Phase 6: Polish & CONVERGE (Final Phase)

**Purpose**: inquebráveis, lista fechada, validação ponta-a-ponta.

- [x] T029 `specs/README.md` `009 ✅` + hash do commit T028 (inquebrável FR-015; quickstart Cenário 5)
- [x] T030 Re-executar harness 9/9 + manifest 9/9 + quickstart "validação completa em um comando" (quickstart Cenários 5–6)
- [x] T031 Confirmar `tasks.md` zero `^- [ ]` (o próprio oráculo FR-016 já asserir; dupla checagem humana) e `git log` com vermelho-antes-do-verde
- [x] T032 [P] Troubleshooting do quickstart executado contra os 3 cenários de falha (hook ausente, config rejeitado, vermelho herdado fora ADR-018)
- [x] T033 Rolagem da porta de entrada: `AGENTS.md:9` → harness 9/9 verde, próximo item 010 (precedente `docs(agents)` 004/006; entra no commit verde ou em `docs(agents)` separado, nunca no vermelho)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — começa imediato; T001 verde é portão (VI).
- **Foundational+Oracle (Phase 2+3)**: dependem do Setup; T004 bloqueia T005–T015; T016 fecha o vermelho.
- **Green (Phase 4+5)**: dependem do vermelho commitado (T016); T025/T026 só na Fase C (ADR-018).
- **Polish (Phase 6)**: depende do verde commitado (T028).

### Within Each Phase

- Oráculo antes do que ele mede (T004–T016 antes de T017).
- `uv.lock` antes de `lefthook.yml` que o referencia (T017 antes de T018).
- Ajustes herdados (T025) antes do manifest final (T026) antes do verde (T028).
- README/hash (T029) após o commit verde (hash só existe depois).

### Parallel Opportunities

- [P] T006, T020, T023, T024, T027, T032 (arquivos distintos, sem dependência).
- US2/US3 verificação (T021–T024) em paralelo entre si após T019; convergem em T025.
- Vermelho (T016) e verde (T028) jamais em paralelo — ordem temporal é a prova (III).

---

## Parallel Example: Phase 5 verification

```bash
# T023 + T024 juntos (arquivos distintos):
Task: "Validar quickstart Cenário 3 em cópia descartável"
Task: "Confirmar .github intocado + escape LEFTHOOK=0"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup (T001–T003) → 2. Phase 2+3 oráculo vermelho commitado (T004–T016) → 3. Phase 4 US1 verde (T017–T020) → **STOP e VALIDAR** pre-commit barra/nomeia.

### Incremental Delivery

1. Setup + oráculo vermelho → 2. US1 (MVP) → 3. US2/US3 + fronteira ADR-018 → 4. Verde commitado → 5. Polish/CONVERGE (README, lista fechada, 9/9).

### Rejeitado

Verde sem vermelho separado (M3-recorrente); ajuste de fronteira fora da Fase C ou além dos 5 pontos (A1-recorrente); `git add` de isca no repo real (Lei Zero: isca só em cópia descartável, `trap` de remoção).

---

## Phase 7: Convergence (converge skill, 2026-09-04)

**Purpose**: fechar os 2 gaps parciais restantes; nada aqui reabre escopo.

- [x] T034 [US3] Provar recusa de `min_version`: baixar `lefthook_2.1.11_Linux_x86_64.gz` em /tmp, conferir sha256 `435aff51fc767a7f135717a4e3e4f3282c15e0a4ca4e2dfd1b54ef8241ee5f3f` (research Q3), executar o binário 2.1.11 contra `lefthook.yml` (`min_version: 2.1.12`), confirmar recusa com erro de versão, preservar saída em `specs/009-lefthook/evidence/min_version_refusal.txt`, limpar /tmp (US3/AC2, FR-001) (partial)
- [x] T035 Medir `time uv run lefthook run pre-commit` (repo verde) e registrar wall time em `specs/009-lefthook/evidence/latencia.txt` com data e carga (`uptime`), sem teto inventado — calibragem por medição (SC-006) (partial)
