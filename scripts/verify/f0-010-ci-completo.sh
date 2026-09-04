#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 010 (0.14): CI completo + branch protection
#
# Contrato de assercoes deste item:
#   specs/010-ci-completo/spec.md (13 FRs, 6 SCs, 3 US)
#   specs/010-ci-completo/plan.md (Fases A-E, D1-D10, fronteira ADR-017)
#   specs/010-ci-completo/contracts/oracle-cli.md (mapa identidade 13 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-010-ci-completo.md (Q1-Q10 D1-D10, 2026-09-04)
#   specs/010-ci-completo/research.md (5 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3):
#   Guardas (verdes-desde-o-nascimento, protegem invariante):
#     FR-001 (job verify preservado), FR-011 (contrato auto-verificavel)
#   Comportamento (carregam o vermelho 11/13):
#     FR-002..010/012/013
#
# Protecao de servidor e config, nao arquivo: este oraculo NUNCA usa token nem
# rede autenticada (Lei Zero). O lado servidor e cenario humano (mostrado em
# quickstart Cenário 4) com checklist versionado — precedente 003-T031.
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-009 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-09-04:
#   D1 checks frouxos + sem-bypass; protecao classica main+develop (Q1/Q2)
#   D2 sem reviews obrigatorios (deadlock com 1 mantenedor) (Q3)
#   D3 setup-uv v10.0.1 SHA 20cfd1bf + uv sync --frozen + cache auto (Q4)
#   D4 SHA+comentario; runner ubuntu-24.04 fixo (Q4/Q5)
#   D5 matriz ["3.12","3.13"] + fail-fast:false (Q6, CLARIFY)
#   D6 pytest-cov 7.1.0 (em dev desde 005) + --fail-under=90 medido 95% (Q7)
#   D7 commitlint v21.2.2 com os 11 tipos; range por evento (Q8, ANALYZE M3)
#   D8 gitleaks v8.30.1 via gitleaks-action v3.0.0 SHA e0c47f4f (Q9, ANALYZE M1)
#   D9 trivy-action v0.36.0 (aquasecurity/, 404 em aquasec/) (Q10)
#   D10 quarentena: timeout-minutes, sem continue-on-error/retry (Q10/ADR-019)
# =============================================================================

set -uo pipefail
LC_ALL=C
export LC_ALL

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
  ["FR-001"]="job verify presente e nao renomeado"
  ["FR-002"]="uses: por SHA + comentario; runner ubuntu-24.04"
  ["FR-003"]="setup-uv + uv sync --frozen + cache"
  ["FR-004"]="matriz 3.12+3.13 + fail-fast false"
  ["FR-005"]="8 jobs nominais unicos"
  ["FR-006"]="pytest-cov dev + fail-under 90"
  ["FR-007"]="commitlint 11 tipos + range por evento"
  ["FR-008"]="procedimento protecao versionado sem token"
  ["FR-009"]="frouxo + sem-bypass documentados"
  ["FR-010"]="timeout por job sem mascara"
  ["FR-011"]="contrato: list 13 exit2 2x <5s"
  ["FR-012"]="manifest 10/10 + self-check f0-001..009"
  ["FR-013"]="README 010 hash + zero [ ] + vermelho-verde"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013"

CI_YML="$ROOT/.github/workflows/ci.yml"
PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
COMMITLINT="$ROOT/commitlint.config.js"
PROC010="$ROOT/specs/010-ci-completo/branch-protection.md"
TASKS010="$ROOT/specs/010-ci-completo/tasks.md"
README_SPECS="$ROOT/specs/README.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"
ORACLE5="$SCRIPT_DIR/f0-005-pytest.sh"
ORACLE6="$SCRIPT_DIR/f0-006-ruff.sh"
ORACLE7="$SCRIPT_DIR/f0-007-mypy.sh"
ORACLE8="$SCRIPT_DIR/f0-008-pip-audit.sh"
ORACLE9="$SCRIPT_DIR/f0-009-lefthook.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: job verify presente e nao renomeado (guarda)
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-001" "${CANON[FR-001]}" "alta" ".github/workflows/ci.yml ausente"
elif ! grep -Eq '^[ ]*verify:' "$CI_YML" 2>/dev/null; then
  fail "FR-001" "${CANON[FR-001]}" "alta" "job verify ausente ou renomeado (fronteira 003)"
else
  pass "FR-001" "${CANON[FR-001]}"
fi

# =============================================================================
# FR-002: uses: por SHA + comentario; runner fixo
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$CI_YML" ]; then
  FR2_OK=0; EVID2="${EVID2}ci.yml ausente; "
else
  USES_TOTAL=$(grep -cE '^[ ]*uses:' "$CI_YML" 2>/dev/null || true)
  USES_SHA=$(grep -cE '^[ ]*uses:[ ]*[^ ]+@[0-9a-f]{40}' "$CI_YML" 2>/dev/null || true)
  USES_TOTAL=$(echo "$USES_TOTAL" | tr -d '[:space:]'); [ -z "$USES_TOTAL" ] && USES_TOTAL=0
  USES_SHA=$(echo "$USES_SHA" | tr -d '[:space:]'); [ -z "$USES_SHA" ] && USES_SHA=0
  if [ "$USES_TOTAL" = "0" ]; then
    FR2_OK=0; EVID2="${EVID2}nenhum uses: no workflow; "
  elif [ "$USES_SHA" != "$USES_TOTAL" ]; then
    FR2_OK=0; EVID2="${EVID2}uses: sem SHA: $USES_SHA/$USES_TOTAL (D4); "
  fi
  if grep -Eq 'runs-on:[ ]*ubuntu-latest' "$CI_YML" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}runs-on ubuntu-latest proibido (fixo 24.04); "
  fi
  if ! grep -Eq 'runs-on:[ ]*ubuntu-24\.04' "$CI_YML" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}runs-on ubuntu-24.04 ausente; "
  fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: setup-uv + uv sync --frozen + cache
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$CI_YML" ]; then
  FR3_OK=0; EVID3="${EVID3}ci.yml ausente; "
else
  if ! grep -q "astral-sh/setup-uv" "$CI_YML" 2>/dev/null; then
    FR3_OK=0; EVID3="${EVID3}setup-uv ausente (D3); "
  fi
  if ! grep -q "uv sync --frozen" "$CI_YML" 2>/dev/null; then
    FR3_OK=0; EVID3="${EVID3}uv sync --frozen ausente (prova do lock, D3); "
  fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: matriz 3.12+3.13 + fail-fast false
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$CI_YML" ]; then
  FR4_OK=0; EVID4="${EVID4}ci.yml ausente; "
else
  if ! grep -q "3\.12" "$CI_YML" 2>/dev/null || ! grep -q "3\.13" "$CI_YML" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}matriz sem 3.12+3.13 exatos (D5); "
  fi
  if ! grep -Eq 'fail-fast:[ ]*false' "$CI_YML" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}fail-fast: false ausente (sinal total, CLARIFY); "
  fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: 8 jobs nominais unicos
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$CI_YML" ]; then
  FR5_OK=0; EVID5="${EVID5}ci.yml ausente; "
else
  for j in harness lint types tests audit secrets coverage commitlint; do
    if ! grep -Eq "^[ ]*$j:" "$CI_YML" 2>/dev/null; then
      FR5_OK=0; EVID5="${EVID5}job $j ausente; "
    fi
  done
  DUPES=$(grep -Eo '^  [a-z][a-z0-9_-]*:' "$CI_YML" 2>/dev/null | sort | uniq -d | tr -d ' :' | tr '\n' ' ' || true)
  if [ -n "$DUPES" ]; then
    FR5_OK=0; EVID5="${EVID5}nomes duplicados: $DUPES (ambiguidade trava PR); "
  fi
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: pytest-cov dev + fail-under 90
# =============================================================================
FR6_OK=1; EVID6=""
if ! python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); assert "pytest-cov==7.1.0" in d.get("dependency-groups",{}).get("dev",[])' "$PYPROJECT" 2>/dev/null; then
  FR6_OK=0; EVID6="${EVID6}dev sem pytest-cov==7.1.0; "
fi
if [ ! -f "$CI_YML" ] || ! grep -Eq 'fail-under.?=.?90|cov-fail-under.?90|fail_under.?=.?90' "$CI_YML" 2>/dev/null; then
  if [ ! -f "$PYPROJECT" ] || ! grep -Eq 'fail_under.?=.?90' "$PYPROJECT" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}--fail-under=90 ausente em ci.yml e pyproject (portao, D6); "
  fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: commitlint 11 tipos + range por evento
# =============================================================================
FR7_OK=1; EVID7=""
if [ ! -f "$COMMITLINT" ]; then
  FR7_OK=0; EVID7="${EVID7}commitlint.config.js ausente; "
else
  for t in feat fix docs test refactor build ci style chore perf revert; do
    if ! grep -q "$t" "$COMMITLINT" 2>/dev/null; then
      FR7_OK=0; EVID7="${EVID7}tipo $t ausente no preset (11 tipos, Q8); "
    fi
  done
fi
if [ ! -f "$CI_YML" ] || ! grep -q "pull_request.base.sha" "$CI_YML" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}range por evento ausente no job commitlint (ANALYZE M3); "
fi
if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi

# =============================================================================
# FR-008: procedimento protecao versionado, sem token
# =============================================================================
FR8_OK=1; EVID8=""
if [ ! -f "$PROC010" ]; then
  FR8_OK=0; EVID8="${EVID8}branch-protection.md ausente (ANALYZE M2); "
else
  for h in "checks" "bypass" "review"; do
    if ! grep -qi "$h" "$PROC010" 2>/dev/null; then FR8_OK=0; EVID8="${EVID8}secao $h ausente no procedimento; "; fi
  done
fi
if grep -rEq 'ghp_[A-Za-z0-9]+|github_pat_[A-Za-z0-9_]+|xox[bpas]-[A-Za-z0-9-]+' --exclude-dir=.venv --exclude-dir=.git --exclude-dir=node_modules . 2>/dev/null; then
  FR8_OK=0; EVID8="${EVID8}padrao de token no repo (Lei Zero); "
fi
if [ "$FR8_OK" = "1" ]; then pass "FR-008" "${CANON[FR-008]}"; else fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID8"; fi

# =============================================================================
# FR-009: frouxo + sem-bypass documentados
# =============================================================================
if [ ! -f "$PROC010" ]; then
  fail "FR-009" "${CANON[FR-009]}" "alta" "procedimento ausente; "
elif ! grep -qi "froux" "$PROC010" 2>/dev/null || ! grep -qi "bypass" "$PROC010" 2>/dev/null; then
  fail "FR-009" "${CANON[FR-009]}" "alta" "frouxo/sem-bypass nao documentados (D1)"
else
  pass "FR-009" "${CANON[FR-009]}"
fi

# =============================================================================
# FR-010: timeout por job, sem mascara
# =============================================================================
FR10_OK=1; EVID10=""
if [ ! -f "$CI_YML" ]; then
  FR10_OK=0; EVID10="${EVID10}ci.yml ausente; "
else
  if grep -q "continue-on-error" "$CI_YML" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}continue-on-error presente (mascara, D10); "
  fi
  TIMEOUT_N=$(grep -c "timeout-minutes" "$CI_YML" 2>/dev/null || true)
  TIMEOUT_N=$(echo "$TIMEOUT_N" | tr -d '[:space:]')
  if [ -z "$TIMEOUT_N" ]; then TIMEOUT_N=0; fi
  if [ "$TIMEOUT_N" = "0" ]; then
    FR10_OK=0; EVID10="${EVID10}timeout-minutes ausente (quarentena ADR-019); "
  fi
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: contrato (list 13, exit 2, 2x byte-identico, <5s) (guarda)
# =============================================================================
FR11_OK=1; EVID11=""
if [ "$NESTED" != "1" ]; then
  if [ -n "${EPOCHSECONDS:-}" ]; then START11=$EPOCHSECONDS; else START11=$(date +%s 2>/dev/null || echo 0); fi
  TMPD="$(mktemp -d)"
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    FR11_OK=0; EVID11="${EVID11}--list falhou; "
  else
    LIST_COUNT=$(FKX_ORACLE_NESTED=1 "$SELF" --list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LIST_COUNT" != "13" ] 2>/dev/null; then
      FR11_OK=0; EVID11="${EVID11}--list contagem $LIST_COUNT != 13; "
    fi
  fi
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    FR11_OK=0; EVID11="${EVID11}exit 2 para uso invalido nao obedecido; "
  fi
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; C1=$?
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; C2=$?
  if [ -n "${EPOCHSECONDS:-}" ]; then END11=$EPOCHSECONDS; else END11=$(date +%s 2>/dev/null || echo 0); fi
  ELAPSED11=$((END11 - START11))
  if [ "$ELAPSED11" -gt 5 ] 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}oraculo >5s (${ELAPSED11}s, SC-006); "
  fi
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR11_OK=0
    DIFF_SNIP=$(diff -u "$TMPD/r1" "$TMPD/r2" 2>/dev/null | head -5 | tr -d '\n' | cut -c1-80 || true)
    EVID11="${EVID11}duas execucoes divergiram; C1=$C1 C2=$C2 diff:${DIFF_SNIP}; "
  fi
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: manifest 10/10 + self-check f0-001..009
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$MANIFEST" ]; then
  FR12_OK=0; EVID12="${EVID12}manifest.sha256 ausente; "
else
  LINES=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
  LINES=$(echo "$LINES" | tr -d '[:space:]')
  if [ -z "$LINES" ] || [ "$LINES" -lt 10 ] 2>/dev/null; then
    FR12_OK=0; EVID12="${EVID12}manifest com $LINES linhas (esperado >=10, piso espelho 005); "
  elif ! sha256sum -c "$MANIFEST" >/dev/null 2>&1; then
    FR12_OK=0; EVID12="${EVID12}sha256sum -c reprovou; "
  fi
fi
if [ "$NESTED" != "1" ] && [ "$FR12_OK" = "1" ]; then
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8" "$ORACLE9"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8" "$ORACLE9"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FR12_OK=0; EVID12="${EVID12}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
fi
if [ "$FR12_OK" = "1" ]; then pass "FR-012" "${CANON[FR-012]}"; else fail "FR-012" "${CANON[FR-012]}" "alta" "$EVID12"; fi

# =============================================================================
# FR-013: README 010 hash + zero [ ] + vermelho-verde
# =============================================================================
FR13_OK=1; EVID13=""
if [ ! -f "$README_SPECS" ]; then
  FR13_OK=0; EVID13="${EVID13}specs/README.md ausente; "
elif ! grep -iq "010.*ci-completo.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR13_OK=0; EVID13="${EVID13}README sem \"010.*ci-completo.*✅.*hash\"; "
fi
if [ ! -f "$TASKS010" ]; then
  FR13_OK=0; EVID13="${EVID13}specs/010-ci-completo/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS010" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR13_OK=0; EVID13="${EVID13}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*010" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(ci).*010" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR13_OK=0; EVID13="${EVID13}par vermelho/verde 010 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR13_OK=0; EVID13="${EVID13}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
fi
if [ "$FR13_OK" = "1" ]; then pass "FR-013" "${CANON[FR-013]}"; else fail "FR-013" "${CANON[FR-013]}" "alta" "$EVID13"; fi

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
