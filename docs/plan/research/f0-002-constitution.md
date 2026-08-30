# RESEARCH — F0/002 · Constitution + AGENTS.md

> **Item do plano:** 0.11 (§17 Fase 0) · **Ordem de execução:** 002/012
> **Data da verificação:** 2026-08-29 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/001-git-branching-strategy/spec.md` › Contratos (vinculante)

---

## Q1 — O que o `speckit-constitution` exige mecanicamente?

Fonte: `.claude/skills/speckit-constitution/SKILL.md`, lido integralmente.

| Exigência | Linha | Consequência para este item |
|---|---|---|
| Substituir **todo** token `[ALL_CAPS]`; qualquer remanescente exige justificativa explícita | 95, 109 | Os **19** placeholders precisam sumir ou ser justificados um a um |
| `CONSTITUTION_VERSION` segue versionamento semântico — MAJOR remove/redefine, MINOR acrescenta, PATCH esclarece | 102–105 | Primeira ratificação é **1.0.0** |
| **Sync Impact Report** prefixado como comentário HTML no topo do arquivo | 114–119 | Artefato obrigatório, não opcional |
| Seção Governance lista procedimento de emenda, política de versionamento e expectativa de revisão de conformidade | 112 | Três subseções obrigatórias |
| Princípios **declarativos, testáveis e sem linguagem vaga** — "should" vira MUST/SHOULD com razão | 125 | Princípio não verificável é defeito, não estilo |
| Datas em ISO `YYYY-MM-DD` | 124 | |
| Escrever de volta em `.specify/memory/constitution.md` (sobrescrever) | 6 | |
| **Proibido** criar/modificar/apagar fonte de aplicação | 31 | O item 002 não toca código |

> **Correção aplicada em 2026-08-30.** Esta linha registrava "18 placeholders",
> número obtido por contagem visual e não por medição. A medição feita na pesquisa
> técnica do plano (`specs/002-constitution-ratification/research.md`, E4) apurou
> **19** distintos fora de comentário HTML — 20 contando os que aparecem dentro de
> comentário. A correção não altera nenhuma decisão C1–C9; entra aqui porque este
> documento se declara vinculante e afirma não usar dado por memória.

**Decisão:** seguir o protocolo do skill à risca, incluindo o Sync Impact Report.
**Alternativa rejeitada:** redigir a constitution à mão ignorando o skill —
perderia o relatório de impacto e a política de versionamento que os itens
003–012 vão consumir.

---

## Q2 — Sobrescrever `constitution.md` quebra algum controle?

```
$ sha256sum .specify/memory/constitution.md
ce7549540fa45543cca797a150201d868e64495fdff39dc38246fb17bd4024b3
$ sha256sum .specify/templates/constitution-template.md
ce7549540fa45543cca797a150201d868e64495fdff39dc38246fb17bd4024b3
$ cat .specify/memory/.constitution-template.json
{"sha256": "ce7549...4024b3", "source": "core"}
```

**Achado:** o hash registrado bate com **os dois** arquivos — confirma que a
constitution atual é cópia intocada do template. Busca por validação:

```
$ grep -rn "constitution-template.json\|sha256" .specify/scripts/
(nenhuma referência)
```

**Decisão:** o `.constitution-template.json` é **metadado de proveniência, não
validação**. Nenhum script o confere. Sobrescrever `constitution.md` é seguro e
o hash deixará de bater — o que é o sinal correto de "customizada".
**Consequência registrada:** o diff da ratificação fica auditável justamente
porque o item 001 versionou o template em branco (ADR-005).

---

## Q3 — `AGENTS.md` é padrão real ou convenção informal?

```
$ curl -o /dev/null -w '%{http_code}' https://agents.md/                → 200
$ curl -o /dev/null -w '%{http_code}' .../openai/agents.md/README.md    → 200
```

Conteúdo verificado: *"A simple, open format for guiding coding agents, used by
over 60k open-source projects. Think of AGENTS.md as a README for agents."*

**Achado estrutural:** o formato **não impõe esquema**. O README canônico traz
apenas seções convencionais — *Dev environment tips*, *Testing instructions*,
*PR instructions* — como exemplo, não como obrigação. É convenção de
**localização**, não de estrutura.

**Decisão:** adotar `AGENTS.md` como porta de entrada, com seções livres
adequadas ao motor, sem forçar o exemplo do README canônico.

---

## Q4 — 🔴 O Claude Code lê `AGENTS.md`?

Fonte: `https://code.claude.com/docs/en/memory.md` (36.982 bytes, HTTP 200 após
redirecionamento de `docs.claude.com`).

