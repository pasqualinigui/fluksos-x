#!/usr/bin/env bash
# =============================================================================
# Oraculo de conformidade — Fase 0, item 002 (0.11): governanca e porta de entrada
#
# Contrato de assercoes deste item:
#   specs/002-constitution-ratification/contracts/oracle-cli.md
#
# Contrato de INTERFACE (normativo, herdado — nao redefinido aqui):
#   specs/001-git-branching-strategy/contracts/oracle-cli.md
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
# NOTA DE DESENHO — FR-011 mede MECANISMO, nao EFEITO:
#   Um script nao observa o contexto carregado por outro processo. FR-011 verifica
#   que a diretiva de importacao documentada pelo fornecedor esta no lugar certo.
#   O efeito em tempo de sessao e o cenario 6 do quickstart, humano. Verde aqui
#   NAO e prova de comportamento em execucao — ver research E6.
#
# NOTA DE DESENHO — FR-021 sao DUAS perguntas:
#   Executar o oraculo do item 001 e obter 0 prova que ele APROVA, nao que esta
#   INTEGRO. Um item futuro poderia trocar uma assercao real por uma tautologia e
#   continuar saindo 0. FR-021a fixa o resumo criptografico (ADR-006); FR-021b
#   confirma a aprovacao. Divergencia de resumo sobe para decisao explicita,
#   NUNCA para atualizacao do valor fixado — atualizar o numero e a forma exata
#   de derrotar a assercao.
#
# NOTA DE DESENHO — SC-008 e restrito a exclusoes MARCADAS:
#   Apontar para alvo inexistente e o comportamento CORRETO de uma regra de
#   exclusao: ela precede o arquivo que impede de entrar no historico. A medicao
#   (research E3) achou 79 de 80 regras literais nessa condicao. Só as marcadas
#   com `# transitorio:` sao cobradas — ver ADR-006.
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

# --- fonte UNICA de identificadores e descricoes ------------------------------
declare -A CANON=(
  ["FR-001"]="governanca sem campo de preenchimento remanescente"
  ["FR-002"]="governanca versionada e ratificacao inaugural e 1.0.0"
  ["FR-003"]="datas da governanca em formato ISO"
  ["FR-004"]="dez principios em numeracao romana continua I a X"
  ["FR-005a"]="cada principio contem verbo normativo"
  ["FR-005b"]="cada principio declara criterio de violacao"
  ["FR-006"]="cada principio declara origem"
  ["FR-007"]="governanca declara emenda versionamento e revisao"
  ["FR-008"]="registro de impacto presente em ocorrencia unica"
  ["FR-009"]="orientacao existe no local convencional do formato aberto"
  ["FR-010a"]="porta de entrada contem identidade operacao e ponteiros"
  ["FR-010b"]="porta de entrada nao reproduz principios nem plano"
  ["FR-011"]="arquivo do construtor contem a diretiva de importacao"
  ["FR-012"]="porta de entrada nao duplica prosa entre seus arquivos"
  ["FR-013"]="arquivo do construtor e regular e nao link simbolico"
  ["FR-014"]="porta de entrada respeita o orcamento de tamanho"
  ["FR-015"]="governanca declara o ciclo canonico com clarificacao"
  ["FR-016a"]="documento de contribuicao declara o ciclo atualizado"
  ["FR-016b"]="nenhum documento normativo mantem o ciclo anterior"
  ["FR-017a"]="veredito retroativo nomeia os 16 artefatos do item 001"
  ["FR-017b"]="nenhuma nao conformidade retroativa pendente de decisao"
  ["FR-018"]="derivacao do material transitorio registrada e transcrita"
  ["FR-019a"]="material de referencia transitorio nao existe mais"
  ["FR-019b"]="nenhuma regra de exclusao referencia o material transitorio"
  ["SC-008"]="toda exclusao marcada como transitoria tem alvo existente"
  ["FR-020a"]="codigos de saida obedecem a semantica do contrato"
  ["FR-020b"]="parametros --quiet e --list obedecem ao contrato"
  ["FR-020c"]="duas execucoes produzem saida identica"
  ["FR-021a"]="oraculo do item anterior permanece integro"
  ["FR-021b"]="oraculo do item anterior continua aprovando"
  ["FR-022"]="evidencias vermelha e verde existem e diferem"
  ["FR-023"]="spec declara contratos entregues e transferidos"
  ["SC-006"]="oraculo conclui em menos de 5 segundos"
)

