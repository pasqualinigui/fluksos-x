# Implementation Plan: UV workspace monorepo — base física do motor

**Branch**: `004-uv-workspace` | **Date**: 2026-08-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-uv-workspace/spec.md`
**Pesquisa vinculante**: `docs/plan/research/f0-004-uv-workspace.md` (Q1–Q10, D1–D10, 2026-08-30, sem NEEDS CLARIFICATION)
**Constitution**: `.specify/memory/constitution.md` v1.0.0 (10 princípios I–X)

---

## Summary

Entregar a **base física do motor** (implementation_plan §§3,15,17 item 0.1, ordem 004/016 ADR-011): root virtual `pyproject.toml` (`name=fluksos-x`, `version=0.1.0`, `requires-python=">=3.12,<3.14"`, `build-system uv_build>=0.12.7,<0.13`, `tool.uv.workspace.members=["packages/*"]`) + `uv.lock` universal versionado + `.venv` descartável + `.python-version` `3.12`. Workspace vazio válido (zero membros) com descoberta por glob já ativa; `uv sync` materializa `.venv` + `uv.lock` sem editar `.gitignore`, sem criar `packages/`, sem introduzir Ruff/MyPy/Pytest/Lefthook (estes são specs 005–009). É a fundação pnpm-like para Python: single lockfile/Single `.venv` que os 12 itens seguintes consomem sem reescrever. Plano é transcrição fiel de D1–D10 verificadas contra `docs.astral.sh` + PyPI `uv 0.12.7` + `uv --help` local em 2026-08-30; nenhum desenho novo.

---

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (família `3.12`; local `3.12.3`, runner `3.12.14` via `setup-python@v7`) + TOML (pyproject/uv.lock) + bash (harness). `uv` `0.12.7` binário (pin §4, PyPI 2026-08-30; local `0.12.1` deve convergir via `uv self update`).

**Primary Dependencies**: `uv 0.12.7` + `uv_build>=0.12.7,<0.13` (`build-system.requires`, `build-backend=uv_build`). Nenhuma outra dependência runtime em 004 (`dependencies=[]`). `ruff 0.16.5`, `mypy 2.3.1`, `pytest 9.1.1`, `lefthook 2.1.11`, `pip-audit`, `trivy`, `lancedb` são **proibidos** neste item (FR-014, escada).

**Storage**: Sistema de arquivos. Artefatos: `pyproject.toml` (raiz), `uv.lock` (raiz, TOML universal), `.venv/` (raiz, interpretador + `.venv/.gitignore:*`), `.python-version` (raiz, `3.12`). Sem base de dados, sem Docker em 004.

**Testing**: Oráculo `scripts/verify/f0-004-uv-workspace.sh` (a criar, contrato `oracle-cli.md`: exit `0`/`1`/`2`, `--quiet`, uma linha por FR) com 10–14 asserções mapeadas 1:1 a FR-001..017 + verificação TOML via `python3 -c 'import tomllib'` (stdlib) + `git check-ignore` + `sha256sum` idempotência. Pytest só existe a partir de 005 — harness bash é único verificador aqui (constitution Additional Constraints).

**Target Platform**: Filesystem POSIX (Linux `ubuntu-24.04` runner + local), macOS e Windows cobertos por lock universal (cross-platform markers). CI `003` job `verify` já cobre runner.

**Project Type**: Infraestrutura de monorepo — workspace virtual. Não produz biblioteca nem CLI executável além do workspace.

**Performance Goals**: `uv sync` em clone limpo <2 min (rede mediana, lock vazio); segundo `uv sync` hash idêntico 100% (SC-002); `rm -rf .venv && uv sync` recria <2 min; harness `f0-004` <5s (SC-006).

**Constraints**:
- Escada de dependências (constitution Additional Constraints): nenhum artefato pode exigir ferramenta além de shell/git/Python stdlib+`uv` — impõe ausência de ruff/mypy/pytest em 004 (FR-014).
- Determinismo (I): single `requires-python` interseção workspace (D4), `uv_build` intervalo menor `<0.13` (D5), `uv.lock` universal, sem `$RANDOM` em lógica.
- Lei Zero (V): `uv.lock` versionado (D2/D7), `.venv` nunca rastreado (D3); `.gitignore` NÃO toca `*.lock` nem `.venv` explícito (FR-010/012, D7).
- Fidelidade ao oráculo (VI): harness cresce por acréscimo (`f0-004` sem tocar `f0-001`/`f0-003`), job CI `verify` reutilizado via glob (FR-017).
- Escopo da máquina: nada escreve em config global, identidade em `.git/config` local.
- Sem privilégio elevado: não exige `sudo`/`admin`.

**Scale/Scope**: 17 FRs, 8 SCs, 3 US (P1–P3), 6 edge cases. Três arquivos produtivos novos (`pyproject.toml`, `uv.lock`, `.python-version`) + um diretório efêmero (`.venv`) + um oráculo (`f0-004-uv-workspace.sh`). Zero membros em 004; 5–7 membros em `packages/*` até fase 01 sem reescrever root.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Princípios avaliados contra v1.0.0 (cada um com Violation/Source rotulados):**

| Princípio | Critério de violação | Avaliação neste plano |
|---|---|---|
| **I Determinismo sobre probabilidade** | decisão sem regra determinística validando modelo | ✅ PASS — `requires-python` single interseção (D4), `uv_build>=0.12.7,<0.13` pinado (D5), `uv.lock` universal idempotente (D10), `members=["packages/*"]` glob determinístico. |
| **II Especificação precede código** | artefato sem spec prévia ou spec pós-código | ✅ PASS — `spec.md` 191 linhas com 17 FRs/8 SCs existe antes deste plano; nenhum `pyproject.toml`/`uv.lock` foi criado ainda (verificado `ls` inexistente Q1/Q7 2026-08-30). |
| **III Teste antes da implementação** | sem par vermelho→verde preservado | ✅ PASS — Fase B gera `f0-004` reprovando (vermelho) antes de Fase C materializar workspace verde; evidências `red.txt`/`green.txt` versionadas. |
| **IV Definição de dados antes da implementação** | componente sem contrato de entrada/saída | ✅ PASS — `data-model.md` (Phase 1) declara entidades Workspace root / uv.lock / Project environment (.venv) / Member futuro com atributos e validações; `contracts/workspace-contract.md` fixa schema TOML. |
| **V Segurança é a Lei Zero** | segredo no histórico ou exclusão cobrindo trava | ✅ PASS — `uv.lock` versionado (FR-006/010), `.venv` ignorado via `.venv/.gitignore:*` (FR-011), nenhum segredo introduzido; `001` D3 (sem `*.lock` em `.gitignore`) preservado por FR-012. |
| **VI O harness é o oráculo** | critério sem asserção ou diff altera oráculo anterior | ✅ PASS — FR-001..017 têm asserção 1:1 em `f0-004` (10–14); plano proíbe tocar `f0-001`/`f0-003` (SHA `63412ca...` asserido por `f0-001` FR-021a). `uv.lock` é verificado, não substituído. |
| **VII Auto-reparo atualiza a documentação** | correção sem alteração normativa | ✅ PASS — plano não corrige falha prévia; se falhar, reparo exigirá `spec.md`/`decisions.md` update por definição do ciclo. |
| **VIII Elo verificado antes de lógica** | código consome serviço sem verificação em research | ✅ PASS — Q1–Q10 verificados 2026-08-30 contra `docs.astral.sh` (HTTP 200) + PyPI `uv/json` (`0.12.7`) + `uv --help`/`python --version` locais; D1–D10 citam fonte + bytes. |
| **IX Agnosticismo de stack** | referência a stack-alvo fora de adaptador | ✅ PASS — workspace é infra do motor, não do sistema-alvo; não assume linguagem/framework do alvo; `uv` isolado como ferramenta de bootstrap declarada. |
| **X Observabilidade** | falha sem REQ-ID ou evidência | ✅ PASS — cada asserção `f0-004` imprime `🔴 FR-XXX` com evidência (`tomllib` parse, `git check-ignore`, `sha256sum`); SC-006 exige FR nomeado. |

**Additional Constraints:**

| Constraint | Avaliação |
|---|---|
| Escada de dependências | ✅ Só `uv` + shell/git/Python stdlib; nenhum `ruff`/`mypy`/`pytest`/`lefthook` neste item (FR-014). |
| Escopo da máquina | ✅ Nenhuma escrita global, identidade em `.git/config` local. |
| Cadeia de suprimentos | ✅ `uv.lock` versionado e verificado; exclusão não cobre lock (FR-010). |
| Ambiente sob demanda | ✅ Sem Docker/service em background; `uv sync` é on-demand. |
| Sem privilégio elevado | ✅ Nenhum `sudo`/`admin` requerido. |

**Veredito pré-Phase 0**: **PASS** — nenhum gate bloqueante, nenhum NEEDS CLARIFICATION (research Q1–Q10 já resolveu).

**Re-avaliação pós-Phase 1**: **PASS** — `research.md` consolida D1–D10, `data-model.md`/`contracts/`/`quickstart.md` não introduzem dependência nova nem violam escada; workspace continua virtual sem membros.

---

## Project Structure

### Documentation (this feature)

```text
specs/004-uv-workspace/
├── spec.md              # Concluído (191 linhas, 17 FRs, 8 SCs)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — Q1–Q10 → D1–D10 (consolida docs/plan/research/f0-004-uv-workspace.md)
├── data-model.md        # Phase 1 — entidades Workspace root / uv.lock / .venv / Member + .python-version
├── quickstart.md        # Phase 1 — 6 cenários de validação (clone limpo, idempotência, descartabilidade, probe member, Lei Zero, CI glob)
├── contracts/
│   └── workspace-contract.md  # Phase 1 — contrato do workspace (pyproject.toml schema, uv.lock, .venv, .python-version)
├── checklists/
│   └── requirements.md  # (gerado por /speckit-checklist, 16/16 PASS — não por este plano)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item produz **três** arquivos versionados + um diretório efêmero + um oráculo; não produz `packages/`:

```text
fluksos-x/
├── pyproject.toml                     # NOVO — workspace root virtual (D1, FR-001..004)
├── uv.lock                            # NOVO — lock universal versionado (D2, FR-006)
├── .python-version                    # NOVO — 3.12 (D5, FR-005, criado por uv init)
├── .venv/                             # NOVO efêmero — gerado por uv sync (D3, FR-008, .venv/.gitignore:*)
│   ├── bin/python                     # interpretador 3.12
│   └── .gitignore                     # "*"
├── .gitignore                         # INTOCADO — já cumpre D3/D7 (FR-012)
├── .github/workflows/ci.yml           # INTOCADO — 003 já cobre 004 via glob (FR-017)
├── scripts/verify/
│   ├── README.md                      # ALTERADO — registra o que f0-004 verifica (+1 linha)
│   ├── f0-001-foundation.sh           # INTOCADO — SHA 63412ca... asserido
│   ├── f0-003-ci-minimo.sh            # INTOCADO
│   └── f0-004-uv-workspace.sh         # NOVO — oráculo deste item (10–14 asserções, FR-001..017)
├── docs/plan/research/
│   └── f0-004-uv-workspace.md         # JÁ EXISTE — pesquisa vinculante 381 linhas (Q1–Q10)
└── specs/004-uv-workspace/            # NOVO ao versionamento
```

**Structure Decision**: `pyproject.toml`/`uv.lock`/`.venv` na raiz seguem `docs.astral.sh/uv/concepts/projects/layout` (layout canônico: *.toml + lock + .venv vizinhos). `packages/*` não existe em 004 por D8 (membros surgem em 006+). Oráculo em `scripts/verify/` segue ADR-002 (um arquivo por item, `f0-NNN-<slug>.sh`) e `README.md` tabela. Spec dir em `specs/004-uv-workspace/` segue Spec-Kit. Não há `src/` porque base física é infra de workspace, não aplicação.

---

## Fases de execução

> Ordem normativa: vermelho antes do verde (III), porque é a única prova auditável; `uv sync` sem flag antes de `--locked`, porque com lock inexistente `--locked` falha por construção; `members=["packages/*"]` antes de qualquer `packages/` existir, porque sem ele cada pacote futuro reescreveria a raiz.

### Fase A — Preparação

1. Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` (deve sair 0 com `f0-001`+`f0-003`).
2. Confirmar ausência de `pyproject.toml`/`uv.lock`/`.python-version`/`packages/` (`ls → inexistente`, Q1/Q7).
3. Confirmar `.gitignore` vigente não contém `*.lock` (D3/D7) e `.venv` ainda não existe.
4. Registrar decisões D1–D10 em `research.md` deste feature dir (consolida `docs/plan/research/f0-004-uv-workspace.md`).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-004-uv-workspace.sh` com contrato `oracle-cli.md` (`0`/`1`/`2`, `--quiet`/`--list`, determinismo, somente leitura, sem `uv` exigido para asserções estáticas).
2. Cobrir FR-001..017 1:1 (10–14 asserções — algumas FRs convergem na mesma asserção):
   - FR-001/002/003/004: `pyproject.toml` existe, `tomllib` válido, `name`/`version`/`requires-python`/`build-system`/`tool.uv.workspace.members`
   - FR-005: `.python-version` contém `3.12`
   - FR-006/007: `uv.lock` existe e `tomllib` válido
   - FR-008/009/011: `.venv/bin/python` existe + `check-ignore` positivo + descartabilidade (probe remove/recria não altera `uv.lock`)
   - FR-010/011/012: `.gitignore` sem `*.lock`, `uv.lock` não ignorado, `.gitignore` inalterado vs 001
   - FR-013/014/015: ausência de `packages/` e de `ruff`/`mypy`/`pytest`/`lefthook` + contrato `workspace=true` documentado
   - FR-016: harness self-check (exit codes, `--list` enumera 10–14 IDs)
   - FR-017: CI glob inclui `f0-004` sem editar `ci.yml`
3. Executar e preservar `evidence/red.txt` — deve reprovar em massa (workspace inexistente).
4. Conferir `--list` enumera 10–14 IDs sem executar.

> Pular esta fase satisfaz os arquivos e ainda assim falha SC-006/Princípio III, porque o par vermelho→verde não existiria.

### Fase C — Workspace verde 🟢

1. Materializar workspace **via `uv`** (sem editar strings à mão quando `uv` disponível):
   ```bash
   uv init --name fluksos-x --bare --python 3.12  # ou: uv init --lib se bare indisponível, depois ajustar
   # Ajustar para virtual workspace (sem src/):
   # pyproject.toml deve conter:
   # [project] name="fluksos-x" version="0.1.0" requires-python=">=3.12,<3.14" dependencies=[]
   # [build-system] requires=["uv_build>=0.12.7,<0.13"] build-backend="uv_build"
   # [tool.uv.workspace] members=["packages/*"]
   # Remover [project] src layout se criado por uv init (virtual root não tem src/)
   uv sync   # gera uv.lock + .venv + .venv/.gitignore:* + .python-version
   ```
   Se `uv` indisponível, fallback determinístico: escrever `pyproject.toml` TOML válido + `uv.lock` TOML vazio válido + `.python-version` `3.12` + `.venv` mínimo; harness deve aceitar ambos (com e sem `uv`).
2. Validar TOML: `python3 -c 'import tomllib; tomllib.load(open("pyproject.toml","rb")); tomllib.load(open("uv.lock","rb"))'` (FR-001/006).
3. Validar Lei Zero: `! git check-ignore -q uv.lock` e `git check-ignore -q .venv` (FR-011).
4. Atualizar `scripts/verify/README.md` tabela (nova linha `f0-004-uv-workspace.sh | 10–14 | UV workspace`).

### Fase D — Verde e convergência local

1. Executar oráculo: `scripts/verify/f0-004-uv-workspace.sh --quiet` → `0`; preservar `evidence/green.txt`.
2. Executar duas vezes e comparar byte a byte (determinismo, SC-006).
3. Teste idempotência: `sha256sum uv.lock` antes/depois de `uv sync` → hash idêntico (SC-002).
4. Teste descartabilidade: `rm -rf .venv && uv sync` → `.venv/bin/python` recriado, `uv.lock` inalterado, `git status --porcelain` não lista `.venv` (SC-003).
5. Teste escalabilidade probe: criar `packages/_probe/pyproject.toml` temporário, `uv sync` descobre sem editar root, remover probe (SC-004).
6. Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0`.
7. `git status` limpo exceto artefatos deste item; `git diff .gitignore` vazio (FR-012).

### Fase E — Entrega remota (pós-merge)

1. Push para `main` em estado conforme → check `verify` verde inclui `f0-004` (SC-007).
2. Injetar violação (ex.: remover `requires-python` ou adicionar `*.lock` em `.gitignore`) em branch, PR para `main` → check vermelho com `🔴 FR-...` (SC-007).
3. Esses dois SCs são observáveis só após merge; registrá-los como evidência de execução remota na convergência.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | `pyproject.toml` root virtual `name=fluksos-x` `version=0.1.0` `requires-python=">=3.12,<3.14"` `build-system uv_build>=0.12.7,<0.13` | FR-001/002/003 | Q1 layout |
| D2 | `uv.lock` ao lado de `pyproject.toml`, versionado, TOML universal, não editado manualmente | FR-006/007 | Q2 layout lockfile |
| D3 | `.venv` vizinho a `pyproject.toml`, gerenciado por `uv sync`/`uv run`, ignorado via `.venv/.gitignore:*`, descartável | FR-008/009/011 | Q3 project-environment |
| D4 | `tool.uv.workspace members=["packages/*"]` sem `exclude`, inter-membro via `{ workspace = true }`, single `requires-python` | FR-004/015 | Q4 workspaces |
| D5 | Pin `uv 0.12.7` (`uv_build>=0.12.7,<0.13`), `.python-version` `3.12`, local `0.12.1` converge ao pin | FR-003/005 | Q5 pypi+docs+local |
| D6 | Flags `--locked`/`--frozen`/`--check` documentadas mas não impostas em 004; `uv sync` sem flag materializa lock inicial | FR-006/009 | Q6 sync |
| D7 | Não modificar `.gitignore` em 004; `uv.lock` já versionado (sem `*.lock`), `.venv` já ignorado internamente | FR-010/012 | Q7 .gitignore |
| D8 | Apenas root virtual em 004; sem `packages/` placeholder; escala para 010 (`--frozen`), 013 (`uv build`/`export`), 014 (Renovate) | FR-013/017 | Q8 ADR-009/011 |
| D9 | Harness `f0-004-uv-workspace.sh` 10–14 asserções só base física; não verifica `packages/*` nem CI flags | FR-016 | Q9 oracle-cli |
| D10 | `uv.lock` universal regenerável, `.venv` descartável; harness testa idempotência via `sha256sum`, não timestamp | FR-009/SC-002 | Q10 sync |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `.gitignore` ganhar `*.lock` e passar a ignorar `uv.lock` | Crítico — trava não versionada, viola V/SC-005 | FR-010 asserção negativa + `git check-ignore -q uv.lock` deve falhar (não ignorado); D7 proíbe tocar `.gitignore` em 004 |
| `requires-python` divergente entre root e futuro membro esvaziar interseção | Alto — `uv sync` falha, membros não resolvem | D4: root single `>=3.12,<3.14` documentado; `data-model.md` exige compatibilidade; harness futuro de cada membro valida interseção |
| `uv 0.12.1` local falhar com `uv_build>=0.12.7` | Médio — falso-negativo local | D5: mensagem de erro nomeia FR-003; `uv self update` / reinstall documentados em `quickstart.md` Troubleshooting |
| `uv sync --locked` imposto já em 004 causar bootstrap paradox (sem lock inicial) | Alto — primeiro run sempre falha | D6: 004 usa `uv sync` sem flag; `--locked`/`--frozen` só em 010 com lock já materializado |
| Criar `packages/` vazio em 004 antecipar responsabilidade de 006+ | Alto — quebra escada/SDD, cada spec futura reescreve raiz | FR-013 asserção `! test -d packages`; D8 rejeita placeholder |
| `pyproject.toml` sem `build-system` não instalável como editable | Médio — `.venv` sem âncora | D1: `build-system uv_build` obrigatório mesmo em root virtual (layout.md) |
| `.venv` versionado acidentalmente (`git add .venv`) | Alto — binários no histórico, viola V | FR-011 `check-ignore` positivo + `.venv/.gitignore:*` interno; harness reprova se `git ls-files | grep .venv` |
| Runner sem `uv` em 004 falhar ao materializar `.venv` | Baixo — fallback ainda deve passar harness estático | Fase C fallback escreve TOML válido + `.venv` mínimo; CI `003` não exige `uv` em 004 (apenas harness bash) |

---

## Complexity Tracking

> Nenhuma violação de Constitution Check a justificar. Tabela permanece vazia por construção.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |
