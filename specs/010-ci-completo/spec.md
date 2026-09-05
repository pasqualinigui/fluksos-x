# Feature Specification: CI completo + branch protection — portão servidor

**Feature Branch**: `010-ci-completo`

**Created**: 2026-09-04

**Status**: Draft

**Input**: User description: "Fase 0, item 0.14 (010/016 na ordem de execução): CI completo + branch protection — workflow com harness + ruff + mypy + pytest + pip-audit + gitleaks + portão de cobertura + matriz Python + uv sync --frozen + validação de mensagem de commit, e proteção de main/develop com required checks que neutralizam --no-verify, sem reviews obrigatórios, sem tokens no repo."

**Item do plano**: 0.14 (§17 Fase 0, Emenda 1) · **Ordem de execução**: 010 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-010-ci-completo.md` (decisões D1–D10, Q1–Q10, hierarquia de fontes P0–P3)
**Contrato de entrada**: `specs/009-lefthook/spec.md` › Contratos (Transferido à 010) + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-015, ADR-016, ADR-017, ADR-019, ADR-020) + `docs/plan/implementation_plan.md` §17 Emenda 1 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem harness 9/9 verde local e CI mínimo (003) que só executa o harness — mas **sem portão real**: `git commit --no-verify` + push direto em `main` passam sem validar nada no servidor, cobertura é relatório (não reprova), mensagem de commit não é validada (risco silencioso ao `semantic-release` de 013) e segredos só são auditados em `fs` local. A Emenda 1 (ADR-009) criou este item exatamente para isso: hook local é conveniência; portão vive no servidor via required checks.

Este item entrega **exclusivamente** workflow completo em `.github/workflows/` (harness + ruff + mypy + pytest + pip-audit + gitleaks + cobertura com `--fail-under` + matriz `["3.12","3.13"]` + `uv sync --frozen` + commitlint com os 11 tipos) e branch protection clássica em `main`+`develop` (checks obrigatórios + sem-bypass inclusive admin, sem reviews obrigatórios), com oráculo `f0-010-ci-completo.sh` de 12–16 asserções. Proteção de servidor é config, não arquivo: o oráculo assere o lado versionável + procedimento documentado; o lado servidor é cenário humano (🧑) com checklist (precedente 003-T031). Não cria `packages/` (011/012), release (013), dependabot/renovate (014), tokens/credenciais em arquivo algum (Lei Zero), runners self-hosted, merge queue, CODEOWNERS.

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (pins SHA + runner fixo + matriz exata + quarentena sem retry mascarador); **II** especificação precede código; **III** vermelho→verde em commits separados; **V** Lei Zero (zero segredos; gitleaks fecha o loop); **VI** harness oráculo com 12–16 asserções + required checks no servidor (ADR-009); **VIII** elo verificado (releases API + docs GitHub 2026-09-04); **X** falha nomeia `FR-XXX` + job nominal único (checks sem ambiguidade).

---

## Clarifications

### Session 2026-09-04 (resolvida — decisão pelo DNA, recomendação acatada)

- Q: Limiar `--fail-under` de cobertura? → A: **90** (medido 95% via `pytest --cov` 2026-09-04; Q1-A).
- Q: Checks estritos ou frouxos? → A: **frouxos + sem-bypass** (Q2-A; estrito compra builds sem ameaça correspondente).
- Q (clarify): Falha em uma versão da matriz cancela as demais? → A: **não (`fail-fast: false`)** — sinal total por run, espelho da regra "uma asserção reprovada não interrompe as demais".
- Q (clarify): Um job por verificador ou job único? → A: **jobs separados** (`harness`, `lint`, `types`, `tests`, `audit`, `secrets`, `coverage`, `commitlint`) — falha nomeia o culpado no PR (princípio X); cada job vira required check independente.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Bypass local morre no servidor (Priority: P1)

Mantenedor commita com `--no-verify` (pula hooks) e empurra em branch. O push abre PR; required checks executam no runner e reprovam (ou o push direto em `main` é recusado pela proteção). Nenhum bypass local altera o veredito do servidor.

**Why this priority**: é a razão de existir do item (ADR-009) — sem isso, todo o harness Fase 0 é conveniência revogável por flag.

**Independent Test**: em cópia descartável com bypass simulado (commit vazio `--no-verify` + push de branch de teste), observar checks executando e bloqueando merge até verde; push direto em `main` recusado (cenário 🧑 no servidor, sem tocar `main` real sem aprovação).

**Acceptance Scenarios**:

1. **Given** branch protegida com checks obrigatórios, **When** PR com commit `--no-verify` e lint quebrado, **Then** checks reprovam e o merge trava até correção.
2. **Given** tentativa de push direto em `main`, **When** push executado, **Then** servidor recusa (proteção + sem-bypass).

---

### User Story 2 — Cobertura vira portão, não relatório (Priority: P2)

PR que derruba cobertura abaixo do limiar reprova no job de cobertura com número nomeado; acima do limiar, passa sem ruído.

**Why this priority**: transforma a lacuna 7 da ADR-009 (relatório que ninguém lê) em garantia mecânica.

**Independent Test**: `pytest --cov --cov-fail-under` local sobre o limiar (verde) e com limiar artificial acima do medido (vermelho nomeado) — sem mutar código de produção.

**Acceptance Scenarios**:

1. **Given** cobertura medida acima do limiar, **When** job de cobertura executa, **Then** saída zero.
2. **Given** limiar acima do medido (simulação), **When** job executa, **Then** saída diferente de zero nomeando o déficit.

---

### User Story 3 — Mensagem fora da gramática é barrada (Priority: P3)

Commit com mensagem fora dos 11 tipos (ex.: `wip stuff`) reprova no job commitlint com a regra nomeada; mensagem conforme (`docs(specs): ...`) passa.

**Why this priority**: protege o `semantic-release` de 013 contra quebra silenciosa (lacuna 5 da ADR-009).

**Independent Test**: validar lote de mensagens reais do histórico (todas passam) + 3 mensagens inválidas sintéticas (todas reprovam com regra nomeada).

**Acceptance Scenarios**:

1. **Given** mensagens do histórico (`docs:`, `feat:`, `fix:`...), **When** commitlint valida, **Then** todas passam (preset aceita os 11 tipos — armadilha Q8).
2. **Given** `wip stuff` / `Update README.md`, **When** commitlint valida, **Then** reprova nomeando a regra.

---

### Edge Cases

- Servidor GitHub inacessível / runner sem Docker: jobs de rede/Trivy fazem skip documentado (⏭️), nunca falham por ambiente — espelho 008-FR-009; Trivy pleno validado onde houver Docker.
- Proteção de servidor ainda não aplicada (repositório sem admin executando o procedimento): oráculo assere workflow + procedimento; cenário 🧑 registra aplicação (precedente 003-T031) — convergência sem o 🧑 é parcial e declarada.
- Job com nome duplicado entre workflows: proibido (ambiguidade trava PRs — docs Q1); oráculo asserir unicidade de nomes.
- `continue-on-error` / retry mascarador: proibidos em qualquer job (003-FR-011 + ADR-019); quarentena = `timeout-minutes` explícito + falha visível.
- Histórico com mensagem fora da gramática (commits antigos pré-convenção): validação incide no intervalo do push/PR, nunca reescreve passado.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST estender `.github/workflows/ci.yml` (003) para workflow completo sem renomear o job `verify` existente (renomear quebra checks nominais e exige ADR prévia — fronteira declarada na pesquisa).
- **FR-002**: O sistema MUST fixar todos os `uses:` por SHA + comentário de versão (`checkout v7.0.1`, `setup-python v7.0.0`, `setup-uv v10.0.1`) e runner fixo `ubuntu-24.04` (nunca `latest`).
- **FR-003**: O sistema MUST prover `setup-uv` oficial com `uv sync --frozen` (prova coerência do lock) + cache auto.
- **FR-004**: O sistema MUST declarar matriz Python exatamente `["3.12", "3.13"]` (intervalo do `requires-python`, sem inventar) com `fail-fast: false` (todas as versões sempre executam — sinal total por run).
- **FR-005**: O sistema MUST executar no CI, cada um em **job separado com nome único e estável**: harness `f0-*.sh` + `ruff check`/`format --check` + `mypy --strict` + `pytest -q` + `pip-audit` + `gitleaks detect` (via `gitleaks/gitleaks-action v3.0.0`, SHA `e0c47f4f…`) + `trivy fs` (via `aquasecurity/trivy-action v0.36.0`, com Docker) + cobertura + commitlint — falha nomeia o job no PR (decisão CLARIFY 2026-09-04, princípio X; remediação ANALYZE M1).
- **FR-006**: O sistema MUST prover portão de cobertura `--fail-under=90` sobre `pytest-cov 7.1.0` (já em dev desde 005 com hash em `uv.lock`; este item adiciona o **portão**, não a dependência — medido 95% em 2026-09-04).
- **FR-007**: O sistema MUST validar mensagens via commitlint (v21.2.2) com preset que aceita os 11 tipos do repo (CONTRIBUTING) e intervalo por evento (`--from ${{ github.event.pull_request.base.sha || github.event.before }} --to ${{ github.event.pull_request.head.sha || github.sha }}`); mensagem fora da gramática reprova com regra nomeada (remediação ANALYZE M3).
- **FR-008**: O sistema MUST documentar procedimento de branch protection clássica (`main`+`develop`): checks obrigatórios + sem-bypass inclusive admin + sem-force/deleção, sem reviews obrigatórios — aplicado por humano no servidor (🧑) com checklist versionado em `specs/010-ci-completo/branch-protection.md`; o oráculo NUNCA usa token (remediação ANALYZE M2).
- **FR-009**: O sistema MUST declarar checks **frouxos** (sem exigência de branch atualizada) + **sem-bypass inclusive admin** em `main`+`develop`.
- **FR-010**: O sistema MUST declarar quarentena ADR-019 no workflow: `timeout-minutes` explícito por job, sem `continue-on-error`, sem retry mascarador.
- **FR-011**: O sistema MUST prover oráculo `scripts/verify/f0-010-ci-completo.sh` com 12–16 asserções sob o contrato `oracle-cli.md` (identidade FR↔asserção, determinismo, somente leitura, self-check `f0-001…f0-009`, manifest 10ª linha).
- **FR-012**: `specs/README.md` MUST conter `010` com `ci-completo` `✅` e hash do commit de convergência (inquebrável em escala, padrão 007–009).
- **FR-013**: `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados (CONVERGE + exceção M3 não se estende).

### Key Entities *(include if feature involves data)*

- **Workflow CI**: arquivo versionado de pipeline; atributos: jobs nominais únicos, pins SHA, matriz, timeouts; jamais contém segredos.
- **Required check**: exigência de servidor; atributos: nome do job, origem (Actions), estrito/frouxo, sem-bypass; fora do repo por construção.
- **Portão de cobertura**: limiar `--fail-under`; atributo: número medido-primeiro, versionado onde o job o lê.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Commit com `--no-verify` e defeito não alcança `main` — ou recusado no push, ou travado no PR até checks verdes.
- **SC-002**: Queda de cobertura abaixo do limiar reprova o PR com o déficit nomeado; acima, silêncio.
- **SC-003**: Mensagem fora da gramática é barrada com regra nomeada; 100% do histórico existente passa no preset.
- **SC-004**: Harness 10/10 + manifest 10/10 + matriz 3.12/3.13 verdes em runner limpo.
- **SC-005**: Zero `[ ]` em `tasks.md`, par vermelho→verde separado, proteção aplicada no servidor com evidência registrada (ou divergência declarada se o 🧑 estiver pendente).
- **SC-006**: Oráculo 2× byte-idêntico, cada execução <5s (espelho FR-014/005/009).

## Assumptions

- Limiar de cobertura 90 (medido 95%) e checks frouxos+sem-bypass decididos no CLARIFY (FR-006/FR-009).
- `gitleaks.toml` ausente = defaults oficiais; `.gitleaksignore` só se o PLAN exigir.
- Trivy pleno exige Docker no runner (padrão em `ubuntu-24.04` hospedado); sem Docker, skip ⏭️ (fecha B2 da auditoria onde houver Docker).
- Auditoria seguinte devida após 012 (009–012 = 4 itens, teto ADR-016); 010 não a cria.
- Scheduled-tasks e demais vigiados (E17/ADR-020) seguem fora de escopo.

## Contratos

### Entregue por este item

- Workflow completo (jobs nominais únicos, SHA pins, matriz, quarentena) + procedimento de proteção + oráculo `f0-010` (12–16) + 10ª linha do manifest + `specs/README.md` `010 ✅` + commitlint com 11 tipos + cobertura como portão.
- bypass `--no-verify` neutralizado no servidor (dívida 009 paga); Trivy pleno onde houver Docker (B2 pago onde aplicável); primeira execução real do pipeline em servidor (resíduo 003-T031/B3 pago).

### Recebido de itens anteriores

- De **009**: bypass como ameaça + commitlint como responsabilidade + Trivy-com-Docker transferidos.
- De **008**: `pip-audit`/`trivy fs` canônicos + skip-sem-Docker como padrão.
- De **003**: `ci.yml` mínimo + job `verify` nominal (intocável sem ADR).
- Da **auditoria/ADR-019**: quarentena de flake como requisito de workflow.
- Da **ADR-016**: teto de auditoria (próxima após 012).

### Transferido a itens posteriores

- À **013** (`0.15` release): mensagens validadas (pré-requisito do `semantic-release`) + pipeline verde estável como base.
- À **014** (`0.16` deps automáticas): harness verde obrigatório no merge como critério de automerge.
- À **auditoria pós-012**: `f0-audit-009-012` devida (010 não a cria, mas a alimenta).
