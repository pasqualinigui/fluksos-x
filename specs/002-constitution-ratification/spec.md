# Feature Specification: Ratificação da Governança e Porta de Entrada para Agentes

**Feature Branch**: `002-constitution-ratification`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Fase 0, item 0.11 (002/012 na ordem de execução): Ratificar a constitution do motor fluksos-x e estabelecer a porta de entrada operacional para agentes."

**Item do plano**: 0.11 (§17 Fase 0) · **Ordem de execução**: 002 de 012
**Pesquisa vinculante**: `docs/plan/research/f0-002-constitution.md` (decisões C1–C9)
**Contrato de entrada**: `specs/001-git-branching-strategy/spec.md` › Contratos

---

## Contexto

O item 001 estabeleceu onde o trabalho é registrado e como provar que foi feito
corretamente. Este item estabelece **contra o quê** ele é julgado.

Há uma consequência mecânica que torna este item diferente de documentação: a
partir da ratificação, toda etapa de planejamento passa a preencher um portão de
conformidade a partir destes princípios, e toda etapa de análise passa a tratar
violação como falha **crítica automática**. Um princípio redigido de forma que
não permita decidir se foi violado não é uma boa intenção — é ruído injetado em
dez ciclos subsequentes, e ruído que se apresenta como autoridade.

Este item também é o único ponto do bootstrap em que o portão substituto usado
até aqui deixa de existir. Depois dele, não há mais "avaliação contra os
documentos de planejamento": há avaliação contra governança ratificada.

Por fim, o item 001 transferiu três obrigações a este item. Elas não são
opcionais nem adiáveis: uma delas é a única oportunidade restante de consultar um
material de referência que sai de circulação ao fim deste ciclo.

---

## Clarifications

### Session 2026-08-29

- Q: Se a reavaliação retroativa encontrar um artefato do item 001 violando um
  princípio recém-ratificado, qual deve ser o tratamento padrão? → A: **Parar e
  consultar o mantenedor.** O ciclo registra o achado e interrompe; a escolha
  entre corrigir o artefato, emendar o princípio ou registrar exceção é do
  mantenedor, caso a caso. Motivo: este é o **primeiro precedente** de conflito
  entre governança e trabalho já convergido — um padrão automático viraria
  jurisprudência sem decisão humana.
- Q: O orçamento de tempo do harness deve ser por oráculo ou um teto total para a
  Fase 0 inteira? → A: **Por oráculo, no máximo 5 segundos cada**; a execução
  conjunta é a soma. Composicional, escala sem número arbitrário, e mantém a
  regra idêntica à do item 001. Teto total agregado fica fora de escopo e é
  reavaliado no item 008, quando o custo real de um bloqueio pré-registro for
  conhecido.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Governança executável, não decorativa (Priority: P1)

O mantenedor precisa que os princípios que regem o motor deixem de viver
espalhados por documentos de planejamento e passem a existir como governança
ratificada, versionada e — sobretudo — **decidível**. Para cada princípio, deve
ser possível olhar um artefato e responder "isto viola ou não viola?" sem
recorrer a interpretação pessoal.

**Why this priority**: dez itens subsequentes serão julgados por estes
princípios, e violação será tratada como falha crítica automática. Princípio
ambíguo transforma esse mecanismo em gerador de falso positivo, ou pior, em
carimbo que todos aprendem a ignorar.

**Independent Test**: tomar cada princípio e um artefato real do repositório, e
verificar se é possível emitir veredito de conformidade sem discussão sobre o que
o princípio quis dizer. Entrega valor sozinho: o portão substituto deixa de ser
necessário.

**Acceptance Scenarios**:

1. **Given** governança em estado de modelo não preenchido, **When** a ratificação
   ocorre, **Then** nenhum campo de preenchimento permanece sem valor ou sem
   justificativa explícita para ter sido deixado em aberto.
2. **Given** a governança ratificada, **When** um princípio é lido isoladamente,
   **Then** ele afirma uma regra em forma declarativa e indica como sua violação
   se manifesta.
3. **Given** a governança ratificada, **When** o mantenedor pergunta de onde veio
   um princípio, **Then** encontra a origem registrada, sem precisar reconstituir
   a decisão.
