# Contract: Oráculo 006 — Ruff 0.16.5

**Feature**: `006-ruff` · **Data**: 2026-08-31
**Herda**: `specs/001-.../contracts/oracle-cli.md` (interface 0/1/2, --quiet/--list)
**Research**: `docs/plan/research/f0-006-ruff.md` D9–D10

Este contrato especializa o oráculo `f0-006-ruff.sh` (10–14 asserções, identidade 1:1).

---

## 1. Invocação

```
scripts/verify/f0-006-ruff.sh [--quiet] [--list]
```

| Parâmetro | Efeito |
|---|---|
| *(nenhum)* | Executa 10–14 asserções |
| `--quiet` | Só violações (`for f in f0-*.sh; do "$f" --quiet`) |
| `--list` | Enumera `FR-001..FR-014` sem executar |

---

## 2. Códigos

| Código | Significado |
|---|---|
| `0` | Conforme — 10–14/10–14 |
| `1` | Não conforme — ≥1 violação |
| `2` | Erro de uso |

---

## 3. Mapa FR spec ↔ FR oráculo (identidade 1:1)

| FR spec | FR oráculo | Descrição |
|---|---|---|
| FR-001 | FR-001 | `ruff==0.16.5` em `[dependency-groups] dev` |
| FR-002 | FR-002 | `[tool.ruff]` `line-length 88` `py312` `exclude` |
| FR-003 | FR-003 | `[tool.ruff.lint]` `select`/`extend-select`/`ignore`/`per-file-ignores` |
| FR-004 | FR-004 | `[tool.ruff.format]` `quote-style` etc. |
| FR-005 | FR-005 | `ruff.toml` não existe (fonte única) |
| FR-006 | FR-006 | `uv.lock` contém `ruff` |
| FR-007 | FR-007 | `.ruff_cache` gitignored |
| FR-008 | FR-008 | `uv run ruff check .` 0 |
| FR-009 | FR-009 | `uv run ruff format --check --diff .` 0 |
| FR-010 | FR-010 | `ruff format .` idempotente |
| FR-011 | FR-011 | Oráculo `0/1/2` `quiet` `list` `FKX` `EPOCHSECONDS` |
| FR-012 | FR-012 | CI glob inclui `f0-006` |
| FR-013 | FR-013 | `CONVERGE` zero `[ ]` |
| FR-014 | FR-014 | Fronteira sem `mypy`/`lefthook`/`packages` |

*Sem fragmentação `a/b` — mapa identidade, prova de `RUF` etc.*

---

## 4. Manifest 6 linhas (ADR-015a)

```
63412ca7…  f0-001
b63ac3c8…  f0-002
d10c61…  f0-003
42e2d36…  f0-004
e39a1f1c…  f0-005
<hash-006>  f0-006
```

`FR-008` assere `sha256sum -c manifest.sha256` 0.

---

## 5. Self-check

`f0-006` executa `--quiet` de `f0-001..005` todos (paralelo, `FKX_ORACLE_NESTED=1`), fecha `M4`.

---

## 6. Restrições

1. Só `ruff` além de `pytest`+`uv`+stdlib (Escada).
2. Somente leitura (`ruff check` sem `--fix`, `format --check` sem re-escrever).
3. `EPOCHSECONDS` sem `date`, listas sorted, `LC_ALL=C`.
4. Raiz por `SCRIPT_DIR`.
5. Falha não interrompe demais.
6. Trap limpa `TMPD`.

---

## 7. Exemplo saída

```
✅ FR-001  ruff==0.16.5 em [dependency-groups] dev
🔴 FR-008  ruff check . 0
           evidencia: I001 import unsorted in tests/test_foo.py

Resultado: 13/14 — 1 violação (alta: 1) — NAO CONFORME
```
