# Research (consolidação Phase 0) — 015 docker-compose

**Fonte vinculante**: `docs/plan/research/f0-015-docker-compose.md` (Q1–Q10, D1–D7, E1–E9, fetch 2026-09-08/09). Abaixo, só decisões + pins congelados; o porquê mora no vinculante.

## Decisões

- **Decision: Postgres `18.6-trixie`, `uuidv7()` como gerador de IDs, volume em `/var/lib/postgresql`.**
  Rationale: major vigente (19 só beta); trixie = base default glibc (extensões futuras, collations estáveis); `uuidv7()` nativo elimina extensão; PGDATA versionado no 18 proíbe o path antigo.
  Alternatives considered: `18.6-alpine3.24` (rejeitado: musl + compilação própria de extensões, economia de ~160MB irrelevante em dev), `17.11-trixie` (rejeitado: sem `uuidv7()` nativo; vive só como fallback do Langfuse).
- **Decision: Redis `8.8.2-trixie`, `--appendonly yes` + `--maxmemory-policy noeviction`.**
  Rationale: série 8.x vigente e unificada; AOF+noeviction exigidos pela fila BullMQ; tri-licença com opção AGPLv3 sem impacto para uso local inalterado.
  Alternatives considered: Valkey (rota de fuga nomeada, só por política); efêmero sem volume (rejeitado: perda silenciosa de fila).
- **Decision: Langfuse OSS `4.30.0` (MIT), imagens do Docker Hub, `TELEMETRY_ENABLED=false`.**
  Rationale: v4.30.0 vigente; Hub é verificável por API (vendor usa `docker.langfuse.com`, divergência declarada: Hub vence por auditabilidade P0); núcleo MIT, EE comercial fora do escopo.
  Alternatives considered: `:4` flutuante (rejeitado: mutável); v3 (rejeitado: série antiga).
- **Decision: PG18 compartilhado (`fkx` + `langfuse`), usuários sem SUPERUSER via init SQL, fallback PG17.**
  Rationale: 1 PG = 1 backup/healthcheck; vendor suporta ≥15 (18 além do recomendado, não fora do suportado); TESTS decide com prova.
  Alternatives considered: PG17 dedicado desde o início (fallback pré-autorizado, sem nova deliberação).
- **Decision: forma compose — `name: fkx`, zero `build:`, profiles, `restart: "no"` explícito, portas só-localhost fixas, `internal: true` no backend.**
  Rationale: compose-spec P1 + compose oficial do vendor como molde; explícito > implícito (I); mapa de portas fecha a colisão Grafana/Langfuse pelo §5.
  Alternatives considered: `unless-stopped` (rejeitado: ressuscita no boot = segundo plano); rede `proxy` do snippet §5 (rejeitada: sem proxy nesta spec).
- **Decision: segredos via `.env` local + `secrets:` file-based + `*_FILE`; `.env.example` molde.**
  Rationale: Lei Zero; entrypoint PG suporta `_FILE` (P1); `.env` ignorado e provado (E9).
- **Decision: ferramentas = `compose config` + Trivy (`config`+`image`) + gitleaks; resto rejeitado com motivo.**
  Rationale: uma fonte de veredito por superfície (I); checkov/hadolint/dive sem objeto ou fora da escada.
- **Decision: sem proxy, sem Dockerfile, sem `gateway` (Fase 2), Pyroscope mantido.**
  Rationale: proxy = deploy; Dockerfile sem `build:` é peça sem objeto; gateway sem consumidor viola IV; Pyroscope por decisão do mantenedor (observabilidade máxima, custo ~zero parado).

## Pins congelados (tag@digest, Hub API 2026-09-09)

| Imagem | Pin |
|---|---|
| `postgres` | `18.6-trixie@sha256:4ef4dbc939d61acea57712655ddb4b4ab27419c913f94cca0cd57cb3ea3c2280` |
| `redis` | `8.8.2-trixie@sha256:37227fff5638322f4ebea25d6d0dc3ee50848604e82b81426f11507b3ec7d2cc` |
| `langfuse/langfuse` | `4.30.0@sha256:376b96bdd8725e74171a3d0cdd9115c8265d4209df95cb26c47370cb3b32329a` |
| `langfuse/langfuse-worker` | `4.30.0@sha256:00bc13c8da68fb77c55bcba0c1c16377f1f360ffb17206dbc708912ce4e3afb5` |
| `clickhouse/clickhouse-server` | `25.12@sha256:8a790dd3468db22b1d4e7b18a176f378ff5ff6053b9c48dd4ea1fa71a24c5ba6` |
| `minio/minio` | `RELEASE.2025-09-07T16-13-09Z-cpuv1@sha256:13582eff79c6605a2d315bdd0e70164142ea7e98fc8411e9e10d089502a6d883` |
| `grafana/grafana` | `13.2.1@sha256:f772d434e8fab0049deb2b1b30abd43342bcfca1537614aa8d36080232cf4283` |
| `grafana/alloy` | `v1.19.2@sha256:b8ec653c44235fbe910879145dac3597d66b0aaecf60bcbbe82580767771a839` |
| `grafana/loki` | `3.7.7@sha256:d70e4659623f3e109af669cae76fe2a5dd5be54e2298fe8aed380d982fbc2500` |
| `grafana/tempo` | `3.0.3@sha256:0296560ac66f8a3600d7fb3014a52c189d4d9c3549ad6ff441bf2409855d68d5` |
| `grafana/pyroscope` | `2.3.0@sha256:881328cdbff0ef7601e23a0e7647fecb7099b4fe4c74fcdd204cb64722e2b2d0` |
| `prom/prometheus` | `v3.14.0@sha256:5ce7540c3c00ef4ab0c9d2c995c6a5b9c421f44b4a115d97a2c7af3b1c21cbb0` |
| LiteLLM (Fase 2) | `ghcr.io/berriai/litellm:v1.100.0` (digest a congelar no item consumidor) |

## Divergências declaradas vs vendor/upstream (não são defeitos)

1. Registry Langfuse: Hub (`langfuse/…`) em vez de `docker.langfuse.com/…` — auditabilidade P0 vence fidelidade.
2. MinIO: `minio/minio` Hub em vez de `cgr.dev/chainguard/minio` sem tag — tag mutável é forma proibida.
3. `restart: always` → `"no"`; segredos env `# CHANGEME` → `.env`+`_FILE`; PG17/Redis7 do vendor → PG18/Redis8 (com fallback).
