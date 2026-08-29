# Feature Specification: Fundação de Versionamento e Convenções do Motor

**Feature Branch**: `001-git-branching-strategy`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Fase 0, item 0.9 (001/012 na ordem de execução): Estabelecer o repositório Git e a estratégia de branching/commits do motor fluksos-x."

**Item do plano**: 0.9 (§17 Fase 0) · **Ordem de execução**: 001 de 012
**Pesquisa vinculante**: `docs/plan/research/f0-001-git-branching.md` (decisões Q1–Q5)

---

## Contexto

O fluksos-x é construído pelo próprio processo determinístico que ele executará.
Isso impõe uma exigência incomum a este primeiro item: o histórico do repositório
não é apenas armazenamento — é **a evidência auditável de que o processo foi
seguido**. A prova de que um teste foi escrito antes da implementação (TDD) é o
próprio par de commits vermelho→verde. Sem um repositório com convenções firmes
desde o commit zero, os onze itens seguintes da Fase 0 perdem a capacidade de
serem verificados após o fato.

Este item é, portanto, a fundação de auditabilidade de todo o restante do
bootstrap.

---

## Clarifications

### Sessão 2026-08-29

Varredura de cobertura aplicada manualmente segundo a taxonomia de 10 categorias
de `/speckit-clarify`, após a conclusão de `/speckit-plan`. Nove categorias
avaliadas como *Clear* — a pesquisa Q1–Q5 e os experimentos E1–E10 haviam
resolvido as ambiguidades antes da redação da spec. Uma categoria retornou
*Partial*:

- **Q**: Os artefatos de integração de agente de IA instalados no repositório
  (as habilidades do motor de especificação) pertencem ao histórico versionado, e
  qual o destino da configuração local de máquina?
  **A**: Sim — os artefatos de integração são versionados; a configuração local
  de máquina é excluída. Registrado como **FR-023**.

  **Fundamentação**: a ferramenta de especificação já sinaliza sua própria
  intenção ao excluir apenas dois arquivos de estado local e manter todo o
  restante versionável. Os artefatos de integração de agente são a outra metade
  da mesma instalação; tratá-los de forma diferente seria incoerente. A razão de
  fundo é mais forte: versioná-los **fixa o protocolo de especificação exato com
  que o motor foi construído**. Num projeto cuja tese é determinismo, protocolo
  que deriva sem registro faz o processo derivar junto.

  **Urgência**: o commit inicial é irreversível, portanto a decisão precisava
  ocorrer antes da implementação, não depois.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fundação versionada e livre de vazamentos (Priority: P1)

O mantenedor precisa de um repositório onde o trabalho do motor passe a ser
registrado, e onde seja estruturalmente impossível que um segredo, um artefato
descartável ou um cache de ferramenta entre no histórico por descuido. O
histórico é permanente: um segredo que entra uma vez permanece recuperável para
sempre, mesmo que removido depois. A proteção precisa existir **antes** do
primeiro registro, não depois.

**Why this priority**: Nada mais neste projeto pode ser registrado antes que
exista onde registrar. E, pela Lei Zero de segurança do motor, o "onde" precisa
já nascer com as exclusões corretas — a ordem importa, porque o primeiro commit
é irreversível.

**Independent Test**: Criar arquivos-isca representando cada categoria proibida
(um arquivo de segredo, um ambiente virtual, bytecode compilado, uma sessão
efêmera, um cache de ferramenta) e confirmar que nenhum deles é considerado
versionável; em seguida criar o arquivo de trava de dependências e confirmar
que ele **é** considerado versionável. Entrega valor sozinho: um repositório
seguro para começar a trabalhar.

**Acceptance Scenarios**:

1. **Given** um diretório de trabalho sem repositório, **When** a fundação é
   estabelecida, **Then** existe um repositório cuja linha principal se chama
   `main`, mesmo que a preferência global da máquina do desenvolvedor indique
   outro nome.
2. **Given** a fundação estabelecida, **When** o mantenedor consulta as linhas
   de trabalho existentes, **Then** encontra `main` (linha estável) e `develop`
   (linha de integração), ambas apontando para o mesmo registro inicial.
3. **Given** a fundação estabelecida, **When** um arquivo de segredo é criado no
   diretório de trabalho, **Then** o sistema de versionamento não o oferece para
   registro e nenhum comando de registro em massa o inclui.
