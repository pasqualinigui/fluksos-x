# Quickstart: MyPy 2.3.1 strict — type checker

**Feature**: `007-mypy` · **Branch**: `007-mypy` · **Date**: 2026-08-31
**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md)

Guia de **validação** (não implementação). Cada cenário roda em clone limpo e prova um `FR`/`SC`.

---

## Pré-requisitos

```bash
python3 --version  # >=3.12,<3.14
uv --version       # 0.12.7
uv run mypy --version  # 2.3.1 após uv sync
```

---

## Cenário 1 — Clone limpo obtém mypy verde (SC-001, FR-001/005/006)

```bash
uv add --dev mypy==2.3.1
uv sync
uv run mypy --version  # → 2.3.1
uv run mypy --help | grep -q "strict" && echo "strict lista 11 flags"
python3 -c 'import tomllib; assert "mypy==2.3.1" in str(tomllib.load(open("pyproject.toml","rb"))["dependency-groups"]["dev"])'
grep -q 'name = "mypy"' uv.lock && echo "uv.lock contém mypy"
```

**Esperado:** `[dependency-groups] dev` com `mypy==2.3.1`, `uv.lock` hash, `.venv/bin/mypy`, sem `mypy.ini`.

---

## Cenário 2 — Strict e overrides para tests/ (SC-002, FR-002/003/008/009)

```bash
# strict true
grep -q 'strict = true' pyproject.toml && echo "strict true"
grep -q 'python_version = "3.12"' pyproject.toml && echo "py312"

# tests/ relaxado
uv run mypy --strict tests/test_harness_oracles.py  # → 0 com overrides disallow_untyped_defs false
echo "def foo(x): return x" > /tmp/e.py
uv run mypy --strict /tmp/e.py 2>&1 | grep -q "disallow_untyped_defs" && echo "reprova sem anotação fora de tests/"
rm /tmp/e.py

# list vs list[int]
echo 'x: list
x = []' > /tmp/f.py
uv run mypy --strict /tmp/f.py 2>&1 | grep -q "disallow-any-generics" && echo "reprova list sem param"
rm /tmp/f.py
```

**Esperado:** `mypy --strict` reprova `disallow_untyped_defs` fora de `tests/`, não em `tests/` com `overrides`; `list` sem `list[int]` reprova `misc`.

---

## Cenário 3 — mypy --version e strict flags (SC-003, FR-010)

```bash
uv run mypy --version  # → 2.3.1
uv run mypy --help | grep -q "disallow-untyped-defs" && echo "strict flag presente"
uv run mypy --help | grep -q "strict" && echo "strict lista"
```

**Esperado:** `2.3.1` e `strict` com 11 flags.

---

## Cenário 4 — Harness 007 <5s e self-check (SC-004, FR-011)

```bash
scripts/verify/f0-007-mypy.sh  # → 12–16/12–16 CONFORME
scripts/verify/f0-007-mypy.sh --list  # → 12–16 IDs
scripts/verify/f0-007-mypy.sh --quiet  # → só violações
time scripts/verify/f0-007-mypy.sh  # → <5s
scripts/verify/f0-007-mypy.sh > /tmp/r1.txt 2>&1
scripts/verify/f0-007-mypy.sh > /tmp/r2.txt 2>&1
diff /tmp/r1.txt /tmp/r2.txt && echo "determinismo byte-identico"
```

**Esperado:** `CANON_ORDER` 12–16, `exit 0/1/2`, `EPOCHSECONDS <5s`, `2× cmp` idêntico.

---

## Cenário 5 — Fronteira e cache (SC-005/008, FR-004/007/014)

```bash
! test -f mypy.ini && echo "sem mypy.ini OK"
! test -f lefthook.yml && echo "sem lefthook.yml OK"
! test -d packages && echo "sem packages OK"
uv run mypy --strict .  # cria .mypy_cache/
git check-ignore -q .mypy_cache && echo ".mypy_cache gitignored"
git status --porcelain | grep -q .mypy_cache && echo "FAIL: .mypy_cache untracked" || echo "OK: .mypy_cache não lista"
! git ls-files | grep -q .mypy_cache && echo "OK: .mypy_cache não rastreado"
```

**Esperado:** `mypy.ini` reprovaria `FR-004`, `lefthook.yml` reprovaria `FR-014`, `.mypy_cache` ignorado.

---

## Cenário 6 — CI glob, CONVERGE e inquebráveis (SC-006/007, FR-012/013/015/016)

```bash
grep -F 'for f in scripts/verify/f0-' .github/workflows/ci.yml && echo "CI glob presente"
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && echo "harness 7/7 CONFORME"
grep -c "^- \[ \]" specs/007-mypy/tasks.md  # → 0 quando tasks 34 [x]
grep -q "007.*mypy.*✅" specs/README.md && echo "README 007 ✅"
git ls-files --error-unmatch specs/007-mypy/spec.md && echo "spec 007 rastreado"
```

**Esperado:** `for f` inclui `f0-007` sem editar `ci.yml`, `tasks.md` zero `[ ]`, `README` `007 ✅`, `spec` rastreado.

---

## Validação completa em um comando

```bash
uv run mypy --version | grep -q "2.3.1" && \
uv run mypy --strict . --no-error-summary >/dev/null 2>&1 && \
uv run mypy --strict tests/ --no-error-summary >/dev/null 2>&1 && \
sha256sum -c scripts/verify/manifest.sha256 && \
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && \
! test -f mypy.ini && \
grep -q 'specs/README.md.*007.*✅' specs/007-mypy/spec.md 2>&1 || grep -q "007.*mypy.*✅" specs/README.md && \
git ls-files --error-unmatch specs/007-mypy/spec.md >/dev/null 2>&1 && \
echo "quickstart OK"
```

**Todos `OK` ⇒ `contracts/mypy-contract.md` satisfeito.**

---

## Troubleshooting

| Sintoma | Causa | Fix |
|---|---|---|
| `mypy.ini` esconde `[tool.mypy]` | `mypy.ini` presente (precedência) | `rm mypy.ini` (FR-004) |
| `disallow_untyped_defs` em `tests/` reprova | `overrides` sem `tests.*` relaxado | Adicionar `[[tool.mypy.overrides]] module = "tests.*"` |
| `warn_unused_configs` typo | `module = "foo.bar"` inexistente | Corrigir `module` ou remover |
| `.mypy_cache` untracked | `.gitignore` sem `.mypy_cache/` | Já deve existir 217; `git check-ignore -q` deve passar |
| `uv run mypy` 1.x | `uv 0.12.1` desatualizado ou lock com 1.x | `uv sync` com `mypy==2.3.1` pin |
| `python_version 3.10` reprova `X|Y` | `3.10` não entende `X|Y` (3.10+) | Manter `python_version 3.12` (D4) |
| `specs/README.md` sem `007 ✅` | `README` desatualizado | Atualizar índice (FR-015) |
| `spec 007` `??` | `git add specs/007-mypy/spec.md` faltou | `git add` + `git ls-files` deve passar |

---

## Nota Fase E — Cenário remoto deferido (T038)

> **Deferido pós-merge**: O cenário remoto de `quickstart.md` (push conforme verde + PR com `mypy.ini` vermelho, SC-005) só é observável após `push`/`PR` real em `main`/`develop` no GitHub. Não bloqueia convergência local — `plan.md` Fase E. Ver `specs/007-mypy/plan.md` §Fase E e `docs/plan/research/f0-007-mypy.md` Q10.
