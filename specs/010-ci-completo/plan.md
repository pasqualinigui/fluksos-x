# Implementation Plan: CI completo + branch protection — portão servidor

**Branch**: `010-ci-completo` | **Date**: 2026-09-04 | **Spec**: `specs/010-ci-completo/spec.md`

**Input**: Feature specification from `/specs/010-ci-completo/spec.md`

## Summary

Estender `.github/workflows/ci.yml` (003) para workflow completo com jobs nominais separados (harness, lint, types, tests, audit, secrets, coverage, commitlint), pins SHA, matriz `["3.12","3.13"]` com `fail-fast: false`, `uv sync --frozen`, portão de cobertura `--fail-under=90`, commitlint com os 11 tipos, quarentena ADR-019 — mais procedimento versionado de branch protection clássica (`main`+`develop`, checks frouxos + sem-bypass, sem reviews), aplicado por humano no servidor (🧑). Oráculo `f0-010` com 14 asserções identidade + 10ª linha do manifest. Nenhum oráculo 001–009 tocado salvo via ADR prévia (nenhum conflito previsto — ver fronteira).

## Technical Context

**Language/Version**: Python 3.12–3.13 (matriz CI; repo `requires-python >=3.12,<3.14`)

**Primary Dependencies**: `setup-uv v10.0.1` (SHA), `checkout v7.0.1`, `setup-python v7.0.0` (SHAs + comentário), `pytest-cov 7.1.0` (dev), `commitlint v21.2.2`, `gitleaks v8.30.1` via `gitleaks/gitleaks-action v3.0.0` (SHA `e0c47f4f…`), `aquasecurity/trivy-action v0.36.0` (remediação ANALYZE M1)

**Storage**: arquivos (`.github/workflows/ci.yml`, `commitlint.config.js`, procedimento `.md`); proteção = config de servidor (fora do repo por construção)

**Testing**: oráculo `f0-010-ci-completo.sh` (14 asserções) com par `red.txt`/`green.txt` + primeira execução real em runner (fecha resíduo 003-T031/B3)

**Target Platform**: runners `ubuntu-24.04` hospedados (com Docker); máquina local sem Docker usa skips ⏭️

**Project Type**: repo tooling (pipeline + governança de merge)

**Performance Goals**: feedback por job isolado; `timeout-minutes` explícito por job (quarentena ADR-019); oráculo <5s, 2× byte-idêntico

**Constraints**: sem `continue-on-error`; sem retry mascarador; sem renomear job `verify`; sem reviews obrigatórios; sem tokens no repo (Lei Zero); nomes de job únicos entre workflows

**Scale/Scope**: 1 workflow, 8 jobs, matriz 2 versões; 13 FRs → 13 asserções identidade 1:1

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | SHA pins + runner fixo + matriz exata + fail-under medido; sem-bypass fecha o bypass probabilístico humano |
| II Spec antes | ✅ PASS | spec 010 precede; workflow/proteção só via este ciclo |
| III Teste antes | ✅ PASS | `f0-010` vermelho separado antes do verde |
| IV Dados antes | ✅ PASS | `data-model.md` + `contracts/oracle-cli.md` antes do IMPLEMENT |
| V Lei Zero | ✅ PASS | zero segredos; oráculo nunca usa token; gitleaks fecha o loop de segredos |
| VI Oráculo | ✅ PASS | 14 asserções novas; 001–009 intocados (sem conflito previsto) |
| VII Auto-reparo | ✅ PASS | lacunas 5/7/8 da ADR-009 + B2/B3 + resíduo T031 pagos aqui |
| VIII Elo verificado | ✅ PASS | releases API + docs GitHub + `--help` executados 2026-09-04 |
| IX Agnosticismo | ✅ PASS | nada de stack-alvo; Actions é toolchain do próprio bootstrap |
| X Observabilidade | ✅ PASS | jobs nominais únicos (falha nomeia job); mapa identidade |

*Re-check pós-Phase 1: sem violações; Complexity Tracking vazio.*

## Project Structure

### Documentation (this feature)

```text
specs/010-ci-completo/
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
.github/workflows/ci.yml            # ESTENDER (010): 8 jobs (dona designada, Emenda 1)
commitlint.config.js                # NOVO (010): preset + 11 tipos do repo
pyproject.toml                      # EDITAR (010): pytest-cov==7.1.0 em dev
uv.lock                             # REGENERAR (010): hash pytest-cov
docs/plan/...                       # procedimento de proteção 🧑 (novo .md versionado)
scripts/verify/f0-010-ci-completo.sh# NOVO (010): 14 asserções
scripts/verify/manifest.sha256      # ACRESCER (010): 10ª linha
specs/README.md                     # EDITAR (010): 010 ✅ + hash
core.hooksPath / .git global        # INTOCADOS (FR-010/009)
packages/, release, renovate        # NÃO CRIAR (011/012, 013, 014)
```

**Structure Decision**: pipeline no workflow existente (estender, nunca renomear `verify`); proteção como procedimento documentado + cenário humano.

## Fases de execução

### Fase A — Preparação

1. Harness 9/9 + manifest 9/9 (base 009).
2. Medir cobertura real (`pytest --cov`): registrado 95% → `--fail-under=90` (FR-006, research Q7).
3. `specs/010-ci-completo/evidence/` para `red.txt`/`green.txt`.

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `f0-010-ci-completo.sh` (14 asserções, identidade) — **arquivo novo**, zero toque em 001–009.
2. Acrescer 10ª linha ao manifest (acréscimo, ADR-015a).
3. Executar: vermelhas de comportamento esperadas (jobs ausentes, cov ausente, commitlint ausente, README sem 010 ✅, tasks abertas); guardas verdes.
4. Preservar `evidence/red.txt` + commit `test(harness)` **separado**.

### Fase C — CI verde 🟢

1. `uv add --dev pytest-cov==7.1.0` + `uv sync`.
2. Estender `ci.yml`: 8 jobs (nomes únicos/estáveis, SHA pins, matriz + `fail-fast:false`, `uv sync --frozen`, `timeout-minutes`, sem `continue-on-error`).
3. `commitlint.config.js` (11 tipos) + validar histórico (SC-003: 100% passa).
4. `f0-010 --quiet` rumo a 14/14 (menos 🧑-proteção, que é cenário humano).

### Fase D — Verde e convergência local

1. `specs/README.md` `010 ✅` + hash; `tasks.md` zero `[ ]`.
2. Commit `feat(ci)` separado. CONVERGE local: harness + manifest + pytest + cadeia verdes.
3. Cenário 🧑 (proteção no servidor): checklist executado pelo mantenedor com evidência registrada; se pendente, divergência declarada (SC-005 honesto).

### Fase E — Entrega remota (primeira validação em servidor!)

1. Push; pipeline executa de verdade no runner (fecha resíduo 003-T031/B3).
2. Required checks observados no PR; Trivy pleno com Docker (fecha B2).

## Decisões técnicas herdadas da pesquisa

D1 frouxo+sem-bypass (CLARIFY) · D2 proteção clássica main+develop, sem reviews (CLARIFY implícito Q2/Q3: sem deadlock) · D3 setup-uv SHA + frozen + cache · D4 SHA+comentário, runner fixo · D5 matriz exata · D6 cov 7.1.0 + fail-under 90 medido · D7 commitlint 11 tipos · D8 gitleaks detect · D9 trivy-action `aquasecurity/` v0.36.0 · D10 quarentena sem máscara.

## Declaração de impacto de fronteira (ADR-017 — antes de qualquer merge)

010 é dona designada de `.github/` (Emenda 1): estender `ci.yml` é uso previsto, não conflito. **Conflito se e somente se**: renomear/remover job `verify` (FR-009/003) ou mudar gatilhos/branches de forma que FRs da 003 reprovem — proibido sem ADR prévia. **Conflito adicional declarado (achado do vermelho 010)**: `f0-009` FR-014 conta linhas do manifest com igualdade (`==9`) e reprova com a 10ª linha legítima da 010 — mesma classe A1/A2 (asserção temporal); correção pré-autorizada via ADR-021 (piso `>=9`, espelho do piso `>=5` da 005), aplicada só na Fase C. Nenhum outro oráculo 001–009 é tocado pela 010; se a implementação descobrir necessidade, volta ao PLAN + ADR prévia (nunca fix direto — A1 não se repete).

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Proteção servidor não aplicada (sem admin/momento) | cenário 🧑 com checklist + divergência declarada em SC-005; oráculo não finge cobrir |
| Runner sem Docker (Trivy) | skip ⏭️ documentado (padrão 008); pleno onde houver Docker |
| Flake sob carga (ADR-019) | `timeout-minutes` + falha visível; re-run manual; sem retry mascarador |
| Histórico com mensagem inválida | validação no intervalo do push/PR, nunca retroativa |
| Tag major sofre tamper | SHA pins em todos os `uses:` |

## Complexity Tracking

> Vazio — Constitution Check sem violações.
