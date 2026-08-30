# Phase 1 — Quickstart: validação do item 002

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30

Roteiro de validação executável. Nove cenários: sete decididos pela máquina, dois
que **exigem julgamento humano** — e estão aqui exatamente porque o oráculo não
consegue decidi-los, não porque foram esquecidos.

Pré-requisitos: nenhum além de shell, git e Python 3.12. Nenhuma dependência do
projeto é necessária neste ponto do bootstrap.

---

## Cenário 1 — O oráculo reprova antes da implementação 🔴

```bash
scripts/verify/f0-002-constitution.sh
echo "exit=$?"
```

**Esperado**: `exit=1`, com reprovação nominal em `FR-001` (governança ainda em
branco), `FR-009`, `FR-011` (porta de entrada inexistente) e `FR-017a`
(veredito retroativo inexistente). `FR-019a` reprova por design — o material
transitório ainda precisa existir nesta fase.

Saída preservada em `evidence/red.txt`. **Este cenário não é repetível depois da
implementação**: é a única prova de que o teste veio antes.

---

## Cenário 2 — Nenhum campo de preenchimento sobrou

```bash
python3 - <<'PY'
import re, pathlib
t = pathlib.Path('.specify/memory/constitution.md').read_text(encoding='utf-8')
t = re.sub(r'<!--.*?-->', '', t, flags=re.S)
print(sorted(set(re.findall(r'\[[A-Z][A-Z0-9_]*\]', t))))
PY
```

**Esperado**: `[]`. Antes da ratificação a mesma consulta devolve 19 tokens.

---

## Cenário 3 — Os dez princípios são decidíveis 🧑 *(julgamento humano)*

Para **cada** princípio `I`–`X`, escolher um artefato real do repositório e
responder: *"este artefato viola este princípio?"*

**Esperado**: dez respostas `sim`/`não` emitidas **sem discutir o que o princípio
quis dizer**. Se a resposta exigir interpretação da intenção, o princípio falhou
`FR-005` e precisa ganhar critério objetivo ou ser rebaixado a orientação não
normativa.

O oráculo verifica que o critério de violação **existe e está rotulado**
(`FR-005b`); ele não verifica se o critério é bom. Essa distinção é deliberada —
uma asserção que pretendesse julgar qualidade de redação aprovaria sempre.

---

## Cenário 4 — A porta de entrada cabe no orçamento

```bash
a=$(wc -l < AGENTS.md); c=$(wc -l < CLAUDE.md)
echo "AGENTS.md=$a  CLAUDE.md=$c  soma=$((a+c))  (limites: 150 / — / 175)"
```

**Esperado**: `AGENTS.md ≤ 150` e `soma ≤ 175`.

---

## Cenário 5 — Os dois arquivos não duplicam prosa

```bash
python3 - <<'PY'
import re, pathlib
def prose(p, minlen=40):
    out, fence = set(), False
    for ln in pathlib.Path(p).read_text(encoding='utf-8').splitlines():
        s = ln.strip()
        if s.startswith('```'): fence = not fence; continue
        if fence or not s: continue
        if s[0] in '#|>' or s.startswith('---') or s.startswith('<!--'): continue
        s = re.sub(r'\s+', ' ', s).lower()
        if len(s) >= minlen: out.add(s)
    return out
dup = prose('AGENTS.md') & prose('CLAUDE.md')
print('duplicadas:', len(dup)); [print('  >', d[:100]) for d in sorted(dup)]
PY
```

**Esperado**: `duplicadas: 0`.

---

## Cenário 6 — O agente construtor carrega a orientação sozinho 🧑 *(julgamento humano)*

Abrir uma sessão nova do agente construtor na raiz do projeto e perguntar algo
que só a porta de entrada responde — por exemplo, qual é a etapa do ciclo
canônico entre especificação e planejamento.

**Esperado**: resposta correta **sem nenhuma ação manual** de carregamento.

Este é o cenário que fecha `FR-011` de verdade. O oráculo verifica apenas que a
diretiva de importação está no lugar documentado pelo fornecedor: um script não
observa o contexto carregado por outro processo (research E6). Verde no oráculo e
falha aqui significa que a documentação do fornecedor mudou — e a asserção
mecânica precisa ser revista, não contornada.

---

## Cenário 7 — O oráculo anterior está íntegro e continua aprovando

```bash
sha256sum scripts/verify/f0-001-foundation.sh
scripts/verify/f0-001-foundation.sh --quiet; echo "exit=$?"
```

**Esperado**: resumo igual a `63412ca7…5a6bbf22` e `exit=0`.

Um resumo diferente significa que a regra de não regressão foi quebrada — o
achado sobe para decisão explícita, **nunca** para atualização do valor fixado.
Atualizar o valor para fazer a asserção passar é a forma exata de derrotá-la.

---

## Cenário 8 — Harness acumulado, com tempo por oráculo

```bash
for f in scripts/verify/f0-*.sh; do
  /usr/bin/time -f "$f real=%e" "$f" --quiet || { echo "REPROVOU: $f"; exit 1; }
done
```

**Esperado**: dois oráculos, ambos `exit=0`, **cada um** abaixo de 5 s (SC-006).
A execução conjunta é a soma; não há teto agregado nesta fase — a decisão sobre
teto agregado foi transferida ao item 008.

---

## Cenário 9 — Determinismo e ausência de resíduo

```bash
scripts/verify/f0-002-constitution.sh > /tmp/r1.txt 2>&1
scripts/verify/f0-002-constitution.sh > /tmp/r2.txt 2>&1
diff /tmp/r1.txt /tmp/r2.txt && echo "IDENTICO"
git status --porcelain
```

**Esperado**: `IDENTICO`, e `git status` sem nenhuma alteração provocada pelas
execuções. Um oráculo que altera o estado que mede não é oráculo.

---

## Critério de conclusão

| Cenário | Verificação | Requisito |
|---|---|---|
| 1 | vermelho preservado | FR-022, SC-005 |
| 2 | zero campos em aberto | FR-001, SC-001 |
| 3 | 🧑 dez princípios decidíveis | FR-005, SC-002 |
| 4 | orçamento respeitado | FR-014, SC-003 |
| 5 | zero prosa duplicada | FR-012 |
| 6 | 🧑 carregamento automático | FR-011, SC-004 |
| 7 | oráculo anterior íntegro e aprovando | FR-021 |
| 8 | harness acumulado, < 5 s por oráculo | SC-006 |
| 9 | determinismo, sem resíduo | FR-020c |

Os cenários 3 e 6 são os únicos que a máquina não decide. Estão nomeados como
tais para que sua ausência seja visível — um roteiro que escondesse os limites do
próprio harness daria a impressão de cobertura total.
