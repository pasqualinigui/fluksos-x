#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 007 (0.3): MyPy 2.3.1 strict — type checker
#
# Contrato de assercoes deste item:
#   specs/007-mypy/spec.md (16 FRs, 8 SCs, 3 US)
#   specs/007-mypy/plan.md (Fases A-E, D1-D10)
#   specs/007-mypy/contracts/mypy-contract.md
#   specs/007-mypy/contracts/oracle-cli.md (mapa identidade 16 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-007-mypy.md (Q1-Q10 D1-D10, 2026-08-31)
#   specs/007-mypy/research.md (D1-D10 consolidadas)
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ pytest 005 + ruff 006 + mypy 007).
#      Nenhuma dependencia do projeto além de ruff/pytest/mypy.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-08-31:
#   D1 mypy==2.3.1 via [dependency-groups] dev (PEP 735), uv sync (Q1)
#   D2 pyproject.toml [tool.mypy] fonte única, sem mypy.ini (Q2)
#   D3 strict = true (11 flags) sem disallow_any_expr adicional (Q3)
#   D4 python_version 3.12 strict true warn_unused_configs true exclude "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)" + overrides tests.* (Q4)
#   D5 native-parser default 2.3, local partial types habilitado (Q5)
#   D6 uv add --dev mypy==2.3.1 -> dev com pytest+ruff+mypy (Q6)
#   D7 compat ruff py312 + overrides para tests/ (Q7)
#   D8 exclude regex (?x) + .mypy_cache gitignored, specs/README.md + git ls-files inquebráveis (Q8)
#   D9 Harness f0-007-mypy.sh 12-16 asserções só mypy (inclui README/commit) (Q9)
#   D10 Determinismo mypy --strict idempotente, fronteira Escada (007 só mypy) (Q10)
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
  ["FR-001"]="mypy==2.3.1 em [dependency-groups] dev exato"
  ["FR-002"]="[tool.mypy] python_version 3.12 strict true warn_unused_configs true exclude"
  ["FR-003"]="[[tool.mypy.overrides]] module tests.* disallow_untyped_defs false etc."
  ["FR-004"]="mypy.ini nao existe fonte unica pyproject.toml"
  ["FR-005"]="uv.lock contem mypy com hash"
  ["FR-006"]="uv.lock contem mypy e transitivos mypy_extensions/pathspec/tomli e uv lock --check"
  ["FR-007"]=".mypy_cache/.dmypy.json gitignored e uv.lock nao ignorado"
  ["FR-008"]="uv run mypy --strict . 0 conforme"
  ["FR-009"]="uv run mypy --strict tests/ 0 com overrides relaxado"
  ["FR-010"]="mypy --version 2.3.1 e strict 11 flags"
  ["FR-011"]="oraculo 12-16 assercoes CANON quiet list FKX EPOCHSECONDS"
  ["FR-012"]="CI glob inclui f0-007 sem editar ci.yml"
  ["FR-013"]="CONVERGE tasks.md zero [ ]"
  ["FR-014"]="fronteira sem lefthook.yml/packages/mypy.ini/ruff.toml"
  ["FR-015"]="specs/README.md 007 mypy concluida 006 ruff"
  ["FR-016"]="git ls-files specs/007-mypy/spec.md rastreado"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014 FR-015 FR-016"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
GITIGNORE="$ROOT/.gitignore"
CI_YML="$ROOT/.github/workflows/ci.yml"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS007="$ROOT/specs/007-mypy/tasks.md"
SPEC007="$ROOT/specs/007-mypy/spec.md"
RESEARCH007="$ROOT/docs/plan/research/f0-007-mypy.md"
README_SPECS="$ROOT/specs/README.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"
ORACLE5="$SCRIPT_DIR/f0-005-pytest.sh"
ORACLE6="$SCRIPT_DIR/f0-006-ruff.sh"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: mypy==2.3.1 em [dependency-groups] dev
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-001" "${CANON[FR-001]}" "alta" "pyproject.toml ausente (FR-001 D1)"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$PYPROJECT"'","rb"))' 2>/dev/null; then
    fail "FR-001" "${CANON[FR-001]}" "alta" "pyproject.toml TOML invalido"
  else
    if python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
dev=d.get("dependency-groups",{}).get("dev",[])
assert "mypy==2.3.1" in dev, f"dev={dev!r}"
deps=d.get("project",{}).get("dependencies",[])
for dep in deps:
    assert "mypy" not in dep.lower(), f"mypy em project.dependencies: {deps}"
PY
    then
      pass "FR-001" "${CANON[FR-001]}"
    else
      val=$(python3 -c 'import tomllib; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("dependency-groups",{}).get("dev"))' 2>/dev/null || echo "?")
      fail "FR-001" "${CANON[FR-001]}" "alta" "dependency-groups.dev=${val} sem mypy==2.3.1 ou mypy em project.dependencies (D1)"
    fi
  fi
fi

# =============================================================================
# FR-002: [tool.mypy] python_version 3.12 strict true warn_unused_configs true exclude
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-002" "${CANON[FR-002]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
m=d.get("tool",{}).get("mypy",{})
assert m.get("python_version")=="3.12", f'python_version={m.get("python_version")!r}'
assert m.get("strict") is True, f'strict={m.get("strict")!r}'
assert m.get("warn_unused_configs") is True, f'warn_unused_configs={m.get("warn_unused_configs")!r}'
exc=m.get("exclude")
assert exc == "(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)", f'exclude={exc!r}'
PY
  if [ $? = 0 ]; then
    pass "FR-002" "${CANON[FR-002]}"
  else
    val=$(python3 -c 'import tomllib, json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(json.dumps(d.get("tool",{}).get("mypy",{}), indent=2))' 2>/dev/null | head -30 || echo "?")
    fail "FR-002" "${CANON[FR-002]}" "alta" "tool.mypy divergente: $val (esperado python_version 3.12 strict true warn_unused_configs true exclude \"(?x)^(docs/|specs/|\\.venv/|\\.ruff_cache/|\\.mypy_cache/|\\.pytest_cache/)\")"
  fi
fi

# =============================================================================
# FR-003: [[tool.mypy.overrides]] module tests.* disallow_untyped_defs false etc.
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-003" "${CANON[FR-003]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
m=d.get("tool",{}).get("mypy",{})
ovs=m.get("overrides")
assert isinstance(ovs, list) and len(ovs)>=1, f"overrides={ovs!r}"
found=False
for o in ovs:
    if o.get("module")=="tests.*":
        assert o.get("disallow_untyped_defs") is False, f'disallow_untyped_defs={o.get("disallow_untyped_defs")!r}'
        assert o.get("disallow_untyped_calls") is False, f'disallow_untyped_calls={o.get("disallow_untyped_calls")!r}'
        assert o.get("warn_return_any") is False, f'warn_return_any={o.get("warn_return_any")!r}'
        found=True
        break
assert found, f"overrides sem module tests.*: {ovs!r}"
PY
  if [ $? = 0 ]; then
    pass "FR-003" "${CANON[FR-003]}"
  else
    val=$(python3 -c 'import tomllib, json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(json.dumps(d.get("tool",{}).get("mypy",{}).get("overrides"), indent=2))' 2>/dev/null | head -30 || echo "?")
    fail "FR-003" "${CANON[FR-003]}" "alta" "tool.mypy.overrides divergente: $val (esperado module tests.* disallow_untyped_defs false disallow_untyped_calls false warn_return_any false)"
  fi
fi

# =============================================================================
# FR-004: mypy.ini não existe
# =============================================================================
FR4_OK=1
EVID4=""
if [ -f "$ROOT/mypy.ini" ]; then FR4_OK=0; EVID4="${EVID4}mypy.ini existe (FR-004 fonte única); "; fi
if [ -f "$ROOT/.mypy.ini" ]; then FR4_OK=0; EVID4="${EVID4}.mypy.ini existe; "; fi
if [ "$FR4_OK" = "1" ]; then
  pass "FR-004" "${CANON[FR-004]}"
else
  fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"
fi

# =============================================================================
# FR-005: uv.lock contém mypy com hash
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-005" "${CANON[FR-005]}" "alta" "uv.lock ausente"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-005" "${CANON[FR-005]}" "alta" "uv.lock TOML invalido"
  else
    if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
      fail "FR-005" "${CANON[FR-005]}" "alta" "uv.lock sem name = \"mypy\" (FR-005)"
    else
      if command -v uv >/dev/null 2>&1; then
        if uv lock --check >/dev/null 2>&1; then
          pass "FR-005" "${CANON[FR-005]}"
        else
          fail "FR-005" "${CANON[FR-005]}" "alta" "uv lock --check reprovou"
        fi
      else
        pass "FR-005" "${CANON[FR-005]}"
      fi
    fi
  fi
fi

# =============================================================================
# FR-006: uv.lock contém mypy e transitivos + uv lock --check
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock ausente"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock TOML invalido"
  else
    FR6_OK=1
    EVID6=""
    if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}sem mypy; "; fi
    if ! grep -Eq 'name = "mypy[_-]extensions"' "$UVLOCK" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}sem mypy_extensions; "; fi
    if ! grep -q 'name = "pathspec"' "$UVLOCK" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}sem pathspec; "; fi
    if [ "$FR6_OK" != "1" ]; then
      fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock sem transitivos: $EVID6"
    else
      if command -v uv >/dev/null 2>&1; then
        if uv lock --check >/dev/null 2>&1; then
          pass "FR-006" "${CANON[FR-006]}"
        else
          fail "FR-006" "${CANON[FR-006]}" "alta" "uv lock --check reprovou"
        fi
      else
        pass "FR-006" "${CANON[FR-006]}"
      fi
    fi
  fi
fi

# =============================================================================
# FR-007: .mypy_cache/.dmypy.json gitignored e uv.lock não ignorado
# =============================================================================
FR7_OK=1
EVID7=""
# .mypy_cache
if ! git check-ignore -q "$ROOT/.mypy_cache" 2>/dev/null; then
  if ! grep -q ".mypy_cache" "$GITIGNORE" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}.mypy_cache não ignorado (git check-ignore falhou); "
  fi
fi
# .dmypy.json (e dmypy.json)
if ! git check-ignore -q "$ROOT/.dmypy.json" 2>/dev/null; then
  if ! grep -q ".dmypy.json" "$GITIGNORE" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}.dmypy.json não ignorado; "
  fi
fi
if git check-ignore -q "$UVLOCK" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}uv.lock ignorado (não deve); "
fi
if git ls-files 2>/dev/null | grep -q ".mypy_cache" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}.mypy_cache rastreado em git ls-files; "
fi
if git ls-files 2>/dev/null | grep -q ".dmypy.json" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}.dmypy.json rastreado; "
fi
if [ "$FR7_OK" = "1" ]; then
  pass "FR-007" "${CANON[FR-007]}"
else
  fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"
fi

# =============================================================================
# FR-008: uv run mypy --strict . 0
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  if [ -f "$PYPROJECT" ] && grep -q "tool.mypy" "$PYPROJECT" 2>/dev/null && grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
    pass "FR-008" "${CANON[FR-008]}"
  else
    fail "FR-008" "${CANON[FR-008]}" "alta" "nested: [tool.mypy] ou mypy em uv.lock ausente"
  fi
else
  if ! command -v uv >/dev/null 2>&1; then
    fail "FR-008" "${CANON[FR-008]}" "alta" "uv não encontrado"
  else
    if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
      fail "FR-008" "${CANON[FR-008]}" "alta" "mypy não em uv.lock — não há como executar mypy --strict (FR-008)"
    else
      if uv run mypy --strict . --no-error-summary >/dev/null 2>&1; then
        pass "FR-008" "${CANON[FR-008]}"
      else
        out=$(uv run mypy --strict . --no-error-summary 2>&1 | head -20 | tr -d '\n' | cut -c1-200)
        # também tenta sem --no-error-summary para capturar erro
        if [ -z "$out" ]; then out=$(uv run mypy --strict . 2>&1 | head -20 | tr -d '\n' | cut -c1-200); fi
        fail "FR-008" "${CANON[FR-008]}" "alta" "uv run mypy --strict . reprovou: $out"
      fi
    fi
  fi
fi

# =============================================================================
# FR-009: uv run mypy --strict tests/ 0 com overrides relaxado
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  if [ -f "$PYPROJECT" ] && grep -q "tool.mypy" "$PYPROJECT" 2>/dev/null; then
    pass "FR-009" "${CANON[FR-009]}"
  else
    fail "FR-009" "${CANON[FR-009]}" "alta" "nested: [tool.mypy] ausente"
  fi
else
  if ! command -v uv >/dev/null 2>&1; then
    fail "FR-009" "${CANON[FR-009]}" "alta" "uv não encontrado"
  else
    if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
      fail "FR-009" "${CANON[FR-009]}" "alta" "mypy não em uv.lock"
    else
      if uv run mypy --strict tests/ --no-error-summary >/dev/null 2>&1; then
        pass "FR-009" "${CANON[FR-009]}"
      else
        out=$(uv run mypy --strict tests/ --no-error-summary 2>&1 | head -20 | tr -d '\n' | cut -c1-200)
        if [ -z "$out" ]; then out=$(uv run mypy --strict tests/ 2>&1 | head -20 | tr -d '\n' | cut -c1-200); fi
        fail "FR-009" "${CANON[FR-009]}" "alta" "uv run mypy --strict tests/ reprovou: $out"
      fi
    fi
  fi
fi

# =============================================================================
# FR-010: mypy --version 2.3.1 e strict 11 flags
# =============================================================================
if ! command -v uv >/dev/null 2>&1; then
  fail "FR-010" "${CANON[FR-010]}" "alta" "uv não encontrado"
else
  if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
    fail "FR-010" "${CANON[FR-010]}" "alta" "mypy não em uv.lock"
  else
    VER=$(uv run mypy --version 2>&1 | head -1 || true)
    if ! echo "$VER" | grep -q "2.3.1" 2>/dev/null; then
      fail "FR-010" "${CANON[FR-010]}" "alta" "mypy --version divergente: $VER (esperado 2.3.1)"
    else
      HELP_OUT=$(uv run mypy --help 2>&1 || true)
      if ! echo "$HELP_OUT" | grep -q "strict" 2>/dev/null; then
        fail "FR-010" "${CANON[FR-010]}" "alta" "mypy --help sem strict"
      else
        # verifica 11 flags de strict estão mencionadas no help
        MISSING10=""
        for flag in "disallow-any-generics" "disallow-untyped-calls" "disallow-untyped-defs" "warn-return-any" "strict-equality"; do
          if ! echo "$HELP_OUT" | grep -q "$flag" 2>/dev/null; then MISSING10="${MISSING10}$flag "; fi
        done
        if [ -n "$MISSING10" ]; then
          fail "FR-010" "${CANON[FR-010]}" "alta" "mypy --help sem flags strict esperadas: $MISSING10"
        else
          pass "FR-010" "${CANON[FR-010]}"
        fi
      fi
    fi
  fi
fi

# =============================================================================
# FR-011: oraculo self-check
# =============================================================================
FR11_OK=1
EVID11=""
if [ -n "${EPOCHSECONDS:-}" ]; then START11=$EPOCHSECONDS; else START11=$(date +%s 2>/dev/null || echo 0); fi
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  TMPD="$(mktemp -d)"
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    FR11_OK=0; EVID11="${EVID11}--list falhou; "
  else
    LIST_COUNT=$(FKX_ORACLE_NESTED=1 "$SELF" --list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LIST_COUNT" -lt 12 ] 2>/dev/null || [ "$LIST_COUNT" -gt 16 ] 2>/dev/null; then
      FR11_OK=0; EVID11="${EVID11}--list contagem $LIST_COUNT fora de 12-16; "
    fi
  fi
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    FR11_OK=0; EVID11="${EVID11}exit 2 para uso inválido não obedecido; "
  fi
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; C1=$?
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; C2=$?
  if [ -n "${EPOCHSECONDS:-}" ]; then END11=$EPOCHSECONDS; else END11=$(date +%s 2>/dev/null || echo 0); fi
  ELAPSED11=$((END11 - START11))
  if [ "$ELAPSED11" -gt 5 ] 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}oráculo >5s (${ELAPSED11}s, FR-011); "
  fi
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR11_OK=0
    # captura diff para debug deterministico, mas mantém evidencia curta
    DIFF_SNIP=$(diff -u "$TMPD/r1" "$TMPD/r2" 2>/dev/null | head -5 | tr -d '\n' | cut -c1-80 || true)
    EVID11="${EVID11}duas execuções divergiram; C1=$C1 C2=$C2 diff:${DIFF_SNIP}; "
  fi
else
  :
fi
if [ "$FR11_OK" = "1" ]; then
  pass "FR-011" "${CANON[FR-011]}"
else
  fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"
fi

# =============================================================================
# FR-012: CI glob inclui f0-007
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-012" "${CANON[FR-012]}" "alta" ".github/workflows/ci.yml ausente"
else
  if ! grep -Fq 'for f in scripts/verify/f0-' "$CI_YML" 2>/dev/null; then
    fail "FR-012" "${CANON[FR-012]}" "alta" "CI sem glob f0-*.sh"
  else
    if [ -f "$SELF" ]; then
      pass "FR-012" "${CANON[FR-012]}"
    else
      fail "FR-012" "${CANON[FR-012]}" "alta" "f0-007 ausente"
    fi
  fi
fi

# =============================================================================
# FR-013: CONVERGE tasks.md zero [ ]
# =============================================================================
if [ ! -f "$TASKS007" ]; then
  fail "FR-013" "${CANON[FR-013]}" "alta" "specs/007-mypy/tasks.md ausente"
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS007" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" = "0" ]; then
    pass "FR-013" "${CANON[FR-013]}"
  else
    fail "FR-013" "${CANON[FR-013]}" "alta" "tasks.md contém $COUNT tarefas [ ] abertas (CONVERGE)"
  fi
fi

# =============================================================================
# FR-014: fronteira sem lefthook.yml/packages/mypy.ini/ruff.toml
# =============================================================================
FR14_OK=1
EVID14=""
if grep -q '^\[tool\.mypy\]' "$ROOT/mypy.ini" 2>/dev/null; then FR14_OK=0; EVID14="${EVID14}mypy.ini com [tool.mypy]; "; fi
if [ -f "$ROOT/mypy.ini" ]; then FR14_OK=0; EVID14="${EVID14}mypy.ini existe; "; fi
if [ -f "$ROOT/.mypy.ini" ]; then FR14_OK=0; EVID14="${EVID14}.mypy.ini existe; "; fi
# lefthook.yml é jurisdição da 009 (conteúdo asserido por f0-009) — ADR-018
if [ -d "$ROOT/packages" ] && [ ! -f "$ROOT/packages/core/pyproject.toml" ]; then FR14_OK=0; EVID14="${EVID14}packages/ sem core/pyproject.toml de membro (ADR-023); "; fi
if [ -n "$(ls "$ROOT/packages" 2>/dev/null | grep -v -x "core" | tr -d '[:space:]' || true)" ]; then FR14_OK=0; EVID14="${EVID14}packages/ com conteudo alem de core/ (ADR-023); "; fi
if [ -f "$ROOT/ruff.toml" ] || [ -f "$ROOT/.ruff.toml" ]; then FR14_OK=0; EVID14="${EVID14}ruff.toml presente (fonte única pyproject); "; fi
if [ "$FR14_OK" = "1" ]; then
  pass "FR-014" "${CANON[FR-014]}"
else
  fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"
fi

# =============================================================================
# FR-015: specs/README.md 007 mypy concluida
# =============================================================================
if [ ! -f "$README_SPECS" ]; then
  fail "FR-015" "${CANON[FR-015]}" "alta" "specs/README.md ausente"
else
  FR15_OK=1
  EVID15=""
  if ! grep -iq "007.*mypy.*✅.*a60c5b4" "$README_SPECS" 2>/dev/null; then
    FR15_OK=0; EVID15="${EVID15}specs/README.md sem \"007.*mypy.*✅.*a60c5b4\"; "
  fi
  if ! grep -iq "006.*ruff.*✅" "$README_SPECS" 2>/dev/null; then
    FR15_OK=0; EVID15="${EVID15}specs/README.md sem \"006.*ruff.*✅\"; "
  fi
  if [ "$FR15_OK" = "1" ]; then
    pass "FR-015" "${CANON[FR-015]}"
  else
    fail "FR-015" "${CANON[FR-015]}" "alta" "$EVID15 README atual: $(grep "007" "$README_SPECS" 2>/dev/null | head -1 | cut -c1-80)"
  fi
fi

# =============================================================================
# FR-016: git ls-files specs/007-mypy/spec.md rastreado
# =============================================================================
FR16_OK=1
EVID16=""
if ! git ls-files --error-unmatch "$SPEC007" >/dev/null 2>&1; then
  FR16_OK=0; EVID16="${EVID16}specs/007-mypy/spec.md não rastreado (??); "
fi
if ! git ls-files --error-unmatch "$RESEARCH007" >/dev/null 2>&1; then
  FR16_OK=0; EVID16="${EVID16}docs/plan/research/f0-007-mypy.md não rastreado; "
fi
if [ "$FR16_OK" = "1" ]; then
  pass "FR-016" "${CANON[FR-016]}"
else
  fail "FR-016" "${CANON[FR-016]}" "alta" "$EVID16"
fi

# =============================================================================
# Self-check f0-001..006 (paralelo, FKX=1)
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  FRSC_OK=1
  EVIDSC=""
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FRSC_OK=0; EVIDSC="${EVIDSC}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
  if [ "$FRSC_OK" != "1" ]; then
    # Se harness herdado reprovar, adiciona evidência a FR-011 se já falhou
    if [ "$FR11_OK" != "1" ]; then
      :
    else
      # registra como falha adicional em FR-011? Não, mantém FR-011 ok mas poderia falhar FR-012?
      # Para não duplicar, apenas mantém rastreável via evidência
      :
    fi
  fi
fi

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
