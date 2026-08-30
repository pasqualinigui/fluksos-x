# Contract — CI Workflow `.github/workflows/ci.yml`

**Feature**: `003-ci-minimo` · **Spec**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md) · **Data model**: [data-model.md](../data-model.md)
**Data de verificação**: 2026-08-30 · **Fontes**: Q1–Q10 em `docs/plan/research/f0-003-ci-minimo.md`

Este contrato fixa o **schema estático** do workflow que `f0-003-ci-minimo.sh` asserirá. É o equivalente para CI do que `oracle-cli.md` é para oráculos: uma linha por REQ-ID, saída binária, sem julgamento.

---

## 1. File contract

| Propriedade | Valor normativo |
|---|---|
| Path | `.github/workflows/ci.yml` |
| Formato | YAML válido (parseável por `python3 -c 'import yaml'`) |
| Top-level keys | MUST conter `name`, `on`, `permissions`, `jobs` (FR-001) |
| Diretório | `.github/workflows/` MUST existir (FR-002, verificado inexistente em Q1) |
| Linhagem | Inexistente antes de 003; criado neste item; ampliado aditivamente em 010/013 sem reescrita (FR-013) |

---

## 2. Trigger contract (`on`)

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
```

| Regra | Verificação | FR |
|---|---|---|
| MUST ter `push` com filtro `branches: [main, develop]` | YAML path `on.push.branches == [main, develop]` | FR-008 |
| MUST ter `pull_request` com filtro idêntico | `on.pull_request.branches == [main, develop]` | FR-008 |
| MUST NOT ter `on: [push]` sem filtro | grep negativa | FR-008 |
| MUST NOT ter `merge_group` ou `tags` neste item | grep negativa (deferidos a 010/013) | FR-008/Contratos |
| Comportamento `push` para `feature/f0-*` | NÃO dispara | SC-005 |
| Comportamento `push` para `main` | dispara | SC-005 |

Fonte: Q7 `events-that-trigger-workflows` (2026-08-30).

---

## 3. Permissions contract

```yaml
permissions:
  contents: read
```

| Regra | Verificação | FR |
|---|---|---|
| MUST declarar `permissions: contents: read` em nível top-level | YAML path `permissions.contents == read` | FR-007 / D6 |
| MUST NOT declarar `write` | grep `write` reprova | FR-007 |
| MUST NOT declarar `id-token: write` | grep reprova (só em 013 com trusted publishing) | FR-007 |
| Ausência de `permissions` | reprova (default indeterminístico entre orgs) | Q6 |

Fonte: Q6 `automatic-token-authentication` — least privilege.

---

## 4. Runner contract

```yaml
jobs:
  verify:
    runs-on: ubuntu-24.04
```

| Regra | Verificação | FR |
|---|---|---|
| `jobs.verify.runs-on` MUST = `ubuntu-24.04` | YAML exact match | FR-003 / D2 |
| MUST NOT = `ubuntu-latest` | grep reprova | FR-003 |
| Runner `ubuntu-26.04` (preview) | MUST NOT ser usado | Q2 |

Fonte: Q2 `github-hosted-runners` — `ubuntu-latest` é alias móvel.

---

## 5. Steps contract

Ordem normativa:

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v7
    with:
      fetch-depth: 0
  - name: Setup Python 3.12
    uses: actions/setup-python@v7
    with:
      python-version: '3.12'
  - name: Run harness
    run: |
      for f in scripts/verify/f0-*.sh; do
        "$f" || exit 1
      done
```

| Step | `name` | `uses`/`run` | `with` | FR | Fonte |
|---|---|---|---|---|---|
| 1 | `Checkout` | `actions/checkout@v7` | `fetch-depth: 0` (não default `1`) | FR-004 | Q3+Q5 / D3 |
| 2 | `Setup Python 3.12` | `actions/setup-python@v7` | `python-version: '3.12'` | FR-005 | Q4+Q9 / D4 |
| 3 | `Run harness` | `run: for f in scripts/verify/f0-*.sh; do "$f" \|\| exit 1; done` | — | FR-010 | Q10 / D10 |

Regras adicionais:

- Job id MUST = `verify` (não `ci`/`build`/`test`) — `FR-009`, nome estável para virar `required check` em 010 (FR-013).
- MUST NOT ter `continue-on-error: true` em nenhum step — FR-011 (propagação de `exit 1`).
- `Run harness` MUST usar **glob** `scripts/verify/f0-*.sh` com `|| exit 1`; lista hardcoded reprova (FR-010).
- MUST NOT conter construção não determinística (`$RANDOM`, `date`, `GITHUB_RUN_NUMBER` em lógica) — FR-012.

Versões pinadas verificadas 2026-08-30:

| Action | major pin | versão exata na fonte | runtime | runner mínimo |
|---|---|---|---|---|
| `actions/checkout` | `v7` | `7.0.1` (`package.json`) | node24 | ≥2.327.1 |
| `actions/setup-python` | `v7` | `7.0.0` | node24 | ≥2.327.1 |

`ubuntu-24.04` hospedado já roda ≥2.329 (rolling) — compatível.

---

## 6. Frontier contract (o que NÃO entra em 003)

Qualquer ocorrência reprova:

```
ruff | mypy | pytest | pip-audit | trivy | gitleaks | uv | matrix | cache: pip | cache: poetry | codecov | release | trusted publishing | pull_request_target | workflow_run
```

Fonte: FR-006 / D5+D8 / Additional Constraints (escada) + C1 (vetor de privilégio elevado). Itens deferidos a 010: `Ruff+MyPy+Pytest+pip-audit+gitleaks`, `uv sync --frozen`, `matrix [3.12,3.13]`, `cache`, `required checks`+`branch protection`, `merge_group`. Deferidos a 013/014: `CHANGELOG`/`release`/`SBOM`/`trusted publishing`, Renovate/Dependabot. `pull_request_target`/`workflow_run` proibidos neste item por least privilege (V) — edge case fork em spec.md:93.

---

## 7. Behavior contract (veredito)

| Estado do repo (local) | `Run harness` exit | Workflow `verify` | Log |
|---|---|---|---|
| conforme (harness `0`) | `0` | ✅ `success` verde | lista cada oráculo executado |
| não conforme (harness `1`) | `1` | ❌ `failure` vermelho | `🔴 FR-...` + evidência (princípio X) |
| erro de uso | `2` | ❌ `failure` | mensagem de uso |

`continue-on-error` ausente garante que `1` não é mascarado. SC-002 exige observação de ambos os vereditos em execução remota real (push conforme + PR com violação injetada).

---

## 8. Determinismo & observabilidade

- Sem `date`, `$RANDOM`, `GITHUB_RUN_NUMBER` em lógica de decisão — FR-012.
- Duas execuções sobre mesmo commit produzem saída idêntica — SC-007 / `oracle-cli.md` FR-018.
- Sem `--quiet` em CI por padrão — log completo para rastreabilidade (X); `--quiet` local é para agregação `for f in ...; do "$f" --quiet || exit 1; done`.

---

## 9. Evolution contract

- Ampliação em 010 é **aditiva**: acrescenta steps (`ruff`, `mypy`, `pytest`), `matrix`, `cache`, `merge_group` sem renomear `verify` nem trocar `runs-on`.
- Verificação estática garante que 010 só acrescenta — contrato testável por diff (FR-013).
- SHA pin (ex.: `actions/checkout@abc123...`) deferido a 014 com Renovate — não entra em 003.

---

## 10. Checks estáticos que este contrato habilita (para `f0-003`)

1. YAML válido + chaves top-level (FR-001)
2. `runs-on: ubuntu-24.04` não `ubuntu-latest` (FR-003)
3. `checkout@v7` + `fetch-depth: 0` (FR-004)
4. `setup-python@v7` + `python-version: '3.12'` (FR-005)
5. Nenhuma ferramenta proibida (FR-006)
6. `permissions: contents: read` sem `write` (FR-007)
7. `on: push/pull_request [main, develop]` (FR-008)
8. Job `verify` + 3 steps nomeados (FR-009)
9. `Run harness` glob + `|| exit 1` (FR-010)
10. Sem `continue-on-error`, sem não-determinismo (FR-011/012)
11. Id `verify` estável (FR-013 escalabilidade)
12. Seção Contratos declarada (FR-014)

Todas as verificações são `shell` + `git` + `python3` stdlib — mesma restrição dos oráculos 001–003.
