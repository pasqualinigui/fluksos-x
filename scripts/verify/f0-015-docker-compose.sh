#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 015 (0.8): docker-compose sob demanda
#
# Contrato de assercoes deste item:
#   specs/015-docker-compose/spec.md (16 FRs, 7 SCs, 5 US + CLARIFY 7/7)
#   specs/015-docker-compose/plan.md (Fases A-D, D1-D7, fronteira Q10)
#   specs/015-docker-compose/contracts/oracle-cli.md (mapa identidade 16 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-015-docker-compose.md (Q1-Q10 D1-D7, 2026-09-08/09)
#   specs/015-docker-compose/research.md (decisoes + pins tag@digest)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento, protegem invariante):
#     FR-011 (ausencia de gateway/litellm), FR-013 (contrato auto-verificavel)
#   Comportamento (carregam o vermelho):
#     FR-001..010, FR-012, FR-014..016
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-014 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#      O oraculo NAO sobe container: prova live com daemon pertence ao T026.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Medicao de exit code: via redirect + $? (nunca $? apos pipe — research Q4/013).
# Self-check em SERIE (ADR-031): f0-001..f0-014 sequenciais, nunca concorrentes.
#
# Decisoes pinadas verificadas 2026-09-09 (Hub API + docs oficiais):
#   D1 postgres 18.6-trixie uuidv7 volume /var/lib/postgresql (Q1)
#   D2 redis 8.8.2-trixie AOF+noeviction, tri-licenca sem impacto local (Q2)
#   D3 langfuse OSS 4.30.0 MIT, TELEMETRY=false, PG18 compartilhado (Q3)
#   D4 name fkx, zero build, profiles, restart no, portas 127.0.0.1 (Q4)
#   D5 read_only+tmpfs, cap_drop ALL, no-new-privileges, sem privileged/sock (Q5)
#   D6 sem proxy, sem Dockerfile (Q6) · D7 compose config + trivy + gitleaks (Q7)
# =============================================================================

set -uo pipefail
LC_ALL=C
export LC_ALL
GIT_PAGER=cat
export GIT_PAGER
PAGER=cat
export PAGER

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
SELF="${SCRIPT_DIR}/$(basename -- "${BASH_SOURCE[0]}")"

QUIET=0
LIST=0
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    --list)  LIST=1 ;;
    *) printf 'erro de uso: parametro desconhecido %s\n' "$arg" >&2
       printf 'uso: %s [--quiet] [--list]\n' "$(basename -- "$SELF")" >&2
       exit 2 ;;
  esac
done

declare -a R_STATUS=() R_ID=() R_DESC=() R_SEV=() R_EVID=()

pass() { R_STATUS+=("ok");   R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("-");  R_EVID+=(""); }
fail() { R_STATUS+=("bad");  R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("$3"); R_EVID+=("${4:-}"); }
skip() { R_STATUS+=("skip"); R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("-");  R_EVID+=("${3:-}"); }

declare -A CANON=(
  ["FR-001"]="compose name fkx zero build imagens tag@digest"
  ["FR-002"]="nucleo postgres+redis sem profile, obs+llm opt-in, gateway ausente"
  ["FR-003"]="restart no explicito em todo servico"
  ["FR-004"]="depends_on longo com condicao + healthcheck com start_period"
  ["FR-005"]="zero segredo literal, env fora do indice, _FILE no banco"
  ["FR-006"]="portas 127.0.0.1 no mapa fixo, backend internal"
  ["FR-007"]="mem cpus pids_limit + logging com rotacao"
  ["FR-008"]="read_only cap_drop ALL no-new-privileges, sem privileged/sock"
  ["FR-009"]="profile llm 4.30.0 + CH25.12 + MinIO, TELEMETRY=false"
  ["FR-010"]="profile observability 6 pins + provisioning"
  ["FR-011"]="ausencia de gateway/litellm + pin registrado"
  ["FR-012"]="PG compartilhado fkx+langfuse sem SUPERUSER via init SQL"
  ["FR-013"]="contrato: list 16 exit2 2x <5s self-check serie"
  ["FR-014"]="trivy image por pin zero HIGH CRITICAL ou skip sem daemon"
  ["FR-015"]="compose config byte-identico 2x"
  ["FR-016"]="README 015 hash + zero [ ] + vermelho-verde + self-check serie"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014 FR-015 FR-016"

COMPOSE="$ROOT/docker-compose.yml"
DOCKERD="$ROOT/docker"
ENVEX="$ROOT/.env.example"
INITSQL="$ROOT/docker/postgres/01-users-dbs.sql"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS015="$ROOT/specs/015-docker-compose/tasks.md"
README_SPECS="$ROOT/specs/README.md"
RESEARCH015="$ROOT/specs/015-docker-compose/research.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"
ORACLE5="$SCRIPT_DIR/f0-005-pytest.sh"
ORACLE6="$SCRIPT_DIR/f0-006-ruff.sh"
ORACLE7="$SCRIPT_DIR/f0-007-mypy.sh"
ORACLE8="$SCRIPT_DIR/f0-008-pip-audit.sh"
ORACLE9="$SCRIPT_DIR/f0-009-lefthook.sh"
ORACLE10="$SCRIPT_DIR/f0-010-ci-completo.sh"
ORACLE11="$SCRIPT_DIR/f0-011-core.sh"
ORACLE12="$SCRIPT_DIR/f0-012-cli.sh"
ORACLE13="$SCRIPT_DIR/f0-013-release.sh"
ORACLE14="$SCRIPT_DIR/f0-014-dependabot.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# Linhas de codigo (comentario nao decide assercao — precedente FR-002/014).
codeonly() { grep -v "^[[:space:]]*#" "$1" 2>/dev/null || true; }

# Nomes dos servicos (indentacao exata de 2 espacos sob services:).
svc_names() {
  awk '/^services:/{s=1;next} /^[^[:space:]]/{s=0} s==1 && /^  [A-Za-z0-9_-]+:/{sub(/^  /,""); sub(/:.*/,""); print}' "$COMPOSE" 2>/dev/null || true
}

# Bloco de um servico (da declaracao ate o proximo servico ou secao top-level).
svc_block() {
  awk -v n="$1" '
    /^services:/{s=1;next}
    /^[^[:space:]]/{s=0}
    s==1 && /^  [A-Za-z0-9_-]+:/{cur=$0; sub(/^  /,"",cur); sub(/:.*/,"",cur)}
    s==1 && cur==n{print}
  ' "$COMPOSE" 2>/dev/null || true
}

# =============================================================================
# FR-001: compose name fkx, zero build, imagens tag@digest da tabela de pins
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$COMPOSE" ]; then
  FR1_OK=0; EVID1="${EVID1}docker-compose.yml ausente (D4); "
else
  CODE1=$(codeonly "$COMPOSE")
  if ! echo "$CODE1" | grep -q "^name: fkx" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem name: fkx; "
  fi
  if echo "$CODE1" | grep -qE "^[[:space:]]+build:" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}bloco build: presente (vedado, D5); "
  fi
  while IFS= read -r line; do
    img=$(echo "$line" | sed -E 's/^[[:space:]]*image:[[:space:]]*//')
    if ! echo "$img" | grep -qE '^[^@]+@sha256:[0-9a-f]{64}$' 2>/dev/null; then
      FR1_OK=0; EVID1="${EVID1}image sem tag@digest: $img; "
    elif [ -f "$RESEARCH015" ] && ! grep -Fq "$img" "$RESEARCH015" 2>/dev/null; then
      FR1_OK=0; EVID1="${EVID1}pin fora da tabela congelada: $img; "
    fi
  done <<< "$(echo "$CODE1" | grep -E '^[[:space:]]*image:' 2>/dev/null || true)"
  if ! echo "$CODE1" | grep -q "image:" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}nenhum image: declarado; "
  fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: nucleo postgres+redis sem profile; obs+llm opt-in; gateway ausente;
# Redis AOF + noeviction + volume
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$COMPOSE" ]; then
  FR2_OK=0; EVID2="${EVID2}docker-compose.yml ausente; "
else
  for svc in postgres redis; do
    blk=$(svc_block "$svc")
    if [ -z "$blk" ]; then
      FR2_OK=0; EVID2="${EVID2}nucleo sem servico $svc; "
    elif echo "$blk" | grep -q "profiles:" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}$svc com profile (nucleo nao tem); "
    fi
  done
  if ! grep -q "profiles:" "$COMPOSE" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}nenhum profile declarado (D4); "
  else
    for prof in observability llm; do
      if ! grep -q "profiles:.*$prof\|- $prof" "$COMPOSE" 2>/dev/null; then
        FR2_OK=0; EVID2="${EVID2}profile $prof ausente; "
      fi
    done
  fi
  RBLK=$(svc_block "redis")
  if [ -n "$RBLK" ]; then
    if ! echo "$RBLK" | grep -q "appendonly" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}redis sem appendonly (D2/Q6); "
    fi
    if ! echo "$RBLK" | grep -q "noeviction" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}redis sem maxmemory-policy noeviction; "
    fi
    if ! echo "$RBLK" | grep -q "volumes:" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}redis sem volume de dados; "
    fi
  fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: restart no explicito em todo servico (ausencia reprova)
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$COMPOSE" ]; then
  FR3_OK=0; EVID3="${EVID3}docker-compose.yml ausente; "
else
  while IFS= read -r svc; do
    [ -z "$svc" ] && continue
    blk=$(svc_block "$svc")
    if ! echo "$blk" | grep -qE '^[[:space:]]+restart: "no"' 2>/dev/null; then
      FR3_OK=0; EVID3="${EVID3}$svc sem restart: \"no\" explicito (D4); "
    fi
    if echo "$blk" | grep -qE '^[[:space:]]+restart: "(always|unless-stopped|on-failure)' 2>/dev/null; then
      FR3_OK=0; EVID3="${EVID3}$svc com restart proibido (segundo plano); "
    fi
  done <<< "$(svc_names)"
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: depends_on longo com condicao + healthcheck com start_period
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$COMPOSE" ]; then
  FR4_OK=0; EVID4="${EVID4}docker-compose.yml ausente; "
else
  while IFS= read -r svc; do
    [ -z "$svc" ] && continue
    blk=$(svc_block "$svc")
    case "$svc" in
      postgres|redis) ;;
      *)
        if ! echo "$blk" | grep -q "depends_on:" 2>/dev/null; then
          FR4_OK=0; EVID4="${EVID4}$svc sem depends_on; "
        elif ! echo "$blk" | grep -qE "condition: service_(healthy|completed_successfully)" 2>/dev/null; then
          FR4_OK=0; EVID4="${EVID4}$svc depends_on sem condition; "
        fi
        ;;
    esac
    if echo "$blk" | grep -q "depends_on:" 2>/dev/null; then
      if echo "$blk" | awk '/depends_on:/{d=1;next} /^    [A-Za-z]/&&d==1&&$0!~/condition:|restart:|required:/{short=1} END{exit short?0:1}'; then
        FR4_OK=0; EVID4="${EVID4}$svc depends_on em forma curta; "
      fi
    fi
    if echo "$blk" | grep -q "ports:" 2>/dev/null; then
      if ! echo "$blk" | grep -q "healthcheck:" 2>/dev/null; then
        FR4_OK=0; EVID4="${EVID4}$svc publica porta sem healthcheck; "
      elif ! echo "$blk" | grep -q "start_period:" 2>/dev/null; then
        FR4_OK=0; EVID4="${EVID4}$svc healthcheck sem start_period; "
      fi
    fi
  done <<< "$(svc_names)"
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: zero segredo literal; .env/secrets fora do indice; _FILE no banco
# Lei Zero: comentario nao decide, mas literal em comentario TAMBEM reprova
# (segredo em comentario e segredo versionado do mesmo jeito).
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$COMPOSE" ]; then
  FR5_OK=0; EVID5="${EVID5}docker-compose.yml ausente; "
