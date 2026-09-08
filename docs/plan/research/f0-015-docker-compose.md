# RESEARCH — F0/015 · docker-compose (Postgres + Redis + observabilidade sob demanda)

> **Item do plano:** 0.8 (§17 Fase 0) · **Ordem de execução:** 015/016 (ADR-011)
> **Data da verificação:** 2026-09-08 · **Papel:** Pesquisador
> **Método:** disco do repositório (P0) + registries/APIs (P0, fetch 2026-09-08) +
> docs oficiais (P1, fetch 2026-09-08) + Context7 compose-spec (P1).
> Nenhum dado por memória.
> **Hierarquia de fontes (ADR-025):** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = padrões estáveis · P3 = comunidade (só
> com corroboração P0/P1). Versão ou comportamento externo exige ≥2 fontes
> independentes incluindo P0.
> **Insumo anterior:** `specs/014-dependency-updates/spec.md` › Contratos
> (Transferido à 015: deps do manifesto de infra entram no mesmo bot, sem config nova) +
> `specs/010-ci-completo/spec.md` (10 checks, `strict:true`, auto-merge servidor) +
> `specs/008-pip-audit-trivy/spec.md` (Trivy 0.74.0; `trivy image` só na 015; sem Docker ⇒ ⏭️) +
> ADR-009, ADR-011, ADR-015, ADR-017, ADR-025, ADR-027 §5, ADR-031, ADR-032, ADR-034–036 +
> `docs/plan/implementation_plan.md` §§5, 15, 17.
> **Base:** harness 14/14 + manifest 14/14 declarados (`AGENTS.md:9`); `docker/` e
> `docker-compose*` inexistentes em disco e no índice (fronteira intacta); `.env`
> ignorado (`.gitignore:21-22`, `git check-ignore` prova abaixo, E9).

---

## Q1 — Postgres: 18? trixie ou alpine? (a pergunta que decide a base)

**Fontes (P0+P1):** Docker Hub API `library/postgres` (fetch 2026-09-08: vigentes
`18.6`, `18.6-trixie`, `18.6-bookworm`, `18.6-alpine3.24`; `18`=`latest`=`18-trixie`;
série `19` só em `19beta3` — não tocar) · `postgresql.org/about/news/postgresql-18-released-3142`
(release 2025-09-25) + `docs/18/` (AIO `io_uring`, `uuidv7()`, `uuidv4()` alias,
`uuid_extract_timestamp()`, skip-scan, OAuth, `RETURNING OLD/NEW`, `pg_upgrade` com stats) ·
`docker-library/docs postgres/README.md` (P1: em 18+, `PGDATA=/var/lib/postgresql/18/docker`
e `VOLUME=/var/lib/postgresql` — montes miram `/var/lib/postgresql`; variante defacto é a
Debian; alpine usa musl com ressalvas de libc; extensões fora de `postgres-contrib`
exigem compilação própria no alpine, `apt` direto no Debian).

| Critério | `18.6-trixie` | `18.6-alpine3.24` |
|---|---|---|
| Tamanho | ~440 MB | ~280 MB (irrelevante em dev local) |
| libc | glibc (collations estáveis, pg_trgm/vetores do futuro indexador 1.4) | musl (histórico de divergência em locale/índice) |
| Extensões futuras (pgvector, PostGIS) | `apt install` | compilar na própria imagem |
| Base default do vendor | ✅ sim (`18` = trixie desde 08/2025) | opt-in |

**Achado:** trixie vence por compatibilidade, não por tamanho. **Recomendação:
`postgres:18.6-trixie@sha256:4ef4dbc939d61acea57712655ddb4b4ab27419c913f94cca0cd57cb3ea3c2280`**
(manifest-list P0 2026-08-26; amd64 `sha256:7341002d…`). `uuidv7()` nativo vira o
gerador de IDs do motor (PKs time-ordered, sem extensão). Volume nomeado mira
`/var/lib/postgresql` (nunca `/var/lib/postgresql/data` no 18 — quebra o start, E1).

---

## Q2 — Redis: qual pin? E a licença, impede?

**Fontes (P0+P1):** Docker Hub API `library/redis` (fetch 2026-09-08: vigentes
`8.8.2`, `8.8.2-trixie`; **sem variante alpine na série 8.8**) · `redis.io/docs`
(Redis 8 = distribuição unificada: JSON, Search/Query Engine, series, probabilísticas,
vector-set beta nativos; **breaking em ACLs**: `@read/@write` passam a incluir os
novos comandos — ACLs custom precisam reanálise) · `redis.io/legal/licenses` (P1:
Redis ≥8 em **tri-licença à escolha do usuário — RSALv2 ou SSPLv1 ou AGPLv3**;
AGPLv3 é OSI-approved; FAQ: quem usa o artefato **como está** não é impactado).

**Achado:** a licença não impede: usamos a imagem oficial **sem modificar nem
redistribuir**, e a opção AGPLv3 existe para quem precisar de OSI puro. Valkey fica
como rota de fuga nomeada (só reabre por política, nunca por releitura — molde
ADR-020 §3). **Recomendação: `redis:8.8.2-trixie@sha256:37227fff5638322f4ebea25d6d0dc3ee50848604e82b81426f11507b3ec7d2cc`**
(P0 2026-08-17; amd64 `sha256:d57835a3…`). Comandos de inicialização com
`--requirepass` + `--maxmemory-policy noeviction` (fila BullMQ do Langfuse não admite
eviction) e healthcheck `redis-cli ping` (precedente no compose oficial do Langfuse).

---

## Q3 — Langfuse: qual versão é free e abre studio local?

**Fontes (P0+P1):** GitHub API `langfuse/langfuse/releases/latest` (fetch 2026-09-08:
**v4.30.0**, 2026-09-04; tags de imagem `4.30.0`/`4.30`/`4`/`latest` no Hub, digest
`sha256:376b96bd…`) · `raw.githubusercontent.com/langfuse/langfuse/main/docker-compose.yml`
(P1: 6 serviços — `web`, `worker`, `postgres`, `clickhouse`, `redis`, `minio`) ·
`langfuse.com/self-hosting` (núcleo OSS; recursos EE exigem license key: SSO, RBAC,
org-management) · `raw …/main/LICENSE` (P1: **MIT fora de `ee/`**; EE sob `ee/LICENSE`
comercial; copyright ClickHouse, Inc. — aquisição 01/2026, núcleo segue MIT) ·
`langfuse.com/self-hosting/deployment/infrastructure/{postgres,clickhouse}` (P1:
**v4 exige PG ≥15 (16 recomendado), ClickHouse ≥25.12**, TZ UTC em tudo; sem ClickHouse
não há self-host).

**Achado:** studio local 100% free = imagem OSS `4.30.0` (trace, playground, prompts,
datasets, custos) sem chave; EE só para SSO/RBAC. Divergências a declarar no SPECIFY:
(1) o compose oficial usa `restart: always` em tudo e segredos via env com `# CHANGEME`
— nós usamos `restart: "no"` (doutrina Q4) e segredos via `.env` local + `_FILE`
onde o entrypoint suporta; (2) o compose oficial fixa `postgres:${17}` e `redis:7` —
nós subimos para PG 18 / Redis 8 (Q1/Q2), **além do recomendado pelo vendor
(PG16)** — risco nomeado e mitigado: migrações do Langfuse são Prisma/SQL padrão e o
TESTS 🔴 sobe o profile contra o PG18 antes do verde; se migrar falhar, o fallback
decidido em CLARIFY é PG dedicado `17` no profile (topologia isolada); (3)
`TELEMETRY_ENABLED` vem `true` por default no vendor — **fixamos `false`**
(determinismo/privacidade; nada reporta para fora); (4) `LANGFUSE_INIT_*` permite
bootstrap headless (org/projeto/chaves por env — candidato a FR de determinismo);
(5) piso de recursos do vendor (web 2CPU/4GiB, worker 2CPU/4GiB, CH 2CPU/8GiB) é
dimensionamento de produção — dev local usa `deploy.resources.limits` menores com
`reservations` documentadas, sem fingir paridade.

---

## Q4 — Compose sênior e determinístico: qual a forma?

**Fontes (P1):** Compose Specification via Context7 (`/compose-spec/compose-spec`:
`depends_on` longo com `service_healthy`/`service_completed_successfully`,
`healthcheck` com `start_period`, `profiles` opt-in, `secrets` file-based de topo,
`ports` longo com `host_ip`) · compose oficial do Langfuse (P1: healthchecks +
`depends_on` com condição, portas amarradas em `127.0.0.1` exceto web/minio,
volumes nomeados por serviço).

**Forma fixada (vira FRs do SPECIFY):** `name: fkx` explícito; **zero `build:`**
(só imagens third-party pinadas `tag@digest`); `profiles:` — núcleo (`postgres`,
`redis`) sempre; `observability` (LGTM), `llm` (Langfuse+ClickHouse+MinIO),
`gateway` (LiteLLM) opt-in; `depends_on: condition: service_healthy` em toda aresta;
`healthcheck` com `start_period` em todo serviço com porta/socket; `env_file: [.env]`
+ `secrets:` file-based para senhas de banco (`POSTGRES_PASSWORD_FILE`, suportado
P1 pelo entrypoint); `pull_policy: missing`; portas **sempre** `127.0.0.1:host:container`
(forma longa quando precisar protocolo); rede `backend` com `internal: true`,
rede `edge` só para quem publica porta; named volumes (`pgdata`, `redisdata`, …);
`deploy.resources.{limits,reservations}` + `pids_limit` por serviço;
`logging: {driver: json-file, max-size, max-file}` (anti-disco-cheio);
**`restart: "no"` explícito em todos** — expressão mecânica de "ambiente sob demanda"
(constitution); `up` por perfil no início da sessão, `down` no fim; nenhum auto-start.

---

## Q5 — Segurança runtime: o que cada serviço carrega?

**Fontes (P2+P1):** consenso 2026 (múltiplos guias, convergentes): non-root,
read-only + tmpfs, `cap_drop: [ALL]` + `cap_add` mínimo, `no-new-privileges:true`,
sem `privileged`, sem `docker.sock`, scan de imagem+IaC · P1 (`docker-library/docs`):
PG suporta `--user` arbitrário com ressalva (initdb exige entrada em `/etc/passwd`;
na prática o entrypoint já opera como `postgres` — fixar `user: "70:70"`? Não:
UID do `postgres` na imagem Debian é 70? **não assumir** — SPECIFY resolve o UID por
inspeção `docker image inspect`/execução e congela; até lá, `user:` só onde o vendor
documenta, ex. ClickHouse oficial usa `user: "101:101"`) · Trivy 0.74.0 (008:
`trivy config` cobre compose+Dockerfile, `trivy image` cobre pins — quita B2 da ADR-017).

**Mínimo por serviço (núcleo):** `read_only: true` + `tmpfs: [/tmp, /run/postgresql]`
(PG precisa escrita em PGDATA via volume, não no rootfs); `cap_drop: [ALL]` +
`cap_add: [CHOWN, SETUID, SETGID]` (PG) / nenhum (Redis); `security_opt:
[no-new-privileges:true]`; `user:` onde vendor-suportado; nenhuma porta além das
documentadas; nenhum bind-mount de código (só `:ro` para configs versionadas em
`docker/`); segredos nunca em `environment` plano para senhas (Lei Zero).

---

## Q6 — Precisa de proxy? Precisa de Dockerfile?

**Não para ambos nesta spec.** Proxy (TLS, hostnames, ACME) é problema de
*deploy*, não de orquestração dev-local — tráfego é `127.0.0.1`; registrar como
não-escopo com roteamento a item DevOps futuro (molde ADR-020 §2). Dockerfile só
existe onde há `build:` — como a forma Q4 proíbe `build:`, **esta spec não cria
Dockerfile** (o `Dockerfile` do §15 §Estrutura pertence a empacotamento/distribuição,
item futuro; Hadolint/Dive/Slim ficam sem objeto — ver Q7). Exceção única: configs
montadas `:ro` a partir de `docker/` (init SQL, `prometheus.yml`, `config.alloy`)
são arquivos versionados, não imagens.

---

## Q7 — Quais ferramentas otimizam (e quais são bloat aqui)?

| Ferramenta | Veredito | Motivo |
|---|---|---|
| `docker compose config` | ✅ ADOTA (FR de oráculo) | render determinístico; valida sintaxe sem daemon |
| `trivy config` (0.74.0, já temos) | ✅ ADOTA | misconfig IaC do compose; quita B2/ADR-017 junto com `trivy image` por pin |
| `trivy image` por pin | ✅ ADOTA (com ⏭️ sem daemon, precedente 008 FR-009) | CVE nas imagens pinadas |
| `gitleaks` (010) | ✅ HERDADO | segredos no compose/`.env.example` |
| `checkov` | ❌ REJEITA | pacote Python extra na escada do harness (oráculo 001–003 só stdlib; pós-004 só toolchain convergida); Trivy já cobre `config` |
| `hadolint`/`dive`/`slimtoolkit` | ❌ REJEITA | sem Dockerfile/`build:` nesta spec — sem objeto; reabre **se** item futuro criar `build:` |
| `docker bench` | ❌ REJEITA | audita host/daemon, não repo — fora do harness por construção |
| `dockle`/`grype` | ❌ REJEITA | redundantes com `trivy image+config` (uma fonte de veredito, princípio I) |

---

## Q8 — LGTM + LiteLLM: quais pins candidatos?

**Fontes (P0):** GitHub API releases/latest (fetch 2026-09-08): **Grafana `13.2.1`**
(2026-09-02, inclui CVE-2026-12704/14199 — motivo para não aceitar `latest` antigo),
**Alloy `v1.19.2`**, **Loki `v3.7.7`**, **Tempo `v3.0.3`**, **Pyroscope `v2.3.0`**,
**Prometheus `v3.14.0`**, **LiteLLM `v1.100.0`** (BerriAI). Tags de imagem seguem as
releases (`grafana/grafana:13.2.1`, `grafana/alloy:v1.19.2`, `grafana/loki:3.7.7`,
`grafana/tempo:3.0.3`, `grafana/pyroscope:2.3.0`, `prom/prometheus:v3.14.0`,
`ghcr.io/berriai/litellm:v1.100.0`); **digests resolvem no SPECIFY/TESTS** via
registry API e congelam `tag@digest` (mesmo procedimento E1/E2 desta pesquisa).
Pyroscope no §5 é o único sem uso amarrado a FR do motor — CLARIFY decide
manter (profile) ou cortar (menos 1 serviço, menos RAM).

---

## Q9 — Fronteira de segredos: `.env` vs `secrets:`?

**Fato (P0 executado):** `.env`/` .env.*` ignorados (`.gitignore:21-22`); `git
check-ignore .env` → `.env` (E9); `.env.example` versionado como template.
**Decisão D6:** mecanismo único — `.env` local (nunca commitado) via `env_file`
para não-segredos + `secrets:` file-based (`secrets/` ignorado, `chmod 600`) para
senhas, consumidos via `*_FILE` onde suportado (PG P1) e via interpolação
`${VAR:?erro}` com fail-fast onde não; `.env.example` documenta todas as chaves
com placeholders; oráculo assere: `.env` ausente do índice + nenhuma senha literal
em `compose*.yml`/`docker/*` (gitleaks + grep), convergindo com a Lei Zero.

---

## Q10 — Fronteira de oráculos: o que quebra ao criar o compose?

**Fonte (P0 executado):** varredura literal sobre os 14 oráculos
(`grep -n -i "docker-compose|docker/|compose"`):
único sítio que conhece o vocabulário é **`f0-008` FR-013**
(`scripts/verify/f0-008-pip-audit.sh:80,509` — `docker-compose.yml existe (deve ser
015)`). Nenhum outro oráculo menciona compose/Dockerfile/`docker/`. Ou seja: o
impacto é **1 ponto em 1 oráculo**, conhecido desde a 008.
**Procedimento (molde ADR-017, sem exceção):** o PLAN da 015 declara este ponto, ADR
de pré-autorização ajusta a FR-013 na Fase C verde (admitir `docker-compose.yml`
+ `docker/` sob jurisdição 015, resto da FR intacto), manifest regenerado citando a
ADR. Qualquer outro vermelho herdado = conflito novo, ADR própria, nunca fix direto.

---

## Decisões (D1–D7, vinculam SPECIFY/CLARIFY)

- **D1 (Q1):** `postgres:18.6-trixie@sha256:4ef4…3ea3c2280`; `uuidv7()` como gerador
  de IDs; volume em `/var/lib/postgresql`.
- **D2 (Q2):** `redis:8.8.2-trixie@sha256:37227f…b3ec7d2cc`; tri-licença sem impacto
  para uso local inalterado; Valkey = rota de fuga nomeada.
- **D3 (Q3):** Langfuse OSS `4.30.0` (MIT), `TELEMETRY_ENABLED=false`, `restart: "no"`,
  segredos via `.env`+`_FILE`; PG18 compartilhado como default com fallback PG17
  dedicado se TESTS reprovar migração (CLARIFY fecha).
- **D4 (Q4/Q5):** forma compose + mínimo de segurança por serviço, como fixado acima;
  `restart: "no"` explícito em tudo (doutrina "ambiente sob demanda").
- **D5 (Q6/Q7):** sem proxy, sem Dockerfile; ferramentas = `compose config` + Trivy
  (`config`+`image`) + gitleaks herdado; resto rejeitado com motivo (não re-litigar).
- **D6 (Q9):** `.env` local + `secrets/` file-based, `.env.example` template; zero
  senha literal versionada.
- **D7 (Q10):** fronteira = 1 ponto (`f0-008` FR-013) via ADR prévia na Fase C.

## NEEDS CLARIFICATION (para CLARIFY, antes do PLAN derivar tarefas)

1. Escopo: núcleo + profiles (`observability`, `llm`, `gateway`) nesta spec, ou só
   núcleo com LGTM/Langfuse em itens próprios?
2. Langfuse: PG18 compartilhado (default, risco nomeado) vs PG17 dedicado no profile?
3. Pyroscope: mantém no profile `observability` ou corta?
4. LiteLLM: profile `gateway` nesta spec (pin `v1.100.0`) ou junto do item que
   consumir o gateway (princípio IV)?

## Evidências (E1–E9, 2026-09-08)

- **E1** Hub API `library/postgres/tags/18.6-trixie`: digest `sha256:4ef4…`,
  push 2026-08-25/26; `docker-library/docs` P1: `VOLUME=/var/lib/postgresql` no 18+.
- **E2** Hub API `library/redis/tags`: `8.8.2`/`8.8.2-trixie` vigentes, sem alpine;
  digest manifest `sha256:37227f…`; amd64 `sha256:d57835a3…`.
- **E3** `postgresql.org` P1: 18 (2025-09-25) com `uuidv7()`/`uuidv4()`/AIO/OAuth.
- **E4** `redis.io/legal/licenses` P1: tri-licença RSALv2/SSPLv1/**AGPLv3**; uso
  inalterado sem impacto (FAQ).
- **E5** GitHub API `langfuse/langfuse/releases/latest`: v4.30.0 (2026-09-04);
  Hub `langfuse/langfuse:4.30.0` digest `sha256:376b96bd…`; `LICENSE` P1: MIT fora
  de `ee/`; compose oficial P1: 6 serviços, healthchecks, `127.0.0.1`, CH 25.12.
- **E6** GitHub API: grafana 13.2.1 / alloy v1.19.2 / loki v3.7.7 / tempo v3.0.3 /
  pyroscope v2.3.0 / prometheus v3.14.0 / litellm v1.100.0.
- **E7** Compose-spec via Context7 P1: `depends_on` longo, `healthcheck`,
  `profiles`, `secrets` file, `ports` com `host_ip`.
- **E8** Ambiente: `Docker 29.8.0` + `compose v5.5.1` presentes; **`docker info`
  exit=1 (daemon desligado)** ⇒ asserts live com ⏭️ (precedente 008 FR-009);
  `trivy` binário ausente local (via `docker run aquasec/trivy:0.74.0` quando
  daemon ativo, ou skip).
- **E9** `.gitignore:21-22` ignora `.env`/`.env.*`; `git check-ignore .env` → `.env`;
  `git ls-files | grep ^docker` → 0 (fronteira intacta).
