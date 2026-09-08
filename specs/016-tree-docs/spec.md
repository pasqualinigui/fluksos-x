# Feature Specification: `docs/tree.md` — mapa da árvore para IA

**Feature Branch**: `feature/f0-tree-docs`

**Created**: 2026-09-09

**Status**: Draft

**Input**: User description: "Fase 0, item 0.10 (016/016 na ordem de execução): docs/tree.md — mapa da árvore para IA, formato + atualização automática, refletindo a árvore real resultante e fechando a Fase 0" (SPECIFY aplicado deterministicamente sobre o research vinculante)

**Item do plano**: 0.10 (§17 Fase 0) · **Ordem de execução**: 016 de 016 (ADR-011, último da Fase 0)
**Pesquisa vinculante**: `docs/plan/research/f0-016-tree.md` (Q1–Q5, decisões D1–D5, hierarquia P0–P3 da ADR-025, pergunta-padrão de ambiente da ADR-027 §5)
**Contrato de entrada**: `specs/013-release-automation/spec.md` › Contratos (Transferido: estrutura final incluindo o fluxo de release) + `specs/014-dependency-updates/spec.md` › Contratos (Transferido: estrutura final incluindo a config do bot) + `specs/015-docker-compose/spec.md` › Contratos (Transferido: árvore final incluindo `docker-compose.yml`, `docker/`, `.env.example`) + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-014, ADR-015, ADR-016, ADR-017, ADR-025, ADR-027 §5) + `docs/plan/implementation_plan.md` §§15, 16 (Bônus #8), 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem 312 arquivos rastreados e nenhuma planta: um agente em zero-contexto lê `AGENTS.md` (84 linhas, porta de entrada) mas não tem o mapa do prédio — **qual diretório guarda o quê, e onde ler cada assunto**. Este item entrega **exclusivamente**: `docs/tree.md` (H1 + resumo + árvore anotada + tabela de ponteiros "onde ler o quê"), gerador determinístico `scripts/generate-tree.py` (stdlib, fonte `git ls-files`) que emite o esqueleto, curadoria com teto fixo, e oráculo `f0-016` com asserções — incluindo a obrigação herdada da auditoria `f0-audit-013-016` (molde 009/ADR-016: sem relatório, sem converge). Não cria mapa dinâmico por relevância (item 1.5 da Fase 1), `llms.txt` web, tokenizador, `ctags`/`tree-sitter`, nem processo residente que reescreva o mapa sozinho.

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (gerador byte-idêntico 2×, teto em linhas+bytes, sem tokenizador); **II** especificação precede código; **III** vermelho→verde em commits separados; **IV** granularidade arquivo/diretório (símbolos são Fase 1); **V** Lei Zero (fonte é o índice: `.env`/`secrets/` nunca aparecem); **VI** harness é o oráculo, e nenhuma fronteira anterior é tocada (a 016 só acrescenta); **VIII** formato e mecanismos verificados em `docs/plan/research/f0-016-tree.md`; **IX** mapa deste motor; **X** falha nomeia `FR-XXX` e a evidência observada.

**Restrição estrutural que molda o item** (research Q2+Q4): "atualização automática" lê-se verificação automática + atualização assistida (nada commita sozinho — *Ambiente sob demanda*), e a auditoria `f0-audit-013-016` é checkpoint não-item que aterrissa **antes** da convergência, com a FR que a exige morando neste item.

## Clarifications

*(sessões registradas aqui pelo `/speckit-clarify`; research traz 3 itens propostos com default: teto ≤120 linhas, `docs/`, `scripts/`.)*

### Session 2026-09-09

- Q: Qual o teto de linhas da parte curada (anotações + ponteiros)? → A: **B — 120 linhas** (comporta ~15 diretórios anotados + ponteiros com folga; estouro futuro por ADR, nunca em silêncio). FR-004/SC-004 já fixavam o número; sessão o ratifica.
- Q: Granularidade da anotação — por diretório ou por artefato? → A: **A — 1 linha por diretório (1º/2º nível) + tabela de ponteiros para artefatos-chave** (a árvore gerada já lista todos os arquivos; curadoria orienta, não duplica o índice).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Agente zero-contexto navega pelo mapa (Priority: P1)

Um agente novo abre `docs/tree.md` e, sem varrer o disco, sabe onde mora cada assunto (governança, plano, specs, harness, pacotes, infra) e qual arquivo ler primeiro para cada pergunta.

**Why this priority**: é o caso de uso que cria o item (§17 0.10 + §16-Bônus#8, MVP). Sem isto, o item não existe.

**Independent Test**: dar a um leitor só o `tree.md` + 5 perguntas ("onde está a governança?", "onde roda o portão?", "onde pinar imagem?") e conferir acerto sem outra fonte.

**Acceptance Scenarios**:

1. **Given** só `docs/tree.md`, **When** perguntado onde vive cada camada do projeto, **Then** cada resposta aponta o path correto existente no índice.
2. **Given** a tabela de ponteiros, **When** seguido um ponteiro, **Then** o destino existe e é o artefato normativo do assunto (não um espelho desatualizado).

---

### User Story 2 — O mapa nunca mente (Priority: P1)

Toda mudança na árvore (arquivo novo, rename, remoção) é detectada mecanicamente: o oráculo reprova enquanto o mapa não acompanhar o índice.

**Why this priority**: mapa desatualizado é pior que mapa ausente (precedente ADR-006: oráculo que parece verificar e não verifica). É a "atualização automática" do §17 lida corretamente: verificação automática, correção assistida.

**Independent Test**: adicionar/remover/renomear arquivo rastreado e conferir que `f0-016` reprova nomeando o path divergente; regenerar + curar e conferir verde.

**Acceptance Scenarios**:

1. **Given** um path rastreado ausente do mapa, **When** o oráculo executa, **Then** reprova nomeando o path.
2. **Given** um path do mapa fora do índice, **When** o oráculo executa, **Then** reprova nomeando o path.
3. **Given** o gerador executado 2×, **When** comparadas as saídas, **Then** são byte-idênticas.

---

### User Story 3 — Auditoria devida trava o converge (Priority: P2)

A convergência da 016 (que leva `convergidas − cobertas` a 4/4) exige o relatório `f0-audit-013-016.md` com o formato inaugural — sem ele, o oráculo reprova e a Fase 0 não fecha.

**Why this priority**: é a trava de cadência (ADR-014/016/027); sem ela, a última spec da fase escapa da auditoria que motivou a convenção.

**Independent Test**: com o relatório ausente, `f0-016` reprova na FR da auditoria; com o relatório no formato, aprova.

**Acceptance Scenarios**:

1. **Given** `docs/plan/audit/f0-audit-013-016.md` ausente, **When** o oráculo executa, **Then** reprova na FR-008.
2. **Given** o relatório presente sem os cabeçalhos `Veredito`/`Achados`/`Destino`, **When** o oráculo executa, **Then** reprova na FR-008.

---

### Edge Cases

- **Arquivo novo ainda untracked**: fora do índice ⇒ fora do mapa por construção (fonte é `git ls-files`, não disco); vira `??` no `git status`, nunca mentira no mapa.
- **Rename sem `git add`**: índice antigo decide até o stage — comportamento correto (mapa espelha o versionado, não o disco).
- **Repo cresce além do teto da curadoria**: oráculo reprova no teto; novo formato decide-se em item próprio com ADR, nunca estourando silenciosamente.
- **Auditoria encontra achado que exige mudar oráculo anterior**: sobe para ADR pelo procedimento (nunca fix direto); a 016 não fecha até a decisão existir.
- **`.env`/`secrets/` ou outro ignorado**: jamais aparecem no mapa (fonte é o índice); aparição é violação da Lei Zero, não "detalhe".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST prover `docs/tree.md` com H1 + bloco de resumo + árvore anotada + tabela de ponteiros "onde ler o quê" (filosofia llms.txt, alvo repo).
- **FR-002**: O esqueleto do mapa MUST ser emitido por `scripts/generate-tree.py` (stdlib, `LC_ALL=C`, ordenado) a partir de `git ls-files`; todo path rastreado MUST aparecer no mapa e nenhum não-rastreado MUST aparecer.
- **FR-003**: O gerador MUST ser byte-idêntico em 2 execuções e MUST NOT depender de binário além de `git` + Python stdlib (sem `tree`, sem tokenizador, sem ctags).
- **FR-004**: A parte curada do mapa (1 linha por diretório + tabela de ponteiros para artefatos-chave, decisão 2026-09-09) MUST respeitar o teto de ≤120 linhas, e o mapa total MUST respeitar o teto de ≤25600 bytes — ambos asseridos por contagem (número, não julgamento).
- **FR-005**: O mapa MUST NOT conter segredo, path ignorado ou path fora do índice (Lei Zero por construção da fonte).
- **FR-006**: O mapa MUST cobrir os destinos herdados: fluxo de release (013), config do bot (014), `docker-compose.yml` + `docker/` + `.env.example` (015).
- **FR-007**: O sistema MUST prover oráculo `scripts/verify/f0-016-*.sh` sob o contrato `oracle-cli.md` (identidade FR↔asserção documentada, determinismo, somente leitura, self-check `f0-001…f0-015` **em série** conforme ADR-031, 16ª linha do manifest).
- **FR-008**: O sistema MUST exigir `docs/plan/audit/f0-audit-013-016.md` com cabeçalhos grepeáveis `Veredito`, `Achados`, `Destino` (obrigação herdada, molde 009/ADR-016; auditoria-checkpoint não-item fora do mapa).
- **FR-009**: `specs/README.md` MUST conter `016` `✅` com hash do commit de convergência, e `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados.

### Key Entities *(include if feature involves data)*

- **Mapa**: `docs/tree.md`; duas camadas — esqueleto gerado (completo, do índice) + curadoria (anotada, com teto).
- **Gerador**: `scripts/generate-tree.py`; stdlib, determinístico, sem escrita além de stdout.
- **Ponteiro**: linha da tabela "onde ler o quê"; destino MUST existir no índice e ser o normativo do assunto.
- **Relatório de auditoria**: `docs/plan/audit/f0-audit-013-016.md`; formato inaugural, exigido pela FR-008.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Leitor só com `tree.md` acerta 5/5 perguntas de navegação sem outra fonte.
- **SC-002**: Qualquer divergência índice↔mapa (1 arquivo) reprova o oráculo nomeando o path.
- **SC-003**: Gerador 2× byte-idêntico; oráculo 2× byte-idêntico, cada execução abaixo de 5 segundos no modo estático (padrão dos oráculos).
- **SC-004**: Curadoria conta ≤120 linhas; total do mapa cabe no bootstrap junto do `AGENTS.md`.
- **SC-005**: Harness 16/16 + manifest 16/16 + `tasks.md` zero `[ ]` + par vermelho→verde em commits separados.
- **SC-006**: Sem `f0-audit-013-016.md` no formato, a 016 não converge (trava de cadência observável).
- **SC-007**: 🧑 Cenário humano — agente real em janela nova usa só `AGENTS.md` + `tree.md` para localizar 3 artefatos de itens distintos; divergência declarada é saída aceitável, silenciosa não é.

## Assumptions

- `docs/` (plano §15) e `scripts/` (convenção do harness) como casas do mapa e do gerador; CLARIFY confirma ou muda antes do PLAN.
- Teto ≤120 linhas proposto no research; CLARIFY confirma o número antes do oráculo o asserir.
- Auditoria produzida como checkpoint não-item antes do converge (precedente 009); seu conteúdo pode gerar ADR de fronteira como qualquer auditoria.
- Nomes de seções da tabela de ponteiros são desenho do PLAN, não desta especificação.
- Operação e evidência server-side neste ciclo vão pelo toolset GitHub MCP (API estruturada) e docs pelo Context7 quando a pesquisa exigir — nunca scraping.
- **Termo canônico**: `tree.md` (o arquivo e o item); `mapa` como forma adjetiva intercambiável.

## Contratos

### Entregue por este item

- `docs/tree.md` (H1 + resumo + árvore anotada + ponteiros) + gerador `scripts/generate-tree.py` + oráculo `f0-016` + 16ª linha do manifest + `specs/README.md` `016 ✅`.
- Fechamento da Fase 0: após a 016, o mapa ADR-011 está 16/16 e a auditoria `f0-audit-013-016` existe.

### Recebido de itens anteriores

- De **013/014/015**: destinos a cobrir (release, bot, compose/docker/`.env`) + pins e convenções a referenciar sem duplicar.
- De **010**: 10 checks sem-bypass + `commitlint` + `strict:true` como restrição de desenho.
- De **009**: molde da FR de auditoria (relatório + cabeçalhos grepeáveis).
- De **005**: `--list` como enumeração dos casos; de **004**: `uv.lock` como fonte única (gerador sem dependência nova).
- De **001 (Lei Zero)**: fonte no índice (ignorados nunca aparecem).

### Transferido a itens posteriores

- À **auditoria pós-016** (`f0-audit-013-016`, checkpoint não-item): último relatório da Fase 0; densidade da fase como dado de recalibragem da cadência (gatilho Fase 1 da ADR-027).
- À **Fase 1 (Harness & Indexação)**: `tree.md` como baseline estático do `repo_map.py` dinâmico (1.5); formato a evoluir por item próprio com ADR quando o teto estourar.
