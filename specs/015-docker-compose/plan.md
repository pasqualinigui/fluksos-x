# Implementation Plan: docker-compose — Postgres + Redis sob demanda, observabilidade em profiles

**Branch**: `feature/f0-docker-compose` | **Date**: 2026-09-09 | **Spec**: `specs/015-docker-compose/spec.md`

**Input**: Feature specification from `/specs/015-docker-compose/spec.md`

## Summary

Declarar `docker-compose.yml` (`name: fkx`, zero `build:`, tudo `tag@digest` congelado) com núcleo `postgres:18.6-trixie` + `redis:8.8.2-trixie` e profiles opt-in (`observability` LGTM+Pyroscope, `llm` Langfuse v4.30.0 + ClickHouse 25.12 + MinIO), tudo `restart: "no"` explícito e desligado por padrão; `docker/` com init SQL e configs `:ro`; `.env.example` estendido; oráculo `f0-015` com 12–16 asserções em identidade + self-check serial + 15ª linha do manifest; fronteira de 1 ponto (`f0-008` FR-013) paga por ADR prévia na Fase C.

## Technical Context

**Language/Version**: Python `>=3.12,<3.14` (só para o harness/oráculo); compose file v2 (Compose `v5.5.1` verificado; mínima documentada no quickstart); `docker compose config` como validador sem daemon

**Primary Dependencies**: nenhuma nova no `pyproject.toml` — só imagens third-party pinadas `tag@digest` (tabela de pins em `research.md` E-pins; digests congelados via Hub API 2026-09-09)

**Storage**: Postgres 18.6 (bancos `fkx` + `langfuse`, volume em `/var/lib/postgresql`) · Redis 8.8 AOF+noeviction · ClickHouse 25.12 · MinIO — todos em named volumes; `down` preserva, `down -v` é destrutivo documentado

**Testing**: harness `scripts/verify/f0-015-*.sh` (12–16 asserções identidade, mapa em `contracts/oracle-cli.md`) + self-check `f0-001…f0-014` em série (ADR-031) + 15ª linha do manifest + prova live com daemon (SC-006 🧑; sem daemon ⇒ ⏭️, precedente 008 FR-009)

**Target Platform**: Linux dev local com Docker 29.8.0+ (daemon sob demanda, nunca residente); CI com daemon para asserts live; `127.0.0.1` em toda porta publicada

**Project Type**: manifesto de infra + oráculo (sem código de produção, sem `build:`, sem Dockerfile)

**Performance Goals**: oráculo 2× byte-idêntico, modo estático <5s cada (padrão); `compose config` byte-idêntico 2×

**Constraints**: Regra 5 (fronteira = 1 ponto `f0-008` FR-013 via ADR-017, 8ª execução); FR-002 da 008 invariante (zero supressão — vale para `trivy image` também); `restart: "no"` explícito em tudo; zero senha literal versionada; zero `latest`; zero `privileged`/`docker.sock`

**Scale/Scope**: 2 serviços núcleo + 6 `llm` (web, worker, CH, MinIO, + PG/Redis do núcleo) + 6 `observability`; `gateway` fora (Fase 2); proxy/TLS fora (DevOps futuro)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | pins `tag@digest` congelados; `restart: "no"` explícito; `compose config` byte-idêntico; portas fixas |
| II Spec antes | ✅ PASS | spec 015 + clarify (7 bullets) precedem; research vinculante Q1–Q10 |
| III Teste antes | ✅ PASS | oráculo vermelho→verde em commits separados; 15ª linha do manifest no vermelho junto (precedente E5/013) |
| IV Dados antes | ✅ PASS | data-model + contracts antes do verde; gateway adiado por falta de consumidor |
| V Lei Zero | ✅ PASS | zero senha literal; `.env`/`secrets/` ignorados e provados; `_FILE` onde suportado |
| VI Oráculo | ✅ PASS | 12–16 asserções novas identidade; fronteira de 1 ponto via ADR-017 |
| VII Auto-reparo | ✅ PASS | quita B2 da ADR-017 (`trivy image` pleno); consome auditoria 009–012 |
| VIII Elo verificado | ✅ PASS | cada tag/digest via Hub API + docs oficiais + compose-spec, fetch 2026-09-08/09 |
| IX Agnosticismo | ✅ PASS | infra do motor; nada sobre stacks-alvo |
| X Observabilidade | ✅ PASS | FRs no oráculo; SC-006 com evidência; falha nomeia FR |

**Re-check pós-Phase 1 (2026-09-09)**: sem violações; desenho não introduziu `build:`, credencial, proxy ou escrita nova além do declarado. Pass.

## Declaração de impacto de fronteira (insumo à ADR — ADR-017, 8ª execução)

Varredura mecânica 2026-09-08/09 (`grep -n -i "docker-compose|docker/|compose"` sobre os 14 oráculos; literais `Dockerfile`, `.dockerignore`, `privileged`, `docker.sock` conferidos — 0 ocorrências fora do abaixo):

| # | Oráculo | Ajuste (forma exata, só na Fase C) |
|---|---|---|
| 1 | `f0-008` FR-013 (linhas 80, 509) | admitir `docker-compose.yml` + `docker/` **se** sob jurisdição 015 (pins `tag@digest`, sem senha literal, sem `latest`); resto da FR intacto (lefthook/gitleaks/packages seguem proibidos) |

Manifest regenerado na Fase C citando a ADR. Qualquer outro vermelho herdado = conflito novo, ADR própria, nunca fix direto. Arquivos novos (`docker-compose.yml`, `docker/`, `.env.example` estendido) são livres desde que: sem senha literal (gitleaks + grep), sem `latest`, sem `build:`, sem `privileged`/`docker.sock`.

## Project Structure

### Documentation (this feature)

```text
specs/015-docker-compose/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (decisões consolidadas do research vinculante)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (oracle-cli.md — mapa FR↔asserção)
├── checklists/
│   └── requirements.md  # Spec quality (16/16)
├── evidence/            # TESTS: red.txt + green.txt (Fase TESTS)
├── spec.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root — só manifesto de infra, sem produção)

```text
docker-compose.yml                # NOVO: name fkx, núcleo + profiles, tudo tag@digest + restart no
docker/
├── postgres/
│   └── 01-users-dbs.sql          # NOVO: usuários fkx/langfuse sem SUPERUSER + bancos (:ro)
├── prometheus/
│   └── prometheus.yml            # NOVO: scrape do núcleo + alloy (:ro)
├── alloy/
│   └── config.alloy              # NOVO: pipeline OTel → Loki/Tempo/Prom (:ro)
└── grafana/
    └── provisioning/             # NOVO: datasources Loki/Tempo/Prom auto-configurados
.env.example                      # ESTENDIDO: todas as chaves com placeholders (zero segredo)
.gitignore                        # VERIFICAR: .env/.env.*/secrets/ ignorados (já: .env sim; secrets/ a confirmar)
scripts/verify/
├── f0-015-docker-compose.sh      # NOVO: 12–16 asserções identidade
└── manifest.sha256               # +15ª linha (no commit vermelho junto, precedente E5)
specs/README.md                   # 015 ✅ + hash (só no CONVERGE)
```

**Structure Decision**: manifesto-de-infra-e-oráculo; `docker/` só guarda configs montadas `:ro` e init SQL (nunca imagens próprias); nenhum `Dockerfile`, nenhum proxy, nenhum workflow novo.

## Complexity Tracking

> Sem violações no Constitution Check — nada a justificar.

## Fases de execução (para TASKS/IMPLEMENT)

- **Fase A (esqueleto)**: oráculo `f0-015` esqueleto + 15ª linha do manifest (o manifest inteiro é verificado por `f0-009/010/011/012` — separar do vermelho causaria regressão, precedente E5/013).
- **Fase B (vermelho 🔴)**: `test(harness)`: oráculo reprovando sobre estado sem compose (commit separado, `evidence/red.txt`).
- **Fase C (verde 🟢)**: `feat(compose)`: `docker-compose.yml` + `docker/` + `.env.example` (ponto ADR-017 aplicado AQUI, nunca antes); asserts live executados com daemon ativo e evidência em `green.txt`; se migração Langfuse reprovar no PG18, fallback PG17 dedicado entra aqui como divergência declarada.
- **Fase D (converge)**: harness 15/15 + manifest 15/15 + `tasks.md` zero `[ ]` + `specs/README.md` `015 ✅` + `AGENTS.md`; SC-006 🧑 como prova ponta a ponta com daemon.
