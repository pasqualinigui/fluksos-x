# Data Model — 015 docker-compose

Entidades do manifesto de infra (FR-001..FR-012). Sem código de produção: "validação" = asserção do oráculo.

## Service

Unidade do compose. Campos: `name` (fixo por serviço, ex. `postgres`), `image` (`tag@digest` da tabela de pins — `latest` inválido), `profile` (ausente = núcleo; senão `observability`|`llm`), `restart` (`"no"`, obrigatório explícito), `healthcheck` (obrigatório se publica porta ou é dependência), `depends_on` (forma longa com condição), `ports` (só forma com `127.0.0.1`), `networks`, `volumes`, `environment` (sem segredo literal), `secrets`, `env_file`, limites service-level `mem_limit`/`mem_reservation`/`cpus`/`pids_limit` (F6: `deploy.resources` é swarm-only, o `up` ignora), `logging`, `user`, `read_only`, `cap_drop`/`cap_add`, `security_opt`.
Validação: `compose config` renderiza; grep nega `latest|build:|privileged|docker.sock`.

## Profile

Conjunto opt-in. Valores: `observability` (Grafana, Alloy, Loki, Tempo, Prometheus, Pyroscope), `llm` (langfuse-web, langfuse-worker, clickhouse, minio + núcleo). `gateway` é valor **proibido** nesta spec (FR-011). Serviço com profile só existe com `--profile` explícito.

## Secret

Credencial fora do versionado. Campos: `name`, origem (`secrets/` file-based ou `.env` local), consumidor (`*_FILE` ou `${VAR:?…}`). Validação: `git ls-files` nega `.env`/`secrets/`; grep nega senha literal em `docker-compose.yml`/`docker/*`; gitleaks aprova.

## Pin

Par `tag@digest` por imagem. Validação: regex `:[^@]+@sha256:[0-9a-f]{64}` em todo `image:`; digest confere com a tabela de pins do `research.md`.

## Volume

Persistência nomeada. Valores: `pgdata` (`/var/lib/postgresql`), `redisdata` (`/data`), `clickhouse-data`, `clickhouse-logs`, `minio-data`, `promdata`, `grafanadata`. Ciclo: `down` preserva; `down -v` destrutivo documentado no quickstart.

## Network

`backend` (`internal: true`, todo serviço) + `edge` (só quem publica UI: grafana:3000, langfuse:3001). Nenhum serviço toca as duas, exceto os que publicam porta.

## Mapa de portas (fixo, FR-006)

| Serviço | Publicação |
|---|---|
| grafana | `127.0.0.1:3000:3000` |
| langfuse-web | `127.0.0.1:3001:3000` |
| postgres | `127.0.0.1:5432:5432` |
| redis | `127.0.0.1:6379:6379` |
| demais | nenhuma |

## Bancos e usuários PG (FR-012)

Bancos `fkx` + `langfuse`; usuários homônimos sem SUPERUSER via `docker/postgres/01-users-dbs.sql`; superuser só no bootstrap. Langfuse usa `public` no próprio banco.
