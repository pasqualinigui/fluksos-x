---
description: "Task list for 001-git-branching-strategy"
---

# Tasks: Fundação de Versionamento e Convenções do Motor

**Input**: Design documents from `/specs/001-git-branching-strategy/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/oracle-cli.md`, `quickstart.md` — todos completos

**Tests**: **SIM, obrigatórios.** A spec exige prova de test-first (SC-004). Como
`pytest` só chega no item 007, o teste deste item é o **oráculo executável**, que
por sua vez é o deliverable da User Story 2. A execução reprovando (T015) é o
portão vermelho.

**Organization**: agrupado por user story, com um desvio de ordem documentado
abaixo.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos distintos, sem dependência)
- **[Story]**: `US1`..`US4` conforme `spec.md`
- Todo item cita o arquivo concreto e o requisito atendido

## Path Conventions

Raiz do monorepo (`fluksos-x/`). Este item não produz código de aplicação —
produz a fundação do repositório e a semente do harness em `scripts/verify/`.

---

## ⚠️ Desvio deliberado da ordem de prioridade

O template pede as user stories em ordem de prioridade (P1 primeiro). **Aqui a
US1 (P1) executa por último.** Não é descuido — é consequência de duas
irreversibilidades:

1. **US2 (o oráculo) precede US1** porque o oráculo é o teste de US1, US3 e US4.
   Implementar US1 antes de existir um oráculo reprovando destrói a única prova
   de test-first disponível antes do item 007 (SC-004).
2. **US1 executa por último** porque seu deliverable final é um commit
   irreversível que precisa **conter** os deliverables de US2, US3 e US4. Comitar
   antes deles obrigaria a um segundo commit corretivo, e o commit inicial
   deixaria de satisfazer FR-015.

Ordem de execução resultante: **US2 → US3 → US4 → US1**.

Consequência para o conceito de MVP: neste item o incremento mínimo entregável
**não** é uma user story isolada — é a Fase 2 + US2, que já entrega um
repositório protegido contra vazamento e um oráculo capaz de provar isso. As
demais são completude, não viabilidade.

---

## Mapa: Fases do `plan.md` ↔ Phases deste arquivo

| `plan.md` | Aqui | Conteúdo |
|---|---|---|
| Fase A | Phase 1 | ADR-001 e contrato de crescimento do harness |
| Fase B | Phase 2 | Regras de exclusão — bloqueante |
| Fase C | Phase 3 | Oráculo e portão vermelho |
| Fase D | Phases 4, 5 e 6 | Convenções, depois repositório e registro inicial |
| Fase E | Phase 7 | Portão verde, determinismo e cenários de validação |

---

## Phase 1: Setup (Infraestrutura compartilhada)

**Purpose**: rastreabilidade entre a numeração das specs e os itens do plano, e o
esqueleto do harness. Nenhum registro versionado ainda.

- [X] T001 [P] Criar `docs/plan/decisions.md` com ADR-001 registrando o mapa entre a numeração sequencial das specs (`001`–`012`) e os itens do plano (`0.9`, `0.11`, `0.1`, `0.4`, `0.2`, `0.3`, `0.12`, `0.5`, `0.6`, `0.7`, `0.8`, `0.10`), a ordem de dependência acordada e a justificativa de cada inversão face ao §17 do plano (FR-022)
- [X] T002 [P] Criar `scripts/verify/README.md` documentando o contrato de crescimento do harness: um arquivo `f0-NNN-<slug>.sh` por item, itens posteriores não modificam oráculos anteriores, e conflito de asserção sobe para decisão em vez de edição silenciosa (contrato §6)

---

## Phase 2: Foundational (Pré-requisito bloqueante)

**Purpose**: as regras de exclusão precisam estar vigentes **antes** de existir a
possibilidade de registrar qualquer coisa.

**⚠️ CRÍTICO**: nenhuma tarefa de qualquer user story pode registrar commit antes
desta fase concluir. O histórico é irreversível — comitar antes de ignorar viola
SC-001 de forma não corrigível.

Todas as tarefas abaixo alteram o **mesmo arquivo** (`.gitignore`) e portanto são
estritamente sequenciais. Nenhuma é `[P]`.

