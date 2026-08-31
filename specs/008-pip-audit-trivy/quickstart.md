# Quickstart: pip-audit 2.10.1 + Trivy 0.74.0 — auditoria de vulnerabilidades

**Feature**: `008-pip-audit-trivy` · **Branch**: `008-pip-audit-trivy` · **Date**: 2026-08-31
**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md)

Guia de **validação** (não implementação). Cada cenário roda em clone limpo e prova um `FR`/`SC`.

---

## Pré-requisitos

```bash
python3 --version  # >=3.12,<3.14
uv --version       # 0.12.7
uv run pip-audit --version  # 2.10.1 após uv sync
docker --version   # 29.7.2 opcional (Trivy via Docker)
```

---

## Cenário 1 — Clone limpo obtém pip-audit verde (SC-001, FR-001/003/005)

```bash
uv add --dev pip-audit==2.10.1
uv sync
uv run pip-audit --version  # → 2.10.1
uv run pip-audit --help | grep -q "cyclonedx-json" && echo "cyclonedx-json lista"
uv run pip-audit --help | grep -q "\-\-fix" && echo "--fix lista"
python3 -c 'import tomllib; assert "pip-audit==2.10.1" in str(tomllib.load(open("pyproject.toml","rb"))["dependency-groups"]["dev"])'
grep -q 'name = "pip-audit"' uv.lock && echo "uv.lock contém pip-audit"
grep -q 'name = "cyclonedx-python-lib"' uv.lock && echo "transitive cyclonedx-python-lib"
```

**Esperado:** `[dependency-groups] dev` com `pip-audit==2.10.1`, `uv.lock` hash, `.venv/bin/pip-audit`, sem `requirements.txt`.

---

## Cenário 2 — pip-audit dry-run e json/cyclonedx (SC-002, FR-007/008)

```bash
uv run pip-audit --dry-run 2>&1 | grep -q "would have audited" && echo "dry-run coleta"
uv run pip-audit 2>&1 | grep -q "No known vulnerabilities found" && echo "0 vulns baseline"
uv run pip-audit -f json 2>&1 | python3 -c 'import json,sys; d=json.load(sys.stdin); assert "dependencies" in d; assert all("vulns" in dep for dep in d["dependencies"])'
uv run pip-audit -f cyclonedx-json -o /tmp/sbom.json 2>&1 && cat /tmp/sbom.json | grep -q "bomFormat" && echo "cyclonedx-json válido"
rm -f /tmp/sbom.json
```

**Esperado:** `pip-audit` 0 sem vulns hoje (41 pacotes), `--dry-run` coleta, `json` com `dependencies[].vulns[]`, `cyclonedx-json` com `bomFormat`.

---

## Cenário 3 — pip-audit --version e Trivy pin (SC-003, FR-003/004/016)

```bash
uv run pip-audit --version  # → 2.10.1
uv run pip-audit --help | grep -q "cyclonedx-json" && echo "cyclonedx presente"
docker --version 2>&1 | head -1
# Trivy pin documentado (não em pyproject.toml):
! grep -q "trivy" pyproject.toml && echo "Trivy não em pyproject.toml dev"
grep -q "0.69.4" pyproject.toml && echo "FAIL: 0.69.4 vulnerável" || echo "OK: não usa 0.69.4"
# Quando Docker disponível:
docker run --rm aquasec/trivy:0.74.0 --version 2>&1 | grep -q "0.74.0" && echo "Trivy 0.74.0 pin OK" || echo "Trivy skip (Docker ausente) OK"
```

**Esperado:** `2.10.1` e `0.74.0` pin, `Trivy` não em `dev`.

---

## Cenário 4 — Harness 008 <5s e self-check (SC-004, FR-010)

```bash
scripts/verify/f0-008-pip-audit.sh  # → 12–16/12–16 CONFORME
scripts/verify/f0-008-pip-audit.sh --list  # → 12–16 IDs
scripts/verify/f0-008-pip-audit.sh --quiet  # → só violações
time scripts/verify/f0-008-pip-audit.sh  # → <5s
scripts/verify/f0-008-pip-audit.sh > /tmp/r1.txt 2>&1
scripts/verify/f0-008-pip-audit.sh > /tmp/r2.txt 2>&1
diff /tmp/r1.txt /tmp/r2.txt && echo "determinismo byte-identico"
```