4. **Given** a fundação estabelecida, **When** o arquivo de trava de dependências
   é criado, **Then** o sistema de versionamento o oferece para registro
   normalmente.
5. **Given** a fundação estabelecida, **When** o registro inicial é criado,
   **Then** ele contém o plano e a pesquisa já produzidos e nenhum item de
   categoria proibida.
6. **Given** a fundação estabelecida, **When** a autoria do registro inicial é
   inspecionada, **Then** ela corresponde à identidade definida para este
   repositório, sem que a preferência global da máquina tenha sido alterada.

---

### User Story 2 - Oráculo executável de conformidade (Priority: P2)

O mantenedor e os agentes precisam de uma forma de perguntar à máquina — e não a
um julgamento humano — se a fundação está conforme. A resposta precisa ser
binária, repetível e obtida sem instalar nada além do que a máquina já possui
neste ponto do bootstrap, porque as ferramentas de qualidade do projeto ainda
não existem (chegam nos itens 004 a 008).

**Why this priority**: É a semente do harness. Todo item subsequente da Fase 0
herda este mecanismo e acrescenta suas próprias asserções a ele. Sem um oráculo
desde o item 001, "está pronto" volta a ser opinião.

**Independent Test**: Executar o oráculo em um estado que viola pelo menos um
critério e observar reprovação com indicação do critério violado; executá-lo
novamente no estado conforme e observar aprovação. Executá-lo duas vezes
seguidas no mesmo estado e observar resultado idêntico.

**Acceptance Scenarios**:

1. **Given** a fundação ainda não implementada, **When** o oráculo é executado,
   **Then** ele reprova e nomeia cada critério não atendido.
2. **Given** a fundação implementada, **When** o oráculo é executado, **Then**
   ele aprova todos os critérios.
3. **Given** um estado qualquer, **When** o oráculo é executado duas vezes
   consecutivas sem alteração no diretório, **Then** os dois resultados são
   idênticos.
4. **Given** uma máquina com apenas as ferramentas presentes no início do
   bootstrap, **When** o oráculo é executado, **Then** ele funciona sem exigir
   instalação de dependências adicionais.
5. **Given** o oráculo executado, **When** o resultado é consumido por um
   processo automatizado, **Then** o sucesso e a falha são distinguíveis por um
   código de saída, não apenas por texto.

---

### User Story 3 - Histórico classificável para release automático (Priority: P3)

O motor publicará versões e um registro de mudanças gerado automaticamente a
partir do histórico (addendum R2). Para isso, cada registro precisa declarar sua
natureza — correção, funcionalidade, documentação, mudança incompatível — de
forma que uma máquina consiga classificá-lo sem interpretação.

**Why this priority**: O valor só se materializa quando houver releases, o que
ocorre após a Fase 0. Mas a convenção precisa valer desde o primeiro registro,
pois histórico não se reescreve retroativamente sem custo.

**Independent Test**: Tomar qualquer registro do histórico e determinar
mecanicamente sua categoria e se ele representa uma mudança incompatível, sem
recorrer a leitura interpretativa da descrição.

**Acceptance Scenarios**:

1. **Given** a convenção documentada, **When** um registro é criado, **Then**
   sua natureza é declarada por um rótulo pertencente a um conjunto fechado e
   conhecido.
2. **Given** a convenção documentada, **When** um registro representa mudança
   incompatível, **Then** existe uma marcação inequívoca que o distingue dos
   demais.
3. **Given** a convenção documentada, **When** um registro afeta uma área
   específica do motor, **Then** é possível declarar essa área de forma
   opcional e padronizada.
4. **Given** o histórico completo do repositório, **When** ele é percorrido por
   um processo automatizado, **Then** 100% dos registros são classificáveis em
   exatamente uma categoria.

---

### User Story 4 - Rastreabilidade de fase e pacote pelo nome da linha de trabalho (Priority: P4)

Quem chega ao projeto — pessoa ou agente — precisa saber, apenas lendo o nome de
uma linha de trabalho, a que fase do plano ela pertence, que parte do motor ela
toca e o que ela faz. Isso substitui a consulta a documentação externa durante a
navegação.

**Why this priority**: É conveniência de navegação e organização. O trabalho
prossegue sem ela, mas o custo de introduzi-la depois é alto, pois nomes de
linhas de trabalho já criadas não se renomeiam sem ruído.

