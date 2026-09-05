# Feature Specification: Ruff 0.16.5 — linter + formatter

**Feature Branch**: `006-ruff`

**Created**: 2026-08-31

**Status**: Draft

**Input**: User description: "Fase 0, item 0.2 (006/016 na ordem de execução): Ruff 0.16.5 — linter e formatter único do monorepo via pyproject.toml [tool.ruff] com line-length 88 target-version py312, select E,F,W,C90 extend-select I,UP,B,SIM,S,C4,A,RUF ignore E501,S101,S603, via dependency-groups dev, ruff check + ruff format --check idempotente. Sem MyPy/Lefthook/packages."

**Item do plano**: 0.2 (§17 Fase 0, Itens 0.1–0.12) · **Ordem de execução**: 006 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-006-ruff.md` (decisões D1–D10, Q1–Q10, nenhuma NEEDS CLARIFICATION)
**Contrato de entrada**: `specs/005-pytest/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011, ADR-015) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor já tem `pytest` (005) para verificação TDD, mas **sem linter e sem formatter** — cada arquivo `tests/` é escrito sem regra determinística de estilo, e `pycodestyle`/`pyflakes`/`isort`/`black` ainda não existem (implementation_plan §4: `Ruff 0.16.5` substitui todos). `Ruff` (Rust, `>=3.7`) é o único linter+formatter do monorepo; `MyPy` (007) é type checker, `Lefthook` (009) orquestra, `pip-audit` (008) audita — nenhum entra em 006 (Escada, constitution Additional Constraints).

Este item entrega **exclusivamente** `ruff` via `uv`: `pyproject.toml` `[tool.ruff]` + `[tool.ruff.lint]` + `[tool.ruff.format]` (line-length 88, py312, exclude, per-file-ignores) com `select`/`extend-select` sênior, `ruff==0.16.5` em `[dependency-groups] dev`, `uv.lock` com hash, `.ruff_cache/` ignorado, `ruff check` (sem --fix) e `ruff format --check --diff` idempotentes, oráculo `f0-006-ruff.sh` 10–14 asserções. Não cria `mypy.ini`/`[tool.mypy]` (007), `lefthook.yml` (009), `pip-audit` (008) nem `packages/` (011/012), não cria `ruff.toml` separado (fonte única `pyproject.toml` D2).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (`[dependency-groups]` pin exato + `line-length`/`target-version` fixos + `ruff format` idempotente), **II** especificação precede código, **III** vermelho→verde preservado (`.sh` + `ruff check`), **V** Lei Zero (trava versionada, `.ruff_cache` ignorado, `dev` local-only), **VI** harness oráculo com 10–14 asserções novas + `ruff check`/`format` nomeando FR, **VIII** elo verificado (PyPI `ruff==0.16.5` + docs.astral.sh 129KB + `uv --help` 2026-08-31), **X** observabilidade (falha nomeia `FR-XXX`).

---

## Clarifications

### Session 2026-08-31

- Q: Criar `ruff.toml` separado além de `pyproject.toml`? → A: **Não.** `ruff.toml` tem precedência e esconderia `[tool.ruff]` — fragmenta config. Fonte única permanece `pyproject.toml` (D2, `configuration` 129KB).
- Q: `select = ["ALL"]` com 900 regras? → A: **Não.** `D`/`ANN`/`PT` exigiriam docstrings/annotations inexistentes em `tests/`, gerariam 100+ violações sem valor. `select E,F,W,C90` + `extend-select I,UP,B,SIM,S,C4,A,RUF` é sênior e estrito sem bloquear `tests/` (D3).
- Q: `ruff check --fix` automático no harness? → A: **Não.** Harness roda `ruff check` sem `--fix` e `ruff format --check --diff` sem re-escrever — apenas leitura (`oracle-cli.md`). `--fix` é conveniência local (D5).
- Q: Adicionar `mypy` junto para aproveitar `pyproject.toml`? → A: **Não.** `mypy` é `007` (`2.3.1` strict), violaria Escada e acoplaria `ruff`/`mypy` (D10). `ruff` `UP`/`I` já é compatível com `mypy` `py312` sem reescrever.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Lint e format verde em clone limpo (Priority: P1)

