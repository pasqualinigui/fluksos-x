---
description: "Task list for 011 — packages/core — kernel do motor"
---

# Tasks: `packages/core` — kernel do motor

**Input**: Design documents from `/specs/011-packages-core/`
**Prerequisites**: `plan.md` (required), `spec.md` (required, US1 P1/US2 P2/US3 P3), `research.md` (4 decisões), `data-model.md` (4 entidades + superfície pública), `contracts/oracle-cli.md` (mapa identidade FR-001..012), `quickstart.md` (5 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-005, FR-012) — primeiro código de produção sob TDD real. A prova é `f0-011-core.sh` 12 asserções reprovando (🔴) e aprovando (🟢) em **commits separados** + `pytest` TDD por módulo em `tests/test_fkx_core_*.py`. Exceção M3 não se estende.

**Artefatos deste item**: `packages/core/pyproject.toml` (membro, runtime pydantic+settings), `packages/core/src/fkx_core/` (`__init__.py`, `config.py`, `state.py`, `models.py`, `exceptions.py` — nada além), `tests/test_fkx_core_*.py`, `.env.example` com as vars, `scripts/verify/f0-011-core.sh` (12 asserções), `scripts/verify/manifest.sha256` 11 linhas, `specs/README.md` índice `011 ✅` + hash. Ajustes de fronteira `packages/` (004–008) **somente** via ADR prévia na Fase C (molde ADR-018/021/022). Nenhum `packages/cli`, grafo, agente, `.env` real.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

`packages/core/` pacote `src/` membro do workspace (`members = ["packages/*"]`). Testes em `tests/` raiz (contrato 005, sem novo diretório). Oráculo em `scripts/verify/f0-011-core.sh` segue ADR-002/015.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `007`–`010`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oráculo completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..012 antes de `packages/` existir. Sem cobertura total, o vermelho seria parcial e o verde não prova TDD (III, SC-005, FR-012) |
| Código por história | **Testes antes do código por módulo (TDD intra-história)** | Primeiro código de produção: cada módulo nasce de teste que reprova (T015→T016, T018→T019, T020→T021, T022→T023) |
| US2/US3 após US1 | **US2/US3 implementação após verde parcial US1** | Depois do MVP, sem mutação além dos módulos + testes |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T013 (vermelho) antes de T014** — criar `packages/` antes do vermelho satisfaz FRs e ainda assim falha SC-005/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T012** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON 12 FRs, FKX_ORACLE_NESTED, determinismo 2×) é pré-requisito de qualquer asserção.
3. **T025 (verde) após T014–T023** — verde só é verde depois da última mutação (código + testes + manifest + ADR de fronteira). Ajustes 004–008 **só** na Fase C via ADR prévia.

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T013 | US1+US2+US3 (oracle) |
| Fase C — Core verde 🟢 | Phase 4 + Phase 5 + Phase 6 | T014–T026 | US1 (MVP) + US2 + US3/models |
| Fase D — Verde e convergência | Phase 7 | T026–T029 | Polish/CONVERGE |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (010) está verde e que `packages/` ainda não existe; preparar evidências.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` 10/10 + `sha256sum -c scripts/verify/manifest.sha256` 10/10 SUCESSO. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausências de fronteira: `! test -d packages`, `! test -f scripts/verify/f0-011-core.sh`, `! test -f .env`, e que `docs/plan/research/f0-011-packages-core.md` existe — registra fronteira FR-002/009 (plan.md Fase A)
- [x] T003 Criar `specs/011-packages-core/evidence/` para `red.txt`/`green.txt` (Princípio III, plan.md Fase A:2)

---

## Phase 2: Foundational — esqueleto do oráculo (blocking)

**Purpose**: contrato de interface executável antes de qualquer asserção (T004 bloqueia T005–T012).

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-011-core.sh` com esqueleto do contrato herdado: parsing `--quiet`/`--list`, raiz pela localização do script (nunca `$PWD`), códigos 0/1/2, formato `<emoji> FR-XXX <descrição>`, linha de resultado final, mapa CANON com as 12 descrições FR-001..012 de `contracts/oracle-cli.md` §3, guarda `FKX_ORACLE_NESTED`, cabeçalho comentando FRs guardas × comportamento, sem efeitos além de stdout/stderr, import sem I/O como asserção permitida (FR-010, contrato §1)
- [x] T005 Acrescer 11ª linha ao `scripts/verify/manifest.sha256` (hash do esqueleto — será regenerada no verde; acréscimo permitido por ADR-015a, nunca reescrita de valor alheio)
- [x] T006 [P] Implementar asserts auto-verificáveis do oráculo em `scripts/verify/f0-011-core.sh`: `--list` enumera 12 IDs do CANON, `--invalido` sai 2, 2 execuções byte-idênticas e cada uma <5s (FR-010/SC-006, contrato §1)

