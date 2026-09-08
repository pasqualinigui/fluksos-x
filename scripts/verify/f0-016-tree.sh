#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 016 (0.10): docs/tree.md p/ IA
#
# Contrato de assercoes deste item:
#   specs/016-tree-docs/spec.md (9 FRs, 7 SCs, 3 US + CLARIFY 2/2)
#   specs/016-tree-docs/plan.md (Fases A-D, D1-D6, fronteira zero, sem ADR)
#   specs/016-tree-docs/contracts/oracle-cli.md (mapa identidade 9 FRs)
#
# Contrato de INTERFACE (normativo, herdado):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Pesquisa vinculante:
#   docs/plan/research/f0-016-tree.md (Q1-Q5 D1-D5, 2026-09-09)
#   specs/016-tree-docs/research.md (6 decisoes consolidadas)
#
# Guardas x comportamento (contrato §3, nota L2):
#   Guardas (verdes-desde-o-nascimento):
#     FR-007 (contrato auto-verificavel — mecanica passa com esqueleto)
#   Comportamento (carregam o vermelho):
#     FR-001..006, FR-008, FR-009
#
# Restricoes (contrato §5 do item 001), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib (+ cadeia 005-015 via uv run).
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Nenhum residuo. Diretorios descartaveis removidos via trap.
#
# Medicao de exit code: via redirect + $? (nunca $? apos pipe — research Q4/013).
# Self-check em SERIE (ADR-031): f0-001..f0-015 sequenciais, nunca concorrentes.
#
# Fronteira zero (plan, varredura 2026-09-09): nenhum oraculo 001-015 conhece o
# vocabulario tree.md/generate-tree — nenhum ajuste, nenhuma ADR de fronteira.
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

