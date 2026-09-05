<!--
Sync Impact Report — ratificação inaugural
==========================================
Versão anterior : nenhuma (modelo não ratificado, 19 campos de preenchimento)
Versão nova     : 1.0.0
Tipo de mudança : MAJOR — primeira ratificação; a governança passa a existir

Princípios acrescentados (10):
  I    Determinismo sobre probabilidade
  II   Especificação precede código
  III  Teste antes da implementação
  IV   Definição de dados antes da implementação
  V    Segurança é a Lei Zero
  VI   O harness é o oráculo
  VII  Auto-reparo atualiza a documentação
  VIII Elo verificado antes de lógica
  IX   Agnosticismo de stack
  X    Observabilidade

Seções alteradas:
  Core Principles          — modelo de 5 slots preenchido com 10 princípios (I–X)
  Additional Constraints   — antes [SECTION_2_NAME]/[SECTION_2_CONTENT]
  Development Workflow     — antes [SECTION_3_NAME]/[SECTION_3_CONTENT]
  Governance               — antes [GOVERNANCE_RULES]
  Rodapé                   — versão, ratificação e última emenda preenchidas

Pendências deferidas:
  - Bloqueio automático de violações verificáveis mecanicamente → item 008 (Lefthook)
  - Teto agregado de tempo do harness completo                  → item 008
  - Primeira emenda e exercício do procedimento definido        → pós-Fase 0
  - Orientação específica para agentes além do construtor       → fora da Fase 0

Templates dependentes: `.specify/templates/plan-template.md` › Constitution Check
passa a ser preenchido a partir deste arquivo. O portão substituto usado nos itens
001 e 002 deixa de existir.

Rastreabilidade: `specs/002-constitution-ratification/` e `docs/plan/decisions.md`
(ADR-006, que transcreve os trechos do material de referência já removido).
-->

# fluksos-x Constitution

Motor determinístico multiagente de engenharia de software. Constrói, melhora,
migra e mantém qualquer sistema pela tríade ADD + SDD + TDD, com Harness
Engineering. O motor é construído usando a si mesmo — portanto esta governança
rege tanto o que ele produz quanto a forma como ele próprio é produzido.

Cada princípio declara um **enunciado normativo**, um **critério de violação
observável** e sua **origem**. Um princípio sem critério de violação não é
ratificável: a partir desta versão, violação de princípio é falha crítica
automática nas etapas de planejamento e análise, e um critério subjetivo
transforma esse mecanismo em gerador de falso positivo com aparência de
autoridade.

## Core Principles

### I. Determinismo sobre probabilidade

Toda decisão que possa ser expressa como regra MUST ser implementada como código
determinístico. Julgamento de modelo probabilístico MUST ficar restrito ao
roteamento entre regras — nunca à regra em si.

**Violation:** existe decisão de negócio ou de conformidade cujo resultado depende
da saída de um modelo, sem regra determinística equivalente que a valide.

**Source:** `docs/plan/implementation_plan.md` §1; material de referência do
mantenedor, transcrito em ADR-006 — *"LLMs are probabilistic, whereas most
business logic is deterministic and requires consistency."*

### II. Especificação precede código (NÃO NEGOCIÁVEL)

Nenhum artefato executável MUST ser criado ou alterado antes de existir
especificação aprovada que o descreva. Se a lógica muda, a especificação muda
**antes**.

**Violation:** existe registro que altera artefato executável sem especificação
correspondente, ou cuja especificação foi registrada depois do código.

**Source:** material de referência do mantenedor, ADR-006 — *"The Golden Rule: If
logic changes, update the SOP before updating the code."*; plano §17 (SDD).

### III. Teste antes da implementação (NÃO NEGOCIÁVEL)

Todo requisito MUST possuir verificação executável que reprove antes da
implementação e aprove depois. Ambas as execuções MUST ser preservadas como
evidência versionada.

**Violation:** não existe par de evidências vermelho→verde para o requisito, ou o
registro do verde precede o do vermelho no histórico.

**Source:** plano §17 (TDD); ADR-002. A prova é o par de registros, porque ela não
é recuperável depois do fato.

### IV. Definição de dados antes da implementação

Antes de implementar um componente, o formato dos seus dados de entrada e de
saída MUST estar declarado em artefato de modelo de dados versionado.

**Violation:** existe componente cujo contrato de entrada/saída não é encontrável
no modelo de dados ou nos contratos da sua especificação.

**Source:** material de referência do mantenedor, ADR-006 — *"Data-First Rule:
Coding only begins once the 'Payload' shape is confirmed."*

### V. Segurança é a Lei Zero

Segredo MUST NOT existir em código, log, mensagem de registro ou histórico. A
regra de exclusão MUST preceder a possibilidade de registro. Travas de
dependência MUST permanecer versionadas.

**Violation:** arquivo de categoria proibida consta do índice ou do histórico; ou
regra de exclusão cobre a trava de dependências.

**Source:** `docs/plan/addendum_v3.md` §9; item 001, FR-008..FR-013. É Lei Zero
porque histórico não se corrige: só se reescreve, e reescrita é incidente.

### VI. O harness é o oráculo

Conformidade MUST ser decidida por código de saída de verificação executável,
nunca por julgamento. Nenhum item MUST modificar a verificação de um item
anterior.

**Violation:** existe critério de aceitação sem asserção correspondente no
harness; ou o diff de um item altera o oráculo de outro.

**Source:** plano §14; ADR-002 e ADR-006, que tornam a segunda metade desta regra
mecanicamente verificável por resumo criptográfico.

### VII. Auto-reparo atualiza a documentação

Ao corrigir uma falha, o ciclo MUST registrar a causa no artefato normativo
correspondente, de modo que a mesma falha não possa repetir-se sem ser detectada.

