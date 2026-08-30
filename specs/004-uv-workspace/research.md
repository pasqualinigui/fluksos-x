# Research — 004 UV workspace monorepo

**Feature**: `004-uv-workspace` (item 0.1, ordem 004/016 ADR-011) · **Date**: 2026-08-30
**Vinculante**: `docs/plan/research/f0-004-uv-workspace.md` (381 linhas, Q1–Q10, D1–D10) · **Status**: sem NEEDS CLARIFICATION
**Método**: consulta direta a fontes canônicas + disco (nenhum dado por memória) — `constitution VIII`

Este arquivo consolida as decisões já verificadas contra fonte. A pesquisa completa com evidências byte-a-byte vive em `docs/plan/research/f0-004-uv-workspace.md`; aqui registra-se apenas o essencial para `plan.md` Fase 0.

---

## Decisões (D1–D10)

| # | Decisão | Rationale | Alternativas consideradas |
|---|---|---|---|
| **D1** | `pyproject.toml` root virtual com `name="fluksos-x"`, `version="0.1.0"`, `requires-python=">=3.12,<3.14"`, `build-system requires=["uv_build>=0.12.7,<0.13"]` `build-backend="uv_build"`, `tool.uv.workspace.members=["packages/*"]` sem `exclude` | `docs.astral.sh/uv/concepts/projects/layout` lista `pyproject.toml` + `build-system uv_build>=0.12.7,<0.13` como mínimo criado por `uv init`; `.../workspaces` exige `members` globs e declara que root é também membro. `uv sync` sem `build-system` não instala projeto como editable (layout.md). `requires-python` single é interseção de todos os membros (workspaces.md). | Omitir `build-system` — rejeitado: `.venv` ficaria sem âncora editable; omitir `tool.uv.workspace` — rejeitado: cada pacote teria lock próprio, perde deduplicação pnpm-like (§2 plano). |
| **D2** | `uv.lock` ao lado de `pyproject.toml`, versionado, TOML legível, gerenciado só por `uv`, formato específico de `uv` (não `pylock.toml` em 004) | `layout.md#the-lockfile`: *"`uv.lock` ... should be checked into version control, allowing for consistent and reproducible installations"*, *"`uv.lock` is managed by uv and should not be edited manually"*, formato específico não intercambiável, `pylock.toml` é export. `uv lock --check`/`--locked`/`--frozen` documentados em `sync.md`. | `*.lock` em `.gitignore` — rejeitado: viola ADR-001 D3 e `f0-001` FR-020/021; criar `pylock.toml` em 004 — rejeitado: duplica fonte de verdade, exportável em 013 sem config extra. |
| **D3** | `.venv` vizinho a `pyproject.toml`, criado por `uv sync`/`uv run`, ignorado via `.venv/.gitignore` interno `*`, descartável e regenerável, nunca versionado | `layout.md#the-project-environment`: *"uv will create a virtual environment ... in a `.venv` directory next to the `pyproject.toml` ... It is not recommended to include the `.venv` directory in version control; it is automatically excluded from git with an internal `.gitignore` file."* `uv run` cria/atualiza automaticamente; `uv sync` é exact sync por padrão (remove estranhos). | `managed=false` (`[tool.uv] managed=false`) — rejeitado: desativa lock/sync automático, determinismo depende de gerenciamento automático; listar `.venv` explícito no `.gitignore` raiz — desnecessário (cobertura interna) e viola regra 5 (ADR-002). |
| **D4** | `members=["packages/*"]` globs, sem `exclude` em 004; dependência inter-membro futura via `tool.uv.sources.<name>={ workspace=true }`; single `requires-python` interseção | `workspaces.md` exemplo `albatross` com `members=["packages/*"]` + `exclude`, `reference/settings` globs, `tool.uv.sources` com `workspace=true` (não `path` dentro de workspace). `implementation_plan.md §15` layout 5–7 pacotes sob `packages/`. | `path` dependencies sem workspace — rejeitado: perde `uv run --package` e lock unificado, cada pacote lock próprio diverge; `members` por pacote enumerado — rejeitado: cada spec futura reescreveria root. |
| **D5** | Pin `uv 0.12.7` (`uv_build>=0.12.7,<0.13`), `.python-version` `3.12`, range `>=3.12,<3.14`; local `0.12.1` converge ao pin | PyPI `uv/json` 2026-08-30 = `0.12.7` (implementation_plan §4 re-verificado), `uv --version` local `0.12.1`, `docs/guides/projects` snippet `uv_build>=0.12.7,<0.13`, `python --version` local `3.12.3`. Intervalo menor `<0.13` é semver estável. | `uv_build>=0.12.1` para acomodar local — rejeitado: indeterminístico, aceita regressão de resolver; `.python-version 3.11` — fora de `requires-python`. |
| **D6** | Flags `--locked`/`--frozen`/`--check` documentadas, não impostas em 004; `uv sync` sem flag materializa lock inicial idempotente | `uv lock/sync --help` + `sync.md`: `--locked` aborta se lock mudaria, `--frozen` confia no lock, `--check` só verifica. Bootstrap sem `uv.lock` + `--locked` falha sempre (paradoxo). 010 consome artefato de 004 com `--frozen`. | Forçar `--locked` em 004 — rejeitado: primeiro run sem lock falha por construção. |
| **D7** | Não modificar `.gitignore` em 004; `uv.lock` já versionado (ausência de `*.lock`), `.venv` já ignorado internamente | `.gitignore` 265 linhas verificado 2026-08-30: sem `*.lock`/`uv.lock`, sem `.venv` literal mas coberto por `.venv/.gitignore:*` após `uv sync`; `# .python-version` comentado (versionável). ADR-002 regra 5 (hash criptográfico) impede reescrever oráculo de 001 sem ADR. | Adicionar `.venv/` explícito ao `.gitignore` raiz — rejeitado: redundante e viola regra 5; adicionar `*.lock` — rejeitado: cobriria `uv.lock`. |
| **D8** | Apenas root virtual em 004; sem `packages/` placeholder; escala para 010 (`uv sync --frozen`), 013 (`uv build`/`uv export`), 014 (Renovate) sem reescrever | ADR-011 mapa 16 posições, `concepts/projects/export` (`requirements.txt`/`pylock.toml`/`cyclonedx`), `uv build` requer `build-system` já presente. Membros criados pelos itens que os exigem (006 `core`, 007 `cli`...). | Criar `packages/core`/`cli` vazios em 004 — rejeitado: antecipa 006/007, viola escada e cria `pyproject.toml` sem spec. |
| **D9** | Harness `f0-004-uv-workspace.sh` 10–14 asserções só base física; não verifica `packages/*` nem CI flags | `specs/001-.../contracts/oracle-cli.md` + `scripts/verify/README.md` + `f0-001` 494 linhas + `f0-003` 487 linhas — contrato: exit `0`/`1`/`2`, `--quiet`, uma linha por REQ-ID, crescimento por acréscimo. CI `003` job `verify` estável com glob `for f in scripts/verify/f0-*.sh`. | Verificar `uv sync --locked` ou `ruff` em 004 — rejeitado: fronteira escada, pertence a 005–010. |
| **D10** | `uv.lock` universal (cross-platform markers), `uv sync` idempotente (`sha256sum` estável), `.venv` descartável (`rm -rf .venv && uv sync` recria) | `sync.md#automatic-lock-and-sync`: locking/syncing automáticos, `uv run` recria se ausente, `uv.lock --upgrade` só muda com constraint. Universal por construção. | Assertar timestamp de `.venv` — rejeitado: não determinístico; harness testa existência + hash de lock. |

