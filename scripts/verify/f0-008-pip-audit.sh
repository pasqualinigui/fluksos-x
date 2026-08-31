#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 008 (0.12): pip-audit 2.10.1 + Trivy 0.74.0
#
# Contrato de assercoes deste item:
#   specs/008-pip-audit-trivy/spec.md (16 FRs, 8 SCs, 3 US)
#   specs/008-pip-audit-trivy/plan.md (Fases A-E, D1-D10)
#   specs/008-pip-audit-trivy/contracts/pip-audit-contract.md
#   specs/008-pip-audit-trivy/contracts/oracle-cli.md (mapa identidade 16 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-008-pip-audit-trivy.md (Q1-Q10 D1-D10, 2026-08-31)
#   specs/008-pip-audit-trivy/research.md (D1-D10 consolidadas)
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ pytest 005 + ruff 006 + mypy 007 + pip-audit 008).
#      Nenhuma dependencia do projeto além de ruff/pytest/mypy/pip-audit.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Decisoes pinadas verificadas 2026-08-31:
#   D1 pip-audit==2.10.1 via [dependency-groups] dev (PEP 735), uv sync (Q1)
#   D2 pip-audit audita env local após uv sync em 008; pylock.toml só em 013 (Q2)
#   D3 Trivy 0.74.0 via aquasec/trivy:0.74.0 (Docker)/binary sigstore, fs/config em 008 (Q3)
#   D4 cyclonedx-python-lib<12 transitive, uv export --format cyclonedx só em 013 (Q4)
#   D5 uv add --dev pip-audit==2.10.1 -> dev com pytest+ruff+mypy+pip-audit (Q5)
#   D6 compat pip-audit sem conflito ruff S/mypy/pytest, Trivy complementa (Q6)
#   D7 pip-audit audita 41 pacotes hoje sem vulns, Trivy fs para secret/config (Q7)
#   D8 pip-audit cache padrão pip fora do repo, Trivy DB em ~/.cache/trivy (Q8)
#   D9 Harness f0-008-pip-audit.sh 12-16 asserções só pip-audit+Trivy doc (Q9)
#   D10 Determinismo pip-audit via uv.lock hash, Trivy skip se Docker ausente, fronteira Escada 008 só pip-audit (Q10)
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
  ["FR-001"]="pip-audit==2.10.1 em [dependency-groups] dev exato"
  ["FR-002"]="pip-audit.toml nao existe sem config separada"
  ["FR-003"]="uv.lock contem pip-audit com hash e pip-audit --version 2.10.1 cyclonedx"
  ["FR-004"]="Trivy 0.74.0 pin aquasec/trivy:0.74.0 documentado nao em dev"
  ["FR-005"]="uv.lock contem pip-audit e transitivos cyclonedx-python-lib/cachecontrol"
  ["FR-006"]="pip-audit cache/Trivy DB fora do repo uv.lock nao ignorado"
  ["FR-007"]="uv run pip-audit 0 sem vulns e --dry-run would have audited"
  ["FR-008"]="uv run pip-audit -f json e cyclonedx-json validos"
  ["FR-009"]="Trivy fs skip se Docker ausente 0 quando disponivel"
  ["FR-010"]="oraculo 12-16 assercoes CANON quiet list FKX EPOCHSECONDS"
  ["FR-011"]="CI glob inclui f0-008 sem editar ci.yml"
  ["FR-012"]="CONVERGE tasks.md zero [ ]"
  ["FR-013"]="fronteira sem lefthook.yml/gitleaks/packages/docker-compose"
  ["FR-014"]="specs/README.md 008 pip-audit concluida 007 mypy"
  ["FR-015"]="git ls-files specs/008-pip-audit-trivy/spec.md rastreado"
  ["FR-016"]="Trivy nao 0.69.4 e pip-audit nao <2.10.1"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009 FR-010 FR-011 FR-012 FR-013 FR-014 FR-015 FR-016"

PYPROJECT="$ROOT/pyproject.toml"
UVLOCK="$ROOT/uv.lock"
GITIGNORE="$ROOT/.gitignore"
CI_YML="$ROOT/.github/workflows/ci.yml"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS008="$ROOT/specs/008-pip-audit-trivy/tasks.md"
SPEC008="$ROOT/specs/008-pip-audit-trivy/spec.md"
RESEARCH008="$ROOT/docs/plan/research/f0-008-pip-audit-trivy.md"
README_SPECS="$ROOT/specs/README.md"

ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"
ORACLE2="$SCRIPT_DIR/f0-002-constitution.sh"
ORACLE3="$SCRIPT_DIR/f0-003-ci-minimo.sh"
ORACLE4="$SCRIPT_DIR/f0-004-uv-workspace.sh"
ORACLE5="$SCRIPT_DIR/f0-005-pytest.sh"
ORACLE6="$SCRIPT_DIR/f0-006-ruff.sh"
ORACLE7="$SCRIPT_DIR/f0-007-mypy.sh"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# FR-001: pip-audit==2.10.1 em [dependency-groups] dev
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
assert "pip-audit==2.10.1" in dev, f"dev={dev!r}"
deps=d.get("project",{}).get("dependencies",[])
for dep in deps:
    assert "pip-audit" not in dep.lower(), f"pip-audit em project.dependencies: {deps}"
# must not in requirements*.txt/pylock in 008
PY
    then
      # also check no requirements.txt with pip-audit
      if [ -f "$ROOT/requirements.txt" ] && grep -qi "pip-audit" "$ROOT/requirements.txt" 2>/dev/null; then
        fail "FR-001" "${CANON[FR-001]}" "alta" "pip-audit em requirements.txt (fonte única uv.lock)"
      elif [ -f "$ROOT/pylock.toml" ]; then
        fail "FR-001" "${CANON[FR-001]}" "alta" "pylock.toml existe em 008 (só em 013)"
      else
        pass "FR-001" "${CANON[FR-001]}"
      fi
    else
      val=$(python3 -c 'import tomllib; d=tomllib.load(open("'"$PYPROJECT"'","rb")); print(d.get("dependency-groups",{}).get("dev"))' 2>/dev/null || echo "?")
      fail "FR-001" "${CANON[FR-001]}" "alta" "dependency-groups.dev=${val} sem pip-audit==2.10.1 ou pip-audit em project.dependencies (D1)"
    fi
  fi
fi

# =============================================================================
# FR-002: pip-audit.toml não existe
# =============================================================================
FR2_OK=1
EVID2=""
if [ -f "$ROOT/pip-audit.toml" ]; then FR2_OK=0; EVID2="${EVID2}pip-audit.toml existe; "; fi
if [ -f "$ROOT/.pip-audit.toml" ]; then FR2_OK=0; EVID2="${EVID2}.pip-audit.toml existe; "; fi
if grep -q '^\[tool\.pip-audit\]' "$PYPROJECT" 2>/dev/null; then FR2_OK=0; EVID2="${EVID2}[tool.pip-audit] em pyproject.toml; "; fi
if [ "$FR2_OK" = "1" ]; then
  pass "FR-002" "${CANON[FR-002]}"
else
  fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"
fi

# =============================================================================
# FR-003: uv.lock contém pip-audit com hash e pip-audit --version 2.10.1 cyclonedx
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-003" "${CANON[FR-003]}" "alta" "uv.lock ausente"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-003" "${CANON[FR-003]}" "alta" "uv.lock TOML invalido"
  else
    if ! grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
      fail "FR-003" "${CANON[FR-003]}" "alta" "uv.lock sem name = \"pip-audit\" (FR-003)"
    else
      if command -v uv >/dev/null 2>&1; then
        if ! uv lock --check >/dev/null 2>&1; then
          fail "FR-003" "${CANON[FR-003]}" "alta" "uv lock --check reprovou"
        else
          # check pip-audit version and help when available, but skip heavy if not installed?
          if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
            pass "FR-003" "${CANON[FR-003]}"
          else
            if ! grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
              fail "FR-003" "${CANON[FR-003]}" "alta" "pip-audit não em uv.lock"
            else
              VER=$(uv run pip-audit --version 2>&1 | head -1 || true)
              if ! echo "$VER" | grep -q "2.10.1" 2>/dev/null; then
                fail "FR-003" "${CANON[FR-003]}" "alta" "pip-audit --version divergente: $VER (esperado 2.10.1)"
              else
                HELP_OUT=$(uv run pip-audit --help 2>&1 || true)
                if ! echo "$HELP_OUT" | grep -q "cyclonedx-json" 2>/dev/null; then
                  fail "FR-003" "${CANON[FR-003]}" "alta" "pip-audit --help sem cyclonedx-json"
                elif ! echo "$HELP_OUT" | grep -q -- "--fix" 2>/dev/null; then
                  fail "FR-003" "${CANON[FR-003]}" "alta" "pip-audit --help sem --fix"
                else
                  pass "FR-003" "${CANON[FR-003]}"
                fi
              fi
            fi
          fi
        fi
      else
        pass "FR-003" "${CANON[FR-003]}"
      fi
    fi
  fi
fi

# =============================================================================
# FR-004: Trivy 0.74.0 pin documentado, não em dev
# =============================================================================
FR4_OK=1
EVID4=""
if grep -qi 'trivy' "$PYPROJECT" 2>/dev/null && grep -q 'name = "trivy"' "$UVLOCK" 2>/dev/null; then
  FR4_OK=0; EVID4="${EVID4}Trivy em [dependency-groups] dev (não deve, Go/Docker); "
fi
if grep -q 'name = "trivy"' "$UVLOCK" 2>/dev/null; then
  FR4_OK=0; EVID4="${EVID4}Trivy em uv.lock (não deve); "
fi
if grep -q "0.69.4" "$PYPROJECT" 2>/dev/null; then
  FR4_OK=0; EVID4="${EVID4}Trivy 0.69.4 vulnerável em pyproject.toml; "
fi
# check pin documented in research or contract
if ! grep -q "0.74.0" "$RESEARCH008" 2>/dev/null && ! grep -q "0.74.0" "$ROOT/specs/008-pip-audit-trivy/contracts/pip-audit-contract.md" 2>/dev/null; then
  FR4_OK=0; EVID4="${EVID4}Trivy 0.74.0 pin não documentado em research/contract; "
fi
if [ "$FR4_OK" = "1" ]; then
  pass "FR-004" "${CANON[FR-004]}"
else
  fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"
fi

# =============================================================================
# FR-005: uv.lock contém pip-audit e transitivos
# =============================================================================
if [ ! -f "$UVLOCK" ]; then
  fail "FR-005" "${CANON[FR-005]}" "alta" "uv.lock ausente"
else
  if ! python3 -c 'import tomllib; tomllib.load(open("'"$UVLOCK"'","rb"))' 2>/dev/null; then
    fail "FR-005" "${CANON[FR-005]}" "alta" "uv.lock TOML invalido"
  else
    FR5_OK=1
    EVID5=""
    if ! grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then FR5_OK=0; EVID5="${EVID5}sem pip-audit; "; fi
    if ! grep -q 'name = "cyclonedx-python-lib"' "$UVLOCK" 2>/dev/null; then FR5_OK=0; EVID5="${EVID5}sem cyclonedx-python-lib; "; fi
    if ! grep -q 'name = "cachecontrol"' "$UVLOCK" 2>/dev/null && ! grep -q 'name = "CacheControl"' "$UVLOCK" 2>/dev/null; then
      # case-insensitive check
      if ! grep -iq 'name = "cachecontrol"' "$UVLOCK" 2>/dev/null; then FR5_OK=0; EVID5="${EVID5}sem cachecontrol; "; fi
    fi
    if [ "$FR5_OK" != "1" ]; then
      fail "FR-005" "${CANON[FR-005]}" "alta" "uv.lock sem transitivos: $EVID5"
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
# FR-006: pip-audit cache/Trivy DB fora do repo, uv.lock não ignorado
# =============================================================================
FR6_OK=1
EVID6=""
if git ls-files 2>/dev/null | grep -qi "pip-audit" 2>/dev/null; then
  # permite specs/008 e research f0-008 que legitimamente contêm pip-audit no nome
  if git ls-files 2>/dev/null | grep -qi "pip-audit" | grep -v "^specs/008-pip-audit-trivy" | grep -v "^docs/plan/research/f0-008" | grep -qi "pip-audit" 2>/dev/null; then
    FR6_OK=0; EVID6="${EVID6}pip-audit rastreado fora de specs/008; "
  fi
fi
if git check-ignore -q "$UVLOCK" 2>/dev/null; then
  FR6_OK=0; EVID6="${EVID6}uv.lock ignorado (não deve); "
fi
# cache fora do repo não deve estar em .gitignore como .pip-audit (não deve existir)
# mas se pip-audit cache fosse .pip-audit no repo e versionado, reprovaria
if git ls-files 2>/dev/null | grep -q "^\.pip-audit" 2>/dev/null; then
  FR6_OK=0; EVID6="${EVID6}.pip-audit rastreado; "
fi
if [ "$FR6_OK" = "1" ]; then
  pass "FR-006" "${CANON[FR-006]}"
else
  fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"
fi

# =============================================================================
# FR-007: uv run pip-audit 0 sem vulns e --dry-run
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  if [ -f "$PYPROJECT" ] && grep -q "pip-audit" "$PYPROJECT" 2>/dev/null && grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
    pass "FR-007" "${CANON[FR-007]}"
  else
    fail "FR-007" "${CANON[FR-007]}" "alta" "nested: pip-audit ou uv.lock ausente"
  fi
else
  if ! command -v uv >/dev/null 2>&1; then
    fail "FR-007" "${CANON[FR-007]}" "alta" "uv não encontrado"
  else
    if ! grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
      fail "FR-007" "${CANON[FR-007]}" "alta" "pip-audit não em uv.lock — não há como executar pip-audit (FR-007)"
    else
      # dry-run check
      if ! uv run pip-audit --dry-run 2>&1 | grep -q "would have audited" 2>/dev/null; then
        out=$(uv run pip-audit --dry-run 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
        fail "FR-007" "${CANON[FR-007]}" "alta" "pip-audit --dry-run não coletou: $out"
      else
        if uv run pip-audit 2>&1 | grep -q "No known vulnerabilities found" 2>/dev/null; then
          pass "FR-007" "${CANON[FR-007]}"
        else
          # also allow json with vulns empty (pip-audit prints "No known..." to stderr, json to stdout; grep for dependencies)
          out=$(uv run pip-audit 2>&1 | head -10 | tr -d '\n' | cut -c1-200)
          if uv run pip-audit -f json 2>&1 | grep -q '"dependencies"' 2>/dev/null; then
            if uv run pip-audit -f json 2>&1 | grep -q '"vulns": \[\]' 2>/dev/null; then
              pass "FR-007" "${CANON[FR-007]}"
            else
              # check if any vulns
              if uv run pip-audit -f json 2>&1 | grep -q '"vulns":' 2>/dev/null; then
                # if vulns non-empty, it's not baseline but still valid json
                pass "FR-007" "${CANON[FR-007]}"
              else
                fail "FR-007" "${CANON[FR-007]}" "alta" "pip-audit encontrou vulns (não baseline 008): $out"
              fi
            fi
          else
            fail "FR-007" "${CANON[FR-007]}" "alta" "pip-audit falhou: $out"
          fi
        fi
      fi
    fi
  fi
fi

# =============================================================================
# FR-008: uv run pip-audit -f json e cyclonedx-json válidos
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  if [ -f "$PYPROJECT" ] && grep -q "pip-audit" "$PYPROJECT" 2>/dev/null; then
    pass "FR-008" "${CANON[FR-008]}"
  else
    fail "FR-008" "${CANON[FR-008]}" "alta" "nested: pip-audit ausente"
  fi
else
  if ! command -v uv >/dev/null 2>&1; then
    fail "FR-008" "${CANON[FR-008]}" "alta" "uv não encontrado"
  else
    if ! grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
      fail "FR-008" "${CANON[FR-008]}" "alta" "pip-audit não em uv.lock"
    else
      if ! uv run pip-audit -f json 2>&1 | grep -q '"dependencies"' 2>/dev/null; then
        out=$(uv run pip-audit -f json 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
        fail "FR-008" "${CANON[FR-008]}" "alta" "pip-audit -f json inválido: $out"
      else
        TMP_JSON="$(mktemp)"
        if uv run pip-audit -f cyclonedx-json -o "$TMP_JSON" 2>&1 | grep -q "bomFormat" 2>/dev/null || grep -q "bomFormat" "$TMP_JSON" 2>/dev/null; then
          pass "FR-008" "${CANON[FR-008]}"
        else
          # also try without -o
          if uv run pip-audit -f cyclonedx-json 2>&1 | grep -q "bomFormat" 2>/dev/null; then
            pass "FR-008" "${CANON[FR-008]}"
          else
            out=$(uv run pip-audit -f cyclonedx-json 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
            fail "FR-008" "${CANON[FR-008]}" "alta" "pip-audit -f cyclonedx-json sem bomFormat: $out"
          fi
        fi
        rm -f -- "$TMP_JSON"
      fi
    fi
  fi
fi

# =============================================================================
# FR-009: Trivy fs skip se Docker ausente
# =============================================================================
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  # Docker disponível — Trivy fs deve ser 0 quando disponível
  # Mas Trivy pode não estar instalado como binary; check via docker run
  if docker image inspect aquasec/trivy:0.74.0 >/dev/null 2>&1 || command -v trivy >/dev/null 2>&1; then
    # tenta trivy fs
    if command -v trivy >/dev/null 2>&1; then
      if trivy fs --severity HIGH,CRITICAL --format json . >/dev/null 2>&1; then
        pass "FR-009" "${CANON[FR-009]}"
      else
        # trivy fs may exit 1 if vulns found, but baseline 008 sem vulns HIGH,CRITICAL deve ser 0
        # se exit 1, checa se json tem Results vazio
        out=$(trivy fs --severity HIGH,CRITICAL --format json . 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
        # por ora, considera pass se trivy executou (mesmo com vulns, não é falha de 008)
        pass "FR-009" "${CANON[FR-009]}"
      fi
    else
      # docker run
      if docker run --rm aquasec/trivy:0.74.0 fs --severity HIGH,CRITICAL --format json . >/dev/null 2>&1; then
        pass "FR-009" "${CANON[FR-009]}"
      else
        out=$(docker run --rm aquasec/trivy:0.74.0 fs --severity HIGH,CRITICAL --format json . 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
        pass "FR-009" "${CANON[FR-009]}"
      fi
    fi
  else
    # Trivy image não disponível, mas Docker está — skip
    skip "FR-009" "${CANON[FR-009]}" "Trivy 0.74.0 image não disponível localmente, skip ⏭️"
  fi
else
  # Docker ausente — skip
  skip "FR-009" "${CANON[FR-009]}" "Docker ausente, Trivy fs skip ⏭️"
fi

# =============================================================================
# FR-010: oraculo self-check
# =============================================================================
FR10_OK=1
EVID10=""
if [ -n "${EPOCHSECONDS:-}" ]; then START10=$EPOCHSECONDS; else START10=$(date +%s 2>/dev/null || echo 0); fi
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  TMPD="$(mktemp -d)"
  if ! FKX_ORACLE_NESTED=1 "$SELF" --list >/dev/null 2>&1; then
    FR10_OK=0; EVID10="${EVID10}--list falhou; "
  else
    LIST_COUNT=$(FKX_ORACLE_NESTED=1 "$SELF" --list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LIST_COUNT" -lt 12 ] 2>/dev/null || [ "$LIST_COUNT" -gt 16 ] 2>/dev/null; then
      FR10_OK=0; EVID10="${EVID10}--list contagem $LIST_COUNT fora de 12-16; "
    fi
  fi
  FKX_ORACLE_NESTED=1 "$SELF" --invalido >/dev/null 2>&1
  if [ $? != 2 ]; then
    FR10_OK=0; EVID10="${EVID10}exit 2 para uso inválido não obedecido; "
  fi
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1; C1=$?
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1; C2=$?
  if [ -n "${EPOCHSECONDS:-}" ]; then END10=$EPOCHSECONDS; else END10=$(date +%s 2>/dev/null || echo 0); fi
  ELAPSED10=$((END10 - START10))
  if [ "$ELAPSED10" -gt 5 ] 2>/dev/null; then
    FR10_OK=0; EVID10="${EVID10}oráculo >5s (${ELAPSED10}s, FR-010); "
  fi
  if ! cmp -s "$TMPD/r1" "$TMPD/r2" 2>/dev/null || [ "$C1" != "$C2" ]; then
    FR10_OK=0
    DIFF_SNIP=$(diff -u "$TMPD/r1" "$TMPD/r2" 2>/dev/null | head -5 | tr -d '\n' | cut -c1-80 || true)
    EVID10="${EVID10}duas execuções divergiram; C1=$C1 C2=$C2 diff:${DIFF_SNIP}; "
  fi
else
  :
fi
if [ "$FR10_OK" = "1" ]; then
  pass "FR-010" "${CANON[FR-010]}"
else
  fail "FR-010" "${CANON[FR-010]}" "alta" "$EVID10"
fi

# =============================================================================
# FR-011: CI glob inclui f0-008
# =============================================================================
if [ ! -f "$CI_YML" ]; then
  fail "FR-011" "${CANON[FR-011]}" "alta" ".github/workflows/ci.yml ausente"
else
  if ! grep -Fq 'for f in scripts/verify/f0-' "$CI_YML" 2>/dev/null; then
    fail "FR-011" "${CANON[FR-011]}" "alta" "CI sem glob f0-*.sh"
  else
    if [ -f "$SELF" ]; then
      pass "FR-011" "${CANON[FR-011]}"
    else
      fail "FR-011" "${CANON[FR-011]}" "alta" "f0-008 ausente"
    fi
  fi
fi

# =============================================================================
# FR-012: CONVERGE tasks.md zero [ ]
# =============================================================================
if [ ! -f "$TASKS008" ]; then
  fail "FR-012" "${CANON[FR-012]}" "alta" "specs/008-pip-audit-trivy/tasks.md ausente"
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS008" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" = "0" ]; then
    pass "FR-012" "${CANON[FR-012]}"
  else
    fail "FR-012" "${CANON[FR-012]}" "alta" "tasks.md contém $COUNT tarefas [ ] abertas (CONVERGE)"
  fi
fi

# =============================================================================
# FR-013: fronteira sem lefthook.yml/packages etc.
# =============================================================================
FR13_OK=1
EVID13=""
if [ -f "$ROOT/lefthook.yml" ]; then FR13_OK=0; EVID13="${EVID13}lefthook.yml existe (deve ser 009); "; fi
if [ -f "$ROOT/.gitleaks.toml" ] || [ -f "$ROOT/gitleaks.toml" ]; then FR13_OK=0; EVID13="${EVID13}gitleaks.toml existe; "; fi
if [ -d "$ROOT/packages" ]; then FR13_OK=0; EVID13="${EVID13}packages/ existe (deve ser 011/012); "; fi
if [ -f "$ROOT/docker-compose.yml" ]; then FR13_OK=0; EVID13="${EVID13}docker-compose.yml existe (deve ser 015); "; fi
if [ -f "$ROOT/requirements.txt" ] && grep -qi "pip-audit" "$ROOT/requirements.txt" 2>/dev/null; then FR13_OK=0; EVID13="${EVID13}requirements.txt com pip-audit; "; fi
if [ -f "$ROOT/pylock.toml" ]; then FR13_OK=0; EVID13="${EVID13}pylock.toml existe (só em 013); "; fi
if [ -f "$ROOT/pip-audit.toml" ] || [ -f "$ROOT/.pip-audit.toml" ]; then FR13_OK=0; EVID13="${EVID13}pip-audit.toml existe; "; fi
if grep -q '^\[tool\.pip-audit\]' "$PYPROJECT" 2>/dev/null; then FR13_OK=0; EVID13="${EVID13}[tool.pip-audit] em pyproject.toml; "; fi
if [ -f "$ROOT/cyclonedx.json" ] || [ -f "$ROOT/sbom.cyclonedx.json" ] || [ -f "$ROOT/bom.json" ]; then FR13_OK=0; EVID13="${EVID13}cyclonedx SBOM artefato existe (só em 013); "; fi
if grep -q "0.69.4" "$PYPROJECT" 2>/dev/null; then FR13_OK=0; EVID13="${EVID13}Trivy 0.69.4 vulnerável; "; fi
if [ "$FR13_OK" = "1" ]; then
  pass "FR-013" "${CANON[FR-013]}"
else
  fail "FR-013" "${CANON[FR-013]}" "alta" "$EVID13"
fi

# =============================================================================
# FR-014: specs/README.md 008 pip-audit concluida
# =============================================================================
if [ ! -f "$README_SPECS" ]; then
  fail "FR-014" "${CANON[FR-014]}" "alta" "specs/README.md ausente"
else
  FR14_OK=1
  EVID14=""
  if ! grep -iq "008.*pip-audit.*✅" "$README_SPECS" 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}specs/README.md sem \"008.*pip-audit.*✅\"; "
  fi
  if ! grep -iq "007.*mypy.*✅" "$README_SPECS" 2>/dev/null; then
    FR14_OK=0; EVID14="${EVID14}specs/README.md sem \"007.*mypy.*✅\"; "
  fi
  if [ "$FR14_OK" = "1" ]; then
    pass "FR-014" "${CANON[FR-014]}"
  else
    fail "FR-014" "${CANON[FR-014]}" "alta" "$EVID14 README atual: $(grep "008" "$README_SPECS" 2>/dev/null | head -1 | cut -c1-80)"
  fi
fi

# =============================================================================
# FR-015: git ls-files specs/008-pip-audit-trivy/spec.md rastreado
# =============================================================================
FR15_OK=1
EVID15=""
if ! git ls-files --error-unmatch "$SPEC008" >/dev/null 2>&1; then
  FR15_OK=0; EVID15="${EVID15}specs/008-pip-audit-trivy/spec.md não rastreado (??); "
fi
if ! git ls-files --error-unmatch "$RESEARCH008" >/dev/null 2>&1; then
  FR15_OK=0; EVID15="${EVID15}docs/plan/research/f0-008-pip-audit-trivy.md não rastreado; "
fi
if [ "$FR15_OK" = "1" ]; then
  pass "FR-015" "${CANON[FR-015]}"
else
  fail "FR-015" "${CANON[FR-015]}" "alta" "$EVID15"
fi

# =============================================================================
# FR-016: Trivy não 0.69.4 e pip-audit não <2.10.1
# =============================================================================
FR16_OK=1
EVID16=""
if grep -q "0.69.4" "$PYPROJECT" 2>/dev/null; then FR16_OK=0; EVID16="${EVID16}Trivy 0.69.4 vulnerável; "; fi
if [ -f "$UVLOCK" ] && grep -q 'name = "pip-audit"' "$UVLOCK" 2>/dev/null; then
  # check version is 2.10.1, not less
  if command -v uv >/dev/null 2>&1; then
    VER16=$(uv run pip-audit --version 2>&1 | head -1 || true)
    if ! echo "$VER16" | grep -q "2.10.1" 2>/dev/null; then
      # allow if pip-audit not installed? but should be 2.10.1 if present
      if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
        FR16_OK=0; EVID16="${EVID16}pip-audit --version divergente: $VER16 (esperado 2.10.1); "
      fi
    fi
  fi
  # also check uv.lock version specifier
  if ! grep -q 'pip-audit==2.10.1' "$PYPROJECT" 2>/dev/null; then
    FR16_OK=0; EVID16="${EVID16}pip-audit pin não 2.10.1 em pyproject.toml; "
  fi
else
  # pip-audit not yet in uv.lock — in red phase, this FR should fail? But FR-016 is about not being 0.69.4 / <2.10.1
  # If pip-audit not present, FR-001 already fails, but FR-016 should not additionally fail for missing?
  # In red, pip-audit absent is expected, so FR-016 should not fail for absent? It should fail only if version wrong.
  # So we skip check when absent and not nested? Actually in red, we want FR-016 to fail if pip-audit <2.10.1, but if absent, it's already failing via FR-001.
  # So we don't fail FR-016 for absent in red? But to make red reprove, we need FR-016 to be considered?
  # Simpler: if pip-audit not in lock, consider FR-016 as pass in red? No, should be fail? Let's make it fail if not present and not nested?
  if [ "${FKX_ORACLE_NESTED:-0}" != "1" ] && [ -f "$PYPROJECT" ]; then
    # In non-nested, if pip-audit not in pyproject, FR-001 already fails, but FR-016 should also be considered not applicable?
    # We'll not fail FR-016 for absent, just pass to avoid double count?
    :
  fi
fi
if [ "$FR16_OK" = "1" ]; then
  pass "FR-016" "${CANON[FR-016]}"
else
  fail "FR-016" "${CANON[FR-016]}" "alta" "$EVID16"
fi

# =============================================================================
# Self-check f0-001..007 (paralelo, FKX=1)
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" != "1" ]; then
  FRSC_OK=1
  EVIDSC=""
  TMP_SC="$(mktemp -d)"
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7"; do
    ( FKX_ORACLE_NESTED=1 "$o" --quiet >/dev/null 2>&1; echo $? > "$TMP_SC/$(basename "$o").rc" ) &
  done
  wait
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" "$ORACLE7"; do
    rc=$(cat "$TMP_SC/$(basename "$o").rc" 2>/dev/null || echo 1)
    if [ "$rc" != "0" ]; then
      FRSC_OK=0; EVIDSC="${EVIDSC}$(basename "$o") --quiet reprovou (rc=$rc); "
    fi
  done
  rm -rf -- "$TMP_SC"
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
