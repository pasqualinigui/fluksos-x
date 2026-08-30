# RESEARCH — F0/003 · CI mínimo

> **Item do plano:** 0.13 (§17 Fase 0, Emenda 1 ADR-009) · **Ordem de execução:** 003/016 (ADR-011)
> **Data da verificação:** 2026-08-30 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/002-constitution-ratification/spec.md` › Contratos (vinculante) + ADR-009/011

Este item entrega o **pipeline que o motor ensina a construir mas não praticava** (ADR-009): workflow que executa o harness da Fase 0 em runner limpo. Escopo restrito por desenho — sem Ruff/MyPy/Pytest/pip-audit/branch protection (estes são spec `010`).

---

## Q1 — Onde vive e como se escreve um workflow?

**Fonte:** `https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions` — HTTP 200, 171 998 bytes, fetch direto em 2026-08-30.

| Exigência | Evidência na fonte |
|---|---|
| Arquivo YAML em `.github/workflows/` com extensão `.yml` ou `.yaml` | *"You must store workflow files in the `.github/workflows` directory"* |
| Chaves top-level mínimas: `name`, `on`, `jobs.<job_id>.runs-on`, `jobs.<job_id>.steps` | documento lista cada chave com semântica |
| `on` define eventos que disparam (push, pull_request, schedule, workflow_dispatch etc.) | seção `on` com exemplos single/multiple, tipos e filtros |
| `permissions` modifica `GITHUB_TOKEN`, top-level ou por job | seção `permissions` com tabela de permissões |

**Achado estrutural:** não existe arquivo `.github/` no repositório hoje (verificado `ls .github → inexistente`). O workflow precisa criá-lo. Sintaxe só aceita YAML, não shell direto.

**Decisão (D1):** workflow em `.github/workflows/ci.yml`, YAML válido, com `name`, `on`, `permissions`, `jobs`.

---

## Q2 — Qual runner garante determinismo hoje e escala amanhã?

**Fonte:** `https://docs.github.com/api/article/body?pathname=/en/actions/reference/runners/github-hosted-runners` — via API markdown, fetch 2026-08-30.

Evidência:

```
> The `-latest` runner images are the latest stable images that GitHub provides,
> and might not be the most recent version of the operating system available
```

Tabela pública (excerto):

| VM | Workflow label |
|---|---|
| Linux 4CPU 16GB | `ubuntu-latest`, `ubuntu-24.04`, `ubuntu-22.04`, `ubuntu-26.04` (preview) |
| Linux ARM | `ubuntu-24.04-arm`, `ubuntu-22.04-arm` |

Private tem 2CPU para mesmas labels.

**Análise determinística (princípio I):** `ubuntu-latest` é **alias móvel**. Hoje aponta para `ubuntu-24.04` (confirmado: link do README aponta para `Ubuntu2404-Readme.md`), mas migrará para `26.04` quando sair de preview. Um CI que usa `-latest` muda de SO sem mudança no repositório — viola determinismo. Um CI pinado em `ubuntu-24.04` muda só quando o repositório muda, e a mudança fica no diff.

**Trade-off:** pinagem atrasa adoção automática de SO novo; `-latest` dá novidade sem esforço. Para Fase 0, onde harness mede egressões byte a byte, determinismo prevalece sobre conveniência. A atualização de runner torna-se **item versionado** (DH renovate/dependabot futuro, spec 014).

**Decisão (D2):** `runs-on: ubuntu-24.04` pinado. Não `ubuntu-latest`. Reavaliado quando `26.04` sair de preview e o harness validar.

**Alternativa rejeitada:** `ubuntu-latest` — indeterminístico por construção. `ubuntu-slim` (1 CPU, 14 GB) — container unprivileged, sem Docker-in-Docker, timeout 15 min; incompatível com expansão para Trivy/docker-compose futuro (spec 015).

---

## Q3 — Qual versão de `actions/checkout` é atual e o que muda?

**Fonte:** `https://raw.githubusercontent.com/actions/checkout/main/README.md` + `.../main/package.json` + `.../main/action.yml` — HTTP 200, fetch 2026-08-30.

Evidência:

```
# Checkout v7
version: 7.0.1   (package.json)
# Checkout v6 / v5 / v4 — seções históricas abaixo
...
- uses: actions/checkout@v7
```

