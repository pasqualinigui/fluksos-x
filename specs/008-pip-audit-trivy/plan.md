# Implementation Plan: pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades

**Branch**: `008-pip-audit-trivy` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-pip-audit-trivy/spec.md`
**Pesquisa vinculante**: `docs/plan/research/f0-008-pip-audit-trivy.md` (Q1–Q10, D1–D10, 2026-08-31, sem NEEDS CLARIFICATION)
**Constitution**: `.specify/memory/constitution.md` v1.0.0 (10 princípios I–X)

---

## Summary

Entregar **o portão de supply chain do monorepo** (implementation_plan §§3,11,17 item 0.12, ordem 008/016 ADR-011): `pip-audit==2.10.1` em `[dependency-groups] dev` com `ruff 0.16.5`/`mypy 2.3.1`/`pytest 9.1.1` coexistindo + `uv.lock` com hash (`cyclonedx-python-lib`/`cachecontrol`/`packaging` transitivos) + `Trivy 0.74.0` pin documentado `aquasec/trivy:0.74.0` (Go binary/Docker, não em `pyproject.toml`) + `uv run pip-audit` 0 em env local sem vulns (`No known vulnerabilities found`, 41 pacotes) e `pip-audit --dry-run`/`-f json`/`cyclonedx-json` válidos + `trivy fs --severity HIGH,CRITICAL` skip `⏭️` se Docker ausente + oráculo `f0-008-pip-audit.sh` 12-16 asserções (inclui `specs/README.md` e `git ls-files` inquebráveis) + `manifest.sha256` 8 linhas. Sem `lefthook`/`gitleaks`/`packages`/`docker-compose` nem `requirements.txt`/`pylock.toml`/`pip-audit.toml` separado (Escada). É o último portão de segurança da Fase 0 antes de `Lefthook` (009) orquestrar `ruff`+`mypy`+`pytest`+`pip-audit`+`trivy`. Plano é transcrição fiel de D1–D10 verificadas contra PyPI `pip-audit 2.10.1` + GitHub `Trivy 0.74.0` + `pip-audit --help` + `uv --help` 2026-08-31; nenhum desenho novo.

---

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (família `3.12`; local `3.12.3`, runner `3.12.14` via `setup-python@v7`) + TOML (pyproject/uv.lock) + bash (oráculo) + pip-audit 2.10.1 (Python `>=3.10`, `advisory-database` + `OSV` via PyPI JSON) + Trivy 0.74.0 (Go, `fs`/`config`/`secret`/`sbom`). `uv` `0.12.7` binário (pin §4, PyPI 2026-08-31; local `0.12.1` converge).

**Primary Dependencies**: `pip-audit==2.10.1` (`cyclonedx-python-lib<12`, `cachecontrol`, `pip-api`, `requests`, `rich`, `tomli` transitivos), `mypy==2.3.1`, `ruff==0.16.5`, `pytest==9.1.1` `pytest-asyncio==1.4.0` `pytest-cov==7.1.0` já em `dev` (005/006/007), `uv_build>=0.12.7,<0.13`. Nenhum `gitleaks 8.30.1`/`cyclonedx-bom 7.3.1`/`lefthook 2.1.11` em 008 (FR-013, Escada); `Trivy` não entra em `dev` (Go/Docker).

**Storage**: Sistema de arquivos. Artefatos: `pyproject.toml` (raiz, `[dependency-groups] dev` + `pip-audit 2.10.1`), `uv.lock` (raiz, TOML universal com `pip-audit` hash), `pip-audit` cache `~/.cache/pip` (fora do repo, não versionado), `Trivy` DB `~/.cache/trivy` (idem), `scripts/verify/f0-008-pip-audit.sh` (oráculo), `scripts/verify/manifest.sha256` 8 linhas, `specs/README.md` (índice). `.mypy_cache`/`_pytest_cache`/`htmlcov` já existem (007/005).

**Testing**: `uv run pip-audit` (auditoria local env, `No known vulnerabilities found` para 41 pacotes) + `uv run pip-audit --dry-run` (`would have audited`) + `uv run pip-audit -f json` (`dependencies[].vulns[]`) + `uv run pip-audit -f cyclonedx-json` (`bomFormat CycloneDX`) + `uv run pip-audit --version` 2.10.1 + `pip-audit --help` `cyclonedx-json`/`--fix` + `trivy fs --severity HIGH,CRITICAL --format json` (`⏭️` skip se Docker ausente) + oráculo `f0-008-pip-audit.sh` 12-16 asserções (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER` 12-16, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`, `2× cmp`) + `pip-audit --no-error-summary` não existe (pip-audit usa `columns`/`json` determinístico). `mypy`/`ruff`/`pytest` devem continuar 16/16,14/14,15/15 (`self-check`).

**Target Platform**: Filesystem POSIX (Linux `ubuntu-24.04` runner + local), macOS/Windows cobertos por lock universal. CI `003` `for f in f0-*.sh` + `010` futuro `uv run pip-audit` determinístico + `015` `trivy image`.

**Project Type**: Infraestrutura de qualidade — auditoria de supply chain + filesystem. Não produz biblioteca nem CLI além do verificador.

**Performance Goals**: `uv sync` com `pip-audit` <2min; `uv run pip-audit` <10s para 41 pacotes (online `PyPI JSON`/`OSV`), `<5s` para `--dry-run`; `uv run pip-audit -f json` <5s; `trivy fs` <10s quando Docker presente, `⏭️` `<1s` quando ausente; `f0-008` <5s `EPOCHSECONDS` `2× cmp`; `manifest 8` `<1s`.

**Constraints**:
- Escada (constitution Additional Constraints): nenhum artefato pode exigir `lefthook`/`gitleaks`/`packages`/`docker-compose` — impõe FR-013 negativo.
- Determinismo (I): `[dependency-groups]` pin exato `2.10.1`, `Trivy 0.74.0` tag fixa, `uv.lock` hash determinístico, `pip-audit` input via `uv.lock` (advisory DB muda, mas baseline hoje 0 vulns), `EPOCHSECONDS` sem `date`, `sha256sum`, `git ls-files` para commit inquebrável.
- Lei Zero (V): `uv.lock` versionado, `pip-audit` cache `~/.cache/pip` e `Trivy` DB `~/.cache/trivy` fora do repo, `dev` local-only.
- Fidelidade ao oráculo (VI): harness cresce por acréscimo (`f0-008` sem tocar `f0-007`..01), `manifest.sha256` 8 linhas aditivo, `CONVERGE` zero `[ ]` + `specs/README.md` e `git ls-files` inquebráveis.
- Escopo da máquina: nada global, identidade em `.git/config` local.
- Sem privilégio elevado: não exige `sudo`/`admin`, `Trivy` via `docker run` ou binary sem `sudo` (quando `docker` presente, `015` trará compose).

**Scale/Scope**: 16 FRs (inclui 2 inquebráveis `FR-014` `FR-015`), 8 SCs, 3 US (P1-P3), 8 edge cases. `pyproject.toml` + `uv.lock` alterados + `pip-audit` cache fora do repo + 1 oráculo `12-16` asserções + `Trivy` pin documentado. `tests/` 13 passed (7 oráculos + 1 list + 5 dívidas) em 008, `pip-audit` deve auditar 41 pacotes sem reprovar.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Princípios avaliados contra v1.0.0:**

| Princípio | Critério de violação | Avaliação neste plano |
|---|---|---|
| **I Determinismo sobre probabilidade** | decisão sem regra determinística validando modelo | ✅ PASS — `pip-audit==2.10.1` exato (D1), `Trivy 0.74.0` tag fixa (D3), `uv.lock` hash determinístico, `pip-audit` input via `uv.lock` (advisory DB muda mas baseline 0 vulns é determinístico no input), `EPOCHSECONDS` sem `date`, `git ls-files` para `README`/`commit`. |
| **II Especificação precede código** | artefato sem spec prévia | ✅ PASS — `spec.md` 207 linhas 16 FRs/8 SCs existe antes deste plano; nenhum `pip-audit` em `pyproject.toml` criado ainda (`! grep -q pip-audit pyproject.toml`, Q1/Q2). |
| **III Teste antes da implementação** | sem par vermelho→verde | ✅ PASS — Fase B gera `f0-008` reprovando (vermelho) antes de Fase C `pip-audit` verde; `pip-audit` reprovando antes, 0 depois; `evidence/red.txt`/`green.txt`. |
| **IV Definição de dados antes da implementação** | componente sem contrato | ✅ PASS — `data-model.md` declara entidades pip-audit/Trivy/manifest + README/commit inquebráveis; `contracts/pip-audit-contract.md` + `oracle-cli.md` fixam schemas. |
| **V Segurança é a Lei Zero** | segredo ou trava coberta | ✅ PASS — `uv.lock` versionado (FR-003/005), `pip-audit` cache fora do repo, `Trivy` DB fora, `dev` local-only, nenhum segredo; `001` D3 sem `*.lock` preservado; `gitleaks` deferido a 010. |
| **VI O harness é o oráculo** | critério sem asserção ou diff altera anterior | ✅ PASS — FR-001..016 têm asserção 1:1 em `f0-008` (12-16); plano proíbe tocar `f0-007`..01 (hashes `54fa8199…` etc. em `manifest.sha256`); `pip-audit` verifica, não re-escreve; `specs/README.md` e `git ls-files` inquebráveis. |
| **VII Auto-reparo atualiza a documentação** | correção sem alteração normativa | ✅ PASS — plano inclui `specs/README.md` e `git ls-files` como FR-014/015 após falha 007 ter passado sem ver; se falhar, reparo exigirá `specs/README.md` update. |
| **VIII Elo verificado antes de lógica** | código consome serviço sem verificação | ✅ PASS — Q1–Q10 verificados 2026-08-31 contra PyPI `pip-audit 2.10.1` + `pip-audit --help` + GitHub `Trivy 0.74.0` + `uv --help`/`python --version` locais; D1–D10 citam fonte+bytes. |
| **IX Agnosticismo de stack** | referência a stack-alvo fora de adaptador | ✅ PASS — `pip-audit`/`Trivy` são infra do motor (Fase 0 bootstrap), não do sistema-alvo; não assumem linguagem/framework do alvo. |
| **X Observabilidade** | falha sem REQ-ID ou evidência | ✅ PASS — cada asserção `f0-008` imprime `🔴 FR-XXX` com evidência (`tomllib` parse, `git check-ignore`, `pip-audit --dry-run` output, `sha256sum`, `grep README`, `git ls-files`); SC-002 exige `would have audited` nomeado. |

**Additional Constraints:**

| Constraint | Avaliação |
|---|---|
| Escada de dependências | ✅ Só `pip-audit` além de `ruff`+`mypy`+`pytest`+`uv`+stdlib; nenhum `lefthook`/`gitleaks`/`packages`/`docker-compose` (FR-013). |
| Escopo da máquina | ✅ Nenhuma escrita global. |
| Cadeia de suprimentos | ✅ `uv.lock` com `pip-audit` hash versionado. |
| Ambiente sob demanda | ✅ Sem Docker obrigatório; `pip-audit` on-demand, `Trivy` skip se Docker ausente (`⏭️`), `docker run` só em 015. |
| Sem privilégio elevado | ✅ Nenhum `sudo`. |

**Veredito pré-Phase 0**: **PASS** — nenhum gate bloqueante, nenhum NEEDS CLARIFICATION (research Q1–Q10 já resolveu, `FR-014/015` inquebráveis adicionados em `spec` ainda `Draft` antes de `plan` derivar tarefas).

**Re-avaliação pós-Phase 1**: **PASS** — `research.md` consolida D1–D10, `data-model.md`/`contracts/`/`quickstart.md` não introduzem dependência nova nem violam escada; `pip-audit` + `ruff`/`mypy`/`pytest` coexistem em `dev`; `specs/README.md` e `git ls-files` inquebráveis adicionados sem aumentar `tasks.md` além de 2 FRs (ainda `<5s`).

---

## Project Structure

### Documentation (this feature)

```text
specs/008-pip-audit-trivy/
├── spec.md              # Concluído (207 linhas, 16 FRs 14+2 inquebráveis, 8 SCs)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — Q1–Q10 → D1–D10 (consolida docs/plan/research/f0-008-pip-audit-trivy.md)
├── data-model.md        # Phase 1 — entidades pip-audit/Trivy/manifest + README/commit inquebráveis
├── quickstart.md        # Phase 1 — 6 cenários (clone limpo, pip-audit dry-run, Trivy fs, fronteira, CONVERGE, CI)
├── contracts/
│   ├── pip-audit-contract.md    # Phase 1 — contrato pip-audit (pyproject.toml schema, pip-audit --help, Trivy pin)
│   └── oracle-cli.md            # Phase 1 — contrato oráculo 008 (CANON 12-16 + manifest 8 linhas + README/commit)
├── checklists/
│   └── requirements.md  # (gerado, 16/16 PASS)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item produz **2 arquivos versionados alterados + 1 oráculo + 1 índice atualizado**; não produz `lefthook`/`packages`/`docker-compose`:

