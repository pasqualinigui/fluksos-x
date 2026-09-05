# Contract: Oráculo 008 — pip-audit 2.10.1 + Trivy 0.74.0

**Feature**: `008-pip-audit-trivy` · **Data**: 2026-08-31
**Herda**: `specs/001-.../contracts/oracle-cli.md` (interface 0/1/2, --quiet/--list)
**Research**: `docs/plan/research/f0-008-pip-audit-trivy.md` D9–D10

Este contrato especializa o oráculo `f0-008-pip-audit.sh` (12–16 asserções, identidade 1:1, inclui `README`/`git ls-files` inquebráveis).

---

## 1. Invocação

```
scripts/verify/f0-008-pip-audit.sh [--quiet] [--list]
```

| Parâmetro | Efeito |
|---|---|
| *(nenhum)* | Executa 12–16 asserções |
| `--quiet` | Só violações (`for f in f0-*.sh; do "$f" --quiet`) |
| `--list` | Enumera `FR-001..FR-016` sem executar |

---

## 2. Códigos

| Código | Significado |
|---|---|
| `0` | Conforme — 12–16/12–16 |
| `1` | Não conforme — ≥1 violação |
| `2` | Erro de uso |

---

## 3. Mapa FR spec ↔ FR oráculo (identidade 1:1 + 2 inquebráveis)

| FR spec | FR oráculo | Descrição |
|---|---|---|
| FR-001 | FR-001 | `pip-audit==2.10.1` em `[dependency-groups] dev` |
| FR-002 | FR-002 | `pip-audit.toml` não existe (sem config separada) |
| FR-003 | FR-003 | `uv.lock` contém `pip-audit` + `pip-audit --version` 2.10.1 + `--help` `cyclonedx-json` |
| FR-004 | FR-004 | `Trivy 0.74.0` pin `aquasec/trivy:0.74.0` documentado, não em `dev` |
| FR-005 | FR-005 | `uv.lock` contém `pip-audit` transitivos `cyclonedx-python-lib` |
| FR-006 | FR-006 | `pip-audit` cache/`Trivy` DB fora do repo, `uv.lock` não ignorado |
| FR-007 | FR-007 | `uv run pip-audit` 0 sem vulns + `--dry-run` `would have audited` |
| FR-008 | FR-008 | `uv run pip-audit -f json` + `cyclonedx-json` válidos |
| FR-009 | FR-009 | `Trivy fs` sai `0` com `⏭️` skip se Docker ausente, `0` com `Results` vazio quando disponível |
| FR-010 | FR-010 | Oráculo `0/1/2` `quiet` `list` `FKX` `EPOCHSECONDS` |
| FR-011 | FR-011 | CI glob inclui `f0-008` |
| FR-012 | FR-012 | CONVERGE zero `[ ]` |
| FR-013 | FR-013 | Fronteira sem `lefthook.yml`/`gitleaks`/`packages`/`docker-compose` |
| FR-014 | FR-014 | `specs/README.md` `008 ✅` (inquebrável) |
| FR-015 | FR-015 | `git ls-files` `specs/008-pip-audit-trivy/spec.md` 0 (inquebrável) |
| FR-016 | FR-016 | `Trivy` não `0.69.4` e `pip-audit` não `<2.10.1` |

*Sem fragmentação `a/b` — mapa identidade.*

---

## 4. Manifest 8 linhas (ADR-015a)

```
63412ca7…  f0-001
b63ac3c8…  f0-002
d10c61…  f0-003
759376ee…  f0-004
dccb114a…  f0-005
5f268846…  f0-006
54fa8199…  f0-007
<hash-008>  f0-008
```

`FR-003` assere `sha256sum -c manifest.sha256` 0 + `specs/README.md` `008 ✅`.

---

## 5. Self-check

`f0-008` executa `--quiet` de `f0-001..007` todos (paralelo, `FKX_ORACLE_NESTED=1`), fecha `M4`.

---

## 6. Restrições

1. Só `pip-audit` além de `ruff`+`mypy`+`pytest`+`uv`+stdlib (Escada, Trivy via Docker).
2. Somente leitura (`pip-audit` sem `--fix` no harness, `trivy fs` read-only).
3. `EPOCHSECONDS` sem `date`, listas sorted, `LC_ALL=C`.
4. Raiz por `SCRIPT_DIR`.
5. Falha não interrompe demais.
6. Trap limpa `TMPD`.

---

## 7. Exemplo saída

```
✅ FR-001  pip-audit==2.10.1 em [dependency-groups] dev
🔴 FR-007  uv run pip-audit 0 sem vulns
           evidencia: Found 1 vulnerability: PYSEC-... in urllib3 2.7.0

Resultado: 15/16 — 1 violação (alta: 1) — NAO CONFORME
```
