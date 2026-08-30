# Contract: Oráculo de Conformidade — item 002

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30
**Artefato**: `scripts/verify/f0-002-constitution.sh`

Este contrato **não redefine a interface do harness**. A interface é normativa e
vive em [`specs/001-git-branching-strategy/contracts/oracle-cli.md`](../../001-git-branching-strategy/contracts/oracle-cli.md):
mesmos códigos de saída (`0`/`1`/`2`), mesmos parâmetros (`--quiet`, `--list`),
mesmo formato de linha, mesmas seis restrições de implementação. O que segue são
as **asserções específicas deste item**.

> Conformidade com o contrato herdado é ela própria uma asserção (`FR-020`).
> Um oráculo deste item que divergisse da interface passaria a exigir tratamento
> especial de onze consumidores — o oposto do que a interface existe para evitar.

---

## 1. Restrição de dependências

Idêntica à do item 001, por posição no bootstrap: **shell, git e Python 3.12
stdlib**. As ferramentas de qualidade chegam nos itens 004–009.

---

## 2. Asserções

33 asserções em cinco grupos. Sufixos `a`/`b`/`c` são refinamento local **deste
contrato**: a spec define o requisito sem decomposição, e aqui ele é quebrado nas
verificações mecânicas que o compõem.

**Uma exceção**: `FR-017b` **não** é refinamento local — é requisito próprio da
spec, acrescentado por `/speckit-clarify` na sessão 2026-08-29. A asserção
homônima o verifica diretamente, sem decompor nada.

### Grupo A — Governança ratificada

| ID | Asserção | Severidade |
|---|---|---|
| `FR-001` | Zero campos de preenchimento remanescentes — padrão `[ALL_CAPS]` **fora de comentário HTML** (research D4) | crítica |
| `FR-002` | Versão presente, semântica, e a ratificação inaugural é `1.0.0` | média |
| `FR-003` | Todas as datas da governança em formato ISO `YYYY-MM-DD` | média |
| `FR-004` | Dez princípios presentes, numeração romana **contínua** `I`–`X`, sem lacuna nem repetição | alta |
| `FR-005a` | Cada princípio contém ao menos um verbo normativo (`MUST` / `MUST NOT` / `SHOULD` com razão declarada) | alta |
| `FR-005b` | Cada princípio declara **critério de violação** rotulado `**Violation:**` e não vazio | alta |
| `FR-006` | Cada princípio declara **origem** rotulada `**Source:**` e não vazia | alta |
| `FR-007` | A seção de governança declara as três subseções: procedimento de emenda, política de versionamento, expectativa de revisão de conformidade | média |
| | *A seção é localizada por `## Governance` **ou** `## Governança` — o modelo canônico usa a forma inglesa. O nome do cabeçalho não é o requisito; as três subseções são. Correção aplicada em 2026-08-30, após `FR-007` reprovar com as três subseções presentes: o defeito estava no oráculo, não na governança* | |
| `FR-008` | Registro de impacto presente, **em ocorrência única**, contendo versão anterior, versão nova, princípios acrescentados e pendências deferidas | média |

> `FR-005b` é a asserção de maior consequência do item. Ela não julga se o
> critério é *bom* — isso é o cenário humano de `quickstart.md`. Ela garante que o
> critério **existe e é rotulado**, tornando sua ausência impossível de passar
> despercebida. Sem esse rótulo, "princípio decidível" volta a ser autoavaliação.

### Grupo B — Porta de entrada

