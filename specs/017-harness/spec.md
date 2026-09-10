# Feature Specification: `core/harness.py` — controles feedforward + feedback

**Feature Branch**: `feature/f1-harness-engine`

**Created**: 2026-09-10

**Status**: Draft

**Input**: User description: "Fase 1, item 1.1 (017/024 na ordem de execução): core/harness.py — feedforward + feedback controls, exit codes: o corpo Python do harness do motor sobre os tipos da 011, stdlib puro, sem retry, componível por exit codes com os 16 oráculos shell" (SPECIFY aplicado deterministicamente sobre o research vinculante)

**Item do plano**: 1.1 (§17 Fase 1) · **Ordem de execução**: 017 de 024 (ADR-040, primeiro da Fase 1)
**Pesquisa vinculante**: `docs/plan/research/f1-017-harness.md` (Q1–Q8, decisões D1–D7, hierarquia P0–P3 da ADR-025, pergunta-padrão de ambiente da ADR-027 §5)
**Contrato de entrada**: `specs/011-packages-core/spec.md` › Contratos (Transferido: tipos-base para harness/constitution/bridge/context) + `specs/015-docker-compose/spec.md` › Contratos (Transferido: `DATABASE_URL`/`REDIS_URL` como elos VIII — sem código cliente nesta spec) + `docs/plan/decisions.md` (ADR-015a, ADR-017, ADR-019 §3, ADR-020 §2, ADR-025, ADR-027 §5, ADR-031 §3, ADR-040, ADR-041) + `docs/plan/implementation_plan.md` §§14, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem 16 oráculos shell que decidem conformidade por exit code, mas **zero corpo Python**: nenhum módulo existe para validar pré-condições antes de executar, nem para executar um comando externo capturando saída + exit code preservado e julgando contra o esperado com falha nomeada. Quem chamar ferramenta externa hoje (Fase 2 chamará dezenas) recebe traceback ou silêncio — nunca um veredito rastreável a requisito. Este item entrega **exclusivamente**: `packages/core/src/fkx_core/harness.py` (portão feedforward pré-execução + julgamento feedback pós-execução, stdlib puro, sobre os tipos da 011, zero retry), com `exit codes` que espelham o contrato do oráculo (`0/1/2`), e oráculo `f1-017-*` com asserções — incluindo o pagamento de fronteira de `f0-011` FR-002 pelo procedimento (molde ADR-017, 10ª execução: PLAN declara → ADR prévia autoriza → verde aplica → manifest cita). Não cria agentes, grafos, retrievers, watchers, LSP, subcomandos CLI, nem consome `DATABASE_URL`/`REDIS_URL` (elos herdados, sem código cliente nesta spec — princípio IV).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (regras em código, julgamento só roteia; sem retry); **II** especificação precede código; **III** vermelho→verde em commits separados; **IV** sem consumidor não há comportamento (gateways, filas e watchers fora); **V** Lei Zero (segredo nunca em evidência: `SecretStr` mascarado se vazar ao veredito); **VI** harness é o oráculo, e a única fronteira (`f0-011` FR-002) é paga pelo procedimento, nunca por edição silenciosa; **VIII** mecanismos verificados no research (subprocess executado + CPython docs); **IX** stdlib puro, agnóstico de stack-alvo; **X** toda falha nomeia o requisito violado + a evidência observada (exceção Python nunca é evidência).

**Restrição estrutural que molda o item** (research D3+D4): julgamento usa `check=False` + captura (caminho-1) — `check=True` só em pré-condição (falha = erro de uso); re-execução para buscar verde é proibida por governança (ADR-019 §3, `010` FR-010), não por preferência.

## Clarifications

*(sessões registradas aqui pelo `/speckit-clarify`; research traz 3 itens propostos com default: erro `HarnessError`, literais `0/1/2` puros, não-POSIX com erro nomeado.)*

### Session 2026-09-10

- Q: Nome do erro do módulo — `HarnessError(FkxError)` novo ou `FkxError` genérico? → A: `HarnessError(FkxError)` novo (recomendação acatada).
- Q: Granularidade dos exits de erro — literais `0/1/2` puros ou `EX_USAGE`/`EX_SOFTWARE`? → A: literais `0/1/2` puros (recomendação acatada).
- Q: Comportamento em plataforma não-POSIX — erro nomeado fail-closed ou sem asserção? → A: erro nomeado fail-closed (recomendação acatada).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Executar comando externo com veredito nomeado (Priority: P1)

Como desenvolvedor do motor, executo um comando externo através do harness e recebo um veredito rastreável a requisito (conformidade + evidência) em vez de traceback ou silêncio — incluindo quando o processo morre por sinal.

**Why this priority**: É a entrega do item (1.1): sem ela, a Fase 2 constrói agentes sobre chamadas que engolem morte de processo (o ponto cego A1, agora com norma Python pela ADR-041).

**Independent Test**: Executar comando que sai `0`, comando que sai `3` e comando morto por `SIGKILL` através do harness; os três vereditos nomeiam requisito distinto com evidência — testável sem nenhum outro item da Fase 1.

**Acceptance Scenarios**:

1. **Given** pré-condições válidas, **When** comando sai `0` com saída esperada, **Then** veredito é conforme (`0`) com a evidência capturada.
2. **Given** pré-condições válidas, **When** comando sai `3`, **Then** veredito é não-conforme (`1`) nomeando o requisito + returncode `3` + saída que falhou.
3. **Given** pré-condições válidas, **When** processo morre por sinal (`-9`), **Then** veredito é falha nomeada (nunca verde, nunca silêncio).

---

### User Story 2 - Recusa pré-execução sem efeitos (Priority: P2)

Como desenvolvedor do motor, chamo o harness com pré-condição inválida (binário ausente, variável obrigatória ausente) e recebo erro de uso **sem que nada execute**.

**Why this priority**: É o feedforward (research Q1/D1): a metade do item que impede estado incorreto antes de nascer.

**Independent Test**: Chamar com binário inexistente; nada executa e o retorno é erro de uso (`2`) nomeando a pré-condição.

**Acceptance Scenarios**:

1. **Given** binário ausente, **When** invoco o harness, **Then** recebo erro de uso (`2`) e nenhum processo é gerado.
2. **Given** timeout exigido, **When** comando excede, **Then** o processo é morto e o veredito é falha nomeada por expiração (fail-closed).

---

### User Story 3 - Composição com o harness shell (Priority: P3)

Como QA do motor, uso os exit codes do `harness.py` dentro e fora dos oráculos shell sem tradução: `0/1/2` significam o mesmo nos dois mundos.

**Why this priority**: Fecha a composição Fase 0 → Fase 1 (16 oráculos continuam decidindo; o corpo Python passa a produzir vereditos no mesmo alfabeto).

**Independent Test**: Invocar o harness via `python3 -c` e via oráculo `f1-017` sobre o mesmo comando com defeito; ambos saem `1` com o mesmo requisito nomeado.

**Acceptance Scenarios**:

1. **Given** comando com defeito conhecido, **When** executo via Python e via oráculo, **Then** ambos os exit codes são `1` e ambos nomeiam o requisito.

---

### Edge Cases

- Processo morto por sinal/OOM (`-9`, `137`): falha nomeada com o número do sinal — nunca verde, nunca traceback nu.
- Timeout expirado: kill + veredito de expiração com a saída parcial como evidência (fail-closed, research Q3).
- Comando que escreve só em stderr / saída vazia: vazio é evidência julgada (guarda contra vazio, como `f0-015/016`), nunca aprovação por ausência.
- Plataforma não-POSIX: falha fechada com `HarnessError` nomeado antes de qualquer execução (CLARIFY 2026-09-10) — sem asserção de comportamento além da recusa.
- Segredo em saída capturada: mascarado no veredito (Lei Zero precede o registro).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST prover `packages/core/src/fkx_core/harness.py` com portão feedforward: pré-condições validadas **antes** de qualquer execução; pré-condição inválida retorna erro de uso sem gerar processo.
- **FR-002**: O sistema MUST prover julgamento feedback: executa o comando capturando stdout/stderr **e** preservando o returncode (terminação anormal, inclusive por sinal, vira falha nomeada — nunca silêncio, nunca verde).
- **FR-003**: O sistema MUST emitir exit codes que espelham o contrato do oráculo: `0` conforme · `1` não conforme · `2` erro de uso (remap proibido, Regra 8).
- **FR-004**: O sistema MUST NOT re-executar para buscar verde: zero retry em qualquer caminho (ADR-019 §3, `010` FR-010).
- **FR-005**: Todo veredito MUST nomear o requisito violado (ou atendido) e a evidência observada (princípio X); traceback Python MUST NOT ser a evidência.
- **FR-006**: O erro do módulo MUST ser `HarnessError(FkxError)` novo, seguindo a taxonomia por módulo da 011 (CLARIFY 2026-09-10).
- **FR-007**: O sistema MUST emitir os literais `0/1/2` puros, sem granularidade `EX_USAGE`/`EX_SOFTWARE` (CLARIFY 2026-09-10; composição por construção, Regra 8).
- **FR-008**: O sistema MUST prover oráculo `scripts/verify/f1-017-*.sh` sob o contrato `oracle-cli.md` (identidade FR↔asserção documentada, determinismo 2×, somente leitura, self-check `f0-001…f0-016` em série conforme ADR-031 + `sha256sum -c` do manifest, 17ª linha do manifest).
- **FR-009**: `specs/README.md` MUST conter `017` `✅` com hash do commit de convergência, e `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados.
- **FR-010**: Fronteira paga pelo procedimento: `f0-011` FR-002 ajustada **exclusivamente** na Fase C verde via ADR prévia (10ª execução do molde ADR-017); nenhum outro oráculo anterior tocado.
- **FR-011**: O sistema MUST NOT adicionar dependência: stdlib puro (`subprocess/os/sys`); `uv.lock` sem pacote novo (Escada).
- **FR-012**: POSIX assumido e declarado; em plataforma não-POSIX o sistema MUST falhar fechado com erro nomeado (`HarnessError`) antes de qualquer execução (CLARIFY 2026-09-10).

### Key Entities *(include if feature involves data)*

- **Veredito**: requisito nomeado + evidência observada + exit (`0/1/2`); o que o feedback produz e o oráculo assere.
- **Pré-condição**: fato verificável antes de executar (binário existe, variável presente); o que o feedforward valida.
- **Execução capturada**: stdout/stderr + returncode preservado (inclusive negativo por sinal); o que o feedback julga.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Comando que sai `0` → veredito conforme com evidência, em 100% das execuções.
- **SC-002**: Pré-condição inválida → erro de uso (`2`) com zero processos gerados, em 100% dos casos.
- **SC-003**: Morte por sinal (`-9`) e saída `≠0` → falha nomeada com número/evidência, em 100% dos casos; zero verdes sobre morte em qualquer execução.
- **SC-004**: Harness 17/17 + manifest 17/17 + `tasks.md` zero `[ ]` + par vermelho→verde em commits separados.
- **SC-005**: Oráculo executa 2× com saída byte-idêntica, cada execução abaixo de 5 segundos (padrão dos oráculos).
- **SC-006**: 🧑 Cenário humano — operador executa o roteiro de demonstração (comando OK, comando com defeito, binário ausente) e obtém `0`, `1`, `2` nomeados; divergência declarada é saída aceitável, silenciosa não é.
- **SC-007**: Fronteira paga pelo procedimento: `f0-011` FR-002 ajustada exclusivamente na Fase C verde via ADR prévia, manifest citando a ADR; nenhum outro oráculo anterior tocado.

> SC-004/SC-007 restatem FR-009/FR-010 por desenho (vereditos legíveis das FRs meta; padrão desde a 003 — ANALYZE A2, manter).

## Assumptions

- Tipos-base 011 (`FkxError`, `Settings`, superfície via `__init__.py`) estáveis e importáveis (E1 do checkpoint).
- `DATABASE_URL`/`REDIS_URL` são elos verificados sem código cliente nesta spec (015, princípio IV).
- Runner `ubuntu-24.04` + Python 3.12/3.13 (CI) e máquina do mantenedor (Linux, Python 3.12.3) — POSIX nos dois (research Q5, com prova executada).
- Superfície da API fixada em `contracts/oracle-cli.md` › Superfície (ANALYZE F1: `harness.run(cmd, *, timeout=None) -> Veredito`); mensagens de evidência seguem o formato do veredito (`data-model.md`).
- **Termo canônico**: `harness` (o módulo e o item); `feedforward`/`feedback` como formas adjetivas dos controles; `veredito` para a saída julgada.

## Contratos

### Entregue por este item

- `packages/core/src/fkx_core/harness.py` (feedforward + feedback, stdlib, zero retry) + erro do módulo + export em `__init__.py`.
- Oráculo `f1-017-*` + 17ª linha do manifest + `specs/README.md` `017 ✅`.
- Primeira execução da norma prospectiva ADR-041 (caminho-1 em oráculo novo + `subprocess` com returncode preservado).

### Recebido de itens anteriores

- De **011**: tipos-base (`FkxError`, taxonomia por módulo, superfície via `__init__.py`).
- De **010**: proibição de retry (FR-010) + 10 checks sem-bypass + `strict:true` como restrição de desenho.
- De **008**: `pip-audit` julgará este item no `pre-push`; de **004**: `uv.lock` como fonte única (sem pacote novo).
- De **001 (Lei Zero)**: segredo mascarado em qualquer evidência.
- De **ADR-031**: self-check em série + caminho-1; de **ADR-041**: norma prospectiva (este item é o primeiro consumidor); de **ADR-040**: posição `017`.
- Do **checkpoint pré-Fase 1**: herança E1 + medição A1 (E2) como prova de que o ponto cego custa ruído — este item elimina a classe no lado Python.

### Transferido a itens posteriores

- À **019** (`spec_kit_bridge.py`): execução de comandos externos via este harness (não `subprocess` direto).
- À **Fase 2 (Agentes Core)**: vereditos nomeados como sinais do ciclo do agente; reavaliação do escopo de credenciais (doutrina ADR-035 §5) quando houver múltiplos atores.
- À **auditoria pós-020** (`017–020`, checkpoint não-item): densidade de achados deste item + amostras de transientes sob load como dado de cadência + reavaliação dos tetos <5s (E4 do checkpoint).