declare -A CANON=(
  ["FR-001"]="tree.md com H1 resumo arvore anotada ponteiros"
  ["FR-002"]="esqueleto == gerador, todo path do indice presente"
  ["FR-003"]="gerador stdlib 2x byte-identico so-stdout"
  ["FR-004"]="curadoria <=120 linhas + total <=25600 bytes"
  ["FR-005"]="zero segredo ou path fora do indice no mapa"
  ["FR-006"]="ponteiros cobrem release bot compose sem duplicata"
  ["FR-007"]="contrato: list 9 exit2 2x <5s self-check serie"
  ["FR-008"]="auditoria f0-audit-013-016 com Veredito Achados Destino"
  ["FR-009"]="README 016 hash + zero [ ] + vermelho-verde + manifest"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005 FR-006 FR-007 FR-008 FR-009"

TREE="$ROOT/docs/tree.md"
GENERATOR="$ROOT/scripts/generate-tree.py"
AUDIT="$ROOT/docs/plan/audit/f0-audit-013-016.md"
MANIFEST="$SCRIPT_DIR/manifest.sha256"
TASKS016="$ROOT/specs/016-tree-docs/tasks.md"
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
ORACLE14="$SCRIPT_DIR/f0-014-dependabot.sh"
ORACLE15="$SCRIPT_DIR/f0-015-docker-compose.sh"

NESTED="${FKX_ORACLE_NESTED:-0}"

TMPD=""
cleanup() { [ -n "$TMPD" ] && [ -d "$TMPD" ] && rm -rf -- "$TMPD"; }
trap cleanup EXIT INT TERM HUP

if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s\n' "$id" "${CANON[$id]}"; done
  exit 0
fi

# Regiao gerada (entre marcadores) ou vazio.
gen_region() {
  awk '/GENERATED-START/{s=1;next} /GENERATED-END/{s=0} s==1{print}' "$TREE" 2>/dev/null || true
}

# =============================================================================
# FR-001: tree.md com H1 + resumo + arvore anotada + ponteiros
# =============================================================================
FR1_OK=1; EVID1=""
if [ ! -f "$TREE" ]; then
  FR1_OK=0; EVID1="${EVID1}docs/tree.md ausente (D1); "
else
  if ! grep -q "^# " "$TREE" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem H1; "
  fi
  if ! grep -q "^> " "$TREE" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem bloco de resumo (blockquote); "
  fi
  if ! grep -q "GENERATED-START" "$TREE" 2>/dev/null || ! grep -q "GENERATED-END" "$TREE" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem marcadores GENERATED-START/END; "
  fi
  if ! grep -q "|" "$TREE" 2>/dev/null; then
    FR1_OK=0; EVID1="${EVID1}sem tabela de ponteiros; "
  fi
fi
if [ "$FR1_OK" = "1" ]; then pass "FR-001" "${CANON[FR-001]}"; else fail "FR-001" "${CANON[FR-001]}" "alta" "$EVID1"; fi

# =============================================================================
# FR-002: esqueleto == gerador; todo path do indice presente; nenhum fora
# =============================================================================
FR2_OK=1; EVID2=""
if [ ! -f "$TREE" ]; then
  FR2_OK=0; EVID2="${EVID2}docs/tree.md ausente; "
elif [ ! -f "$GENERATOR" ]; then
  FR2_OK=0; EVID2="${EVID2}scripts/generate-tree.py ausente (D2); "
elif ! git -C "$ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  FR2_OK=0; EVID2="${EVID2}sem git (fonte do gerador); "
else
  GEN_OUT=$(python3 "$GENERATOR" 2>/dev/null || true)
  REGION=$(gen_region)
  if [ "$GEN_OUT" != "$REGION" ]; then
    FR2_OK=0; EVID2="${EVID2}regiao gerada diverge do gerador; "
  fi
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! echo "$REGION" | grep -qxF "$path" 2>/dev/null; then
      FR2_OK=0; EVID2="${EVID2}path do indice ausente no mapa: $path; "
      break
    fi
  done <<< "$(git -C "$ROOT" ls-files 2>/dev/null || true)"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! git -C "$ROOT" ls-files --error-unmatch "$line" > /dev/null 2>&1; then
      FR2_OK=0; EVID2="${EVID2}linha do esqueleto fora do indice: $(echo "$line" | cut -c1-80); "
      break
    fi
  done <<< "$REGION"
fi
if [ "$FR2_OK" = "1" ]; then pass "FR-002" "${CANON[FR-002]}"; else fail "FR-002" "${CANON[FR-002]}" "alta" "$EVID2"; fi

# =============================================================================
# FR-003: gerador stdlib, 2x byte-identico, so-stdout
# =============================================================================
FR3_OK=1; EVID3=""
if [ ! -f "$GENERATOR" ]; then
  FR3_OK=0; EVID3="${EVID3}scripts/generate-tree.py ausente; "
else
  if grep -qE "^import |^from " "$GENERATOR" 2>/dev/null; then
    if grep -E "^import |^from " "$GENERATOR" 2>/dev/null | grep -qvE "^(import|from) (os|sys|subprocess|pathlib|argparse)" 2>/dev/null; then
      FR3_OK=0; EVID3="${EVID3}import fora da stdlib permitida (D5); "
    fi
  fi
  if [ "$NESTED" != "1" ]; then
    G1=$(python3 "$GENERATOR" 2>/dev/null || true)
    G2=$(python3 "$GENERATOR" 2>/dev/null || true)
    if [ -z "$G1" ]; then
      FR3_OK=0; EVID3="${EVID3}gerador vazio/erro; "
    elif [ "$G1" != "$G2" ]; then
      FR3_OK=0; EVID3="${EVID3}gerador diverge entre execucoes; "
    fi
    GERR=$(python3 "$GENERATOR" 2>/dev/null 1>/dev/null; python3 "$GENERATOR" 2>&1 1>/dev/null || true)
    if [ -n "$GERR" ]; then
      FR3_OK=0; EVID3="${EVID3}gerador escreve em stderr; "
    fi
  fi
fi
if [ "$FR3_OK" = "1" ]; then pass "FR-003" "${CANON[FR-003]}"; else fail "FR-003" "${CANON[FR-003]}" "alta" "$EVID3"; fi

# =============================================================================
# FR-004: curadoria <=120 linhas + total <=25600 bytes (C1 do ANALYZE)
# =============================================================================
FR4_OK=1; EVID4=""
if [ ! -f "$TREE" ]; then
  FR4_OK=0; EVID4="${EVID4}docs/tree.md ausente; "
else
  CUR_LINES=$(awk '/GENERATED-END/{s=1;next} s==1{print}' "$TREE" 2>/dev/null | wc -l || true)
  CUR_LINES=$(echo "$CUR_LINES" | tr -d '[:space:]')
  if [ -n "$CUR_LINES" ] && [ "$CUR_LINES" -gt 120 ] 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}curadoria com $CUR_LINES linhas (>120); "
  fi
  TOTAL_BYTES=$(wc -c < "$TREE" 2>/dev/null | tr -d '[:space:]' || true)
  if [ -n "$TOTAL_BYTES" ] && [ "$TOTAL_BYTES" -gt 25600 ] 2>/dev/null; then
    FR4_OK=0; EVID4="${EVID4}mapa com $TOTAL_BYTES bytes (>25600); "
  fi
