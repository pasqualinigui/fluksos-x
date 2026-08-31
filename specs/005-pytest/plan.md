# Implementation Plan: Pytest 9.1.1 — harness TDD

**Branch**: `005-pytest` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-pytest/spec.md`
**Pesquisa vinculante**: `docs/plan/research/f0-005-pytest.md` (Q1–Q10, D1–D10, 2026-08-31, sem NEEDS CLARIFICATION)
**Constitution**: `.specify/memory/constitution.md` v1.0.0 (10 princípios I–X)

---

## Summary

Entregar **o harness TDD** (implementation_plan §§3,15,17 item 0.4, ordem 005/016 ADR-011): `pyproject.toml` com `[dependency-groups] dev = ["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]` + `[tool.pytest.ini_options]` (`minversion 9.1`, `testpaths ["tests"]`, `addopts "-ra --strict-markers --strict-config"`, `asyncio_mode strict`) + `[tool.coverage.*]` (`branch true`, relatório sem portão) + `tests/conftest.py` + `tests/test_harness_oracles.py` (parametrizado por `f0-*.sh` com `FKX_ORACLE_NESTED`) + `tests/test_harness_debts.py` (5 casos ADR-007) + `scripts/verify/manifest.sha256` 5 linhas + oráculo `f0-005-pytest.sh` 12–16 asserções. Sem `ruff`/`mypy`/`lefthook`/`pip-audit`/`trivy` nem `packages/` nem `pytest.toml` separado (Escada). É a promoção determinística dos oráculos shell a pytest + o manifesto que fecha a cadeia A1 e o pagamento das dívidas SC-003/SC-004/SC-007/FR-001. Plano é transcrição fiel de D1–D10 verificadas contra PyPI `pytest 9.1.1` (2026-06-19) + docs.pytest.org 51KB + docs.astral.sh 169KB + `uv --help` local em 2026-08-31; nenhum desenho novo.

---

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (família `3.12`; local `3.12.3`, runner `3.12.14` via `setup-python@v7`) + TOML (pyproject/uv.lock) + bash (oráculo) + pytest 9.1.1. `uv` `0.12.7` binário (pin §4, PyPI 2026-08-31; local `0.12.1` converge via `uv self update`).

**Primary Dependencies**: `pytest==9.1.1`, `pytest-asyncio==1.4.0` (`pytest<10,>=8.4`), `pytest-cov==7.1.0` (`coverage[toml]>=7.10.6` → `coverage 7.16.0`), `pluggy 1.6.0`, `iniconfig 2.3.0` (transitivos, não pinados). `uv_build>=0.12.7,<0.13` em `build-system`. Nenhum `ruff 0.16.5`, `mypy 2.3.1`, `lefthook 2.1.11` em 005 (FR-015, Escada).

**Storage**: Sistema de arquivos. Artefatos: `pyproject.toml` (raiz, `[dependency-groups]` + `[tool.pytest.ini_options]` + `[tool.coverage.*]`), `uv.lock` (raiz, TOML universal com `pytest` hash), `tests/conftest.py`, `tests/test_harness_oracles.py`, `tests/test_harness_debts.py`, `scripts/verify/manifest.sha256` (5 linhas), `scripts/verify/f0-005-pytest.sh` (oráculo). `.pytest_cache/` e `htmlcov/` efêmeros, já gitignored (`.gitignore` 86–99).

**Testing**: `uv run pytest -q` (oráculo `f0-005-pytest.sh` com 12–16 asserções, exit `0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER`) + `pytest --co -q` (coleção) + `sha256sum -c manifest.sha256` integridade + `time.monotonic` determinismo. `pytest` é o teste de `pytest` (self-hosting). Harness bash permanece fonte de verdade; pytest só orquestra via `subprocess` (`FKX_ORACLE_NESTED=1`).

**Target Platform**: Filesystem POSIX (Linux `ubuntu-24.04` runner + local), macOS/Windows cobertos por lock universal (cross-platform markers). CI `003` job `verify` já cobre runner via glob `f0-*.sh`.

**Project Type**: Infraestrutura de qualidade — harness TDD. Não produz biblioteca nem CLI executável além do verificador.

**Performance Goals**: `uv sync` com `pytest` em clone limpo <2 min; `uv run pytest -q` <5s (SC-003, SC-006, cada oráculo <5s via `EPOCHSECONDS`/`time.monotonic`); `sha256sum -c` <1s; `pytest --co -q` enumera ≥5 casos; 100% determinismo byte-a-byte 2× execuções.

**Constraints**:
- Escada (constitution Additional Constraints): nenhum artefato pode exigir `ruff`/`mypy`/`lefthook`/`pip-audit` — impõe FR-015 negativo.
- Determinismo (I): `[dependency-groups]` pin exato, `minversion 9.1`, `strict-markers`/`strict-config`, `testpaths=["tests"]`, `asyncio_mode strict`, `EPOCHSECONDS` sem `date +%s`, `sha256sum` nativo.
- Lei Zero (V): `uv.lock` versionado (D1), `tests/` nunca introduz segredo, `.pytest_cache`/`htmlcov`/`.coverage` ignorados, `dev` local-only (não publicado).
- Fidelidade ao oráculo (VI): harness cresce por acréscimo (`f0-005` sem tocar `f0-001`..04), `manifest.sha256` 5 linhas aditivo, mapa FR em `contracts/oracle-cli.md` quando não identidade, CONVERGE zero `[ ]` asserido por `f0-005`.
- Escopo da máquina: nada escreve em config global, identidade em `.git/config` local.
- Sem privilégio elevado: não exige `sudo`/`admin`.

**Scale/Scope**: 15 FRs, 8 SCs, 3 US (P1–P3), 8 edge cases. Dois arquivos `tests/*.py` + `conftest.py` + `manifest.sha256` + 1 oráculo. Suite ~9 casos pytest (4 oráculos parametrizados + 5 dívidas) + 91 asserts herdados via `subprocess`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Princípios avaliados contra v1.0.0 (cada um com Violation/Source rotulados):**

| Princípio | Critério de violação | Avaliação neste plano |
|---|---|---|
| **I Determinismo sobre probabilidade** | decisão sem regra determinística validando modelo | ✅ PASS — pin `pytest==9.1.1` exato (D1), `[dependency-groups]` PEP 735 determinístico, `minversion`/`strict-markers`/`strict-config`/`testpaths` (D9), `asyncio strict` (D3), `EPOCHSECONDS`/`time.monotonic` sem `date` (D7), `sha256sum` nativo (D8), `pythonpath=["."]`. |
| **II Especificação precede código** | artefato sem spec prévia ou spec pós-código | ✅ PASS — `spec.md` 217 linhas com 15 FRs/8 SCs existe antes deste plano; nenhum `tests/`/`manifest`/`f0-005` criado ainda (verificado `ls tests/ → inexistente`, `manifest.sha256 inexistente` 2026-08-31). |
| **III Teste antes da implementação** | sem par vermelho→verde preservado | ✅ PASS — Fase B gera `f0-005` reprovando (vermelho) antes de Fase C materializar pytest verde; `tests/test_harness_oracles.py` coleta mas reprova sem `pyproject.toml`; evidências `evidence/red.txt`/`green.txt` versionadas. |
| **IV Definição de dados antes da implementação** | componente sem contrato de entrada/saída | ✅ PASS — `data-model.md` (Phase 1) declara entidades Harness pytest / Manifest / Oracle promotion / Dependency-group dev com atributos e validações; `contracts/pytest-contract.md` e `contracts/oracle-cli.md` fixam schemas. |
| **V Segurança é a Lei Zero** | segredo no histórico ou exclusão cobrindo trava | ✅ PASS — `uv.lock` versionado (FR-006), `.pytest_cache`/`htmlcov`/`.coverage` ignorados (FR-007, .gitignore 86–99), `dev` local-only (não publicado), nenhum segredo introduzido; `001` D3 (sem `*.lock`) preservado. |
| **VI O harness é o oráculo** | critério sem asserção ou diff altera oráculo anterior | ✅ PASS — FR-001..015 têm asserção 1:1 em `f0-005` (12–16); plano proíbe tocar `f0-001`..04 (hashes `63412ca7…` etc. em `manifest.sha256`); `sha256sum -c` prova integridade, não só aprovação; `f0-005` self-check total `001..004 --quiet`. |
| **VII Auto-reparo atualiza a documentação** | correção sem alteração normativa | ✅ PASS — plano paga dívidas ADR-007/015 com documentação (`manifest`, `contracts/oracle-cli.md`, `tests/test_harness_debts.py`); se falhar, reparo exigirá `spec.md`/`decisions.md` update por ciclo. |
| **VIII Elo verificado antes de lógica** | código consome serviço sem verificação em research | ✅ PASS — Q1–Q10 verificados 2026-08-31 contra PyPI `pytest/json`/`1.4.0`/`7.1.0` (HTTP 200) + docs.pytest.org 51KB + docs.astral.sh 169KB + `uv --help`/`python --version` locais; D1–D10 citam fonte + bytes. |
| **IX Agnosticismo de stack** | referência a stack-alvo fora de adaptador | ✅ PASS — pytest é infra do motor (Fase 0 bootstrap), não do sistema-alvo; não assume linguagem/framework do alvo; `pytest` isolado como ferramenta de qualidade declarada. |
| **X Observabilidade** | falha sem REQ-ID ou evidência | ✅ PASS — cada asserção `f0-005` imprime `🔴 FR-XXX` com evidência (`tomllib` parse, `git check-ignore`, `sha256sum`, `subprocess` stdout); FR-010 nomeia 5 casos `test_*`; SC-005 exige FR nomeado. |

**Additional Constraints:**

| Constraint | Avaliação |
|---|---|
| Escada de dependências | ✅ Só `pytest`/`pytest-asyncio`/`pytest-cov` além de shell/git/Python stdlib+`uv`; nenhum `ruff`/`mypy`/`lefthook` neste item (FR-015). |
| Escopo da máquina | ✅ Nenhuma escrita global, identidade em `.git/config` local. |
| Cadeia de suprimentos | ✅ `uv.lock` versionado com `pytest` hash; exclusão não cobre lock (FR-006/007). |
| Ambiente sob demanda | ✅ Sem Docker/service em background; `pytest` e `sha256sum` on-demand. |
| Sem privilégio elevado | ✅ Nenhum `sudo`/`admin` requerido. |

**Veredito pré-Phase 0**: **PASS** — nenhum gate bloqueante, nenhum NEEDS CLARIFICATION (research Q1–Q10 já resolveu).

**Re-avaliação pós-Phase 1**: **PASS** — `research.md` consolida D1–D10, `data-model.md`/`contracts/`/`quickstart.md` não introduzem dependência nova nem violam escada; `tests/` coleta, `manifest` aditivo, sem `ruff`/`mypy`.

---

## Project Structure

### Documentation (this feature)

```text
specs/005-pytest/
├── spec.md              # Concluído (217 linhas, 15 FRs, 8 SCs)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — Q1–Q10 → D1–D10 (consolida docs/plan/research/f0-005-pytest.md)
├── data-model.md        # Phase 1 — entidades Harness pytest / Manifest / Oracle promotion / Dependency-group dev
├── quickstart.md        # Phase 1 — 6 cenários de validação (clone limpo, promoção 1:1, manifest, dívidas, CONVERGE, CI glob)
├── contracts/
│   ├── pytest-contract.md       # Phase 1 — contrato pytest (pyproject.toml schema, tests/, coverage)
│   └── oracle-cli.md            # Phase 1 — contrato oráculo 005 (CANON + mapa FR quando não identidade + manifest)
├── checklists/
│   └── requirements.md  # (gerado por /speckit-checklist, 12/12 PASS)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item produz **4 arquivos versionados + 2 testes + 1 manifesto + 1 oráculo**; não produz `packages/` nem `ruff`/`mypy`:

```text
fluksos-x/
├── pyproject.toml                     # ALTERADO — acrescenta [dependency-groups] dev + [tool.pytest.ini_options] + [tool.coverage.*] (FR-001/003)
├── uv.lock                            # ALTERADO — contém pytest 9.1.1 + deps (FR-006, TOML universal)
├── tests/                             # NOVO — diretório raiz de coleta pytest (FR-004)
│   ├── conftest.py                    # NOVO — mínimo, py_compile válido, sem fixtures globais ainda
│   ├── test_harness_oracles.py        # NOVO — parametrizado por f0-*.sh, subprocess FKX_ORACLE_NESTED (FR-005)
│   └── test_harness_debts.py          # NOVO — 5 casos ADR-007 nomeados (FR-010)
├── scripts/verify/
│   ├── manifest.sha256                # NOVO — 5 linhas sha256sum 001..005 (FR-008, ADR-015a)
│   ├── f0-005-pytest.sh               # NOVO — oráculo deste item (12–16 asserções, FR-001..015)
│   ├── README.md                      # ALTERADO — registra o que f0-005 verifica (+1 linha)
│   ├── f0-001-foundation.sh           # INTOCADO — SHA 63412ca7… asserido via manifest
│   ├── f0-002-constitution.sh         # INTOCADO
│   ├── f0-003-ci-minimo.sh            # INTOCADO
│   └── f0-004-uv-workspace.sh         # INTOCADO — SHA 3db362… asserido
├── .gitignore                         # INTOCADO — já cobre .pytest_cache/htmlcov/.coverage (FR-007)
├── .github/workflows/ci.yml           # INTOCADO — 003 já cobre 005 via glob For f in f0-*.sh (FR-012)
├── docs/plan/research/
│   └── f0-005-pytest.md               # JÁ EXISTE — pesquisa vinculante 479 linhas (Q1–Q10)
└── specs/005-pytest/                  # NOVO ao versionamento
```

**Structure Decision**: `tests/` na raiz segue `docs.pytest.org` discovery (`testpaths=["tests"]`) e `uv workspace` com zero membros (004 `members=["packages/*"]`). `manifest.sha256` em `scripts/verify/` segue ADR-015a (formato `sha256sum -c`, sem parser). Oráculo em `scripts/verify/f0-005-pytest.sh` segue ADR-002 (um arquivo por item, `f0-NNN-<slug>.sh`) e `README.md` tabela. `pyproject.toml` fonte única (`[tool.pytest.ini_options]`), sem `pytest.toml` separado (D2). Não há `src/` porque harness é infra, não aplicação.

---

## Fases de execução

> Ordem normativa: vermelho antes do verde (III), porque é a única prova auditável; `dependency-groups dev` antes de `uv sync`, porque sem grupo não há lock; `manifest.sha256` com 4 linhas congeladas + hash 005 calculado, porque sem manifesto não há integridade; `testpaths=["tests"]` antes de `packages/*/tests`, porque sem raiz cada pacote reescreveria a coleta.

### Fase A — Preparação

1. Confirmar harness existente verde: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` (deve sair 0 com `f0-001` 30/30 + `f0-002` 33/33 + `f0-003` 14/14 + `f0-004` 14/14) e `ls tests/ → inexistente`, `ls manifest.sha256 → inexistente` (Q1/Q7).
2. Confirmar `pyproject.toml` sem `[dependency-groups]` nem `[tool.pytest.ini_options]` e `uv.lock` sem `pytest` (`grep -q "pytest" uv.lock` falha) e `.gitignore` já cobre `.pytest_cache` (Q2/Q5).
3. Registrar decisões D1–D10 em `research.md` deste feature dir (consolida `docs/plan/research/f0-005-pytest.md`).
4. Medir hashes `sha256sum scripts/verify/f0-*.sh` (devem bater `63412ca7…`, `406d72…`, `d10c61…`, `3db362…`).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-005-pytest.sh` com contrato `oracle-cli.md` (`0`/`1`/`2`, `--quiet`/`--list`, `CANON_ORDER` 12–16, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`, somente leitura, sem `pytest` exigido para asserções estáticas).
2. Cobrir FR-001..015 1:1 (12–16 asserções — algumas FRs convergem):
   - FR-001/002: `[dependency-groups] dev` contém `pytest==9.1.1`, `pytest-asyncio==1.4.0`, `pytest-cov==7.1.0` exatos, sem `[project.dependencies]` legado.
   - FR-003: `[tool.pytest.ini_options]` com `minversion`, `testpaths`, `python_files/classes/functions`, `pythonpath`, `addopts`, `markers`, `filterwarnings`, `xfail_strict`, `asyncio_mode strict`.
   - FR-004: `tests/conftest.py` existe (`py_compile` 0) e `! test -f pytest.toml`.
   - FR-005: `tests/test_harness_oracles.py` existe com `parametrize` + `subprocess` `FKX_ORACLE_NESTED`.
   - FR-006/007: `uv.lock` contém `pytest` e `tomllib` válido + `check-ignore` git.
   - FR-008/009: `manifest.sha256` 5 linhas e `sha256sum -c` 0 + self-check `f0-001..004 --quiet` todos.
   - FR-010: `tests/test_harness_debts.py` 5 funções nomeadas.
   - FR-011: `uv run pytest -q` coleta (quando `pytest` instalado) — em vermelho deve reprovar por ausência.
   - FR-012: CI glob `grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml` passa.
   - FR-013: `tasks.md` zero `[ ]` (CONVERGE).
   - FR-014: determinismo 2× `cmp` + `<5s` `EPOCHSECONDS`.
   - FR-015: ausência de `ruff`/`mypy`/`lefthook`/`packages/`.
3. Executar e preservar `evidence/red.txt` — deve reprovar em massa (`pytest` ainda não instalado, `tests/` inexistente).
4. Conferir `--list` enumera 12–16 IDs sem executar.

> Pular esta fase satisfaz os arquivos e ainda assim falha SC-003/Princípio III, porque o par vermelho→verde não existiria.

### Fase C — Harness pytest verde 🟢

1. Materializar `pytest` **via `uv`** (sem editar strings à mão quando `uv` disponível):
   ```bash
   uv add --dev pytest==9.1.1 pytest-asyncio==1.4.0 pytest-cov==7.1.0
   uv sync   # gera uv.lock com pytest + .venv com pytest 9.1.1
   ```
   Se `uv` indisponível, fallback: escrever `[dependency-groups] dev` manual + `uv.lock` TOML válido com `[[package]] pytest` stub; harness deve aceitar ambos (com e sem `uv`).
2. Criar `tests/conftest.py` mínimo:
   ```python
   # conftest for 005 — no global fixtures yet
   ```
   Validar `python -m py_compile tests/conftest.py` (FR-004).
3. Criar `tests/test_harness_oracles.py` parametrizado (D6) e `tests/test_harness_debts.py` 5 casos (D7), ambos `py_compile` válidos.
4. Gerar `scripts/verify/manifest.sha256` 5 linhas:
   ```bash
   sha256sum scripts/verify/f0-001-foundation.sh scripts/verify/f0-002-constitution.sh scripts/verify/f0-003-ci-minimo.sh scripts/verify/f0-004-uv-workspace.sh scripts/verify/f0-005-pytest.sh > scripts/verify/manifest.sha256
   ```
   Validar `sha256sum -c scripts/verify/manifest.sha256` (FR-008).
5. Validar `pyproject.toml` TOML: `python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert d["dependency-groups"]["dev"]'` (FR-001).
6. Validar `uv run pytest --co -q` enumera ≥5 casos (FR-005/010).
7. Atualizar `scripts/verify/README.md` tabela (nova linha `f0-005-pytest.sh | 12–16 | Pytest 9.1.1 — harness TDD + manifest`).

### Fase D — Verde e convergência local

1. Executar oráculo: `scripts/verify/f0-005-pytest.sh --quiet` → `0`; preservar `evidence/green.txt`.
2. Executar `uv run pytest -q` → `X passed` (FR-011); preservar `evidence/pytest_green.txt`.
3. Executar duas vezes e comparar byte a byte (`cmp` stdout) + `EPOCHSECONDS` `<5s` (SC-003, FR-014).
4. Teste `sha256sum -c manifest.sha256` → 0; editar 1 byte em `f0-001` temporário → diverge → reverter (SC-004).
5. Executar harness acumulado: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` → `0` e `uv run pytest -q` → 0 (dupla).
6. `git status` limpo exceto artefatos deste item; `git diff .gitignore` vazio (FR-007).
7. `grep -c "\[ \]" specs/005-pytest/tasks.md` → 0 (CONVERGE, FR-013).

### Fase E — Entrega remota (pós-merge)

1. Push para `main` em estado conforme → check `verify` verde inclui `f0-005` e `pytest` via `for f` glob (SC-006).
2. Injetar violação (ex.: `pytest.toml` presente ou `marker` typo) em branch, PR para `main` → check vermelho com `🔴 FR-...` e `FAILED` pytest (SC-005).
3. Esses dois SCs são observáveis só após merge; registrá-los como evidência remota na convergência.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | `[dependency-groups] dev` com `pytest==9.1.1`, `pytest-asyncio==1.4.0`, `pytest-cov==7.1.0` | FR-001/002/006 | Q1 PyPI 2026-08-31 |
| D2 | `tests/` raiz + `tests/conftest.py`, `test_*.py`, só `pyproject.toml [tool.pytest.ini_options]` | FR-003/004 | Q2 docs.pytest.org 51KB |
| D3 | `asyncio_mode strict` + `asyncio_default_fixture_loop_scope function` | FR-003 | Q3 pytest-asyncio 1.4.0 |
| D4 | `uv add --dev` → `[dependency-groups]` PEP 735, `uv sync` default | FR-001/002 | Q4 docs.astral.sh 169KB |
| D5 | `pytest-cov` relatório `branch true` sem `--cov-fail-under` (portão é 010) | FR-003 | Q5 docs coverage |
| D6 | Promoção oráculos via `subprocess` parametrizado + `--list` vs `CANON_ORDER` | FR-005/011 | Q6 oracle-cli + README |
| D7 | `EPOCHSECONDS`/`time.monotonic` `<5s` + 2× `cmp` + 5 casos ADR-007 | FR-010/014 | Q7 ADR-007/B2 |
| D8 | `manifest.sha256` 5 linhas nativo `sha256sum -c` + self-check `001..004` todos | FR-008/009 | Q8 ADR-015 re-medido |
| D9 | `minversion 9.1`, `testpaths ["tests"]`, `addopts "-ra --strict-markers --strict-config"`, sem `xdist` | FR-003/014 | Q9 pytest docs |
| D10 | 12–16 asserções só pytest+manifesto+dívidas; sem `ruff`/`mypy`/`lefthook`/`packages/` | FR-015 | Q10 constitution |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `pyproject.toml` ganhar `[tool.ruff]` em 005 (adianta 006) | Alto — quebra Escada, cada spec futura reescreve | FR-015 asserção negativa `! grep -q '\[tool.ruff\]'`; D10 rejeita placeholder |
| `pytest.toml` separado esconder `[tool.pytest.ini_options]` | Alto — `pytest` ignora `pyproject.toml` silencioso | FR-004 `! test -f pytest.toml` + `strict-config` reprova config desconhecida |
| `uv 0.12.1` local falhar com `pytest` | Médio — `uv lock` com `requires_python>=3.12` pode advertir | D1: `uv self update` documentado em `quickstart.md` Troubleshooting |
| `async def test_x` sem marker em `strict` passar | Alto — falso-positivo, esconde async | D3: `strict` + `filterwarnings=error`; teste de injeção sem marker deve `FAILED` |
| `manifest.sha256` com `*` (binário) vs `  ` (texto) | Médio — `sha256sum -c` falha em Windows | D8: formato dois espaços canônico, medido via `sha256sum` |
| `pytest-xdist` adiantado | Médio — indeterminístico `load`/`worksteal` | FR-015 `! grep -q xdist` em `dependency-groups`; D9 deferido a 010 |
| Self-check `004` pulou `002`, repetir erro em 005 | Alto — A1/M4 reabre | FR-009 exige `f0-001`..`004 --quiet` todos, não subconjunto |
| `tasks.md` com `[ ]` e CONVERGE verde | Alto — viola ADR-015d | FR-013 asserido por `f0-005` `grep -c "\[ \]"` → 0 |
| `uv.lock` editado manualmente (hash diverge) | Crítico — supply chain | FR-006 `uv lock --check` quando `uv` presente; `tomllib` válido sempre |

---

## Complexity Tracking

> Nenhuma violação de Constitution Check a justificar. Tabela permanece vazia por construção.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |
