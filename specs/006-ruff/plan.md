# Implementation Plan: Ruff 0.16.5 — linter + formatter

**Branch**: `006-ruff` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-ruff/spec.md`
**Pesquisa vinculante**: `docs/plan/research/f0-006-ruff.md` (Q1–Q10, D1–D10, 2026-08-31, sem NEEDS CLARIFICATION)
**Constitution**: `.specify/memory/constitution.md` v1.0.0 (10 princípios I–X)

---

## Summary

Entregar **o linter e formatter único do monorepo** (implementation_plan §§3,15,17 item 0.2, ordem 006/016 ADR-011): `pyproject.toml` `[tool.ruff]` `line-length 88` `target-version py312` `exclude=[.git,...,.ruff_cache,.venv]` + `[tool.ruff.lint]` `select E,F,W,C90` `extend-select I,UP,B,SIM,S,C4,A,RUF` `ignore E501,S101,S603` `per-file-ignores tests/**/* S101,S603` + `[tool.ruff.format]` `quote-style double` `indent-style space` + `ruff==0.16.5` em `[dependency-groups] dev` com `pytest 9.1.1` coexistindo + `uv.lock` com hash + `.ruff_cache/` ignorado + `uv run ruff check .` (sem --fix) e `uv run ruff format --check --diff .` idempotentes + oráculo `f0-006-ruff.sh` 10–14 asserções. Sem `mypy`/`lefthook`/`pip-audit`/`packages/` nem `ruff.toml` separado (Escada). É a base de estilo determinística para `007` (`mypy` `py312`) e `009` (`lefthook` orquestra). Plano é transcrição fiel de D1–D10 verificadas contra PyPI `ruff 0.16.5` simple index + docs.astral.sh 129KB/737KB + `uv --help` 2026-08-31; nenhum desenho novo.

---

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (família `3.12`; local `3.12.3`, runner `3.12.14` via `setup-python@v7`) + TOML (pyproject/uv.lock) + bash (oráculo) + Ruff 0.16.5 (Rust, `>=3.7`). `uv` `0.12.7` binário (pin §4, PyPI 2026-08-31; local `0.12.1` converge).

**Primary Dependencies**: `ruff==0.16.5` (Rust, sem `requires_dist`), `pytest==9.1.1` `pytest-asyncio==1.4.0` `pytest-cov==7.1.0` já em `dev` (005), `uv_build>=0.12.7,<0.13`. Nenhum `mypy 2.3.1`, `lefthook 2.1.11` em 006 (FR-014, Escada).

**Storage**: Sistema de arquivos. Artefatos: `pyproject.toml` (raiz, `[tool.ruff.*]`), `uv.lock` (raiz, TOML universal com `ruff` hash), `.ruff_cache/` (raiz, cache efêmero, `exclude` + `.gitignore` 254), `scripts/verify/f0-006-ruff.sh` (oráculo). `.pytest_cache`/`htmlcov`/`.coverage` já existem (005).

**Testing**: `uv run ruff check .` (linter) + `uv run ruff format --check --diff .` (formatter idempotente) + `uv run ruff check --output-format=concise` (parseável) + oráculo `f0-006-ruff.sh` 10–14 asserções (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER`, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`) + `ruff check --no-cache` para determinismo. `pytest` (`f0-005`) deve continuar 11 passed (`self-check`).

**Target Platform**: Filesystem POSIX (Linux `ubuntu-24.04` runner + local), macOS/Windows cobertos por lock universal. CI `003` `for f in f0-*.sh` + `010` futuro `uv run ruff check` determinístico.

**Project Type**: Infraestrutura de qualidade — linter+formatter. Não produz biblioteca nem CLI além do verificador.

**Performance Goals**: `uv sync` com `ruff` <2min; `uv run ruff check .` <1s em `tests/` (11 arquivos), `uv run ruff format --check .` <1s; `ruff format .` idempotente `sha256sum` idêntico 100%; `f0-006` <5s `EPOCHSECONDS` `2× cmp`.

**Constraints**:
- Escada (constitution Additional Constraints): nenhum artefato pode exigir `mypy`/`lefthook`/`pip-audit` — impõe FR-014 negativo.
- Determinismo (I): `[dependency-groups]` pin exato `0.16.5`, `line-length 88` `py312` fixos, `ruff format` idempotente, `exclude` determinístico, `EPOCHSECONDS` sem `date`, `sha256sum`.
- Lei Zero (V): `uv.lock` versionado, `.ruff_cache` ignorado, `dev` local-only, sem `*.lock` em `.gitignore`.
- Fidelidade ao oráculo (VI): harness cresce por acréscimo (`f0-006` sem tocar `f0-005`..01), `manifest.sha256` 6 linhas aditivo, `CONVERGE` zero `[ ]`.
- Escopo da máquina: nada global, identidade em `.git/config` local.
- Sem privilégio elevado: não exige `sudo`/`admin`.

**Scale/Scope**: 14 FRs, 8 SCs, 3 US (P1–P3), 8 edge cases. `pyproject.toml` + `uv.lock` alterados + `.ruff_cache/` efêmero + 1 oráculo. `tests/` 11 arquivos já existentes, `ruff` deve lintar sem reprovar `S101`/`S603` em `tests/` via `per-file-ignores`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Princípios avaliados contra v1.0.0:**

| Princípio | Critério de violação | Avaliação neste plano |
|---|---|---|
| **I Determinismo sobre probabilidade** | decisão sem regra determinística validando modelo | ✅ PASS — `ruff==0.16.5` exato (D1), `line-length 88` `py312` fixos (D4), `ruff format` idempotente (D5), `select`/`extend-select` determinísticos (D3), `EPOCHSECONDS` sem `date`. |
| **II Especificação precede código** | artefato sem spec prévia | ✅ PASS — `spec.md` 205 linhas 14 FRs/8 SCs existe antes deste plano; nenhum `[tool.ruff]` criado ainda (`grep -q "tool.ruff" pyproject.toml` falha, Q1/Q2). |
| **III Teste antes da implementação** | sem par vermelho→verde | ✅ PASS — Fase B gera `f0-006` reprovando (vermelho) antes de Fase C `ruff` verde; `ruff check`/`format` reprovando antes, 0 depois; `evidence/red.txt`/`green.txt`. |
| **IV Definição de dados antes da implementação** | componente sem contrato | ✅ PASS — `data-model.md` declara entidades Ruff linter/formatter/cache/manifest; `contracts/ruff-contract.md` + `oracle-cli.md` fixam schemas. |
| **V Segurança é a Lei Zero** | segredo ou trava coberta | ✅ PASS — `uv.lock` versionado (FR-006), `.ruff_cache` ignorado (FR-007), `dev` local-only, nenhum segredo; `001` D3 sem `*.lock` preservado. |
| **VI O harness é o oráculo** | critério sem asserção ou diff altera anterior | ✅ PASS — FR-001..014 têm asserção 1:1 em `f0-006` (10–14); plano proíbe tocar `f0-005`..01 (hashes `e39a1f1c…` etc. em `manifest.sha256`); `ruff check`/`format` verificam, não re-escrevem. |
| **VII Auto-reparo atualiza a documentação** | correção sem alteração normativa | ✅ PASS — plano não corrige falha prévia; se falhar, reparo exigirá `spec.md`/`decisions.md` update. |
| **VIII Elo verificado antes de lógica** | código consome serviço sem verificação | ✅ PASS — Q1–Q10 verificados 2026-08-31 contra PyPI simple index `0.16.5` + docs.astral.sh 129KB/737KB + `uv --help`/`python --version` locais; D1–D10 citam fonte+bytes. |
| **IX Agnosticismo de stack** | referência a stack-alvo fora de adaptador | ✅ PASS — `ruff` é infra do motor (Fase 0 bootstrap), não do sistema-alvo; não assume linguagem/framework do alvo. |
| **X Observabilidade** | falha sem REQ-ID ou evidência | ✅ PASS — cada asserção `f0-006` imprime `🔴 FR-XXX` com evidência (`tomllib` parse, `git check-ignore`, `ruff check` concise, `sha256sum`); SC-002 exige lista `I001`/`UP007` nomeada. |

**Additional Constraints:**

| Constraint | Avaliação |
|---|---|
| Escada de dependências | ✅ Só `ruff` além de `pytest`+`uv`+stdlib; nenhum `mypy`/`lefthook`/`pip-audit` (FR-014). |
| Escopo da máquina | ✅ Nenhuma escrita global. |
| Cadeia de suprimentos | ✅ `uv.lock` com `ruff` hash versionado. |
| Ambiente sob demanda | ✅ Sem Docker; `ruff check` on-demand. |
| Sem privilégio elevado | ✅ Nenhum `sudo`. |

**Veredito pré-Phase 0**: **PASS** — nenhum gate bloqueante, nenhum NEEDS CLARIFICATION.

**Re-avaliação pós-Phase 1**: **PASS** — `research.md` consolida D1–D10, `data-model.md`/`contracts/`/`quickstart.md` não introduzem dependência nova nem violam escada; `ruff` + `pytest` coexistem em `dev`.

---

## Project Structure

### Documentation (this feature)

```text
specs/006-ruff/
├── spec.md              # Concluído (205 linhas, 14 FRs, 8 SCs)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — Q1–Q10 → D1–D10 (consolida docs/plan/research/f0-006-ruff.md)
├── data-model.md        # Phase 1 — entidades Ruff linter / formatter / cache / manifest
├── quickstart.md        # Phase 1 — 6 cenários (clone limpo, rules sênior, idempotente, fronteira, CONVERGE, CI)
├── contracts/
│   ├── ruff-contract.md         # Phase 1 — contrato ruff (pyproject.toml schema, exclude, per-file-ignores)
│   └── oracle-cli.md            # Phase 1 — contrato oráculo 006 (CANON 10–14 + manifest 6 linhas)
├── checklists/
│   └── requirements.md  # (gerado, 12/12 PASS)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item produz **2 arquivos versionados alterados + 1 cache efêmero + 1 oráculo**; não produz `mypy`/`lefthook`/`packages/`:

