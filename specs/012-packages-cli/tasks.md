---
description: "Task list for 012 — packages/cli — entry point fkx"
---

# Tasks: `packages/cli` — entry point `fkx`

**Input**: Design documents from `/specs/012-packages-cli/`
**Prerequisites**: `plan.md` (required), `spec.md` (required, US1 P1/US2 P2/US3 P3), `research.md` (5 decisões), `data-model.md` (App + Version + CliFault + superfície), `contracts/oracle-cli.md` (mapa identidade FR-001..012), `quickstart.md` (5 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-005, FR-012) — segundo pacote de produção sob TDD real. A prova é `f0-012-cli.sh` 12 asserções reprovando (🔴) e aprovando (🟢) em **commits separados** + `pytest` TDD via `CliRunner` em `tests/test_fkx_cli_*.py`. Exceção M3 não se estende.

**Artefatos deste item**: `packages/cli/pyproject.toml` (membro, runtime typer+rich, dep fkx-core, `[project.scripts] fkx`), `packages/cli/src/fkx_cli/` (`__init__.py`, `main.py`, `py.typed` — nada além), `tests/test_fkx_cli_*.py`, `scripts/verify/f0-012-cli.sh` (12 asserções), `scripts/verify/manifest.sha256` 12 linhas, `specs/README.md` índice `012 ✅` + hash. Ajustes de fronteira `packages/cli` (004/005/006/007/008/011) **somente** via ADR prévia na Fase C (molde ADR-018/021/022/023). Nenhum subcomando de domínio, TUI, `.env` real, release.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

`packages/cli/` pacote `src/` membro do workspace (`members = ["packages/*"]`). Testes em `tests/` raiz (contrato 005, sem novo diretório). Oráculo em `scripts/verify/f0-012-cli.sh` segue ADR-002/015.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa (mesma razão de `007`–`011`):

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 primeiro | **Oráculo completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo FR-001..012 antes de `packages/cli/` existir. Sem cobertura total, o vermelho seria parcial e o verde não prova TDD (III, SC-005, FR-012) |
| Código por história | **Testes antes do código por história (TDD intra-história)** | Segundo pacote de produção: cada comportamento nasce de teste que reprova (T014→T015, T017→T018, T019→T020) |
| US2/US3 após US1 | **US2/US3 implementação após verde parcial US1** | Depois do MVP, sem mutação além dos módulos + testes |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T012 (vermelho) antes de T013** — criar `packages/cli/` antes do vermelho satisfaz FRs e ainda assim falha SC-005/Princípio III de forma irrecuperável (plan.md Fase B).
2. **T004 antes de T005–T011** — esqueleto `oracle-cli.md` (exit 0/1/2, --quiet/--list, CANON 12 FRs, FKX_ORACLE_NESTED, determinismo 2×) é pré-requisito de qualquer asserção.
3. **T022 (verde) após T013–T020** — verde só é verde depois da última mutação (código + testes + manifest + ADR de fronteira). Ajustes 004–008/011 **só** na Fase C via ADR prévia.

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo 🔴 | Phase 2 + Phase 3 | T004–T012 | US1+US2+US3 (oracle) |
| Fase C — CLI verde 🟢 | Phase 4 + Phase 5 + Phase 6 | T013–T020 | US1 (MVP) + US2 + US3 |
| Fase D — Verde e convergência | Phase 7 | T021–T026 | Polish/CONVERGE |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness herdado (011) está verde e que `packages/cli/` ainda não existe; preparar evidências.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` 11/11 + `sha256sum -c scripts/verify/manifest.sha256` 11/11 SUCESSO. Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausências de fronteira: `! test -d packages/cli`, `! test -f scripts/verify/f0-012-cli.sh`, `! test -f .env`, e que `docs/plan/research/f0-012-packages-cli.md` existe — registra fronteira FR-002 (plan.md Fase A)
- [x] T003 Criar `specs/012-packages-cli/evidence/` para `red.txt`/`green.txt` (Princípio III, plan.md Fase A:2)

---

## Phase 2: Foundational — esqueleto do oráculo (blocking)

**Purpose**: contrato de interface executável antes de qualquer asserção (T004 bloqueia T005–T011).

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-012-cli.sh` com esqueleto do contrato herdado: parsing `--quiet`/`--list`, raiz pela localização do script (nunca `$PWD`), códigos 0/1/2, formato `<emoji> FR-XXX <descrição>`, linha de resultado final, mapa CANON com as 12 descrições FR-001..012 de `contracts/oracle-cli.md` §3, guarda `FKX_ORACLE_NESTED`, cabeçalho comentando FRs guardas × comportamento, sem efeitos além de stdout/stderr, medição de exit code via redirect + `$?` (nunca após pipe — research Q4), import sem I/O como asserção permitida (FR-010, contrato §1)
- [x] T005 Acrescer 12ª linha ao `scripts/verify/manifest.sha256` (hash do esqueleto — será regenerada no verde; acréscimo permitido por ADR-015a, nunca reescrita de valor alheio)
- [x] T006 [P] Implementar asserts auto-verificáveis do oráculo em `scripts/verify/f0-012-cli.sh`: `--list` enumera 12 IDs do CANON, `--invalido` sai 2, 2 execuções byte-idênticas e cada uma <5s (FR-010/SC-006, contrato §1; `[P]` vale contra T005 — arquivo distinto — nunca contra T007–T011, mesmo arquivo)

