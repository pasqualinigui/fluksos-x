# Feature Specification: `packages/core` — kernel do motor

**Feature Branch**: `011-packages-core`

**Created**: 2026-09-04

**Status**: Draft

**Input**: User description: "Fase 0, item 0.6 (011/016 na ordem de execução): packages/core — primeiro código de produção (config, state, models, exceptions): pacote fkx_core membro do workspace UV, settings FKX_ com SecretStr, estado TypedDict com reducers, modelos Pydantic, hierarquia FkxError, tudo sob ruff + mypy strict + pytest, sem grafo/agentes (Fase 2)."

**Item do plano**: 0.6 (§17 Fase 0) · **Ordem de execução**: 011 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-011-packages-core.md` (decisões D1–D7, Q1–Q10, hierarquia de fontes P0–P2)
**Contrato de entrada**: `specs/010-ci-completo/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-015, ADR-016, ADR-017, ADR-020) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem toolchain, harness e pipeline convergidos (001–010) mas **zero código de produção**: nenhuma estrutura existe para config tipada, estado de grafo, payloads validados ou erros de domínio — tudo que os agentes (Fase 2) e a CLI (012) consumirão. O §17 item 0.6 delimita o escopo a **config, state, models, exceptions** (os demais módulos do §15 — `harness.py`, `constitution.py`, `spec_kit_bridge.py`, `context.py` — são Fase 1+, quando houver o que orquestrar/ler; antecipá-los seria especificar comportamento sem consumidor, violação IV).

Este item entrega **exclusivamente** `packages/core/` (`pyproject.toml` membro + `src/fkx_core/` com `config.py`, `state.py`, `models.py`, `exceptions.py`, `__init__.py` com superfície pública), `pydantic==2.13.5` + `pydantic-settings==2.15.0`, testes em `tests/test_fkx_core_*.py`, oráculo `f0-011-core.sh` com 12–16 asserções. Não cria `packages/cli` (012), grafo compilado/agentes/tools (Fase 2), `.env` real (Lei Zero), `docs/tree.md` (016).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (tipos fechados, defaults explícitos, sem comportamento dependente de modelo); **II** especificação precede código; **III** vermelho→verde em commits separados (primeiro código sob TDD real); **IV** modelo de dados antes (`data-model.md` + schemas); **V** Lei Zero (`SecretStr`, sem segredo literal, `.env.example` só template); **VI** harness oráculo + fronteira inversa da 009 (código novo mantém ganchos verdes); **VIII** pins verificados PyPI + docs LangGraph 2026-09-04; **IX** `core` não assume stack-alvo (tipos do motor, não do projeto gerado); **X** falha nomeia `FR-XXX` + exceção de domínio nomeada.

---

## Clarifications

### Session 2026-09-04 (resolvida — decisão pelo DNA, recomendação acatada)

- Q: `pydantic(+settings)` runtime ou só dev? → A: **runtime do pacote** (Q-A; pacote publicado precisa ser funcional; 013 não herdará correção).
- Q (clarify): Settings cobrem além de ambiente+log? → A: **mínimo** (ambiente, log, segredo) — YAGNI/Escada; Fase 1+ estende com consumidor real.
- Q (clarify): Estado declara quais canais? → A: **mínimo escalar** (`status`, `etapa`, `erros` com reducer de acúmulo) — sem canal de mensagens (evita puxar `langchain-core` na Fase 0; Fase 2 decide mensagens com consumidor real).
- Q (clarify): Taxonomia de erros? → A: **por módulo** (`FkxError` raiz + `ConfigError`, `StateError`, `ModelError`) — cada módulo da 011 tem seu tipo; Fase 1+ estende por módulo novo, nunca genérico.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Config tipada a partir do ambiente (Priority: P1)

Desenvolvedor do motor declara `FKX_ENV=dev` (prefixo `FKX_`) e instancia as settings: valores tipados, defaults explícitos, segredo como `SecretStr` (mascarado em log), variável ausente com default usa default, sem default falha com erro de domínio nomeado.

**Why this priority**: sem config, nenhum componente Fase 1+ inicializa — é a base de tudo.

**Independent Test**: com env limpo + `.env` descartável de teste, instanciar settings, asserir tipos/defaults/máscara; remover var obrigatória, observar `ConfigError` nomeado.

**Acceptance Scenarios**:

1. **Given** env com `FKX_` válidas, **When** instanciar settings, **Then** atributos tipados corretos e segredo mascarado em `repr`.
2. **Given** var obrigatória ausente, **When** instanciar, **Then** `ConfigError` (não `ValidationError` cru) nomeando a var.

---

### User Story 2 — Estado de grafo tipado com reducers (Priority: P2)

Desenvolvedor declara o estado do futuro grafo como `TypedDict` com reducers `Annotated` onde acumular; atualização parcial mescla pelo reducer (default sobrescreve); chaves e tipos conferem contra `data-model.md`.

**Why this priority**: é o contrato que os agentes Fase 2 compilarão — erro aqui propaga para todo o motor.

**Independent Test**: construir estado, aplicar atualizações parciais via reducers, asserir mesclagem/overwrite conforme declarado; `mypy --strict` aprova o módulo.

**Acceptance Scenarios**:

1. **Given** `state.py` com `TypedDict` + reducers, **When** aplicar update parcial, **Then** mesclagem segue o reducer declarado (default = overwrite).
2. **Given** chave fora do schema, **When** checagem estática, **Then** `mypy --strict` reprova (contrato tipado, não ditado).

---

### User Story 3 — Erros de domínio nomeados e testáveis (Priority: P3)

Código do motor falha com `FkxError` especializado (`ConfigError`, `StateError`, ...); captura genérica `except Exception` localiza a causa pelo tipo; nenhuma exceção vaza como `BaseException` nua ou `except:` silencioso.

**Why this priority**: observabilidade do motor (X) começa na taxonomia de erros.

**Independent Test**: provocar cada condição de erro, asserir tipo exato + mensagem com contexto (campo/valor, nunca segredo).

**Acceptance Scenarios**:

1. **Given** condição de erro de config/estado, **When** operação executa, **Then** `FkxError` especializado com mensagem contextual.
2. **Given** `grep -rn "except:" src/fkx_core/`, **When** inspecionado, **Then** zero `except:` nus (oráculo asserir).

---

### Edge Cases

