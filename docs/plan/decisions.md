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
