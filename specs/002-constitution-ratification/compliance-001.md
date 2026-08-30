# Veredito de Conformidade Retroativa — artefatos do item 001

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30
**Governança avaliadora**: `.specify/memory/constitution.md` v1.0.0
**Requisito**: FR-017 · **Critério**: SC-007 (100% dos artefatos com veredito)

Os 16 artefatos entregues pelo item 001 são reavaliados contra os dez princípios
recém-ratificados. O conjunto está fixado em `research.md` E8.
`.specify/memory/constitution.md` fica fora: este item o reescreve, e revalidar
contra si mesmo o artefato que define o critério seria circular.

> **Regra de parada (FR-017b).** Qualquer veredito não conforme **interrompe o
> ciclo** e submete a decisão ao mantenedor. Corrigir o artefato, emendar o
> princípio ou registrar exceção são as três saídas, e nenhuma é aplicável
> automaticamente. Este é o primeiro precedente de conflito entre governança e
> trabalho já convergido no motor.

---

## Resultado

| | |
|---|---|
| Artefatos avaliados | **16 / 16** |
| Conformes | **15** |
| Não conformes | **1** |
| Estado do ciclo | ⚠️ **INTERROMPIDO — decisão do mantenedor pendente** |

---

## Vereditos

| # | Artefato | Princípios avaliados | Veredito |
|---|---|---|---|
| 1 | `.gitignore` | V, VI, X | conforme |
| 2 | `CONTRIBUTING.md` | II, V, VI, IX | conforme |
| 3 | `docs/plan/decisions.md` | VII, VIII | conforme |
| 4 | `docs/plan/research/f0-001-git-branching.md` | I, VIII | conforme |
| 5 | `scripts/verify/README.md` | VI, IX, X | conforme |
| 6 | `scripts/verify/f0-001-foundation.sh` | I, V, **VI**, IX, X | 🔴 **nao conforme** |
| 7 | `specs/001-git-branching-strategy/spec.md` | II, IV | conforme |
| 8 | `specs/001-git-branching-strategy/plan.md` | I, II, IV | conforme |
| 9 | `specs/001-git-branching-strategy/research.md` | I, VIII | conforme |
| 10 | `specs/001-git-branching-strategy/data-model.md` | IV | conforme |
| 11 | `specs/001-git-branching-strategy/quickstart.md` | III, X | conforme |
| 12 | `specs/001-git-branching-strategy/tasks.md` | II, III | conforme |
| 13 | `specs/001-git-branching-strategy/contracts/oracle-cli.md` | IV, VI, X | conforme |
| 14 | `specs/001-git-branching-strategy/checklists/requirements.md` | II | conforme |
| 15 | `specs/001-git-branching-strategy/evidence/t015-red.txt` | III | conforme |
| 16 | `specs/001-git-branching-strategy/evidence/t023-green.txt` | III | conforme |

---

## 🔴 Não conformidade — artefato 6 contra o princípio VI

**Artefato**: `scripts/verify/f0-001-foundation.sh`
**Princípio**: **VI — O harness é o oráculo**
**Critério de violação**: *"existe critério de aceitação sem asserção
correspondente no harness"*

### Evidência

Correspondência **em substância**, não por homonímia — um critério coberto por
asserção de nome diferente conta como coberto:

| Critério (spec 001) | Asserção que o decide | Estado |
|---|---|---|
| `SC-001` zero proibidos no histórico | `FR-020a` + `FR-020b` | coberto |
| `SC-002` registros classificáveis | `SC-002` | coberto |
| `SC-003` **< 5 s** e duas execuções idênticas | `FR-018` (checagem **estática** do fonte) | 🔴 **parcial** — o tempo não é medido; a igualdade entre execuções não é comparada empiricamente |
| `SC-004` par vermelho→verde preservado | — | 🔴 **nenhuma** |
| `SC-005` nome revela fase, pacote e propósito | `FR-006` + `FR-006b` | coberto |
| `SC-006` roda só com o do bootstrap | `FR-019` | coberto |
| `SC-007` contratos declarados por escrito | — | 🔴 **nenhuma** |

Verificação executada:

```
grep -n "SECONDS|cmp -s|diff " scripts/verify/f0-001-foundation.sh   -> nenhum
grep -n "evidence|red.txt|green.txt" ...                             -> nenhum
grep -n "Contratos|Transferido" ...                                  -> nenhum
```

