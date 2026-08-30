---
description: "Task list for 002 — Ratificação da Governança e Porta de Entrada"
---

# Tasks: Ratificação da Governança e Porta de Entrada para Agentes

**Input**: Design documents from `/specs/002-constitution-ratification/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`,
`contracts/oracle-cli.md`, `contracts/entrypoint.md`, `quickstart.md`

**Tests**: o ciclo vermelho→verde é **obrigatório** neste item (FR-022, SC-005).
As ferramentas de teste ainda não existem no bootstrap — a prova de test-first é o
oráculo em shell executado e preservado antes da implementação.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável — arquivo diferente, sem dependência de tarefa incompleta
- **[Story]**: `US1`..`US4`, conforme `spec.md`
- Todo caminho de arquivo é explícito

## Path Conventions

Raiz do monorepo. Este item **não produz código de aplicação** — o protocolo de
ratificação proíbe criar ou modificar fonte de aplicação. Produz governança
(`.specify/memory/`), porta de entrada (raiz) e a segunda peça do harness
(`scripts/verify/`).

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template ordena as fases por prioridade de história (P1 → P4). **Este arquivo
não segue essa ordem**, e a inversão é normativa, não conveniência:

| Ordem por prioridade | Ordem executada aqui | Motivo |
|---|---|---|
| US1 (P1) primeiro | **US2 (P2) primeiro** | O oráculo precisa existir e **reprovar** antes de qualquer implementação. É a única prova de test-first disponível antes do item 004, e não é recuperável depois |
| US4 (P4) por último | **US4 dividida** — parte em Foundational, parte no fim | A consulta ao material transitório precisa preceder tudo que possa removê-lo; a remoção precisa ser a última ação mutante (FR-019) |

Três restrições de ordem que **nenhuma tarefa pode violar**:

1. **T011 (vermelho) antes de T013** — implementar antes de registrar o vermelho
   satisfaz todos os FR e ainda assim falha `SC-005`.
2. **Fase 2 (transcrição) antes da Phase 8 (remoção)** — remover antes de
   transcrever destrói a rastreabilidade dos quatro princípios derivados.
3. **Phase 7 (revalidação) antes da Phase 8 (remoção)** — a revalidação pode
   **interromper o ciclo**; interromper depois de destruir o material seria o pior
   dos dois mundos.

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Tarefas | História |
|---|---|---|---|
| Fase A — Preparação | Phase 1 + Phase 2 | T001–T004 | — (bloqueante) |
| Fase B — Oráculo em vermelho 🔴 | Phase 3 | T005–T012 | US2 |
| Fase C — Ratificação | Phase 4 | T013–T019 | US1 |
| Fase D — Porta de entrada | Phase 5 | T020–T023 | US3 |
| Fase E — Ciclo canônico | Phase 6 | T024–T027 | US3 |
| Fase F — Revalidação retroativa ⚠️ | Phase 7 | T028–T031 | US4 |
| Fase G — Remoção 🔒 | Phase 8 | T032–T034 | US4 |
| Fase H — Verde e convergência 🟢 | Phase 9 | T035–T039 | — |

---

## Phase 1: Setup (Registro das constantes fixadas)

**Purpose**: fixar em artefato versionado os valores que o oráculo vai asserir,
antes de o oráculo existir. Um valor fixado dentro do script e em lugar nenhum
mais é indistinguível de número mágico.

- [X] T001 Criar **ADR-006** em `docs/plan/decisions.md` registrando o resumo criptográfico fixado de `scripts/verify/f0-001-foundation.sh` (`63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22`) e a justificativa de research E2: executar o oráculo anterior prova que ele **aprova**, não que está **íntegro** — um item futuro poderia enfraquecer uma asserção e continuar saindo `0`, que é a regressão silenciosa proibida pela ADR-002 e invisível a qualquer execução (FR-021a)
- [X] T002 Acrescentar à **ADR-006** em `docs/plan/decisions.md` a convenção `# transitorio:` para exclusões com data de validade, com a evidência de research E3 — 79 dos 80 padrões literais do `.gitignore` apontam para alvo inexistente, e estão corretos, porque a regra de exclusão existe para preceder o arquivo; `SC-008` fica restrito às exclusões marcadas (FR-019b, SC-008)

