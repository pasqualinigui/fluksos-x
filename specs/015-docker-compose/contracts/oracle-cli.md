# Contrato do oráculo — `f0-015-docker-compose.sh` (mapa FR↔asserção, ADR-015b)

Identidade 1:1 salvo onde indicado. Self-check `f0-001…f0-014` em série (ADR-031) + `sha256sum -c` do manifest + CONVERGE (`tasks.md` zero `[ ]`) seguem o molde 005/010 e não re-numeram FRs.

| FR | Asserção |
|---|---|
| FR-001 | `name: fkx`; zero `build:`; todo `image:` casa `:[^@]+@sha256:[0-9a-f]{64}` e confere com a tabela de pins |
| FR-002 | núcleo = só `postgres`+`redis` sem profile; `observability`/`llm` presentes; `gateway`/`litellm` ausentes; Redis com `appendonly`+`noeviction`+volume |
| FR-003 | todo serviço declara `restart: "no"` (ausência reprova) |
| FR-004 | `depends_on` só forma longa com condição; todo serviço com porta/dependente tem `healthcheck` com `start_period` |
| FR-005 | zero senha literal em `docker-compose.yml`/`docker/*`/`.env.example`; `.env` e `secrets/` fora do índice; `_FILE` nas senhas de banco |
| FR-006 | portas só `127.0.0.1` no mapa fixo (3000/3001/5432/6379); backend `internal: true`; demais sem porta |
| FR-007 | todo serviço com `mem_limit`+`mem_reservation`+`cpus`+`pids_limit` (F6: `deploy.resources` é swarm-only) + `logging` com rotação |
| FR-008 | todo serviço com `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges:true`; zero `privileged`/`docker.sock` |
| FR-009 | profile `llm`: web+worker `4.30.0`, CH `25.12`, MinIO pinado, `TELEMETRY_ENABLED=false`; DATABASE_URL no PG compartilhado; init SQL presente; prova de migração live = T026 🧑 (oráculo não sobe container) |
| FR-010 | profile `observability`: 6 pins + provisioning entre si |
| FR-011 | (assegura a ausência) zero `gateway`/`litellm` no compose; pin registrado no research+contrato |
| FR-012 | init SQL com bancos `fkx`+`langfuse` e usuários sem SUPERUSER |
| FR-013 | contrato de interface obedecido (`--quiet`/`--list`, 0/1/2, 1 linha por asserção, só-leitura, determinismo 2×) |
| FR-014 | `trivy image` por pin: 0 com zero HIGH,CRITICAL, ou ⏭️ sem daemon |
| FR-015 | `compose config` byte-idêntico 2× (sem daemon) |
| FR-016 | self-check serial + manifest + `specs/README.md` + CONVERGE (molde; conta como asserções próprias, não renumera) |

Sem daemon: FR-009-live e FR-014-live viram ⏭️ (precedente 008 FR-009); estáticas decidem.