```text
fluksos-x/
├── pyproject.toml                     # ALTERADO — acrescenta pip-audit==2.10.1 em [dependency-groups] dev (FR-001)
│                                      # já contém [dependency-groups] dev com pytest 9.1.1 + ruff 0.16.5 + mypy 2.3.1 (007) + [tool.ruff.*] (006) + [tool.pytest.*] (005)
├── uv.lock                            # ALTERADO — acrescenta pip-audit 2.10.1 + cyclonedx-python-lib/cachecontrol com hash (FR-003/005)
├── scripts/verify/
│   ├── manifest.sha256                # ALTERADO — 8 linhas (001..008) sha256sum -c 0 (FR-003, D8)
│   ├── f0-008-pip-audit.sh            # NOVO — oráculo deste item (12-16 asserções, FR-001..016, inclui README/commit)
│   ├── README.md                      # INTOCADO — já registra 001..007, 008 adiciona linha em 008 (T034)
│   ├── f0-007-mypy.sh                 # INTOCADO — hash 54fa8199… (manifest)
│   └── f0-001..006                    # INTOCADOS
├── specs/README.md                    # ALTERADO — índice 008 → ✅ (FR-014, inquebrável)
├── tests/                             # EXISTE — 13 passed em 008 (7 oráculos + 1 list + 5 dívidas), pip-audit deve auditar 41 pacotes sem reprovar
├── .gitignore                         # INTOCADO — já cobre __pycache__/.venv/.ruff_cache/.mypy_cache (sem pip-audit cache, fora do repo)
├── .github/workflows/ci.yml           # INTOCADO — 003 glob for f0-*.sh inclui f0-008 sem editar
├── docs/plan/research/
│   └── f0-008-pip-audit-trivy.md      # JÁ EXISTE — pesquisa vinculante 340+ linhas Q1–Q10
└── specs/008-pip-audit-trivy/         # NOVO
```

