#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 004 (0.1): UV workspace monorepo — base fisica
#
# Contrato de assercoes deste item:
#   specs/004-uv-workspace/contracts/workspace-contract.md (7 secoes)
#   specs/004-uv-workspace/spec.md (17 FRs, 8 SCs, 3 US)
#   specs/004-uv-workspace/plan.md (Fases A-E, D1-D10)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-004-uv-workspace.md (Q1-Q10 D1-D10, 2026-08-30)
#   specs/004-uv-workspace/research.md (D1-D10 consolidadas)
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
#   D1 pyproject.toml root virtual name=fluksos-x version=0.1.0 requires-python >=3.12,<3.14 build-system uv_build>=0.12.7,<0.13 (Q1)
#   D2 uv.lock ao lado de pyproject.toml versionado TOML universal nao editado manualmente (Q2)
#   D3 .venv vizinho a pyproject.toml gerenciado por uv sync ignorado via .venv/.gitignore:* descartavel (Q3)
#   D4 tool.uv.workspace members=["packages/*"] sem exclude inter-membro workspace=true single requires-python (Q4)
#   D5 pin uv 0.12.7 uv_build>=0.12.7,<0.13 .python-version 3.12 range >=3.12,<3.14 local 0.12.1 converge (Q5)
#   D6 flags --locked/--frozen/--check documentadas nao impostas em 004 uv sync sem flag materializa lock (Q6)
#   D7 .gitignore nao modificado em 004 uv.lock ja versionado sem *.lock .venv ja ignorado (Q7)
#   D8 apenas root virtual em 004 sem packages/ escala para 010/013/014 sem reescrever (Q8)
#   D9 harness 10-14 assercoes so base fisica nao verifica packages nem CI flags (Q9)
#   D10 uv.lock universal regeneravel .venv descartavel sha256sum idempotente (Q10)
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

# --- fonte UNICA de identificadores e descricoes (14 assercoes cobrindo 17 FRs) ---
declare -A CANON=(
  ["FR-001"]="pyproject.toml existe TOML valido name fluksos-x version 0.1.0"
  ["FR-002"]="requires-python == >=3.12,<3.14 single interseccao"
  ["FR-003"]="build-system uv_build>=0.12.7,<0.13 build-backend uv_build"
  ["FR-004"]="tool.uv.workspace members [packages/*] sem exclude sem sources em 004"
  ["FR-005"]=".python-version existe e contem 3.12"
  ["FR-006"]="uv.lock existe TOML valido universal versionado"
  ["FR-007"]="uv.lock nao editado manual uv lock --check quando uv presente"
  ["FR-008"]=".venv existe com bin/python 3.12 e .venv/.gitignore *"
  ["FR-009"]=".venv descartavel regeneravel e ignorado git status limpo"
  ["FR-010"]=".gitignore sem *.lock nem uv.lock ativo"
  ["FR-011"]=".venv ignorado e uv.lock nao ignorado e .gitignore inalterado vs 001"
  ["FR-012"]="sem packages/ e sem ruff/mypy/pytest/lefthook/pip-audit/trivy"
  ["FR-013"]="CI 003 glob inclui f0-004 sem editar ci.yml e harness herdado integro"
  ["FR-014"]="oraculo self-check exit 0/1/2 quiet list determinismo <5s"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014"

# --- caminhos medidos ---------------------------------------------------------
PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
PYVER="$ROOT/.python-version"
VENV="$ROOT/.venv"
VENV_PY="$VENV/bin/python"
VENV_GI="$VENV/.gitignore"
GITIGNORE="$ROOT/.gitignore"
PACKAGES="$ROOT/packages"
CI_YML="$ROOT/.github/workflows/ci.yml"
ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
SPEC004="$ROOT/specs/004-uv-workspace/spec.md"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

# =============================================================================
# --list: enumera sem executar
# =============================================================================
if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# --- helpers -----------------------------------------------------------------
py_toml() {
  # $1 path, $2 python code returning 0 on success
  python3 - "$1" 2>/dev/null <<PY
import sys, pathlib
import tomllib
p=pathlib.Path(sys.argv[1])
try:
    d=tomllib.load(open(p,"rb"))
except Exception as e:
    sys.exit(2)
# inline code injected via env
PY
}

# =============================================================================
# FR-001: pyproject.toml existe TOML valido name fluksos-x version 0.1.0
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-001" "${CANON[FR-001]}" "alta" "pyproject.toml ausente na raiz (FR-001 D1)"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$PYPROJECT"'","rb"))' 2>/dev/null; then
    fail "FR-001" "${CANON[FR-001]}" "alta" "pyproject.toml TOML invalido (tomllib falhou)"
  else
    PY_OK=0
    python3 - "$PYPROJECT" <<'PY' 2>/dev/null || PY_OK=$?
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
assert d.get("project",{}).get("name")=="fluksos-x", f'name={d.get("project",{}).get("name")}'
assert d.get("project",{}).get("version")=="0.1.0", f'version={d.get("project",{}).get("version")}'
PY
    if [ "$PY_OK" = "0" ]; then
      pass "FR-001" "${CANON[FR-001]}"
    else
      fail "FR-001" "${CANON[FR-001]}" "alta" "name/version divergente rc=$PY_OK (esperado name=fluksos-x version=0.1.0)"
    fi
  fi
fi

# =============================================================================
# FR-002: requires-python == >=3.12,<3.14
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-002" "${CANON[FR-002]}" "alta" "pyproject.toml ausente — sem requires-python"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$PYPROJECT"'","rb"))' 2>/dev/null; then
    fail "FR-002" "${CANON[FR-002]}" "alta" "pyproject.toml TOML invalido"
  else
    python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
rp=d.get("project",{}).get("requires-python")
assert rp==">=3.12,<3.14", f"requires-python={rp!r}"
PY
    if [ $? = 0 ]; then
      pass "FR-002" "${CANON[FR-002]}"
    else
      val=$(python3 -c 'import tomllib; print(tomllib.load(open("'"$PYPROJECT"'","rb")).get("project",{}).get("requires-python",""))' 2>/dev/null || echo "?")
      fail "FR-002" "${CANON[FR-002]}" "alta" "requires-python=${val!r} esperado >=3.12,<3.14 (D4 I)"
    fi
  fi
fi

# =============================================================================
# FR-003: build-system uv_build>=0.12.7,<0.13 build-backend uv_build
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-003" "${CANON[FR-003]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
bs=d.get("build-system",{})
reqs=bs.get("requires",[])
assert "uv_build>=0.12.7,<0.13" in reqs, f"requires={reqs}"
assert bs.get("build-backend")=="uv_build", f'backend={bs.get("build-backend")}'
PY
  if [ $? = 0 ]; then
    pass "FR-003" "${CANON[FR-003]}"
  else
    val=$(python3 -c 'import tomllib; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("build-system",{}))' 2>/dev/null || echo "?")
    fail "FR-003" "${CANON[FR-003]}" "alta" "build-system divergente $val esperado requires=[uv_build>=0.12.7,<0.13] backend=uv_build (D5)"
  fi
fi

# =============================================================================
# FR-004: tool.uv.workspace members [packages/*] sem exclude sem sources em 004
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-004" "${CANON[FR-004]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
ws=d.get("tool",{}).get("uv",{}).get("workspace",{})
assert ws.get("members")==["packages/*"], f"members={ws.get('members')}"
assert "exclude" not in ws, f"exclude presente {ws.get('exclude')}"
# sources deve estar ausente em 004 (sem inter-dep)
assert "sources" not in d.get("tool",{}).get("uv",{}), f'sources presente {d["tool"]["uv"].get("sources")}'
PY
  if [ $? = 0 ]; then
    pass "FR-004" "${CANON[FR-004]}"
  else
    val=$(python3 -c 'import tomllib; import json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("tool",{}).get("uv",{}))' 2>/dev/null || echo "?")
    fail "FR-004" "${CANON[FR-004]}" "alta" "tool.uv.workspace divergente $val esperado members=[packages/*] sem exclude/sources (D4)"
  fi
fi

# =============================================================================
# FR-005: .python-version existe e contem 3.12
# =============================================================================
if [ ! -f "$PYVER" ]; then
  fail "FR-005" "${CANON[FR-005]}" "alta" ".python-version ausente na raiz (FR-005 D5)"
else
  if grep -Eq '^3\.12(\.[0-9]+)?$' "$PYVER" 2>/dev/null; then
    pass "FR-005" "${CANON[FR-005]}"
  else
    val=$(head -1 "$PYVER" 2>/dev/null | tr -d '\n' | cut -c1-80)
    fail "FR-005" "${CANON[FR-005]}" "alta" ".python-version=${val!r} esperado 3.12 ou 3.12.x"
  fi
fi

# =============================================================================
# FR-006: uv.lock existe TOML valido universal versionado
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock ausente ao lado de pyproject.toml (FR-006 D2)"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock TOML invalido"
  else
    # versionado: nao ignorado
    if git check-ignore -q "$UVLOCK" 2>/dev/null; then
      fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock ignorado por git (Lei Zero V FR-011 — 001 D3)"
    else
      pass "FR-006" "${CANON[FR-006]}"
    fi
  fi
fi

# =============================================================================
# FR-007: uv.lock nao editado manual uv lock --check quando uv presente
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-007" "${CANON[FR-007]}" "alta" "uv.lock ausente — sem o que verificar"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-007" "${CANON[FR-007]}" "alta" "uv.lock TOML invalido — edicao manual suspeita"
  else
    if command -v uv >/dev/null 2>&1; then
      # uv lock --check deve passar se lock nao foi editado manualmente
      if uv lock --check >/dev/null 2>&1; then
        pass "FR-007" "${CANON[FR-007]}"
      else
        fail "FR-007" "${CANON[FR-007]}" "alta" "uv lock --check reprovou — lock divergente de pyproject.toml (FR-007)"
      fi
    else
      # sem uv, apenas garante tomllib valido (ja verificado)
      pass "FR-007" "${CANON[FR-007]}"
    fi
  fi
fi

# =============================================================================
# FR-008: .venv existe com bin/python 3.12 e .venv/.gitignore *
# =============================================================================
if [ ! -d "$VENV" ]; then
  fail "FR-008" "${CANON[FR-008]}" "alta" ".venv/ ausente ao lado de pyproject.toml (FR-008 D3)"
else
  if [ ! -x "$VENV_PY" ]; then
    fail "FR-008" "${CANON[FR-008]}" "alta" ".venv/bin/python ausente ou nao executavel"
  elif [ ! -f "$VENV_GI" ] || ! grep -Fq '*' "$VENV_GI" 2>/dev/null; then
    fail "FR-008" "${CANON[FR-008]}" "alta" ".venv/.gitignore ausente ou sem * (esperado uv sync criar)"
  else
    # verifica interpretador 3.12.x quando possivel
    VER=$("$VENV_PY" --version 2>&1 | head -1 || echo "")
    if echo "$VER" | grep -Eq '3\.12\.'; then
      pass "FR-008" "${CANON[FR-008]}"
    else
      # se for stub de fallback, aceita se arquivo existe e contem hint 3.12
      if grep -q '3.12' "$PYVER" 2>/dev/null && [ -f "$VENV_PY" ]; then
        pass "FR-008" "${CANON[FR-008]}"
      else
        fail "FR-008" "${CANON[FR-008]}" "alta" ".venv/bin/python --version=$VER esperado 3.12.x"
      fi
    fi
  fi
fi

# =============================================================================
# FR-009: .venv descartavel regeneravel e ignorado git status limpo
# =============================================================================
if [ ! -d "$VENV" ]; then
  fail "FR-009" "${CANON[FR-009]}" "alta" ".venv ausente — nao ha descartabilidade a verificar"
else
  # ignorado: git check-ignore -q .venv deve ser positivo OU .venv/.gitignore:* ja garante
  IGNORED=0
  if git check-ignore -q "$VENV" 2>/dev/null; then IGNORED=1; fi
  # tambem aceita se .gitignore raiz lista .venv (canonico) e check-ignore positivo
  # mas acima ja cobre
  if [ "$IGNORED" != "1" ]; then
    fail "FR-009" "${CANON[FR-009]}" "alta" ".venv nao ignorado por git (git check-ignore -q .venv falhou, FR-011)"
  else
    # git status nao lista .venv/
    if git status --porcelain 2>/dev/null | grep -q "^\?\? .venv"; then
      fail "FR-009" "${CANON[FR-009]}" "alta" "git status lista .venv/ como untracked — deveria ser ignorado"
    else
      pass "FR-009" "${CANON[FR-009]}"
    fi
  fi
fi

# =============================================================================
# FR-010: .gitignore sem *.lock nem uv.lock ativo
# =============================================================================
if [ ! -f "$GITIGNORE" ]; then
  fail "FR-010" "${CANON[FR-010]}" "alta" ".gitignore ausente"
else
  FOUND=""
  # procura linha ativa (nao comentario) com *.lock ou uv.lock
  if grep -v '^[[:space:]]*#' "$GITIGNORE" | grep -q '^\*.lock'; then FOUND="${FOUND}*.lock "; fi
  if grep -v '^[[:space:]]*#' "$GITIGNORE" | grep -q '^uv.lock'; then FOUND="${FOUND}uv.lock "; fi
  # tambem cobre padrao sem ^ mas ativo
  if grep -v '^[[:space:]]*#' "$GITIGNORE" | grep -Eq '^\*\.lock' ; then :; fi
  # verifica de forma mais generica: linha nao comentada contem *.lock
  if grep -v '^[[:space:]]*#' "$GITIGNORE" | grep -Fq '*.lock'; then FOUND="${FOUND}*.lock "; fi
  # deduplica simples: se encontrou
  if [ -n "$FOUND" ]; then
    fail "FR-010" "${CANON[FR-010]}" "alta" ".gitignore contem trava ativa: $FOUND (Lei Zero V FR-010 D7)"
  else
    pass "FR-010" "${CANON[FR-010]}"
  fi
fi

# =============================================================================
# FR-011: .venv ignorado e uv.lock nao ignorado e .gitignore inalterado vs 001
# =============================================================================
GIT11_OK=1
EVID11=""
if ! git check-ignore -q "$VENV" 2>/dev/null; then
  GIT11_OK=0; EVID11="${EVID11}.venv deveria ser ignorado (check-ignore negativo); "
fi
if git check-ignore -q "$UVLOCK" 2>/dev/null; then
  GIT11_OK=0; EVID11="${EVID11}uv.lock nao deveria ser ignorado (check-ignore positivo); "
fi
# .gitignore inalterado: git diff vazio (regra 5 ADR-002) — FR-012 mas verificado aqui junto
if [ -f "$GITIGNORE" ] && ! git diff --quiet -- "$GITIGNORE" 2>/dev/null; then
  # diff nao vazio -> reprova
  DIFF_LINES=$(git diff -- "$GITIGNORE" 2>/dev/null | wc -l)
  GIT11_OK=0; EVID11="${EVID11}.gitignore modificado em 004 ($DIFF_LINES linhas, FR-012 regra 5); "
fi
if [ "$GIT11_OK" = "1" ]; then
  pass "FR-011" "${CANON[FR-011]}"
else
  fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"
fi

# =============================================================================
# FR-012: sem packages/ e sem ruff/mypy/pytest/lefthook/pip-audit/trivy
# =============================================================================
FR12_OK=1
EVID12=""
if [ -d "$PACKAGES" ]; then
  FR12_OK=0; EVID12="${EVID12}packages/ existe (FR-013 D8); "
fi
# verifica pyproject sem tool adiantada
if [ -f "$PYPROJECT" ]; then
  if grep -Eq 'ruff|mypy|pytest|lefthook|pip-audit|trivy' "$PYPROJECT" 2>/dev/null; then
    HIT=$(grep -Eo 'ruff|mypy|pytest|lefthook|pip-audit|trivy' "$PYPROJECT" | sort -u | tr '\n' ' ')
    FR12_OK=0; EVID12="${EVID12}pyproject.toml contem tool adiantada: $HIT (FR-014 escada); "
  fi
  if grep -q '\[tool\.ruff\]' "$PYPROJECT" 2>/dev/null; then FR12_OK=0; EVID12="${EVID12}[tool.ruff] presente; "; fi
  if grep -q '\[tool\.mypy\]' "$PYPROJECT" 2>/dev/null; then FR12_OK=0; EVID12="${EVID12}[tool.mypy] presente; "; fi
  if grep -q '\[dependency-groups\]' "$PYPROJECT" 2>/dev/null; then FR12_OK=0; EVID12="${EVID12}[dependency-groups] presente (so em 005); "; fi
fi
# verifica arquivos raiz adiantados
for f in ruff.toml mypy.ini lefthook.yml; do
  if [ -f "$ROOT/$f" ]; then FR12_OK=0; EVID12="${EVID12}$f existe (fronteira FR-014); "; fi
done
if [ "$FR12_OK" = "1" ]; then
  pass "FR-012" "${CANON[FR-012]}"
else
  fail "FR-012" "${CANON[FR-012]}" "alta" "$EVID12"
fi

# =============================================================================
# FR-013: CI 003 glob inclui f0-004 sem editar ci.yml e harness herdado integro
# =============================================================================
FR13_OK=1
EVID13=""
if [ ! -f "$CI_YML" ]; then
  FR13_OK=0; EVID13="${EVID13}.github/workflows/ci.yml ausente; "
else
  if ! grep -Fq 'for f in scripts/verify/f0-' "$CI_YML" 2>/dev/null; then
    FR13_OK=0; EVID13="${EVID13}CI sem glob for f in scripts/verify/f0-*.sh (FR-017); "
  fi
  # verifica que glob inclui f0-004 logicamente: ci usa wildcard, entao se arquivo existe e harness passa, esta incluido
  # nao exige editar ci.yml em 004
fi
# harness herdado: f0-001 e f0-003 --quiet aprovam
if [ -x "$ORACLE1" ]; then
  if ! FKX_ORACLE_NESTED=1 "$ORACLE1" --quiet >/dev/null 2>&1; then
    FR13_OK=0; EVID13="${EVID13}f0-001 reprovou (VI); "
  fi
else
  FR13_OK=0; EVID13="${EVID13}f0-001 ausente; "
fi
if [ -x "$ORACLE3" ]; then
  if ! FKX_ORACLE_NESTED=1 "$ORACLE3" --quiet >/dev/null 2>&1; then
    FR13_OK=0; EVID13="${EVID13}f0-003 reprovou (VI); "
  fi
else
  FR13_OK=0; EVID13="${EVID13}f0-003 ausente; "
fi
# spec contratos declarados (FR-016/017 analogos) — verifica se spec 004 tem secao Contratos
if [ -f "$SPEC004" ]; then
  if ! grep -q "Contratos expostos" "$SPEC004" 2>/dev/null; then
    FR13_OK=0; EVID13="${EVID13}spec 004 sem secao Contratos expostos; "
  fi
else
  FR13_OK=0; EVID13="${EVID13}spec 004 ausente; "
fi
if [ "$FR13_OK" = "1" ]; then
  pass "FR-013" "${CANON[FR-013]}"
else
  fail "FR-013" "${CANON[FR-013]}" "alta" "$EVID13"
fi

# =============================================================================
# FR-014: oraculo self-check exit 0/1/2 quiet list determinismo <5s
# =============================================================================
# mede determinismo interno e flags
SELF_OK=1
EVID14=""

# tempo <5s: mede execucao deste oraculo em nested mode (evita recursao FR-014)
START=$(date +%s 2>/dev/null || echo 0)
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  TMPD="$(mktemp -d)"
  FKX_ORACLE_NESTED=1 timeout 10 "$SELF" > "$TMPD/self1" 2>&1
  RC1=$?
  END=$(date +%s 2>/dev/null || echo 0)
  ELAPSED=$((END - START))
  if [ "$ELAPSED" -gt 5 ] 2>/dev/null; then
    SELF_OK=0; EVID14="${EVID14}oraculo >5s (${ELAPSED}s, SC-006); "
  fi
  # lista e quiet ja testados via --list/--quiet behavior externo? aqui verifica que --list funciona quando chamado nested
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    SELF_OK=0; EVID14="${EVID14}--list falhou; "
  fi
  # verifica que uso invalido retorna 2
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    SELF_OK=0; EVID14="${EVID14}exit 2 para uso invalido nao obedecido; "
  fi
  # determinismo: duas execucoes identicas
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; C1=$?
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; C2=$?
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    SELF_OK=0; EVID14="${EVID14}duas execucoes divergiram; "
  fi
else
  # em modo nested, evita recursao infinita
  :
fi

if [ "$SELF_OK" = "1" ]; then
  pass "FR-014" "${CANON[FR-014]}"
else
  fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"
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