4. **Given** a ratificação concluída, **When** o mantenedor consulta o registro de
   impacto, **Then** encontra a versão anterior, a nova, o que foi acrescentado e
   as pendências deliberadamente deferidas.
5. **Given** a governança ratificada, **When** uma etapa de planejamento é
   executada em qualquer item seguinte, **Then** ela avalia o portão contra estes
   princípios e não contra documentos de planejamento.

---

### User Story 2 - Oráculo de conformidade deste item (Priority: P2)

O mantenedor precisa perguntar à máquina se a governança e a porta de entrada
estão conformes, com resposta binária e repetível, usando apenas o que a máquina
já possui — as ferramentas de qualidade do projeto ainda não existem.

**Why this priority**: é a única prova de que este item foi feito na ordem certa,
e é o mecanismo que impede regressão silenciosa dos princípios recém-ratificados.
Sem ele, "a governança está correta" volta a ser opinião — precisamente o que a
governança existe para eliminar.

**Independent Test**: executar em estado incompleto e observar reprovação nominal
por requisito; executar no estado conforme e observar aprovação; executar duas
vezes e obter resultado idêntico.

**Acceptance Scenarios**:

1. **Given** a governança ainda não ratificada, **When** o oráculo é executado,
   **Then** reprova e nomeia cada critério não atendido.
2. **Given** o item concluído, **When** o oráculo é executado, **Then** aprova
   todos os critérios.
3. **Given** o oráculo deste item, **When** ele é executado, **Then** obedece ao
   mesmo contrato de interface do oráculo do item anterior — mesmos códigos de
   saída, mesmo formato, mesmos parâmetros.
4. **Given** o oráculo do item anterior, **When** este item conclui, **Then**
   aquele permanece inalterado e continua aprovando integralmente.

---

### User Story 3 - Porta de entrada que o construtor efetivamente lê (Priority: P3)

Qualquer agente de codificação que chegue ao repositório precisa descobrir, sem
ler mil linhas de planejamento, o que é o motor, como operá-lo e onde estão as
regras. E o agente que **constrói** este motor precisa carregar essa orientação
em toda sessão, automaticamente.

**Why this priority**: sem ela, cada sessão recomeça reconstituindo contexto a
partir de documentos longos — o que é lento, caro e propenso a divergência entre
sessões. É valiosa, mas o trabalho prossegue sem ela; a governança, não.

**Independent Test**: abrir uma sessão nova do agente construtor num diretório
limpo do projeto e verificar se a orientação foi carregada sem nenhuma ação
manual; e verificar se um agente diferente encontraria a orientação no local
convencional do formato aberto.

**Acceptance Scenarios**:

1. **Given** o repositório, **When** um agente de codificação qualquer procura
   orientação no local convencional do formato aberto de mercado, **Then** a
   encontra.
2. **Given** o repositório, **When** o agente que constrói o motor inicia uma
   sessão, **Then** carrega a orientação automaticamente, sem ação manual e sem
   depender de privilégio administrativo em nenhuma plataforma.
3. **Given** a porta de entrada, **When** seu tamanho é medido, **Then** está
   dentro do orçamento que preserva a adesão do agente ao próprio conteúdo.
4. **Given** a porta de entrada, **When** ela é comparada com a governança e com
   o plano, **Then** não reproduz o texto integral de nenhum dos dois — remete a
   eles.
5. **Given** os dois arquivos que compõem a porta de entrada, **When** seus
   conteúdos são comparados, **Then** não há texto duplicado entre eles.
6. **Given** a porta de entrada, **When** um agente lê o ciclo de desenvolvimento,
   **Then** encontra a etapa de clarificação entre especificação e planejamento.

---

### User Story 4 - Quitação das obrigações herdadas (Priority: P4)

O item anterior transferiu três obrigações a este. Elas precisam ser cumpridas
aqui, e uma delas tem prazo real: o material de referência que fundamenta parte
dos princípios sai de circulação ao fim deste ciclo.

**Why this priority**: são dívidas conhecidas e registradas, não descobertas. Mas
a terceira é irreversível na prática — depois de removido o material, a
rastreabilidade dos princípios derivados dele depende exclusivamente do que for
registrado agora.