| ID | Asserção | Severidade |
|---|---|---|
| `FR-009` | Existe orientação no local convencional do formato aberto — `AGENTS.md` na raiz | alta |
| `FR-010a` | Contém identidade do motor, instruções de operação e ponteiros para as fontes normativas | média |
| `FR-010b` | **Não reproduz** o texto integral dos princípios nem do plano de implementação | alta |
| `FR-011` | `CLAUDE.md` existe na raiz e contém a diretiva de importação exata de `AGENTS.md` | alta |
| `FR-012` | Nenhuma linha de **prosa normativa** duplicada entre os dois arquivos (métrica research D5) | média |
| `FR-013` | `CLAUDE.md` é **arquivo regular** — nunca link simbólico (research D7) | alta |
| `FR-014` | Orçamento respeitado: `AGENTS.md` ≤ 150 linhas e a **soma** dos dois ≤ 175 | média |

> **Fronteira declarada em `FR-011`.** Um script não observa o carregamento de
> contexto de outro processo. Esta asserção verifica o **mecanismo documentado
> pelo fornecedor**, não o efeito em tempo de execução (research D6). O efeito é
> verificado pelo cenário manual de `quickstart.md`. `FR-011` verde não é prova de
> comportamento de sessão, e o contrato registra isso para que ninguém o leia como
> se fosse.

> `FR-014` incide sobre a **soma** porque repartir conteúdo entre arquivos não
> reduz o contexto carregado — o importado entra junto. Uma implementação que
> asserisse apenas por arquivo aprovaria a exata evasão que o limite proíbe.

### Grupo C — Ciclo de desenvolvimento

| ID | Asserção | Severidade |
|---|---|---|
| `FR-015` | A governança declara o ciclo canônico normativo **incluindo a etapa de clarificação** entre especificação e planejamento | média |
| `FR-016a` | O documento de contribuição declara o mesmo ciclo, com a etapa de clarificação | média |
| `FR-016b` | Nenhum documento **normativo** mantém o ciclo anterior em circulação | alta |

> Escopo de `FR-016b`: `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md` e a governança.
> Artefatos de especificação e evidência ficam fora — eles registram o passado, e
> reescrever registro histórico para satisfazer uma asserção seria falsificação,
> não conformidade.

### Grupo D — Obrigações herdadas do item 001

| ID | Asserção | Severidade |
|---|---|---|
| `FR-017a` | Existe documento de veredito retroativo, e ele nomeia os **16** artefatos fixados (research D8) — comparação de conjuntos, não de contagem | alta |
| `FR-017b` | **Nenhuma não conformidade pendente de decisão.** Veredito `nao conforme` sem decisão do mantenedor registrada **reprova** e nomeia o par artefato×princípio; com decisão registrada, aprova | crítica |
| `FR-018` | O registro de derivação nomeia os princípios oriundos do material transitório e **transcreve** o trecho de origem | alta |
| `FR-019a` | O material de referência transitório **não existe** no disco | alta |
| `FR-019b` | Nenhuma linha das regras de exclusão referencia o material transitório | alta |
| `SC-008` | Toda exclusão marcada como **transitória** aponta para alvo existente — regra órfã reprova (research D3) | média |

> `FR-017b` é a mecanização da parada obrigatória decidida em `/speckit-clarify`.
> O oráculo **não escolhe** entre corrigir o artefato, emendar o princípio ou
> registrar exceção: ele reprova, nomeia e para. A escolha é do mantenedor.
>
> **Depois de registrada, a decisão libera o ciclo.** É o que `tasks.md` T031
> especifica: *"só prosseguir com 16/16 conforme, **ou com decisão explícita do
> mantenedor registrada**"*. Uma asserção que reprovasse para sempre tornaria a
> saída "exceção fundamentada" inalcançável — a governança nunca poderia conviver
> com uma dívida reconhecida, só apagá-la ou capitular. Registro exigido: saída
> escolhida, fundamentação, data ISO e a decisão arquitetural que a formaliza.
>
> **Correção de contrato aplicada em 2026-08-30.** A redação anterior — *"todo
> veredito é conforme; qualquer não conforme reprova"* — divergia de T031 e da
> própria spec. `/speckit-analyze` não pegou a divergência porque comparou
> cobertura de identificadores, não semântica de enunciado.

