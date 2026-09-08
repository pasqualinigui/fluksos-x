# Feature Specification: Atualização automática de dependências — bot, agrupamento e portão verde

**Feature Branch**: `feature/f0-dependency-updates`

**Created**: 2026-09-08

**Status**: Draft

**Input**: User description: "Fase 0, item 0.16 (014/016 na ordem de execução): atualização automática de dependências — bot com agrupamento e harness verde obrigatório no merge" (SPECIFY aplicado deterministicamente sobre o research vinculante)

**Item do plano**: 0.16 (§17 Fase 0, Emenda 1) · **Ordem de execução**: 014 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-014-dependency-updates.md` (Q1–Q9, decisões D1–D7, hierarquia P0–P3 da ADR-025, pergunta-padrão de ambiente da ADR-027 §5)
**Contrato de entrada**: `specs/013-release-automation/spec.md` › Contratos (Transferido: pipeline de release como validador; condição de saída do override `click`; lugar do `pip-audit` no `lefthook.yml`; trava exportada como base) + `specs/010-ci-completo/spec.md` › Contratos (10 checks, commitlint, proteção sem-bypass, `strict:true`, auto-merge servidor — ADR-035) + `specs/008-pip-audit-trivy/spec.md` (auditoria sem arquivo de configuração; FR-002 como invariante) + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-015, ADR-017, ADR-020, ADR-025, ADR-031, ADR-032, ADR-034, ADR-035) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem cadeia de suprimentos travada (`uv.lock` versionado, hash-pinning) e auditoria bloqueante (`pip-audit` + Trivy no CI) — **mas nenhuma forma de mover as dependências para frente**. Hoje "subiu merge, mudou versão" depende de memória humana (lacuna 6 da ADR-009). Este item entrega **exclusivamente**: configuração versionada de bot de atualização (ecossistemas `uv` + `github-actions`), agrupamento de updates com revisão humana para `major`, automerge condicionado ao portão verde, mensagens de commit compatíveis com Conventional Commits e com o versionamento semântico, e oráculo `f0-014` com asserções. Não cria `docker-compose` (**015**), `docs/tree.md` (**016**), supressão de vulnerabilidade (proibida — Q5), `lockFileMaintenance` estilo Renovate (sem equivalente nativo), merge queue, nem OSV alerts para transitivos.

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (bot sem julgamento: agrupa por regra, mergeia por exit code); **II** especificação precede código; **III** vermelho→verde em commits separados; **IV** o formato dos artefatos (config do bot, workflow de automerge) declarado antes de existir; **V** Lei Zero (bot nativo do servidor: nenhuma credencial nova, nenhum serviço terceiro com escrita); **VI** harness é o oráculo, e a fronteira dos itens anteriores só se ajusta por ADR prévia; **VIII** escolha do bot e cada comportamento externo verificados com evidência executada em `docs/plan/research/f0-014-dependency-updates.md`; **IX** o item atualiza **este** motor e não presume nada sobre stacks-alvo; **X** falha nomeia `FR-XXX` e a evidência observada.

**Restrição estrutural que molda o item** (research Q4+Q7): os commits do bot entram no histórico da linha única, sobre a qual o PSR deriva versão — por isso o prefixo de commit do bot MUST ser não-liberável; e o gate de vulnerabilidade em `pre-commit` converte "corrigir a vulnerabilidade" em operação impossível (ADR-034 §6) — por isso o lugar do `pip-audit` no hook é decisão deste item, pelo procedimento ADR-017.

## Clarifications

### Session 2026-09-08

- Q: Dependabot ou Renovate? → A: **Dependabot** (research Q1). Nativo no servidor, zero credencial nova, compõe com ADR-035 (merge como consequência do exit code). Renovate fica como alternativa registrada com condição de reabertura (CVE transitivo que prove o nativo insuficiente — evidência nova, nunca releitura).
- Q: `pip-audit` fica no `pre-commit` ou move para `pre-push`? → A: **move para `pre-push`** (research Q7). Harmoniza com a forma convergida do `trivy` (FR-004 da 009); preserva fail-fast local (hermético/rápido no commit, externo/completo no push). Quebra `f0-009` FR-003 por desenho → procedimento ADR-017 fixo (7ª execução).
- Q: Ecossistema `github-actions` entra nesta spec ou actions seguem pinadas à mão? → A: **entra, em grupo separado, com tripwire** (research Q3+Q9). A forma SHA+comentário é julgada pelos 10 checks no primeiro PR real do bot; fallback pré-registrado (`ignore` em actions, pin manual) sem nova deliberação.
- Q (clarify): Quais níveis de semver o automerge pode fundir sem ato humano? → A: **minor+patch com automerge, major isolado** — confirma FR-002/US-1: o portão verde decide; commits não-liberáveis; sem revisão prévia por julgamento.
- Q (clarify): Updates de segurança no mesmo fluxo semanal ou em via expressa? → A: **via expressa separada** — grupo `security` próprio, cadência mais rápida, mesmo portão verde e mesmo automerge; CVE parado já bloqueou a `main` uma vez (013) e não espera o grupo semanal.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Updates triviais entram sozinhos, pelo portão (Priority: P1)

Toda semana o bot abre PRs agrupados de `minor`/`patch` das dependências de desenvolvimento. Cada PR roda os 10 checks obrigatórios; verde, o servidor mergeia sem intervenção; vermelho, fica parado para humano ler.

**Why this priority**: é a lacuna 6 da ADR-009 ("subiu merge, mudou versão depende de memória"). Sem isto, o item não existe.

**Independent Test**: com um bump real disponível, conferir que o PR agrupado é aberto, que os checks executam sobre ele e que o merge só ocorre no verde.

**Acceptance Scenarios**:

1. **Given** bumps `minor`/`patch` disponíveis nas dependências de desenvolvimento, **When** o bot executa no schedule, **Then** um único PR agrupado é aberto com manifesto + lock coerentes.
2. **Given** um PR de bot com os 10 checks verdes, **When** o automerge avalia, **Then** o merge acontece sem ato humano.
3. **Given** um PR de bot com qualquer check vermelho, **When** o automerge avalia, **Then** nada mergeia e o vermelho nomeia a causa.
4. **Given** uma correção de segurança disponível, **When** o bot executa, **Then** ela trafega no grupo `security` em cadência diária (não espera o grupo semanal) e mergeia sob o mesmo portão verde.

---

### User Story 2 — `major` nunca entra escondido (Priority: P1)

Atualização `major` (ou de action pinada por SHA) chega em PR próprio, unitário, sem automerge, para revisão humana deliberada.

**Why this priority**: um `major` escondido em grupo é bypass de revisão por agregação — o oposto do que o portão existe para impedir.

**Independent Test**: com um `major` disponível, conferir PR isolado, sem merge automático mesmo verde.

**Acceptance Scenarios**:

1. **Given** um bump `major` disponível, **When** o bot executa, **Then** ele NÃO está no grupo `dev-minor-patch` e sim em PR próprio sem automerge.
2. **Given** um PR de `major` com checks verdes, **When** avaliado, **Then** ele aguarda aprovação/ato humano.

---

### User Story 3 — Bump não queima versão nem quebra convenção (Priority: P2)

Todo commit de bot usa prefixo não-liberável e passa no `commitlint`: atualizar dependência jamais consome número de versão do PSR nem quebra o histórico convencional.

**Why this priority**: a 013 deriva versão do histórico; um prefixo liberável transformaria cada bump num release acidental.

**Independent Test**: inspecionar mensagens de commits do bot contra a gramática de `CONTRIBUTING.md` e simular `semantic-release version --print` antes/depois (sem incremento).

**Acceptance Scenarios**:

1. **Given** commits de bot integrados, **When** a próxima versão é consultada, **Then** nenhum incremento é derivado deles.
2. **Given** um PR de bot, **When** o job `commitlint` executa, **Then** ele aprova o intervalo.

---

### User Story 4 — Portão vermelho de CVE volta a ser operável (Priority: P2)

Com o `pip-audit` no `pre-push`, corrigir uma vulnerabilidade futura volta a ser uma sequência executável (vermelho em commit separado → verde), sem `--no-verify`.

**Why this priority**: é a dívida herdada da ADR-034 §6 — o teorema que este item foi criado para pagar.

**Independent Test**: simular vulnerabilidade conhecida (sem introduzi-la de verdade) é inviável por construção; o teste é estrutural — conferir posição do gate + ordem fail-fast + `LEFTHOOK=0` ainda documentado como escape não-vinculante.

**Acceptance Scenarios**:

1. **Given** o `lefthook.yml`, **When** inspecionado, **Then** `pip-audit` está no `pre-push` (com `trivy` + harness) e ausente do `pre-commit`.
2. **Given** o `pre-commit`, **When** inspecionado, **Then** a ordem fail-fast ruff → format → mypy → pytest está preservada.

---

### Edge Cases

- **PR de bot contra lock vulnerável**: reprova no `audit` como qualquer PR — comportamento correto, nunca suprimido (Q5; FR-002 da 008 é invariante).
- **Bot reescreve pin SHA de action para forma tag-only**: o primeiro PR real prova; vermelho na forma aciona o fallback pré-registrado (`ignore` em actions), sem nova deliberação.
- **Upstream do PSR relaxa `click~=8.1.0` entre research e verde**: re-verificado no verde (Q6); se disparar, a remoção entra por esta spec via ADR-017.
- **Semana sem updates**: nenhum PR é aberto e nada falha — ausência de trabalho não é defeito.
- **Dois PRs de bot concorrentes com conflito no lock**: rebase pelo bot + re-execução dos checks sobre o resultado (`strict:true`); merge só do estado testado (ADR-035 §1).
- **Bot abre PR durante freeze de release (tag `v*` em voo)**: sem interlock — PRs de bot seguem o fluxo normal de PR; a tag dispara release do estado mergeado até então.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST declarar o bot em configuração versionada para o ecossistema `uv` (diretório raiz, schedule semanal), cobrindo manifesto + lock a cada bump.
- **FR-002**: O sistema MUST agrupar updates `minor`/`patch` das dependências de desenvolvimento em grupo único e MUST excluir `major` do agrupamento e do automerge (PR próprio, revisão humana). Updates de segurança MUST trafegar em grupo próprio com cadência diária (`daily`), sob o mesmo portão verde e o mesmo automerge — nunca presos ao grupo semanal.
- **FR-003**: O sistema MUST declarar o ecossistema `github-actions` em separado, preservando a forma de pin por resumo criptográfico + comentário de versão em todo bump.
- **FR-004**: O sistema MUST prefixar toda mensagem de commit do bot com tipo não-liberável (`build(deps)`), de modo que bumps MUST NOT derivar incremento de versão no PSR e MUST passar no `commitlint`.
- **FR-005**: O sistema MUST prover automerge exclusivamente como consequência do portão: apenas PRs de bot, apenas via merge simples, apenas com os checks obrigatórios verdes — e MUST NOT mergear vermelho por nenhuma via.
- **FR-006**: O sistema MUST NOT conter supressão de vulnerabilidade em nenhum arquivo versionado (sem `--ignore-vuln`, sem `pip-audit.toml`, sem `[tool.pip-audit]`) — a política é agrupar + exigir verde.
- **FR-007**: O sistema MUST manter o override mínimo `click>=8.3.3,<8.5.0` com a trava resolvendo `click >= 8.3.3`, re-verificado no verde; se o upstream relaxar o teto, a remoção entra por esta spec (herança da ADR-034 §5).
- **FR-008**: O sistema MUST executar o `pip-audit` local no `pre-push` (com `trivy` + harness) e MUST NOT o executar no `pre-commit`, preservando a ordem fail-fast do `pre-commit` — via procedimento ADR-017 sobre `f0-009` FR-003.
- **FR-009**: O sistema MUST prover oráculo `scripts/verify/f0-014-*.sh` sob o contrato `oracle-cli.md` (identidade FR↔asserção documentada, determinismo, somente leitura, self-check `f0-001…f0-013` **em série** conforme ADR-031, 14ª linha do manifest).
- **FR-010**: `specs/README.md` MUST conter `014` `✅` com hash do commit de convergência, e `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados.
- **FR-011**: O sistema MUST registrar o fallback das actions (forma SHA quebrada → `ignore` + pin manual) como tripwire com dono e sem nova deliberação, em bloco de comentário grepeável em `.github/dependabot.yml`, julgado pelos 10 checks no primeiro PR real do bot.

