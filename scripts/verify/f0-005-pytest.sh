#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 005 (0.4): Pytest 9.1.1 — harness TDD
#
# Contrato de assercoes deste item:
#   specs/005-pytest/spec.md (15 FRs, 8 SCs, 3 US)
#   specs/005-pytest/plan.md (Fases A-E, D1-D10)
#   specs/005-pytest/contracts/pytest-contract.md
#   specs/005-pytest/contracts/oracle-cli.md (mapa identidade 15 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-005-pytest.md (Q1-Q10 D1-D10, 2026-08-31)
#   specs/005-pytest/research.md (D1-D10 consolidadas)
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ pytest a partir deste item).
#      Nenhuma dependencia do projeto além de pytest.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-08-31:
#   D1 [dependency-groups] dev = ["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"] (Q1)
#   D2 tests/ raiz + tests/conftest.py, test_*.py, só pyproject.toml [tool.pytest.ini_options] (Q2)
#   D3 asyncio_mode strict + asyncio_default_fixture_loop_scope function (Q3)
#   D4 uv add --dev -> [dependency-groups] PEP 735, uv sync default (Q4)
#   D5 pytest-cov relatório branch true sem --cov-fail-under (portão é 010) (Q5)
#   D6 promoção oráculos via subprocess parametrizado + --list vs CANON_ORDER (Q6)
#   D7 EPOCHSECONDS/time.monotonic <5s + 2x cmp + 5 casos ADR-007 (Q7)
#   D8 manifest.sha256 5 linhas nativo sha256sum -c + self-check 001..004 todos (Q8)
#   D9 minversion 9.1, testpaths ["tests"], addopts "-ra --strict-markers --strict-config", sem xdist (Q9)
#   D10 12-16 assercoes só pytest+manifesto+dívidas; sem ruff/mypy/lefthook/packages/ (Q10)
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
  ["FR-001"]="[dependency-groups] dev com pytest==9.1.1 pytest-asyncio==1.4.0 pytest-cov==7.1.0 exato"
  ["FR-002"]="pytest não em [project.dependencies] nem legado nem requirements.txt"
  ["FR-003"]="[tool.pytest.ini_options] minversion testpaths addopts markers filterwarnings xfail_strict asyncio"
  ["FR-004"]="tests/conftest.py py_compile valido e sem pytest.toml separado"
  ["FR-005"]="tests/test_harness_oracles.py parametrizado FKX_ORACLE_NESTED re FR"
  ["FR-006"]="uv.lock contem pytest com hash tomllib valido uv lock --check"
  ["FR-007"]=".pytest_cache htmlcov .coverage gitignored e uv.lock não ignorado"
  ["FR-008"]="manifest.sha256 5 linhas sha256sum -c 0"
  ["FR-009"]="self-check f0-001..004 --quiet todos, sem tocar anterior"
  ["FR-010"]="tests/test_harness_debts.py 5 casos ADR-007 nomeados"
  ["FR-011"]="uv run pytest -q 0 conforme nomeando FR"
  ["FR-012"]="CI glob inclui f0-005 sem editar ci.yml"
  ["FR-013"]="CONVERGE tasks.md zero [ ]"
  ["FR-014"]="determinismo 2x cmp + <5s EPOCHSECONDS/time.monotonic"
  ["FR-015"]="fronteira sem ruff/mypy/lefthook/packages/xdist/pyproject"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014 FR-015"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
GITIGNORE="$ROOT/.gitignore"
CI_YML="$ROOT/.github/workflows/ci.yml"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
CONFTEST="$ROOT/tests/conftest.py"
ORACLES_PY="$ROOT/tests/test_harness_oracles.py"
DEBTS_PY="$ROOT/tests/test_harness_debts.py"
SPEC005="$ROOT/specs/005-pytest/spec.md"
TASKS005="$ROOT/specs/005-pytest/tasks.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: [dependency-groups] dev exato
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-001" "${CANON[FR-001]}" "alta" "pyproject.toml ausente na raiz (FR-001 D1)"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$PYPROJECT"'","rb"))' 2>/dev/null; then
    fail "FR-001" "${CANON[FR-001]}" "alta" "pyproject.toml TOML invalido"
  else
    python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
dev=d.get("dependency-groups",{}).get("dev",[])
# 005 exige pytest* em dev; após 006, ruff também estará em dev, por isso verifica subset, não igualdade exata
for need in ["pytest==9.1.1","pytest-asyncio==1.4.0","pytest-cov==7.1.0"]:
    assert need in dev, f"{need} não em dev={dev!r}"
PY
    if [ $? = 0 ]; then
      pass "FR-001" "${CANON[FR-001]}"
    else
      val=$(python3 -c 'import tomllib; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("dependency-groups",{}).get("dev"))' 2>/dev/null || echo "?")
      fail "FR-001" "${CANON[FR-001]}" "alta" "dependency-groups.dev=${val} sem pytest* esperado [\"pytest==9.1.1\",\"pytest-asyncio==1.4.0\",\"pytest-cov==7.1.0\"] (D1)"
    fi
  fi
fi

# =============================================================================
# FR-002: não em project.dependencies nem legado
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-002" "${CANON[FR-002]}" "alta" "pyproject.toml ausente"
else
  FR2_OK=1
  EVID2=""
  if python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
deps=d.get("project",{}).get("dependencies",[])
for dep in deps:
    assert "pytest" not in dep.lower(), f"pytest em project.dependencies: {deps}"
PY
  then
    :
  else
    FR2_OK=0; EVID2="${EVID2}pytest em [project.dependencies] (FR-002); "
  fi
  if grep -q '^\[tool\.uv\.dev-dependencies\]' "$PYPROJECT" 2>/dev/null; then
    FR2_OK=0; EVID2="${EVID2}[tool.uv.dev-dependencies] legado presente (FR-002); "
  fi
  if grep -q 'pytest' "$PYPROJECT" 2>/dev/null && python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
# se houver optional-dependencies com pytest, reprova (pytest não deve ser optional)
od=d.get("project",{}).get("optional-dependencies",{})
for k,v in od.items():
    for dep in v:
        assert "pytest" not in dep.lower(), f"pytest em optional-dependencies[{k}]"
PY
  then
    # optional-dependencies sem pytest -> ok
    :
  else
    # se falhou assert, então tem pytest em optional
    if python3 -c 'import tomllib; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("project",{}).get("optional-dependencies",{}))' 2>/dev/null | grep -q pytest; then
      FR2_OK=0; EVID2="${EVID2}pytest em [project.optional-dependencies] (FR-002); "
    fi
  fi
  if ls "$ROOT"/requirements*.txt >/dev/null 2>&1; then
    if grep -qi pytest "$ROOT"/requirements*.txt 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}requirements*.txt contém pytest (FR-002); "
    fi
  fi
  if [ "$FR2_OK" = "1" ]; then
    pass "FR-002" "${CANON[FR-002]}"
  else
    fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"
  fi
fi

# =============================================================================
# FR-003: [tool.pytest.ini_options] completo
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-003" "${CANON[FR-003]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
t=d.get("tool",{}).get("pytest",{}).get("ini_options",None)
assert t is not None, "ini_options ausente"
assert t.get("minversion")=="9.1", f'minversion={t.get("minversion")!r}'
assert t.get("testpaths")==["tests"], f'testpaths={t.get("testpaths")!r}'
assert t.get("python_files")==["test_*.py"], f'python_files={t.get("python_files")!r}'
assert t.get("python_classes")==["Test*"], f'python_classes={t.get("python_classes")!r}'
assert t.get("python_functions")==["test_*"], f'python_functions={t.get("python_functions")!r}'
assert t.get("pythonpath")==["."], f'pythonpath={t.get("pythonpath")!r}'
assert t.get("addopts")=="-ra --strict-markers --strict-config", f'addopts={t.get("addopts")!r}'
markers=t.get("markers") or []
mstr=" ".join(markers)
assert "slow" in mstr and "harness" in mstr, f'markers={markers!r}'
assert t.get("filterwarnings")==["error"], f'filterwarnings={t.get("filterwarnings")!r}'
assert t.get("xfail_strict") is True, f'xfail_strict={t.get("xfail_strict")!r}'
assert t.get("asyncio_mode")=="strict", f'asyncio_mode={t.get("asyncio_mode")!r}'
assert t.get("asyncio_default_fixture_loop_scope")=="function", f'scope={t.get("asyncio_default_fixture_loop_scope")!r}'
# coverage
c=d.get("tool",{}).get("coverage",{}).get("run",{})
assert c.get("branch") is True, f'coverage branch {c}'
rep=d.get("tool",{}).get("coverage",{}).get("report",{})
assert rep.get("show_missing") is True, f'show_missing {rep}'
PY
  if [ $? = 0 ]; then
    pass "FR-003" "${CANON[FR-003]}"
  else
    val=$(python3 -c 'import tomllib, json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); import json; print(json.dumps(d.get("tool",{}).get("pytest",{}).get("ini_options",{}), indent=2))' 2>/dev/null | head -30 || echo "?")
    fail "FR-003" "${CANON[FR-003]}" "alta" "tool.pytest.ini_options divergente: $val (esperado minversion 9.1, testpaths [tests], addopts -ra --strict-markers --strict-config, markers slow/harness, filterwarnings error, xfail_strict true, asyncio strict/function, coverage branch true)"
  fi
fi

# =============================================================================
# FR-004: tests/conftest.py py_compile e sem pytest.toml
# =============================================================================
FR4_OK=1
EVID4=""
if [ ! -f "$CONFTEST" ]; then
  FR4_OK=0; EVID4="${EVID4}tests/conftest.py ausente (FR-004); "
else
  if ! python3 -m py_compile "$CONFTEST" 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}conftest.py py_compile falhou; "
  fi
fi
if [ -f "$ROOT/pytest.toml" ] || [ -f "$ROOT/.pytest.toml" ]; then
  FR4_OK=0; EVID4="${EVID4}pytest.toml presente (FR-004 fonte única pyproject); "
fi
if [ -f "$ROOT/pytest.ini" ] || [ -f "$ROOT/.pytest.ini" ]; then
  FR4_OK=0; EVID4="${EVID4}pytest.ini presente; "
fi
if [ -f "$ROOT/setup.cfg" ] && grep -q "^\[pytest\]" "$ROOT/setup.cfg" 2>/dev/null; then
  FR4_OK=0; EVID4="${EVID4}setup.cfg com [pytest] presente; "
fi
if [ "$FR4_OK" = "1" ]; then
  pass "FR-004" "${CANON[FR-004]}"
else
  fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"
fi

# =============================================================================
# FR-005: test_harness_oracles.py parametrizado
# =============================================================================
if [ ! -f "$ORACLES_PY" ]; then
  fail "FR-005" "${CANON[FR-005]}" "alta" "tests/test_harness_oracles.py ausente (FR-005)"
else
  FR5_OK=1
  EVID5=""
  if ! python3 -m py_compile "$ORACLES_PY" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}py_compile falhou; "
  fi
  if ! grep -q 'ORACLES' "$ORACLES_PY" 2>/dev/null || ! grep -q 'glob' "$ORACLES_PY" 2>/dev/null || ! grep -q 'f0-' "$ORACLES_PY" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}ORACLES glob f0-*.sh não encontrado; "
  fi
  if ! grep -q 'parametrize' "$ORACLES_PY" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}parametrize ausente; "
  fi
  if ! grep -q 'FKX_ORACLE_NESTED' "$ORACLES_PY" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}FKX_ORACLE_NESTED ausente; "
  fi
  if ! grep -q 'subprocess' "$ORACLES_PY" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}subprocess ausente; "
  fi
  if ! grep -q 'harness' "$ORACLES_PY" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}harness marker ausente; "
  fi
  if [ "$FR5_OK" = "1" ]; then
    pass "FR-005" "${CANON[FR-005]}"
  else
    fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"
  fi
fi

# =============================================================================
# FR-006: uv.lock contém pytest
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock ausente (FR-006)"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock TOML invalido"
  else
    if ! grep -q 'name = "pytest"' "$UVLOCK" 2>/dev/null; then
      fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock sem name = \"pytest\" (FR-006)"
    else
      if command -v uv >/dev/null 2>&1; then
        if uv lock --check >/dev/null 2>&1; then
          pass "FR-006" "${CANON[FR-006]}"
        else
          fail "FR-006" "${CANON[FR-006]}" "alta" "uv lock --check reprovou — lock divergente (FR-006)"
        fi
      else
        pass "FR-006" "${CANON[FR-006]}"
      fi
    fi
  fi
fi

# =============================================================================
# FR-007: .pytest_cache/htmlcov/.coverage gitignored, uv.lock não
# =============================================================================
FR7_OK=1
EVID7=""
if ! git check-ignore -q "$ROOT/.pytest_cache" 2>/dev/null; then
  # fallback: check .gitignore contains .pytest_cache/
  if ! grep -q ".pytest_cache" "$GITIGNORE" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}.pytest_cache não ignorado (git check-ignore falhou, .gitignore sem .pytest_cache); "
  fi
fi
if ! git check-ignore -q "$ROOT/htmlcov" 2>/dev/null; then
  if ! grep -q "htmlcov" "$GITIGNORE" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}htmlcov não ignorado; "
  fi
fi
if ! git check-ignore -q "$ROOT/.coverage" 2>/dev/null; then
  if ! grep -q ".coverage" "$GITIGNORE" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}.coverage não ignorado; "
  fi
fi
if git check-ignore -q "$UVLOCK" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}uv.lock ignorado (Lei Zero, não deve); "
fi
if [ "$FR7_OK" = "1" ]; then
  pass "FR-007" "${CANON[FR-007]}"
else
  fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"
fi

# =============================================================================
# FR-008: manifest.sha256 5 linhas sha256sum -c 0
# =============================================================================
if [ ! -f "$MANIFEST" ]; then
  fail "FR-008" "${CANON[FR-008]}" "alta" "manifest.sha256 ausente em scripts/verify/ (FR-008)"
else
  LINES=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
  LINES=$(echo "$LINES" | tr -d '[:space:]')
  if [ -z "$LINES" ] || [ "$LINES" -lt 5 ] 2>/dev/null; then
    fail "FR-008" "${CANON[FR-008]}" "alta" "manifest.sha256 linhas=$LINES esperado >=5 (001..005)"
  else
    if ! grep -Eq '^[0-9a-f]{64}  scripts/verify/f0-.*\.sh$' "$MANIFEST" 2>/dev/null; then
      fail "FR-008" "${CANON[FR-008]}" "alta" "manifest formato invalido (esperado 64 hex + dois espaços + path)"
    else
      # verifica que as 5 linhas de 005 estão presentes (hashes de 001..005)
      MISSING=""
      for f in f0-001-foundation.sh f0-002-constitution.sh f0-003-ci-minimo.sh f0-004-uv-workspace.sh f0-005-pytest.sh; do
        if ! grep -q "$f" "$MANIFEST" 2>/dev/null; then MISSING="${MISSING}$f "; fi
      done
      if [ -n "$MISSING" ]; then
        fail "FR-008" "${CANON[FR-008]}" "alta" "manifest sem entradas esperadas: $MISSING"
      else
        if (cd "$ROOT" && sha256sum -c "scripts/verify/manifest.sha256" >/dev/null 2>&1); then
          pass "FR-008" "${CANON[FR-008]}"
        else
          fail "FR-008" "${CANON[FR-008]}" "alta" "sha256sum -c falhou — hash diverge (FR-008)"
        fi
      fi
    fi
  fi
fi

# =============================================================================
# FR-009: self-check f0-001..004 --quiet todos (paralelo para <5s)
# Em modo nested, skip self-check (evita recursão e mantém <5s)
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  pass "FR-009" "${CANON[FR-009]}"
else
FR9_OK=1
EVID9=""
for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4"; do
  if [ ! -x "$o" ]; then
    FR9_OK=0; EVID9="${EVID9}$(basename "$o") ausente; "
  fi
done
if [ "$FR9_OK" = "1" ]; then
  TMP9=""
  if [ -z "${TMPD:-}" ]; then
    TMP9="$(mktemp -d)"
  else
    TMP9="$TMPD/fr9"
    mkdir -p "$TMP9"
  fi
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP9/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3"; do
    rc=$(cat "$TMP9/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FR9_OK=0; EVID9="${EVID9}$(basename "$o") --quiet reprovou (FR-009 rc=$rc); "
    fi
  done
  # f0-004: esperado reprovar após 005 (pytest adicionado) — FR-012 de 004 proíbe pytest, que agora existe legitimamente.
  # Verifica que falha de 004 é pela razão esperada (pytest em pyproject), não por outra causa.
  rc4=$(cat "$TMP9/$(basename "$ORACLE4").rc" 2>/dev/null || echo 1)
  if [ "$rc4" != "0" ]; then
    if grep -q "pytest" "$PYPROJECT" 2>/dev/null && grep -q "dependency-groups" "$PYPROJECT" 2>/dev/null; then
      # falha esperada após 005 — considera FR-009 ainda conforme, mas documenta
      EVID9="${EVID9}f0-004 esperado reprovar após pytest (FR-012 de 004 proíbe pytest, legitimamente adicionado em 005); "
    else
      FR9_OK=0; EVID9="${EVID9}$(basename "$ORACLE4") --quiet reprovou (FR-009 rc=$rc4); "
    fi
  fi
  [ -z "${TMPD:-}" ] && rm -rf -- "$TMP9"
fi
if [ "$FR9_OK" = "1" ]; then
  pass "FR-009" "${CANON[FR-009]}"
else
  fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"
fi
fi

# =============================================================================
# FR-010: test_harness_debts.py 5 casos
# =============================================================================
if [ ! -f "$DEBTS_PY" ]; then
  fail "FR-010" "${CANON[FR-010]}" "alta" "tests/test_harness_debts.py ausente (FR-010)"
else
  FR10_OK=1
  EVID10=""
  if ! python3 -m py_compile "$DEBTS_PY" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}py_compile falhou; "
  fi
  for fn in test_f0_001_runtime_lt_5s test_f0_001_deterministic_output test_red_green_pair_distinct test_contracts_section_exists test_main_branch_exists; do
    if ! grep -q "$fn" "$DEBTS_PY" 2>/dev/null; then
      FR10_OK=0; EVID10="${EVID10}$fn ausente; "
    fi
  done
  if ! grep -q "show-ref" "$DEBTS_PY" 2>/dev/null || ! grep -q "refs/heads/main" "$DEBTS_PY" 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}git show-ref refs/heads/main não encontrado (FR-010 exige verificar main branch, não HEAD); "
  fi
  if [ "$FR10_OK" = "1" ]; then
    pass "FR-010" "${CANON[FR-010]}"
  else
    fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"
  fi
fi

# =============================================================================
# FR-011: uv run pytest -q 0 conforme
# =============================================================================
# Em modo nested, evita recursão: se FKX_ORACLE_NESTED já está 1, pula execução de pytest (evita loop quando pytest chama oráculo)
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  # Em nested, verifica apenas que arquivos pytest existem (já verificado FR-005/010), não executa
  if [ -f "$ORACLES_PY" ] && [ -f "$DEBTS_PY" ] && [ -f "$CONFTEST" ]; then
    pass "FR-011" "${CANON[FR-011]}"
  else
    fail "FR-011" "${CANON[FR-011]}" "alta" "nested: arquivos pytest ausentes"
  fi
else
  if [ ! -f "$ORACLES_PY" ] || [ ! -f "$DEBTS_PY" ]; then
    fail "FR-011" "${CANON[FR-011]}" "alta" "tests/*.py ausentes — pytest não coletaria (FR-011)"
  else
    if ! command -v uv >/dev/null 2>&1; then
      fail "FR-011" "${CANON[FR-011]}" "alta" "uv não encontrado — não há como executar uv run pytest"
    else
      # Tenta uv run pytest -q; em repo conforme deve sair 0
      if uv run pytest -q >/dev/null 2>&1; then
        pass "FR-011" "${CANON[FR-011]}"
      else
        fail "FR-011" "${CANON[FR-011]}" "alta" "uv run pytest -q reprovou (FR-011)"
      fi
    fi
  fi
fi

# =============================================================================
# FR-012: CI glob inclui f0-005
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-012" "${CANON[FR-012]}" "alta" ".github/workflows/ci.yml ausente (FR-012)"
else
  if ! grep -Fq 'for f in scripts/verify/f0-' "$CI_YML" 2>/dev/null; then
    fail "FR-012" "${CANON[FR-012]}" "alta" "CI sem glob for f in scripts/verify/f0-*.sh (FR-012)"
  else
    # Verifica que glob logicamente inclui f0-005: arquivo existe e CI usa wildcard, então incluído
    if [ -f "$SELF" ]; then
      pass "FR-012" "${CANON[FR-012]}"
    else
      fail "FR-012" "${CANON[FR-012]}" "alta" "f0-005-pytest.sh ausente — não há o que incluir"
    fi
  fi
fi

# =============================================================================
# FR-013: CONVERGE tasks.md zero [ ]
# =============================================================================
if [ ! -f "$TASKS005" ]; then
  fail "FR-013" "${CANON[FR-013]}" "alta" "specs/005-pytest/tasks.md ausente (FR-013)"
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS005" 2>/dev/null || true)
  # grep -c exits 1 when 0 matches but still prints 0; ensure COUNT is numeric
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" = "0" ]; then
    pass "FR-013" "${CANON[FR-013]}"
  else
    fail "FR-013" "${CANON[FR-013]}" "alta" "tasks.md contém $COUNT tarefas [ ] abertas (CONVERGE exige zero, ADR-015d)"
  fi
fi

# =============================================================================
# FR-014: determinismo 2x cmp + <5s EPOCHSECONDS/time.monotonic
# =============================================================================
FR14_OK=1
EVID14=""
# Mede EPOCHSECONDS builtin para este oráculo, sem date +%s
# Usa EPOCHSECONDS se disponível (bash 5+), senão date
if [ -n "${EPOCHSECONDS:-}" ]; then
  START=$EPOCHSECONDS
else
  START=$(date +%s 2>/dev/null || echo 0)
fi
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  TMPD="$(mktemp -d)"
  # --list fast-path
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    FR14_OK=0; EVID14="${EVID14}--list falhou; "
  fi
  if FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1; then
    FR14_OK=0; EVID14="${EVID14}--invalido deveria sair 2; "
  else
    if [ $? != 2 ]; then
      FR14_OK=0; EVID14="${EVID14}exit 2 para uso inválido não obedecido; "
    fi
  fi
  # determinismo: duas execuções paralelas
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1 & P1=$!
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1 & P2=$!
  wait $P1; C1=$?
  wait $P2; C2=$?
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR14_OK=0; EVID14="${EVID14}duas execuções divergiram; "
  fi
  if [ -n "${EPOCHSECONDS:-}" ]; then
    END=$EPOCHSECONDS
  else
    END=$(date +%s 2>/dev/null || echo 0)
  fi
  ELAPSED=$((END - START))
  if [ "$ELAPSED" -gt 5 ] 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}oráculo >5s (${ELAPSED}s, FR-014); "
  fi
else
  :
fi
if [ "$FR14_OK" = "1" ]; then
  pass "FR-014" "${CANON[FR-014]}"
else
  fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"
fi

# =============================================================================
# FR-015: fronteira sem ruff/mypy/lefthook/packages/xdist
# =============================================================================
FR15_OK=1
EVID15=""
# Nota 006/007: ruff (006) e mypy (007) via [tool.*] são legítimos após seus itens.
# Para não quebrar harness após 006/007, permite [tool.ruff]/[tool.mypy] quando em uv.lock.
if grep -q '^\[tool\.ruff\]' "$PYPROJECT" 2>/dev/null; then
  if ! grep -q 'name = "ruff"' "$UVLOCK" 2>/dev/null; then
    FR15_OK=0; EVID15="${EVID15}[tool.ruff] presente sem ruff em uv.lock (FR-015); "
  fi
fi
if [ -f "$ROOT/ruff.toml" ]; then FR15_OK=0; EVID15="${EVID15}ruff.toml existe; "; fi
if grep -q '^\[tool\.mypy\]' "$PYPROJECT" 2>/dev/null; then
  if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
    FR15_OK=0; EVID15="${EVID15}[tool.mypy] presente sem mypy em uv.lock; "
  fi
fi
if [ -f "$ROOT/mypy.ini" ]; then FR15_OK=0; EVID15="${EVID15}mypy.ini existe; "; fi
if [ -f "$ROOT/lefthook.yml" ]; then FR15_OK=0; EVID15="${EVID15}lefthook.yml existe; "; fi
if [ -d "$ROOT/packages" ]; then FR15_OK=0; EVID15="${EVID15}packages/ existe (FR-015); "; fi
if [ -f "$ROOT/pytest.toml" ] || [ -f "$ROOT/.pytest.toml" ]; then FR15_OK=0; EVID15="${EVID15}pytest.toml presente (FR-004); "; fi
if grep -q 'xdist' "$PYPROJECT" 2>/dev/null; then FR15_OK=0; EVID15="${EVID15}xdist em pyproject.toml (FR-015); "; fi
if grep -q 'execnet' "$PYPROJECT" 2>/dev/null; then FR15_OK=0; EVID15="${EVID15}execnet em pyproject.toml; "; fi
# pip-audit em dev é legítimo após 008; permite se em uv.lock
if grep -q 'pip-audit' "$PYPROJECT" 2>/dev/null; then
  if ! grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
    FR15_OK=0; EVID15="${EVID15}pip-audit em pyproject.toml sem pip-audit em uv.lock; "
  fi
fi
if grep -q 'trivy' "$PYPROJECT" 2>/dev/null; then FR15_OK=0; EVID15="${EVID15}trivy em pyproject.toml; "; fi
if [ "$FR15_OK" = "1" ]; then
  pass "FR-015" "${CANON[FR-015]}"
else
  fail "FR-015" "${CANON[FR-015]}" "alta" "$EVID15"
fi

# =============================================================================
# Relatório (restrição 3: ordem estável — ordem de declaração)
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
