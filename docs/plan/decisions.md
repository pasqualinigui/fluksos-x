# Architecture Decision Records — fluksos-x

Registro das decisões arquiteturais do motor. Uma ADR por decisão que afeta mais
de um item ou que não é derivável da leitura do código.

---

## ADR-001 — Numeração e ordem de execução das specs da Fase 0

**Data**: 2026-08-29 · **Status**: Aceita · **Item**: 001 (0.9)

### Contexto

O §17 do `implementation_plan.md` lista 12 itens para a Fase 0, numerados `0.1` a
`0.12`. O Spec-Kit, por sua vez, numera specs sequencialmente a partir de `001`
conforme a ordem em que são criadas. As duas numerações não coincidem, e a ordem
listada no plano **não é executável como está**.

### Problema

Três inversões de dependência na ordem do §17:

1. **`0.2` Ruff precede `0.4` Pytest** — mas a própria spec do Ruff exige um teste
   que valide a configuração. Sem pytest configurado não há como fazer TDD do
   item 0.2.
2. **`0.5` Lefthook precede `0.12` pip-audit/Trivy** — mas o `lefthook.yml`
   orquestra o pip-audit. Configurá-lo antes obrigaria a revisitá-lo depois.
3. **`0.9` Git aparece em nono lugar** — mas o Spec-Kit organiza o trabalho por
   feature desde a primeira spec, e a prova de TDD vermelho→verde depende do
   histórico existir.

### Decisão

As 12 specs são criadas na **ordem de dependência** abaixo. A numeração
sequencial do Spec-Kit (`001`–`012`) reflete essa ordem, não a do plano. Este
mapa é a fonte de verdade da correspondência.

> ⚠️ **SUPERSEDIDA — não use esta tabela.** A **ADR-011** a substitui: a Emenda 1
> do plano (ADR-009) acrescentou quatro itens à Fase 0 e alterou as posições de
> execução. A tabela abaixo permanece apenas como **registro histórico** do estado
> original de 12 itens. Cada linha vai prefixada por `HIST` para que uma busca por
> texto não a confunda com o mapa vigente.

| Spec | Item do plano | Título | Justificativa da posição |
|---|---|---|---|
| HIST `001` | **0.9** | Git + branching strategy | O Spec-Kit cria feature desde a primeira spec; a prova vermelho→verde exige histórico |
| HIST `002` | **0.11** | AGENTS.md / constitution | Governa as 10 specs seguintes; o portão constitucional do Spec-Kit lê este artefato |
| HIST `003` | **0.1** | UV workspace monorepo | Base física de todos os pacotes |
| HIST `004` | **0.4** | Pytest | Habilita TDD real dos itens seguintes — precisa vir antes de Ruff |
| HIST `005` | **0.2** | Ruff | |
| HIST `006` | **0.3** | MyPy strict | Consome contrato do Ruff: regras que conflitam com tipagem estrita |
| HIST `007` | **0.12** | pip-audit + Trivy | Precisa existir antes de ser orquestrado |
| HIST `008` | **0.5** | Lefthook | Orquestra 005, 006, 004 e 007 — só faz sentido depois deles |
| HIST `009` | **0.6** | `packages/core` | Primeiro código de produção |
| HIST `010` | **0.7** | `packages/cli` | Depende de `core` |
| HIST `011` | **0.8** | docker-compose | Domínio independente (DevOps) |
| HIST `012` | **0.10** | `docs/tree.md` | Por último: reflete a árvore real resultante |

### Consequências

- Referências cruzadas entre specs usam o número **do Spec-Kit** (`003`, `008`),
  nunca o do plano, para evitar ambiguidade. Este documento traduz entre os dois.
- O §17 do plano permanece como está, sem reescrita. Ele registra a intenção; esta
  ADR registra a execução. Reescrever o plano apagaria a evidência de que as
  inversões foram detectadas e por quê.
- Cada spec declara uma seção **Contratos** nomeando o que entrega aos itens
  seguintes e o que transfere a eles. É o mecanismo que substitui a coordenação
  que uma spec única daria.

### Alternativa rejeitada

**Agrupar os 12 itens em 4 specs coerentes** (fundação, harness de qualidade,
pacotes, infraestrutura). Reduziria o número de ciclos e resolveria os conflitos
entre Ruff e MyPy dentro de uma única spec. Rejeitada por decisão do mantenedor:
manter 12 ciclos preserva a granularidade de auditoria — cada item do plano tem
spec, plano, tarefas e convergência próprios e rastreáveis.

---

## ADR-002 — O oráculo de conformidade como harness incremental

**Data**: 2026-08-29 · **Status**: Aceita · **Item**: 001 (0.9)

### Contexto

O plano define o harness como "oráculo determinístico" (§14), mas as ferramentas
que o comporiam — pytest, Ruff, MyPy, pip-audit — só chegam nos itens `004` a
`007`. Os três primeiros itens precisariam ser verificados sem harness.

### Decisão

O harness nasce no item `001` como script em `scripts/verify/f0-001-foundation.sh`,
usando **apenas** o que a máquina já possui: interpretador de shell, git e Python
3.12 stdlib. Cada item subsequente acrescenta `scripts/verify/f0-NNN-<slug>.sh`
seguindo o mesmo contrato de interface (`contracts/oracle-cli.md` do item 001):
códigos de saída `0`/`1`/`2`, uma linha por asserção identificada pelo requisito,
`--quiet` e `--list`.

**Regra de não-regressão**: um item **nunca** modifica o oráculo de um item
anterior. Se um item invalida uma asserção anterior, isso é conflito de contrato
entre specs e sobe para decisão explícita, não para edição silenciosa.

O item `004` (pytest) promove cada oráculo a módulo de teste equivalente. O
parâmetro `--list` existe para que essa promoção enumere os casos sem precisar
interpretar o código do script.

### Consequências

- Nenhum item da Fase 0 fica sem verificação mecânica, inclusive os três que
  antecedem o pytest.
- O harness cresce por acréscimo e permanece auditável: doze arquivos pequenos em
  vez de um monólito.
- A restrição "sem dependências" vale apenas para os oráculos dos itens `001` a
  `003`. A partir de `004` os oráculos podem assumir pytest, e a partir de `005`
  e `006`, Ruff e MyPy.

---

## ADR-003 — Onde vivem as convenções normativas antes da constitution

**Data**: 2026-08-29 · **Status**: Aceita · **Item**: 001 (0.9)

### Contexto

O item `001` precisa estabelecer convenções de commit e de nome de linha de
trabalho. Os dois lugares naturais — `.specify/memory/constitution.md` e
`AGENTS.md` na raiz — são objeto do item `002`.

### Decisão

As convenções vão para **`CONTRIBUTING.md`** na raiz, local convencional e
independente da ferramenta de especificação, já previsto na estrutura final do
§15 do plano. O item `001` **não toca** `.specify/memory/constitution.md` e
**não cria** `AGENTS.md`.

Quando o item `002` ratificar a constitution, ela passa a ser a fonte normativa e
`AGENTS.md` a porta de entrada operacional; `CONTRIBUTING.md` permanece como
detalhamento das convenções de contribuição, referenciando-a.

### Consequência registrada como dívida

O item `001` é o **único dos doze** cujos artefatos nunca enfrentam o portão
constitucional real — no momento de sua execução a constitution é modelo em
branco com 18 placeholders. O `plan.md` do item aplica um portão substituto
contra os princípios de `implementation_plan.md` e `addendum_v3.md`, o que é
legítimo mas não equivale à ratificação.

**Por isso o item `002` recebe, via seção Contratos da spec 001, a
responsabilidade de revalidar retroativamente os artefatos do item `001` contra a
constitution recém-ratificada.** Sem essa transferência explícita, `001` escaparia
permanentemente da governança que rege `002`–`012`.

---

## ADR-004 — Exclusão temporária do material de referência do mantenedor

**Data**: 2026-08-29 · **Status**: Aceita, **transitória** · **Item**: 001 (0.9)
**Expira em**: item 002 (0.11)

### Contexto

`docs/AGENTS-EXAMPLE.md` é o prompt de sistema que o mantenedor usa hoje para
desenvolver, fora deste projeto. Foi colocado em `docs/` como insumo: cinco dos
dez princípios previstos para a constitution do motor derivam dele — determinismo
sobre probabilidade, a Golden Rule de spec antes de código, Data-First,
Self-Annealing e Elo Verificado.

### Decisão

O arquivo **não entra no histórico**. Recebe entrada no `.gitignore` marcada
explicitamente como transitória.

### Consequência e risco assumido

O item `002` depende deste arquivo para redigir a constitution, e ele não estará
sob controle de versão. Se for perdido do disco antes disso, a rastreabilidade
entre os princípios ratificados e sua origem se perde — e não há como
reconstruí-la a partir do repositório.

O risco é aceito por decisão do mantenedor. A mitigação é **mecânica, não
confiança**: a obrigação está registrada na seção Contratos da spec do item
`001`, que o item `002` lê obrigatoriamente antes de começar, conforme a regra de
contrato entre specs. Duas obrigações ficam transferidas:

1. Consultar `docs/AGENTS-EXAMPLE.md` ao redigir a constitution e o `AGENTS.md`.
2. **Remover a entrada transitória do `.gitignore`** junto com o arquivo.

Deixar a entrada no `.gitignore` após o item `002` seria dívida silenciosa: uma
exclusão sem alvo, que ninguém saberia por que existe.

---

## ADR-005 — A constitution em branco é versionada como está

**Data**: 2026-08-29 · **Status**: Aceita · **Item**: 001 (0.9)

### Contexto

`.specify/memory/constitution.md` foi instalado pelo Spec-Kit e contém 18
placeholders não substituídos. Ratificá-la é o item `002`. Surgiu a questão de
excluí-la do commit inicial até estar preenchida.

### Decisão

**É versionada no estado em que está.**

### Justificativa

O histórico registra o estado real do projeto, não o estado desejado. Três
razões, em ordem de peso:

1. **O template em branco é um fato do projeto, não ruído.** O commit inicial
   documenta que o motor nasceu com o Spec-Kit instalado e a constitution ainda
   não ratificada. Excluí-la faria o histórico mentir por omissão.
2. **O diff do item `002` passa a ser a evidência da ratificação.** Com o
   template versionado, a diferença entre o template e a constitution ratificada
   fica visível e auditável. Sem ele, a constitution apareceria do nada.
3. **Consistência com D9.** O item `001` decidiu versionar os artefatos de
   integração de agente justamente para fixar o protocolo com que o motor é
   construído. A constitution é parte desse protocolo; excluí-la seria incoerente.

### Alternativa rejeitada

Excluir até estar preenchida. Rejeitada porque produziria um histórico onde o
portão constitucional aparece já satisfeito, apagando o registro de que os itens
`001` e `002` operaram sob um portão substituto — que é exatamente a dívida que a
ADR-003 e o contrato com o item `002` existem para tornar visível.

---

## ADR-006 — Integridade do harness por resumo criptográfico e convenção de exclusão transitória

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: aceita

### Contexto

A ADR-002 estabeleceu que **um item nunca modifica o oráculo de um item
anterior**, e que conflito de asserção sobe para decisão explícita em vez de
edição silenciosa. Até aqui essa regra era um acordo verificado por leitura de
diff — isto é, por julgamento humano, que é precisamente o que o harness existe
para substituir.

A pesquisa técnica do item `002` (`specs/002-constitution-ratification/research.md`,
E2) mostrou o buraco: executar o oráculo do item `001` e obter código de saída `0`
prova que ele **aprova**, não que está **íntegro**. Um item futuro poderia
enfraquecer uma asserção — trocar uma verificação real por uma tautologia — e o
oráculo continuaria saindo `0`. Nenhuma execução detectaria.

### Decisão

**1. O resumo criptográfico de cada oráculo concluído é fixado pelo item
seguinte.**

```
scripts/verify/f0-001-foundation.sh
sha256 = 63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22
```

O oráculo do item `002` assere esse valor (`FR-021a`) e, separadamente, que o
oráculo do item `001` continua aprovando (`FR-021b`). São duas perguntas
distintas e ambas precisam de resposta.

**2. Divergência de resumo sobe para decisão, nunca para atualização do valor.**

Atualizar o número fixado para fazer a asserção passar é a forma exata de
derrotá-la. Se um oráculo anterior **precisa** mudar, isso é conflito de contrato
entre specs: a mudança e o novo resumo entram por ADR própria, com o motivo
registrado.