---

## Phase 2: Foundational (Transcrição do material transitório) ⚠️ BLOQUEANTE

**Purpose**: extrair do material de referência tudo que precisa sobreviver à sua
remoção. **Nenhuma tarefa da Phase 8 pode começar antes desta fase estar completa.**

**⚠️ CRÍTICO**: esta é a única oportunidade de consulta. Depois da Phase 8 o
material não existe, e o que não estiver transcrito aqui é irrecuperável.

- [X] T003 Ler `docs/AGENTS-EXAMPLE.md` integralmente e registrar na **ADR-006** (`docs/plan/decisions.md`) a tabela de derivação dos princípios, com o trecho **transcrito** e a linha de origem: I *Determinismo* (parcial, L3 e L41), IV *Definição de dados antes da implementação* (L26, L80–86), VII *Auto-reparo atualiza a documentação* (L88–95), VIII *Elo verificado antes de lógica* (L32–35). Transcrever, nunca referenciar — um ponteiro para o arquivo seria referência morta no instante seguinte à T032 (FR-018)
- [X] T004 Registrar na **ADR-006** o que foi **descartado** do material e por quê: as cinco fases B.L.A.S.T. e as três camadas A.N.T. são arquitetura de projeto de automação e não princípios de motor; a persona *System Pilot* é identidade de agente e este item ratifica governança; a fase *Cloud Transfer* pressupõe destino em nuvem e colide com o princípio IX (FR-018)

**Checkpoint**: material transcrito. A remoção da Phase 8 passa a ser segura.

---

## Phase 3: User Story 2 — Oráculo de conformidade (Priority: P2) 🔴 Portão vermelho

**Goal**: uma verificação que responda por código de saída, e não por julgamento,
antes de existir qualquer coisa para ela aprovar.

**Independent Test**: executar em estado incompleto e observar reprovação nominal
por requisito; executar duas vezes e obter saída idêntica.

