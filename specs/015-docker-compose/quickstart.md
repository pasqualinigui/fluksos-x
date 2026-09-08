# Quickstart — validar a 015 de ponta a ponta

Pré-requisitos: Docker com daemon ativo + Compose **≥ v2.24.0** (E1: `profiles`, `depends_on` longo com condição, `secrets` file-based, `ports` longo e `pull_policy` estáveis desde muito antes; local verificado v5.5.1 — research E8). `compose version` abaixo dela é erro nomeado. Sem daemon: só o passo 1 e os greps decidem; lives viram ⏭️.

```bash
# 0. molde de segredos (nunca commitar o real)
cp .env.example .env && chmod 600 .env  # preencher placeholders

# 1. render determinístico (sem daemon)
docker compose config > /tmp/c1.yml && docker compose config > /tmp/c2.yml && cmp /tmp/c1.yml /tmp/c2.yml

# 2. núcleo: abre → prova → fecha
docker compose up -d postgres redis
pg_isready -h 127.0.0.1 -U fkx && redis-cli -h 127.0.0.1 ping  # => PONG
docker compose ps && docker compose down
docker ps --filter name=fkx --format '{{.Names}}'  # => vazio (nada residente)

# 3. profile llm até trace visível
docker compose --profile llm up -d
# abrir http://127.0.0.1:3001, ingerir trace de teste, conferir na UI + TELEMETRY off
docker compose --profile llm down

# 4. profile observability até Grafana com dados
docker compose --profile observability up -d
# abrir http://127.0.0.1:3000, conferir datasources Loki/Tempo/Prometheus
docker compose --profile observability down

# 5. auditoria
trivy config docker-compose.yml
trivy image --severity HIGH,CRITICAL --exit-code 1 postgres:18.6-trixie  # repetir por pin
```

Esperado: passos 1–2 sempre verdes com daemon; 3–4 com daemon; 5 verde ou ⏭️ nomeado. `down -v` apaga dados — ato destrutivo, nunca parte do fluxo normal. Detalhes de entidades em `data-model.md`; mapa FR↔asserção em `contracts/oracle-cli.md`.