**Checkpoint**: esqueleto executável — `f0-012 --list` lista 12 FRs; asserções ainda ausentes.

---

## Phase 3: User Stories US1+US2+US3 — asserções do oráculo 🔴 (Priority: todas)

**Goal**: cobertura total FR-001..012 reprovando sobre repo sem `packages/cli/`.

**Independent Test**: `scripts/verify/f0-012-cli.sh` → vermelhas de comportamento + guardas verdes; `evidence/red.txt` preserva a saída.

- [x] T007 [US1] Implementar em `scripts/verify/f0-012-cli.sh` **Grupo FR-001/002** — `typer==0.27.2` + `rich==15.0.0` runtime em `packages/cli` + hash `uv.lock` + ausência de `click` declarado; membro UV + exatamente `__init__.py`, `main.py`, `py.typed` + `[project.scripts] fkx` (FR-001/002, research D1/D4)
- [x] T008 [US1+US2] Implementar em `scripts/verify/f0-012-cli.sh` **Grupo FR-003/004** — `fkx --help` exit 0 com marcadores + sem-args ≡ ajuda exit 0; `fkx --version` exit 0 só `X.Y.Z` == declarada; medição sem pipe (FR-003/004, CLARIFY 2026-09-05)
- [x] T009 [US3] Implementar em `scripts/verify/f0-012-cli.sh` **Grupo FR-005/006** — opção inválida exit 2 + stderr com dica; dep membro `fkx-core` sem duplicação; domínio → saída nomeada exit 1 (FR-005/006, research D5)
- [x] T010 [US1+US2+US3] Implementar em `scripts/verify/f0-012-cli.sh` **Grupo FR-007/008** — `ruff` + `mypy --strict` zeros sobre `src/fkx_cli/`; testes em `tests/test_fkx_cli_*.py` verdes (FR-007/008)
- [x] T011 Implementar em `scripts/verify/f0-012-cli.sh` **Grupo FR-009/010/011/012** — zero segredo + `escape` + locals off (com guarda anti-vácuo: a asserção FR-009 reprova se `src/fkx_cli/` ausente); contrato + self próprio + manifest 12/12 + self-check `f0-001…f0-011` + README `012 ✅`+hash + tasks zero + vermelho-antes-do-verde (FR-009/010/011/012)
- [x] T012 **VERMELHO** — executar `scripts/verify/f0-012-cli.sh`, preservar saída em `specs/012-packages-cli/evidence/red.txt` (+ `--quiet`), confirmar vermelhas de comportamento (FR-001..009/012) + guardas verdes (FR-010/011), e commitar `test(harness)` **separado**: `test(harness): registra o portao vermelho do item 012 — packages-cli` (plan.md Fase B; restrição 1 acima)

**Checkpoint**: vermelho preservado em commit próprio — qualquer mutação de `packages/cli/` sem verde subsequente é defeito irrecuperável.

---

## Phase 4: User Story 1 — Ajuda instalável (Priority: P1) 🎯 MVP

**Goal**: `fkx --help` e `fkx` sem args com exit 0 e marcadores; entry point instalado.

**Independent Test**: quickstart Cenário 1 (help, sem-args, `--nope` → exit 2 medido sem pipe).

- [x] T013 [US1] Adicionar `typer==0.27.2` + `rich==15.0.0` como runtime de `packages/cli/pyproject.toml` (membro, `[project.scripts] fkx = "fkx_cli.main:app"`) + `uv sync --frozen --all-packages` (hash em `uv.lock`; sync puro é armadilha ADR-023) (FR-001/002, research D1/D4)
- [x] T014 [P] [US1] Escrever testes `tests/test_fkx_cli_help.py` (help exit 0 + marcadores, sem-args ≡ help, `--nope` exit 2 + dica) via `CliRunner` — REPROVANDO sem o módulo (TDD)
- [x] T015 [US1] Implementar `packages/cli/src/fkx_cli/main.py` (callback-raiz `app`, `add_completion=False`, `pretty_exceptions_show_locals=False`) + `__init__.py` (exporta `app`) + `py.typed` vazio até T014 passar (FR-002/003/005, data-model App)

**Checkpoint**: US1 funcional e testável independentemente (MVP do item).

---

## Phase 5: User Story 2 — Versão consultável (Priority: P2)

**Goal**: `fkx --version` imprime só o número declarado, exit 0.

**Independent Test**: quickstart Cenário 2 (valor == `version` do membro, sync canônico).

- [x] T016 [P] [US2] Escrever testes `tests/test_fkx_cli_version.py` (exit 0, só `X.Y.Z`, igual à declarada) — REPROVANDO sem a flag (TDD)
- [x] T017 [US2] Implementar callback `--version` em `packages/cli/src/fkx_cli/main.py` via `importlib.metadata.version("fkx-cli")` (fonte única `[project].version`, sem `__version__` duplicado) até T016 passar (FR-004, data-model Version)

---

## Phase 6: User Story 3 — Erro nomeado (Priority: P3)

**Goal**: domínio vira saída nomeada exit 1; zero `except:` nu; zero segredo.

**Independent Test**: quickstart Cenário 3 (greps zerados; domínio → 1).

- [x] T018 [P] [US3] Escrever testes `tests/test_fkx_cli_errors.py` (domínio → exit 1 + causa nomeada; `escape()` em markup dinâmico; callbacks anotados) — REPROVANDO sem o mapeamento (TDD)
- [x] T019 [US3] Implementar mapeamento `FkxError` → `CliFault(exit 1)` em `packages/cli/src/fkx_cli/main.py` com `escape()` em dado dinâmico até T018 passar (FR-006/009, data-model CliFault)
- [x] T020 [US1+US2+US3] Fechar `packages/cli/src/fkx_cli/__init__.py` (superfície: `app`) e revisar `packages/cli/src/fkx_cli/main.py` (zero `except:` nu, callbacks tipados) (FR-002/007, data-model Superfície)

---

## Phase 7: Verde e convergência (Final Phase)

**Purpose**: oráculo verde, fronteira admitida via ADR prévia, lista fechada.

