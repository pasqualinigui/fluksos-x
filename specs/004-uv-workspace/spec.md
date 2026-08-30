# Feature Specification: UV workspace monorepo — base física do motor

**Feature Branch**: `004-uv-workspace`

**Created**: 2026-08-30

**Status**: Draft

**Input**: User description: "Fase 0, item 0.1 (004/016 na ordem de execução): UV workspace monorepo — base física do motor com pyproject.toml virtual, uv.lock versionado e .venv gerenciado. Escopo restrito sem Ruff/MyPy/Pytest/packages (estes são specs 005–009). SDD+TDD determinístico."

**Item do plano**: 0.1 (§17 Fase 0, Itens 0.1–0.12) · **Ordem de execução**: 004 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-004-uv-workspace.md` (decisões D1–D10, Q1–Q10, nenhuma NEEDS CLARIFICATION)
**Contrato de entrada**: `specs/003-ci-minimo/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-009, ADR-011) + `docs/plan/implementation_plan.md` §§3–4, 15, 17

---

## Contexto

O motor prometido no plano (§1, §15) é um monorepo com múltiplos pacotes (`packages/core`, `cli`, `indexer`, `memory`, `agents`, `observability`, `guardian`) que compartilham um único lockfile determinístico e um único ambiente virtual — análogo ao que `pnpm` é para Node. Até aqui o repositório não possui nenhum `pyproject.toml`, `uv.lock`, `.venv` ou `packages/` (verificado disco em Q1/Q7). Toda ferramenta de qualidade (Ruff 0.16.5, MyPy 2.3.1, Pytest 9.1.1, Lefthook 2.1.11, pip-audit, Trivy) e todo pacote só podem existir **depois** desta base — a escada de dependências (constitution Additional Constraints) proíbe verificar com ferramenta que ainda não existe.

Este item entrega exclusivamente a **base física**: root virtual `pyproject.toml` + `tool.uv.workspace` + `uv.lock` + `.venv` + `.python-version`. Não cria `packages/*`, não configura linter, type checker, testes, hooks ou CI além do que `003` já entregou. Cada pacote futuro nasce em sua própria spec com ciclo completo `RESEARCH → CONVERGE`. A pesquisa Q1–Q10 já fixou pins (`uv 0.12.7`, `uv_build>=0.12.7,<0.13`, `requires-python >=3.12,<3.14`, `members=["packages/*"]`) e leis de versionamento de lockfile (D2) para que os itens 005–016 escalem sem reescrever.

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (single `requires-python` interseção, lock universal), **II** especificação precede código, **III** vermelho→verde preservado, **V** Lei Zero (trava versionada, `.venv` nunca rastreado), **VI** harness oráculo com ~10–14 asserções novas, **VIII** elo verificado (docs.astral.sh + PyPI + help local), **X** observabilidade (falha nomeia FR).

---

## Clarifications

### Session 2026-08-30

- Q: Criar `packages/core/` e `packages/cli/` vazios já em 004 para adiantar? → A: **Não.** Antecipa responsabilidade de 006/007, viola SDD e cria `pyproject.toml` sem spec. 004 entrega só root virtual; membros surgem nos itens que os exigem (D8).
- Q: Adicionar `.venv/` explícito ao `.gitignore` raiz? → A: **Não.** `.venv` já é ignorado via `.venv/.gitignore` interno (`*`) criado por `uv sync`; e `.gitignore` raiz já não introduz `*.lock` (D3). Modificar `.gitignore` aqui violaria regra 5 (oráculo de 001).
- Q: Impor `uv sync --locked` / `--frozen` já em 004? → A: **Não.** No bootstrap o primeiro `uv sync` precisa materializar `uv.lock` sem flag; `--locked` entraria em paradoxo. Política `--frozen` é de CI (010) que consome artefato de 004.
- Q: Criar `pylock.toml` (PEP 751) ou exportar SBOM agora? → A: **Não.** `uv.lock` é a fonte de verdade; `uv export --format pylock.toml|cyclonedx` é capability de 013 sem config extra.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Ambiente reprodutível com um comando (Priority: P1)

Desenvolvedor clona o repositório em máquina limpa (sem `.venv`) e precisa obter um ambiente funcional idêntico ao de qualquer outro clone, com um único comando, sem ativar manualmente e sem divergência entre Linux/macOS/Windows.

**Why this priority**: é a base física de todo o bootstrap. Sem `uv.lock` + `.venv` determinísticos, cada item seguinte (Ruff, MyPy, Pytest, agentes) validaria sobre ambiente divergente — TDD não seria auditável.

**Independent Test**: em clone limpo, executar `uv sync` (ou `uv run --help`) e verificar que `.venv/bin/python` existe, `uv.lock` é TOML válido e segundo `uv sync` não altera hash de `uv.lock` (idempotência D10). Remover `.venv` e repetir prova descartabilidade.

**Acceptance Scenarios**:

1. **Given** clone sem `.venv` nem `uv.lock` pré-existente além do versionado, **When** executa `uv sync`, **Then** `.venv/` é criado com interpretador `3.12` e `uv.lock` permanece TOML válido e com `requires-python` interseção.
2. **Given** `.venv` já existe, **When** executa `uv run python --version`, **Then** saída é `3.12.x` sem necessidade de `source .venv/bin/activate` (gerenciamento transparente).
3. **Given** `uv.lock` versionado no índice, **When** remove `.venv` (`rm -rf .venv`) e executa `uv sync` de novo, **Then** ambiente é recriado idêntico e `git status --porcelain` não lista `.venv/` como untracked.
4. **Given** dois `uv sync` consecutivos sem mudança em `pyproject.toml`, **When** compara `sha256sum uv.lock` antes/depois, **Then** hashes coincidem (idempotência).

---

### User Story 2 — Workspace pronto para `packages/*` sem fricção (Priority: P2)

Arquiteto precisa criar o próximo pacote (`packages/core` em 006 ou `packages/cli` em 007) sem reescrever `pyproject.toml` root, sem duplicar lockfiles e sem quebrar resolução — o glob `packages/*` já deve descobrir membros automaticamente e compartilhar `uv.lock` + `.venv`.

**Why this priority**: valida escalabilidade prometida (D4/D8). Se 004 exigisse editar root por pacote ou criar lock por pacote, cada spec futura reescreveria a base.

**Independent Test**: inspeção estática de `pyproject.toml` root + simulação de membro futuro (criar `packages/_probe/pyproject.toml` temporário e verificar `uv sync` o descobre; remover após teste).

**Acceptance Scenarios**:

1. **Given** `pyproject.toml` root, **When** lido, **Then** contém `[tool.uv.workspace] members = ["packages/*"]` e não contém `exclude` ativo (D4).
2. **Given** workspace com zero membros casados (estado pós-004), **When** executa `uv sync`, **Then** `uv.lock` é válido mesmo vazio e `.venv` existe — root virtual já é membro implícito.
3. **Given** membro futuro `packages/core` com `requires-python = ">=3.12,<3.14"`, **When** declarado e executado `uv sync`, **Then** resolução usa interseção single `requires-python` sem conflito (workspaces.md).
4. **Given** dependência inter-membro futura, **When** declarada, **Then** usa `tool.uv.sources.<nome> = { workspace = true }` (não `path`), e `uv.lock` unifica versões.

---

### User Story 3 — Cadeia de suprimentos versionada e Lei Zero preservada (Priority: P3)

Mantenedor precisa garantir que a trava de dependências seja auditável (PR que altera `pyproject.toml` altera `uv.lock` junto) e que nenhum artefato efêmero ou segredo entre no histórico, sem quebrar oráculo de 001.

**Why this priority**: princípio **V** — histórico não se corrige sem incidente. `uv.lock` versionado é supply-chain security (implementation_plan §3 addendum §9 item 10); `.venv` versionado seria vazamento de binários.

**Independent Test**: `git check-ignore` / `git status --porcelain` + inspeção `.gitignore` contra `*.lock`.

**Acceptance Scenarios**:

1. **Given** `.gitignore`, **When** inspecionado, **Then** não contém `*.lock` nem `uv.lock` (D3 de 001, D7 de 004) — `uv.lock` é rastreado.
2. **Given** `uv.lock` existente, **When** executa `git check-ignore -q uv.lock`, **Then** saída `1` (não ignorado).
3. **Given** `.venv/` existente, **When** executa `git check-ignore -q .venv` ou `git status --porcelain | grep .venv`, **Then** `.venv` é ignorado (via `.venv/.gitignore` interno `*`).
4. **Given** CI `003` (`ci.yml` job `verify`), **When** `f0-004-uv-workspace.sh` é acrescentado, **Then** `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` o inclui automaticamente sem editar `ci.yml`.

---

### Edge Cases

- **Máquina com `uv 0.12.1` instalado.** `0.12.1` < pin `0.12.7`; `uv sync` com `uv_build>=0.12.7,<0.13` em `build-system.requires` deve falhar ou advertir até `uv self update` — local deve convergir ao pin, não o pin ao local (D5).
- **`.python-version` ausente ou com `3.11`.** `uv sync` deve resolver `requires-python >=3.12` e reprovar ambiente fora da interseção; `.python-version` `3.12` fixa determinismo local mas não substitui `requires-python` (D5).
- **Desenvolvedor executa `uv pip install` manual dentro de `.venv`.** `uv sync` subsequente deve remover pacotes estranhos (exact sync por padrão) — `.venv` volta a refletir `uv.lock` (sync.md D10).
- **Re-tentativa sem rede.** `uv sync --frozen` após lock versionado deve recriar `.venv` sem resolver novamente; sem lock, deve falhar explicitamente (não silenciosamente).
- **Tentativa de criar `packages/` sem `pyproject.toml` lá dentro.** `uv sync` deve falhar com mensagem nomeando diretório faltante (workspaces.md: every directory matched must contain `pyproject.toml`).
- **`git add .venv` acidental.** `git check-ignore` deve impedir rastreamento; `f0-004` deve reprovar se `.venv` aparecer em `git ls-files`.

---

## Requirements *(mandatory)*

### Functional Requirements

**Artefato raiz e descoberta**

- **FR-001**: O sistema MUST prover `pyproject.toml` na raiz do repositório, em TOML válido, com `[project] name = "fluksos-x"` e `version = "0.1.0"`.
- **FR-002**: `pyproject.toml` MUST declarar `requires-python = ">=3.12,<3.14"` como fonte de verdade do workspace (interseção single para todos os membros futuros).
- **FR-003**: `pyproject.toml` MUST declarar `[build-system] requires = ["uv_build>=0.12.7,<0.13"]` e `build-backend = "uv_build"` (pin canónico 0.12.7, 2026-08-30; docs snippet `uv_build>=0.12.7,<0.13`).
- **FR-004**: `pyproject.toml` MUST declarar `[tool.uv.workspace] members = ["packages/*"]` sem `exclude` ativo em 004 (D4; `exclude` só quando membro precisar ser excluído).
- **FR-005**: O sistema MUST prover `.python-version` na raiz contendo `3.12` (ou `3.12.x` compatível) quando criado por `uv init`; se ausente, `requires-python` ainda determina `3.12`.

**Trava e ambiente**

- **FR-006**: O sistema MUST prover `uv.lock` ao lado de `pyproject.toml`, em TOML válido, universal (cross-platform), gerenciado por `uv` e versionado (não ignorado por `.gitignore`).
- **FR-007**: `uv.lock` MUST NOT ser editado manualmente fora de `uv lock`/`uv sync`/`uv add` — harness valida que `uv.lock` é parseável e que `uv lock --check` passa (quando `uv` disponível).
- **FR-008**: Após `uv sync`, o sistema MUST prover `.venv/` ao lado de `pyproject.toml` com interpretador executável (`.venv/bin/python` em POSIX) e com `.venv/.gitignore` interno contendo `*`.
- **FR-009**: `.venv/` MUST ser descartável e regenerável: `rm -rf .venv && uv sync` MUST recriar ambiente idêntico sem alterar `uv.lock` (D10; idempotência).

**Git e Lei Zero (fronteira com 001)**

- **FR-010**: `.gitignore` MUST NOT conter `*.lock` nem `uv.lock` (D3 de 001, D7 de 004) — `uv.lock` DEVE ser rastreado. Violar reprova.
- **FR-011**: `.venv/` MUST ser ignorado por git (via `check-ignore`); `uv.lock` MUST NOT ser ignorado. Harness verifica ambos com `git check-ignore -q`.
- **FR-012**: O sistema MUST NOT modificar `.gitignore` neste item além do que `001` já fixou (regra 5: um item nunca modifica oráculo de anterior). Qualquer diff em `.gitignore` em `004` reprova salvo ADR.

**Escalabilidade e fronteira de escopo**

- **FR-013**: O sistema MUST NOT criar `packages/` nem qualquer `packages/*/pyproject.toml` em 004 (D8). Membros são criados pelos itens que os exigem (006–009 etc.) — antecipar reprova.
- **FR-014**: O sistema MUST NOT introduzir `ruff`, `mypy`, `pytest`, `lefthook`, `pip-audit`, `trivy` ou qualquer tool de 005–016 em 004 (escada de dependências, constitution Additional Constraints).
- **FR-015**: `tool.uv.sources` futuro para dependência inter-membro MUST usar forma `{ workspace = true }` (não `{ path = ... }`) quando workspace estiver ativo — contrato documentado, não verificado por harness em 004 por ausência de membros.

**Harness e CI**

- **FR-016**: O sistema MUST prover oráculo `scripts/verify/f0-004-uv-workspace.sh` com 10–14 asserções, exit `0` conforme / `1` violação / `2` uso, `--quiet` só violações, uma linha por asserção identificada por FR, sem modificar `f0-001` nem `f0-003` (VI).
- **FR-017**: CI `003` (`/.github/workflows/ci.yml` job `verify`) MUST incluir `f0-004` automaticamente via glob `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` sem exigir edição de `ci.yml` em 004.

### Key Entities

- **Workspace root**: `pyproject.toml` na raiz + `uv.lock` + `.venv` + `.python-version`. Único ponto de verdade para `requires-python` e single lockfile. Atributos: `name`, `version`, `requires-python`, `build-system.requires`, `tool.uv.workspace.members`.
- **uv.lock (trava universal)**: TOML humano-legível específico de `uv`, captura resolução cross-platform (markers OS/arch/Python). Versionado; não `pylock.toml` em 004 (exportável em 013). Mutável só via `uv`.
- **Project environment (.venv)**: diretório `.venv` com interpretador `3.12` isolado, instalado por `uv sync`/`uv run`. Efêmero, ignorado, descartável; criado automaticamente se ausente.
- **Workspace member (futuro)**: pacote sob `packages/*` com `pyproject.toml` próprio e `requires-python` compatível com interseção do root. Em 004, conjunto vazio mas descoberta já ativa.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Desenvolvedor em clone limpo obtém ambiente funcional com um único `uv sync` em menos de 2 minutos (rede mediana), sem ativar manualmente e sem editar arquivo.
- **SC-002**: Segundo `uv sync` consecutivo sem mudança em `pyproject.toml` não altera `uv.lock` (hash idêntico) em 100% das execuções — idempotência verificável por `sha256sum`.
- **SC-003**: `rm -rf .venv && uv sync` recria `.venv` funcional em 100% das tentativas e mantém `uv.lock` inalterado; `git status --porcelain` nunca lista `.venv/`.
- **SC-004**: Adicionar `packages/_probe` com `pyproject.toml` `requires-python` compatível faz `uv sync` descobrir membro sem editar root além do glob já existente.
- **SC-005**: 100% dos clones validam que `uv.lock` está rastreado (`git check-ignore` negativo) e que `.venv` está ignorado (`check-ignore` positivo) — Lei Zero automatizada.
- **SC-006**: Harness `f0-004` executa em menos de 5 segundos e reporta veredito com FR violado quando provocado (ex.: remover `uv.lock` ou corromper `requires-python`).
- **SC-007**: CI `003` passa a incluir `f0-004` sem alteração em `ci.yml` — push com `f0-004` verde mantém check `verify` verde; push com `f0-004` vermelho torna `verify` vermelho.
- **SC-008**: Nenhum artefato de 005–016 (Ruff, MyPy, Pytest, `packages/`) aparece no diff de 004 — fronteira escopo preservada em 100% da verificação.

## Assumptions

- `uv 0.12.7` como pin canónico (§4 do plano, PyPI 2026-08-30); máquina com `0.12.1` deve atualizar via `uv self update` — projeto não rebaixa pin para acomodar local desatualizado (D5).
- Python `3.12` família cobre `3.12.3` local e `3.12.14` no runner `setup-python@v7`; `requires-python >=3.12,<3.14` é a faixa suportada; `3.13` só entra com matrix em 010.
- `packages/*` glob é suficiente para §15 (5–7 pacotes); `exclude` só será introduzido se membro precisar ser excluído sem mover diretório.
- `uv.lock` formato é específico de `uv` e não intercambiável (`pylock.toml` PEP 751 é export, não fonte de verdade) — layout.md.
- `.venv/.gitignore` com `*` é criado automaticamente por `uv sync`; não é necessário listar `.venv` no `.gitignore` raiz, mas `git status` deve comprovar que está ignorado.
- Spec futura `005` (Pytest) introduzirá `[dependency-groups] dev` no root; `004` deixa `dependencies = []` mínimo para manter lock vazio válido.

## Dependencies

- `001` Git + branching strategy — `.gitignore` D1/D3 aprovados; regra `5` (hash criptográfico) impede reescrever `.gitignore` em 004.
- `003` CI mínimo — `ci.yml` job `verify` estável com `for f in scripts/verify/f0-*.sh` já cobre `f0-004` sem edição.
- `uv 0.12.7` e Python `3.12` — elos verificados em `docs/plan/research/f0-004-uv-workspace.md` Q5/Q6 contra PyPI + docs.astral.sh + `uv --help` local.
- ADR-011 mapa 16 posições fixa `004 → 0.1` logo após `003`; itens `005` (Pytest), `006` (Ruff), `007` (MyPy) consomem workspace sem reescrevê-lo.

## Contratos expostos para itens seguintes

| Consumidor | O que recebe de 004 |
|---|---|
| **005 Pytest 9.1.1** | Root para `[dependency-groups] dev` e ponto de montagem `packages/core` |
| **006 Ruff 0.16.5** | `pyproject.toml` onde `[tool.ruff]` coexistirá sem conflito com `[tool.uv]` |
| **007 MyPy 2.3.1** | `requires-python` single já fixado; `mypy.ini` futuro lê `packages/*` |
| **010 CI completo** | `uv.lock` para `uv sync --frozen` determinístico; `verify` já inclui `f0-004` |
| **013 Release** | `uv build` + `uv export --format pylock.toml|cyclonedx` sem config extra |
| **014 Renovate** | `uv_build>=0.12.7,<0.13` pin para agrupamento e automerge |

## Out of Scope

- Criação de `packages/core`, `packages/cli` ou qualquer membro (itens 006+).
- Configuração de `ruff.toml`/`[tool.ruff]`, `mypy.ini`, `pytest`, `lefthook.yml`, `pip-audit`, `trivy` — todos pós-004.
- Geração de `pylock.toml`, `requirements.txt` ou SBOM — capability de 013.
- Bloqueio `uv sync --locked`/`--frozen` em CI — política de 010.
- Suporte a Python `3.11` ou `3.14` — fora de `requires-python` pinado.
