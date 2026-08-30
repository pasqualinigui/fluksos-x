---
description: "Task list for 004 — UV workspace monorepo — base física do motor"
---

# Tasks: UV workspace monorepo — base física do motor

**Input**: Design documents from `/specs/004-uv-workspace/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md` (D1–D10), `data-model.md` (5 entidades), `contracts/workspace-contract.md` (7 seções), `quickstart.md` (6 cenários)

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (Princípio III, SC-006). A prova é o oráculo `scripts/verify/f0-004-uv-workspace.sh` executado e preservado **antes** da implementação (🔴) e **depois** (🟢) — não recuperável depois. TDD é harness TDD: o oráculo é o teste.

**Artefatos deste item**: três arquivos versionados (`pyproject.toml`, `uv.lock`, `.python-version`), um diretório efêmero (`.venv/` com `.venv/.gitignore:*`), um oráculo (`scripts/verify/f0-004-uv-workspace.sh`), uma linha em `scripts/verify/README.md`, diretório `specs/004-uv-workspace/evidence/`. Nenhum `packages/`, nenhuma tool de 005–016.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência
- **[Story]**: `US1`/`US2`/`US3` conforme `spec.md` (P1/P2/P3)
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. Este item **não produz código de aplicação** — produz infra de workspace (`pyproject.toml`/`uv.lock`/`.venv`/`.python-version`) e a quarta peça do harness (`scripts/verify/`).

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena por prioridade P1→P3 com tasks de cada história antes da próxima. **Este arquivo não segue essa ordem** por imposição normativa:

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 (P1) primeiro | **Oracle completo (US1+US2+US3) primeiro** | O oráculo precisa existir e **reprovar** cobrindo os 17 FRs antes de qualquer `pyproject.toml`. Sem cobertura total, o vermelho seria parcial e o verde subsequente não prova TDD (Princípio III, SC-006) |
| Workspace por história | **Workspace único após vermelho** | `pyproject.toml`/`uv.lock`/`.venv` são artefatos únicos — dividi-los por história criaria colisão de escrita e reescrita. A criação é aditiva e única (FR-001..009) |
| US2/US3 após US1 | **US2/US3 verificação após workspace** | Depois do workspace verde, US2/US3 não mutam arquivo produtivo; apenas inspeção estática adicional (globs, Lei Zero, fronteira) — independência lógica preservada sem colisão |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T015 (vermelho) antes de T016** — criar `pyproject.toml` antes de registrar o vermelho satisfaz todos os FR e ainda assim falha `SC-006`/Princípio III de forma irrecuperável (plan.md Fase B › *"Pular esta fase satisfaz os arquivos e ainda assim falha"*).
2. **T004 antes de T005–T014** — esqueleto do contrato `oracle-cli.md` (exit 0/1/2, --quiet/--list, determinismo, somente leitura) é pré-requisito de qualquer asserção nos grupos.
3. **T026 (verde) após T016–T018** — o verde só é verde depois da última mutação (workspace + README). Verde antes disso mede estado incompleto.

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 | T001–T003 | — (bloqueante) |
| Fase B — Oráculo em reprovação 🔴 | Phase 2 + Phase 3 | T004–T015 | US1+US2+US3 (oracle) |
| Fase C — Workspace verde 🟢 | Phase 4 | T016–T019 | US1 (MVP) |
| Fase D — Verde e convergência local | Phase 5 + Phase 6 + Phase 7 | T020–T029 | US2, US3, Polish |
| Fase E — Entrega remota (pós-merge) | Phase 7 (T030) | T030 | — (SC-007 remoto) |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar que o harness que o workspace vai sustentar está verde e que os artefatos-alvo ainda não existem; preparar evidências.

