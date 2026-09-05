# Feature Specification: pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades

**Feature Branch**: `008-pip-audit-trivy`

**Created**: 2026-08-31

**Status**: Draft

**Input**: User description: "Fase 0, item 0.12 (008/016 na ordem de execução): pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades de supply chain (pip-audit via uv) + filesystem/IaC/secrets scan (Trivy fs), via dependency-groups dev, pip-audit local env, Trivy Docker/binary pin, sem Lefthook/packages."

**Item do plano**: 0.12 (§17 Fase 0, Itens 0.1–0.12) · **Ordem de execução**: 008 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-008-pip-audit-trivy.md` (decisões D1–D10, Q1–Q10, nenhuma NEEDS CLARIFICATION)
**Contrato de entrada**: `specs/007-mypy/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011, ADR-015) + `docs/plan/implementation_plan.md` §§3–4, 11, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor já tem `ruff` (006) para lint `S` bandit e `mypy` (007) para tipos strict, mas **sem portão de vulnerabilidades** — cada `uv.lock` é gerado sem auditoria e `fs` nunca é escaneado para `HIGH,CRITICAL` ou `secret` leak, enquanto `implementation_plan §4/11` exige `pip-audit 2.10.1` (PyPA, `advisory-database` + `OSV` via `PyPI JSON`) + `Trivy 0.74.0` (Aqua, `fs`/`config`/`secret`/`sbom`). `pip-audit` é o único auditor de `uv.lock`/`env` do monorepo; `Trivy` cobre `fs`/`IaC`/`secret` que `ruff S` não pega; `Lefthook` (009) orquestrará, `gitleaks` (010) complementará — nenhum entra em 008 (Escada).

Este item entrega **exclusivamente** auditoria via `uv`: `pip-audit==2.10.1` em `[dependency-groups] dev`, `uv.lock` com hash, `Trivy 0.74.0` pin documentado `aquasec/trivy:0.74.0` (Go binary/Docker, não em `pyproject.toml`), `uv run pip-audit` 0 em env local sem vulns hoje (`No known vulnerabilities found`), `pip-audit --dry-run` coleta sem auditar, `pip-audit -f json`/`cyclonedx-json` válidos, oráculo `f0-008-pip-audit.sh` 12–16 asserções (inclui `specs/README.md` e `git ls-files` inquebráveis). Não cria `lefthook.yml` (009), `gitleaks` (010), `packages/` (011/012), `docker-compose.yml` (015) nem `requirements.txt`/`pylock.toml` — `uv.lock` permanece fonte única (D2).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (`[dependency-groups]` pin exato + `uv.lock` hash + `pip-audit 2.10.1` fixo + `Trivy 0.74.0` tag), **II** especificação precede código, **III** vermelho→verde preservado (`.sh` + `pip-audit`), **V** Lei Zero (trava versionada, cache não versionado, `dev` local-only), **VI** harness oráculo com 12–16 asserções novas + `pip-audit` nomeando FR, **VIII** elo verificado (PyPI `pip-audit 2.10.1` + `pip-audit --help` + GitHub `Trivy 0.74.0` + `uv --help` 2026-08-31), **X** observabilidade (falha nomeia `FR-XXX`).

---

## Clarifications

### Session 2026-08-31

- Q: Auditar `uv.lock` via `pip-audit --locked` com `pylock.toml` em 008? → A: **Não.** `uv.lock` não é `pylock.toml` (PEP 751). `pylock.toml` só em 013 (`uv export -o pylock.toml`) para SBOM. Em 008, `pip-audit` audita env local após `uv sync` (`.venv` materializado de `uv.lock`) — determinístico via lock, sem duplicar fonte (D2).
- Q: `Trivy` via `pip` ou `npm` ou Docker? → A: **Docker image `aquasec/trivy:0.74.0` ou Go binary `trivy_0.74.0_Linux-64bit.tar.gz` sigstore** — não entra em `[dependency-groups] dev` (Go, não Python). Em 008, `trivy fs .` sobre filesystem; `trivy image` só em 015 com `docker-compose`. Se `docker` ausente, oráculo marca `⏭️` skip, não falha (D3).
- Q: Gerar `SBOM cyclonedx` em 008? → A: **Não.** `cyclonedx-python-lib` já é transitive de `pip-audit 2.10.1`, mas `sbom.cyclonedx.json` e `pylock.toml` só em 013 (release). `pip-audit -f cyclonedx-json` validado no harness, mas sem artefato versionado em 008 (D4).
- Q: Adicionar `gitleaks` em 008? → A: **Não.** `gitleaks 8.30.1` é 010 `CI completo` + 009 `Lefthook`. Em 008, `Trivy secret` já cobre `fs` secrets, `gitleaks` complementará em 010 (D10).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Auditoria verde em clone limpo (Priority: P1)

Desenvolvedor clona em máquina limpa (sem `pip-audit` no env) e precisa obter **auditoria sem vulns** com `uv sync` + `uv run pip-audit` — saída determinística, sem `requirements.txt`, com `Trivy 0.74.0` pin documentado.

**Why this priority**: é o primeiro portão de supply chain. Sem `pip-audit`, cada `uv.lock` é gerado sem checar `advisory-database`/`OSV` e `urllib3` 2.7.0 com CVE passa silencioso — `ruff S` não pega CVE, `mypy` não pega vuln. `lefthook` (009) orquestraria `pip-audit` sem lock se `008` não existisse, e `010` (`uv sync --frozen` + `pip-audit` em CI) não teria `uv.lock`.

**Independent Test**: `uv sync` com `pip-audit==2.10.1` → `uv.lock` contém `pip-audit`; `uv run pip-audit --version` → `2.10.1`; `uv run pip-audit` 0 com `No known vulnerabilities found` no env de 41 pacotes.

**Acceptance Scenarios**:

1. **Given** clone sem `pip-audit` e `uv.lock` sem `pip-audit`, **When** `uv add --dev pip-audit==2.10.1` + `uv sync`, **Then** `pyproject.toml` contém `pip-audit==2.10.1` em `[dependency-groups] dev` e `uv.lock` contém `pip-audit 2.10.1` com hash, `.venv/bin/pip-audit` existe, `pip-audit --version` → `2.10.1`.
2. **Given** repo conforme com 41 pacotes, **When** `uv run pip-audit` (sem `--locked`/`-r`), **Then** exit 0 e `No known vulnerabilities found` ou `json` com `dependencies[].vulns[]` vazio; **When** injeta `pip-audit` fake vuln via `requirements` com CVE conhecido, **Then** `pip-audit` reprova com `vuln id` nomeado.
3. **Given** `pyproject.toml` sem `requirements.txt`, **When** `! test -f requirements.txt` e `! test -f pylock.toml`, **Then** fonte única mantida; `uv.lock` permanece lock universal.
4. **Given** repo conforme, **When** `uv run pip-audit --dry-run` + `uv run pip-audit` duas vezes, **Then** `would have audited` e segunda saída idêntica byte-a-byte e `<5s` cada (determinismo via `uv.lock` hash).

---

### User Story 2 — Trivy fs e compatibilidade ruff/mypy/pytest (Priority: P2)

Arquiteto precisa que `Trivy 0.74.0` escaneie `fs` para `vuln`/`secret`/`config` sem conflitar com `ruff` `target-version py312`, `mypy` `strict` ou `pytest`, e que `pip-audit` complemente `ruff S` (que já cobre `S603`/`S101` mas não CVE).

**Why this priority**: `Trivy fs` cobre `secret` leak (`.env` com `AWS_ACCESS_KEY`) e `misconfig` (`Dockerfile` sem `USER`) que `pip-audit` (só Python deps) não pega. Sem pin `0.74.0`, `Trivy` flutuante mudaria DB e geraria falso-positivo/negativo.

**Independent Test**: `trivy fs --severity HIGH,CRITICAL --format json .` lista `Results[].Vulnerabilities` quando provocado com `Dockerfile` vulnerável, mas não em repo limpo; `pip-audit` e `ruff S` coexistem sem conflito de `exclude`.

**Acceptance Scenarios**:

1. **Given** `Trivy 0.74.0` pin `aquasec/trivy:0.74.0`, **When** `docker run --rm aquasec/trivy:0.74.0 fs --severity HIGH,CRITICAL --format json .` em repo sem CVE HIGH, **Then** `Results` vazio ou só `LOW/MEDIUM` ignorados; **When** Docker ausente, **Then** oráculo marca `⏭️` skip, não `🔴`.
2. **Given** `ruff` `S` bandit com `S603` e `pip-audit` em `dev`, **When** `uv run ruff check .` + `uv run pip-audit` + `uv run mypy --strict .` + `uv run pytest -q`, **Then** todos 0 sem conflito de `exclude`/`cache`.
3. **Given** `pip-audit -f cyclonedx-json` + `cyclonedx-python-lib`, **When** `uv run pip-audit -f cyclonedx-json -o /tmp/sbom.json`, **Then** `/tmp/sbom.json` válido `bomFormat CycloneDX` sem reprovar harness (D4).
4. **Given** `Trivy 0.74.0` vs `0.69.4` com CVE-2026-33634, **When** pin é `0.74.0`, **Then** não usa `0.69.4` vulnerável (supply chain).

---

### User Story 3 — Fronteira, cache e CONVERGE (Priority: P3)

Mantenedor roda `pip-audit` e precisa ver **fronteira** (sem `lefthook`/`packages`/`gitleaks`), **cache ignorado** (`.pip-audit`/`trivy DB` não versionado), e **CONVERGE** (`tasks.md` zero `[ ]`) — tudo via `pip-audit` e `f0-008-pip-audit.sh`, sem tocar `f0-007`.

**Why this priority**: Escada e `ADR-015d` (CONVERGE fecha lista). Sem fronteira, `008` anteciparia `lefthook`/`packages` e quebraria `009`/`011`.

**Independent Test**: `! test -f lefthook.yml && ! test -f gitleaks.toml && ! test -d packages` + `! git ls-files | grep pip-audit` + `grep -E -c "^- \[ \]" specs/008-pip-audit-trivy/tasks.md` → 0.

**Acceptance Scenarios**:

1. **Given** `pyproject.toml` com `pip-audit` em `dev`, **When** `! test -f lefthook.yml` e `! test -f .gitleaks.toml`, **Then** fronteira mantida; `Trivy` pin documentado sem artefato versionado.
2. **Given** `.gitignore` sem `.pip-audit` e `pip-audit` cache em `~/.cache/pip`, **When** `uv run pip-audit` cria cache, **Then** `git status --porcelain` não lista cache e `git check-ignore` não precisa (cache fora do repo).
3. **Given** `specs/008-pip-audit-trivy/tasks.md` com 30 tasks, **When** todas `[x]`, **Then** `f0-008-pip-audit.sh` `FR-013` CONVERGE passa; com 1 `[ ]` reprova nomeando `FR-013`.
4. **Given** `f0-008-pip-audit.sh`, **When** `--list` e `--quiet` e `FKX_ORACLE_NESTED=1`, **Then** `CANON_ORDER` 12–16 IDs, `exit 0/1/2`, `EPOCHSECONDS <5s`, `2× cmp` idêntico.

---

### Edge Cases

- **`pip-audit` com vuln HIGH em `urllib3` 2.7.0.** Deve reprovar — `uv run pip-audit` exit 1 com `vuln id` e `fix` sugerido (D1).
- **`Trivy` sem Docker daemon.** Deve `⏭️` skip, não `🔴` — `docker --version` mas `docker info` falha, oráculo marca `⏭️` para `trivy fs` (D3).
- **`pip-audit --ignore-vuln PYSEC-...` sem justificativa.** Deve reprovar — `FR-014` exige `--ignore-vuln` só com ADR quando CVE falso-positivo (D10).
- **`requirements.txt` existe além de `uv.lock`.** Deve reprovar — `uv.lock` é fonte única, `requirements.txt` fragmenta (D2).
- **`gitleaks` detecta `AWS_ACCESS_KEY` em `tests/`.** `008` não exige `gitleaks`, `Trivy secret` já cobre; `gitleaks` é 010 — `f0-008` não deve reprovar se `gitleaks` ausente (D10).
- **`pip-audit --locked` sem `pylock.toml`.** Deve reprovar — `pylock.toml` só em 013, `pip-audit` em 008 usa env local (D2).
- **`cyclonedx` sem `pip-audit` vuln.** `pip-audit -f cyclonedx-json` deve gerar SBOM válido mesmo sem vulns (D4).
- **`Trivy 0.69.4` com CVE-2026-33634.** Deve reprovar se pin for `0.69.4` — `0.74.0` é min (D3).

