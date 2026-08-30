# Phase 0 — Research: Ratificação da Governança e Porta de Entrada

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30
**Método**: verificação empírica na máquina alvo. Nenhuma decisão por memória.
**Insumo anterior**: `docs/plan/research/f0-002-constitution.md` (C1–C9, vinculante, não reaberto)

A pesquisa de domínio já fechou **o quê** (C1–C9): protocolo de ratificação,
`AGENTS.md` como fonte única, `CLAUDE.md` importando-a, orçamento de tamanho,
princípios decidíveis, obrigações herdadas. Esta pesquisa resolve **como medir** —
os mecanismos de asserção que o oráculo `f0-002` precisa implementar.

Oito experimentos. **Dois refutaram premissas** que estavam prestes a entrar no
desenho sem verificação.

---

## E1 — Custo do oráculo do item 001 e viabilidade do aninhamento

`FR-021` exige que o oráculo anterior continue aprovando. A forma mais direta é
executá-lo de dentro do `f0-002` — mas o `f0-001` já executa a si mesmo duas vezes
(auto-verificação de códigos de saída e do caso sem repositório).

```
run1 real=0.32s   run2 real=0.29s   run3 real=0.28s
exit=0            assercoes (--list)=30
```

**Achado:** o custo total, aninhamento incluído, é ~0,3 s. Invocá-lo consome 6 %
do orçamento de 5 s (SC-006). Não há necessidade de mecanismo indireto.

**Decisão D1:** `f0-002` invoca `f0-001 --quiet` e exige código de saída `0`.

---

## E2 — Como provar que o oráculo anterior está *inalterado*

Executá-lo e obter `0` prova que ele **aprova**, não que está **íntegro**. Um item
futuro poderia enfraquecer uma asserção e continuar saindo `0` — exatamente a
regressão silenciosa que a ADR-002 proíbe, e que nenhuma execução detecta.

```
$ sha256sum scripts/verify/f0-001-foundation.sh
63412ca7a9ada4af0e435db89fdbb649423b56005dfd2908c59ba2745a6bbf22
```

**Decisão D2:** o resumo criptográfico do `f0-001` é **fixado** dentro do `f0-002`
e registrado em `docs/plan/decisions.md` (ADR-006), tornando a regra "um item
nunca modifica o oráculo de um item anterior" **mecanicamente verificável** em vez
de acordada. `FR-021` vira duas asserções: integridade (`FR-021a`) e aprovação
(`FR-021b`).

**Alternativa rejeitada:** confiar na revisão de diff. É julgamento humano — o
mesmo que o harness existe para substituir.

---

## E3 — 🔴 A leitura literal de SC-008 é irrealizável

`SC-008` diz: *"Nenhuma regra de exclusão do repositório aponta para alvo
inexistente."* Testado contra o `.gitignore` real:

```
padrões literais (sem curinga, sem negação, sem comentário): 80
  alvo existente em disco:  1
  alvo INEXISTENTE:        79
```

Amostra dos "inexistentes": `build`, `.coverage`, `celerybeat.pid`,
`db.sqlite3`, `cython_debug`, `.claude/settings.local.json`.

### Achado

**Apontar para alvo inexistente é o comportamento correto de um `.gitignore`.**
A regra existe justamente para excluir o arquivo **antes** de ele existir — foi
essa a ordem normativa do item 001 (exclusões vigentes antes do registro inicial,
porque o histórico é irreversível). Um oráculo que implementasse `SC-008` ao pé da
letra reprovaria 79 regras corretas.

### Decisão D3

`SC-008` é asserido apenas sobre **exclusões transitórias** — as que existem para
cobrir material com data de validade e que, cumprida a validade, viram lixo que
aponta para o vazio. Operacionalmente, neste item: `docs/AGENTS-EXAMPLE.md`.

Para que a regra sobreviva a este item, a convenção é marcada:
um bloco de exclusão transitória carrega o marcador `# transitorio:` e o oráculo
exige que todo alvo marcado exista. Alvo marcado e ausente = regra órfã.

> **Registrado para `/speckit-analyze`:** o enunciado de `SC-008` na spec é mais
> largo do que o realizável. A interpretação acima está documentada aqui e no
> contrato do oráculo, mas o texto da spec merece correção — este plano **não** a
> aplica por conta própria (a spec é insumo, não saída, do planejamento).

---

## E4 — Detecção de campos de preenchimento remanescentes (FR-001)

```
padrão \[[A-Z][A-Z0-9_]*\] sobre a governança em branco:
  com comentários HTML : 20 distintos
  sem comentários HTML : 19 distintos
```

Falsos positivos medidos em quatro artefatos reais do item 001
(`CONTRIBUTING.md`, `decisions.md`, `spec.md`, `README.md`): **0 ocorrências**.
O padrão não colide com sintaxe de link markdown nem com siglas.

**Achado secundário:** a pesquisa de domínio (Q1) registrou "18 placeholders". A
medição diz **19** fora de comentário, **20** com. O número correto é o medido; a
diferença não altera nenhuma decisão, mas fica corrigida aqui — em um projeto cuja
tese é *"pesquisa é verificação, não memória"*, um número herdado sem medição é
exatamente o defeito que o processo existe para pegar.

**Decisão D4:** a asserção remove comentários HTML antes de contar, e exige
**zero** ocorrências. Um campo deliberadamente deferido precisa sair do formato de
placeholder e virar prosa justificada — caso contrário "deferido" e "esquecido"
são indistinguíveis.

---

## E5 — Métrica de duplicação entre os dois arquivos da porta de entrada (FR-012)

