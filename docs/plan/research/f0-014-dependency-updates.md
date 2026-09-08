# RESEARCH — F0/014 · Atualização automática de dependências (Dependabot, agrupamento, portão verde)

> **Item do plano:** 0.16 (§17 Fase 0, Emenda 1) · **Ordem de execução:** 014/016 (ADR-011)
> **Data da verificação:** 2026-09-08 · **Papel:** Pesquisador
> **Método:** disco do repositório (P0) + registries/APIs (P0, fetch 2026-09-08) +
> docs oficiais (P1, fetch 2026-09-08). Nenhum dado por memória.
> **Hierarquia de fontes (ADR-025):** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = padrões estáveis · P3 = comunidade (só
> com corroboração P0/P1). Versão ou comportamento externo exige ≥2 fontes
> independentes incluindo P0.
> **Insumo anterior:** `specs/013-release-automation/contracts/oracle-cli.md` ›
> Transferido (pipeline de release como validador; condição de saída do override
> `click`; lugar do `pip-audit` no `lefthook.yml`; trava exportada como base) +
> `specs/010-ci-completo/spec.md` (10 checks, commitlint, proteção sem-bypass) +
> `specs/008-pip-audit-trivy/spec.md` (auditoria sem arquivo de configuração) +
> ADR-009, ADR-011, ADR-015, ADR-017, ADR-025, ADR-027 §5, ADR-030, ADR-031,
> ADR-032, ADR-034, ADR-035 + `docs/plan/research/f0-013-click-cve.md` (Q1–Q9, E1–E7).
> **Base:** harness 13/13 + manifest 13/13 declarados (`AGENTS.md:9`); `click` 8.4.2
> sob override; `.github/` contém só `scripts/` + `workflows/` (sem bot configurado).

---

## Q1 — Renovate ou Dependabot? (a pergunta que decide o item)

**Fontes (P1):** `docs.astral.sh/uv/guides/integration/renovate/` (fetch 2026-09-08:
manager `pep621`, atualiza `pyproject.toml` + `uv.lock`, workspaces, `lockFileMaintenance`,
`minimumReleaseAge` como par de `exclude-newer`) · `docs.astral.sh/uv/guides/integration/dependabot/`
+ `github.blog/changelog/2025-03-13` (ecossistema `uv` GA em 2026-03-13) ·
`docs.renovatebot.com` (`noise-reduction.md`: `packageRules` + `groupName`;
`key-concepts/automerge.md`; `semantic-commits/`: auto-detecção nos últimos 20 commits,
prefixo `chore`) · `docs.github.com` (`dependabot-options-reference`: `groups`,
`versioning-strategy` com `uv` suportado; `automate-dependabot-with-actions`:
automerge via `fetch-metadata` + `gh pr merge --auto`; `customizing-dependabot-prs`:
`commit-message.prefix` + `prefix-development` com `uv` suportado).

| Critério | Renovate | Dependabot |
|---|---|---|
| `uv.lock` | ✅ nativo (`pep621`, manifesto + lock, workspaces) | ✅ GA (`package-ecosystem: "uv"`) |
| Agrupamento | `packageRules` + `groupName` (arbitrário) | `groups:` por ecossistema (`patterns`, `update-types`, `dependency-type`, `applies-to`) |
| Automerge com portão | `automerge:true` por regra | sem automerge próprio — workflow + `gh pr merge --auto`, que respeita required checks e `strict:true` |
| Transitivos | `lockFileMaintenance` | parcial (issues abertas, ex. `dependabot-core#13912`) |
| Onde executa | serviço terceiro (App) ou self-hosted | **nativo no servidor** — zero credencial nova |
| Conventional Commits | auto-detecta; emite `chore(deps):…` (`chore` está no conjunto fechado de 11 tipos) | configurável via `commit-message.prefix`; ressalva P3 `dependabot-core#9304` (capitalização `Bump…`) |

**Achado:** os dois atendem "agrupamento + harness verde obrigatório". O fiel da
balança é arquitetural: o Dependabot executa no servidor sem terceira parte com
escrita (Lei Zero: nenhuma credencial nova), e compõe com a ADR-035 (`strict:true` +
auto-merge servidor — o merge do bot vira consequência do exit code, Regra 4). O
Renovate traria semântica própria de automerge — duas fontes de "quem mergeou".
**Recomendação: Dependabot.** O que se perde (`lockFileMaintenance`, OSV de
transitivos) fica como dívida vigiada: reabre-se **se** um CVE transitivo provar
que o nativo não alcança, nunca por releitura (molde ADR-020 §3).

---

## Q2 — O que o `uv` do repo exige do bot?

**Fonte (P0, repo):** workspace virtual (`[tool.uv] package = false`), membros
`packages/*`; runtime só `typer==0.27.2` + `rich==15.0.0` (em `packages/cli`);
todo o resto em `[dependency-groups]` com pins `==`; `uv.lock` versionado como
fonte única; CI com `uv sync --frozen --all-packages` (padrão ADR-023).
**Fonte (P1 + P3 corroborado):** com `uv.lock` presente o ecossistema `uv` atualiza
manifesto + lock juntos; pin `==` faz o manifesto acompanhar cada bump
(`dependabot-core#12609`: faixa que já contém a nova versão move só o lock).

**Achado:** nossos pins `==` fazem cada PR do bot atualizar manifesto + lock —
bom para rastreabilidade (X): cada bump é um par testável pelo harness.

---

## Q3 — Agrupamento mínimo honesto

**Fonte (P1, GitHub):** `groups:` por ecossistema, com `patterns`, `update-types`
(`minor`, `patch`, `major`), `dependency-type`, `applies-to`
(`version-updates`/`security-updates`).

Desenho que cabe no repo (detalhe é do PLAN): grupo `dev-minor-patch` (tudo de
`[dependency-groups]`) + `major` fora de grupo (unitário, revisão humana, nunca
automerge) + `github-actions` em ecossistema separado e PR próprio (bump de action
muda pin SHA asserido por `f0-003`/`f0-010`). Major agrupado é vedado: um major
escondido em grupo é bypass de revisão por agregação.

---

## Q4 — Automerge sem violar o portão + commits que não queimam versão

**Fonte (P1, GitHub):** workflow em `pull_request` com `if: actor == dependabot[bot]`,
`fetch-metadata` pinado por SHA, `gh pr merge --auto --merge` — o merge só ocorre
com os 10 required checks verdes sobre `strict:true` (ADR-035).

**Restrição que viaja com o achado (molde ADR-033 §4):** commits de bot entram no
histórico da linha única, e o PSR (013) deriva versão de Conventional Commits.
Logo o `commit-message.prefix` do bot **MUST ser tipo não-liberável** —
`build(deps)` (sem efeito em versionamento, `CONTRIBUTING.md:36-51`) — senão cada
bump queima um número de versão. Escopo `deps` minúsculo, válido pela gramática
do harness. **Ressalva registrada:** P3 `#9304` (capitalização quebra convenção);
a prova é o primeiro PR real do bot contra o job `commitlint` — o portão julga,
não esta pesquisa.

---

## Q5 — Supressão de vulnerabilidade continua impossível

**Fonte (P0, executada):** `pip-audit --help` (2.10.1) — só `--ignore-vuln` em CLI,
sem opção de arquivo. **Fonte (P1):** `pypa/pip-audit#694` (aberta desde 2023,
atualizada 2026-03) — sem arquivo de configuração. **Fonte (P0, repo):** `f0-008`
FR-002 reprova `pip-audit.toml`, `.pip-audit.toml` e `[tool.pip-audit]`
(`f0-008-pip-audit.sh:151-157`).

**Achado:** os dois cadeados da ADR-034 seguem fechados (Regra 5 + ausência de
config). A política da 014 é **agrupar + exigir verde**, nunca suprimir. PR de bot
contra lock vulnerável reprova no `audit` como qualquer PR — comportamento correto.

---

## Q6 — Condição de saída do override `click`: dispara ou não?

**Fonte (P0, PyPI):** `pypi.org/pypi/python-semantic-release/json` (fetch 2026-09-08)
→ `info.version` **10.6.2**, `requires_dist` ainda `click<8.5.0,~=8.1.0`.
**Fonte (P0, GitHub API):** `releases/latest` → `tag_name v10.6.2`,
`published_at 2026-08-28`. **Fonte (P0, disco):** `uv.lock:174-175` resolve
`click` 8.4.2 sob override (`uv.lock:11`).

**Achado: condição NÃO disparada — override e FR-017 permanecem.** A 014
re-verifica no seu verde (o upstream pode andar entre este research e o merge);
se disparar, a remoção entra nesta spec pelo molde ADR-017, nunca como fix avulso.

---

## Q7 — Lugar do `pip-audit` no `lefthook.yml` (dívida herdada, ADR-034 §6)

**Fonte (P0, repo):** `lefthook.yml:20-21` roda `uv run pip-audit` no `pre-commit`;
`f0-009` FR-003 **exige** `uv run pip-audit` presente **e** após `uv run pytest`
(ordem fail-fast, `f0-009-lefthook.sh:182-191`); FR-004 já consagra a distinção
(`trivy` só em `pre-push`).

**Achado:** o paradoxo da ADR-034 §6 é teorema, não empate: gate de vulnerabilidade
em `pre-commit` + Regra 2 (vermelho antes do verde) = correção futura impossível
sem `--no-verify`. Mover para `pre-push` harmoniza a base com a forma convergida
(mesma classe do `trivy`: lento/externo/não-hermético) e preserva fail-fast local
(hermético e rápido no `pre-commit`; externo e completo no `pre-push`). Mover
quebra FR-003 por desenho → **conflito previsto, procedimento ADR-017 fixo**
(PLAN declara → ADR autoriza forma exata → verde da 014 aplica → manifest cita).

---

## Q8 — Pergunta-padrão de ambiente (adendo ADR-027 §5)

| Suposição do item | Prova / estado |
|---|---|
| Bot executa no servidor sem segredo novo | Dependabot: P1 (nativo). Renovate self-hosted exigiria App com escrita — contra a hipótese, a favor do Dependabot |
| Bump não quebra `uv sync --frozen` | P0 parcial (CI já usa `--frozen --all-packages`); prova completa só no primeiro PR real do bot — limite honesto, roteado ao TESTS |
| OIDC/release intocados | bot não publica; `release.yml` dispara só em tag (P0, FR-006/012 da 013) |
| `exclude-newer` ↔ `cooldown` | P1 recomenda paridade nos dois bots; repo não usa `exclude-newer` (P0: ausente do `pyproject.toml`) — registrar, não configurar |

---

## Q9 — Fronteira: varredura mecânica sobre os 13 oráculos (2026-09-08)

Comandos: `grep -rn "dependabot|renovate" scripts/verify/` → **zero ocorrências**;
`grep -rn "lefthook" scripts/verify/f0-009-lefthook.sh` (FR-009: `grep -rq lefthook
$ROOT/.github/`); leitura de `f0-008:151-157` (FR-002) e `f0-009:182-191` (FR-003).

| Artefato da 014 | Asserção que incide | Veredito |
|---|---|---|
| `.github/dependabot.yml` | nenhuma | livre |
| workflow de automerge | `f0-009` FR-009 (literal `lefthook` sob `.github/`) | livre **se** sem o literal (cabeçalho sem nomear fronteiras, lição ADR-031) |
| `pip-audit` em `pre-push` (se CLARIFY escolher mover) | `f0-009` FR-003 (ordem fail-fast) | **conflito previsto (1 ponto)** → ADR-017, 7ª execução |
| qualquer `[tool.pip-audit]` / `pip-audit.toml` | `f0-008` FR-002 | **proibido** (invariante, sem ADR que autorize) |
| bumps em `dev` (`==` exatos) | asserções de inclusão (`"x==y" in dev`) | livres; cada bump é par testável |
| bump de `actions/*@sha` | `f0-003`/`f0-010` (SHA 40hex + `# vX.Y.Z`) | livre se preservar a forma |

Sob Dependabot + `pip-audit` onde está, a 014 pode ser o segundo item desde a 009
**sem** procedimento de fronteira — o que só se afirma porque a varredura foi
mecânica, não por intenção de evitá-lo (precedente Q10 da 013).

---

## Decisões (insumo ao SPECIFY/CLARIFY — nada aqui é norma)

- **D1.** Dependabot, ecossistemas `uv` + `github-actions` separado (Q1, Q3).
- **D2.** Grupos: `dev-minor-patch` agrupado; `major` unitário e sem automerge; actions em PR próprio (Q3).
- **D3.** Automerge só via `gh pr merge --auto --merge` sobre checks verdes; sem schedule próprio concorrendo com `strict:true` (Q4).
- **D4.** `commit-message.prefix` não-liberável (`build(deps)`); ressalva #9304 a provar no TESTS (Q4).
- **D5.** Zero supressão; FR-002 da 008 é invariante (Q5).
- **D6.** Override `click` permanece; re-verificado no verde da 014 (Q6).
- **D7.** Destino do `pip-audit` no hook vai ao CLARIFY com procedimento ADR-017 fixo (Q7).

## Declaração de impacto de fronteira (insumo ao PLAN — ADR-017)

Sob D1–D6 com `pip-audit` onde está, a 014 **não** toca oráculo anterior. Se o
CLARIFY escolher mover (D7), o PLAN declara 1 ponto (`f0-009` FR-003) e a ADR
prévia autoriza a forma exata (7ª execução do molde ADR-017), com legitimidade
pelo `uv.lock` no padrão ADR-018 — nunca por nome estático. Tripwire das actions:
forma SHA+comentário preservada, julgada pelos 10 checks no primeiro PR real;
fallback pré-registrado (`ignore` em actions, pin manual) sem nova deliberação.

## Out of Scope (Escada)

`docker-compose` (**015**) · `docs/tree.md` (**016**) · `lockFileMaintenance`
estilo Renovate (sem equivalente nativo; reavaliar se o Dependabot frustrar) ·
OSV alerts para transitivos · merge queue (ADR-035 §5: desproporcional até a
Fase 1) · versões independentes por pacote (rejeitada na ADR-033) · pending
publishers PyPI (metade servidora da 013, procedimento em
`checklists/server-side.md`, não bloqueia esta spec).

## Registro de execução

`git status` limpo antes e depois, exceto este arquivo; nenhum artefato criado no
repo além dele; nenhuma réplica necessária — todas as execuções foram consultas
(PyPI JSON, GitHub API, Astral docs, Renovate/Dependabot docs, grep no disco).
Harness 13/13 + manifest 13/13 re-verificados após a escrita (ver próxima etapa).
