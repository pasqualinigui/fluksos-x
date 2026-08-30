# Implementation Plan: Ratificação da Governança e Porta de Entrada para Agentes

**Branch**: `002-constitution-ratification` | **Date**: 2026-08-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-constitution-ratification/spec.md`

---

## Summary

Ratificar a governança do motor na versão inaugural `1.0.0`, com **dez princípios
decidíveis** — cada um com enunciado normativo, critério de violação observável e
origem transcrita —, estabelecer a porta de entrada operacional em `AGENTS.md` com
`CLAUDE.md` importando-a, atualizar o ciclo canônico para incluir a etapa de
clarificação, e **quitar as três obrigações herdadas do item 001**.

A abordagem é ditada por dois achados que a pesquisa técnica refutou antes de
entrarem no desenho: `SC-008` lido ao pé da letra reprovaria 79 regras de exclusão
corretas (E3), e executar o oráculo anterior **não prova que ele está íntegro** —
só que ele aprova (E2). O primeiro reduziu o escopo da asserção a exclusões
marcadas como transitórias; o segundo transformou a regra de não regressão da
ADR-002 em resumo criptográfico fixado, verificável por máquina em vez de por
leitura de diff.

Este é o item que **desliga o portão substituto**. A partir dele, planejamento e
análise julgam contra governança ratificada, e violação de princípio é falha
crítica automática em dez ciclos.

---

## Technical Context

**Language/Version**: Bash (POSIX-compatible) + Python 3.12.3 — **exclusivamente
stdlib**. Mesma restrição do item 001.

**Primary Dependencies**: Nenhuma. `pytest`, `ruff`, `mypy`, `lefthook`, `trivy` e
`gitleaks` continuam ausentes por design — chegam nos itens 004 a 009.

**Storage**: Sistema de arquivos. Sem base de dados.

**Testing**: Oráculo em script, `scripts/verify/f0-002-constitution.sh`, sob o
contrato de interface herdado do item 001. **33 asserções** em cinco grupos.
Promovido a `pytest` no item 004.

**Target Platform**: Linux (Ubuntu, kernel 7.0.0), git 2.55.0. O artefato
`CLAUDE.md` precisa funcionar também em Windows sem privilégio elevado (C5) — daí
a proibição de link simbólico.

**Project Type**: Governança e documentação normativa. **Não produz código de
aplicação** — o protocolo de ratificação proíbe criar ou modificar fonte de
aplicação.

**Performance Goals**: Oráculo conclui em < 5 s (SC-006). Componente conhecido: a
invocação do oráculo do item 001 custa ~0,3 s, medida em E1.

**Constraints**:
- Ordem irreversível: a remoção do material transitório é a **última ação mutante**
  do ciclo (FR-019). Antes dela: consulta (FR-018) e revalidação (FR-017).
- Parada obrigatória: não conformidade retroativa **interrompe** e sobe ao
  mantenedor (FR-017b). Nenhuma saída é aplicada automaticamente.
- Não regressão: o oráculo do item 001 não é tocado (ADR-002), e sua integridade
  passa a ser asserida.
- Orçamento de contexto: `AGENTS.md` ≤ 150 linhas, soma com `CLAUDE.md` ≤ 175.

**Scale/Scope**: 24 requisitos funcionais, 8 critérios de sucesso, 33 asserções.
Consome contrato de 1 item anterior (001, três obrigações) e entrega contrato a
**todos os itens 003–012** mais uma devolução retroativa ao 001.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Estado da constitution no momento deste planejamento**: `.specify/memory/constitution.md`
contém **19 campos de preenchimento** não substituídos fora de comentário HTML
(medido em E4 — a pesquisa de domínio havia registrado 18). É o modelo em branco.

**Consequência**: este é o **último** planejamento do motor a operar sob portão
substituto. A partir da conclusão deste item o portão real existe, e o substituto
deixa de ser legítimo.

**Portão substituto aplicado** — princípios normativos vigentes conforme
`docs/plan/implementation_plan.md`, `docs/plan/addendum_v3.md` e as ADR-001..005:

| Princípio vigente | Origem | Avaliação |
|---|---|---|
| **Determinismo** | plano §1 | ✅ Oito experimentos executados; nenhum mecanismo adotado por memória. Duas premissas **refutadas** antes de virarem desenho (E2, E3) |
| **Spec precede código** | Golden Rule | ✅ `spec.md` especificada, clarificada e validada (16/16) antes deste plano |
| **Test-First** | plano §17 | ✅ Fase B produz o vermelho antes de qualquer implementação; `FR-022` assere a existência das duas evidências |
| **O harness é o oráculo** | plano §14, ADR-002 | ✅ 33 asserções; e a própria regra de não regressão vira asserção (`FR-021a`), deixando de depender de revisão humana |
| **Segurança é Lei Zero** | addendum §9 | ✅ Nenhum segredo envolvido. `FR-019b` garante que a remoção não deixa regra órfã no `.gitignore` |
| **Pesquisa é verificação, não memória** | plano | ✅ E4 corrigiu um número herdado da própria pesquisa de domínio deste item |
| **Não invadir escopo alheio** | ordem acordada dos 12 itens | ✅ Nenhum artefato dos itens 003–012 é antecipado; o oráculo do 001 é lido, nunca escrito |

**Veredito**: **PASS**. Nenhuma violação a justificar.

**Re-avaliação pós-Phase 1**: **PASS**. O desenho não introduziu dependência, não
antecipou artefatos de itens futuros e não modificou nenhum artefato do item 001 —
exceto `CONTRIBUTING.md` §5, que `FR-016` **exige** atualizar, e `.gitignore`, cuja
entrada transitória `FR-019` **exige** remover. Ambas são obrigações herdadas
explícitas, não invasão de escopo.

> **Ressalva registrada.** A Fase F pode interromper o ciclo por decisão de
> `FR-017b`. Isso não é falha do plano: é o comportamento especificado. Um plano
> que garantisse conclusão incondicional estaria contradizendo a spec.

---

## Project Structure

### Documentation (this feature)

```text
specs/002-constitution-ratification/
├── spec.md              # Concluído (/speckit-specify + /speckit-clarify)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — E1..E8, decisões D1..D8
├── data-model.md        # Phase 1 — entidades + os dez princípios ratificados
├── quickstart.md        # Phase 1 — 9 cenários (2 de julgamento humano)
├── contracts/
│   ├── oracle-cli.md    # Phase 1 — 33 asserções deste item
│   └── entrypoint.md    # Phase 1 — contrato da porta de entrada
├── checklists/
│   └── requirements.md  # Concluído — 16/16
├── compliance-001.md    # Fase F — veredito retroativo dos 16 artefatos
├── evidence/
│   ├── red.txt          # Fase B — oráculo reprovando
│   └── green.txt        # Fase H — oráculo aprovando
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item não produz código de aplicação. Produz governança, porta de entrada e a
segunda peça do harness.