### Key Entities *(include if feature involves data)*

- **Update PR**: unidade de trabalho do bot; atributos: grupo, ecossistema, semver-level, estado do portão. Não mergeia sem verde.
- **Group**: conjunto de bumps que viajam num PR só; `major` nunca pertence a grupo com automerge.
- **Merge Gate**: os 10 required checks sobre `strict:true`; único decisor de merge (ADR-035).
- **Lock Pair**: coerência manifesto + `uv.lock` em todo PR de bot (pins `==` movem os dois juntos).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: PRs agrupados `minor`/`patch` abertos no schedule com manifesto + lock coerentes em 100% dos casos; security em via própria sem esperar o grupo semanal.
- **SC-002**: Zero merges de bot sobre vermelho; zero `major` em grupo com automerge.
- **SC-003**: Zero incremento de versão derivado de commits de bot; 100% dos intervalos de bot aprovados no `commitlint`.
- **SC-004**: Zero supressão em arquivo versionado; PR contra lock vulnerável reprova no `audit` (comportamento, não configuração).
- **SC-005**: Harness 14/14 + manifest 14/14 + `tasks.md` zero `[ ]` + par vermelho→verde em commits separados.
- **SC-006**: Oráculo executa 2× com saída byte-idêntica, cada execução abaixo de 5 segundos (padrão dos oráculos).
- **SC-007**: 🧑 Cenário humano — o primeiro PR real do bot valida ponta a ponta (agrupamento, prefixo, forma SHA das actions, automerge no verde); divergência declarada é saída aceitável, silenciosa não é.