> *"Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If your repository already
> uses `AGENTS.md` for other coding agents, create a `CLAUDE.md` that imports it
> so both tools read the same instructions without duplicating them."*

### 🔴 Achado crítico

O §6 do plano afirma que *"a CLI terá um AGENTS.md próprio que qualquer agente
(Antigravity, Claude Code, Copilot, etc.) pode ler como skill/constitution"*.
**A premissa é falsa para o Claude Code** — que é justamente o agente que está
construindo este motor. Criar apenas `AGENTS.md` deixaria o construtor cego para
a própria constitution do que constrói.

### Opções verificadas na documentação

| Opção | Mecânica | Avaliação |
|---|---|---|
| `CLAUDE.md` contendo `@AGENTS.md` | Importa no início da sessão e permite acrescentar instruções específicas abaixo | **Recomendada pela própria doc**, multiplataforma |
| `ln -s AGENTS.md CLAUDE.md` | Documentado, porém *"On Windows, creating a symlink requires Administrator privileges or Developer Mode"* | Rejeitada — artefato versionado com comportamento dependente de plataforma |
| Apenas `CLAUDE.md` | — | Rejeitada — abandona o padrão aberto e fecha o motor a outros agentes |

**Decisão:** `AGENTS.md` é a **fonte única**; `CLAUDE.md` contém `@AGENTS.md` mais
uma seção curta específica do Claude Code. Sem duplicação de texto.

---

## Q5 — 🔴 Restrição de tamanho que muda o desenho

Mesma fonte, duas passagens:

> *"**Size**: target under 200 lines per CLAUDE.md file. Longer files consume more
> context and reduce adherence."*
>
> *"Splitting into `@path` imports helps organization but **doesn't reduce
> context**, since imported files load at launch."*

### Achado

O limite é de **adesão**, não de capacidade — passar de 200 linhas faz o agente
**obedecer menos**. E imports **não** contornam: o conteúdo importado entra no
contexto do mesmo jeito. Portanto `AGENTS.md` + `CLAUDE.md` somados precisam
caber no orçamento.

Tamanhos aferidos dos artefatos que competiriam pelo mesmo espaço:

| Arquivo | Linhas |
|---|---|
| `CONTRIBUTING.md` | 192 |
| `docs/plan/decisions.md` | 221 |
| `docs/plan/implementation_plan.md` | **1014** |

**Decisão:** `AGENTS.md` fica **abaixo de 150 linhas**, contendo identidade,
regras operacionais e **ponteiros**. Nunca o texto integral dos princípios, nem
cópia do plano.

Isto **valida empiricamente** a ADR-003, que separava fonte normativa de porta de
entrada por argumento de governança. Agora há uma segunda razão, mensurável:
inflar o `AGENTS.md` degrada a adesão do agente a ele.

**Divisão resultante:**

| Artefato | Papel | Quem lê | Quando |
|---|---|---|---|
| `.specify/memory/constitution.md` | Fonte **normativa** — princípios completos com rationale | `speckit-plan`, `speckit-analyze` | Sob demanda, no ciclo |
| `AGENTS.md` | Porta de entrada operacional, < 150 linhas | Qualquer agente | Toda sessão |
| `CLAUDE.md` | `@AGENTS.md` + seção específica | Claude Code | Toda sessão |

---

## Q6 — Como os comandos consomem a constitution?