**Checkpoint**: esqueleto executável — `f0-011 --list` lista 12 FRs; asserções ainda ausentes.

---

## Phase 3: User Stories US1+US2+US3 — asserções do oráculo 🔴 (Priority: todas)

**Goal**: cobertura total FR-001..012 reprovando sobre repo sem `packages/`.

**Independent Test**: `scripts/verify/f0-011-core.sh` → vermelhas de comportamento + guardas verdes; `evidence/red.txt` preserva a saída.

- [x] T007 [US1] Implementar em `scripts/verify/f0-011-core.sh` **Grupo FR-001/002** — `pydantic==2.13.5` + `pydantic-settings==2.15.0` runtime em `packages/core` + hash `uv.lock`; membro UV + exatamente `__init__.py`, `config.py`, `state.py`, `models.py`, `exceptions.py` (FR-001/002, research D1/D5)
- [x] T008 [US1] Implementar **Grupo FR-003/009** — settings `FKX_` + `SecretStr` + `ConfigError` em var ausente; `.env.example` cobre vars; `.env` jamais versionado (FR-003/009, Lei Zero)
- [x] T009 [US2] Implementar **Grupo FR-004/005** — `TypedDict` + canais/reducers; sem Pydantic como state; modelos sem lógica (FR-004/005, research D3)
- [x] T010 [US3] Implementar **Grupo FR-006** — `FkxError` + 3; sem `except:` nu / `BaseException` (FR-006)
- [x] T011 [US1+US2+US3] Implementar **Grupo FR-007/008** — `ruff` + `mypy --strict` zeros sobre `src/fkx_core/`; testes em `tests/test_fkx_core_*.py` verdes (FR-007/008)
- [x] T012 Implementar **Grupo FR-010/011/012** — contrato + self próprio + manifest 11/11 + self-check `f0-001…f0-010` + README `011 ✅`+hash + tasks zero + vermelho-antes-do-verde (FR-010/011/012)
- [x] T013 **VERMELHO** — executar `scripts/verify/f0-011-core.sh`, preservar saída em `specs/011-packages-core/evidence/red.txt` (+ `--quiet`), confirmar 10 vermelhas de comportamento (FR-001..009/012) + 2 guardas verdes (FR-010/011), e commitar `test(harness)` **separado**: `test(harness): registra o portao vermelho do item 011 — packages-core` (plan.md Fase B; restrição 1 acima)

**Checkpoint**: vermelho preservado em commit próprio — qualquer mutação de `packages/` sem verde subsequente é defeito irrecuperável.

---

## Phase 4: User Story 1 — Config tipada (Priority: P1) 🎯 MVP

**Goal**: `load_settings()` de env limpo com tipos/defaults/máscara; `ConfigError` nomeado.

**Independent Test**: quickstart Cenário 1 (env limpo + `.env` descartável; remover obrigatória → `ConfigError`).

- [x] T014 [US1] Adicionar `pydantic==2.13.5` + `pydantic-settings==2.15.0` como runtime de `packages/core/pyproject.toml` (membro) + `uv sync` (hash em `uv.lock`) (FR-001, research D1)
- [x] T015 [P] [US1] Escrever testes `tests/test_fkx_core_config.py` (tipos, defaults, máscara `SecretStr`, var ausente → `ConfigError`) — REPROVANDO sem o módulo (TDD)
- [x] T016 [US1] Implementar `packages/core/src/fkx_core/config.py` + exportar em `__init__.py` até T015 passar (FR-003, data-model Settings)
- [x] T017 [US1] Estender `.env.example` com exatamente `FKX_ENV`, `FKX_LOG_LEVEL`, `FKX_API_SECRET` (template, nunca valor) (FR-009)

**Checkpoint**: US1 funcional e testável independentemente (MVP do item).

---

## Phase 5: User Story 2 — Estado tipado (Priority: P2)

**Goal**: `KernelState` mescla pelo reducer; `mypy --strict` aprova.

**Independent Test**: quickstart Cenário 2 (chaves + mesclagem + mypy 0).

- [x] T018 [P] [US2] Escrever testes `tests/test_fkx_core_state.py` (canais, mesclagem overwrite/acúmulo) — REPROVANDO sem o módulo (TDD)
- [x] T019 [US2] Implementar `packages/core/src/fkx_core/state.py` (`TypedDict` status/etapa/erros + reducer) até T018 passar (FR-004, data-model State)

---

## Phase 6: User Story 3 + models (Priority: P3)

