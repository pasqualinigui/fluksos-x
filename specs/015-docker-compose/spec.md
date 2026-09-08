# Feature Specification: docker-compose — Postgres + Redis sob demanda, observabilidade em profiles

**Feature Branch**: `feature/f0-docker-compose`

**Created**: 2026-09-09

**Status**: Draft

**Input**: User description: "Fase 0, item 0.8 (015/016 na ordem de execução): docker-compose — Postgres 18 (uuidv7) + Redis 8 + Langfuse com studio local + práticas sênior de compose/segurança, tudo desligado por padrão, sem proxy, sem Dockerfile" (SPECIFY aplicado deterministicamente sobre o research vinculante)

**Item do plano**: 0.8 (§17 Fase 0) · **Ordem de execução**: 015 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-015-docker-compose.md` (Q1–Q10, decisões D1–D7, hierarquia P0–P3 da ADR-025, pergunta-padrão de ambiente da ADR-027 §5)
**Contrato de entrada**: `specs/014-dependency-updates/spec.md` › Contratos (Transferido à 015: deps do manifesto de infra entram no mesmo bot, sem config nova) + `specs/010-ci-completo/spec.md` › Contratos (10 checks, commitlint, proteção sem-bypass, `strict:true`, auto-merge servidor — ADR-035) + `specs/008-pip-audit-trivy/spec.md` (`trivy image` só na 015; sem Docker ⇒ ⏭️ skip, FR-009) + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-015, ADR-017, ADR-025, ADR-027 §5, ADR-031, ADR-032) + `docs/plan/implementation_plan.md` §§5, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem estado e cache sem casa: o checkpointer do LangGraph (Fase 2), a fila de ingestão e o cache de embeddings (Fase 1/3) e a observabilidade LLM (Fase 3) precisam de Postgres + Redis + ClickHouse — **mas hoje não existe nenhum manifesto de infra versionado**. Este item entrega **exclusivamente**: `docker-compose.yml` com núcleo (`postgres` 18.6-trixie + `redis` 8.8.2-trixie, pins `tag@digest`) sempre disponível e perfis opt-in (`observability` LGTM + Pyroscope, `llm` Langfuse v4 + ClickHouse + MinIO), tudo **desligado por padrão** com `restart: "no"` explícito (ambiente sob demanda: `up` por perfil abre a sessão, `down` fecha, nada ressuscita), hardening por serviço, segredos fora do versionado, e oráculo `f0-015` com asserções. Não cria proxy reverso/TLS (problema de deploy, roteado a item DevOps futuro), Dockerfile/`build:` (zero nesta spec), profile `gateway`/LiteLLM (adiado à Fase 2 — decisão 2026-09-09, pin registrado para reuso), runners, merge queue, nem `docs/tree.md` (**016**).

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (pins `tag@digest`, `compose config` byte-idêntico, `restart: "no"` explícito em vez de default implícito); **II** especificação precede código; **III** vermelho→verde em commits separados; **IV** o formato do compose (serviços, perfis, redes, volumes, segredos) declarado aqui antes de existir; **V** Lei Zero (zero senha literal versionada; `.env` ignorado e provado); **VI** harness é o oráculo, e a fronteira (`f0-008` FR-013, 1 ponto conhecido) só se ajusta por ADR prévia; **VIII** cada versão e comportamento verificados com evidência executada em `docs/plan/research/f0-015-docker-compose.md`; **IX** infra do **motor**, sem presumir stacks-alvo; **X** falha nomeia `FR-XXX` e a evidência observada.

**Restrição estrutural que molda o item** (research Q3+Q10): o vendor do Langfuse recomenda PG16 e publica `restart: always` — nós pinamos PG18 compartilhado (além do testado pelo vendor) e `restart: "no"` (doutrina da casa); a prova de que as migrações aplicam limpas no PG18 é o TESTS 🔴 desta spec, com fallback pré-registrado (PG17 dedicado no profile) sem nova deliberação.

## Clarifications

### Session 2026-09-08 (maintainer, durante o RESEARCH)

- Q: Núcleo + profiles, só núcleo, ou stack §5 completa ativa? → A: **núcleo + profiles** — `postgres`+`redis` como base sempre disponível; LGTM+Langfuse+LiteLLM atrás de profiles, desligados por padrão (obedece "nada roda em segundo plano": proibido é container com `always` que liga sozinho; a forma é tudo `down` por padrão, `up` explícito por perfil/tarefa).
- Q: Postgres 17 ou 18? → A: **Postgres 18** (`uuidv7()` nativo, trixie default).
- Q: Redis 8 ou Valkey? → A: **Redis 8** (tri-licença com opção AGPLv3; Valkey fica como rota de fuga nomeada).

### Session 2026-09-09 (maintainer, sobre os 3 marcadores da spec)

- Q1 Pyroscope no profile? → A: **A — mantém `grafana/pyroscope:v2.3.0` no profile `observability`** (decisão do mantenedor: observabilidade máxima possível). Fundamento registrado: o §5 do plano já lista profiling contínuo; custo é ~zero (profile opt-in, `down` por padrão); consumidor imediato é o próprio desenvolvimento Fase 1/2 (gargalos de CPU/memória dos agentes em construção), não só a Fase 3 em operação.
- Q2 LiteLLM agora ou na Fase 2? → A: **B — adia à Fase 2** (princípio IV: gateway sem provedor para rotear é especulação). Pin `v1.100.0` + digest a congelar ficam registrados no research Q8 para reuso sem re-pesquisa; profile `gateway` **fora** desta spec.
- Q3 Postgres do Langfuse — compartilhado ou dedicado? → A: **A — compartilhado com fallback pré-autorizado** (1 PG, bancos separados; se TESTS reprovar migração no PG18, PG17 dedicado no profile sem nova deliberação).
- Q4 (clarify 2026-09-09) Portas das UIs — Grafana e Langfuse disputam a 3000? → A: **A — Grafana `127.0.0.1:3000`, Langfuse `127.0.0.1:3001`** (segue o §5 do plano, que já resolveu a colisão na intenção; demais serviços só-rede-interna).
- Q5 (clarify 2026-09-09, delegada) Superusuário único ou usuários por banco? → A: **A — bootstrap superuser + usuários dedicados por banco sem SUPERUSER**, criados por init SQL versionado em `docker/postgres/` (menor privilégio; Langfuse só alcança o próprio banco).
- Q6 (clarify 2026-09-09, delegada) Redis com persistência ou efêmero? → A: **A — `--appendonly yes` + `--maxmemory-policy noeviction` + volume de dados** (a fila BullMQ do Langfuse não admite eviction nem perda silenciosa; cache do motor herda a mesma durabilidade).
- Q7 (clarify 2026-09-09, delegada) Nomes dos bancos no PG compartilhado? → A: **`fkx` (motor) + `langfuse` (studio)**, usuários homônimos sem SUPERUSER, schema `public` do Langfuse isolado no próprio banco.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Sessão com estado, sem daemon residente (Priority: P1)

O desenvolvedor abre uma sessão de trabalho (`up` do núcleo), usa Postgres (estado) e Redis (cache/fila) a partir do motor e dos testes, e fecha tudo (`down`) ao fim — nenhum container sobrevive à sessão, nenhum religa no boot.

**Why this priority**: é a lacuna que cria o item (§17 0.8) composta com a restrição mais dura da casa (ambiente sob demanda). Sem isto, o item não existe.

**Independent Test**: `up` do núcleo → `pg_isready` + `redis-cli ping` respondem; `down` → zero containers do projeto em `ps`; após o ciclo, `restart` de host não ressuscita nada (por construção: `restart: "no"` em todos).

**Acceptance Scenarios**:

1. **Given** daemon Docker ativo e repositório limpo, **When** o núcleo é ligado, **Then** Postgres aceita conexão e Redis responde `PONG` em portas só-localhost.
2. **Given** o núcleo ligado, **When** é desligado, **Then** nenhum container do projeto permanece em execução e os dados persistem em volumes nomeados para a próxima sessão.
3. **Given** máquina reiniciada (ou daemon reiniciado), **When** listado o estado, **Then** nenhum serviço do motor está em execução sem ato explícito.

---

### User Story 2 — Hardening por construção, auditoria verde (Priority: P1)

Cada serviço carrega o mínimo de segurança (non-root onde suportado, rootfs read-only, capabilities zeradas, sem escalação, sem socket do daemon, sem segredo versionado) e a auditoria de imagens + IaC aprova os pins.

**Why this priority**: infra sem hardening é dívida que o Trivy cobra depois — e a B2 da ADR-017 (`trivy image` pleno) foi transferida exatamente a este item.

**Independent Test**: `trivy config` sobre o compose + `trivy image` por pin com zero `HIGH,CRITICAL` (ou ⏭️ documentado sem daemon); grep prova zero senha literal e zero `privileged`/`docker.sock`.

**Acceptance Scenarios**:

1. **Given** o compose versionado, **When** escaneado para misconfiguração, **Then** zero achado bloqueante.
2. **Given** cada imagem pinada, **When** escaneada para CVE `HIGH,CRITICAL`, **Then** zero vulnerabilidade alcançável (ou skip nomeado sem daemon).
3. **Given** os arquivos versionados, **When** inspecionados, **Then** nenhuma senha/segredo literal e nenhum modo privilegiado em nenhum serviço.

---

### User Story 3 — Studio LLM local sob demanda (Priority: P2)

O desenvolvedor liga o profile `llm` e abre o studio do Langfuse no navegador: traces, custos e prompts versionados, com dados só na máquina local e telemetria do vendor desligada.

**Why this priority**: é o consumo Fase 3 que justifica ClickHouse+MinIO; fora de profile, seria 6 serviços pesando toda sessão.

**Independent Test**: `up` do profile → studio responde na porta documentada, ingestão de um trace de teste aparece na UI; `down` → tudo parado.

**Acceptance Scenarios**:

1. **Given** núcleo ativo, **When** o profile `llm` é ligado, **Then** todos os seus serviços ficam `healthy` por `depends_on` com condição (sem corrida de inicialização).
2. **Given** o studio acessível, **When** um trace de teste é ingerido, **Then** ele é visível na UI com custo computado.
3. **Given** a configuração do profile, **When** inspecionada, **Then** telemetria do vendor está desligada e nenhum dado sai da máquina.

---

### User Story 4 — LGTM sob demanda (Priority: P2)

O desenvolvedor liga o profile `observability` e vê logs, métricas e traces do motor no Grafana, com coleta via Alloy e retenção local.

**Why this priority**: fecha o §5 do plano sem impor 5 serviços a quem só precisa do núcleo.

**Independent Test**: `up` do profile → Grafana responde, datasources provisionados apontam para Loki/Tempo/Prometheus do próprio compose.

**Acceptance Scenarios**:

1. **Given** núcleo ativo, **When** o profile `observability` é ligado, **Then** Grafana, Alloy, Loki, Tempo, Prometheus e Pyroscope ficam `healthy`.
2. **Given** o Grafana acessível, **When** consultado, **Then** logs e métricas do período da sessão estão visíveis.

---

### User Story 5 — Gateway LLM adiado à Fase 2, pin registrado (Priority: P3, fora desta spec)

O profile `gateway` **não existe nesta spec** (decisão 2026-09-09, princípio IV: sem provedor para rotear). O pin candidato (`ghcr.io/berriai/litellm:v1.100.0`, research Q8) fica registrado para a Fase 2 criar o profile sem re-pesquisar versões. Nenhuma chave de provedor é versionada em nenhum momento.

**Why this priority**: documenta o adiamento como decisão, não como esquecimento — o molde ADR-020 §2 proíbe "ficou para depois" sem consumidor nomeado; o consumidor é o item Fase 2 que introduzir o gateway multi-provider.

**Independent Test**: `grep` prova ausência de `gateway`/`litellm` no compose + presença do pin no research Q8 e no contrato Transferido.

**Acceptance Scenarios**:

1. **Given** o compose versionado, **When** inspecionado, **Then** não existe profile `gateway` nem referência a `litellm`.
2. **Given** o research Q8 e os Contratos, **When** lidos, **Then** o pin `v1.100.0` e o consumidor (Fase 2) estão nomeados.

---

### Edge Cases

- **Daemon Docker desligado**: asserts live viram ⏭️ skip nomeado (precedente 008 FR-009); asserts estáticos (`compose config`, greps, digests, `trivy config` se disponível) continuam decidindo.
- **Migração Langfuse reprova no PG18**: fallback pré-registrado — PG17 dedicado dentro do profile `llm`, sem nova deliberação (divergência declarada no verde, nunca silenciosa).
- **CVE `HIGH,CRITICAL` em pin no dia do verde**: troca de patch do pin pelo procedimento ADR-017 (mesma classe do bump ruff/ADR-037); `latest` jamais é a saída.
- **Porta localhost ocupada**: falha nomeia a porta e o serviço; nenhuma porta é publicada em interface não-localhost.
- **`.env` ausente**: `compose config` falha rápido com mensagem que nomeia a variável (`${VAR:?…}`); `.env.example` é o molde copiável.
- **`docker compose` antigo sem `profiles`/long-syntax**: versão mínima documentada no quickstart; `compose version` abaixo dela é erro nomeado, não comportamento degradado.
- **Bot de dependências (014) abre bump de imagem**: images de infra seguem pins `tag@digest` e entram no grupo do bot sem config nova (contrato recebido da 014).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST declarar `docker-compose.yml` com `name: fkx`, zero blocos `build:`, e toda imagem pinada `tag@digest` — `postgres:18.6-trixie@sha256:4ef4…` e `redis:8.8.2-trixie@sha256:37227f…` no núcleo (digeridos congelados do research E1/E2).
- **FR-002**: O sistema MUST organizar os serviços em núcleo (sem profile: `postgres`, `redis`) + profiles opt-in (`observability`, `llm`); serviço fora do núcleo MUST NOT iniciar sem seu profile explícito; profile `gateway` MUST NOT existir nesta spec (adiado à Fase 2, decisão 2026-09-09); o Redis do núcleo MUST operar com `--appendonly yes` + `--maxmemory-policy noeviction` e volume de dados nomeado.
- **FR-003**: Todo serviço MUST declarar `restart: "no"` explícito — ausência da chave reprova (o default implícito não conta).
- **FR-004**: Toda aresta de dependência MUST usar `depends_on` longo com `condition: service_healthy` (ou `service_completed_successfully` para jobs one-shot), e todo serviço com porta/socket MUST ter `healthcheck` com `start_period`.
- **FR-005**: Nenhum arquivo versionado (`docker-compose.yml`, `docker/*`, `.env.example`) MUST conter senha/segredo/chave literal; `.env` e `secrets/` MUST estar ignorados e ausentes do índice; senhas de banco MUST trafegar via `*_FILE`/secrets file-based onde suportado.
- **FR-006**: Toda porta publicada MUST estar amarrada a `127.0.0.1`; a rede de backend MUST ter `internal: true`; somente serviços com UI local documentada publicam porta, no mapa fixo — Grafana `127.0.0.1:3000`, Langfuse `127.0.0.1:3001`, Postgres `127.0.0.1:5432`, Redis `127.0.0.1:6379` (Grafana≠Langfuse: a colisão na 3000 resolve-se pelo §5, decisão 2026-09-09); demais serviços MUST NOT publicar porta.
- **FR-007**: Todo serviço MUST declarar limites efetivos sob `docker compose up` (`mem_limit` + `mem_reservation` + `cpus` + `pids_limit` — F6: `deploy.resources` é especificação swarm e o `up` o ignora; forma que impõe de verdade) e rotação de log (`logging` com `max-size`/`max-file`).
- **FR-008**: Todo serviço MUST declarar `read_only: true` (+ `tmpfs` para escritas efêmeras), `cap_drop: [ALL]` (+ `cap_add` mínimo documentado), `security_opt: [no-new-privileges:true]`; MUST NOT existir `privileged: true` nem montagem de `docker.sock` em nenhum serviço.
- **FR-009**: O profile `llm` MUST trazer Langfuse OSS `4.30.0` (`web`+`worker`) + ClickHouse `25.12` + MinIO + uso do Redis do núcleo, com `TELEMETRY_ENABLED=false`, segredos via `.env`+`_FILE`, e migrações aplicando limpas sobre o Postgres do núcleo (ou fallback PG17 dedicado, ver Edge Cases).
- **FR-010**: O profile `observability` MUST pinar Grafana `13.2.1` + Alloy `v1.19.2` + Loki `v3.7.7` + Tempo `v3.0.3` + Prometheus `v3.14.0` + Pyroscope `v2.3.0` com datasources provisionados entre si (decisão 2026-09-09: observabilidade máxima; profiling serve ao desenvolvimento Fase 1/2, custo ~zero com profile parado por padrão).
- **FR-011**: O sistema MUST NOT criar profile `gateway`/LiteLLM nesta spec (adiado à Fase 2, decisão 2026-09-09); o pin candidato `ghcr.io/berriai/litellm:v1.100.0` MUST estar registrado no research Q8 e no contrato Transferido para reuso sem re-pesquisa; nenhuma chave de provedor MUST estar versionada.
- **FR-012**: O Postgres do núcleo MUST ser compartilhado pelo profile `llm` em bancos separados — `fkx` (motor) + `langfuse` (studio, schema `public` isolado no próprio banco) — com usuários homônimos sem SUPERUSER criados por init SQL versionado em `docker/postgres/` (superuser só no bootstrap); se TESTS reprovar migração no PG18, o fallback é Postgres `17` dedicado no profile, sem nova deliberação (decisão 2026-09-09).
- **FR-013**: O sistema MUST prover oráculo `scripts/verify/f0-015-*.sh` sob o contrato `oracle-cli.md` (identidade FR↔asserção documentada, determinismo, somente leitura, self-check `f0-001…f0-014` **em série** conforme ADR-031, 15ª linha do manifest).
- **FR-014**: `trivy image` por pin MUST sair 0 com zero `HIGH,CRITICAL`, ou linha ⏭️ skip nomeado sem daemon (precedente 008 FR-009) — quita a dívida B2 da ADR-017.
- **FR-015**: `docker compose config` MUST renderizar byte-idêntico em 2 execuções (determinismo I executável, sem daemon).
- **FR-016**: `specs/README.md` MUST conter `015` `✅` com hash do commit de convergência, e `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados.

### Key Entities *(include if feature involves data)*

- **Service**: unidade do compose; atributos: imagem pinada, profile (ou núcleo), healthcheck, limites, rede(s), volumes. Nunca liga sozinho após boot.
- **Profile**: conjunto opt-in (`observability`, `llm`, `gateway`); fora do núcleo, nada existe sem profile explícito.
- **Secret**: credencial fora do versionado; via `secrets:` file-based ou `.env` local; nunca literal em arquivo rastreado.
- **Pin**: par `tag@digest` por imagem third-party; `latest` é forma proibida.
- **Volume**: persistência nomeada por serviço com dado (PG, Redis, ClickHouse, MinIO, Prometheus, Grafana); `down` preserva, `down -v` é ato destrutivo documentado.
- **Network**: `backend` interna vs `edge` para UIs locais; tráfego entre serviços nunca sai da rede do projeto.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Sessão núcleo abre (PG+Redis saudáveis em portas só-localhost) e fecha (zero containers residuais) em 100% das execuções com daemon; sem daemon, asserts estáticos decidem e lives viram ⏭️ nomeado.
- **SC-002**: Zero senha literal versionada; zero `privileged`/`docker.sock`; 100% dos serviços com `restart: "no"` explícito, `read_only`, `cap_drop: [ALL]`, `no-new-privileges`.
- **SC-003**: `trivy config` + `trivy image` por pin com zero `HIGH,CRITICAL` (ou skip nomeado sem daemon).
- **SC-004**: `docker compose config` byte-idêntico em 2 execuções; oráculo 2× byte-idêntico, cada execução abaixo de 5 segundos no modo estático (padrão dos oráculos).
- **SC-005**: Harness 15/15 + manifest 15/15 + `tasks.md` zero `[ ]` + par vermelho→verde em commits separados.
- **SC-006**: 🧑 Cenário humano — com daemon ativo: ciclo núcleo `up`→uso→`down`; ciclo `llm` até trace visível no studio; `down` final sem resíduo de container; divergência declarada é saída aceitável, silenciosa não é.
- **SC-007**: Fronteira paga pelo procedimento: `f0-008` FR-013 ajustada exclusivamente na Fase C verde via ADR prévia, manifest citando a ADR; nenhum outro oráculo anterior tocado.

## Assumptions

- Docker 29.8.0 + compose v5.5.1 verificados na máquina do mantenedor (research E8); versão mínima do compose documentada no quickstart do item.
- Runners do CI possuem daemon Docker para os asserts live; sem daemon, skip ⏭️ é veredito válido (não falha).
- Nomes de serviços/redes/volumes e valores de limites/timeouts são desenho do PLAN, não desta especificação.
- Digeridos de LGTM/LiteLLM/MinIO/ClickHouse/Worker congelam no SPECIFY via registry API (mesmo procedimento E1/E2); tags candidatas no research Q8.
- Dependabot cobre bumps das imagens de infra sem config nova (contrato recebido da 014); `major` de infra segue a mesma regra de isolamento da 014.
- Operação e evidência server-side neste ciclo vão pelo toolset GitHub MCP (API estruturada) e docs pelo Context7 quando a pesquisa exigir — nunca scraping.
- **Termo canônico**: `docker-compose` (o arquivo e o item); `compose` como forma adjetiva intercambiável.

## Contratos

### Entregue por este item

- `docker-compose.yml` (núcleo + profiles `observability`/`llm`/`gateway`) com pins `tag@digest`, hardening por serviço, redes/volumes nomeados.
- `docker/` com configs versionadas montadas `:ro` (init SQL, `prometheus.yml`, `config.alloy`, provisioning do Grafana).
- `.env.example` estendido como molde de todas as chaves (placeholders, zero segredo).
- Oráculo `f0-015` + 15ª linha do manifest + `specs/README.md` `015 ✅`.
- Quitação da dívida B2 da ADR-017 (`trivy image` pleno sobre os pins).

### Recebido de itens anteriores

- De **014**: bot cobre bumps das imagens de infra sem config nova; `pip-audit` no `pre-push` (portão que julgará mudanças deste item).
- De **013**: versionamento sobre a linha única (mudanças aqui não liberam versão por si).
- De **012/011**: pacotes consumirão `DATABASE_URL`/`REDIS_URL` do compose (Fase 1/2; sem código cliente nesta spec).
- De **010**: 10 checks sem-bypass + `commitlint` + `strict:true` como restrição de desenho.
- De **009**: `lefthook.yml` (oráculo `f0-009` intocado fora da FR de fronteira, se houver).
- De **008**: Trivy 0.74.0 + invariante sem-supressão + `f0-008` FR-013 como único ponto de fronteira + skip ⏭️ sem daemon.
- De **001 (Lei Zero)**: nenhuma credencial nova em arquivo versionado; `.env` ignorado.

### Transferido a itens posteriores

- À **016** (`docs/tree.md`): árvore final incluindo `docker-compose.yml`, `docker/` e `.env.example` estendido.
- À **auditoria pós-016**: densidade de achados deste item + contagem de bumps de infra verificados pelo molde ADR-037 + amostras de transientes de daemon (família A2/ADR-031) como dado de cadência.
- À **Fase 1 (Harness & Indexação)**: `DATABASE_URL`/`REDIS_URL` como elos verificados (princípio VIII) para checkpointer, cache e fila; `uuidv7()` como gerador de IDs do motor.
- À **Fase 2 (Agentes Core)**: profile `gateway` LiteLLM com pin candidato `ghcr.io/berriai/litellm:v1.100.0` (research Q8; digest a congelar no item consumidor) + reavaliação do escopo de credenciais (doutrina ADR-035 §5).
- À **Fase 3 (Memória & Observabilidade)**: profiles `observability`/`llm` como base operacional do Guardião e da telemetria OTel.
