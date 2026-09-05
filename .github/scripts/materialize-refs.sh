#!/usr/bin/env bash
# =============================================================================
# Materializa refs locais + identidade de autoria no runner.
#
# Por que existe (ADR-030 §1 + adendo materialize):
#   O runner entrega um checkout sem `refs/heads/*` e sem identidade de autoria
#   configurada. Vários oráculos medem exatamente essas duas coisas:
#     - f0-001 FR-001/FR-002 — existência das linhas `main` e `develop`
#     - f0-001 FR-003a       — autoria em escopo local (mantenedor ou bot)
#     - tests/test_harness_debts.py::test_main_branch_exists
#   Reconstruir o que o oráculo define é *setup*, mesmo papel de `uv sync`:
#   não altera o que é medido, apenas põe o runner no estado que a máquina
#   local já tem. Nunca é "fazer o teste passar".
#
# Forma tolerante a checkout (adendo ADR-030):
#   `git fetch origin main:refs/heads/main` é RECUSADO quando `main` está em
#   checkout (runs de push a `main`; PRs são detached e passavam). Por isso:
#   fetch só atualiza tracking refs, e `update-ref` materializa a linha apenas
#   se ela ainda não existir.
#
# Chamado por: jobs `verify`, `harness`, `tests`, `coverage` (os que executam
# oráculos ou testes que dependem de git).
# =============================================================================
set -euo pipefail

git fetch origin main develop

git show-ref --verify --quiet refs/heads/main    || git update-ref refs/heads/main    origin/main
git show-ref --verify --quiet refs/heads/develop || git update-ref refs/heads/develop origin/develop

git config --local user.name  "github-actions[bot]"
git config --local user.email "github-actions[bot]@users.noreply.github.com"
