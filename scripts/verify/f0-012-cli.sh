#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 012 (0.7): packages/cli entry point
#
# Contrato de assercoes deste item:
#   specs/012-packages-cli/spec.md (12 FRs, 6 SCs, 3 US + CLARIFY 4/4)
#   specs/012-packages-cli/plan.md (Fases A-E, D1-D7, fronteira ADR-017)
#   specs/012-packages-cli/contracts/oracle-cli.md (mapa identidade 12 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-012-packages-cli.md (Q1-Q10 D1-D7, 2026-09-05)
#   specs/012-packages-cli/research.md (5 decisoes consolidadas)
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
# Medicao de exit code: via redirect + $? (nunca $? apos pipe — research Q4).
# Assercao FR-009 carrega guarda anti-vacuo: reprova se src/fkx_cli/ ausente
# (grep sem alvo seria verde vacuo — licao ADR-012).
#
# Decisoes pinadas verificadas 2026-09-05:
#   D1 typer==0.27.2 + rich==15.0.0 runtime do pacote, sem click (Q1-Q3)
#   D2 callback-raiz + flags + codigos 0/0/2/1 (CLARIFY 4/4)
#   D3 consome fkx_core, sem duplicar (Q7)
#   D4 sem subcomandos de dominio (Q10, Escada/Fase 1+)
#   D5 src/fkx_cli/ membro + py.typed; testes em tests/ via CliRunner (Q5/Q9)
#   D6 Rich com escape, locals off (Q6, Lei Zero)
#   D7 fronteira Q10 (6 pontos: 004/005/006/007/008/011, EXTRA_PKG admite core+cli)
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
  ["FR-001"]="typer+rich runtime packages/cli + hash lock, sem click"
  ["FR-002"]="membro UV + main+init+py.typed + scripts fkx"
  ["FR-003"]="--help exit 0 marcadores + sem-args ajuda"
  ["FR-004"]="--version exit 0 so X.Y.Z"
  ["FR-005"]="opcao invalida exit 2 stderr dica"
  ["FR-006"]="dep fkx-core sem duplicar + dominio exit 1"
  ["FR-007"]="ruff + mypy zeros src/fkx_cli"
  ["FR-008"]="testes tests/test_fkx_cli verdes CliRunner"
  ["FR-009"]="zero segredo + escape + locals off"
  ["FR-010"]="contrato: list 12 exit2 2x <5s"
  ["FR-011"]="manifest 12/12 + self-check f0-001..011"
  ["FR-012"]="README 012 hash + zero [ ] + vermelho-verde"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012"

PKGDIR="$ROOT/packages/cli"
SRCDIR="$PKGDIR/src/fkx_cli"
MAINPY="$SRCDIR/main.py"
INITPY="$SRCDIR/__init__.py"
PYPROJECT_PKG="$PKGDIR/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS012="$ROOT/specs/012-packages-cli/tasks.md"
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

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# Sonda comportamental unica (1 invocacao uv): help/versao/erro via CliRunner
# So executa quando o pacote existe; resultado em variaveis PROBE_*.
# =============================================================================
PROBE_RAN=0
PROBE_HELP_EXIT=""; PROBE_HELP_OUT=""
PROBE_NOARGS_EXIT=""
PROBE_VERSION_EXIT=""; PROBE_VERSION_OUT=""
PROBE_BAD_EXIT=""; PROBE_BAD_OUT=""
if [ -f "$MAINPY" ] && [ "$NESTED" != "1" ] && command -v uv >/dev/null 2>&1; then
  TMPD="$(mktemp -d)"
  # ADR-030 §4: COLUMNS pinado (determinismo de render; runner resolve ~0)
  COLUMNS=80
  export COLUMNS
  cat > "$TMPD/probe.py" <<'PYEOF'
from typer.testing import CliRunner
from fkx_cli.main import app
r = CliRunner()
h = r.invoke(app, ["--help"])
n = r.invoke(app, [])
v = r.invoke(app, ["--version"])
b = r.invoke(app, ["--nope"])
print("help_exit=" + str(h.exit_code))
print("help_out=" + h.output.replace("\n", "\\n"))
print("noargs_exit=" + str(n.exit_code))
print("version_exit=" + str(v.exit_code))
print("version_out=" + v.output.strip().replace("\n", "\\n"))
print("bad_exit=" + str(b.exit_code))
print("bad_out=" + b.output.replace("\n", "\\n"))
PYEOF
  if PROBE_RAW="$(uv run --no-sync -- python "$TMPD/probe.py" 2>/dev/null)"; then
    PROBE_RAN=1
    PROBE_HELP_EXIT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^help_exit=//p')"
    PROBE_HELP_OUT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^help_out=//p')"
    PROBE_NOARGS_EXIT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^noargs_exit=//p')"
    PROBE_VERSION_EXIT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^version_exit=//p')"
    PROBE_VERSION_OUT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^version_out=//p')"
    PROBE_BAD_EXIT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^bad_exit=//p')"
    PROBE_BAD_OUT="$(printf '%s' "$PROBE_RAW" | sed -n 's/^bad_out=//p')"
  fi
fi

# =============================================================================
# FR-001: typer+rich runtime em packages/cli + hash lock, sem click
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$PYPROJECT_PKG" ]; then
  FR1_OK=0; EVID1="${EVID1}packages/cli/pyproject.toml ausente; "
elif ! python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); deps=d.get("project",{}).get("dependencies",[]); assert "typer==0.27.2" in deps, deps; assert "rich==15.0.0" in deps, deps; assert not any("click" in x for x in deps), deps' "$PYPROJECT_PKG" 2>/dev/null; then
  FR1_OK=0; EVID1="${EVID1}dependencies sem typer==0.27.2+rich==15.0.0 ou com click (D1); "
fi
if [ ! -f "$UVLOCK" ]; then
  FR1_OK=0; EVID1="${EVID1}uv.lock ausente; "
else
  if ! grep -q 'name = "typer"' "$UVLOCK" 2>/dev/null; then FR1_OK=0; EVID1="${EVID1}lock sem typer; "; fi
  if ! grep -q 'name = "rich"' "$UVLOCK" 2>/dev/null; then FR1_OK=0; EVID1="${EVID1}lock sem rich; "; fi
  if ! grep -q 'name = "fkx-cli"' "$UVLOCK" 2>/dev/null; then FR1_OK=0; EVID1="${EVID1}lock sem fkx-cli; "; fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: membro UV + exatamente main+init+py.typed + [project.scripts] fkx
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -d "$PKGDIR" ]; then
  FR2_OK=0; EVID2="${EVID2}packages/cli/ ausente; "
else
  for m in __init__.py main.py py.typed; do
    if [ ! -f "$SRCDIR/$m" ]; then FR2_OK=0; EVID2="${EVID2}src/fkx_cli/$m ausente; "; fi
  done
  EXTRA=$(ls "$SRCDIR" 2>/dev/null | grep -v -x -e "__init__.py" -e "main.py" -e "py.typed" -e "__pycache__" | tr '\n' ' ' || true)
  if [ -n "$EXTRA" ]; then FR2_OK=0; EVID2="${EVID2}modulos alem do minimo: $EXTRA (D4); "; fi
  if [ -f "$PYPROJECT_PKG" ]; then
    if ! python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); s=d.get("project",{}).get("scripts",{}); assert s.get("fkx") == "fkx_cli.main:app", s' "$PYPROJECT_PKG" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}[project.scripts] fkx != fkx_cli.main:app (Q5); "
    fi
  fi
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: --help exit 0 com marcadores; sem-args equivale a ajuda
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$MAINPY" ]; then
  FR3_OK=0; EVID3="${EVID3}main.py ausente; "
else
  if ! grep -q "typer.Typer" "$MAINPY" 2>/dev/null; then FR3_OK=0; EVID3="${EVID3}typer.Typer ausente (callback-raiz); "; fi
  if ! grep -q "add_completion=False" "$MAINPY" 2>/dev/null; then FR3_OK=0; EVID3="${EVID3}add_completion=False ausente (data-model App); "; fi
  if [ "$PROBE_RAN" = "1" ]; then
    if [ "$PROBE_HELP_EXIT" != "0" ]; then FR3_OK=0; EVID3="${EVID3}--help exit $PROBE_HELP_EXIT != 0; "; fi
    case "$PROBE_HELP_OUT" in *--help*--version*|*--version*--help*) ;; *) FR3_OK=0; EVID3="${EVID3}--help sem marcadores --help/--version; " ;; esac
    if [ "$PROBE_NOARGS_EXIT" != "0" ]; then FR3_OK=0; EVID3="${EVID3}sem-args exit $PROBE_NOARGS_EXIT != 0 (CLARIFY); "; fi
  elif [ "$NESTED" != "1" ]; then
    FR3_OK=0; EVID3="${EVID3}sonda comportamental nao executou (sync?); "
  fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: --version exit 0 imprimindo so X.Y.Z == declarada
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$MAINPY" ]; then
  FR4_OK=0; EVID4="${EVID4}main.py ausente; "
else
  if ! grep -q "importlib.metadata\|from importlib import metadata" "$MAINPY" 2>/dev/null; then FR4_OK=0; EVID4="${EVID4}fonte unica importlib.metadata ausente (research); "; fi
  if grep -Eq '__version__[ ]*=' "$MAINPY" 2>/dev/null; then FR4_OK=0; EVID4="${EVID4}__version__ estatico proibido (duas fontes); "; fi
  if [ "$PROBE_RAN" = "1" ]; then
    if [ "$PROBE_VERSION_EXIT" != "0" ]; then FR4_OK=0; EVID4="${EVID4}--version exit $PROBE_VERSION_EXIT != 0; "; fi
    if ! printf '%s' "$PROBE_VERSION_OUT" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then FR4_OK=0; EVID4="${EVID4}--version nao e so X.Y.Z: $PROBE_VERSION_OUT; "; fi
    DECLARED=$(python3 -c 'import tomllib,sys; print(tomllib.load(open(sys.argv[1],"rb"))["project"]["version"])' "$PYPROJECT_PKG" 2>/dev/null || true)
    if [ -n "$DECLARED" ] && [ "$PROBE_VERSION_OUT" != "$DECLARED" ]; then FR4_OK=0; EVID4="${EVID4}versao $PROBE_VERSION_OUT != declarada $DECLARED; "; fi
  elif [ "$NESTED" != "1" ]; then
    FR4_OK=0; EVID4="${EVID4}sonda comportamental nao executou (sync?); "
  fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: opcao invalida exit 2 + stderr/dica --help
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$MAINPY" ]; then
  FR5_OK=0; EVID5="${EVID5}main.py ausente; "
elif [ "$PROBE_RAN" = "1" ]; then
  if [ "$PROBE_BAD_EXIT" != "2" ]; then FR5_OK=0; EVID5="${EVID5}--nope exit $PROBE_BAD_EXIT != 2; "; fi
  case "$PROBE_BAD_OUT" in *--help*) ;; *) FR5_OK=0; EVID5="${EVID5}erro sem dica de --help; " ;; esac
elif [ "$NESTED" != "1" ]; then
  FR5_OK=0; EVID5="${EVID5}sonda comportamental nao executou (sync?); "
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: dep fkx-core sem duplicar; dominio -> saida nomeada exit 1
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$PYPROJECT_PKG" ]; then
  FR6_OK=0; EVID6="${EVID6}packages/cli/pyproject.toml ausente; "
elif ! python3 -c 'import tomllib,sys; d=tomllib.load(open(sys.argv[1],"rb")); deps=d.get("project",{}).get("dependencies",[]); assert any(x.split("=")[0].strip().strip("\"") == "fkx-core" for x in deps), deps' "$PYPROJECT_PKG" 2>/dev/null; then
  FR6_OK=0; EVID6="${EVID6}dependencia de membro fkx-core ausente (D3); "
fi
if [ ! -f "$MAINPY" ]; then
  FR6_OK=0; EVID6="${EVID6}main.py ausente; "
else
  if grep -Eq 'class (Settings|KernelState|ErrorDetail)' "$SRCDIR"/*.py 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}duplicacao de tipos de fkx_core (D3); "; fi
  if ! grep -q "FkxError" "$MAINPY" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}FkxError nao consumido; "; fi
  if ! grep -Eq 'Exit\(1\)|exit\(1\)' "$MAINPY" 2>/dev/null; then FR6_OK=0; EVID6="${EVID6}mapeamento dominio->exit 1 ausente (CLARIFY); "; fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: ruff + mypy zeros sobre src/fkx_cli/
# =============================================================================
if [ ! -d "$SRCDIR" ]; then
  fail "FR-007" "${CANON[FR-007]}" "alta" "src/fkx_cli/ ausente"
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
# FR-008: testes tests/test_fkx_cli_*.py verdes (TDD)
# =============================================================================
if ! ls "$ROOT"/tests/test_fkx_cli_*.py >/dev/null 2>&1; then
  fail "FR-008" "${CANON[FR-008]}" "alta" "tests/test_fkx_cli_*.py ausentes (TDD, Q9)"
else
  if [ "$NESTED" != "1" ] && command -v uv >/dev/null 2>&1; then
    if uv run pytest -q "$ROOT"/tests/test_fkx_cli_*.py >/dev/null 2>&1; then
      pass "FR-008" "${CANON[FR-008]}"
    else
      fail "FR-008" "${CANON[FR-008]}" "alta" "pytest test_fkx_cli_* reprovou"
    fi
  else
    pass "FR-008" "${CANON[FR-008]}"
  fi
fi

# =============================================================================
# FR-009: zero segredo + escape + locals off (guarda anti-vacuo)
# =============================================================================
FR9_OK=1; EVID9=""
if [ ! -d "$SRCDIR" ]; then
  FR9_OK=0; EVID9="${EVID9}src/fkx_cli/ ausente (guarda anti-vacuo: grep sem alvo seria verde); "
else
  if grep -rniEq 'sk-[A-Za-z0-9]{8,}|api[_-]?secret[ ]*[:=]|passw(or)?d[ ]*[:=]|token[ ]*=' "$SRCDIR" 2>/dev/null; then FR9_OK=0; EVID9="${EVID9}literal de segredo no pacote (Lei Zero); "; fi
  if [ -f "$MAINPY" ] && ! grep -q "escape" "$MAINPY" 2>/dev/null; then FR9_OK=0; EVID9="${EVID9}escape() ausente em main.py (Q6); "; fi
  if [ -f "$MAINPY" ] && ! grep -q "pretty_exceptions_show_locals=False" "$MAINPY" 2>/dev/null; then FR9_OK=0; EVID9="${EVID9}pretty_exceptions_show_locals=False ausente (Lei Zero); "; fi
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
# FR-011: manifest 12/12 + self-check f0-001..011 (guarda)
# =============================================================================
FR11_OK=1; EVID11=""
if [ ! -f "$MANIFEST" ]; then
  FR11_OK=0; EVID11="${EVID11}manifest.sha256 ausente; "
else
  LINES=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)
  LINES=$(echo "$LINES" | tr -d '[:space:]')
  if [ -z "$LINES" ] || [ "$LINES" -lt 12 ] 2>/dev/null; then
    FR11_OK=0; EVID11="${EVID11}manifest com $LINES linhas (esperado >=12, piso); "
  elif ! sha256sum -c "$MANIFEST" >/dev/null 2>&1; then
    FR11_OK=0; EVID11="${EVID11}sha256sum -c reprovou; "
  fi
fi
if [ "$NESTED" != "1" ] && [ "$FR11_OK" = "1" ]; then
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FR11_OK=0; EVID11="${EVID11}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
fi
if [ "$FR11_OK" = "1" ]; then pass "FR-011" "${CANON[FR-011]}"; else fail "FR-011" "${CANON[FR-011]}" "alta" "$EVID11"; fi

# =============================================================================
# FR-012: README 012 hash + zero [ ] + vermelho-verde
# =============================================================================
FR12_OK=1; EVID12=""
if [ ! -f "$README_SPECS" ]; then
  FR12_OK=0; EVID12="${EVID12}specs/README.md ausente; "
elif ! grep -iq "012.*packages-cli.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR12_OK=0; EVID12="${EVID12}README sem \"012.*packages-cli.*✅.*hash\"; "
fi
if [ ! -f "$TASKS012" ]; then
  FR12_OK=0; EVID12="${EVID12}specs/012-packages-cli/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS012" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR12_OK=0; EVID12="${EVID12}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*012" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(packages).*012" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR12_OK=0; EVID12="${EVID12}par vermelho/verde 012 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
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
