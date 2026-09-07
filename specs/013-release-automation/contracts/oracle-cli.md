# Contrato do oráculo: `f0-013-release.sh` — mapa FR↔asserção (ADR-015b)

**Spec**: `specs/013-release-automation/spec.md` (16 FRs, 11 SCs, 4 US) · **Oráculo**: `scripts/verify/f0-013-release.sh`
**Contrato de interface**: `specs/001-git-branching-strategy/contracts/oracle-cli.md`

Identidade 1:1 — o oráculo emite os IDs **da spec**, sem remapeamento.

| Asserção | FR | Verifica |
|---|---|---|
| FR-001 | FR-001 | `python-semantic-release==10.6.2` em dev + hash `uv.lock` |
| FR-002 | FR-002 | `commit_parser = "conventional"` + `tag_format = "v{version}"` |
| FR-003 | FR-003 | `version_toml` com 3 caminhos (lockstep) |
| FR-004 | FR-004 | `allow_zero_version = true` + `major_on_zero = false` |
| FR-005 | FR-005 | `changelog_file` configurado (default com conventional) |
| FR-006 | FR-006 | `release.yml` com gatilho `on: push: tags:` |
| FR-007 | FR-007 | jobs `build` e `publish` separados; `id-token: write` só no publish |
| FR-008 | FR-008 | `uv build --all-packages`; `dist/` no `.gitignore` |
| FR-009 | FR-009 | `pypa/gh-action-pypi-publish` com SHA pinado; zero credencial |
| FR-010 | FR-010 | `uv export --format cyclonedx1.5`; `cyclonedx-bom` ausente |
| FR-011 | FR-011 | `pylock.toml` e SBOM **não** versionados (efêmeros) |
| FR-012 | FR-012 | fluxo não grava em `main` sem PR; tag é gatilho |
| FR-013 | FR-013 | `setup-uv` com `version:` pinado |
| FR-014 | FR-014 | `checklists/server-side.md` presente |
| FR-015 | FR-015 | contrato: `--list` 16 IDs, `--invalido` exit 2, 2× <5s, self-check série |
| FR-016 | FR-016 | `specs/README.md` `013 ✅` + hash; `tasks.md` zero `[ ]`; vermelho→verde |

### Entregue por este item

- Oráculo `f0-013-release.sh` (16 asserções identidade) + 13ª linha do manifest.
- Checklist `checklists/server-side.md` (metade servidora 🧑).

### Recebido de itens anteriores

- Contrato `oracle-cli.md` (001); molde de oráculo de `f0-012` (012); `uv.lock` como fonte (004); `--no-dev` (005); mensagens validadas (010); proteção sem-bypass (010).

### Transferido a itens posteriores

- Pipeline de release verde como validador (014).
- Trava exportada como base de comparação (014).
- Estrutura final incluindo fluxo de release (016).
