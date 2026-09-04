# Implementation Plan: `packages/core` — kernel do motor

**Branch**: `011-packages-core` | **Date**: 2026-09-04 | **Spec**: `specs/011-packages-core/spec.md`

**Input**: Feature specification from `/specs/011-packages-core/spec.md`

## Summary

Criar `packages/core/` (membro UV, módulo `fkx_core`) com `config.py` (settings `FKX_` + `SecretStr`), `state.py` (`TypedDict` status/etapa/erros + reducer), `models.py` (Pydantic), `exceptions.py` (`FkxError` + 3), `pydantic(+settings)` como runtime do pacote, testes em `tests/`, oráculo `f0-011` com 14 asserções identidade + 11ª linha do manifest. Primeiro código de produção sob TDD real; nada de grafo/agentes/CLI.

## Technical Context

**Language/Version**: Python 3.12 (`requires-python >=3.12,<3.14`; matriz CI 3.12/3.13)

**Primary Dependencies**: `pydantic==2.13.5` + `pydantic-settings==2.15.0` (runtime de `packages/core`, hash `uv.lock`)

**Storage**: arquivos (`packages/core/pyproject.toml`, `src/fkx_core/*.py`); N/A banco

**Testing**: oráculo `f0-011-core.sh` (14 asserções) com par `red.txt`/`green.txt` + `pytest` em `tests/test_fkx_core_*.py` (testpaths existentes)

**Target Platform**: pacote Python importável (consumido por 012 e Fase 1+)

**Project Type**: library (kernel)

**Performance Goals**: importação sem efeitos colaterais nem I/O; oráculo <5s, 2× byte-idêntico

**Constraints**: `mypy --strict` zero violações; `ruff` zero; sem `except:` nu; sem segredo literal; sem grafo/agentes/CLI; testes só em `tests/`

**Scale/Scope**: 4 módulos + `__init__`; 12 FRs → 12 asserções identidade 1:1

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | tipos fechados, reducers declarados, sem modelo no caminho |
| II Spec antes | ✅ PASS | spec 011 precede; código só neste ciclo |
| III Teste antes | ✅ PASS | `f0-011` vermelho separado + pytest TDD por função |
| IV Dados antes | ✅ PASS | `data-model.md` + schemas antes do IMPLEMENT |
| V Lei Zero | ✅ PASS | `SecretStr`, `.env` jamais versionado, sem literal |
| VI Oráculo | ✅ PASS | 12 asserções novas; 001–010 intocados (sem conflito previsto) |
| VII Auto-reparo | ✅ PASS | dívidas 009/010 consumidas como FRs (fronteira inversa, cobertura) |
| VIII Elo verificado | ✅ PASS | PyPI + docs LangGraph + execução 2026-09-04 |
| IX Agnosticismo | ✅ PASS | tipos do motor, nada de stack-alvo |
| X Observabilidade | ✅ PASS | erros nomeados por domínio + FRs no oráculo |

*Re-check pós-Phase 1: sem violações; Complexity Tracking vazio.*

## Project Structure

### Documentation (this feature)

```text
specs/011-packages-core/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── oracle-cli.md    # mapa FR↔asserção identidade 1:1 (ADR-015b)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
packages/core/pyproject.toml            # NOVO (011): membro, deps runtime pydantic(+settings)
packages/core/src/fkx_core/__init__.py  # NOVO (011): superfície pública
packages/core/src/fkx_core/config.py    # NOVO (011): settings FKX_ + SecretStr
packages/core/src/fkx_core/state.py     # NOVO (011): TypedDict + reducers
packages/core/src/fkx_core/models.py    # NOVO (011): Pydantic payloads
packages/core/src/fkx_core/exceptions.py# NOVO (011): FkxError + 3
tests/test_fkx_core_*.py                # NOVO (011): TDD por módulo (testpaths existentes)
.env.example                            # ESTENDER (011): vars implementadas (template)
scripts/verify/f0-011-core.sh           # NOVO (011): 12 asserções
scripts/verify/manifest.sha256          # ACRESCER (011): 11ª linha
specs/README.md                         # EDITAR (011): 011 ✅ + hash
packages/cli/, docker, .env             # NÃO CRIAR (012, 015, Lei Zero)
```

**Structure Decision**: pacote `src/` membro do workspace; testes no `tests/` raiz (contrato 005); `.env.example` estendido como template.

## Fases de execução

### Fase A — Preparação

1. Harness 10/10 + manifest 10/10 (base 010).
2. `specs/011-packages-core/evidence/` para `red.txt`/`green.txt`.

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `f0-011-core.sh` (12 asserções, identidade) — **arquivo novo**, zero toque em 001–010.
2. Acrescer 11ª linha ao manifest (acréscimo, ADR-015a).
3. Executar: vermelhas de comportamento esperadas (pacote ausente); guardas verdes.
4. Preservar `evidence/red.txt` + commit `test(harness)` **separado**.

### Fase C — Core verde 🟢

1. `packages/core/` + `uv sync` (runtime com hash).
2. 4 módulos + `__init__` público; `.env.example` com as vars.
3. `pytest` TDD por módulo; `ruff` + `mypy --strict` zeros.
4. `f0-011 --quiet` rumo a 12/12.

### Fase D — Verde e convergência local

1. `specs/README.md` `011 ✅` + hash; `tasks.md` zero `[ ]`.
2. Commit `feat(packages)` separado. CONVERGE: harness + manifest + pytest + cadeia verdes.

### Fase E — Entrega remota

1. Push; matriz 3.12/3.13 + required checks validam código novo no servidor (primeiro código de produção sob portão).

## Decisões técnicas herdadas da pesquisa

D1 runtime do pacote (CLARIFY) · D2 settings `FKX_` + `SecretStr`, `.env.example` extensível · D3 TypedDict + reducers, Pydantic em models · D4 sem grafo/agentes · D5 `src/fkx_core/`, testes em `tests/` · D6 `FkxError` + 3 · D7 fronteira Q8.

## Declaração de impacto de fronteira (ADR-017 — antes de qualquer merge)

011 cria `packages/*` pela primeira vez: oráculos 004–008 asserem `packages/` **ausente** (fronteira "deve ser 011/012") — **conflito previsto e legítimo**: a existência do diretório é o próprio objeto da spec. Forma do ajuste (padrão ADR-018, só na Fase C, via ADR prévia se o vermelho confirmar): admitir `packages/core/` com `pyproject.toml` de membro (jurisdição da 011), mantendo a proibição a qualquer outro conteúdo. Nenhum outro oráculo é tocado; se a implementação descobrir necessidade, volta ao PLAN + ADR prévia.

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| `packages/` quebra 004–008 no vermelho da 011 | Declarado acima; ADR prévia antes do verde; oráculo novo cobre conteúdo |
| Dependência runtime vs lock | `uv sync` + `uv lock --check` no verde; CI matriz valida 3.12/3.13 |
| Segredo em teste/modelo | `SecretStr` + oráculo grepa ausência de literal; `.env` jamais commitado |
| Escopo inchando p/ Fase 1 (harness/bridge) | §17 delimita 4 módulos; extra exige spec própria |

## Complexity Tracking

> Vazio — Constitution Check sem violações.
