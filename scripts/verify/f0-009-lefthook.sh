#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 009 (0.5): Lefthook 2.1.12 pre-commit
#
# Contrato de assercoes deste item:
#   specs/009-lefthook/spec.md (16 FRs, 6 SCs, 3 US)
#   specs/009-lefthook/plan.md (Fases A-E, D1-D10, fronteira ADR-017)
#   specs/009-lefthook/contracts/oracle-cli.md (mapa identidade 16 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-009-lefthook.md (Q1-Q10 D1-D10, 2026-09-04)
#   specs/009-lefthook/research.md (5 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento, protegem invariante):
#     FR-008/009/010/011/012/013/014 (FR-008 e documentacao por natureza)
#   Comportamento (carregam o vermelho 9/16):
#     FR-001..007/015/016
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ pytest 005 + ruff 006 + mypy 007
#      + pip-audit 008 + lefthook 009 via uv run). Nenhuma outra dependencia.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#      NUNCA executa jobs do hook (observa via validate/dump/check-install).
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-09-04:
#   D1 lefthook==2.1.12 (CLARIFY; plano dizia 2.1.11, desvio registrado) (Q1)
#   D2 wrapper PyPI via uv add --dev, hash uv.lock, min_version declarativo (Q2)
#   D3 binario oficial sha256 435aff51… + --help executado em /tmp (Q3)
#   D4 lefthook.yml raiz YAML unico; remotes/self-update proibidos (Q4)
#   D5 check-only: sem --fix/stage_fixed (Q5, CLARIFY pelo DNA I+VI+X)
#   D6 fail-fast uv run; pre-push espelha harness (Q6)
#   D7 CI intocado, glob inclui f0-009 (Q7, ADR-009)
#   D8 .git/hooks fora do indice; lefthook-local.yml inexistente (Q8)
#   D9 validate/dump/check-install assertaveis; jobs nunca executados (Q10)
#   D10 fronteira ao PLAN + ADR-018 previa (Q-fronteira, ADR-017)
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
  ["FR-001"]="pin 2.1.12: min_version + dev + uv.lock concordam"
  ["FR-002"]="lefthook.yml raiz YAML unico sem remotes/self-update"
  ["FR-003"]="pre-commit fail-fast uv run ordem sem cor forcada"
  ["FR-004"]="trivy fs so pre-push + skip sem Docker"
  ["FR-005"]="pre-push contem harness f0-*.sh"
  ["FR-006"]="somente-leitura sem --fix/stage_fixed"
  ["FR-007"]="validate + check-install saem 0"
  ["FR-008"]="escape LEFTHOOK=0 documentado"
  ["FR-009"]="CI intocado glob inclui f0-009"
  ["FR-010"]="sem escrita fora do repo nada global"
  ["FR-011"]="cadencia: f0-audit-005-008 presente + cabecalhos"
  ["FR-012"]="fronteira: PLAN declara + ADR-018 existe"
  ["FR-013"]="contrato: list 16 exit2 2x <5s"
  ["FR-014"]="manifest 9/9 + self-check f0-001..008"
  ["FR-015"]="specs/README.md 009 lefthook hash"
  ["FR-016"]="CONVERGE zero [ ] + vermelho-antes-do-verde"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014 FR-015 FR-016"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
GITIGNORE="$ROOT/.gitignore"
CI_YML="$ROOT/.github/workflows/ci.yml"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
HOOKYML="$ROOT/lefthook.yml"
TASKS009="$ROOT/specs/009-lefthook/tasks.md"
SPEC009="$ROOT/specs/009-lefthook/spec.md"
QUICK009="$ROOT/specs/009-lefthook/quickstart.md"
README_SPECS="$ROOT/specs/README.md"
AUDIT0508="$ROOT/docs/plan/audit/f0-audit-005-008.md"
DECISIONS="$ROOT/docs/plan/decisions.md"
PLAN009="$ROOT/specs/009-lefthook/plan.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"
ORACLE5="$SCRIPT_DIR/f0-005-pytest.sh"
ORACLE6="$SCRIPT_DIR/f0-006-ruff.sh"
ORACLE7="$SCRIPT_DIR/f0-007-mypy.sh"
ORACLE8="$SCRIPT_DIR/f0-008-pip-audit.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"
HAVE_LOCK=0
if [ -f "$UVLOCK" ] && grep -q 'name = "lefthook"' "$UVLOCK" 2>/dev/null; then HAVE_LOCK=1; fi

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: pin 2.1.12 (min_version + dev + uv.lock)
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$HOOKYML" ]; then
  FR1_OK=0; EVID1="${EVID1}lefthook.yml ausente; "
