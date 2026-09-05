#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 001 (0.9): fundacao de versionamento
#
# Contrato normativo:
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
#
# Restricoes (contrato §5), todas obrigatorias:
#   1. Apenas shell, git e Python 3.12 stdlib. Nenhuma dependencia do projeto.
#   2. Somente leitura sobre o estado medido. Escreve apenas em stdout/stderr.
#   3. Saida deterministica e ordenada. Sem horario, sem aleatorio, sem ordem
#      de leitura do sistema de arquivos.
#   4. Raiz resolvida pela localizacao deste script, nunca pelo diretorio atual.
#   5. Assercao reprovada NAO interrompe as demais.
#   6. Arquivos-isca removidos via trap, inclusive em interrupcao.
#
# NOTA DE DESENHO — Grupo C e verificado em DUAS CAMADAS:
#
#   Camada 1 (sempre): repositorio descartavel HERMETICO, semeado apenas com o
#   .gitignore do projeto. GIT_CONFIG_GLOBAL e GIT_CONFIG_SYSTEM apontam para
#   /dev/null, de modo que nenhuma configuracao da maquina participe. Responde:
#   "o .gitignore do projeto, SOZINHO, esta correto?"
#
#   Sem a hermeticidade isto seria um falso-positivo esperando acontecer: um
#   .gitignore global da maquina excluindo `.env.local` faria FR-008b APROVAR
#   com o .gitignore do projeto quebrado — a mesma classe de erro que E7
#   demonstrou em `git check-ignore`. Verificado empiricamente: um repositorio
#   recem-criado herda `core.excludesFile` global por padrao.
#
#   Camada 2 (quando o repositorio do projeto existe): as mesmas verificacoes
#   in situ, no repositorio real, onde participam `.git/info/exclude`, config
#   local e global. Responde: "o repositorio real esta de fato protegido?"
#
#   As duas camadas precisam CONCORDAR. Divergencia e violacao com evidencia
#   nomeando a discrepancia — e o sintoma de configuracao de maquina mascarando
#   (ou quebrando) a regra do projeto.
#
#   Motivo de existir a Camada 1: o oraculo precisa reprovar de forma informativa
#   ANTES de o repositorio existir (FR-021), e o portao vermelho (SC-004) roda
#   exatamente nesse estado. Os Grupos A, B, D e E medem sempre o projeto real.
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

# --- acumuladores (restricao 5: nada interrompe) ------------------------------
declare -a R_STATUS=() R_ID=() R_DESC=() R_SEV=() R_EVID=()

pass() { R_STATUS+=("ok");   R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("-");  R_EVID+=(""); }
fail() { R_STATUS+=("bad");  R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("$3"); R_EVID+=("${4:-}"); }
skip() { R_STATUS+=("skip"); R_ID+=("$1"); R_DESC+=("$2"); R_SEV+=("-");  R_EVID+=("${3:-}"); }

check() { # id desc severidade condicao_ja_avaliada evidencia
  if [ "$4" = "0" ]; then pass "$1" "$2"; else fail "$1" "$2" "$3" "${5:-}"; fi
}

# --- fonte UNICA de identificadores e descricoes (base da assercao FR-017) ---
# `--list` imprime daqui, e o relatorio final valida que cada resultado usa
# exatamente a descricao canonica. Descricao divergente ou duplicada reprova.
declare -A CANON=(
  ["FR-001"]="repositorio existe e linha principal e main"
  ["FR-002"]="linha de integracao develop existe"
  ["FR-003a"]="identidade de autoria definida em escopo local"
  ["FR-003b"]="escopo global da maquina nao foi alterado"
  ["FR-004"]="convencoes declaram os 11 tipos de registro"
  ["FR-005"]="convencoes declaram escopo opcional e marcacao de incompatibilidade"
  ["FR-006"]="convencoes declaram formato de nome de linha de funcionalidade"
  ["FR-007"]="convencoes declaram papeis de main e develop"
  ["FR-008a"]="arquivo de ambiente base e excluido"
  ["FR-008b"]="variantes de arquivo de ambiente sao excluidas"
  ["FR-009"]="arquivo-modelo de ambiente permanece versionavel"
  ["FR-010"]="ambiente virtual e bytecode sao excluidos"
  ["FR-011"]="caches das ferramentas de qualidade sao excluidos"
  ["FR-012"]="efemeros do motor excluidos e diretorio-pai preservado"
  ["FR-012b"]="camada hermetica e repositorio real concordam sobre as exclusoes"
  ["FR-013"]="trava de dependencias permanece versionavel"
  ["FR-014"]="exclusoes geridas pela ferramenta de spec nao sao redeclaradas"
  ["FR-015"]="registro inicial existe e contem plano e pesquisa"
  ["FR-018"]="oraculo nao contem construcao nao deterministica"
  ["FR-019"]="oraculo nao invoca ferramenta fora do permitido"
  ["FR-020a"]="nenhum arquivo proibido consta do indice"
  ["FR-020b"]="nenhum arquivo proibido consta do historico"
  ["FR-022"]="registro de decisoes arquiteturais mapeia specs e itens do plano"
  ["FR-023a"]="artefatos de integracao de agente permanecem versionaveis"
  ["FR-023b"]="configuracao local de maquina do agente e excluida"
  ["SC-002"]="todos os registros satisfazem a gramatica de convencao"
  ["FR-006b"]="linhas de funcionalidade obedecem ao formato de nome"
  ["FR-016"]="codigos de saida obedecem a semantica do contrato"
  ["FR-017"]="cada resultado usa a descricao canonica do seu requisito"
  ["FR-021"]="oraculo reprova informativamente sem repositorio"
)

# ordem de exibicao do --list: estavel, nunca a ordem do array associativo
CANON_ORDER="FR-001 FR-002 FR-003a FR-003b FR-004 FR-005 FR-006 FR-007 FR-008a FR-008b FR-009 FR-010 FR-011 FR-012 FR-012b FR-013 FR-014 FR-015 FR-018 FR-019 FR-020a FR-020b FR-022 FR-023a FR-023b SC-002 FR-006b FR-016 FR-017 FR-021"
# --- sandbox descartavel + trap (restricao 6) ---------------------------------
SANDBOX=""
cleanup() { [ -n "$SANDBOX" ] && [ -d "$SANDBOX" ] && rm -rf -- "$SANDBOX"; }
trap cleanup EXIT INT TERM HUP

# =============================================================================
# --list: enumera sem executar (permite ao item 004 promover a pytest)
# =============================================================================
if [ "$LIST" = "1" ]; then
  for id in $CANON_ORDER; do printf '%-8s %s
' "$id" "${CANON[$id]}"; done
  exit 0
fi

# =============================================================================
# GRUPO A — Repositorio e linhas de trabalho
# =============================================================================
HAS_REPO=1
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then HAS_REPO=0; fi

if [ "$HAS_REPO" != "0" ]; then
  # FR-021: reprova de forma informativa, nao com erro abrupto
  fail "FR-001" "repositorio existe e linha principal e main" "media" \
       "nenhum repositorio em $ROOT — a fundacao ainda nao foi estabelecida"
  fail "FR-002" "linha de integracao develop existe" "media" "sem repositorio"
  fail "FR-003a" "identidade de autoria definida em escopo local" "media" "sem repositorio"
else
  # ADR-029: mede a existencia da linha principal (propriedade do repo),
  # nunca a sessao (HEAD) — enunciado sempre disse "a linha principal e main"
  git -C "$ROOT" show-ref --verify --quiet refs/heads/main
  check "FR-001" "repositorio existe e linha principal e main" "media" "$?" \
        "refs/heads/main existe; linhas: $(git -C "$ROOT" for-each-ref --format='%(refname:short)' refs/heads | sort | tr '\n' ' ')"

  git -C "$ROOT" show-ref --verify --quiet refs/heads/develop
  check "FR-002" "linha de integracao develop existe" "media" "$?" \
        "linhas: $(git -C "$ROOT" for-each-ref --format='%(refname:short)' refs/heads | sort | tr '\n' ' ')"

  L_NAME="$(git -C "$ROOT" config --local --get user.name 2>/dev/null || echo "")"
  L_MAIL="$(git -C "$ROOT" config --local --get user.email 2>/dev/null || echo "")"
  check "FR-003a" "identidade de autoria definida em escopo local" "media" \
        "$([ -n "$L_NAME" ] && [ "$L_MAIL" = "pasqualini166@gmail.com" ] && echo 0 || echo 1)" \
        "local: ${L_NAME:-<vazio>} <${L_MAIL:-<vazio>}>"