Desenvolvedor clona em máquina limpa (sem `.ruff_cache`) e precisa obter **lint e format** com `uv sync` + `uv run ruff check .` + `uv run ruff format --check .` — saída determinística, sem `ruff.toml` separado, com `line-length 88` e `py312`.

**Why this priority**: é o primeiro portão de estilo. Sem `ruff`, cada `tests/*.py` diverge em imports/aspas/tamanho de linha — `mypy` (007) e `lefthook` (009) validariam sobre base não formatada, e `010` (`uv sync --frozen` + `ruff` em CI) não teria lock.

**Independent Test**: `uv sync` com `ruff==0.16.5` → `uv.lock` contém `ruff`; `uv run ruff check .` 0; `uv run ruff format --check .` 0; `uv run ruff format .` segunda vez não altera hash (`sha256sum` idêntico).

**Acceptance Scenarios**:

1. **Given** clone sem `ruff` e `uv.lock` sem `ruff`, **When** `uv add --dev ruff==0.16.5` + `uv sync`, **Then** `pyproject.toml` contém `ruff==0.16.5` em `[dependency-groups] dev` e `uv.lock` contém `ruff 0.16.5` com hash, `.venv/bin/ruff` existe.
2. **Given** `pyproject.toml` com `[tool.ruff]` `line-length 88` `target-version py312`, **When** `uv run ruff check .` em repo conforme (`tests/` com imports ordenados), **Then** exit 0; **When** cria `a.py` com `import os, sys` desordenado + `x=1` sem espaço, **Then** `ruff check` reprova com `E401`/`I001`/`E231` nomeando FR.
3. **Given** `pyproject.toml` com `[tool.ruff.format]` `quote-style double`, **When** `uv run ruff format --check --diff .` em repo conforme, **Then** exit 0 com `2 files already formatted`; **When** cria `b.py` com `x='a'` (aspas simples) , **Then** `format --check` reprova com diff `-'a'` `+"a"` e `ruff format .` corrige para `"` (idempotente).
4. **Given** repo conforme, **When** `uv run ruff check .` e `uv run ruff format --check .` duas vezes, **Then** segunda saída idêntica byte-a-byte e `<5s` cada (determinismo `EPOCHSECONDS`).

---

### User Story 2 — Regras sênior e compatibilidade pytest/mypy (Priority: P2)

Arquiteto precisa que `ruff` aplique **regras sênior** `UP`/`B`/`S`/`SIM`/`C4`/`A`/`RUF`/`I` além do default `E,F,W`, mas **sem quebrar** `tests/test_harness_*.py` (que usa `assert` e `subprocess` com `FKX_ORACLE_NESTED` sem `shell=True`).

**Why this priority**: `UP` moderniza `Union` para `X|Y` (3.12), `B` pega `B006`/`B008`, `S` cobre `S603` (subprocess) — ganho sobre `flake8`. Sem `ignore` correto, `tests/` reprovaria `S101` (`assert` em teste) e `S603` (`subprocess` sem `shell` é seguro).

**Independent Test**: `uv run ruff check --output-format=concise .` lista `I001`/`UP007`/`B006` quando provocado; `grep -q 'per-file-ignores.*tests.*S101' pyproject.toml`.

**Acceptance Scenarios**:

1. **Given** `[tool.ruff.lint]` com `select = ["E","F","W","C90"]` + `extend-select = ["I","UP","B","SIM","S","C4","A","RUF"]`, **When** cria `c.py` com `from typing import Union; x: Union[int, str]` , **Then** `ruff check` sugere `UP007` `X | Y`.
2. **Given** `per-file-ignores = {"tests/**/*": ["S101","S603"]}`, **When** `ruff check tests/test_harness_debts.py` com `assert` e `subprocess.run`, **Then** não reprova `S101`/`S603` em `tests/`, mas reprovaria `S101` em `src/` futuro (fora de `tests/`).
3. **Given** `ignore = ["E501"]` (line-length), **When** cria `d.py` com linha 120 chars, **Then** `ruff check` não reprova `E501` (format cuida), mas `ruff format --check` reprova se não formatado.
4. **Given** `mypy` ainda não instalado (007), **When** `ruff check` com `target-version py312`, **Then** não gera `ANN`/`D` (docstring) porque `D` não está em `select` — evita 100+ violações sem valor em `tests/`.

---

### User Story 3 — Fronteira, cache e CONVERGE (Priority: P3)

