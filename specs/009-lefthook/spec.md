# Feature Specification: Lefthook — orquestração pre-commit do harness

**Feature Branch**: `009-lefthook`

**Created**: 2026-09-04

**Status**: Draft

**Input**: User description: "Fase 0, item 0.5 (009/016 na ordem de execução): Lefthook — orquestração pre-commit do harness (ruff + mypy strict + pytest + pip-audit + trivy fs condicional), via lefthook.yml versionado, min_version pinado, sem remotes/self-update, sem tocar CI, com pré-autorização de fronteira (ADR-017) e FR de cadência de auditoria (ADR-016)."

**Item do plano**: 0.5 (§17 Fase 0, Emenda 1 com 0.13–0.16) · **Ordem de execução**: 009 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-009-lefthook.md` (decisões D1–D10, Q1–Q10, hierarquia de fontes P0–P3)
**Contrato de entrada**: `specs/008-pip-audit-trivy/spec.md` › Contratos (Transferido à 009) + `docs/plan/audit/f0-audit-005-008.md` + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-015, ADR-016, ADR-017) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem quatro verificadores convergidos — `pytest` (005), `ruff` (006), `mypy strict` (007), `pip-audit`+Trivy (008) — mas **nenhuma orquestração local**: cada autor roda cada ferramenta à mão, em ordem arbitrária, ou não roda. O `implementation_plan §4` exige `Lefthook 2.1.11` como pre-commit que dê feedback em segundos. Hook local é conveniência, não portão (ADR-009): `--no-verify` o desfaz, e o portão real vive no servidor (010, required checks). Esta spec fecha o harness de qualidade da Fase 0 sem tocá-lo por dentro — só o invoca.

Este item entrega **exclusivamente** `lefthook.yml` na raiz (YAML, `min_version` = pin) com jobs `pre-commit` fail-fast (`ruff check` → `ruff format --check` → `mypy --strict` → `pytest -q` → `pip-audit`, + `trivy fs` quando houver Docker) e `pre-push` espelhando o harness, instalação via `uv add --dev` (wrapper PyPI, pin exato + hash em `uv.lock`), oráculo `f0-009-lefthook.sh` com 12–16 asserções (inclui `specs/README.md` e `git ls-files` inquebráveis, FR de cadência ADR-016 e declaração de fronteira ADR-017). Não cria `packages/` (011/012), não edita `.github/` (glob inclui `f0-009` sem edição), não usa `remotes` nem `self-update`, não escreve fora do repo.

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (pin exato + `uv.lock` hash + `min_version` + ordem fail-fast fixa, sem correção silenciosa sem modo de falha); **II** especificação precede código; **III** vermelho→verde em commits separados (vermelho volta a ser obrigatório — exceção M3 da auditoria 005–008 não se estende); **V** Lei Zero (trava versionada; `remotes` proibido = supply chain fechada); **VI** harness oráculo com 12–16 asserções novas nomeando FR, sem modificar oráculos 001–008 (ajustes de fronteira só via ADR prévia — ADR-017); **VIII** elo verificado (GitHub releases API + checksum `435aff51…` + `--help` executado 2026-09-04); **X** falha nomeia `FR-XXX`.

---

## Clarifications

### Session 2026-09-04 (resolvida — decisão do mantenedor: recomendação acatada)

- Q: Pin 2.1.11 (plano) ou 2.1.12 (latest, com fix fail-closed #1484)? → A: **2.1.12.** Desvio do plano registrado com Q1 da pesquisa como evidência (decisão CLARIFY 2026-09-04, recomendação do pesquisador acatada pelo mantenedor).
- Q: Hook reescreve arquivos (auto-correção) ou só reporta falha? → A: **só reporta (check-only).** Determinado pelo DNA: princípios I+VI+X e "observa, nunca corrige" — correção silenciosa esconde modificação do autor e gera estado não atribuído a commit humano. `stage_fixed` não é usado; `fail_on_changes` dispensado (nada escreve).
- Q: `trivy fs` em todo commit ou só no push? → A: **só no `pre-push` (+ skip documentado sem Docker).** Determinado pelo DNA: o valor P1 do item é feedback em segundos (US1) e o precedente 008 normalizou skip condicional — latência de scan não taxa iteração; cobertura antes do push + portão no CI.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Commit com lint quebrado é barrado em segundos (Priority: P1)

Mantenedor edita código Python com violação `ruff`, encena e commita. O hook `pre-commit` executa e reprova no job `ruff check`, nomeando a regra e o arquivo, antes de qualquer job posterior rodar.

**Why this priority**: é o valor central do item — feedback local em segundos, sem depender de CI.

**Independent Test**: introduzir violação `ruff` em arquivo-isca, rodar `lefthook run pre-commit`, observar reprovação nomeada; remover isca, observar verde.

**Acceptance Scenarios**:

1. **Given** `lefthook.yml` instalado e `lefthook` via `uv run`, **When** `lefthook run pre-commit` sobre staged com violação `ruff`, **Then** saída diferente de zero com o job `ruff` nomeado como causa.
2. **Given** staged limpo, **When** `lefthook run pre-commit`, **Then** saída zero após executar todos os jobs na ordem declarada.

---

### User Story 2 — Push executa o harness completo localmente (Priority: P2)

Antes de empurrar, o mantenedor quer a mesma rede do CI na máquina. O hook `pre-push` executa o harness `f0-*.sh` e só libera o push com tudo verde.

**Why this priority**: espelha o portão real (CI) localmente; sem ele, o primeiro feedback seria o runner.

**Independent Test**: `lefthook run pre-push` em repo verde → zero; com oráculo forjado vermelho em cópia descartável → diferente de zero (oráculo observa, teste usa ambiente isolado, nunca o repo real).

**Acceptance Scenarios**:

1. **Given** harness 9/9 verde, **When** `lefthook run pre-push`, **Then** saída zero.
2. **Given** `LEFTHOOK=0`, **When** qualquer `git commit`/`push`, **Then** ganchos silenciosamente ignorados (escape documentado; conformidade segue decidida pelo harness/CI, não pelo hook).

---

### User Story 3 — Clone limpo instala ganchos por procedimento único (Priority: P3)

Colaborador novo clona, sincroniza e instala ganchos com comandos documentados; `lefthook validate` + `check-install` confirmam sem julgamento.

**Why this priority**: sem setup de um comando, o hook é letra morta para terceiros.

**Independent Test**: em clone descartável, executar o procedimento documentado e rodar `validate` + `check-install` → ambos zero.

**Acceptance Scenarios**:

1. **Given** clone limpo com `uv.lock` íntegro, **When** procedimento de setup documentado, **Then** `lefthook validate` e `lefthook check-install` saem zero.
2. **Given** `lefthook.yml` com `min_version` acima do binário, **When** execução de hooks (`run`/`install`), **Then** o próprio lefthook recusa com erro de versão (exceção medida: `validate` não impõe — evidência `min_version_refusal.txt`, 2026-09-04).

---

### Edge Cases

- `git commit --no-verify`: bypassa ganchos por desenho do git — fora do escopo corrigir; o portão é o CI (010). O oráculo nunca asserir que bypass é impossível.
- `lefthook` não instalado na máquina: `lefthook.yml` existe mas ganchos não executam; o oráculo valida config via `uv run`, nunca exige instalação global.
- Docker ausente: job `trivy fs` (só no `pre-push`, FR-004) faz skip documentado (espelho da 008-FR-009 ⏭️), nunca falha.
- Corretores (`ruff --fix`/`format` com escrita) não rodam em hooks (FR-006 check-only) — `stage_fixed`/`fail_on_changes` não se aplicam; quem escreve arquivo é commit humano.
- `lefthook-local.yml` ausente: execução normal; presente e não-ignorado: o oráculo reprova (override pessoal não entra no histórico).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST fixar o pin do Lefthook em **2.1.12** (latest estável; desvio do plano §4 registrado: plano congelado em 2026-08-29 com 2.1.11, 2.1.12 publicada em 2026-08-28 com fix fail-closed #1484 — evidência `docs/plan/research/f0-009-lefthook.md` Q1, decisão CLARIFY 2026-09-04) e declará-lo em `lefthook.yml:min_version` e em `[dependency-groups] dev` com hash em `uv.lock`.
- **FR-002**: O sistema MUST prover `lefthook.yml` (YAML) na raiz do repo como única config — sem TOML/JSON alternativos, sem `remotes`, sem `self-update`.
- **FR-003**: O sistema MUST declarar jobs `pre-commit` fail-fast nesta ordem: `ruff check` → `ruff format --check` → `mypy --strict` → `pytest -q` → `pip-audit` — todos via `uv run`, saída ordenada e sem cor forçada.
- **FR-004**: O sistema MUST declarar job `trivy fs` exclusivamente no hook `pre-push`: executa quando Docker disponível, skip documentado quando ausente (nunca falha por ausência) — fora do `pre-commit`, cuja latência é orçamento de segundos (decisão CLARIFY 2026-09-04, precedente 008-FR-009).
- **FR-005**: O sistema MUST declarar hook `pre-push` executando o harness `for f in scripts/verify/f0-*.sh` (espelho do CI).
- **FR-006**: O sistema MUST operar todos os jobs `pre-commit` em modo somente-leitura (`ruff check`, `ruff format --check`, sem `--fix`, sem `stage_fixed`): o hook reporta a falha nomeada e o autor corrige em novo commit — correção pelo hook é proibida (decisão CLARIFY 2026-09-04, princípios I+VI+X).
- **FR-007**: O sistema MUST instalar ganchos por `lefthook install` documentado em procedimento único para clone limpo; `lefthook validate` e `lefthook check-install` MUST sair zero após o procedimento.
- **FR-008**: O sistema MUST preservar o escape `LEFTHOOK=0` documentado (ganchos ignorados; conformidade segue do harness/CI).
- **FR-009**: O sistema MUST NOT editar `.github/` — o glob `f0-*.sh` do CI inclui `f0-009` sem alteração (asserção espelho da FR-012/006).
- **FR-010**: O sistema MUST NOT escrever fora do repo: `lefthook install` só toca `.git/hooks/` (fora do índice por construção); nenhuma config global da máquina.
- **FR-011**: O sistema MUST asserir via oráculo próprio a FR de cadência (ADR-016): existência de `docs/plan/audit/f0-audit-005-008.md` com cabeçalhos do formato inaugural — sem relatório, o oráculo reprova.
- **FR-012**: O sistema MUST declarar no PLAN o impacto de fronteira (tabela Q·fronteira da pesquisa: FR-012/004, FR-015/005, FR-014/006, FR-014/007, FR-013/008) e SÓ ajustar esses pontos via ADR prévia ao merge (ADR-017) — pós-fix silencioso com regeneração de manifest é proibido.
- **FR-013**: O sistema MUST prover oráculo `scripts/verify/f0-009-lefthook.sh` com 12–16 asserções sob o contrato `oracle-cli.md` (códigos 0/1/2, `--quiet`/`--list`, linha por REQ-ID, determinismo, somente leitura, nunca executa os jobs).
- **FR-014**: O sistema MUST asserir `sha256sum -c scripts/verify/manifest.sha256` com a 9ª linha (`f0-009`) e executar `--quiet` de `f0-001…f0-008` (self-check total, ADR-015a/e).
- **FR-015**: `specs/README.md` MUST conter `009` com `lefthook` `✅` e hash do commit de convergência (inquebrável em escala, padrão 007/008).
- **FR-016**: `tasks.md` MUST fechar com zero tarefas `[ ]` (CONVERGE fecha a lista, ADR-015d, asserido pelo próprio oráculo) e o par vermelho→verde MUST viver em commits separados (vermelho em commit `test(harness)` próprio — exceção M3 não se estende).

### Key Entities *(include if feature involves data)*

- **lefthook.yml**: config versionada do orquestrador; atributos: `min_version`, jobs `pre-commit`/`pre-push`, modos de falha; sem `remotes`.
- **Hook job**: unidade executável (`run` via `uv run`); atributos: ordem, `glob`/`tags`, modo somente-leitura, skip condicional.
- **Asserção de fronteira**: regra de oráculo anterior que proíbe artefato futuro; relaciona-se com o item novo pela tabela de impacto (ADR-017).
- **Dívida de cadência**: relatório de auditoria devido; relaciona-se com a spec que seria a 5ª (ADR-016).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Mantenedor com staged contendo violação de lint recebe reprovação nomeada localmente antes de qualquer push, sem aguardar runner.
- **SC-002**: Clone limpo executa o procedimento documentado e obtém `validate` + `check-install` verdes na primeira tentativa.
- **SC-003**: Harness completo executa 9/9 verde e o manifest valida 9/9 linhas via comando único.
- **SC-004**: Bypass local (`--no-verify`, `LEFTHOOK=0`) permanece possível e documentado, sem degradar a decisão de conformidade (que segue do harness/CI).
- **SC-005**: Zero tarefas abertas em `tasks.md` e par vermelho→verde em commits separados no histórico.
- **SC-006**: Oráculo executa duas vezes sobre o mesmo estado com saída byte-idêntica e cada execução abaixo de 5 segundos (espelho FR-014/005); latência dos jobs `pre-commit` é medida e registrada na evidência verde (teto operacional calibrado por medição, nunca inventado — lição ADR-013).

## Assumptions

- Pin decidido no CLARIFY: **2.1.12** (FR-001, Clarifications 2026-09-04); `min_version` acompanha.
- Instalação via wrapper PyPI `uv add --dev lefthook==<pin>` (padrão 005–008); binário manual só como reserva documentada.
- `trivy fs` condicional ao Docker local (espelho 008-FR-009); validação plena com Docker fica à 010/015 (B2 da auditoria).
- `lefthook-local.yml` não existe; se mencionado no futuro, entra no `.gitignore` antes de existir (Lei Zero).
- Validação de mensagem de commit (commitlint) é 010, não 009.

## Contratos

### Entregue por este item

- `lefthook.yml` orquestrando 005+006+007+008 (jobs + modos de falha + `min_version`).
- `lefthook` em `[dependency-groups] dev` com hash em `uv.lock` (fonte única, sem global).
- Oráculo `f0-009-lefthook.sh` (12–16 asserções, identidade FR↔asserção) + 9ª linha do manifest + `specs/README.md` `009 ✅` + FR de cadência (ADR-016).
- Ajustes de fronteira em 004–008 **somente** via ADR prévia (ADR-017), com esta spec como primeira execução do procedimento.

### Recebido de itens anteriores

- De **008**: ferramentas a orquestrar (`ruff` + `mypy --strict` + `pytest` + `pip-audit` + `trivy fs`) + skip-sem-Docker como padrão (o `lefthook.yml` é entregue por este item, não recebido).
- De **007/006/005**: comandos canônicos (`ruff check`, `ruff format --check`, `mypy --strict`, `pytest -q`) e padrão de oráculo (identidade, inquebráveis, CONVERGE).
- Da **auditoria 005–008**: relatório vigente (FR-011), exceções A1/M3 como proibições ativas, B2 como skip condicional herdado.
- Das **ADR-016/017**: trava de cadência e procedimento de fronteira como FRs próprias.

### Transferido a itens posteriores

- À **010** (`0.14` CI completo + branch protection): ganchos locais como conveniência documentada + bypass `--no-verify` como ameaça a neutralizar via required checks; validação de mensagem de commit; Trivy com Docker.
- Às **011/012** (`packages/core|cli`): primeiro código de produção MUST manter ganchos verdes (fronteira inversa declarada desde já).
- À **015** (`0.8` docker-compose): `trivy image` pleno com Docker verificado.
