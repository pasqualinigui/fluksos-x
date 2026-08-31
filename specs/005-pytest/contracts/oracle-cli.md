# Contract: Oráculo 005 — Pytest 9.1.1 (harness TDD)

**Feature**: `005-pytest` · **Data**: 2026-08-31
**Herda**: `specs/001-git-branching-strategy/contracts/oracle-cli.md` (interface normativa 0/1/2, --quiet/--list, determinismo)
**Research**: `docs/plan/research/f0-005-pytest.md` D6–D10

Este contrato especializa o **oráculo deste item** (`scripts/verify/f0-005-pytest.sh`) e o **mapa FR↔asserção** quando não for identidade (ADR-015b). Em 005 o mapa É identidade (12–16 FRs → 12–16 asserções 1:1), portanto este arquivo documenta a identidade e o manifesto.

---

## 1. Invocação

```
scripts/verify/f0-005-pytest.sh [--quiet] [--list]
```

| Parâmetro | Efeito |
|---|---|
| *(nenhum)* | Executa 12–16 asserções e imprime relatório legível |
| `--quiet` | Só violações (para `for f in f0-*.sh; do "$f" --quiet || exit 1; done`) |
| `--list` | Enumera `FR-001..FR-015` (ou 012..016 conforme subdivisão) sem executar |

Sem args posicionais. Raiz por `SCRIPT_DIR`, nunca `$PWD` (oracle-cli.md §5 restrição 4).

---

## 2. Códigos de saída

| Código | Significado |
|---|---|
| `0` | Conforme — 12–16/12–16 |
| `1` | Não conforme — ao menos 1 violação |
| `2` | Erro de uso — parâmetro inválido |

---

## 3. Mapa FR spec ↔ FR oráculo (ADR-015b)

Em 005 **identidade 1:1** — cada FR da spec tem uma asserção homônima no oráculo. Não há fragmentação `a/b`, portanto **não há mapa de refinamento** (se houvesse, seria listado aqui como "FR-001a/b refinam FR-001").

| FR spec | FR oráculo | Descrição |
|---|---|---|
| FR-001 | FR-001 | `[dependency-groups] dev` com `pytest==9.1.1` etc. exato |
| FR-002 | FR-002 | Não em `[project.dependencies]` nem legado |
| FR-003 | FR-003 | `[tool.pytest.ini_options]` completo (minversion, testpaths, addopts, asyncio strict) |
| FR-004 | FR-004 | `tests/conftest.py` py_compile 0, sem `pytest.toml` |
| FR-005 | FR-005 | `test_harness_oracles.py` parametrizado FKX_ORACLE_NESTED |
| FR-006 | FR-006 | `uv.lock` contém pytest hash (`uv lock --check`) |
| FR-007 | FR-007 | `.pytest_cache`/`htmlcov` gitignored |
| FR-008 | FR-008 | `manifest.sha256` 5 linhas `sha256sum -c` 0 |
| FR-009 | FR-009 | Self-check `f0-001..004 --quiet` todos |
| FR-010 | FR-010 | 5 casos ADR-007 nomeados |
| FR-011 | FR-011 | `uv run pytest -q` 0 conforme |
| FR-012 | FR-012 | CI glob inclui f0-005 sem editar ci.yml |
| FR-013 | FR-013 | CONVERGE zero `[ ]` em tasks.md |
| FR-014 | FR-014 | Determinismo 2× cmp + <5s EPOCHSECONDS |
| FR-015 | FR-015 | Fronteira: sem ruff/mypy/lefthook/packages/xdist |

*Se 005 precisasse fragmentar (ex.: FR-003 em `FR-003a` minversion + `FR-003b` testpaths), o mapa seria declarado aqui. Como não fragmentou, a tabela acima é a prova de identidade.*

---

## 4. Manifesto (`manifest.sha256`) — ADR-015a

Formato nativo `sha256sum` (dois espaços, sem parser):

```
63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22  scripts/verify/f0-001-foundation.sh
406d72528ddebba417887a65f553c99d9c7df8982fb2b72672904b3ec09386a7  scripts/verify/f0-002-constitution.sh
d10c61e8623fcf3f7c706ab8ca7387303c2d5282da0afaee50bf5c6401b6f7d4  scripts/verify/f0-003-ci-minimo.sh
3db36208b4e13fb24bace3aaa3247224f163ca02a070d8b15e64084b1bafd88e  scripts/verify/f0-004-uv-workspace.sh
<hash-005>  scripts/verify/f0-005-pytest.sh
```

* `FR-008` assere `sha256sum -c scripts/verify/manifest.sha256` exit 0.
* Divergência é ADR, nunca `sed -i` no hash (ADR-015a).

---

## 5. Self-check (ADR-015e)

`f0-005` executa:

```
f0-001-foundation.sh --quiet
f0-002-constitution.sh --quiet
f0-003-ci-minimo.sh --quiet
f0-004-uv-workspace.sh --quiet
```

Todos, não subconjunto (fecha M4). CI glob `for f in f0-*.sh` também cobre, mas execução isolada de `f0-005` prova sem depender do loop.

---

## 6. Restrições do oráculo (herdadas)

1. Só shell, git, Python 3.12 stdlib + `pytest` (a partir de 005 `scripts/verify/README.md:74` — `004+ pytest`). `sha256sum`, `grep`, `py_compile` são stdlib/shell.
2. Somente leitura (observa, não corrige) — `FKX_ORACLE_NESTED=1` evita recursão `FR-014`.
3. Determinismo: `EPOCHSECONDS` builtin em `f0-005-pytest.sh` (bash, sem fork) mede `<5s` do oráculo; `time.monotonic()` em `tests/test_harness_debts.py` mede o mesmo limiar no lado pytest — dois proxies do mesmo `<5s`, não fontes concorrentes; `date +%s` proibido (B2); listas sorted; `LC_ALL=C`.
4. Raiz por `SCRIPT_DIR`.
5. Falha não interrompe demais.
6. Trap limpia `TMPD`.

---

## 7. Exemplo de saída

```
✅ FR-001  [dependency-groups] dev com pytest==9.1.1 exato
✅ FR-002  não em [project.dependencies] nem legado
🔴 FR-008  manifest.sha256 5 linhas sha256sum -c 0
           evidencia: sha256sum -c falhou: f0-001 hash diverge

Resultado: 14/15 aprovadas — 1 violação (alta: 1) — NÃO CONFORME
```
