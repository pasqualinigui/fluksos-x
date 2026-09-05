# Implementation Plan: `packages/cli` — entry point `fkx`

**Branch**: `012-packages-cli` | **Date**: 2026-09-05 | **Spec**: `specs/012-packages-cli/spec.md`

**Input**: Feature specification from `/specs/012-packages-cli/spec.md`

## Summary

Criar `packages/cli/` (membro UV, módulo `fkx_cli`) com `main.py` (callback-raiz `app: typer.Typer` + `--help`/`--version`), entry point `fkx` em `[project.scripts]`, versão via `importlib.metadata` (fonte única `[project].version`), `typer==0.27.2` + `rich==15.0.0` como runtime do pacote, dependência de membro `fkx-core`, testes em `tests/` via `CliRunner`, oráculo `f0-012` com 12 asserções identidade + 12ª linha do manifest. Segundo pacote de produção sob TDD real; nenhum subcomando de domínio.

## Technical Context

**Language/Version**: Python 3.12 (`requires-python >=3.12,<3.14`; matriz CI 3.12/3.13)

**Primary Dependencies**: `typer==0.27.2` + `rich==15.0.0` (runtime de `packages/cli`, hash `uv.lock`) + `fkx-core` (membro do workspace)

**Storage**: arquivos (`packages/cli/pyproject.toml`, `src/fkx_cli/*.py`); N/A banco

**Testing**: oráculo `f0-012-cli.sh` (12 asserções) com par `red.txt`/`green.txt` + `pytest` em `tests/test_fkx_cli_*.py` via `typer.testing.CliRunner` (testpaths existentes)

**Target Platform**: pacote Python instalável com comando `fkx` (consumido por operador, CI e Fase 1+)

**Project Type**: cli (entry point)

**Performance Goals**: invocação `--help`/`--version` sem efeitos colaterais nem I/O além de stdout/stderr; oráculo <5s, 2× byte-idêntico

**Constraints**: `mypy --strict` zero violações; `ruff` zero; sem `except:` nu; sem segredo literal; sem subcomando de domínio; testes só em `tests/`

**Scale/Scope**: 1 módulo + `__init__` (+ `py.typed`); 12 FRs → 12 asserções identidade 1:1 (FR-010/011 são as guardas: self-check/manifesto)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | exit codes fixos (0 ajuda/versão, 2 uso, 1 domínio), versão única, sem modelo no caminho |
| II Spec antes | ✅ PASS | spec 012 + clarify 4/4 precedem; código só neste ciclo |
| III Teste antes | ✅ PASS | `f0-012` vermelho separado + pytest TDD via CliRunner |
| IV Dados antes | ✅ PASS | `data-model.md` + contratos antes do IMPLEMENT; sem subcomando sem consumidor |
| V Lei Zero | ✅ PASS | sem literal, `escape` em markup dinâmico, `pretty_exceptions_show_locals` off |
| VI Oráculo | ✅ PASS | 12 asserções novas identidade; 001–011 intocados (conflito previsto → ADR prévia, molde ADR-018/023) |
| VII Auto-reparo | ✅ PASS | lições 009/010/011 consumidas como desenho (py.typed, --all-packages, EXTRA_PKG, pipe-mask) |
| VIII Elo verificado | ✅ PASS | PyPI + GitHub releases + executado 2026-09-05 (Q1–Q10) + CliRunner/metadata provados no PLAN |
| IX Agnosticismo | ✅ PASS | CLI fala do motor, nada de stack-alvo |
| X Observabilidade | ✅ PASS | erros nomeados por código (uso 2, domínio 1) + FRs no oráculo |

*Re-check pós-Phase 1: sem violações; Complexity Tracking vazio.*

## Project Structure

### Documentation (this feature)

```text
specs/012-packages-cli/
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
packages/cli/pyproject.toml            # NOVO (012): membro, runtime typer+rich, dep fkx-core, [project.scripts] fkx
packages/cli/src/fkx_cli/__init__.py  # NOVO (012): superfície pública (app)
packages/cli/src/fkx_cli/main.py      # NOVO (012): callback-raiz app + --help/--version + exit 1 domínio
packages/cli/src/fkx_cli/py.typed     # NOVO (012): marcador PEP 561 (lição ADR-024)
tests/test_fkx_cli_*.py                # NOVO (012): TDD via CliRunner (testpaths existentes)
scripts/verify/f0-012-cli.sh           # NOVO (012): 12 asserções identidade
scripts/verify/manifest.sha256          # ACRESCER (012): 12ª linha
specs/README.md                         # EDITAR (012): 012 ✅ + hash
packages/core/, subcomandos, TUI       # NÃO TOCAR / NÃO CRIAR (011 convergido; Fase 1+/Fase 4)
```

