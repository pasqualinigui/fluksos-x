# Implementation Plan: CI mínimo — harness da Fase 0 em runner limpo

**Branch**: `003-ci-minimo` | **Date**: 2026-08-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-ci-minimo/spec.md`
**Pesquisa vinculante**: `docs/plan/research/f0-003-ci-minimo.md` (Q1–Q10, D1–D10, 2026-08-30, sem NEEDS CLARIFICATION)
**Constitution**: `.specify/memory/constitution.md` v1.0.0 (10 princípios I–X)

---

## Summary

Entregar o pipeline que o motor ensina mas não praticava (ADR-009): workflow **`.github/workflows/ci.yml`** que executa o harness completo da Fase 0 (`for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done`) em runner limpo `ubuntu-24.04`, com `actions/checkout@v7` (`fetch-depth: 0`) e `actions/setup-python@v7` (`python 3.12`), `permissions: contents: read`, gatilhos `push`/`pull_request` em `[main, develop]`, job único `verify` com steps estáveis `Checkout`/`Setup Python 3.12`/`Run harness`. É o **portão remoto mínimo**: só shell, git e Python 3.12 stdlib — sem Ruff/MyPy/Pytest/pip-audit/cache/matrix/branch protection (estes são spec `010`, FR-006). Abordagem é literalmente a transcrição das decisões D1–D10 já verificadas contra fonte em 2026-08-30; nenhum desenho novo é necessário, apenas fidelidade às fontes.

---

## Technical Context

**Language/Version**: YAML (GitHub Actions workflow syntax 2026-08-30) + Shell (bash, POSIX) + Python 3.12 stdlib (harness). `python-version: '3.12'` resolve para `3.12.14` no runner; local `3.12.3` — família pinada, não patch (D4/D9).

**Primary Dependencies**: `actions/checkout@v7` (`7.0.1` em 2026-08-30, node24, runner ≥2.327.1) · `actions/setup-python@v7` (`7.0.0`, node24). Nenhuma outra dependência. `ruff`, `mypy`, `pytest`, `pip-audit`, `trivy`, `gitleaks`, `uv`, `cache` são **proibidos** neste item (D5/D8, FR-006).

**Storage**: Sistema de arquivos + GitHub Actions runner. Sem base de dados. Workflow persiste apenas YAML em `.github/workflows/ci.yml`.

**Testing**: Oráculo `scripts/verify/f0-003-ci-minimo.sh` (a criar, padrão oracle-cli) com ~14 asserções mapeadas 1:1 aos FR-001..014 + inspeção estática YAML (`python3 -c 'import yaml'`) + execução do harness existente (`f0-001`, `f0-002`) antes e depois. Promovido a pytest em spec `005` via `--list`.

**Target Platform**: GitHub-hosted runner `ubuntu-24.04` (x64, 4CPU 16GB, Actions Runner ≥2.329.0 rolling) + Linux local do mantenedor. `ubuntu-26.04` em preview — não usado (D2). GHES self-hosted desatualizado fora do escopo (spec Assumptions).

**Project Type**: Infraestrutura de CI — workflow de verificação. Não produz código de aplicação nem biblioteca.

**Performance Goals**: Workflow completo < 2 min (checkout <10s, setup-python <20s, harness <10s em <5s por oráculo). Harness local permanece <5s por oráculo (FR-018). Sem matriz, sem cache — tempo é custo aceito por determinismo (D5).

**Constraints**:
- Escada de dependências (constitution Additional Constraints): nenhum artefato pode exigir ferramenta além de shell/git/Python stdlib — impõe ausência de `uv`, `ruff`, etc. (D5/D8).
- Determinismo (I): `runs-on` pinado `ubuntu-24.04` não `ubuntu-latest` (D2), actions major pin `v7` (D3/D4), sem `$RANDOM`/`date`/`GITHUB_RUN_NUMBER` em lógica (FR-012), sem cache com chave instável.
- Lei Zero / least privilege (V): `permissions: contents: read` top-level, nenhum `write`/`id-token: write` (D6).
- Fidelidade ao oráculo (VI): job `verify` propaga `exit 1` sem `continue-on-error` (D10), `fetch-depth: 0` obrigatório para `git log --all` (D5).
- Escopo da máquina: nada escreve em config global, nenhum serviço em background, sem `restart: always`.
- Sem privilégio elevado: não exige `sudo`/`admin`.

**Scale/Scope**: 14 FRs, 8 SCs, 3 US (P1–P3), 7 edge cases. Um arquivo produtivo (`.github/workflows/ci.yml`), um oráculo (`f0-003-ci-minimo.sh`), diretório `.github/workflows/` inexistente antes (Q1). Consumidor imediato: itens 004–016; consumidor crítico: `010` que transforma `verify` em `required check` sem rename.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Princípios avaliados contra v1.0.0 (cada um com Violation/Source rotulados):**

| Princípio | Critério de violação | Avaliação neste plano |
|---|---|---|
| **I Determinismo sobre probabilidade** | decisão sem regra determinística validando modelo | ✅ PASS — runner pinado `ubuntu-24.04` (D2), actions `v7` (D3/D4), sem alias móvel, sem construção não determinística (FR-012). Re-run produz saída idêntica (SC-007). |
| **II Especificação precede código** | artefato sem spec prévia ou spec pós-código | ✅ PASS — `spec.md` 197 linhas com 14 FRs/8 SCs existe antes deste plano; nenhum `.github/workflows/ci.yml` foi criado ainda (verificado `ls .github` inexistente). |
| **III Teste antes da implementação** | sem par vermelho→verde preservado | ✅ PASS — Fase B deste plano gera `f0-003` reprovando (vermelho) antes de Fase C criar `ci.yml` verde; evidências `red.txt`/`green.txt` versionadas. |
| **IV Definição de dados antes da implementação** | componente sem contrato de entrada/saída | ✅ PASS — `data-model.md` (Phase 1) declara entidades Workflow/Job/Step/Harness/Action pinada com atributos; `contracts/ci-workflow.md` fixa schema YAML. |
| **V Segurança é a Lei Zero** | segredo no histórico ou exclusão cobrindo trava | ✅ PASS — `permissions: contents: read` least privilege (D6), nenhum segredo introduzido; `.gitignore` não toca trava de dependências. |
| **VI O harness é o oráculo** | critério sem asserção ou diff altera oráculo anterior | ✅ PASS — `FR-001..014` têm asserção 1:1 em `f0-003`; plano proíbe tocar `f0-001`/`f0-002` (ADR-002/006, SHA `63412ca...` asserido por FR-021a). Workflow **orquestra** harness, não o substitui. |
| **VII Auto-reparo atualiza a documentação** | correção sem alteração normativa | ✅ PASS — plano não corrige falha prévia; se falhar, reparo exigirá ADR/spec update por definição do ciclo. |
| **VIII Elo verificado antes de lógica** | código consome serviço sem verificação em research | ✅ PASS — Q1–Q10 verificados 2026-08-30 contra docs.github.com raw + package.json + manifests; D1–D10 citam fonte + HTTP 200 + bytes. Nenhuma versão por memória. |
| **IX Agnosticismo de stack** | referência a stack-alvo fora de adaptador | ✅ PASS — workflow é infra do motor, não do sistema-alvo; não assume linguagem/framework do alvo. |
| **X Observabilidade** | falha sem REQ-ID ou evidência | ✅ PASS — `Run harness` sem `--quiet` por padrão para log completo; cada violação sai como `🔴 FR-...` com evidência (SC-002). |

**Additional Constraints:**

| Constraint | Avaliação |
|---|---|
| Escada de dependências | ✅ Só shell/git/Python stdlib; nenhum `uv`/`ruff`/`cache` neste item (FR-006). |
| Escopo da máquina | ✅ Nenhuma escrita global, identidade em `.git/config` local. |
| Cadeia de suprimentos | ✅ Sem trava de dependências introduzida; exclusão não cobre trava. |
| Ambiente sob demanda | ✅ Nenhum Docker/service em background; runner efêmero do GitHub. |
| Sem privilégio elevado | ✅ Nenhum `sudo`/`admin` requerido. |

**Veredito pré-Phase 0**: **PASS** — nenhum gate bloqueante, nenhum NEEDS CLARIFICATION.

**Re-avaliação pós-Phase 1**: **PASS** — `research.md` já resolveu todos os unknowns, `data-model.md`/`contracts/`/`quickstart.md` não introduzem dependência nova nem violam escada; workflow continua sendo orquestração, não substituição do harness.

---

## Project Structure

### Documentation (this feature)

```text
specs/003-ci-minimo/
├── spec.md              # Concluído (197 linhas, 14 FRs, 8 SCs)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — Q1–Q10 → D1–D10 (consolida docs/plan/research/f0-003-ci-minimo.md)
├── data-model.md        # Phase 1 — entidades Workflow/Job/Step/Harness/Action
├── quickstart.md        # Phase 1 — 6 cenários de validação (inspeção + harness + determinismo + fetch-depth)
├── contracts/
│   └── ci-workflow.md   # Phase 1 — contrato do workflow .github/workflows/ci.yml (YAML schema, triggers, permissions)
├── checklists/
│   └── requirements.md  # (gerado por /speckit-checklist, não por este plano)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item produz **um** artefato produtivo fora da spec e **um** oráculo; não produz `src/`/`packages/`:

```text
fluksos-x/
├── .github/
│   └── workflows/
│       └── ci.yml                 # NOVO — workflow deste item (D1–D10, FR-001..014)
├── scripts/verify/
│   ├── README.md                  # ALTERADO — registra o que f0-003 verifica (+1 linha na tabela)
│   ├── f0-001-foundation.sh       # INTOCADO — SHA 63412ca... asserido
│   ├── f0-002-constitution.sh     # INTOCADO
│   └── f0-003-ci-minimo.sh        # NOVO — oráculo deste item (~14 asserções)
├── docs/plan/research/
│   └── f0-003-ci-minimo.md        # JÁ EXISTE — pesquisa vinculante 288 linhas (Q1–Q10)
└── specs/003-ci-minimo/           # NOVO ao versionamento
```

**Structure Decision**: `.github/workflows/ci.yml` vai ao local canônico que GitHub Actions lê (Q1: *"You must store workflow files in the `.github/workflows` directory"*). Oráculo em `scripts/verify/` segue ADR-002 (um arquivo por item, `f0-NNN-<slug>.sh`) e `README.md` tabela. Spec dir em `specs/003-ci-minimo/` segue Spec-Kit. Não há `src/` porque CI mínimo é infra de verificação, não aplicação.

---

## Fases de execução