fi

# FR-003b: o escopo global nao pode conter init.defaultBranch escrito por este item.
# Verificacao conservadora: o valor global permanece o que era antes (ausente).
G_DEFBR="$(git config --global --get init.defaultBranch 2>/dev/null || echo "")"
check "FR-003b" "escopo global da maquina nao foi alterado" "alta" \
      "$([ -z "$G_DEFBR" ] && echo 0 || echo 1)" \
      "global init.defaultBranch = ${G_DEFBR:-<ausente, correto>}"

# =============================================================================
# GRUPO B — Convencoes documentadas
# =============================================================================
CONTRIB="$ROOT/CONTRIBUTING.md"
if [ ! -f "$CONTRIB" ]; then
  fail "FR-004" "convencoes declaram os 11 tipos de registro" "media" "CONTRIBUTING.md inexistente"
  fail "FR-005" "convencoes declaram escopo opcional e marcacao de incompatibilidade" "media" "CONTRIBUTING.md inexistente"
  fail "FR-006" "convencoes declaram formato de nome de linha de funcionalidade" "media" "CONTRIBUTING.md inexistente"
  fail "FR-007" "convencoes declaram papeis de main e develop" "media" "CONTRIBUTING.md inexistente"
else
  MISSING=""
  for t in feat fix docs test refactor ci chore perf build style revert; do
    grep -qE "\`${t}\`|^\| \`?${t}\`?" "$CONTRIB" || MISSING="${MISSING}${t} "
  done
  check "FR-004" "convencoes declaram os 11 tipos de registro" "media" \
        "$([ -z "$MISSING" ] && echo 0 || echo 1)" "tipos ausentes: ${MISSING:-nenhum}"

  grep -q "escopo" "$CONTRIB" && grep -qE "BREAKING CHANGE|incompat" "$CONTRIB"
  check "FR-005" "convencoes declaram escopo opcional e marcacao de incompatibilidade" "media" "$?" \
        "procurado: mencao a escopo e a mudanca incompativel"

  grep -qE "feature/f<fase>|feature/f[0-9]" "$CONTRIB"
  check "FR-006" "convencoes declaram formato de nome de linha de funcionalidade" "media" "$?" \
        "procurado: padrao feature/f<fase>-<pacote>-<funcionalidade>"

  grep -q '`main`' "$CONTRIB" && grep -q '`develop`' "$CONTRIB"
  check "FR-007" "${CANON[FR-007]}" "media" "$?" \
        "procurado: mencao a main e develop"
fi

# T029 / FR-006b — documentar o formato nao basta: as linhas existentes precisam
# obedecer a ele. Sem esta assercao, `feature/qualquer-coisa` passa com saida 0.
if [ "$HAS_REPO" = "0" ]; then
  BADBR=""
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    printf '%s' "$b" | grep -qE '^feature/f[0-9]+(-[a-z0-9]+){2,}$' || BADBR="${BADBR}${b} "
  done <<< "$(git -C "$ROOT" for-each-ref --format='%(refname:short)' refs/heads | grep '^feature/' | sort)"
  check "FR-006b" "${CANON[FR-006b]}" "media" \
        "$([ -z "$BADBR" ] && echo 0 || echo 1)" \
        "${BADBR:+fora do padrao feature/f<fase>-<pacote>-<funcionalidade>: $BADBR}"
else
  skip "FR-006b" "${CANON[FR-006b]}" "sem repositorio"
fi

# =============================================================================
# GRUPO C — Higiene do historico (Lei Zero), em repositorio descartavel
# =============================================================================
GI="$ROOT/.gitignore"
if [ ! -f "$GI" ]; then
  while IFS='|' read -r id desc; do
    fail "$id" "$desc" "critica" ".gitignore inexistente"
  done <<'SEMGI'
FR-008a|arquivo de ambiente base e excluido
FR-008b|variantes de arquivo de ambiente sao excluidas
FR-009|arquivo-modelo de ambiente permanece versionavel
FR-010|ambiente virtual e bytecode sao excluidos
FR-011|caches das ferramentas de qualidade sao excluidos
FR-012|efemeros do motor excluidos e diretorio-pai preservado
FR-013|trava de dependencias permanece versionavel
FR-014|exclusoes geridas pela ferramenta de spec nao sao redeclaradas
FR-023a|artefatos de integracao de agente permanecem versionaveis
FR-023b|configuracao local de maquina do agente e excluida
SEMGI
else
  SANDBOX="$(mktemp -d)"
  # hermetico: nenhuma configuracao da maquina participa da Camada 1
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  git -C "$SANDBOX" init -q -b main . >/dev/null 2>&1
  unset GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM
  cp -- "$GI" "$SANDBOX/.gitignore"
  mkdir -p "$SANDBOX/.venv" "$SANDBOX/.ruff_cache" "$SANDBOX/.mypy_cache" \
           "$SANDBOX/.pytest_cache" "$SANDBOX/htmlcov" "$SANDBOX/__pycache__" \
           "$SANDBOX/.fluksos-x/sessions" "$SANDBOX/.fluksos-x/reports" \
           "$SANDBOX/.fluksos-x/specs" "$SANDBOX/.tmp" \
           "$SANDBOX/.claude/skills/speckit-plan"
  : > "$SANDBOX/.env";              : > "$SANDBOX/.env.local"
  : > "$SANDBOX/.env.production";   : > "$SANDBOX/.env.staging"
  : > "$SANDBOX/.env.example";      : > "$SANDBOX/uv.lock"
  : > "$SANDBOX/.venv/pyvenv.cfg";  : > "$SANDBOX/__pycache__/m.cpython-312.pyc"
  : > "$SANDBOX/.ruff_cache/c";     : > "$SANDBOX/.mypy_cache/c"
  : > "$SANDBOX/.pytest_cache/c";   : > "$SANDBOX/htmlcov/i.html"
  : > "$SANDBOX/.coverage"
  : > "$SANDBOX/.fluksos-x/sessions/s.json"
  : > "$SANDBOX/.fluksos-x/reports/r.md"
  : > "$SANDBOX/.fluksos-x/specs/keep.md"
  : > "$SANDBOX/.tmp/scratch"
  : > "$SANDBOX/.claude/skills/speckit-plan/SKILL.md"
  : > "$SANDBOX/.claude/settings.local.json"

  # Camada 1 — hermetica. Camada 2 — in situ, so quando o repositorio existe.
  # Divergencia entre elas e registrada em DIVERG e reprovada ao final.
  DIVERG=""
  _herm() { env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
                git -C "$SANDBOX" check-ignore -q -- "$1"; }
  _situ() { git -C "$ROOT" check-ignore -q -- "$1"; }

  _cross() { # caminho ; ecoa 0 se ignorado na Camada 1
    local path="$1" h s
    _herm "$path"; h=$?
    if [ "$HAS_REPO" = "0" ]; then
      _situ "$path"; s=$?
      if [ "$h" -ne "$s" ]; then
        DIVERG="${DIVERG}${path}(hermetico=$([ $h -eq 0 ] && echo ignorado || echo versionavel),insitu=$([ $s -eq 0 ] && echo ignorado || echo versionavel)) "
      fi
    fi
    return $h
  }

  ign()  { _cross "$1"; }                    # 0 = ignorado
  vers() { _cross "$1"; [ $? -ne 0 ]; }      # 0 = versionavel

  ign ".env"
  check "FR-008a" "arquivo de ambiente base e excluido" "critica" "$?" ".env visivel ao versionador"

  VARFAIL=""
  for v in .env.local .env.production .env.staging; do
    ign "$v" || VARFAIL="${VARFAIL}${v} "
  done
  check "FR-008b" "variantes de arquivo de ambiente sao excluidas" "critica" \
        "$([ -z "$VARFAIL" ] && echo 0 || echo 1)" \
        "variantes NAO excluidas: ${VARFAIL:-nenhuma} (modo de falha do template canonico, E1/E5)"

  vers ".env.example"
  check "FR-009" "arquivo-modelo de ambiente permanece versionavel" "alta" "$?" \
        ".env.example foi capturado por alguma exclusao"

  ENVFAIL=""
  for f in .venv/pyvenv.cfg __pycache__/m.cpython-312.pyc; do
    ign "$f" || ENVFAIL="${ENVFAIL}${f} "
  done
  check "FR-010" "ambiente virtual e bytecode sao excluidos" "alta" \
        "$([ -z "$ENVFAIL" ] && echo 0 || echo 1)" "nao excluidos: ${ENVFAIL:-nenhum}"

  CACHEFAIL=""
  for f in .ruff_cache/c .mypy_cache/c .pytest_cache/c htmlcov/i.html .coverage; do
    ign "$f" || CACHEFAIL="${CACHEFAIL}${f} "
  done
  check "FR-011" "caches das ferramentas de qualidade sao excluidos" "media" \
        "$([ -z "$CACHEFAIL" ] && echo 0 || echo 1)" "nao excluidos: ${CACHEFAIL:-nenhum}"

  EPHFAIL=""
  for f in .fluksos-x/sessions/s.json .fluksos-x/reports/r.md .tmp/scratch; do
    ign "$f" || EPHFAIL="${EPHFAIL}${f} "
  done
  vers ".fluksos-x/specs/keep.md" || EPHFAIL="${EPHFAIL}<diretorio-pai .fluksos-x/ foi excluido inteiro> "
  check "FR-012" "efemeros do motor excluidos e diretorio-pai preservado" "alta" \
        "$([ -z "$EPHFAIL" ] && echo 0 || echo 1)" "problemas: ${EPHFAIL:-nenhum}"

  vers "uv.lock"
  check "FR-013" "trava de dependencias permanece versionavel" "alta" "$?" \
        "uv.lock capturado por exclusao — controle de cadeia de suprimentos desfeito"

  grep -qE "^[[:space:]]*(feature\.json|\.specify/)" "$GI"
  DUP=$?
  check "FR-014" "exclusoes geridas pela ferramenta de spec nao sao redeclaradas" "media" \
        "$([ "$DUP" -ne 0 ] && echo 0 || echo 1)" ".gitignore duplica regras de .specify/.gitignore"

  # Camadas 1 e 2 precisam concordar: divergencia indica configuracao de maquina
  # mascarando ou quebrando a regra do projeto.
  if [ "$HAS_REPO" = "0" ]; then
    check "FR-012b" "camada hermetica e repositorio real concordam sobre as exclusoes" "alta" \
          "$([ -z "$DIVERG" ] && echo 0 || echo 1)" \
          "${DIVERG:+divergencias: $DIVERG}"
  else
    skip "FR-012b" "camada hermetica e repositorio real concordam sobre as exclusoes" \
         "repositorio ainda nao existe — verificavel a partir do portao verde"
  fi

  vers ".claude/skills/speckit-plan/SKILL.md"
  check "FR-023a" "artefatos de integracao de agente permanecem versionaveis" "alta" "$?" \
        ".claude/skills/ excluido — o protocolo de especificacao ficaria fora do historico"

  ign ".claude/settings.local.json"
  check "FR-023b" "configuracao local de maquina do agente e excluida" "alta" "$?" \
        ".claude/settings.local.json versionavel — vazaria caminhos e permissoes da maquina"
