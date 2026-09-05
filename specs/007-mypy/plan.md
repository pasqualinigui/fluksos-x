# Implementation Plan: MyPy 2.3.1 strict — type checker

**Branch**: `007-mypy` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-mypy/spec.md`
**Pesquisa vinculante**: `docs/plan/research/f0-007-mypy.md` (Q1–Q10, D1–D10, 2026-08-31, sem NEEDS CLARIFICATION)
**Constitution**: `.specify/memory/constitution.md` v1.0.0 (10 princípios I–X)

---

## Summary

Entregar **o type checker strict do monorepo** (implementation_plan §§3,15,17 item 0.3, ordem 007/016 ADR-011): `pyproject.toml` `[tool.mypy]` `python_version 3.12` `strict true` `warn_unused_configs true` `exclude "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"` + `[[tool.mypy.overrides]]` `module tests.*` `disallow_untyped_defs false` `disallow_untyped_calls false` `warn_return_any false` + `mypy==2.3.1` em `[dependency-groups] dev` com `ruff 0.16.5`/`pytest 9.1.1` coexistindo + `uv.lock` com hash + `.mypy_cache/`/`.dmypy.json` ignorados + `uv run mypy --strict .` 0 em `tests/` com overrides + `uv run mypy --strict` fora de `tests/` reprova `disallow_untyped_defs` + oráculo `f0-007-mypy.sh` 12–16 asserções (inclui `specs/README.md` e `git ls-files` inquebráveis) + `manifest.sha256` 7 linhas. Sem `lefthook`/`pip-audit`/`packages/` nem `mypy.ini` separado (Escada). É o último portão de qualidade da Fase 0 antes de `Lefthook` (009) orquestrar `ruff`+`mypy`+`pytest`. Plano é transcrição fiel de D1–D10 verificadas contra PyPI `mypy 2.3.1` + `mypy --help` `strict` 11 flags + docs 132KB + `uv --help` 2026-08-31; nenhum desenho novo.

---

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (família `3.12`; local `3.12.3`, runner `3.12.14` via `setup-python@v7`) + TOML (pyproject/uv.lock) + bash (oráculo) + MyPy 2.3.1 (Python, `>=3.10`). `uv` `0.12.7` binário (pin §4, PyPI 2026-08-31; local `0.12.1` converge).

**Primary Dependencies**: `mypy==2.3.1` (`mypy_extensions`, `pathspec`, `tomli` transitivos), `ruff==0.16.5`, `pytest==9.1.1` `pytest-asyncio==1.4.0` `pytest-cov==7.1.0` já em `dev` (005/006), `uv_build>=0.12.7,<0.13`. Nenhum `lefthook 2.1.11`/`pip-audit` em 007 (FR-014, Escada).

**Storage**: Sistema de arquivos. Artefatos: `pyproject.toml` (raiz, `[tool.mypy]`), `uv.lock` (raiz, TOML universal com `mypy` hash), `.mypy_cache/`/`.dmypy.json` (raiz, cache efêmero, `exclude` + `.gitignore` 217), `scripts/verify/f0-007-mypy.sh` (oráculo), `scripts/verify/manifest.sha256` 7 linhas, `specs/README.md` (índice). `.ruff_cache`/`htmlcov`/`.coverage` já existem (006/005).

**Testing**: `uv run mypy --strict .` (type checker, `python_version 3.12` `strict` 11 flags) + `uv run mypy --strict tests/` com `overrides` relaxado + `uv run mypy --version` `2.3.1` + `mypy --help` `strict` + oráculo `f0-007-mypy.sh` 12–16 asserções (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER` 12–16, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`, `2× cmp`) + `mypy --no-error-summary` para determinismo. `ruff` (`f0-006`) e `pytest` (`f0-005`) devem continuar 14/14 e 15/15 (`self-check`).

**Target Platform**: Filesystem POSIX (Linux `ubuntu-24.04` runner + local), macOS/Windows cobertos por lock universal. CI `003` `for f in f0-*.sh` + `010` futuro `uv run mypy --strict` determinístico.

**Project Type**: Infraestrutura de qualidade — type checker. Não produz biblioteca nem CLI além do verificador.

**Performance Goals**: `uv sync` com `mypy` <2min; `uv run mypy --strict .` <2s em `tests/` (12 arquivos), `<5s` em repo com `exclude` `docs/|specs/`; `f0-007` <5s `EPOCHSECONDS` `2× cmp`; `manifest 7` `<1s`.

**Constraints**:
- Escada (constitution Additional Constraints): nenhum artefato pode exigir `lefthook`/`pip-audit`/`packages` — impõe FR-014 negativo.
- Determinismo (I): `[dependency-groups]` pin exato `2.3.1`, `python_version 3.12` fixo, `strict` atômico, `exclude` regex determinístico, `EPOCHSECONDS` sem `date`, `sha256sum`, `git ls-files` para commit inquebrável.
- Lei Zero (V): `uv.lock` versionado, `.mypy_cache`/`dmypy.json` ignorados, `dev` local-only.
- Fidelidade ao oráculo (VI): harness cresce por acréscimo (`f0-007` sem tocar `f0-006`..01), `manifest.sha256` 7 linhas aditivo, `CONVERGE` zero `[ ]` + `specs/README.md` e `git ls-files` inquebráveis.
- Escopo da máquina: nada global, identidade em `.git/config` local.
- Sem privilégio elevado: não exige `sudo`/`admin`.

**Scale/Scope**: 16 FRs (inclui 2 inquebráveis `FR-015` `FR-016`), 8 SCs, 3 US (P1–P3), 8 edge cases. `pyproject.toml` + `uv.lock` alterados + `.mypy_cache/` efêmero + 1 oráculo `12–16` asserções. `tests/` 12 arquivos já existentes, `mypy` deve checar com `overrides` sem reprovar `S101`/`S603` de `ruff`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Princípios avaliados contra v1.0.0:**

| Princípio | Critério de violação | Avaliação neste plano |
|---|---|---|
| **I Determinismo sobre probabilidade** | decisão sem regra determinística validando modelo | ✅ PASS — `mypy==2.3.1` exato (D1), `python_version 3.12` `strict` atômico (D4), `exclude` regex determinístico, `EPOCHSECONDS` sem `date`, `git ls-files` para `README`/`commit`. |
| **II Especificação precede código** | artefato sem spec prévia | ✅ PASS — `spec.md` 203 linhas 16 FRs/8 SCs existe antes deste plano; nenhum `[tool.mypy]` criado ainda (`! grep -q "tool.mypy" pyproject.toml`, Q1/Q2). |
| **III Teste antes da implementação** | sem par vermelho→verde | ✅ PASS — Fase B gera `f0-007` reprovando (vermelho) antes de Fase C `mypy` verde; `mypy --strict` reprovando antes, 0 depois; `evidence/red.txt`/`green.txt`. |
| **IV Definição de dados antes da implementação** | componente sem contrato | ✅ PASS — `data-model.md` declara entidades MyPy strict/cache/manifest + README/commit inquebráveis; `contracts/mypy-contract.md` + `oracle-cli.md` fixam schemas. |
| **V Segurança é a Lei Zero** | segredo ou trava coberta | ✅ PASS — `uv.lock` versionado (FR-005/006), `.mypy_cache`/`dmypy.json` ignorados (FR-007), `dev` local-only, nenhum segredo; `001` D3 sem `*.lock` preservado. |
| **VI O harness é o oráculo** | critério sem asserção ou diff altera anterior | ✅ PASS — FR-001..016 têm asserção 1:1 em `f0-007` (12–16); plano proíbe tocar `f0-006`..01 (hashes `ee85cfdf…` etc. em `manifest.sha256`); `mypy --strict` verifica, não re-escreve; `specs/README.md` e `git ls-files` inquebráveis. |
| **VII Auto-reparo atualiza a documentação** | correção sem alteração normativa | ✅ PASS — plano inclui `specs/README.md` e `git ls-files` como FR-015/016 após falha 006 ter passado sem ver; se falhar, reparo exigirá `specs/README.md` update. |
| **VIII Elo verificado antes de lógica** | código consome serviço sem verificação | ✅ PASS — Q1–Q10 verificados 2026-08-31 contra PyPI `mypy 2.3.1` + `mypy --help` `strict` 11 flags + docs 132KB + `uv --help`/`python --version` locais; D1–D10 citam fonte+bytes. |
| **IX Agnosticismo de stack** | referência a stack-alvo fora de adaptador | ✅ PASS — `mypy` é infra do motor (Fase 0 bootstrap), não do sistema-alvo; não assume linguagem/framework do alvo. |
| **X Observabilidade** | falha sem REQ-ID ou evidência | ✅ PASS — cada asserção `f0-007` imprime `🔴 FR-XXX` com evidência (`tomllib` parse, `git check-ignore`, `mypy --strict` output, `sha256sum`, `grep README`, `git ls-files`); SC-002 exige lista `no-untyped-def` nomeada. |

**Additional Constraints:**

| Constraint | Avaliação |
|---|---|
| Escada de dependências | ✅ Só `mypy` além de `ruff`+`pytest`+`uv`+stdlib; nenhum `lefthook`/`pip-audit`/`packages` (FR-014). |
| Escopo da máquina | ✅ Nenhuma escrita global. |
| Cadeia de suprimentos | ✅ `uv.lock` com `mypy` hash versionado. |
| Ambiente sob demanda | ✅ Sem Docker; `mypy --strict` on-demand, `dmypy` não usado no harness. |
| Sem privilégio elevado | ✅ Nenhum `sudo`. |

**Veredito pré-Phase 0**: **PASS** — nenhum gate bloqueante, nenhum NEEDS CLARIFICATION (research Q1–Q10 já resolveu, `FR-015/016` inquebráveis adicionados em `spec` ainda `Draft` antes de `plan` derivar tarefas).

**Re-avaliação pós-Phase 1**: **PASS** — `research.md` consolida D1–D10, `data-model.md`/`contracts/`/`quickstart.md` não introduzem dependência nova nem violam escada; `mypy` + `ruff`/`pytest` coexistem em `dev`; `specs/README.md` e `git ls-files` inquebráveis adicionados sem aumentar `tasks.md` além de 2 FRs (ainda `<5s`).

---

## Project Structure

### Documentation (this feature)

```text
specs/007-mypy/
├── spec.md              # Concluído (203 linhas, 16 FRs 14+2 inquebráveis, 8 SCs)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — Q1–Q10 → D1–D10 (consolida docs/plan/research/f0-007-mypy.md)
├── data-model.md        # Phase 1 — entidades MyPy strict / cache / manifest + README/commit inquebráveis
├── quickstart.md        # Phase 1 — 6 cenários (clone limpo, strict sênior, overrides, fronteira, CONVERGE, CI)
├── contracts/
│   ├── mypy-contract.md         # Phase 1 — contrato mypy (pyproject.toml schema, python_version, strict, overrides)
│   └── oracle-cli.md            # Phase 1 — contrato oráculo 007 (CANON 12–16 + manifest 7 linhas + README/commit)
├── checklists/
│   └── requirements.md  # (gerado, 12/12 PASS)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item produz **2 arquivos versionados alterados + 1 cache efêmero + 1 oráculo + 1 índice atualizado**; não produz `lefthook`/`packages/`:

```text
fluksos-x/
├── pyproject.toml                     # ALTERADO — acrescenta [tool.mypy] python_version 3.12 strict true warn_unused_configs true exclude "(?x)^(docs/|specs/|\\.venv/)" + [[tool.mypy.overrides]] module tests.* (FR-002/003)
│                                      # já contém [dependency-groups] dev com pytest 9.1.1 + ruff 0.16.5 + mypy 2.3.1 (007) + [tool.ruff.*] (006) + [tool.pytest.*] (005)
├── uv.lock                            # ALTERADO — acrescenta mypy 2.3.1 + mypy_extensions/pathspec/tomli com hash (FR-005/006)
├── .mypy_cache/                       # NOVO efêmero — cache mypy, ignorado via .gitignore 217 + exclude (FR-007)
├── .dmypy.json                        # NOVO efêmero — dmypy daemon, ignorado (FR-007, não portão)
├── scripts/verify/
│   ├── manifest.sha256                # ALTERADO — 7 linhas (001..007) sha256sum -c 0 (FR-008, D8)
│   ├── f0-007-mypy.sh                 # NOVO — oráculo deste item (12–16 asserções, FR-001..016, inclui README/commit)
│   ├── README.md                      # INTOCADO — já registra 001..006, 007 adiciona linha em 007 (T030)
│   ├── f0-006-ruff.sh                 # INTOCADO — hash ee85cfdf… (manifest)
│   └── f0-001..005                    # INTOCADOS
├── specs/README.md                    # ALTERADO — índice 007 → ✅ (FR-015, inquebrável)
├── tests/                             # EXISTE — 12 passed, mypy deve checar com overrides disallow_untyped_defs false
├── .gitignore                         # INTOCADO — já cobre .mypy_cache/ 217 + .dmypy.json 218
├── .github/workflows/ci.yml           # INTOCADO — 003 glob for f0-*.sh inclui f0-007 sem editar
├── docs/plan/research/
│   └── f0-007-mypy.md                 # JÁ EXISTE — pesquisa vinculante 376 linhas Q1–Q10
└── specs/007-mypy/                    # NOVO
```