## Assumptions

- A linha de integração é única e `develop` é espelho (ADR-032); PRs do bot miram `main` como qualquer `feature/*`.
- O repo não usa `exclude-newer` (P0: ausente do `pyproject.toml`) — paridade `cooldown`/`minimumReleaseAge` registrada, não configurada.
- Nomes exatos de grupos, schedule e ordem interna do workflow são desenho do PLAN, não desta especificação.
- A prova do automerge e do prefixo contra o servidor só existe no primeiro PR real do bot (limite honesto, ADR-025 §3); até lá, o TESTS prova config + forma + harness.
- Operação e evidência server-side neste ciclo (abrir/inspecionar PRs, ler checks, armar merge) vão pelo toolset GitHub MCP (API estruturada, autenticado como `pasqualinigui`, verificado 2026-09-08) — nunca por scraping de saída de CLI; é determinismo (I) e rastreabilidade (X) aplicados à operação, e docs externas pelo Context7 quando a pesquisa exigir.
- **Termo canônico**: `dependabot` (a escolha Q1) como nome do mecanismo; `update`/`bump` como formas adjetivas intercambiáveis.

## Contratos

### Entregue por este item

- Configuração versionada do bot (`uv` + `github-actions`), com grupos, schedule, prefixo de commit e política de automerge condicionada ao portão.
- Workflow de automerge próprio, com gate de ator e pin SHA.
- `pip-audit` no `pre-push` via procedimento ADR-017 (1 ponto em `f0-009` FR-003) — ou registro fundamentado da manutenção, se o CLARIFY reverter D7 pelo procedimento (não por preferência).
- Oráculo `f0-014` + 14ª linha do manifest + `specs/README.md` `014 ✅`.
- Condição de saída do override `click` re-verificada (mantido ou removido pelo gatilho upstream, nunca por edição avulsa).

### Recebido de itens anteriores

- De **013**: pipeline de release verde como validador do que entra; trava exportada como base; override `click` + FR-017 com condição de saída; dívida do lugar do `pip-audit` no hook.
- De **012/011**: pacotes publicáveis com pins `==` (cada bump move manifesto + lock).
- De **010**: 10 checks sem-bypass + `commitlint` + proteção `strict:true` + auto-merge servidor como restrição de desenho do automerge.
- De **009**: `lefthook.yml` e oráculo `f0-009` (conteúdo sob jurisdição da 009; ajuste só via ADR-017).
- De **008**: auditoria sem config (FR-002 como invariante — supressão fora de questão) + `pip-audit` em `dev`.
- De **005**: `--no-dev` fora do artefato; de **004**: `uv.lock` como fonte única.
- De **001 (Lei Zero)**: bot nativo sem credencial nova; de **ADR-031**: portão determinístico em série.

### Transferido a itens posteriores

- À **015** (`docker-compose`): dependências do manifesto de infra (se houver) entram no mesmo bot, sem config nova.
- À **016** (`docs/tree.md`): estrutura final incluindo a config do bot.
- À **auditoria pós-016**: primeira automação com escrita recorrente no repo por ator não-humano; densidade de PRs do bot como dado de cadência; e a ressalva #9304 (capitalização) como item de vigilância.
- À **Fase 2 (Agentes Core)**: reavaliação do escopo de token do bot vs. agentes com credencial (doutrina ADR-035 §5: detecção, não prevenção, até múltiplos atores).
