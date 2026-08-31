# Feature Specification: MyPy 2.3.1 strict — type checker

**Feature Branch**: `007-mypy`

**Created**: 2026-08-31

**Status**: Draft

**Input**: User description: "Fase 0, item 0.3 (007/016 na ordem de execução): MyPy 2.3.1 strict — type checker com python_version 3.12 strict true warn_unused_configs true exclude regex e per-module overrides para tests.* (disallow_untyped_defs false), via dependency-groups dev, mypy --strict. Sem Lefthook/packages."

**Item do plano**: 0.3 (§17 Fase 0, Itens 0.1–0.12) · **Ordem de execução**: 007 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-007-mypy.md` (decisões D1–D10, Q1–Q10, nenhuma NEEDS CLARIFICATION)
**Contrato de entrada**: `specs/006-ruff/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011, ADR-015) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor já tem `ruff` (006) para lint/format e `pytest` (005) para TDD, mas **sem type checker** — cada `tests/*.py` é escrito sem `strict` e `Any` implícito passa silencioso, enquanto `implementation_plan §4` exige `MyPy 2.3.1` `strict` (nova série `2.x`, `native-parser` Rust). `MyPy` ( `>=3.10` ) é o único type checker do monorepo; `Lefthook` (009) orquestra, `pip-audit` (008) audita — nenhum entra em 007 (Escada).

Este item entrega **exclusivamente** `mypy` via `uv`: `pyproject.toml` `[tool.mypy]` `python_version 3.12` `strict true` `warn_unused_configs true` `exclude "(?x)^(docs/|specs/|\\.venv/)"` + `[[tool.mypy.overrides]]` `module tests.*` `disallow_untyped_defs false` `disallow_untyped_calls false` `warn_return_any false` + `mypy==2.3.1` em `[dependency-groups] dev`, `uv.lock` com hash, `.mypy_cache/`/`.dmypy.json` ignorados, `uv run mypy --strict .` 0 em `tests/` com overrides, oráculo `f0-007-mypy.sh` 12–16 asserções (inclui `specs/README.md` e `git ls-files` inquebráveis). Não cria `mypy.ini`/` .mypy.ini` separado (fonte única `pyproject.toml` D2), `lefthook.yml` (009), `pip-audit` (008) nem `packages/` (011/012).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (`[dependency-groups]` pin exato + `python_version 3.12` fixo + `strict` atômico), **II** especificação precede código, **III** vermelho→verde preservado (`.sh` + `mypy --strict`), **V** Lei Zero (trava versionada, `.mypy_cache` ignorado, `dev` local-only), **VI** harness oráculo com 10–14 asserções novas + `mypy --strict` nomeando FR, **VIII** elo verificado (PyPI `mypy==2.3.1` + `mypy --help` `strict` + docs 132KB + `uv --help` 2026-08-31), **X** observabilidade (falha nomeia `FR-XXX`).

---

## Clarifications

### Session 2026-08-31

- Q: Criar `mypy.ini` separado além de `pyproject.toml`? → A: **Não.** `mypy.ini` tem precedência e esconderia `[tool.mypy]` — fragmenta config. Fonte única permanece `pyproject.toml` (D2, `config_file` 132KB).
- Q: `strict = true` + `disallow_any_expr = true` adicional? → A: **Não.** `disallow_any_expr` bloquearia `tests/` com `Any` em `subprocess` mocks; `strict` puro (11 flags) já é sênior sem ser bloqueante para `tests/` (D3). Reavaliar em `011` (`packages/core`).
- Q: `exclude = "tests/"` para esconder `tests/` de `mypy`? → A: **Não.** `tests/` deve ser checado com `overrides` relaxado (`disallow_untyped_defs false`), não excluído — `exclude` só para `docs/` `specs/` `/.venv/` (D4). `ignore_errors = true` seria silencioso.
- Q: Adicionar `dmypy` daemon em 007? → A: **Não.** `dmypy` usa `.dmypy.json` + `.mypy_cache/` já gitignored, mas harness roda `mypy` batch (`strict` sem daemon) para determinismo. `dmypy` é conveniência local, não portão (D10).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Type check verde em clone limpo (Priority: P1)

Desenvolvedor clona em máquina limpa (sem `.mypy_cache`) e precisa obter **type check strict** com `uv sync` + `uv run mypy --strict .` — saída determinística, sem `mypy.ini` separado, com `python_version 3.12` e `strict` atômico.