**3. Exclusão transitória carrega marcador legível por máquina.**

```gitignore
# transitorio: <motivo> — remover em <item>
<padrao>
```

O oráculo exige que todo alvo assim marcado **exista**. Alvo marcado e ausente é
regra órfã e reprova (`SC-008`).

### Por que o marcador é necessário

A pesquisa E3 mediu o `.gitignore` vigente:

```
padrões literais (sem curinga, sem negação, sem comentário): 80
  alvo existente em disco:  1
  alvo INEXISTENTE:        79
```

**Apontar para alvo inexistente é o comportamento correto de uma regra de
exclusão.** Ela existe para preceder o arquivo que impede de entrar no histórico —
foi essa a ordem normativa do item `001` (exclusões vigentes antes do registro
inicial, porque o histórico é irreversível). Um critério que reprovasse regra sem
alvo reprovaria 79 regras corretas, e um oráculo assim seria desabilitado na
primeira semana. Oráculo desabilitado é pior que oráculo ausente, porque o
repositório continua parecendo verificado.

O marcador separa as duas populações: regra permanente aponta para o futuro por
construção; regra transitória que perdeu o alvo é lixo.

### Derivação dos princípios a partir do material de referência transitório

`docs/AGENTS-EXAMPLE.md` foi consultado ao redigir a governança e **removido ao
fim do item `002`** (ADR-004, `FR-019`). Os trechos abaixo estão **transcritos**,
não referenciados: um ponteiro para o arquivo seria referência morta no instante
seguinte à remoção, e a rastreabilidade dos princípios derivados morreria junto.

| Princípio ratificado | Linha de origem | Trecho transcrito |
|---|---|---|
| **I — Determinismo sobre probabilidade** (parcial) | L3 | *"You prioritize reliability over speed and never guess at business logic. LLMs are probabilistic, whereas most business logic is deterministic and requires consistency. This system fixes that mismatch."* |
| **I — Determinismo sobre probabilidade** (parcial) | L41 | *"You operate within a 3-layer architecture that separates concerns to maximize reliability. LLMs are probabilistic; business logic must be deterministic."* |
| **II — Especificação precede código** | L47 | *"The Golden Rule: If logic changes, update the SOP before updating the code."* |
| **IV — Definição de dados antes da implementação** | L26 | *"Data-First Rule: You must define the JSON Data Schema (Input/Output shapes) in `AGENTS.md`. Coding only begins once the 'Payload' shape is confirmed."* |
| **IV — Definição de dados antes da implementação** | L80–86 | *"Before building any Tool, you must define the Data Schema... What does the raw input look like? What does the processed output look like? Coding only begins once the 'Payload' shape is confirmed."* |
| **VII — Auto-reparo atualiza a documentação** | L88–95 | *"Self-Annealing (The Repair Loop): 1. Analyze: Read the stack trace and error message. Do not guess. 2. Patch. 3. Test. 4. Update Architecture: Update the corresponding `.md` file in `architecture/` with the new learning... so the error never repeats."* |
| **VIII — Elo verificado antes de lógica** | L32–35 | *"Link (Connectivity). 1. Verification: Test all API connections and `.env` credentials. 2. Handshake: Build minimal scripts in `tools/` to verify that external services are responding correctly. Do not proceed to full logic if the 'Link' is broken."* |

**Quatro dos dez princípios derivam do material** — I, II (parcial, junto com o
plano §17), IV, VII e VIII. Os demais vêm do plano de implementação, do addendum
§9 e das ADR-002 e ADR-003.

### O que foi descartado do material, e por quê

| Descartado | Motivo |
|---|---|
| As cinco fases **B.L.A.S.T.** (Blueprint, Link, Architect, Stylize, Trigger) | É arquitetura de projeto de automação, não princípio de motor. O motor já tem ciclo canônico próprio, derivado do SDD |
| As três camadas **A.N.T.** (`architecture/`, Navigation, `tools/`) | Mesma razão: prescreve estrutura de diretórios de um projeto-alvo. Colide com o princípio IX (agnosticismo de stack) |
| A persona **System Pilot** | Identidade de agente. Este item ratifica **governança**, não identidade — e identidade fixada em governança impediria o motor de operar sob outros agentes |
| A fase **Cloud Transfer** (L72) e *"A project is only 'Complete' when the payload is in its final cloud destination"* (L100) | Pressupõe destino em nuvem. Colide diretamente com o princípio IX e com o ambiente do mantenedor, onde nada roda em segundo plano |

### Consequências

- A regra de não regressão da ADR-002 deixa de depender de revisão humana.
- Cada item da Fase 0 passa a fixar o resumo do oráculo do item anterior, formando
  uma cadeia de integridade ao longo dos doze itens.
- A remoção de `docs/AGENTS-EXAMPLE.md` torna-se segura: tudo que dele deriva está
  transcrito acima e nos rótulos `Origem:` da governança ratificada.

---

## ADR-007 — Exceção fundamentada: as três lacunas de asserção do item 001

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: aceita
**Decisão do mantenedor**, tomada sob `FR-017b` · **Saída escolhida: C**

### Contexto

A revalidação retroativa exigida pelo item `002` (`FR-017`) julgou os 16 artefatos
entregues pelo item `001` contra a governança recém-ratificada. Quinze passaram.
Um não: `scripts/verify/f0-001-foundation.sh` viola o **princípio VI — O harness é
o oráculo**, cujo critério é *"existe critério de aceitação sem asserção
correspondente no harness"*.

Verificada correspondência **em substância**, não por homonímia:

| Critério do item `001` | Asserção que o decide | Estado |
|---|---|---|
| `SC-001` zero proibidos no histórico | `FR-020a` + `FR-020b` | coberto |
| `SC-002` registros classificáveis | `SC-002` | coberto |
| `SC-003` **< 5 s** e duas execuções idênticas | `FR-018` (checagem **estática** do fonte) | 🔴 parcial |
| `SC-004` par vermelho→verde preservado | — | 🔴 nenhuma |
| `SC-005` nome revela fase, pacote e propósito | `FR-006` + `FR-006b` | coberto |
| `SC-006` roda só com o do bootstrap | `FR-019` | coberto |
| `SC-007` contratos declarados por escrito | — | 🔴 nenhuma |

`FR-018` verifica que o **fonte** não contém construção não determinística. É
estática: não observa se duas execuções produzem a mesma saída, nem quanto tempo
levam. `SC-003` pede as duas garantias.

### Problema

As três saídas possíveis colidiam entre si:

| Saída | Por que foi rejeitada / aceita |
|---|---|
| **A — corrigir `f0-001-foundation.sh`** | **Rejeitada.** Acrescentar asserções ao oráculo do item anterior quebra a ADR-002 e invalida `FR-021a` do item `002` — o resumo criptográfico fixado mudaria. A regra "um item nunca modifica o oráculo de um item anterior" seria quebrada exatamente no ciclo que a tornou mecânica |
| **B — emendar o princípio VI** | **Rejeitada.** Restringir a exigência a itens pós-ratificação enfraquece o princípio no seu primeiro exercício, e estabelece que a governança recua diante de trabalho já feito. O princípio funcionou: ele encontrou uma lacuna real |
| **C — exceção fundamentada com transferência a item nomeado** | **Aceita** |

### Decisão

**1. Exceção registrada, com prazo.** O item `001` convergiu **antes** da
ratificação da governança — é o único dos doze nessa condição, e a ADR-003 já
registrara essa dívida. A não conformidade é reconhecida, não perdoada.

**2. A cobertura das três lacunas é transferida ao item `0.4` do plano — Pytest.**

> **Nota de numeração (ADR-011)**: à época esta ADR chamou o destinatário de
> "item `004`". Com a renumeração, Pytest passa a ser a spec **`005`**. O item do
> plano (`0.4`) não mudou e a transferência segue apontando para o mesmo trabalho.

O item `004` já tem, por desenho anterior a este achado, a tarefa de promover cada
`f0-NNN-*.sh` a módulo de teste equivalente — é a razão de `--list` existir. As
três asserções faltantes entram **como casos de teste novos**, em arquivo novo:

| Lacuna | Forma no item `004` |
|---|---|
| `SC-003` tempo | caso que mede a execução de `f0-001-foundation.sh` e exige < 5 s |
| `SC-003` determinismo empírico | caso que executa duas vezes e compara a saída byte a byte |
| `SC-004` par vermelho→verde | caso que exige `evidence/t015-red.txt` e `t023-green.txt` presentes e distintos |
| `SC-007` contratos declarados | caso que exige a seção Contratos da spec do item `001` |
| **`FR-001` mede HEAD, não a linha principal** *(achado posterior, ver abaixo)* | caso que exija a **existência** de `refs/heads/main`, permitindo trabalho em linha de funcionalidade |

**3. `scripts/verify/f0-001-foundation.sh` permanece intocado.** É isto que torna
a saída C compatível com a ADR-002: a cobertura é acrescentada **ao lado**, nunca
dentro. O resumo `63412ca7…5a6bbf22` continua válido e asserido.

**4. A exceção expira quando o item `004` convergir.** Não é indefinida. Se o item
`004` convergir sem cobrir as lacunas, o achado reabre.

### Achado posterior — quinta lacuna, mesma classe

Ainda na Fase 9 do item `002`, ao registrar os commits numa linha de
funcionalidade, `FR-001` do item `001` reprovou:

```
🔴 FR-001  repositorio existe e linha principal e main
           evidencia: linha atual: feature/f0-constitution-ratification
```

**A asserção mede a linha apontada por HEAD, não a existência da linha
principal.** Enunciado e implementação divergem: *"a linha principal é `main`"* é
propriedade do repositório; *"estou em `main` agora"* é propriedade da sessão de
trabalho. `refs/heads/main` existia o tempo todo.

A consequência é concreta: **o harness reprova em qualquer linha de
funcionalidade** — exatamente o fluxo que o `CONTRIBUTING.md` §2 deste projeto
prescreve. Um item futuro que siga a convenção de ramificação documentada não
consegue rodar o harness até integrar.

Mesma classe das outras quatro, mesma resolução: **transferida ao item `004`**
como caso de teste novo, sem tocar em `f0-001-foundation.sh`. Até lá, o registro
de commits do bootstrap permanece em `main` — que é o que o item `001` de fato
fez, verificável em `git log`.

**Nota de método**: as quatro primeiras lacunas vieram de comparação sistemática
entre critérios e asserções. Esta veio de **usar** o harness num fluxo que ele
nunca tinha visto. As duas formas de achado são necessárias e nenhuma substitui a
outra — a primeira encontra o que foi esquecido, a segunda encontra o que foi
entendido errado.

### Por que C e não A

A saída A parece a mais direta — "o oráculo está incompleto, complete-o". Ela
custaria a única regra que impede regressão silenciosa no harness, e a custaria
para pagar uma dívida de um item que antecede a própria governança. Trocar uma
garantia estrutural permanente por uma correção pontual é mau negócio, mesmo
quando a correção é legítima.

### Consequências

- O princípio VI permanece íntegro e já provou seu valor: encontrou **cinco**
  lacunas reais que a revisão humana do item `001` não pegou — quatro por
  comparação sistemática, uma pelo uso.
- A ADR-002 permanece íntegra e mecanicamente verificável.
- O item `004` herda **cinco** casos de teste nomeados, com origem registrada.
- Fica estabelecido o **primeiro precedente** do motor para conflito entre
  governança e trabalho já convergido: reconhecer, registrar, transferir a item
  nomeado com prazo — nunca reescrever o passado nem enfraquecer a regra.

---

## ADR-008 — Achado de uso: o critério do princípio VII é mais fraco que seu enunciado

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: **registrada, não aplicada**
**Origem**: cenário 3 de `quickstart.md`, executado em T041

> Esta ADR **não emenda a governança**. Ela registra um achado e o encaminha ao
> procedimento próprio. Emendar governança de dentro de outro comando é o que a
> ADR-007 estabeleceu que não se faz.

### Contexto

O cenário 3 submete cada um dos dez princípios ratificados ao teste de
decidibilidade: tomar um artefato real e responder *"viola ou não viola?"* usando
**apenas** o critério de violação escrito na governança.

Nove princípios passaram. O **VII — Auto-reparo atualiza a documentação** não.

### Achado

O enunciado e o critério cobram coisas diferentes:

| | Texto |
|---|---|
| **Enunciado** | *"Ao corrigir uma falha, o ciclo MUST registrar **a causa** no artefato normativo correspondente, **de modo que a mesma falha não possa repetir-se** sem ser detectada."* |
| **Critério de violação** | *"existe correção de falha cujo registro **não altera nenhum artefato normativo**."* |

O caso concreto que expôs a folga: durante o item `002`, o padrão de `py_decisao`
em `f0-002-constitution.sh` usava `\s*`, que em Python inclui quebra de linha, e
por isso atravessava a linha vazia e capturava a linha seguinte — aprovando um
registro de decisão em branco. A correção alterou o oráculo, que é artefato
normativo: **pelo critério, não viola**. Mas a causa não ficou registrada, e nada
impedia a reintrodução do mesmo `\s*` no dia seguinte: **pelo enunciado, o
propósito não era servido**.

Emitir veredito exigiu **escolher entre as duas leituras** — que é exatamente o
que `FR-005` do item `002` proíbe.

### Por que a máquina não pega isto

`FR-005b` assere que cada princípio **tem** um critério de violação rotulado e não
vazio. O critério do VII existe e está rotulado — a asserção aprova, corretamente.

Nenhuma asserção compara o **critério** com o **enunciado que ele deveria
operacionalizar**. Essa comparação é semântica, e é o que o cenário 3 faz.

**Consequência para o método**: `FR-005b` verde não é prova de decidibilidade; é
prova de que o critério existe. A decidibilidade é medida pelo cenário 3, por
pessoa, e a diferença entre as duas coisas precisa continuar visível.

### Encaminhamento

**Candidato a emenda PATCH** da governança — esclarece redação sem alterar o que é
decidido em nenhum dos nove princípios restantes. Redação sugerida para o critério
do princípio VII:

> *"existe correção de falha cujo registro não identifica **a causa** no artefato
> normativo correspondente."*

A emenda MUST ser exercitada por `/speckit-constitution` próprio, seguindo o
procedimento da seção Governance: proposta em especificação, avaliação de impacto
sobre artefatos já convergidos, e atualização de versão, rodapé e registro de
impacto. Será também o **primeiro exercício real do procedimento de emenda**, que
o item `002` definiu mas não exercitou — obrigação já transferida ao pós-Fase 0.

### Consequências

- O princípio VII permanece **inalterado** e vigente na forma ratificada.
- O achado fica rastreável: quem exercitar a emenda encontra o caso concreto que a
  motivou, sem reconstituir a conversa.
- Fica registrado que o primeiro portão constitucional real produziu, além de
  vereditos, **um achado sobre a própria governança** — que é o que se espera de um
  mecanismo que se aplica a si mesmo.

---

## ADR-009 — Emenda 1 do plano: o motor precisa do pipeline que ele ensina a construir

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: aceita
**Efeito**: acrescenta os itens **0.13 a 0.16** à Fase 0 do `implementation_plan.md`

### Contexto

Auditoria do plano executada durante o item `002`, por busca sistemática em
`docs/plan/`, não por leitura de memória.

O plano cobre bem o que eu esperava e mais: Ruff, MyPy, Pytest, Lefthook,
pip-audit, Trivy, gitleaks, SBOM via `cyclonedx-py`, hash-pinning por `uv.lock`,
`python-semantic-release` para o CHANGELOG, `SecretStr` do Pydantic, sandbox de
comandos, hardening de container, e observabilidade completa na Fase 3.

**E não dá pipeline ao próprio motor.** As duas únicas ocorrências de CI no plano
são o modo `fkx run --headless`, para o motor ser *consumido* por CI alheia, e o
agente DevOps do item 3.7, que *gera* pipeline para o sistema-alvo. O motor ensina
o que não pratica.

### Os doze buracos encontrados

| # | Buraco | Consequência |
|---|---|---|
| 1 | Nenhum workflow de integração contínua | Todo enforcement é hook local |
| 2 | Sem branch protection nem required status checks | É a **única** forma real de neutralizar `--no-verify` |
| 3 | `python-semantic-release` citado, nunca executado | O CHANGELOG "automático" não tem gatilho |
| 4 | Nada publica no PyPI | O addendum já assume `fkx` publicado — o notificador de versão consulta a API do PyPI de um pacote que nada publica |
| 5 | Sem validação automática de mensagem de commit | `semantic-release` **depende** de Conventional Commits; um commit malformado quebra o versionamento em silêncio |
| 6 | Sem atualização automática de dependências | "Subiu merge, mudou versão" depende de memória humana |
| 7 | Cobertura é relatório, não portão | `pytest-cov` gera número; ninguém reprova por ele |
| 8 | Sem `uv sync --frozen` em CI | O hash-pinning só protege se alguém provar que o lock está coerente |
| 9 | Sem matriz de versões de Python | Roda em 3.12 na máquina do mantenedor; ninguém sabe sobre as demais |
| 10 | SBOM gerado, nunca publicado | SBOM que não acompanha o release não serve a ninguém |
| 11 | Sem trusted publishing | A alternativa é token de longa duração no repositório, contra a Lei Zero |
| 12 | Sem CODEOWNERS | Irrelevante com um mantenedor; relevante ao abrir o projeto |

### Sobre `--no-verify`, que motivou esta auditoria

**Não é possível proibir `--no-verify`.** É uma flag do cliente git, executada na
máquina de quem commita. Nenhuma configuração dentro do repositório a impede.

O que torna o bypass **inútil** vive no servidor: *required status checks*, que
reprovam a integração mesmo quando o commit local passou, e *branch protection*,
que impede escrita direta nas linhas principais. Por isso o item `0.14` inclui
essas duas coisas — sem elas, o item `0.5` (Lefthook) entrega a **sensação** de
portão sem o portão.

Hook local continua valendo: ele dá feedback em segundos em vez de minutos. É
conveniência, não garantia, e o plano precisava dizer qual é qual.

### Decisão

**1. Emendar o plano, não apenas criar specs.** A ADR-001 mapeia specs ↔ itens do
plano. Criar spec sem item correspondente quebra o mapa e faz o plano mentir na
próxima leitura. A emenda entra como seção marcada em `§17`, sem tocar em 0.1–0.12.

**2. `0.13` é executado imediatamente após o item `002`.** O harness cresce por
acréscimo desde o item `001`; a integração contínua cresce junto. Um CI que só
chega no fim da Fase 0 significa dez itens construídos sem rede, e uma primeira
execução do pipeline que precisa validar dez itens de uma vez.

O CI mínimo é executável **agora**: depende apenas de shell, git e Python, que já
existem. É a mesma restrição de dependências dos oráculos `001`–`003`.

**3. Numeração das specs**: ver **ADR-011**.

> ⚠️ **Correção.** Esta ADR atribuiu inicialmente os números de spec `013`–`016`
> aos quatro itens novos, seguindo a numeração **do plano**. Isso contradiz o
> invariante da ADR-001, onde o número da spec é a **posição de execução** — e a
> própria ADR dizia que `0.13` executaria em terceiro. A ADR-011 corrige o mapa e
> passa a ser a fonte de verdade. Erro apontado pelo mantenedor.

### Consequência para o método

Esta ausência **não foi apontada na leitura inicial do plano**. Foram apontadas a
ordem inexecutável do `§17` e a premissa falsa sobre `AGENTS.md`, ambas defeitos de
*conteúdo presente*. O CI era defeito de **ausência**, e ausência não salta da
página: só aparece quando alguém pergunta *"o que deveria estar aqui e não está?"*.

Fica registrado como lição de método: a leitura de um plano precisa de uma passada
por **checklist de completude**, não apenas de revisão crítica do que está escrito.
Esta é uma das razões que motivam a etapa `INTAKE` avaliada para o motor.

---

## ADR-010 — Fronteira de idioma: onde o projeto fala inglês e onde fala português

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: aceita

### Contexto

O projeto é escrito em português do Brasil por decisão do mantenedor, que não tem
fluência em inglês. A ambição é que o motor seja utilizável globalmente.

Traduzir depois é caro e, em alguns lugares, **impossível sem quebrar**: tradução
automática de identificador quebra o código, e de documento normativo produz
ambiguidade exatamente onde ela não pode existir. Depender de "o dev traduz na
IDE dele" não é mecanismo.

### Decisão

| Camada | Idioma | Razão |
|---|---|---|
| Identificadores, comandos da CLI, nomes de arquivo, códigos de erro | **inglês** | É a superfície pública. `fkx run --headless` já é inglês. Não custa nada ao mantenedor, que não escreve identificadores em prosa |
| **Rótulos estruturais** da governança e da porta de entrada | **inglês** | São nomes de campo, não prosa: `**Violation:**`, `**Source:**`, `**Version**`, `**Ratified**`. São o que o harness lê e o que uma tradução futura precisa preservar intacto |
| Prosa da governança e da porta de entrada | **português** | É o que o mantenedor lê e mantém |
| Specs, ADRs, pesquisa, veredictos, plano | **português** | É a oficina. Não é superfície pública e não está previsto traduzir |

A regra em uma frase: **o que é campo, é inglês; o que é texto, é português.**

### Constatação que limita a decisão

`scripts/verify/f0-001-foundation.sh` casa a palavra **`escopo`** dentro de
`CONTRIBUTING.md` (asserção `FR-005`). Pela ADR-002, aquele oráculo **não pode ser
editado**. Portanto `escopo` fica **congelado em português** em `CONTRIBUTING.md`
até que o item `004` promova os oráculos a módulos de teste.

É um caso pequeno — uma palavra —, mas ilustra o custo real da regra de não
regressão: **acoplamento a idioma vira dívida no instante em que o oráculo
converge.** Daí a decisão ser tomada agora, no item `002`, e não depois.

### Escopo da aplicação imediata

Convertidos agora, com o oráculo `f0-002` ajustado no mesmo movimento:

| Artefato | Antes | Depois |
|---|---|---|
| `.specify/memory/constitution.md` | `**Violação:**`, `**Origem:**` | `**Violation:**`, `**Source:**` |
| `.specify/memory/constitution.md` | `## Restrições Adicionais`, `## Fluxo de Desenvolvimento` | `## Additional Constraints`, `## Development Workflow` |
| `.specify/memory/constitution.md` | subseções de governança em português | `### Amendment Procedure`, `### Versioning Policy`, `### Compliance Review Expectation` |
| `AGENTS.md` | seis cabeçalhos em português | seis cabeçalhos em inglês |

**Não** convertidos: specs, ADRs, pesquisa, `compliance-001.md`, `CONTRIBUTING.md`
e toda a prosa. São a oficina, permanecem em português.

### Reabertura do item 002

A conversão exige editar `scripts/verify/f0-002-constitution.sh`, de um item já
convergido. Pela letra da ADR-002, o proibido é um item modificar o oráculo de
**outro**; o item `002` ajustando o próprio não é isso.

A alternativa era pagar depois pelo mecanismo de exceção da ADR-007 — o que criaria
a **segunda** dívida da mesma classe antes de a primeira ser paga. Reabrir agora
custa seis asserções e dois arquivos; adiar custa uma dívida permanente.

O ciclo vermelho→verde do item `002` **não é refeito**: nenhuma asserção nova é
acrescentada e nenhum requisito muda. É refatoração de rótulo sobre verde
existente, e o verde é reconfirmado ao final.

---

## ADR-011 — Emenda da ADR-001: mapa de execução com 16 itens

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: aceita
**Emenda**: ADR-001 · **Motivo**: Emenda 1 do plano (ADR-009)

### Problema

A ADR-001 fixou um invariante: **o número da spec é a posição de execução**, não o
número do item no plano. Foi por isso que a spec `001` é o item `0.9` e a `003` é
o item `0.1`.

A ADR-009 acrescentou quatro itens à Fase 0 e atribuiu a eles os números `013` a
`016` **pela ordem no plano**, não pela ordem de execução — dizendo ao mesmo tempo
que o `013` seria executado em terceiro. As duas afirmações se contradizem, e a
tabela resultante ficava com `013–016` inseridos entre `008` e `009`.

**Segundo defeito, encontrado junto**: a ADR-009 colocou a automação de release
(`0.15`) logo depois do CI completo (`0.14`). Mas publicar no PyPI exige que o
pacote exista — `0.15` depende de `0.7` (`packages/cli`), não apenas de `0.14`.

### Decisão