---

## Requirements *(mandatory)*

### Functional Requirements

**Artefato raiz e auditoria local (D2)**

- **FR-001**: O sistema MUST declarar `pip-audit==2.10.1` (exato) em `[dependency-groups] dev` em `pyproject.toml` (PEP 735, `uv add --dev pip-audit==2.10.1`), sem `pip-audit` em `[project.dependencies]` nem `requirements*.txt`/`pylock.toml` em 008 (D1/D5).
- **FR-002**: O sistema MUST NOT prover `pip-audit` config separado `pip-audit.toml`/` .pip-audit.toml` nem `[tool.pip-audit]` em `pyproject.toml` — auditoria é via `uv run pip-audit` sem config file (D2).
- **FR-003**: O sistema MUST prover `pip-audit` com hash em `uv.lock` (`grep 'name = "pip-audit"'` + `tomllib` válido + `uv lock --check` quando `uv` presente) e `pip-audit --version` → `2.10.1` e `pip-audit --help` lista `cyclonedx-json`/`cyclonedx-xml` e `--fix` (D1/D5, Q1).
- **FR-004**: O sistema MUST prover `Trivy 0.74.0` pin documentado (não em `pyproject.toml` dev) — `aquasec/trivy:0.74.0` Docker image + `trivy_0.74.0_Linux-64bit.tar.gz` binary sigstore, verificável via `docker image inspect` ou `trivy --version` quando disponível; `Trivy` MUST NOT estar em `[dependency-groups] dev` nem `requirements*.txt` (D3, Q3).

**Trava e cache (D5/D8)**

- **FR-005**: `uv.lock` MUST conter `pip-audit` e `cyclonedx-python-lib`/`cachecontrol`/`packaging` transitivos, `tomllib` válido, `uv lock --check` 0 (D1/D5, Q1).
- **FR-006**: `.pip-audit` cache e `Trivy` DB (`~/.cache/trivy`) MUST NOT ser versionados — `git ls-files | grep pip-audit` vazio e `git check-ignore` não precisa (cache fora do repo), `uv.lock` MUST NOT ser ignorado (D8, `.gitignore`).

**Auditoria determinística (D3/D4)**

- **FR-007**: `uv run pip-audit` (sem `--locked`/`-r`, env local após `uv sync`) MUST sair 0 em repo sem vulns hoje e 1 com vuln injetada (ex.: `urllib3` CVE) com `FR-XXX` nomeado, e `uv run pip-audit --dry-run` MUST coletar `would have audited` sem falhar (D2, Q1/Q9).
- **FR-008**: `uv run pip-audit -f json` MUST sair 0 com `json` válido `dependencies[].vulns[]` e `uv run pip-audit -f cyclonedx-json -o /tmp/sbom.json` MUST gerar `bomFormat CycloneDX` válido mesmo sem vulns (D4, Q4).
- **FR-009**: `Trivy fs` (`trivy fs --severity HIGH,CRITICAL --format json .` ou `docker run aquasec/trivy:0.74.0 fs ...`) MUST sair `0` com status `⏭️` skip (linha `⏭️ FR-009 ...`) se Docker/binary ausente (`docker info` falha), e sair `0` com `Results` vazio (`0 vulns HIGH,CRITICAL`) em repo limpo quando disponível; MUST NOT exigir `lefthook.yml`/`gitleaks` (D3, Q3/Q9).

**Harness e CI (D9/D10)**

