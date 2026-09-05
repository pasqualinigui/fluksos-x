# Feature Specification: CI mínimo — harness da Fase 0 em runner limpo

**Feature Branch**: `003-ci-minimo`

**Created**: 2026-08-30

**Status**: Draft

**Input**: User description: "Fase 0, item 0.13 (003/016 na ordem de execução): CI mínimo — workflow que executa o harness da Fase 0 em runner limpo. Só shell, git e Python 3.12 stdlib. Escopo restrito sem Ruff/MyPy/Pytest/pip-audit/branch protection (estes são spec 010)."

**Item do plano**: 0.13 (§17 Fase 0, Emenda 1 ADR-009) · **Ordem de execução**: 003 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-003-ci-minimo.md` (decisões D1–D10, Q1–Q10, nenhuma NEEDS CLARIFICATION)
**Contrato de entrada**: `specs/002-constitution-ratification/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-009, ADR-011)

---

## Contexto

O plano original entregava ao motor a capacidade de **gerar** pipelines para os sistemas-alvo (agente DevOps, item 3.7) e **não dava pipeline ao próprio motor** (ADR-009). Todo enforcement de qualidade até aqui é hook local (`lefthook`), que `git commit --no-verify` desfaz por completo. A Emenda 1 acrescentou quatro itens à Fase 0; este é o primeiro deles, executado imediatamente após a constitution (`002`) para que o harness cresça por acréscimo **junto** com a integração contínua — dez itens construídos sem rede significaria validar dez itens de uma vez na primeira execução.

Este item é **intencionalmente mínimo**: depende apenas de shell, git e Python 3.12 stdlib, que já existem (mesma restrição dos oráculos `001`–`003`, `scripts/verify/README.md` › Restrição de dependências). Ruff, MyPy, Pytest, pip-audit, gitleaks, matriz de Python, `uv sync --frozen`, required status checks e branch protection são item `010` (0.14) e **não** entram aqui. A especificação registra essa fronteira escopo para que o plano não seja reescrito e a ordem executável (ADR-011) permaneça auditável.

O workflow deve obedecer aos princípios ratificados (constitution 1.0.0): **I** determinismo sobre probabilidade (runner e actions pinados, sem alias móvel), **III** teste antes da implementação (harness vermelho→verde continua sendo a prova), **V** segurança Lei Zero (menor privilégio do `GITHUB_TOKEN`), **VI** o harness é o oráculo (workflow reproduz exatamente o oráculo local, não o substitui), **VIII** elo verificado (toda versão externa verificada contra fonte, não memória — pesquisa Q1–Q10), **X** observabilidade (falha nomeia requisito e evidência via saída do harness).

---

## Clarifications

### Session 2026-08-30

- Q: O CI mínimo deve bloquear `push --no-verify` sozinho? → A: **Não.** Este item não cria branch protection nem required status checks (são `010`). O workflow **executa** o harness em runner limpo e **reporta** o veredito; o bloqueio mecânico vem em `010`. Até lá, o harness local somado ao workflow remoto já dá detecção — o bypass continua possível, mas deixa rastro no check.
- Q: Cache de dependências entra agora? → A: **Não.** Sem `uv.lock`/`pyproject.toml`, cache não tem chave estável e esconderia indeterminismo futuro. Cache entra em `010` com `uv`.
- Q: Runner deve ser `ubuntu-latest` para pegar SO novo automaticamente? → A: **Não.** `ubuntu-latest` é alias móvel (Q2). Pin `ubuntu-24.04` para determinismo; atualização de SO é item versionado (spec `014`).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Veredito remoto idêntico ao local (Priority: P1)

O mantenedor faz `push` para `main` (ou abre PR para `main`/`develop`) e precisa que um runner limpo do GitHub execute **exatamente** o mesmo harness que roda localmente (`for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done`) e que o check fique verde quando o harness está verde e vermelho quando há violação — sem instalar nada além do que a máquina já possui no início do bootstrap.

**Why this priority**: é o portão que faltava. Sem ele, dez itens são construídos sem rede; a primeira execução do pipeline teria de validar dez itens de uma vez. É o valor mínimo viável de CI.

