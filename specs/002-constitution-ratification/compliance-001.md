# Veredito de Conformidade Retroativa — artefatos do item 001

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30
**Governança avaliadora**: `.specify/memory/constitution.md` v1.0.0
**Requisito**: FR-017 · **Critério**: SC-007 (100% dos artefatos com veredito)

Os 16 artefatos entregues pelo item 001 são reavaliados contra os dez princípios
recém-ratificados. O conjunto está fixado em `research.md` E8.
`.specify/memory/constitution.md` fica fora: este item o reescreve, e revalidar
contra si mesmo o artefato que define o critério seria circular.

> **Regra de parada (FR-017b).** Qualquer veredito não conforme **interrompe o
> ciclo** e submete a decisão ao mantenedor. Corrigir o artefato, emendar o
> princípio ou registrar exceção são as três saídas, e nenhuma é aplicável
> automaticamente. Este é o primeiro precedente de conflito entre governança e
> trabalho já convergido no motor.

---

## Resultado

| | |
|---|---|
| Artefatos avaliados | **16 / 16** |
| Conformes | **15** |
| Não conformes | **1** |
| Estado do ciclo | ⚠️ **INTERROMPIDO — decisão do mantenedor pendente** |

---

## Vereditos

| # | Artefato | Princípios avaliados | Veredito |
|---|---|---|---|
| 1 | `.gitignore` | V, VI, X | conforme |
| 2 | `CONTRIBUTING.md` | II, V, VI, IX | conforme |
| 3 | `docs/plan/decisions.md` | VII, VIII | conforme |
| 4 | `docs/plan/research/f0-001-git-branching.md` | I, VIII | conforme |
| 5 | `scripts/verify/README.md` | VI, IX, X | conforme |
| 6 | `scripts/verify/f0-001-foundation.sh` | I, V, **VI**, IX, X | 🔴 **nao conforme** |
| 7 | `specs/001-git-branching-strategy/spec.md` | II, IV | conforme |
| 8 | `specs/001-git-branching-strategy/plan.md` | I, II, IV | conforme |
| 9 | `specs/001-git-branching-strategy/research.md` | I, VIII | conforme |
| 10 | `specs/001-git-branching-strategy/data-model.md` | IV | conforme |
| 11 | `specs/001-git-branching-strategy/quickstart.md` | III, X | conforme |
| 12 | `specs/001-git-branching-strategy/tasks.md` | II, III | conforme |
| 13 | `specs/001-git-branching-strategy/contracts/oracle-cli.md` | IV, VI, X | conforme |
| 14 | `specs/001-git-branching-strategy/checklists/requirements.md` | II | conforme |
| 15 | `specs/001-git-branching-strategy/evidence/t015-red.txt` | III | conforme |
| 16 | `specs/001-git-branching-strategy/evidence/t023-green.txt` | III | conforme |

---

## 🔴 Não conformidade — artefato 6 contra o princípio VI

**Artefato**: `scripts/verify/f0-001-foundation.sh`
**Princípio**: **VI — O harness é o oráculo**
**Critério de violação**: *"existe critério de aceitação sem asserção
correspondente no harness"*

### Evidência

Correspondência **em substância**, não por homonímia — um critério coberto por
asserção de nome diferente conta como coberto:

| Critério (spec 001) | Asserção que o decide | Estado |
|---|---|---|
| `SC-001` zero proibidos no histórico | `FR-020a` + `FR-020b` | coberto |
| `SC-002` registros classificáveis | `SC-002` | coberto |
| `SC-003` **< 5 s** e duas execuções idênticas | `FR-018` (checagem **estática** do fonte) | 🔴 **parcial** — o tempo não é medido; a igualdade entre execuções não é comparada empiricamente |
| `SC-004` par vermelho→verde preservado | — | 🔴 **nenhuma** |
| `SC-005` nome revela fase, pacote e propósito | `FR-006` + `FR-006b` | coberto |
| `SC-006` roda só com o do bootstrap | `FR-019` | coberto |
| `SC-007` contratos declarados por escrito | — | 🔴 **nenhuma** |