**Structure Decision**: `pip-audit` em `[dependency-groups] dev` segue `PEP 735` (mesmo que `pytest`/`ruff`/`mypy` em 005/006/007). `Trivy 0.74.0` pin é tag `aquasec/trivy:0.74.0` (Docker) + binary `sigstore`, não entra em `pyproject.toml` (Go, não Python). `manifest.sha256` 8 linhas segue ADR-015a. Oráculo `f0-008-pip-audit.sh` segue ADR-002. `specs/README.md` índice flat segue ADR-011 + `FR-014` inquebrável. Não há `src/` porque auditoria é infra.

---

## Fases de execução

> Ordem normativa: vermelho antes do verde (III); `pip-audit==2.10.1` em `[dependency-groups]` antes de `uv sync`; `pip-audit.toml` separado inexistente verificado antes de `pyproject.toml`; `specs/README.md` e `git ls-files` verificados após `pip-audit` 0, porque README/commit inquebráveis só fazem sentido quando `pip-audit` já está verde.

### Fase A — Preparação

1. Confirmar harness verde: `for f in f0-*.sh; do "$f" --quiet || exit 1; done` → `0` com `f0-001` 30/30 `f0-002` 33/33 `f0-003` 14/14 `f0-004` 14/14 `f0-005` 15/15 `f0-006` 14/14 `f0-007` 16/16 + `uv run pip-audit --version` 2.10.1 (quando instalado) + `uv run ruff check` 0 + `uv run pytest -q` 13 passed.
2. Confirmar ausência de `pip-audit` em `pyproject.toml` (`! grep -q pip-audit pyproject.toml`), ausência de `pip-audit` em `uv.lock` (`! grep -q 'name = "pip-audit"' uv.lock`), ausência de `gitleaks.toml`/`requirements.txt`/`pylock.toml`, e que `docs/plan/research/f0-008-pip-audit-trivy.md` 340+ linhas existe.
3. Medir hashes `sha256sum f0-*.sh` (devem bater `63412ca7…` `b63ac3c8…` `d10c61…` `759376ee…` `dccb114a…` `5f268846…` `54fa8199…`).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-008-pip-audit.sh` com contrato `oracle-cli.md` (`0`/`1`/`2`, `--quiet`/`--list`, `CANON_ORDER` 12–16, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`).
2. Cobrir FR-001..016 1:1 (12–16 asserções):
   - FR-001: `[dependency-groups] dev` contém `pip-audit==2.10.1` exato, sem `pip-audit` em `[project.dependencies]`.
   - FR-002: `pip-audit.toml` não existe (sem config separada).
   - FR-003: `uv.lock` contém `pip-audit` + `tomllib` + `uv lock --check` + `pip-audit --version` 2.10.1 e `--help` `cyclonedx-json`.
   - FR-004: `Trivy 0.74.0` pin `aquasec/trivy:0.74.0` documentado, não em `dev`.
   - FR-005: `uv.lock` contém `pip-audit` e transitivos `tomllib` + `uv lock --check`.
   - FR-006: cache `pip-audit`/`Trivy DB` fora do repo, `uv.lock` não ignorado.
   - FR-007: `uv run pip-audit` 0 sem vulns e `pip-audit --dry-run` `would have audited`.
   - FR-008: `uv run pip-audit -f json` 0 com `dependencies[].vulns[]` e `cyclonedx-json` válido.
    - FR-009: `Trivy fs` sai `0` com `⏭️` skip se Docker ausente (`docker info` falha, linha `⏭️ FR-009`), e `0` com `Results` vazio quando disponível.
   - FR-010: oráculo self-check `0/1/2` `quiet` `list` `FKX` `EPOCHSECONDS` `<5s` `2× cmp`.
   - FR-011: CI glob `for f` inclui `f0-008`.
   - FR-012: CONVERGE `grep -E "^- \[ \]" tasks.md` 0.
   - FR-013: fronteira `! lefthook.yml` `! gitleaks.toml` `! packages/` etc.
   - FR-014: `specs/README.md` contém `008` `✅` (inquebrável).
   - FR-015: `git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md` 0 (inquebrável).
   - FR-016: `Trivy` não `0.69.4` e `pip-audit` não `<2.10.1`.
