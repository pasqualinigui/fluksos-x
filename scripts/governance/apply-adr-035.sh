#!/usr/bin/env bash
# =============================================================================
# Aplica os ajustes da ADR-035 — "O merge pertence ao servidor, nao ao agente"
#
# O QUE ESTE SCRIPT E
#   Metade servidora da ADR-035, no molde do checklist FR-014 do item 013: config
#   que nao vive em arquivo, aplicada por quem tem o token. Ele NAO e oraculo --
#   nao entra em scripts/verify/ nem no manifest.sha256.
#
# POR QUE E SCRIPT, E NAO PROSA
#   Prosa de "va em settings e marque a caixa" nao tem codigo de saida. Isto tem:
#   0 = servidor no estado da ADR-035; 1 = divergente.
#
# IDEMPOTENTE
#   Rodar duas vezes nao muda nada na segunda. --check nao escreve.
#
# A ARMADILHA QUE ELE EVITA (ADR-035 §3)
#   PUT /branches/{b}/protection SUBSTITUI o objeto inteiro -- usa-lo para mudar
#   `strict` apagaria os 10 checks e o enforce_admins em silencio. Aqui os ramos
#   vao pelo SUB-RECURSO .../protection/required_status_checks, que e cirurgico.
#
# NAO TOCA (ADR-035 §4 -- armadilhas, nao esquecimentos)
#   required_linear_history        fica false  (true proibiria merge commit)
#   required_pull_request_reviews  fica null   (impasse com mantenedor unico)
#   required_conversation_resolution fica false (travaria o auto-merge)
#
# USO
#   scripts/governance/apply-adr-035.sh --check    # so relata, nao escreve
#   scripts/governance/apply-adr-035.sh --apply    # aplica e reverifica
# =============================================================================
set -uo pipefail
LC_ALL=C; export LC_ALL

REPO="pasqualinigui/fluksos-x"
MODE=""
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    --apply) MODE="apply" ;;
    *) printf 'erro de uso: parametro desconhecido %s\n' "$arg" >&2
       printf 'uso: %s [--check|--apply]\n' "$(basename -- "$0")" >&2; exit 2 ;;
  esac
done
if [ -z "$MODE" ]; then
  printf 'uso: %s [--check|--apply]\n' "$(basename -- "$0")" >&2; exit 2
fi

command -v gh >/dev/null 2>&1 || { printf 'gh nao encontrado\n' >&2; exit 2; }

FAIL=0
report() { # nome esperado obtido
  if [ "$2" = "$3" ]; then printf '  ✅ %-32s %s\n' "$1" "$3"
  else printf '  🔴 %-32s esperado=%s obtido=%s\n' "$1" "$2" "$3"; FAIL=1; fi
}

verifica() {
  printf '\nProtecao de linha (sub-recurso required_status_checks):\n'
  for b in main develop; do
    local s c
    s=$(gh api "repos/$REPO/branches/$b/protection/required_status_checks" --jq '.strict' 2>/dev/null || echo "?")
    c=$(gh api "repos/$REPO/branches/$b/protection/required_status_checks" --jq '.contexts|length' 2>/dev/null || echo "?")
    report "$b strict" "true" "$s"
    report "$b checks obrigatorios" "10" "$c"
  done

  printf '\nSettings do repositorio:\n'
  local j
  j=$(gh api "repos/$REPO" 2>/dev/null) || { printf '  🔴 leitura do repo falhou\n'; FAIL=1; return; }
  report "allow_auto_merge"        "true"  "$(echo "$j" | jq -r '.allow_auto_merge')"
  report "allow_merge_commit"      "true"  "$(echo "$j" | jq -r '.allow_merge_commit')"
  report "allow_squash_merge"      "false" "$(echo "$j" | jq -r '.allow_squash_merge')"
  report "allow_rebase_merge"      "false" "$(echo "$j" | jq -r '.allow_rebase_merge')"
  report "delete_branch_on_merge"  "true"  "$(echo "$j" | jq -r '.delete_branch_on_merge')"
  report "allow_update_branch"     "true"  "$(echo "$j" | jq -r '.allow_update_branch')"

  printf '\nNao-mudancas deliberadas (ADR-035 §4 — mexer aqui quebra):\n'
  for b in main develop; do
    local p lin rev conv
    p=$(gh api "repos/$REPO/branches/$b/protection" 2>/dev/null)
    lin=$(echo "$p"  | jq -r '.required_linear_history.enabled')
    rev=$(echo "$p"  | jq -r 'if .required_pull_request_reviews == null then "null" else "definido" end')
    conv=$(echo "$p" | jq -r '.required_conversation_resolution.enabled')
    report "$b required_linear_history" "false" "$lin"
    report "$b required_pull_request_reviews" "null" "$rev"
    report "$b required_conversation_resolution" "false" "$conv"
  done
}

if [ "$MODE" = "apply" ]; then
  printf 'Aplicando ADR-035 §3 em %s\n' "$REPO"
  for b in main develop; do
    gh api -X PATCH "repos/$REPO/branches/$b/protection/required_status_checks" \
      -F strict=true >/dev/null || { printf '🔴 falhou strict em %s\n' "$b" >&2; exit 1; }
    printf '  aplicado: %s strict=true\n' "$b"
  done
  gh api -X PATCH "repos/$REPO" \
    -F allow_auto_merge=true \
    -F allow_merge_commit=true \
    -F allow_squash_merge=false \
    -F allow_rebase_merge=false \
    -F delete_branch_on_merge=true \
    -F allow_update_branch=true >/dev/null || { printf '🔴 falhou settings\n' >&2; exit 1; }
  printf '  aplicado: settings do repositorio\n'
fi

printf '\n=== Estado medido em %s ===\n' "$REPO"
verifica

if [ "$FAIL" = "0" ]; then
  printf '\nResultado: servidor conforme a ADR-035 — CONFORME\n'; exit 0
else
  printf '\nResultado: servidor divergente da ADR-035 — NAO CONFORME\n'
  printf 'Para aplicar: %s --apply\n' "$0"
  exit 1
fi
