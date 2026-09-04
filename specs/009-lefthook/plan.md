# Implementation Plan: Lefthook — orquestração pre-commit do harness

**Branch**: `009-lefthook` | **Date**: 2026-09-04 | **Spec**: `specs/009-lefthook/spec.md`

**Input**: Feature specification from `/specs/009-lefthook/spec.md`

## Summary

Orquestrar o harness 005–008 localmente via `lefthook.yml` (pin 2.1.12, `min_version` declarativo, instalação pelo wrapper PyPI em `[dependency-groups] dev`): jobs `pre-commit` fail-fast somente-leitura + `trivy fs` e harness completo no `pre-push`, oráculo `f0-009-lefthook.sh` com 16 asserções identidade 1:1 (inclui FR de cadência ADR-016), 9ª linha do manifest, ajustes de fronteira 004–008 **pré-autorizados pela ADR-018** (primeira execução do procedimento ADR-017), sem tocar CI, sem `remotes`/`self-update`, sem escrita global.

## Technical Context

**Language/Version**: Python 3.12 (repo; Lefthook é binário Go consumido via wrapper, não código do projeto)

**Primary Dependencies**: `lefthook==2.1.12` (PyPI wrapper, `[dependency-groups] dev` + hash `uv.lock`) · cadeia 005–008 já em dev (`pytest`, `ruff`, `mypy`, `pip-audit`)

**Storage**: arquivos (`lefthook.yml`, `uv.lock`); N/A banco

**Testing**: oráculo `f0-009-lefthook.sh` (16 asserções) com par `red.txt`/`green.txt` + promoção pytest existente

**Target Platform**: Linux dev local do mantenedor (ganchos não rodam em CI)

**Project Type**: repo tooling (orquestração do harness)

**Performance Goals**: feedback `pre-commit` em segundos; oráculo <5s estável, 2 execuções byte-idênticas (espelho FR-014/005)

**Constraints**: oráculo somente-leitura (nunca executa jobs); sem edição de `.github/`; sem `remotes`/`self-update`; sem escrita global; determinismo FR-018

**Scale/Scope**: 1 repo, 5 jobs `pre-commit` + harness `pre-push`; 16 FRs → 16 asserções

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | pin exato + `uv.lock` + `min_version` + ordem fail-fast fixa; julgamento só roteia (qual job) |
| II Spec antes | ✅ PASS | spec 009 precede; ajustes 004–008 entram por ADR-018 prévia, nunca por edição direta |
| III Teste antes | ✅ PASS | `f0-009` vermelho em commit `test(harness)` separado antes do verde (exceção M3 não se estende) |
| IV Dados antes | ✅ PASS | `data-model.md` + `contracts/oracle-cli.md` com mapa identidade antes do IMPLEMENT |
| V Lei Zero | ✅ PASS | `remotes` proibido; trava versionada; `lefthook-local.yml` inexistente e sem regra que o crie |
| VI Oráculo | ✅ PASS | 16 asserções novas; 001–008 intocados exceto o pré-autorizado em ADR-018 |
| VII Auto-reparo | ✅ PASS | A1/A2 da auditoria viram ADR-017/018 + FR-012 (fronteira declarada no PLAN) |
| VIII Elo verificado | ✅ PASS | releases API + checksum `435aff51…` + `--help` executado 2026-09-04 |
| IX Agnosticismo | ✅ PASS | nada de stack-alvo; `uv run` é toolchain do próprio bootstrap (Escada) |
| X Observabilidade | ✅ PASS | falha nomeia FR; mapa identidade documentado |

*Re-check pós-Phase 1: sem violações; Complexity Tracking vazio.*

## Project Structure

### Documentation (this feature)

```text
specs/009-lefthook/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── oracle-cli.md    # mapa FR↔asserção identidade 1:1 (ADR-015b)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lefthook.yml                        # NOVO (009): jobs pre-commit + pre-push, min_version 2.1.12
pyproject.toml                      # EDITAR (009): lefthook==2.1.12 em [dependency-groups] dev
uv.lock                             # REGENERAR (009): hash lefthook (fonte única)
scripts/verify/f0-009-lefthook.sh   # NOVO (009): 16 asserções
scripts/verify/manifest.sha256      # ACRESCER (009): 9ª linha (acréscimo, ADR-015a)
specs/README.md                     # EDITAR (009): 009 ✅ + hash (inquebrável FR-015)
scripts/verify/f0-004-*.sh          # AJUSTE PRÉ-AUTORIZADO (ADR-018, só no verde)
scripts/verify/f0-005-*.sh          # AJUSTE PRÉ-AUTORIZADO (ADR-018, só no verde)
scripts/verify/f0-006-*.sh          # AJUSTE PRÉ-AUTORIZADO (ADR-018, só no verde)
scripts/verify/f0-007-*.sh          # AJUSTE PRÉ-AUTORIZADO (ADR-018, só no verde)
scripts/verify/f0-008-*.sh          # AJUSTE PRÉ-AUTORIZADO (ADR-018, só no verde)
.github/                            # INTOCADO (glob inclui f0-009 sem edição)
```

**Structure Decision**: repo-root tooling; nenhum pacote novo (011/012), nenhum workflow novo (010).

## Fases de execução

### Fase A — Preparação

1. Harness 8/8 verde + manifest 8/8 SUCESSO (base da auditoria 005–008).
2. ADR-018 registrada (pré-autorização de fronteira) **antes** de qualquer merge desta spec.
3. `specs/009-lefthook/evidence/` criado para `red.txt`/`green.txt`.

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `f0-009-lefthook.sh` (16 asserções, identidade FR↔asserção) — **arquivo novo**, zero toque em 001–008.
2. Acrescer 9ª linha ao manifest (acréscimo de linha nova, não reescrita de valor — permitido por ADR-015a).
3. Executar: 16/16 vermelhas esperadas (`lefthook.yml` ausente, dev sem lefthook, README sem 009 ✅).
4. Preservar `evidence/red.txt` + `--quiet` e commitar `test(harness)` **separado** (regra reaﬁrmada pós-M3).

### Fase C — Lefthook verde 🟢

1. `uv add --dev lefthook==2.1.12` + `uv sync` (hash no lock).
2. Escrever `lefthook.yml` (jobs FR-003/004/005, `min_version: 2.1.12`, sem remotes).
3. `lefthook install` local + `validate` + `check-install` verdes.
4. Aplicar **somente agora** os ajustes ADR-018 nos 5 oráculos + regenerar manifest.
5. `f0-009 --quiet` 16/16 + harness 9/9 + `sha256sum -c` 9/9.

### Fase D — Verde e convergência local

1. `specs/README.md` `009 ✅` + hash do commit verde (inquebrável FR-015).
2. `tasks.md` zero `[ ]` asserido pelo próprio oráculo (FR-016).
3. Commit `feat(harness)` separado do vermelho. CONVERGE: harness + manifest + pytest + ruff + mypy + pip-audit verdes.

### Fase E — Entrega remota (pós-merge)

1. Push; CI executa glob incluindo `f0-009` sem edição (FR-009) — primeira validação em runner limpo.
2. B2 (Trivy pleno com Docker) segue transferido à 010/015.

## Decisões técnicas herdadas da pesquisa

D1 pin **2.1.12** (CLARIFY) · D2 wrapper PyPI via `uv add --dev` · D3 `lefthook.yml` raiz YAML · D4 `min_version` = pin, `remotes`/`self-update` proibidos · D5 check-only (FR-006, sem `stage_fixed`) · D6 ordem fail-fast + `uv run`, `pre-push` espelha harness · D7 CI intocado · D8 `lefthook-local.yml` inexistente · D9 oráculo observa via `validate`/`dump`/`check-install` · D10 fronteira ao PLAN + ADR prévia (executado: tabela abaixo + ADR-018).

## Declaração de impacto de fronteira (ADR-017 — antes de qualquer merge)

| Oráculo | Asserção que disparará sobre estado correto | Ajuste pré-autorizado (só na Fase C) |
|---|---|---|
| `f0-004` FR-012 | `lefthook` em pyproject/groups; loop `lefthook.yml` | admitir `lefthook` em dev **se** `name = "lefthook"` em `uv.lock`; admitir `lefthook.yml` (jurisdição da 009) |
| `f0-005` FR-015 | `lefthook.yml` existe | admitir existência (conteúdo é jurisdição da 009) |
| `f0-006` FR-014 | `lefthook.yml` existe ("deve ser 009") | idem |
| `f0-007` FR-014 | `lefthook.yml` existe ("deve ser 009") | idem |
| `f0-008` FR-013 | `lefthook.yml` existe ("deve ser 009") | idem |

Forma exata dos diffs: padrão `0e7b077` (legitimidade via `uv.lock`, nunca nome estático). Manifest regenerado **na Fase C**, citado na ADR-018.

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Ajuste de fronteira vira A1-recorrente | ADR-018 prévia + diffs aplicados só no verde + manifest citado |
| Vermelho co-comitado (M3-recorrente) | Fase B commita `test(harness)` separado; FR-016 asserir ordem via log |
| `lefthook` indisponível numa máquina | oráculo valida via `uv run`; hook ausente ≠ falha (FR-008 escape documentado) |
| PyPI fora do ar no setup | `uv.lock` + cache; falha de rede é erro de ambiente, não do oráculo |
| Tentação de `remotes`/`self-update` futuros | proibição nesta spec + FR do oráculo grepa ausência |

## Complexity Tracking

> Vazio — Constitution Check sem violações.