- **FR-010**: O sistema MUST prover oráculo `scripts/verify/f0-008-pip-audit.sh` com 12–16 asserções, `CANON_ORDER` 12–16, `exit 0/1/2`, `--quiet` só violações, `--list` enumera, `FKX_ORACLE_NESTED`, `EPOCHSECONDS <5s`, `2× cmp` idêntico (Q9, D9, oracle-cli.md).
- **FR-011**: `CI` `003` (`/.github/workflows/ci.yml` `for f in scripts/verify/f0-*.sh`) MUST incluir `f0-008` sem editar `ci.yml` (Q9, D9, FR-012 de 007).
- **FR-012**: CONVERGE — `specs/008-pip-audit-trivy/tasks.md` MUST ter zero `[ ]` quando `f0-008` sai 0 — asserido por `f0-008` `grep -E "^- \[ \]"` (ADR-015d, Q10).
- **FR-013**: Fronteira Escada — MUST NOT conter `lefthook.yml`, `gitleaks`/`pip-audit.toml`, `packages/` com `pyproject.toml`, `docker-compose.yml`, `requirements.txt` com `pip-audit`, `cyclonedx` SBOM artefato — qualquer presença reprova (constitution Additional Constraints, Q10, D10).
- **FR-014**: `specs/README.md` MUST conter `008` com `pip-audit` `✅` e `hash` `62d2a91` e `007` `✅` com `a60c5b4` e `009` `⏳` — `grep -iq "008.*pip-audit.*✅.*62d2a91" specs/README.md` e `grep -iq "007.*mypy.*✅.*a60c5b4"` (inquebrável em escala, ADR-011).
- **FR-015**: `specs/008-pip-audit-trivy/spec.md` e `docs/plan/research/f0-008-pip-audit-trivy.md` MUST estar rastreados por git (`git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md` 0) — `??` reprova (commit inquebrável).
- **FR-016**: `Trivy` 0.74.0 MUST NOT ser `0.69.4` vulnerável e `pip-audit` MUST NOT ser `<2.10.1` — `grep -q "0.69.4"` reprova e `pip-audit --version` 2.10.1 (D3, Q1).

### Key Entities

- **pip-audit strict**: `pip-audit==2.10.1` em `dev` + `uv.lock` hash + `cyclonedx-python-lib` transitive + `pip-audit --version`/`--help` `cyclonedx`/`--fix`.
- **Trivy pin**: `aquasec/trivy:0.74.0` Docker image + binary sigstore, `fs`/`config`/`secret` scanners, skip se Docker ausente.
- **Manifest**: `scripts/verify/manifest.sha256` 8 linhas (001..008) após 008, `sha256sum -c` 0.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Dev em clone limpo com `pip-audit 2.10.1` obtém `pip-audit 2.10.1` com `uv sync` e `uv run pip-audit` passa sem vulns sem config file separado.
- **SC-002**: `uv run pip-audit --dry-run` coleta `would have audited` e `uv run pip-audit -f json` gera `dependencies[].vulns[]` válido 100% observável.
- **SC-003**: `uv run pip-audit --version` → `2.10.1` e `pip-audit --help` lista `cyclonedx-json` e `--fix` em 100%.
- **SC-004**: `f0-008-pip-audit.sh` `12/16` ou `16/16` em `<5s` com `EPOCHSECONDS` e `2× cmp` idêntico 100%.
- **SC-005**: Injeção de `lefthook.yml` ou `gitleaks.toml` → `f0-008` reprova `FR-013` em 100% (fronteira).
- **SC-006**: `for f in f0-*.sh; do "$f" --quiet || exit 1; done` inclui `f0-008` sem diff em `ci.yml` — harness 8/8 verde.
- **SC-007**: `tasks.md` zero `[ ]` quando `f0-008` sai 0 — CONVERGE (ADR-015d) via `grep -E "^- \[ \]"`.
- **SC-008**: Nenhum artefato `009–016` (`lefthook`, `packages/`, `docker-compose`) aparece no diff de `008` — fronteira 100% preservada.

## Assumptions

