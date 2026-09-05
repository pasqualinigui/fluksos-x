# Procedimento — Branch protection (`main` + `develop`) — item 010

> **Natureza**: config de servidor aplicada por humano (🧑). Este arquivo é o
> procedimento versionado + checklist; o oráculo (`f0-010` FR-008/009) assere
> este documento, nunca o servidor (sem token — Lei Zero). Precedente 003-T031.

## Aplicar (GitHub → Settings → Branches → Add rule)

Para cada padrão (`main`, `develop`):

- [x] Branch name pattern: `main` (respectivamente `develop`)
- [x] ✅ Require status checks before merging — checks: `verify`, `harness`,
      `lint`, `types`, `tests`, `audit`, `secrets`, `coverage`, `commitlint`
- [x] ✅ Require branches to be up to date: **DESMARCADO** (checks frouxos —
      decisão CLARIFY 2026-09-04)
- [x] ✅ Do not allow bypassing the above settings (inclusive admins)
- [x] ✅ Restrict deletions + block force pushes (padrão da proteção)
- [x] ⬜ Require pull request reviews: **DESMARCADO** (deadlock com 1
      mantenedor; reavaliar com 2º colaborador)
- [x] ⬜ Lock branch, merge queue, signed commits, linear history: **fora de
      escopo da 010** (não decididos; merge queue/linear avaliados em item futuro)

## Verificar (cenário 🧑, quickstart Cenário 4)

- [x] PR de teste com defeito: checks vermelhos travam o merge até verde
- [x] Push direto em `main`: recusado pelo servidor
- [x] Evidência registrada abaixo (data + executor + prints/links)

## Evidência de aplicação

- [x] Aplicada em: **2026-09-05** por: **agente de sessão (build, via `gh` + MCP GitHub, conta `pasqualinigui`)**
- **Repositório:** `pasqualinigui/fluksos-x` (criado nesta sessão; visibilidade
  alterada privado → **público** por decisão do mantenedor — protection com
  required checks exige Pro em privado no plano free).
- **Divergência anterior BAIXADA:** a declarada em 2026-09-04 (sem acesso ao
  servidor) não vale mais; esta seção a substitui como evidência positiva.
- **Cenário 🧑 executado:**
  - PR #1 (`feature/f0-a1-proof`, `test(a1)` com violação `ruff` F401
    proposital): CI run `33946950104` — `lint`/`tests`/`harness`/`verify`/
    `secrets`/`coverage` vermelhos, `audit`/`types`/`commitlint` verdes;
    `gh pr merge` recusado: *"Pull request #1 is not mergeable: the base
    branch policy prohibits the merge"* (inclusive admin — `enforce_admins`
    verificado). PR fechado sem merge; branch removida.
  - Push direto em `main` (commit vazio de sonda): recusado:
    `"[remote rejected] main -> main (protected branch hook declined)"`;
    `main` local restaurada via `reset --hard` (tree limpa, sem resíduo).
- **Proteção verificada via API** (`main` + `develop`): 9 contexts,
  `strict: false` (frouxos), `enforce_admins: true`, sem reviews,
  `allow_force_pushes: false`, `allow_deletions: false`.
- **Dívida exposta pelo novo fluxo:** pre-push travou em `feature/*`
  (`f0-001` media HEAD, não a linha) → corrigida pela ADR-029 na mesma
  sessão (forma exata, manifest citado); `f0-001` 30/30 em feature branch.