**Independent Test**: Apresentar um nome de linha de trabalho a alguém que nunca
viu o projeto e verificar se consegue identificar fase, pacote e propósito sem
outra fonte.

**Acceptance Scenarios**:

1. **Given** a convenção documentada, **When** uma nova linha de trabalho de
   funcionalidade é nomeada, **Then** o nome revela a fase, o pacote e o
   propósito, nessa ordem.
2. **Given** a convenção documentada, **When** o mantenedor precisa saber onde
   integrar uma linha de trabalho concluída, **Then** a documentação declara
   qual linha recebe integrações e qual representa o estado estável.

---

### Edge Cases

- **O diretório já contém um repositório.** A fundação não pode destruir
  histórico existente nem duplicar configuração. Deve reconhecer o estado e
  convergir para a conformidade sem perda.
- **A preferência global da máquina define outra linha principal.** A fundação
  precisa resultar em `main` independentemente disso, e sem modificar a
  preferência global — a máquina do desenvolvedor não é território do projeto.
- **Um arquivo proibido já está sendo rastreado antes da regra existir.** Uma
  regra de exclusão não remove do rastreamento o que já entrou. O oráculo precisa
  detectar essa condição, porque ela é exatamente o modo de falha que a Lei Zero
  visa impedir.
- **Uma regra ampla demais captura o arquivo de trava de dependências.** Padrões
  genéricos de exclusão de arquivos gerados podem alcançar a trava por acidente,
  desfazendo silenciosamente o controle de cadeia de suprimentos. Precisa haver
  verificação positiva explícita, não apenas ausência de menção.
- **Existe um arquivo-modelo de configuração que deve ser versionado enquanto o
  arquivo real não deve.** A regra precisa distinguir o modelo público do arquivo
  com valores reais.
- **A ferramenta de especificação mantém suas próprias exclusões.** Duplicar
  essas regras cria duas fontes de verdade que podem divergir; o projeto deve
  respeitar as exclusões que a ferramenta já gerencia em vez de reescrevê-las.
- **Um registro é criado com rótulo fora do conjunto.** Neste item não há
  bloqueio automático (ver Fora de Escopo); o oráculo deve, ainda assim, ser
  capaz de apontar registros não conformes já existentes no histórico.
- **O oráculo é executado antes de o repositório existir.** Ele deve reprovar de
  forma informativa, não falhar de forma abrupta.
- **A ferramenta de integração de agente cria configuração local de máquina após
  o commit inicial.** O arquivo ainda não existe no momento da fundação, mas
  surgirá durante o uso. A regra de exclusão precisa antecedê-lo, pois ele pode
  conter caminhos e permissões específicos da máquina do mantenedor.

---

## Requirements *(mandatory)*

### Functional Requirements

**Repositório e linhas de trabalho**

- **FR-001**: O sistema MUST estabelecer um repositório versionado na raiz do
  projeto cuja linha principal se chame `main`, de forma independente de
  qualquer preferência configurada globalmente na máquina do desenvolvedor.
- **FR-002**: O sistema MUST prover uma linha de integração chamada `develop`,
  derivada de `main`.
- **FR-003**: O sistema MUST registrar a identidade de autoria
  `Guilherme <pasqualini166@gmail.com>` no escopo deste repositório, e MUST NOT
  alterar qualquer configuração de escopo global da máquina.

**Convenções normativas**

- **FR-004**: O sistema MUST documentar um conjunto fechado de 11 rótulos de
  natureza de registro: `feat`, `fix`, `docs`, `test`, `refactor`, `ci`,
  `chore`, `perf`, `build`, `style`, `revert`.
- **FR-005**: O sistema MUST documentar um formato de mensagem de registro que
  admita declaração opcional de área afetada e uma marcação inequívoca de
  mudança incompatível.
- **FR-006**: O sistema MUST documentar a convenção de nomes de linhas de
  trabalho de funcionalidade no formato `feature/f<fase>-<pacote>-<funcionalidade>`.
- **FR-007**: O sistema MUST documentar qual linha representa o estado estável e
  qual recebe integrações.

**Higiene do histórico (Lei Zero)**

- **FR-008**: O sistema MUST impedir o rastreamento de arquivos de segredos e de
  variáveis de ambiente com valores reais.
- **FR-009**: O sistema MUST permitir o rastreamento de arquivos-modelo de
  configuração que não contenham valores reais.