```
package.json: "version": "7.0.1", "type": "module"
action.yml: inputs fetch-depth default 1, 0 = all history
```

README v7 changelog:

* v7: ESM migration + security fixes, `allow-unsafe-pr-checkout` para `pull_request_target`
* v6: `persist-credentials` em arquivo separado sob `$RUNNER_TEMP`, requer runner >= v2.329.0 para Docker container action
* v5: node24 runtime, requer runner >= v2.327.1

**Verificação de compatibilidade:** runner `ubuntu-24.04` hospedado por GitHub já roda `v2.329+` (rolling). Uso de `@v7` não quebra CI público.

**Decisão (D3):** `actions/checkout@v7` pinado em major. Major pin (`@v7`) é prática escalável: recebe patches sem quebrar determinismo de minor. SHA pin é mais determinístico mas sem renovação automática; entra em spec 014 (Renovate). Para CI mínimo, major pin é equilíbrio correto.

**Achado crítico para este item (ver Q5):** `fetch-depth` default `1` só traz um commit. Harness `f0-001-foundation.sh` executa `git log --all --pretty=format: --name-only --diff-filter=A | sort -u` para auditar histórico (FR-020b). Com depth 1, histórico aparenta limpo mesmo sujo — falso-negativo. Pesquisa E7 do item 001 já demonstrou classe similar com `check-ignore`.

**Decisão associada:** `fetch-depth: 0` obrigatório neste workflow.

---

## Q4 — Qual versão de `actions/setup-python` e qual Python?

**Fonte:** `https://raw.githubusercontent.com/actions/setup-python/main/README.md` + `.../main/package.json` + `.../main/action.yml` — fetch 2026-08-30.

Evidência:

```
# setup-python  version 7.0.0
- uses: actions/setup-python@v7  with python-version: '3.13'
...
## Breaking changes in V6 / V7: node24, runner >= v2.327.1
```

```
package.json: "version": "7.0.0", "engines": {"node": ">=24.0.0"}
action.yml: inputs python-version, check-latest false, using node24
```

Manifest de versões: `https://raw.githubusercontent.com/actions/python-versions/main/versions-manifest.json`

```
families: 3.12, 3.13, 3.14 ...
3.12 samples: 3.12.14, 3.12.13, 3.12.12 ...
```

Máquina local: `Python 3.12.3` (medido). Plano pinado `>=3.12,<3.14`.

**Decisão (D4):**
* Action: `actions/setup-python@v7` (major pin, mesmo rationale Q3)
* Python: `python-version: '3.12'` — resolve para `3.12.14` (latest patch da família). Não pinar patch `3.12.3` porque CI deve validar família suportada, não snapshot. `3.12` é determinístico no sentido semântico (família), e escalável quando spec 010 introduzir matriz `[3.12, 3.13]`.

**Alternativa rejeitada:** omitir `python-version` (usa PATH do runner, varia entre imagens) — indeterminístico, rejeitado por VIII.

---

## Q5 — Por que `fetch-depth: 0` e não cache?

**Fonte:** `action.yml` de checkout (linha `fetch-depth` default 1) + leitura dos oráculos locais.

```
# f0-001-foundation.sh:360
HIST_ALL="$(git -C "$ROOT" log --all --pretty=format: --name-only --diff-filter=A ...)"
```

Sem histórico completo, `HIST_ALL` contém só o commit do trigger. Arquivo proibido adicionado 10 commits atrás não aparece — FR-020b aprova indevidamente. É exatamente a classe de falso-negativo do princípio VI.

Evidência adicional: README checkout v4: *"Only a single commit is fetched by default"*.

**Cache:** `setup-python` suporta `cache: pip` mas CI mínimo **não tem dependências** (harness usa stdlib). Cache adicionado agora esconderia indeterminismo futuro (quando `uv.lock` existir, cache com hash errado aprova). Princípio da escada de dependências (constitution Additional Constraints) proíbe exigir ferramenta que ainda não existe.

**Decisão (D5):**
* `fetch-depth: 0` obrigatório
* `cache` omitido no item 003; entra em 010 quando `uv` existir
* `persist-credentials: false` não necessário para leitura, mas deixar default `true` não quebra determinismo; manter default para não acoplar a decisão prematura

---

## Q6 — `GITHUB_TOKEN` mínimo necessário

**Fonte:** `https://docs.github.com/api/article/body?pathname=/en/actions/security-guides/automatic-token-authentication` — secção *Modifying the permissions* (fetch 2026-08-30).

> *"Use the `permissions` key ... to configure the minimum required permissions ... As a good security practice, you should grant the `GITHUB_TOKEN` the least required access."*

Exemplos na fonte usam `permissions: contents: read` para job que lê repositório.

Workflow syntax (mesma fonte Q1) lista granularidades: `contents`, `actions`, `checks`, `pull-requests` etc. Se qualquer `permissions` é especificado, não especificados viram `none`.

**Análise deste item:** CI mínimo só faz `checkout` + `python harness`. Nenhuma escrita, nenhum release, nenhum comentário. `contents: read` é suficiente. `write` seria privilégio elevado (Lei Zero por analogia).

**Decisão (D6):** top-level `permissions: contents: read`. É o menor que permite checkout. Escalável: spec 010 (CI completo) acrescentará `checks: write` ou `pull-requests: read` se necessário, e spec 013 (release) precisará `contents: write` + `id-token: write` para trusted publishing — cada ampliação fica em diff próprio.

**Alternativa rejeitada:** omitir `permissions` (default `write` em repositórios antigos ou `read` dependendo de setting org) — indeterminístico entre orgs, rejeitado.

---

## Q7 — Em que eventos o workflow deve disparar?

**Fonte:** `https://docs.github.com/api/article/body?pathname=/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows` — tabela de eventos.

Eventos relevantes:

* `push` — dispara em push a branch/tag; com filtro `branches: [main, develop]`
* `pull_request` — dispara em `opened/synchronize/reopened` por default; com `branches: [main, develop]` filtra pelo **base**

Requisito do plano: CI mínimo valida harness da Fase 0 após cada integração. Branches principais são `main` e `develop` (FR-001/002). Feature branches são `feature/f*-*` (FR-006b); validar só quando apontam para as principais evita custo em branch efêmero.

**Decisão (D7):**

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
```

É o padrão escalável: item 010 acrescentará `merge_group` para merge queue, item 013 acrescentará `tags: ['v*.*.*']` para release — sem reescrever triggers existentes.

**Alternativa rejeitada:** `on: [push]` sem filtro — executa em toda feature branch, custo sem valor e ruído. `on: pull_request` sem `push` — deixa bypass via push direto sem PR.

---

## Q8 — Arquitetura escalável: como 0.13 vira 0.14 sem reescrever?

**Contexto:** ADR-009/011. 0.13 depende só de shell/git/Python. 0.14 exige Ruff, MyPy, Pytest, pip-audit, gitleaks, matriz Python, `uv sync --frozen`, required checks. Se 0.13 for monolito shell, 0.14 precisa reescrever.

**Princípios aplicáveis:** I (determinismo), VI (harness é oráculo), Additional Constraints (escada de dependências).

**Decisão (D7 já + D8):**

* Workflow único `.github/workflows/ci.yml` com job `verify` (nome estável `verify` — é o que branch protection referenciará em 010 como required check). Nome não muda entre 0.13 e 0.14; novos jobs são acrescentados, não renomeados.
* Job `verify` com steps nomeados: `Checkout`, `Setup Python 3.12`, `Run harness`. Nomes estáveis viram `checks` no GitHub.
* Sem `matrix` em 0.13 (só 3.12). Matrix `[3.12, 3.13]` entra em 010 como extensão, sem renomear job (usa `matrix.python-version` e inclui no nome do step).
* Artefatos e caching só em 010; estrutura de diretórios `.github/workflows/` já existe, então 010 adiciona `ci.yml` steps ou novos workflows `release.yml`, `dependency.yml` sem tocar，供.

**Evidência de que funciona:** `jobs.<job_id>.outputs` e `workflow_call` são suportados (workflow syntax Q1), mas para CI mínimo não são necessários; manter simples é escalável porque simples é componível.

**Decisão (D8):** um workflow, um job determinístico, nomes estáveis.

---

## Q9 — Python 3.12 no runner: o que existe e o que o oráculo exige?

**Fonte:** manifest python-versions + `python --version` local + constitution Additional Constraints (escada).

* Manifest confirma `3.12.14` disponível no tool cache de `setup-python`.
* Local é `3.12.3` — família compatível.
* Oráculo `f0-001` exige `FR-019` (só shell/git/Python stdlib) e `f0-002` exige que harness não contenha não-determinismo. O harness roda com `python3` do PATH — em CI, `setup-python` coloca `3.12` no PATH, então `python3 -c` do oráculo usa a versão correta.

**Decisão (D9):** `python-version: '3.12'` sem `cache`, sem `architecture` override (default `x64` do runner `ubuntu-24.04`). Harness invocado como `bash scripts/verify/f0-*.sh` ou `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` — não precisa de `python` explícito, mas `setup-python` garante que qualquer `python3` interno seja 3.12.

---

## Q10 — Como o workflow reprova e como escala o portão?

**Fonte:** leitura de `scripts/verify/f0-001-foundation.sh` (494 linhas) + `specs/001-.../contracts/oracle-cli.md` + `scripts/verify/README.md`.

Contrato:

* exit `0` conforme, `1` não conforme, `2` erro de uso
* `--quiet` só violações
* uma linha por asserção identificada por REQ-ID

Harness completo hoje: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done`

**Decisão (D10):** step

```yaml
- name: Run harness
  run: |
    for f in scripts/verify/f0-*.sh; do
      "$f" || exit 1
    done
```

Sem `continue-on-error`. Falha propaga como `1` e GitHub marca check como failed — é o que branch protection consumirá em 010. `--quiet` opcional: em CI, log completo é útil, mas `--quiet` reduz ruído; manter sem `--quiet` para observabilidade (princípio X). Decisão final: sem `--quiet` em CI para rastreabilidade, a menos que log exceda limite.

**Escala:** quando `005` (Pytest) promover oráculos a testes, harness shell continua executando; `ci.yml` acrescentará step `pytest` em paralelo sem remover o shell — dupla verificação durante transição.

---

## Resumo das decisões vinculantes

| # | Decisão | Fonte |
|---|---|---|
| D1 | Workflow em `.github/workflows/ci.yml` YAML com `name/on/permissions/jobs` | Q1 workflow-syntax |
| D2 | `runs-on: ubuntu-24.04` pinado, não `ubuntu-latest` | Q2 runners, princípio I |
| D3 | `actions/checkout@v7` (7.0.1) major pin, com `fetch-depth: 0` | Q3 README + package.json, Q5 |
| D4 | `actions/setup-python@v7` (7.0.0) + `python-version: '3.12'` | Q4 README + manifest |
| D5 | `fetch-depth: 0` obrigatório; sem cache em 0.13 | Q5 action.yml + FR-020b |
| D6 | `permissions: contents: read` least privilege | Q6 token docs |
| D7 | `on: push/pull_request branches [main, develop]` | Q7 events |
| D8 | Job único `verify` com nomes estáveis, sem matrix ainda | Q8 arquitetura |
| D9 | Python 3.12 família, runner x64 default | Q9 manifest + local |
| D10 | `for f in scripts/verify/f0-*.sh; do "$f" \|\| exit 1; done` | Q10 oracle-cli |

**Nenhum `NEEDS CLARIFICATION` remanescente.** Próxima etapa: `SPECIFY` da spec `003 — CI mínimo`.

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **010 (0.14 CI completo)** | Workflow `ci.yml` com job `verify` estável para virar required check; `permissions` base para ampliar; triggers base para acrescentar `merge_group` |
| **013 (0.15 release)** | Runner e action versions pinadas como referência para trusted publishing workflow separado |
| **014 (0.16 renovate)** | Mapa de dependências pinadas (`checkout@v7`, `setup-python@v7`, `ubuntu-24.04`) para automerge |

## Pacotes e versões pinadas verificadas em 2026-08-30

| Pacote | Versão verificada | Fonte | Nota |
|---|---|---|---|
| `actions/checkout` | `v7` (`7.0.1`) | raw `package.json` main | node24, runner >=2.327.1 |
| `actions/setup-python` | `v7` (`7.0.0`) | raw `package.json` main | node24 |
| `ubuntu` runner | `24.04` | runner reference API | `ubuntu-latest` = `24.04` hoje |
| `Python` | `3.12.14` (família `3.12`) | python-versions manifest + local `3.12.3` | plano `>=3.12,<3.14` |
| `GitHub Actions workflow` | syntax 2026-08-30 | docs.github.com | `.github/workflows/*.yml` |