fi

# =============================================================================
# GRUPO D — Estado do historico
# =============================================================================
if [ "$HAS_REPO" != "0" ]; then
  fail "FR-015"  "registro inicial existe e contem plano e pesquisa" "media" "sem repositorio"
  fail "FR-020a" "nenhum arquivo proibido consta do indice" "critica" "sem repositorio"
  fail "FR-020b" "nenhum arquivo proibido consta do historico" "critica" "sem repositorio"
  fail "SC-002"  "todos os registros satisfazem a gramatica de convencao" "media" "sem repositorio"
else
  if git -C "$ROOT" rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
    TRACKED="$(git -C "$ROOT" ls-files | sort)"
    HASPLAN=1
    printf '%s\n' "$TRACKED" | grep -q "^docs/plan/implementation_plan.md$" && \
    printf '%s\n' "$TRACKED" | grep -q "^docs/plan/research/f0-001-git-branching.md$" && HASPLAN=0
    check "FR-015" "registro inicial existe e contem plano e pesquisa" "media" "$HASPLAN" \
          "arquivos rastreados: $(printf '%s\n' "$TRACKED" | grep -c .)"

    # D4 — MECANISMO OBRIGATORIO. `git check-ignore` NAO enxerga o indice (E7):
    # usa-lo aqui produziria falso-negativo com um segredo ja registrado.
    IDX_VIOL="$(git -C "$ROOT" ls-files -i -c --exclude-standard | sort)"
    check "FR-020a" "nenhum arquivo proibido consta do indice" "critica" \
          "$([ -z "$IDX_VIOL" ] && echo 0 || echo 1)" "$IDX_VIOL"

    HIST_ALL="$(git -C "$ROOT" log --all --pretty=format: --name-only --diff-filter=A 2>/dev/null | sort -u | grep -v '^$' || true)"
    HIST_VIOL=""
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      case "$f" in
        .env|.env.*) [ "$f" = ".env.example" ] || HIST_VIOL="${HIST_VIOL}${f} " ;;
        .venv/*|*/__pycache__/*|__pycache__/*) HIST_VIOL="${HIST_VIOL}${f} " ;;
        .fluksos-x/sessions/*|.fluksos-x/reports/*|.tmp/*) HIST_VIOL="${HIST_VIOL}${f} " ;;
        .claude/settings.local.json) HIST_VIOL="${HIST_VIOL}${f} " ;;
      esac
    done <<< "$HIST_ALL"
    check "FR-020b" "nenhum arquivo proibido consta do historico" "critica" \
          "$([ -z "$HIST_VIOL" ] && echo 0 || echo 1)" "$HIST_VIOL"

    BADMSG="$(git -C "$ROOT" log --all --pretty=format:%s | python3 -c '
import re, sys
RX = re.compile(r"^(feat|fix|docs|test|refactor|ci|chore|perf|build|style|revert)"
                r"(\([a-z0-9][a-z0-9._-]*\))?(!)?: .+")
# ADR-030: merges sinteticos do GitHub (PR) nao sao registros de autor
MERGE = re.compile(r"^Merge [0-9a-f]{40} into \S+")
bad = [l for l in sys.stdin.read().splitlines() if l.strip() and not RX.match(l) and not MERGE.match(l)]
print("; ".join(sorted(bad)))
')"
    check "SC-002" "todos os registros satisfazem a gramatica de convencao" "media" \
          "$([ -z "$BADMSG" ] && echo 0 || echo 1)" "$BADMSG"
  else
    fail "FR-015"  "registro inicial existe e contem plano e pesquisa" "media" "repositorio sem nenhum registro"
    skip "FR-020a" "nenhum arquivo proibido consta do indice" "sem registro para auditar"
    skip "FR-020b" "nenhum arquivo proibido consta do historico" "sem registro para auditar"
    skip "SC-002"  "todos os registros satisfazem a gramatica de convencao" "sem registro para auditar"
  fi
fi

# =============================================================================
# GRUPO E — Meta
# =============================================================================
# FR-018: verificacao estatica de nao determinismo no proprio oraculo.
NONDET="$(grep -nE '\$RANDOM|\$\(date|`date|--pretty=format:%(ct|ad)' "$SELF" | grep -v '^[0-9]*:#' | grep -v 'nondet-exempt' || true)"  # nondet-exempt
check "FR-018" "oraculo nao contem construcao nao deterministica" "alta" \
      "$([ -z "$NONDET" ] && echo 0 || echo 1)" "$NONDET"

# FR-019 / SC-006: nenhuma ferramenta fora de shell, git e Python stdlib.
FORBIDDEN="$(grep -nE '^[^#]*\b(pytest|ruff|mypy|lefthook|trivy|gitleaks|uv|pip|npm|npx|node)\b[[:space:]]' "$SELF" | grep -v 'nondet-exempt' || true)"  # nondet-exempt
check "FR-019" "oraculo nao invoca ferramenta fora do permitido" "alta" \
      "$([ -z "$FORBIDDEN" ] && echo 0 || echo 1)" "$FORBIDDEN"

# T032 / FR-016 — semantica dos tres codigos de saida, verificada de fato.
# `--list` e o parametro invalido nao reexecutam as assercoes, entao nao recursam.
"$SELF" --list >/dev/null 2>&1;  RC_LIST=$?
"$SELF" --parametro-invalido >/dev/null 2>&1; RC_BAD=$?
check "FR-016" "${CANON[FR-016]}" "alta" \
      "$([ "$RC_LIST" -eq 0 ] && [ "$RC_BAD" -eq 2 ] && echo 0 || echo 1)" \
      "--list=$RC_LIST (esperado 0), parametro invalido=$RC_BAD (esperado 2)"

# T031 / FR-021 — com o repositorio ja criado, a condicao "sem repositorio" deixou
# de ser observavel in situ. Reproduz num diretorio descartavel. FKX_ORACLE_NESTED
# impede recursao infinita: a execucao aninhada pula esta assercao.
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  skip "FR-021" "${CANON[FR-021]}" "execucao aninhada — evita recursao"
else
  NEST="$(mktemp -d)"
  mkdir -p "$NEST/scripts/verify"
  cp -- "$SELF" "$NEST/scripts/verify/"
  NESTOUT="$(FKX_ORACLE_NESTED=1 "$NEST/scripts/verify/$(basename -- "$SELF")" 2>&1)"; RC_NOREPO=$?
  rm -rf -- "$NEST"
  printf '%s' "$NESTOUT" | grep -q "nenhum repositorio em"; INFORMATIVO=$?
  check "FR-021" "${CANON[FR-021]}" "alta" \
        "$([ "$RC_NOREPO" -eq 1 ] && [ "$INFORMATIVO" -eq 0 ] && echo 0 || echo 1)" \
        "saida=$RC_NOREPO (esperado 1), mensagem informativa=$([ "$INFORMATIVO" -eq 0 ] && echo sim || echo NAO)"
fi

DEC="$ROOT/docs/plan/decisions.md"
if [ -f "$DEC" ] && grep -q "ADR-001" "$DEC" && grep -q '`012`' "$DEC"; then
  pass "FR-022" "registro de decisoes arquiteturais mapeia specs e itens do plano"
else
  fail "FR-022" "registro de decisoes arquiteturais mapeia specs e itens do plano" "media" \
       "docs/plan/decisions.md ausente ou sem ADR-001 com o mapa 001-012"
fi

# T030 / FR-017 — o defeito que esta assercao previne ocorreu de fato no portao
# vermelho deste item: FR-004..FR-007 exibiam descricao generica em vez da propria,
# e foi detectado por leitura humana, nao pelo harness.
DESCERR=""
for i in "${!R_ID[@]}"; do
  id="${R_ID[$i]}"
  if [ -z "${CANON[$id]+x}" ]; then
    DESCERR="${DESCERR}${id}(sem entrada canonica) "
  elif [ "${R_DESC[$i]}" != "${CANON[$id]}" ]; then
    DESCERR="${DESCERR}${id}(usou \"${R_DESC[$i]}\") "
  fi
done
check "FR-017" "${CANON[FR-017]}" "alta" \
      "$([ -z "$DESCERR" ] && echo 0 || echo 1)" "$DESCERR"

# =============================================================================
# Relatorio (restricao 3: ordem estavel — ordem de declaracao, nunca do FS)
# =============================================================================
TOTAL=${#R_ID[@]}
OK=0; BAD=0; SKIPPED=0
CRIT=0; ALTA=0; MEDIA=0

for i in "${!R_ID[@]}"; do
  case "${R_STATUS[$i]}" in
    ok)   OK=$((OK+1));      SYM="✅" ;;
    skip) SKIPPED=$((SKIPPED+1)); SYM="⏭️" ;;
    *)    BAD=$((BAD+1));    SYM="🔴"
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
