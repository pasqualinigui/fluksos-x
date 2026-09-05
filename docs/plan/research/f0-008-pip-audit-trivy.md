# RESEARCH — F0/008 · pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades

> **Item do plano:** 0.12 (§17 Fase 0) · **Ordem de execução:** 008/016 (ADR-011)
> **Data da verificação:** 2026-08-31 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/007-mypy/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-011) + `docs/plan/implementation_plan.md` §§3–4, 11, 15, 17 + `specs/001-.../contracts/oracle-cli.md` + `pyproject.toml` (007) + `scripts/verify/README.md` (restrição) + `uv.lock` (007)

Este item entrega **o portão de segurança de supply chain do monorepo** (implementation_plan §4: `pip-audit 2.10.1` + `Trivy 0.74.0`). Até aqui o harness é `ruff` (linter `S` bandit via `extend-select S`) + `mypy strict` + `pytest` + shell; `pip-audit` é o primeiro verificador que **consulta advisory database externo** e `Trivy` é o primeiro que **escaneia filesystem/container/IaC** — por isso a fronteira com `Lefthook` (009, que orquestrará ambos) e `packages/*` (011/012) precisa ser fechada agora. Não cria `lefthook.yml` nem `packages/` — estes são specs 009 e 011/012 (Escada).

---

## Q1 — Qual pin canônico de `pip-audit` 2.10.1 e o que traz vs `pip-audit` 2.9.x?

**Fonte:** `https://pypi.org/pypi/pip-audit/json` + `.../pip-audit/2.10.1/json` + `https://pypi.org/simple/pip-audit/` + `https://github.com/pypa/pip-audit/releases/tag/v2.10.1` + `uv run --with pip-audit==2.10.1 pip-audit --help` + `uv run --with pip-audit==2.10.1 pip-audit --version` — HTTP 200, fetch 2026-08-31.

Evidências:

```
pip-audit        2.10.1  requires_python='>=3.10' upload 2026-06-10T22:17:00Z
  simple index last 10: ['2.6.3','2.7.0','2.7.1','2.7.2','2.7.3','2.8.0','2.9.0','2.10.0','2.10.1'] → 2.10.1 é latest estável
  summary: A tool for scanning Python environments for known vulnerabilities
  requires_dist: ['CacheControl[filecache]>=0.13.0', 'cyclonedx-python-lib<12,>=5', 'packaging>=23', 'pip-api>=0.0.28', 'pip-requirements-parser>=32', 'requests>=2.31', 'rich>=12.4', 'tomli>=2.2.1', 'tomli-w>=1.2', 'platformdirs>=4.2']
  GitHub release v2.10.1 tag 2026-06-10: Fixed KeyError crash when OSV omite ranges (PR #1046)
```

`pip-audit --help` (extraído `uv run --with pip-audit==2.10.1`):

```
pip-audit 2.10.1
usage: pip-audit [-h] [-V] [-l] [-r REQUIREMENT] [--locked] [-f FORMAT]
                 [--desc [{on,off,auto}]] [--fix] [--ignore-vuln ID]
                 [--disable-pip] [project_path]

  -l, --local              show only results for dependencies in the local environment
  -r REQUIREMENT           audit the given requirements file (multiple)
  --locked                 audit lock files from the local Python project (project_path only)
  -f FORMAT                the format to emit audit results in (choices: columns, json, cyclonedx-json, cyclonedx-xml, markdown)
  -s SERVICE               vulnerability service (choices: osv, pypi, esms) default pypi
  --fix                    automatically upgrade dependencies with known vulnerabilities
  -o FILE, --output        output results to the given file
  --ignore-vuln ID         ignore a specific vulnerability by ID (multiple)
  --disable-pip            don't use pip for dependency resolution (hash-only or --no-deps)
```

Novidades 2.10.x vs 2.9.x (extraído de `CHANGELOG` + `release`):

