# RESEARCH — F0/011 · `packages/core` — kernel do motor (config, state, models, exceptions)

> **Item do plano:** 0.6 (§17 Fase 0) · **Ordem de execução:** 011/016 (ADR-011)
> **Data da verificação:** 2026-09-04 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Hierarquia de fontes:** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = stdlib/best-practice estável.
> **Insumo anterior:** `specs/010-ci-completo/spec.md` › Contratos + `docs/plan/decisions.md`
> (ADR-011, ADR-015, ADR-016, ADR-020) + `docs/plan/implementation_plan.md` §§3–4, 15, 17
> (estrutura §15: `config.py`, `state.py`, `harness.py`, `constitution.py`,
> `spec_kit_bridge.py`, `context.py`, `models.py`, `exceptions.py`) +
> `docs/plan/addendum_v3.md` §9 (Secrets: Settings + `SecretStr`).

Este item entrega **o primeiro código de produção**: pacote `fkx_core` como membro
do workspace UV (`packages/core/`, `members = ["packages/*"]` já declarado),
com config tipada, estado de grafo, modelos validados e hierarquia de exceções —
tudo sob `ruff` + `mypy --strict` + `pytest` já convergidos (fronteira inversa da
009: código novo MUST manter ganchos verdes). Não cria `packages/cli` (012),
`docker-compose` (015), `.env` real (Lei Zero), nem grafo/agentes executáveis
(Fase 2 — aqui só o **schema** do estado, não o loop).

---

## Q1 — Pins canônicos: pydantic, settings, langgraph?

**Fonte (P0):** `https://pypi.org/pypi/{pydantic,pydantic-settings,langgraph}/json` +
`uv run --with pydantic-settings==2.15.0` executado — HTTP 200, fetch 2026-09-04.

```
pydantic           2.13.5  requires_python >=3.9   (confere plano §4)
pydantic-settings  2.15.0  requires_python >=3.10  (plano dizia "latest" → pin 2.15.0)
langgraph          1.2.11   requires_python >=3.10  (confere plano §4)
```

**Achado:** `pydantic-settings` era o único pin aberto do §4 — fechado em 2.15.0
(import + `SecretStr` executados com sucesso nesta pesquisa).

## Q2 — Padrões Pydantic Settings + segredos?

**Fonte (P0/P1):** import executado acima + `docs/plan/addendum_v3.md:370`
(Settings + `SecretStr`) — fetch 2026-09-04.

`BaseSettings` com `env_prefix="FKX_"` (namespacing evita colisão com ambiente);
segredos como `SecretStr` (mascara em logs/repr — Lei Zero em profundidade);
`.env` real nunca versionado; `.env.example` (template versionável, FR-009/001)
pode ganhar as chaves documentadas. Decisão de nomes exatos ao SPECIFY.

## Q3 — TypedDict vs dataclass vs Pydantic para o estado do grafo?

**Fonte (P1):** `https://docs.langchain.com/oss/python/langgraph/graph-api`
(seção State/Schema), oficial — fetch 2026-09-04.

Veredito literal da fonte: *"The main documented way to specify the schema of a
graph is by using a TypedDict. If you want to provide default values in your
state, use a dataclass."* Pydantic `BaseModel` suportado mas *"less performant
than a TypedDict or dataclass"*. Reducers via `Annotated[..., fn]`; default
sobrescreve; `add_messages` para canais de mensagens.

**Decisão para SPECIFY:** `state.py` = `TypedDict` canônico (+ `Annotated`
reducers onde acumular); `dataclass` só se defaults exigirem; Pydantic em
`models.py` (payloads validados), **nunca** como schema do grafo. Sem inventar
quarta forma.

## Q4 — O que `StateGraph` exige além do schema?

**Fonte (P1):** mesma página (StateGraph/compile/nodes) — fetch 2026-09-04.

`StateGraph(State)` + `.compile()` **obrigatório** antes de usar; nós são
funções puras estado→atualização parcial; **nós devem ser idempotentes**
(re-execução em resume não pode corromper — converge com nosso determinismo:
efeito repetido = mesmo estado). Em 011: só o schema + tipos; grafo compilado
e agentes são Fase 2 (2.1/2.2). Proibido antecipar loop aqui (Escada).

