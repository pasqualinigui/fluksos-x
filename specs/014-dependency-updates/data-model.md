# Data Model: Atualização automática de dependências (014)

> Formatos declarados antes de gerados (princípio IV). Nomes exatos de chaves são desenho final do IMPLEMENT dentro destes formatos.

## DependabotConfig (`.github/dependabot.yml`)

| Campo | Forma | Regra |
|---|---|---|
| `version` | `2` (literal) | fixo do formato |
| `updates[]` | lista de 2 entradas: `uv` + `github-actions` | uma por ecossistema, nunca misturados |
| `updates[].directory` | `"/"` | raiz (manifesto + lock co-localizados) |
| `updates[].schedule.interval` | `weekly` (versões; security é event-driven, sem schedule próprio) | D2 + clarify Q2 + achado de implementação |
| `updates[].groups` | `dev-minor-patch` (patterns dev, `update-types: [minor, patch]`); `security` (`applies-to: security-updates`); `major` excluído de grupo com automerge | FR-002 |
| `updates[].commit-message.prefix` | `build(deps)` (não-liberável) | FR-004; ressalva #9304 no TESTS |
| `updates[].open-pull-requests-limit` | `5` (default do formato; teto de ruído) | nunca 0 para `uv` (mataria o item) |

## AutomergeWorkflow (`.github/workflows/dependabot-automerge.yml`, se criado)

| Campo | Forma | Regra |
|---|---|---|
| `on: pull_request` + gate `actor == dependabot[bot]` | filtro de ator | só PRs do bot |
| `uses: dependabot/fetch-metadata@<40hex>` | pin SHA + comentário | fronteira 003/010 |
| `run: gh pr merge --auto --merge` | merge simples | squash/rebase desligados no servidor (ADR-035); sem `--squash`/`--rebase` em nenhuma linha |
| proibido no arquivo | literal `lefthook`; `continue-on-error`; `pull_request_target` | FR-009 da 009; FR-010 da 010; FR-006 da 003 |

## LefthookDelta (`lefthook.yml`, ponto ADR-017)

| Estado | `pre-commit` | `pre-push` |
|---|---|---|
| Antes | ruff, format, mypy, pytest, **pip-audit** | harness, trivy |
| Depois | ruff, format, mypy, pytest (ordem intacta) | harness, trivy, **pip-audit** |

## TripwireRecord (bloco de comentário em `.github/dependabot.yml`, remediação F3)

| Campo | Forma | Regra |
|---|---|---|
| marcador | `# TRIPWIRE-014-actions:` + fallback (`ignore` em actions + pin manual) | locus único grepeável pelo oráculo (FR-011); sem nova deliberação se disparar |

## OracleAssertionSet (`f0-014-dependabot.sh`, 11 asserções identidade)

FR-001..011 da spec, 1:1, sem remapeamento (mapa em `contracts/oracle-cli.md`). Self-check `f0-001…f0-013` em série (ADR-031). Guarda FR-009 (contrato auto-verificável) e FR-010 (README + tasks + vermelho→verde) seguem o molde 005/010.

## ManifestLine (14ª linha)

`sha256sum` de `f0-014-dependabot.sh` em `scripts/verify/manifest.sha256`, acrescentada no commit vermelho junto do oráculo (precedente E5: separar faria `f0-009/010/011/012` reprovarem junto).