**Why this priority**: é o primeiro portão de tipos. Sem `mypy`, cada `tests/*.py` aceita `def foo(x):` sem `-> None` e `x: Any` implícito — `ruff` (006) não pega `Any`, `pytest` (005) não pega `untyped defs`. `lefthook` (009) orquestraria `mypy` sem lock se `007` não existisse, e `010` (`uv sync --frozen` + `mypy` em CI) não teria `uv.lock`.

**Independent Test**: `uv sync` com `mypy==2.3.1` → `uv.lock` contém `mypy`; `uv run mypy --version` → `2.3.1`; `uv run mypy --strict tests/` 0 em `tests/` com `overrides` `disallow_untyped_defs false`.

**Acceptance Scenarios**:

1. **Given** clone sem `mypy` e `uv.lock` sem `mypy`, **When** `uv add --dev mypy==2.3.1` + `uv sync`, **Then** `pyproject.toml` contém `mypy==2.3.1` em `[dependency-groups] dev` e `uv.lock` contém `mypy 2.3.1` com hash, `.venv/bin/mypy` existe, `mypy --version` → `2.3.1`.
2. **Given** `pyproject.toml` com `[tool.mypy]` `python_version 3.12` `strict true`, **When** `uv run mypy --strict tests/test_harness_oracles.py` com `overrides` `tests.*` relaxado, **Then** exit 0 mesmo que `def test_foo():` sem `-> None` em `tests/`; **When** cria `e.py` com `def foo(x): return x` sem anotação fora de `tests/`, **Then** `mypy --strict .` reprova `disallow_untyped_defs`.
3. **Given** `pyproject.toml` com `exclude = "(?x)^(docs/|specs/|\\.venv/)"`, **When** `uv run mypy --strict .` em repo com `docs/` e `specs/` (Markdown), **Then** não tenta checar `docs/` `specs/` (excluídos), apenas `tests/` e futuros `packages/`.
4. **Given** repo conforme, **When** `uv run mypy --strict .` duas vezes, **Then** segunda saída idêntica byte-a-byte e `<5s` cada (determinismo `EPOCHSECONDS`, `--no-error-summary` para teste).

---

### User Story 2 — Strict sênior e compatibilidade ruff/pytest (Priority: P2)

Arquiteto precisa que `mypy` `strict` aplique `disallow-untyped-defs/calls` `warn-return-any` `strict-equality` além do default, mas **sem quebrar** `tests/` que usa `Any` em `subprocess` mocks e `def test_*():` sem `-> None`, e **sem conflitar** com `ruff` `target-version py312` `UP`/`I`.

**Why this priority**: `strict` puro habilita 11 flags (`disallow-any-generics`, `no-implicit-reexport`, `strict-equality`, `extra-checks`) — ganho sobre `mypy` sem `strict`. Sem `overrides` correto, `tests/` reprovaria `disallow_untyped_defs` e `warn_return_any` sem valor.

**Independent Test**: `uv run mypy --strict --show-error-codes tests/` lista `no-untyped-def` quando provocado em `src/` futuro, mas não em `tests/` com `overrides`; `grep -q 'python_version.*3.12' pyproject.toml` + `ruff target-version py312` alinhados.

**Acceptance Scenarios**:

1. **Given** `[tool.mypy]` `strict = true`, **When** cria `f.py` com `x: list` sem param (`list` vs `list[int]`) fora de `tests/`, **Then** `mypy --strict` reprova `disallow-any-generics` (`misc`).
2. **Given** `[[tool.mypy.overrides]] module = "tests.*" disallow_untyped_defs = false`, **When** `mypy --strict tests/test_harness_debts.py` com `def test_foo():` sem `-> None`, **Then** não reprova `disallow_untyped_defs` em `tests/`, mas reprovaria em `packages/core/src.py` sem `overrides`.
3. **Given** `ruff` `UP007` moderniza `Union[int, str]` → `int | str` (3.12) e `mypy` `python_version 3.12`, **When** `ruff --fix` aplica `X|Y`, **Then** `mypy --strict` não reprova `X|Y` (compatível 3.12), sem conflito.
4. **Given** `warn_unused_configs = true`, **When** cria `[[tool.mypy.overrides]] module = "foo.bar"` typo, **Then** `mypy` avisa `unused config` (detecta `module` inexistente).

---

### User Story 3 — Fronteira, cache e CONVERGE (Priority: P3)