- [X] T003 Criar `.gitignore` na raiz partindo do template canônico do GitHub para Python (220 linhas), cobrindo ambientes virtuais, bytecode, caches de lint/tipos/testes e relatórios de cobertura (FR-010, FR-011)
- [X] T004 Em `.gitignore`, substituir o bloco de ambiente do template pelo trio corrigido `.env` + `.env.*` + `!.env.example` — o template canônico traz apenas `.env` e deixa `.env.local`, `.env.production` e `.env.staging` passarem, vazamento demonstrado em E1/E5 (FR-008, FR-009, D1)
- [X] T005 Em `.gitignore`, acrescentar o bloco de efêmeros do motor — `.fluksos-x/sessions/`, `.fluksos-x/reports/`, `.tmp/`, `*.lance/` — excluindo os subdiretórios e **nunca** o diretório-pai `.fluksos-x/`, sob pena de a negação de filhos tornar-se inoperante (FR-012, D2)
- [X] T006 Em `.gitignore`, acrescentar `.claude/settings.local.json` mantendo `.claude/skills/` versionável, para fixar no histórico o protocolo de especificação com que o motor é construído (FR-023, D9)
- [X] T007 Auditar `.gitignore` confirmando que nenhum padrão de lockfile foi introduzido e que as exclusões geridas por `.specify/.gitignore` (`feature.json`, `extensions/*/local-config.yml`) não foram duplicadas (FR-013, FR-014, D3)

**Checkpoint**: regras vigentes. A partir daqui é seguro criar repositório.

---

## Phase 3: User Story 2 — Oráculo executável de conformidade (Priority: P2) 🎯 Portão vermelho

**Goal**: um mecanismo que responda por código de saída, e não por julgamento
humano, se a fundação está conforme — usando apenas o que a máquina já possui.

**Independent Test**: executar em estado violador e observar reprovação nominal
por requisito; executar em estado conforme e observar aprovação; executar duas
vezes seguidas e obter saída idêntica.

Todas as tarefas T008–T014 escrevem o **mesmo arquivo** e são sequenciais.

- [X] T008 [US2] Criar `scripts/verify/f0-001-foundation.sh` com o esqueleto do contrato: parsing de `--quiet` e `--list`, resolução da raiz do projeto a partir da localização do próprio script (nunca do diretório corrente), códigos de saída `0`/`1`/`2`, formato de linha `<status> <FR-ID> <descrição>` e linha de resultado final (FR-016, FR-017, FR-019, contrato §1–§3)
- [X] T009 [US2] Implementar em `scripts/verify/f0-001-foundation.sh` as asserções do Grupo A — existência do repositório com linha principal `main`, existência de `develop`, identidade de autoria em escopo local, e ausência de escrita em escopo global; na falta de repositório, `FR-001` reprova com mensagem informativa em vez de erro abrupto (FR-001, FR-002, FR-003, FR-021)
- [X] T010 [US2] Implementar em `scripts/verify/f0-001-foundation.sh` as asserções do Grupo B — o documento de convenções declara os 11 tipos, o formato com escopo opcional e marcação de incompatibilidade, o formato de nome de linha de funcionalidade, e os papéis de `main` e `develop` (FR-004, FR-005, FR-006, FR-007)
- [X] T011 [US2] Implementar em `scripts/verify/f0-001-foundation.sh` as asserções do Grupo C, usando arquivos-isca temporários: exclusão do arquivo de ambiente base e de **pelo menos três variantes** (`.local`, `.production`, `.staging`), e as asserções **positivas** de que `.env.example`, `uv.lock` e `.claude/skills/` permanecem versionáveis, mais a exclusão de `.claude/settings.local.json` (FR-008a, FR-008b, FR-009, FR-012, FR-013, FR-023a, FR-023b)
- [X] T012 [US2] Implementar em `scripts/verify/f0-001-foundation.sh` as asserções do Grupo D — `FR-020a` via listagem dos rastreados que casam com as exclusões (`git ls-files -i -c --exclude-standard`) e `FR-020b` via varredura do histórico completo, como asserções **separadas** com severidades distintas; `git check-ignore` é **proibido** nestas asserções por produzir falso-negativo demonstrado em E7 (FR-015, FR-020a, FR-020b, SC-002, D4, D5)
- [X] T013 [US2] Implementar em `scripts/verify/f0-001-foundation.sh` as asserções do Grupo E — determinismo entre execuções, ausência de invocação de ferramenta fora de shell/git/Python stdlib, e presença do mapa de decisões arquiteturais; a validação da gramática de commit usa a expressão regular dos 11 tipos validada em E10 (FR-018, FR-019, FR-022, SC-006, D7)
- [X] T014 [US2] Implementar em `scripts/verify/f0-001-foundation.sh` a limpeza dos arquivos-isca via `trap`, garantindo remoção mesmo em interrupção, e confirmar que o script não escreve nada fora de saída padrão e erro padrão (contrato §5, restrições 2 e 6)
- [X] T015 [US2] 🔴 **PORTÃO VERMELHO** — executar `scripts/verify/f0-001-foundation.sh`, confirmar código de saída `1`, confirmar que `FR-001`, `FR-002`, `FR-004`–`FR-007` e `FR-015` reprovam, e preservar a saída integral como artefato de evidência do vermelho. Nenhuma tarefa da Phase 4 em diante pode iniciar antes desta concluir (SC-004, quickstart cenário 1)

