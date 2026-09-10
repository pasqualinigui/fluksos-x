# CHECKPOINT — Pré-`018`: cobertura do portão e o custo do vermelho

> **Data**: 2026-09-10 · **Classe**: checkpoint não-item (molde ADR-014), pré-`018`
> **Escopo**: quem executa os oráculos da Fase 1 · o mecanismo que torna
> `--no-verify` obrigatório no portão vermelho · estado dos gatilhos de CI/CD ·
> força normativa das §§5-6 do checkpoint pré-Fase 1
> **Origem**: pergunta do mantenedor em sessão 2026-09-10 — *"vejo muitos commits
> com `--no-verify`; se o problema existe e é detectado, deve ser ajustado"*.
> **Método**: varredura mecânica dos 17 oráculos por `grep -n "scripts/verify/f0-"`
> e leitura do código de cada FR citada · `grep -rn "f1-"` em `.github/`,
> `lefthook.yml`, `tests/`, `scripts/` · contagem `git log --grep` sobre 141 commits ·
> leitura integral de `lefthook.yml`, `ci.yml`, `release.yml`,
> `dependabot-automerge.yml` · medição de tempo de `f1-017` aninhado e isolado.
> Nenhuma conclusão por memória.
> **Destino das decisões deste relatório**: `docs/plan/decisions.md` (ADR-043,
> ADR-044, ADR-045, carimbadas como aceitas em 2026-09-10). Este arquivo é
> **evidência**; a norma vive nas ADRs. Nada aqui é auto-aplicável.

---

## 1. Veredito

Dois defeitos e uma dívida. Nenhum é de execução da 017 — todos são de
**desenho do portão**, herdados de quando só existia a Fase 0.

1. **A `017` convergiu fora de todo portão automático** (§2). Defeito vivo,
   princípio VI. Correção autorizada por ADR-043, fronteira zero.
2. **O `pre-commit` torna o portão vermelho impossível** (§3). Não é preguiça
   de agente: é o teorema da ADR-034 §6, pago só pelo `pip-audit` e nunca
   generalizado ao `pytest`. Correção autorizada por ADR-044, 1 ponto de
   fronteira.
3. **As normas §5 e §6 do checkpoint pré-Fase 1 não são exigíveis** (§4). Prosa
   em auditoria, sem ADR e sem oráculo. Promovidas por ADR-045; a asserção é
   herdada pela `018`.

O que **não** é defeito: a organização de CI/CD (§5). Os gatilhos estão
disciplinados e a resposta que o agente deu sobre push-por-documento está
correta — o que falta a ela é oráculo, não razão.

---

## 2. Achado 1 — cegueira de fase do portão (evidência)

```
$ grep -rn "f1-" .github/ lefthook.yml tests/ scripts/
scripts/verify/f1-017-harness.sh:14:#   docs/plan/research/f1-017-harness.md
scripts/verify/manifest.sha256:17:cd63b011...  scripts/verify/f1-017-harness.sh
```

Duas ocorrências: o próprio script e a sua linha de manifest. **Nenhum
executor.** Os quatro pontos que rodam o harness enumeram por `f0-*`:

| Ponto | Forma vigente | Alcança `f1-017`? |
|---|---|---|
| `ci.yml` job `verify` | `for f in scripts/verify/f0-*.sh` | não |
| `ci.yml` job `harness` | `for f in scripts/verify/f0-*.sh` | não |
| `lefthook.yml` `pre-push.harness` | `for f in scripts/verify/f0-*.sh` | não |
| `tests/test_harness_oracles.py` | `glob("f0-*.sh")` | não |
| `AGENTS.md` › *How to operate* | `for f in scripts/verify/f0-*.sh` | não |

Consequência: o verde 17/17 registrado na convergência da 017 só existe porque
o operador acrescentou o glob à mão. O servidor — que a ADR-035 define como o
único decisor — nunca executou `f1-017`.

**Mapa de congelamento** (por que a correção é acréscimo, nunca substituição):

| Oráculo | FR | Forma asserida |
|---|---|---|
| `f0-003` | FR-010 | literal cheio `for f in scripts/verify/f0-*.sh` |
| `f0-004` | FR-017 | prefixo `for f in scripts/verify/f0-` |
| `f0-005` | FR-012 | prefixo `for f in scripts/verify/f0-` |
| `f0-005` | FR-005 | cadeia `f0-` em `test_harness_oracles.py` |
| `f0-006` | FR-012 | prefixo `for f in scripts/verify/f0-` |
| `f0-007` | FR-012 | prefixo `for f in scripts/verify/f0-` |
| `f0-008` | FR-011 | prefixo `for f in scripts/verify/f0-` |
| `f0-009` | FR-005, FR-009 | prefixo `for f in scripts/verify/f0-` |

Oito asserções em sete oráculos convergidos. Substituir por glob genérico
reprova todos; **acrescentar um segundo laço preserva todos**. Destino: ADR-043.

**Custo medido** (não estimado):

```
$ FKX_ORACLE_NESTED=1 f1-017-harness.sh --quiet   ->  0,06 s   (12/12)
$ f1-017-harness.sh --quiet                        -> 13,08 s   (12/12)
```

`f1-017` respeita `FKX_ORACLE_NESTED`, logo a promoção a pytest custa ~0,06 s e
o CI ganha ~13 s por job de harness. Tetos de 10 min intactos.

---

## 3. Achado 2 — o `pre-commit` torna o portão vermelho impossível

### O mecanismo

`lefthook.yml` › `pre-commit` roda `uv run pytest -q`. A Regra 2 exige um commit
onde o teste **reprova**. Os dois não podem coexistir. O agente da 017 registrou
o fato na mensagem de `d4a5d3a`, sem esconder:

> *"Commit com --no-verify (precedente ADR-034 secao 6): o hook pytest reprova o
> vermelho por desenho; ruff/format/mypy executados a mao e verdes (este
> registro e a prova)."*

O teorema já existia. A ADR-034 §6 o enunciou sobre o `pip-audit` — *"um gate de
vulnerabilidade em `pre-commit` converte 'corrigir a vulnerabilidade' em operação
impossível"* — e a ADR-036 o pagou **só para aquele caso**. O enunciado geral não
é sobre vulnerabilidade; é sobre a natureza do verificador: **resultado** no
`pre-commit` mata o 🔴, **forma** não.

### A medição

```
$ git rev-list --count HEAD                        -> 141
$ git log --format=%h --grep='no-verify' | wc -l   ->   6
```

`d4a5d3a`, `80f70c2`, `e73d9a7`, `9aa5481`, `0228d9d`, `90cd548` — todos
declaram o bypass no corpo. Mas git **não registra** que um hook foi pulado:
`6` é piso, não contagem. Uma norma cuja adesão não é mensurável não é norma.

### O que a correção alcança, e o que não alcança

| Ponto do ciclo | Antes | Depois da ADR-044 |
|---|---|---|
| commit 🔴 | bypass **obrigatório** | passa no trio estático, sem bypass |
| push do 🔴 (§6 ponto 1) | bypass obrigatório | **continua** obrigatório |
| commit/push 🟢 | verde natural | verde natural |
| integração | 10 checks sem-bypass | inalterado |

O push do 🔴 só deixa de exigir bypass quando a expectativa for **invertida**
deterministicamente — não suprimida. É FR-α/FR-β da ADR-045, e a semântica já
existe: a 017 entregou `harness.run` → `Veredito`, onde não conformidade
**declarada** é conformidade (princípio I: a regra decide, o modelo só roteia).

E o limite de fundo é o da ADR-009: `--no-verify` é flag do cliente git, não se
proíbe de dentro do repositório. O que se remove é a **necessidade**; o que
neutraliza vive no servidor.

### Prova de discriminação da FR-008 reescrita

Uma asserção que não reprova o estado errado é tautologia — o modo exato de
derrotar um oráculo sem tocar no seu resumo. Sonda executada nesta sessão, com
restauração garantida:

```
isca (pytest de volta ao pre-commit):
  🔴 FR-008  pytest e pip-audit no pre-push, fora do pre-commit
  Resultado: 10/11 — NAO CONFORME

estado correto (restaurado):
  ✅ FR-008  pytest e pip-audit no pre-push, fora do pre-commit
  Resultado: 11/11 — CONFORME
```

A FR discrimina nas duas direções. `f0-009` FR-003 permanece verde em ambos os
estados, como previsto: ela assere ordem por número de linha e presença no
arquivo, jamais a seção — verificado por leitura do código, não por suposição.

---

## 4. Achado 3 — normas sem oráculo

```
$ grep -n "Regra de fallback\|disciplina de push" docs/plan/decisions.md  -> vazio
$ grep -rn "checkpoint-pre-fase1" scripts/verify/*.sh                     -> vazio
```