Mantenedor roda `ruff check` + `ruff format --check` e precisa ver **fronteira** (sem `mypy`/`lefthook`/`packages`), **cache ignorado** (`.ruff_cache/`), e **CONVERGE** (`tasks.md` zero `[ ]`) — tudo via `ruff` e `f0-006-ruff.sh`, sem tocar `f0-005`.

**Why this priority**: Escada e `ADR-015d` (CONVERGE fecha lista). Sem fronteira, `006` anteciparia `mypy`/`lefthook` e quebraria `007`/`009`.

**Independent Test**: `! test -f mypy.ini && ! test -f lefthook.yml && ! test -d packages` + `git check-ignore -q .ruff_cache` + `grep -c "\[ \]" tasks.md` → 0.

**Acceptance Scenarios**:

1. **Given** `pyproject.toml` com `[tool.ruff]`, **When** `! test -f ruff.toml` e `! test -f .ruff.toml`, **Then** fonte única mantida; `ruff check` lê `pyproject.toml` sem `--config`.
2. **Given** `.gitignore` com `.ruff_cache/` e `exclude = [".ruff_cache",...]`, **When** `uv run ruff check .` cria `.ruff_cache/`, **Then** `git check-ignore -q .ruff_cache` positivo e `git status --porcelain` não lista `.ruff_cache/`.
3. **Given** `specs/006-ruff/tasks.md` com 30 tasks, **When** todas `[x]`, **Then** `f0-006-ruff.sh` `FR-013` `CONVERGE` passa; com 1 `[ ]` reprova nomeando `FR-013`.
4. **Given** `f0-006-ruff.sh`, **When** `--list` e `--quiet` e `FKX_ORACLE_NESTED=1`, **Then** `CANON_ORDER` 10–14 IDs, `exit 0/1/2`, `EPOCHSECONDS <5s`, `2× cmp` idêntico.

---

### Edge Cases

- **`ruff.toml` existe além de `pyproject.toml`.** Deve reprovar — `ruff.toml` tem precedência e esconderia `[tool.ruff]` (Q2, D2).
- **Linha 120 chars com `E501`.** Deve **não** reprovar `E501` (ignore), mas `ruff format --check` reprova se não formatado (D3/D4).
- **`assert` em `tests/` vs `src/` futuro.** `S101` ignorado em `tests/**/*` via `per-file-ignores`, mas reprovaria em `packages/core/src/` (D3, Q7).
- **`subprocess.run` sem `shell=True` em `tests/`.** `S603` ignorado em `tests/`, mas `S607` (`*` em subprocess) ainda reprovaria se `shell=True` (D3).
- **`.ruff_cache` versionado acidentalmente.** `git check-ignore -q .ruff_cache` positivo; `f0-006` reprova se `git ls-files | grep .ruff_cache` (Lei Zero).
- **`packages/` criado sem `pyproject.toml` lá dentro.** `f0-006` deve reprovar se `packages/` existir — é `011`/`012`, não `006` (Fronteira).
- **Máquina com `ruff` 0.15.x global.** `uv run ruff --version` em `.venv` deve ser `0.16.5` — local converge ao pin (D1).
- **`uv run ruff format` idempotente.** Segunda `format` sem mudança não altera hash `sha256sum` (D5, Q10).

---

## Requirements *(mandatory)*

### Functional Requirements

**Artefato raiz e descoberta (D2)**

- **FR-001**: O sistema MUST declarar `ruff==0.16.5` (exato) em `[dependency-groups] dev` em `pyproject.toml` (PEP 735, `uv add --dev ruff==0.16.5`), sem `ruff` em `[project.dependencies]` nem `requirements*.txt` (D1/D6).
- **FR-002**: O sistema MUST prover `[tool.ruff]` em `pyproject.toml` com `line-length = 88` e `target-version = "py312"` e `exclude = [".git", ".hg", ".mypy_cache", ".pytest_cache", ".ruff_cache", ".venv", ...]` (D4, Q2/Q8).
- **FR-003**: O sistema MUST prover `[tool.ruff.lint]` com `select = ["E","F","W","C90"]` e `extend-select = ["I","UP","B","SIM","S","C4","A","RUF"]` e `ignore = ["E501","S101","S603"]` e `per-file-ignores = {"tests/**/*": ["S101","S603"]}` (D3, Q3/Q7).
- **FR-004**: O sistema MUST prover `[tool.ruff.format]` com `quote-style = "double"` e `indent-style = "space"` e `line-ending = "auto"` e `docstring-code-format = false` (D4, Q4).
- **FR-005**: O sistema MUST NOT prover `ruff.toml` nem `.ruff.toml` separado — fonte única é `pyproject.toml` (D2, Q2).