CANON_ORDER="FR-001 FR-002 FR-003 FR-004 FR-005a FR-005b FR-006 FR-007 FR-008 FR-009 FR-010a FR-010b FR-011 FR-012 FR-013 FR-014 FR-015 FR-016a FR-016b FR-017a FR-017b FR-018 FR-019a FR-019b SC-008 FR-020a FR-020b FR-020c FR-021a FR-021b FR-022 FR-023 SC-006"

# --- constantes fixadas (contrato §4, ADR-006) --------------------------------
HASH_F0_001="63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22"
BUDGET_AGENTS=150
BUDGET_TOTAL=175
DUP_MINLEN=40

# --- caminhos medidos ---------------------------------------------------------
GOV="$ROOT/.specify/memory/constitution.md"
AGENTS="$ROOT/AGENTS.md"
CLAUDEMD="$ROOT/CLAUDE.md"
CONTRIB="$ROOT/CONTRIBUTING.md"
DEC="$ROOT/docs/plan/decisions.md"
GITIGNORE="$ROOT/.gitignore"
TRANSIT="$ROOT/docs/AGENTS-EXAMPLE.md"
FEATDIR="$ROOT/specs/002-constitution-ratification"
COMPLIANCE="$FEATDIR/compliance-001.md"
SPEC="$FEATDIR/spec.md"
RED="$FEATDIR/evidence/red.txt"
GREEN="$FEATDIR/evidence/green.txt"
ORACLE1="$SCRIPT_DIR/f0-001-foundation.sh"

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

