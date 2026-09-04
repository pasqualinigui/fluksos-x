#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 011 (0.6): packages/core kernel
#
# Contrato de assercoes deste item:
#   specs/011-packages-core/spec.md (12 FRs, 6 SCs, 3 US)
#   specs/011-packages-core/plan.md (Fases A-E, D1-D7, fronteira ADR-017)
#   specs/011-packages-core/contracts/oracle-cli.md (mapa identidade 12 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-011-packages-core.md (Q1-Q10 D1-D7, 2026-09-04)
#   specs/011-packages-core/research.md (4 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento, protegem invariante):
#     FR-010 (contrato auto-verificavel), FR-011 (manifest accretion +
#     self-check herdado: ambos verdadeiros antes do codigo por construcao)
#   Comportamento (carregam o vermelho 10/12):
#     FR-001..009/012
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-010 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-09-04:
#   D1 pydantic==2.13.5 + pydantic-settings==2.15.0 runtime do pacote (Q1, CLARIFY)
#   D2 settings FKX_ minimas + SecretStr; .env.example extensivel (Q2)
#   D3 TypedDict + reducers; Pydantic em models, nunca state (Q3)
#   D4 sem grafo compilado/agentes (Q4, Escada/Fase 2)
#   D5 src/fkx_core/ membro; testes em tests/ (Q5/Q7)
#   D6 FkxError + ConfigError/StateError/ModelError (Q9)
#   D7 fronteira Q8 (.env.example-sim, .env-nunca, sem cli/docker/grafo)
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
  ["FR-001"]="pydantic+settings runtime packages/core + hash lock"
  ["FR-002"]="membro UV + 4 modulos + init nada alem"
  ["FR-003"]="settings FKX_ + SecretStr + ConfigError"
  ["FR-004"]="TypedDict canais/reducers sem Pydantic state"
  ["FR-005"]="modelos Pydantic sem logica"
  ["FR-006"]="FkxError + 3 sem except nu"
  ["FR-007"]="ruff + mypy zeros src/fkx_core"
  ["FR-008"]="testes tests/test_fkx_core verdes TDD"
  ["FR-009"]="env example cobre vars env nunca"
  ["FR-010"]="contrato: list 12 exit2 2x <5s"
  ["FR-011"]="manifest 11/11 + self-check f0-001..010"
  ["FR-012"]="README 011 hash + zero [ ] + vermelho-verde"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012"

PKGDIR="$ROOT/packages/core"
SRCDIR="$PKGDIR/src/fkx_core"
PYPROJECT_PKG="$PKGDIR/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
ENVEXAMPLE="$ROOT/.env.example"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS011="$ROOT/specs/011-packages-core/tasks.md"
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
ORACLE10="$SCRIPT_DIR/f0-010-ci-completo.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: pydantic(+settings) runtime em packages/core + hash lock
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$PYPROJECT_PKG" ]; then
  FR1_OK=0; EVID1="${EVID1}packages/core/pyproject.toml ausente; "
elif ! python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); deps=d.get("project",{}).get("dependencies",[]); assert "pydantic==2.13.5" in deps, deps; assert "pydantic-settings==2.15.0" in deps, deps' "$PYPROJECT_PKG" 2>/dev/null; then
  FR1_OK=0; EVID1="${EVID1}dependencies sem pydantic==2.13.5+pydantic-settings==2.15.0 (D1 runtime); "
fi
if [ ! -f "$UVLOCK" ]; then
  FR1_OK=0; EVID1="${EVID1}uv.lock ausente; "
else
  if ! grep -q 'name = "pydantic"' "$UVLOCK" 2>/dev/null; then FR1_OK=0; EVID1="${EVID1}lock sem pydantic; "; fi
  if ! grep -q 'name = "pydantic-settings"' "$UVLOCK" 2>/dev/null; then FR1_OK=0; EVID1="${EVID1}lock sem pydantic-settings; "; fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: membro UV + exatamente 4 modulos + __init__
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -d "$PKGDIR" ]; then
  FR2_OK=0; EVID2="${EVID2}packages/core/ ausente; "
else
  for m in __init__.py config.py state.py models.py exceptions.py; do
    if [ ! -f "$SRCDIR/$m" ]; then FR2_OK=0; EVID2="${EVID2}src/fkx_core/$m ausente; "; fi
  done
  EXTRA=$(ls "$SRCDIR" 2>/dev/null | grep -v -x -e "__init__.py" -e "config.py" -e "state.py" -e "models.py" -e "exceptions.py" -e "py.typed" -e "__pycache__" | tr '\n' ' ' || true)
  if [ -n "$EXTRA" ]; then FR2_OK=0; EVID2="${EVID2}modulos alem dos 4: $EXTRA (Q8); "; fi
  if [ -d "$ROOT/packages/cli" ]; then FR2_OK=0; EVID2="${EVID2}packages/cli existe (deve ser 012); "; fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: settings FKX_ + SecretStr + ConfigError
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$SRCDIR/config.py" ]; then
  FR3_OK=0; EVID3="${EVID3}config.py ausente; "
else
  if ! grep -q "FKX_" "$SRCDIR/config.py" 2>/dev/null; then FR3_OK=0; EVID3="${EVID3}prefixo FKX_ ausente; "; fi
  if ! grep -q "SecretStr" "$SRCDIR/config.py" 2>/dev/null; then FR3_OK=0; EVID3="${EVID3}SecretStr ausente (Lei Zero); "; fi
  if ! grep -q "ConfigError" "$SRCDIR/config.py" 2>/dev/null; then FR3_OK=0; EVID3="${EVID3}ConfigError ausente; "; fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: TypedDict canais/reducers; sem Pydantic como state
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$SRCDIR/state.py" ]; then
  FR4_OK=0; EVID4="${EVID4}state.py ausente; "
else
  if ! grep -q "TypedDict" "$SRCDIR/state.py" 2>/dev/null; then FR4_OK=0; EVID4="${EVID4}TypedDict ausente (Q3); "; fi
  for k in status etapa erros; do
    if ! grep -q "\"$k\"\|'$k'\|$k:" "$SRCDIR/state.py" 2>/dev/null; then FR4_OK=0; EVID4="${EVID4}canal $k ausente; "; fi
  done
  if grep -q "BaseModel" "$SRCDIR/state.py" 2>/dev/null; then FR4_OK=0; EVID4="${EVID4}BaseModel em state.py proibido (Q3); "; fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: modelos Pydantic sem logica
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$SRCDIR/models.py" ]; then
  FR5_OK=0; EVID5="${EVID5}models.py ausente; "
else
  if ! grep -q "BaseModel" "$SRCDIR/models.py" 2>/dev/null; then FR5_OK=0; EVID5="${EVID5}BaseModel ausente em models.py; "; fi
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: FkxError + 3; sem except nu / BaseException
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$SRCDIR/exceptions.py" ]; then
  FR6_OK=0; EVID6="${EVID6}exceptions.py ausente; "
else
  for e in "FkxError" "ConfigError" "StateError" "ModelError"; do
    if ! grep -q "class $e" "$SRCDIR/exceptions.py" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}class $e ausente; "; fi
  done
  if grep -rEq 'except:[ ]*(#|$)' "$SRCDIR" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}except: nu no pacote; "; fi
  if grep -Eq 'BaseException' "$SRCDIR/exceptions.py" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}BaseException direta proibida; "; fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: ruff + mypy zeros sobre src/fkx_core/
# =============================================================================
if [ ! -d "$SRCDIR" ]; then
  fail "FR-007" "${CANON[FR-007]}" "alta" "src/fkx_core/ ausente"
else
  FR7_OK=1; EVID7=""
  if [ "$NESTED" != "1" ] && command -v uv >/dev/null 2>&1 && [ -f "$UVLOCK" ]; then
    if ! uv run ruff check "$SRCDIR" >/dev/null 2>&1; then FR7_OK=0; EVID7="${EVID7}ruff check reprovou; "; fi
    if ! uv run ruff format --check "$SRCDIR" >/dev/null 2>&1; then FR7_OK=0; EVID7="${EVID7}ruff format reprovou; "; fi
    if ! uv run mypy --strict "$SRCDIR" >/dev/null 2>&1; then FR7_OK=0; EVID7="${EVID7}mypy --strict reprovou; "; fi
  fi
  if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi
fi

# =============================================================================
# FR-008: testes tests/test_fkx_core_*.py verdes
# =============================================================================
if ! ls "$ROOT"/tests/test_fkx_core_*.py >/dev/null 2>&1; then
  fail "FR-008" "${CANON[FR-008]}" "alta" "tests/test_fkx_core_*.py ausentes (TDD, Q7)"
else
  if [ "$NESTED" != "1" ] && command -v uv >/dev/null 2>&1; then
    if uv run pytest -q "$ROOT"/tests/test_fkx_core_*.py >/dev/null 2>&1; then
      pass "FR-008" "${CANON[FR-008]}"
    else
      fail "FR-008" "${CANON[FR-008]}" "alta" "pytest test_fkx_core_* reprovou"
    fi
  else
    pass "FR-008" "${CANON[FR-008]}"
  fi
