# Implementation Plan: Atualização automática de dependências

**Branch**: `feature/f0-dependency-updates` | **Date**: 2026-09-08 | **Spec**: `specs/014-dependency-updates/spec.md`

**Input**: Feature specification from `/specs/014-dependency-updates/spec.md`

## Summary

Configurar o Dependabot (ecossistemas `uv` + `github-actions`) com grupos (`dev-minor-patch` com automerge no verde, `major` isolado sem automerge, `security` em via expressa), prefixo de commit não-liberável `build(deps)`, workflow de automerge condicionado aos 10 checks, `pip-audit` movido para `pre-push` via ADR-017, e oráculo `f0-014` com 11 asserções em identidade — sem supressão, sem credencial nova, sem tocar oráculo anterior fora do procedimento.

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (matriz CI 3.12 + 3.13); `uv` com `uv.lock` como fonte única; `uv sync --frozen --all-packages` (padrão ADR-023)

**Primary Dependencies**: nenhuma nova — Dependabot é nativo do servidor (sem pacote, sem App, sem token). Pins `==` em `[dependency-groups] dev` fazem cada bump mover manifesto + lock

**Storage**: N/A (config versionada: `.github/dependabot.yml` + workflow de automerge + `lefthook.yml`)

**Testing**: harness `scripts/verify/f0-014-*.sh` (11 asserções identidade) + self-check `f0-001…f0-013` em série (ADR-031) + 14ª linha do manifest + prova servidor no primeiro PR real do bot (SC-007 🧑)

**Target Platform**: GitHub (`pasqualinigui/fluksos-x`): proteção `main`/`develop`, `strict:true`, auto-merge servidor, squash/rebase desligados (ADR-035)

**Project Type**: config de automação + oráculo (sem código de produção)

**Performance Goals**: oráculo 2× byte-idêntico, cada execução <5s (padrão)

**Constraints**: Regra 5 (nenhum oráculo 001–013 tocado fora da ADR-017); FR-002 da 008 é invariante (zero supressão); commits de bot não-liberáveis (PSR deriva versão do histórico); `.github/` sem o literal `lefthook` (FR-009 da 009)

**Scale/Scope**: 8 deps dev + 2 runtime + actions pinadas por SHA; 1 grupo versionado, 1 grupo security, 1 grupo actions, majors unitários

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | bot agrupa por regra, mergeia por exit code; API MCP estruturada na operação |
| II Spec antes | ✅ PASS | spec 014 + clarify precedem; research vinculante Q1–Q9 |
| III Teste antes | ✅ PASS | oráculo vermelho→verde em commits separados; 14ª linha do manifest no vermelho junto (precedente E5) |
| IV Dados antes | ✅ PASS | data-model + contracts antes do verde |
| V Lei Zero | ✅ PASS | bot nativo, zero credencial; zero supressão |
| VI Oráculo | ✅ PASS | 11 asserções novas identidade; 001–013 intocados (1 ponto via ADR-017) |
| VII Auto-reparo | ✅ PASS | paga a dívida ADR-034 §6; consome auditorias 009–012 |
| VIII Elo verificado | ✅ PASS | uv GA, groups, automerge, prefix — tudo P0/P1 com fetch 2026-09-08 |
| IX Agnosticismo | ✅ PASS | atualiza este motor |
| X Observabilidade | ✅ PASS | FRs no oráculo; SC-007 com evidência verbatim |

**Re-check pós-Phase 1 (2026-09-08)**: sem violações; desenho não introduziu ferramenta, credencial ou escrita nova além do declarado. Pass.

## Declaração de impacto de fronteira (insumo à ADR — ADR-017, 7ª execução)

Varredura mecânica 2026-09-08 (`dependabot|renovate` → 0 ocorrências nos 13 oráculos; literais `lefthook`, `pip-audit`, `[tool.pip-audit]` conferidos ponto a ponto):

| # | Oráculo | Ajuste (forma exata, só na Fase C) |
|---|---|---|
| 1 | `f0-009` FR-003 | admitir `uv run pip-audit` ausente do `pre-commit` **se** presente no `pre-push` após o harness (jurisdição 014); ordem fail-fast do `pre-commit` intacta |

Manifest regenerado na Fase C citando a ADR. Qualquer outro vermelho herdado = conflito novo, ADR própria, nunca fix direto. `[tool.pip-audit]`/`pip-audit.toml` seguem **proibidos** (invariante, sem exceção). Arquivos novos (`.github/dependabot.yml`, workflow de automerge) são livres desde que sem o literal `lefthook` e com `uses:` por SHA+comentário.

## Project Structure

### Documentation (this feature)

```text
specs/014-dependency-updates/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (D1–D7 consolidadas)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (oracle-cli.md)
├── checklists/
│   └── requirements.md  # Spec quality (16/16)
├── evidence/            # TESTS: red.txt + green.txt (Fase TESTS)
├── spec.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root — só config, sem produção)

```text
.github/
├── dependabot.yml              # NOVO: ecossistemas uv + github-actions, grupos, prefixo
└── workflows/
    ├── ci.yml                  # INTOCADO (fronteira 003/010)
    ├── release.yml             # INTOCADO (fronteira 013)
    └── dependabot-automerge.yml# NOVO: gate de ator + merge --auto
lefthook.yml                    # AJUSTE FR-003 via ADR-017: pip-audit pre-commit → pre-push
pyproject.toml                  # override click MANTIDO (D5); sem [tool.pip-audit] (invariante)
uv.lock                         # fonte única; bumps futuros via bot, não à mão
scripts/verify/
├── f0-014-dependabot.sh        # NOVO: 11 asserções identidade
└── manifest.sha256             # +14ª linha (no commit vermelho junto, precedente E5)
specs/README.md                 # 014 ✅ + hash (só no CONVERGE)
```

**Structure Decision**: config-e-oráculo, sem pacote novo; todo artefato versionado existente permanece intocado fora do ponto único autorizado.

## Complexity Tracking

> Sem violações no Constitution Check — nada a justificar.

## Fases de execução (para TASKS/IMPLEMENT)

- **Fase A (esqueleto)**: oráculo `f0-014` esqueleto + 14ª linha do manifest (o manifest inteiro é verificado por `f0-009/010/011/012` — separar do vermelho causaria regressão, precedente E5).
- **Fase B (vermelho 🔴)**: `test(harness)`: oráculo reprovando sobre estado sem bot (commit separado, `evidence/red.txt`).
- **Fase C (verde 🟢)**: `feat(deps)`: `dependabot.yml` + automerge + `lefthook.yml` (ponto ADR-017 aplicado AQUI, nunca antes) + `uv sync` coerente; re-verificar Q6 (override `click`) e registrar o veredito no commit.
- **Fase D (converge)**: harness 14/14 + manifest 14/14 + `tasks.md` zero `[ ]` + `specs/README.md` `014 ✅` + `AGENTS.md`; primeiro PR real do bot como SC-007 🧑 (fora do merge desta spec se nenhum bump existir — divergência declarada, precedente 010/SC-005).