> `FR-019a` só pode ficar verde **depois** da última ação mutante do ciclo. É essa
> a garantia de ordem: um plano que removesse o material antes da revisão
> satisfaria `FR-019` isoladamente e ainda assim destruiria a única oportunidade
> de consulta que `FR-018` exige.

### Grupo E — Meta e não regressão

| ID | Asserção | Severidade |
|---|---|---|
| `FR-020a` | Os três códigos de saída obedecem à semântica do contrato herdado | alta |
| `FR-020b` | `--quiet` e `--list` comportam-se conforme o contrato herdado | alta |
| `FR-020c` | Duas execuções consecutivas sobre o mesmo estado produzem saída idêntica | alta |
| `FR-021a` | **Integridade**: o resumo criptográfico de `f0-001-foundation.sh` bate com o valor fixado (research D2) | alta |
| `FR-021b` | **Aprovação**: `f0-001-foundation.sh --quiet` sai com código `0` | alta |
| `FR-022` | Existem as evidências vermelha e verde deste item, e elas diferem entre si | média |
| `FR-023` | A especificação deste item declara Contratos entregues e transferidos | média |
| `SC-006` | Este oráculo conclui em menos de 5 segundos | alta |

> **Por que `FR-021` são duas asserções.** Executar o oráculo anterior e obter `0`
> prova que ele **aprova**, não que está **íntegro**: um item futuro poderia
> enfraquecer uma asserção e continuar saindo `0`. É a regressão silenciosa que a
> ADR-002 proíbe e que nenhuma execução detecta. `FR-021a` torna a regra "um item
> nunca modifica o oráculo de um item anterior" mecanicamente verificável, em vez
> de acordada entre cavalheiros e conferida por leitura de diff.

---

## 2.1 Critérios de sucesso sem asserção própria

Seis dos oito critérios de sucesso da spec **não** possuem asserção homônima:
são decididos pela asserção do requisito funcional que os realiza. O mapa evita
que a ausência seja lida como lacuna de cobertura.

| Critério | Decidido por | Observação |
|---|---|---|
| `SC-001` | `FR-001` | zero campos em aberto |
| `SC-002` | `FR-005b` **+ cenário 3 do quickstart** | a máquina verifica que o critério existe; a decidibilidade é julgada por humano |
| `SC-003` | `FR-014` | orçamento medido automaticamente |
| `SC-004` | `FR-011` **+ cenário 6 do quickstart** | o oráculo assere o mecanismo; o efeito de sessão é humano (research E6) |
| `SC-005` | `FR-022` | par vermelho→verde preservado |
| `SC-007` | `FR-017a` | 100 % dos 16 artefatos, por comparação de conjuntos |

`SC-006` (tempo) e `SC-008` (exclusão órfã) têm asserção própria porque não são
consequência de nenhum requisito funcional isolado.

---

## 3. Recursão

`FR-020a`, `FR-020b` e `FR-020c` executam o próprio oráculo. A guarda é a mesma do
item 001 — a variável `FKX_ORACLE_NESTED=1` marca a execução aninhada, que pula as
asserções auto-referenciais. `FR-021b` invoca o oráculo do item **001**, cuja
própria guarda já é interna a ele; medido em ~0,3 s, incluído no orçamento de
`SC-006` (research E1).

---

## 4. Valores fixados

| Constante | Valor | Origem |
|---|---|---|
| Resumo de `f0-001-foundation.sh` | `63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22` | medido em research E2 |
| Orçamento de `AGENTS.md` | 150 linhas | pesquisa de domínio C6 |
| Orçamento somado | 175 linhas | limite documentado de 200, com margem de 25 para 003–012 |
| Conjunto retroativo | 16 caminhos | research E8 |
| Comprimento mínimo de linha para a métrica de duplicação | 40 caracteres | research E5 |

Um valor fixado que precise mudar é **conflito de contrato entre specs** e sobe
para decisão explícita, exatamente como manda a regra de não regressão.
