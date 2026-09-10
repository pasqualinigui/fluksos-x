# fluksos-x — mapa da árvore (para IA)

> Motor determinístico `fkx` em bootstrap (Fase 0, 16/16). Este mapa é a planta do repositório: a região gerada lista todos os paths rastreados; a curadoria abaixo diz o papel de cada diretório e onde ler cada assunto. Detalhe mora nos arquivos apontados, nunca aqui.

<!-- GENERATED-START -->
.claude/skills/speckit-analyze/SKILL.md
.claude/skills/speckit-checklist/SKILL.md
.claude/skills/speckit-clarify/SKILL.md
.claude/skills/speckit-constitution/SKILL.md
.claude/skills/speckit-converge/SKILL.md
.claude/skills/speckit-implement/SKILL.md
.claude/skills/speckit-plan/SKILL.md
.claude/skills/speckit-specify/SKILL.md
.claude/skills/speckit-tasks/SKILL.md
.claude/skills/speckit-taskstoissues/SKILL.md
.env.example
.github/dependabot.yml
.github/scripts/materialize-refs.sh
.github/workflows/ci.yml
.github/workflows/dependabot-automerge.yml
.github/workflows/release.yml
.gitignore
.python-version
.specify/.gitignore
.specify/init-options.json
.specify/integration.json
.specify/integrations/agy.manifest.json
.specify/integrations/claude.manifest.json
.specify/integrations/speckit.manifest.json
.specify/memory/.constitution-template.json
.specify/memory/constitution.md
.specify/scripts/bash/check-prerequisites.sh
.specify/scripts/bash/common.sh
.specify/scripts/bash/create-new-feature.sh
.specify/scripts/bash/resolve-template.sh
.specify/scripts/bash/setup-plan.sh
.specify/scripts/bash/setup-tasks.sh
.specify/templates/checklist-template.md
.specify/templates/constitution-template.md
.specify/templates/plan-template.md
.specify/templates/spec-template.md
.specify/templates/tasks-template.md
.specify/workflows/speckit/workflow.yml
.specify/workflows/workflow-registry.json
AGENTS.md
CLAUDE.md
CONTRIBUTING.md
commitlint.config.js
docker-compose.yml
docker/alloy/config.alloy
docker/grafana/provisioning/datasources.yaml
docker/postgres/01-users-dbs.sh
docker/prometheus/prometheus.yml
docs/guides/agent-bootstrap.md
docs/plan/addendum_v3.md
docs/plan/audit/f0-audit-001-004.md
docs/plan/audit/f0-audit-005-008.md
docs/plan/audit/f0-audit-009-012.md
docs/plan/audit/f0-audit-013-016.md
docs/plan/audit/f1-checkpoint-pre-fase1.md
docs/plan/decisions.md
docs/plan/implementation_plan.md
docs/plan/research/f0-001-git-branching.md
docs/plan/research/f0-002-constitution.md
docs/plan/research/f0-003-ci-minimo.md
docs/plan/research/f0-004-uv-workspace.md
docs/plan/research/f0-005-pytest.md
docs/plan/research/f0-006-ruff.md
docs/plan/research/f0-007-mypy.md
docs/plan/research/f0-008-fr007-flake.md
docs/plan/research/f0-008-pip-audit-trivy.md
docs/plan/research/f0-009-lefthook.md
docs/plan/research/f0-010-ci-completo.md
docs/plan/research/f0-011-packages-core.md
docs/plan/research/f0-012-packages-cli.md
docs/plan/research/f0-013-click-cve.md
docs/plan/research/f0-013-release-automation.md
docs/plan/research/f0-014-dependency-updates.md
docs/plan/research/f0-015-docker-compose.md
docs/plan/research/f0-016-tree.md
docs/plan/research/f0-skills-mcp-2026-09.md
docs/plan/research/f1-017-harness.md
docs/tree.md
lefthook.yml
packages/cli/pyproject.toml
packages/cli/src/fkx_cli/__init__.py
packages/cli/src/fkx_cli/main.py
packages/cli/src/fkx_cli/py.typed
packages/core/pyproject.toml
packages/core/src/fkx_core/__init__.py
packages/core/src/fkx_core/config.py
packages/core/src/fkx_core/exceptions.py
packages/core/src/fkx_core/models.py
packages/core/src/fkx_core/py.typed
packages/core/src/fkx_core/state.py
pyproject.toml
scripts/generate-tree.py
scripts/governance/apply-adr-035.sh
scripts/verify/README.md
scripts/verify/f0-001-foundation.sh
scripts/verify/f0-002-constitution.sh
scripts/verify/f0-003-ci-minimo.sh
scripts/verify/f0-004-uv-workspace.sh
scripts/verify/f0-005-pytest.sh
scripts/verify/f0-006-ruff.sh
scripts/verify/f0-007-mypy.sh
scripts/verify/f0-008-pip-audit.sh
scripts/verify/f0-009-lefthook.sh
scripts/verify/f0-010-ci-completo.sh
scripts/verify/f0-011-core.sh
scripts/verify/f0-012-cli.sh
scripts/verify/f0-013-release.sh
scripts/verify/f0-014-dependabot.sh
scripts/verify/f0-015-docker-compose.sh
scripts/verify/f0-016-tree.sh
scripts/verify/manifest.sha256
specs/001-git-branching-strategy/checklists/requirements.md
specs/001-git-branching-strategy/contracts/oracle-cli.md
specs/001-git-branching-strategy/data-model.md
specs/001-git-branching-strategy/evidence/t015-red.txt
specs/001-git-branching-strategy/evidence/t023-green.txt
specs/001-git-branching-strategy/plan.md
specs/001-git-branching-strategy/quickstart.md
specs/001-git-branching-strategy/research.md
specs/001-git-branching-strategy/spec.md
specs/001-git-branching-strategy/tasks.md
specs/002-constitution-ratification/checklists/requirements.md
specs/002-constitution-ratification/compliance-001.md
specs/002-constitution-ratification/contracts/entrypoint.md
specs/002-constitution-ratification/contracts/oracle-cli.md
specs/002-constitution-ratification/data-model.md
specs/002-constitution-ratification/evidence/green.txt
specs/002-constitution-ratification/evidence/red.txt
specs/002-constitution-ratification/plan.md
specs/002-constitution-ratification/quickstart.md
specs/002-constitution-ratification/research.md
specs/002-constitution-ratification/spec.md
specs/002-constitution-ratification/tasks.md
specs/003-ci-minimo/contracts/ci-workflow.md
specs/003-ci-minimo/data-model.md
specs/003-ci-minimo/evidence/green-quiet.txt
specs/003-ci-minimo/evidence/green.txt
specs/003-ci-minimo/evidence/red-quiet.txt
specs/003-ci-minimo/evidence/red.txt
specs/003-ci-minimo/plan.md
specs/003-ci-minimo/quickstart.md
specs/003-ci-minimo/research.md
specs/003-ci-minimo/spec.md
specs/003-ci-minimo/tasks.md
specs/004-uv-workspace/checklists/requirements.md
specs/004-uv-workspace/contracts/workspace-contract.md
specs/004-uv-workspace/data-model.md
specs/004-uv-workspace/evidence/green-quiet.txt
specs/004-uv-workspace/evidence/green.txt
specs/004-uv-workspace/evidence/list.txt
specs/004-uv-workspace/evidence/red-quiet.txt
specs/004-uv-workspace/evidence/red.txt
specs/004-uv-workspace/plan.md
specs/004-uv-workspace/quickstart.md
specs/004-uv-workspace/research.md
specs/004-uv-workspace/spec.md
specs/004-uv-workspace/tasks.md
specs/005-pytest/checklists/requirements.md
specs/005-pytest/contracts/oracle-cli.md
specs/005-pytest/contracts/pytest-contract.md
specs/005-pytest/data-model.md
specs/005-pytest/evidence/green.txt
specs/005-pytest/evidence/green_quiet.txt
specs/005-pytest/evidence/list.txt
specs/005-pytest/evidence/pytest_green.txt
specs/005-pytest/evidence/red.txt
specs/005-pytest/evidence/red_quiet.txt
specs/005-pytest/plan.md
specs/005-pytest/quickstart.md
specs/005-pytest/research.md
specs/005-pytest/spec.md
specs/005-pytest/tasks.md
specs/006-ruff/checklists/requirements.md
specs/006-ruff/contracts/oracle-cli.md
specs/006-ruff/contracts/ruff-contract.md
specs/006-ruff/data-model.md
specs/006-ruff/evidence/green.txt
specs/006-ruff/evidence/green_quiet.txt
specs/006-ruff/evidence/list.txt
specs/006-ruff/evidence/red.txt
specs/006-ruff/evidence/red_quiet.txt
specs/006-ruff/evidence/ruff_check.txt
specs/006-ruff/evidence/ruff_format.txt
specs/006-ruff/plan.md
specs/006-ruff/quickstart.md
specs/006-ruff/research.md
specs/006-ruff/spec.md
specs/006-ruff/tasks.md
specs/007-mypy/checklists/requirements.md
specs/007-mypy/contracts/mypy-contract.md
specs/007-mypy/contracts/oracle-cli.md
specs/007-mypy/data-model.md
specs/007-mypy/evidence/green.txt
specs/007-mypy/evidence/green_quiet.txt
specs/007-mypy/evidence/list.txt
specs/007-mypy/evidence/mypy_green.txt
specs/007-mypy/evidence/red.txt
specs/007-mypy/evidence/red_quiet.txt
specs/007-mypy/plan.md
specs/007-mypy/quickstart.md
specs/007-mypy/research.md
specs/007-mypy/spec.md
specs/007-mypy/tasks.md
specs/008-pip-audit-trivy/checklists/requirements.md
specs/008-pip-audit-trivy/contracts/oracle-cli.md
specs/008-pip-audit-trivy/contracts/pip-audit-contract.md
specs/008-pip-audit-trivy/data-model.md
specs/008-pip-audit-trivy/evidence/green.txt
specs/008-pip-audit-trivy/evidence/green_quiet.txt
specs/008-pip-audit-trivy/evidence/list.txt
specs/008-pip-audit-trivy/evidence/pip_audit_green.txt
specs/008-pip-audit-trivy/evidence/red.txt
specs/008-pip-audit-trivy/evidence/red_quiet.txt
specs/008-pip-audit-trivy/plan.md
specs/008-pip-audit-trivy/quickstart.md
specs/008-pip-audit-trivy/research.md
specs/008-pip-audit-trivy/spec.md
specs/008-pip-audit-trivy/tasks.md
specs/009-lefthook/checklists/requirements.md
specs/009-lefthook/contracts/oracle-cli.md
specs/009-lefthook/data-model.md
specs/009-lefthook/evidence/green.txt
specs/009-lefthook/evidence/green_quiet.txt
specs/009-lefthook/evidence/latencia.txt
specs/009-lefthook/evidence/list.txt
specs/009-lefthook/evidence/min_version_refusal.txt
specs/009-lefthook/evidence/red.txt
specs/009-lefthook/evidence/red_quiet.txt
specs/009-lefthook/plan.md
specs/009-lefthook/quickstart.md
specs/009-lefthook/research.md
specs/009-lefthook/spec.md
specs/009-lefthook/tasks.md
specs/010-ci-completo/branch-protection.md
specs/010-ci-completo/checklists/requirements.md
specs/010-ci-completo/contracts/oracle-cli.md
specs/010-ci-completo/data-model.md
specs/010-ci-completo/evidence/green.txt
specs/010-ci-completo/evidence/green_quiet.txt
specs/010-ci-completo/evidence/list.txt
specs/010-ci-completo/evidence/red.txt
specs/010-ci-completo/evidence/red_quiet.txt
specs/010-ci-completo/plan.md
specs/010-ci-completo/quickstart.md
specs/010-ci-completo/research.md
specs/010-ci-completo/spec.md
specs/010-ci-completo/tasks.md
specs/011-packages-core/checklists/requirements.md
specs/011-packages-core/contracts/oracle-cli.md
specs/011-packages-core/data-model.md
specs/011-packages-core/evidence/green.txt
specs/011-packages-core/evidence/green_quiet.txt
specs/011-packages-core/evidence/list.txt
specs/011-packages-core/evidence/red.txt
specs/011-packages-core/evidence/red_quiet.txt
specs/011-packages-core/plan.md
specs/011-packages-core/quickstart.md
specs/011-packages-core/research.md
specs/011-packages-core/spec.md
specs/011-packages-core/tasks.md
specs/012-packages-cli/checklists/requirements.md
specs/012-packages-cli/contracts/oracle-cli.md
specs/012-packages-cli/data-model.md
specs/012-packages-cli/evidence/green.txt
specs/012-packages-cli/evidence/green_quiet.txt
specs/012-packages-cli/evidence/list.txt
specs/012-packages-cli/evidence/red.txt
specs/012-packages-cli/evidence/red_quiet.txt
specs/012-packages-cli/plan.md
specs/012-packages-cli/quickstart.md
specs/012-packages-cli/research.md
specs/012-packages-cli/spec.md
specs/012-packages-cli/tasks.md
specs/013-release-automation/checklists/requirements.md
specs/013-release-automation/checklists/server-side.md
specs/013-release-automation/contracts/oracle-cli.md
specs/013-release-automation/data-model.md
specs/013-release-automation/evidence/green.txt
specs/013-release-automation/evidence/red-fr017.txt
specs/013-release-automation/evidence/red.txt
specs/013-release-automation/plan.md
specs/013-release-automation/quickstart.md
specs/013-release-automation/research.md
specs/013-release-automation/spec.md
specs/013-release-automation/tasks.md
specs/014-dependency-updates/checklists/requirements.md
specs/014-dependency-updates/contracts/oracle-cli.md
specs/014-dependency-updates/data-model.md
specs/014-dependency-updates/evidence/green.txt
specs/014-dependency-updates/evidence/red.txt
specs/014-dependency-updates/evidence/sc007-deferral.txt
specs/014-dependency-updates/plan.md
specs/014-dependency-updates/quickstart.md
specs/014-dependency-updates/research.md
specs/014-dependency-updates/spec.md
specs/014-dependency-updates/tasks.md
specs/015-docker-compose/checklists/requirements.md
specs/015-docker-compose/contracts/oracle-cli.md
specs/015-docker-compose/data-model.md
specs/015-docker-compose/evidence/green.txt
specs/015-docker-compose/evidence/red.txt
specs/015-docker-compose/plan.md
specs/015-docker-compose/quickstart.md
specs/015-docker-compose/research.md
specs/015-docker-compose/spec.md
specs/015-docker-compose/tasks.md
specs/016-tree-docs/checklists/requirements.md
specs/016-tree-docs/contracts/oracle-cli.md
specs/016-tree-docs/data-model.md
specs/016-tree-docs/evidence/green.txt
specs/016-tree-docs/evidence/red.txt
specs/016-tree-docs/plan.md
specs/016-tree-docs/quickstart.md
specs/016-tree-docs/research.md
specs/016-tree-docs/spec.md
specs/016-tree-docs/tasks.md
specs/017-harness/checklists/requirements.md
specs/017-harness/contracts/oracle-cli.md
specs/017-harness/data-model.md
specs/017-harness/plan.md
specs/017-harness/quickstart.md
specs/017-harness/research.md
specs/017-harness/spec.md
specs/README.md
tests/__init__.py
tests/conftest.py
tests/test_fkx_cli_errors.py
tests/test_fkx_cli_help.py
tests/test_fkx_cli_version.py
tests/test_fkx_core_config.py
tests/test_fkx_core_errors.py
tests/test_fkx_core_models.py
tests/test_fkx_core_state.py
tests/test_harness_debts.py
tests/test_harness_oracles.py
uv.lock
<!-- GENERATED-END -->

## Árvore anotada (1 linha por diretório)

- `.github/` — CI e automação do servidor (workflows + bot).
- `.specify/` — ferramenta Spec-Kit (templates, scripts, memória da constitution).
- `docker/` — configs do compose montadas `:ro` (nunca imagens próprias).
- `docs/` — guias, plano, decisões, auditorias e pesquisas por item.
- `packages/` — código de produção (`core`, `cli`).
- `scripts/` — geradores e harness de verificação (oráculos `f0-*`).
- secrets/ — segredos file-based do compose (ignorado; só existe local).
- `specs/` — especificações por item + índice do mapa de execução.
- `tests/` — pytest do harness e dos pacotes.

## Ponteiros — onde ler o quê

| Assunto | Path | Papel |
|---|---|---|
| Porta de entrada operacional | `AGENTS.md` | ciclo canônico, 10 regras, onde estão as fontes |
| Governança (prevalece sobre tudo) | `.specify/memory/constitution.md` | 10 princípios I–X com critério de violação |
| Convenções de registro e linhas | `CONTRIBUTING.md` | commits, linhas de trabalho + PR, o que nunca entra |
| Plano das 5 fases e estrutura final | `docs/plan/implementation_plan.md` | intenção histórica; execução vive nas ADRs |
| Por que cada decisão | `docs/plan/decisions.md` | ADR-001..039, fonte da ordem e das exceções |
| Mapa de execução vigente | `specs/README.md` | 16 posições; `spec.md:11` traduz item↔ordem |
| Contrato do harness | `specs/001-git-branching-strategy/contracts/oracle-cli.md` | interface `--quiet`/`--list`, exit 0/1/2 |
| Como o harness cresce | `scripts/verify/README.md` | um oráculo por item + `manifest.sha256` |
| Release e publicação | `.github/workflows/release.yml` | PSR + OIDC PyPI + SBOM (013) |
| Atualização de dependências | `.github/dependabot.yml` | bot uv+actions com automerge pelo portão (014) |
| Infra local sob demanda | `docker-compose.yml` | núcleo PG+Redis + profiles, `restart: no` (015) |
| Segredos locais (molde) | `.env.example` | placeholders; o arquivo real nunca é commitado |
| CLI instalada | `packages/cli/src/fkx_cli/main.py` | entry point fkx via Typer |
| Núcleo do motor | `packages/core/src/fkx_core/` | config, estado, modelos, exceções |
| Auditoria vigente | `docs/plan/audit/f0-audit-013-016.md` | achados 013–016 e destinos |
