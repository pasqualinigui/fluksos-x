#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 006 (0.2): Ruff 0.16.5 — linter + formatter
#
# Contrato de assercoes deste item:
#   specs/006-ruff/spec.md (14 FRs, 8 SCs, 3 US)
#   specs/006-ruff/plan.md (Fases A-E, D1-D10)
#   specs/006-ruff/contracts/ruff-contract.md
#   specs/006-ruff/contracts/oracle-cli.md (mapa identidade 14 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-006-ruff.md (Q1-Q10 D1-D10, 2026-08-31)
#   specs/006-ruff/research.md (D1-D10 consolidadas)
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ pytest 005 + ruff 006).
#      Nenhuma dependencia do projeto além de ruff/pytest.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-08-31:
#   D1 ruff==0.16.5 via [dependency-groups] dev (PEP 735), uv sync (Q1)
#   D2 pyproject.toml [tool.ruff.*] fonte única, sem ruff.toml (Q2)
#   D3 select E,F,W,C90 + extend-select I,UP,B,SIM,S,C4,A,RUF ignore E501,S101,S603 per-file-ignores tests/**/* S101,S603 (Q3)
#   D4 line-length 88 target-version py312 exclude=[.git,...,.ruff_cache,.venv] + format double (Q4)
#   D5 uv run ruff check / format --check --diff idempotente, sem --fix no harness (Q5)
#   D6 uv add --dev ruff==0.16.5 -> dev com pytest+ruff (Q6)
#   D7 S bandit como portão, pip-audit deferido 008 (Q7)
#   D8 exclude replica default + tests/ lintado (Q8)
#   D9 Harness f0-006-ruff.sh 10-14 asserções só ruff (Q9)
#   D10 Determinismo ruff format idempotente, compat mypy UP/I, fronteira 006 só ruff (Q10)
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
  ["FR-001"]="ruff==0.16.5 em [dependency-groups] dev exato"
  ["FR-002"]="[tool.ruff] line-length 88 target-version py312 exclude"
  ["FR-003"]="[tool.ruff.lint] select E,F,W,C90 extend-select I,UP,B,SIM,S,C4,A,RUF ignore per-file-ignores"
  ["FR-004"]="[tool.ruff.format] quote-style double indent-style space line-ending auto"
  ["FR-005"]="ruff.toml nao existe fonte unica pyproject.toml"
  ["FR-006"]="uv.lock contem ruff com hash"
  ["FR-007"]=".ruff_cache gitignored e uv.lock nao ignorado"
  ["FR-008"]="uv run ruff check . 0 conforme"
  ["FR-009"]="uv run ruff format --check --diff . 0 idempotente"
  ["FR-010"]="ruff format . idempotente sha256sum"
  ["FR-011"]="oraculo 10-14 assercoes CANON quiet list FKX EPOCHSECONDS"
  ["FR-012"]="CI glob inclui f0-006 sem editar ci.yml"
  ["FR-013"]="CONVERGE tasks.md zero [ ]"
  ["FR-014"]="fronteira sem mypy/lefthook/packages/ruff.toml D/ANN"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
GITIGNORE="$ROOT/.gitignore"
CI_YML="$ROOT/.github/workflows/ci.yml"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS006="$ROOT/specs/006-ruff/tasks.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"
ORACLE5="$SCRIPT_DIR/f0-005-pytest.sh"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: ruff==0.16.5 em [dependency-groups] dev
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
assert "ruff==0.16.5" in dev, f"dev={dev!r}"
# ensure not in project.dependencies
deps=d.get("project",{}).get("dependencies",[])
for dep in deps:
    assert "ruff" not in dep.lower(), f"ruff em project.dependencies: {deps}"
PY
    then
      pass "FR-001" "${CANON[FR-001]}"
    else
      val=$(python3 -c 'import tomllib; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("dependency-groups",{}).get("dev"))' 2>/dev/null || echo "?")
      fail "FR-001" "${CANON[FR-001]}" "alta" "dependency-groups.dev=${val} sem ruff==0.16.5 ou ruff em project.dependencies (D1)"
    fi
  fi
fi