O invariante da ADR-001 é **mantido**: número da spec = posição de execução. O mapa
é renumerado para acomodar os quatro itens novos.

| Spec | Item do plano | Título | Justificativa da posição |
|---|---|---|---|
| `001` | **0.9** | Git + branching strategy | ✅ concluída |
| `002` | **0.11** | Constitution + porta de entrada | ✅ concluída |
| `003` | **0.13** | **CI mínimo** | Depende só de shell, git e Python, que já existem. A integração contínua cresce junto com o harness — chegando no fim, dez itens seriam construídos sem rede |
| `004` | **0.1** | UV workspace monorepo | Base física de todos os pacotes |
| `005` | **0.4** | Pytest | Habilita TDD real dos itens seguintes; precede Ruff |
| `006` | **0.2** | Ruff | |
| `007` | **0.3** | MyPy strict | Consome contrato do Ruff: regras que conflitam com tipagem estrita |
| `008` | **0.12** | pip-audit + Trivy | Precisa existir antes de ser orquestrado |
| `009` | **0.5** | Lefthook | Orquestra 005, 006, 007 e 008 |
| `010` | **0.14** | **CI completo + branch protection** | Precisa das ferramentas existindo. Traz os *required checks* que tornam `--no-verify` inócuo |
| `011` | **0.6** | `packages/core` | Primeiro código de produção |
| `012` | **0.7** | `packages/cli` | Depende de `core` |
| `013` | **0.15** | **Automação de release** | **Depende de `012`**: não se publica um pacote que não existe. E de `010`: release exige pipeline verde |
| `014` | **0.16** | **Atualização de dependências** | Depois de `013`: precisa do pipeline completo para validar o que entra |
| `015` | **0.8** | docker-compose | Domínio independente (DevOps) |
| `016` | **0.10** | `docs/tree.md` | Por último: reflete a árvore real resultante |

### Consequências

- **Nenhuma renomeação de diretório.** Só existem `specs/001-*` e `specs/002-*`,
  ambas concluídas e com número inalterado. Os demais ainda não foram criados —
  a renumeração é gratuita **hoje** e cara em qualquer momento posterior.
- A Fase 0 passa de 12 para **16 itens**. O `progresso` passa a ser medido sobre 16.
- A próxima spec é a **`003` — CI mínimo**, não mais o UV workspace.
- Referências cruzadas já escritas nas specs `001` e `002` apontam para itens do
  plano (`0.4`, `0.5`, `0.12`) e para números de spec. **Os números de spec citados
  precisam ser relidos por este mapa** — em especial a transferência do item `002`
  ao "item 004 (Pytest)", que passa a ser a spec **`005`**.

### Correção de rastreabilidade decorrente

A ADR-007 transferiu cinco casos de teste ao "item `004` (0.4 — Pytest)". Com a
renumeração, **Pytest passa a ser a spec `005`**. O item do plano (`0.4`) não muda.
A transferência segue válida e apontando para o mesmo trabalho; o que muda é o
número da spec que a receberá.

Onde o texto disser "item 004" no contexto da dívida do harness, leia-se
**"item 0.4 do plano, spec `005`"**. As correções de texto estão aplicadas em
`docs/plan/decisions.md` (ADR-007) e em
`specs/002-constitution-ratification/spec.md` › Contratos.

### Lição de método registrada

Dois defeitos numa única ADR, ambos de **ordem**, ambos passando por revisão minha
sem serem notados — e o primeiro foi apontado pelo mantenedor, não pelo processo.

A causa é a mesma nos dois: a ADR-009 raciocinou sobre *"onde isto entra no plano"*
e não sobre *"o que precisa existir antes disto funcionar"*. São perguntas
diferentes, e só a segunda produz ordem executável. Foi exatamente o defeito que a
ADR-001 corrigiu no `§17` original do plano — e que reapareceu ao estender esse
mesmo plano.

**Nenhum oráculo cobre ordem de execução entre specs.** É candidato a asserção do
item `003` (CI mínimo): o mapa da ADR vigente é a única fonte, e hoje nada verifica
se ele é coerente — se cada posição vem depois de tudo de que depende.

---

## ADR-012 — Emenda 2: o ciclo do motor, e quatro lacunas fora da Fase 0

**Data**: 2026-08-30 · **Item**: `002` (0.11) · **Estado**: aceita
**Efeito**: acrescenta os itens **2.9, 2.10, 3.9 e 4.11**; corrige o ciclo do motor no addendum

### Correção que precede a decisão

Uma auditoria anterior desta sessão listou cinco sugestões como se fossem lacunas.
**Duas já estavam no plano** e foram propostas por engano:

| Proposto como novo | Onde já estava |
|---|---|
| `fkx doctor` | Item **4.5**, marcado MVP, mais a tabela de features (`Doctor — verifica saúde do ambiente`) |
| Etapa de entrevista antes da spec, produzindo um PRD | Item **4.2** `fkx interview`, com dez perguntas de descoberta já redigidas (`§` da entrevista), mais o ciclo do addendum que já começava por `INTERVIEW` |

**Causa**: a busca de verificação usou `\|` como alternância com `grep -E`, onde
isso casa uma barra vertical literal. Todas as cinco buscas retornaram vazio, e o
vazio foi lido como ausência. Um erro de ferramenta que produziu uma conclusão
inteira errada, e que só apareceu porque o plano foi lido de novo.

Registrado sob o princípio **VIII** — *pesquisa é verificação, não memória*: uma
busca que retorna vazio precisa ser confirmada por um controle positivo antes de
virar conclusão. É a mesma classe de defeito das verdades vácuas do item `002`.

### Achado que substitui as duas sugestões retiradas

O ciclo que o motor aplicará aos projetos de terceiros, no addendum, era:

```
INTERVIEW → CONSTITUTION → RESEARCH → SPEC → PLAN → TASKS → TESTS → IMPLEMENT → HARNESS → QA → DEVOPS → COMMIT → CONVERGE
```

**Faltavam `CLARIFY` e `ANALYZE`** — zero ocorrências das duas palavras em ambos os
documentos de planejamento. Enquanto isso, o ciclo do próprio bootstrap, ratificado
na governança, tem as duas.

Isso é mais grave que qualquer uma das sugestões retiradas. A tese do projeto é que
**o motor é construído usando a si mesmo**; um ciclo que ele aplica aos outros e não
aplica a si não é um processo determinístico, são dois processos com o mesmo nome.

E as duas etapas não são teóricas — cada uma pegou um defeito neste bootstrap que
nenhuma outra etapa pegou:

| Etapa | O que encontrou no item `002` |
|---|---|
| `CLARIFY` | `SC-006` trazia "10 segundos", um limiar inventado sem fonte declarada |
| `ANALYZE` | `SC-008` reprovaria 79 regras de exclusão corretas se implementado ao pé da letra |

**Decisão**: o ciclo do addendum passa a incluir as duas, na mesma posição do ciclo
do bootstrap.

### As quatro lacunas que sobreviveram à verificação

| Item | Lacuna | Por que importa |
|---|---|---|
| **2.9** | **Golden tests dos agentes** | O motor é determinístico nas regras, mas os agentes chamam modelo. Sem entradas fixas e saídas esperadas versionadas, trocar de modelo ou ajustar um prompt não produz sinal — é a diferença entre *"o motor funciona"* e *"o motor funciona igual ao que funcionava"* |
| **2.10** | **Teto de custo e latência por sessão** | LiteLLM está no plano; limite de gasto não. A pergunta 8 da entrevista cobre orçamento **do projeto-alvo**, não do motor. Um laço de agente sem teto é incidente financeiro, não defeito |
| **3.9** | **Retenção dos efêmeros** | `.fluksos-x/sessions/` e `reports/` estão excluídos do versionamento desde o item `001`, e **nada os apaga**. Em alguns meses são gigabytes silenciosos no disco do usuário |
| **4.11** | **Contrato de saída da CLI** | `fkx run --headless` será consumido por CI e por outros agentes. Sem `--json` com schema versionado e códigos de saída documentados, cada release quebra quem integra — o mesmo problema que o contrato do oráculo resolveu na Fase 0, e que o plano não resolvia para a CLI |

### Escopo

Nenhum dos quatro entra na Fase 0. O `2.10` e o `4.11` **poderiam** ser antecipados,
mas dependem de artefatos que só existem depois: gateway de modelo e comandos reais
da CLI. Antecipá-los produziria especificação sobre o que ainda não existe —
exatamente o que o princípio **IV** proíbe.

### Consequências

- A Fase 0 permanece com **16 itens**; o mapa da ADR-011 não muda.
- Fase 2 passa a 10 itens, Fase 3 a 9, Fase 4 a 11.
- O ciclo do motor e o ciclo do bootstrap ficam **idênticos no núcleo SDD**, com o
  ciclo do motor acrescentando as etapas que só fazem sentido com agentes
  (`HARNESS`, `QA`, `DEVOPS`, `COMMIT`) e a entrevista inicial.

---

## ADR-013 — Algoritmo de fronteira para o `fkx interview`

**Data**: 2026-08-30 · **Destino**: item **4.2** do plano · **Estado**: aceita
**Fonte externa**: `mattpocock/skills`, skill `grilling` — MIT, verificada em 2026-08-30

### Contexto

O item `4.2` (`fkx interview`) é a etapa de descoberta que abre o ciclo do motor
para qualquer projeto que ele construa. O plano a define como **dez perguntas**
(`§` da entrevista), feitas de uma vez.

Perguntar as dez juntas tem um defeito concreto: a resposta da pergunta 6
(*stack preferida, ou o motor decide?*) **muda o que faz sentido perguntar** na 7
(*integrações externas*) e na 9 (*deploy target*). Perguntadas em bloco, ou o
usuário responde no vácuo, ou o motor precisa reinterpretar respostas dadas sob
premissas que mudaram depois.

### Fonte verificada

Repositório `mattpocock/skills`, licença MIT. Estrutura real conferida por
download direto, não por memória:

| Arquivo | Tamanho | Papel |
|---|---|---|
| `skills/productivity/grill-me/SKILL.md` | 157 B | Apenas delega — invoca a primitiva |
| `skills/productivity/grilling/SKILL.md` | 1987 B | **A primitiva**, reutilizada por 5 skills do repositório |
| `skills/engineering/grill-with-docs/SKILL.md` | 247 B | Compõe `grilling` + `domain-modeling` |

### O que é adotado

**1. Rodadas por fronteira.** A *fronteira* é o conjunto de decisões cujos
pré-requisitos já estão resolvidos — as perguntas respondíveis **agora** sem
supor respostas ainda não ouvidas. Pergunta-se a fronteira inteira numa rodada,
cada item numerado e com recomendação. As respostas reformam a árvore e empurram
a fronteira. Uma pergunta cuja resposta depende de outra ainda aberta pertence a
uma rodada **posterior**.

**2. Separação de responsabilidade, normativa.** Encontrar **fato** é trabalho do
motor: se a pergunta depende do ambiente, o motor vai olhar em vez de perguntar.
**Decisão** é do mantenedor: apresentar e esperar.

Isto coincide com o princípio **VIII** (*pesquisa é verificação, não memória*) e
com `FR-017b` do item `002` (*o mantenedor é a autoridade de decisão*). A
coincidência é a razão de a adoção ser barata: não introduz regra nova, dá forma
executável a duas que já existem.

**3. Critério de parada mecânico.** A sessão termina quando a fronteira esvazia —
e não numa cota de perguntas. Isto **corrige um defeito do nosso próprio ciclo**:
`speckit-clarify` para em "até 5 perguntas", que é número sem fundamento — a mesma
classe do `SC-006` com "10 segundos" que o próprio `CLARIFY` pegou no item `002`.

### O que **não** é adotado, e por quê

| Não adotado | Motivo |
|---|---|
| O arquivo da skill | Depende do `Skill` tool e de sub-agentes do Claude Code. O `fkx interview` é código Python que roda sob qualquer agente. Copiar traria acoplamento sem trazer valor — o valor está no algoritmo, reimplementável em poucas dezenas de linhas |
| Terminação **apenas** por fronteira vazia | A árvore é construída pelo modelo: duas execuções sobre a mesma entrada geram árvores diferentes, e a fronteira pode não convergir. Viola o princípio **I** |
| Ausência de artefato | A primitiva termina em "entendimento compartilhado". Nosso ciclo exige artefato versionado em toda etapa: sem PRD em disco, o harness não tem o que asserir e a sessão seguinte recomeça do zero |