**Esperado:** `CANON_ORDER` 12–16, `exit 0/1/2`, `EPOCHSECONDS <5s`, `2× cmp` idêntico.

---

## Cenário 5 — Fronteira, cache e Trivy skip (SC-005/008, FR-002/006/009/013)

```bash
! test -f lefthook.yml && echo "sem lefthook.yml OK"
! test -f gitleaks.toml && echo "sem gitleaks.toml OK"
! test -d packages && echo "sem packages OK"
! test -f requirements.txt && echo "sem requirements.txt OK"
! test -f pylock.toml && echo "sem pylock.toml OK"
uv run pip-audit  # cria cache em ~/.cache/pip
! git ls-files | grep -q "pip-audit" && echo "OK: pip-audit cache não rastreado"
git check-ignore -q uv.lock && echo "FAIL: uv.lock ignorado" || echo "OK: uv.lock não ignorado"
# Trivy sem Docker deve skip, não fail:
docker info >/dev/null 2>&1 || echo "Docker ausente → Trivy ⏭️ skip esperado"
```

**Esperado:** `lefthook.yml` reprovaria `FR-013`, `Trivy` ⏭️ se Docker ausente, cache fora do repo.

---

## Cenário 6 — CI glob, CONVERGE e inquebráveis (SC-006/007, FR-011/012/014/015)

```bash
grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml && echo "CI glob presente"
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && echo "harness 8/8 CONFORME"
grep -c "^- \[ \]" specs/008-pip-audit-trivy/tasks.md  # → 0 quando tasks 38 [x]
grep -iq "008.*pip-audit.*✅" specs/README.md && echo "README 008 ✅"
git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md && echo "spec 008 rastreado"
git ls-files --error-unmatch docs/plan/research/f0-008-pip-audit-trivy.md && echo "research 008 rastreado"
```

**Esperado:** `for f` inclui `f0-008` sem editar `ci.yml`, `tasks.md` zero `[ ]`, `README` `008 ✅`, `spec` e `research` rastreados.

---

## Validação completa em um comando

```bash
uv run pip-audit --version | grep -q "2.10.1" && \
uv run pip-audit --dry-run 2>&1 | grep -q "would have audited" && \
uv run pip-audit -f json 2>&1 | python3 -c 'import json,sys; json.load(sys.stdin)' && \
sha256sum -c scripts/verify/manifest.sha256 && \
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && \
! test -f lefthook.yml && \
grep -iq "008.*pip-audit.*✅" specs/README.md && \
git ls-files --error-unmatch specs/008-pip-audit-trivy/spec.md >/dev/null 2>&1 && \
git ls-files --error-unmatch docs/plan/research/f0-008-pip-audit-trivy.md >/dev/null 2>&1 && \
echo "quickstart OK"
```

**Todos `OK` ⇒ `contracts/pip-audit-contract.md` satisfeito.**

---

## Troubleshooting

| Sintoma | Causa | Fix |
|---|---|---|
| `pip-audit` com vuln HIGH | `urllib3` 2.7.0 CVE futuro | `uv run pip-audit --fix` ou `pip-audit --ignore-vuln PYSEC-...` com ADR (FR-016) |
| `Trivy` sem Docker | `docker info` falha | `Trivy` skip `⏭️` em 008; `015` trará compose (D3) |
| `pip-audit --locked` falha | `pylock.toml` não existe | Usar `uv run pip-audit` sem `--locked` em 008; `pylock.toml` só em 013 (D2) |
| `requirements.txt` com `pip-audit` | `requirements.txt` existe | `rm requirements.txt` (FR-001, fonte única `uv.lock`) |
| `cyclonedx-json` vazio | `pip-audit` sem vulns mas SBOM deve ser válido | `bomFormat` ainda válido mesmo sem vulns (FR-008) |
| `Trivy 0.69.4` | Pin antigo vulnerável | Atualizar para `aquasec/trivy:0.74.0` (FR-016) |
| `specs/README.md` sem `008 ✅` | `README` desatualizado | Atualizar índice (FR-014) |
| `spec 008` `??` | `git add` faltou | `git add` + `git ls-files` deve passar |