# --- helper Python: analise da governanca ------------------------------------
py_gov() { # $1 = subcomando
  python3 - "$GOV" "$1" <<'PY'
import re, sys, pathlib
p, cmd = sys.argv[1], sys.argv[2]
if not pathlib.Path(p).exists():
    print("AUSENTE"); sys.exit(0)
raw = pathlib.Path(p).read_text(encoding='utf-8')
body = re.sub(r'<!--.*?-->', '', raw, flags=re.S)

if cmd == "placeholders":
    print(' '.join(sorted(set(re.findall(r'\[[A-Z][A-Z0-9_]*\]', body)))) or "OK")

elif cmd == "versao":
    m = re.search(r'\*\*Version\*\*:\s*(\d+\.\d+\.\d+)', body)
    print(m.group(1) if m else "SEM-VERSAO")

elif cmd == "datas":
    m = re.search(r'\*\*Ratified\*\*:\s*([^|\n]+)\|?\s*\*\*Last Amended\*\*:\s*([^\n]+)', body)
    if not m:
        print("SEM-RODAPE"); sys.exit(0)
    bad = [d.strip() for d in m.groups() if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', d.strip())]
    # qualquer data em formato nao-ISO no corpo tambem reprova
    bad += re.findall(r'\b\d{2}/\d{2}/\d{4}\b', body)
    print(' '.join(bad) or "OK")

elif cmd == "numeracao":
    got = re.findall(r'^###\s+([IVX]+)\.\s', body, flags=re.M)
    want = ["I","II","III","IV","V","VI","VII","VIII","IX","X"]
    print("OK" if got == want else f"esperado I..X, obtido: {' '.join(got) or '<nenhum>'}")

elif cmd in ("normativo", "violacao", "origem"):
    blocks = re.split(r'^###\s+(?=[IVX]+\.\s)', body, flags=re.M)[1:]
    # Verdade vacua e reprovacao: uma assercao que aprova porque o conjunto
    # examinado esta vazio reporta verde sobre nada. Exigimos os dez blocos.
    if len(blocks) != 10:
        print(f"nenhum principio avaliavel — {len(blocks)} blocos encontrados (esperado 10)")
        sys.exit(0)
    faltam = []
    for b in blocks:
        num = b.split('.')[0].strip()
        if cmd == "normativo":
            ok = re.search(r'\bMUST NOT\b|\bMUST\b|\bSHOULD\b', b)
        elif cmd == "violacao":
            m = re.search(r'\*\*(?:Violation|Violação):\*\*\s*(\S.*)', b)
            ok = m and len(m.group(1).strip()) > 20
        else:
            m = re.search(r'\*\*(?:Source|Origem):\*\*\s*(\S.*)', b)
            ok = m and len(m.group(1).strip()) > 10
        if not ok: faltam.append(num)
    print(' '.join(f"principio {n}" for n in faltam) or "OK")

elif cmd == "governanca":
    # A secao de governanca e localizada por qualquer das duas grafias: o modelo
    # canonico usa "## Governance". O nome do cabecalho nao e o requisito — as
    # tres subsecoes sao. A exigencia abaixo permanece identica.
    sec = ''
    for h in ('## Governance', '## Governança'):
        if h in body: sec = body.split(h)[-1]; break
    falta = [k for k, pat in (
        ("procedimento de emenda",   r'Amendment Procedure|[Ee]menda'),
        ("politica de versionamento", r'Versioning Policy|[Vv]ersionamento'),
        ("revisao de conformidade",  r'Compliance Review|revisão de conformidade'))
             if not re.search(pat, sec)]
    print(' '.join(falta) or "OK")

elif cmd == "impacto":
    n = len(re.findall(r'Sync Impact Report', raw))
    if n != 1:
        print(f"ocorrencias do registro de impacto: {n} (esperado 1)"); sys.exit(0)
    blk = re.search(r'<!--(.*?)-->', raw, flags=re.S).group(1)
    falta = [k for k, pat in (("versao anterior", r'[Aa]nterior'),
                              ("versao nova", r'1\.0\.0'),
                              ("principios acrescentados", r'[Pp]rincípios'),
                              ("pendencias deferidas", r'[Dd]eferid'))
             if not re.search(pat, blk)]
    print(' '.join(falta) or "OK")

elif cmd == "ciclo":
    print("OK" if re.search(r'CLARIFY', body) and re.search(r'RESEARCH', body) else "ciclo canonico com CLARIFY ausente")
PY
}

# --- helper Python: prosa normativa e duplicacao ------------------------------
py_prose() { # $1 $2 = arquivos ; imprime linhas duplicadas ou OK
  python3 - "$1" "$2" "$DUP_MINLEN" <<'PY'
import re, sys, pathlib
def prose(p, minlen):
    out, fence = set(), False
    q = pathlib.Path(p)
    if not q.exists(): return out
    for ln in q.read_text(encoding='utf-8').splitlines():
        s = ln.strip()
        if s.startswith('```'): fence = not fence; continue
        if fence or not s: continue
        if s[0] in '#|>' or s.startswith('---') or s.startswith('<!--'): continue
        s = re.sub(r'\s+', ' ', s).lower()
        if len(s) >= minlen: out.add(s)
    return out
a, b, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
dup = sorted(prose(a, n) & prose(b, n))
print('\n'.join(d[:90] for d in dup) if dup else "OK")
PY
}

# Verifica se um achado nao conforme tem DECISAO DO MANTENEDOR registrada.
# Exige as quatro partes: saida escolhida, fundamentacao substantiva, data ISO e
# a decisao arquitetural que a formaliza. Faltando qualquer uma, o achado segue
# pendente e FR-017b reprova.
py_decisao() {
  # CAUSA REGISTRADA (principio VII) — defeito real, corrigido em 2026-08-30:
  # a primeira versao usava `\*\*Saída escolhida\*\*:\s*(\S.*)`. Em Python `\s`
  # inclui QUEBRA DE LINHA, entao com o valor apagado o padrao atravessava a linha
  # vazia e capturava a LINHA SEGUINTE — aprovando um registro de decisao em branco.
  # Detectado pelo controle adversarial, nao por assercao: a assercao aprovava.
  # A ancoragem correta e `[ \t]*(\S[^\n]*)`, que nao cruza a quebra de linha.
  # Nao substituir por \s* de novo.
  python3 - "$COMPLIANCE" <<'PYD'
import re, sys, pathlib
t = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
falta = []
m = re.search(r'\*\*Saída escolhida\*\*:[ \t]*(\S[^\n]*)', t)
if not m or len(m.group(1).strip()) < 5: falta.append("saida-escolhida")
m2 = re.search(r'\*\*Fundamentação\*\*:[ \t]*(\S[^\n]*)', t)
if not m2 or len(m2.group(1).strip()) < 40: falta.append("fundamentacao")
if not re.search(r'\*\*Data\*\*:\s*\d{4}-\d{2}-\d{2}', t): falta.append("data-ISO")
if not re.search(r'ADR-\d+', t): falta.append("decisao-arquitetural")
print(' '.join(falta) or "OK")
PYD
}

py_sha() { python3 -c "import hashlib,sys,pathlib;p=pathlib.Path(sys.argv[1]);print(hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else 'AUSENTE')" "$1"; }

# =============================================================================
# GRUPO A — Governanca ratificada
# =============================================================================
if [ ! -f "$GOV" ]; then
  for id in FR-001 FR-002 FR-003 FR-004 FR-005a FR-005b FR-006 FR-007 FR-008 FR-015; do
    fail "$id" "${CANON[$id]}" "alta" "governanca ausente em ${GOV#"$ROOT"/}"
  done
else
  V="$(py_gov placeholders)"
  check "FR-001" "${CANON[FR-001]}" "critica" "$([ "$V" = "OK" ] && echo 0 || echo 1)" \
        "campos remanescentes: $V"

  V="$(py_gov versao)"
  check "FR-002" "${CANON[FR-002]}" "media" "$([ "$V" = "1.0.0" ] && echo 0 || echo 1)" \
        "versao encontrada: $V (esperado 1.0.0)"

  V="$(py_gov datas)"
  check "FR-003" "${CANON[FR-003]}" "media" "$([ "$V" = "OK" ] && echo 0 || echo 1)" \
        "datas fora do formato ISO: $V"

  V="$(py_gov numeracao)"
  check "FR-004" "${CANON[FR-004]}" "alta" "$([ "$V" = "OK" ] && echo 0 || echo 1)" "$V"

  V="$(py_gov normativo)"
  check "FR-005a" "${CANON[FR-005a]}" "alta" "$([ "$V" = "OK" ] && echo 0 || echo 1)" \
        "sem verbo normativo: $V"

  V="$(py_gov violacao)"
  check "FR-005b" "${CANON[FR-005b]}" "alta" "$([ "$V" = "OK" ] && echo 0 || echo 1)" \
        "sem criterio de violacao: $V"

  V="$(py_gov origem)"
  check "FR-006" "${CANON[FR-006]}" "alta" "$([ "$V" = "OK" ] && echo 0 || echo 1)" \
        "sem origem declarada: $V"

  V="$(py_gov governanca)"
  check "FR-007" "${CANON[FR-007]}" "media" "$([ "$V" = "OK" ] && echo 0 || echo 1)" \
        "subsecoes ausentes: $V"

  V="$(py_gov impacto)"
  check "FR-008" "${CANON[FR-008]}" "media" "$([ "$V" = "OK" ] && echo 0 || echo 1)" "$V"

  V="$(py_gov ciclo)"
  check "FR-015" "${CANON[FR-015]}" "media" "$([ "$V" = "OK" ] && echo 0 || echo 1)" "$V"
fi

# =============================================================================
# GRUPO B — Porta de entrada
# =============================================================================
check "FR-009" "${CANON[FR-009]}" "alta" "$([ -f "$AGENTS" ] && echo 0 || echo 1)" \
      "AGENTS.md ausente na raiz do projeto"

if [ -f "$AGENTS" ]; then
  MISS=""
  # Cabecalhos em ingles por ADR-010: AGENTS.md e o formato aberto lido por
  # agentes de qualquer origem. A prosa permanece em portugues.
  for sec in "Identity" "How to operate" "Canonical cycle" "Rules that do not bend" "Where the sources are" "Precedence"; do
    grep -q "$sec" "$AGENTS" || MISS="${MISS}[$sec] "
  done
  check "FR-010a" "${CANON[FR-010a]}" "media" "$([ -z "$MISS" ] && echo 0 || echo 1)" \
        "secoes ausentes: $MISS"

  D1="$(py_prose "$AGENTS" "$GOV")"
  D2="$(py_prose "$AGENTS" "$ROOT/docs/plan/implementation_plan.md")"
  REPRO=""
  [ "$D1" != "OK" ] && REPRO="reproduz da governanca: $D1"
  [ "$D2" != "OK" ] && REPRO="${REPRO} reproduz do plano: $D2"
  check "FR-010b" "${CANON[FR-010b]}" "alta" "$([ -z "$REPRO" ] && echo 0 || echo 1)" "$REPRO"
else
  fail "FR-010a" "${CANON[FR-010a]}" "media" "AGENTS.md ausente"
  fail "FR-010b" "${CANON[FR-010b]}" "alta" "AGENTS.md ausente"
fi

if [ -f "$CLAUDEMD" ]; then
  grep -qx '@AGENTS.md' "$CLAUDEMD"
  check "FR-011" "${CANON[FR-011]}" "alta" "$?" \
        "diretiva '@AGENTS.md' ausente como linha propria em CLAUDE.md"
else
  fail "FR-011" "${CANON[FR-011]}" "alta" "CLAUDE.md ausente na raiz do projeto"
fi

# Verdade vacua: com um dos arquivos ausente a intersecao e vazia por construcao,
# e a assercao aprovaria sobre nada. Ausencia e NAO APLICAVEL, nao conformidade —
# FR-009, FR-011 e FR-013 e que respondem pela ausencia.
if [ -f "$AGENTS" ] && [ -f "$CLAUDEMD" ]; then
  DUP="$(py_prose "$AGENTS" "$CLAUDEMD")"
  check "FR-012" "${CANON[FR-012]}" "media" "$([ "$DUP" = "OK" ] && echo 0 || echo 1)" \
        "prosa duplicada: $DUP"
else
  skip "FR-012" "${CANON[FR-012]}" "porta de entrada incompleta — nao ha par a comparar"
fi

check "FR-013" "${CANON[FR-013]}" "alta" \
      "$([ -f "$CLAUDEMD" ] && [ ! -L "$CLAUDEMD" ] && echo 0 || echo 1)" \
      "CLAUDE.md ausente ou e link simbolico (exige privilegio de administrador no Windows)"

if [ -f "$AGENTS" ] && [ -f "$CLAUDEMD" ]; then
  NA=$(wc -l < "$AGENTS"); NC=$(wc -l < "$CLAUDEMD"); NT=$((NA+NC))
  check "FR-014" "${CANON[FR-014]}" "media" \
        "$([ "$NA" -le "$BUDGET_AGENTS" ] && [ "$NT" -le "$BUDGET_TOTAL" ] && echo 0 || echo 1)" \
        "AGENTS.md=$NA (limite $BUDGET_AGENTS), soma=$NT (limite $BUDGET_TOTAL)"
else
  fail "FR-014" "${CANON[FR-014]}" "media" "porta de entrada incompleta"
fi

# =============================================================================
# GRUPO C — Ciclo de desenvolvimento
# =============================================================================
if [ -f "$CONTRIB" ]; then
  grep -q "CLARIFY" "$CONTRIB"
  check "FR-016a" "${CANON[FR-016a]}" "media" "$?" \
        "etapa de clarificacao ausente no documento de contribuicao"
else
  fail "FR-016a" "${CANON[FR-016a]}" "media" "CONTRIBUTING.md ausente"
fi

# FR-016b: escopo restrito aos documentos NORMATIVOS. Artefatos de spec e de
# evidencia ficam de fora — sao registro historico, e reescreve-los para
# satisfazer uma assercao seria falsificacao, nao conformidade.
OLDCYCLE=""
for f in "$CONTRIB" "$AGENTS" "$CLAUDEMD" "$GOV"; do
  [ -f "$f" ] || continue
  HIT="$(grep -nE '→' "$f" | grep -E 'PLAN|SPEC' | grep -v 'CLARIFY' || true)"
  [ -n "$HIT" ] && OLDCYCLE="${OLDCYCLE}${f#"$ROOT"/}: ${HIT} "
done
check "FR-016b" "${CANON[FR-016b]}" "alta" "$([ -z "$OLDCYCLE" ] && echo 0 || echo 1)" "$OLDCYCLE"

# =============================================================================
# GRUPO D — Obrigacoes herdadas do item 001
# =============================================================================
ART16=".gitignore
CONTRIBUTING.md
docs/plan/decisions.md
docs/plan/research/f0-001-git-branching.md
scripts/verify/README.md
scripts/verify/f0-001-foundation.sh
specs/001-git-branching-strategy/spec.md
specs/001-git-branching-strategy/plan.md
specs/001-git-branching-strategy/research.md
specs/001-git-branching-strategy/data-model.md
specs/001-git-branching-strategy/quickstart.md
specs/001-git-branching-strategy/tasks.md
specs/001-git-branching-strategy/contracts/oracle-cli.md
specs/001-git-branching-strategy/checklists/requirements.md
specs/001-git-branching-strategy/evidence/t015-red.txt
specs/001-git-branching-strategy/evidence/t023-green.txt"

if [ -f "$COMPLIANCE" ]; then
  AUSENTES=""
  while IFS= read -r a; do
    grep -qF -- "$a" "$COMPLIANCE" || AUSENTES="${AUSENTES}${a} "
  done <<< "$ART16"
  check "FR-017a" "${CANON[FR-017a]}" "alta" "$([ -z "$AUSENTES" ] && echo 0 || echo 1)" \
        "artefatos sem veredito: $AUSENTES"

  # Achado nao conforme reprova enquanto NAO houver decisao do mantenedor
  # registrada. Depois de registrada, aprova — e o que tasks.md T031 especifica.
  # Uma assercao que reprovasse para sempre tornaria a saida "excecao fundamentada"
  # inalcancavel: a governanca so poderia apagar a divida ou capitular diante dela.
  NAOCONF="$(grep -nE 'nao conforme|não conforme' "$COMPLIANCE" | grep -vE '^[0-9]+:>' || true)"
  if [ -z "$NAOCONF" ]; then
    pass "FR-017b" "${CANON[FR-017b]}"
  else
    DECISAO="$(py_decisao)"
    check "FR-017b" "${CANON[FR-017b]}" "critica" \
          "$([ "$DECISAO" = "OK" ] && echo 0 || echo 1)" \
          "$NAOCONF
registro da decisao incompleto — falta: $DECISAO
DECISAO DO MANTENEDOR REQUERIDA: corrigir o artefato, emendar o principio ou
registrar excecao. O oraculo nao escolhe — FR-017b proibe saida automatica."
  fi
else
  fail "FR-017a" "${CANON[FR-017a]}" "alta" "veredito retroativo ausente em ${COMPLIANCE#"$ROOT"/}"
  fail "FR-017b" "${CANON[FR-017b]}" "critica" "veredito retroativo ausente"
fi

if [ -f "$DEC" ] && grep -q "ADR-006" "$DEC"; then
  DERIV=0
  grep -q "Derivação dos princípios" "$DEC" || DERIV=1
  grep -qE 'L88.95|Self-Annealing' "$DEC" || DERIV=1
  grep -q "Data-First" "$DEC" || DERIV=1
  check "FR-018" "${CANON[FR-018]}" "alta" "$DERIV" \
        "ADR-006 nao registra a tabela de derivacao com os trechos transcritos"
else
  fail "FR-018" "${CANON[FR-018]}" "alta" "ADR-006 ausente em ${DEC#"$ROOT"/}"
fi

check "FR-019a" "${CANON[FR-019a]}" "alta" "$([ ! -e "$TRANSIT" ] && echo 0 || echo 1)" \
      "${TRANSIT#"$ROOT"/} ainda existe — a remocao e a ultima acao do ciclo (FR-019)"

if [ -f "$GITIGNORE" ]; then
  ORFA="$(grep -n 'AGENTS-EXAMPLE' "$GITIGNORE" || true)"
  check "FR-019b" "${CANON[FR-019b]}" "alta" "$([ -z "$ORFA" ] && echo 0 || echo 1)" "$ORFA"

  # SC-008: apenas exclusoes MARCADAS sao cobradas (ADR-006, research E3).
  ORFAS=""
  while IFS= read -r ln; do
    pat="$(printf '%s' "$ln" | sed 's#/$##')"
    [ -n "$pat" ] || continue
    [ -e "$ROOT/$pat" ] || ORFAS="${ORFAS}${pat} "
  done < <(awk '/^# transitorio:/{flag=1;next} /^#/{next} /^[[:space:]]*$/{flag=0;next} flag{print}' "$GITIGNORE")
  check "SC-008" "${CANON[SC-008]}" "media" "$([ -z "$ORFAS" ] && echo 0 || echo 1)" \
        "regras transitorias sem alvo: $ORFAS"
else
  fail "FR-019b" "${CANON[FR-019b]}" "alta" ".gitignore ausente"
  fail "SC-008" "${CANON[SC-008]}" "media" ".gitignore ausente"
fi

# =============================================================================
# GRUPO E — Meta e nao regressao
# =============================================================================
if [ "${FKX_ORACLE_NESTED:-0}" = "1" ]; then
  skip "FR-020a" "${CANON[FR-020a]}" "execucao aninhada — evita recursao"
  skip "FR-020b" "${CANON[FR-020b]}" "execucao aninhada — evita recursao"
  skip "FR-020c" "${CANON[FR-020c]}" "execucao aninhada — evita recursao"
else
  "$SELF" --list >/dev/null 2>&1;             RC_LIST=$?
  "$SELF" --parametro-invalido >/dev/null 2>&1; RC_BAD=$?
  check "FR-020a" "${CANON[FR-020a]}" "alta" \
        "$([ "$RC_LIST" -eq 0 ] && [ "$RC_BAD" -eq 2 ] && echo 0 || echo 1)" \
        "--list=$RC_LIST (esperado 0), parametro invalido=$RC_BAD (esperado 2)"

  N_LIST="$("$SELF" --list | wc -l)"
  N_CANON="$(printf '%s' "$CANON_ORDER" | wc -w)"
  Q_OUT="$(FKX_ORACLE_NESTED=1 "$SELF" --quiet 2>&1 | grep -c '^✅' || true)"
  check "FR-020b" "${CANON[FR-020b]}" "alta" \
        "$([ "$N_LIST" -eq "$N_CANON" ] && [ "$Q_OUT" -eq 0 ] && echo 0 || echo 1)" \
        "--list enumerou $N_LIST de $N_CANON; --quiet exibiu $Q_OUT aprovacoes (esperado 0)"

  TMPD="$(mktemp -d)"
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r1" 2>&1
  FKX_ORACLE_NESTED=1 "$SELF" > "$TMPD/r2" 2>&1
  cmp -s "$TMPD/r1" "$TMPD/r2"
  check "FR-020c" "${CANON[FR-020c]}" "alta" "$?" \
        "duas execucoes divergiram: $(diff "$TMPD/r1" "$TMPD/r2" | head -3 | tr '\n' ' ')"
fi

SHA_ATUAL="$(py_sha "$ORACLE1")"
check "FR-021a" "${CANON[FR-021a]}" "alta" \
      "$([ "$SHA_ATUAL" = "$HASH_F0_001" ] && echo 0 || echo 1)" \
      "resumo atual : $SHA_ATUAL
resumo fixado: $HASH_F0_001
ADR-002/ADR-006: divergencia sobe para DECISAO EXPLICITA, nunca para atualizacao
do valor fixado — atualizar o numero e a forma exata de derrotar esta assercao."

if [ -x "$ORACLE1" ]; then
  "$ORACLE1" --quiet >/dev/null 2>&1
  check "FR-021b" "${CANON[FR-021b]}" "alta" "$?" \
        "o oraculo do item 001 deixou de aprovar — regressao no item anterior"
else
  fail "FR-021b" "${CANON[FR-021b]}" "alta" "oraculo do item 001 ausente ou nao executavel"
fi

if [ -f "$RED" ] && [ -f "$GREEN" ]; then
  cmp -s "$RED" "$GREEN"
  check "FR-022" "${CANON[FR-022]}" "media" "$([ $? -ne 0 ] && echo 0 || echo 1)" \
        "evidencias vermelha e verde sao identicas — o ciclo nao foi observado"
else
  fail "FR-022" "${CANON[FR-022]}" "media" \
       "evidencia ausente: vermelha=$([ -f "$RED" ] && echo sim || echo NAO), verde=$([ -f "$GREEN" ] && echo sim || echo NAO)"
fi

if [ -f "$SPEC" ]; then
  CTR=0
  grep -q "Entregue por este item" "$SPEC" || CTR=1
  grep -q "Transferido a itens posteriores" "$SPEC" || CTR=1
  check "FR-023" "${CANON[FR-023]}" "media" "$CTR" "secao Contratos incompleta na spec"
else
  fail "FR-023" "${CANON[FR-023]}" "media" "spec.md ausente"
fi

# SC-006: o valor medido so aparece na evidencia quando REPROVA, preservando
# FR-020c — duas execucoes aprovadas produzem saida byte a byte identica.
check "SC-006" "${CANON[SC-006]}" "alta" "$([ "$SECONDS" -lt 5 ] && echo 0 || echo 1)" \
      "tempo decorrido: ${SECONDS}s (limite 5s)"

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