```text
fluksos-x/
├── AGENTS.md                          # NOVO — porta de entrada, <= 150 linhas
├── CLAUDE.md                          # NOVO — @AGENTS.md + seção do construtor
├── CONTRIBUTING.md                    # ALTERADO — §5 ganha a clarificação (FR-016)
├── .gitignore                         # ALTERADO — entrada transitória removida (FR-019)
├── .specify/memory/constitution.md    # REESCRITO — v1.0.0 ratificada
├── scripts/verify/
│   ├── README.md                      # ALTERADO — registra o que 002 verifica
│   ├── f0-001-foundation.sh           # INTOCADO — integridade asserida (FR-021a)
│   └── f0-002-constitution.sh         # NOVO — oráculo deste item
├── docs/
│   ├── AGENTS-EXAMPLE.md              # REMOVIDO — última ação mutante (FR-019)
│   └── plan/
│       ├── decisions.md               # ALTERADO — ADR-006
│       └── research/f0-002-constitution.md   # NOVO ao versionamento
└── specs/002-constitution-ratification/      # NOVO ao versionamento
```

**Structure Decision**: `AGENTS.md` e `CLAUDE.md` vão à **raiz** porque é onde as
ferramentas os procuram — o formato aberto é convenção de localização, e o agente
construtor carrega `CLAUDE.md` da raiz do projeto. A governança permanece em
`.specify/memory/`, o local que as etapas de planejamento e análise leem sem
configuração. O veredito retroativo fica em `compliance-001.md`, dentro da spec
**deste** item e não do 001, porque é produto deste ciclo: o item 001 está
convergido e seu diretório é registro histórico.

---

## Fases de execução

