# Data Model — 004 UV workspace monorepo

**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md) (D1–D10)

Derivado de FR-001..017 e Key Entities `spec.md:138-144`. Nenhum SQL; modelo é filesystem + TOML.

---

## Entidades

### 1. Workspace root

Artefato raiz do monorepo. É também um membro implícito do workspace.

| Atributo | Tipo | Restrição | Fonte |
|---|---|---|---|
| `path` | path | MUST ser `pyproject.toml` na raiz do repo | FR-001, layout.md |
| `project.name` | string | `== "fluksos-x"` (hyphen, não underscore) | FR-001 |
| `project.version` | semver string | `== "0.1.0"` | FR-001 |
| `project.requires-python` | specifier | `== ">=3.12,<3.14"` (single interseção) | FR-002, D4 |
| `project.dependencies` | list[string] | `== []` em 004 (sem runtime deps) | assumptions — dev deps só em 005 |
| `build-system.requires` | list[string] | MUST conter `uv_build>=0.12.7,<0.13` (único elemento em 004) | FR-003, D5 |
| `build-system.build-backend` | string | `== "uv_build"` | FR-003 |
| `tool.uv.workspace.members` | list[glob] | `== ["packages/*"]`, sem `exclude` em 004 | FR-004, D4 |
| `tool.uv.workspace.exclude` | list[glob] | MUST NOT existir em 004 | FR-004 |
| `tool.uv.sources` | table | MUST NOT existir em 004 (sem membros, sem inter-dep) | FR-015 |
| `formato` | file | TOML válido (`tomllib.load` sem erro) | FR-001 |

**Validação**: `python3 -c 'import tomllib, pathlib; d=tomllib.load(open("pyproject.toml","rb")); assert d["project"]["name"]=="fluksos-x"; assert d["project"]["requires-python"]==">=3.12,<3.14"; assert "uv_build>=0.12.7,<0.13" in d["build-system"]["requires"]; assert d["tool"]["uv"]["workspace"]["members"]==["packages/*"]'`

**Transições**: criado em Fase C (`uv init` + ajuste), nunca reescrito por itens que adicionam membros — apenas `tool.uv.sources` pode ganhar entradas em 006+ sem tocar `members`.

**Relacionamentos**: 1 — 1 `uv.lock` (ao lado), 1 — 1 `.venv` (vizinho), 1 — N `Workspace member` futuro (0 em 004, descoberto por glob).

---

### 2. uv.lock (trava universal)

Lockfile determinístico cross-platform.

| Atributo | Tipo | Restrição | Fonte |
|---|---|---|---|
| `path` | path | `== "uv.lock"` ao lado de `pyproject.toml` | FR-006, D2 |
| `formato` | file | TOML válido (`tomllib.load`) | FR-006 |
| `versionado` | git | `! git check-ignore -q uv.lock` (não ignorado) | FR-011, D7 |
| `gerenciado` | tool | mutável só via `uv lock`/`uv sync`/`uv add` | FR-007 |
| `universal` | markers | contém markers OS/arch/Python (cross-platform) | D10, layout.md |
| `idempotente` | hash | `sha256sum` idêntico após `uv sync` duplo sem mudança em `pyproject.toml` | SC-002, D10 |

**Validação**: existência + TOML parse + `git check-ignore` negativo; quando `uv` disponível, `uv lock --check` deve passar (FR-007 — harness tolera `uv` ausente).

**Transições**: vazio válido em 004 (sem deps) → cresce quando `dependencies`/`dependency-groups` ganham entradas em 005+; sempre versionado.

**Entidade não-confusível**: não é `pylock.toml` (PEP 751) — este é export de 013 via `uv export --format pylock.toml`.

---

### 3. Project environment (.venv)

Ambiente virtual isolado e descartável.

| Atributo | Tipo | Restrição | Fonte |
|---|---|---|---|
| `path` | directory | `== ".venv/"` ao lado de `pyproject.toml` | FR-008, D3 |
| `interpreter` | file | `.venv/bin/python` (POSIX) executável, `python --version` == `3.12.x` | FR-008 |
| `.venv/.gitignore` | file | MUST existir e conter `*` (criado por `uv sync`) | FR-008, D3 |
| `ignorado` | git | `git check-ignore -q .venv` positivo; `git status --porcelain` não lista `.venv/` | FR-011 |
| `descartável` | lifecycle | `rm -rf .venv && uv sync` recria idêntico sem alterar `uv.lock` | FR-009, D10 |
| `gerenciado` | tool | criado por `uv sync` ou `uv run` (sem `source activate`) | FR-008, D3 |

**Validação**: `test -x .venv/bin/python && grep -Fq '*' .venv/.gitignore && git check-ignore -q .venv`

**Transições**: efêmero — removível a qualquer momento; recriado on-demand por `uv sync`/`uv run`.

---

### 4. .python-version

Pin local de Python.

| Atributo | Tipo | Restrição | Fonte |
|---|---|---|---|
| `path` | file | `== ".python-version"` na raiz | FR-005, D5 |
| `conteúdo` | string | `3.12` ou `3.12.x` (ex.: `3.12.3`), linha única sem espaços | FR-005 |
| `versionado` | git | `! git check-ignore -q .python-version` (linha `# .python-version` em `.gitignore` é comentário, não ativo) | D7 |
| `precedência` | rule | não substitui `requires-python` — este é fonte de verdade do workspace | FR-005 |

**Validação**: `grep -Eq '^3\.12(\.[0-9]+)?$' .python-version`

---

### 5. Workspace member (futuro — zero em 004)

Pacote sob `packages/*` com `pyproject.toml` próprio.

| Atributo | Tipo | Restrição | Fonte |
|---|---|---|---|
| `path` | directory | `packages/<name>/` com `pyproject.toml` dentro | D4, workspaces.md |
| `requires-python` | specifier | MUST ser compatível com interseção do root (`>=3.12,<3.14`) — caso contrário workspace falha | D4 |
| `descoberta` | glob | casado por `members=["packages/*"]` e não `exclude`; todo diretório casado MUST conter `pyproject.toml` | D4 |
| `inter-dep` | table | dependência entre membros via `tool.uv.sources.<nome>={ workspace=true }` (não `path`) | FR-015 |
| `existência em 004` | constraint | MUST NOT existir — `! test -d packages` (FR-013, D8) | FR-013 |

**Validação em 004**: `! test -d packages` (harness reprova se existir).

**Validação futura (005+)**: criar `packages/_probe/pyproject.toml` temporário e `uv sync` deve descobrir sem editar root (SC-004).

---

## Diagrama de relacionamentos

```
Workspace root (pyproject.toml)
  ├─1:1── uv.lock (universal, versionado)
  ├─1:1── .venv (efêmero, ignorado, .venv/.gitignore:*)
  ├─1:1── .python-version (3.12)
  └─1:N── Workspace member (0 em 004, packages/* futuro, workspace=true)
```

---

## Regras de validação cruzada

1. `requires-python` do root é interseção single — membros com `requires-python` incompatível fazem `uv sync` falhar (workspaces.md).
2. `uv.lock` hash estável após `uv sync` duplo sem mudança em `pyproject.toml` (idempotência).
3. `.venv` nunca em `git ls-files`; `uv.lock` sempre em `git ls-files` após commit.
4. `.gitignore` diff vazio em 004 (FR-012) — 001 já fixou exclusões.