- [x] T001 Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` — deve sair `0` com `f0-001` (30/30) e `f0-003` (14/14). Se falhar, corrigir antes de prosseguir (plan.md Fase A:1, VI)
- [x] T002 Confirmar ausência de `pyproject.toml`, `uv.lock`, `.python-version`, `packages/`, `.venv/` (`ls pyproject.toml uv.lock .python-version` deve falhar, `test ! -d packages && test ! -d .venv`) e que `docs/plan/research/f0-004-uv-workspace.md` (381 linhas, Q1–Q10 D1–D10) e `.gitignore` (265 linhas, sem `*.lock`) existem — registra fronteira FR-001/006/013 (plan.md Fase A:2)
- [x] T003 Criar diretório de evidências `specs/004-uv-workspace/evidence/` (`mkdir -p specs/004-uv-workspace/evidence`) para `red.txt` e `green.txt` (Princípio III, plan.md Fase B:3 / Fase D:1)

**Checkpoint**: pré-requisitos satisfeitos — oráculo anterior íntegro, alvo inexistente, evidências endereçáveis.

---

## Phase 2: Foundational (Esqueleto do oráculo) ⚠️ BLOQUEANTE

**Purpose**: criar o invólucro que todo FR vai usar. **Nenhuma asserção de Phase 3 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: este esqueleto implementa o contrato `specs/001-git-branching-strategy/contracts/oracle-cli.md` herdado via `contracts/workspace-contract.md` §7 e `scripts/verify/README.md`. Sem ele, `--list`/`--quiet`/códigos não são decidíveis.

- [x] T004 [US1+US2+US3] Criar `scripts/verify/f0-004-uv-workspace.sh` com esqueleto do contrato herdado: parsing de `--quiet` e `--list`, resolução da raiz pela localização do script (`SCRIPT_DIR`/`REPO_ROOT`, nunca `$PWD`), códigos `0` conforme / `1` não conforme / `2` erro de uso, formato `<emoji> FR-XXX <descrição>` uma linha por REQ-ID, linha de resultado final `X/Y passed`, mapa canônico único de descrições, guarda de recursão `FKX_ORACLE_NESTED`, sem efeitos além de stdout/stderr (FR-016, contrato oracle-cli §1–§3, data-model.md Entidade Workspace root)

**Checkpoint**: foundation ready — asserções de história podem ser acrescentadas sem recriar contrato.

---

## Phase 3: Oracle completo — 10–14 asserções + vermelho 🔴 (US1+US2+US3)

**Goal**: oráculo que responda por código de saída cobrindo **todos** os FR-001..017 antes de existir qualquer coisa para aprovar. É a única prova auditável de test-first.

**Independent Test**: executar em estado com `pyproject.toml`/`uv.lock` inexistentes → `exit 1` com reprovação nominal por FR; executar duas vezes → saída idêntica; `--list` enumera 10–14 IDs sem executar.

### Implementation por grupo (mesmo arquivo, sequencial — não paralelizável)

- [x] T005 [US1] Implementar em `scripts/verify/f0-004-uv-workspace.sh` **Grupo FR-001/002/003/004** — `pyproject.toml` existe, `python3 -c 'import tomllib'` TOML válido, `project.name=="fluksos-x"` / `version=="0.1.0"` / `requires-python==">=3.12,<3.14"` / `build-system.requires==["uv_build>=0.12.7,<0.13"]` + `build-backend=="uv_build"` / `tool.uv.workspace.members==["packages/*"]` sem `exclude` (FR-001..004, D1/D4/D5, data-model Workspace root)
- [x] T006 [US1] Implementar **Grupo FR-005** — `.python-version` existe e `grep -Eq '^3\.12(\.[0-9]+)?$'` passa (FR-005, D5, data-model .python-version)
- [x] T007 [US1] Implementar **Grupo FR-006/007** — `uv.lock` existe, `tomllib` válido, `! git check-ignore -q` já será US3 mas existência aqui; quando `uv` disponível, `uv lock --check` passa se não editado manualmente (FR-006/007, D2, data-model uv.lock)
- [x] T008 [US1] Implementar **Grupo FR-008/009** — `.venv` existe, `test -x .venv/bin/python` e `.venv/.gitignore` contém `*` (FR-008), descartabilidade: segundo `uv sync` hash idêntico documentado mas não assertado aqui antes de workspace existir (FR-009, D3/D10, data-model .venv)
- [x] T009 [US2] Implementar **Grupo FR-004/015** — workspace pronto para `packages/*`: `members==["packages/*"]` já coberto em T005, ausência de `tool.uv.sources` em 004, e que todo dir casado precisaria `pyproject.toml` (contrato futuro `workspace=true`) (FR-004/015, D4, data-model Member)
- [x] T010 [US2] Implementar **Grupo FR-017** — CI glob inclui `f0-004` sem editar `ci.yml`: `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` passa (FR-017, D8, plan.md Source Code)
- [x] T011 [US3] Implementar **Grupo FR-010/011/012** — Lei Zero e `.gitignore` intacto: `! grep -q '^\*.lock'` nem `uv.lock` em `.gitignore` (FR-010), `git check-ignore -q .venv` positivo e `! git check-ignore -q uv.lock` (FR-011), `git diff -- .gitignore` vazio (FR-012, D7, data-model regras cruzadas)
- [x] T012 [US3] Implementar **Grupo FR-013/014/015** — fronteira escada: `! test -d packages` (FR-013), `! grep -R 'ruff\|mypy\|pytest\|lefthook\|pip-audit\|trivy' pyproject.toml` / ausência de `[tool.ruff]`/`[tool.mypy]`/`[dependency-groups]` (FR-014), contrato `workspace=true` documentado (FR-015, D8)
- [x] T013 [US3] Implementar **Grupo meta — integridade harness herdado**: `f0-001-foundation.sh --quiet` e `f0-003-ci-minimo.sh --quiet` aprovam quando invocados pelo oráculo (não regressão, VI, SC-006) + determinismo interno (duas execuções idênticas, FR-016)
- [x] T014 [US3] Implementar **Grupo FR-016 self-check** — exit codes `0`/`1`/`2`, `--quiet` só violações, `--list` enumera 10–14 IDs sem executar, tempo <5s (FR-016, SC-006, oracle-cli)

### Captura do vermelho (não recuperável)

- [x] T015 🔴 **Executar** `scripts/verify/f0-004-uv-workspace.sh` e `scripts/verify/f0-004-uv-workspace.sh --quiet` e preservar saída íntegra em `specs/004-uv-workspace/evidence/red.txt`. Esperado `exit=1` com reprovação em massa (FR-001 base — `pyproject.toml` inexistente) e `FR-006` por ausência de `uv.lock`. Conferir `--list` enumera 10–14 IDs sem executar. Este `red.txt` é a prova de TDD — se não existir antes de T016, o par vermelho→verde é irrecuperável (Princípio III, SC-006, plan.md Fase B:3)

**Checkpoint**: existe oráculo completo e existe prova registrada de que ele reprova. A partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Ambiente reprodutível com um comando (Priority: P1) 🎯 MVP

**Goal**: clone limpo obtém ambiente funcional idêntico com `uv sync`, `.venv` sem ativação manual, idempotência de `uv.lock`.

**Independent Test**: `quickstart.md` Cenário 1 + 2 + 3 (SC-001/SC-002/SC-003): `uv sync` → `.venv/bin/python` `3.12.x`, `uv.lock` TOML válido, segundo `uv sync` hash idêntico, `rm -rf .venv && uv sync` recria sem alterar lock e sem `git status` listar `.venv`

- [x] T016 [US1] Materializar workspace **via `uv`** (D1/D5): `uv init --name fluksos-x --bare --python 3.12` (ou fallback `python3 -c` escrevendo TOML) e ajustar `pyproject.toml` para root virtual conforme `contracts/workspace-contract.md` §1 — `[project] name="fluksos-x" version="0.1.0" requires-python=">=3.12,<3.14" dependencies=[]` + `[build-system] requires=["uv_build>=0.12.7,<0.13"] build-backend="uv_build"` + `[tool.uv.workspace] members=["packages/*"]` — remover `src/` se criado por `uv init`, garantir TOML válido via `python3 -c 'import tomllib'` (FR-001..004)
- [x] T017 [US1] Gerar `uv.lock` + `.venv` + `.python-version`: `uv sync` (sem `--locked`/`--frozen` em 004, D6) — gera `uv.lock` TOML válido universal, `.venv/bin/python` executável `3.12.x`, `.venv/.gitignore:*`, `.python-version:3.12` (FR-005..008). Fallback sem `uv`: escrever `uv.lock` TOML vazio válido + `.python-version 3.12` + `.venv` mínimo com `bin/python` stub + `.venv/.gitignore:*`
- [x] T018 [US1] Validar TOML estático: `python3 -c 'import tomllib; tomllib.load(open("pyproject.toml","rb")); tomllib.load(open("uv.lock","rb"))'` + `grep -Eq '^3\.12' .python-version` (FR-001/006/005, quickstart Cenário 1)
- [x] T019 [US1] Atualizar `scripts/verify/README.md` tabela — nova linha `f0-004-uv-workspace.sh | 10–14 | UV workspace — base física (pyproject.toml + uv.lock + .venv + .python-version)` — conforme `plan.md` Fase C:4 e contrato de crescimento do harness (ADR-002)

**Checkpoint**: MVP entregue — `uv sync` em clone limpo entrega `.venv` funcional; sem este checkpoint, US2/US3 não têm sobre o que verificar descoberta/Lei Zero.

---

## Phase 5: User Story 2 — Workspace pronto para `packages/*` sem fricção (Priority: P2)

**Goal**: glob `packages/*` descobre membros automaticamente e compartilha `uv.lock`+`.venv` sem editar root.

**Independent Test**: `quickstart.md` Cenário 4 (SC-004): inspeção estática `members==["packages/*"]` + probe `packages/_probe` descoberto por `uv sync` sem editar root, depois removido

- [x] T020 [P] [US2] Verificar `tool.uv.workspace` via inspeção estática `quickstart.md` Cenário 4: `python3 -c 'import tomllib; assert tomllib.load(open("pyproject.toml","rb"))["tool"]["uv"]["workspace"]["members"]==["packages/*"]'` e ausência de `exclude` (FR-004, D4, SC-004)
- [x] T021 [US2] Executar probe de escalabilidade `quickstart.md` Cenário 4: criar `packages/_probe/pyproject.toml` com `requires-python` compatível, `uv sync` descobre membro sem editar `pyproject.toml` root, verificar `uv.lock` ainda válido, remover `packages/_probe` e `uv sync` limpo (SC-004, FR-015, D4)
- [x] T022 [US2] Verificar CI glob pós-workspace: `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` ainda passa e `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` inclui `f0-004` (FR-017, SC-007)

---

## Phase 6: User Story 3 — Cadeia de suprimentos versionada e Lei Zero preservada (Priority: P3)

**Goal**: trava auditável, nenhum artefato efêmero no histórico, `.gitignore` intacto, fronteira escada preservada.

**Independent Test**: `quickstart.md` Cenário 5 (SC-005/SC-008): `! grep` `*.lock` em `.gitignore`, `check-ignore` positivo para `.venv` e negativo para `uv.lock`, `! test -d packages` e ausência de ruff/mypy

- [x] T023 [P] [US3] Verificar Lei Zero via `quickstart.md` Cenário 5: `! grep -q '^\*.lock' .gitignore && ! grep -q '^uv.lock' .gitignore` (FR-010), `git check-ignore -q .venv && ! git check-ignore -q uv.lock` (FR-011), `git diff -- .gitignore` vazio (FR-012, D7, SC-005)
- [x] T024 [P] [US3] Verificar fronteira via `quickstart.md` Cenário 5: `! test -d packages` (FR-013), `! grep -R 'ruff\|mypy\|pytest\|lefthook\|pip-audit\|trivy' pyproject.toml` e `! test -f ruff.toml && ! test -f mypy.ini && ! test -f lefthook.yml` (FR-014), `tool.uv.sources` ausente em 004 mas documentado como `{ workspace = true }` (FR-015, SC-008)
- [x] T025 [US3] Verificar idempotência e descartabilidade remanescente: `sha256sum uv.lock > /tmp/b && uv sync && sha256sum uv.lock > /tmp/a && diff /tmp/b /tmp/a` (SC-002) + `rm -rf .venv && uv sync && test -x .venv/bin/python && ! git check-ignore -q uv.lock` (SC-003, FR-009)

---

## Phase 7: Polish & Convergência 🟢

**Purpose**: fechar ciclo vermelho→verde, provar determinismo e registrar o que a máquina não decide.

- [x] T026 🟢 Executar `scripts/verify/f0-004-uv-workspace.sh` e `scripts/verify/f0-004-uv-workspace.sh --quiet` e preservar saída íntegra em `specs/004-uv-workspace/evidence/green.txt`. Esperado `exit=0` com **10–14/10–14** aprovadas (SC-006, plan.md Fase D:1)
- [x] T027 Executar `quickstart.md` validação determinismo: `scripts/verify/f0-004-uv-workspace.sh > /tmp/r1.txt 2>&1` vs `/tmp/r2.txt` diff idêntico + `git status --porcelain` limpo exceto artefatos deste item (`pyproject.toml`, `uv.lock`, `.python-version`, `scripts/verify/f0-004-uv-workspace.sh`, `scripts/verify/README.md`, `specs/004-uv-workspace/evidence/`) e `.venv/` não listado (FR-009, plan.md Fase D:4)
- [x] T028 Executar harness acumulado conforme contrato local e remoto: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0`; cada oráculo <5s (FR-016, plan.md Fase D:6, SC-006 agregada)
- [x] T029 Executar `quickstart.md` validação completa em um comando (Cenário 1+2+3+4+5) — todos `OK` = contrato `contracts/workspace-contract.md` §7 satisfeito (SC-001..008)
- [x] T030 Registrar ciclo em commits separados vermelho→verde obedecendo `CONTRIBUTING.md` §1 (`^(feat|fix|docs|chore|refactor)(\(.+\))?: .+`): commit 🔴 com oracle + `red.txt`, commit 🟢 com `pyproject.toml`+`uv.lock`+`.python-version`+`.venv`+`README.md`+`green.txt` — par auditável (Princípio III, plan.md Fase D:7)
- [x] T031 [P] Anotar em `specs/004-uv-workspace/quickstart.md` ou `plan.md` Fase E que **Cenário 6 (SC-007 remoto)** — push conforme verde + PR com violação vermelho — só é observável após push/PR real em `main`/`develop` e fica deferido pós-merge (não bloqueia convergência local, mas é o único SC que exige GitHub, plan.md Fase E)

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
Phase 4 (T016–T019)              US1 — workspace verde (MVP) 🟢
   ↓
Phase 5 (T020–T022)              US2 — descoberta e CI glob (verificação estática)
   ↓
Phase 6 (T023–T025)              US3 — Lei Zero e fronteira (verificação estática)
   ↓
Phase 7 (T026–T031)              Polish & Convergência (verde + determinismo + harness acumulado)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T004 | T001, T002 | harness íntegro + alvo inexistente são pré-condição do contrato |
| T005–T014 | T004 | asserções exigem esqueleto `oracle-cli` (exit/flags/determinismo) |
| T015 | T005–T014 | vermelho só é prova se oráculo cobrir os 17 FRs |
| T016 | **T015** | criar `pyproject.toml` antes do vermelho falha SC-006 de forma irrecuperável |
| T017–T019 | T016 | `uv.lock`/`.venv`/`.python-version` e README só fazem sentido com `pyproject.toml` em disco |
| T020–T025 | T016 | pins/fronteira/Lei Zero são verificados sobre `pyproject.toml`/`uv.lock` existentes |
| T026 | T016–T018 | verde só é verde após última mutação (workspace + README) |
| T030 | T026 | commits só após verde medido |

### Oportunidades reais de paralelismo

**Três oportunidades reais**, cobrindo 5 tarefas, verificadas quanto a colisão de arquivo:

- **T020, T023, T024** — inspeções `grep`/`tomllib`/`git check-ignore` somente leitura sobre `pyproject.toml`/`uv.lock`/`.gitignore`, arquivos de saída distintos (`/tmp/*`) — paralelizáveis entre si (`[P]`).
- **T025** — `sha256sum` idempotência + descartabilidade — leitura de `uv.lock` e recriação de `.venv` (depende de T016, mas paralelizável com T023/T024 em leitura de lock).
- **T031** — anotação deferida de Cenário 6, não toca `pyproject.toml` nem oracle após verde.

As demais tarefas **não** são paralelizáveis: T005–T014 editam o mesmo `f0-004-uv-workspace.sh`, T016–T018 tocam `pyproject.toml`/`uv.lock`/`README.md` sequencialmente, T015/T026 escrevem `evidence/` ordenadamente. Marcá-las `[P]` criaria colisão real.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T019). Entrega **ambiente reprodutível com um comando** — a base física. Sem ela, sete pacotes e cinco ferramentas de qualidade validariam sobre ambiente divergente. US2/US3 agregam confiança mas o MVP já materializa lock+venv determinísticos.

### Entrega incremental

1. Phases 1–2 → pré-requisitos + esqueleto (remoção segura futura)
2. Phase 3 → 🔴 vermelho preservado (prova de test-first garantida)
3. Phase 4 → **workspace verde** — `.venv` reprodutível existe (MVP)
4. Phases 5–6 → descoberta `packages/*` e Lei Zero verificadas — workspace é pnpm-like, não só `pyproject.toml`
5. Phase 7 → 🟢 verde, determinismo, harness acumulado, commits auditáveis

### Critério de conclusão do item

| Condição | Verificação | SC |
|---|---|---|
| `pyproject.toml` TOML válido, `name`/`version`/`requires-python`/`build-system`/`members` | T018 + T005 | SC-001 |
| `uv.lock` TOML válido, versionado | T018 + T023 | SC-005 |
| `.venv/bin/python` `3.12.x`, `.venv/.gitignore:*`, `check-ignore` positivo | T017 + T023 | SC-001/SC-003 |
| Segundo `uv sync` hash idêntico | T025 | SC-002 |
| `rm -rf .venv && uv sync` recria sem alterar lock | T025 | SC-003 |
| `packages/_probe` descoberto sem editar root | T021 | SC-004 |
| `.gitignore` sem `*.lock`, `uv.lock` não ignorado, diff vazio | T023 | SC-005 |
| Harness 10–14 `exit 0`, re-run idêntico, <5s | T026 + T027 | SC-006 |
| CI `003` inclui `f0-004` via glob | T022 | SC-007 |
| Sem `packages/` nem ruff/mypy em 004 | T024 | SC-008 |
| 10–14/10–14 `exit 0`, par vermelho→verde distinto | T015 + T026 | FR-016 análogo |
| Harness acumulado <5s por oráculo, `git status` limpo | T027/T028 | FR-016 |
| Commits separados vermelho→verde em Conventional Commits | T030 | Princípio III |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **5** das 31 tarefas, deliberadamente — este item edita `f0-004-uv-workspace.sh` e `pyproject.toml` muitas vezes sequencialmente.
- Cada tarefa cita o FR/SC que a origina, para que qualquer linha do oráculo seja rastreável até `spec.md` sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits **separados**: é a prova auditável de que o teste veio primeiro, e ela não é recuperável depois (plan.md Fase B › *"A única prova auditável"*).
- T031 é deferido remoto — não bloqueia `T026` verde local, mas SC-007 só fecha após observação em GitHub (plan.md Fase E).
- Nenhuma tarefa introduz `ruff`/`mypy`/`pytest`/`pip-audit`/`trivy`/`lefthook` — violaria FR-014 e escada de dependências (constitution Additional Constraints).

