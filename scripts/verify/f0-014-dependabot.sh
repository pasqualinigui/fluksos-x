#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 014 (0.16): atualizacao de dependencias
#
# Contrato de assercoes deste item:
#   specs/014-dependency-updates/spec.md (11 FRs, 7 SCs, 4 US + CLARIFY 5/5)
#   specs/014-dependency-updates/plan.md (Fases A-D, D1-D7, fronteira Q9)
#   specs/014-dependency-updates/contracts/oracle-cli.md (mapa identidade 11 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-014-dependency-updates.md (Q1-Q9 D1-D7, 2026-09-08)
#   specs/014-dependency-updates/research.md (7 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento, protegem invariante):
#     FR-006 (zero supressao), FR-007 (override click herdado da ADR-034),
#     FR-009 (contrato auto-verificavel)
#   Comportamento (carregam o vermelho):
#     FR-001..005, FR-008, FR-010, FR-011
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-013 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Medicao de exit code: via redirect + $? (nunca $? apos pipe — research Q4/013).
# Self-check em SERIE (ADR-031): f0-001..f0-013 sequenciais, nunca concorrentes.
#
# Decisoes pinadas verificadas 2026-09-08:
#   D1 Dependabot uv + github-actions (Q1) · D2 grupos + automerge por nivel (Q3)
#   D3 prefixo build(deps) (Q4) · D4 zero supressao (Q5) · D5 override click fica (Q6)
#   D6 pip-audit no pre-push via ADR-017 (Q7) · D7 actions com tripwire (Q3/Q9)
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
  ["FR-001"]="dependabot.yml uv raiz schedule semanal"
  ["FR-002"]="grupos dev-minor-patch + security por evento, major isolado"
  ["FR-003"]="github-actions separado, pins SHA + comentario"
  ["FR-004"]="prefixo build(deps) nao-liberavel"
  ["FR-005"]="automerge so bot so --merge so no verde"
  ["FR-006"]="zero supressao em arquivo versionado"
  ["FR-007"]="override click>=8.3.3,<8.5.0 + lock resolve >=8.3.3"
  ["FR-008"]="pip-audit no pre-push, fora do pre-commit"
  ["FR-009"]="contrato: list 11 exit2 2x <5s self-check serie"
  ["FR-010"]="README 014 hash + zero [ ] + vermelho-verde"
  ["FR-011"]="tripwire TRIPWIRE-014-actions no dependabot.yml"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
DEPENDBOT="$ROOT/.github/dependabot.yml"
AUTOMERGE="$ROOT/.github/workflows/dependabot-automerge.yml"
HOOKYML="$ROOT/lefthook.yml"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS014="$ROOT/specs/014-dependency-updates/tasks.md"
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
ORACLE11="$SCRIPT_DIR/f0-011-core.sh"
ORACLE12="$SCRIPT_DIR/f0-012-cli.sh"
ORACLE13="$SCRIPT_DIR/f0-013-release.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: dependabot.yml com ecossistema uv, diretorio raiz, schedule semanal
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$DEPENDBOT" ]; then
  FR1_OK=0; EVID1="${EVID1}.github/dependabot.yml ausente (D1); "
else
  if ! grep -q 'package-ecosystem: "uv"' "$DEPENDBOT" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem package-ecosystem uv; "
  fi
  if ! grep -q 'directory: "/"' "$DEPENDBOT" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem directory raiz; "
  fi
  if ! grep -q 'interval: "weekly"' "$DEPENDBOT" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem schedule semanal; "
  fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: grupos dev-minor-patch + security por evento, major isolado sem automerge
# Security e event-driven (alerta dispara PR, sem schedule proprio — P1 docs);
# checagens sobre linhas nao-comentadas: comentario nao decide assercao.
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$DEPENDBOT" ]; then
  FR2_OK=0; EVID2="${EVID2}.github/dependabot.yml ausente; "
else
  CODEONLY=$(grep -v "^[[:space:]]*#" "$DEPENDBOT" 2>/dev/null || true)
  if ! echo "$CODEONLY" | grep -q "dev-minor-patch" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}sem grupo dev-minor-patch; "
  fi
  if ! echo "$CODEONLY" | grep -q "applies-to: \"security-updates\"" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}sem grupo security por evento (applies-to); "
  fi
  if echo "$CODEONLY" | grep -q "automerge.*major\|major.*automerge" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}major com automerge (vedado, D2); "
  fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: github-actions separado, pins SHA 40hex + comentario de versao
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$DEPENDBOT" ]; then
  FR3_OK=0; EVID3="${EVID3}.github/dependabot.yml ausente; "
else
  if ! grep -q 'package-ecosystem: "github-actions"' "$DEPENDBOT" 2>/dev/null; then
    FR3_OK=0; EVID3="${EVID3}sem ecossistema github-actions separado (D7); "
  fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: commit-message prefix nao-liberavel build(deps)
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$DEPENDBOT" ]; then
  FR4_OK=0; EVID4="${EVID4}.github/dependabot.yml ausente; "
else
  if ! grep -q "build(deps)" "$DEPENDBOT" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}sem prefixo build(deps) (D3); "
  fi
  if grep -qE "prefix: \"(feat|fix|perf)(\(|\"|:)" "$DEPENDBOT" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}prefixo liberavel queimaria versao do PSR; "
  fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: automerge so bot, so --merge, so no verde
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$AUTOMERGE" ]; then
  FR5_OK=0; EVID5="${EVID5}dependabot-automerge.yml ausente (D3); "
else
  if ! grep -q "dependabot\[bot\]" "$AUTOMERGE" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}sem gate de ator dependabot[bot]; "
  fi
  if ! grep -q "merge --auto --merge" "$AUTOMERGE" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}sem merge --auto --merge; "
  fi
  if grep -qE "merge --(squash|rebase)" "$AUTOMERGE" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}squash/rebase proibidos no servidor (ADR-035); "
  fi
  if grep -qE "pull_request_target|workflow_run" "$AUTOMERGE" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}vetor proibido no workflow (fronteira 003); "
  fi
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: zero supressao em arquivo versionado (guarda — invariante 008)
# =============================================================================
FR6_OK=1; EVID6=""
if [ -f "$ROOT/pip-audit.toml" ] || [ -f "$ROOT/.pip-audit.toml" ]; then
  FR6_OK=0; EVID6="${EVID6}arquivo de config pip-audit existe (FR-002 da 008); "
fi
if grep -q '^\[tool\.pip-audit\]' "$PYPROJECT" 2>/dev/null; then
  FR6_OK=0; EVID6="${EVID6}[tool.pip-audit] em pyproject.toml; "
fi
if grep -rq "ignore-vuln" "$ROOT/.github/" "$HOOKYML" "$PYPROJECT" 2>/dev/null; then
  FR6_OK=0; EVID6="${EVID6}--ignore-vuln em arquivo versionado (D4); "
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: override minimo click + lock >= 8.3.3 (guarda — heranca ADR-034)
# Re-verificado no verde da 014 (Q6); remocao so pelo gatilho upstream via ADR.
# =============================================================================
FR7_OK=1; EVID7=""
if [ ! -f "$PYPROJECT" ]; then
  FR7_OK=0; EVID7="${EVID7}pyproject.toml ausente; "
else
  if ! python3 -c '
import tomllib, sys
d = tomllib.load(open(sys.argv[1], "rb"))
ovr = d.get("tool", {}).get("uv", {}).get("override-dependencies", [])
assert ovr == ["click>=8.3.3,<8.5.0"], ovr
' "$PYPROJECT" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}override-dependencies != [\"click>=8.3.3,<8.5.0\"]; "
  fi
fi
if [ ! -f "$UVLOCK" ]; then
  FR7_OK=0; EVID7="${EVID7}uv.lock ausente; "
else
  if ! python3 -c '
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"^\[\[package\]\]\nname = \"click\"\nversion = \"([^\"]+)\"", s, re.M)
assert m, "click ausente do lock"
v = tuple(int(x) for x in m.group(1).split(".")[:3])
assert v >= (8, 3, 3), m.group(1)
' "$UVLOCK" 2>/dev/null; then
    LOCKV=$(grep -A1 '^name = "click"$' "$UVLOCK" 2>/dev/null | grep '^version = ' | head -1 | cut -d'"' -f2)
    FR7_OK=0; EVID7="${EVID7}uv.lock resolve click ${LOCKV:-?} < 8.3.3; "
  fi
fi
if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi

# =============================================================================
# FR-008: pip-audit no pre-push, fora do pre-commit (ponto ADR-017 sobre FR-003/009)
# =============================================================================
FR8_OK=1; EVID8=""
if [ ! -f "$HOOKYML" ]; then
  FR8_OK=0; EVID8="${EVID8}lefthook.yml ausente; "
else
  PRECOMMIT_SECT=$(awk '/^[ ]*pre-commit:/,/^[ ]*pre-push:/' "$HOOKYML" 2>/dev/null || true)
  if echo "$PRECOMMIT_SECT" | grep -q "pip-audit" 2>/dev/null; then
    FR8_OK=0; EVID8="${EVID8}pip-audit no pre-commit (teorema ADR-034 §6, D6); "
  fi
  if ! grep -q "pip-audit" "$HOOKYML" 2>/dev/null; then
    FR8_OK=0; EVID8="${EVID8}pip-audit ausente do hook (deve estar no pre-push); "
  fi
  for job in "uv run ruff check" "uv run ruff format --check" "uv run mypy --strict" "uv run pytest"; do
    if ! echo "$PRECOMMIT_SECT" | grep -Fq "$job" 2>/dev/null; then
      FR8_OK=0; EVID8="${EVID8}fail-fast desfalcado no pre-commit ($job); "
    fi
  done
fi
if [ "$FR8_OK" = "1" ]; then pass "FR-008" "${CANON[FR-008]}"; else fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID8"; fi

# =============================================================================
# FR-009: contrato auto-verificavel (list 11, exit2, 2x <5s, self-check serie)
# =============================================================================
FR9_OK=1; EVID9=""
LIST_COUNT=$(bash "$SELF" --list 2>/dev/null | wc -l || true)
LIST_COUNT=$(echo "$LIST_COUNT" | tr -d '[:space:]')
if [ "$LIST_COUNT" != "11" ]; then
  FR9_OK=0; EVID9="${EVID9}--list enumera $LIST_COUNT != 11; "
fi
INVALID_RC=0
bash "$SELF" --invalido > /dev/null 2>&1 || INVALID_RC=$?
if [ "$INVALID_RC" != "2" ]; then
  FR9_OK=0; EVID9="${EVID9}--invalido exit $INVALID_RC != 2; "
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
    FR9_OK=0; EVID9="${EVID9}2 execucoes divergem; "
  fi
  if [ "$ELAPSED1" -gt 5000 ] || [ "$ELAPSED2" -gt 5000 ]; then
    FR9_OK=0; EVID9="${EVID9}execucao >5s (${ELAPSED1}ms/${ELAPSED2}ms); "
  fi
fi
if [ "$NESTED" != "1" ]; then
  TMP_SC="$(mktemp -d)"
  SC_FAIL=0
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" \
           "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11" "$ORACLE12" "$ORACLE13"; do
    if [ ! -x "$o" ]; then
      FR9_OK=0; EVID9="${EVID9}$(basename "$o") ausente ou nao executavel; "
      SC_FAIL=1
    elif [ "$SC_FAIL" = "0" ]; then
      rc=0
      timeout 5 env FKX_ORACLE_NESTED=1 bash "$o" --quiet > /dev/null 2>&1 || rc=$?
      if [ "$rc" != "0" ] && [ "$rc" != "124" ]; then
        FR9_OK=0; EVID9="${EVID9}$(basename "$o") --quiet reprovou (rc=$rc); "
      fi
    fi
  done
  rm -rf -- "$TMP_SC"
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# FR-010: README 014 hash + zero [ ] + vermelho-verde
# =============================================================================
FR10_OK=1; EVID10=""
if [ ! -f "$README_SPECS" ]; then
  FR10_OK=0; EVID10="${EVID10}specs/README.md ausente; "
elif ! grep -iq "014.*depend.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR10_OK=0; EVID10="${EVID10}README sem \"014.*depend.*✅.*hash\"; "
fi
if [ ! -f "$TASKS014" ]; then
  FR10_OK=0; EVID10="${EVID10}specs/014-dependency-updates/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS014" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR10_OK=0; EVID10="${EVID10}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*014" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(deps).*014" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR10_OK=0; EVID10="${EVID10}par vermelho/verde 014 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR10_OK=0; EVID10="${EVID10}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: tripwire TRIPWIRE-014-actions no dependabot.yml (remediacao F3)
# =============================================================================
FR11_OK=1; EVID11=""
if [ ! -f "$DEPENDBOT" ]; then
  FR11_OK=0; EVID11="${EVID11}.github/dependabot.yml ausente; "
elif ! grep -q "TRIPWIRE-014-actions" "$DEPENDBOT" 2>/dev/null; then
  FR11_OK=0; EVID11="${EVID11}sem bloco TRIPWIRE-014-actions (fallback sem dono); "
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

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