**Structure Decision**: `[tool.mypy]` em `pyproject.toml` segue `mypy.readthedocs.io/en/stable/config_file.html` (fonte única, sem `mypy.ini` separado D2). `manifest.sha256` 7 linhas segue ADR-015a. Oráculo `f0-007-mypy.sh` segue ADR-002. `specs/README.md` índice flat segue ADR-011 + `FR-015` inquebrável. `exclude` regex `(?x)` para `mypy` (verbose) vs `ruff` `exclude` lista TOML. Não há `src/` porque type checker é infra.

---

## Fases de execução

> Ordem normativa: vermelho antes do verde (III); `mypy==2.3.1` em `[dependency-groups]` antes de `uv sync`; `mypy.ini` ausente verificado antes de `[tool.mypy]`; `specs/README.md` e `git ls-files` verificados após `mypy --strict` 0, porque README/commit inquebráveis só fazem sentido quando `mypy` já está verde.

### Fase A — Preparação

1. Confirmar harness verde: `for f in f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com `f0-001` 30/30 `f0-002` 33/33 `f0-003` 14/14 `f0-004` 14/14 `f0-005` 15/15 `f0-006` 14/14 + `uv run mypy --version` 2.3.1 + `uv run pytest -q` 12 passed + `uv run ruff check` 0.
2. Confirmar ausência de `[tool.mypy]` (`! grep -q "tool.mypy" pyproject.toml`), ausência de `mypy.ini` (`! test -f mypy.ini`), ausência de `mypy` em `uv.lock` (`! grep -q 'name = "mypy"' uv.lock`), e `.gitignore` já cobre `.mypy_cache` (217).
3. Medir hashes `sha256sum f0-*.sh` (devem bater `63412ca7…` `b63ac3c8…` `d10c61…` `2f8839de…` `ab26f233…` `ee85cfdf…`).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-007-mypy.sh` com contrato `oracle-cli.md` (`0`/`1`/`2`, `--quiet`/`--list`, `CANON_ORDER` 12–16, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`).
2. Cobrir FR-001..016 1:1 (12–16 asserções):
   - FR-001: `[dependency-groups] dev` contém `mypy==2.3.1` exato, sem `mypy` em `[project.dependencies]`.
   - FR-002: `[tool.mypy]` `python_version 3.12` `strict true` `warn_unused_configs true` `exclude` regex.
   - FR-003: `[[tool.mypy.overrides]]` `module tests.*` `disallow_untyped_defs false` etc.
   - FR-004: `! test -f mypy.ini` (fonte única).
   - FR-005: `uv.lock` contém `mypy` + `tomllib` + `uv lock --check` + `mypy --version 2.3.1`.
   - FR-006: `uv.lock` contém `mypy` e transitivos `tomllib` + `uv lock --check`.
   - FR-007: `.mypy_cache`/`dmypy.json` gitignored, `uv.lock` não.
   - FR-008: `uv run mypy --strict .` 0 em conforme (com `overrides`).
   - FR-009: `uv run mypy --strict tests/` 0 com `overrides` relaxado, fora de `tests/` reprova `disallow_untyped_defs`.
   - FR-010: `mypy --version` 2.3.1 + `strict` 11 flags.
   - FR-011: oráculo self-check `0/1/2` `quiet` `list` `determinismo` `2× cmp` `<5s`.
   - FR-012: CI glob `for f` inclui `f0-007`.
   - FR-013: CONVERGE `grep -E "^- \[ \]" tasks.md` 0.
   - FR-014: fronteira `! [tool.mypy]` etc. `! lefthook.yml` `! packages/`.
   - FR-015: `specs/README.md` contém `007` `✅` (inquebrável).
   - FR-016: `git ls-files --error-unmatch specs/007-mypy/spec.md` 0 (inquebrável, `??` reprova).
3. Executar e preservar `evidence/red.txt` — deve reprovar (6–8/16) por ausência de `mypy`.
4. Conferir `--list` enumera 12–16 IDs.

### Fase C — MyPy verde 🟢

1. Materializar `mypy` via `uv`:

```bash
uv add --dev mypy==2.3.1
uv sync  # mypy em .venv/bin/mypy, uv.lock com hash
```

Fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub + `[tool.mypy]` TOML válido.

2. Acrescentar `[tool.mypy]` + `[[tool.mypy.overrides]]` em `pyproject.toml` conforme `contracts/mypy-contract.md` (D4).
3. Validar `uv run mypy --strict .` 0 em `tests/` (com `overrides`) e `uv run mypy --strict` fora de `tests/` reprova `disallow_untyped_defs` quando injetado.
4. Gerar `manifest.sha256` 7 linhas: `sha256sum f0-001..007 > manifest.sha256` + `sha256sum -c` 0.
5. Atualizar `specs/README.md` índice `007 → ✅` (FR-015) e `README.md` `f0-007` linha.
6. Validar `git ls-files --error-unmatch specs/007-mypy/spec.md` 0 (FR-016).

### Fase D — Verde e convergência local

1. `f0-007-mypy.sh --quiet` → `0`; `evidence/green.txt`.
2. `uv run mypy --strict .` 0 + `uv run mypy --strict tests/` 0 + `mypy --version` 2.3.1 (SC-003).
3. `2× cmp` determinismo + `<5s` `EPOCHSECONDS`.
4. `for f in f0-*.sh; do "$f" --quiet || exit 1; done` → `0` (7/7) + `uv run pytest -q` 12 passed + `uv run ruff check` 0 (pytest 005 + ruff 006 ainda verdes).
5. `grep -E "^- \[ \]" tasks.md` → 0 + `git ls-files` 0.

### Fase E — Entrega remota (pós-merge)

1. Push `main` conforme → `verify` verde inclui `f0-007`.
2. Injetar `mypy.ini` ou `lefthook.yml` → PR `verify` vermelho `FR-004`/`FR-014`.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | `mypy==2.3.1` via `[dependency-groups] dev` | FR-001/005/006 | Q1 PyPI 2026-08-15 |
| D2 | `pyproject.toml` `[tool.mypy]` fonte única, sem `mypy.ini` | FR-002/004 | Q2 docs/config_file 132KB |
| D3 | `strict = true` (11 flags) sem `disallow_any_expr` adicional | FR-002 | Q3 mypy --help strict |
| D4 | `python_version 3.12` `strict true` `warn_unused_configs true` `exclude "(?x)^(docs/|specs/|\\.venv/)"` + `[[tool.mypy.overrides]] tests.*` | FR-002/003 | Q4 docs/config_file |
| D5 | `native-parser` default 2.3, `local partial types` habilitado (2.0) | FR-002 | Q5 mypy --help 2.x |
| D6 | `uv add --dev mypy==2.3.1` → `dev` com `pytest`+`ruff`+`mypy` | FR-001/005 | Q6 uv docs |
| D7 | Compat `ruff` `py312` + `overrides` para `tests/` | FR-003 | Q7 docs/ruff 006 D10 |
| D8 | `exclude` regex `(?x)` + `.mypy_cache` gitignored, `specs/README.md` + `git ls-files` inquebráveis | FR-002/007/015/016 | Q8 docs/config_file + ADR-011 |
| D9 | Harness `f0-007-mypy.sh` 12–16 asserções só mypy (inclui README/commit) | FR-011/015/016 | Q9 oracle-cli |
| D10 | Determinismo `mypy --strict` idempotente, fronteira Escada (007 só mypy) | FR-014 | Q10 constitution |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `mypy.ini` esconde `[tool.mypy]` | Alto — config duplicada | FR-004 `! test -f mypy.ini` + `strict` |
| `disallow_untyped_defs` em `tests/` | Alto — `def test_foo():` reprova | D4 `overrides` `tests.*` `false` |
| `warn_unused_configs` typo | Médio — `module` inexistente silencioso | D4 `warn_unused_configs true` |
| `exclude` sem `docs/` `specs/` | Médio — `mypy` tenta checar Markdown | D4 `exclude "(?x)^(docs/|specs/)"` |
| `lefthook` adiantado em 007 | Alto — Escada | FR-014 `! lefthook.yml` |
| `uv 0.12.1` com `mypy` | Médio — lock diverge | D1 `uv self update` |
| `specs/README.md` desatualizado | Alto — índice mente, escala quebra | D8 `FR-015` `grep -q "007.*✅"` inquebrável |
| `spec 007` não commitado (`??`) | Alto — 007 não está na `main` | D8 `FR-016` `git ls-files --error-unmatch` inquebrável |
| `.mypy_cache` versionado | Alto — cache no histórico | FR-007 `check-ignore` |

---

## Complexity Tracking

> Nenhuma violação de Constitution Check a justificar.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |
