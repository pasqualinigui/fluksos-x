# Data Model: pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades

**Feature**: `008-pip-audit-trivy` | **Date**: 2026-08-31
**Source**: `spec.md` FR-001..016, `research.md` D1–D10, `contracts/` (Phase 1)

---

## Entidades

### 1. pip-audit

Auditoria de env local via `uv run pip-audit` após `uv sync`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `version` | `str` | `"2.10.1"` exato (`>=3.10`) | FR-001, D1 |
| `format_json` | `bool` | `pip-audit -f json` gera `dependencies[].vulns[]` válido | FR-008, D4 |
| `format_cyclonedx` | `bool` | `pip-audit -f cyclonedx-json` gera `bomFormat CycloneDX` válido | FR-008, D4 |
| `dry_run` | `str` | `would have audited` em `pip-audit --dry-run` | FR-007, D2 |
| `vulns` | `list[Vuln]` | `No known vulnerabilities found` hoje para 41 pacotes | FR-007, D7 |

**Validações:**

* `tomllib` parse `pyproject.toml` OK, sem `requirements.txt`/`pylock.toml` em 008 (`! test -f requirements.txt`).
* `uv run pip-audit` 0 sem vulns, `uv run pip-audit --dry-run` coleta sem falhar, `pip-audit --help` lista `cyclonedx-json`/`--fix`.
* `pip-audit --version` 2.10.1.

**Relações:**

* `1 1` para `uv.lock` (mesmo `dev` group).
* `1 1` para `Manifest` (8 linhas após 008).

---

### 2. Trivy pin

Pin Go/Docker `aquasec/trivy:0.74.0` documentado, não em `pyproject.toml`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `version` | `str` | `"0.74.0"` tag 2026-08-14, 50 assets, sigstore | FR-004, D3 |
| `image` | `str` | `aquasec/trivy:0.74.0` Docker image | FR-004, D3 |
| `binary` | `str` | `trivy_0.74.0_Linux-64bit.tar.gz` sigstore | FR-004, D3 |
| `scanners` | `list[str]` | `vuln, secret, config, sbom` | FR-009, D3 |
| `skip_when_no_docker` | `bool` | `⏭️` skip se `docker info` falha | FR-009, D10 |

**Validações:**

* `Trivy` não em `[dependency-groups] dev` nem `requirements*.txt` (`! grep -q trivy pyproject.toml`).
* `Trivy 0.69.4` com CVE-2026-33634 não permitido (`! grep -q "0.69.4"`).

---

### 3. Manifest de integridade (estendido)

`scripts/verify/manifest.sha256` 8 linhas (001..008) após 008.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `lines` | `int` | `8` | FR-003 |
| `files` | `list[str]` | `f0-001..008` ordem ADR-011 | FR-003 |
| `verification` | `cmd` | `sha256sum -c` 0 | FR-003 |
| `readme` | `str` | `specs/README.md` contém `008 ✅` | FR-014 |
| `tracked` | `bool` | `git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md` 0 | FR-015 |

---

### 4. Spec index inquebrável

`specs/README.md` + `git ls-files`.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `readme` | `str` | `grep -iq "008.*pip-audit.*✅" specs/README.md` | FR-014 |
| `tracked` | `bool` | `git ls-files --error-unmatch` 0 | FR-015 |

**Validações:**

* `specs/README.md` flat `001-008` com `008 ✅` (não `⏳`).
* `specs/008-pip-audit-trivy/spec.md` rastreado (não `??`).

---

### 5. Dependency-group dev (estendido)

`[dependency-groups] dev` agora com 6 entradas.

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `dev` | `list[str]` | `["pip-audit==2.10.1","mypy==2.3.1","ruff==0.16.5","pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]` | FR-001 |
| `uv.lock` | `bool` | contém `pip-audit` `cyclonedx-python-lib` `cachecontrol` | FR-003/005 |

---

## Relações

```
[dependency-groups] dev ──1──> uv.lock ──1──> pip-audit (41 pacotes, 0 vulns hoje)
      │
      ├─1──> Trivy pin 0.74.0 ──1──> trivy fs . (HIGH,CRITICAL, ⏭️ se Docker ausente)
      │
      └─1──> Manifest 8 linhas ──1──> pip-audit determinístico via uv.lock hash
                                │
Spec index ──1──> git ls-files (commit inquebrável)
```

## Ciclo de vida

* **Criação:** 008 cria `pip-audit==2.10.1` em `dev` + `uv.lock` hash + `Trivy` pin documentado (não instalado se Docker ausente).
* **Mutação:** `pip-audit.toml` nunca criado; `Trivy` pin só atualiza tag, não `pyproject.toml`; `requirements.txt`/`pylock.toml` nunca criados em 008.
* **Idempotência:** `pip-audit` segunda vez não altera `uv.lock` hash (`--dry-run` coleta igual).

## Volume / escala

* `uv.lock` 41 pacotes, `pip-audit` <10s, `trivy fs` <10s com Docker, `f0-008` 12-16 asserções <5s.
* `pip-audit` cache `~/.cache/pip` fora do repo, `Trivy` DB `~/.cache/trivy` fora, ignorados.