- `.env` real ausente: settings usam defaults/env do processo — nunca falha por arquivo ausente (arquivo é conveniência local, não requisito).
- Segredo em log/traceback: `SecretStr` mascara `repr`; mensagem de erro nunca interpola valor secreto (oráculo asserir por padrão `get_secret_value` só no ponto de uso + ausência de literal).
- Python 3.13 (matriz CI): código 3.12-compatível sem `match` exótico? `requires-python >=3.12,<3.14` — sintaxe válida nas duas (oráculo não testa versão, CI matriz cobre).
- `packages/cli` (012) importando `core` antes de existir: fora de escopo — 012 cuida da integração; 011 só garante importabilidade (`__init__` público).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST declarar `pydantic==2.13.5` + `pydantic-settings==2.15.0` como **dependências de runtime** de `packages/core` (pacote funcional em qualquer ambiente; `uv.lock` do workspace segue fonte única) — decisão CLARIFY 2026-09-04.
- **FR-002**: O sistema MUST prover `packages/core/pyproject.toml` como membro do workspace UV (`members = ["packages/*"]` já declara o padrão) + `src/fkx_core/` com `__init__.py`, `config.py`, `state.py`, `models.py`, `exceptions.py` — e nada além destes 4 módulos (+ `__init__`).
- **FR-003**: O sistema MUST prover settings com prefixo `FKX_`, tipos fechados, defaults explícitos e segredos como `SecretStr`, cobrindo **exatamente** ambiente, nível de log e segredo (superfície mínima — YAGNI/Escada, decisão CLARIFY 2026-09-04); var obrigatória ausente MUST elevar `ConfigError` nomeando a var.
- **FR-004**: O sistema MUST prover estado como `TypedDict` com canais exatamente `status`, `etapa`, `erros` (este com reducer de acúmulo; demais overwrite), sem canal de mensagens (decisão CLARIFY 2026-09-04); Pydantic proibido como schema de grafo (decisão Q3 — performance documentada).
- **FR-005**: O sistema MUST prover modelos Pydantic para payloads em `models.py` (validação com tipos, sem lógica de negócio).
- **FR-006**: O sistema MUST prover `FkxError(Exception)` + exatamente `ConfigError`, `StateError`, `ModelError` (um por módulo da 011; extensão futura por módulo novo — documentado para Fase 1+) em `exceptions.py`; `except:` nu proibido no pacote; `BaseException` direta proibida.
- **FR-007**: O sistema MUST passar `ruff check`, `ruff format --check` e `mypy --strict` sobre `src/fkx_core/` com zero violações (fronteira inversa da 009).
- **FR-008**: O sistema MUST prover testes em `tests/test_fkx_core_*.py` (config `testpaths`/`coverage` existente — sem novo diretório de testes) cobrindo US1–US3 com vermelho→verde preservado.
- **FR-009**: O sistema MUST documentar em `.env.example` exatamente as vars implementadas (template, nunca valor); `.env` real jamais versionado (Lei Zero).
- **FR-010**: O sistema MUST prover oráculo `scripts/verify/f0-011-core.sh` com 12–16 asserções sob o contrato `oracle-cli.md` (identidade FR↔asserção, determinismo, somente leitura, self-check `f0-001…f0-010`, manifest 11ª linha).
- **FR-011**: `specs/README.md` MUST conter `011` com `packages-core` `✅` e hash do commit de convergência (inquebrável em escala, padrão 007–010).
- **FR-012**: `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados (CONVERGE + exceção M3 não se estende).

### Key Entities *(include if feature involves data)*

- **Settings**: config tipada do motor; atributos: prefixo `FKX_`, tipos, defaults, `SecretStr`; sem `.env` versionado.
- **State**: schema `TypedDict` do grafo futuro; canais fixos `status`, `etapa`, `erros` (acúmulo); sem comportamento; extensão futura por ADR/spec do consumidor (Fase 2), nunca por adição silenciosa.
- **Model**: payload Pydantic validado; sem lógica de negócio.
- **FkxError**: raiz de erros de domínio; especializações fixas `ConfigError`, `StateError`, `ModelError` (uma por módulo; extensão por módulo novo); mensagens contextuais sem segredos.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Desenvolvedor instancia settings de env limpo e obtém tipos/defaults corretos com segredos mascarados, sem ler documentação além do `.env.example`.
- **SC-002**: Atualizações parciais de estado mesclam pelo reducer declarado em 100% dos casos testados (overwrite onde sem reducer).
- **SC-003**: Toda condição de erro do pacote eleva `FkxError` especializado nomeado; zero `except:` nus no pacote.
- **SC-004**: `ruff`, `mypy --strict` e `pytest` (incluindo cobertura do pacote) verdes sobre código novo; ganchos locais verdes.
- **SC-005**: Harness 11/11 + manifest 11/11 + tasks zero `[ ]` + par vermelho→verde separado.
- **SC-006**: Oráculo 2× byte-idêntico, cada execução <5s (espelho FR-014/005/009/010).

## Assumptions

- Dependência runtime-vs-dev decidida no CLARIFY (FR-001 = runtime do pacote).
- Nomes de *módulos* fixos (§17: config, state, models, exceptions); nomes internos (classes, campos, vars) ao PLAN/`data-model.md` (desenho, não spec).
- `harness.py`, `constitution.py`, `spec_kit_bridge.py`, `context.py` são Fase 1+ (fora — §17 delimita 0.6 aos 4 módulos).
- Sem grafo compilado, sem agentes, sem CLI neste item.

## Contratos

### Entregue por este item

- `packages/core/` (4 módulos + `__init__` público) + pins com hash + testes em `tests/` + `.env.example` com as vars + oráculo `f0-011` (12–16) + 11ª linha do manifest + `specs/README.md` `011 ✅`.
- Base importável para 012 (CLI) e Fase 1 (harness/constitution/bridge/context sobre estes tipos).

### Recebido de itens anteriores

- De **010**: pipeline + quarentena (código novo validado no servidor); cobertura como portão (SC-004 medido contra ele).
- De **009**: fronteira inversa (código novo mantém ganchos verdes) + `lefthook-local` inexistente.
- De **007/006/005**: `mypy --strict`, `ruff`, `pytest` + `testpaths`/`coverage` (sem novo diretório).
- De **004**: workspace (`members`) + `.python-version` + `uv.lock` como fonte.
- De **001 (Lei Zero)**: `.env` jamais versionado; `.env.example` template.

### Transferido a itens posteriores

- À **012** (`packages/cli`): `fkx_core` importável com superfície pública estável.
- À **Fase 1** (harness/constitution/bridge/context): tipos-base para construir em cima.
- À **Fase 2** (agentes): `state.py` como schema a compilar (não compilado aqui).
- À **auditoria pós-012**: primeiro código de produção sob TDD auditável.