**Violation:** existe correção de falha cujo registro não altera nenhum artefato
normativo — especificação, contrato, decisão arquitetural ou harness.

**Source:** material de referência do mantenedor, ADR-006 — *"Self-Annealing:
Update the corresponding file with the new learning so the error never repeats."*

### VIII. Elo verificado antes de lógica

Nenhuma lógica MUST ser construída sobre dependência externa cuja disponibilidade
e contrato não tenham sido verificados por execução mínima registrada. Pesquisa é
verificação, não memória.

**Violation:** existe código que consome serviço, ferramenta ou versão externa sem
evidência de verificação em `docs/plan/research/`.

**Source:** material de referência do mantenedor, ADR-006 — *"Handshake: Do not
proceed to full logic if the 'Link' is broken."*

### IX. Agnosticismo de stack

O motor MUST NOT assumir linguagem, framework ou ferramenta do sistema-alvo. Toda
dependência de stack MUST estar isolada atrás de adaptador declarado.

**Violation:** existe, fora de adaptador declarado, referência a ferramenta
específica do sistema-alvo.

**Source:** plano §1 e §6 — o motor desenvolve **qualquer** sistema. Foi por este
princípio que a fase de transferência para nuvem do material de referência foi
descartada (ADR-006).

### X. Observabilidade

Toda execução do motor MUST produzir saída rastreável a um requisito
identificado. Falha MUST nomear o requisito violado e a evidência observada.

**Violation:** existe caminho de falha que termina sem identificador de requisito
ou sem evidência na saída.

**Source:** plano §14; contrato de interface do oráculo, item 001 §3.

## Additional Constraints

**Escada de dependências.** Nenhum artefato pode exigir ferramenta que ainda não
existe no seu ponto do bootstrap. Um verificador que dependa de ferramenta
posterior está errado, ainda que funcione na máquina de quem o escreveu.

**Escopo da máquina.** Nenhum artefato do projeto escreve em configuração de
escopo global do sistema operacional ou do versionador. A identidade de autoria
vive em escopo local do repositório.

**Cadeia de suprimentos.** A trava de dependências é versionada e sua exclusão é
proibida. A regra é asserida positivamente pelo harness, para que uma regressão
futura reprove em vez de passar despercebida.

**Ambiente sob demanda.** Nada roda em segundo plano. Serviços containerizados
são ligados explicitamente e desligados após uso; reinício automático é proibido.

**Sem privilégio elevado.** Nenhum artefato versionado pode exigir privilégio de
administrador ou modo especial do sistema operacional em qualquer plataforma
suportada.

## Development Workflow

O ciclo canônico é normativo e não admite atalho:

```
RESEARCH → SPECIFY → CLARIFY → PLAN → TASKS → ANALYZE → TESTS 🔴 → IMPLEMENT 🟢 → CONVERGE
```

| Etapa | Papel | Princípio que a sustenta |
|---|---|---|
| RESEARCH | Verificar contra a fonte, nunca lembrar | VIII |
| SPECIFY | Declarar o quê, sem o como | II |
| CLARIFY | Fechar ambiguidade **antes** de o plano derivar tarefas dela | II |
| PLAN | Fixar o como, o modelo de dados e os contratos | I, IV |
| TASKS | Ordem executável com dependências explícitas | I |
| ANALYZE | Detectar divergência entre artefatos | VI, X |
| TESTS 🔴 | Verificação reprovando, evidência preservada | III |
| IMPLEMENT 🟢 | Até o verde, sem tocar o que já convergiu | III, VI |
| CONVERGE | Confirmar que o construído é o especificado | VI |

**A especificação é insumo do planejamento, nunca sua saída.** Um plano que
corrige a especificação faz o defeito desaparecer sem rastro, e a especificação
passa a concordar com o plano por construção. Achado de plano volta à etapa de
análise, que o formaliza com decisão registrada.

## Governance

Esta governança prevalece sobre qualquer outra prática do projeto. Em divergência
entre ela e a porta de entrada operacional, os planos ou a documentação de
contribuição, **ela prevalece** — e a divergência precisa ser corrigida, não
tolerada.

### Amendment Procedure

1. A emenda é proposta em especificação própria, com justificativa e o princípio
   afetado nomeado.
2. O impacto sobre artefatos já convergidos é avaliado **antes** da adoção.
3. Encontrada não conformidade em artefato já entregue, o ciclo **interrompe** e
   submete a decisão ao mantenedor: corrigir o artefato, emendar o princípio ou
   registrar exceção fundamentada. Nenhuma dessas saídas é aplicada
   automaticamente.
4. A emenda adotada atualiza a versão, o rodapé e o registro de impacto no topo
   deste arquivo.

### Versioning Policy

Versionamento semântico sobre a governança:

| Incremento | Quando |
|---|---|
| MAJOR | princípio removido ou redefinido de forma incompatível |
| MINOR | princípio acrescentado, ou seção normativa nova |
| PATCH | esclarecimento de redação que não altera o que é decidido |

Execução repetida da ratificação sobre conteúdo idêntico **não** produz versão
nova: a versão acompanha mudança de conteúdo, não execução de comando.

### Compliance Review Expectation

Toda etapa de planejamento preenche o portão de conformidade a partir deste
arquivo. Toda etapa de análise trata violação de princípio como falha
**crítica automática**. Todo item do bootstrap acrescenta seu oráculo ao harness
e nunca modifica os anteriores.

Orientação operacional de rotina vive em `AGENTS.md`, que remete a este arquivo
sem reproduzi-lo.

**Version**: 1.0.0 | **Ratified**: 2026-08-30 | **Last Amended**: 2026-08-30
