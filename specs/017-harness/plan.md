# Implementation Plan: `core/harness.py` — controles feedforward + feedback

**Branch**: `feature/f1-harness-engine` | **Date**: 2026-09-10 | **Spec**: `specs/017-harness/spec.md`

**Input**: Feature specification from `/specs/017-harness/spec.md`

## Summary

Criar `packages/core/src/fkx_core/harness.py` (stdlib puro): portão feedforward que valida pré-condições antes de executar (falha = erro de uso `2`, zero processos) + julgamento feedback que executa com `check=False` + captura e returncode preservado (sinal/OOM vira falha nomeada, nunca verde; zero retry), exit codes literais `0/1/2` componíveis com os 16 oráculos, erro `HarnessError(FkxError)` exportado no `__init__.py`. Oráculo `f1-017-*` com 12 asserções em identidade (mapa em `contracts/oracle-cli.md`) + self-check `f0-001…f0-016` em série + 17ª linha do manifest. Fronteira com 1 ponto (`f0-011` FR-002): PLAN declara → ADR prévia autoriza (10ª execução do molde ADR-017) → verde aplica → manifest cita.

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (medido 3.12.3, research Q5); stdlib puro (`subprocess`, `os`, `sys`) — sem dependência nova, `uv.lock` intocado

**Primary Dependencies**: nenhuma nova — tipos 011 (`FkxError`); `git` segue exigido só pelos oráculos, não pelo módulo

**Storage**: N/A (módulo sem estado; vereditos são valores retornados, não persistidos)

**Testing**: harness `scripts/verify/f1-017-*.sh` (12 asserções identidade, mapa em `contracts/oracle-cli.md`) + `tests/test_fkx_core_harness.py` (pytest TDD, importa da superfície `fkx_core`) + self-check `f0-001…f0-016` em série (ADR-031) + 17ª linha do manifest

**Target Platform**: repo `pasqualinigui/fluksos-x`, `main` via `feature/*` + PR (proteção, `strict:true`, auto-merge servidor — ADR-035); runtime POSIX (Linux dev + `ubuntu-24.04` CI, matriz 3.12/3.13); não-POSIX falha fechado (CLARIFY)

**Project Type**: módulo de kernel + oráculo (primeiro corpo Python do harness; os 16 oráculos shell continuam decidindo)

**Performance Goals**: módulo sem teto próprio (chamadas delegam timeout ao chamador); oráculo 2× byte-idêntico, cada execução <5s no modo estático (padrão — com o dado E4 do checkpoint sobre tetos sob load)

**Constraints**: Regra 5 (1 ponto de fronteira, pago pelo procedimento — nunca edição silenciosa); zero retry (ADR-019 §3, `010` FR-010); exceção nunca é evidência (X); Lei Zero (segredo mascarado em veredito); `check=True` só em pré-condição

**Scale/Scope**: 1 módulo + 1 erro + exports; 12 FRs; 1 oráculo novo; 1 linha de manifest; 1 ADR de fronteira (prévia)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | regras em código (feedforward/feedback), julgamento só roteia; zero retry; literais `0/1/2` |
| II Spec antes | ✅ PASS | spec 017 + clarify (3/3) precedem; research vinculante Q1–Q8 |
| III Teste antes | ✅ PASS | oráculo + pytest vermelhos antes, verdes depois, commits separados; manifest linha 17 no vermelho junto (precedente E5) |
| IV Dados antes | ✅ PASS | data-model + contracts antes do verde; sem consumidor não há comportamento (gateway/fila/watcher fora) |
| V Lei Zero | ✅ PASS | segredo mascarado em veredito; sem credencial nova; `uv.lock` intocado |
| VI Oráculo | ✅ PASS | 12 asserções novas identidade; 001–016 intocados fora do ponto autorizado (fronteira paga, não editada) |
| VII Auto-reparo | ✅ PASS | primeira execução da norma ADR-041; consome E1/E2 do checkpoint |
| VIII Elo verificado | ✅ PASS | subprocess + EX_* executados (P0) + CPython docs (P1); POSIX com prova dupla; Windows declarado fora |
| IX Agnosticismo | ✅ PASS | stdlib puro; nada do stack-alvo |
| X Observabilidade | ✅ PASS | FRs no oráculo; veredito nomeia requisito + evidência; SC-006 com evidência |

**Re-check pós-Phase 1 (2026-09-10)**: sem violações; desenho não introduziu dependência, residente, rede ou escrita nova além do declarado. Pass.

## Declaração de impacto de fronteira (varredura com 1 ponto — ADR-017, 10ª execução)

Varredura mecânica 2026-09-10 (`alem dos 4|EXTRA=` sobre os 16 oráculos — research Q7): **1 ponto genuíno**.

| # | Oráculo | Conflito | Ajuste (forma exata, só na Fase C verde) |
|---|---|---|---|
| 1 | `f0-011` FR-002 (l.144) | `EXTRA` lista `harness.py` como "módulos além dos 4" sobre estado correto | whitelist admite `harness.py` **se** `specs/017-*/` existe com o módulo sob jurisdição (jurisdição 017); resto proibido; padrão ADR-018 (legitimidade: membro `packages/core`, nunca nome estático) |

`f0-012` FR-002 é sobre `cli/` (intocado). `f0-004/005/006/007/008` asserem diretórios, não conteúdo de `core/`. **ADR prévia obrigatória antes do verde** (conflito de contrato entre specs, ADR-002). Manifest regenerado na Fase C citando a ADR prévia. Qualquer outro vermelho herdado = conflito novo, ADR própria, nunca fix direto.

## Project Structure

### Documentation (this feature)

```text
specs/017-harness/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (decisões consolidadas do research vinculante)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (oracle-cli.md — mapa FR↔asserção)
│   └── oracle-cli.md
├── checklists/
│   └── requirements.md  # Spec quality (15/16, 1 FAIL aceito ADR-010)
├── evidence/            # TESTS: red.txt + green.txt (Fase TESTS)
├── spec.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root — 1 módulo + exports + testes + oráculo)

```text
packages/core/src/fkx_core/
├── harness.py           # NOVO: feedforward + feedback, stdlib, zero retry
├── __init__.py          # +exports (HarnessError + superfície do módulo)
└── py.typed             # intocado (marcador PEP 561)
tests/
└── test_fkx_core_harness.py  # NOVO: pytest TDD (vermelho sem harness.py)
scripts/verify/
├── f1-017-harness.sh    # NOVO: 12 asserções identidade (primeiro oráculo f1-*)
└── manifest.sha256      # +17ª linha (no commit vermelho junto, precedente E5)
specs/README.md          # 017 ✅ + hash (só no CONVERGE)
```

**Structure Decision**: kernel acrescido por módulo (molde 011/012); testes no `tests/` raiz importando da superfície pública (molde `test_fkx_core_*`); oráculo novo segue o contrato `oracle-cli.md` com prefixo `f1-` (primeiro da Fase 1); manifest aditivo (ADR-015a).

## Complexity Tracking

> Sem violações no Constitution Check — nada a justificar.

## Fases de execução (para TASKS/IMPLEMENT)

- **Fase A (esqueleto)**: oráculo `f1-017` esqueleto (contrato de interface: `--quiet`/`--list`, 0/1/2) + 17ª linha do manifest **no mesmo commit** (o manifest inteiro é verificado por `f0-009/010/011/012` via `sha256sum -c` — separar causaria regressão, precedente E5 da 013).
- **Fase B (vermelho 🔴)**: `test(harness)`: oráculo com as 12 asserções reprovando sobre estado sem `harness.py` + `tests/test_fkx_core_harness.py` reprovando (commit separado, `evidence/red.txt`). **Push do vermelho aqui** (disciplina §6: durabilidade da prova).
- **Fase C (verde 🟢)**: `feat(harness)`: `harness.py` + `HarnessError` + exports + ajuste autorizado de `f0-011` FR-002 (só aqui, citando a ADR prévia) + manifest regenerado citando a ADR prévia; pytest verde.
- **Fase D (converge)**: harness 17/17 + manifest 17/17 + `tasks.md` zero `[ ]` + `specs/README.md` `017 ✅` + PR (push + auto-merge servidor); SC-006 🧑 com roteiro do `quickstart.md`.