### Desenho resultante do item 4.2

| Componente | Origem |
|---|---|
| Rodadas por fronteira; pergunta numerada com recomendação | `grilling` (MIT, atribuído) |
| **Taxonomia fixa de categorias**, varrida em toda sessão | `speckit-clarify`, que já usa 10 categorias — é a garantia de auditoria que a árvore sozinha não dá |
| Saída em **PRD versionado**, com todas as perguntas e respostas registradas | Ciclo do motor: toda etapa produz artefato |
| **Parada**: fronteira vazia **E** toda categoria resolvida ou deferida | As duas condições, nunca uma. A fronteira garante ordem; a taxonomia garante cobertura |

As dez perguntas já redigidas no plano permanecem — deixam de ser um formulário e
passam a ser **as sementes da árvore**, distribuídas por rodadas conforme as
dependências entre elas.

### Nota sobre a fonte

O README do repositório posiciona-se explicitamente contra o Spec-Kit, dizendo que
abordagens assim *"assumem o processo e tiram seu controle"*. Este projeto escolheu
o Spec-Kit deliberadamente. A discordância é legítima e **ortogonal**: `grilling` é
mecanismo de entrevista, usável independentemente da filosofia de processo em volta.

Registrado para que a adoção não seja lida como adesão à crítica.

### Atribuição

Algoritmo derivado da skill `grilling` de Matt Pocock (`mattpocock/skills`),
licença MIT, Copyright (c) 2026 Matt Pocock. Reimplementado, não copiado. A
atribuição acompanha o código do item `4.2`.

---

## ADR-014 — Registro da auditoria pós-004 e a convenção de auditoria-checkpoint

**Data**: 2026-08-30 · **Item**: nenhum (checkpoint não-item, entre 004 e 005) ·
**Estado**: aceita · **Evidência**: `docs/plan/audit/f0-audit-001-004.md`

### Contexto

Os itens 001–004 da Fase 0 convergiram com harness verde (91/91 asserções). O
mantenedor pediu uma auditoria cruzada antes de iniciar o item 005: *as specs
foram feitas corretamente? o SDD está sendo executado direito? o harness está
bom?* A pergunta é a que a ADR-009 ensinou: não só revisar o que está escrito,
mas perguntar o que deveria estar e não está.

A auditoria encontrou quatro achados acionáveis (A1, A2, M3, M4) e cinco baixos,
registrados com evidência reproduzível no relatório. Os dois altos divergem da
governança vigente:

- **A1** — a cadeia de integridade por hash (ADR-006) só existe de 002 sobre 001;
  003 e 004 aprovam o harness herdado sem asserir sua integridade.
- **A2** — o oráculo do 004 remapeia silenciosamente os FRs da spec
  (FR-001…017 → FR-001…014), violando o princípio X.

### Decisão

**1. Nenhum oráculo ou artefato convergido é tocado.** Os achados A1, A2, M3 e
M4 são **exceções registradas com transferência à spec 005**, exatamente o
mecanismo da ADR-007. A correção é **aditiva**: nasce certa da 005 em diante, e
a dívida fica visível até ser paga.

**2. A auditoria vira convenção.** Auditorias de completude são **checkpoints
não-item**: ocorrem entre fases e a cada no máximo quatro itens, com artefato
versionado em `docs/plan/audit/`, no formato do relatório inaugural. Não entram
no mapa de execução da ADR-011 — são a etapa ANALYZE ampliada para o plano
inteiro. Os achados alimentam este arquivo e, quando o motor existir, o Agente
Guardião (item 3.8).

**3. Destino de cada achado** — fixado no relatório §5: A1/A2/M3/M4 à spec 005;
B1/B2 valem como norma a partir da 005; B3 é dívida de registro reconhecida; B4
vira asserção de pin na 005; B5 é corrigido no próprio saneamento (AGENTS.md é
porta de entrada, não oráculo convergido).

### Por que não criar uma spec de saneamento

As dívidas são exatamente do formato da spec 005 (Pytest, 0.4): a ADR-007 já
transferiu cinco casos a ela, e a ADR-002 a aponta como o item que promove os
oráculos a pytest. Uma spec intermediária quebraria a renumeração da ADR-011 sem
ganho. A spec 005 herda tudo pela seção Contratos — o canal que já existe.

### Consequências

- O repositório passa a ter três classes de documento normativo: **plano**
  (intenção), **ADRs** (decisão), **auditoria** (evidência). O relatório não é
  normativo; as ADRs que ele gerou são.
- A spec 005 começa com a maior lista de dívidas recebidas até aqui — o que é
  o sinal de que o mecanismo funciona, não de que falhou.
- O motor herda o padrão: auditoria periódica de completude é função do Guardião.

---

## ADR-015 — Padrão corrigido do harness: manifesto de integridade, mapa FR↔asserção, CONVERGE fecha a lista

**Data**: 2026-08-30 · **Item**: nenhum (checkpoint não-item) · **Estado**: aceita ·
**Origem**: achados A1, A2, M3, M4 de `docs/plan/audit/f0-audit-001-004.md` ·
**Efeito**: normativo a partir da spec 005; nenhum oráculo 001–004 é modificado

### Problema

Quatro defeitos do harness atual, todos da mesma família — a norma diz mais do
que o mecanismo garante:

1. **Integridade (A1)** — ADR-006 fixou a regra, mas ela se expressa como
   "cada item fixa o hash do anterior", e a cadeia parou no 002. Falta um
   mecanismo único e estático.
2. **Rastreabilidade (A2)** — o oráculo pode reidentificar requisitos sem deixar
   rastro; a saída do harness deixa de nomear o requisito da spec.
3. **Convergência (M3)** — o CONVERGE fechou a spec 003 com a lista de tarefas
   aberta; "convergiu" passou a valer mais que "registrou".
4. **Cobertura herdada (M4)** — o self-check do oráculo novo cobre a si e
   "alguns anteriores", sem regra.

### Decisão

**(a) Manifesto de integridade — `scripts/verify/manifest.sha256`.**

A partir da spec 005, os resumos de **todos** os oráculos convergidos vivem num
arquivo único, no formato nativo de `sha256sum` (para verificação por
`sha256sum -c`, sem parser novo). Valores congelados nesta ADR (medidos em
2026-08-30, harness verde):

```
63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22  scripts/verify/f0-001-foundation.sh
406d72528ddebba417887a65f553c99d9c7df8982fb2b72672904b3ec09386a7  scripts/verify/f0-002-constitution.sh
d10c61e8623fcf3f7c706ab8ca7387303c2d5282da0afaee50bf5c6401b6f7d4  scripts/verify/f0-003-ci-minimo.sh
3db36208b4e13fb24bace3aaa3247224f163ca02a070d8b15e64084b1bafd88e  scripts/verify/f0-004-uv-workspace.sh
```

Regras: a spec **N** cria ou acrescenta o manifesto cobrindo `001..N`, e seu
oráculo o assere (`sha256sum -c` exit 0). Divergência de hash sobe para decisão
por ADR — **nunca** para atualização silenciosa do valor. O manifesto é
aditivo: uma linha por oráculo, na ordem de execução.

**(b) Mapa FR↔asserção é obrigatório quando não for identidade.**