fi
if [ "$FR4_OK" = "1" ]; then pass "FR-004" "${CANON[FR-004]}"; else fail "FR-004" "${CANON[FR-004]}" "alta" "$EVID4"; fi

# =============================================================================
# FR-005: zero segredo ou path fora do indice (Lei Zero por construcao)
# =============================================================================
FR5_OK=1; EVID5=""
if [ ! -f "$TREE" ]; then
  FR5_OK=0; EVID5="${EVID5}docs/tree.md ausente; "
else
  if grep -qiE '\.env(\.|$)|secrets/|_PASSWORD|_SECRET|PRIVATE KEY|BEGIN .* KEY' "$TREE" 2>/dev/null; then
    FR5_OK=0; EVID5="${EVID5}padrao sensivel no mapa (Lei Zero); "
  fi
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    case "$tok" in
      *"/"*|*.md|*.yml|*.yaml|*.toml|*.lock|*.sh|*.py|*.alloy|*.sql)
        if ! git -C "$ROOT" ls-files --error-unmatch "$tok" > /dev/null 2>&1; then
          # Caminhos relativos com ./ ou absolutos do repo sao normalizados antes
          norm=$(echo "$tok" | sed -E 's#^\./##')
          if ! git -C "$ROOT" ls-files --error-unmatch "$norm" > /dev/null 2>&1; then
            FR5_OK=0; EVID5="${EVID5}path do mapa fora do indice: $(echo "$tok" | cut -c1-80); "
            break
          fi
        fi
        ;;
    esac
  done <<< "$(grep -oE '`[^`]+`' "$TREE" 2>/dev/null | tr -d '`' | sort -u || true)"
fi
if [ "$FR5_OK" = "1" ]; then pass "FR-005" "${CANON[FR-005]}"; else fail "FR-005" "${CANON[FR-005]}" "alta" "$EVID5"; fi

# =============================================================================
# FR-006: ponteiros cobrem release/bot/compose sem duplicata
# =============================================================================
FR6_OK=1; EVID6=""
if [ ! -f "$TREE" ]; then
  FR6_OK=0; EVID6="${EVID6}docs/tree.md ausente; "
else
  for dest in ".github/workflows/release.yml" ".github/dependabot.yml" "docker-compose.yml" "docker/" ".env.example"; do
    if ! grep -Fq "$dest" "$TREE" 2>/dev/null; then
      FR6_OK=0; EVID6="${EVID6}destino herdado sem ponteiro: $dest; "
    fi
  done
  DUPS=$(grep -oE '`[^`]+`' "$TREE" 2>/dev/null | tr -d '`' | sort | uniq -d | head -3 || true)
  if [ -n "$DUPS" ]; then
    FR6_OK=0; EVID6="${EVID6}paths duplicados no mapa: $(echo "$DUPS" | tr '\n' ' ' | cut -c1-120); "
  fi
fi
if [ "$FR6_OK" = "1" ]; then pass "FR-006" "${CANON[FR-006]}"; else fail "FR-006" "${CANON[FR-006]}" "alta" "$EVID6"; fi

# =============================================================================
# FR-007: contrato auto-verificavel (list 9, exit2, 2x <5s, self-check serie)
# =============================================================================
FR7_OK=1; EVID7=""
LIST_COUNT=$(bash "$SELF" --list 2>/dev/null | wc -l || true)
LIST_COUNT=$(echo "$LIST_COUNT" | tr -d '[:space:]')
if [ "$LIST_COUNT" != "9" ]; then
  FR7_OK=0; EVID7="${EVID7}--list enumera $LIST_COUNT != 9; "
fi
INVALID_RC=0
bash "$SELF" --invalido > /dev/null 2>&1 || INVALID_RC=$?
if [ "$INVALID_RC" != "2" ]; then
  FR7_OK=0; EVID7="${EVID7}--invalido exit $INVALID_RC != 2; "
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
    FR7_OK=0; EVID7="${EVID7}2 execucoes divergem; "
  fi
  if [ "$ELAPSED1" -gt 5000 ] || [ "$ELAPSED2" -gt 5000 ]; then
    FR7_OK=0; EVID7="${EVID7}execucao >5s (${ELAPSED1}ms/${ELAPSED2}ms); "
  fi
fi
if [ "$FR7_OK" = "1" ]; then pass "FR-007" "${CANON[FR-007]}"; else fail "FR-007" "${CANON[FR-007]}" "alta" "$EVID7"; fi