else
  while IFS= read -r line; do
    if echo "$line" | grep -qiE 'password|passwd|secret|_key|api_key|token' 2>/dev/null; then
      if ! echo "$line" | grep -qE '\$\{[^}]+\}|_FILE|/run/secrets|CHANGEME-NUNCA' 2>/dev/null; then
        if echo "$line" | grep -qiE ':\s*["'"'"']?[^$"'"'"'[:space:]#][^#]*["'"'"']?\s*(#|$)' 2>/dev/null; then
          FR5_OK=0; EVID5="${EVID5}possivel segredo literal: $(echo "$line" | cut -c1-80); "
        fi
      fi
    fi
  done <<< "$(grep -v "^[[:space:]]*#" "$COMPOSE" 2>/dev/null || true)"
  if git -C "$ROOT" ls-files 2>/dev/null | grep -qx ".env"; then
    FR5_OK=0; EVID5="${EVID5}.env rastreado (Lei Zero); "
  fi
  if git -C "$ROOT" ls-files 2>/dev/null | grep -q "^secrets/"; then
    FR5_OK=0; EVID5="${EVID5}secrets/ rastreado (Lei Zero); "
  fi
  PBLK=$(svc_block "postgres")
  if [ -n "$PBLK" ]; then
    if ! echo "$PBLK" | grep -q "POSTGRES_PASSWORD_FILE" 2>/dev/null; then
      FR5_OK=0; EVID5="${EVID5}postgres sem POSTGRES_PASSWORD_FILE (D6); "
    fi
  fi
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: portas 127.0.0.1 no mapa fixo; backend internal
# Mapa: grafana 3000, langfuse-web 3001, postgres 5432, redis 6379.
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$COMPOSE" ]; then
  FR6_OK=0; EVID6="${EVID6}docker-compose.yml ausente; "
else
  CODE6=$(codeonly "$COMPOSE")
  while IFS= read -r line; do
    if ! echo "$line" | grep -q "127.0.0.1" 2>/dev/null; then
      FR6_OK=0; EVID6="${EVID6}porta sem 127.0.0.1: $(echo "$line" | cut -c1-80); "
    fi
  done <<< "$(echo "$CODE6" | awk '/ports:/{p=1;next} /^    [A-Za-z_]+:/{p=0} /^  [A-Za-z]/{p=0} p==1 && NF{print}' || true)"
  for spec in "grafana:3000" "langfuse-web:3001" "postgres:5432" "redis:6379"; do
    svc="${spec%%:*}"; port="${spec##*:}"
    blk=$(svc_block "$svc")
    if [ -n "$blk" ] && ! echo "$blk" | grep -q "$port" 2>/dev/null; then
      FR6_OK=0; EVID6="${EVID6}$svc fora do mapa (porta $port); "
    fi
  done
  if ! echo "$CODE6" | grep -q "internal: true" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}rede backend sem internal: true; "
  fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: limites efetivos (F6: service-level, deploy e swarm-only) + logs
# =============================================================================
FR7_OK=1; EVID7=""
if [ ! -f "$COMPOSE" ]; then
  FR7_OK=0; EVID7="${EVID7}docker-compose.yml ausente; "
else
  while IFS= read -r svc; do
    [ -z "$svc" ] && continue
    blk=$(svc_block "$svc")
    for key in "mem_limit:" "mem_reservation:" "cpus:" "pids_limit:"; do
      if ! echo "$blk" | grep -q "$key" 2>/dev/null; then
        FR7_OK=0; EVID7="${EVID7}$svc sem $key (F6); "
      fi
    done
    if ! echo "$blk" | grep -q "logging:" 2>/dev/null; then
      FR7_OK=0; EVID7="${EVID7}$svc sem logging; "
    else
      if ! echo "$blk" | grep -q "max-size" 2>/dev/null; then
        FR7_OK=0; EVID7="${EVID7}$svc logging sem rotacao (max-size); "
      fi
    fi
  done <<< "$(svc_names)"
fi
if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi

# =============================================================================
# FR-008: read_only + cap_drop ALL + no-new-privileges; sem privileged/sock
# =============================================================================
FR8_OK=1; EVID8=""
if [ ! -f "$COMPOSE" ]; then
  FR8_OK=0; EVID8="${EVID8}docker-compose.yml ausente; "
else
  CODE8=$(codeonly "$COMPOSE")
  if echo "$CODE8" | grep -qE "privileged:[[:space:]]*true" 2>/dev/null; then
    FR8_OK=0; EVID8="${EVID8}privileged: true presente (vedado); "
  fi
  if echo "$CODE8" | grep -q "docker.sock" 2>/dev/null; then
    FR8_OK=0; EVID8="${EVID8}montagem de docker.sock (vedada); "
  fi
  while IFS= read -r svc; do
    [ -z "$svc" ] && continue
    blk=$(svc_block "$svc")
    if ! echo "$blk" | grep -qE '^[[:space:]]+read_only: true' 2>/dev/null; then
      FR8_OK=0; EVID8="${EVID8}$svc sem read_only: true; "
    fi
    if ! echo "$blk" | grep -q "cap_drop" 2>/dev/null || ! echo "$blk" | grep -q "ALL" 2>/dev/null; then
      FR8_OK=0; EVID8="${EVID8}$svc sem cap_drop ALL; "
    fi
    if ! echo "$blk" | grep -q "no-new-privileges:true" 2>/dev/null; then
      FR8_OK=0; EVID8="${EVID8}$svc sem no-new-privileges; "
    fi
  done <<< "$(svc_names)"
fi
if [ "$FR8_OK" = "1" ]; then pass "FR-008" "${CANON[FR-008]}"; else fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID8"; fi

# =============================================================================
# FR-009: profile llm — web+worker 4.30.0, CH 25.12, MinIO, TELEMETRY=false
# Prova de migracao live pertence ao T026 (oraculo nao sobe container).
# =============================================================================
FR9_OK=1; EVID9=""
if [ ! -f "$COMPOSE" ]; then
  FR9_OK=0; EVID9="${EVID9}docker-compose.yml ausente; "
else
  CODE9=$(codeonly "$COMPOSE")
  for pin in "langfuse/langfuse:4.30.0" "langfuse/langfuse-worker:4.30.0" "clickhouse/clickhouse-server:25.12" "minio/minio:RELEASE.2025-09-07T16-13-09Z-cpuv1"; do
    if ! echo "$CODE9" | grep -Fq "$pin" 2>/dev/null; then
      FR9_OK=0; EVID9="${EVID9}pin ausente no profile llm: $pin; "
    fi
  done
  if ! echo "$CODE9" | grep -q "TELEMETRY_ENABLED=false\|TELEMETRY_ENABLED: \"false\"\|TELEMETRY_ENABLED: 'false'" 2>/dev/null; then
    if ! grep -q "TELEMETRY_ENABLED" "$ROOT/.env.example" 2>/dev/null; then
      FR9_OK=0; EVID9="${EVID9}TELEMETRY_ENABLED=false nem no compose nem no .env.example; "
    fi
  fi
  if ! echo "$CODE9" | grep -q "DATABASE_URL" 2>/dev/null; then
    FR9_OK=0; EVID9="${EVID9}langfuse sem DATABASE_URL no PG compartilhado; "
  fi
  if [ ! -f "$INITSQL" ]; then
    FR9_OK=0; EVID9="${EVID9}docker/postgres/01-users-dbs.sql ausente (FR-012); "
  fi
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# FR-010: profile observability — 6 pins + provisioning entre si
# =============================================================================
FR10_OK=1; EVID10=""
if [ ! -f "$COMPOSE" ]; then
  FR10_OK=0; EVID10="${EVID10}docker-compose.yml ausente; "
else
  CODE10=$(codeonly "$COMPOSE")
  for pin in "grafana/grafana:13.2.1" "grafana/alloy:v1.19.2" "grafana/loki:3.7.7" "grafana/tempo:3.0.3" "grafana/pyroscope:2.3.0" "prom/prometheus:v3.14.0"; do
    if ! echo "$CODE10" | grep -Fq "$pin" 2>/dev/null; then
      FR10_OK=0; EVID10="${EVID10}pin ausente no profile observability: $pin; "
    fi
  done
  if [ ! -d "$ROOT/docker/grafana/provisioning" ]; then
    FR10_OK=0; EVID10="${EVID10}docker/grafana/provisioning ausente; "
  fi
  if [ ! -f "$ROOT/docker/prometheus/prometheus.yml" ]; then
    FR10_OK=0; EVID10="${EVID10}docker/prometheus/prometheus.yml ausente; "
  fi
  if [ ! -f "$ROOT/docker/alloy/config.alloy" ]; then
    FR10_OK=0; EVID10="${EVID10}docker/alloy/config.alloy ausente; "
  fi
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: ausencia de gateway/litellm + pin registrado (guarda)
# =============================================================================
FR11_OK=1; EVID11=""
if [ -f "$COMPOSE" ]; then
  CODE11=$(codeonly "$COMPOSE")
  if echo "$CODE11" | grep -qi "litellm\|gateway" 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}gateway/litellm no compose (adiado a Fase 2, D5); "
  fi
fi
if [ -f "$RESEARCH015" ]; then
  if ! grep -q "v1.100.0" "$RESEARCH015" 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}pin litellm v1.100.0 fora do research (reuso Fase 2); "
  fi
else
  FR11_OK=0; EVID11="${EVID11}research.md da spec ausente; "
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: PG compartilhado fkx+langfuse, sem SUPERUSER, via init SQL
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$INITSQL" ]; then
  FR12_OK=0; EVID12="${EVID12}docker/postgres/01-users-dbs.sql ausente (D3/Q7); "
else
  for db in fkx langfuse; do
    if ! grep -qi "$db" "$INITSQL" 2>/dev/null; then
      FR12_OK=0; EVID12="${EVID12}init SQL sem banco/usuario $db; "
    fi
  done
  if grep -qi "SUPERUSER" "$INITSQL" 2>/dev/null; then
    if ! grep -qi "NOSUPERUSER" "$INITSQL" 2>/dev/null; then
      FR12_OK=0; EVID12="${EVID12}init SQL concede SUPERUSER (vedado, Q5); "
    fi
  fi
fi
if [ -f "$COMPOSE" ]; then
  NPG=$(codeonly "$COMPOSE" | grep -c "image: postgres" 2>/dev/null || true)
  NPG=$(echo "$NPG" | tr -d '[:space:]')
  if [ -n "$NPG" ] && [ "$NPG" != "0" ] && [ "$NPG" != "1" ]; then
    FR12_OK=0; EVID12="${EVID12}$NPG servicos postgres (compartilhado = 1); "
  fi
fi
if [ "$FR12_OK" = "1" ]; then pass "FR-012" "${CANON[FR-012]}"; else fail "FR-012" "${CANON[FR-012]}" "alta" "$EVID12"; fi

# =============================================================================
# FR-013: contrato auto-verificavel (list 16, exit2, 2x <5s, self-check serie)
# =============================================================================
FR13_OK=1; EVID13=""
LIST_COUNT=$(bash "$SELF" --list 2>/dev/null | wc -l || true)
LIST_COUNT=$(echo "$LIST_COUNT" | tr -d '[:space:]')
if [ "$LIST_COUNT" != "16" ]; then
  FR13_OK=0; EVID13="${EVID13}--list enumera $LIST_COUNT != 16; "
fi
INVALID_RC=0
bash "$SELF" --invalido > /dev/null 2>&1 || INVALID_RC=$?
if [ "$INVALID_RC" != "2" ]; then
  FR13_OK=0; EVID13="${EVID13}--invalido exit $INVALID_RC != 2; "
fi
if [ "$NESTED" != "1" ]; then
  T1=$(date +%s%N)
  OUT1=$(FKX_ORACLE_NESTED=1 bash "$SELF" --quiet 2>&1 || true)
  T2=$(date +%s%N)
  OUT2=$(FKX_ORACLE_NESTED=1 bash "$SELF" --quiet 2>&1 || true)
  T3=$(date +%s%N)
  ELAPSED1=$(( (T2 - T1) / 1000000 ))
  ELAPSED2=$(( (T3 - T2) / 1000000 ))
  if [ "$OUT1" != "$OUT2" ]; then
    FR13_OK=0; EVID13="${EVID13}2 execucoes divergem; "
  fi
  if [ "$ELAPSED1" -gt 5000 ] || [ "$ELAPSED2" -gt 5000 ]; then
    FR13_OK=0; EVID13="${EVID13}execucao >5s (${ELAPSED1}ms/${ELAPSED2}ms); "
  fi
fi
if [ "$FR13_OK" = "1" ]; then pass "FR-013" "${CANON[FR-013]}"; else fail "FR-013" "${CANON[FR-013]}" "alta" "$EVID13"; fi

# =============================================================================
# FR-014: trivy image por pin zero HIGH CRITICAL — ou skip sem daemon/imagem
# (precedente 008 FR-009: sem Docker ⇒ ⏭️, nunca 🔴)
# =============================================================================
FR14_OK=1; EVID14=""
HAVE_TRIVY=0
if command -v trivy > /dev/null 2>&1; then HAVE_TRIVY=1; fi
DAEMON_UP=0
if docker info > /dev/null 2>&1; then DAEMON_UP=1; fi
if [ "$HAVE_TRIVY" = "0" ] && [ "$DAEMON_UP" = "0" ]; then
  skip "FR-014" "${CANON[FR-014]}" "sem trivy e sem daemon Docker (precedente 008)"
  FR14_SKIP=1
else
  PINS="postgres:18.6-trixie redis:8.8.2-trixie langfuse/langfuse:4.30.0 langfuse/langfuse-worker:4.30.0 clickhouse/clickhouse-server:25.12 minio/minio:RELEASE.2025-09-07T16-13-09Z-cpuv1 grafana/grafana:13.2.1 grafana/alloy:v1.19.2 grafana/loki:3.7.7 grafana/tempo:3.0.3 grafana/pyroscope:2.3.0 prom/prometheus:v3.14.0"
  if [ "$HAVE_TRIVY" = "1" ]; then
    TRIVY_BIN="trivy"
  else
    TRIVY_BIN="docker run --rm aquasec/trivy:0.74.0"
  fi
  for pin in $PINS; do
    if [ "$DAEMON_UP" = "1" ] && ! docker image inspect "$pin" > /dev/null 2>&1; then
      skip "FR-014" "${CANON[FR-014]}" "imagem $pin ausente local (pull fora do oraculo)"
      FR14_SKIP=1
      break
    fi
  done
  if [ "${FR14_SKIP:-0}" != "1" ]; then
    for pin in $PINS; do
      TOUT=$($TRIVY_BIN image --severity HIGH,CRITICAL --exit-code 1 --quiet --no-progress "$pin" 2>&1 || true)
      # shellcheck disable=SC2181
      if [ -n "$TOUT" ]; then
        FR14_OK=0; EVID14="${EVID14}$pin: HIGH/CRITICAL ou erro de scan; "
        break
      fi
    done
  fi
fi
if [ "${FR14_SKIP:-0}" = "1" ]; then :; elif [ "$FR14_OK" = "1" ]; then pass "FR-014" "${CANON[FR-014]}"; else fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"; fi

# =============================================================================
# FR-015: compose config byte-identico 2x (sem daemon)
# =============================================================================
FR15_OK=1; EVID15=""
if [ ! -f "$COMPOSE" ]; then
  FR15_OK=0; EVID15="${EVID15}docker-compose.yml ausente; "
elif ! command -v docker > /dev/null 2>&1 || ! docker compose version > /dev/null 2>&1; then
  FR15_OK=0; EVID15="${EVID15}plugin docker compose indisponivel (dependencia dura); "
else
  if [ "$NESTED" != "1" ]; then
    C1=$(docker compose -f "$COMPOSE" config 2>/dev/null || true)
    C2=$(docker compose -f "$COMPOSE" config 2>/dev/null || true)
    if [ -z "$C1" ]; then
      FR15_OK=0; EVID15="${EVID15}compose config vazio/erro; "
    elif [ "$C1" != "$C2" ]; then
      FR15_OK=0; EVID15="${EVID15}compose config diverge entre execucoes; "
    fi
  fi
fi
if [ "$FR15_OK" = "1" ]; then pass "FR-015" "${CANON[FR-015]}"; else fail "FR-015" "${CANON[FR-015]}" "alta" "$EVID15"; fi

# =============================================================================
# FR-016: README 015 hash + zero [ ] + vermelho-verde + self-check serie
# =============================================================================
FR16_OK=1; EVID16=""
if [ ! -f "$README_SPECS" ]; then
  FR16_OK=0; EVID16="${EVID16}specs/README.md ausente; "
elif ! grep -iq "015.*docker.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR16_OK=0; EVID16="${EVID16}README sem \"015.*docker.*✅.*hash\"; "
fi
if [ ! -f "$TASKS015" ]; then
  FR16_OK=0; EVID16="${EVID16}specs/015-docker-compose/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS015" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR16_OK=0; EVID16="${EVID16}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*015" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(compose).*015" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR16_OK=0; EVID16="${EVID16}par vermelho/verde 015 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR16_OK=0; EVID16="${EVID16}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
fi
if [ ! -f "$MANIFEST" ]; then
  FR16_OK=0; EVID16="${EVID16}manifest.sha256 ausente; "
elif ! (cd "$ROOT" && sha256sum -c "$MANIFEST" > /dev/null 2>&1); then
  FR16_OK=0; EVID16="${EVID16}manifest.sha256 diverge (sha256sum -c); "
fi
if [ "$NESTED" != "1" ]; then
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" \
           "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11" "$ORACLE12" \
           "$ORACLE13" "$ORACLE14"; do
    if [ ! -x "$o" ]; then
      FR16_OK=0; EVID16="${EVID16}$(basename "$o") ausente ou nao executavel; "
      break
    else
      rc=0
      timeout 5 env FKX_ORACLE_NESTED=1 bash "$o" --quiet > /dev/null 2>&1 || rc=$?
      if [ "$rc" != "0" ] && [ "$rc" != "124" ]; then
        FR16_OK=0; EVID16="${EVID16}$(basename "$o") --quiet reprovou (rc=$rc); "
        break
      fi
    fi
  done
fi
if [ "$FR16_OK" = "1" ]; then pass "FR-016" "${CANON[FR-016]}"; else fail "FR-016" "${CANON[FR-016]}" "alta" "$EVID16"; fi

# =============================================================================
# Relatório
# =============================================================================
TOTAL=${#R_ID[@]}
OK=0; BAD=0; SKIPPED=0
CRIT=0; ALTA=0; MEDIA=0

for i in "${!R_ID[@]}"; do
  case "${R_STATUS[$i]}" in
    ok)   OK=$((OK+1));           SYM="✅" ;;
    skip) SKIPPED=$((SKIPPED+1)); SYM="⏭️" ;;
    *)    BAD=$((BAD+1));         SYM="🔴"
          case "${R_SEV[$i]}" in
            critica) CRIT=$((CRIT+1)) ;;
            alta)    ALTA=$((ALTA+1)) ;;
            *)       MEDIA=$((MEDIA+1)) ;;
          esac ;;
  esac
  if [ "$QUIET" = "1" ] && [ "${R_STATUS[$i]}" = "ok" ]; then continue; fi
  printf '%s %-8s %s\n' "$SYM" "${R_ID[$i]}" "${R_DESC[$i]}"
  if [ "${R_STATUS[$i]}" != "ok" ] && [ -n "${R_EVID[$i]}" ]; then
    printf '%s\n' "${R_EVID[$i]}" | while IFS= read -r line; do
      [ -n "$line" ] && printf '           evidencia: %s\n' "$line"
    done
  fi
done

printf '\n'
if [ "$BAD" -eq 0 ]; then
  printf 'Resultado: %d/%d asserções aprovadas' "$OK" "$TOTAL"
  [ "$SKIPPED" -gt 0 ] && printf ' (%d não aplicáveis)' "$SKIPPED"
  printf ' — CONFORME\n'
  exit 0
else
  printf 'Resultado: %d/%d asserções aprovadas — %d violação(ões)' "$OK" "$TOTAL" "$BAD"
  printf ' (critica: %d, alta: %d, media: %d)' "$CRIT" "$ALTA" "$MEDIA"
  [ "$SKIPPED" -gt 0 ] && printf ' — %d não aplicaveis' "$SKIPPED"
  printf ' — NAO CONFORME\n'
  exit 1
fi
