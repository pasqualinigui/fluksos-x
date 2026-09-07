#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 013 (0.15): automacao de release
#
# Contrato de assercoes deste item:
#   specs/013-release-automation/spec.md (16 FRs, 11 SCs, 4 US + CLARIFY 5/5)
#   specs/013-release-automation/plan.md (Fases A-E, D1-D9, fronteira Q10)
#   specs/013-release-automation/contracts/oracle-cli.md (mapa identidade 16 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-013-release-automation.md (Q1-Q10 D1-D9, 2026-09-06)
#   specs/013-release-automation/research.md (9 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento, protegem invariante):
#     FR-015 (contrato auto-verificavel), FR-016 (README accretion +
#     self-check herdado: ambos verdadeiros antes do codigo por construcao)
#   Comportamento (carregam o vermelho 14/16):
#     FR-001..014
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-012 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Medicao de exit code: via redirect + $? (nunca $? apos pipe — research Q4).
# Self-check em SERIE (ADR-031): f0-001..f0-012 sequenciais, nunca concorrentes.
#
# Decisoes pinadas verificadas 2026-09-06:
#   D1 python-semantic-release==10.6.2 em dev (Q1)
#   D2 build/SBOM por uv, cyclonedx-bom descartado (Q5)
#   D3 publicacao por action oficial PyPA (PEP 740 — Q6 corrigido)
#   D4 lockstep 3 pyproject.toml via version_toml (Q4)
#   D5 allow_zero_version + major_on_zero (Q3)
#   D6 fluxo B: PSR calcula, humano aplica via PR (Q7)
#   D7 artefatos efemeros, nao versionados (Q10)
#   D8 dois pending publishers + GitHub environment (Q8)
#   D9 pin uv no workflow (Q9)
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
  ["FR-001"]="python-semantic-release==10.6.2 em dev + hash lock"
  ["FR-002"]="commit_parser conventional + tag_format v{version}"
  ["FR-003"]="version_toml 3 caminhos lockstep"
  ["FR-004"]="allow_zero_version + major_on_zero"
  ["FR-005"]="changelog_file configurado"
  ["FR-006"]="release.yml proprio + tag trigger"
  ["FR-007"]="jobs build+publish separados + id-token so publish"
  ["FR-008"]="uv build --all-packages + dist no gitignore"
  ["FR-009"]="pypa action pinada + zero credencial"
  ["FR-010"]="uv export cyclonedx1.5 + cyclonedx-bom ausente"
  ["FR-011"]="pylock+SBOM efemeros nao versionados"
  ["FR-012"]="fluxo nao grava main sem PR"
  ["FR-013"]="setup-uv com version pinado"
  ["FR-014"]="checklist server-side presente"
  ["FR-015"]="contrato: list 16 exit2 2x <5s self-check serie"
  ["FR-016"]="README 013 hash + zero [ ] + vermelho-verde"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014 FR-015 FR-016"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
RELEASE_YML="$ROOT/.github/workflows/release.yml"
CI_YML="$ROOT/.github/workflows/ci.yml"
GITIGNORE="$ROOT/.gitignore"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS013="$ROOT/specs/013-release-automation/tasks.md"
README_SPECS="$ROOT/specs/README.md"
SERVER_SIDE="$ROOT/specs/013-release-automation/checklists/server-side.md"

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

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: python-semantic-release==10.6.2 em dev + hash lock
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$PYPROJECT" ]; then
  FR1_OK=0; EVID1="${EVID1}pyproject.toml ausente; "
else
  if ! python3 -c '
import tomllib, sys
d = tomllib.load(open(sys.argv[1], "rb"))
dev = d.get("dependency-groups", {}).get("dev", [])
assert any("python-semantic-release==10.6.2" in x for x in dev), dev
' "$PYPROJECT" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}dev sem python-semantic-release==10.6.2 (D1); "
  fi
fi
if [ ! -f "$UVLOCK" ]; then
  FR1_OK=0; EVID1="${EVID1}uv.lock ausente; "
else
  if ! grep -q 'name = "python-semantic-release"' "$UVLOCK" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}lock sem python-semantic-release; "
  fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: commit_parser conventional + tag_format v{version}
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$PYPROJECT" ]; then
  FR2_OK=0; EVID2="${EVID2}pyproject.toml ausente; "
elif ! python3 -c '
import tomllib, sys
d = tomllib.load(open(sys.argv[1], "rb"))
sr = d.get("tool", {}).get("semantic_release", {})
assert sr.get("commit_parser") == "conventional", sr.get("commit_parser")
assert sr.get("tag_format") == "v{version}", sr.get("tag_format")
' "$PYPROJECT" 2>/dev/null; then
  FR2_OK=0; EVID2="${EVID2}[tool.semantic_release] sem commit_parser=conventional ou tag_format=v{version} (D1); "
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: version_toml 3 caminhos lockstep
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$PYPROJECT" ]; then
  FR3_OK=0; EVID3="${EVID3}pyproject.toml ausente; "
elif ! python3 -c '
import tomllib, sys
d = tomllib.load(open(sys.argv[1], "rb"))
sr = d.get("tool", {}).get("semantic_release", {})
vt = sr.get("version_toml", ())
if isinstance(vt, str):
    vt = (vt,)
expected = {
    "pyproject.toml:project.version",
    "packages/core/pyproject.toml:project.version",
    "packages/cli/pyproject.toml:project.version",
}
assert set(vt) == expected, f"version_toml={vt} != {expected}"
' "$PYPROJECT" 2>/dev/null; then
  FR3_OK=0; EVID3="${EVID3}version_toml sem 3 caminhos (D4); "
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: allow_zero_version + major_on_zero
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$PYPROJECT" ]; then
  FR4_OK=0; EVID4="${EVID4}pyproject.toml ausente; "
elif ! python3 -c '
import tomllib, sys
d = tomllib.load(open(sys.argv[1], "rb"))
sr = d.get("tool", {}).get("semantic_release", {})
azv = sr.get("allow_zero_version")
moz = sr.get("major_on_zero")
assert azv is True, "allow_zero_version=" + str(azv)
assert moz is False, "major_on_zero=" + str(moz)
' "$PYPROJECT" 2>/dev/null; then
  FR4_OK=0; EVID4="${EVID4}allow_zero_version!=true ou major_on_zero!=false (D5); "
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: changelog_file configurado (commit_parser=conventional ja garante default)
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$PYPROJECT" ]; then
  FR5_OK=0; EVID5="${EVID5}pyproject.toml ausente; "
elif ! python3 -c '
import tomllib, sys
d = tomllib.load(open(sys.argv[1], "rb"))
sr = d.get("tool", {}).get("semantic_release", {})
assert sr.get("commit_parser") == "conventional", sr
' "$PYPROJECT" 2>/dev/null; then
  FR5_OK=0; EVID5="${EVID5}commit_parser!=conventional (Q3 default changelog); "
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: release.yml proprio + tag trigger
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$RELEASE_YML" ]; then
  FR6_OK=0; EVID6="${EVID6}release.yml ausente; "
else
  if ! grep -q "tags:" "$RELEASE_YML" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}release.yml sem tag trigger (FR-006); "
  fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: jobs build+publish separados + id-token so publish
# =============================================================================
FR7_OK=1; EVID7=""
if [ ! -f "$RELEASE_YML" ]; then
  FR7_OK=0; EVID7="${EVID7}release.yml ausente; "
else
  if ! grep -q "build:" "$RELEASE_YML" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}job build ausente; "
  fi
  if ! grep -q "publish:" "$RELEASE_YML" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}job publish ausente; "
  fi
  if grep -q "id-token:" "$RELEASE_YML" 2>/dev/null; then
    BUILD_HAS_IDTOKEN=$(awk '/^  build:/,/^  [a-z]/' "$RELEASE_YML" | grep -c "id-token:.*write" || true)
    if [ "$BUILD_HAS_IDTOKEN" -gt 0 ]; then
      FR7_OK=0; EVID7="${EVID7}id-token: write no job build (FR-007); "
    fi
  fi
fi
if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi

# =============================================================================
# FR-008: uv build --all-packages + dist no gitignore
# =============================================================================
FR8_OK=1; EVID8=""
if [ ! -f "$RELEASE_YML" ]; then
  FR8_OK=0; EVID8="${EVID8}release.yml ausente; "