- [X] T005 [US2] Criar `scripts/verify/f0-002-constitution.sh` com o esqueleto do contrato **herdado** do item 001: parsing de `--quiet` e `--list`, resolução da raiz pela localização do próprio script (nunca pelo diretório corrente), códigos de saída `0`/`1`/`2`, formato `<status> <REQ-ID> <descrição>`, linha de resultado final, mapa canônico único de descrições e guarda de recursão `FKX_ORACLE_NESTED` (FR-020a, FR-020b, contrato §1–§3)
- [X] T006 [US2] Implementar em `scripts/verify/f0-002-constitution.sh` o **Grupo A — Governança ratificada**, 9 asserções: `FR-001` (zero `[ALL_CAPS]` **fora de comentário HTML**, per research D4), `FR-002` (versão semântica, inaugural `1.0.0`), `FR-003` (datas ISO), `FR-004` (dez princípios, numeração romana contínua I–X sem lacuna nem repetição), `FR-005a` (verbo normativo por princípio), `FR-005b` (rótulo `Violação:` presente e não vazio), `FR-006` (rótulo `Origem:` presente e não vazio), `FR-007` (três subseções de governança), `FR-008` (registro de impacto em ocorrência **única**)
- [X] T007 [US2] Implementar em `scripts/verify/f0-002-constitution.sh` o **Grupo B — Porta de entrada**, 7 asserções: `FR-009` (`AGENTS.md` na raiz), `FR-010a` (identidade, operação e ponteiros), `FR-010b` (não reproduz o texto integral dos princípios nem do plano), `FR-011` (`CLAUDE.md` contém a diretiva de importação exata — asserção de **mecanismo documentado**, não de efeito de sessão, per research D6), `FR-012` (métrica de prosa normativa de research D5: linha normalizada ≥ 40 caracteres, fora de bloco de código, interseção vazia), `FR-013` (`CLAUDE.md` é **arquivo regular**, nunca link simbólico), `FR-014` (`AGENTS.md` ≤ 150 linhas **e a soma** ≤ 175)
- [X] T008 [US2] Implementar em `scripts/verify/f0-002-constitution.sh` o **Grupo C — Ciclo de desenvolvimento**, 3 asserções: `FR-015` (a governança declara o ciclo canônico com a etapa de clarificação entre especificação e planejamento), `FR-016a` (o documento de contribuição declara o mesmo ciclo), `FR-016b` (nenhum documento **normativo** — `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, governança — mantém o ciclo anterior em circulação; artefatos de especificação e evidência ficam **fora** do escopo, porque são registro histórico e reescrevê-los seria falsificação)
- [X] T009 [US2] Implementar em `scripts/verify/f0-002-constitution.sh` o **Grupo D — Obrigações herdadas**, 6 asserções: `FR-017a` (o documento de veredito nomeia os **16** artefatos de research D8 — comparação de **conjuntos**, nomeando os ausentes, nunca de contagem), `FR-017b` (todo veredito é `conforme`; qualquer `nao conforme` **reprova** e nomeia o par artefato×princípio sem escolher a saída), `FR-018` (o registro de derivação nomeia os princípios e **transcreve** o trecho), `FR-019a` (o material transitório não existe no disco), `FR-019b` (nenhuma linha das regras de exclusão o referencia), `SC-008` (toda exclusão marcada `# transitorio:` aponta para alvo existente)
- [X] T010 [US2] Implementar em `scripts/verify/f0-002-constitution.sh` o **Grupo E — Meta e não regressão**, 8 asserções: `FR-020a` (semântica dos três códigos de saída), `FR-020b` (`--quiet` e `--list` conforme o contrato herdado), `FR-020c` (duas execuções produzem saída idêntica), `FR-021a` (**integridade**: resumo criptográfico de `f0-001-foundation.sh` bate com o valor fixado na ADR-006), `FR-021b` (**aprovação**: `f0-001-foundation.sh --quiet` sai com `0`), `FR-022` (evidências vermelha e verde existem e diferem), `FR-023` (a spec declara Contratos entregues e transferidos), `SC-006` (este oráculo conclui em menos de 5 s)
- [X] T011 [US2] 🔴 **Executar** `scripts/verify/f0-002-constitution.sh` e preservar a saída íntegra em `specs/002-constitution-ratification/evidence/red.txt`. Esperado `exit=1`, com reprovação nominal de `FR-001` (governança ainda em branco), `FR-009` e `FR-011` (porta de entrada inexistente) e `FR-017a` (veredito inexistente). `FR-019a` reprova **por design** — o material precisa existir nesta fase (SC-005, FR-022)
- [X] T012 [US2] Conferir na saída de T011 que `FR-021a` e `FR-021b` **já aprovam nesta fase**: o oráculo do item 001 está íntegro e aprovando desde antes de este item começar. Uma reprovação aqui significa que a regra de não regressão foi quebrada antes mesmo do trabalho — e sobe para decisão, nunca para atualização do valor fixado (FR-021)

**Checkpoint**: existe oráculo e existe prova registrada de que ele reprova. A
partir daqui, qualquer verde é auditável contra este vermelho.

---

## Phase 4: User Story 1 — Governança executável (Priority: P1) 🎯 Núcleo do item

**Goal**: os princípios deixam de viver espalhados por documentos de planejamento e
passam a existir como governança ratificada, versionada e **decidível**.

**Independent Test**: tomar cada princípio e um artefato real do repositório, e
emitir veredito de conformidade sem discutir o que o princípio quis dizer.

- [X] T013 [US1] Reescrever `.specify/memory/constitution.md` com os **dez princípios I–X** de `data-model.md`, cada um contendo enunciado normativo (`MUST` / `MUST NOT`), rótulo `Violação:` com estado **observável de artefato**, e rótulo `Origem:` — com o trecho transcrito para os quatro derivados do material transitório. Numeração romana contínua, sem lacuna (FR-004, FR-005, FR-006)
- [X] T014 [US1] Preencher em `.specify/memory/constitution.md` a seção **Restrições Adicionais**: escada de dependências do harness por item do bootstrap, proibição de escrita em configuração de escopo global da máquina, e a trava de cadeia de suprimentos versionada (FR-001, herda item 001)
- [X] T015 [US1] Preencher em `.specify/memory/constitution.md` a seção **Fluxo de Desenvolvimento** declarando o ciclo canônico normativo `RESEARCH → SPECIFY → CLARIFY → PLAN → TASKS → ANALYZE → TESTS 🔴 → IMPLEMENT 🟢 → CONVERGE`, com a etapa de clarificação explicitamente entre especificação e planejamento (FR-015)
- [X] T016 [US1] Preencher em `.specify/memory/constitution.md` a seção **Governança** com as três subseções obrigatórias: procedimento de emenda, política de versionamento (MAJOR remove ou redefine, MINOR acrescenta, PATCH esclarece) e expectativa de revisão de conformidade (FR-007)
- [X] T017 [US1] Emitir no topo de `.specify/memory/constitution.md` o **registro de impacto** como comentário HTML em **ocorrência única**: versão anterior (*modelo não ratificado*), versão nova (`1.0.0`), os dez princípios acrescentados nomeados, seções alteradas e pendências deferidas com o item destinatário (FR-008)
- [X] T018 [US1] Preencher o rodapé de `.specify/memory/constitution.md`: versão `1.0.0`, data de ratificação e data de última emenda, todas em formato ISO `YYYY-MM-DD` (FR-002, FR-003)
- [X] T019 [US1] Executar `scripts/verify/f0-002-constitution.sh` e confirmar **Grupo A verde (9/9)**. Reprovação de `FR-005b` aqui significa princípio sem critério de violação — que não pode ser ratificado como está: ou ganha critério objetivo, ou é rebaixado a orientação não normativa em seção separada. Reprovação de `FR-001` significa campo de preenchimento remanescente: um campo deliberadamente deferido precisa **sair do formato de placeholder** e virar prosa justificada, senão "deferido" e "esquecido" ficam indistinguíveis (SC-001, SC-002)

**Checkpoint**: o portão substituto deixa de ser necessário. A partir daqui,
planejamento e análise julgam contra governança ratificada.

---

## Phase 5: User Story 3 — Porta de entrada operacional (Priority: P3)

**Goal**: qualquer agente descobre o motor sem ler mil linhas de planejamento, e o
agente que o constrói carrega essa orientação em toda sessão.

**Independent Test**: sessão nova do agente construtor num diretório limpo, sem
nenhuma ação manual de carregamento.

- [X] T020 [US3] Criar `AGENTS.md` na raiz conforme `contracts/entrypoint.md` §2, com as seis seções obrigatórias — Identidade, Como operar, Ciclo canônico, Regras que não se quebram, Onde estão as fontes, Precedência — em **≤ 150 linhas**, contendo apenas **ponteiros**: MUST NOT reproduzir o texto integral dos princípios nem do plano de implementação (FR-009, FR-010, FR-014)
- [X] T021 [US3] Criar `CLAUDE.md` na raiz com a diretiva de importação exata `@AGENTS.md` mais uma seção curta do que é específico do agente construtor e não cabe no formato aberto. **Arquivo regular** — link simbólico é proibido porque exige privilégio de administrador no Windows, e o artefato é versionado e viaja (FR-011, FR-013, C5)
- [X] T022 [US3] Executar os cenários 4 e 5 de `quickstart.md` antes de seguir: orçamento (`AGENTS.md` ≤ 150 e soma ≤ 175) e duplicação de prosa (interseção vazia). Estourar o orçamento **não** se resolve repartindo em mais arquivos — o importado é carregado junto; a única saída é promover texto a ponteiro (FR-012, FR-014, SC-003)
- [X] T023 [US3] Executar `scripts/verify/f0-002-constitution.sh` e confirmar **Grupo B verde (7/7)** — `FR-009`, `FR-010a`, `FR-010b`, `FR-011`, `FR-012`, `FR-013`, `FR-014`

---

## Phase 6: User Story 3 — Ciclo canônico em circulação (Priority: P3)

**Goal**: a etapa de clarificação, adotada a partir deste item, existe em forma
normativa e nenhuma versão anterior do ciclo permanece circulando.

**Independent Test**: um agente lê o ciclo na porta de entrada e encontra a
clarificação entre especificação e planejamento.

- [X] T024 [US3] Atualizar `CONTRIBUTING.md` §5 substituindo `RESEARCH → SPEC → PLAN → TASKS → ANALYZE → TESTS → IMPLEMENT → CONVERGE` pelo ciclo com a etapa de clarificação, e acrescentar às regras que o sustentam a razão de ela existir: fechar ambiguidade **antes** de o planejamento derivar tarefas dela (FR-016a)
- [X] T025 [US3] Varrer `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md` e `.specify/memory/constitution.md` confirmando que o ciclo anterior não permanece em circulação. **Não** tocar em artefatos de especificação nem de evidência dos itens 001 e 002 — são registro histórico, e reescrevê-los para satisfazer uma asserção seria falsificação, não conformidade (FR-016b)
- [X] T026 [P] [US3] Atualizar `scripts/verify/README.md` registrando o que o item 002 passa a verificar — as 33 asserções em cinco grupos e o novo mecanismo de integridade por resumo criptográfico — conforme o contrato de crescimento do harness (§6 do contrato do item 001, ADR-002)
- [X] T027 [US3] Executar `scripts/verify/f0-002-constitution.sh` e confirmar **Grupo C verde (3/3)** — `FR-015`, `FR-016a`, `FR-016b`

---

## Phase 7: User Story 4 — Revalidação retroativa (Priority: P4) ⚠️ PONTO DE PARADA

**Goal**: os artefatos já entregues pelo item 001 são julgados contra a governança
que acabou de existir — o primeiro exercício real do portão.

**Independent Test**: existe veredito escrito para cada artefato do item anterior,
nomeando princípio e artefato.

- [X] T028 [US4] Criar `specs/002-constitution-ratification/compliance-001.md` com a tabela dos **16 artefatos** fixados em research E8: `.gitignore`, `CONTRIBUTING.md`, `docs/plan/decisions.md`, `docs/plan/research/f0-001-git-branching.md`, `scripts/verify/README.md`, `scripts/verify/f0-001-foundation.sh` e os 10 artefatos sob `specs/001-git-branching-strategy/`. `.specify/memory/constitution.md` fica **fora**: este item o reescreve, e revalidar contra si mesmo o artefato que define o critério é circular (FR-017a, SC-007)
- [X] T029 [US4] Emitir em `compliance-001.md` o veredito de cada artefato contra os princípios que sobre ele incidem, com os campos da entidade *Veredito de conformidade retroativa* de `data-model.md`: artefato, princípios avaliados, veredito `conforme` \| `nao conforme`, e fundamentação **obrigatória** quando não conforme (FR-017)
- [X] T030 [US4] ⚠️ **Se qualquer veredito for `nao conforme`**: registrar o achado em `compliance-001.md`, **interromper o ciclo** e submeter a decisão ao mantenedor. MUST NOT corrigir o artefato, emendar o princípio ou registrar exceção por conta própria — este é o primeiro precedente de conflito entre governança e trabalho já convergido, e precedente estabelecido por omissão vira jurisprudência sem ninguém ter decidido (FR-017b)
- [X] T031 [US4] Executar `scripts/verify/f0-002-constitution.sh` e confirmar `FR-017a` e `FR-017b` verdes. Só prosseguir com 16/16 `conforme`, ou com decisão explícita do mantenedor registrada em `compliance-001.md`

**Checkpoint**: dívida do item 001 quitada, ou ciclo interrompido por decisão
pendente. Não há terceira saída.

---

## Phase 8: User Story 4 — Remoção do material transitório (Priority: P4) 🔒 ÚLTIMA AÇÃO MUTANTE

**Goal**: o material de referência sai de circulação sem deixar rastreabilidade
órfã nem regra de exclusão apontando para o vazio.

**Independent Test**: o material não existe e nenhuma regra de exclusão o menciona.

**⚠️ Pré-condição dura**: Phase 2 completa (transcrição) **e** Phase 7 concluída
sem interrupção pendente. Executar esta fase antes destas satisfaz `FR-019`
isoladamente e destrói a única oportunidade de consulta que `FR-018` exige.

- [X] T032 [US4] Remover `docs/AGENTS-EXAMPLE.md` do disco. Tudo que dele deriva já está transcrito na ADR-006 (T003, T004) e nos rótulos `Origem:` dos princípios I, IV, VII e VIII (T013) (FR-019a)
- [X] T033 [US4] Remover de `.gitignore` a entrada `docs/AGENTS-EXAMPLE.md` **e o bloco de comentário que a explica** (o bloco de 11 linhas de comentário mais a entrada, linhas 45–56 da versão do item 001), para não deixar regra órfã apontando para alvo inexistente (FR-019b, SC-008)
- [X] T034 [US4] Executar `scripts/verify/f0-002-constitution.sh` e confirmar **Grupo D verde (6/6)** — inclusive `FR-019a`, que só pode ficar verde depois desta fase, e é essa a garantia mecânica da ordem

---

## Phase 9: Polish & Convergência 🟢

**Purpose**: fechar o ciclo vermelho→verde, provar determinismo e executar o que a
máquina não decide.

- [X] T035 🟢 Executar `scripts/verify/f0-002-constitution.sh` e preservar a saída íntegra em `specs/002-constitution-ratification/evidence/green.txt`. Esperado `exit=0` com **33/33** asserções aprovadas (SC-005, FR-022)
- [X] T036 Executar o cenário 9 de `quickstart.md`: duas execuções consecutivas produzindo saída **idêntica** e `git status` sem nenhuma alteração provocada pelas execuções — um oráculo que altera o estado que mede não é oráculo (FR-020c)
- [X] T037 [P] Executar o cenário 8 de `quickstart.md`: harness acumulado `f0-001` e `f0-002`, ambos `exit=0`, **cada um** abaixo de 5 s. A execução conjunta é a soma; não há teto agregado nesta fase — a decisão foi transferida ao item 008 (SC-006)
- [X] T038 [P] Executar os cenários **3 e 6** de `quickstart.md` — os dois que a máquina não decide: dez vereditos de decidibilidade emitidos sem discutir o que o princípio quis dizer (SC-002), e sessão nova do agente construtor carregando a orientação sem ação manual (SC-004)
- [X] T039 Registrar o ciclo em commits obedecendo à convenção do próprio item 001 (`CONTRIBUTING.md` §1), separando o vermelho do verde para que o par fique auditável no histórico (`FR-022`, `SC-005`)

---

## Dependencies

### Ordem de fases (estrita)

```
Phase 1 (T001–T002)
   ↓
Phase 2 (T003–T004)  ⚠️ BLOQUEANTE para a Phase 8
   ↓
Phase 3 (T005–T012)  🔴 vermelho preservado
   ↓
Phase 4 (T013–T019)  US1 — governança
   ↓
Phase 5 (T020–T023)  US3 — porta de entrada
   ↓
Phase 6 (T024–T027)  US3 — ciclo canônico
   ↓
Phase 7 (T028–T031)  US4 — revalidação ⚠️ pode interromper
   ↓
Phase 8 (T032–T034)  US4 — remoção 🔒 última ação mutante
   ↓
Phase 9 (T035–T039)  🟢 verde e convergência
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Por quê |
|---|---|---|
| T003 | T001, T002 | mesma ADR, mesmo arquivo |
| T011 | T005–T010 | o vermelho só é prova se o oráculo estiver completo |
| T013 | **T011** | implementar antes de registrar o vermelho falha `SC-005` de forma irrecuperável |
| T021 | T020 | a não duplicação (`FR-012`) só é verificável contra o texto já escrito |
| T029 | T013 | não há contra o quê revalidar antes de a governança existir |
| T032 | **T003, T004, T031** | transcrição feita **e** revalidação encerrada |
| T033 | T032 | remover a regra antes do alvo deixa janela em que o material fica versionável |
| T035 | T034 | o verde só é verde depois da última ação mutante |

### Oportunidades reais de paralelismo

**Duas oportunidades reais**, cobrindo três tarefas, ambas verificadas quanto a conflito de arquivo:

- **T026** — `scripts/verify/README.md` não é tocado por nenhuma tarefa da Phase 6.
- **T037 e T038** — leitura apenas; nenhuma escreve.

As demais tarefas **não** são paralelizáveis: T005–T010 editam o mesmo script,
T013–T018 o mesmo documento de governança, e T001–T004 a mesma ADR. Marcá-las `[P]`
seria decorativo — e criaria colisão real se alguém as executasse em paralelo.

---

## Implementation Strategy

### Incremento mínimo viável

Phases 1–4 (T001–T019). Entrega a **governança ratificada e decidível**, que é o
contrato que os itens 003–012 consomem e o que desliga o portão substituto. Porta
de entrada e quitação de dívida agregam valor, mas o trabalho prossegue sem elas.

### Entrega incremental

1. Phases 1–2 → constantes fixadas e material transcrito (a remoção fica segura)
2. Phase 3 → 🔴 vermelho preservado (a prova de test-first fica garantida)
3. Phase 4 → **governança ratificada** — portão real existe
4. Phases 5–6 → porta de entrada e ciclo canônico em circulação
5. Phases 7–8 → dívida do item 001 quitada e material fora de circulação
6. Phase 9 → 🟢 verde, determinismo e os dois cenários humanos

### Critério de conclusão do item

| Condição | Verificação |
|---|---|
| 33/33 asserções aprovadas, `exit=0` | T035 |
| Par vermelho→verde preservado e distinto | T011 + T035, asserido por `FR-022` |
| Oráculo do item 001 íntegro e aprovando | `FR-021a` + `FR-021b` |
| Cada oráculo abaixo de 5 s | T037 |
| Dez princípios decididos sem interpretação | T038, cenário 3 |
| Orientação carregada sem ação manual | T038, cenário 6 |
| 16/16 artefatos com veredito registrado | T029, asserido por `FR-017a` |
| Material transitório fora de circulação, sem regra órfã | T032, T033 |

---

## Notes

- `[P]` = arquivos diferentes, sem dependência. Usado em **3** das 39 tarefas,
  deliberadamente — este item edita poucos arquivos e muitas vezes.
- Cada tarefa cita o requisito que a origina, para que qualquer linha do oráculo
  seja rastreável até a spec sem ler o script.
- Commit após cada grupo lógico. O par vermelho→verde precisa ficar em commits
  **separados**: é a prova auditável de que o teste veio primeiro, e ela não é
  recuperável depois.
- T030 é a única tarefa que pode **encerrar o ciclo sem conclusão**. Isso não é
  falha do plano: é o comportamento especificado em `FR-017b`.