**Checkpoint**: existe um oráculo, e existe prova registrada de que ele reprova
antes da implementação.

---

## Phase 4: User Story 3 — Histórico classificável para release automático (Priority: P3)

**Goal**: cada registro declara sua natureza de forma que uma máquina o
classifique sem interpretação, viabilizando o registro de mudanças automático do
addendum R2.

**Independent Test**: tomar qualquer registro do histórico e determinar
mecanicamente sua categoria e se representa mudança incompatível, sem leitura
interpretativa.

- [X] T016 [US3] Criar `CONTRIBUTING.md` na raiz declarando o conjunto fechado dos 11 tipos (`feat`, `fix`, `docs`, `test`, `refactor`, `ci`, `chore`, `perf`, `build`, `style`, `revert`), a gramática do cabeçalho `<tipo>[(<escopo>)][!]: <descrição>`, a marcação de mudança incompatível e o rodapé correspondente, registrando que `perf` e `build` excedem os 7 tipos do §18 do plano por serem exigidos pela classificação automática de releases (FR-004, FR-005, D7, D8)

---

## Phase 5: User Story 4 — Rastreabilidade de fase e pacote pelo nome (Priority: P4)

**Goal**: pessoa ou agente identifica fase, pacote e propósito de uma linha de
trabalho apenas pelo nome, sem consultar outra fonte.

**Independent Test**: apresentar um nome de linha de trabalho a quem nunca viu o
projeto e verificar se identifica fase, pacote e propósito.

- [X] T017 [US4] Acrescentar a `CONTRIBUTING.md` a seção de linhas de trabalho: formato `feature/f<fase>-<pacote>-<funcionalidade>` com exemplos do §18 do plano, o papel de `main` como estado estável e de `develop` como linha de integração, e a regra de que linhas de funcionalidade derivam de `develop`; validar contra os exemplos do plano que fase, pacote e propósito são dedutíveis do nome sem consulta externa (FR-006, FR-007, SC-005)

**Checkpoint**: convenções normativas documentadas. O commit inicial já pode
obedecê-las e contê-las.

---

## Phase 6: User Story 1 — Fundação versionada e livre de vazamentos (Priority: P1)

**Goal**: repositório onde o trabalho passa a ser registrado e onde é
estruturalmente impossível que segredo ou artefato descartável entre por
descuido.

**Independent Test**: criar arquivos-isca de cada categoria proibida e confirmar
que nenhum é oferecido para registro; criar a trava de dependências e confirmar
que ela é.

> Executa por último pelo motivo documentado no topo: o commit inicial precisa
> conter os deliverables das Phases 1–5.

- [X] T018 [US1] Em `scripts/` ou por execução direta, detectar se a raiz já contém repositório: ausente → criar com linha principal `main`; presente → verificar o nome da linha principal e renomear para `main` se necessário. **Não** reinicializar às cegas — E8 demonstrou que o parâmetro de nomeação é descartado em silêncio no re-init (FR-001, D6)
- [X] T019 [US1] Definir no escopo **local** do repositório a identidade `Guilherme <pasqualini166@gmail.com>` e a preferência de linha principal, e confirmar que o escopo global da máquina permanece sem qualquer entrada escrita por este item (FR-003)
- [X] T020 [US1] Antes de registrar, inspecionar exatamente o que será incluído, confirmando que `docs/`, `specs/`, `scripts/`, `.specify/`, `.claude/skills/`, `.gitignore` e `CONTRIBUTING.md` entram e que nenhum arquivo de categoria proibida aparece (SC-001, FR-023)
- [X] T021 [US1] Criar o commit inicial contendo o plano, a pesquisa, as specs, o oráculo e as convenções, com mensagem obedecendo à gramática definida em `CONTRIBUTING.md` (FR-015, FR-004, FR-005)
- [X] T022 [US1] Criar a linha `develop` a partir de `main`, ambas apontando para o registro inicial (FR-002)

**Checkpoint**: fundação completa. O oráculo deve agora aprovar.

---

## Phase 7: Polish & Validação cruzada

**Purpose**: converter a implementação em evidência, e verificar os cenários que
a pesquisa empírica mostrou serem os pontos de falha reais.