* `2.10.1` fixa `KeyError` quando `OSV` `affected` omite `ranges` (regressão de `2.10.0`).
* `2.10.0` introduz `cyclonedx-python-lib<12` compat (antes `<11`) e `CacheControl` filecache.
* `2.9.0` (2025-04-07) já trazia `--locked` para auditar `pylock.toml`/`uv.lock` via `project_path`.

**Achado estrutural hoje:** `pyproject.toml` sem `pip-audit` em `[dependency-groups] dev`; `which pip-audit → not installed` (via `uv` apenas); `uv.lock` contém `mypy 2.3.1` + `ruff 0.16.5` + `pytest 9.1.1` com hash, sem `pip-audit`; `pip-audit --dry-run` em repo com 41 pacotes (via `uv run --with`) → `Dry run: would have audited 41 packages` / `No known vulnerabilities found`.

**Decisão (D1):** pin canônico em **2026-08-31**:

```toml
[dependency-groups]
dev = ["pip-audit==2.10.1", "mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", ...]
```

* `pip-audit==2.10.1` — latest estável, `>=3.10` compatível com `requires-python >=3.12,<3.14` e com `ruff`/`mypy` `py312`.
* Não pinar `2.9.0` — perde fix `KeyError` OSV; não pinar `<2.8` — perde `--locked` e `cyclonedx` v2.

**Alternativa rejeitada:** `safety` (Safety API, pago, licença proprietária, requer token) — `pip-audit` é `PyPA/Google` Apache-2.0, usa `advisory-database` + `OSV` via `PyPI JSON`, sem token; `pip-audit>=2` flutuante — indeterminístico; `bandit` separado — `ruff` já re-implementa `S` (Q7).

---

## Q2 — `pip-audit` via `uv.lock` / `pylock.toml` / `requirements.txt` vs `local env`?

**Fonte:** `https://pypi.org/project/pip-audit/` (docs `pip-audit` 2.10.1) + `uv run --with pip-audit==2.10.1 pip-audit --help` (`--locked`, `--disable-pip`, `-r`) + `https://docs.astral.sh/uv/concepts/projects/layout/#the-project-environment` (PEP 751 `pylock.toml`) — fetch 2026-08-31.

Evidências (texto extraído):

> *"`--locked` audit lock files from the local Python project. This flag only applies to auditing from project paths"* — `pip-audit --help`
> *"`--disable-pip` don't use pip for dependency resolution; this can only be used with hashed requirements files or if the `--no-deps` flag has been provided"*
> *"`-r REQUIREMENT` audit the given requirements file; this option can be used multiple times"*
> *"`uv.lock` format is specific to uv and not usable by other tools. ... `pylock.toml` (PEP 751) is intended to replace `requirements.txt` ... uv supports `pylock.toml` as an export target."* — `docs/plan/research/f0-004-uv-workspace.md` Q2

**Achado:** `pyproject.toml` com `[dependency-groups] dev` + `uv.lock` na raiz é fonte única do workspace (004). `pip-audit` pode auditar de três formas: (a) `pip-audit` sem args → resolve `pip` local `+ .venv`; (b) `pip-audit -r requirements.txt` → arquivo hash; (c) `pip-audit --locked` com `project_path` → `pylock.toml` (quando existir). `uv.lock` **não é** `pylock.toml` — `pip-audit` não lê `uv.lock` diretamente sem `pylock.toml` exportado. Em Fase 0 (sem `pylock.toml` ainda, ver `f0-004` D2), a forma determinística é `pip-audit` no env local após `uv sync` (que materializa `dev` em `.venv`).

**Decisão (D2):**

* **Em 008 (Fase 0, sem `pylock.toml`):** `pip-audit` audita **o ambiente local** após `uv sync` — `uv run pip-audit` sem `--locked`/`-r`, lendo `.venv` materializado. É determinístico porque `.venv` vem de `uv.lock` hash (004) e `pip-audit` consulta `PyPI JSON`/`OSV` online.
* **Em 013 (release, 0.15):** `uv export --format pylock.toml -o pylock.toml` + `pip-audit --locked` sobre `pylock.toml` — SBOM e auditoria travada.
* **Não criar** `requirements.txt` nem `pylock.toml` em 008 — `uv.lock` permanece fonte única; `pylock.toml` é exportado em 013 quando `SBOM/cyclonedx` for publicado (evita duplicar fonte de verdade, Q6).

**Alternativa rejeitada:** `pip-audit -r requirements.txt` — fora do lock universal, quebra `uv sync --frozen`; `pip-audit --locked` em 008 sem `pylock.toml` — falharia (`pylock.toml` não existe); `pip-audit --disable-pip` — só com hashes, não se aplica a env local.

---

## Q3 — Qual pin canônico de `Trivy` 0.74.0 e modos `fs`/`image`/`config`?

**Fonte:** `https://github.com/aquasecurity/trivy/releases/tag/v0.74.0` (2026-08-14) + `https://api.github.com/repos/aquasecurity/trivy/releases/latest` + `https://trivy.dev/docs/latest/` (scanners/targets) + `docker --version` (29.7.2) + `which trivy → not installed` — HTTP 200, fetch 2026-08-31.

Evidências:

```
Trivy            0.74.0  tag 2026-08-14T11:29:11Z, 50 assets, Alpine/Debian/RPM, attested via Sigstore
  latest stable: v0.74.0 (v0.73.0 2026-08-03, v0.72.0 2026-06-30) → 0.74.0 é latest
  summary: Find vulnerabilities, misconfigurations, secrets, SBOM in containers, Kubernetes, code repositories, clouds
  scanners: vuln, secret, config (misconfig), sbom
  targets: Container Image, Filesystem, Git Repository, VM Image, Kubernetes
  assets: aquasec/trivy:0.74.0 (Docker Hub), trivy_0.74.0_Linux-64bit.tar.gz (Go binary), checksums.txt + sigstore.json
```

Docs `trivy.dev` (extraído):

> *"Trivy has scanners that look for security issues, and targets where it can find those issues. Targets: Container Image, Filesystem, Git Repository, VM Image, Kubernetes, Cloud ... Scanners: vuln, misconfig, secret, license, sbom"*
> *"trivy fs .  → scan filesystem; trivy image python:3.12 → scan image; trivy config . → scan IaC misconfigurations (Dockerfile, K8s, Terraform)"*

**Achado estrutural hoje:** `which trivy → not installed`; `docker --version 29.7.2` mas `docker daemon` não roda por padrão (plan Environment: Docker ligado sob demanda, `restart: always` proibido); `f0-006` `ruff S` já cobre `S603`/`S101` mas não `cve` em `uv.lock`; `pip-audit` cobre `uv.lock` Python, `Trivy` cobre `fs` secrets + `config` misconfig + `image` quando `docker-compose` (015) chegar.

**Decisão (D3):** pin canônico em **2026-08-31**:

```toml
# Trivy não entra em [dependency-groups] dev — é Go binary / Docker image, não Python.
# Pin é tag Docker + binary checksum:
Trivy            0.74.0  aquasec/trivy:0.74.0 (Docker) / trivy_0.74.0_Linux-64bit.tar.gz (binary, sigstore)
```

* Em 008 (sem `docker-compose` ainda, 015): **Trivy `fs` sobre o filesystem** — `trivy fs --format json --severity HIGH,CRITICAL .` + `trivy config .` para IaC, sem `image` (sem `Dockerfile` do motor ainda além de futuro `015`).
* Se `docker` não estiver disponível no harness (Fase 0, `003` CI mínimo sem Docker), **Trivy é `⏭️` (skip) no oráculo**, não falha — Fase 0 `003` CI não tem Docker; `015` trará `docker-compose` com `Trivy` serviço.
* Não pinar `0.69.4` — contém CVE-2026-33634 chain de supply via credencial (alert 2026-03-27, Tenable, CISA até 2026-04-09); `0.74.0` é patch.

**Alternativa rejeitada:** `Trivy` via `pip` (não existe, Go); `0.73.x` flutuante — indeterminístico; `Trivy` como `dev` Python dep — viola `Motor 100% Python`? Não, mas `Trivy` é Go, não Python, não deve entrar em `pyproject.toml`.

---

## Q4 — Como `pip-audit` e `Trivy` se relacionam com `cyclonedx`/`SBOM` e `uv export`?

**Fonte:** `https://pypi.org/pypi/cyclonedx-bom/json` (7.3.1, `<4.0,>=3.9`) + `https://pypi.org/pypi/cyclonedx-python-lib/json` (11.12.0) + `uv run --with pip-audit==2.10.1 pip-audit --help` (`-f cyclonedx-json/xml`) + `docs/plan/research/f0-004-uv-workspace.md` D2 (`uv export --format cyclonedx/pylock`) — fetch 2026-08-31.

Evidências:

```
cyclonedx-bom    7.3.1  (<4.0,>=3.9)  Tools: cdx-bom, cyclonedx CLI
cyclonedx-python-lib 11.12.0  (pip-audit requires_dist: cyclonedx-python-lib<12,>=5)
pip-audit -f     cyclonedx-json, cyclonedx-xml  (formats for SBOM)
uv export        --format cyclonedx1.5 / pylock.toml  (SBOM para release)
```

**Decisão (D4):**

* **Em 008:** `pip-audit` **sem `cyclonedx` no harness** — `pip-audit -f json` ou `columns` para humano, `cyclonedx-json` só em 013 quando SBOM acompanha release. `uv` já tem `cyclonedx-python-lib` como transitive de `pip-audit 2.10.1`, não precisa declarar `cyclonedx-bom` separado em 008.
* **Em 013 (0.15, Automação de release):** `uv export --format cyclonedx1.5 -o sbom.cyclonedx.json` + `pip-audit -f cyclonedx-json` + `cyclonedx-bom` gera SBOM anexado ao release via `python-semantic-release` + trusted publishing (OIDC). `pylock.toml` (PEP 751) exportado junto.
* **Não criar** `sbom.cyclonedx.json` nem `pylock.toml` em 008 — evita duplicar fonte de verdade antes do pipeline de release.

**Alternativa rejeitada:** `cyclonedx-bom 7.3.1` em `[dependency-groups] dev` em 008 — SBOM só em 013, não antes; `pip-audit --locked` com `pylock.toml` em 008 — `pylock.toml` não existe até 013.

---

## Q5 — Como declarar `pip-audit` via `uv` sem quebrar `ruff`/`mypy`/`pytest`?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/dependencies/` (PEP 735) + `pyproject.toml` (007) `dev = ["mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", ...]` + `uv add --help` — fetch 2026-08-31.

Evidência (repetida de Q4/Q6 de 005/006/007):

> *"`uv add --dev pip-audit` will create a `dev` group: `[dependency-groups] dev = [\"pip-audit\"]`"* — `dev` é `default-groups = ["dev"]`, `uv sync` instala `dev`.

**Decisão (D5):**

```bash
uv add --dev pip-audit==2.10.1   # → [dependency-groups] dev = ["pip-audit==2.10.1", "mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", ...]
uv sync
```

* Resultado `pyproject.toml`:

```toml
[dependency-groups]
dev = ["pip-audit==2.10.1", "mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

* `uv.lock` passa a conter `pip-audit 2.10.1` + `cyclonedx-python-lib` `cachecontrol` `pip-api` `requests` `rich` com hash (universal). `uv sync --no-dev` omite para `013` release.
* `Trivy` **não** entra em `dev` — é Go/Docker, pin é tag `aquasec/trivy:0.74.0` + checksum, ver D3.

**Alternativa rejeitada:** `pip-audit` sem `dev` — `uv run pip-audit` falharia em CI sem `pip install`; `requirements-dev.txt` — fora do lock universal, quebra `uv sync --frozen`; `[tool.uv.dev-dependencies]` legado — deprecated.

---

## Q6 — Compatibilidade `pip-audit`/`Trivy` com `ruff` `S` bandit, `mypy strict`, `pytest`?

**Fonte:** `docs/plan/research/f0-006-ruff.md` D7 (`ruff S` bandit) + `docs/plan/research/f0-007-mypy.md` D7 (compat `ruff` `py312` + `mypy`) + `https://docs.astral.sh/ruff/rules/#flake8-bandit` (S) — fetch 2026-08-31.

Evidências:

* `ruff` `S` cobre `S603`/`S607` (subprocess sem `shell=True`, `start_process` sem `shell` ) e `S101` (assert) — é o `security_scan` que `pip-audit` **complementa** (vulns em deps, não em código). `ruff` `S` não detecta CVE em `urllib3` 2.7.0, `pip-audit` detecta.
* `mypy` `strict` com `python_version 3.12` não conflita com `pip-audit` (que lê `uv.lock`, não `pyproject.toml` `exclude`).
* `pytest` `tests/` com `def test_foo():` sem `-> None` — `mypy` `overrides` já relaxa (007 D4), `pip-audit` não afeta `pytest` (é dev dep, não runtime).

**Decisão (D6):**

* Em 008, `pip-audit` é **segundo portão de segurança de supply chain** (primeiro foi `ruff S` em 006). `Trivy` `fs`/`config` é **terceiro** (secrets, misconfig). Cada um cobre superfície distinta, sem sobreposição que gere conflito.
* `ruff` `S` permanece `ignore S101/S603` em `tests/**/*` (006 D3) — `pip-audit` não muda isso; `Trivy` `secret` flagaria `.env` se existisse, mas `.env` já é Lei Zero (001).
* Nenhum `per-file-ignores` novo para `pip-audit`/`Trivy` — `pip-audit` ignora via `--ignore-vuln ID` (quando necessário, ver Q10).

**Alternativa rejeitada:** `bandit` separado — redundante, `ruff S` já cobre; `safety` — pago, token; `pip-audit` como `ruff` rule — não existe.

---

## Q7 — Quais vulnerabilidades já cobertas (`ruff S`, `trivy` secret) e como `pip-audit` as complementa?

**Fonte:** `https://pypi.org/pypi/pip-audit/json` (advisory via OSV/PyPI) + `https://trivy.dev/docs/latest/scanner/secret/` (secret detector) + `docs/plan/addendum_v3.md` (Secrets Lei Zero) — fetch 2026-08-31.

Evidências:

* `pip-audit` consulta `advisory-database` + `PyPI JSON` + `OSV` (`https://api.osv.dev/v1/query`) para CVEs em `urllib3`, `certifi`, `requests`, etc.
* `Trivy` `secret` detecta `AWS_ACCESS_KEY`, `GITHUB_TOKEN`, `PRIVATE_KEY` em `fs` e `config`.
* `ruff S` já detecta `S603`/`S607`/`S101` em código, mas não CVE em `requests 2.34.2`.

**Decisão (D7):**

* Em 008, `pip-audit` audita **41 pacotes** do env local (via `uv run pip-audit --dry-run` hoje: `would have audited 41 packages`, `No known vulnerabilities found`).
* `Trivy fs --scanners secret,config` audita **segredos e misconfigurações** (`Dockerfile` futuro, `.env`).
* `pip-audit` é para **deps Python**, `Trivy` para **fs/config/image** — não há sobreposição, ambos necessários para 010 `CI completo` (que junta `pip-audit` + `gitleaks` + `trivy`).