- **FR-010**: O sistema MUST impedir o rastreamento de ambientes virtuais e de
  bytecode gerado.
- **FR-011**: O sistema MUST impedir o rastreamento de caches e relatórios
  produzidos pelas ferramentas de qualidade previstas nos itens 004 a 008.
- **FR-012**: O sistema MUST impedir o rastreamento dos artefatos efêmeros do
  motor: histórico de sessões, relatórios regeneráveis e área de trabalho
  temporária.
- **FR-013**: O sistema MUST garantir que o arquivo de trava de dependências
  permaneça rastreável, por ser instrumento de controle de cadeia de
  suprimentos.
- **FR-014**: O sistema MUST NOT redefinir exclusões que a ferramenta de
  especificação já gerencia por conta própria.
- **FR-023**: O sistema MUST versionar os artefatos de integração de agente de
  IA instalados no repositório, por fixarem o protocolo de especificação com que
  o motor é construído, e MUST excluir a configuração local de máquina desses
  mesmos artefatos.

**Registro inicial**

- **FR-015**: O sistema MUST criar um registro inicial que contenha o plano de
  implementação e a pesquisa já produzidos, e que obedeça à convenção definida
  em FR-004 e FR-005.

**Oráculo de conformidade**

- **FR-016**: O sistema MUST prover uma verificação executável que avalie cada
  requisito acima e comunique aprovação ou reprovação por código de saída.
- **FR-017**: A verificação MUST identificar nominalmente cada requisito
  reprovado.
- **FR-018**: A verificação MUST produzir resultado idêntico em execuções
  repetidas sobre o mesmo estado.
- **FR-019**: A verificação MUST operar usando apenas recursos já presentes na
  máquina no início do bootstrap, sem exigir instalação de dependências do
  projeto.
- **FR-020**: A verificação MUST detectar a condição em que um arquivo de
  categoria proibida já se encontra rastreado, e não apenas a existência da
  regra de exclusão.
- **FR-021**: A verificação MUST reprovar de forma informativa quando executada
  antes de o repositório existir.

**Rastreabilidade entre itens**

- **FR-022**: O sistema MUST declarar explicitamente o que entrega aos itens
  seguintes da Fase 0 e quais responsabilidades transfere a eles.

---

### Key Entities

- **Repositório**: o registro histórico do trabalho do motor. Atributos
  relevantes: linha principal, linhas de trabalho existentes, identidade de
  autoria no escopo local.
- **Linha de trabalho (branch)**: sequência nomeada de registros. Categorias:
  estável, de integração, de funcionalidade. Relaciona-se a uma fase do plano e
  a um pacote do motor.
- **Registro (commit)**: unidade atômica de mudança. Atributos: natureza
  (um dos 11 rótulos), área afetada (opcional), indicação de incompatibilidade,
  descrição, autoria.
- **Regra de exclusão**: declaração de que uma categoria de arquivo não pertence
  ao histórico. Categorias: segredos, ambientes, artefatos gerados, caches de
  ferramentas, efêmeros do motor. Possui a contraparte **regra de inclusão
  obrigatória**, aplicável à trava de dependências.
- **Oráculo de conformidade**: procedimento que avalia o estado do repositório
  contra os requisitos e emite veredito binário rastreável a requisitos
  individuais.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em qualquer momento do ciclo de vida do projeto, o número de
  arquivos de segredo, ambiente virtual, cache de ferramenta ou artefato
  efêmero presentes no histórico é **zero**, verificável por uma única execução
  do oráculo.
- **SC-002**: 100% dos registros do histórico são classificáveis
  automaticamente em exatamente uma das 11 categorias, sem leitura
  interpretativa.
- **SC-003**: O oráculo conclui em menos de 5 segundos e produz resultado
  idêntico em execuções consecutivas sobre o mesmo estado.
- **SC-004**: O oráculo reprova pelo menos um critério antes da implementação e
  aprova todos após, com ambas as execuções registradas como evidência do ciclo
  vermelho→verde.
- **SC-005**: Uma pessoa ou agente que nunca viu o projeto identifica a fase, o
  pacote e o propósito de qualquer linha de trabalho de funcionalidade apenas
  pelo nome, sem consultar outra fonte.
- **SC-006**: O oráculo executa com sucesso em uma máquina que possua apenas as
  ferramentas presentes no início do bootstrap, sem nenhuma instalação
  adicional.
