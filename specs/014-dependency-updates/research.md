# Research consolidado: Atualização automática de dependências (014)

**Fonte vinculante**: `docs/plan/research/f0-014-dependency-updates.md` (Q1–Q9, fetch 2026-09-08)
**Decisões do mantenedor**: sessão clarify 2026-09-08 (Dependabot; `pip-audit` no `pre-push`; `github-actions` com tripwire; automerge minor+patch; via expressa `security`)

## D1 — Bot: Dependabot

- **Decision**: Dependabot, ecossistemas `uv` + `github-actions`, config em `.github/dependabot.yml`.
- **Rationale**: nativo no servidor (zero credencial nova, Lei Zero); compõe com ADR-035 (`strict:true` + auto-merge servidor: merge como consequência do exit code); `uv` GA desde 2026-03-13 com `groups`, `versioning-strategy` e `commit-message.prefix`.
- **Alternatives considered**: Renovate (mais expressivo: `lockFileMaintenance`, OSV de transitivos) — rejeitado por exigir terceiro com escrita; reabre-se só com CVE transitivo que prove o nativo insuficiente (evidência nova, nunca releitura).

## D2 — Agrupamento e automerge por nível

- **Decision**: grupo `dev-minor-patch` com automerge no verde; `major` em PR próprio sem automerge; grupo `security` próprio em cadência rápida sob o mesmo portão.
- **Rationale**: major agrupado é bypass de revisão por agregação; CVE parado já bloqueou a `main` (013) e não espera o grupo semanal; o portão verde decide cada merge (Regra 4).
- **Alternatives considered**: automerge só-patch (rejeitado: julgamento prévio onde o exit code decide); segurança no fluxo semanal (rejeitado: custo de espera); automerge de major (vedado).

## D3 — Prefixo de commit não-liberável

- **Decision**: `commit-message.prefix` = `build(deps)` (+ `prefix-development` onde couber).
- **Rationale**: commits de bot entram na linha única sobre a qual o PSR deriva versão; tipo liberável queimaria um número por bump. Ressalva `dependabot-core#9304` vai ao TESTS (job `commitlint` julga).
- **Alternatives considered**: `chore(deps)` (equivalente; `build` escolhido por nomear dependência como build/maintenance, e ambos são não-liberáveis).

## D4 — Zero supressão

- **Decision**: nenhuma forma de `--ignore-vuln` em arquivo; política = agrupar + exigir verde.
- **Rationale**: `pip-audit` 2.10.1 sem arquivo de configuração (issue #694 aberta) + `f0-008` FR-002 como invariante — os dois cadeados da ADR-034 seguem fechados.
- **Alternatives considered**: nenhuma (invariante, sem ADR que autorize discutir).

## D5 — Override `click` permanece

- **Decision**: `override-dependencies = ["click>=8.3.3,<8.5.0"]` + FR-007, re-verificados no verde da 014.
- **Rationale**: PSR segue 10.6.2 com `click~=8.1.0` (PyPI + GitHub API, 2026-09-08); condição de saída não disparada.
- **Alternatives considered**: remoção antecipada (rejeitada: reintroduz `PYSEC-2026-2132` e quebra 3 checks).

## D6 — `pip-audit` no `pre-push`

- **Decision**: mover `uv run pip-audit` de `pre-commit` para `pre-push` (com `trivy` + harness), preservando fail-fast do `pre-commit`.
- **Rationale**: teorema ADR-034 §6 (gate em `pre-commit` + Regra 2 = correção impossível); harmoniza com a forma convergida do `trivy` (FR-004 da 009).
- **Alternatives considered**: manter (rejeitado: repete o ciclo `--no-verify` a cada CVE). Quebra `f0-009` FR-003 por desenho → ADR-017, 7ª execução.

## D7 — Actions com tripwire

- **Decision**: ecossistema `github-actions` em grupo separado; forma SHA+comentário julgada pelos 10 checks no primeiro PR real; fallback pré-registrado (`ignore` + pin manual).
- **Rationale**: onde o harness pode julgar, a spec configura o julgamento em vez de proferi-lo.
- **Alternatives considered**: excluir actions (fallback, não default); misturar com Python (vedado: PR ilegível, pins distintos).