**Trava e cache (D6/D8)**

- **FR-006**: O sistema MUST conter `ruff` com hash em `uv.lock` (`grep 'name = "ruff"'` + `tomllib` válido + `uv lock --check` quando `uv` presente) (D1/D6, Q1).
- **FR-007**: `.ruff_cache/` MUST ser ignorado por git (`git check-ignore -q .ruff_cache` positivo e `! git ls-files | grep .ruff_cache`) e `uv.lock` MUST NOT ser ignorado (D8, Q8, `.gitignore` 254).

**Lint/format determinísticos (D5)**

- **FR-008**: `uv run ruff check .` MUST sair 0 em repo conforme e 1 com violação injetada (ex.: `import os, sys` desordenado) com `FR-XXX` nomeado via `concise` (D5, Q5/Q9).
- **FR-009**: `uv run ruff format --check --diff .` MUST sair 0 em repo conforme e 1 com diff quando `x='a'` (aspas simples) com `FR-XXX` (D5, Q5/Q10).
- **FR-010**: `uv run ruff format .` MUST ser idempotente — segunda `format` não altera `sha256sum` de `tests/*.py` (D5, Q10).

**Harness e CI (D9/D10)**

- **FR-011**: O sistema MUST prover oráculo `scripts/verify/f0-006-ruff.sh` com 10–14 asserções, `CANON_ORDER` 10–14, `exit 0/1/2`, `--quiet` só violações, `--list` enumera, `FKX_ORACLE_NESTED`, `EPOCHSECONDS <5s`, `2× cmp` idêntico (Q9, D9, oracle-cli.md).
- **FR-012**: `CI` `003` (`/.github/workflows/ci.yml` `for f in scripts/verify/f0-*.sh`) MUST incluir `f0-006` sem editar `ci.yml` (Q9, D9, FR-012 de 005).
- **FR-013**: CONVERGE — `specs/006-ruff/tasks.md` MUST ter zero `[ ]` quando `f0-006` sai 0 — asserido por `f0-006` `grep -E "^- \[ \]"` (ADR-015d, Q10).
- **FR-014**: Fronteira Escada — MUST NOT conter `[tool.mypy]`/`mypy.ini`, `lefthook.yml`, `pip-audit`/`trivy`, `packages/` com `pyproject.toml`, `ruff.toml` separado, nem `ann`/`d` em `select` (`D` pydocstyle) — qualquer presença reprova (constitution Additional Constraints, Q10, D10).

### Key Entities

- **Ruff linter**: `[tool.ruff.lint]` `select`/`extend-select`/`ignore`/`per-file-ignores` + `exclude`. Atributos: `line-length`, `target-version`, `select`, `extend-select`, `ignore`, `per-file-ignores`.
- **Ruff formatter**: `[tool.ruff.format]` `quote-style`/`indent-style`/`line-ending`/`docstring-code-format`. Atributos: `quote-style`, `indent-style`, `line-ending`, `docstring-code-format`.
- **Ruff cache**: `.ruff_cache/` efêmero, ignorado, `exclude` default, `ruff check --no-cache` para determinismo.
- **Manifest**: `scripts/verify/manifest.sha256` 6 linhas (001..006) após 006, `sha256sum -c` 0.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Dev em clone limpo com `uv 0.16.5` obtém `ruff 0.16.5` com `uv sync` e `uv run ruff check .` + `format --check .` passam sem `ruff.toml` separado.
- **SC-002**: `uv run ruff check --output-format=concise .` lista `I001`/`UP007`/`B006` quando provocado, e `E501` **não** lista quando linha 120 chars (ignore) — 100% observável.
- **SC-003**: `uv run ruff format .` segunda vez não altera `sha256sum` de `tests/*.py` em 100% (idempotente).
- **SC-004**: `f0-006-ruff.sh` `12/12` ou `14/14` em `<5s` com `EPOCHSECONDS` e `2× cmp` idêntico 100%.
- **SC-005**: Injeção de `ruff.toml` ou `mypy.ini` → `f0-006` reprova `FR-005`/`FR-014` em 100% (fronteira).
- **SC-006**: `for f in f0-*.sh; do "$f" --quiet || exit 1; done` inclui `f0-006` sem diff em `ci.yml` — harness 6/6 verde.
- **SC-007**: `tasks.md` zero `[ ]` quando `f0-006` sai 0 — CONVERGE (ADR-015d) via `grep -E "^- \[ \]"`.
- **SC-008**: Nenhum artefato `007–016` (`mypy`, `lefthook`, `packages/`) aparece no diff de `006` — fronteira 100% preservada.