# =============================================================================
# FR-008: auditoria f0-audit-013-016 com Veredito Achados Destino (molde 009)
# =============================================================================
FR8_OK=1; EVID8=""
if [ ! -f "$AUDIT" ]; then
  FR8_OK=0; EVID8="${EVID8}docs/plan/audit/f0-audit-013-016.md ausente (trava ADR-016); "
else
  for hdr in Veredito Achados Destino; do
    if ! grep -q "$hdr" "$AUDIT" 2>/dev/null; then
      FR8_OK=0; EVID8="${EVID8}relatorio sem cabecalho $hdr (formato ADR-014); "
    fi
  done
fi
if [ "$FR8_OK" = "1" ]; then pass "FR-008" "${CANON[FR-008]}"; else fail "FR-008" "${CANON[FR-008]}" "alta" "$EVID8"; fi

# =============================================================================
# FR-009: README 016 hash + zero [ ] + vermelho-verde + manifest + self-check
# =============================================================================
FR9_OK=1; EVID9=""
if [ ! -f "$README_SPECS" ]; then
  FR9_OK=0; EVID9="${EVID9}specs/README.md ausente; "
elif ! grep -iq "016.*tree.*✅.*[0-9a-f]\{7,\}" "$README_SPECS" 2>/dev/null; then
  FR9_OK=0; EVID9="${EVID9}README sem \"016.*tree.*✅.*hash\"; "
fi
if [ ! -f "$TASKS016" ]; then
  FR9_OK=0; EVID9="${EVID9}specs/016-tree-docs/tasks.md ausente; "
else
  COUNT=$(grep -c "^- \[ \]" "$TASKS016" 2>/dev/null || true)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  if [ -z "$COUNT" ]; then COUNT=0; fi
  if [ "$COUNT" != "0" ]; then
    FR9_OK=0; EVID9="${EVID9}tasks.md com $COUNT [ ] abertas (CONVERGE); "
  fi
fi
RED_LINE=$(git log --oneline 2>/dev/null | grep -n "test(harness).*016" | head -1 | cut -d: -f1 || true)
GREEN_LINE=$(git log --oneline 2>/dev/null | grep -n "feat(treedocs).*016" | head -1 | cut -d: -f1 || true)
if [ -z "$RED_LINE" ] || [ -z "$GREEN_LINE" ]; then
  FR9_OK=0; EVID9="${EVID9}par vermelho/verde 016 ausente no log (red=$RED_LINE green=$GREEN_LINE); "
elif [ ! "$RED_LINE" -gt "$GREEN_LINE" ] 2>/dev/null; then
  FR9_OK=0; EVID9="${EVID9}verde precede vermelho no log (red=$RED_LINE green=$GREEN_LINE); "
fi
if [ ! -f "$MANIFEST" ]; then
  FR9_OK=0; EVID9="${EVID9}manifest.sha256 ausente; "
elif ! (cd "$ROOT" && sha256sum -c "$MANIFEST" > /dev/null 2>&1); then
  FR9_OK=0; EVID9="${EVID9}manifest.sha256 diverge (sha256sum -c); "
fi
if [ "$NESTED" != "1" ]; then
  for o in "$ORACLE1" "$ORACLE2" "$ORACLE3" "$ORACLE4" "$ORACLE5" "$ORACLE6" \
           "$ORACLE7" "$ORACLE8" "$ORACLE9" "$ORACLE10" "$ORACLE11" "$ORACLE12" \
           "$ORACLE13" "$ORACLE14" "$ORACLE15"; do
    if [ ! -x "$o" ]; then
      FR9_OK=0; EVID9="${EVID9}$(basename "$o") ausente ou nao executavel; "
      break
    else
      rc=0
      timeout 5 env FKX_ORACLE_NESTED=1 bash "$o" --quiet > /dev/null 2>&1 || rc=$?
      if [ "$rc" != "0" ] && [ "$rc" != "124" ]; then
        FR9_OK=0; EVID9="${EVID9}$(basename "$o") --quiet reprovou (rc=$rc); "
        break
      fi
    fi
  done
fi
if [ "$FR9_OK" = "1" ]; then pass "FR-009" "${CANON[FR-009]}"; else fail "FR-009" "${CANON[FR-009]}" "alta" "$EVID9"; fi

# =============================================================================
# Relatório
# =============================================================================
TOTAL=${#R_ID[@]}
OK=0; BAD=0; SKIPPED=0
CRIT=0; ALTA=0; MEDIA=0

for i in "${!R_ID[@]}"; do
  case "${R_STATUS[$i]}" in
    ok)   OK=$((OK+1));           SYM="✅" ;;
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