> A ordem é **normativa**. Três restrições a governam: (1) o vermelho antes da
> implementação, porque é a única prova de test-first disponível antes do item 004;
> (2) a consulta ao material transitório antes de sua remoção, porque a remoção é
> irreversível; (3) a revalidação retroativa antes da remoção, porque ela pode
> interromper o ciclo — e interromper depois de destruir o material seria o pior
> dos dois mundos.

### Fase A — Preparação

1. Registrar **ADR-006** em `docs/plan/decisions.md`, contendo:
   - o resumo criptográfico fixado de `f0-001-foundation.sh` e a razão (E2);
   - a **tabela de derivação** dos princípios oriundos do material transitório,
     com os trechos **transcritos** (FR-018) — este é o registro que sobrevive à
     remoção;
   - a convenção `# transitorio:` para exclusões com data de validade (E3).

### Fase B — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-002-constitution.sh` com as 33 asserções de
   `contracts/oracle-cli.md`.
2. **Executar e preservar a saída** em `evidence/red.txt`. Deve reprovar em massa:
   governança em branco, porta de entrada inexistente, veredito retroativo
   inexistente. `FR-019a` reprova por design — o material ainda precisa existir.
3. Conferir que `FR-021a` e `FR-021b` já aprovam **nesta fase**: o oráculo do item
   001 está íntegro e aprovando desde antes de este item começar.

> Pular esta fase satisfaz todos os FR e ainda assim **falha SC-005**, porque a
> evidência do vermelho não existiria e não é recuperável depois.

### Fase C — Ratificação da governança

1. **Consultar `docs/AGENTS-EXAMPLE.md`** (FR-018). As quatro derivações estão
   fixadas em `data-model.md`: I (parcial), IV, VII e VIII.
2. Reescrever `.specify/memory/constitution.md` na versão `1.0.0` com os dez
   princípios de `data-model.md`, cada um com `Violação:` e `Origem:` rotulados.
3. Preencher as duas seções extras: **Restrições Adicionais** e **Fluxo de
   Desenvolvimento** — esta última declara o ciclo canônico com a clarificação
   (FR-015).
4. Preencher **Governança**: procedimento de emenda, política de versionamento e
   expectativa de revisão de conformidade (FR-007).
5. Emitir o **registro de impacto** como comentário único no topo (FR-008).

### Fase D — Porta de entrada

1. Escrever `AGENTS.md` conforme `contracts/entrypoint.md`, ≤ 150 linhas, só
   ponteiros — nunca o texto integral dos princípios nem do plano.
2. Escrever `CLAUDE.md`: a diretiva `@AGENTS.md` mais a seção específica do agente
   construtor. **Arquivo regular**, nunca link simbólico.
3. Medir orçamento e duplicação antes de seguir (cenários 4 e 5 do quickstart).

### Fase E — Ciclo canônico

1. Atualizar `CONTRIBUTING.md` §5 para o ciclo com clarificação (FR-016a).
2. Varrer os documentos normativos e garantir que o ciclo anterior não permanece
   em circulação (FR-016b). Artefatos de especificação e evidência ficam fora do
   escopo — são registro histórico.
3. Atualizar `scripts/verify/README.md` registrando o que o item 002 passa a
   verificar, conforme o contrato de crescimento do harness.

### Fase F — Revalidação retroativa ⚠️ *ponto de parada possível*

1. Produzir `compliance-001.md` com veredito para os **16 artefatos** fixados em
   E8, nomeando artefato e princípios avaliados.
2. **Se qualquer veredito for `nao conforme`**: registrar o achado, **interromper
   o ciclo** e submeter a decisão ao mantenedor (FR-017b). Não corrigir o
   artefato, não emendar o princípio, não registrar exceção por conta própria.
3. Só prosseguir com 16/16 `conforme`, ou com decisão explícita do mantenedor
   registrada.

### Fase G — Remoção do material transitório 🔒 *última ação mutante*

1. Remover `docs/AGENTS-EXAMPLE.md` do disco.
2. Remover do `.gitignore` a entrada transitória **e o comentário que a explica**,
   para não deixar regra órfã (FR-019b, SC-008).

> A partir daqui o material não existe. Tudo que dele deriva já está transcrito na
> ADR-006 e nos campos `Origem:` dos princípios — foi essa a razão de a Fase A
> preceder tudo.

### Fase H — Verde e convergência 🟢

