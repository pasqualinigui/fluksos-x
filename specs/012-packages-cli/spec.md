# Feature Specification: `packages/cli` — entry point `fkx`

**Feature Branch**: `012-packages-cli`

**Created**: 2026-09-05

**Status**: Draft

**Input**: User description: "Fase 0, item 0.7 (012/016 na ordem de execução): packages/cli — entry point fkx (--help, --version): pacote fkx_cli membro do workspace UV, comando fkx instalável, --help com saída legível, --version imprimindo a versão do pacote, erros com código de saída nomeado, consumindo fkx_core sem duplicá-lo, tudo sob ruff + mypy strict + pytest, sem subcomandos de domínio (Fase 1+)."

**Item do plano**: 0.7 (§17 Fase 0) · **Ordem de execução**: 012 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-012-packages-cli.md` (decisões D1–D7, Q1–Q10, hierarquia de fontes P0–P2, ADR-025)
**Contrato de entrada**: `specs/011-packages-core/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011, ADR-015, ADR-017, ADR-018, ADR-023, ADR-024, ADR-025) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem kernel importável (`fkx_core`, 011) mas **zero superfície executável**: não existe comando instalável, ajuda legível nem versão consultável — tudo que o operador (e, na Fase 1+, os agentes e o CI) invocará. O §17 item 0.7 delimita o escopo a **entry point, --help, --version** (os demais comandos do §15 — `init`, `dev`, `interview`, `spec`, `run`, `audit`, `status`, `config`, `doctor`, `benchmark`, `guardian` — são Fase 1+, quando houver o que comandar; antecipá-los seria especificar comportamento sem consumidor, violação IV).

Este item entrega **exclusivamente** `packages/cli/` (`pyproject.toml` membro + `src/fkx_cli/` com `__init__.py`, `main.py` expondo o objeto `app`, `py.typed` PEP 561 + entry point `fkx` em `[project.scripts]`), `typer==0.27.2` + `rich==15.0.0` como runtime do pacote, dependência de membro `fkx-core`, testes em `tests/test_fkx_cli_*.py`, oráculo `f0-012-cli.sh` com 12–16 asserções. Não cria subcomando de domínio (012 entrega só o entry point), TUI `textual` (Fase 4), `docker-compose` (015), `.env` real (Lei Zero), release/publish (013), `docs/tree.md` (016).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (códigos de saída fixos 0/0/2, versão única do pacote, sem comportamento dependente de modelo); **II** especificação precede código; **III** vermelho→verde em commits separados; **IV** superfície mínima antes do código (entry point + 2 flags, sem subcomando sem consumidor); **V** Lei Zero (sem segredo literal, dado dinâmico escapado em markup, `pretty_exceptions_show_locals` desligado); **VI** harness oráculo + fronteira das 004–008/011 admitindo `packages/cli/` somente via ADR prévia (molde ADR-018/023); **VIII** pins verificados PyPI + GitHub releases + execução 2026-09-05; **IX** `cli` não assume stack-alvo (fala do motor, não do projeto gerado); **X** falha nomeia `FR-XXX` + código de saída documentado.

---

## Clarifications

### Session 2026-09-05

- Q: `fkx` sem argumentos mostra ajuda (exit 0), erro nomeado (exit 2) ou ação padrão? → A: **ajuda, exit 0** (decisão do mantenedor, recomendação acatada).
- Q: `app` nasce como grupo multi-comando vazio ou callback-raiz mínimo? → A: **callback-raiz mínimo** (decisão do mantenedor, recomendação acatada — YAGNI/Escada; subcomandos via `add_typer` na Fase 1).
- Q: formato exato da saída de `fkx --version`? → A: **só o número** (ex.: `0.1.0`) — decisão do mantenedor, recomendação acatada (máquina-legível, asserção exata).
- Q: exit code de erro de domínio vindo de `fkx_core`? → A: **exit 1** (decisão do mantenedor, recomendação acatada — 2 reservado a erro de uso; base do futuro 4.11).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Ajuda legível do comando (Priority: P1)

Operador instala o pacote e executa `fkx --help`: recebe a lista de opções (`--help`, `--version`) em saída formatada legível, com código de saída 0; sem argumentos inválidos, sem traceback.

**Why this priority**: sem entry point instalável e ajuda legível, o motor não é invocável — é a base de toda interação futura (operador, CI, agentes).

**Independent Test**: instalar o pacote em ambiente limpo, executar `fkx --help`, asserir exit 0 + presença dos marcadores `--help`/`--version` na saída; executar `fkx --nope`, asserir exit 2 + mensagem em stderr com dica de `--help`.

**Acceptance Scenarios**:

1. **Given** pacote instalado, **When** executar `fkx --help`, **Then** exit 0 e saída contém `--help` e `--version`.
2. **Given** pacote instalado, **When** executar `fkx` sem argumentos, **Then** exit 0 e saída equivale a `fkx --help` (decisão CLARIFY 2026-09-05).
3. **Given** pacote instalado, **When** executar `fkx --nope`, **Then** exit 2 e stderr nomeia a opção inválida com dica de `--help`.

---

### User Story 2 — Versão consultável (Priority: P2)

Operador executa `fkx --version`: recebe a versão do pacote instalado, com código de saída 0; o valor impresso confere com a versão declarada do pacote em 100% das invocações.

**Why this priority**: é o contrato mínimo de identificabilidade — sem ele, nenhum relato de defeito, CI ou agente sabe o que está executando.

**Independent Test**: executar `fkx --version`, asserir exit 0 + valor igual à versão declarada do pacote instalado.

**Acceptance Scenarios**:

1. **Given** pacote instalado, **When** executar `fkx --version`, **Then** exit 0 e a saída impressa é somente o número da versão declarada do pacote (decisão CLARIFY 2026-09-05).

---

### User Story 3 — Erro nomeado, nunca traceback cru (Priority: P3)

Operador provoca qualquer condição de erro coberta (opção inválida, falha de domínio vinda de `fkx_core`): recebe mensagem que nomeia a causa e código de saída documentado; nenhum erro vaza como traceback não tratado nem `except:` silencioso no pacote.

**Why this priority**: observabilidade da CLI (X) começa no contrato de falha — cada release futuro que quebrar quem integra repete o problema que o contrato do oráculo resolveu na Fase 0.

**Independent Test**: provocar cada condição de erro, asserir código de saída + mensagem com causa nomeada (nunca segredo); `grep -rn "except:" src/fkx_cli/` retorna zero ocorrências (oráculo asserir).

**Acceptance Scenarios**:

1. **Given** condição de erro de uso ou de domínio, **When** comando executa, **Then** saída nomeia a causa e o exit code é o documentado (uso inválido → 2; domínio → 1).
2. **Given** `grep -rn "except:" src/fkx_cli/`, **When** inspecionado, **Then** zero `except:` nus (oráculo asserir).

---

### Edge Cases

- Largura de terminal variável: o contrato cobre **marcadores presentes + códigos**, nunca contagem exata de bytes da ajuda (largura varia por terminal; medir bytes seria contrato frágil).
- Saída sob pipe: medição de exit code usa redirect + `$?`, nunca `$?` após pipe (o pipe mascara o código com o do último comando — armadilha Q4).
- `fkx` sem argumentos: equivale a `fkx --help` (exit 0) — decisão CLARIFY 2026-09-05; sem traceback em nenhum caso.
- `packages/cli` importando `core` antes do sync: fora de escopo do operador — setup canônico é `uv sync --all-packages` (ADR-023); 012 só garante importabilidade após sync.
- Terminal sem cor / `NO_COLOR`: saída permanece legível sem sequências de escape obrigatórias (Rich degrada; contrato não exige cor).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST declarar `typer==0.27.2` + `rich==15.0.0` como **dependências de runtime** de `packages/cli` (`uv.lock` do workspace segue fonte única); `click` MUST NOT ser declarado (0.27.2 é standalone — research Q3).
- **FR-002**: O sistema MUST prover `packages/cli/pyproject.toml` como membro do workspace UV + `src/fkx_cli/` com `__init__.py`, `main.py` (expondo o objeto `app` como callback-raiz mínimo, sem subcomando — decisão CLARIFY 2026-09-05), `py.typed` (PEP 561) — e nada além destes módulos (+ `__init__` + marcador).
- **FR-003**: O sistema MUST expor o comando instalável `fkx` via `[project.scripts]` apontando para o objeto `app`; `fkx --help` MUST sair com 0 e listar `--help` e `--version` em saída formatada.
- **FR-004**: O sistema MUST implementar `fkx --version` saindo com 0 e imprimindo **somente o número** da versão declarada do pacote instalado (ex.: `0.1.0`; decisão CLARIFY 2026-09-05 — fonte única da versão ao PLAN, sem duplicação).
- **FR-005**: O sistema MUST sair com 2 e mensagem em stderr (nomeando a opção + dica de `--help`) diante de opção inválida.
- **FR-006**: O sistema MUST declarar dependência de membro `fkx-core` e consumir sua superfície pública sem duplicar config/estado/modelos; erro de domínio vindo de `fkx_core` MUST virar saída nomeada + **exit 1** (decisão CLARIFY 2026-09-05 — 2 é reservado a erro de uso; mínimo 0.7, contrato pleno de saída é o item 4.11, fora).
- **FR-007**: O sistema MUST passar `ruff check`, `ruff format --check` e `mypy --strict` sobre `src/fkx_cli/` com zero violações (fronteira inversa da 009; callbacks tipados).
- **FR-008**: O sistema MUST prover testes em `tests/test_fkx_cli_*.py` (config `testpaths`/`coverage` existente — sem novo diretório de testes) cobrindo US1–US3 com vermelho→verde preservado.
- **FR-009**: O sistema MUST conter zero segredo literal; dado dinâmico interpolado em markup MUST ser escapado; `pretty_exceptions_show_locals` MUST permanecer desligado (Lei Zero).
- **FR-010**: O sistema MUST prover oráculo `scripts/verify/f0-012-cli.sh` com 12–16 asserções sob o contrato `oracle-cli.md` (identidade FR↔asserção, determinismo, somente leitura, self-check `f0-001…f0-011`, manifest 12ª linha).
- **FR-011**: `specs/README.md` MUST conter `012` com `packages-cli` `✅` e hash do commit de convergência (inquebrável em escala, padrão 007–011).
- **FR-012**: `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados (CONVERGE + exceção M3 não se estende).

### Key Entities *(include if feature involves data)*

- **App**: objeto raiz do entry point; expõe `--help`/`--version`; sem subcomando de domínio nesta spec.
- **Version**: versão declarada do pacote instalado; fonte única; impressa por `--version`.
- **CliFault**: falha nomeada da CLI (uso inválido ou domínio); atributos: mensagem com causa, exit code documentado, nunca segredo, nunca traceback cru.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operador instala o pacote e obtém ajuda legível (`--help`, `--version` listados) sem ler documentação além do comando.
- **SC-002**: `fkx --version` imprime a versão declarada do pacote em 100% das invocações, com exit 0.
- **SC-003**: Toda condição de erro coberta produz mensagem com causa nomeada + exit code documentado; zero `except:` nus no pacote.
- **SC-004**: `ruff`, `mypy --strict` e `pytest` (incluindo cobertura do pacote) verdes sobre código novo; ganchos locais verdes.
- **SC-005**: Harness 12/12 + manifest 12/12 + tasks zero `[ ]` + par vermelho→verde separado.
- **SC-006**: Oráculo 2× byte-idêntico, cada execução <5s (mesmo padrão das asserções de determinismo dos oráculos anteriores).

## Assumptions

- Nome do comando `fkx` (plano §2 decisão 10 + §15; ADR-010: identificador em inglês).
- Fonte única da versão ao PLAN/`data-model.md` (metadados do pacote instalado — desenho, não spec).
- Nomes internos (funções, callbacks, códigos além de 0/1/2) ao PLAN/`data-model.md`.
- Subcomandos futuros penduram-se no callback-raiz via `add_typer` (Fase 1+) — nenhuma estrutura de grupo antecipada.
- `init/dev/interview/spec/run/audit/status/config/doctor/benchmark/guardian` e TUI são Fase 1+/Fase 4 (fora — §15 lista o destino, 0.7 delimita o mínimo).
- Sem grafo compilado, sem agentes, sem `.env` novo neste item.

## Contratos

### Entregue por este item

- `packages/cli/` (entry point `fkx` + `--help`/`--version` + códigos 0/0/2/1) + pins com hash + testes em `tests/` + oráculo `f0-012` (12–16) + 12ª linha do manifest + `specs/README.md` `012 ✅`.
- Superfície executável para a Fase 1 (subcomandos nascem sobre este entry point) e para a 013 (não se publica pacote que não existe — ADR-009/011).

### Recebido de itens anteriores

- De **011**: `fkx_core` importável com superfície pública estável (consumida, nunca duplicada).
- De **010**: pipeline + quarentena (código novo validado no servidor); `uv sync --frozen --all-packages` como setup canônico (sem ajuste de CI por este item).
- De **009**: fronteira inversa (código novo mantém ganchos verdes).
- De **007/006/005**: `mypy --strict`, `ruff`, `pytest` + `testpaths`/`coverage` (sem novo diretório).
- De **004**: workspace (`members`) + `.python-version` + `uv.lock` como fonte.
- De **001 (Lei Zero)**: sem segredo em código/log/histórico; dado dinâmico escapado.

### Transferido a itens posteriores

- À **013** (automação de release): pacote `fkx-cli` publicável com entry point funcional.
- À **Fase 1** (subcomandos): `app` como raiz onde `init/dev/spec/...` se penduram.
- À **4.11** (contrato de saída da CLI): códigos mínimos 0/0/2/1 como base do schema `--json` futuro.
- À **auditoria pós-012**: segundo pacote de produção sob TDD auditável (primeira auditoria cobrindo código Fase 0 além do kernel).