**Independent Test**: fazer push com estado conforme → workflow `verify` verde; introduzir violação mínima (ex.: linha `feature/foo` fora do padrão FR-006b ou arquivo `.env` rastreado) → push seguinte com check vermelho, log nomeia FR violado. Reproduz localmente com `scripts/verify/f0-001-foundation.sh` e `f0-002-constitution.sh`.

**Acceptance Scenarios**:

1. **Given** repositório em estado conforme (harness local `0`), **When** ocorre `push` para `main`, **Then** workflow `ci` dispara, job `verify` conclui com sucesso e lista cada oráculo executado.
2. **Given** repositório com violação injetada (ex.: commit com mensagem fora de Conventional Commits), **When** ocorre `push` para `develop` ou PR para `main`, **Then** job `verify` falha (`exit 1`), check vermelho, log contém o identificador da asserção e evidência (mesmo formato local: `🔴 FR-...`).
3. **Given** repositório com histórico contendo arquivo proibido (`.env`) adicionado há N commits, **When** workflow executa com `fetch-depth: 0`, **Then** FR-020b reprova (histórico completo auditado). Com `fetch-depth: 1` reprovaria incorretamente — por isso `0` é obrigatório.
4. **Given** workflow em execução, **When** qualquer `scripts/verify/f0-*.sh` sai com `1`, **Then** step `Run harness` propaga `exit 1` e job falha — sem `continue-on-error`.

---

### User Story 2 - Determinismo de ambiente entre máquina local e runner (Priority: P2)

O mantenedor e um contribuidor em máquina diferente precisam obter o **mesmo veredito** para o mesmo commit, sem depender de configuração de máquina local, versão de SO do runner ou versão flutuante de action. O CI deve pinar o que é móvel por construção.

**Why this priority**: princípio **I**. Um CI que muda de resultado sem mudança no repositório não é oráculo — é loteria. A pesquisa Q2/Q3/Q4 mediu exatamente essa mobilidade.

**Independent Test**: inspecionar `ci.yml` em disco — `runs-on`, `uses:` e `python-version` devem estar pinados; comparar com tabela de decisões vinculantes D2–D4.

**Acceptance Scenarios**:

1. **Given** `ci.yml`, **When** lido, **Then** `runs-on: ubuntu-24.04` (pinado), **não** `ubuntu-latest`.
2. **Given** `ci.yml`, **When** lido, **Then** `uses: actions/checkout@v7` com `fetch-depth: 0` e `uses: actions/setup-python@v7` com `python-version: '3.12'` — ambos major pin `v7` verificados em 2026-08-30 como `7.0.1` e `7.0.0` (node24, runner ≥2.327.1).
3. **Given** harness, **When** executado localmente com Python 3.12.3 e no runner com 3.12.14 (família `3.12`), **Then** vereditos coincidem — família pinada, não patch.
4. **Given** dois pushes do **mesmo** commit (re-run), **When** workflow reexecuta, **Then** saída é idêntica (sem data/horário/aleatório), obedecendo ao contrato `oracle-cli.md` de determinismo.

---

### User Story 3 - Privilégio mínimo e fronteira de escopo preservada (Priority: P3)

O workflow deve rodar com o menor privilégio possível e **não** introduzir ferramentas ou portões de itens futuros, para que a escada de dependências (constitution Additional Constraints) e a ordem da ADR-011 não sejam violadas por antecipação.

**Why this priority**: Lei Zero por analogia — `contents: write` quando só se lê é privilégio elevado. E antecipar Ruff/MyPy etc. quebraria a restrição `001–003: stdlib apenas` e invalidaria a prova de TDD vermelho→verde dos itens `005–010`.

**Independent Test**: inspeção estática de `ci.yml` contra lista de proibições deste item.

**Acceptance Scenarios**:

1. **Given** `ci.yml`, **When** inspecionado, **Then** contém `permissions: contents: read` (top-level) e nenhum `write` ou `id-token: write`.
2. **Given** `ci.yml`, **When** inspecionado, **Then** não contém `ruff`, `mypy`, `pytest`, `pip-audit`, `trivy`, `gitleaks`, `uv`, `matrix`, `cache: pip`, `codecov`, `release`, `trusted publishing` — qualquer um reprova.
3. **Given** `ci.yml`, **When** executado, **Then** steps são apenas `Checkout`, `Setup Python 3.12`, `Run harness` (nomes estáveis) dentro de um único job `verify`.
4. **Given** futuro item `010`, **When** ele amplia `ci.yml` para incluir matriz e ferramentas, **Then** job `verify` permanece com mesmo `job_id` (`verify`) para virar `required check` sem rename — nomes estáveis desde `003`.

---

### Edge Cases

- **Push direto com `--no-verify` ainda passa localmente.** O workflow dispara igual (evento `push`) e reprova remotamente; o bypass deixa rastro no check. Bloqueio mecânico só em `010` via branch protection — documentado, não omitido.
- **PR de fork.** `pull_request` de fork dispara no base com `contents: read`; `checkout@v7` por padrão recusa `pull_request_target`/`workflow_run` de fork sem `allow-unsafe-pr-checkout` (Q3) — comportamento seguro por padrão; `003` não usa `pull_request_target`.
- **Histórico raso esconderia violação.** `fetch-depth: 1` faria `git log --all` parecer limpo. Por isso `fetch-depth: 0` é obrigatório; teste de regressão verifica que `HIST_ALL` contém ao menos `HEAD~1` quando há dois commits.
- **Re-run do workflow.** Deve produzir mesma saída; harness já garante determinismo (FR-018), workflow não pode acrescentar construção não determinística (`date`, `$RANDOM`, `actions/cache` com chave instável).
- **Ausência de `specs/003-*` ainda não criada.** Workflow existe antes de oráculo `003` existir; deve continuar executando `f0-001` e `f0-002` até que `f0-003` seja acrescentado — `for f in scripts/verify/f0-*.sh` cobre por construção, sem lista hardcoded.
- **Runner `ubuntu-24.04` removido pelo provedor.** Falha explícita de `runs-on` é preferível a migração silenciosa para `26.04` via `ubuntu-latest`; atualização é PR versionado validado pelo harness (spec `014`).
- **Token antigo com `permissions: write` padrão.** Declarar `contents: read` torna o workflow determinístico entre organizações com defaults diferentes (Q6).

---

## Requirements *(mandatory)*

### Functional Requirements

**Artefato e localização**

- **FR-001**: O sistema MUST prover um workflow em `.github/workflows/ci.yml` em YAML válido com chaves top-level `name`, `on`, `permissions`, `jobs`.
- **FR-002**: O diretório `.github/workflows/` MUST existir como consequência deste item (verificado inexistente antes — Q1).

**Runner e actions determinísticos**

- **FR-003**: O job `verify` MUST declarar `runs-on: ubuntu-24.04` **pinado**; MUST NOT usar `ubuntu-latest` (Q2, princípio I, D2).
- **FR-004**: O step de checkout MUST usar `actions/checkout@v7` (major pin `v7` = `7.0.1` em 2026-08-30, node24) com `with: fetch-depth: 0` (Q3/Q5, D3/D5). Omisso ou `1` reprova.
- **FR-005**: O step de setup de Python MUST usar `actions/setup-python@v7` (major pin `v7` = `7.0.0` em 2026-08-30, node24) com `with: python-version: '3.12'` (família, resolve para `3.12.14` no runner; local é `3.12.3`) (Q4/Q9, D4/D9). Omitir versão ou usar `3.x` flutuante reprova.
- **FR-006**: O workflow MUST NOT introduzir `cache` (pip/poetry), `matrix`, `uv`, `ruff`, `mypy`, `pytest`, `pip-audit`, `trivy`, `gitleaks` ou qualquer ferramenta de item `005–010` (D5, D8; escada de dependências).

**Privilégio mínimo**

- **FR-007**: O workflow MUST declarar `permissions: contents: read` em nível top-level (menor privilégio que permite checkout); MUST NOT declarar `write` nem `id-token: write` (Q6, D6, princípio V).

**Gatilhos**

- **FR-008**: O workflow MUST disparar em `on: push: branches: [main, develop]` e `on: pull_request: branches: [main, develop]` (Q7, D7). Sem filtro (`on: [push]`) ou sem `pull_request` reprova. `merge_group` e `tags` ficam para `010`/`013`.

**Job e steps estáveis**

- **FR-009**: O workflow MUST conter exatamente um job com id `verify` (nome estável que `010` referenciará como required check) com steps nomeados `Checkout`, `Setup Python 3.12`, `Run harness` (D8). Renomear `verify` reprova.
- **FR-010**: O step `Run harness` MUST executar o harness exatamente como o contrato local: `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` (sem `continue-on-error`, MUST NOT usar `--quiet` em CI — log completo por observabilidade, princípio X; agregação local MAY usar `--quiet`; D10). Lista hardcoded de oráculos reprova (deve expandir via glob).

**Fidelidade ao oráculo**

- **FR-011**: O workflow MUST propagar o código de saída do harness (`0` conforme → check verde, `1` não conforme → check vermelho, `2` erro de uso) sem mascarar; `continue-on-error: true` reprova.
- **FR-012**: O workflow MUST NOT conter construção não determinística (`$RANDOM`, `date`, `GITHUB_RUN_NUMBER` em lógica de decisão) (princípio I, contrato `oracle-cli.md` FR-018).

**Fronteira de escopo e escalabilidade**

- **FR-013**: O workflow MUST ser extensível para `010` sem reescrita: acrescentar steps/matrix/caching deve ser aditivo, não renomeação de `verify` ou troca de `runs-on` (Q8, D8) — consequência de FR-009 para `010` como required check (id estável, não duplicação). Verificação estática garante que `010` só acrescenta.

**Rastreabilidade entre itens**

- **FR-014**: O sistema MUST declarar o que entrega aos itens seguintes e quais responsabilidades transfere, conforme seção Contratos deste spec (ADR-002/011).

### Key Entities

- **Workflow**: arquivo YAML em `.github/workflows/ci.yml` que orquestra jobs em runner. Atributos: `name`, `on` (eventos e filtros), `permissions`, `jobs.<id>.runs-on`, `jobs.<id>.steps`.
- **Job `verify`**: unidade de execução que valida o harness. Atributos: `runs-on` (pinado), `steps` (checkout, setup-python, run harness), status (`success`/`failure`) consumido por branch protection futura.
- **Harness Fase 0**: conjunto `scripts/verify/f0-*.sh` com contrato `oracle-cli.md` (códigos `0`/`1`/`2`, `--quiet`/`--list`, saída determinística por REQ-ID). Atributos: `FR-016` semântica de códigos, `FR-018` sem não-determinismo.
- **Action pinada**: referência `actions/<name>@v<major>` que resolve para versão verificada (checkout `7.0.1`, setup-python `7.0.0` em 2026-08-30). Atributo: major pin escalável, SHA pin fica para `014`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Workflow existe em `.github/workflows/ci.yml`, é YAML válido e contém `name`, `on`, `permissions: contents: read`, `jobs.verify.runs-on: ubuntu-24.04` — verificado por inspeção estática sem executar o workflow.
- **SC-002**: Um `push` para `main` em estado conforme produz check `verify` verde; `pull_request` para `main` com violação injetada produz check vermelho com log contendo identificador FR e evidência — observado em ao menos uma execução remota real.
- **SC-003**: `actions/checkout@v7` e `actions/setup-python@v7` estão presentes com `fetch-depth: 0` e `python-version: '3.12'` respectivamente — 100% dos pins conferem com tabela de pacotes verificados (Q3/Q4).
- **SC-004**: Nenhuma ferramenta de item `010` (`ruff`, `mypy`, `pytest`, `pip-audit`, `trivy`, `gitleaks`, `uv`, `matrix`, `cache`) aparece em `ci.yml` — 100% de fronteira de escopo preservada.
- **SC-005**: Triggers são exatamente `push` e `pull_request` filtrados para `branches: [main, develop]` — verificado por parsing YAML; push para `feature/f0-...` não dispara, push para `main` dispara.
- **SC-006**: Step `Run harness` usa glob `scripts/verify/f0-*.sh` com `|| exit 1`, sem `continue-on-error`, e job `verify` mantém id estável `verify` — 100% escalável para `010` sem rename.
- **SC-007**: Duas execuções do workflow sobre o mesmo commit produzem saída idêntica (determinismo), e verificação com `fetch-depth: 0` detecta violação histórica que `fetch-depth: 1` esconderia — demonstrado por teste de regressão local comparando `git log --all` raso vs completo.
- **SC-008**: `GITHUB_TOKEN` tem exatamente `contents: read` (least privilege); workflow executa sem `write` e sem `id-token: write` — verificado por inspeção de `permissions` e por execução bem-sucedida sem privilégio de escrita.

---

## Assumptions

- Runner `ubuntu-24.04` hospedado por GitHub já roda Actions Runner `≥ v2.329.0`, compatível com `checkout@v7` e `setup-python@v7` (ambos `node24`, exigem `≥ v2.327.1`) — verificado via changelogs v5/v6/v7 e natureza rolling do runner hospedado (Q3/Q4). Se o runner estiver desatualizado em GHES self-hosted (fora do escopo — projeto usa github.com), o workflow falharia com mensagem de runtime, não silenciosa.
- Repositório é público ou privado em github.com com Actions habilitado; `GITHUB_TOKEN` com `contents: read` é suficiente para `actions/checkout` via HTTPS — verificado na doc de autenticação automática (Q6).
- `Python` família `3.12` é suficiente; não é necessário pinar `3.12.14` exato nem `3.12.3` local — família dá determinismo semântico e escala para matriz `010`.
- Harness permanece em `scripts/verify/f0-*.sh` e continua obedecendo a `contracts/oracle-cli.md` (códigos `0`/`1`/`2`); o workflow apenas o orquestra, não o reimplementa (princípio VI).
- Até `010`, branch protection não existe; `--no-verify` continua burlando o hook local, mas o check remoto registra a tentativa — comportamento documentado como deferido, não como omissão.
- Workflows são lidos da branch padrão; em PRs, o workflow que roda é o da base (`main`/`develop`) mesclado com o head — por isso `fetch-depth: 0` audita `refs/pull/*/merge` corretamente.

---

## Contratos *(específico do bootstrap da Fase 0)*

### Entregue por este item

| Consumidor | Contrato entregue |
|---|---|
| **Todos os itens 004–016** | Workflow `ci.yml` executando o harness em runner limpo — primeiro portão remoto; a partir daqui todo item é validado local + remoto |
| **010 (0.14 CI completo + branch protection)** | Job `verify` estável (`jobs.verify`) pronto para virar `required check`; `permissions: contents: read` base para ampliar; `on:` base para acrescentar `merge_group`; runner/actions pins como referência |
| **005 (0.1 UV workspace)** | Runner `ubuntu-24.04` e `setup-python@v7` validados — base para `uv sync --frozen` futuro |
| **014 (0.16 atualização de dependências)** | Mapa de pins (`checkout@v7`, `setup-python@v7`, `ubuntu-24.04`, `python 3.12`) para automerge |

### Transferido a itens posteriores

| Destinatário | Responsabilidade transferida | Motivo |
|---|---|---|
| **010 (0.14)** | `Ruff` + `MyPy` + `Pytest` + `pip-audit` + `gitleaks`, portão de cobertura, `uv sync --frozen`, validação de `Conventional Commits`, matriz `[3.12, 3.13, ...]`, `cache`, `required checks` e `branch protection` que tornam `--no-verify` inócuo | Escada de dependências — ferramentas ainda não existem; antecipar violaria D5/D8 e `FR-006` |
| **013 (0.15)** | `CHANGELOG` via `python-semantic-release`, tag, build, publicação PyPI via **trusted publishing (OIDC)** com `contents: write` + `id-token: write`, SBOM anexado | Precisa de `012` (`packages/cli` existente) e de `010` verde |
| **014 (0.16)** | Renovate/Dependabot com agrupamento e harness verde obrigatório; SHA pin se desejado | Precisa do pipeline completo para validar o que entra |

