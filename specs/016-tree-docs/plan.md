# Implementation Plan: `docs/tree.md` — mapa da árvore para IA

**Branch**: `feature/f0-tree-docs` | **Date**: 2026-09-09 | **Spec**: `specs/016-tree-docs/spec.md`

**Input**: Feature specification from `/specs/016-tree-docs/spec.md`

## Summary

Criar `docs/tree.md` (H1 + resumo + árvore anotada por diretório + tabela de ponteiros) com esqueleto emitido por `scripts/generate-tree.py` (stdlib, fonte `git ls-files`, byte-idêntico), curadoria com teto de 120 linhas, e oráculo `f0-016` com 12–16 asserções em identidade + self-check serial + 16ª linha do manifest — incluindo a FR da auditoria `f0-audit-013-016` (molde 009/ADR-016). Fronteira zero: nenhum oráculo anterior conhece o vocabulário (varredura abaixo); nenhum ajuste, nenhuma ADR de fronteira.

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` stdlib puro no gerador (sem dependência nova; `LC_ALL=C`, ordenado); `git ls-files` como fonte

**Primary Dependencies**: nenhuma nova — só `git` (já exigido desde 001) e stdlib

**Storage**: N/A (documento versionado `docs/tree.md` + script `scripts/generate-tree.py`; auditoria-checkpoint fora do mapa)

**Testing**: harness `scripts/verify/f0-016-*.sh` (12–16 asserções identidade, mapa em `contracts/oracle-cli.md`) + self-check `f0-001…f0-015` em série (ADR-031) + 16ª linha do manifest + auditoria `f0-audit-013-016.md` como checkpoint pré-converge (SC-006)

**Target Platform**: repo `pasqualinigui/fluksos-x`, `main` via `feature/*` + PR (proteção, `strict:true`, auto-merge servidor — ADR-035)

**Project Type**: documento + gerador + oráculo (sem código de produção)

**Performance Goals**: gerador e oráculo 2× byte-idênticos, cada execução <5s no modo estático (padrão)

**Constraints**: Regra 5 (fronteira zero verificada — nenhum oráculo 001–015 tocado, nenhuma ADR exigida); Lei Zero (fonte no índice: ignorados nunca aparecem); teto 120 linhas na curadoria; granularidade por diretório + ponteiros (decisão 2026-09-09)

**Scale/Scope**: 312 paths / ~12 KB hoje; mapa total <25 KB; 1 relatório de auditoria herdado como FR

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | gerador stdlib byte-idêntico; teto em linhas+bytes (sem tokenizador); fonte `git ls-files` |
| II Spec antes | ✅ PASS | spec 016 + clarify (2 bullets) precedem; research vinculante Q1–Q5 |
| III Teste antes | ✅ PASS | oráculo vermelho→verde em commits separados; 16ª linha do manifest no vermelho junto (precedente E5) |
| IV Dados antes | ✅ PASS | data-model + contracts antes do verde; granularidade arquivo/diretório (símbolos são Fase 1) |
| V Lei Zero | ✅ PASS | fonte no índice; zero segredo/path ignorado no mapa; gerador sem escrita além de stdout |
| VI Oráculo | ✅ PASS | 12–16 asserções novas identidade; 001–015 intocados (fronteira zero, sem ADR) |
| VII Auto-reparo | ✅ PASS | fecha a Fase 0 com mapa que impede apodrecimento futuro; consome auditorias 009–012 |
| VIII Elo verificado | ✅ PASS | formato (aider P1, llms.txt P2) + ambiente (stdlib+git P0) com fetch 2026-09-09 |
| IX Agnosticismo | ✅ PASS | mapa deste motor |
| X Observabilidade | ✅ PASS | FRs no oráculo; SC-007 com evidência |

**Re-check pós-Phase 1 (2026-09-09)**: sem violações; desenho não introduziu dependência, residente ou escrita nova além do declarado. Pass.

## Declaração de impacto de fronteira (varredura com zero pontos — ADR-017)

Varredura mecânica 2026-09-09 (`tree.md|generate-tree|tree-docs` sobre os 15 oráculos + `.github/` + `lefthook.yml` + `pyproject.toml`): **zero ocorrências**. Arquivos novos (`docs/tree.md`, `scripts/generate-tree.py`) não colidem com nenhuma asserção de fronteira (008 FR-013 rege `docker-compose.yml`, não `docs/`; nenhuma FR lista `docs/` como proibido). **Nenhum ajuste, nenhuma ADR de fronteira.** Qualquer vermelho herdado no verde = conflito novo, ADR própria, nunca fix direto. Manifest regenerado na Fase C sem citação de ADR de fronteira (só a linha 16).

## Project Structure

### Documentation (this feature)

```text
specs/016-tree-docs/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (decisões consolidadas do research vinculante)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (oracle-cli.md — mapa FR↔asserção)
├── checklists/
│   └── requirements.md  # Spec quality (16/16)
├── evidence/            # TESTS: red.txt + green.txt (Fase TESTS)
├── spec.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root — só documento + gerador, sem produção)

```text
docs/
└── tree.md                       # NOVO: H1 + resumo + árvore anotada + ponteiros
scripts/
├── generate-tree.py              # NOVO: stdlib, git ls-files → esqueleto (stdout)
└── verify/
    ├── f0-016-tree.sh            # NOVO: 12–16 asserções identidade
    └── manifest.sha256           # +16ª linha (no commit vermelho junto, precedente E5)
docs/plan/audit/
└── f0-audit-013-016.md           # CHECKPOINT não-item pré-converge (formato ADR-014)
specs/README.md                   # 016 ✅ + hash (só no CONVERGE)
```

**Structure Decision**: documento-e-oráculo; gerador sem escrita além de stdout (o humano edita, o oráculo verifica); auditoria fora do mapa de execução (ADR-011), dentro da FR-008.

## Complexity Tracking

> Sem violações no Constitution Check — nada a justificar.

## Fases de execução (para TASKS/IMPLEMENT)

- **Fase A (esqueleto)**: oráculo `f0-016` esqueleto + 16ª linha do manifest (o manifest inteiro é verificado por `f0-009/010/011/012` — separar do vermelho causaria regressão, precedente E5).
- **Fase B (vermelho 🔴)**: `test(harness)`: oráculo reprovando sobre estado sem mapa (commit separado, `evidence/red.txt`).
- **Fase C (verde 🟢)**: `feat(treedocs)`: gerador + `docs/tree.md` + curadoria; auditoria `f0-audit-013-016.md` aterrissa como checkpoint (pode ser commit próprio anterior ao verde, precedente 009); re-verificar contagens (312 paths da pesquisa vs índice atual).
- **Fase D (converge)**: harness 16/16 + manifest 16/16 + `tasks.md` zero `[ ]` + `specs/README.md` `016 ✅` + `AGENTS.md` (Fase 0 16/16); SC-007 🧑 em janela nova.