## Assumptions

- `ruff 0.16.5` latest estável 2026-08-31 (simple index `0.16.5` upload `2026-08-27`, `>=3.7` compatível com `>=3.12,<3.14`); `mypy 2.3.1` `>=3.10` compatível, mas deferido a 007.
- Python `3.12.3` local e `3.12.14` runner `setup-python@v7`; `requires-python >=3.12,<3.14` alinha `target-version py312`.
- `.gitignore` já ignora `.ruff_cache/` (254) — sem edição em 006; `001` D3 (sem `*.lock`) preservado.
- `pyproject.toml` fonte única para `ruff`/`pytest`/`coverage`; `ruff.toml` separado rejeitado (D2).
- `ruff format` idempotente e `check` sem `--fix` no harness (D5).

## Dependencies

- `001` Git + branching — `.gitignore` sem `*.lock`, harness 30/30.
- `005` Pytest — `[dependency-groups] dev` com `pytest==9.1.1`, `tests/` 11 passed, `manifest 5/5`, `uv.lock` com `pytest`.
- `uv 0.12.7` e `ruff 0.16.5` — elos verificados `docs/plan/research/f0-006-ruff.md` Q1/Q2 contra PyPI simple index + docs.astral.sh 129KB + `uv --help`.
- ADR-011 mapa 16 posições fixa `006 → 0.2` após `005` (0.4) antes de `007` (0.3) — escada.

## Contratos

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **007 MyPy 2.3.1** | `[tool.ruff]` `line-length 88` `py312` estável onde `[tool.mypy]` coexistirá; `UP`/`I` não conflitam com `mypy strict` |
| **008 pip-audit+Trivy** | `uv.lock` com `ruff 0.16.5` hash auditável; `S` já cobre `subprocess`/`assert` |
| **009 Lefthook** | `ruff check`/`format` orquestráveis via `lefthook.yml` (`uv run ruff check --fix`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `ruff` em `uv.lock` para `uv run ruff check` determinístico em CI; `format --check` idempotente |
| **011 core / 012 cli** | `per-file-ignores` `tests/**/*` `S101,S603` → escala para `packages/*/tests` sem reescrever |

### Recebido de itens anteriores

| Item | Contrato recebido |
|---|---|
| `001` | `.gitignore` sem `*.lock`, harness 30/30 |
| `005` | `[dependency-groups] dev` com `pytest 9.1.1`, `tests/` 11 passed, `manifest 5/5`, `uv.lock` pytest |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **007** (`0.3` MyPy) | `mypy.ini`/`[tool.mypy]` strict `python_version 3.12` + `per-file-ignores` complementares | Só existe com `mypy` 2.3.1; `ruff` `UP` já compatível |
| **009** (`0.5` Lefthook) | `lefthook.yml` com `ruff check`/`ruff format` + `pytest` | Orquestra `005`+`006` |
| **008** (`0.12`) | `S` reavaliado para `src/` + `pip-audit`/`trivy` | `S` em `tests/` foi `ignore` em 006 |
| **010** (`0.14`) | `ruff` em CI `uv run ruff check` + `format --check` como `required check` | Pipeline completo |

## Out of Scope

- `mypy.ini`/`[tool.mypy]`/`dmypy` — `007` (MyPy 2.3.1 strict).
- `lefthook.yml` — `009` (Lefthook 2.1.11).
- `pip-audit`/`trivy`/`cyclonedx` — `008`.
- `packages/core`/`cli` — `011`/`012`.
- `ruff.toml`/`.ruff.toml` separado — fonte única `pyproject.toml` (D2).
- `D`/`ANN`/`PT` rules — deferidos (sem docstrings/annotations em `tests/`).