**Structure Decision**: pacote `src/` membro do workspace (espelho 011); testes no `tests/` raiz (contrato 005); entry point `[project.scripts]` (PEP 621, tutorial oficial Typer).

## Fases de execução

### Fase A — Preparação

1. Harness 11/11 + manifest 11/11 (base 011, run limpo).
2. `specs/012-packages-cli/evidence/` para `red.txt`/`green.txt`.

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `f0-012-cli.sh` (12 asserções identidade + guardas do contrato) — **arquivo novo**, zero toque em 001–011.
2. Acrescer 12ª linha ao manifest (acréscimo, ADR-015a).
3. Executar: vermelhas de comportamento esperadas (pacote ausente); guardas verdes.
4. Preservar `evidence/red.txt` + commit `test(harness)` **separado**.

### Fase C — CLI verde 🟢

1. `packages/cli/` + `uv sync --all-packages` (runtime com hash; sync puro é armadilha — ADR-023).
2. `main.py` + `__init__` público + `py.typed` desde o esqueleto (ADR-024).
3. `pytest` TDD via CliRunner; `ruff` + `mypy --strict` zeros; `fkx --help/--version` exit 0 medidos sem pipe.
4. `f0-012 --quiet` rumo a 12/12.

### Fase D — Verde e convergência local

1. `specs/README.md` `012 ✅` + hash; `tasks.md` zero `[ ]`.
2. Commit `feat(packages)` separado. CONVERGE: harness + manifest + pytest + cadeia verdes.

### Fase E — Entrega remota

1. Push; matriz 3.12/3.13 + required checks validam código novo no servidor.

## Decisões técnicas herdadas da pesquisa

D1 runtime do pacote, sem click (CLARIFY: pins; Q3) · D2 callback-raiz + flags + códigos 0/0/2/1 (CLARIFY 4/4) · D3 consome `fkx_core`, sem duplicar · D4 sem subcomandos (Escada) · D5 layout `src/fkx_cli/` + `py.typed`, testes em `tests/` via CliRunner · D6 Rich com `escape`, locals off · D7 fronteira Q10 (6 pontos, EXTRA_PKG admite `core`+`cli`).

## Declaração de impacto de fronteira (ADR-017 — antes de qualquer merge)

012 cria `packages/cli/` pela primeira vez: oráculos 004 (FR-012), 005 (FR-015), 006 (FR-014), 007 (FR-014), 008 (FR-013) asserem `packages/` **só com `core/`** (`EXTRA_PKG = ls | grep -v -x core`), e 011 (FR-002) assere `packages/cli` **ausente** — **conflito previsto e legítimo**: a existência do diretório é o próprio objeto da spec. Forma do ajuste (padrão ADR-018/023, só na Fase C, via ADR prévia se o vermelho confirmar): admitir `core` + `cli` com `pyproject.toml` de membro (jurisdição da 012), mantendo a proibição a qualquer outro conteúdo; legitimidade via `uv.lock` (`fkx-cli`/`typer`/`rich` presentes). Nenhum outro oráculo é tocado; `ci.yml`/`lefthook.yml` seguem sem ajuste (ADR-023 já canônico). Se a implementação descobrir necessidade além destes 6 pontos, volta ao PLAN + ADR prévia.

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| `packages/cli/` quebra 004–008/011 no vermelho da 012 | Declarado acima; ADR prévia antes do verde; oráculo novo cobre conteúdo |
| `uv sync` puro remove membros (ADR-023) | Setup canônico `--all-packages` no quickstart; oráculo não depende de sync puro |
| `$?` após pipe mascara exit code (Q4) | Oráculo mede com redirect; quickstart documenta a armadilha |
| Escopo inchando p/ subcomandos Fase 1 | §17 delimita entry point + 2 flags; extra exige spec própria |
| Help byte-exato frágil por largura de terminal | Contrato por marcadores + códigos, nunca bytes (Q4/Edge) |

## Complexity Tracking

> Vazio — Constitution Check sem violações.