**Alternativa rejeitada:** `snyk` — pago, token, fora do escopo `Motor 100% Python`; `dependabot` sem `pip-audit` — só abre PR, não audita local.

---

## Q8 — Como `pip-audit`/`Trivy` interagem com `.gitignore`, `cache`, `baseline`?

**Fonte:** `https://pip.pypa.io/en/stable/topics/caching/` (pip cache) + `.gitignore` (`.pytest_cache` 99, `.ruff_cache` 254, `.mypy_cache` 217, `.venv` 200) + `pip-audit --help` (`--cache-dir`, `--disable-pip`) — fetch 2026-08-31.

Evidências:

> *"`pip-audit` uses the pip HTTP cache by default; --cache-dir overrides"*
> *"`pip-audit --disable-pip` don't use pip for dependency resolution; can only be used with hashed requirements files"*

**Achado:** `.gitignore` já ignora `.pytest_cache`, `.ruff_cache`, `.mypy_cache`, `.venv` — correto, mas `pip-audit` **não** lê `.gitignore` para decidir o que auditar; ele audita o env local. `pip-audit` cache vive em `~/.cache/pip` ou `--cache-dir`, não em `.pip-audit/` no repo.

**Decisão (D8):**

* `pip-audit` em 008 **sem `--cache-dir` explícito** — usa cache padrão do `pip` (determinístico, não versionado). Não criar `.pip-audit/` no repo.
* `Trivy` cache DB vive em `~/.cache/trivy` (quando binary) ou Docker volume; em CI `003` `ubuntu-24.04` sem Docker, `Trivy` é skip (ver D3/D10).
* **Baseline:** `pip-audit` sem vulnerabilidades hoje (`No known vulnerabilities found`); se futura audit encontrar CVE, `--ignore-vuln ID` será usado com justificativa em `pyproject.toml` ou `pip-audit` config (ver Q10, D10).

**Alternativa rejeitada:** `--cache-dir .pip-audit` no repo — criaria cache versionável, viola Lei Zero (V); `pip-audit --disable-pip` em 008 sem hashes — falharia (`--disable-pip` requer `--require-hashes`).

---

## Q9 — O que o harness de 008 deve verificar (e o que NÃO verificar)?

**Fonte:** `specs/001-.../contracts/oracle-cli.md` + `scripts/verify/README.md` (restrição `007+ MyPy`, `008+ pip-audit`) + `specs/007-mypy/contracts/oracle-cli.md` — fetch 2026-08-31.

Evidência restrição:

> *"Um oráculo que exija ferramenta ainda não instalada no seu ponto do bootstrap está errado, ainda que funcione na máquina de quem o escreveu."* — `README.md:79` (restrição por item).

**Decisão (D9):** `f0-008-pip-audit.sh` com **12–16 asserções** (similar a `f0-007`):

| FR candidato | Verificável por harness | Como |
|---|---|---|
| `pip-audit==2.10.1` em `[dependency-groups] dev` | sim | `tomllib` parse |
| `pip-audit` **não** em `[project.dependencies]` | sim | `tomllib` |
| `uv.lock` contém `pip-audit` + `cyclonedx-python-lib` | sim | `grep 'name = "pip-audit"'` + `uv lock --check` |
| `uv run pip-audit --version` 2.10.1 | sim | `uv run pip-audit --version` |
| `uv run pip-audit --help` lista `cyclonedx-json` e `--fix` | sim | `grep -q cyclonedx-json` |
| `uv run pip-audit` (local env) 0 sem vulns | sim | `uv run pip-audit` (quando `pip-audit` instalado) |
| `uv run pip-audit --dry-run` não audita, só coleta | sim | `grep -q "would have audited"` |
| `trivy --version` ou `aquasec/trivy:0.74.0` presente quando Docker disponível | sim | `docker image inspect aquasec/trivy:0.74.0` ou `trivy --version` |
| `gitleaks` **não** exigido em 008 (é 010) | sim | `! grep -q gitleaks pyproject.toml` |
| Fronteira: sem `lefthook.yml`/`packages/`/`mypy.ini` separado | sim | `! test -f lefthook.yml` etc. |
| `pip-audit` não em `requirements*.txt` | sim | `! test -f requirements.txt` com `pip-audit` |

**NÃO verificar em 008** (Escada):

* `lefthook.yml` (`009`, orquestra `pip-audit`/`trivy` + `ruff`/`mypy`/`pytest`).
* `gitleaks`/`pip-audit --locked` com `pylock.toml` (`010`/`013`, precisam `pylock.toml`).
* `packages/` (`011`/`012`), `docker-compose` (`015`).

**Decisão (D9):** oráculo `f0-008-pip-audit.sh` segue `oracle-cli.md` (`0`/`1`/`2`, `--quiet`, `--list`, `CANON_ORDER`, `FKX_ORACLE_NESTED`, `EPOCHSECONDS`). `ruff`/`mypy`/`pytest` devem continuar passando (`self-check`).

---

## Q10 — Determinismo e fronteira Escada para `pip-audit`/`Trivy`?

**Fonte:** `constitution.md:176` (Escada) + `docs/plan/implementation_plan.md:835-846` (§17) + `specs/007-mypy/spec.md:190` (Out of Scope) — fetch 2026-08-31.

Evidência Escada:

> *"Nenhum artefato pode exigir ferramenta que ainda não existe no seu ponto do bootstrap."*

**Decisão (D10):**

* **Determinismo:** `pip-audit` consulta `PyPI JSON`/`OSV` online — `pip-audit 2.10.1` com `uv.lock` hash é determinístico **no input** (lock), mas **não** no tempo (advisory DB muda). Em 008, `pip-audit` sem `vulns` (`No known vulnerabilities found`) é o baseline; se futura CVE surgir, harness deve **permitir** `pip-audit` falhar com evidência `FR-XXX` e `--ignore-vuln` será adicionado com ADR. `Trivy` `fs` sem `image` é determinístico para `HIGH,CRITICAL` com DB local (quando `docker run aquasec/trivy:0.74.0 fs .`).
* **Fronteira Escada (008):** **NÃO** cria `lefthook.yml` (`009`), `gitleaks` (`010`), `packages/` (`011`/`012`), `mypy.ini` separado (é `pyproject.toml` em 007 per D2), `docker-compose.yml` (`015`). `pip-audit` é `dev` dep, não runtime; `Trivy` é Go/Docker, não entra em `pyproject.toml`.
* **CI:** `003` `ubuntu-24.04` sem Docker → `Trivy` skip (`⏭️`) em oráculo, não fail — `015` trará `docker-compose`.

**Decisão (D10):** em 008, garantir apenas `pyproject.toml` `[dependency-groups] dev` + `pip-audit==2.10.1` + `uv.lock` + `Trivy` pin documentado (não instalado se Docker ausente). Escala para `009` (`lefthook` orquestra `pip-audit` + `trivy fs`), `010` (`pip-audit` + `gitleaks` em CI `uv run pip-audit` + `gitleaks protect`).

---

## Resumo das decisões vinculantes

| # | Decisão | Fonte |
|---|---|---|
| D1 | `pip-audit==2.10.1` via `[dependency-groups] dev` (PEP 735), `uv sync` | Q1 PyPI 2026-06-10 |
| D2 | `pip-audit` audita env local após `uv sync` em 008; `pylock.toml`/`--locked` só em 013 (release) | Q2 pip-audit --help + uv pylock |
| D3 | `Trivy 0.74.0` via `aquasec/trivy:0.74.0` (Docker) / binary tar.gz sigstore, `fs`/`config` em 008, `image` em 015 | Q3 GitHub 2026-08-14 |
| D4 | `cyclonedx-python-lib<12` transitive de `pip-audit`, `uv export --format cyclonedx1.5` e `pylock.toml` só em 013 | Q4 PyPI cyclonedx + uv export |
| D5 | `uv add --dev pip-audit==2.10.1` → `dev` com `pytest`+`ruff`+`mypy`+`pip-audit` | Q5 uv docs |
| D6 | Compat `pip-audit` sem conflito `ruff S`/`mypy`/`pytest`, `Trivy` complementa `secret`/`config` | Q6 ruff S + mypy 007 |
| D7 | `pip-audit` audita 41 pacotes hoje sem vulns, `Trivy` `fs` para `secret`/`config` | Q7 advisory DB |
| D8 | `pip-audit` cache padrão pip, não `.pip-audit/` no repo; `Trivy` DB em `~/.cache/trivy` | Q8 pip cache |
| D9 | Harness `f0-008-pip-audit.sh` 12–16 asserções só pip-audit+Trivy doc, sem lefthook/gitleaks | Q9 oracle-cli + README |
| D10 | Determinismo `pip-audit` via `uv.lock` hash (advisory muda), `Trivy` skip se Docker ausente, fronteira Escada 008 só pip-audit | Q10 constitution |

**Nenhum `NEEDS CLARIFICATION` remanescente.** Próxima etapa: `SPECIFY` da spec `008 — pip-audit 2.10.1 + Trivy 0.74.0`.

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **009 Lefthook** | `uv.lock` com `pip-audit 2.10.1` hash auditável + `Trivy 0.74.0` pin documentado, orquestrável via `lefthook.yml` (`uv run pip-audit` + `trivy fs`) sem reescrever `pyproject.toml` |
| **010 CI completo** | `pip-audit` em `uv.lock` para `uv run pip-audit` determinístico em CI + `gitleaks` `protect` + `Trivy` `fs` |
| **011 core / 012 cli** | `pyproject.toml` `[dependency-groups] dev` com `pip-audit` → escala para `packages/*` sem reescrever; `Trivy` `fs` escaneia `packages/` |
| **014 Renovate** | `pip-audit==2.10.1` pin para agrupamento e automerge |

## Pacotes e versões pinadas verificadas em 2026-08-31

| Pacote | Versão verificada | Fonte | Nota |
|---|---|---|---|
| `pip-audit` | `2.10.1` | PyPI `pip-audit/json` upload 2026-06-10 | `>=3.10`, `OSV`/`PyPI` advisory, `cyclonedx` |
| `Trivy` | `0.74.0` | GitHub `aquasecurity/trivy` tag 2026-08-14 | Go, `fs`/`config`/`image`, 50 assets, sigstore |
| `gitleaks` | `8.30.1` | GitHub `gitleaks/gitleaks` tag 2026-03-21 | Go, `protect`/`detect`, deferido a 010 (não 008) |
| `cyclonedx-bom` | `7.3.1` | PyPI `cyclonedx-bom/json` | `<4.0,>=3.9`, deferido a 013 (SBOM) |
| `cyclonedx-python-lib` | `11.12.0` | PyPI `cyclonedx-python-lib/json` | transitive de `pip-audit 2.10.1` |
| `ruff` | `0.16.5` | PyPI `ruff/json` re-verificado | `dev` já em 006, coexiste |
| `mypy` | `2.3.1` | PyPI `mypy/json` re-verificado | `dev` já em 007 |
| `pytest` | `9.1.1` | PyPI `pytest/json` | `dev` já em 005 |
| `Python` | `3.12.3` local, `3.12` família, `>=3.12,<3.14` | `python --version` + `requires-python` | `pip-audit` `>=3.10` alinha |
| `uv` | `0.12.1` local / `0.12.7` pin | `uv --version` + PyPI `uv/json` | `uv add --dev pip-audit` → `dependency-groups` |