3. Executar e preservar `evidence/red.txt` — deve reprovar (6–8/16) por ausência de `pip-audit`.
4. Conferir `--list` enumera 12–16 IDs.

### Fase C — pip-audit verde 🟢

1. Materializar `pip-audit` via `uv`:

```bash
uv add --dev pip-audit==2.10.1
uv sync  # pip-audit em .venv/bin/pip-audit, uv.lock com hash
```

Fallback sem `uv`: escrever `[dependency-groups] dev` manual + `uv.lock` stub TOML válido com `[[package]] name="pip-audit"`.

2. Validar `uv run pip-audit --version` 2.10.1 e `--help` `cyclonedx-json`/`--fix`.
3. Validar `uv run pip-audit` 0 sem vulns e `pip-audit --dry-run` `would have audited`.
4. Gerar `manifest.sha256` 8 linhas: `sha256sum f0-001..008 > manifest.sha256` + `sha256sum -c` 0.
5. Atualizar `specs/README.md` índice `008 → ✅` (FR-014) e `README.md` `f0-008` linha.
6. Validar `git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md` 0 (FR-015).

### Fase D — Verde e convergência local

1. `f0-008-pip-audit.sh --quiet` → `0`; `evidence/green.txt`.
2. `uv run pip-audit` 0 + `uv run pip-audit -f json` 0 + `pip-audit --version` 2.10.1 (SC-003).
3. `2× cmp` determinismo + `<5s` `EPOCHSECONDS`.
4. `for f in f0-*.sh; do "$f" --quiet || exit 1; done` → `0` (8/8) + `uv run pytest -q` 13 passed + `uv run ruff check` 0 + `uv run mypy --strict .` 0.
5. `grep -E "^- \[ \]" tasks.md` → 0 + `git ls-files` 0.

