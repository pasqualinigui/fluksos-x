# Specification Quality Checklist: Automação de release

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-09-06
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [ ] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

### Iteração 1 — 2026-09-06

**Falhas corrigidas antes de registrar:**

1. *No implementation details* — a primeira redação nomeava ferramenta e formato
   dentro dos FRs (`uv publish`, `cyclonedx1.5`, `id-token: write`). Corrigido: os
   FRs declaram **o que** deve valer ("identidade federada de vida curta",
   "formato padrão da indústria", "permissão declarada no menor escopo"), e o
   *como* fica no PLAN. As duas exceções deliberadas são os **pins exatos**
   (FR-001, FR-013): num item de bootstrap o pin verificado **é** o requisito,
   pelo princípio VIII — o mesmo padrão das specs 005–012, e a razão pela qual
   `f0-00X` FR-001 assere versão exata em todas elas.

2. *Scope is clearly bounded* — a redação inicial não dizia o que **não** entra.
   Corrigido no Contexto (014/015/016, imagem de container, canais de
   pré-lançamento, versões independentes por pacote).

**Item ainda aberto — [NEEDS CLARIFICATION] (3, o teto):**

| # | FR | Pergunta | Por que não tem padrão razoável |
|---|---|---|---|
| Q1 | FR-004 | `0.x` na Fase 0, ou `1.0.0` no primeiro release? | O padrão da ferramenta produz `1.0.0` num motor com 12/16 itens da Fase 0 — aceitar o padrão *é* uma decisão de produto, não um detalhe |
| Q2 | FR-012 | Desenho A (tag como fonte) ou B (proposta de mudança)? | Ambos satisfazem a restrição de não exigir bypass, com custos opostos (dependência nova vs. um PR por release); a pesquisa mediu, não decidiu |
| Q3 | FR-011 | Inventário efêmero ou versionado? | Versionado aciona ADR-017 sobre 3 asserções da `f0-008`; efêmero não. É escolha entre rastreabilidade no repositório e verdade no artefato |

Nenhuma delas é detalhe técnico: as três mudam escopo, fronteira ou fluxo de
trabalho. Por isso não foram resolvidas por suposição informada (regra do
skill: apenas quando existe padrão razoável).

**Estado**: pronto para `/speckit-clarify`. Não prosseguir a `/speckit-plan`
antes de fechar Q1–Q3 — a constituição posiciona a etapa de clarificação
**antes** de o planejamento derivar tarefas da ambiguidade.