**Independent Test**: verificar que existe veredito escrito para cada artefato do
item anterior contra cada princípio; que a origem dos princípios derivados do
material de referência está registrada; e que não resta exclusão apontando para
alvo inexistente.

**Acceptance Scenarios**:

1. **Given** a governança ratificada, **When** os artefatos do item anterior são
   reavaliados contra ela, **Then** existe veredito registrado por escrito,
   nomeando princípio e artefato.
2. **Given** um princípio derivado do material de referência transitório,
   **When** sua origem é consultada, **Then** ela está registrada de forma que
   sobreviva ao desaparecimento do material.
3. **Given** o ciclo concluído, **When** o repositório é inspecionado, **Then** o
   material transitório não existe mais e nenhuma regra de exclusão aponta para
   ele.
4. **Given** a sequência de trabalho, **When** a remoção do material ocorre,
   **Then** ela é a última ação do ciclo, posterior à ratificação e à sua revisão.

---

### Edge Cases

- **A reavaliação retroativa encontra violação num artefato do item anterior.**
  O item anterior está concluído e registrado. O ciclo **interrompe** e submete a
  decisão ao mantenedor, entre corrigir o artefato, emendar o princípio ou
  registrar exceção fundamentada. Nenhuma dessas saídas é aplicada
  automaticamente: será o primeiro precedente de como o motor trata conflito
  entre governança e trabalho já entregue, e precedente não se estabelece por
  omissão.
- **Um princípio se mostra não decidível durante a própria redação.** Ele não pode
  ser ratificado como está: ou ganha critério objetivo de violação, ou é rebaixado
  a orientação não normativa numa seção separada.
- **O orçamento de tamanho da porta de entrada é excedido.** Repartir o conteúdo
  entre arquivos não resolve, porque conteúdo referenciado também é carregado. A
  única saída é reduzir de fato, promovendo texto a ponteiro.
- **O material de referência transitório é consultado, mas dele não deriva nenhum
  princípio novo.** Ainda assim a consulta precisa ficar registrada, sob pena de
  a obrigação parecer cumprida sem ter sido.
- **A ratificação é executada duas vezes.** A segunda execução não pode produzir
  versão nova sem mudança de conteúdo, nem duplicar o registro de impacto.
- **A porta de entrada e a governança divergem.** Se a porta de entrada afirmar
  algo que a governança contradiz, a governança prevalece — mas a divergência
  precisa ser detectável, não descoberta por acaso.

---

## Requirements *(mandatory)*

### Functional Requirements

**Governança ratificada**

- **FR-001**: O sistema MUST ratificar a governança do motor, sem deixar campo de
  preenchimento sem valor — salvo os explicitamente justificados como deferidos.
- **FR-002**: A governança MUST ser versionada segundo versionamento semântico,
  sendo a ratificação inicial a versão inaugural.
- **FR-003**: Todas as datas registradas MUST usar formato ISO de data.
- **FR-004**: A governança MUST conter dez princípios cobrindo: determinismo
  sobre probabilidade; especificação precede código; teste antes da
  implementação; definição de dados antes da implementação; segurança como lei
  zero; o harness como oráculo; auto-reparo que atualiza a documentação; elo
  verificado; agnosticismo de stack; observabilidade.
- **FR-005**: Cada princípio MUST ser declarativo e **decidível** — seu enunciado
  precisa permitir emitir veredito de violação sobre um artefato concreto sem
  recorrer a interpretação subjetiva.
- **FR-006**: Cada princípio MUST registrar sua origem, de modo que a
  rastreabilidade sobreviva ao desaparecimento das fontes transitórias.
- **FR-007**: A governança MUST declarar procedimento de emenda, política de
  versionamento e expectativa de revisão de conformidade.
- **FR-008**: O sistema MUST produzir um registro de impacto da ratificação
  contendo versão anterior, versão nova, o que foi acrescentado e as pendências
  deferidas.

**Porta de entrada operacional**

- **FR-009**: O sistema MUST prover orientação operacional no local convencional
  do formato aberto de mercado para agentes de codificação.
- **FR-010**: A orientação MUST conter identidade do motor, como operá-lo e
  ponteiros para as fontes normativas, e MUST NOT reproduzir o texto integral dos
  princípios nem do plano de implementação.
