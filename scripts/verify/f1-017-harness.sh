#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 1, item 017 (1.1): core/harness.py p/ motor
#
# Contrato de assercoes deste item:
#   specs/017-harness/spec.md (12 FRs, 7 SCs, 3 US + CLARIFY 3/3)
#   specs/017-harness/plan.md (Fases A-D, D1-D8, fronteira 1 ponto, ADR previa)
#   specs/017-harness/contracts/oracle-cli.md (mapa identidade 12 FRs + Superficie)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f1-017-harness.md (Q1-Q8 D1-D7, 2026-09-10)
#   specs/017-harness/research.md (8 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento):
#     FR-008 (contrato auto-verificavel — mecanica passa com esqueleto)
#   Comportamento (carregam o vermelho):
#     FR-001..007, FR-009..012
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-016 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Medicao de exit code: via redirect + $? (nunca $? apos pipe — research Q4/013).
# Self-check em SERIE (ADR-031): f0-001..f0-016 sequenciais, nunca concorrentes.
# Pares 2x medem em ms (date +%s%N); partes lentas (uv run, self-check) rodam
# SOMENTE fora de aninhamento — par compara aninhado x aninhado (molde 016).
#
# Fronteira 1 ponto (plan, varredura 2026-09-10 + ADR previa, 10a execucao do
# molde ADR-017): f0-011 FR-002 admite harness.py sob jurisdicao 017 — e nada
# alem. Qualquer outro vermelho herdado = conflito novo, ADR propria.
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

declare -A CANON=(
  ["FR-001"]="feedforward recusa sem processo + marcador ausente"
  ["FR-002"]="feedback preserva rc; sinal nunca verde; vazio com guarda"
  ["FR-003"]="exits literais 0 1 2 nos tres cenarios"
  ["FR-004"]="zero retry: tentativa unica, sem sleep retry backoff"
  ["FR-005"]="veredito nomeia requisito+evidencia; sem traceback; sem segredo"
  ["FR-006"]="HarnessError(FkxError) exportado; sem except nu"
  ["FR-007"]="nenhum exit fora de 0 1 2"
  ["FR-008"]="contrato: list 12 exit2 2x <5s manifest17 self-check serie"
  ["FR-009"]="README 017 hash + zero [ ] + vermelho-verde"
  ["FR-010"]="PLAN+ADR previa; f0-011 admite harness.py e nada alem"
  ["FR-011"]="so stdlib; uv.lock sem pacote novo"
  ["FR-012"]="POSIX declarado; nonposix fail-closed nomeado"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012"

HARNESS="$ROOT/packages/core/src/fkx_core/harness.py"
INITMOD="$ROOT/packages/core/src/fkx_core/__init__.py"
CORE_PYPROJECT="$ROOT/packages/core/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS017="$ROOT/specs/017-harness/tasks.md"
README_SPECS="$ROOT/specs/README.md"
PLAN017="$ROOT/specs/017-harness/plan.md"
DECISIONS="$ROOT/docs/plan/decisions.md"
F0011="$SCRIPT_DIR/f0-011-core.sh"

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
ORACLE15="$SCRIPT_DIR/f0-015-docker-compose.sh"
ORACLE16="$SCRIPT_DIR/f0-016-tree.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP
TMPD="$(mktemp -d 2>/dev/null || true)"
if [ -z "$TMPD" ] || [ ! -d "$TMPD" ]; then
  printf 'erro interno: sem diretorio descartavel\n' >&2
  exit 2
fi

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# Sonda comportamental P1 (ambiente normal + segredo-isca no ambiente).
# Imprime uma linha por cenario: SC=<nome> exit=<e> rc=<r> req=<id>
# evlen=<n> notrace=<B> nocanary=<B> [exp=<B>]. Falha de import => rc!=0.
probe_p1() {
  FKX_PROBE_CANARY="canary-017-marker" timeout 120 uv run --frozen --all-packages python -c '
import json
from fkx_core import harness
S = "canary-017-marker"
def line(name, v, exp=None):
    parts = ["SC=" + name, "exit=" + str(v.exit), "rc=" + str(v.returncode),
             "req=" + v.requisito, "evlen=" + str(len(v.evidencia)),
             "notrace=" + str("Traceback" not in v.evidencia),
             "nocanary=" + str(S not in v.evidencia)]
    if exp is not None:
        parts.append("exp=" + str(exp))
    print(" ".join(parts))
v = harness.run(["true"], requisito="FR-002"); line("true", v)
v = harness.run(["bash", "-c", "exit 3"], requisito="FR-002"); line("exit3", v)
v = harness.run(["bash", "-c", "kill -9 $$"], requisito="FR-002"); line("kill", v)
v = harness.run(["sleep", "5"], requisito="FR-002", timeout=1)
line("timeout", v, exp=("timeout" in v.evidencia.lower() or "expir" in v.evidencia.lower()))
v = harness.run(["binario-inexistente-017-fkxfk"], requisito="FR-001"); line("binabsent", v)
' > "$TMPD/p1.out" 2> "$TMPD/p1.err"
  echo $?
}

# Sonda P2 (plataforma forcada + marcador que nao pode nascer).
probe_p2() {
  FKX_HARNESS_FORCE_PLATFORM=nonposix MARKER_017="$TMPD/marker-017" timeout 120 uv run --frozen --all-packages python -c '
import os
from fkx_core import harness
m = os.environ["MARKER_017"]
v = harness.run(["touch", m], requisito="FR-001")
print("SC=touch exit=" + str(v.exit) + " req=" + v.requisito)
v = harness.run(["true"], requisito="FR-012")
print("SC=truestrict exit=" + str(v.exit) + " req=" + v.requisito)
' > "$TMPD/p2.out" 2> "$TMPD/p2.err"
  echo $?
}

# Sonda P3 (hierarquia de erro pela superficie publica).
probe_p3() {
  timeout 120 uv run --frozen --all-packages python -c '
from fkx_core import FkxError, HarnessError
print("sub=" + str(issubclass(HarnessError, FkxError)))
print("exc=" + str(FkxError.__bases__ == (Exception,)))
' > "$TMPD/p3.out" 2> "$TMPD/p3.err"
  echo $?
}

P1_RC=99; P2_RC=99; P3_RC=99
if [ "$NESTED" != "1" ]; then
  if [ -f "$HARNESS" ]; then
    P1_RC=$(probe_p1)
    P2_RC=$(probe_p2)
    P3_RC=$(probe_p3)
  else
    P1_RC=127; P2_RC=127; P3_RC=127
  fi
fi

# =============================================================================
# FR-001: feedforward recusa sem processo + marcador ausente (ANALYZE C1)
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$HARNESS" ]; then
  FR1_OK=0; EVID1="${EVID1}harness.py ausente; "
elif [ "$NESTED" = "1" ]; then
  :
else
  if [ "$P1_RC" != "0" ]; then
    FR1_OK=0; EVID1="${EVID1}sonda P1 indisponivel (rc=$P1_RC); "
  else
    if ! grep -q "^SC=binabsent exit=2 rc=0 req=FR-001 " "$TMPD/p1.out" 2>/dev/null; then
      FR1_OK=0; EVID1="${EVID1}binario ausente sem exit 2 nomeado FR-001; "
    fi
  fi
  if [ "$P2_RC" != "0" ]; then
    FR1_OK=0; EVID1="${EVID1}sonda P2 indisponivel (rc=$P2_RC); "
  else
    if ! grep -q "^SC=touch exit=2 req=FR-001$" "$TMPD/p2.out" 2>/dev/null; then
      FR1_OK=0; EVID1="${EVID1}portao nao recusou touch sob nonposix; "
    fi
    if [ -e "$TMPD/marker-017" ]; then
      FR1_OK=0; EVID1="${EVID1}marcador nasceu: processo gerado apos recusa (C1); "
    fi
  fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: feedback preserva rc; sinal nunca verde; vazio com guarda (C4)
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$HARNESS" ]; then
  FR2_OK=0; EVID2="${EVID2}harness.py ausente; "
elif [ "$NESTED" = "1" ]; then
  :
else
  if [ "$P1_RC" != "0" ]; then
    FR2_OK=0; EVID2="${EVID2}sonda P1 indisponivel (rc=$P1_RC); "
  else
    if ! grep -q "^SC=true exit=0 rc=0 req=FR-002 " "$TMPD/p1.out" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}true sem exit 0 rc 0; "
    fi
    if ! grep -q "^SC=exit3 exit=1 rc=3 req=FR-002 " "$TMPD/p1.out" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}exit 3 sem exit 1 rc 3 preservado; "
    fi
    if ! grep -q "^SC=kill exit=1 rc=-9 req=FR-002 " "$TMPD/p1.out" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}morte por sinal sem falha nomeada rc -9 (nunca verde); "
    fi
    if ! grep -q "^SC=timeout exit=1 .* exp=True$" "$TMPD/p1.out" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}timeout sem expiracao nomeada fail-closed; "
    fi
    if grep -E "^SC=(true|exit3|kill|timeout|binabsent) " "$TMPD/p1.out" 2>/dev/null | grep -qv "evlen=[1-9]"; then
      FR2_OK=0; EVID2="${EVID2}veredito com evidencia vazia (guarda C4); "
    fi
  fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: exits literais 0 1 2 nos tres cenarios
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$HARNESS" ]; then
  FR3_OK=0; EVID3="${EVID3}harness.py ausente; "
elif [ "$NESTED" = "1" ]; then
  :
else
  if [ "$P1_RC" != "0" ]; then
    FR3_OK=0; EVID3="${EVID3}sonda P1 indisponivel (rc=$P1_RC); "
  else
    for want in "SC=true exit=0 " "SC=exit3 exit=1 " "SC=binabsent exit=2 "; do
      if ! grep -q "^${want}" "$TMPD/p1.out" 2>/dev/null; then
        FR3_OK=0; EVID3="${EVID3}cenario sem literal esperado: $want; "
      fi
    done
  fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: zero retry — forma estatica precisa (ANALYZE C2)
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$HARNESS" ]; then
  FR4_OK=0; EVID4="${EVID4}harness.py ausente; "
else
  if grep -rinE "tenacity|backoff|time\.sleep|[^a-zA-Z_]retry[^a-zA-Z_]" "$HARNESS" 2>/dev/null | grep -qv "^.*#" 2>/dev/null; then
    HIT=$(grep -rinE "tenacity|backoff|time\.sleep|[^a-zA-Z_]retry[^a-zA-Z_]" "$HARNESS" 2>/dev/null | grep -v "^.*#" | head -1 | cut -c1-100 || true)
    FR4_OK=0; EVID4="${EVID4}construcao de re-tentativa no fonte: $HIT; "
  fi
  if grep -rinE "tenacity|backoff" "$HARNESS" 2>/dev/null | grep -q "^.*#" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}a palavra vive nem em comentario (forma exige ausencia total); "
  fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: veredito nomeia requisito+evidencia; sem traceback; sem segredo
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$HARNESS" ]; then
  FR5_OK=0; EVID5="${EVID5}harness.py ausente; "
elif [ "$NESTED" = "1" ]; then
  :
else
  if [ "$P1_RC" != "0" ]; then
    FR5_OK=0; EVID5="${EVID5}sonda P1 indisponivel (rc=$P1_RC); "
  else
    if grep -E "^SC=(true|exit3|kill|timeout|binabsent) " "$TMPD/p1.out" 2>/dev/null | grep -qv "req=FR-00[12] "; then
      FR5_OK=0; EVID5="${EVID5}veredito sem requisito nomeado; "
    fi
    if grep -E "^SC=(true|exit3|kill|timeout|binabsent) " "$TMPD/p1.out" 2>/dev/null | grep -qv "notrace=True"; then
      FR5_OK=0; EVID5="${EVID5}traceback como evidencia (X violado); "
    fi
    if grep -E "^SC=(true|exit3|kill|timeout|binabsent) " "$TMPD/p1.out" 2>/dev/null | grep -qv "nocanary=True"; then
      FR5_OK=0; EVID5="${EVID5}segredo-isca vazou ao veredito (Lei Zero); "
    fi
  fi
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: HarnessError(FkxError) exportado; sem except nu
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$HARNESS" ]; then
  FR6_OK=0; EVID6="${EVID6}harness.py ausente; "
else
  if [ ! -f "$INITMOD" ]; then
    FR6_OK=0; EVID6="${EVID6}__init__.py ausente; "
  elif ! grep -q "HarnessError" "$INITMOD" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}HarnessError fora da superficie publica; "
  fi
  if grep -nE "except\s*:" "$HARNESS" 2>/dev/null | grep -qv "except.*Exception\|except.*Error" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}except nu no modulo; "
  fi
  if [ "$NESTED" != "1" ]; then
    if [ "$P3_RC" != "0" ]; then
      FR6_OK=0; EVID6="${EVID6}sonda P3 indisponivel (rc=$P3_RC); "
    else
      if ! grep -q "^sub=True$" "$TMPD/p3.out" 2>/dev/null; then
        FR6_OK=0; EVID6="${EVID6}HarnessError nao e subclasse de FkxError; "
      fi
    fi
  fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: nenhum exit fora de 0 1 2 (proibicao negativa — ANALYZE A1)
# =============================================================================
FR7_OK=1; EVID7=""
if [ ! -f "$HARNESS" ]; then
  FR7_OK=0; EVID7="${EVID7}harness.py ausente; "
elif [ "$NESTED" = "1" ]; then
  :
else
  if [ "$P1_RC" != "0" ] || [ "$P2_RC" != "0" ]; then
    FR7_OK=0; EVID7="${EVID7}sondas indisponiveis (rc=$P1_RC/$P2_RC); "
  else
    OUT7=$(grep -hoE "^SC=[a-z0-9]+ exit=-?[0-9]+" "$TMPD/p1.out" "$TMPD/p2.out" 2>/dev/null | grep -vE "exit=[012]$" || true)
    if [ -n "$OUT7" ]; then
      FR7_OK=0; EVID7="${EVID7}exit fora do alfabeto: $(echo "$OUT7" | tr '\n' ' ' | cut -c1-100); "
    fi
  fi
fi
if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi

# =============================================================================
# FR-008: contrato auto-verificavel + manifest17 + self-check serie
# =============================================================================
FR8_OK=1; EVID8=""
LIST_COUNT=$(bash "$SELF" --list 2>/dev/null | wc -l || true)
LIST_COUNT=$(echo "$LIST_COUNT" | tr -d '[:space:]')
if [ "$LIST_COUNT" != "12" ]; then
  FR8_OK=0; EVID8="${EVID8}--list enumera $LIST_COUNT != 12; "
fi
INVALID_RC=0
bash "$SELF" --invalido > /dev/null 2>&1 || INVALID_RC=$?
if [ "$INVALID_RC" != "2" ]; then
  FR8_OK=0; EVID8="${EVID8}--invalido exit $INVALID_RC != 2; "
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
    FR8_OK=0; EVID8="${EVID8}2 execucoes divergem; "
  fi
  if [ "$ELAPSED1" -gt 5000 ] || [ "$ELAPSED2" -gt 5000 ]; then
    FR8_OK=0; EVID8="${EVID8}execucao >5s (${ELAPSED1}ms/${ELAPSED2}ms); "
  fi
fi
if [ ! -f "$MANIFEST" ]; then
  FR8_OK=0; EVID8="${EVID8}manifest.sha256 ausente; "
elif ! (cd "$ROOT" && sha256sum -c "$MANIFEST" > /dev/null 2>&1); then
  FR8_OK=0; EVID8="${EVID8}manifest.sha256 diverge (sha256sum -c); "
fi
if [ "$NESTED" != "1" ]; then
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" \
           "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11" "$ORACLE12" \
           "$ORACLE13" "$ORACLE14" "$ORACLE15" "$ORACLE16"; do
    if [ ! -x "$o" ]; then
      FR8_OK=0; EVID8="${EVID8}$(basename "$o") ausente ou nao executavel; "
      break
    else
      rc=0
      timeout 5 env FKX_ORACLE_NESTED=1 bash "$o" --quiet > /dev/null 2>&1 || rc=$?
      if [ "$rc" != "0" ] && [ "$rc" != "124" ]; then
        FR8_OK=0; EVID8="${EVID8}$(basename "$o") --quiet reprovou (rc=$rc); "
        break
      fi
    fi
  done
fi
if [ "$FR8_OK" = "1" ]; then pass "FR-008" "${CANON[FR-008]}"; else fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID8"; fi

# =============================================================================
# FR-009: README 017 hash + zero [ ] + vermelho-verde
# =============================================================================
FR9_OK=1; EVID9=""
if [ ! -f "$README_SPECS" ]; then
  FR9_OK=0; EVID9="${EVID9}specs/README.md ausente; "
elif ! grep -iq "017.*harness.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR9_OK=0; EVID9="${EVID9}README sem \"017.*harness.*✅.*hash\"; "
fi
if [ ! -f "$TASKS017" ]; then
  FR9_OK=0; EVID9="${EVID9}specs/017-harness/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS017" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR9_OK=0; EVID9="${EVID9}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*017" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(harness).*017" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR9_OK=0; EVID9="${EVID9}par vermelho/verde 017 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR9_OK=0; EVID9="${EVID9}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# FR-010: PLAN declara + ADR previa autoriza; f0-011 admite harness.py e nada alem
# =============================================================================
FR10_OK=1; EVID10=""
if [ ! -f "$PLAN017" ]; then
  FR10_OK=0; EVID10="${EVID10}specs/017-harness/plan.md ausente; "
elif ! grep -q "f0-011" "$PLAN017" 2>/dev/null; then
  FR10_OK=0; EVID10="${EVID10}PLAN sem declaracao de fronteira f0-011 (molde ADR-017); "
fi
if [ ! -f "$DECISIONS" ]; then
  FR10_OK=0; EVID10="${EVID10}docs/plan/decisions.md ausente; "
elif ! grep -q "harness\.py" "$DECISIONS" 2>/dev/null; then
  FR10_OK=0; EVID10="${EVID10}sem ADR previa autorizando harness.py (10a execucao); "
fi
if ! grep -q '"harness\.py"' "$F0011" 2>/dev/null; then
  FR10_OK=0; EVID10="${EVID10}f0-011 FR-002 sem whitelist de harness.py; "
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: so stdlib; uv.lock sem pacote novo (Escada)
# =============================================================================
FR11_OK=1; EVID11=""
if [ ! -f "$HARNESS" ]; then
  FR11_OK=0; EVID11="${EVID11}harness.py ausente; "
else
  if grep -E "^import |^from " "$HARNESS" 2>/dev/null | grep -qvE "^(import|from) (os|sys|subprocess|typing|__future__|fkx_core|\.)" 2>/dev/null; then
    HIT11=$(grep -E "^import |^from " "$HARNESS" 2>/dev/null | grep -vE "^(import|from) (os|sys|subprocess|typing|__future__|fkx_core|\.)" | head -1 | cut -c1-100 || true)
    FR11_OK=0; EVID11="${EVID11}import fora da stdlib permitida: $HIT11; "
  fi
fi
if [ ! -f "$UVLOCK" ]; then
  FR11_OK=0; EVID11="${EVID11}uv.lock ausente; "
elif grep -q '^name = "harness"' "$UVLOCK" 2>/dev/null; then
  FR11_OK=0; EVID11="${EVID11}pacote harness no uv.lock (dependencia nova); "
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: POSIX declarado; nonposix fail-closed nomeado (ANALYZE C3)
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$HARNESS" ]; then
  FR12_OK=0; EVID12="${EVID12}harness.py ausente; "
else
  if ! grep -qE "os\.name|FORCE_PLATFORM" "$HARNESS" 2>/dev/null; then
    FR12_OK=0; EVID12="${EVID12}portao de plataforma ausente no fonte; "
  fi
  if [ "$NESTED" != "1" ]; then
    if [ "$P2_RC" != "0" ]; then
      FR12_OK=0; EVID12="${EVID12}sonda P2 indisponivel (rc=$P2_RC); "
    else
      if ! grep -q "^SC=truestrict exit=2 req=FR-012$" "$TMPD/p2.out" 2>/dev/null; then
        FR12_OK=0; EVID12="${EVID12}nonposix sem recusa nomeada FR-012; "
      fi
    fi
  fi
fi
if [ "$FR12_OK" = "1" ]; then pass "FR-012" "${CANON[FR-012]}"; else fail "FR-012" "${CANON[FR-012]}" "alta" "$EVID12"; fi

# =============================================================================
# Relatório
# =============================================================================
TOTAL=${#R_ID[@]}
OK=0; BAD=0; SKIPPED=0
CRIT=0; ALTA=0; MEDIA=0

for i in "${!R_ID[@]}"; do
  case "${R_STATUS[$i]}" in
    ok)   OK=$((OK+1));           SYM="✅" ;;
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