---

## Fontes verificadas 2026-08-30

| Fonte | Evidência | HTTP |
|---|---|---|
| `https://docs.astral.sh/uv/concepts/projects/layout/` | `pyproject.toml` + `build-system uv_build` + `.venv` + `uv.lock` versionado | 200 |
| `https://docs.astral.sh/uv/concepts/projects/workspaces/` | `tool.uv.workspace members/exclude`, single `requires-python`, `workspace=true` | 200 |
| `https://docs.astral.sh/uv/concepts/projects/sync/` | `uv lock --check`, `uv sync --locked/--frozen`, exact sync | 200 |
| `https://docs.astral.sh/uv/reference/settings/` | `members`/`exclude` globs | 200 |
| `https://pypi.org/pypi/uv/json` | `uv` `0.12.7` (PyPI latest) | 200 |
| `uv --version` / `uv init --help` / `uv sync --help` local | `0.12.1` local, flags `--locked/--frozen/--check`, `--build-backend uv/hatch/...` | local |
| `python --version` local | `3.12.3` | local |
| `.gitignore` (265 linhas) + `f0-001-foundation.sh` | sem `*.lock`, sem `.venv` literal, `uv.lock` versionado | disco |
| `.github/workflows/ci.yml` (003, 25 linhas) | job `verify` glob inclui `f0-004` automaticamente | disco |

---

## Pós-Phase 1 — nenhum NEEDS CLARIFICATION remanescente

Todas as incógnitas do Technical Context foram resolvidas por D1–D10; `data-model.md`/`contracts/`/`quickstart.md` não introduzem incógnita nova.