- `pip-audit 2.10.1` latest estável 2026-08-31 (upload `2026-06-10`, `>=3.10` compatível com `>=3.12,<3.14`); `Trivy 0.74.0` latest 2026-08-14 (Go, 50 assets, sigstore); `gitleaks 8.30.1` e `cyclonedx-bom 7.3.1` deferidos a 010/013.
- Python `3.12.3` local e `3.12.14` runner `setup-python@v7`; `requires-python >=3.12,<3.14` alinha.
- `.gitignore` já ignora `__pycache__`/` .venv`/` .ruff_cache`/` .mypy_cache` — sem edição em 008; `001` D3 sem `*.lock` preservado.
- `pip-audit` consulta `PyPI JSON`/`OSV` online — baseline hoje `No known vulnerabilities found` para 41 pacotes; se futura CVE surgir, harness permitirá `--ignore-vuln` com ADR.
- `Trivy` sem Docker em Fase 0 `003` CI é `⏭️` skip, não `🔴` — `015` `docker-compose` trará `Trivy` serviço.

## Dependencies

- `001` Git + branching — `.gitignore` sem `*.lock`, harness 30/30.
- `007` MyPy — `[tool.mypy]` `strict` 2.3.1, `uv.lock` com `mypy` hash, `manifest 7/7`.
- `006` Ruff — `[tool.ruff]` `py312` com `S` bandit, `uv.lock` com `ruff`, `manifest 7/7`.
- `005` Pytest — `tests/` 13 passed em 008 (7 oráculos + 1 list + 5 dívidas).
- `uv 0.12.7` e `pip-audit 2.10.1`/`Trivy 0.74.0` — elos verificados `docs/plan/research/f0-008-pip-audit-trivy.md` Q1/Q3 contra PyPI `2.10.1` + GitHub `0.74.0` + `pip-audit --help` 2026-08-31; `uv --help`.
- ADR-011 mapa 16 posições fixa `008 → 0.12` após `007` (0.3) antes de `009` (0.5) — escada.

## Contratos

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **009 Lefthook** | `uv.lock` com `pip-audit 2.10.1` hash auditável + `Trivy 0.74.0` pin documentado, orquestrável via `lefthook.yml` (`uv run pip-audit` + `trivy fs`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `pip-audit` em `uv.lock` para `uv run pip-audit` determinístico em CI + `gitleaks` `protect` + `Trivy` `fs` |
| **011 core / 012 cli** | `pyproject.toml` `[dependency-groups] dev` com `pip-audit` → escala para `packages/*` sem reescrever |
| **014 Renovate** | `pip-audit==2.10.1` pin para agrupamento e automerge |

### Recebido de itens anteriores

| Item | Contrato recebido |
|---|---|
| `001` | `.gitignore` sem `*.lock`, harness 30/30 |
| `007` | `[tool.mypy]` `strict` 2.3.1, `uv.lock` com `mypy` hash, `manifest 7/7` |
| `006` | `[tool.ruff]` `py312` com `S` bandit, `uv.lock` ruff, `manifest 7/7` |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **009** (`0.5` Lefthook) | `lefthook.yml` com `ruff` + `mypy --strict` + `pytest` + `pip-audit` + `trivy fs` | Orquestra `005`+`006`+`007`+`008` |
| **010** (`0.14`) | `pip-audit` + `gitleaks` em CI `uv run pip-audit` + `trivy fs` como `required check` | Pipeline completo |
| **013** (`0.15`) | `pip-audit -f cyclonedx-json` + `uv export --format cyclonedx/pylock.toml` + `cyclonedx-bom` SBOM | Release com SBOM |
| **015** (`0.8`) | `trivy image` + `docker-compose` com `trivy` serviço | `fs` vira `image` com container |

## Out of Scope

- `lefthook.yml` — `009` (Lefthook 2.1.11).
- `gitleaks`/`pip-audit --locked` com `pylock.toml` — `010`/`013`.
- `packages/core`/`cli` — `011`/`012`.
- `docker-compose.yml` — `015`.
- `cyclonedx` SBOM artefato — `013`.
- `trivy image` scan — `015` (008 só `fs`/`config`).