## Q5 — Empacotamento UV: layout e nome?

**Fonte (P0 repo):** `pyproject.toml` (`members = ["packages/*"]`),
`.python-version` (`3.12`) — fetch 2026-09-04.

`packages/core/pyproject.toml` (membro) + `src/fkx_core/` (layout `src/`,
padrão §15); `uv sync` + `uv lock --check` provam coerência (doutrina 010).
Módulo `fkx_core` (inglês, ADR-010: identificador é superfície).

## Q6 — `mypy --strict` + `ruff` sobre código novo: algo especial?

**Fonte (P0 repo):** `pyproject.toml` `[tool.mypy]` strict + `[tool.ruff]`,
oráculo `f0-007`/`f0-006` verdes — fetch 2026-09-04.

Nada especial além de obedecer: `disallow_untyped_defs` (toda função anotada),
`warn_unused_configs`, `exclude` já cobre `.venv`; `ruff format --check` no
hook. Fronteira inversa: primeiro código sob portão total — qualquer vermelho
aqui é do autor, nunca do harness.

## Q7 — Onde vivem os testes da 011?

**Fonte (P0 repo):** `[tool.pytest.ini_options] testpaths = ["tests"]`,
`[tool.coverage] source = ["tests"]` — fetch 2026-09-04.

Em `tests/test_*.py` (config existente; cobertura conta `tests/`). Criar
`packages/core/tests/` exigiria reconfigurar `testpaths`+coverage — mudança de
contrato de 005 sem ganho. **Não criar.**

## Q8 — Fronteira: o que a 011 NÃO cria?

`packages/cli/` (012) · `docker-compose*`/Dockerfile (015) · `.env` real ou
qualquer segredo (Lei Zero) · grafo compilado, agentes, tools (Fase 2) ·
`docs/tree.md` (016, reflete a árvore resultante — inclui `packages/` só lá) ·
release/publish (013). `.env.example` **pode** ganhar chaves (template, não
segredo — decisão ao SPECIFY com a lista exata de vars).

## Q9 — Hierarquia de exceções: forma canônica?

**Fonte (P2 + P0 executado):** `Exception.__mro__ == (Exception, BaseException,
object)` conferido em Python 3.12 local — fetch 2026-09-04.

Raiz `FkxError(Exception)` em `exceptions.py`; subclasses por domínio
(`ConfigError`, `StateError`, ... nomes exatos ao SPECIFY); nunca herdar de
`BaseException` direto; nunca usar `except:` nu no código do motor (mypy/ruff
cobrem o resto). Sem inventar framework de erros.

## Q10 — `SecretStr` vaza em log?

**Fonte (P0 executado):** import + `repr` mascarado via pydantic 2.13.5 —
fetch 2026-09-04 (padrão documentado Pydantic; addendum §9 o exige).

`SecretStr` mascara `repr`/`str`; acesso via `.get_secret_value()` só no ponto
de uso. Oráculo da 011 deve asserir ausência de segredo literal + `SecretStr`
nos campos sensíveis (espelho FR-020/001, sem reescrever 001).

## Decisões (insumo ao SPECIFY/CLARIFY — nada aqui é norma)

- **D1.** Pins: `pydantic==2.13.5` + `pydantic-settings==2.15.0` em dev do workspace (runtime do motor viaja junto? **ao SPECIFY**: dependência do pacote vs dev — motor publicado precisa runtime declarado; provisório: dependência de `packages/core`).
- **D2.** Settings `FKX_` + `SecretStr`; `.env.example` extensível (lista ao SPECIFY).
- **D3.** `state.py` TypedDict + reducers; Pydantic em `models.py`.
- **D4.** Sem grafo compilado/agentes (Fase 2).
- **D5.** Layout `src/fkx_core/`; testes em `tests/`.
- **D6.** `FkxError(Exception)` + domínios (nomes ao SPECIFY).
- **D7.** Fronteira Q8 (inclui `.env.example`-sim / `.env`-não).