> Ordem normativa: vermelho antes do verde (III), porque é a única prova auditável; `fetch-depth: 0` antes de qualquer asserção de histórico, porque sem ele FR-020b valida falso-negativo; ampliação em `010` sem rename, porque `verify` vira `required check`.

### Fase A — Preparação

1. Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` (deve sair 0 com `f0-001`+`f0-002`).
2. Confirmar ausência de `.github/` (`ls .github → inexistente`, Q1).
3. Registrar decisões D1–D10 em `research.md` deste feature dir (consolida `docs/plan/research/f0-003-ci-minimo.md`).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-003-ci-minimo.sh` com contrato `oracle-cli.md` (`0`/`1`/`2`, `--quiet`/`--list`, determinismo, somente leitura).
2. Cobrir FR-001..014 1:1 (14 asserções + integridade de anteriores se desejado):
   - FR-001/002: existência e caminho do workflow
   - FR-003/004/005: pins determinísticos
   - FR-006: proibições (grep negativo para ruff/mypy/etc.)
   - FR-007: permissions
   - FR-008: triggers
   - FR-009/010: job verify e Run harness glob
   - FR-011/012: propagação de exit e ausência de não-determinismo
   - FR-013: escalabilidade (job verify não renomeado)
   - FR-014: contratos declarados (seção Contratos existe)
3. Executar e preservar `evidence/red.txt` — deve reprovar em massa (workflow inexistente).
4. Conferir `--list` enumera 14 IDs sem executar.

> Pular esta fase satisfaz os FR e ainda assim falha SC-005/Princípio III, porque o par vermelho→verde não existiria.

### Fase C — Workflow verde 🟢

