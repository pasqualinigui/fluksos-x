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

- [x] No [NEEDS CLARIFICATION] markers remain
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

### Iteração 1 — SPECIFY, 2026-09-06

**Falhas corrigidas antes de registrar:**

1. *No implementation details* — a primeira redação nomeava ferramenta e formato
   dentro dos FRs. Corrigido: os FRs declaram **o que** deve valer, e o *como*
   fica no PLAN. As duas exceções deliberadas são os **pins exatos** (FR-001,
   FR-013): num item de bootstrap o pin verificado **é** o requisito, pelo
   princípio VIII — mesmo padrão das specs 005–012.

2. *Scope is clearly bounded* — a redação inicial não dizia o que **não** entra.
   Corrigido no Contexto.

**Estado ao fim da iteração 1**: 15/16 itens passando; o único aberto era
`No [NEEDS CLARIFICATION] markers remain`, com 3 marcadores.

### Iteração 2 — CLARIFY, 2026-09-06

Varredura estruturada por taxonomia (`/speckit-clarify`). Achou **2 lacunas de
alto impacto** que a redação original não continha, além dos 3 marcadores:
**quem aciona o release** (papéis: Partial) e **aceitação parcial entre os dois
pacotes** (ciclo de vida: Missing; confiabilidade e falha de serviço externo:
Partial). Cinco perguntas no total — o teto do fluxo.

| # | Pergunta | Resposta | Onde foi aplicada |
|---|---|---|---|
| Q1 | Quem decide que uma publicação acontece? | ato deliberado do mantenedor (tag) | FR-006, borda *Integração sem tag*, SC-010 |
| Q2 | Como a versão alcança a linha protegida? | desenho B — proposta de mudança com os 10 checks | FR-012 |
| Q3 | Aceitação parcial entre os dois pacotes? | reexecução idempotente, mesma versão | FR-009, US3 cenário 4, 2 bordas, SC-009 |
| Q4 | `1.0.0` ou `0.x` na Fase 0? | `0.x` enquanto a Fase 0 não fechar | FR-004 |
| Q5 | Inventário efêmero ou versionado? | efêmero, anexado à publicação | FR-011 |

**Terminologia normalizada**: `release` passa a ser o termo canônico (o mesmo do
plano, §17 item 0.15), com `liberável` como forma adjetiva. As 24 ocorrências de
"liberação" foram substituídas; a única remanescente é a nota de glossário em
*Assumptions*, que registra o termo anterior uma vez, como manda a convenção.

**Consequência de escopo registrada**: Q5 = efêmero significa que a 013 **não
aciona o procedimento ADR-017** — nenhuma asserção de oráculo anterior é tocada.
Seria o primeiro item desde a 009 nessa condição. Se o PLAN descobrir necessidade
de versionar os artefatos, a decisão volta ao CLARIFY, não ao PLAN (regra 7).

**Estado**: **16/16 itens passando.** Nenhum marcador aberto.

### Cobertura ainda não resolvida (baixo impacto, deliberadamente não perguntada)

- **Observabilidade do fluxo de release**: princípio X já obriga nomear requisito
  e evidência; detalhe de saída é desenho do PLAN.
- **Releases concorrentes**: um mantenedor, uma linha de integração (ADR-032);
  probabilidade desprezível hoje. Reabre se a condição de saída da ADR-032
  disparar (segundo colaborador com escrita).

### Iteração 3 — correção de procedência, 2026-09-06

Pergunta do mantenedor sobre OIDC/Sigstore expôs **erro de método no RESEARCH**,
não na spec: a Q6 afirmava que `uv publish` sobe atestados PEP 740 por padrão.
Era inferência a partir da flag `--no-attestations`, apresentada dentro de uma
linha rotulada `Fonte (P0, executada)`.

Verificado contra a fonte: `uv publish` **não gera** atestado (docs uv, e as
issues `astral-sh/uv#19489` e `#15618` abertas); a documentação do PyPI nomeia
`pypa/gh-action-pypi-publish` como quem gera e envia por padrão sob trusted
publishing.

**Efeito na spec**: FR-009 ganha a cláusula de procedência; US3 ganha o cenário 5
(verificação por terceiro); SC-011 acrescentado; Contexto e Contratos atualizados.
Contagem de FRs permanece **16** — a procedência é propriedade do ato de publicar,
não requisito novo, então foi dobrada no FR-009 em vez de romper a faixa 12–16.

**Regra de método que o achado acrescenta**: em linha de `Fonte`, só entra o que
a fonte diz; consequência derivada vai para `Achado`. Uma inferência dentro de
uma citação é indistinguível de evidência na releitura — foi assim que esta
passou pelo SPECIFY e pelo CLARIFY sem ser pega.

**Estado**: 16/16 itens passando. **Pronto para `/speckit-plan`.**