- **FR-011**: A orientação MUST ser carregada automaticamente pelo agente que
  constrói o motor, ao início de cada sessão, sem ação manual.
- **FR-012**: Os artefatos que compõem a porta de entrada MUST NOT duplicar texto
  entre si.
- **FR-013**: A solução MUST NOT depender de privilégio administrativo ou de modo
  especial do sistema operacional em nenhuma plataforma suportada.
- **FR-014**: A porta de entrada MUST respeitar um orçamento de tamanho
  verificável, abaixo do limite documentado a partir do qual a adesão do agente ao
  próprio conteúdo degrada.

**Ciclo de desenvolvimento**

- **FR-015**: O sistema MUST documentar de forma normativa o ciclo de
  desenvolvimento canônico, incluindo a etapa de clarificação entre a
  especificação e o planejamento.
- **FR-016**: A documentação de contribuição existente MUST refletir o ciclo
  atualizado, sem manter versão anterior em circulação.

**Obrigações herdadas do item anterior**

- **FR-017**: O sistema MUST reavaliar os artefatos entregues pelo item anterior
  contra a governança recém-ratificada, registrando veredito por escrito que
  nomeie princípio e artefato.
- **FR-017b**: Ao encontrar não conformidade num artefato já entregue, o sistema
  MUST interromper e submeter a decisão ao mantenedor, registrando o achado.
  MUST NOT aplicar correção, emenda ou exceção por conta própria.
- **FR-018**: O sistema MUST consultar o material de referência transitório ao
  redigir os princípios, e MUST registrar quais princípios dele derivam.
- **FR-019**: O sistema MUST remover o material de referência transitório e a
  regra de exclusão que o cobre, e essa remoção MUST ser a última ação do ciclo.

**Oráculo de conformidade**

- **FR-020**: O sistema MUST prover verificação executável que avalie os
  requisitos acima e comunique aprovação ou reprovação por código de saída,
  obedecendo ao mesmo contrato de interface do oráculo do item anterior.
- **FR-021**: O oráculo do item anterior MUST permanecer inalterado e MUST
  continuar aprovando integralmente ao fim deste item.
- **FR-022**: A verificação MUST reprovar antes da implementação e aprovar depois,
  com ambas as execuções preservadas como evidência.

**Rastreabilidade entre itens**

- **FR-023**: O sistema MUST declarar o que entrega aos itens seguintes e quais
  responsabilidades transfere a eles.

---

### Key Entities

- **Princípio**: regra normativa do motor. Atributos: numeração, nome, enunciado
  declarativo, critério de violação, origem. Um princípio sem critério de violação
  não é ratificável.
- **Governança**: conjunto ordenado de princípios mais as regras de emenda,
  versionamento e revisão. Atributos: versão, data de ratificação, data da última
  emenda.
- **Registro de impacto**: sumário de uma ratificação ou emenda. Atributos: versão
  anterior, versão nova, princípios acrescentados, seções alteradas, pendências
  deferidas.
- **Porta de entrada**: orientação operacional legível por agentes. Atributos:
  localização convencional, tamanho, conteúdo por referência.
- **Veredito de conformidade retroativa**: resultado da reavaliação de um artefato
  do item anterior contra um princípio. Atributos: artefato, princípio, veredito,
  fundamentação quando não conforme.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero campos de preenchimento permanecem na governança sem valor ou
  sem justificativa registrada.
- **SC-002**: 100% dos princípios permitem emitir veredito de violação sobre um
  artefato concreto sem interpretação subjetiva, verificável tomando cada
  princípio contra ao menos um artefato real do repositório.
- **SC-003**: A porta de entrada permanece dentro do orçamento de tamanho, medido
  automaticamente.
- **SC-004**: O agente que constrói o motor carrega a orientação em toda sessão
  sem nenhuma ação manual, em qualquer plataforma suportada.
- **SC-005**: A verificação reprova ao menos um critério antes da implementação e
  aprova todos depois, com ambas as execuções preservadas como evidência.
- **SC-006**: O harness acumulado — deste item e do anterior — aprova
  integralmente, e **cada oráculo isolado** conclui em menos de 5 segundos,
  mesmo limite adotado no item anterior. A execução conjunta é a soma dos
  oráculos; não há teto agregado nesta fase.