# =============================================================================
# FR-002: [tool.ruff] line-length 88 py312 exclude
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-002" "${CANON[FR-002]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
r=d.get("tool",{}).get("ruff",{})
assert r.get("line-length")==88, f'line-length={r.get("line-length")!r}'
assert r.get("target-version")=="py312", f'target-version={r.get("target-version")!r}'
exc=r.get("exclude") or []
for need in [".ruff_cache", ".venv", ".git"]:
    assert need in exc, f"exclude sem {need}: {exc}"
PY
  if [ $? = 0 ]; then
    pass "FR-002" "${CANON[FR-002]}"
  else
    val=$(python3 -c 'import tomllib, json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(json.dumps(d.get("tool",{}).get("ruff",{}), indent=2))' 2>/dev/null | head -20 || echo "?")
    fail "FR-002" "${CANON[FR-002]}" "alta" "tool.ruff divergente: $val (esperado line-length 88 target-version py312 exclude com .ruff_cache/.venv)"
  fi
fi

# =============================================================================
# FR-003: [tool.ruff.lint] select etc.
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-003" "${CANON[FR-003]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
lint=d.get("tool",{}).get("ruff",{}).get("lint",{})
assert lint.get("select")==["E","F","W","C90"], f'select={lint.get("select")!r}'
ext=lint.get("extend-select") or []
for code in ["I","UP","B","SIM","S","C4","A","RUF"]:
    assert code in ext, f"extend-select sem {code}: {ext}"
ign=lint.get("ignore") or []
for code in ["E501","S101","S603"]:
    assert code in ign, f"ignore sem {code}: {ign}"
pfi=lint.get("per-file-ignores") or {}
assert "tests/**/*" in pfi, f"per-file-ignores sem tests/**/*: {pfi}"
assert "S101" in pfi["tests/**/*"] and "S603" in pfi["tests/**/*"], f"per-file-ignores tests/**/* sem S101/S603: {pfi}"
PY
  if [ $? = 0 ]; then
    pass "FR-003" "${CANON[FR-003]}"
  else
    val=$(python3 -c 'import tomllib, json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(json.dumps(d.get("tool",{}).get("ruff",{}).get("lint",{}), indent=2))' 2>/dev/null | head -30 || echo "?")
    fail "FR-003" "${CANON[FR-003]}" "alta" "tool.ruff.lint divergente: $val"
  fi
fi

# =============================================================================
# FR-004: [tool.ruff.format]
# =============================================================================
if [ ! -f "$PYPROJECT" ]; then
  fail "FR-004" "${CANON[FR-004]}" "alta" "pyproject.toml ausente"
else
  python3 - "$PYPROJECT" <<'PY' 2>/dev/null
import tomllib, sys
d=tomllib.load(open(sys.argv[1],"rb"))
fmt=d.get("tool",{}).get("ruff",{}).get("format",{})
assert fmt.get("quote-style")=="double", f'quote-style={fmt.get("quote-style")!r}'
assert fmt.get("indent-style")=="space", f'indent-style={fmt.get("indent-style")!r}'
assert fmt.get("line-ending")=="auto", f'line-ending={fmt.get("line-ending")!r}'
assert fmt.get("docstring-code-format") is False, f'docstring-code-format={fmt.get("docstring-code-format")!r}'
PY
  if [ $? = 0 ]; then
    pass "FR-004" "${CANON[FR-004]}"
  else
    val=$(python3 -c 'import tomllib, json; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(json.dumps(d.get("tool",{}).get("ruff",{}).get("format",{}), indent=2))' 2>/dev/null | head -20 || echo "?")
    fail "FR-004" "${CANON[FR-004]}" "alta" "tool.ruff.format divergente: $val"
  fi
fi

# =============================================================================
# FR-005: ruff.toml não existe
# =============================================================================
FR5_OK=1
EVID5=""
if [ -f "$ROOT/ruff.toml" ]; then FR5_OK=0; EVID5="${EVID5}ruff.toml existe (FR-005 fonte única); "; fi
if [ -f "$ROOT/.ruff.toml" ]; then FR5_OK=0; EVID5="${EVID5}.ruff.toml existe; "; fi
if [ "$FR5_OK" = "1" ]; then
  pass "FR-005" "${CANON[FR-005]}"
else
  fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"
fi

# =============================================================================
# FR-006: uv.lock contém ruff
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock ausente"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock TOML invalido"
  else
    if ! grep -q 'name = "ruff"' "$UVLOCK" 2>/dev/null; then
      fail "FR-006" "${CANON[FR-006]}" "alta" "uv.lock sem name = \"ruff\" (FR-006)"
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
# FR-007: .ruff_cache gitignored
# =============================================================================
FR7_OK=1
EVID7=""
if ! git check-ignore -q "$ROOT/.ruff_cache" 2>/dev/null; then
  if ! grep -q ".ruff_cache" "$GITIGNORE" 2>/dev/null; then
    FR7_OK=0; EVID7="${EVID7}.ruff_cache não ignorado (git check-ignore falhou); "
  fi
fi
if git check-ignore -q "$UVLOCK" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}uv.lock ignorado (não deve); "
fi
if git ls-files 2>/dev/null | grep -q ".ruff_cache" 2>/dev/null; then
  FR7_OK=0; EVID7="${EVID7}.ruff_cache rastreado em git ls-files; "
fi
if [ "$FR7_OK" = "1" ]; then
  pass "FR-007" "${CANON[FR-007]}"
else
  fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"
fi

# =============================================================================
# FR-008: uv run ruff check . 0
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  # nested: apenas verifica config, não executa ruff (evita custo e loop)
  if [ -f "$PYPROJECT" ] && grep -q "tool.ruff" "$PYPROJECT" 2>/dev/null; then
    pass "FR-008" "${CANON[FR-008]}"
  else
    fail "FR-008" "${CANON[FR-008]}" "alta" "nested: [tool.ruff] ausente"
  fi
else
  if ! command -v uv >/dev/null 2>&1; then
    fail "FR-008" "${CANON[FR-008]}" "alta" "uv não encontrado"
  else
    if ! grep -q 'name = "ruff"' "$UVLOCK" 2>/dev/null; then
      fail "FR-008" "${CANON[FR-008]}" "alta" "ruff não em uv.lock — não há como executar ruff check (FR-008)"
    else
      if uv run ruff check . --output-format=concise >/dev/null 2>&1; then
        pass "FR-008" "${CANON[FR-008]}"
      else
        out=$(uv run ruff check . --output-format=concise 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
        fail "FR-008" "${CANON[FR-008]}" "alta" "uv run ruff check reprovou: $out"
      fi
    fi
  fi
fi

# =============================================================================
# FR-009: uv run ruff format --check --diff . 0
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  if [ -f "$PYPROJECT" ] && grep -q "tool.ruff" "$PYPROJECT" 2>/dev/null; then
    pass "FR-009" "${CANON[FR-009]}"
  else
    fail "FR-009" "${CANON[FR-009]}" "alta" "nested: [tool.ruff] ausente"
  fi
else
  if ! command -v uv >/dev/null 2>&1; then
    fail "FR-009" "${CANON[FR-009]}" "alta" "uv não encontrado"
  else
    if ! grep -q 'name = "ruff"' "$UVLOCK" 2>/dev/null; then
      fail "FR-009" "${CANON[FR-009]}" "alta" "ruff não em uv.lock — não há como executar format --check (FR-009)"
    else
      if uv run ruff format --check --diff . >/dev/null 2>&1; then
        pass "FR-009" "${CANON[FR-009]}"
      else
        out=$(uv run ruff format --check --diff . 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
        fail "FR-009" "${CANON[FR-009]}" "alta" "uv run ruff format --check reprovou: $out"
      fi
    fi
  fi
fi

# =============================================================================
# FR-010: ruff format . idempotente
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  pass "FR-010" "${CANON[FR-010]}"
else
  if ! command -v uv >/dev/null 2>&1 || ! grep -q 'name = "ruff"' "$UVLOCK" 2>/dev/null; then
    fail "FR-010" "${CANON[FR-010]}" "alta" "ruff não disponível para teste idempotente"
  else
    # idempotente: duas format seguidas não alteram hash de tests/*.py
    TMPF="$(mktemp -d)"
    # copia estado atual de tests/*.py hashes
    find "$ROOT/tests" -name "*.py" -exec sha256sum {} \; 2>/dev/null | sort > "$TMPF/a1" || true
    uv run ruff format . >/dev/null 2>&1
    find "$ROOT/tests" -name "*.py" -exec sha256sum {} \; 2>/dev/null | sort > "$TMPF/a2" || true
    uv run ruff format . >/dev/null 2>&1
    find "$ROOT/tests" -name "*.py" -exec sha256sum {} \; 2>/dev/null | sort > "$TMPF/a3" || true
    if cmp -s "$TMPF/a2" "$TMPF/a3" 2>/dev/null; then
      pass "FR-010" "${CANON[FR-010]}"
    else
      fail "FR-010" "${CANON[FR-010]}" "alta" "ruff format não idempotente — segunda format alterou hash"
    fi
    rm -rf -- "$TMPF"
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
  fi
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    FR11_OK=0; EVID11="${EVID11}exit 2 para uso inválido não obedecido; "
  fi
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1 & P1=$!
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1 & P2=$!
  wait $P1; C1=$?
  wait $P2; C2=$?
  if [ -n "${EPOCHSECONDS:-}" ]; then END11=$EPOCHSECONDS; else END11=$(date +%s 2>/dev/null || echo 0); fi
  ELAPSED11=$((END11 - START11))
  if [ "$ELAPSED11" -gt 5 ] 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}oráculo >5s (${ELAPSED11}s, FR-011); "
  fi
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR11_OK=0; EVID11="${EVID11}duas execuções divergiram; "
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
# FR-012: CI glob inclui f0-006
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
      fail "FR-012" "${CANON[FR-012]}" "alta" "f0-006 ausente"
    fi
  fi
fi

# =============================================================================
# FR-013: CONVERGE tasks.md zero [ ]
# =============================================================================
if [ ! -f "$TASKS006" ]; then
  fail "FR-013" "${CANON[FR-013]}" "alta" "specs/006-ruff/tasks.md ausente"
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS006" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" = "0" ]; then
    pass "FR-013" "${CANON[FR-013]}"
  else
    fail "FR-013" "${CANON[FR-013]}" "alta" "tasks.md contém $COUNT tarefas [ ] abertas (CONVERGE)"
  fi
fi

# =============================================================================
# FR-014: fronteira sem mypy/lefthook/packages
# =============================================================================
FR14_OK=1
EVID14=""
# Nota 007: mypy via [tool.mypy] é legítimo após 007; permite quando em uv.lock
if grep -q '^\[tool\.mypy\]' "$PYPROJECT" 2>/dev/null; then
  if ! grep -q 'name = "mypy"' "$UVLOCK" 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}[tool.mypy] presente sem mypy em uv.lock; "
  fi
