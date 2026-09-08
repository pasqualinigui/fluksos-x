# Contrato do oráculo: `f0-014-dependabot.sh` — mapa FR↔asserção (ADR-015b)

**Spec**: `specs/014-dependency-updates/spec.md` (11 FRs, 7 SCs, 4 US + CLARIFY 5/5) · **Oráculo**: `scripts/verify/f0-014-dependabot.sh`
**Contrato de interface**: `specs/001-git-branching-strategy/contracts/oracle-cli.md`

Identidade 1:1 — o oráculo emite os IDs **da spec**, sem remapeamento.

| Asserção | FR | Verifica |
|---|---|---|
| FR-001 | FR-001 | `.github/dependabot.yml` com ecossistema `uv`, diretório raiz, schedule semanal |
| FR-002 | FR-002 | grupos `dev-minor-patch` + `security` próprio; `major` fora de grupo com automerge |
| FR-003 | FR-003 | ecossistema `github-actions` separado; pins `uses:` SHA 40hex + comentário |
| FR-004 | FR-004 | `commit-message.prefix` não-liberável (`build(deps)`) |
| FR-005 | FR-005 | automerge só bot, só `--merge`, só no verde (gate de ator; sem squash/rebase) |
| FR-006 | FR-006 | zero supressão: sem `--ignore-vuln`, sem `pip-audit.toml`, sem `[tool.pip-audit]` |
| FR-007 | FR-007 | override `click>=8.3.3,<8.5.0` + lock `>= 8.3.3` (ou remoção pelo gatilho, via ADR) |
| FR-008 | FR-008 | `pip-audit` no `pre-push`, ausente do `pre-commit`; fail-fast intacto (ponto ADR-017) |
| FR-009 | FR-009 | contrato: `--list` 11 IDs, `--invalido` exit 2, 2× <5s, self-check série |
| FR-010 | FR-010 | `specs/README.md` `014 ✅` + hash; `tasks.md` zero `[ ]`; vermelho→verde |
| FR-011 | FR-011 | tripwire actions registrado em bloco de comentário grepeável no `.github/dependabot.yml` (fallback `ignore` + pin manual, sem nova deliberação) |

### Entregue por este item

- Oráculo `f0-014-dependabot.sh` (11 asserções identidade) + 14ª linha do manifest.
- Config do bot + automerge + `lefthook.yml` ajustado no ponto autorizado.

### Recebido de itens anteriores

- Contrato `oracle-cli.md` (001); molde de oráculo de `f0-013` (013); `uv.lock` como fonte (004); `--no-dev` (005); mensagens validadas + proteção `strict:true` + auto-merge servidor (010); `lefthook.yml` sob jurisdição da 009 (ajuste só via ADR-017); auditoria sem config (008, invariante); override `click` + FR-017 com condição de saída (013/ADR-034).

### Transferido a itens posteriores

- Config do bot como validadora contínua (015: deps de infra entram sem config nova).
- Estrutura final incluindo o bot (016).
- Primeira escrita recorrente por ator não-humano + ressalva #9304 (auditoria pós-016).
- Reavaliação de escopo bot-vs-agentes (Fase 2, doutrina ADR-035 §5).