§5 (forma fixa do fallback) e §6 (2 pontos de push) do checkpoint pré-Fase 1
vivem **apenas** naquele documento de auditoria. Pelo princípio VI não são
exigíveis; pelo princípio I são julgamento de sessão — o que o mantenedor
identificou como *"escolha do modelo"*.

Adicionalmente, `f1-017` FR-009 verifica o par vermelho→verde por posição de
linha no `git log`:

```
RED_LINE=$(git log --oneline | grep -n "test(harness).*017" | head -1 | cut -d: -f1)
GREEN_LINE=$(git log --oneline | grep -n "feat(harness).*017" | head -1 | cut -d: -f1)
```

Isso prova **ordem**, jamais **genuinidade**: um 🔴 fabricado com `red.txt`
escrito à mão passa. Destino: ADR-045, FR-α e FR-β.

---

## 5. Não-achado — CI/CD está organizado

Conferido por leitura integral dos três workflows:

| Aspecto | Estado |
|---|---|
| Gatilhos | `ci.yml`: `push`/`pull_request` restritos a `[main, develop]` · `release.yml`: só tag `v*` · `dependabot-automerge.yml`: só `pull_request` |
| Privilégio | `permissions: contents: read` em todos |
| Pinagem | todo `uses:` por SHA de 40 hex + versão legível em comentário |
| Tetos | `timeout-minutes` em todos os jobs |
| Determinismo | `COLUMNS=80`, `uv sync --frozen`, matriz 3.12/3.13 com `fail-fast: false` |

**Nenhum workflow dispara por documento gerado.** A pergunta do mantenedor
("push a cada documento é o padrão?") foi respondida corretamente em
`f1-checkpoint-pre-fase1.md` §6: nem push-por-documento, nem spec inteira antes
do push, mas **2 pontos fixos** — no 🔴 (a prova é irrecuperável se a estação
morrer entre 🔴 e 🟢 com o vermelho só local) e no CONVERGE. O raciocínio é
sólido; falta-lhe oráculo, e é o que a ADR-045 FR-γ endereça junto da cobertura
de fase.

---

## 6. Destino (nada aqui é auto-aplicável)

| Achado | ADR | Aplicação | Fronteira |
|---|---|---|---|
| §2 cegueira de fase | **ADR-043** | Bloco A, neste checkpoint | nenhuma |
| §3 teorema do `pre-commit` | **ADR-044** | Bloco B, neste checkpoint | 1 ponto: `f0-014` FR-008 |
| §4 normas sem oráculo | **ADR-045** | FRs herdadas pela `018` | nenhuma aqui |

Precedente para aplicar sob ADR sem spec nova — manutenção corretiva de
artefato já convergido, executada seis vezes:

```
928f727  ADR-035  criou scripts/governance/apply-adr-035.sh
f162287  ADR-037  alterou o oráculo convergido f0-006
464df63  ADR-031  alterou oráculos (self-check serial)
ea681d1  ADR-031  reescreveu ci.yml
9613c1c  ADR-030  alterou ci.yml
ee49723  ADR-029  alterou f0-001 FR-001
```

Todos em commit único, com `fix(...)`/`ci:`/`build(deps):`. A Regra 2 (par
🔴→🟢) governa **requisito de item**; manutenção corretiva de artefato já
especificado corre por ADR. Spec nova governa **capacidade nova** — e não há
capacidade nova aqui.

## 7. Revisão datada

Junto da auditoria pós-`020` (`017–020`, ADR-040 › Cadência): reavaliar se
FR-α/FR-β eliminaram o resíduo de `--no-verify` no push do 🔴, e medir quantos
commits do intervalo declararam bypass. Duas amostras de bypass **não
declarado** no mesmo intervalo disparam investigação pela ADR-019 §4.

### Amostra de transiente observada nesta sessão (família E4)

Durante a execução deste checkpoint, `f0-016` FR-009 reprovou uma vez com
`f0-007-mypy.sh --quiet reprovou (rc=1)`. Verificação imediata: `f0-007`
isolado 16/16 CONFORME, e `f0-016` 3/3 CONFORME em repetição. É a família E4
(`timeout 5` sobre oráculo aninhado sob contenção), já documentada em
`f1-checkpoint-pre-fase1.md` E4 — **1 amostra**, registrada aqui para a
contagem da ADR-019 §4. Não houve verde-falso: o vermelho apontou estado
correto medido sob carga, não estado incorreto.

Esta é, também, a origem exata do `--no-verify` no push do checkpoint anterior
(§5 daquele relatório). O resíduo tratado na ADR-045 é o mesmo fenômeno.