```
speckit-plan:60     Read FEATURE_SPEC and `.specify/memory/constitution.md`
speckit-plan:66     Fill Constitution Check section from constitution
speckit-analyze:66  Constitution conflicts are automatically CRITICAL
speckit-analyze:256 Prioritize constitution violations (these are always CRITICAL)
plan-template:39    ## Constitution Check
```

**Achado:** a partir da ratificação, todo `/speckit-plan` preenche o portão a
partir da constitution real, e todo `/speckit-analyze` trata violação como
**CRITICAL automático**. O portão substituto usado nos itens 001 e 002 deixa de
existir.

**Consequência direta:** um princípio redigido de forma não verificável vira
ruído em onze ciclos. Daí a exigência do skill (linha 125) de princípios
declarativos e testáveis ser tratada aqui como requisito, não como estilo.

---

## Q7 — Capacidade do template

```
$ grep -cE '^### \[PRINCIPLE_[0-9]+_NAME\]' .specify/templates/constitution-template.md
5
$ grep -oE '\[SECTION_[0-9]+_NAME\]' ...
[SECTION_2_NAME] [SECTION_3_NAME]
```

Comentário do próprio template no slot 5:
`<!-- Example: V. Observability, VI. Versioning & Breaking Changes, VII. Simplicity -->`

**Achado:** os 5 slots **não** limitam a 5 princípios — o template exemplifica
três princípios num único slot. Os 10 princípios previstos cabem.

**Decisão:** manter a numeração romana contínua (I…X) e usar as duas seções
extras para restrições adicionais e fluxo de desenvolvimento.

---

## Q8 — Obrigações herdadas do item 001

Fonte: `specs/001-git-branching-strategy/spec.md` › Contratos › Transferido.

| # | Obrigação | Origem |
|---|---|---|
| 1 | **Revalidação retroativa** dos artefatos do item 001 contra a constitution ratificada | ADR-003 |
| 2 | **Consultar** `docs/AGENTS-EXAMPLE.md` ao redigir a constitution | ADR-004 |
| 3 | **Remover** o arquivo **e** a entrada transitória do `.gitignore` | ADR-004 |

Estado verificado do insumo:

```
docs/AGENTS-EXAMPLE.md          119 linhas, presente em disco, fora do versionamento ✅
.gitignore                      1 entrada transitória ✅
```

**Decisão:** as três entram como requisitos da spec do item 002, não como notas.
A terceira tem ordem obrigatória: **remover só depois** de a constitution estar
ratificada e revisada, porque é a última chance de consultar o material.

---

## Resumo das decisões

| # | Decisão | Fonte |
|---|---|---|
| C1 | Seguir o protocolo do `speckit-constitution`, com Sync Impact Report | Q1 |
| C2 | Primeira ratificação é **1.0.0** | Q1 (regra semântica do skill) |
| C3 | Sobrescrever `constitution.md` é seguro — o hash é proveniência, não validação | Q2 |
| C4 | `AGENTS.md` como fonte única + `CLAUDE.md` com `@AGENTS.md` | **Q4 — o Claude Code não lê AGENTS.md** |
| C5 | Symlink rejeitado: exige privilégio de administrador no Windows | Q4 |
| C6 | `AGENTS.md` **< 150 linhas**, só ponteiros — imports não reduzem contexto | **Q5 — acima de 200 linhas a adesão cai** |
| C7 | Princípios declarativos e **testáveis**; princípio não verificável é defeito | Q1 linha 125 + Q6 |
| C8 | 10 princípios em numeração contínua I–X; os 5 slots não limitam | Q7 |
| C9 | As 3 obrigações herdadas viram requisitos; a remoção do material vem **por último** | Q8 |

**Nenhum `NEEDS CLARIFICATION` remanescente.**

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **todos (003–012)** | Portão constitucional **real** — o substituto deixa de existir |
| **todos** | `AGENTS.md` + `CLAUDE.md` como porta de entrada operacional |
| **001 (retroativo)** | Revalidação dos artefatos já entregues contra os princípios ratificados |
| **008** (Lefthook) | Princípios que o enforcement automático precisa refletir |
