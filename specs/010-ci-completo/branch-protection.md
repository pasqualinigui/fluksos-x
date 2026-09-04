# Procedimento — Branch protection (`main` + `develop`) — item 010

> **Natureza**: config de servidor aplicada por humano (🧑). Este arquivo é o
> procedimento versionado + checklist; o oráculo (`f0-010` FR-008/009) assere
> este documento, nunca o servidor (sem token — Lei Zero). Precedente 003-T031.

## Aplicar (GitHub → Settings → Branches → Add rule)

Para cada padrão (`main`, `develop`):

- [ ] Branch name pattern: `main` (respectivamente `develop`)
- [ ] ✅ Require status checks before merging — checks: `verify`, `harness`,
      `lint`, `types`, `tests`, `audit`, `secrets`, `coverage`, `commitlint`
- [ ] ✅ Require branches to be up to date: **DESMARCADO** (checks frouxos —
      decisão CLARIFY 2026-09-04)
- [ ] ✅ Do not allow bypassing the above settings (inclusive admins)
- [ ] ✅ Restrict deletions + block force pushes (padrão da proteção)
- [ ] ⬜ Require pull request reviews: **DESMARCADO** (deadlock com 1
      mantenedor; reavaliar com 2º colaborador)
- [ ] ⬜ Lock branch, merge queue, signed commits, linear history: **fora de
      escopo da 010** (não decididos; merge queue/linear avaliados em item futuro)

## Verificar (cenário 🧑, quickstart Cenário 4)

- [ ] PR de teste com defeito: checks vermelhos travam o merge até verde
- [ ] Push direto em `main`: recusado pelo servidor
- [ ] Evidência registrada abaixo (data + executor + prints/links)

## Evidência de aplicação

<!-- preencher na convergência; se pendente, registrar divergência declarada (SC-005) -->
- [ ] Aplicada em: ____ por: ____
- **DIVERGÊNCIA DECLARADA (2026-09-04, convergência 010):** proteção NÃO aplicada —
  sem `gh`/token neste ambiente (Lei Zero proíbe credencial no repo) e sem acesso
  ao servidor nesta sessão. Workflow + procedimento versionados e verificados;
  required checks passam a valer no primeiro PR após aplicação humana do checklist
  acima. Revalidar na auditoria pós-012.