```text
fluksos-x/
├── pyproject.toml                     # ALTERADO — acrescenta [tool.ruff] + [tool.ruff.lint] + [tool.ruff.format] (FR-002..004)
│                                      # já contém [dependency-groups] dev com pytest (005) + ruff 0.16.5 (006)
├── uv.lock                            # ALTERADO — acrescenta ruff 0.16.5 com hash (FR-006)
├── .ruff_cache/                       # NOVO efêmero — cache ruff, ignorado via .gitignore 254 + exclude (FR-007)
├── scripts/verify/
│   ├── manifest.sha256                # ALTERADO — 6 linhas (001..006) sha256sum -c 0 (FR-008)
│   ├── f0-006-ruff.sh                 # NOVO — oráculo deste item (10–14 asserções, FR-001..014)
│   ├── README.md                      # ALTERADO — registra f0-006 (T031)
│   ├── f0-005-pytest.sh               # INTOCADO — hash e39a1f1c… (manifest)
│   └── f0-001..004                    # INTOCADOS
├── tests/                             # EXISTE — 11 passed, ruff deve lintar com per-file-ignores S101/S603
│   ├── conftest.py
│   ├── test_harness_oracles.py
│   └── test_harness_debts.py
├── .gitignore                         # INTOCADO — já cobre .ruff_cache/ 254
├── .github/workflows/ci.yml           # INTOCADO — 003 glob for f0-*.sh inclui f0-006 sem editar
├── docs/plan/research/
│   └── f0-006-ruff.md                 # JÁ EXISTE — pesquisa vinculante 376 linhas
└── specs/006-ruff/                    # NOVO
```

