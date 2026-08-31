# Contract: pip-audit + Trivy — Fase 0, item 008 (0.12)

**Feature**: `008-pip-audit-trivy` · **Data**: 2026-08-31
**Spec**: `specs/008-pip-audit-trivy/spec.md` (FR-001..016) · **Research**: `docs/plan/research/f0-008-pip-audit-trivy.md` D1–D10
**Herda**: `specs/001-.../contracts/oracle-cli.md`

Este contrato fixa o **pin + invocação pip-audit/Trivy** que 008 introduz e que 009–015 consomem.

---

## 1. Onde vivem os arquivos

```
pyproject.toml              # [dependency-groups] dev + pip-audit==2.10.1
uv.lock                     # contém pip-audit 2.10.1 + cyclonedx-python-lib/cachecontrol com hash (universal)
pip-audit cache             # ~/.cache/pip (fora do repo, não versionado)
Trivy DB                    # ~/.cache/trivy ou Docker volume (fora do repo)
Trivy image                 # aquasec/trivy:0.74.0 (Docker, quando daemon disponível)
scripts/verify/
├── manifest.sha256         # 8 linhas (001..008) sha256sum -c 0
└── f0-008-pip-audit.sh     # 12-16 asserções FR-001..016
specs/README.md             # índice 008 ✅ (inquebrável)
```

* Sem `requirements.txt`/`pylock.toml`/`pip-audit.toml` nem `[tool.pip-audit]` em `pyproject.toml` — fonte única `uv.lock` (D2).
* `Trivy` não entra em `pyproject.toml` `dev` — Go/Docker, pin é tag `aquasec/trivy:0.74.0`.

---

## 2. Schema `pyproject.toml`

### 2.1 `[dependency-groups]`

```toml
[dependency-groups]
dev = ["pip-audit==2.10.1", "mypy==2.3.1", "ruff==0.16.5", "pytest==9.1.1", "pytest-asyncio==1.4.0", "pytest-cov==7.1.0"]
```

### 2.2 `Trivy` pin (documentado, não em TOML)

```toml
# Trivy não é Python — pin é tag Docker + binary:
# aquasec/trivy:0.74.0  +  trivy_0.74.0_Linux-64bit.tar.gz (sigstore)
# verificado via: docker image inspect aquasec/trivy:0.74.0  ou  trivy --version (quando instalado)
```

**Verificação:**

```bash
python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); assert "pip-audit==2.10.1" in d["dependency-groups"]["dev"]'
grep -q 'name = "pip-audit"' uv.lock && echo "uv.lock contém pip-audit"
! grep -q 'trivy' pyproject.toml && echo "Trivy não em pyproject.toml"
```

---

## 3. Invocação

```bash
uv run pip-audit --version               # → 2.10.1
uv run pip-audit --help | grep -q cyclonedx-json  # lista cyclonedx + --fix
uv run pip-audit                         # audit local env após uv sync (41 pacotes, 0 vulns hoje)
uv run pip-audit --dry-run               # coleta would have audited, não audita
uv run pip-audit -f json                 # json com dependencies[].vulns[]
uv run pip-audit -f cyclonedx-json -o /tmp/sbom.json  # bomFormat CycloneDX
# Trivy (quando Docker disponível):
docker run --rm aquasec/trivy:0.74.0 --version  # → 0.74.0
trivy fs --severity HIGH,CRITICAL --format json .  # ou docker run aquasec/trivy:0.74.0 fs ...
trivy --version 2>&1 | grep -q "0.74.0" || echo "Trivy skip se Docker ausente"
```

* `pip-audit` sem `--locked`/`-r` em 008 — lê `.venv` materializado de `uv.lock`.
* `pip-audit --locked` só em 013 com `pylock.toml` (`uv export -o pylock.toml`).
* `Trivy fs` com `HIGH,CRITICAL` e `secret`/`config` — `015` trará `trivy image`.

---

## 4. Fronteira (FR-013)

Em 008 **MUST NOT** existir:

* `lefthook.yml` (`009`), `gitleaks` config (`010`), `packages/` com `pyproject.toml` (`011`/`012`)
* `docker-compose.yml` (`015`), `requirements.txt`/`pylock.toml`/`pip-audit.toml`
* `cyclonedx` SBOM artefato `sbom.cyclonedx.json` (`013`)

---

## 5. Evolução para 009/010/013/015

```
pip-audit==2.10.1 em dev + Trivy 0.74.0 pin  # 008
→ 009: lefthook.yml orquestra uv run pip-audit + trivy fs --severity HIGH,CRITICAL
→ 010: CI ubuntu-24.04 uv run pip-audit + gitleaks protect + trivy fs como required check
→ 013: uv export --format pylock.toml + pip-audit --locked + cyclonedx-bom SBOM
→ 015: docker-compose com trivy service + trivy image python:3.12
```

Sem reescrever `[dependency-groups] dev` em 009/010, apenas orquestrar `uv run pip-audit`.
