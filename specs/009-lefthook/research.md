# Research: Lefthook — orquestração pre-commit do harness

**Fonte vinculante**: `docs/plan/research/f0-009-lefthook.md` (Q1–Q10, fetch 2026-09-04) · **Consolidação**: decisões abaixo, sem NEEDS CLARIFICATION restante (pin e modos resolvidos no CLARIFY 2026-09-04).

## Decision: pin 2.1.12 via wrapper PyPI em dev + `min_version` declarativo

- **Decision**: `lefthook==2.1.12` em `[dependency-groups] dev` (hash `uv.lock`) + `min_version: 2.1.12` no `lefthook.yml`.
- **Rationale**: latest estável com fix fail-closed #1484; instalação pelo lock mantém fonte única e o padrão 005–008; `min_version` faz a própria ferramenta recusar versão errada.
- **Alternatives considered**: 2.1.11 (fidelidade ao plano — rejeitada: defasagem de 1 dia no freeze, sem ganho); binário manual (fora do lock — reserva); brew/npm/go (fora do toolchain UV — rejeitados).

## Decision: hooks somente-leitura, sem auto-correção

- **Decision**: jobs `pre-commit` só verificam (`ruff check`, `format --check`); sem `--fix`, sem `stage_fixed`; `fail_on_changes` dispensado.
- **Rationale**: princípios I+VI+X e "observa, nunca corrige" — correção pelo hook gera estado não atribuído a commit humano.
- **Alternatives considered**: `stage_fixed: true` (rejeitado: reescreve + re-encena silenciosamente); `fail_on_changes` (dispensado: nada escreve, nada há para falhar-aberto).

## Decision: `trivy fs` só no pre-push (+ skip sem Docker)

- **Decision**: scan fora do `pre-commit`; `pre-push` executa; ausência de Docker = skip documentado.
- **Rationale**: valor P1 do item é feedback em segundos; precedente 008-FR-009 normalizou o skip; cobertura antes do push + portão no CI.
- **Alternatives considered**: em todo commit (rejeitado: taxa iteração); nos dois (rejeitado: redundância sem ganho de portão).

## Decision: `pre-push` espelha o harness; CI intocado

- **Decision**: `pre-push` roda `for f in scripts/verify/f0-*.sh`; `.github/` intocado (glob inclui `f0-009`).
- **Rationale**: ADR-009 (hook conveniência, portão no servidor); padrão FR-012/006.
- **Alternatives considered**: required-checks nesta spec (rejeitado: é 010); hook de mensagem de commit (rejeitado: é 010).

## Decision: fronteira via ADR prévia (procedimento ADR-017)

- **Decision**: tabela de impacto no PLAN + ADR-018 antes de qualquer merge; diffs padrão `uv.lock`; aplicação só na Fase C.
- **Rationale**: achado A1 da auditoria 005–008 (pós-fix silencioso proibido); conflito genuíno exige decisão, não edição.
- **Alternatives considered**: ajustar junto sem ADR (rejeitado: repetiria A1); não ajustar (impossível: harness reprovaria estado correto).