1. Executar o oráculo. As 33 asserções aprovam; preservar `evidence/green.txt`.
2. Executar duas vezes e comparar (FR-020c), e conferir `git status` limpo.
3. Executar o harness acumulado: `f0-001` e `f0-002`, cada um < 5 s (SC-006).
4. Registrar o ciclo em commits que obedeçam à convenção do próprio item 001.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito |
|---|---|---|
| D1 | `f0-002` invoca `f0-001 --quiet`; custo medido ~0,3 s | FR-021b, SC-006 |
| D2 | Integridade do oráculo anterior fixada por resumo criptográfico | FR-021a |
| D3 | `SC-008` restrito a exclusões **marcadas como transitórias** | FR-019, SC-008 |
| D4 | Campos em aberto contados fora de comentário HTML; exigido zero | FR-001 |
| D5 | Duplicação medida sobre prosa normativa, fora de blocos de código | FR-012 |
| D6 | `FR-011` assere o mecanismo documentado, não o efeito de sessão | FR-011 |
| D7 | `CLAUDE.md` precisa ser arquivo regular | FR-013 |
| D8 | Conjunto de 16 artefatos retroativos fixado nominalmente | FR-017, SC-007 |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Um princípio é ratificado sem critério de violação e vira gerador de falso positivo em dez ciclos | **Crítico** — o mecanismo de falha crítica automática passa a disparar sobre interpretação | `FR-005b` exige o rótulo `Violação:` em cada princípio; o cenário 3 do quickstart aplica o teste humano que a máquina não faz |
| Um item futuro enfraquece o oráculo do 001 e continua saindo `0` | **Crítico** — regressão silenciosa, a exata falha que a ADR-002 proíbe | `FR-021a`: resumo criptográfico fixado. Divergência sobe para decisão, **nunca** para atualização do valor |
| A remoção do material transitório ocorre antes da consulta | **Crítico e irreversível** — a rastreabilidade dos princípios derivados morre | Fase A transcreve os trechos na ADR-006; Fase G é a última ação mutante por construção; `FR-019a` só fica verde no fim |
| `SC-008` implementado ao pé da letra reprova 79 regras corretas | Alto — oráculo inútil, ou pior, desabilitado | E3 refutou a leitura literal antes da implementação; convenção `# transitorio:` delimita o escopo |
| A porta de entrada cresce e a adesão do agente ao próprio conteúdo cai sem sinal de erro | Alto — degradação silenciosa, o artefato continua "funcionando" | `FR-014` sobre a **soma**, com margem explícita de 25 linhas para 003–012 |
| A revalidação retroativa encontra violação e o ciclo é interrompido | Médio — trabalho não conclui neste ciclo | É o comportamento especificado (`FR-017b`), não um defeito. A Fase F precede a Fase G justamente para que a interrupção não custe o material |
| `AGENTS.md` e `CLAUDE.md` divergem com o tempo | Médio — duas verdades | `FR-012` proíbe prosa duplicada: sem duplicação não há o que divergir. A precedência da governança está declarada no próprio `AGENTS.md` |
| Verde em `FR-011` lido como prova de carregamento em tempo de execução | Médio — confiança indevida numa asserção de proxy | A fronteira está declarada no contrato, na pesquisa (E6) e no cenário 6 do quickstart |

---

## Complexity Tracking

> Preenchido apenas se o portão constitucional apresentar violações a justificar.

Nenhuma violação. Tabela não aplicável.

---

## Achado devolvido à spec

`SC-008` — *"Nenhuma regra de exclusão do repositório aponta para alvo
inexistente"* — é **mais largo do que o realizável**: apontar para alvo inexistente
é o comportamento correto de uma regra de exclusão, e 79 das 80 regras literais do
`.gitignore` atual estão nessa condição (E3).

Este plano adotou a interpretação restrita a exclusões transitórias e a documentou
em três lugares, mas **não alterou a spec por conta própria** — a spec é insumo do
planejamento, não sua saída. O ajuste de texto foi encaminhado a
`/speckit-analyze`, que é a etapa cujo trabalho é justamente detectar divergência
entre artefatos.

> **Resolvido em 2026-08-30.** `/speckit-analyze` registrou o achado como **S1
> (HIGH)** e a correção foi aplicada em `spec.md` › Success Criteria com aval do
> mantenedor. `SC-008` passou a exigir alvo existente apenas para exclusões
> **marcadas como transitórias**. O plano permanece como está: sua interpretação
> era a correta, e agora a spec a acompanha — nesta ordem, que é a que preserva a
> spec como fonte.