1. Criar `.github/workflows/ci.yml` exatamente conforme D1–D10:
   ```yaml
   name: ci
   on:
     push: { branches: [main, develop] }
     pull_request: { branches: [main, develop] }
   permissions: { contents: read }
   jobs:
     verify:
       runs-on: ubuntu-24.04
       steps:
         - name: Checkout
           uses: actions/checkout@v7
           with: { fetch-depth: 0 }
         - name: Setup Python 3.12
           uses: actions/setup-python@v7
           with: { python-version: '3.12' }
         - name: Run harness
           run: |
             for f in scripts/verify/f0-*.sh; do
               "$f" || exit 1
             done
   ```
 2. Validar YAML: inspeção stdlib de chaves top-level `name`/`on`/`permissions`/`jobs` via `python3` (leitura textual + `grep` estrutural) com fallback `grep`/`awk` determinístico quando `yaml` (PyYAML) não estiver disponível — sem introduzir dependência além de shell/git/Python stdlib (Q1, B1). Falha em YAML inválido reprova FR-001.
3. Atualizar `scripts/verify/README.md` tabela (nova linha `f0-003-ci-minimo.sh | 14 | CI mínimo`).

### Fase D — Verde e convergência local

1. Executar oráculo: `scripts/verify/f0-003-ci-minimo.sh --quiet` → `0`; preservar `evidence/green.txt`.
2. Executar duas vezes e comparar byte a byte (determinismo, FR-018).
3. Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0`.
4. Teste de regressão `fetch-depth`: local `git log --all` vs `git log --max-count=1` — demonstrar que shallow esconderia histórico.
5. `git status` limpo exceto artefatos deste item.

### Fase E — Entrega remota (pós-merge)

1. Push para `main` em estado conforme → check `verify` verde (SC-002).
2. Injetar violação (ex.: linha `feature/foo` malformada) em branch, PR para `main` → check vermelho com `🔴 FR-...` (SC-002).
3. Esses dois SCs são observáveis só após merge; registrá-los como evidência de execução remota na convergência.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | Workflow em `.github/workflows/ci.yml` YAML com `name/on/permissions/jobs` | FR-001/002 | Q1 workflow-syntax |
| D2 | `runs-on: ubuntu-24.04` pinado | FR-003 | Q2 runners, I |
| D3 | `actions/checkout@v7` + `fetch-depth: 0` | FR-004 | Q3+Q5 |
| D4 | `actions/setup-python@v7` + `python-version: '3.12'` | FR-005 | Q4+Q9 |
| D5 | Sem cache, sem matrix em 003 | FR-006 | Q5+Q8 |
| D6 | `permissions: contents: read` least privilege | FR-007 | Q6 |
| D7 | `on: push/pull_request branches [main, develop]` | FR-008 | Q7 |
| D8 | Job único `verify` com steps nomeados estáveis | FR-009/013 | Q8 |
| D9 | Python família `3.12`, x64 default | FR-005 | Q9 |
| D10 | `Run harness` via glob + `|| exit 1` sem `continue-on-error` | FR-010/011 | Q10 |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `fetch-depth: 1` default esconderia violação em `git log --all` (FR-020b) | Crítico — falso-negativo, viola VI | D5: `fetch-depth: 0` obrigatório + asserção FR-004 + teste de regressão Fase D |
| `ubuntu-latest` migrar para 26.04 silenciosamente | Alto — indeterminismo, viola I | D2: pin `ubuntu-24.04`; atualização é spec `014` com harness verde obrigatório |
| `permissions` omitido virar `write` em org com default antigo | Alto — privilégio elevado, viola V | D6: declarar `contents: read` explicitamente; asserção FR-007 |
| Antecipar `ruff`/`mypy`/`cache` agora quebrar escada e TDD de 005–010 | Alto — invalida prova vermelho→verde futura | FR-006 asserção negativa (grep) + D5/D8; checklist bloqueia adição |
| `verify` renomeado em 010 quebraria branch protection | Médio — `required check` órfão | FR-009/013: id estável `verify` desde 003; contrato `010` reutiliza |
| YAML inválido ou chave top-level faltando | Médio — workflow não carrega | FR-001 asserção + validação `python -c yaml.safe_load` em Fase C |
| Runner `ubuntu-24.04` removido pelo provedor | Baixo — falha explícita preferível a migração silenciosa; edge case documentado | Falha é sinal desejado; PR versionado em spec 014 migra |

---

## Complexity Tracking

> Nenhuma violação de Constitution Check a justificar. Tabela permanece vazia por construção.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |
