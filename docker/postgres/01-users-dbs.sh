#!/usr/bin/env bash
# Init do Postgres compartilhado (015, FR-012): bancos fkx + langfuse com
# usuarios homonimos NOSUPERUSER. Senhas via ambiente (entrypoint nao
# substitui env em .sql — por isso .sh executavel, nao .sql). Roda UMA vez,
# so com volume vazio; superuser do bootstrap nao e reutilizado depois.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
-- NOSUPERUSER em tudo que a aplicacao toca (Q5)
CREATE USER fkx WITH PASSWORD '${FKX_DB_PASSWORD:?fkx banco}';
CREATE DATABASE fkx OWNER fkx;
GRANT ALL PRIVILEGES ON DATABASE fkx TO fkx;

CREATE USER langfuse WITH PASSWORD '${LANGFUSE_DB_PASSWORD:?langfuse banco}';
CREATE DATABASE langfuse OWNER langfuse;
GRANT ALL PRIVILEGES ON DATABASE langfuse TO langfuse;
EOSQL
