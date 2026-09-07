---
description: "Task list for 013 — automação de release"
---

# Tasks: Automação de release

**Input**: Design documents from `/specs/013-release-automation/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/oracle-cli.md`, `quickstart.md`

## Phase 1: Setup

- [x] T001 Confirmar harness 12/12 + manifest 12/12
- [x] T002 Confirmar ausências de fronteira
- [x] T003 Criar `evidence/` para red.txt/green.txt

## Phase 2: Foundational — esqueleto do oráculo

- [x] T004 Criar `scripts/verify/f0-013-release.sh` com esqueleto
- [x] T005 Acrescer 13ª linha ao manifest
- [x] T006 Implementar asserts auto-verificáveis

## Phase 3: Asserções do oráculo 🔴

- [x] T007 FR-001/002 — PSR em dev + configuração
- [x] T008 FR-003/004/005 — version_toml + allow_zero_version
- [x] T009 FR-006/007 — release.yml + jobs separados
- [x] T010 FR-008/009/010 — uv build + pypa action + SBOM
- [x] T011 FR-011/012/013/014 — efêmeros + tag trigger + pin uv + checklist
- [x] T012 **VERMELHO** — executar oráculo, preservar red.txt

## Phase 4+5: Configuração verde 🟢

- [x] T013 Adicionar PSR em dev + uv sync
- [x] T014 Adicionar [tool.semantic_release]
- [x] T015 Validar em réplica
- [x] T016 Validar CHANGELOG + lockstep
- [x] T017 Confirmar uv publish --dry-run

## Phase 6: Workflow + checklist

- [x] T018 Criar release.yml com jobs separados
- [x] T019 Implementar SBOM + pylock no workflow
- [x] T020 Criar checklists/server-side.md

## Phase 7: Convergência

- [x] T021 **VERDE** — oráculo 16/16 + commit feat(release)
- [x] T022 README 013 ✅ + hash
- [x] T023 Re-executar harness 13/13
- [x] T024 Confirmar tasks zero [ ] + AGENTS.md
- [x] T025 Troubleshooting + commit docs(specs)