### Fase E — Entrega remota (pós-merge)

1. Push `main` conforme → `verify` verde inclui `f0-008`.
2. Injetar `lefthook.yml` ou `gitleaks.toml` → PR `verify` vermelho `FR-013`.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | `pip-audit==2.10.1` via `[dependency-groups] dev` | FR-001/003/005 | Q1 PyPI 2026-06-10 |
| D2 | `pip-audit` audita env local após `uv sync` em 008; `pylock.toml`/`--locked` só em 013 | FR-007 | Q2 pip-audit --help + uv pylock |
| D3 | `Trivy 0.74.0` via `aquasec/trivy:0.74.0` (Docker) / binary sigstore, `fs`/`config` em 008 | FR-004/009 | Q3 GitHub 2026-08-14 |
| D4 | `cyclonedx-python-lib<12` transitive de `pip-audit`, `uv export --format cyclonedx1.5` só em 013 | FR-008 | Q4 PyPI cyclonedx + uv export |
| D5 | `uv add --dev pip-audit==2.10.1` → `dev` com `pytest`+`ruff`+`mypy`+`pip-audit` | FR-001/003 | Q5 uv docs |
| D6 | Compat `pip-audit` sem conflito `ruff S`/`mypy`/`pytest`, `Trivy` complementa | FR-007 | Q6 ruff S + mypy 007 |
| D7 | `pip-audit` audita 41 pacotes hoje sem vulns, `Trivy` `fs` para `secret`/`config` | FR-007 | Q7 advisory DB |
| D8 | `pip-audit` cache padrão pip, não `.pip-audit/` no repo; `Trivy` DB em `~/.cache/trivy` | FR-006 | Q8 pip cache |
| D9 | Harness `f0-008-pip-audit.sh` 12-16 asserções só pip-audit+Trivy doc, sem lefthook/gitleaks | FR-010/014/015 | Q9 oracle-cli + README |
| D10 | Determinismo `pip-audit` via `uv.lock` hash, `Trivy` skip se Docker ausente, fronteira Escada 008 só pip-audit | FR-013 | Q10 constitution |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| `pip-audit` consulta `PyPI JSON`/`OSV` online e advisory DB muda | Alto — `pip-audit` pode passar hoje e falhar amanhã com nova CVE | FR-007 baseline `No known vulnerabilities found` hoje; se CVE surgir, harness permite `--ignore-vuln` com ADR (D10) |
| `Trivy` sem Docker daemon em Fase 0 | Médio — `trivy fs` falharia se exigisse Docker | D3 `Trivy` skip `⏭️` se Docker ausente, não `🔴`; `015` trará `docker-compose` |
| `pip-audit --locked` sem `pylock.toml` | Médio — `pip-audit --locked` falharia em 008 | D2 `pip-audit` em 008 usa env local, não `--locked`; `pylock.toml` só em 013 |
| `requirements.txt` fragmenta `uv.lock` | Médio — lock universal perde fonte única | FR-001/013 `! test -f requirements.txt` reprova |
| `cyclonedx` SBOM sem `pip-audit` vuln | Baixo — `cyclonedx-json` vazio ainda válido | FR-008 `bomFormat CycloneDX` válido mesmo sem vulns |
| `Trivy 0.69.4` vulnerável CVE-2026-33634 | Alto — supply chain | FR-016 `grep -q "0.69.4"` reprova, pin `0.74.0` obrigatório |
| `specs/README.md` desatualizado | Alto — índice mente, escala quebra | D8 `FR-014` `grep -q "008.*✅"` inquebrável |
| `spec 008` não commitado (`??`) | Alto — 008 não está na `main` | D8 `FR-015` `git ls-files --error-unmatch` inquebrável |
| `pip-audit` cache versionado | Alto — cache no histórico | FR-006 `git ls-files | grep pip-audit` vazio |

---

## Complexity Tracking

> Nenhuma violação de Constitution Check a justificar.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| — | — | — |