fi

# =============================================================================
# FR-009: .env.example cobre vars; .env jamais versionado
# =============================================================================
FR9_OK=1; EVID9=""
if git ls-files --error-unmatch .env >/dev/null 2>&1 || [ -f "$ROOT/.env" ]; then
  # .env presente no disco e rastreado = violacao; presente nao-rastreado = tolerado? NAO: Lei Zero, .env nao entra
  if git ls-files --error-unmatch .env >/dev/null 2>&1; then FR9_OK=0; EVID9="${EVID9}.env rastreado (Lei Zero); "; fi
fi
if [ ! -f "$ENVEXAMPLE" ]; then
  FR9_OK=0; EVID9="${EVID9}.env.example ausente (T017 documenta vars); "
else
  for v in FKX_ENV FKX_LOG_LEVEL FKX_API_SECRET; do
    if ! grep -q "$v" "$ENVEXAMPLE" 2>/dev/null; then FR9_OK=0; EVID9="${EVID9}$v ausente em .env.example (T017); "; fi
  done
fi
if [ ! -f "$SRCDIR/config.py" ]; then
  FR9_OK=0; EVID9="${EVID9}config.py ausente; "
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# FR-010: contrato (list 12, exit 2, 2x byte-identico, <5s) (guarda)
# =============================================================================
FR10_OK=1; EVID10=""
if [ "$NESTED" != "1" ]; then
  if [ -n "${EPOCHSECONDS:-}" ]; then START10=$EPOCHSECONDS; else START10=$(date +%s 2>/dev/null || echo 0); fi
  TMPD="$(mktemp -d)"
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    FR10_OK=0; EVID10="${EVID10}--list falhou; "
  else
    LIST_COUNT=$(FKX_ORACLE_NESTED=1 "$SELF" --list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LIST_COUNT" != "12" ] 2>/dev/null; then
      FR10_OK=0; EVID10="${EVID10}--list contagem $LIST_COUNT != 12; "
    fi
  fi
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    FR10_OK=0; EVID10="${EVID10}exit 2 para uso invalido nao obedecido; "
  fi
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; C1=$?
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; C2=$?
  if [ -n "${EPOCHSECONDS:-}" ]; then END10=$EPOCHSECONDS; else END10=$(date +%s 2>/dev/null || echo 0); fi
  ELAPSED10=$((END10 - START10))
  if [ "$ELAPSED10" -gt 5 ] 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}oraculo >5s (${ELAPSED10}s, SC-006); "
  fi
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR10_OK=0
    DIFF_SNIP=$(diff -u "$TMPD/r1" "$TMPD/r2" 2>/dev/null | head -5 | tr -d '\n' | cut -c1-80 || true)
    EVID10="${EVID10}duas execucoes divergiram; C1=$C1 C2=$C2 diff:${DIFF_SNIP}; "
  fi
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: manifest 11/11 + self-check f0-001..010
# =============================================================================
FR11_OK=1; EVID11=""
if [ ! -f "$MANIFEST" ]; then
  FR11_OK=0; EVID11="${EVID11}manifest.sha256 ausente; "
else
  LINES=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
  LINES=$(echo "$LINES" | tr -d '[:space:]')
  if [ -z "$LINES" ] || [ "$LINES" -lt 11 ] 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}manifest com $LINES linhas (esperado >=11, piso); "
  elif ! sha256sum -c "$MANIFEST" >/dev/null 2>&1; then
    FR11_OK=0; EVID11="${EVID11}sha256sum -c reprovou; "
  fi
fi
if [ "$NESTED" != "1" ] && [ "$FR11_OK" = "1" ]; then
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FR11_OK=0; EVID11="${EVID11}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: README 011 hash + zero [ ] + vermelho-verde
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$README_SPECS" ]; then
  FR12_OK=0; EVID12="${EVID12}specs/README.md ausente; "
elif ! grep -iq "011.*packages-core.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR12_OK=0; EVID12="${EVID12}README sem \"011.*packages-core.*✅.*hash\"; "
fi
if [ ! -f "$TASKS011" ]; then
  FR12_OK=0; EVID12="${EVID12}specs/011-packages-core/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS011" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR12_OK=0; EVID12="${EVID12}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*011" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(packages).*011" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR12_OK=0; EVID12="${EVID12}par vermelho/verde 011 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR12_OK=0; EVID12="${EVID12}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
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