- **SC-007**: Cada um dos 6 itens subsequentes da Fase 0 que dependem deste
  encontra seu contrato declarado por escrito, sem necessidade de inferência.

---

## Contratos *(específico do bootstrap da Fase 0)*

Conforme a regra de contrato entre specs acordada para as 12 specs sequenciais.

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **Todos os itens 002–012** | Repositório em `main`, linha `develop`, convenção de registro normativa, identidade de autoria local |
| **Todos os itens 002–012** | Prova vermelho→verde viável: o histórico passa a ser evidência auditável do processo |
| **003** (0.1 UV workspace) | Exclusão de ambientes virtuais já vigente; trava de dependências explicitamente **não** excluída |
| **005** (0.2 Ruff) | Exclusão do cache da ferramenta de lint já vigente |
| **006** (0.3 MyPy) | Exclusão do cache do verificador de tipos já vigente |
| **007** (0.4 Pytest) | Exclusão de cache e relatórios de cobertura já vigente; oráculo pronto para ser promovido a testes automatizados |
| **012** (0.10 tree.md) | Convenções de linha de trabalho documentadas e prontas para referência |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **002** (0.11 Constitution) | **Revalidação retroativa deste item** contra a constitution assim que ela for ratificada | Este é o único dos 12 itens cujos artefatos nunca enfrentam o portão constitucional real: no momento de sua execução a constitution é modelo em branco. O portão substituto do `plan.md` avalia os princípios do plano e do addendum, mas não substitui a ratificação. Sem esta transferência, 001 escapa permanentemente da governança que rege 002–012 |
| **002** (0.11 Constitution) | **Consumir e retirar o material de referência transitório**: consultar `docs/AGENTS-EXAMPLE.md` ao redigir a constitution, e então remover o arquivo **e** a entrada transitória correspondente no `.gitignore` | O material fica fora do histórico por decisão do mantenedor (ADR-004). Uma exclusão sem alvo, sobrevivendo ao item 002, seria dívida silenciosa que ninguém saberia explicar |
| **008** (0.5 Lefthook) | Bloqueio automático de registros fora da convenção, por meio de mecanismo versionado | A ferramenta de hooks só existe no item 008; mecanismos nativos não versionáveis não são determinísticos |
| **008 / 009** (0.5 / 0.12) | Varredura ativa de segredos no conteúdo dos arquivos | Este item impede por categoria de arquivo; a varredura por conteúdo exige ferramenta ainda ausente |
| **Pós-Fase 0** | Geração automática do registro de mudanças e versionamento semântico | Depende de histórico acumulado e de publicação, ambos posteriores à Fase 0 |
| **Fora da Fase 0** | Repositório remoto e sincronização | Não faz parte do bootstrap local |

---

## Assumptions

- O bootstrap ocorre com um único mantenedor em máquina local, sem repositório
  remoto e sem colaboração concorrente. Fluxos de revisão entre pares e proteção
  de linhas de trabalho ficam fora deste item.
- A máquina possui um sistema de versionamento em versão recente o bastante para
  permitir nomear a linha principal no ato da criação — verificado durante a
  pesquisa (`docs/plan/research/f0-001-git-branching.md`, Q2).
- A máquina possui um interpretador Python 3.12 e um interpretador de scripts de
  shell, ambos verificados presentes. O oráculo não pode assumir mais que isso,
  porque as ferramentas do projeto ainda não foram instaladas.
- O documento de governança do projeto ainda é um modelo não preenchido; ele é
  objeto do item 002. Até lá, os princípios normativos vigentes são os expressos
  em `docs/plan/implementation_plan.md` e `docs/plan/addendum_v3.md`.
- O conjunto de 11 rótulos adotado é um superconjunto dos 7 declarados no §18 do
  plano. Os 4 adicionais (`perf`, `build`, `style`, `revert`) provêm do conjunto
  canônico da convenção e são necessários para a classificação automática de
  releases exigida pelo addendum R2. Decisão registrada na pesquisa, Q1.
- A ferramenta de especificação gerencia suas próprias exclusões de estado local;
  o projeto as respeita em vez de duplicá-las.
- Este item não altera nem depende do estado do serviço de contêineres, que nesta
  máquina é iniciado e encerrado manualmente por decisão do mantenedor.
