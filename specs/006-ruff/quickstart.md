# Quickstart: Ruff 0.16.5 — linter + formatter

**Feature**: `006-ruff` · **Branch**: `006-ruff` · **Date**: 2026-08-31
**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md)

Guia de **validação** (não implementação). Cada cenário roda em clone limpo e prova um `FR`/`SC`.

---

## Pré-requisitos

```bash
python3 --version  # >=3.12,<3.14
uv --version       # 0.12.7
uv run ruff --version  # 0.16.5 após uv sync
```

---

## Cenário 1 — Clone limpo obtém ruff verde (SC-001, FR-001/006)

```bash
uv add --dev ruff==0.16.5
uv sync
uv run ruff --version  # → 0.16.5
uv run ruff check .  # → All checks passed!
uv run ruff format --check .  # → 2 files already formatted
python3 -c 'import tomllib; assert "ruff==0.16.5" in str(tomllib.load(open("pyproject.toml","rb"))["dependency-groups"]["dev"])'
grep -q 'name = "ruff"' uv.lock && echo "uv.lock contém ruff"
```

**Esperado:** `[dependency-groups] dev` com `ruff==0.16.5`, `uv.lock` hash, `.venv/bin/ruff`, sem `ruff.toml`.

---

## Cenário 2 — Regras sênior e E501 ignorada (SC-002, FR-003/008)

```bash
# E501 ignorada
echo 'x = "a" * 120  # linha 120 chars' > /tmp/long.py
uv run ruff check --output-format=concise /tmp/long.py | grep -q E501 && echo "E501 reprovaria" || echo "E501 ignorada OK (format cuida)"
rm /tmp/long.py

# UP007
echo 'from typing import Union
x: Union[int, str]' > /tmp/up.py
uv run ruff check --output-format=concise /tmp/up.py | grep -q UP007 && echo "UP007 sugere X|Y"
rm /tmp/up.py
```

**Esperado:** `E501` não lista (ignore), `UP007` lista `X|Y`, `I001` lista imports desordenados.

---

## Cenário 3 — Format idempotente (SC-003, FR-010)

```bash
uv run ruff format .  # primeira
sha256sum tests/test_harness_oracles.py > /tmp/a
uv run ruff format .  # segunda
sha256sum tests/test_harness_oracles.py > /tmp/b
diff /tmp/a /tmp/b && echo "idempotente OK"
# aspas simples → double
echo "x='a'" > /tmp/q.py
uv run ruff format --check --diff /tmp/q.py 2>&1 | grep -q '"a"' && echo "diff mostra double quotes"
uv run ruff format /tmp/q.py
grep -q '"a"' /tmp/q.py && echo "format corrigiu para double"
rm /tmp/q.py
```

**Esperado:** segunda `format` não altera hash, `--check --diff` mostra `-'a'` `+"a"`.

---

## Cenário 4 — Harness 006 <5s e self-check (SC-004, FR-011)

```bash
scripts/verify/f0-006-ruff.sh  # → 10–14/10–14 CONFORME
scripts/verify/f0-006-ruff.sh --list  # → 10–14 IDs
scripts/verify/f0-006-ruff.sh --quiet  # → só violações
time scripts/verify/f0-006-ruff.sh  # → <5s
scripts/verify/f0-006-ruff.sh > /tmp/r1.txt 2>&1
scripts/verify/f0-006-ruff.sh > /tmp/r2.txt 2>&1
diff /tmp/r1.txt /tmp/r2.txt && echo "determinismo byte-identico"
```

**Esperado:** `CANON_ORDER` 10–14, `exit 0/1/2`, `EPOCHSECONDS <5s`, `2× cmp` idêntico.

---

## Cenário 5 — Fronteira e cache (SC-005/008, FR-005/007/014)

```bash
! test -f ruff.toml && echo "sem ruff.toml OK"
! test -f mypy.ini && echo "sem mypy.ini OK"
! test -f lefthook.yml && echo "sem lefthook.yml OK"
! test -d packages && echo "sem packages OK"
uv run ruff check .  # cria .ruff_cache/
git check-ignore -q .ruff_cache && echo ".ruff_cache gitignored"
git status --porcelain | grep -q .ruff_cache && echo "FAIL: .ruff_cache untracked" || echo "OK: .ruff_cache não lista"
! git ls-files | grep -q .ruff_cache && echo "OK: .ruff_cache não rastreado"
```

**Esperado:** `ruff.toml` reprovaria `FR-005`, `mypy.ini` reprovaria `FR-014`, `.ruff_cache` ignorado.

---

## Cenário 6 — CI glob e CONVERGE (SC-006/007, FR-012/013)

```bash
grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml && echo "CI glob presente"
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && echo "harness 6/6 CONFORME"
grep -c "^- \[ \]" specs/006-ruff/tasks.md  # → 0 quando tasks 30 [x]
```

**Esperado:** `for f` inclui `f0-006` sem editar `ci.yml`, `tasks.md` zero `[ ]`.

---

## Validação completa em um comando

```bash
uv run ruff check . && \
uv run ruff format --check --diff . && \
uv run ruff format . && sha256sum tests/test_harness_oracles.py | diff - /tmp/a 2>/dev/null || true && \
sha256sum -c scripts/verify/manifest.sha256 && \
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && \
! test -f ruff.toml && \
grep -q 'per-file-ignores' pyproject.toml && \
echo "quickstart OK"
```

**Todos `OK` ⇒ `contracts/ruff-contract.md` satisfeito.**

---

## Troubleshooting

| Sintoma | Causa | Fix |
|---|---|---|
| `ruff.toml` esconde `[tool.ruff]` | `ruff.toml` presente (precedência) | `rm ruff.toml` (FR-005) |
| `E501` reprova | `ignore` sem `E501` | Adicionar `ignore = ["E501"]` (D3) |
| `S101` em `tests/` reprova | `per-file-ignores` sem `tests/` | Adicionar `tests/**/* S101,S603` |
| `.ruff_cache` untracked | `.gitignore` sem `.ruff_cache/` | Já deve existir 254; `git check-ignore -q` deve passar |
| `uv run ruff` 0.15.x | `uv 0.12.1` desatualizado ou lock com 0.15 | `uv sync` com `ruff==0.16.5` pin |
| `format` não idempotente | `line-ending` `auto` vs `lf` | Manter `line-ending auto` (D4) |