Mantenedor roda `mypy --strict` e precisa ver **fronteira** (sem `lefthook`/`packages`), **cache ignorado** (`.mypy_cache/`/`.dmypy.json`), e **CONVERGE** (`tasks.md` zero `[ ]`) — tudo via `mypy` e `f0-007-mypy.sh`, sem tocar `f0-006`.

**Why this priority**: Escada e `ADR-015d` (CONVERGE fecha lista). Sem fronteira, `007` anteciparia `lefthook`/`packages` e quebraria `009`/`011`.

**Independent Test**: `! test -f mypy.ini && ! test -f lefthook.yml && ! test -d packages` + `git check-ignore -q .mypy_cache` + `grep -c "\[ \]" tasks.md` → 0.

**Acceptance Scenarios**:

1. **Given** `pyproject.toml` com `[tool.mypy]`, **When** `! test -f mypy.ini` e `! test -f .mypy.ini`, **Then** fonte única mantida; `mypy` lê `pyproject.toml` sem `--config-file`.
2. **Given** `.gitignore` com `.mypy_cache/`/`.dmypy.json` e `exclude = "(?x)^(\\.mypy_cache/|\\.dmypy.json)"` não necessário (mypy ignora via `exclude`), **When** `uv run mypy --strict .` cria `.mypy_cache/`, **Then** `git check-ignore -q .mypy_cache` positivo e `git status --porcelain` não lista `.mypy_cache/`.
3. **Given** `specs/007-mypy/tasks.md` com 30 tasks, **When** todas `[x]`, **Then** `f0-007-mypy.sh` `FR-013` `CONVERGE` passa; com 1 `[ ]` reprova nomeando `FR-013`.
4. **Given** `f0-007-mypy.sh`, **When** `--list` e `--quiet` e `FKX_ORACLE_NESTED=1`, **Then** `CANON_ORDER` 10–14 IDs, `exit 0/1/2`, `EPOCHSECONDS <5s`, `2× cmp` idêntico.

---

### Edge Cases

- **`mypy.ini` existe além de `pyproject.toml`.** Deve reprovar — `mypy.ini` tem precedência e esconderia `[tool.mypy]` (Q2, D2).
- **`def foo(x):` sem `-> None` em `tests/` vs `src/` futuro.** `disallow_untyped_defs` relaxado em `tests.*` via `overrides`, mas reprovaria em `packages/core/` sem `overrides` (D4).
- **`x: list` sem param (`list[int]`) em `src/` futuro.** `disallow-any-generics` (strict) reprova `misc` — deve reprovar fora de `tests/` (D3).
- **`warn_unused_configs` typo `module = "foo.bar"` inexistente.** Deve reprovar com `unused config` (D4).
- **`.mypy_cache` versionado acidentalmente.** `git check-ignore -q .mypy_cache` positivo; `f0-007` reprova se `git ls-files | grep .mypy_cache` (Lei Zero).
- **`packages/` criado sem `pyproject.toml` lá dentro.** `f0-007` deve reprovar se `packages/` existir — é `011`/`012`, não `007` (Fronteira).
- **Máquina com `mypy` 1.x global.** `uv run mypy --version` em `.venv` deve ser `2.3.1` — local converge ao pin (D1).
- **`mypy --strict` com `python_version 3.12` vs `3.10`.** `3.10` reprovaria `X|Y` (3.10+), `3.12` alinha com `ruff` `py312` (D4/D7).

---

## Requirements *(mandatory)*

### Functional Requirements

**Artefato raiz e descoberta (D2)**

- **FR-001**: O sistema MUST declarar `mypy==2.3.1` (exato) em `[dependency-groups] dev` em `pyproject.toml` (PEP 735, `uv add --dev mypy==2.3.1`), sem `mypy` em `[project.dependencies]` nem `requirements*.txt` (D1/D6).
- **FR-002**: O sistema MUST prover `[tool.mypy]` em `pyproject.toml` com `python_version = "3.12"` e `strict = true` e `warn_unused_configs = true` e `exclude = "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)"` (D4, Q2/Q8).
- **FR-003**: O sistema MUST prover `[[tool.mypy.overrides]]` com `module = "tests.*"` `disallow_untyped_defs = false` `disallow_untyped_calls = false` `warn_return_any = false` (D4, Q4).
- **FR-004**: O sistema MUST NOT prover `mypy.ini` nem `.mypy.ini` separado — fonte única é `pyproject.toml` (D2, Q2).
- **FR-005**: O sistema MUST prover `mypy` com hash em `uv.lock` (`grep 'name = "mypy"'` + `tomllib` válido + `uv lock --check` quando `uv` presente) e `mypy --version` → `2.3.1` (D1/D6, Q1).

**Trava e cache (D6/D8)**

- **FR-006**: `uv.lock` MUST conter `mypy` e `mypy_extensions`/`pathspec`/`tomli` transitivos, `tomllib` válido, `uv lock --check` 0 (D1/D6, Q1).
- **FR-007**: `.mypy_cache/` e `.dmypy.json` MUST ser ignorados por git (`git check-ignore -q` positivo e `! git ls-files | grep`) e `uv.lock` MUST NOT ser ignorado (D8, Q8, `.gitignore` 217).

**Type check determinístico (D3/D4)**

- **FR-008**: `uv run mypy --strict .` MUST sair 0 em repo conforme (com `overrides` para `tests/`) e 1 com violação injetada (ex.: `x: list` sem param) com `FR-XXX` nomeado (D3, Q3/Q9).
- **FR-009**: `uv run mypy --strict tests/` MUST sair 0 em `tests/` com `overrides` relaxado, e `uv run mypy --strict` fora de `tests/` com `def foo(x):` sem `-> None` MUST reprovar `disallow_untyped_defs` (D4, Q4).
- **FR-010**: `uv run mypy --version` MUST ser `2.3.1` e `mypy --help` deve listar `strict` com 11 flags (D1/D3, Q1/Q3).

**Harness e CI (D9/D10)**

- **FR-011**: O sistema MUST prover oráculo `scripts/verify/f0-007-mypy.sh` com 12–16 asserções, `CANON_ORDER` 12–16, `exit 0/1/2`, `--quiet` só violações, `--list` enumera, `FKX_ORACLE_NESTED`, `EPOCHSECONDS <5s`, `2× cmp` idêntico (Q9, D9, oracle-cli.md).
- **FR-012**: `CI` `003` (`/.github/workflows/ci.yml` `for f in scripts/verify/f0-*.sh`) MUST incluir `f0-007` sem editar `ci.yml` (Q9, D9, FR-012 de 006).
- **FR-013**: CONVERGE — `specs/007-mypy/tasks.md` MUST ter zero `[ ]` quando `f0-007` sai 0 — asserido por `f0-007` `grep -E "^- \[ \]"` (ADR-015d, Q10).
- **FR-014**: Fronteira Escada — MUST NOT conter `lefthook.yml`, `pip-audit`/`trivy`, `packages/` com `pyproject.toml`, `mypy.ini` separado, `ruff.toml` separado, `ann`/`d` já cobertos por `ruff` mas `mypy` `strict` não deve ser `ignore` — qualquer presença reprova (constitution Additional Constraints, Q10, D10).
- **FR-015**: `specs/README.md` MUST conter `007` com `mypy` `✅` e `006` `✅` e `008` `⏳` — `grep -q "007.*mypy.*✅" specs/README.md` e `grep -q "006.*ruff.*✅"` (inquebrável em escala, ADR-011).
- **FR-016**: `specs/007-mypy/spec.md` e `docs/plan/research/f0-007-mypy.md` MUST estar rastreados por git (`git ls-files --error-unmatch specs/007-mypy/spec.md` 0) — `??` reprova (commit inquebrável).

### Key Entities

- **MyPy strict**: `[tool.mypy]` `python_version`/`strict`/`warn_unused_configs`/`exclude` + `[[tool.mypy.overrides]]` `module`/`disallow_untyped_defs`/`calls`/`warn_return_any`. Atributos: `python_version`, `strict`, `warn_unused_configs`, `exclude`, `overrides`.
- **MyPy cache**: `.mypy_cache/`/`.dmypy.json` efêmeros, ignorados, `exclude` regex, `mypy --no-error-summary` para determinismo.
- **Manifest**: `scripts/verify/manifest.sha256` 7 linhas (001..007) após 007, `sha256sum -c` 0.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Dev em clone limpo com `mypy 2.3.1` obtém `mypy 2.3.1` com `uv sync` e `uv run mypy --strict .` passa sem `mypy.ini` separado.
- **SC-002**: `uv run mypy --strict` reprova `disallow-untyped-defs` quando `def foo(x):` sem `-> None` fora de `tests/`, e **não** reprova em `tests/` com `overrides` — 100% observável.
- **SC-003**: `uv run mypy --version` → `2.3.1` e `mypy --help` lista `strict` com 11 flags em 100%.
- **SC-004**: `f0-007-mypy.sh` `12/16` ou `16/16` em `<5s` com `EPOCHSECONDS` e `2× cmp` idêntico 100%.
- **SC-005**: Injeção de `mypy.ini` ou `lefthook.yml` → `f0-007` reprova `FR-004`/`FR-014` em 100% (fronteira).
- **SC-006**: `for f in f0-*.sh; do "$f" --quiet || exit 1; done` inclui `f0-007` sem diff em `ci.yml` — harness 7/7 verde.
- **SC-007**: `tasks.md` zero `[ ]` quando `f0-007` sai 0 — CONVERGE (ADR-015d) via `grep -E "^- \[ \]"`.
- **SC-008**: Nenhum artefato `008–016` (`lefthook`, `packages/`) aparece no diff de `007` — fronteira 100% preservada.

## Assumptions

- `mypy 2.3.1` latest 2.x estável 2026-08-31 (upload `2026-08-15`, `>=3.10` compatível com `>=3.12,<3.14`); `ruff 0.16.5` compatível, mas deferido `D`/`ANN` em `ruff` não conflita com `mypy` `strict`.
- Python `3.12.3` local e `3.12.14` runner `setup-python@v7`; `requires-python >=3.12,<3.14` alinha `python_version 3.12`.
- `.gitignore` já ignora `.mypy_cache/` (217) e `.dmypy.json` (218) — sem edição em 007; `001` D3 sem `*.lock` preservado.
- `pyproject.toml` fonte única para `mypy`/`ruff`/`pytest`; `mypy.ini` separado rejeitado (D2).
- `mypy --strict` sem `disallow_any_expr` adicional em 007 (reavaliar em `011`).

## Dependencies

- `001` Git + branching — `.gitignore` sem `*.lock`, harness 30/30.
- `006` Ruff — `[tool.ruff]` `line-length 88` `py312` com `select` sênior, `uv.lock` com `ruff 0.16.5`, `manifest 6/6`.
- `005` Pytest — `tests/` 12 passed, `pytest` em `dev`.
- `uv 0.12.7` e `mypy 2.3.1` — elos verificados `docs/plan/research/f0-007-mypy.md` Q1/Q2 contra PyPI `2.3.1` + `mypy --help` strict + docs 132KB + `uv --help`.
- ADR-011 mapa 16 posições fixa `007 → 0.3` após `006` (0.2) antes de `008` (0.12) — escada.

## Contratos

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **008 pip-audit+Trivy** | `uv.lock` com `mypy 2.3.1` hash auditável |
| **009 Lefthook** | `mypy --strict` orquestrável via `lefthook.yml` (`uv run mypy --strict`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `mypy` em `uv.lock` para `uv run mypy --strict` determinístico em CI |
| **011 core / 012 cli** | `pyproject.toml` `[tool.mypy]` com `overrides` `tests.*` → escala para `packages/*` sem reescrever |

### Recebido de itens anteriores

| Item | Contrato recebido |
|---|---|
| `001` | `.gitignore` sem `*.lock`, harness 30/30 |
| `006` | `[tool.ruff]` `py312` com `select` sênior, `uv.lock` ruff 0.16.5, `manifest 6/6` |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **008** (`0.12`) | `pip-audit`/`trivy` + `S` reavaliado para `src/` | `S` em `tests/` foi `ignore` em 006 |
| **009** (`0.5` Lefthook) | `lefthook.yml` com `ruff` + `mypy --strict` + `pytest` | Orquestra `005`+`006`+`007` |
| **010** (`0.14`) | `mypy` em CI `uv run mypy --strict` como `required check` | Pipeline completo |
| **011** (`0.6`) | `strict` sem `overrides` para `packages/core/src` (sem `disallow_untyped_defs false`) | `tests/` foi exceção, `src/` é strict puro |

## Out of Scope

- `lefthook.yml` — `009` (Lefthook 2.1.11).
- `pip-audit`/`trivy`/`cyclonedx` — `008`.
- `packages/core`/`cli` — `011`/`012`.
- `mypy.ini`/`.mypy.ini` separado — fonte única `pyproject.toml` (D2).
- `dmypy` daemon — conveniência local, não portão (D10).

