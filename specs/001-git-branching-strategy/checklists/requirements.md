# Specification Quality Checklist: Fundação de Versionamento e Convenções do Motor

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-29
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

### Iteração 1 — achados e correções aplicadas

| Item | Achado | Correção |
|---|---|---|
| *No implementation details* | Rascunho inicial citava nomes de comandos e de arquivos (`git init -b main`, `.gitignore`, `uv.lock`, `.tmp/`) nos requisitos | Requisitos reescritos por **capacidade e categoria** ("arquivo de trava de dependências", "regra de exclusão", "área de trabalho temporária"). Os nomes concretos permanecem apenas na pesquisa e serão fixados no `plan.md` |
| *Success criteria technology-agnostic* | SC iniciais mencionavam códigos de saída e nomes de ferramentas | Reescritos como resultados observáveis: contagem zero de artefatos proibidos, 100% de registros classificáveis, tempo de execução, determinismo entre execuções |
| *Testable and unambiguous* | FR sobre higiene do histórico não distinguia "existe regra" de "arquivo já rastreado" | Separado em FR-008..FR-013 (regras) e **FR-020** (detecção de arquivo já rastreado), que é o modo de falha real |
| *Edge cases* | Faltavam os casos de repositório preexistente, regra ampla capturando a trava, e arquivo-modelo versionável | Três casos acrescentados, mais o caso de exclusões geridas por terceiros e o de oráculo executado sem repositório |

### Decisões de escopo registradas

1. **Git como assunto, não como escolha de implementação.** A spec descreve
   "sistema de versionamento", "linha de trabalho" e "registro" em vez de
   "git", "branch" e "commit". O termo Git aparece apenas no título do item e no
   contexto — é o objeto do trabalho, não uma alternativa técnica em aberto.
   Isso mantém o item *No implementation details* honesto sem tornar a spec
   ilegível.

2. **Nenhum `[NEEDS CLARIFICATION]` emitido.** Todas as decisões que poderiam
   gerar ambiguidade já foram resolvidas e registradas na pesquisa vinculante
   `docs/plan/research/f0-001-git-branching.md` (Q1 conjunto de rótulos, Q2 nome
   da linha principal, Q3 trava de dependências versionada, Q4 categorias de
   exclusão, Q5 fronteira do enforcement). A spec cita essas decisões como
   premissas em vez de reabri-las.

3. **Seção `Contratos` acrescentada ao template.** Não faz parte do modelo
   padrão, mas é exigida pela regra de contrato entre as 12 specs sequenciais da
   Fase 0 acordada com o mantenedor. Sem ela, FR-022 e SC-007 seriam
   inverificáveis.

### Ponto de atenção para `/speckit-plan`

- A ordem de execução é **normativa e não negociável**: as regras de exclusão
  precisam estar vigentes **antes** do registro inicial. Um plano que crie o
  repositório e registre o conteúdo antes de estabelecer as exclusões satisfaz
  os FR isoladamente mas viola SC-001, porque o histórico é irreversível.
- O oráculo precisa ser escrito e executado em estado de reprovação **antes** da
  implementação (SC-004). O plano deve tornar essa ordem explícita como duas
  etapas separadas, não como uma só.

**Veredito**: todos os itens aprovados. Spec pronta para `/speckit-plan`.