- **SC-007**: 100% dos artefatos entregues pelo item anterior possuem veredito
  registrado contra a governança ratificada.
- **SC-008**: Nenhuma regra de exclusão **marcada como transitória** aponta para
  alvo inexistente. Exclusão não marcada fica fora deste critério: apontar para
  alvo ainda inexistente é o comportamento **correto** de uma regra de exclusão —
  ela existe para preceder o arquivo que impede de entrar no histórico. A medição
  do repositório vigente confirma: 79 das 80 regras literais estão nessa condição
  por construção, e um critério que as reprovasse tornaria o oráculo inútil.

---

## Contratos *(específico do bootstrap da Fase 0)*

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **Todos os itens 003–012** | Portão de conformidade **real**: o portão substituto usado em 001 e 002 deixa de existir |
| **Todos os itens 003–012** | Dez princípios decidíveis, contra os quais planejamento e análise passam a julgar |
| **Todos os itens 003–012** | Porta de entrada operacional carregada automaticamente a cada sessão |
| **Todos os itens 003–012** | Ciclo canônico normativo, incluindo a etapa de clarificação |
| **001** (retroativo) | Veredito de conformidade dos artefatos já entregues |
| **008** (0.5 Lefthook) | Princípios que o bloqueio automático precisará refletir |
| **012** (0.10 tree.md) | Porta de entrada e governança prontas para referência no mapa do projeto |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **004** (0.4 Pytest) | Cobertura das **cinco lacunas de asserção** do harness do item 001: `SC-003` (tempo e determinismo empírico), `SC-004` (par vermelho→verde), `SC-007` (contratos declarados) e `FR-001` (mede a linha apontada por HEAD, não a existência da linha principal) | Decisão do mantenedor sob `FR-017b`, registrada na **ADR-007**. O item 004 já promove cada oráculo a módulo de teste, então as asserções entram como **casos novos, ao lado** — nunca dentro de `f0-001-foundation.sh`, o que preserva a ADR-002 e a asserção `FR-021a` deste item. A exceção **expira quando o item 004 convergir** |
| **008** (0.5 Lefthook) | Bloqueio automático de violações de princípio verificáveis mecanicamente | A ferramenta de hooks só existe no item 008 |
| **008** (0.5 Lefthook) | Decisão sobre teto agregado de tempo do harness completo | O custo real de um bloqueio pré-registro só é conhecido quando a ferramenta existir; até lá vale o limite por oráculo |
| **Pós-Fase 0** | Primeira emenda da governança e exercício do procedimento definido | Este item ratifica a versão inaugural e define o procedimento; exercitá-lo exige mudança real |
| **Fora da Fase 0** | Orientação específica para outros agentes de codificação além do construtor | O formato aberto já cobre o caso geral; adaptações específicas dependem de demanda real |

---

## Assumptions

- O bootstrap continua com um único mantenedor em máquina local, sem colaboração
  concorrente sobre a governança. O procedimento de emenda é definido, mas não
  exercitado neste item. O mantenedor é a autoridade de decisão em conflito entre
  governança e trabalho já entregue (FR-017b).
- O material de referência transitório permanece legível em disco até o momento
  de sua remoção — verificado durante a pesquisa.
- O agente que constrói o motor não lê o arquivo do formato aberto de mercado,
  conforme sua documentação oficial. Este fato é premissa da spec, não hipótese —
  está verificado em `docs/plan/research/f0-002-constitution.md`, Q4.
- O orçamento de tamanho da porta de entrada não é contornável por repartição em
  arquivos, porque conteúdo referenciado também é carregado no início da sessão.
  Verificado na mesma pesquisa, Q5.
- Os dez princípios cobrem áreas já identificadas nos documentos de planejamento e
  no material de referência transitório. Este item os ratifica e os torna
  decidíveis; não os descobre.
- Este item não produz código de aplicação: o protocolo de ratificação proíbe
  criar ou modificar fonte de aplicação.
- O oráculo deste item opera sob a mesma restrição de dependências do anterior —
  apenas o que a máquina já possui no início do bootstrap.