else
  if ! grep -Eq '^[ ]*min_version:[ ]*["'"'"']?2\.1\.12["'"'"']?' "$HOOKYML" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}min_version != 2.1.12 em lefthook.yml (D1); "
  fi
fi
if [ ! -f "$PYPROJECT" ]; then
  FR1_OK=0; EVID1="${EVID1}pyproject.toml ausente; "
elif ! python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); assert "lefthook==2.1.12" in d.get("dependency-groups",{}).get("dev",[])' "$PYPROJECT" 2>/dev/null; then
  FR1_OK=0; EVID1="${EVID1}[dependency-groups].dev sem lefthook==2.1.12 (D2); "
fi
if [ "$HAVE_LOCK" != "1" ]; then
  FR1_OK=0; EVID1="${EVID1}uv.lock sem name = \"lefthook\"; "
elif [ "$NESTED" != "1" ]; then
  if ! command -v uv >/dev/null 2>&1; then
    FR1_OK=0; EVID1="${EVID1}uv nao encontrado; "
  else
    VER=$(uv run lefthook version 2>&1 | head -1 || true)
    if ! echo "$VER" | grep -q "2\.1\.12" 2>/dev/null; then
      FR1_OK=0; EVID1="${EVID1}lefthook version divergente: $VER (esperado 2.1.12); "
    fi
  fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: lefthook.yml raiz YAML unico, sem remotes/self-update
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$HOOKYML" ]; then
  FR2_OK=0; EVID2="${EVID2}lefthook.yml ausente na raiz; "
else
  for alt in "$ROOT/lefthook.yaml" "$ROOT/.lefthook.yml" "$ROOT/.lefthook.yaml" "$ROOT/lefthook.toml" "$ROOT/lefthook.json" "$ROOT/.config/lefthook.yml"; do
    if [ -f "$alt" ]; then FR2_OK=0; EVID2="${EVID2}config alternativa existe: $alt (uma forma, Q4); "; fi
  done
  if grep -Eq '^[ ]*remotes:' "$HOOKYML" 2>/dev/null; then FR2_OK=0; EVID2="${EVID2}remotes: proibido (supply chain, D4); "; fi
  if grep -Eq 'self-update' "$HOOKYML" 2>/dev/null; then FR2_OK=0; EVID2="${EVID2}self-update proibido (D4); "; fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: pre-commit fail-fast via uv run, ordem, sem cor forcada
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$HOOKYML" ]; then
  FR3_OK=0; EVID3="${EVID3}lefthook.yml ausente; "
else
  L_RUFF=$(grep -n "uv run ruff check" "$HOOKYML" 2>/dev/null | head -1 | cut -d: -f1 || true)
  L_FMT=$(grep -n "uv run ruff format --check" "$HOOKYML" 2>/dev/null | head -1 | cut -d: -f1 || true)
  L_MYPY=$(grep -n "uv run mypy --strict" "$HOOKYML" 2>/dev/null | head -1 | cut -d: -f1 || true)
  L_PY=$(grep -n "uv run pytest" "$HOOKYML" 2>/dev/null | head -1 | cut -d: -f1 || true)
  L_PA=$(grep -n "uv run pip-audit" "$HOOKYML" 2>/dev/null | head -1 | cut -d: -f1 || true)
  if [ -z "$L_RUFF" ] || [ -z "$L_FMT" ] || [ -z "$L_MYPY" ] || [ -z "$L_PY" ] || [ -z "$L_PA" ]; then
    FR3_OK=0; EVID3="${EVID3}jobs ausentes (ruff=$L_RUFF fmt=$L_FMT mypy=$L_MYPY pytest=$L_PY pip-audit=$L_PA); "
  elif [ ! "$L_RUFF" -lt "$L_FMT" ] 2>/dev/null || [ ! "$L_FMT" -lt "$L_MYPY" ] 2>/dev/null || [ ! "$L_MYPY" -lt "$L_PY" ] 2>/dev/null || [ ! "$L_PY" -lt "$L_PA" ] 2>/dev/null; then
    FR3_OK=0; EVID3="${EVID3}ordem fail-fast quebrada ($L_RUFF<$L_FMT<$L_MYPY<$L_PY<$L_PA); "
  fi
  if grep -Eq 'CLICOLOR_FORCE|NO_COLOR=0|--color=always|--colors[ ]+on' "$HOOKYML" 2>/dev/null; then
    FR3_OK=0; EVID3="${EVID3}cor forcada no config (determinismo); "
  fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: trivy fs so no pre-push + skip sem Docker
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$HOOKYML" ]; then
  FR4_OK=0; EVID4="${EVID4}lefthook.yml ausente; "
else
  PRECOMMIT_SECT=$(awk '/^[ ]*pre-commit:/,/^[ ]*pre-push:/' "$HOOKYML" 2>/dev/null || true)
  if echo "$PRECOMMIT_SECT" | grep -q "trivy" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}trivy no pre-commit (deve ser so pre-push, D-CLARIFY); "
  fi
  if ! grep -q "trivy" "$HOOKYML" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}trivy ausente do config (deve estar no pre-push); "
  fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: pre-push contem harness f0-*.sh
# =============================================================================
if [ ! -f "$HOOKYML" ]; then
  fail "FR-005" "${CANON[FR-005]}" "alta" "lefthook.yml ausente; "
elif ! grep -Fq 'for f in scripts/verify/f0-' "$HOOKYML" 2>/dev/null; then
  fail "FR-005" "${CANON[FR-005]}" "alta" "pre-push sem harness f0-*.sh (FR-005)"
else
  pass "FR-005" "${CANON[FR-005]}"
fi

# =============================================================================
# FR-006: somente-leitura (sem --fix/stage_fixed)
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$HOOKYML" ]; then
  FR6_OK=0; EVID6="${EVID6}lefthook.yml ausente; "
else
  if grep -Eq 'ruff --fix|ruff check --fix|format --write|stage_fixed:[ ]*true' "$HOOKYML" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}escritor no hook (--fix/stage_fixed, FR-006 check-only); "
  fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: validate + check-install (observa, nunca executa jobs)