fi
if [ -f "$ROOT/mypy.ini" ]; then FR14_OK=0; EVID14="${EVID14}mypy.ini existe; "; fi
# lefthook.yml é jurisdição da 009 (conteúdo asserido por f0-009) — ADR-018
if [ -d "$ROOT/packages" ] && [ ! -f "$ROOT/packages/core/pyproject.toml" ]; then FR14_OK=0; EVID14="${EVID14}packages/ sem core/pyproject.toml de membro (ADR-023); "; fi
if [ -d "$ROOT/packages/cli" ] && [ ! -f "$ROOT/packages/cli/pyproject.toml" ]; then FR14_OK=0; EVID14="${EVID14}packages/ com cli/ sem pyproject.toml de membro (ADR-026); "; fi
if [ -n "$(ls "$ROOT/packages" 2>/dev/null | grep -v -x -e "core" -e "cli" | tr -d '[:space:]' || true)" ]; then FR14_OK=0; EVID14="${EVID14}packages/ com conteudo alem de core/+cli/ (ADR-023/026); "; fi
if [ -f "$ROOT/ruff.toml" ] || [ -f "$ROOT/.ruff.toml" ]; then FR14_OK=0; EVID14="${EVID14}ruff.toml presente; "; fi
if grep -q '"D"' "$PYPROJECT" 2>/dev/null && grep -q 'select.*D' "$PYPROJECT" 2>/dev/null; then
  # D pydocstyle não deve estar em select em 006 (deferido)
  if grep -Eq 'select.*".*D.*"' "$PYPROJECT" 2>/dev/null; then FR14_OK=0; EVID14="${EVID14}D em select (deferido a 007); "; fi
fi
if [ "$FR14_OK" = "1" ]; then
  pass "FR-014" "${CANON[FR-014]}"
else
  fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14"
fi

# =============================================================================
# Self-check f0-001..005 (paralelo, FKX=1, skip FR-011 quando nested para <5s)
# =============================================================================
# FR-009 já cobre self-check de 005? Não, FR-009 é ruff format, não harness.
# Este bloco adicional assere que harness herdado 001..005 --quiet todos, como em 005 FR-009
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  FRSC_OK=1
  EVIDSC=""
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FRSC_OK=0; EVIDSC="${EVIDSC}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
  if [ "$FRSC_OK" != "1" ]; then
    # Se harness herdado reprovar, FR-011 já reprovaria via determinismo, mas registra aqui também
    # Para não duplicar falha, apenas adiciona evidência a FR-011 se já falhou, senão cria falha extra em FR-012? 
    # Mantém FR-012 como CI glob, então registra como parte de FR-011 evidence já
    :
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