Primeira tentativa (linhas normalizadas, ≥ 40 caracteres, ignorando cabeçalhos e
tabelas) produziu **1 falso positivo**: uma linha de comando repetida
legitimamente entre `CONTRIBUTING.md` e `scripts/verify/README.md`.

Métrica refinada — exclui também o conteúdo de blocos de código cercados:

| Par de documentos reais | Linhas duplicadas |
|---|---|
| `CONTRIBUTING.md` × `docs/plan/decisions.md` | 0 |
| `CONTRIBUTING.md` × `scripts/verify/README.md` | 0 |
| `specs/001/spec.md` × `specs/001/plan.md` | 0 |
| `docs/plan/decisions.md` × `scripts/verify/README.md` | 0 |
| **controle positivo:** `CONTRIBUTING.md` × si mesmo | **37** |

**Decisão D5:** duplicação é medida sobre **prosa normativa** — linha normalizada
(espaços colapsados, caixa baixa) com ≥ 40 caracteres, fora de bloco de código,
que não seja cabeçalho, tabela, citação ou comentário. Interseção não vazia entre
`AGENTS.md` e `CLAUDE.md` reprova.

Quatro pares reais com zero falso positivo e um controle positivo detectando 37 —
a métrica discrimina.

---

## E6 — O que o oráculo consegue de fato observar sobre FR-011

`FR-011` exige que a orientação seja carregada automaticamente a cada sessão do
agente construtor. **Um script não observa o carregamento de contexto de outro
processo.** Asserir o inobservável produziria uma asserção que aprova sempre.

**Decisão D6:** o oráculo assere o **mecanismo documentado pelo fornecedor**, não
o efeito: existe `CLAUDE.md` na raiz e ele contém a diretiva de importação exata
de `AGENTS.md`. A verificação do efeito é o cenário manual de `quickstart.md`.

Esta é uma fronteira honesta entre o que o harness decide e o que ele não decide —
e fica registrada como tal, para que ninguém leia `FR-011` verde como prova de
comportamento em tempo de execução.

---

## E7 — Privilégio de plataforma (FR-013)

C5 rejeitou o link simbólico porque exige privilégio de administrador no Windows.
A asserção correspondente é direta e decidível: `CLAUDE.md` **é arquivo regular**.

**Decisão D7:** asserção sobre o tipo do arquivo, não sobre a plataforma. Um link
simbólico reprova em qualquer sistema operacional, inclusive naqueles onde ele
funcionaria — porque o artefato é versionado e viaja para máquinas onde não
funciona.

---

## E8 — Conjunto dos artefatos sujeitos à revalidação retroativa (FR-017)

`SC-007` exige veredito para **100 %** dos artefatos entregues pelo item 001.
"100 % de um conjunto indefinido" não é mensurável. Enumeração no disco:

```
$ git ls-files   (excluídos .specify/, .claude/skills/ e os dois documentos
                  de planejamento pré-existentes)
```

resulta em **16 caminhos**: `.gitignore`, `CONTRIBUTING.md`,
`docs/plan/decisions.md`, `docs/plan/research/f0-001-git-branching.md`,
`scripts/verify/README.md`, `scripts/verify/f0-001-foundation.sh` e os 10
artefatos sob `specs/001-git-branching-strategy/`.

**Decisão D8:** o conjunto é **fixado nominalmente** no contrato do oráculo. O
documento de veredito precisa nomear os 16; a asserção compara conjuntos, não
contagens — um artefato ausente é nomeado na reprovação.

`.specify/memory/constitution.md`, embora versionado pelo item 001 (ADR-005), fica
**fora** do conjunto: este item o reescreve, e revalidar contra si mesmo o
artefato que define o critério é circular.

---

## Resumo das decisões

| # | Decisão | Requisito | Fonte |
|---|---|---|---|
| D1 | `f0-002` invoca `f0-001 --quiet` diretamente; custo ~0,3 s | FR-021, SC-006 | E1 |
| D2 | Integridade do oráculo anterior fixada por resumo criptográfico | FR-021 | E2 |
| D3 | `SC-008` asserido sobre exclusões **marcadas como transitórias** | FR-019, SC-008 | **E3 — refutação** |
| D4 | Placeholders contados fora de comentário HTML; exigido zero | FR-001, SC-001 | E4 |
| D5 | Duplicação medida sobre prosa normativa, fora de blocos de código | FR-012 | E5 |
| D6 | `FR-011` assere o mecanismo documentado, não o efeito em tempo de execução | FR-011 | **E6 — fronteira** |
| D7 | `CLAUDE.md` precisa ser arquivo regular, nunca link simbólico | FR-013 | E7 |
| D8 | Conjunto de 16 artefatos do item 001 fixado nominalmente | FR-017, SC-007 | E8 |

**Nenhum `NEEDS CLARIFICATION` remanescente.**

### Correções que esta pesquisa devolve a artefatos anteriores

| Artefato | Correção | Estado |
|---|---|---|
| `docs/plan/research/f0-002-constitution.md` Q1 | "18 placeholders" → **19** fora de comentário HTML (medido) | ✅ aplicada em 2026-08-30, com nota de correção na fonte |
| `specs/002-constitution-ratification/spec.md` SC-008 | Enunciado mais largo que o realizável (E3) | ✅ aplicada em 2026-08-30 via `/speckit-analyze` achado **S1** |

Nenhuma das duas foi aplicada por este documento. Uma pesquisa que corrigisse
sozinha os artefatos que a vinculam deixaria de ser pesquisa e viraria decisão —
e o rastro de quem decidiu o quê desapareceria junto.