`FR-018` verifica que o **fonte do script** não contém construção não
determinística. É uma checagem estática: ela não observa se duas execuções
produzem de fato a mesma saída, nem quanto tempo a execução leva. São garantias
diferentes, e `SC-003` pede as duas.

### Por que isto não é rigor excessivo

O item 001 é o único dos doze que nunca foi julgado por uma governança ratificada
— a dívida que a ADR-003 registrou e transferiu a este item. Três critérios de
aceitação seus são verificados **por leitura humana**, que é exatamente o que o
princípio VI existe para substituir. Enquanto o harness não os cobre, "o item 001
está conforme" continua sendo opinião.

O contraste torna o achado concreto: o item 002 cobre as mesmas três lacunas —
`SC-006` mede o tempo, `FR-020c` compara duas execuções byte a byte, `FR-022`
assere o par de evidências, `FR-023` assere a seção de contratos, e a §2.1 do seu
contrato declara nominalmente cada critério sem asserção homônima e quem o decide.
Nada disso existia quando o item 001 convergiu.

### Por que o ciclo parou aqui

`FR-017b` proíbe que eu escolha. As três saídas possíveis são:

| Saída | O que implica |
|---|---|
| **A — Corrigir o artefato** | Acrescentar as asserções faltantes a `f0-001-foundation.sh`. Colide frontalmente com a **ADR-002** e com a asserção `FR-021a` deste item: o resumo criptográfico fixado mudaria, e a regra "um item nunca modifica o oráculo de um item anterior" seria quebrada logo no ciclo que a tornou mecânica |
| **B — Emendar o princípio VI** | Restringir a exigência a itens posteriores à ratificação. Enfraquece o princípio no seu primeiro exercício e cria precedente de que governança recua diante de trabalho já feito |
| **C — Registrar exceção fundamentada** | Manter o princípio íntegro, registrar que o item 001 antecede a ratificação, e transferir a cobertura das três lacunas a um item nomeado — com prazo, não indefinidamente |

Nenhuma foi aplicada. O oráculo reprova `FR-017b` e nomeia o par
artefato×princípio até que a decisão seja registrada aqui.

### Decisão do mantenedor

**Saída escolhida**: **C — exceção fundamentada com transferência a item nomeado**

**Fundamentação**: A saída A quebraria a ADR-002 e invalidaria `FR-021a` deste
mesmo item — o resumo criptográfico fixado de `f0-001-foundation.sh` mudaria, e a
regra "um item nunca modifica o oráculo de um item anterior" cairia exatamente no
ciclo que a tornou mecânica. A saída B enfraqueceria o princípio VI no seu
primeiro exercício, logo depois de ele ter encontrado uma lacuna real que a
revisão humana do item 001 não pegou. A saída C reconhece a não conformidade, a
registra, e transfere a cobertura ao **item 004 (0.4 — Pytest)**, que já tem por
desenho a tarefa de promover cada oráculo a módulo de teste: as quatro asserções
faltantes entram **como casos de teste novos, ao lado**, nunca dentro do oráculo
do item 001. A exceção **expira quando o item 004 convergir** — se ele convergir
sem cobri-las, o achado reabre.

**Registro**: `docs/plan/decisions.md` › **ADR-007**

**Data**: 2026-08-30

### Estado após a decisão

| | |
|---|---|
| Não conformidade | reconhecida e registrada |
| `scripts/verify/f0-001-foundation.sh` | **intocado** — resumo `63412ca7…5a6bbf22` permanece válido |
| Princípio VI | íntegro, sem emenda |
| ADR-002 | íntegra |
| Cobertura transferida a | **item 004 (Pytest)**, 5 casos nomeados |
| Prazo | convergência do item 004 |

---

## Adendo — quinta lacuna, encontrada no uso (2026-08-30)

Durante a Fase 9 deste item, `FR-001` do oráculo do item 001 reprovou ao trabalhar
numa linha de funcionalidade:

```
🔴 FR-001  repositorio existe e linha principal e main
           evidencia: linha atual: feature/f0-constitution-ratification
```

A asserção mede **a linha apontada por HEAD**, não a existência da linha
principal. `refs/heads/main` existia. Enunciado e implementação divergem, e o
efeito é que o harness reprova em qualquer linha de funcionalidade — o fluxo que o
`CONTRIBUTING.md` §2 do próprio projeto prescreve.

Mesma classe, mesma decisão (**C**): transferida ao item 004 como caso de teste
novo, sem tocar em `f0-001-foundation.sh`. Até lá, o registro do bootstrap
permanece em `main` — que é o que o item 001 de fato fez.

**Nota de método**: as quatro primeiras lacunas vieram de comparação sistemática
entre critérios e asserções. Esta veio de **usar** o harness num fluxo que ele
nunca tinha visto. As duas formas de achado são necessárias, e nenhuma substitui a
outra.

---

# Cenário 3 — Teste de decidibilidade dos dez princípios

**Data**: 2026-08-30 · **Tarefa**: T041 · **Critério**: `SC-002`
**Método**: para cada princípio, um artefato real do repositório e a pergunta
*"este artefato viola este princípio?"* — respondida **sem discutir o que o
princípio quis dizer**. Só o critério de violação escrito na governança conta.

Este é um dos dois cenários que a máquina não decide. `FR-005b` assere que o
critério de violação **existe e está rotulado**; se ele é **utilizável** é o que se
mede aqui.

| № | Princípio | Artefato testado | Observado | Veredito | Decidido sem interpretação? |
|---|---|---|---|---|---|
| **I** | Determinismo sobre probabilidade | `scripts/verify/f0-002-constitution.sh` | Zero decisões dependentes de saída de modelo. O único casamento de `llm` na busca foi a substring dentro de `re.fullmatch` | **não viola** | ✅ sim |
| **II** | Especificação precede código | `scripts/verify/f0-002-constitution.sh` | `specs/002-constitution-ratification/` existe; spec e oráculo entraram no mesmo registro `13014e8`, spec não posterior ao código | **não viola** | ✅ sim |
| **III** | Teste antes da implementação | `specs/002-constitution-ratification/evidence/` | `red.txt` em `13014e8`; `green.txt` em `7e88314`, **posterior**. O par existe e o verde não precede o vermelho | **não viola** | ✅ sim |
| **IV** | Definição de dados antes da implementação | `scripts/verify/f0-002-constitution.sh` | Contrato de entrada/saída em `contracts/oracle-cli.md`: invocação, três códigos de saída, formato de linha, 33 asserções | **não viola** | ✅ sim |
| **V** | Segurança é a Lei Zero | `.gitignore` e o índice do repositório | `git ls-files -i -c --exclude-standard` devolve **0**; a trava de dependências permanece versionável (`FR-013` do item 001, verde) | **não viola** | ✅ sim |
| **VI** | O harness é o oráculo | `scripts/verify/f0-001-foundation.sh` | `SC-003` coberto só parcialmente, `SC-004` e `SC-007` sem asserção, `FR-001` mede a linha apontada por HEAD | 🔴 **viola** | ✅ sim |
| **VI** | O harness é o oráculo | `scripts/verify/f0-002-constitution.sh` | `SC-002` → `FR-005b` + cenário 3; `SC-004` → `FR-011` + cenário 6. Correspondência existe e a fronteira está declarada no contrato §2.1 | **não viola** | ✅ sim |
| **VII** | Auto-reparo atualiza a documentação | `scripts/verify/f0-002-constitution.sh` | As cinco correções deste ciclo alteraram o oráculo e/ou o contrato — artefatos normativos | **não viola** | ⚠️ **não** — ver abaixo |
| **VIII** | Elo verificado antes de lógica | `docs/plan/research/f0-002-constitution.md` | O oráculo consome git e Python 3.12; ambos verificados e registrados em `docs/plan/research/` | **não viola** | ✅ sim |
| **IX** | Agnosticismo de stack | `AGENTS.md` | Zero referências a ferramenta de sistema-alvo fora de adaptador declarado | **não viola** | ✅ sim |
| **X** | Observabilidade | `scripts/verify/f0-002-constitution.sh` | 52 chamadas de resultado, **todas** carregando identificador de requisito; nenhum caminho de falha anônimo | **não viola** | ✅ sim |

## Resultado

| | |
|---|---|
| Princípios testados | **10** (11 vereditos — VI testado contra dois artefatos) |
| Decididos sem interpretação | **9 de 10** |
| Exigiram interpretação | **1 — princípio VII** |
| Violações encontradas | **1**, já registrada e decidida (ADR-007, saída C) |

## 🔴 O princípio VII não foi decidível

Foi o único veredito que não saiu do critério escrito. O enunciado diz:

> *"Ao corrigir uma falha, o ciclo MUST registrar **a causa** no artefato normativo
> correspondente, de modo que a mesma falha não possa repetir-se sem ser
> detectada."*

O critério de violação diz:

> *"existe correção de falha cujo registro **não altera nenhum artefato
> normativo**."*

**As duas frases cobram coisas diferentes.** A correção do regex de `py_decisao`
alterou o oráculo — pelo critério, não viola. Mas a **causa** não estava registrada
em lugar nenhum até T045, e nada impedia alguém reintroduzir `\s*` no dia seguinte:
pelo enunciado, o propósito não era servido.

Precisei escolher entre as duas leituras para emitir veredito. **Isso é exatamente
o que `FR-005` proíbe.** Adotei o critério, porque é ele que a governança declara
como teste — declarar violação onde o critério não a sustenta seria o falso
positivo que o princípio existe para evitar.

O achado é o produto mais valioso deste cenário: `FR-005b` assere que o critério
**existe**, e ele existia. A máquina não tem como ver que ele é **mais fraco que o
enunciado que deveria operacionalizar**. Só o uso mostra.

Encaminhado como **candidato a emenda PATCH** em T047 — a ser exercitado por
`/speckit-constitution` próprio. Emendar governança de dentro de outro comando é
o que a ADR-007 estabeleceu que não se faz.

## Cenário 6 — pendente de ação do mantenedor

`SC-004` exige que o agente construtor carregue a orientação de `AGENTS.md` em
toda sessão, sem ação manual. **Nenhum processo automatizado pode verificar isso**:
um script não observa o contexto carregado por outro processo (research E6).

`FR-011` verde assere que a diretiva `@AGENTS.md` está no lugar documentado pelo
fornecedor — o mecanismo, nunca o efeito.

### Registro do mantenedor (T042) — ✅ APROVADO

**Procedimento executado**: sessão nova do agente construtor na raiz do projeto,
pergunta *"qual é a etapa do ciclo canônico entre especificação e planejamento?"*

**Resultado observado**: resposta correta — **CLARIFY**. O agente citou
`AGENTS.md` **pelo nome**, reproduziu a sequência canônica completa
`RESEARCH → SPECIFY → CLARIFY → PLAN → TASKS → ANALYZE → TESTS 🔴 → IMPLEMENT 🟢 → CONVERGE`
e explicou o propósito da etapa — *"fechar ambiguidades antes de o planejamento
derivar tarefas dela"*. Nenhuma ação manual de carregamento foi necessária.

**Data**: 2026-08-30 · **Executado por**: mantenedor

### O que este resultado prova, e o que não prova

**Prova** o efeito que `FR-011` não alcança: a orientação foi carregada
automaticamente ao início da sessão. `SC-004` satisfeito.

**Prova também a cadeia de importação de C4.** O agente construtor lê `CLAUDE.md`,
não o arquivo do formato aberto — e ainda assim atribuiu o conteúdo ao
`AGENTS.md`. A diretiva `@AGENTS.md` fez o trabalho: fonte única, sem duplicação,
e o agente enxerga a fonte, não o importador. Era exatamente esta a razão de o
link simbólico ter sido rejeitado em C5.

**Não prova** que o comportamento se mantém se a documentação do fornecedor mudar.
Se algum dia `FR-011` ficar verde e este cenário falhar, o defeito estará na
asserção mecânica — que precisará ser revista, nunca contornada.

## Estado final da revalidação retroativa

| Critério | Estado |
|---|---|
| `SC-007` — 16/16 artefatos com veredito | ✅ |
| `SC-002` — dez princípios decidíveis (cenário 3) | ✅ 9 de 10 sem interpretação; princípio VII encaminhado por ADR-008 |
| `SC-004` — carregamento automático (cenário 6) | ✅ verificado pelo mantenedor |
| Não conformidade encontrada | 1, decidida pela saída C (ADR-007) |