**Structure Decision**: `[tool.ruff]` em `pyproject.toml` segue `docs.astral.sh/ruff/configuration` (fonte única, sem `ruff.toml` separado D2). `manifest.sha256` 6 linhas segue ADR-015a. Oráculo `f0-006-ruff.sh` segue ADR-002. `exclude` replica default ruff + `.gitignore` 254. Não há `src/` porque linter é infra.

---

## Fases de execução

> Ordem normativa: vermelho antes do verde (III); `ruff==0.16.5` em `[dependency-groups]` antes de `uv sync`; `ruff.toml` ausente verificado antes de `[tool.ruff]`; `ruff format` idempotente após `ruff check` 0, porque format sem lint verde esconderia estilo vs correção.

### Fase A — Preparação

1. Confirmar harness verde: `for f in f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com `f0-001` 30/30 `f0-002` 33/33 `f0-003` 14/14 `f0-004` 14/14 `f0-005` 15/15 + `uv run pytest -q` 11 passed.
2. Confirmar ausência de `[tool.ruff]` (`! grep -q "tool.ruff" pyproject.toml`), ausência de `ruff.toml`/`ruff` em `uv.lock` (`! grep -q 'name = "ruff"' uv.lock`), e `.gitignore` já cobre `.ruff_cache`.
3. Medir hashes `sha256sum f0-*.sh` (devem bater `63412ca7…` `b63ac3c8…` `d10c61…` `42e2d36…` `e39a1f1c…`).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-006-ruff.sh` com contrato `oracle-cli.md` (`0`/`1`/`2`, `--quiet`/`--list`, `CANON_ORDER` 10–14, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`).
2. Cobrir FR-001..014 1:1 (10–14 asserções):
   - FR-001: `[dependency-groups] dev` contém `ruff==0.16.5` exato, sem `ruff` em `[project.dependencies]`.
   - FR-002: `[tool.ruff]` `line-length 88` `target-version py312` `exclude` lista.
   - FR-003: `[tool.ruff.lint]` `select`/`extend-select` `ignore`/`per-file-ignores` sênior.
   - FR-004: `[tool.ruff.format]` `quote-style` etc., `ruff.toml` não existe.
   - FR-005: `! test -f ruff.toml` (fonte única).
   - FR-006: `uv.lock` contém `ruff` + `tomllib` + `uv lock --check`.
   - FR-007: `.ruff_cache` gitignored, `uv.lock` não.
   - FR-008: `uv run ruff check .` 0 em conforme (quando ruff instalado, senão apenas verifica config).
   - FR-009: `uv run ruff format --check --diff .` 0 e idempotente.
   - FR-010: `ruff format .` idempotente `sha256sum` (segunda não altera).
   - FR-011: oráculo self-check `0/1/2` `quiet` `list` `determinismo` `2× cmp` `<5s`.
   - FR-012: CI glob `for f` inclui `f0-006`.
   - FR-013: CONVERGE `grep -E "^- \[ \]" tasks.md` 0.
   - FR-014: fronteira `! [tool.mypy]` etc.
3. Executar e preservar `evidence/red.txt` — deve reprovar (6–8/14) por ausência de `ruff`.
4. Conferir `--list` enumera 10–14 IDs.

### Fase C — Ruff verde 🟢

1. Materializar `ruff` via `uv`:

```bash
uv add --dev ruff==0.16.5
uv sync  # ruff em .venv/bin/ruff, uv.lock com hash
```

Fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub + `[tool.ruff]` TOML válido.

2. Acrescentar `[tool.ruff]` + `[tool.ruff.lint]` + `[tool.ruff.format]` em `pyproject.toml` conforme `contracts/ruff-contract.md` (D3/D4).
3. Validar `uv run ruff check .` 0 em `tests/` (com `per-file-ignores` S101/S603) e `uv run ruff format --check .` 0.
4. Gerar `manifest.sha256` 6 linhas: `sha256sum f0-001..006 > manifest.sha256` + `sha256sum -c` 0.
5. Atualizar `README.md` (+`f0-006` 10–14).

### Fase D — Verde e convergência local

1. `f0-006-ruff.sh --quiet` → `0`; `evidence/green.txt`.
2. `uv run ruff check .` 0 + `uv run ruff format --check .` 0 + `ruff format .` idempotente `sha256sum` (SC-003).
3. `2× cmp` determinismo + `<5s` `EPOCHSECONDS`.
4. `for f in f0-*.sh; do "$f" --quiet || exit 1; done` → `0` (6/6) + `uv run pytest -q` 11 passed (pytest 005 ainda verde).
5. `grep -E "^- \[ \]" tasks.md` → 0.

### Fase E — Entrega remota (pós-merge)

1. Push `main` conforme → `verify` verde inclui `f0-006`.
2. Injetar `ruff.toml` ou `mypy.ini` → PR `verify` vermelho `FR-005`/`FR-014`.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | `ruff==0.16.5` via `[dependency-groups] dev` | FR-001/006 | Q1 simple index 2026-08-27 |
| D2 | `pyproject.toml` `[tool.ruff.*]` fonte única, sem `ruff.toml` | FR-002..005 | Q2 docs/configuration 129KB |
| D3 | `select E,F,W,C90` + `extend-select I,UP,B,SIM,S,C4,A,RUF` `ignore E501,S101,S603` `per-file-ignores tests/**/* S101,S603` | FR-003 | Q3 rules/ 737KB |
| D4 | `line-length 88` `target-version py312` `exclude=[.git,...,.ruff_cache,.venv]` + `format double` | FR-002/004 | Q4 docs/formatter |
| D5 | `uv run ruff check` / `format --check --diff` idempotente, sem `--fix` no harness | FR-008..010 | Q5 docs/linter |
| D6 | `uv add --dev ruff==0.16.5` → `dev` com `pytest`+`ruff` | FR-001/006 | Q6 uv docs |
| D7 | `S` bandit como portão, `pip-audit` deferido 008 | FR-003 | Q7 bandit |
| D8 | `exclude` replica default + `tests/` lintado | FR-002/007 | Q8 docs |
| D9 | Harness `f0-006-ruff.sh` 10–14 asserções só ruff | FR-011 | Q9 oracle-cli |
| D10 | Determinismo `ruff format` idempotente, compat `mypy` UP/I, fronteira 006 só ruff | FR-014 | Q10 constitution |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `ruff.toml` esconde `[tool.ruff]` | Alto — config duplicada | FR-005 `! test -f ruff.toml` + `strict-config` |
| `select ALL` com `D`/`ANN` | Alto — 100+ violações sem valor em `tests/` | D3 `select` sênior sem `D`/`ANN`, deferidos 007+ |
| `E501` vs `format` conflito | Médio — line-length duplicado | D3 `ignore E501`, `format` cuida |
| `S101`/`S603` em `tests/` | Alto — `assert`/`subprocess` reprova sem `per-file-ignores` | D3 `per-file-ignores` |
| `mypy` adiantado em 006 | Alto — Escada | FR-014 `! [tool.mypy]` |
| `uv 0.12.1` com `ruff` | Médio — lock diverge | D1 `uv self update` em quickstart |
| `ruff format` não idempotente | Alto — `sha256sum` muda segunda vez | D5 `format --check` idempotente asserido |
| `.ruff_cache` versionado | Alto — cache no histórico | FR-007 `check-ignore` + `exclude` |

---

## Complexity Tracking

> Nenhuma violação de Constitution Check a justificar.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |
