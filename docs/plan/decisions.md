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

| Spec | Item do plano | Título | Justificativa da posição |
|---|---|---|---|
| `001` | **0.9** | Git + branching strategy | O Spec-Kit cria feature desde a primeira spec; a prova vermelho→verde exige histórico |
| `002` | **0.11** | AGENTS.md / constitution | Governa as 10 specs seguintes; o portão constitucional do Spec-Kit lê este artefato |
| `003` | **0.1** | UV workspace monorepo | Base física de todos os pacotes |
| `004` | **0.4** | Pytest | Habilita TDD real dos itens seguintes — precisa vir antes de Ruff |
| `005` | **0.2** | Ruff | |
| `006` | **0.3** | MyPy strict | Consome contrato do Ruff: regras que conflitam com tipagem estrita |
| `007` | **0.12** | pip-audit + Trivy | Precisa existir antes de ser orquestrado |
| `008` | **0.5** | Lefthook | Orquestra 005, 006, 004 e 007 — só faz sentido depois deles |
| `009` | **0.6** | `packages/core` | Primeiro código de produção |
| `010` | **0.7** | `packages/cli` | Depende de `core` |
| `011` | **0.8** | docker-compose | Domínio independente (DevOps) |
| `012` | **0.10** | `docs/tree.md` | Por último: reflete a árvore real resultante |

> ⚠️ **Este mapa foi emendado.** A **ADR-011** o substitui: a Emenda 1 do plano
> (ADR-009) acrescentou quatro itens à Fase 0, e a inserção deles altera as
> posições de execução. A tabela acima permanece como registro do estado original
> de 12 itens; **a fonte de verdade vigente é a ADR-011**.

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
