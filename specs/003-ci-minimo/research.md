# Research — 003 CI mínimo

**Feature**: `003-ci-minimo` · **Item do plano**: 0.13 (Emenda 1 ADR-009) · **Ordem**: 003/016 (ADR-011)
**Data**: 2026-08-30 · **Método**: consulta direta a fontes canônicas e ao disco (VIII). Nenhum dado por memória.
**Pesquisa vinculante consolidada**: `docs/plan/research/f0-003-ci-minimo.md` (288 linhas, Q1–Q10, D1–D10)
**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> Este arquivo consolida em formato `Decision / Rationale / Alternatives` as 10 decisões já verificadas em `docs/plan/research/f0-003-ci-minimo.md`. Não introduz decisões novas; a fonte primária continua sendo o arquivo em `docs/plan/research/`.

---

## D1 — Onde vive e como se escreve um workflow

**Decision**: Workflow em `.github/workflows/ci.yml`, YAML válido com chaves top-level `name`, `on`, `permissions`, `jobs`.

**Rationale**: Fonte `docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions` (HTTP 200, 171 998 bytes, 2026-08-30): *"You must store workflow files in the `.github/workflows` directory"* com extensão `.yml`/`.yaml`; lista chaves `on`, `permissions` (modifica `GITHUB_TOKEN`), `jobs.<id>.runs-on/steps`. Verificação em disco: `.github/` inexistente (Q1), logo precisa ser criado.

**Alternatives considered**: Nenhuma — GitHub só lê desse diretório; sintaxe só YAML, não shell direto. Rejeitado escrever fora do diretório ou em shell puro.

---

## D2 — Runner pinado para determinismo

**Decision**: `runs-on: ubuntu-24.04` pinado; MUST NOT `ubuntu-latest`.

**Rationale**: Fonte `github-hosted-runners` API markdown (2026-08-30): tabela `ubuntu-latest | ubuntu-24.04 | ubuntu-22.04 | ubuntu-26.04 (preview)` + nota *"The `-latest` runner images are the latest stable images ... might not be the most recent version"*. `ubuntu-latest` hoje = `24.04` (link para `Ubuntu2404-Readme.md`), mas migrará para `26.04` ao sair de preview — alias móvel. Princípio I exige determinismo: CI que muda de SO sem mudança no repo não é oráculo. Pin muda só por diff versionado (spec 014).

**Alternatives considered**: `ubuntu-latest` — indeterminístico por construção, rejeitado. `ubuntu-slim` (1 CPU, 14GB, unprivileged, sem Docker-in-Docker, timeout 15min) — incompatível com expansão futura Trivy/docker-compose (spec 015), rejeitado.

---

## D3 — actions/checkout@v7 determinístico

**Decision**: `uses: actions/checkout@v7` (major pin `v7` = `7.0.1` em 2026-08-30, node24, runner ≥2.327.1) com `fetch-depth: 0`.

**Rationale**: Fontes `raw.githubusercontent.com/actions/checkout/main/README.md` + `package.json` (`"version": "7.0.1", "type": "module"`) + `action.yml` (`fetch-depth default 1, 0 = all history`) — HTTP 200, 2026-08-30. Changelog v7: ESM + security, v5: node24 requer runner ≥2.327.1. Runner `ubuntu-24.04` hospedado já roda ≥2.329 (rolling), compatível. Major pin `v7` recebe patches sem quebrar determinismo minor; SHA pin sem renovação automática fica para spec 014 (Renovate). Ver Q5 para `fetch-depth: 0`.

**Alternatives considered**: `v6`/`v5`/`v4` — desatualizados, sem security fixes v7, rejeitados. SHA pin — mais determinístico mas exige renovação manual, deferido a 014.

---

## D4 — actions/setup-python@v7 + Python 3.12 família

**Decision**: `uses: actions/setup-python@v7` (`7.0.0`, node24) com `with: python-version: '3.12'`.

**Rationale**: Fontes `setup-python` README + `package.json` (`"version": "7.0.0", "engines": {"node": ">=24.0.0"}`) + `action.yml` (`python-version`, `check-latest false`, node24) + manifest `actions/python-versions/main/versions-manifest.json` (famílias `3.12`, `3.13`, samples `3.12.14`/`3.12.13`...), fetch 2026-08-30. Local `Python 3.12.3` medido; plano `>=3.12,<3.14`. Família `3.12` resolve para `3.12.14` no runner — determinismo semântico, escala para matriz `[3.12, 3.13]` em 010 sem pin de patch.

**Alternatives considered**: Omitir `python-version` (usa PATH do runner, varia entre imagens) — indeterminístico, rejeitado por VIII. Pinar `3.12.3` exato — snapshot frágil, não valida família suportada, rejeitado.

---

## D5 — fetch-depth: 0 obrigatório; sem cache

**Decision**: `fetch-depth: 0` obrigatório no checkout; `cache` omitido em 003.

**Rationale**: `action.yml` checkout `fetch-depth default 1` + `f0-001-foundation.sh:360` `HIST_ALL="$(git log --all ... --diff-filter=A)"`. Com depth 1, histórico aparenta limpo mesmo sujo — arquivo proibido 10 commits atrás não aparece, FR-020b aprova indevidamente (falso-negativo classe E7 item 001, princípio VI). README checkout v4: *"Only a single commit is fetched by default"*. Cache `setup-python` `cache: pip` irrelevante: CI mínimo não tem dependências (harness stdlib); cache com chave instável esconderia indeterminismo futuro quando `uv.lock` existir; escada de dependências proíbe exigir ferramenta inexistente.

**Alternatives considered**: `fetch-depth: 1` (default) — falso-negativo, rejeitado. `cache: pip` — sem chave estável, rejeitado até 010 com `uv`.

---

## D6 — GITHUB_TOKEN least privilege

**Decision**: Top-level `permissions: contents: read`.

**Rationale**: Fonte `automatic-token-authentication` (fetch 2026-08-30): *"Use the `permissions` key ... to configure the minimum required permissions ... grant the least required access"*; exemplos usam `contents: read` para job que lê repo. Syntax lista granularidades `contents`, `actions`, `checks` etc.; se qualquer `permissions` especificado, não especificados viram `none`. CI mínimo só faz `checkout` + `python harness` — nenhuma escrita, release ou comentário; `write` seria privilégio elevado (Lei Zero por analogia). Escalável: 010 acrescentará `checks: write` se preciso, 013 precisará `contents: write` + `id-token: write` para trusted publishing — cada ampliação em diff próprio.

**Alternatives considered**: Omitir `permissions` (default `write` em repos antigos ou `read` conforme org) — indeterminístico entre orgs, rejeitado.

---

## D7 — Gatilhos push + pull_request em [main, develop]

**Decision**:
```yaml
on:
  push: { branches: [main, develop] }
  pull_request: { branches: [main, develop] }
```

**Rationale**: Fonte `events-that-trigger-workflows` tabela (2026-08-30): `push` dispara em push a branch/tag com filtro `branches`; `pull_request` dispara `opened/synchronize/reopened` filtrando pelo **base**. Branches principais `main`/`develop` (FR-001/002); feature branches `feature/f*-*` (FR-006b) só validam quando apontam para principais — evita custo/ruído em branch efêmero. Padrão escalável: 010 acrescenta `merge_group`, 013 acrescenta `tags: ['v*.*.*']` sem reescrever triggers.

**Alternatives considered**: `on: [push]` sem filtro — executa em toda feature branch, custo sem valor, rejeitado. `on: pull_request` sem `push` — deixa bypass via push direto sem PR, rejeitado.

---

## D8 — Job único verify com nomes estáveis

**Decision**: Um workflow `ci.yml`, um job `verify` (id estável para virar `required check` em 010), steps nomeados `Checkout`, `Setup Python 3.12`, `Run harness`; sem `matrix` em 003.

**Rationale**: Contexto ADR-009/011: 0.13 depende só shell/git/Python; 0.14 exige Ruff/MyPy/Pytest/matriz/`uv`. Se 0.13 fosse monolito, 0.14 reescreveria. Princípios I/VI/escada: nome `verify` não muda entre 0.13→0.14; novos jobs acrescentados, não renomeados. Sem `matrix` (só 3.12); matriz `[3.12, 3.13]` entra em 010 como extensão. Artefatos/caching só em 010; `.github/workflows/` já existe, então 010 adiciona steps sem tocar base. `jobs.<id>.outputs`/`workflow_call` suportados (Q1) mas desnecessários para mínimo — simples é componível.

**Alternatives considered**: Múltiplos jobs ou nome instável — quebraria `required check` futuro, rejeitado. Incluir `matrix` agora — sem família `3.13` validada, rejeitado.

---

## D9 — Python 3.12 família no runner

**Decision**: `python-version: '3.12'` sem `cache`, sem `architecture` override (default `x64` de `ubuntu-24.04`); harness invocado como `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done`.

**Rationale**: Manifest confirma `3.12.14` no tool cache; local `3.12.3` família compatível. Oráculo `f0-001` exige só stdlib (FR-019), `f0-002` exige sem não-determinismo. `setup-python` coloca `3.12` no PATH, então `python3 -c` interno usa versão correta. Sem `architecture` override — default `x64` do runner é suficiente.

**Alternatives considered**: Pin `3.12.14` exato — escala mal para matriz futura, rejeitado. Omitir `setup-python` — PATH do runner varia, indeterminismo, rejeitado.

---

## D10 — Propagação de falha idêntica ao local

**Decision**: Step `Run harness`:
```yaml
- name: Run harness
  run: |
    for f in scripts/verify/f0-*.sh; do
      "$f" || exit 1
    done
```
Sem `continue-on-error`; sem `--quiet` em CI (observabilidade X).

**Rationale**: Contrato `oracle-cli.md` + `scripts/verify/README.md`: exit `0` conforme, `1` não conforme, `2` erro de uso; `--quiet` só violações, uma linha por REQ-ID. Harness completo hoje: `for f in ...; do "$f" --quiet || exit 1; done`. Em CI, log completo é útil (princípio X) — sem `--quiet` para rastreabilidade unless log exceda limite. Sem `continue-on-error`, falha propaga como `1` e GitHub marca check failed — o que branch protection consumirá em 010. Quando `005` promover a pytest, harness shell continua executando; `ci.yml` acrescentará `pytest` sem remover shell.

**Alternatives considered**: `continue-on-error: true` — mascara falha, check verde com violação, rejeitado. `--quiet` obrigatório — economiza log mas perde evidência, rejeitado. Lista hardcoded de oráculos — não cobre `f0-003` futuro, rejeitado; glob cobre por construção.

---

## Resumo vinculante

| # | Decisão | Fonte | FR |
|---|---|---|---|
| D1 | `.github/workflows/ci.yml` YAML `name/on/permissions/jobs` | Q1 | FR-001/002 |
| D2 | `runs-on: ubuntu-24.04` | Q2, I | FR-003 |
| D3 | `checkout@v7` + `fetch-depth: 0` | Q3+Q5 | FR-004 |
| D4 | `setup-python@v7` + `python 3.12` | Q4+Q9 | FR-005 |
| D5 | `fetch-depth: 0` + sem cache | Q5 | FR-006 |
| D6 | `permissions: contents: read` | Q6, V | FR-007 |
| D7 | `on: push/pull_request [main,develop]` | Q7 | FR-008 |
| D8 | job `verify` estável, sem matrix | Q8 | FR-009/013 |
| D9 | python família `3.12`, x64 | Q9 | FR-005 |
| D10 | `Run harness` glob + `|| exit 1` | Q10, X | FR-010/011 |

**NEEDS CLARIFICATION**: nenhum — todos os unknowns já resolvidos por verificação direta em 2026-08-30 (Q1–Q10). Próxima fase: `data-model.md` + `contracts/` + `quickstart.md`.