# =============================================================================
if [ "$NESTED" = "1" ]; then
  if [ "$HAVE_LOCK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "nested: lefthook ausente do lock"; fi
else
  if [ "$HAVE_LOCK" != "1" ]; then
    fail "FR-007" "${CANON[FR-007]}" "alta" "uv.lock sem name = \"lefthook\" (FR-007)"
  elif ! command -v uv >/dev/null 2>&1; then
    fail "FR-007" "${CANON[FR-007]}" "alta" "uv nao encontrado"
  else
    if ! uv run lefthook validate >/dev/null 2>&1; then
      fail "FR-007" "${CANON[FR-007]}" "alta" "lefthook validate reprovou"
    else
      if [ -f "$ROOT/.git/hooks/pre-commit" ] && grep -q "lefthook" "$ROOT/.git/hooks/pre-commit" 2>/dev/null; then
        if uv run lefthook check-install >/dev/null 2>&1; then
          pass "FR-007" "${CANON[FR-007]}"
        else
          fail "FR-007" "${CANON[FR-007]}" "alta" "check-install reprovou com ganchos instalados"
        fi
      else
        skip "FR-007" "${CANON[FR-007]}" "ganchos nao instalados nesta maquina (setup local FR-007); validate OK"
      fi
    fi
  fi
fi

# =============================================================================
# FR-008: escape LEFTHOOK=0 documentado
# =============================================================================
if [ ! -f "$HOOKYML" ] && [ ! -f "$QUICK009" ]; then
  fail "FR-008" "${CANON[FR-008]}" "alta" "lefthook.yml e quickstart ausentes; "
elif grep -rq "LEFTHOOK=0" "$HOOKYML" "$QUICK009" 2>/dev/null; then
  pass "FR-008" "${CANON[FR-008]}"
else
  fail "FR-008" "${CANON[FR-008]}" "alta" "LEFTHOOK=0 nao documentado (FR-008)"
fi

# =============================================================================
# FR-009: CI intocado, glob inclui f0-009 (guarda)
# =============================================================================
FR9_OK=1; EVID9=""
if [ ! -f "$CI_YML" ]; then
  FR9_OK=0; EVID9="${EVID9}.github/workflows/ci.yml ausente; "
else
  if ! grep -Fq 'for f in scripts/verify/f0-' "$CI_YML" 2>/dev/null; then
    FR9_OK=0; EVID9="${EVID9}CI sem glob f0-*.sh; "
  fi
  if grep -q "lefthook" "$ROOT/.github/workflows/ci.yml" 2>/dev/null || grep -rq "lefthook" "$ROOT/.github/" 2>/dev/null; then
    FR9_OK=0; EVID9="${EVID9}.github menciona lefthook (CI intocado, FR-009); "
  fi
  if [ ! -f "$SELF" ]; then FR9_OK=0; EVID9="${EVID9}f0-009 ausente; "; fi
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# FR-010: sem escrita fora do repo, nada global (guarda)
# =============================================================================
FR10_OK=1; EVID10=""
if [ -n "$(git config --local --get core.hooksPath 2>/dev/null || true)" ]; then
  FR10_OK=0; EVID10="${EVID10}core.hooksPath local definido (ganchos fora de .git/); "
fi
if [ -f "$HOOKYML" ]; then
  # caminho absoluto HOST (dois-pontos + espaco + barra); montagem container
  # ($PWD:/w, sem espaco) nao e escrita no host e nao casa aqui
  if grep -Eq '^[^#]*:[ ]+/[^ ]' "$HOOKYML" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}caminho absoluto no config (escrita fora do repo); "
  fi
  if grep -Eq '~' "$HOOKYML" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}~ (home) referenciado no config; "
  fi
fi
if [ "$FR10_OK" = "1" ]; then pass "FR-010" "${CANON[FR-010]}"; else fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"; fi

# =============================================================================
# FR-011: cadencia ADR-016 (guarda)
# =============================================================================
FR11_OK=1; EVID11=""
if [ ! -f "$AUDIT0508" ]; then
  FR11_OK=0; EVID11="${EVID11}docs/plan/audit/f0-audit-005-008.md ausente (ADR-016); "
else
  for h in "Veredito" "Achados" "Destino"; do
    if ! grep -q "$h" "$AUDIT0508" 2>/dev/null; then FR11_OK=0; EVID11="${EVID11}cabecalho $h ausente no relatorio; "; fi
  done
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: fronteira ADR-017 (guarda)
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$PLAN009" ] || ! grep -q "impacto de fronteira" "$PLAN009" 2>/dev/null; then
  FR12_OK=0; EVID12="${EVID12}plan.md sem declaracao de impacto de fronteira (ADR-017); "
fi
if [ ! -f "$DECISIONS" ] || ! grep -q "ADR-018" "$DECISIONS" 2>/dev/null; then
  FR12_OK=0; EVID12="${EVID12}ADR-018 ausente em decisions.md; "
fi
if [ "$FR12_OK" = "1" ]; then pass "FR-012" "${CANON[FR-012]}"; else fail "FR-012" "${CANON[FR-012]}" "alta" "$EVID12"; fi

# =============================================================================
# FR-013: contrato (list 16, exit 2, 2x byte-identico, <5s) (guarda)
# =============================================================================
FR13_OK=1; EVID13=""
if [ "$NESTED" != "1" ]; then
  if [ -n "${EPOCHSECONDS:-}" ]; then START13=$EPOCHSECONDS; else START13=$(date +%s 2>/dev/null || echo 0); fi
  TMPD="$(mktemp -d)"
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    FR13_OK=0; EVID13="${EVID13}--list falhou; "
  else
    LIST_COUNT=$(FKX_ORACLE_NESTED=1 "$SELF" --list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LIST_COUNT" != "16" ] 2>/dev/null; then
      FR13_OK=0; EVID13="${EVID13}--list contagem $LIST_COUNT != 16; "
    fi
  fi
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    FR13_OK=0; EVID13="${EVID13}exit 2 para uso invalido nao obedecido; "
  fi
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; C1=$?
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; C2=$?
  if [ -n "${EPOCHSECONDS:-}" ]; then END13=$EPOCHSECONDS; else END13=$(date +%s 2>/dev/null || echo 0); fi
  ELAPSED13=$((END13 - START13))
  if [ "$ELAPSED13" -gt 5 ] 2>/dev/null; then
    FR13_OK=0; EVID13="${EVID13}oraculo >5s (${ELAPSED13}s, SC-006); "
  fi
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR13_OK=0
    DIFF_SNIP=$(diff -u "$TMPD/r1" "$TMPD/r2" 2>/dev/null | head -5 | tr -d '\n' | cut -c1-80 || true)
    EVID13="${EVID13}duas execucoes divergiram; C1=$C1 C2=$C2 diff:${DIFF_SNIP}; "
  fi
fi
if [ "$FR13_OK" = "1" ]; then pass "FR-013" "${CANON[FR-013]}"; else fail "FR-013" "${CANON[FR-013]}" "alta" "$EVID13"; fi

# =============================================================================
# FR-014: manifest 9/9 + self-check f0-001..008 (guarda)
# =============================================================================
FR14_OK=1; EVID14=""
if [ ! -f "$MANIFEST" ]; then
  FR14_OK=0; EVID14="${EVID14}manifest.sha256 ausente; "
else
  LINES=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
  LINES=$(echo "$LINES" | tr -d '[:space:]')
  # piso >=9 (ADR-021): igualdade temporal proibida; espelho do piso >=5 da 005
  if [ -z "$LINES" ] || [ "$LINES" -lt 9 ] 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}manifest com $LINES linhas (esperado >=9); "
  elif ! sha256sum -c "$MANIFEST" >/dev/null 2>&1; then
    FR14_OK=0; EVID14="${EVID14}sha256sum -c reprovou; "
  fi
fi
if [ "$NESTED" != "1" ] && [ "$FR14_OK" = "1" ]; then
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FR14_OK=0; EVID14="${EVID14}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
fi
if [ "$FR14_OK" = "1" ]; then pass "FR-014" "${CANON[FR-014]}"; else fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"; fi

# =============================================================================
# FR-015: specs/README.md 009 lefthook hash
# =============================================================================
if [ ! -f "$README_SPECS" ]; then
  fail "FR-015" "${CANON[FR-015]}" "alta" "specs/README.md ausente"
elif ! grep -iq "009.*lefthook.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  fail "FR-015" "${CANON[FR-015]}" "alta" "README sem \"009.*lefthook.*✅.*hash\""
else
  pass "FR-015" "${CANON[FR-015]}"
fi

# =============================================================================
# FR-016: CONVERGE zero [ ] + vermelho-antes-do-verde
# =============================================================================
FR16_OK=1; EVID16=""
if [ ! -f "$TASKS009" ]; then
  FR16_OK=0; EVID16="${EVID16}specs/009-lefthook/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS009" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR16_OK=0; EVID16="${EVID16}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*009" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(harness).*009" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR16_OK=0; EVID16="${EVID16}par vermelho/verde 009 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
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
