# Contract: Oráculo 007 — MyPy 2.3.1 strict

**Feature**: `007-mypy` · **Data**: 2026-08-31
**Herda**: `specs/001-.../contracts/oracle-cli.md` (interface 0/1/2, --quiet/--list)
**Research**: `docs/plan/research/f0-007-mypy.md` D9–D10

Este contrato especializa o oráculo `f0-007-mypy.sh` (12–16 asserções, identidade 1:1, inclui `README`/`git ls-files` inquebráveis).

---

## 1. Invocação

```
scripts/verify/f0-007-mypy.sh [--quiet] [--list]
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
| FR-001 | FR-001 | `mypy==2.3.1` em `[dependency-groups] dev` |
| FR-002 | FR-002 | `[tool.mypy]` `python_version 3.12` `strict true` `warn_unused_configs` `exclude` |
| FR-003 | FR-003 | `[[tool.mypy.overrides]]` `tests.*` `disallow_untyped_defs false` etc. |
| FR-004 | FR-004 | `mypy.ini` não existe (fonte única) |
| FR-005 | FR-005 | `uv.lock` contém `mypy` + `mypy --version` 2.3.1 |
| FR-006 | FR-006 | `uv.lock` contém `mypy` transitivos |
| FR-007 | FR-007 | `.mypy_cache`/`dmypy.json` gitignored |
| FR-008 | FR-008 | `uv run mypy --strict .` 0 |
| FR-009 | FR-009 | `uv run mypy --strict tests/` 0 com `overrides` |
| FR-010 | FR-010 | `mypy --version` 2.3.1 `strict` 11 flags |
| FR-011 | FR-011 | Oráculo `0/1/2` `quiet` `list` `FKX` `EPOCHSECONDS` |
| FR-012 | FR-012 | CI glob inclui `f0-007` |
| FR-013 | FR-013 | `CONVERGE` zero `[ ]` |
| FR-014 | FR-014 | Fronteira sem `lefthook`/`packages` |
| FR-015 | FR-015 | `specs/README.md` `007 ✅` (inquebrável) |
| FR-016 | FR-016 | `git ls-files` `specs/007-mypy/spec.md` 0 (inquebrável) |

*Sem fragmentação `a/b` — mapa identidade.*

---

## 4. Manifest 7 linhas (ADR-015a)

```
63412ca7…  f0-001
b63ac3c8…  f0-002
d10c61…  f0-003
42e2d36…  f0-004
e39a1f1c…  f0-005
ee85cfdf…  f0-006
<hash-007>  f0-007
```

`FR-008` assere `sha256sum -c manifest.sha256` 0 + `specs/README.md` `007 ✅`.

---

## 5. Self-check

`f0-007` executa `--quiet` de `f0-001..006` todos (paralelo, `FKX_ORACLE_NESTED=1`), fecha `M4`.

---

## 6. Restrições

1. Só `mypy` além de `ruff`+`pytest`+`uv`+stdlib (Escada).
2. Somente leitura (`mypy --strict` sem `--install-types`).
3. `EPOCHSECONDS` sem `date`, listas sorted, `LC_ALL=C`.
4. Raiz por `SCRIPT_DIR`.
5. Falha não interrompe demais.
6. Trap limpa `TMPD`.

---

## 7. Exemplo saída

```
✅ FR-001  mypy==2.3.1 em [dependency-groups] dev
🔴 FR-008  mypy --strict . 0
           evidencia: tests/test_foo.py:1: error: Need type annotation

Resultado: 15/16 — 1 violação (alta: 1) — NAO CONFORME
```