O oráculo emite os identificadores **da spec** (FR-NNN da spec). Fragmentação ou
junção só é admitida com o mapa escrito no `contracts/oracle-cli.md` do item
(ex.: "asserção FR-016a/b refinam FR-016; FR-015 não verificável por harness,
verificado por cenário humano"). Remapeamento silencioso é proibido.

**(c) Vocabulário único da seção Contratos.**

Toda spec usa as três subseções canônicas, grepeáveis por qualquer oráculo:

```
### Entregue por este item
### Recebido de itens anteriores
### Transferido a itens posteriores
```

(A 003 usa duas delas; a 004 usa "Contratos expostos"; o nome padrão é o da 003,
que é o que o oráculo já verifica.)

**(d) CONVERGE fecha a lista.**

Zero tarefas `[ ]` em `tasks.md` é condição do verde final — asserida pelo
oráculo **do próprio item** (cada item verifica a si, nunca os anteriores).
A 003 convergiu com 31/31 abertas: exceção registrada, sem edição retroativa.

**(e) Self-check cobre todos os anteriores.**

O oráculo do item N executa `--quiet` de `f0-001…f0-(N-1)`, não de um subconjunto.
Fecha a lacuna da 004, que pula a 002.

### O que não muda

- ADR-002 (um item nunca modifica oráculo anterior) — estas regras são aditivas.
- ADR-006 — o manifesto é a forma estática da cadeia que ela descreveu.
- Os oráculos 001–004 — intocados; os quatro hashes acima os congelam.

### Consequências

- A spec 005 nasce com o padrão corrigido e com a primeira execução do
  manifesto — seu próprio oráculo entra no manifesto como linha 5.
- O CI mínimo (003) não precisa mudar: o glob `f0-*.sh` não inclui o manifesto
  (que é dado, não script); o oráculo da 005 o verifica.
- A primeira divergência de hash no futuro terá precedente e procedimento — que
  é o que distingue incidente de rotina.

---

## ADR-016 — Trava de cadência da auditoria-checkpoint: a 5ª spec não converge sem relatório

**Data**: 2026-09-04 · **Item**: nenhum (checkpoint não-item, entre 008 e 009) ·
**Estado**: aceita · **Origem**: convenção da ADR-014 ("a cada no máximo quatro
itens") + folga detectada em sessão: nenhum oráculo, tasks.md ou CONVERGE travava
a 009 na ausência da auditoria 005–008 — o gatilho dependia de alguém contar até
quatro, isto é, de julgamento humano onde deveria haver regra (princípios I, VI).

### Decisão

**1. Toda spec que seria a 5ª desde a última auditoria recebe como obrigação
herdada a existência do relatório** `docs/plan/audit/f0-audit-NNN-MMM.md`,
**asserida pelo próprio oráculo** (presença do arquivo + cabeçalhos grepeáveis do
formato inaugural: `Veredito`, `Achados`, `Destino`). Sem relatório, o oráculo
reprova e a spec não converge. A trava é local (cada item verifica a si, ADR-015d)
e mecânica: esquecer a auditoria passa a ser impossível por construção.

**2. Bootstrap declarado.** A primeira portadora é a 009 (`f0-audit-005-008.md`,
de 2026-09-04): a auditoria aterrissou antes, de modo que a 009 nasce verde nessa
FR. Não há ciclo vermelho→verde a recuperar aqui — há regra a estrear. Registrado
nesta ADR para que o verde inicial nunca seja lido como prova do mecanismo.

**3. Teto 4 mantido; recalibragem com dados.** Rendimento observado: auditoria
001–004 achou 4 acionáveis/4 itens (2 altos); 005–008 achou 2 altos + 1 médio +
4 notas/4 itens. Densidade ≈ 1 achado relevante por item sustenta o teto até a
Fase 0 fechar (16 ÷ 4 = 4 auditorias exatas). Reavaliar granularidade por fase
(Fase 2, com agentes e não-determinismo, pode justificar teto menor) quando houver
ponto de dado da Fase 1 — nunca por intuição.

### Consequências

- A 009 herda via Contratos ("Recebido de itens anteriores"): relatório
  `f0-audit-005-008.md` + 1 FR de cadência no próprio oráculo.
- Auditoria segue não-item fora do mapa ADR-011; o que entra no mapa é só a FR
  que a exige. Nenhum oráculo 001–008 é tocado por esta ADR.

---

## ADR-017 — Registro da auditoria pós-008: exceção do manifest silencioso e pré-autorização de fronteira

**Data**: 2026-09-04 · **Item**: nenhum (checkpoint não-item, entre 008 e 009) ·
**Estado**: aceita · **Evidência**: `docs/plan/audit/f0-audit-005-008.md` (A1, A2,
M3, M4, B1–B3).

### 1. Exceção A1: edições pós-convergência sem ADR (`0e7b077`, `0afea59`)

Reconhecido e registrado, não perdoado: os dois commits alteraram oráculos
convergidos (004/005 e 007/008) e regeneraram o manifest sem decisão, violando
ADR-002/006/015a. A substância era legítima (conflito genuíno de fronteira:
a 008 põe `pip-audit` em dev por desenho; as fronteiras o proibiam) — por isso
exceção, não reversão. Reverter seria reescrever histórico (incidente, Lei Zero).

**Base congelada a partir desta ADR** (estado verificado `sha256sum -c` 8/8 em
2026-09-04; é este o presente que o futuro comparará):

```
63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22  f0-001
b63ac3c8aa329e6a5c7c210a044d0e4690728674bb27946fa04bf14607fb9a0c  f0-002
d10c61e8623fcf3f7c706ab8ca7387303c2d5282da0afaee50bf5c6401b6f7d4  f0-003
018926b5a6b89e481a03789921fb49bbe2ae75a94fc731f8513dc99ead91b730  f0-004
8ae95f8c9d7ad5514d7513abb8d8cdcef6d9bb3783fe271b4573086f752cd716  f0-005
5f2688463fbd061598ff5dc28733b2f095e37e0f8624d550aeacdd103e69782f  f0-006
da18a82ac2d8815480839fc1fd6858d50b0d340918e4e457ccd157d959d4bf32  f0-007
10c7323c562d4699c7ac49192dea10d230da0f2948a544403d371c231233412e  f0-008
```

**Nota de supersessão (B1):** a tabela do §(a) da ADR-015 reflete 2026-08-30 e
diverge da base acima no item 004. Não é reescrita (registro histórico); o
manifest é a fonte vigente e esta ADR é a ponte entre os dois estados.

### 2. Regra de pré-autorização de fronteira (A2) + transferência à 009

Asserção de fronteira ("ferramenta X ainda não existe") é verdade temporária; todo
item que adiciona ferramenta quebra a fronteira dos anteriores por desenho. A
partir desta ADR, o procedimento é:

1. O **PLAN do item novo declara o impacto de fronteira** (quais oráculos
   anteriores reprovarão sobre estado correto, e por quê);
2. A **decisão de ajuste entra por ADR prévia ao merge** (conflito de contrato
   entre specs, ADR-002) — nunca por fix pós-vermelho com regeneração silenciosa;
3. O padrão de legitimidade é o de `0e7b077`: **proibido ↔ ausente do `uv.lock`**,
   nunca proibido ↔ nome estático (nomes envelhecem; o lock é a fonte).

**Transferência à 009 (Lefthook):** seu PLAN declara o impacto sobre as fronteiras
004/005 (`lefthook` em pyproject/dev, `lefthook.yml` novo) sob esta regra antes de
qualquer merge. É a primeira execução do procedimento — e a prova de que A1 não
se repete.

### 3. Exceção M3: vermelho co-comitado em 005–008

`red.txt` estreia no mesmo commit feat que o verde nas quatro specs — ordem
temporal improvável, prova degradada a alegação. Sem reparo (histórico imutável);
exceção registrada. A partir da 009, vermelho em commit separado volta a ser
obrigatório.

### 4. Destinos menores

- M4 (texto T013 auto-referente na 005, oráculo correto): registro, sem ação.
- B2 (Trivy ⏭️ sem Docker na 008): validação plena transferida à 010 (ou 015).
- B3 (CI em servidor não-evidenciado, resíduo 003-T031): revalidar na 010.

---

## ADR-018 — Pré-autorização de fronteira da 009 (primeira execução do procedimento ADR-017)

**Data**: 2026-09-04 · **Item**: `009` (0.5), fase PLAN · **Estado**: aceita ·
**Evidência**: `docs/plan/research/f0-009-lefthook.md` (Q·fronteira) +
`specs/009-lefthook/plan.md` (declaração de impacto) · **Efeito**: autoriza os
ajustes abaixo **exclusivamente no commit verde da 009 (Fase C)**, nunca antes,
nunca depois, nunca além desta lista.

### Contexto

A 009 cria `lefthook.yml` + `lefthook==2.1.12` em dev por desenho — e cinco
asserções de oráculos anteriores proíbem exatamente isso (levantamento mecânico
`grep -n lefthook scripts/verify/f0-00*.sh`). Sem ajuste, o harness reprovaria
estado correto; com ajuste silencioso, repetiríamos o achado A1
(`f0-audit-005-008.md`). É o conflito de contrato entre specs que a ADR-002 manda
subir para decisão — esta ADR é essa decisão, **prévia a qualquer merge**.

### Ajustes autorizados (forma exata: padrão `0e7b077`, legitimidade via `uv.lock`)

| # | Oráculo | Ajuste |
|---|---|---|
| 1 | `f0-004` FR-012 | admitir `lefthook` em pyproject/groups **se** `name = "lefthook"` em `uv.lock`; admitir `lefthook.yml` (conteúdo = jurisdição da 009) |
| 2 | `f0-005` FR-015 | admitir existência de `lefthook.yml` |
| 3 | `f0-006` FR-014 | idem |
| 4 | `f0-007` FR-014 | idem |
| 5 | `f0-008` FR-013 | idem |

Manifest regenerado na Fase C **citando esta ADR** (é a ponte exigida pela
ADR-017, não "regeneração silenciosa"). Qualquer vermelho herdado fora destes 5
pontos após o verde é conflito novo e sobe para ADR própria — nunca para fix
direto.

### Consequências

- A FR-012 da 009 (oráculo asserir PLAN + esta ADR) nasce verificável desde o
  vermelho: antes da Fase C ela reprova (ajustes ainda não aplicados — correto,
  o estado ainda não os comporta); no verde, aprova.
- Estabelece o molde reutilizável: PLAN declara → ADR autoriza → verde aplica →
  manifest cita. A 010 (gitleaks, CI) e a 011/012 (`packages/`) herdam o molde.

---

## ADR-019 — Flake ambiental sob carga: registro, critério de convergência e transferência à 010

**Data**: 2026-09-04 · **Item**: `009` (0.5), fase CONVERGE · **Estado**: aceita ·
**Evidência**: runs do harness em loop durante a 009 (dados abaixo). **Classe**:
achado de uso (como ADR-008), não defeito de implementação — nenhuma asserção é
tocada por esta ADR.

### Dados observados (não alegados)

- ~60 execuções de oráculo em loops completos: 5 reprovações (~7%), em 5
  oráculos distintos (003-FR-014, 004, 007, 008-FR-007, 009-FR-014) — nunca a
  mesma FR duas vezes, nunca reproduzível isolada (002-nested 24/24 verde,
  008 6/6, 007 3/3, todos os oráculos 3–6× verdes sozinhos).
- 1 mecanismo capturado com prova: 008-FR-007 reprovou `grep "would have
  audited"` e a re-execução imediata para evidência **continha a string** —
  comportamento transiente da ferramenta externa, não erro de lógica.
- Carga sustentada ~4.0 durante os loops; oráculos disparam processos aninhados
  em paralelo e invocam ferramentas externas (`uv run`, `pip-audit`); asserts de
  temporização usam `EPOCHSECONDS` (resolução 1s).
- Nenhuma das FRs que falharam foi tocada pela 009 (únicos toques: 5 pontos
  ADR-018, sem relação com os pontos de falha).

### Decisão

**1. Natureza: ambiental e pré-existente, não regressão da 009.** O padrão
(falhas heterogêneas, isoladas-verdes, um caso com prova de transiência) é
incompatível com defeito de lógica introduzido — defeito de lógica reproduz.

**2. Critério de CONVERGE inalterado e cumprido.** CONVERGE exige harness exit 0
+ manifest + cadeia verdes — avaliado em run completo limpo (9/9 + 9/9 +
pytest 15 passed, evidência `green.txt` da 009). O critério nunca exigiu
"todo loop sempre verde sob qualquer carga"; nenhum item da história seria
reavaliado por esse padrão retroativo.

**3. Transferência à 010 (CI completo).** Endurecimento pertence ao pipeline,
não aos oráculos convergidos: dimensionar runner, política de retry/quarentena
para transientes de ferramenta externa, e tetos de tempo com margem para carga
(EPOCHSECONDS 1s é instrumento grosseiro sob load ~4). Até lá, loops locais sob
carga são evidência de tendência, não veredito.

**4. Procedimento futuro.** Flake com 2+ amostras na mesma FR vira defeito
investigado (não mais "ambiental por padrão"); quem alegar ambiental apresenta
tabela amostra/isolado como a acima.

---

## ADR-020 — Roteamento normativo dos achados multi-harness (anti-esquecimento)

**Data**: 2026-09-04 · **Item**: nenhum (checkpoint não-item, pós-009) ·
**Estado**: aceita · **Evidência**: `docs/plan/research/f0-skills-mcp-2026-09.md`
Apêndice E11–E18 (ECC, `harness/harness`, `deepseek-harness`, `open-design`,
`deer-flow`; vereditos contra fonte primária, fetch 2026-09-04).

### Problema

Achados estratégicos sem consumidor nomeado apodrecem em memória de conversa —
exatamente o que o princípio VII proíbe ("a mesma falha não possa repetir-se",
aqui na forma: o mesmo aprendizado não possa perder-se). O apêndice registra;
esta ADR **obriga o consumo**.

### Decisão

**1. Tabela de roteamento (fonte: E16).** Cada takeaway tem item consumidor e
momento de consumo fixados — invariante de log model-visible → 3.1/3.3;
seam triplo, composição em camadas, registry checksums, MCP hardening →
Emenda 3; ciclo de vida de instinto → 3.8/3.9; rule-packs → 3.8/010;
teto por run → 2.10; sandbox em modos → 2.6; trace-id → 3.4;
goals/compactação → 4.2/`core/context.py`.

**2. Regra de consumo.** O RESEARCH do item consumidor MUST citar e avaliar a
entrada correspondente; especificação que use o mecanismo sem a citação viola
rastreabilidade (VIII). ANALYZE que ignorar roteamento sem registro = achado
no mínimo MEDIUM. "Ficou para depois" sem transferência a item nomeado = a
mesma violação.

**3. Rejeições com motivo (não re-litigar).** Framework Cordis/TS (D3),
catálogo skills em bulk (bloat), auto-instalação por score (classe ADR-002),
IM channels, Gateway multi-worker, plataforma Harness como dependência,
packs de domínio no motor (tese mecanismo/conteúdo, E14). Reabertura exige
evidência nova, não releitura.

**4. Vigiado, não agendado.** Agendador de tarefas (E17): observação pós-MVP;
entrada no plano só por spec própria + ADR.

---

## ADR-022 — Pré-autorização de fronteira da 010 (003: SHA ⊃ tag; fronteira reduzida aos vetores)

**Data**: 2026-09-04 · **Item**: `010` (0.14), fase TESTS 🔴→GREEN · **Estado**:
aceita · **Evidência**: run vermelho da 010 (f0-003 FR-004/005/006 reprovam sobre
`ci.yml` estendido correto) + `specs/010-ci-completo/plan.md` (declaração
complementada) · **Efeito**: autoriza os ajustes abaixo **exclusivamente no
commit verde da 010 (Fase C)**.

### Contexto

Três conflitos genuínos, todos previstos pela classe mas não pela tabela (falha
de completude do PLAN da 010, registrada sem maquiagem — a FR-012 do oráculo
novo pegou o que a tabela esqueceu, que é exatamente para o que ela existe):

1. **FR-004/005 (003) exigem `@v7` literal.** SHA pins (`@3d3c42e5… # v7.0.1`)
   são estritamente mais fortes que tag major mutável para a intenção da 003
   ("versão verificada da família v7"). Exigir o literal eternizaria a forma
   mais fraca — inversão da intenção pela letra.
2. **FR-006 (003) proíbe o vocabulário inteiro da 010** (`ruff|mypy|…|uv
   |matrix:|cache:`) no `ci.yml`. A 010 é a dona designada do arquivo (Emenda 1);
   a proibição era verdade temporal (fronteira), não invariante. O invariante
   real são os **vetores** (`pull_request_target`, `workflow_run`).

### Ajustes autorizados (forma exata, só na Fase C)

| # | Oráculo | Ajuste |
|---|---|---|
| 1 | `f0-003` FR-004 | aceitar `actions/checkout@<40hex> # v7.0.1` como equivalente a `@v7` (SHA ⊃ tag); manter `fetch-depth: 0` + proximidade; atualizar descrição CANON para "família v7 (tag ou SHA+comentário)" |
| 2 | `f0-003` FR-005 | aceitar `actions/setup-python@<40hex> # v7.0.0` idem; manter `python-version 3.12` + veto `3.x`; atualizar descrição idem |
| 3 | `f0-003` FR-006 | reduzir lista proibida a `pull_request_target\|workflow_run`; remover palavras-ferramenta (dono atual: 010); atualizar descrição para "fronteira: sem vetores proibidos" |

Manifest regenerado na Fase C citando esta ADR. Qualquer outro vermelho herdado
fora destes pontos = conflito novo, ADR própria, nunca fix direto.

### Consequências

- Segunda execução do procedimento ADR-017 (primeira: ADR-018/009). O molde
  PLAN-declara → ADR-autoriza → verde-aplica → manifest-cita está estabelecido.
- Lição de método para auditoria pós-012: tabelas de impacto devem varrer
  **assertions literais** (grep por nome de ferramenta/versão nos oráculos
  anteriores), não só arquivos — a 010 varreu arquivos e perdeu 3 literais.

---

## ADR-021 — Pré-autorização de fronteira da 010: piso no lugar de igualdade (f0-009 FR-014)

**Data**: 2026-09-04 · **Item**: `010` (0.14), fase TESTS 🔴 · **Estado**: aceita ·
**Evidência**: run vermelho da 010 (`f0-009 --quiet` rc=1 por `LINES==9` com
manifest legítimo de 10 linhas) + `specs/010-ci-completo/plan.md` (declaração de
impacto) · **Efeito**: autoriza UM ajuste, **exclusivamente no commit verde da
010 (Fase C)**.

### Contexto

A 009 escreveu sua asserção de manifest com igualdade (`LINES=="9"`) em vez do
piso usado pela 005 (`-lt 5`, i.e. `>=5`) — asserção temporal: verdadeira no dia
da convergência, falsa no dia seguinte por acréscimo legítimo. É a classe A1/A2
exata, desta vez **descoberta pelo próprio vermelho da 010 antes de qualquer
merge** — o procedimento ADR-017 funcionou como desenhado (detecção pré-merge,
não pós-fix). Ironia registrada sem maquiagem: o auditor carregava a classe que
auditou; o mecanismo a pegou de todo modo.

### Ajuste autorizado (forma exata, espelho da 005)

Em `scripts/verify/f0-009-lefthook.sh` (FR-014): trocar igualdade por piso
(`>=9`) + manter `sha256sum -c` (a integridade real). Comentário citando esta
ADR. Manifest regenerado na Fase C da 010 citando esta ADR. Nada mais na 009 é
tocado; nenhum outro oráculo é tocado.

### Consequências

- A partir da 010, igualdade sobre contagem de manifest é padrão proibido em
  oráculos novos (piso + formato + `sha256sum -c`, molde 005/010).
- A FR-012 da 010 já nasce nesse padrão (`>=10`).

### Consequências

- Nenhum plano, spec ou oráculo muda por esta ADR — ela governa o futuro,
  não reescreve passado nem antecipa norma sobre artefato inexistente (IV).
- Qualquer chat/agente que chegue ao item X encontra obrigação + evidência
  sem depender desta conversa: ADR-020 aponta, E11–E18 fundamentam.
- A 010 não é afetada: seu conjunto de entrada permanece o fechado no checkpoint
  009 (contratos 008/009, ADR-009/015–017/019).

---

## ADR-023 — Pré-autorização de fronteira da 011: `packages/` admitido + `--all-packages` obrigatório

**Data**: 2026-09-04 · **Item**: `011` (0.6), fase TESTS 🔴→GREEN · **Estado**:
aceita · **Evidência**: run vermelho da 011 + `uv sync` puro removendo
`fkx-core`/`pydantic` do `.venv` (observado: `- python-dotenv`, `- fkx-core`;
`uv run --no-sync` sem módulo) + `specs/011-packages-core/plan.md`
(declaração) · **Efeito**: autoriza os ajustes abaixo **exclusivamente no
commit verde da 011 (Fase C)**.

### Contexto

Dois conflitos genuínos. (1) Cinco oráculos (004–008) proíbem `packages/` —
e a 011 **é** `packages/core` por desenho (item 0.6 do plano). (2) Descoberto no
verde: `uv sync` puro **remove** membros do workspace sob raiz virtual
(`[tool.uv] package = false`); sem `--all-packages`, CI (`uv sync --frozen`
em 6 jobs) e dev perdem `fkx_core` → `pytest` morre em collection ERROR.
A verificação "sync passou" (`Resolved/Checked`) sem `uv pip list`/import é
vácua — lição de método registrada: **saída de gerenciador não é prova de
instalação; import é**.

### Ajustes autorizados (forma exata, só na Fase C)

| # | Alvo | Ajuste |
|---|---|---|
| 1 | `f0-004/005/006/007/008` (fronteira `packages/`) | admitir `packages/core/` com `pyproject.toml` de membro (jurisdição 011); resto proibido; padrão ADR-018 |
| 2 | `.github/workflows/ci.yml` (010, 6 jobs com sync) | `uv sync --frozen` → `uv sync --frozen --all-packages`; substring preservada (FR-003/010 intactos); sem tocar jobs, pins ou triggers |

Manifest regenerado na Fase C citando esta ADR. Qualquer outro vermelho
herdado = conflito novo, ADR própria, nunca fix direto.

### Consequências

- Quarta execução do procedimento ADR-017. Padrão de setup do repo passa a ser
  `uv sync --all-packages` (documentado no quickstart da 011); `uv sync` puro
  é armadilha conhecida a partir desta ADR.
- Lição permanente: comandos de sync/listagem provam intenção; **import prova
  instalação** (vale para todo verificador futuro que dependa de pacote).

---

## ADR-024 — Pré-autorização de refinamento da 011: `py.typed` + `ErrorDetail` (achados do verde)

**Data**: 2026-09-04 · **Item**: `011` (0.6), fase TESTS 🔴→GREEN · **Estado**:
aceita · **Evidência**: `mypy --strict .` reprovando (`import-untyped`, PEP 561)
+ FR-005 exigindo `BaseModel` com spec sem modelo concreto · **Efeito**:
autoriza os ajustes abaixo **exclusivamente no commit verde da 011 (Fase C)**.

### Contexto

Dois achados genuínos do harness sobre o próprio item, ambos descobertos pelo
vermelho/verde antes de qualquer merge: (1) sem `py.typed`, o pacote instalado
é opaco ao mypy (PEP 561) — `f0-007` FR-008/009 pegou; (2) FR-005 exigindo
`BaseModel` mas a spec sem modelo concreto — `ErrorDetail(field, reason)`
fecha a lacuna com papel real (forma estruturada de `FkxError`, base da
observabilidade X e do futuro Guardião 3.8), sem especulação.

### Ajustes autorizados (forma exata, só na Fase C)

| # | Alvo | Ajuste |
|---|---|---|
| 1 | `packages/core/src/fkx_core/py.typed` | marcador PEP 561 vazio (empacotamento, não código) |
| 2 | `f0-011` FR-002 (próprio oráculo, ainda pré-verde) | whitelist admite `py.typed`; escopo de "nada além" = módulos `.py` (marcadores fora do escopo, registrado aqui — sem reescrita de spec) |
| 3 | `models.py` + `exceptions.py` + `__init__.py` | `ErrorDetail` + `FkxError.detail()` + export; teste de roundtrip |

Manifest regenerado na Fase C citando esta ADR. Nada de outros itens é tocado.

### Consequências

- Quinta execução do procedimento ADR-017 (primeira sobre o próprio item em
  construção — ainda pré-verde, sem pair vermelho afetado: o vermelho capturou
  `models.py` ausente, e `ErrorDetail` nasce dentro do verde que o apaga).
- Lição: checklist de empacotamento PEP 561 entra no template mental de pacotes
  futuros (012+): `pyproject` + `py.typed` + import desde o esqueleto.
- Lição de ferramenta: appends em `decisions.md` ancoram SEMPRE no tail
  verificado na hora (âncora em texto do meio insere no meio; re-ancorar no
  mesmo texto duplica) — falha cometida duas vezes nesta sessão, pega pelo
  `grep ^## ADR-` antes do commit.

---

## ADR-025 — Hierarquia de fontes, triangulação mínima e roteamento dos limites honestos

**Data**: 2026-09-04 · **Item**: nenhum (checkpoint não-item, pré-012) ·
**Estado**: aceita · **Evidência**: convenção praticada nos researches 005–011
(cabeçalho P0–P3) + sessão estratégica pós-011 (50k usuários, legados).

### Problema

A hierarquia de fontes existia como convenção, não como norma: nada impedia um
RESEARCH futuro de citar blog obscuro como fonte única de versão — e limites
honestos (carga só se prova no alvo; sem env, verificação parcial; sem env
sanitizado, sem resgate) viviam em conversa, não em artefato (violação VII por
omissão).

### Decisão

**1. Hierarquia normativa (vale para todo RESEARCH, motor e projetos gerados).**
P0 = registry API + executado + arquivos do repo · P1 = docs oficiais +
releases · P2 = engenharia big-tech/padrões · P3 = comunidade (só com
corroboração P0/P1). Proibido como fonte única: sem data, sem autoria
verificável, SEO-farm.

**2. Triangulação mínima.** Versão ou comportamento externo exige ≥2 fontes
independentes incluindo P0. Alegação com fonte única é achado em ANALYZE
(no mínimo MEDIUM; HIGH se versão de supply chain).

**3. Roteamento dos limites (structural-honest, não removível por design).**
(a) Carga/escala: afirmação exige medição; instrumento (k6 ou outro) é detalhe
do item DevOps (Fase 2), a decidir no RESEARCH dele — sem vencedor antecipado.
(b) Todo sistema gerado sai com matriz de verificação *provado-vs-declarado*
como artefato obrigatório; modo de verificação limitada declara-se no
`interview` (requisito de desenho do ciclo: 4.2/4.6/CONVERGE). (c) Resgate sem
env sanitizado não opera (portão de ciclo futuro, Lei Zero já proíbe o dado).
(d) Ferramenta de carga e demais vigiados: backlog E17/ADR-020.

### Consequências

- Nenhum código, oráculo, spec ou plano muda por esta ADR — ela normatiza
  processo e roteia futuro. Primeira norma nascida de sessão estratégica,
  não de auditoria: o molde checkpoint serve aos dois.
- ANALYZE que ignorar fonte única sem registro = achado (fecha o loop com o §2).

---

## ADR-026 — Pré-autorização de fronteira da 012: `packages/cli/` admitido

**Data**: 2026-09-05 · **Item**: `012` (0.7), fase TESTS 🔴→GREEN · **Estado**:
aceita · **Evidência**: run 10/12 da 012 (`f0-004/005/006/007/008/011`
reprovam sobre estado correto) + `specs/012-packages-cli/plan.md`
(declaração) · **Efeito**: autoriza os ajustes abaixo **exclusivamente no
commit verde da 012 (Fase C)**.

### Contexto

Seis conflitos genuínos, todos previstos na tabela Q10 do research
(`docs/plan/research/f0-012-packages-cli.md`, levantamento mecânico
`grep -n "packages" scripts/verify/f0-00*.sh`). A 012 **é** `packages/cli`
por desenho (item 0.7 do plano); cinco oráculos asserem `packages/` só-com-
`core/` e um assere `cli/` ausente. Sem ajuste, o harness reprovaria estado
correto; com ajuste silencioso, repetiríamos o achado A1
(`f0-audit-005-008.md`).

### Ajustes autorizados (forma exata, só na Fase C)

| # | Alvo | Ajuste |
|---|---|---|
| 1 | `f0-004` FR-012 | `grep -v -x "core"` → `grep -v -x -e "core" -e "cli"` + exigir `packages/cli/pyproject.toml` de membro quando `cli/` presente (jurisdição 012); resto proibido; padrão ADR-023 |
| 2 | `f0-005` FR-015 | idem (forma da linha 590) |
| 3 | `f0-006` FR-014 | idem (forma da linha 434) |
| 4 | `f0-007` FR-014 | idem (forma da linha 467) |
| 5 | `f0-008` FR-013 | idem (forma da linha 495) |
| 6 | `f0-011` FR-002 (linha 146) | `packages/cli existe (deve ser 012)` → admitir `cli/` com `pyproject.toml` de membro (guarda cumprida); resto da FR intacto |

Legitimidade via `uv.lock` (padrão ADR-018): `fkx-cli` + `typer` + `rich`
presentes no lock. Manifest regenerado na Fase C citando esta ADR.
Qualquer outro vermelho herdado = conflito novo, ADR própria, nunca fix
direto.

### Consequências

- Sexta execução do procedimento ADR-017. A FR-012 da 012 (oráculo asserir
  PLAN + esta ADR) aprova no verde.
- Achados laterais da Fase C (fora da tabela acima, sem tocar oráculo
  alheio): `[tool.uv.sources] fkx-core = { workspace = true }` obrigatório
  para dep membro→membro (`uv lock` recusa sem ele); re-sync
  `--all-packages` obrigatório após criar `src/` (sync com só-pyproject
  instala `dist-info` sem `.pth` editável → `import fkx_cli` falha).

---

## ADR-027 — Trava de cadência da auditoria, segunda geração: sinal líder + portão pytest

**Data**: 2026-09-05 · **Item**: nenhum (checkpoint não-item, pós-012) ·
**Estado**: aceita · **Origem**: achado M2 de `docs/plan/audit/f0-audit-009-012.md`
(auditoria exigiu 2 lembretes do mantenedor) · **Efeito**: normativo imediato;
nenhum oráculo, workflow, spec ou plano muda por esta ADR.

### Problema

A ADR-016 posiciona a FR de cadência no oráculo da **5ª** spec: trava tardia,
que dispara no meio do item seguinte. Nada computa o estado na fronteira
N+4→N+5. Todos os gatilhos dependiam de contar até quatro — julgamento onde
deveria haver regra (I, VI). Prova: 2 lembretes.

### Decisão

**1. Sinal líder (toda sessão vê).** O bloco de estado de
`docs/guides/agent-bootstrap.md` contém one-liner puro-leitura que imprime
`AUDIT OK (n/4)` ou `AUDIT DUE (4/4)`, computado como no §3. Sessão nova sem
o sinal = bootstrap desatualizado (achado em auditoria, no mínimo MEDIUM).

**2. Portão pytest (ninguém bypassa sem deixar rastro).**
`test_audit_cadence` em `tests/test_harness_debts.py`: falha quando
`convergidas − cobertas ≥ 4` sem relatório cobrindo. Roda no hook pre-commit
(`pytest -q`) e no job `tests` do CI (required check) — mesma doutrina ADR-009,
sem tocar workflow nem oráculos (regra 5 intacta; nenhuma ADR de fronteira
exigida para a trava em si).

**3. Computação determinística (definida aqui, nunca na cabeça do agente).**

- `convergidas` = linhas `✅` no mapa `specs/README.md:9` (fonte ADR-011).
- `cobertas` = maior `MMM` entre `docs/plan/audit/f0-audit-NNN-MMM.md` com
  cabeçalhos grepeáveis `Veredito`, `Achados`, `Destino` (formato ADR-014).
- `convergidas − cobertas < 4` → passa; `≥ 4` → falha nomeando a faixa
  descoberta (X). A FR da ADR-016 permanece como segunda trava (sem
  contradição: esta dispara na fronteira, aquela no converge da 5ª).

**4. Doutrina das camadas (o que cada uma pega e por construção perde).**

| Camada | Pega | Por construção perde |
|---|---|---|
| Oráculo (harness) | conformidade mecânica: arquivos, pins, exits, bytes, hashes | procedimento (verde por construção), semântica, prosa de planos |
| pytest TDD | comportamento executável; regressão | decisões de desenho; o spec estar certo |
| ANALYZE | inconsistência entre artefatos | o que nenhum artefato diz (cobertura varia por item) |
| Auditoria | semântica, ausência, procedimento, ciclo executado | a própria cadência (esta ADR fecha); perspicácia (mérito do auditor) |
| Trava de cadência | o esquecimento da auditoria | nada além disso — escopo proposital |

O harness é tão bom quanto as perguntas feitas antes dele existir; a auditoria
é a camada que inventa perguntas novas. Mecanizá-la garante que aconteça;
a densidade de achados (§6) mede se foi perspicaz.

**5. Gatilho condicional da Fase 1.** Recalibragem por dado, nunca por
intuição: se a auditoria pós-016 render **≥3 achados HIGH**, a Fase 1 abre em
cadência 2 por default. Ponto de dado 009–012: 2 HIGH — gatilho **não**
dispara (registrado como dado).

### Consequências

- Auditoria sem trava passa a ser dívida rastreável a esta ADR, não conversa.
- `test_audit_cadence` nasce com TDD sobre fixtures (prova 🔴→🟢 sem o repo
  jamais avermelhar — repo vermelho travaria todos os commits via hook).
- Ordem normativa: auditoria devida primeiro (repo sempre verde), mecanismo
  em seguida. Mecanismo antes da dívida = auto-bloqueio via hook.
- **Adendo pós-primeira-execução-servidora:** todo RESEARCH declara o que o
  item assume sobre o ambiente de execução e onde está a prova executada
  dessa suposição (lacuna que gerou a ADR-030).

---

## ADR-028 — Exceção fundamentada de fluxo: `main` direto na Fase 0 + poda

**Data**: 2026-09-05 · **Item**: nenhum (checkpoint não-item, pós-012) ·
**Estado**: aceita · **Origem**: divergência entre `CONTRIBUTING.md` §2
(`feature/*` de `develop`, de volta a `develop`) e a prática (tudo direto em
`main`; `develop`, `003-ci-minimo`, `004-uv-workspace` abandonadas).

### Decisão

**1. Exceção, não licença.** Fluxo `main`-direto vale **somente na Fase 0**,
fundamentado em: 1 mantenedor + 1 agente, hook integral por commit, histórico
linear como evidência legível de TDD (molde ADR-007). É a terceira aplicação
do molde "exceção com prazo e gatilho".

**2. Condição de saída explícita.** Primeiro colaborador com write **ou**
primeiro PR externo ⇒ fluxo por `feature/*` + PR entra em vigor na mesma
sessão, por decisão registrada (sem migração silenciosa).

**3. Poda parcial (correção em sessão: poda total era inválida).**
Ponteiros locais `003-ci-minimo`, `004-uv-workspace` (100% em `main`,
verificado `git branch --merged`) removidos. `develop` foi removida e
**restaurada na mesma sessão**: `f0-001` FR-002 exige a existência da linha
`develop` (30/30 reprovou sem ela) — removê-la quebraria oráculo convergido
(ADR-002), o que nenhuma ADR de fluxo pode autorizar sem o procedimento de
fronteira. `develop` permanece como linha exigida pelo harness, ainda que sem
uso; seu destino (reavivar com fluxo por PR ou migrar a asserção) decide-se
junto da condição de saída, nunca antes.

### Consequências

- A divergência deixa de ser silenciosa: ou cabe nesta exceção, ou é achado.
- A proteção da 010 (PR + checks), quando aplicada (A1 → 013), exigirá na
  prática o fluxo por PR — as duas dívidas se encontram e se pagam juntas.

> **Adendo 2026-09-05 (migração servidor):** condição de saída antecipada —
> proteção aplicada em `pasqualinigui/fluksos-x` + cenário 🧑 executado (PR com
> defeito travado, push direto recusado). Exceção `main`-direto **encerrada**;
> fluxo passa a `feature/*` + PR nesta sessão. Ver ADR-029 (dívida que o novo
> fluxo expôs) e `specs/010-ci-completo/branch-protection.md` (evidência).

---

## ADR-029 — Correção de enunciado: FR-001 mede a linha, não a sessão

**Data**: 2026-09-05 · **Item**: nenhum (checkpoint não-item, migração
servidor) · **Estado**: aceita · **Origem**: 5ª lacuna da ADR-007 + cenário 🧑
A1 (pre-push travou em `feature/*` por `linha atual: feature/f0-a1-proof`).

### Contexto

O enunciado diz *"a linha principal é `main`"* (propriedade do repositório);
a implementação media *"estou em `main` agora"* (propriedade da sessão).
Sob fluxo `main`-direto, as duas leituras coincidiam e o defeito dormia; sob
fluxo por PR (obrigatório pós-proteção), o oráculo reprova push legítimo —
a exceção da ADR-007 venceu pelo motivo errado e a dívida veio cobrar.

### Decisão (forma exata, única mudança autorizada neste arquivo)

Em `scripts/verify/f0-001-foundation.sh`, bloco GRUPO A: trocar a medida de
HEAD (`symbolic-ref ... BRANCH = main`) por existência de
`refs/heads/main` (`show-ref --verify --quiet`, espelho da FR-002 e do teste
`test_main_branch_exists` da 005, que já pagava a detecção). Enunciado e
descrição CANON inalterados — a implementação passa a dizer o que o
enunciado sempre disse. Manifest regenerado citando esta ADR. Nada mais
neste oráculo é tocado; nenhum outro oráculo é tocado.

### Consequências

- Sétima execução do procedimento ADR-017 (primeira sobre o item 001 —
  intocável desde a convergência; a forma é a mesma das anteriores).
- O pagamento da 005 (teste de existência) e a correção desta ADR se somam:
  detecção + comportamento, sem contradição.

> **Adendo (mesma sessão, antes de qualquer push):** a correção acima move o
> resumo de `f0-001` (`63412ca7…` → `d00b9299…`), e `f0-002` FR-021a fixa o
> valor antigo por número (mecanismo ADR-006, anterior ao manifest). Sem
> atualizar a linha fixada, o pre-push reprova push legítimo em `feature/*`
> — a cadeia de integridade funcionando como desenhada. Fica autorizada,
> **exclusivamente**, a atualização da constante `HASH_F0_001` em `f0-002`
> para o novo resumo (+ comentário citando esta ADR) e a regeneração do
> manifest. É consequência mecânica da correção acima, não segunda mudança
> de semântica: nenhuma asserção muda de sentido, só o número fixado
> acompanha o estado autorizado.

---

## ADR-030 — Remediação da primeira execução servidora (5 gaps, 1 PR)

**Data**: 2026-09-05 · **Item**: nenhum (checkpoint não-item, migração
servidor) · **Estado**: aceita · **Evidência**: run `33946950104` (PR #1) +
run `33947842158` (PR #2) + reproduções locais (`COLUMNS=0/10`) · **Efeito**:
autoriza os ajustes abaixo **neste PR**, com re-verde no runner antes do
merge. Nada além desta tabela é tocado.

### Contexto

Primeira execução do pipeline em servidor encontrou 5 gaps, nenhum detectável
localmente (princípio VIII nunca tocou o runner em 12 itens — lacuna de método
registrada na ADR-027 §5). Todos com prova no log; todos de ambiente/setup;
zero defeito de lógica do produto.

### Ajustes autorizados (forma exata)

| # | Alvo | Ajuste |
|---|---|---|
| 1 | `ci.yml` (jobs `verify`, `harness`, `tests`, `coverage`) | step `Materialize refs + identity` após Checkout: `git fetch origin main:refs/heads/main develop:refs/heads/develop` + `git config --local user.name/email github-actions[bot]` (reconstrói o que o oráculo define; setup, não jogo) |
| 2 | `ci.yml` (job `secrets`) | `env: GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` (breaking da action v3, README oficial; token da Actions, Lei Zero intacta) |
| 3 | `f0-001` SC-002 | pular merges sintéticos `^Merge [0-9a-f]{40} into \S+` (leitura formalizada: registro automatizado do GitHub não é registro de autor; commitlint segue validando o intervalo) |
| 4 | `tests/conftest.py` + sonda `f0-012` + `env` do CI | `COLUMNS=80` (determinismo I, espelho de `LC_ALL=C`; app intacto; terminal estreito real = limite documentado, endurecimento só com relato) |
| 5 | Manifest | regenerado citando esta ADR |

Manifest regenerado na aplicação citando esta ADR. Qualquer outro vermelho
no runner fora destes 5 pontos = conflito novo, ADR própria, nunca fix
direto.

> **Nota de execução:** cada edição autorizada em `f0-001` move seu resumo e
> exige acompanhar `HASH_F0_001` em `f0-002` + manifest (consequência
> mecânica do Adendo ADR-029, aqui pela edição SC-002). Cadeia verificada
> pelo próprio pre-push antes de cada push — o mecanismo mordeu duas vezes
> nesta sessão, ambas a favor da integridade.

### Consequências

- O PR que aplica este pacote só converge verde no runner (prova da prova).
- A1 encontra aqui sua quitação operacional: pipeline executa + portão
  decide no servidor (evidência em `branch-protection.md`).
- Pergunta-padrão de ambiente entra no RESEARCH a partir da 013 (adendo
  ADR-027): *"o que este item assume sobre o ambiente de execução, e onde
  está a prova executada dessa suposição?"*