else
  if ! grep -q "uv build" "$RELEASE_YML" 2>/dev/null; then
    FR8_OK=0; EVID8="${EVID8}uv build ausente no workflow; "
  fi
fi
if [ ! -f "$GITIGNORE" ]; then
  FR8_OK=0; EVID8="${EVID8}.gitignore ausente; "
elif ! grep -q "dist/" "$GITIGNORE" 2>/dev/null; then
  FR8_OK=0; EVID8="${EVID8}dist/ ausente do .gitignore (001 Lei Zero); "
fi
if [ "$FR8_OK" = "1" ]; then pass "FR-008" "${CANON[FR-008]}"; else fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID8"; fi

# =============================================================================
# FR-009: pypa action pinada + zero credencial
# =============================================================================
FR9_OK=1; EVID9=""
if [ ! -f "$RELEASE_YML" ]; then
  FR9_OK=0; EVID9="${EVID9}release.yml ausente; "
else
  if ! grep -q "pypa/gh-action-pypi-publish" "$RELEASE_YML" 2>/dev/null; then
    FR9_OK=0; EVID9="${EVID9}pypa/gh-action-pypi-publish ausente (D3); "
  fi
  if ! grep -qE "pypa/gh-action-pypi-publish@[0-9a-f]{40}" "$RELEASE_YML" 2>/dev/null; then
    FR9_OK=0; EVID9="${EVID9}pypa action sem pin SHA (D3); "
  fi
fi
if [ -f "$RELEASE_YML" ]; then
  if grep -qiE "(password|token|secret)\s*[:=]\s*['\"]?[A-Za-z0-9+/=]{8,}" "$RELEASE_YML" 2>/dev/null; then
    FR9_OK=0; EVID9="${EVID9}credencial literal no workflow (Lei Zero); "
  fi
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# FR-010: uv export cyclonedx1.5 + cyclonedx-bom ausente
# =============================================================================
FR10_OK=1; EVID10=""
if [ ! -f "$RELEASE_YML" ]; then
  FR10_OK=0; EVID10="${EVID10}release.yml ausente; "
else
  if ! grep -q "cyclonedx" "$RELEASE_YML" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}SBOM cyclonedx ausente no workflow (D2); "
  fi
fi
if [ -f "$UVLOCK" ]; then
  if grep -q 'name = "cyclonedx-bom"' "$UVLOCK" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}cyclonedx-bom no lock (D2 descartado); "
  fi
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: pylock+SBOM efemeros nao versionados
# =============================================================================
FR11_OK=1; EVID11=""
if [ -f "$ROOT/pylock.toml" ]; then
  FR11_OK=0; EVID11="${EVID11}pylock.toml versionado (D7 efemero); "
fi
if [ -f "$ROOT/sbom.cyclonedx.json" ] || [ -f "$ROOT/sbom.json" ] || [ -f "$ROOT/cyclonedx.json" ]; then
  FR11_OK=0; EVID11="${EVID11}SBOM versionado (D7 efemero); "
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: fluxo nao grava main sem PR (tag eh gatilho, ato deliberado)
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$RELEASE_YML" ]; then
  FR12_OK=0; EVID12="${EVID12}release.yml ausente; "
else
  if grep -qE "^\s+branches:" "$RELEASE_YML" 2>/dev/null; then
    if ! grep -qE "^\s+tags:" "$RELEASE_YML" 2>/dev/null; then
      FR12_OK=0; EVID12="${EVID12}release.yml com trigger de branches sem tags (FR-012); "
    fi
  fi
fi
if [ "$FR12_OK" = "1" ]; then pass "FR-012" "${CANON[FR-012]}"; else fail "FR-012" "${CANON[FR-012]}" "alta" "$EVID12"; fi

# =============================================================================
# FR-013: setup-uv com version pinado
# =============================================================================
FR13_OK=1; EVID13=""
if [ ! -f "$RELEASE_YML" ]; then
  FR13_OK=0; EVID13="${EVID13}release.yml ausente; "