Verificação executada:

```
grep -n "SECONDS|cmp -s|diff " scripts/verify/f0-001-foundation.sh   -> nenhum
grep -n "evidence|red.txt|green.txt" ...                             -> nenhum
grep -n "Contratos|Transferido" ...                                  -> nenhum
```

`FR-018` verifica que o **fonte do script** não contém construção não
determinística. É uma checagem estática: ela não observa se duas execuções
produzem de fato a mesma saída, nem quanto tempo a execução leva. São garantias
diferentes, e `SC-003` pede as duas.

### Por que isto não é rigor excessivo

O item 001 é o único dos doze que nunca foi julgado por uma governança ratificada
— a dívida que a ADR-003 registrou e transferiu a este item. Três critérios de
aceitação seus são verificados **por leitura humana**, que é exatamente o que o
princípio VI existe para substituir. Enquanto o harness não os cobre, "o item 001
está conforme" continua sendo opinião.

O contraste torna o achado concreto: o item 002 cobre as mesmas três lacunas —
`SC-006` mede o tempo, `FR-020c` compara duas execuções byte a byte, `FR-022`
assere o par de evidências, `FR-023` assere a seção de contratos, e a §2.1 do seu
contrato declara nominalmente cada critério sem asserção homônima e quem o decide.
Nada disso existia quando o item 001 convergiu.

### Por que o ciclo parou aqui

`FR-017b` proíbe que eu escolha. As três saídas possíveis são:

| Saída | O que implica |
|---|---|
| **A — Corrigir o artefato** | Acrescentar as asserções faltantes a `f0-001-foundation.sh`. Colide frontalmente com a **ADR-002** e com a asserção `FR-021a` deste item: o resumo criptográfico fixado mudaria, e a regra "um item nunca modifica o oráculo de um item anterior" seria quebrada logo no ciclo que a tornou mecânica |
| **B — Emendar o princípio VI** | Restringir a exigência a itens posteriores à ratificação. Enfraquece o princípio no seu primeiro exercício e cria precedente de que governança recua diante de trabalho já feito |
| **C — Registrar exceção fundamentada** | Manter o princípio íntegro, registrar que o item 001 antecede a ratificação, e transferir a cobertura das três lacunas a um item nomeado — com prazo, não indefinidamente |

Nenhuma foi aplicada. O oráculo reprova `FR-017b` e nomeia o par
artefato×princípio até que a decisão seja registrada aqui.

### Decisão do mantenedor

**Saída escolhida**: **C — exceção fundamentada com transferência a item nomeado**

**Fundamentação**: A saída A quebraria a ADR-002 e invalidaria `FR-021a` deste
mesmo item — o resumo criptográfico fixado de `f0-001-foundation.sh` mudaria, e a
regra "um item nunca modifica o oráculo de um item anterior" cairia exatamente no
ciclo que a tornou mecânica. A saída B enfraqueceria o princípio VI no seu
primeiro exercício, logo depois de ele ter encontrado uma lacuna real que a
revisão humana do item 001 não pegou. A saída C reconhece a não conformidade, a
registra, e transfere a cobertura ao **item 004 (0.4 — Pytest)**, que já tem por
desenho a tarefa de promover cada oráculo a módulo de teste: as quatro asserções
faltantes entram **como casos de teste novos, ao lado**, nunca dentro do oráculo
do item 001. A exceção **expira quando o item 004 convergir** — se ele convergir
sem cobri-las, o achado reabre.

**Registro**: `docs/plan/decisions.md` › **ADR-007**

**Data**: 2026-08-30

### Estado após a decisão

| | |
|---|---|
| Não conformidade | reconhecida e registrada |
| `scripts/verify/f0-001-foundation.sh` | **intocado** — resumo `63412ca7…5a6bbf22` permanece válido |
| Princípio VI | íntegro, sem emenda |
| ADR-002 | íntegra |
| Cobertura transferida a | **item 004 (Pytest)**, 4 casos nomeados |
| Prazo | convergência do item 004 |
