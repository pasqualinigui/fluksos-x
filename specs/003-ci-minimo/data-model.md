# Data Model — 003 CI mínimo

**Feature**: `003-ci-minimo` · **Plan**: [plan.md](./plan.md) · **Spec**: [spec.md](./spec.md)
**Princípio IV**: formato de dados de entrada/saída declarado antes da implementação

> Este item não cria tabela nem API applicativa. As "entidades" são artefatos do próprio pipeline — arquivo YAML, job, step, harness e action pinada — mas cada uma tem atributos, validações e relações que o oráculo `f0-003` asserirá deterministicamente.

---

## Entidade: Workflow

Arquivo YAML que o GitHub Actions lê em `.github/workflows/ci.yml` (D1).

| Campo | Tipo | Restrição | Origem |
|---|---|---|---|
| `name` | string | MUST existir, não vazio | FR-001 |
| `on` | map | MUST conter `push` e `pull_request` | FR-008 |
| `on.push.branches` | list[string] | MUST = `[main, develop]` exatamente | FR-008 / D7 |
| `on.pull_request.branches` | list[string] | MUST = `[main, develop]` | FR-008 / D7 |
| `permissions` | map | MUST = `{contents: read}` top-level, MUST NOT conter `write`/`id-token: write` | FR-007 / D6 |
| `jobs` | map | MUST conter chave única `verify` | FR-009 |
| `path` | string | MUST = `.github/workflows/ci.yml` | FR-001/002 |

**Relações**: contém 1 `Job verify` (1:1). É lido da branch padrão; em PRs, o workflow da base é mesclado com o head.

**Validação**: `python3 -c 'import yaml; yaml.safe_load(open(path))'` deve parsear sem erro (SC-001); inspeção estática verifica chaves top-level.

**Estado**: não tem ciclo de vida além de existir/ser YAML válido; ausência ou YAML inválido → FR-001 violado (exit 1 do oráculo).

---

## Entidade: Job `verify`

Unidade de execução que valida o harness (D8). Nome estável desde 003 para virar `required check` em 010 sem rename (FR-013).

| Campo | Tipo | Restrição | Origem |
|---|---|---|---|
| `id` | string | MUST = `verify` | FR-009 |
| `runs-on` | string | MUST = `ubuntu-24.04` pinado; MUST NOT = `ubuntu-latest` | FR-003 / D2 |
| `steps` | list[Step] | MUST conter 3 steps nomeados `Checkout`, `Setup Python 3.12`, `Run harness` nesta ordem | FR-009 |
| `status` | enum | `success` (exit 0) / `failure` (exit 1) / `error` (exit 2) — consumido por branch protection futura (010) | FR-011 |

**Relações**: pertence a 1 Workflow (N:1), contém 3 Steps (1:3), orquestra N Harness oracles via glob.

**Validação**: presença do id `verify` em `jobs`; `runs-on` pinado; ausência de `continue-on-error: true` em qualquer step (FR-011).

**Transições**: não há transição interna; o job é efêmero por execução. Escalabilidade: 010 acrescenta steps/matrix sem renomear o job.

---

## Entidade: Step

Passo dentro do job `verify` (D8).

| Campo | Tipo | Restrição | Origem |
|---|---|---|---|
| `name` | string | MUST ∈ {`Checkout`, `Setup Python 3.12`, `Run harness`} | FR-009 |
| `uses` | string | para `Checkout`: MUST = `actions/checkout@v7`; para `Setup Python 3.12`: MUST = `actions/setup-python@v7` | FR-004/005 / D3/D4 |
| `with.fetch-depth` | integer | para `Checkout`: MUST = `0` (não default `1`) | FR-004 / D5 |
| `with.python-version` | string | para `Setup Python 3.12`: MUST = `'3.12'` (família, não `3.x` flutuante) | FR-005 / D4 |
| `run` | string | para `Run harness`: MUST = `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` (glob, sem lista hardcoded, sem `continue-on-error`) | FR-010 / D10 |
| `continue-on-error` | bool | MUST NOT = `true` para nenhum step | FR-011 |

**Relações**: pertence a 1 Job (N:1). Ordem é significativa: Checkout → Setup → Run.

**Validação**: inspeção YAML + grep negativo para `continue-on-error` e para ferramentas proibidas (FR-006).

---

## Entidade: Harness Fase 0

Conjunto `scripts/verify/f0-*.sh` com contrato `oracle-cli.md` (spec 001).

| Atributo | Tipo | Restrição | Origem |
|---|---|---|---|
| `path` | string | `scripts/verify/f0-*.sh` (glob) | FR-010 |
| `exit_code` | enum 0/1/2 | `0` conforme, `1` não conforme, `2` erro de uso — `Run harness` MUST propagar sem mascarar | FR-011 / contrato oracle-cli |
| `interface` | flags | MUST aceitar `--quiet` (só violações) e `--list` (enumera REQ-IDs) | contrato oracle-cli |
| `determinismo` | propriedade | duas execuções sobre mesmo estado produzem saída idêntica, sem `$RANDOM`/`date` | FR-012 / FR-018 |
| `efeitos` | propriedade | somente leitura; escreve só stdout/stderr | contrato oracle-cli |
| `raiz` | propriedade | resolve root pela localização do script, não por `$PWD` | contrato oracle-cli |

**Relações**: é orquestrado por `Job verify` via `Run harness` (N:1). Cada `f0-NNN` é uma peça do harness acumulado.

**Validação**: `for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done` local deve reproduzir veredito remoto (SC-002); `f0-003` deve continuar aprovando `f0-001`/`f0-002` (ADR-002/006).

---

## Entidade: Action pinada

Referência `actions/<name>@v<major>` que resolve para versão verificada (Q3/Q4).

| Campo | Tipo | Restrição | Origem |
|---|---|---|---|
| `name` | string | `actions/checkout` ou `actions/setup-python` | D3/D4 |
| `major` | string | MUST = `v7` (verificado 2026-08-30: checkout `7.0.1`, setup-python `7.0.0`, node24) | FR-004/005 |
| `runtime` | string | `node24`, requer runner ≥2.327.1 (compatível com `ubuntu-24.04` ≥2.329) | Q3/Q4 |
| `sha_pin` | string | deferido a spec 014 (Renovate/Dependabot) — não entra em 003 | Q8 |

**Relações**: usada por Step (N:1). Mapa de pins para automerge em 014: `checkout@v7`, `setup-python@v7`, `ubuntu-24.04`, `python 3.12`.

**Validação**: `grep -E 'uses: actions/(checkout|setup-python)@v7'` no `ci.yml` (SC-003).

---

## Entidade: Trigger

Evento que dispara o workflow (D7).

| Campo | Tipo | Restrição | Origem |
|---|---|---|---|
| `event` | enum | MUST ∈ {`push`, `pull_request`} | FR-008 |
| `filter.branches` | list[string] | MUST = `[main, develop]` | FR-008 |
| `excluded` | list[string] | `merge_group`, `tags` deferidos a 010/013 — MUST NOT aparecer em 003 | FR-008 |

**Relações**: pertence a Workflow (N:1).

**Validação**: parsing YAML de `on`; `push` para `feature/f0-*` não dispara, `push` para `main` dispara (SC-005).

---

## Diagrama de relações (textual)

```
Workflow (.github/workflows/ci.yml)
  ├─ permissions: contents: read
  ├─ triggers: push[main,develop] + pull_request[main,develop]
  └─ Job verify (runs-on: ubuntu-24.04)
       ├─ Step Checkout (uses: checkout@v7, fetch-depth: 0, Action pinada)
       ├─ Step Setup Python 3.12 (uses: setup-python@v7, python 3.12, Action pinada)
       └─ Step Run harness (run: for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done)
            └─ Harness Fase 0 (f0-001, f0-002, f0-003...)
                 └─ verifica FR-001..014 deste item + integridade de anteriores
```

## Regras de validação cruzadas

- **FR-006 (fronteira)**: `ci.yml` MUST NOT conter `ruff`, `mypy`, `pytest`, `pip-audit`, `trivy`, `gitleaks`, `uv`, `matrix`, `cache` — grep negativo global.
- **FR-012 (não-determinismo)**: MUST NOT conter `$RANDOM`, `date`, `GITHUB_RUN_NUMBER` em lógica de decisão.
- **FR-013 (escalabilidade)**: acrescentar steps/matrix em 010 é aditivo; renomear `verify` ou trocar `runs-on` reprova.
- **FR-014 (contratos)**: seção Contratos em `spec.md` declara entrega a 010/013/014 — sem ela, reprova.

Nenhum `NEEDS CLARIFICATION` — todas as entidades derivam diretamente dos FRs e das decisões D1–D10 já verificadas.