- [x] T021 **ADR PRÉVIA** — redigir a próxima ADR livre (descobrir o número com `grep ^## ADR- docs/plan/decisions.md` antes de redigir) em `docs/plan/decisions.md` (molde ADR-018/021/022/023): admitir `packages/cli/` com `pyproject.toml` de membro nos oráculos 004 (FR-012), 005 (FR-015), 006 (FR-014), 007 (FR-014), 008 (FR-013) que asserem `packages/` só-com-`core/`, e em 011 (FR-002) que assere `cli/` ausente (jurisdição da 012; resto proibido; legitimidade via `uv.lock`); forma exata dos diffs; aplicação SÓ em T022. Sem esta ADR, T022 não executa (plan.md Fase C + restrição 3)
- [x] T022 **VERDE** — cadeia `ruff`/`mypy`/`pytest` zeros + `scripts/verify/f0-012-cli.sh` rumo a 12/12 + ADR de fronteira aplicada SÓ agora + manifest 12/12 + preservar `evidence/green.txt` + commitar `feat(packages)` **separado** do T012: `feat(packages): packages cli entry point (012)` (plan.md Fase C/D)
- [x] T023 `specs/README.md` `012 ✅` + hash do commit T022 (inquebrável FR-011; quickstart Cenário 5)
- [x] T024 Re-executar harness 12/12 + manifest 12/12 + quickstart "validação completa em um comando" (quickstart Cenário 5)
- [x] T025 Confirmar `tasks.md` zero `^- [ ]` + `git log` com vermelho-antes-do-verde + AGENTS.md rolado (011→012, harness 12/12, próximo 013)
- [x] T026 [P] Troubleshooting do `specs/012-packages-cli/quickstart.md` (sync sem `--all-packages`, callback sem anotação, help sem Rich) + commit de convergência `docs(specs)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — começa imediato; T001 verde é portão (VI).
- **Foundational+Oracle (Phase 2+3)**: dependem do Setup; T004 bloqueia T005–T011; T012 fecha o vermelho.
- **Green (Phase 4+5+6)**: dependem do vermelho commitado (T012); dentro de cada US, teste antes do código (T014<T015, T016<T017, T018<T019).
- **Verde final (Phase 7)**: depende de todos os módulos + testes; T022 aplica ADR de fronteira; T023–T026 fecham.

### Within Each Phase

- Oráculo antes do que ele mede (T004–T012 antes de T013).
- Teste antes do código por história (TDD intra-história).
- `uv.lock` antes do que o referencia (T013 antes de T014+).
- README/hash (T023) após o commit verde (hash só existe depois).

### Parallel Opportunities

- [P] T006, T014, T016, T018, T026 (arquivos distintos, sem dependência).
- US2/US3 testes (T016/T018) em paralelo entre si após T012; implementações convergem em T022.
- Vermelho (T012) e verde (T022) jamais em paralelo — ordem temporal é a prova (III).

---

## Parallel Example: Phase 6 tests

```bash
# T016 + T018 juntos (arquivos distintos):
Task: "Escrever testes tests/test_fkx_cli_version.py (TDD, reprovando)"
Task: "Escrever testes tests/test_fkx_cli_errors.py (TDD, reprovando)"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup (T001–T003) → 2. Phase 2+3 oráculo vermelho commitado (T004–T012) → 3. Phase 4 US1 (T013–T015) → **STOP e VALIDAR** `fkx --help` instalado.

### Incremental Delivery

1. Setup + oráculo vermelho → 2. US1 (MVP) → 3. US2 + US3 → 4. Verde + ADR fronteira → 5. Polish/CONVERGE (README, lista fechada, 12/12).

### Rejeitado

Verde sem vermelho separado (M3-recorrente); `packages/cli/` sem ADR prévia (fronteira-004–008/011); testes em `packages/cli/tests/` (contrato 005); teste via subprocesso instalado (acopla instalação ao unitário); grupo multi-comando vazio (CLARIFY: YAGNI); `__version__` estático (duas fontes); medição de exit após pipe (máscara).