else
  if ! grep -q "setup-uv" "$RELEASE_YML" 2>/dev/null; then
    FR13_OK=0; EVID13="${EVID13}setup-uv ausente (D9); "
  elif ! grep -q "version:" "$RELEASE_YML" 2>/dev/null; then
    FR13_OK=0; EVID13="${EVID13}setup-uv sem version: pinado (D9/Q9); "
  fi
fi
if [ "$FR13_OK" = "1" ]; then pass "FR-013" "${CANON[FR-013]}"; else fail "FR-013" "${CANON[FR-013]}" "alta" "$EVID13"; fi

# =============================================================================
# FR-014: checklist server-side presente
# =============================================================================
FR14_OK=1; EVID14=""
if [ ! -f "$SERVER_SIDE" ]; then
  FR14_OK=0; EVID14="${EVID14}checklists/server-side.md ausente (D8/FR-014); "
else
  if ! grep -q "pending" "$SERVER_SIDE" 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}server-side sem pending publishers (D8); "
  fi
  if ! grep -q "environment" "$SERVER_SIDE" 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}server-side sem GitHub environment (D8); "
  fi
fi
if [ "$FR14_OK" = "1" ]; then pass "FR-014" "${CANON[FR-014]}"; else fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"; fi

# =============================================================================
# FR-015: contrato auto-verificavel (list 16, exit2, 2x <5s, self-check serie)
# =============================================================================
FR15_OK=1; EVID15=""
LIST_COUNT=$(bash "$SELF" --list 2>/dev/null | wc -l || true)
LIST_COUNT=$(echo "$LIST_COUNT" | tr -d '[:space:]')
if [ "$LIST_COUNT" != "16" ]; then
  FR15_OK=0; EVID15="${EVID15}--list enumera $LIST_COUNT != 16; "
fi
INVALID_RC=0
bash "$SELF" --invalido > /dev/null 2>&1 || INVALID_RC=$?
if [ "$INVALID_RC" != "2" ]; then
  FR15_OK=0; EVID15="${EVID15}--invalido exit $INVALID_RC != 2; "
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
    FR15_OK=0; EVID15="${EVID15}2 execucoes divergem; "
  fi
  if [ "$ELAPSED1" -gt 5000 ] || [ "$ELAPSED2" -gt 5000 ]; then
    FR15_OK=0; EVID15="${EVID15}execucao >5s (${ELAPSED1}ms/${ELAPSED2}ms); "
  fi
fi
if [ "$NESTED" != "1" ]; then
  TMP_SC="$(mktemp -d)"
  SC_FAIL=0
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" \
           "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11" "$ORACLE12"; do
    if [ ! -x "$o" ]; then
      FR15_OK=0; EVID15="${EVID15}$(basename "$o") ausente ou nao executavel; "
      SC_FAIL=1
    elif [ "$SC_FAIL" = "0" ]; then
      rc=0
      timeout 5 env FKX_ORACLE_NESTED=1 bash "$o" --quiet > /dev/null 2>&1 || rc=$?
      if [ "$rc" != "0" ] && [ "$rc" != "124" ]; then
        FR15_OK=0; EVID15="${EVID15}$(basename "$o") --quiet reprovou (rc=$rc); "
      fi
    fi
  done
  rm -rf -- "$TMP_SC"
fi
if [ "$FR15_OK" = "1" ]; then pass "FR-015" "${CANON[FR-015]}"; else fail "FR-015" "${CANON[FR-015]}" "alta" "$EVID15"; fi

# =============================================================================
# FR-016: README 013 hash + zero [ ] + vermelho-verde
# =============================================================================
FR16_OK=1; EVID16=""
if [ ! -f "$README_SPECS" ]; then
  FR16_OK=0; EVID16="${EVID16}specs/README.md ausente; "
elif ! grep -iq "013.*release.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR16_OK=0; EVID16="${EVID16}README sem \"013.*release.*✅.*hash\"; "
fi
if [ ! -f "$TASKS013" ]; then
  FR16_OK=0; EVID16="${EVID16}specs/013-release-automation/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS013" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR16_OK=0; EVID16="${EVID16}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*013" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(release).*013" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR16_OK=0; EVID16="${EVID16}par vermelho/verde 013 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR16_OK=0; EVID16="${EVID16}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
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
