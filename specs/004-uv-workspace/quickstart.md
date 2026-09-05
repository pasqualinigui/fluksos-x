# Quickstart — 004 UV workspace monorepo

**Spec**: [spec.md](./spec.md) (17 FRs, 8 SCs, 3 US) · **Plan**: [plan.md](./plan.md) (Fases A–E) · **Contracts**: [workspace-contract.md](./contracts/workspace-contract.md)

Guia de validação executável da base física. Cada cenário é independente e prova um `SC`/`US` distinto. Nenhum cenário exige Ruff/MyPy/Pytest/Docker — apenas `uv`, `python3`, `git`, `bash`.

**Pré-requisitos**: `uv 0.12.7` (ou `>=0.12.7,<0.13`; se local `0.12.1`, `uv self update`), `python 3.12` (`python --version` → `3.12.x`), `git`, `bash`.

---

## Cenário 1 — Clone limpo, ambiente com um comando (US1, SC-001)

Prova que a base física é reprodutível com um comando.

```bash
git clone <repo> /tmp/fkx-probe && cd /tmp/fkx-probe
ls pyproject.toml uv.lock .python-version   # D1/D2/D5 existem
uv sync
ls .venv/bin/python .venv/.gitignore       # FR-008
uv run python --version                    # → 3.12.x sem source .venv/bin/activate
git status --porcelain | grep -q .venv && echo "FAIL .venv leaked" || echo "OK .venv ignorado"
```

**Esperado**: `uv sync` cria `.venv` em <2 min, `uv run` funciona sem ativação, `git status` não lista `.venv/`.

---

## Cenário 2 — Idempotência do lock (SC-002)

Prova que `uv.lock` é determinístico.

```bash
sha256sum uv.lock > /tmp/before
uv sync
sha256sum uv.lock > /tmp/after
diff /tmp/before /tmp/after && echo "OK idempotente" || echo "FAIL drift"
uv sync && sha256sum uv.lock | diff - /tmp/after
```

**Esperado**: hashes idênticos em 100% das execuções consecutivas sem mudança em `pyproject.toml`.

---

## Cenário 3 — .venv descartável e regenerável (US1 edge, SC-003)

Prova que `.venv` é efêmero e `uv.lock` é fonte de verdade.

```bash
sha256sum uv.lock > /tmp/lock-before
rm -rf .venv
test ! -d .venv && echo "OK removido"
uv sync
test -x .venv/bin/python && echo "OK recriado"
sha256sum uv.lock > /tmp/lock-after
diff /tmp/lock-before /tmp/lock-after && echo "OK lock inalterado" || echo "FAIL lock mudou"
git check-ignore -q .venv && echo "OK .venv ignorado" || echo "FAIL .venv não ignorado"
git check-ignore -q uv.lock && echo "FAIL uv.lock ignorado" || echo "OK uv.lock rastreado"
```

**Esperado**: `.venv` recriado idêntico, `uv.lock` hash inalterado, Lei Zero preservada.

---

## Cenário 4 — Workspace pronto para `packages/*` sem editar root (US2, SC-004)

Prova que o glob `packages/*` descobre membros automaticamente.

```bash
test ! -d packages && echo "OK sem packages em 004" || echo "FAIL packages não deveria existir"
mkdir -p packages/_probe/src/_probe
cat > packages/_probe/pyproject.toml <<'TOML'
[project]
name = "_probe"
version = "0.1.0"
requires-python = ">=3.12,<3.14"
dependencies = []
[build-system]
requires = ["uv_build>=0.12.7,<0.13"]
build-backend = "uv_build"
TOML
uv sync && echo "OK membro _probe descoberto sem editar root pyproject.toml" || echo "FAIL descoberta"
rm -rf packages/_probe
uv sync && echo "OK limpo após remover probe"
```

**Esperado**: `uv sync` descobre `_probe` via `members=["packages/*"]` sem tocar `pyproject.toml` root; inter-membro futuro usa `{ workspace = true }`.

---

## Cenário 5 — Lei Zero e harness (US3, SC-005/SC-006) + fronteira escopo (SC-008)

Prova que a trava é auditável, o oráculo nomeia FR e a fronteira está preservada.

```bash
# Lei Zero
grep -F "*.lock" .gitignore && echo "FAIL *.lock em .gitignore" || echo "OK sem *.lock"
git check-ignore -q uv.lock && echo "FAIL uv.lock ignorado" || echo "OK uv.lock rastreado"
git check-ignore -q .venv && echo "OK .venv ignorado" || echo "FAIL .venv não ignorado"
git diff -- .gitignore | grep -q . && echo "FAIL .gitignore diff em 004" || echo "OK .gitignore intacto"

# Harness nomeia FR e roda <5s
time scripts/verify/f0-004-uv-workspace.sh --quiet && echo "OK harness verde"
time scripts/verify/f0-004-uv-workspace.sh 2>&1 | grep -q "FR-" && echo "OK observável" || echo "FAIL sem FR"
scripts/verify/f0-004-uv-workspace.sh --list | grep -c "^FR-"   # 10–14

# Fronteira escopo — nada de 005–016 em 004
test -d packages && echo "FAIL packages existe" || echo "OK sem packages"
grep -R "ruff\|mypy\|pytest\|lefthook\|pip-audit\|trivy" pyproject.toml && echo "FAIL tool adiantada" || echo "OK fronteira preservada"

# CI glob inclui f0-004 sem editar ci.yml
grep -F "for f in scripts/verify/f0-" .github/workflows/ci.yml && echo "OK CI glob"
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && echo "OK harness acumulado"
```

**Esperado**: Lei Zero verde, harness <5s com `FR-` por linha, fronteira `SC-008` preservada, `ci.yml` inclui `f0-004` automaticamente.

---

## Cenário 6 — Validação remota (SC-007, pós-merge)

Observável só após push.

1. Push verde em `main` → GitHub Actions job `verify` verde (inclui `f0-004`).
2. Branch com violação (ex.: remover `requires-python` ou adicionar `*.lock` em `.gitignore`) → PR `verify` vermelho com `🔴 FR-...`.

---

## Troubleshooting

| Sintoma | Causa | Correção |
|---|---|---|
| `uv_build>=0.12.7` falha com `uv 0.12.1` | local desatualizado (D5) | `uv self update` ou reinstall `astral-sh/uv 0.12.7` |
| `.python-version` com `3.11` | fora de `requires-python` | `echo 3.12 > .python-version && uv sync` |
| `uv sync` cria `src/` | `uv init` default cria `src/<name>` para lib | remover `src/` — root virtual não tem código; manter só `pyproject.toml`/`uv.lock`/`.venv` |
| `packages/_probe` falha sem `pyproject.toml` | todo dir casado precisa `pyproject.toml` (workspaces.md) | garantir `packages/_probe/pyproject.toml` antes de `uv sync` |
| `git check-ignore .venv` negativo | `.venv/.gitignore:*` ainda não criado (sem `uv sync`) | `uv sync` primeiro, depois checar |

---

## Limpeza

```bash
rm -rf /tmp/fkx-probe /tmp/before /tmp/after /tmp/lock-before /tmp/lock-after
```

Nenhum cenário deixa resíduo além do clone temporário.
