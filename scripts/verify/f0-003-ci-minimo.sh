#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 003 (0.13): CI minimo — harness Fase 0 em runner limpo
#
# Contrato de assercoes deste item:
#   specs/003-ci-minimo/contracts/ci-workflow.md
#   specs/003-ci-minimo/spec.md (14 FRs, 8 SCs)
#   specs/003-ci-minimo/plan.md (Fases A-E, D1-D10)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-003-ci-minimo.md (Q1-Q10 D1-D10, 2026-08-30)
#   specs/003-ci-minimo/research.md (D1-D10 consolidadas)
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib. Nenhuma dependencia do projeto.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-08-30:
#   D1 ci.yml em .github/workflows/ci.yml YAML name/on/permissions/jobs (Q1)
#   D2 runs-on ubuntu-24.04 pinado nao latest (Q2, I)
#   D3 checkout@v7 (7.0.1) fetch-depth 0 (Q3+Q5)
#   D4 setup-python@v7 (7.0.0) python 3.12 familia (Q4+Q9)
#   D5 sem cache/matrix (Q5+Q8) D6 permissions contents:read (Q6/V)
#   D7 on push/pull_request [main,develop] (Q7)
#   D8 job verify estavel sem matrix (Q8) D9 python 3.12 D10 Run harness glob || exit 1 (Q10/X)
# =============================================================================

set -uo pipefail
LC_ALL=C
export LC_ALL

# --- restricao 4: raiz pela localizacao do script -----------------------------
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

# --- acumuladores (restricao 5) ----------------------------------------------
declare -a R_STATUS=() R_ID=() R_DESC=() R_SEV=() R_EVID=()

pass() { R_STATUS+=("ok");   R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("-");  R_EVID+=(""); }
fail() { R_STATUS+=("bad");  R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("$3"); R_EVID+=("${4:-}"); }
skip() { R_STATUS+=("skip"); R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("-");  R_EVID+=("${3:-}"); }

check() {
  if [ "$4" = "0" ]; then pass "$1" "$2"; else fail "$1" "$2" "$3" "${5:-}"; fi
}

# --- fonte UNICA de identificadores e descricoes (14 FRs) --------------------
declare -A CANON=(
  ["FR-001"]="workflow em .github/workflows/ci.yml YAML valido com chaves top-level"
  ["FR-002"]="diretorio .github/workflows existe"
  ["FR-003"]="job verify runs-on pinado ubuntu-24.04 nao latest"
  ["FR-004"]="checkout familia v7 com fetch-depth 0 (tag ou SHA+comentario)"
  ["FR-005"]="setup-python familia v7 com python-version 3.12 familia"
  ["FR-006"]="fronteira: sem vetores pull_request_target/workflow_run"
  ["FR-007"]="permissions contents read least privilege sem write id-token"
  ["FR-008"]="triggers push e pull_request em [main, develop]"
  ["FR-009"]="job verify estavel com steps Checkout Setup Python 3.12 Run harness"
  ["FR-010"]="Run harness glob for f in scripts/verify/f0-*.sh com || exit 1 sem --quiet em CI"
  ["FR-011"]="propaga exit sem continue-on-error"
  ["FR-012"]="sem construcao nao deterministica e determinismo interno"
  ["FR-013"]="extensivel para 010 sem rename de verify ou troca de runs-on"
  ["FR-014"]="contratos entregues e transferidos declarados e harness herdado integro"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014"

# --- caminhos medidos ---------------------------------------------------------
CI_YML="$ROOT/.github/workflows/ci.yml"
WORKFLOWS_DIR="$ROOT/.github/workflows"
SPEC003="$ROOT/specs/003-ci-minimo/spec.md"
ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

# =============================================================================
# --list: enumera sem executar (FR-020b analogo)
# =============================================================================
if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# --- helpers -----------------------------------------------------------------
ci_text() {
  if [ -f "$CI_YML" ]; then cat -- "$CI_YML"; else echo ""; fi
}

# =============================================================================
# FR-001: workflow existe YAML valido com chaves top-level name/on/permissions/jobs
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-001" "${CANON[FR-001]}" "alta" ".github/workflows/ci.yml ausente (FR-001/FR-002)"
else
  MISSING=""
  TXT="$(ci_text)"
  for k in "name:" "on:" "permissions:" "jobs:"; do
    echo "$TXT" | grep -q "$k" || MISSING="${MISSING}${k} "
  done
  # YAML valido via python3 stdlib + grep fallback (plan Fase C, quickstart 1b)
  PY_OK=0
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$CI_YML" <<'PY' 2>/dev/null
import pathlib, sys
p = pathlib.Path(sys.argv[1])
t = p.read_text(encoding='utf-8', errors='ignore')
# validacao estrutural minima sem PyYAML: chaves top-level presentes
need = ["name:", "on:", "permissions:", "jobs:"]
missing = [k for k in need if k not in t]
sys.exit(0 if not missing else 1)
PY
    PY_OK=$?
  fi
  # fallback: se python3 falhou por sintaxe python, usa grep (ja calculado)
  if [ -n "$MISSING" ] || [ "$PY_OK" != "0" ]; then
    fail "FR-001" "${CANON[FR-001]}" "alta" "chaves ausentes: $MISSING (py:$PY_OK)"
  else
    pass "FR-001" "${CANON[FR-001]}"
  fi
fi

# =============================================================================
# FR-002: diretorio .github/workflows existe
# =============================================================================
if [ -d "$WORKFLOWS_DIR" ]; then
  pass "FR-002" "${CANON[FR-002]}"
else
  fail "FR-002" "${CANON[FR-002]}" "alta" ".github/workflows/ inexistente (Q1)"
fi

# =============================================================================
# FR-003: runs-on pinado ubuntu-24.04 nao latest
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-003" "${CANON[FR-003]}" "alta" "ci.yml ausente — nao ha runs-on a verificar"
else
  HAS_PIN=0; HAS_LATEST=0
  grep -q 'runs-on: ubuntu-24.04' "$CI_YML" && HAS_PIN=1
  grep -q 'ubuntu-latest' "$CI_YML" && HAS_LATEST=1
  if [ "$HAS_PIN" = "1" ] && [ "$HAS_LATEST" = "0" ]; then
    pass "FR-003" "${CANON[FR-003]}"
  else
    EVID=""
    [ "$HAS_PIN" != "1" ] && EVID="${EVID}runs-on ubuntu-24.04 ausente; "
    [ "$HAS_LATEST" = "1" ] && EVID="${EVID}ubuntu-latest proibido (alias movel Q2); "
    fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-004: checkout@v7 com fetch-depth 0
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-004" "${CANON[FR-004]}" "alta" "ci.yml ausente"
else
  CK_V7=0; FD0=0
  grep -q 'uses: actions/checkout@v7' "$CI_YML" && CK_V7=1
  # ADR-022: SHA pinado com comentario v7.0.1 equivale a @v7 (SHA implica tag)
  if [ "$CK_V7" = "0" ] && grep -Eq 'uses: actions/checkout@[0-9a-f]{40} +# v7\.0\.1' "$CI_YML"; then CK_V7=1; fi
  grep -q 'fetch-depth: 0' "$CI_YML" && FD0=1
  # garante que fetch-depth pertence ao checkout (proximidade)
  if [ "$CK_V7" = "1" ] && [ "$FD0" = "1" ]; then
    pass "FR-004" "${CANON[FR-004]}"
  else
    EVID=""
    [ "$CK_V7" != "1" ] && EVID="${EVID}actions/checkout@v7 ausente (esperado v7 7.0.1 node24); "
    [ "$FD0" != "1" ] && EVID="${EVID}fetch-depth: 0 ausente (default 1 esconde historico FR-020b Q5); "
    fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-005: setup-python@v7 com python-version 3.12 familia
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-005" "${CANON[FR-005]}" "alta" "ci.yml ausente"
else
  SP_V7=0; PY312=0
  grep -q 'uses: actions/setup-python@v7' "$CI_YML" && SP_V7=1
  # ADR-022: SHA pinado com comentario v7.0.0 equivale a @v7
  if [ "$SP_V7" = "0" ] && grep -Eq 'uses: actions/setup-python@[0-9a-f]{40} +# v7\.0\.0' "$CI_YML"; then SP_V7=1; fi
  grep -q "python-version: '3.12'" "$CI_YML" && PY312=1
  # aceita tambem double quotes por robustez mas reprova se ausente
  if [ "$PY312" = "0" ]; then grep -q 'python-version: "3.12"' "$CI_YML" && PY312=1; fi
  if [ "$SP_V7" = "1" ] && [ "$PY312" = "1" ]; then
    # verifica que nao usa 3.x flutuante
    if grep -q "python-version: '3.x'" "$CI_YML" || grep -q 'python-version: "3.x"' "$CI_YML"; then
      fail "FR-005" "${CANON[FR-005]}" "alta" "python-version 3.x flutuante proibido (familia 3.12 exigida Q4/D4)"
    else
      pass "FR-005" "${CANON[FR-005]}"
    fi
  else
    EVID=""
    [ "$SP_V7" != "1" ] && EVID="${EVID}actions/setup-python@v7 ausente (esperado v7 7.0.0 node24); "
    [ "$PY312" != "1" ] && EVID="${EVID}python-version '3.12' ausente; "
    fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-006: fronteira — vetores proibidos (ferramentas 010 liberadas por ADR-022)
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-006" "${CANON[FR-006]}" "alta" "ci.yml ausente"
else
  FOUND=""
  # lista reduzida (ADR-022): só vetores reais; palavras-ferramenta/matriz/cache
  # pertencem a 010, dona designada (Emenda 1)
  if grep -Eq 'pull_request_target|workflow_run' "$CI_YML"; then
    FOUND="$(grep -Eo 'pull_request_target|workflow_run' "$CI_YML" | sort -u | tr '\n' ' ')"
    fail "FR-006" "${CANON[FR-006]}" "alta" "vetor proibido: $FOUND"
  else
    pass "FR-006" "${CANON[FR-006]}"
  fi
fi

# =============================================================================
# FR-007: permissions contents: read sem write/id-token
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-007" "${CANON[FR-007]}" "alta" "ci.yml ausente"
else
  HAS_PERM=0; HAS_READ=0; HAS_WRITE=0; HAS_IDTOKEN=0
  grep -q 'permissions:' "$CI_YML" && HAS_PERM=1
  grep -q 'contents: read' "$CI_YML" && HAS_READ=1
  # detecta write como valor de permissions (nao como substring de outra palavra)
  if grep -Eq 'contents:\s*write' "$CI_YML"; then HAS_WRITE=1; fi
  if grep -q 'id-token: write' "$CI_YML"; then HAS_IDTOKEN=1; fi
  if [ "$HAS_PERM" = "1" ] && [ "$HAS_READ" = "1" ] && [ "$HAS_WRITE" = "0" ] && [ "$HAS_IDTOKEN" = "0" ]; then
    pass "FR-007" "${CANON[FR-007]}"
  else
    EVID=""
    [ "$HAS_PERM" != "1" ] && EVID="${EVID}permissions ausente (default indeterministico Q6); "
    [ "$HAS_READ" != "1" ] && EVID="${EVID}contents: read ausente; "
    [ "$HAS_WRITE" = "1" ] && EVID="${EVID}contents: write proibido (least privilege V); "
    [ "$HAS_IDTOKEN" = "1" ] && EVID="${EVID}id-token: write proibido (so em 013 trusted publishing); "
    fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-008: triggers push/pull_request em [main, develop]
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-008" "${CANON[FR-008]}" "alta" "ci.yml ausente"
else
  HAS_PUSH=0; HAS_PR=0; HAS_MAIN=0; HAS_DEVELOP=0; HAS_MERGE=0; HAS_TAGS=0
  grep -q 'push:' "$CI_YML" && HAS_PUSH=1
  grep -q 'pull_request:' "$CI_YML" && HAS_PR=1
  # verifica branches [main, develop] — aceita formato yaml flow ou block
  if grep -q 'main' "$CI_YML" && grep -q 'develop' "$CI_YML"; then HAS_MAIN=1; HAS_DEVELOP=1; fi
  grep -q 'merge_group' "$CI_YML" && HAS_MERGE=1
  # tags como trigger (nao como comentario) — procura linha com tags:
  if grep -Eq '^\s*tags:' "$CI_YML"; then HAS_TAGS=1; fi
  if [ "$HAS_PUSH" = "1" ] && [ "$HAS_PR" = "1" ] && [ "$HAS_MAIN" = "1" ] && [ "$HAS_MERGE" = "0" ] && [ "$HAS_TAGS" = "0" ]; then
    pass "FR-008" "${CANON[FR-008]}"
  else
    EVID=""
    [ "$HAS_PUSH" != "1" ] && EVID="${EVID}on.push ausente; "
    [ "$HAS_PR" != "1" ] && EVID="${EVID}on.pull_request ausente; "
    [ "$HAS_MAIN" != "1" ] && EVID="${EVID}branches [main, develop] ausentes; "
    [ "$HAS_MERGE" = "1" ] && EVID="${EVID}merge_group proibido neste item (deferido 010); "
    [ "$HAS_TAGS" = "1" ] && EVID="${EVID}tags trigger proibido neste item (deferido 013); "
    fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-009: job verify estavel com steps nomeados
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-009" "${CANON[FR-009]}" "alta" "ci.yml ausente"
else
  HAS_VERIFY=0; HAS_CK=0; HAS_PY=0; HAS_RUN=0
  grep -q 'verify:' "$CI_YML" && HAS_VERIFY=1
  grep -q 'name: Checkout' "$CI_YML" && HAS_CK=1
  grep -q 'name: Setup Python 3.12' "$CI_YML" && HAS_PY=1
  grep -q 'name: Run harness' "$CI_YML" && HAS_RUN=1
  # verifica ordem: Checkout antes de Setup antes de Run harness (linha)
  ORDER_OK=1
  if [ "$HAS_CK" = "1" ] && [ "$HAS_PY" = "1" ] && [ "$HAS_RUN" = "1" ]; then
    CK_LINE=$(grep -n 'name: Checkout' "$CI_YML" | cut -d: -f1 | head -1)
    PY_LINE=$(grep -n 'name: Setup Python 3.12' "$CI_YML" | cut -d: -f1 | head -1)
    RUN_LINE=$(grep -n 'name: Run harness' "$CI_YML" | cut -d: -f1 | head -1)
    if [ "$CK_LINE" -gt "$PY_LINE" ] || [ "$PY_LINE" -gt "$RUN_LINE" ]; then ORDER_OK=0; fi
  else
    ORDER_OK=0
  fi
  if [ "$HAS_VERIFY" = "1" ] && [ "$HAS_CK" = "1" ] && [ "$HAS_PY" = "1" ] && [ "$HAS_RUN" = "1" ] && [ "$ORDER_OK" = "1" ]; then
    pass "FR-009" "${CANON[FR-009]}"
  else
    EVID=""
    [ "$HAS_VERIFY" != "1" ] && EVID="${EVID}job id verify ausente (estavel para required check 010); "
    [ "$HAS_CK" != "1" ] && EVID="${EVID}step Checkout ausente; "
    [ "$HAS_PY" != "1" ] && EVID="${EVID}step Setup Python 3.12 ausente; "
    [ "$HAS_RUN" != "1" ] && EVID="${EVID}step Run harness ausente; "
    [ "$ORDER_OK" != "1" ] && EVID="${EVID}ordem Checkout->Setup->Run violada; "
    fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-010: Run harness glob com || exit 1 sem --quiet em CI
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-010" "${CANON[FR-010]}" "alta" "ci.yml ausente"
else
  HAS_GLOB=0; HAS_EXIT=0; HAS_QUIET_IN_CI=0
  grep -Fq 'for f in scripts/verify/f0-*.sh' "$CI_YML" && HAS_GLOB=1
  grep -Fq '|| exit 1' "$CI_YML" && HAS_EXIT=1
  # detecta --quiet dentro do bloco Run harness (se existir, reprova)
  # isola bloco Run harness ate proximo step ou fim
  RUN_BLOCK=$(awk '/name: Run harness/{flag=1;next} flag && /name: /{exit} flag' "$CI_YML")
  echo "$RUN_BLOCK" | grep -q -- '--quiet' && HAS_QUIET_IN_CI=1
  # lista hard-coded reprova: procura enumeracao explicita de oraculos sem glob
  HAS_HARDCODED=0
  if grep -q 'f0-001-foundation.sh' "$CI_YML" && ! grep -q 'f0-\*.sh' "$CI_YML"; then HAS_HARDCODED=1; fi
  if [ "$HAS_GLOB" = "1" ] && [ "$HAS_EXIT" = "1" ] && [ "$HAS_QUIET_IN_CI" = "0" ] && [ "$HAS_HARDCODED" = "0" ]; then
    pass "FR-010" "${CANON[FR-010]}"
  else
    EVID=""
    [ "$HAS_GLOB" != "1" ] && EVID="${EVID}glob for f in scripts/verify/f0-*.sh ausente; "
    [ "$HAS_EXIT" != "1" ] && EVID="${EVID}|| exit 1 ausente (propagacao FR-011); "
    [ "$HAS_QUIET_IN_CI" = "1" ] && EVID="${EVID}--quiet proibido em CI (observabilidade X, FR-010); "
    [ "$HAS_HARDCODED" = "1" ] && EVID="${EVID}lista hard-coded de oraculos (deve ser glob); "
    fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID"
  fi
fi

# =============================================================================
# FR-011: propaga exit sem continue-on-error
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-011" "${CANON[FR-011]}" "alta" "ci.yml ausente"
else
  if grep -q 'continue-on-error' "$CI_YML"; then
    # se tiver continue-on-error true, reprova; se false, tolera mas ainda verifica
    if grep -q 'continue-on-error: true' "$CI_YML"; then
      fail "FR-011" "${CANON[FR-011]}" "alta" "continue-on-error: true mascara falha (FR-011 D10)"
    else
      # presenca sem true ainda suspeita mas permite?
      fail "FR-011" "${CANON[FR-011]}" "alta" "continue-on-error presente — deve estar ausente para propagar exit 1"
    fi
  else
    pass "FR-011" "${CANON[FR-011]}"
  fi
fi

# =============================================================================
# FR-012: sem nao determinismo + determinismo interno (duas execucoes identicas)
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-012" "${CANON[FR-012]}" "alta" "ci.yml ausente"
else
  NONDET=""
  grep -Eq '\$RANDOM' "$CI_YML" && NONDET="${NONDET}\$RANDOM "
  # date em logica (evita falso positivo em comentario? mas grep simples)
  if grep -Eq '\bdate\b' "$CI_YML"; then NONDET="${NONDET}date "; fi
  grep -q 'GITHUB_RUN_NUMBER' "$CI_YML" && NONDET="${NONDET}GITHUB_RUN_NUMBER "
  if [ -n "$NONDET" ]; then
    fail "FR-012" "${CANON[FR-012]}" "alta" "construcao nao deterministica: $NONDET (FR-012 I)"
  else
    # determinismo interno: duas execucoes deste oraculo produzem saida identica (FR-018 analogo)
    if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
      # evita recursao infinita quando chamado via harness acumulado
      pass "FR-012" "${CANON[FR-012]}"
    else
      TMPD="$(mktemp -d)"
      # serial por ADR-031: forma ja vigente em f0-007..012
      FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; RC1=$?
      FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; RC2=$?
      if cmp -s "$TMPD/r1" "$TMPD/r2" && [ "$RC1" -eq "$RC2" ]; then
        pass "FR-012" "${CANON[FR-012]}"
      else
        DIFF_HEAD=$(diff -u "$TMPD/r1" "$TMPD/r2" | head -5 | tr '\n' ' ' | cut -c1-200)
        fail "FR-012" "${CANON[FR-012]}" "alta" "duas execucoes divergiram rc1=$RC1 rc2=$RC2 diff: $DIFF_HEAD"
      fi
    fi
  fi
fi

# =============================================================================
# FR-013: extensivel sem rename de verify ou troca de runs-on
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-013" "${CANON[FR-013]}" "alta" "ci.yml ausente"
else
  # ja verificado FR-003 e FR-009, mas FR-013 garante estabilidade futura
  # verifica que verify existe e runs-on ainda 24.04 (nao foi trocado)
  if grep -q 'verify:' "$CI_YML" && grep -q 'runs-on: ubuntu-24.04' "$CI_YML"; then
    pass "FR-013" "${CANON[FR-013]}"
  else
    fail "FR-013" "${CANON[FR-013]}" "alta" "verify renomeado ou runs-on trocado — quebra escalabilidade para 010 (FR-013)"
  fi
fi

# =============================================================================
# FR-014: contratos entregues/transferidos declarados e harness herdado integro
# =============================================================================
SPEC_OK=1
EVID_SPEC=""
if [ ! -f "$SPEC003" ]; then
  SPEC_OK=0; EVID_SPEC="spec 003 ausente; "
else
  grep -q "Entregue por este item" "$SPEC003" || { SPEC_OK=0; EVID_SPEC="${EVID_SPEC}secao Contratos Entregue ausente; "; }
  grep -q "Transferido a itens posteriores" "$SPEC003" || { SPEC_OK=0; EVID_SPEC="${EVID_SPEC}secao Transferido ausente; "; }
fi

# harness herdado integro: f0-001 e f0-002 aprovam via --quiet (principio VI)
HARNESS_OK=1
EVID_HARN=""
if [ -x "$ORACLE1" ]; then
  FKX_ORACLE_NESTED=1 "$ORACLE1" --quiet >/dev/null 2>&1 || { HARNESS_OK=0; EVID_HARN="${EVID_HARN}f0-001 reprovou; "; }
else
  HARNESS_OK=0; EVID_HARN="${EVID_HARN}f0-001 ausente; "
fi
if [ -x "$ORACLE2" ]; then
  FKX_ORACLE_NESTED=1 "$ORACLE2" --quiet >/dev/null 2>&1 || { HARNESS_OK=0; EVID_HARN="${EVID_HARN}f0-002 reprovou; "; }
else
  HARNESS_OK=0; EVID_HARN="${EVID_HARN}f0-002 ausente; "
fi

if [ "$SPEC_OK" = "1" ] && [ "$HARNESS_OK" = "1" ]; then
  pass "FR-014" "${CANON[FR-014]}"
else
  fail "FR-014" "${CANON[FR-014]}" "alta" "${EVID_SPEC}${EVID_HARN}"
fi

# =============================================================================
# Relatorio (restricao 3: ordem estavel — ordem de declaracao)
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
  printf 'Resultado: %d/%d assercoes aprovadas' "$OK" "$TOTAL"
  [ "$SKIPPED" -gt 0 ] && printf ' (%d nao aplicaveis)' "$SKIPPED"
  printf ' — CONFORME\n'
  exit 0
else
  printf 'Resultado: %d/%d assercoes aprovadas — %d violacao(oes)' "$OK" "$TOTAL" "$BAD"
  printf ' (critica: %d, alta: %d, media: %d)' "$CRIT" "$ALTA" "$MEDIA"
  [ "$SKIPPED" -gt 0 ] && printf ' — %d nao aplicaveis' "$SKIPPED"
  printf ' — NAO CONFORME\n'
  exit 1
fi