- [X] T023 🟢 **PORTÃO VERDE** — executar `scripts/verify/f0-001-foundation.sh`, confirmar código de saída `0` e todas as asserções aprovadas, e preservar a saída integral como artefato de evidência do verde, formando com T015 o par vermelho→verde exigido (SC-004, quickstart cenário 2)
- [X] T024 Verificar determinismo de `scripts/verify/f0-001-foundation.sh` — duas execuções consecutivas sem alteração de estado produzem saída idêntica, e a execução conclui em menos de 5 segundos (SC-003, FR-018, quickstart cenário 3)
- [X] T025 [P] Executar os cenários 4, 5, 6 e 7 do `quickstart.md` contra o repositório real — variantes de arquivo de ambiente invisíveis com o modelo visível, trava de dependências versionável, exclusão parcial de `.fluksos-x/` com o diretório-pai preservado, e habilidades do motor de especificação versionáveis com a configuração local excluída; remover os arquivos-isca ao final (SC-001, FR-008, FR-009, FR-012, FR-013, FR-023a, FR-023b)
- [X] T026 [P] Executar o cenário 8 do `quickstart.md` em repositório descartável fora do projeto — registrar um arquivo de ambiente antes de existir regra, acrescentar as regras, e confirmar que `FR-020a` reprova com severidade crítica; um oráculo que aprove este cenário está errado ainda que aprove o repositório real (FR-020, D4)
- [X] T027 Executar o cenário 9 do `quickstart.md` — confirmar as duas linhas de trabalho, o registro inicial conforme a gramática, a identidade em escopo local, e o escopo global da máquina sem qualquer entrada escrita por este item (FR-001, FR-002, FR-003)
- [X] T028 Conferir a seção Contratos de `spec.md` item a item, confirmando que cada entrega declarada aos itens `003`, `005`, `006`, `007` e `012` está de fato disponível, e que as responsabilidades transferidas aos itens `002` (revalidação retroativa contra a constitution ratificada **e** consumo/retirada do material de referência transitório, ADR-004), `008`, `009` e ao pós-Fase 0 estão registradas por escrito (FR-022, SC-007)

---

## Dependencies

### Ordem de fases (estrita)

```
Phase 1 (Setup)
   ↓
Phase 2 (Foundational — .gitignore)      ⚠️ BLOQUEANTE para todo registro
   ↓
Phase 3 (US2 — Oráculo)                  ⚠️ T015 é portão vermelho
   ↓
Phase 4 (US3 — convenção de registro)
   ↓
Phase 5 (US4 — convenção de linha)
   ↓
Phase 6 (US1 — repositório e commit)
   ↓
Phase 7 (Polish — portão verde e validação)
```

### Dependências críticas por tarefa

| Tarefa | Depende de | Motivo |
|---|---|---|
| T004–T007 | T003 | mesmo arquivo, alterações sequenciais |
| T009–T014 | T008 | mesmo arquivo; o esqueleto define o contrato de saída |
| **T015** | T008–T014 | o oráculo precisa estar completo para que a reprovação seja significativa |
| T016 | — | independente, mas precede T021 por precisar estar no commit |
| T017 | T016 | mesmo arquivo, seção subsequente |
| **T018–T022** | **T015** | portão vermelho: implementar antes destrói a prova de test-first |
| T020 | T003–T007, T016, T017 | só se pode inspecionar o que será registrado depois de as regras e as convenções existirem |
| T021 | T020 | inspecionar antes de registrar, nunca depois |
| T022 | T021 | a linha de integração deriva do registro inicial |
| T023 | T018–T022 | o verde só é significativo com a implementação completa |
| T024–T028 | T023 | validação após conformidade estabelecida |

### Oportunidades reais de paralelismo

Escassas por natureza — este item é sequencial porque o histórico é irreversível
e a prova vermelho→verde é ordenada.

| Grupo | Tarefas | Justificativa |
|---|---|---|
| Setup | T001, T002 | arquivos distintos, nenhuma dependência |
| Validação final | T025, T026 | T025 atua no repositório real, T026 em repositório descartável fora do projeto |

**Explicitamente não paralelizáveis**: T003–T007 (mesmo arquivo), T008–T014
(mesmo arquivo), T018–T022 (estado sequencial do repositório). Paralelizar
qualquer um destes produziria resultado não determinístico ou destruiria a
ordem que a spec torna normativa.

---

## Implementation Strategy

### Incremento mínimo viável

**Phase 1 + Phase 2 + Phase 3** (T001–T015). Ao final: regras de exclusão
vigentes e um oráculo capaz de provar conformidade, com evidência registrada de
que ele reprova o estado incompleto. É o menor recorte que entrega valor real —
proteção contra vazamento mais capacidade de auditar essa proteção.

### Entrega incremental

1. **T001–T007** → repositório ainda inexistente, porém já protegido por regra.
2. **T008–T015** → harness existe e reprova. Prova de test-first registrada.
3. **T016–T017** → convenções normativas documentadas.
4. **T018–T022** → fundação materializada, histórico iniciado.
5. **T023–T028** → conformidade demonstrada e cenários de falha real verificados.

### Critério de conclusão do item

Os seis critérios do `quickstart.md` atendidos, com destaque para o par T015
(vermelho) e T023 (verde): sem os dois artefatos de evidência, SC-004 falha
mesmo que os 23 requisitos funcionais estejam satisfeitos.

Concluído isto, o item segue para `/speckit-analyze` e depois
`/speckit-converge`.
