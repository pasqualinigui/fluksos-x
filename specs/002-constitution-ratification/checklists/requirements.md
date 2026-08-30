# Specification Quality Checklist: Ratificação da Governança e Porta de Entrada para Agentes

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
| *No implementation details* | Rascunho citava `constitution.md`, `AGENTS.md`, `CLAUDE.md` e a sintaxe de importação nos requisitos | Reescrito por capacidade: "governança", "porta de entrada", "local convencional do formato aberto", "agente que constrói o motor". Os nomes concretos ficam na pesquisa e serão fixados no `plan.md` |
| *Testable and unambiguous* | FR sobre princípios dizia apenas "declarativos e testáveis" — vago sobre o que torna um princípio testável | **FR-005** reescrito para o critério operacional: o enunciado precisa permitir emitir veredito de violação **sobre um artefato concreto** sem interpretação subjetiva. **SC-002** dá o método de verificação |
| *Success criteria measurable* | "porta de entrada pequena" não é mensurável | **SC-003** amarra ao orçamento medido automaticamente; **FR-014** o exige verificável |
| *Edge cases* | Faltava o caso mais consequente: a reavaliação retroativa encontrar violação num artefato já entregue | Acrescentado, com as três saídas possíveis e a exigência de registrar a decisão — será o primeiro precedente de conflito entre governança e trabalho entregue |
| *Scope bounded* | Não estava explícito que ratificar ≠ exercitar emenda | Fora de escopo declarado; transferido ao pós-Fase 0 |

### Decisões de escopo registradas

1. **Vocabulário em camadas, como no item 001.** A spec fala em "governança",
   "porta de entrada" e "agente que constrói o motor"; `plan.md` e `contracts/`
   fixam os nomes concretos. Mantém o item *No implementation details* honesto sem
   tornar a spec ilegível.

2. **Nenhum `[NEEDS CLARIFICATION]` emitido.** As nove decisões C1–C9 da pesquisa
   fecharam o que geraria ambiguidade — em especial C4 (o agente construtor não lê
   o arquivo do formato aberto) e C6 (o orçamento de tamanho é de adesão, não de
   capacidade). A spec as trata como premissas verificadas, não as reabre.

3. **FR-005 é o requisito de maior consequência do item.** A partir da
   ratificação, violação de princípio vira falha crítica automática em dez ciclos.
   Um princípio não decidível não é apenas inútil: é um gerador de falso positivo
   com aparência de autoridade. Daí o edge case que obriga a rebaixar a orientação
   não normativa qualquer princípio que não passe nesse teste durante a redação.

### Pontos de atenção para `/speckit-clarify` e `/speckit-plan`

- **Ordem irreversível (FR-019).** A remoção do material de referência transitório
  é a última ação do ciclo. Um plano que a coloque antes da revisão da governança
  satisfaz o requisito isoladamente e ainda assim destrói a única oportunidade de
  consulta.
- **A reavaliação retroativa (FR-017) pode gerar trabalho fora deste item.** Se
  encontrar violação num artefato do item 001, a decisão precisa ser explícita e
  registrada — não absorvida em silêncio.
- **FR-021 é uma restrição de não-regressão**, herdada da ADR-002: este item
  acrescenta seu oráculo, nunca edita o anterior.

### Iteração 2 — pós `/speckit-clarify` (2026-08-29)

Duas ambiguidades reais confirmadas e integradas; oito categorias já estavam
*Clear* graças à fase de RESEARCH que antecede o specify neste projeto.

| Achado | Efeito na spec |
|---|---|
| FR-017 não declarava o tratamento padrão de violação retroativa | **FR-017b** acrescentado: interromper e submeter ao mantenedor; proibido aplicar correção, emenda ou exceção automaticamente. Edge case realinhado |
| SC-006 trazia "10 segundos" sem fundamento declarado | Substituído pela regra derivada: **5 s por oráculo**, mesmo limite do item 001; a execução conjunta é a soma. Teto agregado transferido ao item 008 |

Nenhuma regressão: 16/16 permanecem aprovados. As duas mudanças **fortalecem**
itens já aprovados (*Success criteria are measurable*, *Requirements are testable
and unambiguous*) em vez de corrigir reprovações.

### Iteração 3 — pós `/speckit-analyze` (2026-08-30)

Análise cruzada de oito artefatos, sete passes mecânicos. **Zero issues CRITICAL**,
cobertura 32/32 (24 FR + 8 SC), zero ambiguidade, zero duplicação, seis invariantes
de ordem preservados.

Um achado alterou a spec:

| Achado | Severidade | Efeito na spec |
|---|---|---|
| **S1** — `SC-008` intestável como escrito: exigia que nenhuma regra de exclusão apontasse para alvo inexistente, mas 79 das 80 regras literais vigentes estão nessa condição **por construção** | HIGH | `SC-008` reescrito, restrito a exclusões **marcadas como transitórias**, com a medição citada no próprio critério |

Dois achados fora da spec, também aplicados: **C1** (nota do contrato do oráculo
contradizia a existência de `FR-017b` como requisito de spec) e **R1** (a pesquisa
de domínio vinculante carregava "18 placeholders" contra 19 medidos).

O achado S1 foi **descoberto pela pesquisa técnica do plano e deliberadamente não
aplicado por ela**. O plano registrou a interpretação correta em três lugares e
devolveu o texto a esta etapa. Se o plano tivesse editado a spec, o defeito
desapareceria sem rastro e a spec passaria a concordar com o plano por construção —
que é o modo de falha exato que o SDD existe para impedir.

Nenhuma regressão: **16/16 permanecem aprovados**. A mudança **fortalece**
*Success criteria are measurable* — um critério intestável era, até aqui, um
falso positivo desta própria checklist.

**Veredito**: todos os itens aprovados. Spec pronta para `/speckit-implement`.