**Goal**: erros nomeados + payloads validados + superfície pública fechada.

**Independent Test**: quickstart Cenário 3 (tipos exatos, zero `except:` nu).

- [x] T020 [P] [US3] Escrever testes `tests/test_fkx_core_errors.py` (tipos, mensagens contextuais, sem segredo) — REPROVANDO sem o módulo (TDD)
- [x] T021 [US3] Implementar `packages/core/src/fkx_core/exceptions.py` (`FkxError` + 3) até T020 passar (FR-006, data-model Errors)
- [x] T022 [P] [US1+US2] Escrever testes `tests/test_fkx_core_models.py` (validação, sem lógica) — REPROVANDO sem o módulo (TDD)
- [x] T023 [US1+US2] Implementar `packages/core/src/fkx_core/models.py` + fechar `__init__.py` (superfície: `load_settings`, `Settings`, `KernelState`, 4 erros) (FR-005, data-model Superfície)

---

## Phase 7: Verde e convergência (Final Phase)

**Purpose**: oráculo verde, fronteira admitida via ADR prévia, lista fechada.

- [x] T024 **ADR PRÉVIA** — redigir ADR-023 em `docs/plan/decisions.md` (molde ADR-018/021/022): admitir `packages/core/` com `pyproject.toml` de membro nos oráculos 004–008 que asserem `packages/` ausente (jurisdição da 011; resto proibido); forma exata dos diffs; aplicação SÓ em T025. Sem esta ADR, T025 não executa (plan.md Fase C + restrição 3)
- [x] T025 **VERDE** — cadeia `ruff`/`mypy`/`pytest` zeros + `scripts/verify/f0-011-core.sh` rumo a 12/12 + ADR-023 aplicada SÓ agora + manifest 11/11 + preservar `evidence/green.txt` + commitar `feat(packages)` **separado** do T013: `feat(packages): packages core kernel (011)` (plan.md Fase C/D)
- [x] T026 `specs/README.md` `011 ✅` + hash do commit T025 (inquebrável FR-011; quickstart Cenário 5)
- [x] T027 Re-executar harness 11/11 + manifest 11/11 + quickstart "validação completa em um comando" (quickstart Cenário 5)
- [x] T028 Confirmar `tasks.md` zero `^- [ ]` + `git log` com vermelho-antes-do-verde + AGENTS.md rolado (010→011, harness 11/11, próximo 012)
- [x] T029 [P] Troubleshooting do quickstart (import falha, mypy reclama, segredo em log) + commit de convergência `docs(specs)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — começa imediato; T001 verde é portão (VI).
- **Foundational+Oracle (Phase 2+3)**: dependem do Setup; T004 bloqueia T005–T012; T013 fecha o vermelho.
- **Green (Phase 4+5+6)**: dependem do vermelho commitado (T013); dentro de cada US, teste antes do código (T015<T016, T018<T019, T020<T021, T022<T023).
- **Verde final (Phase 7)**: depende de todos os módulos + testes; T025 aplica ADR de fronteira; T026–T029 fecham.

### Within Each Phase

- Oráculo antes do que ele mede (T004–T013 antes de T014).
- Teste antes do código por módulo (TDD intra-história).
- `uv.lock` antes do que o referencia (T014 antes de T015+).
- README/hash (T026) após o commit verde (hash só existe depois).

### Parallel Opportunities

- [P] T006, T015, T018, T020, T022, T029 (arquivos distintos, sem dependência).
- US2/US3 testes (T018/T020/T022) em paralelo entre si após T013; implementações convergem em T025.
- Vermelho (T013) e verde (T025) jamais em paralelo — ordem temporal é a prova (III).

---

## Parallel Example: Phase 6 tests

```bash
# T020 + T022 juntos (arquivos distintos):
Task: "Escrever testes tests/test_fkx_core_errors.py (TDD, reprovando)"
Task: "Escrever testes tests/test_fkx_core_models.py (TDD, reprovando)"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup (T001–T003) → 2. Phase 2+3 oráculo vermelho commitado (T004–T013) → 3. Phase 4 US1 (T014–T017) → **STOP e VALIDAR** settings de env limpo.

### Incremental Delivery

1. Setup + oráculo vermelho → 2. US1 (MVP) → 3. US2 + US3/models → 4. Verde + ADR fronteira → 5. Polish/CONVERGE (README, lista fechada, 11/11).

### Rejeitado

Verde sem vermelho separado (M3-recorrente); `packages/` sem ADR prévia (fronteira-004–008); testes em `packages/core/tests/` (contrato 005); Pydantic como state (performance); grafo/agentes/CLI neste item (Escada).
